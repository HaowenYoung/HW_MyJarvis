# Cron & Automation

## Cron jobs

```bash
# Alert check: 07:00 daily
0 7 * * * cd ~/agent-system && bash tools/check-alerts.sh >> wiki/plans/alerts-$(date +\%Y-\%m-\%d).md

# Auto wrap-up: 23:30 daily
30 23 * * * cd ~/agent-system && bash tools/auto-wrapup.sh

# Weekly compile + lint + L3 distill: Sunday 20:00
0 20 * * 0 cd ~/agent-system && claude "weekly: compile + lint + L2→L3 distill"

# Monthly L4 distill: 1st of month 20:00
0 20 1 * * cd ~/agent-system && claude "monthly: L3→L4 policy review"

# Optional: plan draft at 07:30
30 7 * * * cd ~/agent-system && claude "从 Notion 读 events，生成今日 plan draft，同步到 Notion"
```

## auto-wrapup.sh

Incremental wrap-up: reads `wiki/meta/wrapup-log.md` for last commit hash → only processes new commits.
A day can have multiple wrap-ups. If no new commits since last wrap-up → skip.

## check-alerts.sh

Runs 3a-3e deterministic checks + event reminders + preparation task deadlines.
High-priority alerts → 飞书 push via `notify.sh`.

## 飞书 bot systemd service

`tools/myjarvis-feishu.service` — auto-restart on crash, auto-start on boot.
Uses the Python interpreter configured in `tools/myjarvis-feishu.service` (edit `ExecStart=` to your own `python3` path). Needs `HTTPS_PROXY` if behind a firewall.

## Data ingestion sources

**Must ingest**: Active projects (via source_path.txt), historical schedules, research notes, meeting decisions, Claude session summaries
**Should ingest**: Annotated Zotero papers, blog posts, old project summaries
**Don't ingest**: Unread papers, source code, pure Q&A chats, raw transcripts
