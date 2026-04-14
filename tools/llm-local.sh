#!/bin/bash
# llm-local.sh — ollama local fallback (30s timeout)
# Usage: tools/llm-local.sh "prompt" OR echo "prompt" | tools/llm-local.sh
# Exit 1 on timeout/failure. Stdout = model response.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/llm-config.env" 2>/dev/null || true

PROMPT="${1:-$(cat)}"
MODEL="${LLM_LOCAL_MODEL:-qwen3:32b}"
TIMEOUT="${LLM_LOCAL_TIMEOUT:-30}"

RESPONSE=$(curl -s --max-time "$TIMEOUT" \
  -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c "
import json,sys
print(json.dumps({
  'model': '$MODEL',
  'prompt': '/no_think ' + sys.argv[1],
  'stream': False,
  'options': {'num_predict': 512, 'temperature': 0.3}
}))" "$PROMPT")" 2>/dev/null)

[ $? -ne 0 ] || [ -z "$RESPONSE" ] && { echo "TIMEOUT" >&2; exit 1; }

echo "$RESPONSE" | python3 -c "
import sys,json
try: print(json.load(sys.stdin).get('response',''))
except: print('PARSE_ERROR',file=sys.stderr); sys.exit(1)"
