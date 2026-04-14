#!/bin/bash
# extract-frontmatter.sh <file>
# Parse YAML frontmatter from a markdown file.
# Output: key: value pairs, one per line.

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: tools/extract-frontmatter.sh <file>" >&2
  exit 1
fi

sed -n '1{/^---$/!q}; 1,/^---$/{/^---$/d; p}' "$FILE"
