#!/bin/bash
# recent-changes.sh <days>
# List wiki/ files modified in the last N days.
# Output: one file path per line.

set -euo pipefail

DAYS="${1:-3}"

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

find wiki/ projects/ -name "*.md" -type f -mtime -"$DAYS" | sort
