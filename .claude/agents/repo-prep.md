---
model: sonnet
---

# Repo Exploration Prep (Steps 1-2)

**Prerequisites**: Read `docs/repo-exploration.md` for the full 4-layer protocol, meta.md format, and exploration brief structure.

Clone a repo and analyze L1-L3. Layer 4 (Transfer) is done interactively by CC + user, not by this agent.

## Input

- GitHub URL or owner/repo
- User's original message (exploration intent)

## Step 1: Acquisition

1. `git clone` (or pull if exists) → `~/repos/<owner>-<repo>/`
2. Create `raw/repos/<owner>-<repo>/meta.md` with frontmatter (source, owner, repo, url, language, topics, discovered, explore_status, clone_path)

## Step 1.5: Exploration brief

Assemble personalized "reading lens" from user context:
- `wiki/context/active-projects.md` → what user is working on
- `projects/*/wiki/INDEX.md` → project stages and needs
- `wiki/knowledge/papers-index.md` → topic overlap with this repo
- `wiki/knowledge/repos-index.md` → previously explored related repos

Write `## Exploration brief` in meta.md: intent, focus areas, project context, related papers/repos, transfer targets.

## Step 2: Layered analysis

**L1 Purpose** (README + top-level files): problem, approach, input/output, differentiation from similar tools.

**L2 Structure** (directories + entry points): subsystem map table (子问题 → 模块 → 关键文件), data flow, critical path vs auxiliary modules.

**L3 Implementation** (core modules only, guided by brief's focus areas): implementation logic, tech choices, key trade-offs, clever parts, weaknesses. Skip modules the brief marks as low-priority.

Write each layer into corresponding meta.md sections.

## Output

- `raw/repos/<owner>-<repo>/meta.md` with L1-L3 filled + exploration brief
- Ready for interactive Layer 4 discussion with CC + user

## Incidental discoveries (required output)

Beyond L1-L3 analysis, report insights noticed during execution. These are system evolution signals.

Examples: a design pattern worth adopting across user's projects, implementation approach that validates/contradicts an existing idea, code structure that maps to a paper's theoretical framework, anti-pattern the user should avoid.

Tag each: `[rule-signal]` `[trait-signal]` `[cross-ref]` `[stale]` `[flag-user]` `[wiki-update]`

Invoking session appends these to `wiki/meta/discoveries-inbox.md` (format: Date | Source | Tag | Discovery) and checks for cross-subagent convergence.
