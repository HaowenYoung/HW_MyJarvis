#!/usr/bin/env bash
# lint.sh — Wiki 健康检查
#
# 两阶段 lint：
#   Phase 1: llm-wiki-compiler /wiki-lint（topics 健康检查）
#   Phase 2: Agent 层自定义检查（rules 违反、orphan patterns 等）
#
# Usage:
#   ./tools/lint.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

WEEK=$(date +%Y-W%V)
REPORT_FILE="wiki/reviews/lint-$WEEK.md"

echo "=== Lint: Phase 1 — Wiki Topic Health Check ==="
echo ""

claude --plugin-dir .wiki-compiler/plugin -p "/wiki-lint"

echo ""
echo "=== Lint: Phase 2 — Agent Layer Health Check ==="
echo ""

claude -p "$(cat <<PROMPT
你是 Personal Agent System 的 lint 引擎。执行 Agent 层健康检查：

1. **规则违反检查**：扫描 raw/daily/ 最近 2 周，对照 wiki/rules/ 中的 active rules，找出违反情况。更新每条 rule 的 violation count。

2. **Pattern 陈旧检查**：检查 wiki/memory/ 中的 patterns，找出：
   - 最近 4 周无新观测的 pattern → 标记 potentially-stale
   - 与近期 raw/ 数据矛盾的 pattern → 标记 needs-update

3. **Orphan 页面检查**：
   - wiki/ 下没有被 INDEX.md 引用的页面
   - wiki/ 下引用了不存在的 raw/ 文件的页面

4. **INDEX 完整性**：检查 wiki/INDEX.md 是否反映了所有 wiki/ 子目录中的页面

5. **Rule 退休候选**：
   - 2 周内违反 5+ 次 → 标记 under-review
   - 4 周未触发 → 标记 potentially-stale

输出报告到 $REPORT_FILE，格式：

# Lint Report: $WEEK

## Summary
| Check | Issues Found |
|-------|-------------|
| Rule Violations | N |
| Stale Patterns | N |
| Orphan Pages | N |
| INDEX Gaps | N |
| Rule Retirement Candidates | N |

## Details
（每个 check 的详细发现和建议修复）

## Recommended Actions
（按优先级排序的修复建议）
PROMPT
)"

echo ""
echo "Lint report: $REPORT_FILE"
