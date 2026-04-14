#!/bin/bash
# check-alerts.sh
# Run all deterministic alert checks (3a-3e), output active alerts.
# Called by: cron at 7:00 daily, and at Claude Code session start.
# Output: alerts to stdout AND wiki/plans/alerts-YYYY-MM-DD.md

set -uo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

TODAY=$(date +%Y-%m-%d)
TODAY_EPOCH=$(date +%s)
ALERT_FILE="wiki/plans/alerts-${TODAY}.md"
ALERTS=""

add_alert() {
  local level="$1"  # WARNING | INFO
  local category="$2"
  local message="$3"
  ALERTS="${ALERTS}\n- **[${level}] ${category}**: ${message}"
}

# ────────────────────────────────────────────────
# 3a. Deadline 预警
# Scan project wikis for deadline fields
# ────────────────────────────────────────────────
for f in projects/*/wiki/INDEX.md wiki/context/active-projects.md; do
  [ -f "$f" ] || continue
  # Look for dates in format YYYY-MM-DD after "deadline" or "results" keywords
  while IFS= read -r line; do
    deadline_date=$(echo "$line" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
    [ -z "$deadline_date" ] && continue
    deadline_epoch=$(date -d "$deadline_date" +%s 2>/dev/null || continue)
    remaining_days=$(( (deadline_epoch - TODAY_EPOCH) / 86400 ))
    if [ "$remaining_days" -ge 0 ] && [ "$remaining_days" -le 14 ]; then
      context=$(echo "$line" | sed 's/|//g' | sed 's/  */ /g' | head -c 120)
      add_alert "WARNING" "Deadline" "${context} — ${remaining_days} days remaining"
    fi
  done < <(grep -i -E '(deadline|results|due|投稿|submission)' "$f" 2>/dev/null || true)
done

# ────────────────────────────────────────────────
# 3b. Pattern 异常 — task type time distribution
# Check if any task type is missing for 5+ days
# ────────────────────────────────────────────────
if [ -d "raw/daily" ]; then
  WEEK_AGO=$(date -d "$TODAY - 7 days" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null || echo "")
  if [ -n "$WEEK_AGO" ]; then
    reading_days=0
    total_days=0
    for f in raw/daily/*.md; do
      [ -f "$f" ] || continue
      fname=$(basename "$f" .md)
      [[ "$fname" < "$WEEK_AGO" ]] && continue
      total_days=$((total_days + 1))
      if grep -qi "Type:.*reading" "$f" 2>/dev/null; then
        reading_days=$((reading_days + 1))
      fi
    done
    if [ "$total_days" -ge 5 ] && [ "$reading_days" -eq 0 ]; then
      add_alert "INFO" "Pattern" "过去 ${total_days} 天没有 reading 类型任务"
    fi
  fi
fi

# ────────────────────────────────────────────────
# 3c. Blocked task 检测
# Look for tasks blocked 3+ days in raw/daily/
# ────────────────────────────────────────────────
if [ -d "raw/daily" ]; then
  blocked_tasks=$(grep -rh "Status:.*blocked" raw/daily/*.md 2>/dev/null | sort | uniq -c | sort -rn || true)
  if [ -n "$blocked_tasks" ]; then
    while IFS= read -r line; do
      count=$(echo "$line" | awk '{print $1}')
      task=$(echo "$line" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/Status:.*blocked//' | sed 's/^[[:space:]]*//')
      if [ "$count" -ge 3 ]; then
        add_alert "WARNING" "Blocked" "Task blocked ${count} days: ${task}"
      fi
    done <<< "$blocked_tasks"
  fi
fi

# ────────────────────────────────────────────────
# 3e. Rule violation 累積警告
# Use rule-audit.sh output
# ────────────────────────────────────────────────
if [ -x "tools/rule-audit.sh" ]; then
  violations=$(bash tools/rule-audit.sh 2>/dev/null | grep "HIGH VIOLATIONS" || true)
  if [ -n "$violations" ]; then
    while IFS= read -r line; do
      add_alert "WARNING" "Rule Violation" "$line"
    done <<< "$violations"
  fi
fi

# ────────────────────────────────────────────────
# Event reminders (preparation task deadlines + reminder_days_before)
# ────────────────────────────────────────────────
for f in raw/events/*.md; do
  [ -f "$f" ] || continue
  fname=$(basename "$f" .md)
  # Check reminder_days_before in frontmatter
  reminder_days=$(sed -n '/^---$/,/^---$/{/^reminder_days_before:/s/.*: *//p}' "$f" | head -1 || true)
  event_date=$(sed -n '/^---$/,/^---$/{/^date:/s/.*: *//p}' "$f" | head -1 || true)
  desc=$(sed -n '/^---$/,/^---$/{/^description:/s/.*: *//p}' "$f" | head -1 || true)
  if [ -n "$reminder_days" ] && [ -n "$event_date" ]; then
    event_epoch=$(date -d "$event_date" +%s 2>/dev/null || continue)
    reminder_epoch=$((event_epoch - reminder_days * 86400))
    if [ "$TODAY_EPOCH" -ge "$reminder_epoch" ] && [ "$TODAY_EPOCH" -le "$event_epoch" ]; then
      days_until=$(( (event_epoch - TODAY_EPOCH) / 86400 ))
      add_alert "WARNING" "Event Reminder" "${desc} in ${days_until} days (${event_date})"
    fi
  fi
  # Check preparation task deadlines
  if grep -q "deadline: $TODAY" "$f" 2>/dev/null; then
    prep_task=$(grep -B1 "deadline: $TODAY" "$f" | grep "task:" | sed 's/.*task: *//' | head -1)
    add_alert "WARNING" "Preparation" "今天是 deadline: ${prep_task} (for ${desc:-$fname})"
  fi
done

# ────────────────────────────────────────────────
# 3d. 知识关联 — skip here (requires codex, not deterministic)
# ────────────────────────────────────────────────

# ────────────────────────────────────────────────
# Session-guard check (unsummarized previous work)
# ────────────────────────────────────────────────
if [ -x "tools/session-guard.sh" ]; then
  guard_output=$(bash tools/session-guard.sh 2>/dev/null || true)
  if echo "$guard_output" | grep -q "WARNING" 2>/dev/null; then
    add_alert "INFO" "Session" "Previous session has unsummarized work. Run wrap-up first."
  fi
fi

# ────────────────────────────────────────────────
# Output
# ────────────────────────────────────────────────
if [ -z "$ALERTS" ]; then
  echo "No active alerts for $TODAY."
  exit 0
fi

# Write alert file
mkdir -p "$(dirname "$ALERT_FILE")"
{
  echo "# Alerts — $TODAY"
  echo ""
  echo "Generated: $(date -Iseconds)"
  echo ""
  echo -e "$ALERTS"
} > "$ALERT_FILE"

# Print to stdout
echo "⚠️ Active alerts for $TODAY:"
echo -e "$ALERTS"
echo ""
echo "Written to: $ALERT_FILE"

# 飞书 push for high-priority alerts (WARNING level)
HIGH_ALERTS=$(echo -e "$ALERTS" | grep "\[WARNING\]" || true)
if [ -n "$HIGH_ALERTS" ] && [ -x "tools/notify.sh" ]; then
  bash tools/notify.sh "⚠️ MyJarvis Alerts ($TODAY):
$HIGH_ALERTS"
fi
