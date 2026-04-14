#!/usr/bin/env bash
# distill.sh — Pattern → Rule 提升
#
# 扫描 wiki/memory/ 中的 patterns，找出满足提升条件的候选，
# 逐个展示给用户审批（acc/rej/edit）。
#
# Usage:
#   ./tools/distill.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "=== Distill: Pattern → Rule Promotion ==="
echo ""

claude -p "$(cat <<'PROMPT'
你是 Personal Agent System 的 distill 引擎。执行 pattern → rule 提升流程：

## 提升候选扫描

1. 读取 wiki/memory/ 中所有 pattern 页面
2. 找出满足提升条件的候选：
   - 5+ 次观测
   - 观测跨越 3+ 天
   - 无内部矛盾
3. 排除已标记为 "rejected-for-promotion" 的 patterns

## 逐个审批

对每个候选，展示：
- **候选规则文本**（从 pattern 提炼出简洁的规则表述）
- **支撑证据**：列出所有观测（日期 + raw/ 引用）
- **建议 category**：scheduling / estimation / priority / workflow
- **影响评估**：这条规则会如何影响未来的 plan generation

等待用户回复：
- `acc` → 创建 wiki/rules/{category}-rules.md 中的条目（或追加到已有文件）
- `rej [reason]` → 在 pattern 页面标记 "rejected-for-promotion"，记录 raw/feedback/
- `edit [text]` → 按用户修改后创建规则

## 现有规则检查

同时检查 wiki/rules/ 中的现有 active rules：
- 2 周内违反 5+ 次 → 提议废除或修改
- 4 周未被引用/应用 → 提议标记 stale

## 输出

每处变更后：
- 更新 wiki/INDEX.md 的 Rules 表格
- 记录到 raw/feedback/ 中
PROMPT
)"

echo ""
echo "Distill complete."
