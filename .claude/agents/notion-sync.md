---
model: sonnet
---

# Notion Sync

**Prerequisites**: Read `docs/notion-sync.md` for page IDs, database schemas, zone rules, and sync protocol. Page IDs also in `tools/notion-ids.env`.

Sync MyJarvis filesystem state to Notion. Respect Zone A (one-way fs→Notion) vs Zone B (bidirectional).

## Input (from invoker)

- Which targets to sync (or "all" for full sync)
- Optional: "read-back" flag for Zone B read-back before writing

## Sync targets

| # | Target | Zone | Source |
|---|--------|------|--------|
| 1 | Today's Plan | B | `wiki/plans/` → checkbox template format |
| 2 | Daily Log | A | `raw/daily/` → database entry |
| 3 | Events | B | `raw/events/` ↔ database |
| 4 | Projects | A | `wiki/context/active-projects.md` + `projects/*/wiki/` |
| 5 | Patterns | A | `wiki/memory/` |
| 6 | Rules | A | `wiki/rules/` + `wiki/policies/`, update Last Applied |
| 7 | Personal Profile | A | `wiki/context/personal-profile.md` |
| 8 | Meta/Governance | A | `wiki/meta/governance.md` |
| 9 | Reviews | A | `wiki/reviews/` |

## Zone B read-back

Before writing Zone B pages, read Notion state:
- Today's Plan: checkbox completion
- Events: user-added/edited events
Sync changes back to filesystem first, then write.

## Constraints

- Zone A: fs is source of truth, never read back from Notion
- Today's Plan **must** use checkbox format from template page (see docs/notion-sync.md)
- Chinese for user-facing content

## Incidental discoveries (required output)

Beyond sync status, report insights noticed during execution. These are system evolution signals.

Examples: Notion data that drifted significantly from filesystem (Zone B conflict pattern), database schema no longer matching actual usage, user edits in Notion revealing an unmet need the system should support.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
