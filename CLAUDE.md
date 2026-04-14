# MyJarvis — Personal Agent System

## Core principle

MyJarvis 的核心价值是**个性化**。通用 LLM 给所有人一样的回答；MyJarvis 基于你 wiki 里的偏好、习惯、历史决策、研究方向、阅读笔记、工程哲学给"你"的回答。

**每次生成输出前，问自己：这个回答用到了 wiki 里的什么个人信息？**
如果答案是"没有"，就去找相关 wiki context 再重新生成——否则这次操作没利用到 MyJarvis。

这意味着 plan 基于你的 L3-L6 rules 和 time patterns、论文筛选基于你当前项目、repo 探索按你的理解习惯定制、**写作辅助引用你自己的 reading notes 和个人评价**、alert 基于你的行为 pattern、决策建议结合你的历史先例与 traits。不是通用最佳实践。

---

## Architecture

Hybrid: filesystem (source of truth) + Notion (browse) + 飞书 (mobile).
Write: local markdown + git. Browse: Notion MCP. Interact: Claude Code CLI / 飞书 bot.
→ [docs/engineering-config.md](docs/engineering-config.md)

---

## Directory

```
raw/       append-only 原始数据 (daily/events/papers/repos/ideas/sessions/drafts/feedback)
wiki/      LLM-compiled 知识 (memory/rules/policies/traits/values/knowledge/plans/reviews/meta)
projects/  项目知识库 (source_path.txt→repo; wiki/ 含 INDEX/arch/progress/backlog/decisions/constraints)
tools/     scripts + config
docs/      本文件的 sub-specs（按需深读）
```

---

## Memory hierarchy

```
L1 Observations → L2 Patterns → L3 Domain rules → L4 Policies → L5 Traits → L6 Values
```

- **Bottom-up induction**: weekly L2→L3 / monthly L3→L4 / quarterly L4→L5，全部需用户 acc/rej
- **Top-down deduction**: L5 trait → provisional L3 rule → 用户确认
- **User correction fast-track**: 用户纠正直接入对应层级（通常 L3），不走统计积累；写 Claude memory feedback 时双写到 wiki/rules/
- **L3 domains**: engineering / code-reading / paper-reading / paper-writing / research / personal
  （code-reading = 方法论偏好，非代码质量评判）

→ [docs/memory-hierarchy.md](docs/memory-hierarchy.md)

---

## Core operations

| Operation | 一句话 | Docs |
|-----------|--------|------|
| **Ingest** | append 到 raw/，需 frontmatter | [operations.md](docs/operations.md) |
| **Compile** | raw/ → wiki/：extract → patterns → cross-ref → index → sync（含 `raw/claude-sessions/`）| [operations.md](docs/operations.md) |
| **Plan** | 日 plan（work+life），cites rules w/ level，扫 14 天 events | [operations.md](docs/operations.md) |
| **Wrap-up** | 增量多 session；**扫所有 project repos**（`tools/scan-project-repos.sh`）→ daily log → review drafts → project wiki → session summary → Notion sync → git commit；23:30 cron 兜底 | [operations.md](docs/operations.md) |
| **Lint** | Weekly；bash + LLM + **Codex 交叉审计** | [operations.md](docs/operations.md) |
| **Repo exploration** | 4 层递进：Purpose → Structure → Implementation → Transfer | [repo-exploration.md](docs/repo-exploration.md) |
| **Distill** | L2→L3 weekly / L3→L4 monthly / L4→L5 quarterly；**Codex 对抗审计** candidates | [operations.md](docs/operations.md) |
| **Ideas** | 捕获 → Codex enrich（关联+评分+行动计划）→ 孵化 → 推进/归档 | [idea-management.md](docs/idea-management.md) |
| **Self-modification** | 读架构 → impact → **Codex 审 impact** → 提案 → 用户 acc/rej → 执行 → changelog | [self-modification.md](docs/self-modification.md) |
| **ARIS research** | 调研/文献/查新/找idea/审稿/写论文/实验计划：注入 context → 调 ARIS → 产出回流 | [aris-integration.md](docs/aris-integration.md) |
| **Session knowledge** | 3 层兜底：commit 同 wiki / session-guard / 23:30 cron | [operations.md](docs/operations.md) |

---

## Routing

- **飞书 bot (unattended)**: SiliconFlow(5s) → ollama qwen3:32b(30s) → Codex → scratch. Non-Codex 仅 drafts；Codex 写正式文件。→ [routing-feishu.md](docs/routing-feishu.md)
- **CC session (attended)**: CC 直接 orchestrate bash / llm-route.sh / Codex / self。Sub-unit 失败则 CC 自己做（degrade, not block）。→ [routing-session.md](docs/routing-session.md)

---

## Subagents

Sonnet 执行 agent，CC orchestrate。定义在 `.claude/agents/`，每个 prompt 引用 `docs/` 作 prerequisite。

| Agent | 操作 | 触发 |
|-------|------|------|
| compile | raw/ → wiki/ | "compile" / weekly |
| plan | 日 plan | "今日 plan" / morning |
| wrapup | wrap-up + project wiki + Notion | "wrap-up" / 23:30 |
| distill | L2→L3→L4→L5 | "distill" / weekly/monthly |
| lint | 健康检查 | "lint" / weekly |
| notion-sync | Notion 同步 | compile/plan/wrapup 后 |
| idea-enrich | Idea 关联+评分 | "记个 idea" |
| session-end | Session-end 知识捕获 | session 结束 |
| project-init | 新项目初始化 | "新建项目" |
| repo-prep | Repo L1-L3 准备 | "探索 <repo>" |

**Not subagents**（需交互或太轻量）: paper reading, self-modification, ingest, alert check.

**使用判断**：subagent 是可选优化，不是必须。context 充裕（量小）→ 主 session；大量文件读写或连续重操作（compile+lint+distill）→ delegate。不要为用而用——同一 context 信息天然互联本身就是价值。

---

## Other modules（概览；深入看 docs）

- **Paper KB** — 三层检索：papers-index.md → papers-\<topic\>.md → raw/papers/。Zotero CSV import。→ [paper-knowledge.md](docs/paper-knowledge.md)
- **Notion sync** — Zone A (fs→Notion 单向) / Zone B (双向：plan/events/daily/scratch) / Zone B+ (双向 user-override: ideas)。→ [notion-sync.md](docs/notion-sync.md)
- **Project integration** — source_path.txt → repo；`tools/generate-project-claude.sh` 自动生成项目 CLAUDE.md（注入 L3-L6 rules + 当前状态 + 知识访问 + session-end protocol）。→ [project-integration.md](docs/project-integration.md)
- **Outputs** — 4 层：Routine / Decision support / Proactive alerts / Knowledge synthesis。→ [assistant-outputs.md](docs/assistant-outputs.md)
- **Automation** — 07:00 alert / 23:30 wrap-up / Sun 20:00 compile+lint / 每月 1 号 20:00 L4 distill。→ [cron-automation.md](docs/cron-automation.md)
- **Codex audit protocol** — 含实验 review、novelty/related work 文献注入。→ [codex-audit.md](docs/codex-audit.md)

---

## Constraints

**Data discipline**
- Filesystem 是 Zone A 唯一 source of truth；Zone B 双向
- raw/ append-only，创建后不可变；wiki/ 仅由 LLM 维护
- 项目代码在项目 repo（via `source_path.txt`），不复制
- 每个 wiki page 必须有 `## Sources`
- 时间戳 ISO 8601；文件名 `YYYY-MM-DD`；中文面向用户，英文面向系统/代码/文件名
- API keys 仅在 `tools/*-config.env`，绝不入 git

**Governance**
- **系统修改必须走 self-modification protocol**：impact → Codex 审 → 提案 → 用户 acc → 执行。不要直接改 CLAUDE.md 或 docs/
- User-set rules outrank auto-generated rules（同层级）
- 从 L5 推出的 provisional L3 rule 必须经用户确认
- 每次重要操作后 git commit
- Project session 必须通过 session-end protocol 反馈

**Operational**
- Plans 必须 cite 所用 rule 及 level
- Paper ↔ project cross-reference 必须维护
- Sync failure 不阻塞 filesystem 操作
- SiliconFlow/ollama 仅写 drafts，不写 formal files
- Subagent 输出必须带 incidental discoveries，持久化到 `wiki/meta/discoveries-inbox.md`；主 session 检查跨 subagent 关联（2 周内多条指向同一 entity → 更高层级信号）。隔离 context 不等于丢弃 context
- Subagent 和 docs/ 并存；修改操作流程时两处都要更新

---

## How to read detailed specs

**执行一个操作前，必须先读对应的 `docs/*.md`。** 按需读，不要每个 session 全读：

| 要做 | 读 |
|------|------|
| Compile / Plan / Wrap-up / Lint / Distill | `docs/operations.md` |
| Routing | `docs/routing-session.md` or `docs/routing-feishu.md` |
| Paper work | `docs/paper-knowledge.md` |
| Repo exploration | `docs/repo-exploration.md` |
| "记个 idea" | `docs/idea-management.md` |
| Project setup | `docs/project-integration.md` |
| "加个功能" / "改一下" / "新增模块" | `docs/self-modification.md` |
| Codex 审计（含实验 review、novelty 注入） | `docs/codex-audit.md` |
| "调研" / "文献" / "查新" / "找idea" / "审稿" / "写论文" | `docs/aris-integration.md` |
| Memory hierarchy 细则 | `docs/memory-hierarchy.md` |
| Notion sync 细则 | `docs/notion-sync.md` |
| 系统 manifest | `docs/engineering-config.md` |
