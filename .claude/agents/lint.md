---
model: sonnet
---

# Lint

**Prerequisites**: Read `docs/operations.md` (Lint) for context.

System health check: run deterministic + consistency checks on the MyJarvis knowledge base.

## Checks

1. **Broken links**: Run `tools/check-broken-links.sh` — cross-file references that don't resolve
2. **Orphan pages**: Run `tools/find-orphans.sh` — wiki/ pages not linked from INDEX.md
3. **Rule audit**: Run `tools/rule-audit.sh` — violation counts, stale rules, expired provisionals
4. **Contradictions**: Pairwise L3 rule consistency within each domain
5. **Stale claims**: wiki/ statements not supported by recent raw/ data (>30 days)
6. **Data gaps**: raw/ subdirectories with no recent entries
7. **Project divergence**: project wiki vs actual repo state (compare progress.md with `git log`)
8. **Cross-ref integrity**: broken paper↔project, repo↔project bidirectional links

## Codex cross-check (parallel with Sonnet consistency checks)

After bash deterministic checks complete, run Codex consistency check **in parallel** with Sonnet's own checks (items 4-8 above).
See `docs/codex-audit.md` §3 "Lint 双模型交叉检查" for full protocol.

Send Codex: bash check results + wiki/rules/ full rules + recent wiki/memory/ patterns + project INDEX.md files.
Codex independently checks: rule pairwise consistency, stale claims, cross-ref integrity, rule-vs-behavior drift.

Merge results:
- Both found → high confidence (report directly)
- Only Sonnet found → tag "待确认 (Claude-only)"
- Only Codex found → tag "待确认 (Codex-only)"

**Degradation**: If Codex unavailable, report Sonnet-only results and note "Codex 交叉检查未完成".

## Output

Structured report grouped by severity:
- **Error**: broken links, contradictions, stale provisionals
- **Warning**: stale claims, project divergence, data gaps
- **Info**: orphan pages, underused rules

Each issue includes: location, description, suggested fix.
Items with cross-model disagreement are highlighted with their source (Claude-only / Codex-only / consensus).

## Incidental discoveries (required output)

Beyond the lint report, report deeper insights noticed during execution. These are system evolution signals.

Examples: the real root cause behind a rule violation (not just "violated 5 times" but "because the user's workflow changed"), systemic design debt patterns, a cluster of broken cross-refs revealing a module boundary that should be restructured.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
