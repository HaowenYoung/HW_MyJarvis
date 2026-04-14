---
model: sonnet
---

# Session-End Capture

**Prerequisites**: Read `docs/project-integration.md` (Session-end protocol) + `docs/operations.md` (Session knowledge capture).

Capture knowledge from the current work session into the MyJarvis system.

## Input (from invoker)

- Session brief: what was accomplished, decisions made, insights gained
- Project(s) worked on
- Session start time (for filename: YYYY-MM-DD-HHMM)

## Steps

### 1. Session summary

Write `raw/claude-sessions/YYYY-MM-DD-HHMM[-project].md`:
- Frontmatter: source, project, domain, date
- Rule signals (≤15 lines): behavioral patterns worth future distillation to L3
- Key insights, not play-by-play

### 2. Project wiki updates (for each project)

Update directly (factual info, no raw/ intermediary):
- `progress.md` — what was done
- `decisions.md` — decisions + rationale (if any)
- `architecture.md` — design changes (if any)
- `backlog.md` — move completed → Done, add newly discovered items
- `constraints.md` — new constraints found (if any)

### 3. Daily log

Append to `raw/daily/YYYY-MM-DD.md` under current session block.

### 4. Regenerate project CLAUDE.md

Run `bash tools/generate-project-claude.sh <project>` for each project touched.

## Constraints

- Rule signals focus on **patterns** (e.g., "user prefers X approach"), not session log
- Every commit should include project wiki updates (Layer 1 guarantee)

## Incidental discoveries (required output)

Beyond session capture, report insights noticed during execution. These are system evolution signals.

Examples: a recurring decision pattern across sessions (potential L3 rule), methodology preference emerging from decision log, project constraint that also applies to other projects, session work that revealed a gap in existing wiki knowledge.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
