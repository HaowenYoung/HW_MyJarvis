# Notion Sync Rules

## Structure

```
📂 Agent System Hub
├── 📊 Daily Log (database)          ← one-way: fs → Notion
├── 📊 Patterns (database)           ← one-way
├── 📊 Rules (database)              ← one-way (L3 + L4)
├── 📊 Events (database)             ← BIDIRECTIONAL
├── 📄 Today's Plan                  ← BIDIRECTIONAL
├── 📄 Personal Profile              ← one-way
├── 📄 Traits & Values               ← one-way
├── 📂 Projects                      ← one-way
├── 📂 Reviews                       ← one-way
└── 📄 Meta / Governance             ← one-way
```

## Sync zones

**Zone A: Knowledge (one-way fs → Notion)**: Patterns, Rules, Policies, Traits, Values, Project wikis, Reviews, Profile, Meta. User should NOT edit in Notion.

**Zone B: Assistant (bidirectional)**: Today's Plan, Events, Daily Log notes, Scratch notes. Read back at plan generation and wrap-up.

## Database schemas

**Daily Log**: Date, Summary (title), Tasks Done, Tasks Total, Key Outcomes, Blockers, Energy (High/Med/Low)

**Patterns**: Pattern (title), Category, Observations, Confidence, Status, First Seen

**Rules** (L3 + L4):

| Property | Type |
|----------|------|
| Rule | Title |
| Level | Select: L3-rule / L4-policy |
| Category | Select: scheduling/estimation/priority/verification/workflow |
| Source Pattern | Relation → Patterns |
| Violation Count | Number |
| Status | Select: active/provisional/under-review/retired |
| Created | Date |
| Last Applied | Date |

**Events**: Event (title), Date, Time, Type, Location, Duration, Status, Notes, Reminder Date, Preparation Tasks

## Today's Plan sync protocol

Template page: `$NOTION_DAILY_PLAN_TEMPLATE_PAGE_ID` (📋 Daily Plan Template under Agent System Hub)

**Plan generation sync (Step 3d)**:
1. Fetch template page → 获取骨架结构
2. `replace_content` Today's Plan page (`$NOTION_TODAYS_PLAN_PAGE_ID`)，用 template 结构填充当天内容
3. Work tasks 必须用 checkbox 格式（`- [ ]`），这是 Zone B 双向同步的基础——用户在 Notion 勾选后 wrap-up 读回

**格式规范**:
- 标题: `# Daily Plan: YYYY-MM-DD (Day)`
- Work tasks: `- [ ] **HH:MM–HH:MM** 任务名 — 描述 \`type est\``
- Fixed events: `- **HH:MM–HH:MM** 事件名（protected）`
- Rules applied: `- **L{N}/{rule-name}**: 如何应用`
- Success criteria: 编号列表，末尾 ✓/✗

**Wrap-up sync (Step 5e)**:
1. Fetch Today's Plan → 读取 checkbox 状态
2. 追加 Actually done / Retrospective 段落（如有）

## Notion page IDs

> IDs are loaded from `tools/notion-ids.env`. Template placeholders below.

| Page | Env var | Type |
|------|---------|------|
| Agent System Hub | `$NOTION_HUB_PAGE_ID` | parent |
| Today's Plan | `$NOTION_TODAYS_PLAN_PAGE_ID` | Zone B |
| Daily Plan Template | `$NOTION_DAILY_PLAN_TEMPLATE_PAGE_ID` | template |
| Personal Profile | `$NOTION_PERSONAL_PROFILE_PAGE_ID` | Zone A |
| Projects | `$NOTION_PROJECTS_PAGE_ID` | Zone A |
| Reviews | `$NOTION_REVIEWS_PAGE_ID` | Zone A |
| Meta / Governance | `$NOTION_META_PAGE_ID` | Zone A |
| Daily Log (data source) | `collection://$NOTION_DAILY_LOG_DB_ID` | Zone A |
| Patterns (data source) | `collection://$NOTION_PATTERNS_DB_ID` | Zone A |
| Rules (data source) | `collection://$NOTION_RULES_DB_ID` | Zone A |

## Sync checklist (wrap-up)

**每次 wrap-up 必须同步全部 Zone A 页面，不只 plan。**

1. **Daily Log database**: create/update entry (date, summary, tasks done/total, key outcomes, blockers, energy)
2. **Today's Plan page**: checkbox states + Actually done / Retrospective
3. **Projects page**: 从 `wiki/context/active-projects.md` + `projects/*/wiki/` 同步最新进度
4. **Personal Profile**: 从 `wiki/context/personal-profile.md` 同步（如有变化）
5. **Meta/Governance**: 从 `wiki/meta/governance.md` 同步（如有变化）
6. **Patterns database**: 从 `wiki/memory/` 同步（如 compile/distill 产生新条目）
7. **Rules database**: 从 `wiki/rules/` + `wiki/policies/` 同步；更新 Last Applied
8. **Reviews**: 从 `wiki/reviews/` 同步（如有）

**Compile 后同步**: 至少同步 3 (Projects) + 6 (Patterns) + 7 (Rules)。
**Distill 后同步**: 至少同步 6 (Patterns) + 7 (Rules)。
