#!/bin/bash
# list-links.sh <file>
# Extract all internal markdown links from a wiki page.
# Looks in ## Sources, ## Related, ## Promoted to, ## Abstracted to sections,
# and also catches all markdown links throughout the file.
# Output: one linked file path per line (relative to repo root).

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: tools/list-links.sh <file>" >&2
  exit 1
fi

DIR=$(dirname "$FILE")

# Extract all markdown link targets: [text](path)
# Filter to internal .md links only (exclude http/https)
grep -oP '\]\(\K[^)]+' "$FILE" 2>/dev/null \
  | grep -v '^https\?://' \
  | grep -v '^mailto:' \
  | grep '\.md' \
  | while read -r link; do
    # Resolve relative path
    resolved=$(cd "$DIR" && realpath --relative-to="$(git rev-parse --show-toplevel)" "$link" 2>/dev/null || echo "$link")
    echo "$resolved"
  done \
  | sort -u
