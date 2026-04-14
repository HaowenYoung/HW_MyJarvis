#!/bin/bash
# rule-audit.sh
# Scan all rule/policy frontmatter, flag items needing attention.
# Flags: violation_count > 3, status: under-review, last_applied > 28 days ago.
# Output: file | reason

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

TODAY=$(date +%s)
STALE_DAYS=28

for f in wiki/rules/*.md wiki/policies/*.md wiki/traits/*.md wiki/values/*.md; do
  [ -f "$f" ] || continue

  # Extract frontmatter fields
  vc=$(sed -n '/^---$/,/^---$/{/^violation_count:/s/.*: *//p}' "$f" | head -1)
  status=$(sed -n '/^---$/,/^---$/{/^status:/s/.*: *//p}' "$f" | head -1)
  last=$(sed -n '/^---$/,/^---$/{/^last_applied:/s/.*: *//p}' "$f" | head -1)

  # Check violation count
  if [ -n "$vc" ] && [ "$vc" != "null" ] && [ "$vc" -gt 3 ] 2>/dev/null; then
    echo "$f | HIGH VIOLATIONS: $vc"
  fi

  # Check status
  if [ "$status" = "under-review" ]; then
    echo "$f | STATUS: under-review"
  fi

  # Check staleness
  if [ -n "$last" ] && [ "$last" != "null" ]; then
    last_epoch=$(date -d "$last" +%s 2>/dev/null || echo 0)
    if [ "$last_epoch" -gt 0 ]; then
      diff_days=$(( (TODAY - last_epoch) / 86400 ))
      if [ "$diff_days" -gt "$STALE_DAYS" ]; then
        echo "$f | STALE: last applied $diff_days days ago"
      fi
    fi
  elif [ "$last" = "null" ] || [ -z "$last" ]; then
    echo "$f | NEVER APPLIED"
  fi
done
