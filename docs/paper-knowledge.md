# Paper Knowledge Base

## Ingestion: Zotero CSV

- Raw file: `raw/papers/zotero-library.csv` (UTF-8, BOM handled)
- Parse: `tools/parse-zotero-csv.sh` → `raw/papers/parsed/` one .md per paper

### Field mapping

| CSV Column | Maps to | Notes |
|-----------|---------|-------|
| Key | cite_key | Unique ID |
| Title | title | |
| Author | authors | Semicolon-separated |
| Publication Year | year | |
| Item Type | item_type | conferencePaper, journalArticle, etc. |
| Publication Title | venue | |
| Conference Name | conference | |
| Abstract Note | abstract | |
| Manual Tags | manual_tags | High-value signal |
| Automatic Tags | auto_tags | |
| Notes | zotero_notes | Reading evidence |
| File Attachments | pdf_path | |
| DOI | doi | |
| Url | url | |
| Date Added | date_added | |

### Auto read_status

- Notes non-empty → 精读
- Notes empty + PDF exists → 扫读
- Notes empty + no PDF → 未读

## Compile pipeline

1. **Deterministic parse** (python): CSV → per-paper .md with frontmatter
2. **Topic classification** (ollama): title + abstract → 1-3 topic labels
3. **Cross-reference scoring** (codex): paper × project → relevance + related_projects
4. **Generate papers-index.md** (bash): group by topic, generate tables
5. **Generate papers-\<topic\>.md** (Claude Code): literature synthesis for each topic

## PDF full-text injection (on demand)

Read pdf_path → convert via marker/pymupdf4llm → append to `## Full content` section.

## Paper reading workflow

**Trigger**: User says "读一下这篇论文"
**Process**: Agent reads → user discusses → agent explains/debates

**Session end produces 3 outputs**:

1. **Reading notes** → `wiki/knowledge/papers-<topic>.md` per-paper section
   Content: Core contribution, My assessment, Key findings, Useful for my work, Concerns, Key quotes
   Purpose: compiled cache for future reference

2. **Rule signals** → `raw/claude-sessions/YYYY-MM-DD-HHMM.md`
   Domain: paper-reading. Accumulate 5+ → promote to `wiki/rules/paper-reading/`

3. **Cross-references** → update project wikis
   If user says "这个方法可以用在 XX 项目里" → update Related literature

**Route**: Claude Code (reading) → Codex (extraction) → bash (status update)

## Per-paper .md format

```yaml
---
source: zotero
cite_key: F48EKUC7
title: "Paper title"
authors: [...]
year: 2020
item_type: conferencePaper
venue: "..."
read_status: 精读 | 扫读 | 未读
topics: []
relevance: ""
related_projects: []
ingested: YYYY-MM-DD
---
# Paper title
## Zotero notes
## Abstract
## Reading notes
## Full content
```
