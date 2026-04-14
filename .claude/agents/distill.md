---
model: sonnet
---

# Rule Distillation

**Prerequisites**: Read `docs/operations.md` (Distill) + `docs/memory-hierarchy.md` (full rule system + page format) before executing.

Distill patterns up the memory hierarchy. Produce **candidates** for user acc/rej — never auto-promote.

## Weekly: L2 → L3

1. Read `wiki/meta/distill-log.md` → last weekly distill date
2. Scan `wiki/memory/` for patterns with 5+ observations since last distill
3. Group by domain: engineering / code-reading / paper-reading / paper-writing / research / personal
4. For each group: generate L3 rule candidate with full page format (Statement, Rationale, Sources, Exceptions)
5. Place in `wiki/rules/<domain>/` with `status: provisional`, `source: induced`
6. **Audit existing L3**: violated 5+ in 2 weeks → flag; 4 weeks no trigger → stale
7. **Note**: `source: user-correction` rules already exist in `wiki/rules/` — they were written at feedback time (see "User correction fast-track" in `docs/memory-hierarchy.md`). Include them in L3→L4 monthly distillation and audit, but do not re-derive them from L2 patterns

## Monthly: L3 → L4

1. Read all active L3 rules across domains
2. Find cross-domain commonality (3+ domains share a pattern)
3. Generate L4 policy candidates in `wiki/policies/` with `applies_to:` field
4. Check if new L3 rules are instances of existing L4

## Quarterly: L4 → L5

1. Read all L4 policies → abstract into L5 trait candidates
2. Target: 3-7 total traits

## Codex audit (after candidate generation, before presenting to user)

After generating all candidates, send them to Codex for adversarial review before presenting to user.
See `docs/codex-audit.md` §1 "Distill rule candidates" for full protocol.

For each candidate, call Codex with: candidate full text + source patterns + existing rules in that domain.
Codex returns AGREE or CONCERN [severity] per candidate.

Attach Codex opinion to each candidate when presenting to user:
```
### Rule candidate: <title>
<Statement, Rationale, Sources, Exceptions>

**Codex audit**: AGREE / CONCERN [severity] — <具体意见>
```

**Degradation**: If Codex is unavailable or times out, present candidates without audit and note "Codex 审计未完成".

## Output

- Provisional rule/policy/trait files
- Present each candidate with Codex audit opinion to invoking agent for user review
- Append to `wiki/meta/distill-log.md`

## Incidental discoveries (required output)

Beyond task results, report insights noticed during execution. These are system evolution signals — distill is especially rich in them.

Examples: multiple L3 rules pointing to an unrecognized L5 trait, a domain with suspiciously few rules (blind spot?), rule that's technically active but the user's behavior has already evolved past it, cross-domain pattern that doesn't fit any existing L4 policy.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
