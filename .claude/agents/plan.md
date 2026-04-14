---
model: sonnet
---

# Plan Generation

**Prerequisites**: Read `docs/operations.md` (Plan generation) + `docs/notion-sync.md` (Today's Plan sync protocol) before executing.

Generate a daily plan by assembling context from 9+ sources and applying L3-L6 rules.

## Context assembly (in order)

1. `wiki/values/` (L6) → `wiki/traits/` (L5) → `wiki/policies/` (L4) → `wiki/rules/` (L3)
2. `wiki/context/active-projects.md` + each `projects/*/wiki/INDEX.md`
3. `raw/events/YYYY-MM-DD.md` (today) + next 14 days for preparation deadlines
4. `raw/events/monthly/YYYY-MM.md`
5. Project repos: `git log --since='3 days ago'` for each project (via `source_path.txt`)
6. `raw/daily/` last 3 days + `raw/feedback/` last 5 entries
7. `wiki/memory/time-patterns.md`
8. Active ideas with `action_deadline` today or overdue (`raw/ideas/`)

## Generation

- Fixed events first (marked "protected")
- Work tasks around events: `- [ ] **HH:MM–HH:MM** 任务名 — 描述 \`type est\``
- Rules applied section: cite which L3-L6 rules influenced each decision
- Success criteria: numbered list

## Output

- Write `wiki/plans/YYYY-MM-DD.md`
- Report plan content for Notion sync (invoker handles sync using template format from docs/notion-sync.md)

## Constraints

- Plans **must cite** which rules (with level) were applied
- Chinese for user-facing content

## Incidental discoveries (required output)

Beyond task results, report insights noticed during execution. These are system evolution signals.

Examples: L3 rules that contradict each other when applied together, time pattern anomalies vs last week, a project that's been untouched for days despite high priority, rule that was cited but felt wrong for today's context.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
