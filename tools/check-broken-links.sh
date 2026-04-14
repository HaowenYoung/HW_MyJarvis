#!/bin/bash
# check-broken-links.sh
# Scan all wiki/ and projects/ markdown files for broken internal links.
# Output: BROKEN: source_file → target_link

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

found=0
for f in $(find wiki/ projects/ -name "*.md" -type f 2>/dev/null); do
  dir=$(dirname "$f")
  # Extract markdown link targets (internal .md only)
  grep -oP '\]\(\K[^)]+' "$f" 2>/dev/null \
    | grep -v '^https\?://' \
    | grep -v '^mailto:' \
    | grep '\.md' \
    | while read -r link; do
      # Resolve relative to the file's directory
      target="$dir/$link"
      resolved=$(realpath -m "$target" 2>/dev/null || echo "$target")
      if [ ! -f "$resolved" ]; then
        echo "BROKEN: $f → $link"
        found=1
      fi
    done
done

if [ "$found" -eq 0 ]; then
  echo "No broken links found."
fi
