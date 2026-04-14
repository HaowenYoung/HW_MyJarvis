# Repo exploration module

## Overview

用于理解和学习 GitHub 上感兴趣的 repo。
核心目标不是评估代码质量，而是：理解它做什么、怎么做的、对我有什么用。

与 paper reading 对称：
  paper: 理解研究问题 → 方法 → 实现 → 对我的启发
  repo:  理解目标问题 → 结构 → 实现 → 对我的借鉴

## 理解的四个层次

每个 repo 的探索按以下层次递进，每层都产出笔记：

### Layer 1: Purpose（做什么）
- 这个 repo 解决什么问题？
- 目标用户是谁？
- 输入是什么，输出是什么？
- 和已有方案（其他 repo / 论文）的区别是什么？

### Layer 2: Structure（怎么拆的）
- 问题被拆成了哪几个子问题？
- 每个子问题对应 repo 的哪个模块/目录/文件？
- 模块之间的数据流和调用关系是什么？
- 核心模块 vs 辅助模块（哪些是关键路径，哪些是 utility）

### Layer 3: Implementation（怎么做的）
- 每个核心模块的具体实现逻辑
- 用了什么算法/设计模式/框架
- 关键的技术决策和 trade-off
- 巧妙的地方和不足的地方

### Layer 4: Transfer（对我有什么用）
- 哪些思路可以借鉴到我的哪个项目？
- 具体怎么借鉴？直接复用 / 适配改造 / 仅思路参考？
- 哪些实现细节跟我的论文研究相关？
- 这个 repo 的方法论和我已读的哪些论文有关联？

Layer 1-3 任何 LLM 都能做。Layer 4 只有 MyJarvis 能做，
因为它知道你的项目、你的论文、你的研究方向。

## Data structure

raw/repos/
  <owner>-<repo>/
    meta.md             — frontmatter + 四层笔记
    clone_path.txt      — 本地 clone 路径

wiki/knowledge/
  repos-index.md        — 全量索引
  repos-<topic>.md      — 主题综述

### meta.md frontmatter
```yaml
source: github
owner: <owner>
repo: <repo>
url: https://github.com/<owner>/<repo>
language: <primary language>
topics: [topic1, topic2]
discovered: YYYY-MM-DD
explore_status: 深度探索 | 浅看 | 收藏未看
clone_path: ~/repos/<owner>-<repo>/
related_projects: []
related_papers: []
```

### meta.md body（四层结构）

```markdown
# <owner>/<repo>

## Why interesting
（一句话：为什么想看这个 repo）

## Exploration brief
（Step 1.5 产出：基于你的项目/论文需求定制的阅读重点）

## Layer 1: Purpose
### Problem
（它解决什么问题）
### Approach
（它用什么方式解决，一句话概括核心思路）
### Input / Output
（输入是什么 → 输出是什么）
### Differentiation
（和同类方案/论文的区别）

## Layer 2: Structure
### Subsystem map
（问题拆解 → 模块对应表）
| 子问题 | 对应模块 | 关键文件 |
|--------|---------|---------|
| 数据导入 | ingest/ | ingest.py, parsers/ |
| 编译知识 | compile/ | compiler.py, index.py |
| 查询 | query/ | search.py, reranker.py |

### Data flow
（模块之间的数据流向，一段简短描述或简图）

### Critical path
（哪些模块是核心路径，哪些是辅助）

## Layer 3: Implementation
### <核心模块 1 名称>
- 实现逻辑：...
- 技术选型：...
- 关键决策/trade-off：...
- 巧妙之处：...
- 不足：...

### <核心模块 2 名称>
- ...
（只写核心模块，辅助模块略过）

## Layer 4: Transfer
### 可借鉴到 <项目名 1>
- 什么：（借鉴什么思路/实现）
- 在哪里：（项目的哪个模块可以用）
- 怎么借鉴：直接复用 / 适配改造 / 仅思路参考
- 具体行动：（如果要用，下一步做什么）

### 可借鉴到 <项目名 2>
- ...

### 与论文的关联
- 和 <cite_key>: （这个 repo 实现了 / 类似于 / 改进了该论文的方法）
- 对我的论文的启发：...

### 不适用的部分
- （明确标注哪些看着好但不适合你的情况，避免将来误借鉴）
```

## Exploration session workflow

### Step 1: Repo acquisition (bash)
  - git clone 或 git pull
  - 创建 raw/repos/<owner>-<repo>/ 和 meta.md 基本信息

### Step 1.5: Assemble exploration brief (bash + Codex)

在分析代码之前，先组装个性化的"阅读透镜"。

读取：
  a) 触发意图：用户原始消息
  b) 用户的活跃项目：cat wiki/context/active-projects.md
     → 每个项目当前在做什么、需要什么
  c) 用户的论文方向：projects/<paper>/wiki/INDEX.md
     → 论文在什么阶段、研究什么问题
  d) 相关论文：Codex 快速判断 repo README 和 papers-index.md 的交集
  e) 相关已探索 repos：grep repos-index.md 看有没有同 topic 的

Codex 生成 exploration brief：
```markdown
## Exploration brief
- **Intent**: 参考 compile 实现优化 MyJarvis 的增量编译
- **Focus areas**: compile 模块的架构和增量策略（Layer 2-3 重点）
- **My project context**: MyJarvis 当前用 git diff 做增量检测（Phase 0），
  想看看有没有更好的方案
- **Related paper**: Karpathy 2026 LLM KB pattern（概念来源）
- **Related repos**: 之前看过 `<other-repo-on-same-topic>`（同 topic，可对比）
- **Transfer targets**: MyJarvis agent-system (compile pipeline)
```

### Step 2: Layered code analysis (Codex, guided by brief)

Codex 按四层递进分析，每层的产出写入 meta.md 对应 section。

**Layer 1 分析**（快速，读 README + 顶层文件）：
  - Codex 读 README、setup.py/package.json、顶层目录结构
  - 产出：Purpose / Approach / Input-Output / Differentiation
  - 耗时：几秒

**Layer 2 分析**（中等，读目录结构 + 核心模块的入口）：
  - Codex 读各模块目录结构、__init__.py / index.js、主入口文件
  - 产出：Subsystem map（子问题 → 模块映射表）、Data flow、Critical path
  - 重点分析 brief 里 focus areas 对应的模块
  - 耗时：十几秒

**Layer 3 分析**（深度，只读核心模块的实现）：
  - Codex 读 brief 里 focus areas 指定的核心模块源码
  - 产出：每个核心模块的实现逻辑、技术选型、关键决策
  - 不分析 brief 说 skip 的模块
  - 耗时：较长，但只读关键代码

**Layer 4 由 Claude Code 在交互中完成**（不是 Codex 预生成的）：
  因为 transfer 需要你参与——"这个能不能用在我的项目里"是你的判断，
  不是 Codex 能替你做的。Codex 可以预填一些 suggestion（标注为 provisional），
  但最终的 transfer notes 在你和 Claude Code 的交互讨论中确认。

### Step 3: Interactive exploration (Claude Code + user)

Claude Code 读完 Codex 产出的 Layer 1-3 笔记，跟你交互讨论。
典型对话：
  - 你："这个 compile 模块的增量策略具体怎么做的？"
    → CC 读 compile/ 源码回答
  - 你："比我们用 git diff 的方案好在哪？"
    → CC 对比你项目的 compile Phase 0 和这个 repo 的实现
  - 你："这个思路我可以用在 MyJarvis 里"
    → CC 记录到 Layer 4 transfer notes

### Step 4: Session-end outputs

4a) 完善 meta.md（Codex）：
  - Layer 1-3 已由 Step 2 预填，Step 3 交互中如果有修正则更新
  - Layer 4 Transfer：从 session 交互中提取你确认的借鉴点
    标注每个借鉴是"你确认的"还是"Codex 建议的（provisional）"
  - 更新 explore_status 为"深度探索"

4b) Cross-references（Codex）：
  - repo → project: 更新 projects/<project>/wiki/INDEX.md 的 ## Related repos
    注明具体借鉴什么，不只是"相关"
  - repo → paper: 更新 repos-index 和 papers-index 互链
  - repo → repo: 如果和之前看过的 repo 有对比价值，互链
  - project → repo: 更新 meta.md 的 related_projects

4c) Rule signals（Codex）→ raw/claude-sessions/
  domain: code-reading
  但这里的 rules 不是"代码质量评判标准"，而是"理解代码的方法论偏好"：
    - "用户习惯从数据流入口开始理解系统" → code-reading rule
    - "用户喜欢先看子问题拆解再看实现" → code-reading rule
    - "用户倾向于跟自己项目对比着理解" → code-reading rule

4d) Daily log → raw/daily/ append

4e) Immediate project CLAUDE.md regeneration
  如果 Layer 4 有确认的借鉴点 → 重新生成对应项目的 CLAUDE.md
  新增的 ## Related repos section 里会出现：
  "karpathy/llm-wiki: compile 增量策略可借鉴（用户确认），
   具体见 raw/repos/karpathy-llm-wiki/meta.md Layer 4"

## L3 code-reading domain（修正方向）

从"代码审查标准"改为"代码理解的方法论偏好"：

wiki/rules/code-reading/ 下的规则不是"什么代码是好的"，
而是"你习惯怎么理解代码"：
  - "从 input/output 开始理解系统，而不是从架构图"
  - "先看子问题拆解，再看每个子问题的实现"
  - "理解新模块时习惯跟自己项目的类似模块对比"
  - "关注 trade-off 和 why，而不只是 how"
  - "对 single-file 实现方式特别感兴趣"

这些规则影响 exploration brief 的生成：
  brief 里的 focus areas 和分析顺序会按你的理解习惯来组织。

同一个 L5 trait 在 code-reading 里的演绎：
  L5 "depth over breadth" → code-reading rule:
    "深度探索时只分析 2-3 个核心模块的实现，不要所有模块都浅看"
  L5 "rigor" → code-reading rule:
    "理解实现时必须搞清楚 why（为什么这么做），不能只看 how"

## repos-index.md format

同 papers-index.md：按 topic 分组的表格。

## Compile integration

compile 时处理 raw/repos/ 和 papers 一样：
  1. bash: 扫描 meta.md frontmatter
  2. llm-route.sh: topic 分类
  3. Codex: cross-ref scoring
  4. Claude Code: 生成 repos-<topic>.md 综述
  5. bash: 更新 repos-index.md

综述的格式也按四层组织：
  repos-<topic>.md 不是每个 repo 的摘要拼接，
  而是按"这个 topic 下的 repos 共同解决什么问题（L1）、
  各自怎么拆解的（L2 对比）、实现策略有什么异同（L3 对比）、
  对我的项目各自有什么用（L4 汇总）"来组织。

## Quick command

"探索 <url>" 或 "看看 <owner>/<repo>"
  → 执行完整 exploration workflow

"浅看 <url>"
  → 只做 Layer 1-2（Purpose + Structure），不深入 Layer 3
  → explore_status 标记为"浅看"

"深入 <已浅看的 repo> 的 <模块名>"
  → 对之前浅看的 repo 补充 Layer 3 的特定模块分析

## Feishu bot integration

飞书消息中包含 GitHub repo 链接（owner/repo 或完整 URL）+ 探索关键词时：
  1. feishu-bot.py regex fast-path 拦截
  2. 提取 owner/repo
  3. 后台启动 tools/explore-repo.sh → Claude Code session 执行 exploration workflow
  4. 完成后飞书回复摘要（Layer 1 Purpose + Layer 2 Structure 概要）
