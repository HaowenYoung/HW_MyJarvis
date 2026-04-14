[English](README.md) | **中文**

# MyJarvis —— 个人 Agent 系统

> **这是已脱敏的框架模板。**作者本人真正在用的那套——带着真实 `raw/` 日志、编译好的 `wiki/`、活跃项目——在另一个私有仓库里。你看到的这份是空骨架：clone 下来，用你自己的数据喂它，它才变成"你的" agent。

> 通用 LLM 给所有人一样的回答；MyJarvis 基于**你自己**的 rules、traits、values、阅读笔记、项目上下文和历史决策，给"你"的回答。

每次生成输出前，系统都会先问自己一句：

> *"我这次回答用到了 wiki 里的哪些个人信息？
> 如果答案是'没有'——就去找相关 context 再重新生成。"*

这一句话，就是整个项目的立项理由。

---

## 为什么要做这个

绝大多数"AI 助手"把每次对话当作匿名 prompt。它不记得你是谁、你上周二做了什么决定、你的研究方向是什么、为什么你三周前和审稿人意见不合。结果是：它产出"看上去合理但通用"的回答，你再花力气手动个性化。

MyJarvis 反其道而行之。它是一个**单用户、有态度**的系统，它的全部工作就是把你的生活编译成一张结构化知识网络，并在每次交互时把最相关的那部分注入进来。

## 三大核心理念

### 1. 把"个性化"当成一等约束
每一个操作——日常 plan、论文筛选、repo 探索、写作辅助、alert——都必须 cite 生成它所依赖的个人 rules / traits / values。如果某个回答换一个通用 chatbot 也能说出来，那按定义就是一次失败。

### 2. 自演化 memory（L1 → L6）
Memory 不是静态 prompt。它按周期被蒸馏、被对抗审计、被你确认：

```
L1 Observations  →  L2 Patterns  →  L3 Domain rules
                                          ↓
               L6 Values  ← L5 Traits  ←  L4 Policies
```

三条通路保持它的诚实性：

- **Bottom-up induction**——weekly L2→L3, monthly L3→L4, quarterly L4→L5，每一次晋升都要你 `accept / reject`。
- **Top-down deduction**——L5 trait 可以推出一条 provisional L3 rule，但仍需你确认。
- **User-correction fast-track**——你纠正 agent 时，修正直接进入对应层级（通常 L3），绕过统计积累。

### 3. Karpathy 风格的 LLM Wiki
灵感来自 Karpathy 的 *LLM Wiki* 思路：**原始数据不应直接喂给 LLM**。所有东西都先经过 `compile`——提取、交叉引用、索引——形成一张 paper ↔ project ↔ idea ↔ rule 互链的知识网络。LLM 消费的是"处理后的知识"，不是"原始日志堆"。

### 两条支撑性理念

- **Filesystem 是唯一 source of truth。**所有产物都是 git 管理的 markdown。无 vendor lock-in，人眼可审，脚本可处理，冷备份友好。Notion 是浏览层，不是存储层。
- **双 LLM 对抗治理。**Distillation candidate、novelty claim、self-modification 提案都先经 Codex (GPT-5.4, high reasoning) 审计，再由你裁决——避免单一模型的幻觉自我强化成"规则"。

---

## 架构一图

```
     ┌──────────────── write / git ────────────────┐
     │                                             │
     ▼                                             │
   raw/   ──compile──▶   wiki/   ──inject──▶   LLM 层
 (append-only)       (知识网络)              ┌─────┴──────┐
                                             │ Claude Code│  attended
                                             │  飞书 bot   │  mobile / unattended
                                             │   Notion   │  浏览 (sync)
                                             └─────┬──────┘
                                                   │
                                              输出 / 决策
                                                   │
                                                   └── 回流 raw/
```

三个入口，一套 filesystem，一张知识图。

---

## 目录结构

| 路径 | 作用 |
|------|------|
| `raw/` | Append-only 原始数据（daily/、events/、papers/、repos/、ideas/、claude-sessions/、drafts/、feedback/）。必须带 frontmatter。 |
| `wiki/` | LLM 编译出的知识：memory/、rules/、policies/、traits/、values/、knowledge/、plans/、reviews/、meta/。仅 LLM 维护。 |
| `projects/` | 每个项目的知识库。通过 `source_path.txt` 链到真实代码仓库。 |
| `tools/` | Bash + Python 脚本（`compile.sh`、`plan.sh`、`lint.sh`、`sync-to-notion.sh`、`feishu-bot.py` 等）。 |
| `docs/` | 每项操作的详细 spec，按需阅读。 |
| `.claude/agents/` | Subagent prompts（Sonnet 执行，主 session 调度）。 |

权威 manifest 见 [`CLAUDE.md`](CLAUDE.md)。

---

## 核心操作

| 操作 | 一句话 | 详情 |
|------|--------|------|
| **Ingest** | 带 frontmatter append 到 `raw/` | [docs/operations.md](docs/operations.md) |
| **Compile** | `raw/` → `wiki/`：extract / pattern / cross-ref / index / sync | [docs/operations.md](docs/operations.md) |
| **Plan** | 日 plan（work + life），cite rules 并标 level，扫 14 天事件窗 | [docs/operations.md](docs/operations.md) |
| **Wrap-up** | 增量 session summary → project wiki → Notion → git commit（23:30 cron 兜底） | [docs/operations.md](docs/operations.md) |
| **Lint** | Weekly 健康检查；bash + LLM + Codex 交叉审计 | [docs/operations.md](docs/operations.md) |
| **Distill** | L2→L3 / L3→L4 / L4→L5，Codex 对抗审计 candidate | [docs/operations.md](docs/operations.md) |
| **Repo exploration** | 4 层递进：Purpose → Structure → Implementation → Transfer | [docs/repo-exploration.md](docs/repo-exploration.md) |
| **Ideas** | 捕获 → Codex enrich（关联 + 评分 + 行动计划）→ 孵化 → 推进/归档 | [docs/idea-management.md](docs/idea-management.md) |
| **Self-modification** | Impact 分析 → Codex 审 → 提案 → 用户 acc/rej → 执行 → changelog | [docs/self-modification.md](docs/self-modification.md) |
| **ARIS research** | 注入 context 的研究工作流（文献、查新、写论文、实验计划） | [docs/aris-integration.md](docs/aris-integration.md) |

---

## Subagents 与自动化

`.claude/agents/` 下 10 个 Sonnet subagent，每个只管一件事：

| Agent | 触发 |
|-------|------|
| `compile` | `"compile"` / 每周 |
| `plan` | `"今日 plan"` / 早晨 |
| `wrapup` | `"wrap-up"` / 每晚 23:30 |
| `distill` | `"distill"` / 每周 / 每月 |
| `lint` | `"lint"` / 每周 |
| `notion-sync` | compile / plan / wrapup 之后 |
| `idea-enrich` | `"记个 idea"` |
| `session-end` | Session 结束 |
| `project-init` | `"新建项目"` |
| `repo-prep` | `"探索 <repo>"` |

Cron 时间表（详见 [`docs/cron-automation.md`](docs/cron-automation.md)）：

- **07:00 每天** —— alert check
- **23:30 每天** —— 自动 wrap-up（增量）
- **周日 20:00** —— 每周 compile + lint + L2→L3 distill
- **每月 1 号 20:00** —— L3→L4 policy review

---

## 技术栈

- **语言。** Bash（主）+ Python 3（飞书 bot、CSV 解析、评分）。
- **Claude Code CLI** —— attended 编排。
- **Codex MCP**（GPT-5.4, high reasoning）—— distillation、novelty、self-modification 的对抗审计。
- **Notion MCP** —— 双向 sync。Zone A：`fs → Notion`（单向，编译知识）；Zone B：`fs ↔ Notion`（plan / daily / scratch）；Zone B+：user-override（ideas）。
- **SiliconFlow**（快速）+ **ollama qwen3:32b**（本地兜底）—— 仅限飞书 bot，仅写 draft，绝不写正式文件。
- **飞书 (Lark) bot** —— 移动端 / 无人值守通道，systemd 托管。
- **Zotero CSV** 论文导入管线。
- **git** —— 每次重要操作都以一次 commit 收尾。

有意没有 `package.json` 或 `requirements.txt`——每个脚本在开头自行声明依赖。

---

## Quickstart

> MyJarvis 是一个**单用户**系统。Fork 它不会直接给你一个可用的 agent，它给你的是一个骨架，你需要用几周时间用自己的 `raw/` 数据把它填起来。

```bash
# 1. clone
git clone <this-repo> myjarvis && cd myjarvis

# 2. 拉 wiki-compiler submodule
git submodule update --init --recursive

# 3. 填 secrets（绝不 commit——已在 .gitignore 里）
cp tools/llm-config.env.example      tools/llm-config.env
cp tools/notify-config.env.example   tools/notify-config.env
cp tools/notion-ids.env.example      tools/notion-ids.env
# 填 API key、Notion page ID、飞书 webhook 等

# 4. 用 Claude Code 打开仓库
claude .

# 5. 在 Claude Code 会话里：
# > 读 CLAUDE.md 和 setup_guide.md，写下第一条 raw/daily/ 条目

# 6. 累积几天 raw/ 数据后，第一次真正的操作：
# > compile
```

完整的分步搭建流程（Notion 数据库 schema、飞书 bot service 文件、cron 安装）见 [`setup_guide.md`](setup_guide.md)。

---

## 隐私模型

**本仓库开箱是空的、clone 下来是安全的**。`raw/`、`wiki/`、`projects/` 都只留骨架目录 + `.gitkeep` 占位，追踪的只有结构，外加两份通用框架文档（`wiki/meta/governance.md`、`wiki/meta/rule-lifecycle.md`）。

**但一旦你开始用，你的 fork 就会变"私人化"**。几天之内你会积累：日志、事件、纠正反馈、项目笔记，再经过蒸馏会形成描述你心理画像的 wiki。所以一开始就要做好心理准备：

- 把你的 fork **默认视作 private**。不做新一轮脱敏，不要往 public remote 推。
- 开始用之后要盯紧的敏感面：
  - `raw/daily/`、`raw/events/`、`raw/feedback/` —— 个人日志
  - `wiki/traits/`、`wiki/values/` —— 心理画像
  - `raw/papers/`、`raw/ideas/` —— 未公开研究
  - `projects/*/source_path.txt` —— 私有 repo 路径
  - `tools/*-config.env` —— API key（已 `.gitignore`，但第一次跑完后再核一遍）

### 将来想公开你的私人 fork 时

走一遍当初构建这个 template 所用的清单：

1. 清空 `raw/` 下每个子目录（保留结构 + `.gitkeep`，删内容）。
2. 删 `wiki/{memory,rules,policies,traits,values,context,knowledge,plans,reviews,topics}/` 下的内容。
3. 把 `wiki/INDEX.md` 重置成空模板；删 `wiki/meta/{changelog,discoveries-inbox,distill-log,wrapup-log,search-index}`。
4. 把具体的 `projects/<name>/` 换回 `projects/_template/`。
5. `tools/*-config.env` 还原成 `.env.example` 占位版。
6. 清掉 `tools/auto-wrapup.sh`、`tools/explore-repo.sh`、`tools/myjarvis-feishu.service` 里的硬编码路径。
7. 清空 `.claude/settings.local.json` 的 permission 缓存。
8. 重读 `.gitignore`，`grep` 一遍你的用户名 / home 路径 / 真实 API key，再 commit。

"一键脱敏"脚本还没写，列在 roadmap 里。

---

## 状态

这个仓库是**框架骨架**，不是一个活的产品。没有一个合并社区 PR 的 upstream——作者自己那份个性化 fork 在别处私有维护。使用方式就是：clone、占为己有、按需 diverge。讨论架构思路的 issue 欢迎；设计争论正是这个仓库该承载的内容。

## 协议

[GPL-3.0](LICENSE)。基于本系统的衍生作品必须同样采用 GPL-3.0。

## 致谢

- **Andrej Karpathy 的 LLM Wiki** —— 把个人知识视作编译后的交叉引用网络、而非聊天记录的直接灵感。
- **Anthropic Claude Code** —— 整个编排基座。
- **OpenAI Codex / GPT-5.4** —— 对抗审计者。
- **Notion、飞书 (Lark)、Zotero** —— 本系统的栖息地。
