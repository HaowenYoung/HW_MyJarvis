#!/usr/bin/env bash
# plan.sh — 生成每日计划
#
# 读取 wiki/ 上下文 + raw/ 近期数据，生成 wiki/plans/YYYY-MM-DD.md
# 然后进入 review 循环：用户 acc/rej/edit
#
# Usage:
#   ./tools/plan.sh              # 生成今天的计划
#   ./tools/plan.sh 2026-04-07   # 生成指定日期的计划

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

TARGET_DATE="${1:-$(date +%Y-%m-%d)}"
PLAN_FILE="wiki/plans/$TARGET_DATE.md"

echo "=== Plan Generation: $TARGET_DATE ==="
echo "Output: $PLAN_FILE"
echo ""

claude -p "$(cat <<PROMPT
你是 Personal Agent System 的计划引擎。为 $TARGET_DATE 生成每日计划。

读取以下输入：
1. wiki/INDEX.md — 知识库总览
2. wiki/rules/scheduling-rules.md — 排程约束（如果存在）
3. wiki/rules/priority-rules.md — 优先级逻辑（如果存在）
4. wiki/rules/estimation-rules.md — 时间估算调整（如果存在）
5. wiki/context/active-projects.md — 活跃项目
6. wiki/context/personal-profile.md — 个人偏好和约束
7. projects/*/wiki/INDEX.md — 各项目状态和 backlog（如果存在）
8. raw/daily/ 最近 3 天 — 近期动量
9. wiki/memory/time-patterns.md — 时间模式（如果存在）
10. raw/feedback/ 最近 5 条 — 偏好信号（如果存在）

输出计划到 $PLAN_FILE，格式：

# Daily Plan: $TARGET_DATE

## Context
简述近况、待办、carry-over。

## Proposed Tasks
1. [ ] **Task A** (Project X, type, ~Xh adjusted) — 理由
2. [ ] **Task B** ...

## Alternatives Considered
- Task D 被推迟因为 [原因]

## Rules Applied
- 引用了哪些 rules 及其影响

---

如果 wiki/rules/ 下还没有规则，在 Rules Applied 中注明 "No rules established yet — using defaults"。
PROMPT
)"

echo ""
echo "Plan generated at $PLAN_FILE"
echo ""
echo "Review the plan and respond:"
echo "  acc          — accept as-is"
echo "  rej [reason] — reject with reason"
echo "  edit [changes] — accept with modifications"
