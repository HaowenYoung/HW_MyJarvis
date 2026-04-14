#!/bin/bash
# assemble-context.sh <task-description>
# Full context retrieval pipeline: deterministic filter → semantic rank → prefetch → assemble.
# Output: path to assembled context file.

set -euo pipefail

QUERY="${1:-}"
if [ -z "$QUERY" ]; then
  echo "Usage: tools/assemble-context.sh '<task description>'" >&2
  exit 1
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

CONTEXT_FILE="/tmp/context-$(date +%s).md"
SEARCH_INDEX="wiki/meta/search-index.json"

# Step 1: Ensure search index exists
if [ ! -f "$SEARCH_INDEX" ]; then
  bash tools/rebuild-search-index.sh >/dev/null 2>&1
fi

# Step 2: Tier 2 semantic ranking via ollama
PROMPT="你是一个搜索排序助手。给定用户查询和候选页面列表，输出最相关的 top-5 页面的 file 路径，每行一个，不要其他输出。

查询: $QUERY

候选页面:
$(cat "$SEARCH_INDEX")"

# Call ollama via API (cleaner than `ollama run` which has terminal escape codes)
OLLAMA_PAYLOAD=$(python3 -c "
import json, sys
print(json.dumps({'model':'qwen3:32b','prompt':'/no_think '+sys.stdin.read(),'stream':False,'options':{'num_predict':256}}))
" <<< "$PROMPT")

TOP_K=$(curl -s http://localhost:11434/api/generate \
  -d "$OLLAMA_PAYLOAD" 2>/dev/null \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" \
  | grep -E '^\s*(wiki/|projects/)' | sed 's/^[0-9]*\.\s*//' | head -5)

# Fallback: if ollama fails or returns nothing, use all topic + context pages
if [ -z "$TOP_K" ]; then
  TOP_K=$(find wiki/topics/ wiki/context/ -name "*.md" -type f | head -5)
fi

# Step 3: Prefetch — expand related links from top-K pages
EXPANDED=""
for f in $TOP_K; do
  [ -f "$f" ] || continue
  EXPANDED="$EXPANDED $f"
  # Add linked pages (1 hop)
  linked=$(bash tools/list-links.sh "$f" 2>/dev/null || true)
  for l in $linked; do
    [ -f "$l" ] && EXPANDED="$EXPANDED $l"
  done
done

# Deduplicate
EXPANDED=$(echo "$EXPANDED" | tr ' ' '\n' | sort -u)

# Step 4: Assemble context file
echo "# Assembled context for: $QUERY" > "$CONTEXT_FILE"
echo "# Generated: $(date -Iseconds)" >> "$CONTEXT_FILE"
echo "# Pages: $(echo "$EXPANDED" | wc -w)" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

for f in $EXPANDED; do
  [ -f "$f" ] || continue
  echo "---" >> "$CONTEXT_FILE"
  echo "## FILE: $f" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  cat "$f" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
done

echo "$CONTEXT_FILE"
