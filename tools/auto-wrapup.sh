#!/bin/bash
# Auto wrap-up script — triggered by cron at 23:30 daily
# Cron: 30 23 * * * cd ~/agent-system && bash tools/auto-wrapup.sh
#
# Supports incremental wrap-up: checks wrapup-log.md for last wrap-up commit,
# only processes new work since then. A day can have multiple wrap-ups.

set -euo pipefail

TODAY=$(date +%Y-%m-%d)
WRAPUP_LOG="wiki/meta/wrapup-log.md"
LOG_FILE="raw/daily/${TODAY}-auto-wrapup.log"

cd "$(dirname "$0")/.."

echo "[$(date)] Starting auto wrap-up for $TODAY" >> "$LOG_FILE"

# Get today's last wrap-up commit hash from wrapup-log.md
LAST_HASH=$(grep "$TODAY" "$WRAPUP_LOG" 2>/dev/null | tail -1 | grep -oP 'commit: \K[a-f0-9]+' || true)

if [ -z "$LAST_HASH" ]; then
    # No wrap-up today at all → full wrap-up
    MODE="auto-full"
    echo "[$(date)] No wrap-up found for today, doing full wrap-up" >> "$LOG_FILE"
else
    # Check for new commits since last wrap-up
    NEW_COMMITS=$(git log --oneline "${LAST_HASH}..HEAD" 2>/dev/null | wc -l)
    if [ "$NEW_COMMITS" -eq 0 ]; then
        echo "[$(date)] No new work since last wrap-up (${LAST_HASH}), skipping." >> "$LOG_FILE"
        exit 0
    fi
    MODE="auto-incremental"
    echo "[$(date)] Found ${NEW_COMMITS} new commits since ${LAST_HASH}, doing incremental wrap-up" >> "$LOG_FILE"
fi

# Trigger Claude Code for wrap-up
"${CLAUDE_BIN:-claude}" --dangerously-skip-permissions "Auto wrap-up (${MODE}):
1. 从 Notion 读 Today's Plan 最新状态
2. 模式: ${MODE}
   - auto-full: 生成完整 daily log
   - auto-incremental: 只处理上次 wrap-up (commit ${LAST_HASH:-none}) 之后的新 commit
3. Append 到 raw/daily/${TODAY}.md（新增 ## Session N block，不覆盖之前的）
4. 更新 project wikis（只处理增量变更的项目）
5. Incremental compile
6. 同步到 Notion
7. 在 wiki/meta/wrapup-log.md 追加记录
8. git commit
9. 生成明天的 plan draft" 2>&1 | tee -a "$LOG_FILE"

echo "[$(date)] Auto wrap-up (${MODE}) completed for $TODAY" >> "$LOG_FILE"
