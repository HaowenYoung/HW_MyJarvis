**English** | [中文](README.zh.md)

# MyJarvis — A Personal Agent System

> **This is the privacy-scrubbed framework template.** The author's personalized instance — with real `raw/` logs, compiled `wiki/`, and active projects — lives in a separate private repo. What you see here is the empty skeleton: clone it, feed it your own data, and it becomes *your* agent.

> Generic LLMs give everyone the same answer. MyJarvis gives *you* **your** answer — grounded in your own rules, traits, values, reading notes, project context, and historical decisions.

Before generating any output, the agent asks itself:

> *"What personal context from the wiki did I actually use?
> If the answer is nothing — go find it, and regenerate."*

That single question is the entire product thesis.

---

## Why it exists

Most "AI assistants" treat every user as an anonymous prompt. They have no memory of who you are, what you decided last Tuesday, what your research direction is, or why you disagreed with a reviewer three weeks ago. The result: plausible but generic output that you then have to re-personalize by hand.

MyJarvis is the opposite. It is an opinionated, single-user system whose *entire* job is to compile your life into a structured knowledge network and inject the relevant slice into every interaction.

## Three core ideas

### 1. Personalization as a first-class constraint
Every operation — daily planning, paper filtering, repo exploration, writing help, alerts — is required to cite the personal rules / traits / values that shaped it. If a response could have been produced by a generic chatbot, it's by definition a failure mode.

### 2. Self-evolving memory (L1 → L6)
Memory is not a static prompt. It is distilled on a schedule, adversarially audited, and confirmed by you:

```
L1 Observations  →  L2 Patterns  →  L3 Domain rules
                                          ↓
              L6 Values  ←  L5 Traits  ←  L4 Policies
```

Three pathways keep it honest:

- **Bottom-up induction** — weekly L2→L3, monthly L3→L4, quarterly L4→L5, each promotion gated by `accept / reject`.
- **Top-down deduction** — an L5 trait can propose a provisional L3 rule, still subject to confirmation.
- **User-correction fast-track** — when you correct the agent, the fix lands directly at the right level (usually L3), bypassing the statistical pipeline.

### 3. Karpathy-style LLM Wiki
Inspired by Karpathy's *LLM Wiki* idea: **raw data should never be fed directly to the model.** Everything flows through a `compile` step that extracts, cross-references, and indexes it into a knowledge network where papers ↔ projects ↔ ideas ↔ rules link to one another. The LLM consumes *processed knowledge*, not a pile of logs.

### Plus two supporting principles

- **Filesystem as source of truth.** Every artifact is git-tracked markdown. No vendor lock-in. Human-auditable, script-processable, cold-backup friendly. Notion is a browsing layer, not storage.
- **Dual-LLM adversarial governance.** Distillation candidates, novelty claims, and self-modification proposals are audited by Codex (GPT-5.4, high reasoning) before you judge them — so one model's hallucinations can't self-reinforce into "rules."

---

## Architecture at a glance

```
     ┌──────────────── write / git ────────────────┐
     │                                             │
     ▼                                             │
   raw/   ──compile──▶   wiki/   ──inject──▶   LLM layer
 (append-only)       (knowledge network)     ┌─────┴──────┐
                                             │ Claude Code│  attended
                                             │  飞书 bot   │  mobile / unattended
                                             │   Notion   │  browse (sync)
                                             └─────┬──────┘
                                                   │
                                            outputs / decisions
                                                   │
                                                   └── back to raw/
```

Three channels. One filesystem. One knowledge graph.

---

## Directory layout

| Path | What it holds |
|------|---------------|
| `raw/` | Append-only source data (daily/, events/, papers/, repos/, ideas/, claude-sessions/, drafts/, feedback/). Requires frontmatter. |
| `wiki/` | LLM-compiled knowledge: memory/, rules/, policies/, traits/, values/, knowledge/, plans/, reviews/, meta/. Only LLMs write here. |
| `projects/` | Per-project knowledge bases. Each project links to its actual repo via `source_path.txt`. |
| `tools/` | Bash + Python scripts (`compile.sh`, `plan.sh`, `lint.sh`, `sync-to-notion.sh`, `feishu-bot.py`, …). |
| `docs/` | Detailed specs for every operation. Read on demand. |
| `.claude/agents/` | Subagent prompts (Sonnet executors orchestrated by the main session). |

See [`CLAUDE.md`](CLAUDE.md) for the authoritative manifest.

---

## Core operations

| Operation | One-liner | Spec |
|-----------|-----------|------|
| **Ingest** | Append to `raw/` with frontmatter | [docs/operations.md](docs/operations.md) |
| **Compile** | `raw/` → `wiki/`: extract, pattern-detect, cross-reference, index, sync | [docs/operations.md](docs/operations.md) |
| **Plan** | Daily work+life plan, citing rules w/ level, scanning a 14-day event horizon | [docs/operations.md](docs/operations.md) |
| **Wrap-up** | Incremental session summary → project wiki → Notion → git commit (23:30 cron fallback) | [docs/operations.md](docs/operations.md) |
| **Lint** | Weekly health check; bash + LLM + Codex cross-audit | [docs/operations.md](docs/operations.md) |
| **Distill** | L2→L3 / L3→L4 / L4→L5 with Codex adversarial review | [docs/operations.md](docs/operations.md) |
| **Repo exploration** | 4-layer progression: Purpose → Structure → Implementation → Transfer | [docs/repo-exploration.md](docs/repo-exploration.md) |
| **Ideas** | Capture → Codex enrich (linking + scoring + action plan) → incubate → promote/archive | [docs/idea-management.md](docs/idea-management.md) |
| **Self-modification** | Impact analysis → Codex audit → proposal → user accept/reject → apply → changelog | [docs/self-modification.md](docs/self-modification.md) |
| **ARIS research** | Context-injected research workflows (lit review, novelty check, paper writing, experiment planning) | [docs/aris-integration.md](docs/aris-integration.md) |

---

## Subagents & automation

Ten Sonnet subagents live in `.claude/agents/`, each with a single responsibility:

| Agent | Trigger |
|-------|---------|
| `compile` | `"compile"` / weekly |
| `plan` | `"今日 plan"` / morning |
| `wrapup` | `"wrap-up"` / nightly 23:30 |
| `distill` | `"distill"` / weekly / monthly |
| `lint` | `"lint"` / weekly |
| `notion-sync` | After compile / plan / wrapup |
| `idea-enrich` | `"记个 idea"` |
| `session-end` | Session close |
| `project-init` | `"新建项目"` |
| `repo-prep` | `"探索 <repo>"` |

Cron schedule (see [`docs/cron-automation.md`](docs/cron-automation.md)):

- **07:00 daily** — alert check
- **23:30 daily** — auto wrap-up (incremental)
- **Sunday 20:00** — weekly compile + lint + L2→L3 distill
- **1st of month 20:00** — L3→L4 policy review

---

## Tech stack

- **Languages.** Bash (primary), Python 3 (飞书 bot, CSV parsing, scoring).
- **Claude Code CLI** — attended orchestration.
- **Codex MCP** (GPT-5.4, high reasoning) — adversarial audit for distillation, novelty, self-modification.
- **Notion MCP** — bidirectional sync. Zone A: `fs → Notion` (one-way, compiled knowledge). Zone B: `fs ↔ Notion` (plan / daily / scratch). Zone B+: user-override (ideas).
- **SiliconFlow** (fast tier) + **ollama qwen3:32b** (local fallback) — used only by the 飞书 bot and only for drafts, never for formal files.
- **飞书 (Lark)** bot — mobile / unattended channel, systemd-managed.
- **Zotero CSV** pipeline for paper ingestion.
- **git** — every important operation ends with a commit.

There is intentionally no `package.json` or `requirements.txt`. Each script documents its own dependencies at the top.

---

## Quickstart

> MyJarvis is a *per-user* system. Forking it does not give you a working agent — it gives you a scaffold you then populate with your own `raw/` data over weeks.

```bash
# 1. clone
git clone <this-repo> myjarvis && cd myjarvis

# 2. pull the wiki-compiler submodule
git submodule update --init --recursive

# 3. populate secrets (NEVER commit these — already in .gitignore)
cp tools/llm-config.env.example      tools/llm-config.env
cp tools/notify-config.env.example   tools/notify-config.env
cp tools/notion-ids.env.example      tools/notion-ids.env
# fill in API keys, Notion page IDs, 飞书 webhook, etc.

# 4. open the repo in Claude Code
claude .

# 5. in the Claude Code session, bootstrap
# > read CLAUDE.md and setup_guide.md, create your first raw/daily/ entry

# 6. first real operation once you have a few days of raw/ data:
# > compile
```

A full guided walkthrough (Notion database schemas, 飞书 bot service file, cron installation) lives in [`setup_guide.md`](setup_guide.md).

---

## Privacy model

**This repo starts empty and safe to clone.** `raw/`, `wiki/`, and `projects/` are scrubbed skeletons — only structural directories, `.gitkeep` markers, and two generic framework docs (`wiki/meta/governance.md`, `wiki/meta/rule-lifecycle.md`) are tracked.

But **the moment you start using it, your fork becomes personal**. Within days you'll have daily logs, life events, decision feedback, project notes, and — after distillation — a wiki that describes your psychology. Plan for that:

- Treat your fork as **private by default**. Do not push it to a public remote without a fresh scrub.
- Sensitive surfaces to watch once you start using MyJarvis:
  - `raw/daily/`, `raw/events/`, `raw/feedback/` — personal logs
  - `wiki/traits/`, `wiki/values/` — psychological profile
  - `raw/papers/`, `raw/ideas/` — unpublished research
  - `projects/*/source_path.txt` — paths to private repos
  - `tools/*-config.env` — API keys (already `.gitignore`d, but check after first run)

### If you later want to publish your personalized fork

Same checklist this template was built with:

1. Empty every subdirectory of `raw/` (keep structure + `.gitkeep`, delete contents).
2. Delete `wiki/{memory,rules,policies,traits,values,context,knowledge,plans,reviews,topics}/` contents.
3. Reset `wiki/INDEX.md` to a blank template; delete `wiki/meta/{changelog,discoveries-inbox,distill-log,wrapup-log,search-index}`.
4. Replace concrete `projects/<name>/` with `projects/_template/` again.
5. Revert `tools/*-config.env` to `.env.example` files with placeholder keys.
6. Strip hardcoded paths from `tools/auto-wrapup.sh`, `tools/explore-repo.sh`, `tools/myjarvis-feishu.service`.
7. Clear `.claude/settings.local.json` permission cache.
8. Re-read `.gitignore`, `grep` for your username / home path / real API keys, commit.

A helper script to automate this scrub is on the roadmap but not yet written.

---

## Status

This repository is a **framework skeleton**, not a live product. There is no upstream merging community PRs — the author maintains their personalized fork privately. You are expected to clone, own, and diverge: make it yours. Issues discussing architecture are welcome; design debates are the point.

## License

[GPL-3.0](LICENSE). If you build on this system, your derivative work must also be GPL-3.0.

## Acknowledgments

- **Andrej Karpathy's LLM Wiki** — the direct inspiration for treating personal knowledge as a compiled, cross-referenced network rather than a chat log.
- **Anthropic Claude Code** — the orchestration substrate.
- **OpenAI Codex / GPT-5.4** — the adversarial auditor.
- **Notion, 飞书 (Lark), Zotero** — the surfaces this system lives on.
