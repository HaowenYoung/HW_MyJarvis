#!/usr/bin/env bash
# compile.sh — 两阶段编译：llm-wiki-compiler + agent 层 pattern 提取
#
# Phase 1: 调用 /wiki-compile（llm-wiki-compiler plugin）
#          raw/ → wiki/topics/（通用主题编译）
#
# Phase 2: Agent 层增量编译
#          raw/ → wiki/memory/（pattern 提取）
#          wiki/memory/ → 更新 wiki/INDEX.md
#
# Usage:
#   ./tools/compile.sh           # 增量编译
#   ./tools/compile.sh --full    # 全量重编译
#   ./tools/compile.sh --skip-wiki-compile  # 只跑 agent 层

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

FULL_FLAG=""
SKIP_WIKI_COMPILE=false

for arg in "$@"; do
  case $arg in
    --full) FULL_FLAG="--full" ;;
    --skip-wiki-compile) SKIP_WIKI_COMPILE=true ;;
  esac
done

echo "=== Compile: Phase 1 — Wiki Topic Compilation ==="

if [[ "$SKIP_WIKI_COMPILE" == false ]]; then
  echo "Running: claude --plugin-dir .wiki-compiler/plugin -p \"/wiki-compile $FULL_FLAG\""
  echo ""
  echo "This invokes llm-wiki-compiler to compile raw/ → wiki/topics/"
  echo "Output: wiki/topics/*.md, wiki/schema.md, wiki/.compile-state.json"
  echo ""
  claude --plugin-dir .wiki-compiler/plugin -p "/wiki-compile $FULL_FLAG"
else
  echo "(Skipped — --skip-wiki-compile flag set)"
fi

echo ""
echo "=== Compile: Phase 2 — Agent Layer Pattern Extraction ==="
echo ""
echo "Running: claude -p with compile prompt..."
echo ""

claude -p "$(cat <<'PROMPT'
你是 Personal Agent System 的编译引擎。执行 Phase 2 编译：

1. 读取 raw/daily/ 中最近 7 天的条目
2. 读取 wiki/memory/ 中现有的 pattern 页面
3. 对比分析：
   - 在 raw/ 中出现 3+ 次的行为模式 → 创建或更新 wiki/memory/ 页面
   - 每个 pattern 页面包含：描述、观测列表（带日期和 raw/ 引用）、置信度、category
4. 更新 wiki/context/active-projects.md（如果项目状态有变化）
5. 重建 wiki/INDEX.md 的 Memory (Patterns) 表格
6. 不要修改 raw/ 下的任何文件

输出编译报告：新增/更新了哪些 patterns，扫描了多少条目。
PROMPT
)"

echo ""
echo "=== Compile complete ==="
echo "Run 'git add -A && git commit' to save changes."
