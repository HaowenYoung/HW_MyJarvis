#!/bin/bash
# find-orphans.sh
# Find wiki pages that are not referenced by any other page.
# Excludes INDEX.md itself (it's the hub, not expected to be linked to).
# Output: orphan page paths, one per line.

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

all_pages=$(find wiki/ projects/ -name "*.md" -type f | grep -v "INDEX.md")

for page in $all_pages; do
  basename=$(basename "$page")
  # Check if this filename appears in any other .md file
  referrers=$(grep -rl "$basename" wiki/ projects/ --include="*.md" 2>/dev/null | grep -v "$page" | head -1)
  if [ -z "$referrers" ]; then
    echo "ORPHAN: $page"
  fi
done
