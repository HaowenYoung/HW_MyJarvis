---
model: sonnet
---

# Wrap-up

**Prerequisites**: Read `docs/operations.md` (Wrap-up) + `docs/notion-sync.md` (sync checklist) before executing.

Incremental wrap-up: process work since last wrap-up. Multiple wrap-ups per day OK.

## Steps

1. Read `wiki/meta/wrapup-log.md` → last commit hash
2. `git log` since last hash → if no new commits, skip
3. Read Notion Today's Plan → checkbox completion status (Zone B read-back)
4. Append session block to `raw/daily/YYYY-MM-DD.md` as `## Session N`
5. **Scan all project repos**:
   - For each project with `source_path.txt`: `git log --since=<last wrapup>` in project repo
   - New commits → update `projects/<project>/wiki/progress.md`
   - Missing session file → generate `raw/claude-sessions/` entry from git log
6. Incremental compile if new raw/ changes
7. **Project wiki updates**: progress.md, decisions.md, architecture.md, backlog.md, constraints.md
   (Factual updates go directly to project wiki, no raw/ intermediary)
8. **Notion sync checklist**: Daily Log, Today's Plan, Projects, Patterns, Rules, Profile, Meta
9. Append to `wiki/meta/wrapup-log.md` with commit hash

## Auto mode (23:30)

- Pre-generate tomorrow's plan draft → `wiki/plans/YYYY-MM-DD.md`

## Constraints

- Catches work from project repos even if session-end wasn't run
- No new commits → skip (don't create empty wrap-up)

## Incidental discoveries (required output)

Beyond task results, report insights noticed during execution. These are system evolution signals.

Examples: a project with commits but no session-end (recurring pattern?), cross-project work themes emerging, task completion rate anomaly, a decision logged in one project that affects another.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
