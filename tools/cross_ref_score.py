#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any

try:
    import yaml  # type: ignore[import-not-found]
except Exception:  # pragma: no cover - optional dependency
    yaml = None


REPO_ROOT = Path(__file__).resolve().parents[1]
PAPERS_DIR = REPO_ROOT / "raw" / "papers" / "parsed"
TOPIC_FILTER = {
    "code-efficiency",
    "performance-optimization",
    "profiling",
    "llm-for-se",
    "code-repair",
    "software-testing",
    "fuzzing",
    "fault-localization",
    "agent-for-se",
    "program-analysis",
}

PROJECT_RULES = {
    "Understand_CodeEffi_ReasoningAbility": {
        "high": [
            "code efficiency",
            "code-efficiency",
            "efficiency reasoning",
            "code optimization",
            "performance reasoning",
            "code repair",
            "program optimization",
            "competitive programming",
            "energy efficiency",
            "runtime complexity",
            "algorithmic optimization",
            "algorithm optimization",
        ],
        "medium": [
            "llm for se",
            "llm-for-se",
            "program analysis",
            "fault localization",
            "fault-localization",
            "code generation",
            "code-generation",
            "code understanding",
            "software quality",
        ],
    },
    "Perf_InputConstraint_Gen": {
        "high": [
            "performance testing",
            "performance stress testing",
            "stress testing",
            "input generation",
            "constraint generation",
            "fuzzing",
            "performance profiling",
            "workload generation",
            "benchmark generation",
            "performance bugs",
            "performance bug",
            "performance-stressing",
            "performance stressing",
            "perfforge",
            "wedge",
            "hssmf",
        ],
        "medium": [
            "software testing",
            "software-testing",
            "fault localization",
            "fault-localization",
            "program analysis",
            "mutation testing",
            "test generation",
            "symbolic execution",
        ],
    },
}

FRONTMATTER_PATTERN = re.compile(
    r"\A(?P<open>---\r?\n)(?P<frontmatter>.*?)(?P<close>\r?\n---(?:\r?\n|$))",
    re.DOTALL,
)
TOP_LEVEL_KEY_PATTERN = re.compile(r"^([A-Za-z0-9_]+):(.*)$")


def warn(message: str) -> None:
    print(f"WARNING: {message}", file=sys.stderr)


def parse_flow_list(value: str) -> list[Any]:
    inner = value[1:-1].strip()
    if inner == "":
        return []

    items: list[str] = []
    current: list[str] = []
    quote_char = ""

    for char in inner:
        if quote_char:
            current.append(char)
            if char == quote_char:
                quote_char = ""
            continue

        if char in {'"', "'"}:
            quote_char = char
            current.append(char)
            continue

        if char == ",":
            items.append("".join(current).strip())
            current = []
            continue

        current.append(char)

    if current:
        items.append("".join(current).strip())

    return [parse_scalar(item) for item in items if item]


def parse_scalar(value: str) -> Any:
    text = value.strip()
    if text == "":
        return ""
    if text in {"[]", "{}"}:
        return [] if text == "[]" else {}
    if text[0] in {'"', "'"} and text[-1] == text[0]:
        inner = text[1:-1]
        if text[0] == '"':
            return inner.replace(r"\\", "\\").replace(r"\"", '"')
        return inner.replace(r"\\", "\\").replace(r"\'", "'")
    if text.startswith("[") and text.endswith("]"):
        return parse_flow_list(text)
    if text.lower() in {"true", "false"}:
        return text.lower() == "true"
    if re.fullmatch(r"-?\d+", text):
        return int(text)
    return text


def fallback_yaml_load(frontmatter_text: str) -> dict[str, Any]:
    data: dict[str, Any] = {}
    lines = frontmatter_text.splitlines()
    index = 0

    while index < len(lines):
        raw_line = lines[index]
        stripped = raw_line.strip()
        if stripped == "":
            index += 1
            continue
        if raw_line.startswith((" ", "\t")):
            raise ValueError(f"unexpected indentation on line {index + 1}")
        if ":" not in raw_line:
            raise ValueError(f"invalid YAML line {index + 1}: {raw_line!r}")

        key, raw_value = raw_line.split(":", 1)
        key = key.strip()
        raw_value = raw_value.strip()
        index += 1

        if raw_value == "":
            items: list[Any] = []
            while index < len(lines):
                candidate = lines[index]
                stripped_candidate = candidate.strip()
                if stripped_candidate == "":
                    index += 1
                    continue
                if not candidate.startswith((" ", "\t")):
                    break
                item = candidate.lstrip()
                if not item.startswith("- "):
                    raise ValueError(
                        f"unsupported block value for {key!r} on line {index + 1}"
                    )
                items.append(parse_scalar(item[2:]))
                index += 1
            data[key] = items
            continue

        data[key] = parse_scalar(raw_value)

    return data


def load_frontmatter(frontmatter_text: str) -> dict[str, Any]:
    parser_errors: list[str] = []

    if yaml is not None:
        try:
            loaded = yaml.safe_load(frontmatter_text)
            if loaded is None:
                return {}
            if not isinstance(loaded, dict):
                raise ValueError("frontmatter is not a mapping")
            return loaded
        except Exception as exc:
            parser_errors.append(f"PyYAML: {exc}")

    try:
        loaded = fallback_yaml_load(frontmatter_text)
        if not isinstance(loaded, dict):
            raise ValueError("fallback parser did not return a mapping")
        return loaded
    except Exception as exc:
        parser_errors.append(f"fallback: {exc}")

    raise ValueError("; ".join(parser_errors))


def normalize_topics(raw_topics: Any) -> list[str]:
    if raw_topics is None or raw_topics == "":
        return []
    if isinstance(raw_topics, str):
        return [raw_topics.strip().lower()] if raw_topics.strip() else []
    if isinstance(raw_topics, list):
        normalized: list[str] = []
        for item in raw_topics:
            if isinstance(item, str):
                token = item.strip().lower()
                if token:
                    normalized.append(token)
        return normalized
    return []


def compute_relevance(search_text: str, rules: dict[str, list[str]]) -> str:
    lowered = search_text.lower()
    if any(keyword in lowered for keyword in rules["high"]):
        return "high"
    if any(keyword in lowered for keyword in rules["medium"]):
        return "medium"
    return ""


def find_entry_spans(frontmatter_text: str) -> tuple[list[str], list[tuple[str, int, int]]]:
    lines = frontmatter_text.splitlines(keepends=True)
    entries: list[tuple[str, int, int]] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        stripped = line.rstrip("\r\n")
        match = TOP_LEVEL_KEY_PATTERN.match(stripped)
        if match and not line.startswith((" ", "\t")):
            start = index
            key = match.group(1)
            index += 1
            while index < len(lines):
                next_line = lines[index]
                next_stripped = next_line.rstrip("\r\n")
                next_match = TOP_LEVEL_KEY_PATTERN.match(next_stripped)
                if next_match and not next_line.startswith((" ", "\t")):
                    break
                index += 1
            entries.append((key, start, index))
            continue
        index += 1

    return lines, entries


def render_field_line(key: str, value: str, append_newline: bool, newline: str) -> str:
    suffix = newline if append_newline else ""
    return f"{key}: {value}{suffix}"


def update_frontmatter_fields(
    frontmatter_text: str, relevance: str, related_projects: list[str]
) -> str:
    lines, entries = find_entry_spans(frontmatter_text)
    newline = "\r\n" if "\r\n" in frontmatter_text else "\n"
    entry_by_start = {start: (key, end) for key, start, end in entries}
    entry_keys = {key for key, _, _ in entries}
    replacement_values = {
        "relevance": f'"{relevance}"' if relevance else '""',
        "related_projects": repr(related_projects) if related_projects else "[]",
    }
    missing_after_topics = [
        key for key in ("relevance", "related_projects") if key not in entry_keys
    ]

    output: list[str] = []
    index = 0
    inserted_after_topics = False

    while index < len(lines):
        entry = entry_by_start.get(index)
        if entry is None:
            output.append(lines[index])
            index += 1
            continue

        key, end = entry
        if key in replacement_values:
            output.append(
                render_field_line(
                    key,
                    replacement_values[key],
                    append_newline=end < len(lines),
                    newline=newline,
                )
            )
        else:
            output.extend(lines[index:end])

        if key == "topics" and missing_after_topics:
            for position, missing_key in enumerate(missing_after_topics):
                has_more_inserted = position < len(missing_after_topics) - 1
                has_more_existing = end < len(lines)
                output.append(
                    render_field_line(
                        missing_key,
                        replacement_values[missing_key],
                        append_newline=has_more_inserted or has_more_existing,
                        newline=newline,
                    )
                )
            inserted_after_topics = True

        index = end

    if missing_after_topics and not inserted_after_topics:
        if output and not output[-1].endswith(("\n", "\r")):
            output[-1] = output[-1] + newline
        for position, missing_key in enumerate(missing_after_topics):
            output.append(
                render_field_line(
                    missing_key,
                    replacement_values[missing_key],
                    append_newline=position < len(missing_after_topics) - 1,
                    newline=newline,
                )
            )

    return "".join(output)


def update_paper(path: Path, summary: dict[str, Any]) -> None:
    summary["total_papers"] += 1

    try:
        original_text = path.read_text(encoding="utf-8")
    except Exception as exc:
        warn(f"{path}: unable to read file: {exc}")
        return

    match = FRONTMATTER_PATTERN.match(original_text)
    if match is None:
        warn(f"{path}: missing or malformed frontmatter delimiters")
        return

    frontmatter_text = match.group("frontmatter")
    try:
        metadata = load_frontmatter(frontmatter_text)
    except Exception as exc:
        warn(f"{path}: skipped malformed frontmatter ({exc})")
        return

    topics = normalize_topics(metadata.get("topics"))
    if not topics:
        summary["skipped_missing_topics"] += 1
        return
    if not any(topic in TOPIC_FILTER for topic in topics):
        summary["skipped_topic_filter"] += 1
        return

    summary["topic_matched_papers"] += 1

    title = metadata.get("title", "")
    abstract_short = metadata.get("abstract_short", "")
    title_text = title if isinstance(title, str) else ""
    abstract_text = abstract_short if isinstance(abstract_short, str) else ""
    search_text = " ".join([title_text, abstract_text, " ".join(topics)]).lower()

    related_projects: list[str] = []
    paper_relevance = ""

    for project_name, rules in PROJECT_RULES.items():
        project_relevance = compute_relevance(search_text, rules)
        if project_relevance:
            related_projects.append(project_name)
            summary["project_counts"][project_name][project_relevance] += 1
            if project_relevance == "high" or paper_relevance != "high":
                paper_relevance = project_relevance

    updated_frontmatter = update_frontmatter_fields(
        frontmatter_text,
        paper_relevance,
        related_projects,
    )
    updated_text = (
        original_text[: match.start("frontmatter")]
        + updated_frontmatter
        + original_text[match.end("frontmatter") :]
    )

    if updated_text != original_text:
        path.write_text(updated_text, encoding="utf-8")
        summary["updated_papers"] += 1


def main() -> int:
    if not PAPERS_DIR.exists():
        print(f"Paper directory not found: {PAPERS_DIR}", file=sys.stderr)
        return 1

    summary: dict[str, Any] = {
        "total_papers": 0,
        "topic_matched_papers": 0,
        "updated_papers": 0,
        "skipped_missing_topics": 0,
        "skipped_topic_filter": 0,
        "project_counts": {
            project_name: {"high": 0, "medium": 0}
            for project_name in PROJECT_RULES
        },
    }

    for path in sorted(PAPERS_DIR.glob("*.md")):
        update_paper(path, summary)

    print(f"Total papers processed: {summary['total_papers']}")
    print(f"Topic-matched papers processed: {summary['topic_matched_papers']}")
    print(f"Papers updated: {summary['updated_papers']}")
    for project_name, counts in summary["project_counts"].items():
        total_linked = counts["high"] + counts["medium"]
        print(f"{project_name}: {total_linked} linked")
        print(f"  high: {counts['high']}")
        print(f"  medium: {counts['medium']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
