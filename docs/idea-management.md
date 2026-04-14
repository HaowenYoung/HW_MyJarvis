# Idea management module

## Overview

Ideas 有独立的生命周期，不混在 scratch notes 里。
从随手捕获到最终落地（或归档），全程有知识关联、可信度追踪、行动计划。

## Data structure

raw/ideas/                  # 独立目录，不在 scratch/ 里
  idea-YYYY-MM-DD-HHMM-<slug>.md

## Idea frontmatter

```yaml
source: session | feishu | paper-reading | repo-exploration | manual
created: YYYY-MM-DDTHH:MM:SS
status: seed | exploring | validated | promoted | archived
domain: research | engineering | paper | personal

credibility:
  novelty: 0.0-1.0         # 想法新颖度（vs 已有工作）
  feasibility: 0.0-1.0     # 以当前能力/资源的可行性
  relevance: 0.0-1.0       # 跟当前研究方向/项目的相关度
  overall: 0.0-1.0         # 加权平均 (novelty*0.3 + feasibility*0.3 + relevance*0.4)

related_papers: []
related_projects: []
related_repos: []
related_ideas: []

next_action: "具体下一步做什么"
action_type: literature-search | prototype | discuss-with-advisor | write-proposal | experiment | read-paper | explore-repo
action_deadline: YYYY-MM-DD
```

## Idea body sections

```markdown
# <Idea title>

## Idea
（原始想法，保持用户原话，不改写）

## Knowledge context (Codex enrichment)
### 相关论文
（每篇标注：跟这个 idea 具体什么关系，支持/矛盾/互补/可借鉴）
### 相关项目
（你的哪个项目跟这个 idea 相关，具体在哪个环节）
### 相关 repos
（如果有探索过的 repo 跟这个 idea 相关）
### 相关 ideas
（之前的 idea 跟这个有关联吗？是互补还是同主题？）

## Credibility rationale
### Novelty (score)
（为什么这么打分：有没有类似工作？如果有，你的差异点在哪？）
### Feasibility (score)
（为什么这么打分：需要什么资源/技能？你有没有？缺什么？）
### Relevance (score)
（为什么这么打分：跟你当前方向有多近？是核心还是边缘？）

## Action plan
1. <具体行动> (<action_type>, by <deadline>)
2. <下一步，如果上一步结果 positive>
3. ...

## Evolution log
- YYYY-MM-DD: <事件>. <credibility 变化>.
```

## Idea lifecycle stages

### Stage 1: Capture（即时）

触发方式：
  a) Claude Code session 中用户说了一个 idea → CC 直接写入 raw/ideas/
  b) 飞书发消息 → llm-route.sh 分类为 idea → escalate to Codex
  c) Paper reading session 中产生联想 → session-end 提取
  d) Repo exploration 中产生联想 → session-end 提取
  e) 用户在 Notion Ideas database 手动添加 → 下次 session 回传

无论哪种触发方式，都进入 Stage 2。

### Stage 2: Enrich（Codex，捕获时立即执行）

Codex 读 idea 内容后执行：

2a) Knowledge linking：
  - 读 wiki/knowledge/papers-index.md → 找 topic 相关的论文
  - 读 wiki/context/active-projects.md → 找相关项目
  - 读 wiki/knowledge/repos-index.md → 找相关 repos
  - 读 raw/ideas/ 其他 ideas → 找关联 ideas
  写入 frontmatter 的 related_* 字段和 ## Knowledge context section

2b) Credibility scoring：
  - Novelty: 读 related papers，判断这个 idea 的核心贡献是否已有人做过
    没有类似工作 → 高分；有类似但角度不同 → 中分；已有高度相似工作 → 低分
  - Feasibility: 读 personal-profile.md 和 active-projects.md，
    判断用户的技能、资源、时间是否支持
    能直接做 → 高分；需要学新东西但可行 → 中分；需要大量资源 → 低分
  - Relevance: 判断 idea 跟用户当前研究方向和活跃项目的距离
    核心方向 → 高分；相关但不是核心 → 中分；完全不同领域 → 低分
  写入 credibility 字段和 ## Credibility rationale section

2c) Action plan：
  基于 idea 内容和 credibility，建议 1-3 个后续行动步骤
  每步标注 action_type 和建议 deadline
  写入 ## Action plan section 和 frontmatter 的 next_action

2d) 初始 evolution log entry

### Stage 3: Incubate（被动，在 compile/distill 中触发）

每次 compile 时，检查所有 status=seed|exploring 的 ideas：

3a) 新论文 ingest → 跟所有 active ideas 做 cross-ref：
  - 新论文跟某个 idea 高度相关？
    → 更新 idea 的 related_papers
    → 重新评估 novelty（别人是不是也在做了？）
    → 重新评估 feasibility（新论文的方法能不能借鉴？）
    → 在 evolution log 追加记录
    → 如果 credibility 显著变化 → 飞书推送通知用户

3b) 新 idea ingest → 跟所有现有 ideas 做关联检测：
  - 两个 idea 是同一个主题的不同角度？→ 互相链接
  - 新 idea 是旧 idea 的特化/泛化？→ 标注关系
  - 多个 seed ideas 汇聚到同一个方向？→ 提示用户可能值得推进

3c) 项目进展 → 更新相关 idea 的 feasibility：
  - 某个项目里你学了新技能 → 某个之前 feasibility 低的 idea 变可行了
  - 某个项目做完了 → 你有精力推进新 idea 了

### Stage 4: Promote or Archive（用户决定）

Promote（idea → project）：
  用户说 "把这个 idea 推进为正式项目" 或在 Notion 改 status 为 promoted
  → 在 projects/ 下创建新项目目录
  → idea 的 knowledge context 成为项目 wiki 的 seed 内容
  → idea 的 action plan 成为项目 backlog 的初始 items
  → idea status 改为 promoted，链接到新项目

Archive：
  idea 被证伪 / 别人已经做了 / 不感兴趣了
  → status 改为 archived
  → 保留在 raw/ideas/ 但不再参与 incubation
  → archive 原因记录在 evolution log

## Notion Ideas database (Zone B+, bidirectional)

在 Agent System Hub 下新增 📊 Ideas database：

| Property | Type | 说明 |
|----------|------|------|
| Idea | Title | 想法标题 |
| Status | Select: seed/exploring/validated/promoted/archived | 生命阶段 |
| Domain | Select: research/engineering/paper/personal | 领域 |
| Credibility | Number (0-1) | overall 分数 |
| Novelty | Number (0-1) | |
| Feasibility | Number (0-1) | |
| Relevance | Number (0-1) | |
| Next action | Rich text | 下一步做什么 |
| Action deadline | Date | |
| Related projects | Rich text | 关联项目名 |
| Related papers | Rich text | 关联论文 cite_key |
| Related ideas | Relation → Ideas | 关联的其他 ideas |
| Source | Select: session/feishu/paper-reading/repo-exploration/manual | |
| Created | Date | |
| Notes | Rich text | 用户手动补充的备注 |

这是 Zone B+：
  - 你可以在 Notion 上改 status（seed → exploring）
  - 你可以调 credibility 分数（覆盖 Codex 的判断）
  - 你可以加 notes
  - 你可以手动创建新 idea
  - 所有修改在下次 session/compile 时回传到 raw/ideas/

### Notion 展示优化

Ideas database 建议创建多个 view：

1. **Active ideas** (default view)
   Filter: status ≠ archived, status ≠ promoted
   Sort: credibility overall 降序
   → 最有价值的 idea 排最前面

2. **By domain**
   Group by: domain
   → 看你各领域的 idea 分布

3. **Needs action**
   Filter: action_deadline <= 一周内
   Sort: action_deadline 升序
   → 该行动的 idea

4. **Idea graph**（Notion Relation 可视化）
   通过 Related ideas 字段看 idea 之间的网络

## Plan generation integration

plan generation 时也扫描 ideas：
  - 有 action_deadline 在今天或过期的 idea → 排入 daily plan
    "Review idea: meta-memory eval — next action: literature search (overdue by 2 days)"
  - 有 credibility 显著变化的 idea → 排入 plan 的 alerts 区

## Quick commands

在 Claude Code session 里：
  "记个 idea: <内容>" → 创建 idea + Codex enrich + Notion sync
  "看看我的 ideas" → cat raw/ideas/ 列出所有 active ideas 的标题和 credibility
  "推进 <idea slug>" → 把 idea promote 为 project

在飞书里：
  自然语言发 idea → 飞书 bot 识别 intent=idea → escalate to Codex → 完整 enrich 流程
  /ideas → 返回 active ideas 列表 + credibility 排序
