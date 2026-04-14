---
model: sonnet
---

# Idea Enrichment

**Prerequisites**: Read `docs/idea-management.md` (Stage 2: Enrich) for full specification and frontmatter format.

Enrich a new idea with knowledge linking, credibility scoring, and action plan.

## Input

- Path to idea file in `raw/ideas/` (already has title and raw idea text)

## Steps

### 1. Knowledge linking

Read index files, find connections:
- `wiki/knowledge/papers-index.md` → topic-related papers → what's the relationship? (supports/contradicts/complements/method source)
- `wiki/context/active-projects.md` → related projects → which module/phase?
- `wiki/knowledge/repos-index.md` → related repos
- `raw/ideas/` other files → related ideas → complementary or same-topic?

Write: frontmatter `related_*` fields + `## Knowledge context` section.

### 2. Credibility scoring

- **Novelty** (0-1): Compare with related papers. No similar work → high; different angle → mid; highly similar existing work → low
- **Feasibility** (0-1): Read `wiki/context/personal-profile.md` + `active-projects.md`. Skills/time/resources match → high
- **Relevance** (0-1): Distance to current research + active projects. Core direction → high
- **Overall**: novelty×0.3 + feasibility×0.3 + relevance×0.4

Write: frontmatter `credibility` + `## Credibility rationale` with justification for each score.

### 3. Action plan

1-3 concrete next steps. Each: action description, `action_type`, deadline suggestion.
Write: `## Action plan` + frontmatter `next_action`, `action_type`, `action_deadline`.

### 4. Evolution log

Add initial entry: `YYYY-MM-DD: Created. Credibility: X.XX. <one-line rationale>.`

## Output

Updated idea file with all sections filled. Return summary for Notion sync.

## Incidental discoveries (required output)

Beyond enrichment results, report insights noticed during execution. These are system evolution signals.

Examples: multiple seed ideas converging on the same direction (cluster signal), a research blind spot revealed by the knowledge linking, an idea that challenges an existing L3 rule, feasibility score shift because a recent project taught a new skill.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
