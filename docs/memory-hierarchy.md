# Memory Hierarchy — L1-L6 Rule System

## Layer overview

```
L1  Observations     raw/daily/, raw/feedback/       "What happened?"
L2  Patterns         wiki/memory/                     "What keeps happening?"
L3  Domain rules     wiki/rules/                      "What to do in this task type?"
L4  Policies         wiki/policies/                   "What to do across all similar tasks?"
L5  Traits           wiki/traits/                     "What kind of person is the user?"
L6  Values           wiki/values/                     "What does the user fundamentally prioritize?"
```

## Layer functions

**L3 Domain rules** — Prescribe specific actions for a specific task type.
- Scope: one task type (e.g. "dataset building", "code review", "paper writing")
- Updated: weekly, from L2 patterns with 5+ observations
- **Organized by domain**: `wiki/rules/{engineering,code-reading,paper-reading,paper-writing,personal,research}/`
- Frontmatter includes `domain:` field matching directory name

**L4 Cross-domain policies** — Generalize rules across task types.
- Scope: all tasks sharing a trait
- Updated: monthly, by finding commonality across multiple L3 rules
- **Not organized by domain** (cross-domain by definition)
- Frontmatter includes `applies_to:` field listing applicable domains
- Function: when a new L3 rule is created, check if it's an instance of an existing L4 policy

**L5 Personal traits** — Model the user as a person. Enable deduction to new domains.
- Updated: quarterly, by abstracting across L4 policies. Count: 3-7 traits
- Function: **deductive generator**. New task type with no L3 rule → read L5 traits → deduce provisional rule

**L6 Life philosophy** — Resolve conflicts between lower layers.
- Updated: rarely (life-phase transitions only). Count: 1-3 statements
- Function: **arbiter**. When two L4 policies conflict, L6 breaks the tie

## Distillation pipeline (bottom-up)

```
L1 → L2    Every compile: extract patterns from raw/ (3+ observations)
L2 → L3    Weekly distill: by domain. paper-reading patterns → paper-reading rules only.
L3 → L4    Monthly review: first find commonality within each domain, then across domains.
L4 → L5    Quarterly review: abstract across policies → trait candidates → user acc/rej
L5 → L6    Rare: only when user explicitly reflects on fundamental values
```

## User correction fast-track

用户纠正是已经结晶的知识，不需要从 L1 开始统计积累。

**问题**: Claude memory feedback 即时生效后，行为被纠正 → 不再产生新的 L1 观察 → 永远达不到升级阈值 → L1-L6 管道被架空。

**机制: 写时双写**

写 Claude memory (type: feedback) 时，同步写入 wiki/ 对应层级：

```
用户纠正 → Claude memory（即时行为修正，跨 session）
        → 评估纠正的层级：
          - 特定领域操作规则 → wiki/rules/<domain>/  (L3)
          - 跨领域偏好/策略 → wiki/policies/         (L4)
          - 人格特质描述    → wiki/traits/            (L5)
        → 写入 wiki/ 对应位置
          - source: user-correction（区别于 induced / deduced）
          - status: active（用户亲自说的，不需要 provisional）
          - 不需要满足观察次数要求
```

**后续蒸馏正常参与**:
- L3 user-correction rules 跟 induced rules 一样参与 L3→L4 月度蒸馏
- 审计机制同样适用（violated 5+/2w → flag; 4w no trigger → stale）

**与底层积累路径的关系**:
- 底层路径（L1→L2→L3 统计积累）对非用户纠正的被动观察仍然有效
- 两条路径互补：被动观察靠统计显著性，用户纠正靠直接注入
- 如果某条 user-correction rule 后来又被底层观察独立发现，视为交叉验证（更可信）

## Deduction pipeline (top-down)

```
New task with no L3 rule?
  → Check L4 policies: applicable policy exists? → Apply it, create provisional L3
  → No L4 either? → Check L5 traits: deduce provisional L4 + L3
  → Place provisional rule in the matching domain directory
  → Mark status: provisional, present to user for confirmation
  → Confirmed provisional rules become permanent
```

## Rule page format

```yaml
---
level: L3 | L4 | L5 | L6
domain: engineering | code-reading | paper-reading | paper-writing | research | personal  # L3 only
applies_to: [domain1, domain2]  # L4 only
status: active | provisional | under-review | retired
created: 2026-04-06
last_applied: 2026-04-06
violation_count: 0
source: induced | deduced | user-set
---

# Rule title

## Statement
## Rationale
## Sources
## Exceptions
## Application log
```

## Cross-referencing rule

During compile, build bidirectional links between papers and projects:
1. Read paper's abstract, notes, tags
2. Read project's INDEX.md goals
3. Determine relevance by **topic overlap**, not keyword matching
4. If relevant, add bidirectional links in both places

Cross-references also apply between: projects↔projects, papers↔patterns/rules, blogs↔projects.
Rebuilt on full compile, updated incrementally on partial compiles.
