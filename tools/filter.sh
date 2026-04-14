#!/bin/bash
# filter.sh <date-range> [project] [type]
# Filter raw/ files by date range, project, and/or type.
# Date range format: YYYY-MM-DD:YYYY-MM-DD (start:end)
# Example: tools/filter.sh 2026-04-01:2026-04-07 "Understand CodeEffi" coding

set -euo pipefail

DATE_RANGE="${1:-}"
PROJECT="${2:-}"
TYPE="${3:-}"

if [ -z "$DATE_RANGE" ]; then
  echo "Usage: tools/filter.sh <start:end> [project] [type]" >&2
  exit 1
fi

START=$(echo "$DATE_RANGE" | cut -d: -f1)
END=$(echo "$DATE_RANGE" | cut -d: -f2)

# Collect candidate files from raw/daily/ and raw/events/
candidates=""
for dir in raw/daily raw/events; do
  [ -d "$dir" ] || continue
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    # Extract date from filename (YYYY-MM-DD.md)
    fname=$(basename "$f" .md)
    if [[ ! "$fname" < "$START" ]] && [[ ! "$fname" > "$END" ]]; then
      candidates="$candidates $f"
    fi
  done
done

# Apply project filter
if [ -n "$PROJECT" ] && [ -n "$candidates" ]; then
  filtered=""
  for f in $candidates; do
    if grep -qi "project:.*$PROJECT" "$f" 2>/dev/null; then
      filtered="$filtered $f"
    fi
  done
  candidates="$filtered"
fi

# Apply type filter
if [ -n "$TYPE" ] && [ -n "$candidates" ]; then
  filtered=""
  for f in $candidates; do
    if grep -qi "Type:.*$TYPE" "$f" 2>/dev/null; then
      filtered="$filtered $f"
    fi
  done
  candidates="$filtered"
fi

# Output one file per line
for f in $candidates; do
  echo "$f"
done
