# MyJarvis Output Capabilities

## Layer 1: Routine operations (已实现)

Daily planning, wrap-up, project wiki generation, event management, Notion sync.

**Event management**: `raw/events/YYYY-MM-DD.md`. Simple format: `- HH:MM | type | description | location | duration`. Extended format: YAML frontmatter with reminder_days_before + preparation tasks.

## Layer 2: Decision support (被动触发)

**2a. 论文筛选**: relevance scoring, chapter recommendations, reading time budget.
Route: context assembly → Claude Code reasoning.

**2b. 任务优先级判断**: urgency × importance, dependency analysis, L5 trait-based adaptation.
Route: project wiki + rules → Claude Code reasoning.

**2c. 技术方案选择**: historical precedents, trait-based adaptation, time cost comparison.
Route: decisions.md + sessions → Claude Code reasoning.

## Layer 3: Proactive alerts (主动触发)

**3a. Deadline 预警**: scan projects for deadlines, estimate remaining work, alert if tight.
**3b. Pattern 异常**: compare task type distribution vs L4 policy expectations.
**3c. Blocked task**: same task blocked 3+ days → suggest workaround.
**3d. 知识关联**: new ingest relevance > threshold to active project → alert.
**3e. Rule violation**: violation_count increased 3+ in 2 weeks → suggest change.

Alert delivery (3 tiers):
- **High** → 飞书 push + Notion (deadlines, event reminders, blocked 5d+)
- **Medium** → Notion only (pattern anomaly, rule violations, cross-ref)
- **Low** → alerts file only (lint, stale rules)

## Layer 4: Knowledge synthesis

**4a. 周报/月报**: time distribution, efficiency metrics, rule violations, pattern changes, action items.
**4b. 研究方向分析**: reading coverage, blind spots, paper recommendations, interest drift.
**4c. 跨项目知识迁移**: specific knowledge fragments + migration suggestions.
**4d. 写作素材准备**: literature summaries, user opinions, experiment data, organized by writing logic.

## Capability routing summary

| Capability | Trigger | bash | ollama | codex | Claude Code |
|------------|---------|------|--------|-------|-------------|
| 2a Paper screening | user asks | filter | rank | - | reason |
| 2b Priority | user asks | cat rules | - | - | reason |
| 2c Tech choice | user asks | grep | - | - | reason |
| 3a Deadline | cron 7:00 | calc | estimate | - | alert |
| 3b Pattern | cron 7:00 | stats | match | - | - |
| 3c Blocked | cron 7:00 | grep | - | - | workaround |
| 3d Knowledge link | post-ingest | diff | - | cross-ref | - |
| 3e Rule violation | cron 7:00 | audit | - | - | suggest |
| 4a Weekly report | weekly | stats | trends | - | report |
| 4b Research dir | monthly | stats | - | gap | recommend |
| 4c Knowledge transfer | cross-ref | - | - | detect | analyze |
| 4d Writing material | user asks | filter | rank | extract | assemble |
