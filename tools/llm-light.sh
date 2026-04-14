#!/bin/bash
# llm-light.sh — SiliconFlow MiniMax call (fast, cheap, 5s timeout)
# Usage: tools/llm-light.sh "prompt" OR echo "prompt" | tools/llm-light.sh
# Exit 1 on timeout/failure. Stdout = model response.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/llm-config.env" 2>/dev/null || { echo "TIMEOUT" >&2; exit 1; }

PROMPT="${1:-$(cat)}"

RESPONSE=$(curl -s --max-time "${LLM_LIGHT_TIMEOUT:-5}" \
  -X POST "${LLM_LIGHT_API_BASE}/chat/completions" \
  -H "Authorization: Bearer ${LLM_LIGHT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c "
import json,sys
print(json.dumps({
  'model': '${LLM_LIGHT_MODEL}',
  'messages': [{'role':'user','content':sys.argv[1]}],
  'temperature': 0.3
}))" "$PROMPT")" 2>/dev/null)

[ $? -ne 0 ] || [ -z "$RESPONSE" ] && { echo "TIMEOUT" >&2; exit 1; }

echo "$RESPONSE" | python3 -c "
import sys,json
try: print(json.load(sys.stdin)['choices'][0]['message']['content'])
except: print('PARSE_ERROR',file=sys.stderr); sys.exit(1)"
