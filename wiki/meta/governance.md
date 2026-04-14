# Governance — Meta-Rules 宪法

> 系统的最高级规则。所有其他 rules 和操作必须遵守。

## Sources

- CLAUDE.md §Constraints, §Rule hierarchy

## 核心原则

### 1. ��件系统是 Source of Truth（Zone A）

- Zone A（Knowledge）：文件系统 → Notion，单向同步
- Zone B（Assistant）：Today's Plan, Events, Daily Log notes, Scratch — 双向同步
- 冲突时，文件系统胜出

### 2. Raw 数据不可变

- `raw/` 下的文件创建后永不修改、永不删除
- 所有修正通过追加新条目实现
- 版本控制由 git 提供

### 3. Wiki 由 LLM 维护

- `wiki/` 下的内容由 Claude 编写和维护
- 用户通过 review（acc/rej/edit）间接控制内容

### 4. 6 层规则体系

- L2 Patterns → L3 Domain rules → L4 Policies → L5 Traits → L6 Values
- 每层有明确的提升条件、审批要求、退休条件
- 高层 resolve 低层冲突（L6 > L5 > L4 > L3）
- User-set rules 在同层级优先于 auto-generated

### 5. 人类保持最终决策权

- 所有层级的提升/推导均需人工审批
- Provisional rules（由 L5 推导）必须经用户确认才能永久化
- Governance 修改必须经人工审批
- 系统永远不自动执行不可逆操作

### 6. 可追溯性

- 每个 wiki 页面必须包含 `## Sources`
- 每个 plan 必须引用所用的 rules（含层级）
- 每个 rule 必须链接回源 patterns 或上层来源
- Cross-references 在 papers ↔ projects 之间保持

### 7. Cross-referencing

- 编译时建立 papers ↔ projects 双向链接
- 基于 topic overlap 判断相关性，非关键词匹配
- 全量 compile 时重建，增量 compile 时更新

## 数据格式规范

- 时间戳：ISO 8601
- 文件名：`YYYY-MM-DD`
- 链接：Markdown `[text](path)`
- 用户面内容：中文优先
- 系统/代码/文件名：英文

## 修改本宪法的条件

1. 必须由用户显式提出
2. 修改前展示当前条款和修改建议
3. 用户 `acc` 后生效
4. 变更记录到 `raw/feedback/` 注明 "governance-change"
5. 每月 governance review 时回顾
