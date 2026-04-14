#!/bin/bash
# notify.sh <message>
# Push notification via 飞书.
# Uses webhook for simple text, or API for rich cards.

set -euo pipefail

MESSAGE="${1:-}"
if [ -z "$MESSAGE" ]; then
  echo "Usage: tools/notify.sh <message>" >&2
  exit 1
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
source "$ROOT/tools/notify-config.env" 2>/dev/null || true

# Method 1: Webhook (simple, no OAuth needed)
if [ -n "${FEISHU_BOT_WEBHOOK:-}" ] && [ "$FEISHU_BOT_WEBHOOK" != "https://open.feishu.cn/open-apis/bot/v2/hook/your-hook-id" ]; then
  curl -s -X POST "$FEISHU_BOT_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"${MESSAGE}\"}}" > /dev/null 2>&1
  echo "[notify] 飞书 webhook: sent"
  exit 0
fi

# Method 2: API with tenant_access_token (richer, needs app credentials)
if [ -n "${FEISHU_APP_ID:-}" ] && [ "$FEISHU_APP_ID" != "your-app-id" ]; then
  TOKEN=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
    -H "Content-Type: application/json" \
    -d "{\"app_id\":\"${FEISHU_APP_ID}\",\"app_secret\":\"${FEISHU_APP_SECRET}\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('tenant_access_token',''))" 2>/dev/null)

  if [ -n "$TOKEN" ]; then
    ESCAPED=$(echo "$MESSAGE" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")
    curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"receive_id\":\"${FEISHU_USER_OPEN_ID}\",\"msg_type\":\"text\",\"content\":\"{\\\"text\\\":${ESCAPED}}\"}" > /dev/null 2>&1
    echo "[notify] 飞书 API: sent"
    exit 0
  fi
fi

echo "[notify] 飞书: skipped (not configured)"
