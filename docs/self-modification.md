# Self-modification protocol

## Overview

MyJarvis 是一个模块化可插拔系统。用户可以随时要求新增模块、修改流程、调整规则。
这些修改不需要外部对话（如 claude.ai），Claude Code 自己读 CLAUDE.md + docs/ 
就有完整的架构上下文，可以独立完成修改。

## 修改类型

| 类型 | 例子 | 影响范围 |
|------|------|---------|
| 新增模块 | "加一个读 repo 的功能" | 新增 docs/*.md + raw/ 子目录 + tools/ + Notion database |
| 修改流程 | "wrap-up 改成每 2 小时一次" | 修改 docs/operations.md + cron |
| 调整规则 | "compile 的 pattern 阈值改成 4 次" | 修改 docs/memory-hierarchy.md |
| 新增数据源 | "接入我的 Google Calendar" | 新增 docs/*.md + tools/ 脚本 |
| 修改路由 | "飞书 bot 也用 Codex 处理 event" | 修改 docs/routing-feishu.md |
| 修改 Notion 结构 | "加一个 Repos database" | 修改 docs/notion-sync.md + 创建 database |
| 新增交互通道 | "加 email 推送" | 新增 docs/*.md + tools/ 脚本 |

## Self-modification workflow

当用户说"加个功能 XX"或"改一下 YY"时，执行以下流程：

### Step 1: Understand request

读取用户的修改需求。如果需求模糊，提问澄清（但不要过度提问，跟 plan review 一样，
先给一个合理的方案让用户 acc/rej，比反复追问更高效）。

### Step 2: Architecture review

读相关的架构文件，理解现有设计：
  - 必读：CLAUDE.md（核心宪法，理解整体架构和 constraints）
  - 按需读：跟修改相关的 docs/*.md（理解要改的模块的详细设计）
  - 按需读：tools/ 下的相关脚本（理解现有实现）
  - 按需读：wiki/meta/（理解当前状态，如 routing-feedback、distill-log）

### Step 3: Impact analysis

在修改之前分析影响面：

  a) 哪些文件需要改？
     - CLAUDE.md 核心宪法需要更新吗？（概要层面）
     - 哪些 docs/ 文件需要改？
     - 需要新建哪些文件/目录？
     - 需要新建/修改哪些 tools/ 脚本？
     
  b) 跟现有模块有冲突吗？
     - 新功能的数据格式跟现有 frontmatter 标准一致吗？
     - 新功能的文件位置符合现有目录结构吗？
     - 新功能的 Notion 同步属于哪个 Zone？
     - 新功能的计算路由走哪条路径？
  
  c) 需要改哪些跨模块的东西？
     - compile 的 Phase 0 需要扫描新目录吗？
     - plan generation 需要读新数据吗？
     - cross-reference 需要覆盖新实体吗？
     - project CLAUDE.md 需要注入新内容吗？
     - 飞书 bot 需要新 command 或新 intent 吗？

### Step 3.5: Codex audit of impact analysis

完成 impact analysis 后，发送给 Codex 审计。详见 `docs/codex-audit.md` §2 "Self-modification impact analysis"。

Codex 审计维度：遗漏的跨模块影响、constraint 违反、更简单的替代方案、副作用。
Codex 返回：LGTM / MISSED / VIOLATION / SIMPLIFY + 具体意见。

将 Codex 意见合并到 Step 4 提案中，标注 "[Codex 审计]"。

**降级**: Codex 不可用时跳过，正常提案，标注"Codex 审计未完成"。

### Step 4: Propose modification

向用户呈现修改方案，格式：

```markdown
## 修改方案：<功能名>

### 新增文件
- docs/<module>.md — <一句话描述>
- raw/<dir>/ — <存什么>
- tools/<script>.sh — <做什么>

### 修改文件
- CLAUDE.md — 加概要 + quick dispatch 条目
- docs/operations.md — compile Phase X 加扫描 <dir>
- docs/notion-sync.md — 新增 <database> (Zone X)
- docs/routing-feishu.md — 新增 /<command>
- tools/generate-project-claude.sh — 注入 <section>

### 跨模块影响
- compile: Phase 0 扫描范围加 raw/<dir>/
- plan generation: 读 <new data source>
- cross-ref: <entity> ↔ projects, <entity> ↔ papers
- Notion: 新建 <database>，Zone <X>
- 飞书 bot: 新增 /<command>

### 不改的（明确标注）
- routing 不变
- memory hierarchy 不变
- ...

### 风险
- <如果有潜在问题，标注>

要我执行吗？(acc/rej/edit)
```

### Step 5: User review

用户回复：
  - `acc` → 执行修改
  - `rej <原因>` → 调整方案重新提案
  - `edit <修改>` → 按修改执行

### Step 6: Execute modification

按方案逐步执行：

6a) 创建新文件（docs/, raw/, tools/）

6b) 修改现有 docs/ 文件
  对每个修改：先 cat 当前内容 → 修改 → 验证一致性

6c) 更新 CLAUDE.md
  只改两处：
    - Core operations 概要加一行
    - Quick dispatch 加对应的触发词
  不要把详细内容塞进 CLAUDE.md（保持 < 20k chars）

6d) 创建/修改 tools/ 脚本

6e) 如果需要 Notion：通过 MCP 创建 database，更新 notion-ids.env

6f) 如果需要飞书 bot 更新：修改 tools/feishu-bot.py

### Step 7: Verify

修改完成后验证：

  a) wc -c CLAUDE.md — 确保 < 20k chars
  b) 检查所有 docs/ 文件引用的文件/目录是否存在
  c) 检查新增 tools/ 脚本是否 chmod +x
  d) 检查 .gitignore 是否需要更新
  e) 如果改了 Notion 结构 → 验证 database 已创建

### Step 8: Document the modification

8a) git commit -m "feat: <功能描述>"

8b) 在 wiki/meta/changelog.md 追加一条记录：
```markdown
## YYYY-MM-DD: <功能名>
- **What**: <一句话描述修改内容>
- **Why**: <用户的需求>
- **Files changed**: <列表>
- **Impact**: <跨模块影响>
```

8c) 如果这次修改产生了新的系统设计 insight（比如"原来 X 和 Y 应该解耦"），
  写入 raw/claude-sessions/ 作为 rule signal，
  将来可能 distill 为 L4 policy（关于系统设计本身的策略）。

## 模块化设计约束（新模块必须满足）

新模块加入系统时，必须遵循以下约束，确保可插拔：

### 数据层
- 原始数据放 raw/<module>/ 下，带标准 frontmatter
- 编译产物放 wiki/knowledge/<module>-index.md + wiki/knowledge/<module>-*.md
- 如果需要 cross-ref → 在 compile Phase 3 加扫描规则

### 计算层
- 明确哪些操作是 bash 确定性的、哪些需要 LLM
- 飞书 bot 的新 intent 用 llm-route.sh（SiliconFlow → ollama）
- 深度分析用 Codex，综合推理用 Claude Code

### 展示层
- Notion database/page 的 Zone 必须明确（A / B / B+）
- 飞书 bot 的新 command 格式：/<command>
- project CLAUDE.md 里需要注入什么？

### 生命周期
- 数据怎么进来（ingest）？
- 怎么编译（compile 的哪个 phase 处理）？
- 怎么跟其他模块 cross-reference？
- 怎么在 plan generation 中被使用？
- 怎么在 session-end 被记录？

### 独立 docs/ 文件
- 每个模块一个 docs/<module>.md
- 包含：overview、data structure、workflow、cross-ref rules、
  Notion sync、quick commands、compute routing

## 系统演化的 meta-rule

这个 self-modification protocol 本身也会演化：

- 每次修改后，如果发现 Step 3 的 impact analysis 漏了某个维度
  → 更新这个文档的 impact analysis checklist
- 如果发现某种类型的修改总是需要改同样的一批文件
  → 提取为模板，加速未来同类修改
- 如果 changelog.md 积累了足够多的修改记录
  → 可以 distill 出"系统设计偏好"（L4 level）
  比如"用户倾向于给每个新实体都建 Notion database"
  或"用户倾向于所有新模块都支持飞书 command"

## 示例：用户说"加一个读 repo 的功能"

Step 1: 理解需求 — 探索 GitHub repos，理解架构，找借鉴点
Step 2: 读 CLAUDE.md + docs/paper-knowledge.md（对称设计参考）
Step 3: Impact analysis:
  新增: docs/repo-exploration.md, raw/repos/, wiki/knowledge/repos-index.md
  修改: CLAUDE.md (概要+dispatch), docs/operations.md (compile),
        docs/notion-sync.md (Repos database), docs/routing-feishu.md (/repos cmd),
        docs/project-integration.md (## Related repos in project CLAUDE.md)
  cross-ref: repo ↔ project, repo ↔ paper, repo ↔ repo
Step 4: 呈现方案 → 用户 acc
Step 5-7: 执行 + 验证
Step 8: changelog + git commit
