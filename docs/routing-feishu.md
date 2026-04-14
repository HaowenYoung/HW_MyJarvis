# Feishu Bot Message Routing

Routing for messages received by `tools/feishu-bot.py`.
Bot is unattended — no Claude Code session active.

## Escalation chain

```
飞书消息进入
│
├── Slash command? (/plan /progress /backlog /alerts /week /status)
│   → bash 读文件 → 回复 (instant, 0 cost)
│
├── GitHub repo detected? (owner/repo or github.com URL + 探索/看看/了解 keyword)
│   → 即时回复 "开始探索..."
│   → 后台 tools/explore-repo.sh → clone → Claude Code 分析 → notify.sh 摘要
│   → 详见 docs/repo-exploration.md
│
└── Natural language
    │
    ▼
    SiliconFlow MiniMax-M2.5 (5s timeout, tools/llm-light.sh)
    │
    ├── Success + confidence >= 0.85 + event/log/task
    │   → write raw/drafts/pending/ → reply "已记录（待确认）"
    ├── Success + confidence >= 0.85 + simple_query
    │   → bash reads file → reply content
    ├── Success + confidence < 0.85 or intent=idea/complex
    │   → escalate to Codex
    └── Timeout/Failure
        │
        ▼
        ollama qwen3:32b (30s timeout, tools/llm-local.sh)
        │
        ├── Success → same routing as above
        └── Timeout/Failure → escalate to Codex
```

## Codex in feishu bot

- **idea**: read wiki/knowledge/ + projects/, do knowledge linking, write `raw/scratch/idea-*.md`, reply
- **complex**: if single-turn solvable → process; else → save scratch + redirect to Claude Code
- **fallback**: Codex does classification + extraction, writes formal files directly

## Write permissions

| Unit | Formal files | raw/drafts/ |
|------|-------------|-------------|
| bash (slash cmd) | read-only | — |
| SiliconFlow | ❌ | ✅ draft only |
| ollama | ❌ | ✅ draft only |
| Codex | ✅ formal | ✅ draft |

## Draft mechanism

SiliconFlow/ollama output → `raw/drafts/pending/`:
```yaml
---
source: siliconflow | ollama
created: ISO-8601
confidence: 0.85
intent: event
status: pending_review
target_file: raw/events/2026-04-08.md
---
```
Review: wrap-up (Codex batch), session-guard, feishu cron (2h push pending count).

## Classification prompt

Output JSON: intent (event/log/task/simple_query/idea/complex/unknown), confidence (0-1), extracted fields (date, time, project, type, description, duration, reminder_days_before).

## Scripts

- `tools/llm-light.sh` — SiliconFlow MiniMax (5s timeout)
- `tools/llm-local.sh` — ollama fallback (30s timeout)
- `tools/llm-route.sh` — escalation: SiliconFlow → ollama → exit 1

Config: `tools/llm-config.env` (gitignored)

## Connection mode

WebSocket (outbound) via `lark-oapi` SDK `WSClient`. No public IP needed.
Bot connects out to Feishu servers, receives events through the WebSocket.
Managed by systemd (`tools/myjarvis-feishu.service`).
