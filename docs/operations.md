# Core Operations — Detailed Flows

## Ingest

**Daily**: Append to `raw/daily/YYYY-MM-DD.md` (Project, Type, Status, Estimated, Actual, Notes).
**Events**: Append to `raw/events/YYYY-MM-DD.md`. Supports future dates + extended frontmatter (reminder_days_before, preparation tasks).
**Monthly summary**: `raw/events/monthly/YYYY-MM.md` — compiled from individual event files.
**Batch**: Notion pages, Zotero BibTeX + PDFs, Claude sessions, blogs.
All files need frontmatter: `source`, `original_path`, `ingested`, `tags`, `project`.

## Compile

1. Extract events and information from new/changed raw/ files
   - Scan scope includes `raw/claude-sessions/` (agent-system + project-session feedback)
2. Update wiki/memory/ patterns (3+ observations → pattern page)
3. **Cross-reference**: link papers ↔ projects, papers ↔ patterns
4. Rebuild wiki/INDEX.md
5. Never modify raw/ — immutable

Scale: if too large for single pass, compile by subdirectory in priority order.
After compile: sync to Notion.

## Plan generation

**Step 3a**: Read Notion updates (Today's Plan, Events, scratch) → sync to filesystem.

**Step 3b**: Assemble context:
1. `wiki/values/` → L6
2. `wiki/traits/` → L5
3. `wiki/policies/` → L4
4. `wiki/rules/` → L3
5. `wiki/context/active-projects.md` + `projects/*/wiki/INDEX.md`
6. `raw/events/YYYY-MM-DD.md` → today's events
6b. `raw/events/` next 14 days → preparation task deadlines
6c. `raw/events/monthly/YYYY-MM.md` → monthly overview
7. Project repos: `git log --since='3 days ago'`
8. `raw/daily/` last 3 days + `raw/feedback/` last 5 entries
9. `wiki/memory/time-patterns.md`

**Step 3c**: Generate plan. Fixed events first, work tasks around them. Cite rules applied.
**Step 3d**: Sync to Notion Today's Plan.

## Review

`acc` / `rej [feedback]` / `edit [changes]`. Log to `raw/feedback/`.

## Wrap-up

**Two modes: manual and auto (cron 23:30). Both support incremental.**

**5a**: Read Notion plan status
**5b**: Append to `raw/daily/YYYY-MM-DD.md` as `## Session N` block
**5c**: Auto-scan all project repos for unsummarized work (`tools/scan-project-repos.sh`):
For each project with `source_path.txt`:
1. `git log --since=<last wrap-up>` in the project repo
2. If new commits exist → update `projects/<project>/wiki/progress.md` from commit messages
3. If no corresponding `raw/claude-sessions/*-<project>.md` → generate one from git log
4. Append project session entry to daily log
This catches work done in project-repo sessions even if session-end protocol wasn't executed.
**5d**: Incremental compile

**5d-bis-1: Project knowledge capture**
Update `projects/<project>/wiki/`: progress.md, decisions.md, architecture.md, insight.md, backlog.md, constraints.md.
事实性信息，直接更新，不需要经过 raw/。

**5d-bis-2: Session summary (独立于 wrap-up)**
每个 session 结束前必须执行。`raw/claude-sessions/YYYY-MM-DD-HHMM.md`（规则性信号 ≤15 行）。
不依赖 wrap-up 状态。

**5e**: Notion sync checklist:
1. Daily Log database
2. Today's Plan page
3. Projects page
4. Patterns/Rules databases
**5e-bis**: Append to `wiki/meta/wrapup-log.md`
**5f**: (Auto only) Pre-generate tomorrow's plan draft

**Auto wrap-up incremental logic**: Read wrapup-log → git log since last hash → new commits? → incremental wrap-up.

## Lint

Health check: contradictions, stale claims, orphan pages, high-violation rules, data gaps, project wiki vs repo divergence, broken cross-references.
**Codex 交叉检查**: 一致性检查阶段 Sonnet + Codex 并行独立执行，diff 结果标注共识/分歧。详见 `docs/codex-audit.md`。

## Distill

**Weekly (L2→L3)**: 5+ observations → domain rule candidates → Codex 审计 → user acc/rej. Audit: violated 5+/2w → flag; 4w no trigger → stale.
**Monthly (L3→L4)**: Find cross-domain commonality → policy candidates → Codex 审计 → user acc/rej.
**Quarterly (L4→L5)**: Abstract across policies → trait candidates → Codex 审计 → user acc/rej.
**L6**: Only on user trigger.

**Codex audit**: 每次 distill 产出 candidates 后，发给 Codex 做对抗性审计（归纳逻辑、过拟合、反例、矛盾）。审计意见附加到 candidate 一起呈现给用户。详见 `docs/codex-audit.md`。

**User correction fast-track**: `source: user-correction` 的规则不走观察次数积累，直接入对应层级（通常 L3）。写 Claude memory feedback 时双写。详见 `docs/memory-hierarchy.md` "User correction fast-track"。

**Incremental protocol**: Read `wiki/meta/distill-log.md` → process delta → append record.

## Research operations (ARIS 集成)

CC 编排，ARIS skill 执行，MyJarvis 知识系统提供 context 和接收产出。

| 触发词 | ARIS skill | Context 注入 | 产出回流 |
|--------|-----------|-------------|---------|
| 调研/文献/related work | `/research-lit` | paper KB + project wiki + L3 paper-reading rules | raw/papers/ → 增量 compile → wiki/knowledge/papers-* |
| 查新/novelty | `/novelty-check` | idea 库 + paper KB | raw/ideas/ novelty 结果 + idea 状态更新 |
| 找 idea/brainstorm | `/idea-discovery` | active projects + L5 traits + L3 research rules + idea 库 | raw/ideas/ → MyJarvis idea management 流程 |
| 审稿/review | `/auto-review-loop` | project wiki + L3 rules | raw/claude-sessions/ + project wiki (decisions/constraints/backlog) |
| 写论文/paper | `/paper-writing` | reading notes + project wiki + L3 paper-writing rules | project repo paper/ + project wiki (progress/decisions) |
| 实验计划 | `/experiment-plan` | project backlog + constraints | project repo EXPERIMENT_PLAN.md + project wiki backlog |

**降级**: ARIS skill 不可用 → CC 自己做简化版。Context 组装失败 → 跳过该 context 源继续。

详见 `docs/aris-integration.md`。

## Session knowledge capture (3-layer guarantee)

**Layer 1**: Every commit → update project wikis in same commit.
**Layer 2**: Session start → `tools/session-guard.sh` → reconcile if WARNING.
**Layer 3**: 23:30 cron safety net.
