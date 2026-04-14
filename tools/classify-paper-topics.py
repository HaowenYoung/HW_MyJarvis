#!/usr/bin/env python3
"""
classify-paper-topics.py — Batch topic classification for parsed papers via ollama API.
Usage: python3 tools/classify-paper-topics.py [--batch-size 10] [--limit N]
Reads raw/papers/parsed/*.md, calls ollama qwen3:32b for topic labels,
writes topics back into each paper's frontmatter.
"""
import os, sys, json, re, glob, time
import urllib.request

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "qwen3:32b"
PARSED_DIR = "raw/papers/parsed"
BATCH_SIZE = int(sys.argv[sys.argv.index("--batch-size")+1]) if "--batch-size" in sys.argv else 10
LIMIT = int(sys.argv[sys.argv.index("--limit")+1]) if "--limit" in sys.argv else 0

# Predefined topic palette (ollama picks from these or creates new ones)
TOPIC_HINT = """
Topics to choose from (pick 1-3 per paper, or create a new topic if none fit):
- code-efficiency, performance-optimization, code-generation, code-repair
- program-analysis, static-analysis, dynamic-analysis, profiling
- software-testing, fuzzing, mutation-testing, test-generation
- bug-detection, fault-localization, root-cause-analysis
- LLM-for-SE, code-LLM, agent-for-SE, prompt-engineering
- software-maintenance, code-review, code-quality, technical-debt
- empirical-study, mining-software-repos, developer-study
- machine-learning, deep-learning, anomaly-detection
- other (specify)
"""

def call_ollama(prompt, max_tokens=512):
    payload = json.dumps({
        "model": MODEL,
        "prompt": "/no_think " + prompt,
        "stream": False,
        "options": {"num_predict": max_tokens, "temperature": 0.3}
    }).encode()
    req = urllib.request.Request(OLLAMA_URL, data=payload,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read()).get("response", "")
    except Exception as e:
        print(f"  ollama error: {e}", file=sys.stderr)
        return ""

def extract_frontmatter(filepath):
    with open(filepath, encoding='utf-8') as f:
        content = f.read()
    m = re.match(r'^---\n(.*?)\n---\n(.*)$', content, re.DOTALL)
    if not m:
        return None, content
    return m.group(1), m.group(2)

def get_field(fm, field):
    m = re.search(rf'^{field}:\s*(.+)$', fm, re.MULTILINE)
    return m.group(1).strip().strip('"') if m else ""

def update_topics(filepath, topics_list):
    with open(filepath, encoding='utf-8') as f:
        content = f.read()
    topics_str = str(topics_list)
    content = re.sub(r'^topics:\s*\[.*?\]', f'topics: {topics_str}', content, count=1, flags=re.MULTILINE)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# Collect papers needing classification
papers = []
for fp in sorted(glob.glob(f"{PARSED_DIR}/*.md")):
    fm, _ = extract_frontmatter(fp)
    if not fm:
        continue
    existing = get_field(fm, "topics")
    if existing and existing != "[]":
        continue  # already classified
    title = get_field(fm, "title")
    abstract_short = get_field(fm, "abstract_short")
    tags = get_field(fm, "manual_tags")
    if not title:
        continue
    papers.append({"path": fp, "title": title, "abstract": abstract_short, "tags": tags})

if LIMIT > 0:
    papers = papers[:LIMIT]

print(f"Papers to classify: {len(papers)} (batch size: {BATCH_SIZE})")

# Process in batches
classified = 0
for i in range(0, len(papers), BATCH_SIZE):
    batch = papers[i:i+BATCH_SIZE]

    # Build batch prompt
    lines = []
    for j, p in enumerate(batch):
        lines.append(f"{j+1}. Title: {p['title']}")
        if p['abstract']:
            lines.append(f"   Abstract: {p['abstract'][:200]}")
        if p['tags'] and p['tags'] != '[]':
            lines.append(f"   Tags: {p['tags']}")

    prompt = f"""Classify each paper into 1-3 topics. Output ONLY a JSON array of arrays.
Example: [["code-efficiency", "LLM-for-SE"], ["bug-detection"], ["fuzzing", "test-generation"]]

{TOPIC_HINT}

Papers:
{chr(10).join(lines)}

Output the JSON array (one inner array per paper, same order):"""

    response = call_ollama(prompt, max_tokens=1024)

    # Parse response — find JSON array
    try:
        # Extract JSON from response
        json_match = re.search(r'\[.*\]', response, re.DOTALL)
        if json_match:
            topics_batch = json.loads(json_match.group())
        else:
            print(f"  Batch {i//BATCH_SIZE+1}: no JSON in response, skipping", file=sys.stderr)
            continue
    except json.JSONDecodeError:
        print(f"  Batch {i//BATCH_SIZE+1}: JSON parse error, skipping", file=sys.stderr)
        continue

    # Apply topics
    for j, p in enumerate(batch):
        if j < len(topics_batch):
            topics = topics_batch[j]
            if isinstance(topics, list):
                topics = [t.strip().lower() for t in topics if isinstance(t, str)]
                update_topics(p['path'], topics)
                classified += 1

    done = min(i + BATCH_SIZE, len(papers))
    print(f"  Batch {i//BATCH_SIZE+1}: classified {done}/{len(papers)}")

print(f"\nDone: {classified} papers classified.")
