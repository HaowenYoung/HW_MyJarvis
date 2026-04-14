#!/bin/bash
# explore-repo.sh <owner/repo> [mode]
# Triggered by feishu-bot when user mentions a GitHub repo.
# Clones (or pulls), creates meta.md scaffold, then launches Claude Code
# for 4-layer understanding analysis. Sends summary back via notify.sh.
#
# mode: "full" (default, Layer 1-3) or "shallow" (Layer 1-2 only)

set -euo pipefail

REPO_SLUG="${1:-}"
MODE="${2:-full}"

if [ -z "$REPO_SLUG" ]; then
  echo "Usage: tools/explore-repo.sh <owner/repo> [full|shallow]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
ROOT=$(pwd)
TODAY=$(date +%Y-%m-%d)

OWNER=$(echo "$REPO_SLUG" | cut -d/ -f1)
REPO=$(echo "$REPO_SLUG" | cut -d/ -f2)
SAFE_NAME="${OWNER}-${REPO}"
CLONE_DIR="$HOME/repos/${SAFE_NAME}"
RAW_DIR="${ROOT}/raw/repos/${SAFE_NAME}"

# ─── Step 1: Clone or pull ──────────────────────────────
if [ -d "$CLONE_DIR" ]; then
  echo "[explore] Pulling ${REPO_SLUG}..."
  git -C "$CLONE_DIR" pull --ff-only 2>/dev/null || true
else
  echo "[explore] Cloning ${REPO_SLUG}..."
  mkdir -p "$HOME/repos"
  git clone --depth 50 "https://github.com/${REPO_SLUG}.git" "$CLONE_DIR"
fi

# ─── Step 1 cont: Scaffold raw/repos/ ───────────────────
mkdir -p "$RAW_DIR"
echo "$CLONE_DIR" > "${RAW_DIR}/clone_path.txt"

# Create meta.md if it doesn't exist
if [ ! -f "${RAW_DIR}/meta.md" ]; then
  # Fetch repo info from GitHub API
  REPO_JSON=$(curl -s "https://api.github.com/repos/${REPO_SLUG}" 2>/dev/null || echo "{}")
  LANG=$(echo "$REPO_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('language','unknown'))" 2>/dev/null || echo "unknown")
  DESC=$(echo "$REPO_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('description',''))" 2>/dev/null || echo "")
  TOPICS=$(echo "$REPO_JSON" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin).get('topics',[])))" 2>/dev/null || echo "[]")

  cat > "${RAW_DIR}/meta.md" <<METAEOF
---
source: github
owner: ${OWNER}
repo: ${REPO}
url: https://github.com/${REPO_SLUG}
language: ${LANG}
topics: ${TOPICS}
discovered: ${TODAY}
explore_status: 收藏未看
clone_path: ${CLONE_DIR}
related_projects: []
related_papers: []
---

# ${OWNER}/${REPO}

## Why interesting

${DESC}

## Exploration brief

## Layer 1: Purpose
### Problem
### Approach
### Input / Output
### Differentiation

## Layer 2: Structure
### Subsystem map
### Data flow
### Critical path

## Layer 3: Implementation

## Layer 4: Transfer
METAEOF

  echo "[explore] Created ${RAW_DIR}/meta.md"
fi

# ─── Gather context for exploration brief ────────────────
ACTIVE_PROJECTS=$(cat wiki/context/active-projects.md 2>/dev/null || ls projects/ 2>/dev/null || echo "(none)")
REPOS_INDEX=$(cat wiki/knowledge/repos-index.md 2>/dev/null || echo "(none yet)")

# ─── Step 2-3: Launch Claude Code for analysis ───────────
echo "[explore] Starting Claude Code analysis (mode: ${MODE})..."

if [ "$MODE" = "shallow" ]; then
  LAYER_INSTRUCTION="只做 Layer 1 (Purpose) 和 Layer 2 (Structure)。不深入 Layer 3。
更新 explore_status 为 '浅看'。"
else
  LAYER_INSTRUCTION="做 Layer 1 (Purpose)、Layer 2 (Structure)、Layer 3 (Implementation，只分析核心模块)。
Layer 4 (Transfer) 预填 provisional suggestions，标注为 provisional。
更新 explore_status 为 '浅看'（飞书触发的无人值守分析，深度探索需要交互确认）。"
fi

"${CLAUDE_BIN:-claude}" --dangerously-skip-permissions "Repo exploration: ${REPO_SLUG}

你在 MyJarvis 系统中执行 repo 理解性阅读流程。
参考 docs/repo-exploration.md 的四层理解模型。
这是飞书触发的无人值守探索，目标是理解，不是评审。

代码已 clone 到: ${CLONE_DIR}
Meta 文件: ${RAW_DIR}/meta.md

用户的活跃项目：
${ACTIVE_PROJECTS}

已探索的 repos：
${REPOS_INDEX}

─── 任务 ───

Step 1.5: 生成 Exploration brief
  基于 repo README 和用户的活跃项目，生成个性化阅读重点。
  写入 meta.md ## Exploration brief。

Step 2: 四层递进分析
  ${LAYER_INSTRUCTION}

  Layer 1: 读 README、顶层文件。回答：解决什么问题？怎么解决的？输入/输出？和同类的区别？
  Layer 2: 读目录结构、各模块入口。画出子问题→模块映射表、数据流、关键路径。
  Layer 3: 读 brief 里 focus areas 对应的核心模块源码。分析实现逻辑、技术选型、关键决策和 trade-off。

  每层产出写入 meta.md 对应 section。

Step 4 (部分):
  - 检查 projects/ 和 raw/repos/，写入 cross-references（如果有关联）
  - 更新 wiki/knowledge/repos-index.md（不存在则创建）
  - git add -A && git commit -m 'feat: explore ${REPO_SLUG}'

关键原则：
  - 理解为主，不是评审。关注 why 和 how，不是好不好。
  - Layer 4 Transfer 需要用户交互确认，这里只预填 provisional suggestions。
  - 不要启动交互式讨论，直接分析并输出。" 2>&1

# ─── Send summary via Feishu ─────────────────────────────
PURPOSE=$(sed -n '/^### Problem/,/^### /{/^### Problem/d;/^### /d;p}' "${RAW_DIR}/meta.md" | head -5)
APPROACH=$(sed -n '/^### Approach/,/^### /{/^### Approach/d;/^### /d;p}' "${RAW_DIR}/meta.md" | head -3)
STRUCTURE=$(sed -n '/^### Subsystem map/,/^### /{/^### Subsystem map/d;/^### /d;p}' "${RAW_DIR}/meta.md" | head -8)

SUMMARY="✅ 探索完成: ${REPO_SLUG}

🎯 Problem:
${PURPOSE}

💡 Approach:
${APPROACH}

🏗 Structure:
${STRUCTURE}

详见 raw/repos/${SAFE_NAME}/meta.md"

bash "${ROOT}/tools/notify.sh" "$SUMMARY"

echo "[explore] Done: ${REPO_SLUG}"
