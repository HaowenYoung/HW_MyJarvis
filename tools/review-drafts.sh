#!/bin/bash
# review-drafts.sh — List pending drafts from feishu bot
# Usage: tools/review-drafts.sh [--count-only]

set -euo pipefail
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PENDING="$ROOT/raw/drafts/pending"

if [ ! -d "$PENDING" ]; then
  echo "0 pending drafts"
  exit 0
fi

COUNT=$(find "$PENDING" -name "*.md" -type f 2>/dev/null | wc -l)

if [ "${1:-}" = "--count-only" ]; then
  echo "$COUNT"
  exit 0
fi

echo "Pending drafts: $COUNT"
echo ""

for f in "$PENDING"/*.md; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  source=$(sed -n '/^source:/s/.*: *//p' "$f" | head -1)
  confidence=$(sed -n '/^confidence:/s/.*: *//p' "$f" | head -1)
  intent=$(sed -n '/^intent:/s/.*: *//p' "$f" | head -1)
  target=$(sed -n '/^target_file:/s/.*: *//p' "$f" | head -1)
  echo "  $fname | source: $source | confidence: $confidence | intent: $intent → $target"
done
