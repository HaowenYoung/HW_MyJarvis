#!/bin/bash
# llm-route.sh — Escalation routing: SiliconFlow → ollama → exit 1
# Usage: tools/llm-route.sh "prompt" OR echo "prompt" | tools/llm-route.sh
# Stdout = model response. Stderr = which model was used.
# Exit 0 on success, exit 1 if all models fail.

set -uo pipefail
DIR="$(dirname "$0")"
PROMPT="${1:-$(cat)}"

# Priority 1: SiliconFlow (5s)
RESULT=$("$DIR/llm-light.sh" "$PROMPT" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
  echo "$RESULT"
  echo "siliconflow" >&2
  exit 0
fi

# Priority 2: ollama (30s)
RESULT=$("$DIR/llm-local.sh" "$PROMPT" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
  echo "$RESULT"
  echo "ollama" >&2
  exit 0
fi

# Both failed
echo "ALL_FAILED" >&2
exit 1
