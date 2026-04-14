#!/usr/bin/env bash
# sync-to-notion.sh — 将 wiki/ 内容同步到 Notion browse layer
#
# Usage:
#   ./tools/sync-to-notion.sh              # 同步所有变更
#   ./tools/sync-to-notion.sh daily        # 只同步今日 daily log
#   ./tools/sync-to-notion.sh plan         # 只同步今日 plan
#   ./tools/sync-to-notion.sh patterns     # 只同步 patterns
#   ./tools/sync-to-notion.sh rules        # 只同步 rules
#   ./tools/sync-to-notion.sh review       # 只同步最新 review
#
# Prerequisites:
#   - Notion MCP 已连接
#   - tools/notion-ids.env 已配置（database/page IDs）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

NOTION_IDS_FILE="$SCRIPT_DIR/notion-ids.env"
SYNC_TARGET="${1:-all}"
TODAY=$(date +%Y-%m-%d)

if [[ ! -f "$NOTION_IDS_FILE" ]]; then
  echo "Error: $NOTION_IDS_FILE not found."
  echo "Run Phase 1 Step 2 (Notion setup) first to create it."
  echo ""
  echo "Expected format:"
  echo "  NOTION_HUB_PAGE_ID=xxx"
  echo "  NOTION_DAILY_LOG_DB_ID=xxx"
  echo "  NOTION_PATTERNS_DB_ID=xxx"
  echo "  NOTION_RULES_DB_ID=xxx"
  echo "  NOTION_TODAYS_PLAN_PAGE_ID=xxx"
  echo "  NOTION_PROJECTS_PAGE_ID=xxx"
  echo "  NOTION_REVIEWS_PAGE_ID=xxx"
  exit 1
fi

# shellcheck source=/dev/null
source "$NOTION_IDS_FILE"

echo "=== Sync to Notion: $SYNC_TARGET ==="
echo ""

claude -p "$(cat <<PROMPT
你是 Personal Agent System 的 Notion 同步引擎。

已加载 Notion IDs：
- Hub Page: ${NOTION_HUB_PAGE_ID:-未配置}
- Daily Log DB: ${NOTION_DAILY_LOG_DB_ID:-未配置}
- Patterns DB: ${NOTION_PATTERNS_DB_ID:-未配置}
- Rules DB: ${NOTION_RULES_DB_ID:-未配置}
- Today's Plan Page: ${NOTION_TODAYS_PLAN_PAGE_ID:-未配置}
- Projects Page: ${NOTION_PROJECTS_PAGE_ID:-未配置}
- Reviews Page: ${NOTION_REVIEWS_PAGE_ID:-未配置}

同步目标: $SYNC_TARGET

执行同步（使用 Notion MCP tools）：

### 如果 target=all 或 daily:
- 读取 raw/daily/$TODAY.md
- Upsert 到 Daily Log database（key: date=$TODAY）
- Properties: Date, Summary（从内容提取一句话总结）, Tasks Done, Tasks Total, Key Outcomes, Energy

### 如果 target=all 或 plan:
- 读取 wiki/plans/$TODAY.md（如果存在）
- 覆写 Today's Plan page 内容

### 如果 target=all 或 patterns:
- 读取 wiki/memory/ 中所有 pattern 文件
- 对每个 pattern，upsert 到 Patterns database（key: pattern name）
- Properties: Pattern, Category, Observations, Confidence, Status, First Seen

### 如果 target=all 或 rules:
- 读取 wiki/rules/ 中所有 rule 文件
- 对每个 rule，upsert 到 Rules database（key: rule name）
- Properties: Rule, Category, Source Pattern, Violation Count, Status, Created, Last Applied

### 如果 target=all 或 review:
- 读取 wiki/reviews/ 中最新的 lint/review 文件
- 创建新 page under Reviews page

同步规则：
- 使用 notion-search 查找现有条目，避免重复
- 使用 notion-update-page 更新已存在的条目
- 使用 notion-create-pages 创建新条目
- 同步失败不阻塞，打印 warning 继续
PROMPT
)"

echo ""
echo "Sync complete."
