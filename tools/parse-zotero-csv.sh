#!/usr/bin/env python3
"""
parse-zotero-csv.sh — Parse Zotero CSV export into per-paper markdown files.
Usage: tools/parse-zotero-csv.sh raw/papers/zotero-library.csv
Output: raw/papers/parsed/ directory with one .md per paper.
"""
import csv, sys, os, re
from datetime import date

if len(sys.argv) < 2:
    print("Usage: tools/parse-zotero-csv.sh <zotero-library.csv>", file=sys.stderr)
    sys.exit(1)

input_csv = sys.argv[1]
output_dir = "raw/papers/parsed"
os.makedirs(output_dir, exist_ok=True)

today = date.today().isoformat()
count = 0

with open(input_csv, encoding='utf-8-sig') as f:  # utf-8-sig strips BOM
    reader = csv.DictReader(f)
    for row in reader:
        key = row.get('Key', '').strip()
        if not key:
            continue

        title = row.get('Title', '').strip()
        authors = row.get('Author', '').strip()
        year = row.get('Publication Year', '').strip()
        venue = row.get('Conference Name') or row.get('Publication Title') or ''
        venue = venue.strip()
        abstract = row.get('Abstract Note', '').strip()
        manual_tags = row.get('Manual Tags', '').strip()
        auto_tags = row.get('Automatic Tags', '').strip()
        notes = row.get('Notes', '').strip()
        pdf = row.get('File Attachments', '').strip()
        doi = row.get('DOI', '').strip()
        url = row.get('Url', '').strip()
        date_added = row.get('Date Added', '').strip()
        item_type = row.get('Item Type', '').strip()

        # Determine read status
        if notes:
            read_status = "精读"
        elif pdf:
            read_status = "扫读"
        else:
            read_status = "未读"

        # Build filename: first-author-year-title-slug.md
        first_author = 'unknown'
        if authors:
            first_author = authors.split(';')[0].split(',')[0].strip().lower()
            first_author = re.sub(r'[^a-z0-9]', '', first_author)
        title_slug = re.sub(r'[^a-z0-9]+', '-', title.lower())[:40].strip('-')
        filename = f"{first_author}-{year}-{title_slug}.md"

        # Format tags as lists
        mt = [t.strip() for t in manual_tags.split(';') if t.strip()] if manual_tags else []
        at = [t.strip() for t in auto_tags.split(';') if t.strip()] if auto_tags else []

        # Escape quotes in title for YAML
        title_escaped = title.replace('"', '\\"')
        venue_escaped = venue.replace('"', '\\"')
        abstract_short = abstract[:200].replace('"', '\\"')

        content = f"""---
source: zotero
cite_key: {key}
title: "{title_escaped}"
authors: [{authors}]
year: {year}
item_type: {item_type}
venue: "{venue_escaped}"
abstract_short: "{abstract_short}..."
manual_tags: {mt}
auto_tags: {at}
read_status: {read_status}
pdf_path: "{pdf}"
doi: "{doi}"
url: "{url}"
date_added: "{date_added}"
topics: []
relevance: ""
related_projects: []
ingested: "{today}"
---

# {title}

## Zotero notes
{notes if notes else "(无笔记)"}

## Abstract
{abstract if abstract else "(无摘要)"}

## Reading notes
(paper reading session 后自动填充)

## Full content
(按需注入 PDF 全文)
"""
        filepath = os.path.join(output_dir, filename)
        with open(filepath, 'w', encoding='utf-8') as out:
            out.write(content)
        count += 1

print(f"Parsed {count} papers to {output_dir}/")
