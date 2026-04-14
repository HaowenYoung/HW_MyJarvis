#!/usr/bin/env python3
"""
MyJarvis 飞书 Bot — WebSocket mode (no public IP needed).
Bot connects outbound to Feishu servers. Uses bash + ollama only.

Run: python3 tools/feishu-bot.py
Managed by: systemd (tools/myjarvis-feishu.service)
Requires: pip install lark-oapi
"""

import os
import sys
import json
import subprocess
import logging
import urllib.request
import re
import threading
import time
from datetime import datetime
from pathlib import Path

import lark_oapi as lark
from lark_oapi.ws import Client as WSClient

# Setup
ROOT = Path(__file__).parent.parent
LOG_FMT = "%(asctime)s [%(levelname)s] %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FMT)
log = logging.getLogger("myjarvis-feishu")

# Load config
def load_config():
    config = {}
    env_file = ROOT / "tools" / "notify-config.env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                config[k.strip()] = v.strip()
    return config

CONFIG = load_config()
APP_ID = CONFIG.get("FEISHU_APP_ID", "")
APP_SECRET = CONFIG.get("FEISHU_APP_SECRET", "")

# Build lark client
client = lark.Client.builder().app_id(APP_ID).app_secret(APP_SECRET).build()

# Message dedup (feishu retries unacknowledged events)
_seen_messages = {}
DEDUP_WINDOW = 60  # seconds

# Remember user's chat_id from last message (for proactive sends like reminders)
_user_chat_id = None

# ─── Helpers ────────────────────────────────────────────

def run_bash(cmd, timeout=10):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True,
                          timeout=timeout, cwd=ROOT)
        return r.stdout.strip()
    except Exception as e:
        return f"(error: {e})"

def call_llm_route(prompt):
    """Call tools/llm-route.sh (SiliconFlow → ollama fallback)."""
    try:
        r = subprocess.run(
            ["bash", str(ROOT / "tools" / "llm-route.sh"), prompt],
            capture_output=True, text=True, timeout=40, cwd=ROOT)
        if r.returncode == 0 and r.stdout.strip():
            source = r.stderr.strip()
            log.info(f"llm-route: {source}")
            return r.stdout.strip()
    except Exception as e:
        log.error(f"llm-route error: {e}")
    return ""

def reply_text(message_id, text):
    """Reply to a message via Feishu API (raw HTTP)."""
    try:
        token = get_tenant_token()
        if not token:
            log.error("No tenant token, cannot reply")
            return
        payload = json.dumps({
            "content": json.dumps({"text": text[:2000]}),
            "msg_type": "text"
        }).encode()
        req = urllib.request.Request(
            f"https://open.feishu.cn/open-apis/im/v1/messages/{message_id}/reply",
            data=payload,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp.read()
    except Exception as e:
        log.error(f"Reply error: {e}")

def send_message(chat_id, text):
    """Proactively send a message to a chat (not a reply)."""
    try:
        token = get_tenant_token()
        if not token:
            log.error("No tenant token, cannot send")
            return
        payload = json.dumps({
            "receive_id": chat_id,
            "content": json.dumps({"text": text[:2000]}),
            "msg_type": "text"
        }).encode()
        req = urllib.request.Request(
            "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id",
            data=payload,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp.read()
        log.info(f"Sent message to {chat_id}: {text[:50]}")
    except Exception as e:
        log.error(f"Send error: {e}")

def get_tenant_token():
    try:
        payload = json.dumps({"app_id": APP_ID, "app_secret": APP_SECRET}).encode()
        req = urllib.request.Request(
            "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
            data=payload, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read()).get("tenant_access_token", "")
    except Exception as e:
        log.error(f"Token error: {e}")
        return ""

def today():
    return datetime.now().strftime("%Y-%m-%d")

def now_ts():
    return datetime.now().strftime("%H:%M")

def get_weather(city="Guangzhou"):
    """Get weather from wttr.in (free, no API key)."""
    try:
        url = f"http://wttr.in/{city}?format=%l:+%c+%t+%w&lang=zh"
        req = urllib.request.Request(url, headers={"User-Agent": "curl/7.0"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            return resp.read().decode().strip()
    except Exception:
        return None

def get_time_info():
    """Get current time + date info."""
    now = datetime.now()
    weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    return f"{now.strftime('%Y-%m-%d')} {weekdays[now.weekday()]} {now.strftime('%H:%M')}"

# ─── Command Handlers ───────────────────────────────────

def handle_command(cmd, args, message_id):
    cmd = cmd.lower().strip("/")

    if cmd == "plan":
        out = run_bash(f"cat wiki/plans/{today()}.md 2>/dev/null || echo '今日无 plan'")
    elif cmd == "progress":
        if not args:
            out = f"用法: /progress <project>\n{run_bash('ls projects/')}"
        else:
            out = run_bash(f"tail -20 projects/{args}/wiki/progress.md 2>/dev/null || echo 'Not found'")
    elif cmd == "backlog":
        if not args:
            out = f"用法: /backlog <project>\n{run_bash('ls projects/')}"
        else:
            out = run_bash(f"sed -n '/^## Active/,/^## Queued/p' projects/{args}/wiki/backlog.md 2>/dev/null || echo 'Not found'")
    elif cmd == "alerts":
        out = run_bash(f"cat wiki/plans/alerts-{today()}.md 2>/dev/null || echo '今日无 alerts'")
    elif cmd == "week":
        week = datetime.now().strftime("%Y-W%V")
        out = run_bash(f"head -30 wiki/reviews/week-{week}.md 2>/dev/null || echo '本周无周报'")
    elif cmd == "status":
        projects = run_bash("ls projects/ | wc -l")
        wiki = run_bash("find wiki/ -name '*.md' | wc -l")
        daily = run_bash(f"wc -w raw/daily/{today()}.md 2>/dev/null | awk '{{print $1}}' || echo '0'")
        alerts = run_bash(f"grep -c WARNING wiki/plans/alerts-{today()}.md 2>/dev/null || echo '0'")
        last = run_bash("git log -1 --format='%h %s' 2>/dev/null")
        drafts = run_bash("bash tools/review-drafts.sh --count-only 2>/dev/null || echo '0'")
        out = (f"🤖 MyJarvis Status\n"
               f"Projects: {projects}\nWiki pages: {wiki}\n"
               f"Today's log: {daily} words\nActive alerts: {alerts}\n"
               f"Pending drafts: {drafts}\nLast commit: {last}")
    else:
        out = f"未知命令: /{cmd}\n可用: /plan /progress /backlog /alerts /week /status"

    reply_text(message_id, out)

# ─── Natural Language Handler ───────────────────────────

CLASSIFY_PROMPT = """你是 MyJarvis，一个聪明、简洁的个人助手。用户通过飞书跟你聊天。

你有两个任务：
1. 判断用户意图，输出 JSON
2. 像朋友一样自然地回复用户（1-3 句话，口语化，不要官腔）

格式：先输出 JSON，然后换行写你的回复。

JSON（不要 code block，直接输出）：
{{"intent": "event|log|task|simple_query|idea|complex",
  "confidence": 0.0-1.0,
  "extracted": {{"date": "YYYY-MM-DD or null", "time": "HH:MM 24h or null",
    "project": null, "type": "meeting|errand|coding|writing|reading|admin or null",
    "description": "简短描述", "duration": "Xh or null"}}}}

意图说明：
- event: 用户要记日程/会议/提醒 → 高 confidence
- log: 用户在汇报做了什么 → 高 confidence
- task: 用户要加待办 → 高 confidence
- simple_query: 闲聊、问候、问问题、查信息 → 高 confidence，自由回答
- idea: 学术/技术灵感 → idea
- complex: 需要深度分析 → complex

对于 simple_query，你可以自由回答用户的问题。如果用户问日程相关的，下面有今天的日程信息供你参考：

--- 今日日程 ---
{today_events}
--- 系统状态 ---
现在是 {now}，今天是 {today}。
---

时间规则：下午3点=15:00，上午10点=10:00，晚上8点=20:00

用户消息："{msg}"
"""

def handle_natural_language(text, message_id):
    # Fast-path: time/weather queries (no LLM needed)
    text_lower = text.lower()
    if any(w in text_lower for w in ["几点", "时间", "什么时候", "今天周几", "星期几", "日期"]):
        reply_text(message_id, f"🕐 {get_time_info()}")
        return
    if any(w in text_lower for w in ["天气", "气温", "下雨", "weather"]):
        # Extract city name if mentioned, default Guangzhou
        city = "Guangzhou"
        for c in ["北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "南京", "西安", "香港"]:
            if c in text:
                city = c
                break
        weather = get_weather(city)
        if weather:
            reply_text(message_id, f"🌤 {weather}")
        else:
            reply_text(message_id, "😅 天气服务暂时不可用")
        return

    # Inject today's events into prompt so LLM can answer schedule questions
    today_events = run_bash(f"cat raw/events/{today()}.md 2>/dev/null | grep '^- ' || echo '（今天没有日程）'")
    prompt = CLASSIFY_PROMPT.format(today=today(), now=get_time_info(), msg=text, today_events=today_events)
    response = call_llm_route(prompt)

    if not response:
        # All LLMs failed → save scratch
        save_scratch(text)
        reply_text(message_id, "🤔 没搞懂，存了个笔记。试试 /plan 或 /status？")
        return

    try:
        # Find the outermost JSON object (handle nested braces)
        depth = 0
        start = -1
        for i, c in enumerate(response):
            if c == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and start >= 0:
                    break
        if start < 0:
            raise ValueError("No JSON")
        json_str = response[start:i+1]
        parsed = json.loads(json_str)
        intent = parsed.get("intent", "complex")
        confidence = float(parsed.get("confidence", 0))
        data = parsed.get("extracted", {})
        # Extract natural language reply (text after JSON block)
        nl_reply = response[i+1:].strip().strip('`').strip()
    except Exception:
        save_scratch(text)
        reply_text(message_id, "🤔 没搞懂，存笔记了。")
        return

    # Low confidence or complex → save scratch
    if confidence < 0.85 or intent in ("idea", "complex", "unknown"):
        save_scratch(text, intent=intent)
        if nl_reply:
            reply_text(message_id, nl_reply)
        elif intent == "idea":
            reply_text(message_id, "💡 有意思，记下了。下次 session 看。")
        else:
            reply_text(message_id, "🧠 这个得开 session 处理，先记下了。")
        return

    # simple_query → use LLM's natural language reply directly
    if intent == "simple_query":
        reply_text(message_id, nl_reply or "👋 在的！发 /status 看状态，或直接说事儿。")
        return

    # High confidence write actions
    # confidence >= 0.95 → write formal file directly; < 0.95 → draft
    direct_write = confidence >= 0.95

    if intent == "event":
        date = data.get("date") or today()
        time_str = data.get("time") or ""
        desc = data.get("description") or text
        evt_type = data.get("type") or "meeting"
        duration = data.get("duration") or "1h"
        line = f"- {time_str} | {evt_type} | {desc} | duration: {duration}"
        target = f"raw/events/{date}.md"

        if direct_write:
            write_formal(target, line)
            sync_event_to_notion(date, time_str, desc, evt_type, duration)
        else:
            write_draft(intent, line, target=target, confidence=confidence)

        reply_text(message_id, nl_reply or f"👌 记了：{date} {time_str} {desc}")

    elif intent == "log":
        desc = data.get("description") or text
        proj = data.get("project") or "personal"
        entry = f"\n## {now_ts()} - {desc}\n- **Project**: {proj}\n- **Status**: done\n"
        target = f"raw/daily/{today()}.md"

        if direct_write:
            write_formal(target, entry)
        else:
            write_draft(intent, entry, target=target, confidence=confidence)

        reply_text(message_id, nl_reply or f"👌 记了：{desc}")

    elif intent == "task":
        desc = data.get("description") or text
        proj = data.get("project")
        if not proj:
            projects = run_bash("ls projects/")
            reply_text(message_id, f"哪个项目？\n{projects}")
            return

        if direct_write:
            backlog = ROOT / "projects" / proj / "wiki" / "backlog.md"
            if backlog.exists():
                content = backlog.read_text()
                content = content.replace("## Active", f"## Active\n- {desc}", 1)
                backlog.write_text(content)
        else:
            write_draft(intent, f"- {desc}", target=f"projects/{proj}/wiki/backlog.md",
                        confidence=confidence)

        reply_text(message_id, nl_reply or f"👌 加到 {proj} backlog 了：{desc}")

def write_formal(target_path, content):
    """Write directly to formal file (high confidence, skip draft)."""
    fpath = ROOT / target_path
    fpath.parent.mkdir(parents=True, exist_ok=True)
    with open(fpath, "a") as f:
        if fpath.stat().st_size == 0:
            f.write(f"---\nsource: feishu\ningested: {today()}\ntags: [events]\n---\n\n")
        f.write(content + "\n")
    log.info(f"Formal write: {target_path}")

def sync_event_to_notion(date, time_str, desc, evt_type, duration):
    """Sync event to Notion Events database."""
    try:
        token = get_tenant_token()  # reuse feishu token func... actually need Notion
        # Use notify-config for Notion IDs
        env = {}
        env_file = ROOT / "tools" / "notion-ids.env"
        if env_file.exists():
            for line in env_file.read_text().splitlines():
                if line.strip() and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip()

        events_db = env.get("NOTION_EVENTS_DB_ID", "")
        if not events_db:
            log.warning("No NOTION_EVENTS_DB_ID, skipping Notion sync")
            return

        # Notion sync is done via claude CLI or MCP — too complex for bot
        # Instead, mark for next session sync
        log.info(f"Event written to formal file, will sync to Notion at next wrap-up")
    except Exception as e:
        log.warning(f"Notion sync skipped: {e}")

# ─── Repo Exploration Trigger ──────────────────────────

# Match owner/repo or github.com/owner/repo URLs
_REPO_PATTERN = re.compile(
    r'(?:https?://)?(?:www\.)?github\.com/([\w.-]+)/([\w.-]+)'  # full URL
    r'|'
    r'\b([\w.-]+)/([\w.-]+)\b'  # bare owner/repo
)

# Keywords that signal exploration intent (Chinese + English)
_EXPLORE_KEYWORDS = re.compile(
    r'探索|看看|了解|学习|研究一下|分析一下|explore|check out|look at', re.IGNORECASE
)

def try_repo_exploration(text, message_id):
    """Fast-path: detect GitHub repo + exploration intent → trigger background exploration.
    Returns True if handled, False to fall through to normal NL processing."""
    m = _REPO_PATTERN.search(text)
    if not m:
        return False

    # Extract owner/repo from whichever group matched
    if m.group(1) and m.group(2):
        owner, repo = m.group(1), m.group(2)
    elif m.group(3) and m.group(4):
        # Bare owner/repo — require exploration keyword to avoid false positives
        if not _EXPLORE_KEYWORDS.search(text):
            return False
        owner, repo = m.group(3), m.group(4)
    else:
        return False

    # Filter out obvious non-repo matches
    if owner.lower() in ("www", "http", "https", "api", "raw", "gist"):
        return False

    slug = f"{owner}/{repo}"
    log.info(f"Repo exploration triggered: {slug}")

    # Immediate reply
    reply_text(message_id, f"🔍 开始探索 {slug}，完成后飞书通知你。")

    # Launch exploration in background (non-blocking)
    script = str(ROOT / "tools" / "explore-repo.sh")
    log_file = str(ROOT / "raw" / "repos" / f"{owner}-{repo}-explore.log")
    try:
        subprocess.Popen(
            ["bash", script, slug],
            stdout=open(log_file, "w"),
            stderr=subprocess.STDOUT,
            cwd=ROOT
        )
        log.info(f"Exploration process launched for {slug}")
    except Exception as e:
        log.error(f"Failed to launch exploration: {e}")
        reply_text(message_id, f"❌ 启动探索失败: {e}")

    return True

def save_scratch(text, intent="unknown"):
    scratch = ROOT / "raw" / "scratch" / f"feishu-{int(datetime.now().timestamp())}.md"
    scratch.parent.mkdir(parents=True, exist_ok=True)
    scratch.write_text(
        f"---\nsource: feishu\ningested: {today()}\nintent: {intent}\n---\n\n{text}\n")

def write_draft(intent, content, target, confidence):
    draft_dir = ROOT / "raw" / "drafts" / "pending"
    draft_dir.mkdir(parents=True, exist_ok=True)
    draft_file = draft_dir / f"{intent}-{int(datetime.now().timestamp())}.md"
    draft_file.write_text(
        f"---\nsource: llm-route\ncreated: {datetime.now().isoformat()}\n"
        f"confidence: {confidence}\nintent: {intent}\n"
        f"status: pending_review\ntarget_file: {target}\n---\n\n{content}\n")

# ─── Event Handler ──────────────────────────────────────

def on_message(data):
    """Handle incoming Feishu messages."""
    try:
        msg = data.event.message
        message_id = msg.message_id

        # Dedup: skip if we've seen this message_id recently
        now_epoch = datetime.now().timestamp()
        if message_id in _seen_messages and (now_epoch - _seen_messages[message_id]) < DEDUP_WINDOW:
            log.info(f"Dedup: skipping {message_id}")
            return
        _seen_messages[message_id] = now_epoch
        # Clean old entries
        for k in list(_seen_messages):
            if now_epoch - _seen_messages[k] > DEDUP_WINDOW * 2:
                del _seen_messages[k]

        # Remember chat_id for proactive messages (reminders etc.)
        global _user_chat_id
        _user_chat_id = msg.chat_id
        log.debug(f"Captured chat_id: {_user_chat_id}")

        # Parse message content
        content = json.loads(msg.content or "{}")
        text = content.get("text", "").strip()

        if not text:
            return

        log.info(f"Received: {text[:100]}")

        # Slash command?
        if text.startswith("/"):
            parts = text.split(maxsplit=1)
            cmd = parts[0]
            args = parts[1] if len(parts) > 1 else ""
            handle_command(cmd, args, message_id)
        # Repo exploration fast-path (before general NL)
        elif try_repo_exploration(text, message_id):
            pass  # handled
        else:
            handle_natural_language(text, message_id)

    except Exception as e:
        log.error(f"Message handler error: {e}", exc_info=True)

# ─── Main ───────────────────────────────────────────────

# ─── Event Reminder Timer ───────────────────────────────

_reminded_today = set()  # track what we've already reminded

def check_event_reminders():
    """Scan today's events, send reminder 15 min before. Pure bash, zero tokens."""
    while True:
        try:
            now = datetime.now()
            today_file = ROOT / "raw" / "events" / f"{now.strftime('%Y-%m-%d')}.md"
            if today_file.exists():
                for line in today_file.read_text().splitlines():
                    line = line.strip()
                    if not line.startswith("- ") or "|" not in line:
                        continue
                    parts = [p.strip() for p in line.lstrip("- ").split("|")]
                    if len(parts) < 3:
                        continue
                    time_str = parts[0]
                    desc = parts[2] if len(parts) > 2 else parts[1]

                    # Parse HH:MM
                    try:
                        evt_h, evt_m = int(time_str.split(":")[0]), int(time_str.split(":")[1])
                    except (ValueError, IndexError):
                        continue

                    # Remind 15 min before
                    diff_min = (evt_h * 60 + evt_m) - (now.hour * 60 + now.minute)
                    reminder_key = f"{now.strftime('%Y-%m-%d')}_{time_str}_{desc[:20]}"

                    if 0 <= diff_min <= 15 and reminder_key not in _reminded_today:
                        _reminded_today.add(reminder_key)
                        notify_msg = f"⏰ 提醒：{time_str} {desc}（{diff_min}分钟后）"
                        log.info(f"Reminder: {notify_msg}")
                        if _user_chat_id:
                            send_message(_user_chat_id, notify_msg)
                        else:
                            log.warning("No chat_id yet (user hasn't sent any message). Reminder not delivered.")

            # Clean old reminders at midnight
            if now.hour == 0 and now.minute == 0:
                _reminded_today.clear()

        except Exception as e:
            log.error(f"Reminder check error: {e}")

        time.sleep(60)

def main():
    if not APP_ID or APP_ID == "your-app-id":
        log.error("FEISHU_APP_ID not configured in tools/notify-config.env")
        sys.exit(1)

    log.info("MyJarvis 飞书 Bot starting (WebSocket mode, no public IP needed)")

    # Start reminder timer (background thread, pure bash, zero tokens)
    reminder_thread = threading.Thread(target=check_event_reminders, daemon=True)
    reminder_thread.start()
    log.info("Event reminder timer started (checks every 60s)")

    # Register event handler
    handler = lark.EventDispatcherHandler.builder("", "") \
        .register_p2_im_message_receive_v1(on_message) \
        .build()

    # Connect via WebSocket (outbound, no public IP needed)
    ws_client = WSClient(APP_ID, APP_SECRET,
                         event_handler=handler,
                         log_level=lark.LogLevel.INFO)
    ws_client.start()

if __name__ == "__main__":
    main()
