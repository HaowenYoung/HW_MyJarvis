#!/bin/bash
# scan-project-repos.sh [since-commit-or-date]
# Scan all project repos for work not yet captured in agent-system.
# Called during wrap-up Step 5c.
#
# For each project: read source_path.txt → git log in repo → check if
# agent-system has a corresponding session summary. If not, output a report.
#
# Output: per-project report of uncaptured work.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Determine "since" time: from arg, or from last wrap-up, or 24h ago
SINCE="${1:-}"
if [ -z "$SINCE" ]; then
    LAST_HASH=$(grep -oP 'commit: \K[a-f0-9]+' wiki/meta/wrapup-log.md 2>/dev/null | tail -1 || true)
    if [ -n "$LAST_HASH" ] && git cat-file -e "$LAST_HASH" 2>/dev/null; then
        SINCE=$(git log -1 --format='%ci' "$LAST_HASH" 2>/dev/null)
    else
        SINCE="24 hours ago"
    fi
fi

TODAY=$(date +%Y-%m-%d)
FOUND_WORK=false

for proj_dir in projects/*/; do
    [ -d "$proj_dir" ] || continue
    proj_name=$(basename "$proj_dir")
    source_file="$proj_dir/source_path.txt"
    [ -f "$source_file" ] || continue

    repo_path=$(head -1 "$source_file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    repo_path="${repo_path/#\~/$HOME}"
    [ -d "$repo_path" ] || continue

    # Get recent commits in project repo
    commits=$(cd "$repo_path" && git log --since="$SINCE" --oneline --no-merges 2>/dev/null || true)
    [ -z "$commits" ] && continue

    commit_count=$(echo "$commits" | wc -l)

    # Check if we have a session summary for this project today
    has_summary=false
    if ls raw/claude-sessions/*-"$proj_name".md 2>/dev/null | grep -q "$TODAY"; then
        has_summary=true
    fi

    # Check if progress.md was updated today
    progress_updated=false
    if [ -f "$proj_dir/wiki/progress.md" ]; then
        mod_date=$(date -r "$proj_dir/wiki/progress.md" +%Y-%m-%d 2>/dev/null || echo "")
        [ "$mod_date" = "$TODAY" ] && progress_updated=true
    fi

    echo "=== $proj_name ($commit_count new commits) ==="
    echo "Repo: $repo_path"
    echo "Session summary: $([ "$has_summary" = true ] && echo 'YES' || echo 'MISSING')"
    echo "Progress.md updated today: $([ "$progress_updated" = true ] && echo 'YES' || echo 'NO')"
    echo ""
    echo "Recent commits:"
    echo "$commits" | head -10
    [ "$commit_count" -gt 10 ] && echo "  ... and $((commit_count - 10)) more"
    echo ""

    # Output diff stats for context
    echo "Changed files:"
    (cd "$repo_path" && git log --since="$SINCE" --name-only --format="" --no-merges 2>/dev/null | sort -u | head -15) || true
    echo ""
    echo "---"
    FOUND_WORK=true
done

if [ "$FOUND_WORK" = false ]; then
    echo "No uncaptured project work found since last wrap-up."
fi
