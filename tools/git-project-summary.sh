#!/bin/bash
# git-project-summary.sh <project-name>
# Read projects/<name>/source_path.txt, run git log in the project repo.
# Output: recent commit summary (last 3 days).

set -euo pipefail

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "Usage: tools/git-project-summary.sh <project-name>" >&2
  exit 1
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SOURCE_FILE="$ROOT/projects/$PROJECT/source_path.txt"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: $SOURCE_FILE not found" >&2
  exit 1
fi

REPO_PATH=$(head -1 "$SOURCE_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
# Expand ~ if present
REPO_PATH="${REPO_PATH/#\~/$HOME}"

if [ ! -d "$REPO_PATH" ]; then
  echo "Error: repo path '$REPO_PATH' does not exist" >&2
  exit 1
fi

echo "=== $PROJECT ($(basename "$REPO_PATH")) ==="
echo "Path: $REPO_PATH"
echo ""
cd "$REPO_PATH"
git log --since="3 days ago" --oneline --stat 2>/dev/null || echo "(no recent commits)"
