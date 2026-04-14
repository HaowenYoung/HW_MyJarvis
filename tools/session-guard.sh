#!/bin/bash
# session-guard.sh
# Check if there is unsummarized work since the last wrap-up.
# Uses wiki/meta/wrapup-log.md instead of .lock files.
# Run at the start of every new Claude Code session.
# Output: WARNING lines if unsummarized work found, nothing if clean.

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

WRAPUP_LOG="wiki/meta/wrapup-log.md"
NOW_EPOCH=$(date +%s)

# Get the last wrap-up commit hash (any day, most recent)
LAST_HASH=$(grep -oP 'commit: \K[a-f0-9]+' "$WRAPUP_LOG" 2>/dev/null | tail -1 || true)

if [ -z "$LAST_HASH" ]; then
    # No wrap-up ever recorded — check if there are any commits at all
    TOTAL_COMMITS=$(git log --oneline 2>/dev/null | wc -l)
    if [ "$TOTAL_COMMITS" -eq 0 ]; then
        exit 0  # Empty repo
    fi
    # There are commits but no wrap-up log → everything is unsummarized
    echo "WARNING: No wrap-up records found. All work is unsummarized."
    echo ""
    echo "Recent commits:"
    git log --oneline -10 2>/dev/null
    echo ""
    echo "ACTION: Review git log, do a wrap-up to establish baseline."
    exit 0
fi

# Check if that commit still exists (guard against rebases)
if ! git cat-file -e "$LAST_HASH" 2>/dev/null; then
    echo "WARNING: Last wrap-up commit $LAST_HASH no longer exists (rebased?)."
    exit 0
fi

# Get time of last wrap-up commit
LAST_EPOCH=$(git log -1 --format='%ct' "$LAST_HASH" 2>/dev/null || echo "0")
HOURS_SINCE=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))

# Count new commits since last wrap-up
NEW_COMMITS=$(git log --oneline "${LAST_HASH}..HEAD" 2>/dev/null | wc -l)

if [ "$NEW_COMMITS" -eq 0 ]; then
    # No new work since last wrap-up — clean
    exit 0
fi

# There is unsummarized work
echo "WARNING: ${NEW_COMMITS} commits since last wrap-up (${HOURS_SINCE}h ago)."
echo ""
echo "Last wrap-up: $(grep "$LAST_HASH" "$WRAPUP_LOG" | tail -1)"
echo ""
echo "Unsummarized commits:"
git log --oneline "${LAST_HASH}..HEAD" 2>/dev/null | head -15
echo ""
echo "Projects with changes:"
git log --name-only --format="" "${LAST_HASH}..HEAD" 2>/dev/null \
    | grep -E '^(wiki/|projects/)' | sed 's|/.*||' | sort -u || true
echo ""
echo "ACTION: Review commits above, update project wikis + write session summary."
