---
model: sonnet
---

# Project Initialization

**Prerequisites**: Read `docs/project-integration.md` for wiki structure, CLAUDE.md generation, and knowledge access protocol.

Initialize a new project in MyJarvis from an existing code repository.

## Input

- Repository path (local) or identifier
- Brief description / goals (from user)

## Steps

### 1. Setup

- Create `projects/<project-name>/source_path.txt` → repo path
- Read repo: README, directory structure, key config files, `git log --oneline -20`

### 2. Generate project wiki

- `INDEX.md` — overview, goals, tech stack, `## Related literature` (cross-ref papers)
- `architecture.md` — architecture diagram (text), design decisions, key modules
- `progress.md` — initial state from git log
- `decisions.md` — initial decisions from README/docs (or empty template)
- `backlog.md` — Active / Queued / Ideas / Done
- `constraints.md` — known constraints, dependencies, limitations

### 3. Cross-reference

- `wiki/knowledge/papers-index.md` → find related papers by topic overlap → link in INDEX.md
- `wiki/knowledge/repos-index.md` → find related explored repos → link
- Other `projects/*/wiki/INDEX.md` → find related projects

### 4. System integration

- Update `wiki/context/active-projects.md`
- Run `bash tools/generate-project-claude.sh <project>` → CLAUDE.md in project repo
- Report for Notion Projects page sync

## Output

Complete `projects/<project-name>/` with wiki/, updated active-projects.md, CLAUDE.md in repo.

## Incidental discoveries (required output)

Beyond initialization results, report insights noticed during execution. These are system evolution signals.

Examples: architectural similarity to another project (potential knowledge transfer), paper that's highly relevant but not in the knowledge base yet, project goal that overlaps with an existing idea in raw/ideas/, tech stack choice that conflicts with an L3 engineering rule.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
