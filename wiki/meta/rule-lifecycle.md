# Rule Lifecycle

> 定义 6 层规则体系的完整生命周期。

## Sources

- CLAUDE.md §Rule hierarchy, §Distillation pipeline

## 层级概览

```
L1  Observations     raw/daily/, raw/feedback/       "What happened?"
L2  Patterns         wiki/memory/                     "What keeps happening?"
L3  Domain rules     wiki/rules/                      "What to do in this task type?"
L4  Policies         wiki/policies/                   "What to do across all similar tasks?"
L5  Traits           wiki/traits/                     "What kind of person is the user?"
L6  Values           wiki/values/                     "What does the user fundamentally prioritize?"
```

## 提升条件（Bottom-up induction）

### L1 → L2 (Observations → Patterns)

- **阈值**: raw/ 中出现 **3+ 次**独立观测
- **时间跨度**: 观测跨越至少 **3 天**
- **一致性**: 观测之间无矛盾
- **频率**: 每次 compile 自动检测

### L2 → L3 (Patterns → Domain rules)

- **阈值**: **5+ 次**观测
- **审批**: 用户 acc/rej/edit
- **频率**: Weekly distill（Sunday 20:00）

### L3 → L4 (Domain rules → Policies)

- **条件**: 多个 L3 rules 跨不同 task types 表现出共性
- **审批**: 用户 acc/rej/edit
- **频率**: Monthly distill（每月 1 日 20:00）
- **提升后**: 原 L3 rules 标记 retired（已被 L4 覆盖）

### L4 → L5 (Policies → Traits)

- **条件**: 多个 L4 policies 指向同一个人格特征
- **审批**: 用户 acc/rej/edit
- **频率**: Quarterly review

### L5 → L6 (Traits → Values)

- **条件**: 用户显式反思 或 重大生活阶段变化
- **频率**: Rare

## 推导条件（Top-down deduction）

```
New task with no L3 rule?
  → Check L4 policies → applicable? → Apply, create provisional L3
  → No L4 either? → Check L5 traits → deduce provisional L4 + L3
  → Mark status: provisional, present to user
  → User confirms → permanent
```

## 退休条件

| 层级 | 条件 | 触发 |
|------|------|------|
| L3 | 高违反率 | 2 周内违反 **5+ 次** → under-review |
| L3 | 长期未触发 | **4 周**无应用记录 → potentially-stale |
| L3 | 被 L4 覆盖 | 提升为 L4 policy 后 → retired |
| L4 | 高违反率 | 1 月内违反 **5+ 次** → under-review |
| L4 | 长期未触发 | **8 周**无应用 → potentially-stale |
| L5 | 用户显式废除 | retired |
| L6 | 用户显式废除 | retired |
| All | 用户显式废除 | 任何层级均可由用户直接 retire |

## 状态机

```
[pattern 3+ obs] → [rule candidate] → acc/rej/edit
                                          |
                        [active L3] ← acc/edit
                            |
              violation / stale / promoted-to-L4
                            |
                      [under-review / retired]

[multiple L3 rules] → [L4 candidate] → acc → [active L4]
[multiple L4 policies] → [L5 candidate] → acc → [active L5]
[L5 traits aggregate] → [L6 candidate] → acc → [active L6]
```

## Page format

Every rule/policy/trait/value page:
```yaml
---
level: L3 | L4 | L5 | L6
status: active | provisional | under-review | retired
created: YYYY-MM-DD
last_applied: YYYY-MM-DD | null
violation_count: 0
source: induced | deduced | user-set
category: ...  # L3/L4 only
---
```

Sections: Statement, Rationale, Sources, Exceptions, Application log.

## Review 周期

- **Weekly**: compile + lint + L2→L3 distill
- **Monthly**: L3→L4 policy review (1st of month)
- **Quarterly**: L4→L5 trait review
- **Annual/Rare**: L5→L6 value review
