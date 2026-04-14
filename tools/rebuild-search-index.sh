#!/bin/bash
# rebuild-search-index.sh
# Rebuild the Tier 2 search index from wiki/INDEX.md and all wiki pages.
# Output: wiki/meta/search-index.json
# Format: [{file, title, summary, tags}]

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

OUTPUT="wiki/meta/search-index.json"

echo "[" > "$OUTPUT"

first=true
for f in $(find wiki/ projects/ -name "*.md" -type f | sort); do
  [ -f "$f" ] || continue

  # Extract title: first # heading
  title=$(grep -m1 '^# ' "$f" | sed 's/^# //' | sed 's/"/\\"/g')
  [ -z "$title" ] && continue

  # Extract tags from frontmatter
  tags=$(sed -n '/^---$/,/^---$/{/^tags:/s/tags: *\[//;s/\]//;s/, */,/g;p}' "$f" | head -1)

  # Extract first non-empty, non-heading, non-frontmatter line as summary
  summary=$(sed -n '/^---$/,/^---$/d; /^$/d; /^#/d; /^>/d; /^|/d; /^-/d; /^Last updated/d; p' "$f" | head -1 | sed 's/"/\\"/g' | cut -c1-200)

  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$OUTPUT"
  fi

  printf '  {"file": "%s", "title": "%s", "summary": "%s", "tags": "%s"}' \
    "$f" "$title" "$summary" "$tags" >> "$OUTPUT"
done

echo "" >> "$OUTPUT"
echo "]" >> "$OUTPUT"

echo "Search index rebuilt: $(grep -c '"file"' "$OUTPUT") entries → $OUTPUT"
