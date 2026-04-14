#!/usr/bin/env bash
# ingest.sh — 追加条目到 raw/daily/$(date +%Y-%m-%d).md
#
# Usage:
#   ./tools/ingest.sh "Task description" [options]
#   echo "multi-line note" | ./tools/ingest.sh -
#
# Options:
#   --project NAME    项目名 (default: personal)
#   --type TYPE       coding|writing|reading|meeting|admin|planning (default: coding)
#   --status STATUS   done|partial|blocked|skipped (default: done)
#   --est TIME        预估时间 (e.g. "1.5h")
#   --actual TIME     实际时间 (e.g. "2h")
#   --notes TEXT      额外备注
#
# Examples:
#   ./tools/ingest.sh "Fixed auth bug" --project <your-project> --type coding --actual 1.5h
#   ./tools/ingest.sh "Read paper on LLM agents" --type reading --est 2h --status partial

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)
DAILY_FILE="$PROJECT_ROOT/raw/daily/$TODAY.md"

# Defaults
PROJECT="personal"
TYPE="coding"
STATUS="done"
EST=""
ACTUAL=""
NOTES=""
DESCRIPTION=""

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --project)  PROJECT="$2"; shift 2 ;;
    --type)     TYPE="$2"; shift 2 ;;
    --status)   STATUS="$2"; shift 2 ;;
    --est)      EST="$2"; shift 2 ;;
    --actual)   ACTUAL="$2"; shift 2 ;;
    --notes)    NOTES="$2"; shift 2 ;;
    -)          DESCRIPTION=$(cat); shift ;;
    *)
      if [[ -z "$DESCRIPTION" ]]; then
        DESCRIPTION="$1"
      else
        DESCRIPTION="$DESCRIPTION $1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$DESCRIPTION" ]]; then
  echo "Error: No description provided." >&2
  echo "Usage: $0 \"Task description\" [--project NAME] [--type TYPE] [--status STATUS] [--est TIME] [--actual TIME] [--notes TEXT]" >&2
  exit 1
fi

# Create daily file if doesn't exist
if [[ ! -f "$DAILY_FILE" ]]; then
  echo "# Daily Log: $TODAY" > "$DAILY_FILE"
  echo "" >> "$DAILY_FILE"
fi

# Append entry
{
  echo ""
  echo "## $NOW - $DESCRIPTION"
  echo "- **Project**: $PROJECT"
  echo "- **Type**: $TYPE"
  echo "- **Status**: $STATUS"
  [[ -n "$EST" ]] && echo "- **Estimated**: $EST"
  [[ -n "$ACTUAL" ]] && echo "- **Actual**: $ACTUAL"
  [[ -n "$NOTES" ]] && echo "- **Notes**: $NOTES"
} >> "$DAILY_FILE"

echo "Ingested to $DAILY_FILE"
echo "  [$NOW] $DESCRIPTION ($PROJECT/$TYPE/$STATUS)"
