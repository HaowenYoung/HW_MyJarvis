# MyJarvis Setup Guide

> 本文档覆盖从 `git clone` 到全套自动化就位的完整路径。配合 `CLAUDE.md`（系统 manifest）和 `docs/*.md`（各操作详细 spec）一起读。
>
> 约定：命令示例里出现 `$VAR` 代表你需要替换的变量；`→` 指"接着执行"。

---

## Phase 0: Prerequisites

| 必需 | 说明 |
|------|------|
| **Claude Code CLI** | 本系统的主编排入口。安装见 claude.ai/code。验证：`claude --version` |
| **Git** | 文件系统 + 版本控制。Linux 发行版自带 |
| **Notion account** | 浏览层。需在 Claude Code 里启用 **Notion MCP**（Settings → Connectors） |

| 可选 | 用途 |
|------|------|
| **飞书/Lark 开发者账号** | 移动端 / 无人值守通道 |
| **Ollama + qwen3:32b** | 本地 LLM 兜底（飞书 bot 使用） |
| **SiliconFlow 或兼容 OpenAI 的 API** | 快速 LLM 层（飞书 bot 使用） |
| **systemd + cron** (Linux) | 自动化：23:30 wrap-up、07:00 alert 等 |

---

## Phase 1: Clone and configure

### 1.1 Clone the template

```bash
git clone <your-fork-url> myjarvis
cd myjarvis
git submodule update --init --recursive   # 拉 wiki-compiler
```

### 1.2 生成配置文件

```bash
cp tools/llm-config.env.example    tools/llm-config.env
cp tools/notify-config.env.example tools/notify-config.env
cp tools/notion-ids.env.example    tools/notion-ids.env   # 先留占位，Phase 2 再填
```

`.gitignore` 已经把这三个 `.env` 排除在外，不会被 commit。

**`tools/llm-config.env`** — 如果你用 SiliconFlow：去 siliconflow.cn 建 API key，填入 `LLM_LIGHT_API_KEY`；`LLM_LIGHT_MODEL` 保持默认或改成你偏好的模型。只用 ollama 本地模型可以把 `LLM_LIGHT_*` 留空。

**`tools/notify-config.env`** — 可选。如果不用飞书，整个文件留占位也行。启用飞书见 Phase 4。

### 1.3 填 personal profile

Template 里 `wiki/context/` 是空目录。创建你自己的 `personal-profile.md`（不 commit，只喂给 LLM）：

```bash
cat > wiki/context/personal-profile.md <<'EOF'
# Personal Profile

## Role
- <你的职业 / 学术身份>

## Current projects
- <项目 A — 一句话描述>
- <项目 B — 一句话描述>

## Work habits
- <你什么时候精力最好？偏好什么工作节奏？>

## Known preferences
- <明确的工作偏好、工具偏好、输出风格偏好>

## Current phase
- <你这个季度 / 这个月的主线是什么>
EOF
```

这是 L5 trait 层的种子输入。空着也能跑——系统会在 compile 时从 `raw/` 行为里自动归纳，只是冷启动慢一些。

---

## Phase 2: Notion workspace setup

### 2.1 用 Claude Code 一步到位（推荐）

打开 repo 后启动 Claude Code，在会话里发一条：

```
读 CLAUDE.md 和 docs/notion-sync.md。然后用 Notion MCP 帮我创建 browse layer：

1. 顶层页面 "Agent System Hub"
2. 下面 4 个 database：
   - Daily Log         (schema 见 docs/notion-sync.md)
   - Patterns          (schema 见 docs/notion-sync.md)
   - Rules (L3+L4)     (schema 见 docs/notion-sync.md)
   - Events            (schema 见 docs/notion-sync.md)
3. 下面 6 个子页面：
   - Today's Plan
   - Daily Plan Template
   - Personal Profile
   - Projects
   - Reviews
   - Meta / Governance
4. 把所有 ID 填到 tools/notion-ids.env
```

Claude Code 会调用 Notion MCP 完成创建并回填 IDs。

### 2.2 Database schemas 概要

完整定义在 `docs/notion-sync.md` §Database schemas。摘要：

- **Daily Log**: `Date, Summary(title), Tasks Done, Tasks Total, Key Outcomes, Blockers, Energy(High/Med/Low)`
- **Patterns**: `Pattern(title), Category, Observations, Confidence, Status, First Seen`
- **Rules (L3+L4)**: `Rule(title), Level(L3-rule/L4-policy), Category, Source Pattern(relation→Patterns), Violation Count, Status, Created, Last Applied`
- **Events**: `Event(title), Date, Time, Type, Location, Duration, Status, Notes, Reminder Date, Preparation Tasks`

### 2.3 Sync zones（重要约束）

- **Zone A（fs → Notion，单向）**: Patterns / Rules / Policies / Traits / Values / Project wikis / Reviews / Profile / Meta。**永远不要直接在 Notion 改这些页面**——会被下一次 sync 覆盖。
- **Zone B（双向）**: Today's Plan / Events / Daily Log notes / Scratch。可以在 Notion 编辑，wrap-up 会读回文件系统。

---

## Phase 3: First use (daily workflow)

### 3.1 第一天：写一条 daily

```bash
# 手动写
echo "---
date: $(date +%Y-%m-%d)
---
# $(date +%Y-%m-%d)
- 今天开始搭 MyJarvis
- 装好了 Notion MCP
" > raw/daily/$(date +%Y-%m-%d).md
```

或者直接在 Claude Code 里口述："wrap-up：今天完成了 MyJarvis 初装"。

### 3.2 每天早晨：生成 plan

```
帮我生成今天的 daily plan
```

系统读 wiki → 出 plan → 写 `wiki/plans/YYYY-MM-DD.md` → sync 到 Notion。之后你在任何设备打开 Notion 都能看到并勾选 checkbox。

### 3.3 每天晚上：wrap-up

```
wrap-up：
- Task A 完成，2h
- Task B 做了一半
- 额外修了个 bug，40min
```

系统追加 `raw/daily/YYYY-MM-DD.md` → 更新 project wiki → sync Notion → git commit。

不想手动触发？见 Phase 4 的 cron 配置。

### 3.4 第 5–7 天：首次 compile

```
对 raw/ 做首次 compile。按 docs/operations.md 的 compile 协议执行。
```

产出：`wiki/memory/`（patterns）、`wiki/knowledge/`（topics）、`wiki/INDEX.md` 刷新、新 patterns 同步到 Notion Patterns database。

### 3.5 每周：lint + distill

```
lint wiki/                # 健康检查：矛盾、过期、孤立页
distill                   # L2→L3 候选，逐条 acc/rej
```

每月：`distill（L3→L4 policy review）`。每季度：`distill（L4→L5 traits）`。

### 3.6 Sanity checks

- `wiki/INDEX.md` 数字在 compile 后更新（Topics / Patterns / Rules 计数不为 0）
- `git log --oneline` 每天晚上至少一个 wrap-up commit
- Notion Daily Log database 每天一行新 entry

---

## Phase 4: Optional automation

### 4.1 飞书 bot（移动端 + 无人值守）

1. 飞书开放平台创建自建应用 → 启用机器人能力 → 获取 `App ID`, `App Secret`, `Webhook URL`。
2. 填进 `tools/notify-config.env`。
3. 事件订阅 → 回调 URL: `http://<your-server>:9321/feishu/event`，给 bot 发消息拿到你的 `open_id` 填进 env。
4. 编辑 `tools/myjarvis-feishu.service` 把 `YOUR_USER`、`/path/to/MyJarvis`、`/path/to/python3` 改成你的真实值。
5. 安装 systemd 服务：

```bash
sudo cp tools/myjarvis-feishu.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now myjarvis-feishu
sudo systemctl status myjarvis-feishu
```

6. 在飞书里给 bot 发一条消息验证是否回复。

详细路由逻辑见 `docs/routing-feishu.md`。

### 4.2 Cron jobs

`crontab -e` 添加（把 `~/agent-system` 改成你 MyJarvis 仓库的绝对路径）：

```cron
# Alert check: 07:00 daily
0 7 * * * cd /path/to/MyJarvis && bash tools/check-alerts.sh >> wiki/plans/alerts-$(date +\%Y-\%m-\%d).md

# Auto wrap-up: 23:30 daily (incremental, safe to re-run)
30 23 * * * cd /path/to/MyJarvis && bash tools/auto-wrapup.sh

# Weekly compile + lint + L2→L3 distill: Sunday 20:00
0 20 * * 0 cd /path/to/MyJarvis && claude "weekly: compile + lint + L2→L3 distill"

# Monthly L3→L4 policy review: 1st of month 20:00
0 20 1 * * cd /path/to/MyJarvis && claude "monthly: L3→L4 policy review"
```

完整解释见 `docs/cron-automation.md`。

`tools/auto-wrapup.sh` 是增量的：读 `wiki/meta/wrapup-log.md` 定位上次 commit hash，只处理增量；一天可以多次运行，无副作用。

---

## Giving context to Claude Code

| 信息类型 | 载体 | 备注 |
|----------|------|------|
| 系统全局规范 | `CLAUDE.md` | 根目录，Claude Code 自动读 |
| 操作细则 | `docs/*.md` | 按需阅读（触发器在 CLAUDE.md "How to read detailed specs"） |
| Notion IDs | `tools/notion-ids.env` | sync 脚本读取 |
| 个人上下文 | `wiki/context/personal-profile.md` | 冷启动种子 |
| 项目上下文 | `projects/*/wiki/INDEX.md` | 每项目一份 |
| 每日输入 | 会话里直接口述 | "wrap-up：做了 A 没做 B" |
| 规则审批 | 会话里 `acc` / `rej` / 修订 | distill / self-modification 时逐条确认 |
| 移动端临时笔记 | Notion scratch | 下次 session 手动拉取（Zone B） |

---

## Key principles to keep

1. **Filesystem 是 source of truth**；Notion 是镜像。Zone A 页面不要在 Notion 直接改。
2. **Zone B 可双向**——Today's Plan 的 checkbox、Events、Scratch 可以在 Notion 编辑，wrap-up 会读回。
3. **每次 session 结束前 git commit**。
4. **Sync 失败不阻塞** filesystem 操作，下次 wrap-up 补同步。
5. **CLAUDE.md 和 `docs/` 随系统演进**——修改前走 self-modification 协议（见 `docs/self-modification.md`）。
6. **Raw 不可变，Wiki 由 LLM 维护**——用户只在 distill/review 时通过 acc/rej 间接控制 wiki。

---

## Where to read next

| 你想做 | 读 |
|-------|----|
| 了解系统核心 | `CLAUDE.md` |
| 深挖某个操作 | `docs/operations.md` + `docs/<topic>.md` |
| 加 LLM 入口（Codex / 其他） | `docs/routing-session.md` + `docs/codex-audit.md` |
| 跑研究工作流 | `docs/aris-integration.md` |
| 改系统本身 | `docs/self-modification.md` |
| 记忆层级规则 | `docs/memory-hierarchy.md` |
