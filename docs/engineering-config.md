# Engineering Configuration

## Full directory structure

```
~/agent-system/

raw/                                  # L0-L1: append-only, immutable
  daily/                              # Daily logs: YYYY-MM-DD.md (append-式 Session blocks)
  feedback/                           # Accept/reject logs
  scratch/                            # Quick captures, mobile notes, feishu fallback
  events/                             # Life events (supports future dates)
    YYYY-MM-DD.md
    monthly/                          # Monthly event summaries
  papers/                             # Zotero CSV + parsed per-paper .md
    parsed/                           # One .md per paper
  drafts/                             # Feishu bot draft mechanism
    pending/                          # Awaiting review
    reviewed/                         # Approved/rejected
  notion-archive/                     # One-time Notion import
  calendar/                           # Historical schedules
    meetings/
  blogs/                              # User's blog posts
  claude-sessions/                    # Session summaries (YYYY-MM-DD-HHMM[-project].md)

wiki/                                 # L2+: LLM-compiled, human-readable
  INDEX.md                            # Master TOC
  memory/                             # L2 Patterns
  rules/                              # L3 Domain rules (by domain)
    engineering/ paper-reading/ paper-writing/ personal/ research/
  policies/                           # L4 Cross-domain policies
  traits/                             # L5 Personal traits
  values/                             # L6 Life philosophy
  knowledge/                          # Compiled knowledge (papers-index, topic syntheses)
  context/                            # personal-profile.md, active-projects.md
  plans/                              # Daily plans + alerts
  reviews/                            # Weekly/monthly reports
  meta/                               # rule-lifecycle, governance, distill-log, wrapup-log, search-index.json

projects/                             # Per-project knowledge bases
  <project-name>/
    source_path.txt
    wiki/ (INDEX, architecture, progress, decisions, backlog, constraints)

tools/                                # Scripts and config
  auto-wrapup.sh                      filter.sh              extract-frontmatter.sh
  list-links.sh                       check-broken-links.sh  find-orphans.sh
  rule-audit.sh                       recent-changes.sh      git-project-summary.sh
  rebuild-search-index.sh             assemble-context.sh    session-guard.sh
  check-alerts.sh                     parse-zotero-csv.sh    classify-paper-topics.py
  cross_ref_score.py                  generate-project-claude.sh
  notify.sh                           feishu-bot.py          myjarvis-feishu.service
  llm-light.sh                        llm-local.sh           llm-route.sh
  review-drafts.sh                    scan-project-repos.sh
  notify-config.env (gitignored)      llm-config.env (gitignored)  notion-ids.env

docs/                                 # Detailed specifications (this directory)
```

## Naming conventions

- Timestamps: ISO 8601
- Filenames: YYYY-MM-DD
- User-facing content: Chinese preferred
- System/code/filenames: English
- Session files: YYYY-MM-DD-HHMM[-project].md

## Error handling

- Sync failure does not block filesystem operations
- If llm-route.sh fails in CC session → CC does it itself
- If Codex fails → CC does it (degrade, don't block)
- If bash script fails → CC reads stderr, fixes
- SiliconFlow/ollama in feishu bot: draft-only writes
- API keys only in tools/*-config.env, never in git
