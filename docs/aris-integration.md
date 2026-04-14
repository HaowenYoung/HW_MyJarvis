# ARIS 集成操作

## Overview

ARIS (Auto-claude-code-research-in-sleep) 的 skills 作为 Claude Code 全局可用的 slash commands 已安装。本文档定义 MyJarvis 如何包裹这些 skills，实现**个性化 context 注入 + 产出回流**。

核心模式：CC 编排，ARIS skill 执行，MyJarvis 知识系统提供输入和接收输出。

```
用户在 MyJarvis 触发研究操作
  → CC 组装 MyJarvis context（paper KB, project wiki, L3-L6 rules）
  → 调用 ARIS skill（context 作为额外输入）
  → 产出回流到 MyJarvis 知识系统
  → 触发增量 compile（如果写了 raw/）
```

## 设计原则

1. **不改 ARIS skills 本身** — ARIS 是外部依赖，保持可独立升级
2. **context 注入在调用侧** — CC 组装 context 传给 skill，不是 skill 来读 MyJarvis
3. **产出回流遵循 MyJarvis 数据流** — 新数据进 raw/（L1）→ compile 进 wiki/（L2+）；project wiki 是例外（事实性信息直接更新）
4. **降级策略** — ARIS skill 不可用时，CC 自己做简化版（degrade, don't block）

## 集成操作

### 1. 文献调研

**触发词**: "调研"、"文献"、"related work"、"survey" + 研究主题

**Context 组装**:
```
1. wiki/knowledge/papers-index.md → 已有论文列表（避免重复搜索）
2. wiki/knowledge/papers-<topic>.md → 相关主题的已有综述
3. projects/<active>/wiki/INDEX.md → 当前项目目标（指导搜索方向）
4. wiki/rules/paper-reading/ → L3 论文阅读规则（指导筛选标准）
5. 如果有具体 project context → project wiki 的 constraints + decisions
```

**调用**: `/research-lit "<主题>"` + 组装的 context 作为前置说明

**产出回流**:
```
1. 每篇发现的论文 → raw/papers/<key>.md（reading notes 格式，frontmatter 含 source/tags/project）
2. 综述文档 → raw/papers/ 下的 survey note
3. 触发增量 compile:
   - 更新 wiki/knowledge/papers-index.md（新论文入目录）
   - 更新/创建 wiki/knowledge/papers-<topic>.md（主题综述）
   - 更新 cross-ref: 新论文 ↔ active projects
```

### 2. 新颖性验证

**触发词**: "查新"、"novelty check"、"有没有人做过"

**Context 组装**:
```
1. 待验证的 idea 全文（从 raw/ideas/ 或用户输入）
2. wiki/knowledge/papers-index.md → 已知论文（避免遗漏已读过的相关工作）
3. projects/<relevant>/wiki/INDEX.md → 项目背景
```

**调用**: `/novelty-check` + idea + context

**产出回流**:
```
1. novelty 结果追加到 raw/ideas/<idea>.md 的 ## Novelty check section
2. 如果发现高相关论文 → 同时走文献调研的回流路径
3. 更新 idea 状态（novel/partially-novel/not-novel）
```

### 3. Idea 发现

**触发词**: "找 idea"、"brainstorm"、"research ideas"、"有什么可以做的"

**Context 组装**:
```
1. wiki/context/active-projects.md → 当前在做什么（避免重复）
2. wiki/traits/ → L5 人格特质（生成匹配用户风格的 idea）
3. wiki/rules/research/ → L3 研究规则（指导 idea 质量标准）
4. raw/ideas/ 现有 idea 库 → 避免重复 + 可以在已有 idea 上延伸
5. wiki/knowledge/papers-<topic>.md → 已有文献理解（作为 idea 的知识基础）
```

**调用**: `/idea-discovery "<研究方向>"` + context

**产出回流**:
```
1. 每个 idea → raw/ideas/<idea-name>.md（MyJarvis idea frontmatter 格式）
2. 进入 MyJarvis idea management 流程：自动触发 enrich（Codex 知识关联 + 评分）
3. 发现的相关论文 → raw/papers/（同文献调研回流）
```

### 4. 审稿迭代

**触发词**: "审稿"、"review"、"帮我审一下" + 项目/论文 context

**Context 组装**:
```
1. projects/<project>/wiki/ 全量（INDEX, progress, constraints, decisions, architecture）
2. 相关 raw/papers/ reading notes（作为审稿的文献参考）
3. wiki/rules/paper-writing/ → L3 论文写作规则（作为额外审稿标准）
4. wiki/rules/research/ → L3 研究规则
5. 如果审的是 metric/方法设计 → project constraints.md 尤其重要
```

**调用**: `/auto-review-loop "<审稿目标>"` + context

**产出回流**:
```
1. 审稿记录 → raw/claude-sessions/YYYY-MM-DD-HHMM-review-<project>.md
2. 直接更新 project wiki:
   - decisions.md（审稿中做出的设计决策）
   - constraints.md（审稿发现的新约束）
   - backlog.md（审稿建议的后续工作）
3. AUTO_REVIEW.md 留在项目目录（ARIS 原生产出）
```

### 5. 论文写作

**触发词**: "写论文"、"paper"、"draft"、"开始写"

**Context 组装**:
```
1. projects/<project>/wiki/ 全量
2. 相关 raw/papers/ reading notes（作为引用素材 + 参考写法）
3. wiki/rules/paper-writing/ → L3 论文写作规则
4. wiki/rules/research/ → L3 研究规则
5. 实验结果（从 project repo 读取）
```

**调用**: `/paper-writing` pipeline（plan → figure → write → compile → improve）+ context

**产出回流**:
```
1. paper/ 目录留在项目 repo（ARIS 原生产出位置）
2. 直接更新 project wiki:
   - progress.md（论文写作进度）
   - decisions.md（写作中做出的 framing 决策）
3. 写作过程中的 rule signals → raw/claude-sessions/（将来可 distill）
```

### 6. 实验计划

**触发词**: "实验计划"、"experiment plan"、"怎么验证"

**Context 组装**:
```
1. projects/<project>/wiki/backlog.md → 现有待办
2. projects/<project>/wiki/constraints.md → 约束条件（时间、资源、数据）
3. projects/<project>/wiki/decisions.md → 已做决策（避免冲突）
4. wiki/rules/research/ → L3 研究规则
```

**调用**: `/experiment-plan` + context

**产出回流**:
```
1. EXPERIMENT_PLAN.md 留在项目 repo
2. 直接更新 project wiki:
   - backlog.md（实验任务拆解）
   - constraints.md（如果发现新约束）
```

## Context 组装原则

1. **相关性 > 完整性** — 不要 dump 整个 wiki/，只选跟当前操作相关的部分
2. **优先读 compiled knowledge** — wiki/ > raw/（遵循 info retrieval priority 规则）
3. **标注来源** — 注入的 context 标明出处，让 ARIS skill 知道哪些是用户已有知识、哪些是系统规则
4. **不超过 context 预算** — 每个操作的注入 context 控制在合理范围，避免淹没 ARIS skill 的核心指令

## 降级策略

| 场景 | 行为 |
|------|------|
| ARIS skill 不可用（未安装/报错） | CC 自己做简化版（如：文献调研退化为手动 arXiv 搜索 + 整理） |
| Context 组装失败（wiki/ 缺数据） | 跳过该 context 源，用已有的部分继续 |
| 产出回流失败（compile 报错） | 产出保留在 raw/，标记待处理，不阻塞 |

### 7. 支撑 Codex 审计

**触发词**: 无独立触发词。由 `docs/codex-audit.md` §5 "Literature-grounded review" 在 Codex 审计流程内部调用。

**场景**: Codex 审计涉及 novelty claim 或 related work 完备性时，CC 用 /arxiv 和 /semantic-scholar 搜索相关论文，注入 Codex prompt 作为 verified evidence。审计完成后，CC 验证 Codex 额外引用的论文。

**Context 组装**:
```
1. 审计目标中的关键词（如研究主题、方法名、任务名）→ 提取 2-3 组查询
2. wiki/knowledge/papers-index.md → 已有论文列表（避免重复搜索已收录的）
3. 搜索结果按相关性筛选 top 5 篇
```

**调用**: CC 直接调用 /arxiv 和 /semantic-scholar skills，不通过用户触发

**产出回流**:
```
不回流。审计路径的论文仅作为 Codex prompt 的 ephemeral context，不入库 raw/papers/。
如果用户认为审计中发现的某篇论文值得收录，走正常的文献调研回流路径（§1）。
```

**与 §1-§6 的区别**:
- §1-§6 是用户触发的独立操作，产出回流到 MyJarvis 知识系统
- §7 是 Codex 审计流程的内部支撑，产出不回流，仅服务于当次审计质量

## 与 ARIS research-wiki 的关系

暂不合并两套知识系统。通过回流机制间接同步：
- ARIS 产出 → 回流到 MyJarvis raw/ → compile 到 wiki/
- MyJarvis wiki/ → 通过 context 注入喂给 ARIS skills

未来如果需要合并，可考虑让 ARIS research-wiki 的存储后端指向 MyJarvis 的 wiki/knowledge/。
