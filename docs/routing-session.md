# Claude Code Session Compute Orchestration

CC is the orchestrator, directly dispatches to the right unit.

## Dispatch table

| Need | Unit | How |
|------|------|-----|
| Deterministic ops | bash | Direct shell commands |
| Lightweight semantic | llm-route.sh | INDEX.md ranking, simple classification |
| Code analysis, session summary | Codex | CC plugin |
| Cross-ref scoring | Codex | CC plugin |
| Project wiki updates | Codex | CC plugin |
| NL generation (wiki articles) | Claude Code | Direct output |
| Plan generation | Claude Code | Multi-source synthesis |
| Distill L3→L4→L5 | Claude Code | Inductive abstraction |
| Codex audit (distill/lint/self-mod) | Codex | Adversarial review of CC judgments |
| Experiment design review | Codex | Adversarial review of research design decisions in project sessions |
| Research ops (ARIS integration) | ARIS skills | CC assembles MyJarvis context → invokes ARIS skill → captures output |
| User interaction | Claude Code | Dialogue |

## Per-operation orchestration

**Plan generation**:
```
1. bash: filter.sh, cat events/rules, git-project-summary.sh
2. llm-route.sh: semantic ranking (INDEX.md → top-K)
3. Codex (parallel): project repo state summary
4. bash: cat top-K pages → context.md
5. Claude Code: synthesize → generate plan
```

**Compile**:
```
1. bash: git diff, recent-changes.sh
2. llm-route.sh: raw/daily/ text → structured fields (→ draft)
3. Codex: review drafts → merge to formal files
4. Codex: cross-reference scoring
5. Claude Code: write wiki articles
6. bash: rebuild INDEX.md, check links
```

**Lint**:
```
1. bash: broken links, orphans, rule-audit
2. llm-route.sh: pairwise rule consistency (→ draft)
3. Codex: review lint drafts
4. Claude Code: synthesize report
```

**Wrap-up**:
```
1. bash: read Notion, wrapup-log
2. Codex: review pending drafts
3. Claude Code: user dialogue, generate daily log
4. Codex: update project wikis + session summary
5. bash: git commit, notify.sh, Notion sync
```

**Paper reading**:
```
1. Claude Code: read paper + user interaction
2. Codex: extract reading notes + rule signals + cross-refs
3. bash: update papers-index.md read_status
```

**Research operations (ARIS integration)**:
```
1. CC: identify operation type from trigger words
2. CC: assemble MyJarvis context (paper KB, project wiki, L3-L6 rules)
3. CC: invoke ARIS skill with context as preamble
4. CC: capture output → write to raw/ (papers, ideas, sessions)
5. CC: trigger incremental compile if raw/ was written
6. CC: update project wiki directly (decisions, constraints, progress, backlog)
```
See `docs/aris-integration.md` for per-operation context assembly and output routing.

## Error handling

| Scenario | Behavior |
|----------|----------|
| llm-route.sh fails | Claude Code does it (stronger) |
| Codex fails | Claude Code does it (degrade, don't block) |
| bash fails | CC reads stderr, fixes |

## Two routing contexts compared

| | Feishu bot | Claude Code session |
|---|-----------|-------------------|
| Trigger | feishu message | SSH session |
| Orchestrator | feishu-bot.py | Claude Code |
| Primary model | SiliconFlow MiniMax | Claude Code |
| Escalation | SiliconFlow→ollama→Codex→scratch | CC picks best unit |
| Write permissions | SiliconFlow/ollama: draft only | CC/Codex: formal |
| Interaction | Single-turn | Multi-turn |
