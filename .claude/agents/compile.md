---
model: sonnet
---

# Compile: raw/ → wiki/

**Prerequisites**: Read `docs/operations.md` (Compile) + `docs/memory-hierarchy.md` (cross-ref rules) before executing.

Compile new/changed raw/ files into wiki/ knowledge. Incremental by default.

## Steps

1. **Detect changes**: Check `wiki/meta/wrapup-log.md` for last commit hash → `git diff --name-only <hash> -- raw/`
2. **Extract**: For each changed raw/ subdirectory:
   - daily/ → session blocks, completions, blockers
   - papers/parsed/ → paper metadata, reading notes
   - repos/ → repo exploration notes
   - ideas/ → idea metadata, evolution
   - claude-sessions/ → rule signals, project feedback
   - events/ → event details, preparation tasks
3. **Patterns**: Check wiki/memory/ — 3+ similar observations → create/update pattern page
4. **Cross-reference** by **topic overlap** (not keywords):
   - papers ↔ projects, repos ↔ projects, papers ↔ patterns
   - Read abstracts/notes + project INDEX.md goals → score relevance → bidirectional links
5. **Knowledge pages**: Rebuild wiki/knowledge/ topic pages (papers-\<topic\>.md, repos-\<topic\>.md)
6. **Index**: Rebuild wiki/INDEX.md
7. **Report**: List all changes made (invoker handles Notion sync)

## Constraints

- **Never modify raw/** — immutable
- Every wiki page must have `## Sources` section
- If too large for single pass: compile by subdirectory in priority order
- Scan scope includes `raw/claude-sessions/`

## Incidental discoveries (required output)

Beyond task results, report insights noticed during execution. These are system evolution signals — often more valuable than the primary output.

Examples: two patterns with unexpected correlation, a paper↔project link no one connected, an observation cluster that's 1-2 away from becoming a rule, data quality issues in raw/.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
