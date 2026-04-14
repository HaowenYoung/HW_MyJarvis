# Project Integration

## Project wiki structure

```
projects/<project>/
  source_path.txt           # Pointer to actual repo
  wiki/
    INDEX.md                # Overview + ## Related literature
    architecture.md         # Architecture + design decisions
    progress.md             # Progress log
    decisions.md            # Decision log with rationale
    backlog.md              # Active / Queued / Ideas / Done
    constraints.md          # Known constraints + edge cases
```

## Project initialization

Create `source_path.txt` → read project repo → generate wiki/ (INDEX, architecture, progress, decisions, backlog, constraints) → add Related literature via cross-referencing → update active-projects.md → sync to Notion → git commit.

## generate-project-claude.sh

Generates a CLAUDE.md in the project repo, injecting:
- L3 rules filtered by `project_type` (code→engineering, paper→paper-writing+research, all→paper-reading)
- L4 policies, L5 traits, L6 values
- **Current project state** (from progress.md recent, backlog.md Active, constraints.md open)
- **Knowledge access protocol** (6 retrieval paths into agent-system)
- **Experiment review protocol** (research/paper/mixed only — auto-trigger Codex after design decisions)
- **Session-end protocol** (3 steps + immediate CLAUDE.md regen)

## Knowledge access protocol (injected into project CLAUDE.md)

| # | Need | Where |
|---|------|-------|
| 1 | Historical decisions | projects/<project>/wiki/decisions.md |
| 2 | Related papers | INDEX.md → Related literature → papers-<topic>.md |
| 3 | Cross-project knowledge | grep projects/*/wiki/ |
| 4 | Historical solutions | grep raw/claude-sessions/ |
| 5 | User paper opinions | wiki/knowledge/papers-<topic>.md per-paper notes |
| 6 | User preferences | wiki/traits/ + wiki/policies/ |

Priority: wiki links (deterministic) > grep > semantic search.

## Session-end protocol (injected into project CLAUDE.md)

**Step 1**: Session summary → `raw/claude-sessions/YYYY-MM-DD-HHMM-<project>.md`
**Step 2**: Update project wiki (progress, decisions, architecture, backlog, constraints)
**Step 3**: Append to daily log
**Step 4**: Immediate CLAUDE.md regeneration via generate-project-claude.sh
