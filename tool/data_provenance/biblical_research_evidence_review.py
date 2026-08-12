#!/usr/bin/env python3
"""Evidence Packet JSON을 사람이 비교하기 쉬운 Markdown Review로 렌더링한다."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


SUPPORTED_SCHEMA_VERSION = 1
EXPECTED_TOOL_NAME = "Reshet Biblical Research Evidence Packet Generator"

LOCAL_SOURCE_ORDER = (
    ("korean_revised", "개역개정"),
    ("korean_revised_legacy", "개역한글"),
    ("kjv", "KJV"),
    ("original_language_analysis", "원전분해"),
    ("korean_new_translation", "새번역"),
)
COMPACT_SOURCE_ORDER = LOCAL_SOURCE_ORDER[:4]


class EvidenceReviewError(RuntimeError):
    """지원하는 Evidence Packet 구조가 아니거나 렌더링할 수 없을 때 발생한다."""


def _object(value: object, path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise EvidenceReviewError(f"{path}는 JSON object여야 함")
    return value


def _list(value: object, path: str) -> list[Any]:
    if not isinstance(value, list):
        raise EvidenceReviewError(f"{path}는 JSON array여야 함")
    return value


def _string(value: object, path: str, *, nullable: bool = False) -> str | None:
    if nullable and value is None:
        return None
    if not isinstance(value, str):
        raise EvidenceReviewError(f"{path}는 문자열이어야 함")
    return value


def _integer(value: object, path: str) -> int:
    if type(value) is not int or value < 0:
        raise EvidenceReviewError(f"{path}는 0 이상의 정수여야 함")
    return value


def _boolean(value: object, path: str) -> bool:
    if not isinstance(value, bool):
        raise EvidenceReviewError(f"{path}는 boolean이어야 함")
    return value


def _required(payload: dict[str, Any], key: str, path: str) -> Any:
    if key not in payload:
        raise EvidenceReviewError(f"{path}.{key} 필드가 없음")
    return payload[key]


def _validate_string_list(value: object, path: str) -> list[str]:
    rows = _list(value, path)
    for index, row in enumerate(rows):
        _string(row, f"{path}[{index}]")
    return rows


def _validate_local_reference(value: object, path: str) -> None:
    reference = _object(value, path)
    _string(_required(reference, "status", path), f"{path}.status")
    _string(
        _required(reference, "requested_canonical_verse_key", path),
        f"{path}.requested_canonical_verse_key",
    )
    records = _list(_required(reference, "records", path), f"{path}.records")
    for record_index, raw_record in enumerate(records):
        record_path = f"{path}.records[{record_index}]"
        record = _object(raw_record, record_path)
        _string(_required(record, "source_verse_key", record_path), f"{record_path}.source_verse_key")
        _string(_required(record, "full_verse", record_path), f"{record_path}.full_verse")
        _validate_string_list(
            _required(record, "matched_translation_tokens", record_path),
            f"{record_path}.matched_translation_tokens",
        )
        if "matched_source_entries" in record:
            entries = _list(
                record["matched_source_entries"],
                f"{record_path}.matched_source_entries",
            )
            for entry_index, raw_entry in enumerate(entries):
                entry_path = f"{record_path}.matched_source_entries[{entry_index}]"
                entry = _object(raw_entry, entry_path)
                for key in (
                    "surface",
                    "lemma",
                    "morphology",
                    "translation",
                    "transliteration",
                ):
                    if key in entry:
                        _string(entry[key], f"{entry_path}.{key}", nullable=True)


def validate_packet(value: object) -> dict[str, Any]:
    packet = _object(value, "packet")
    schema_version = _required(packet, "schema_version", "packet")
    if schema_version != SUPPORTED_SCHEMA_VERSION:
        raise EvidenceReviewError(
            "지원하지 않는 Evidence Packet schema_version: "
            f"{schema_version!r}; supported={SUPPORTED_SCHEMA_VERSION}"
        )

    tool = _object(_required(packet, "tool", "packet"), "packet.tool")
    tool_name = _string(
        _required(tool, "name", "packet.tool"), "packet.tool.name"
    )
    if tool_name != EXPECTED_TOOL_NAME:
        raise EvidenceReviewError(f"지원하지 않는 Evidence Packet tool: {tool_name!r}")

    target = _object(_required(packet, "target", "packet"), "packet.target")
    for key in ("normalized_strong", "language"):
        _string(_required(target, key, "packet.target"), f"packet.target.{key}")
    for key in ("canonical_headword", "transliteration"):
        _string(
            _required(target, key, "packet.target"),
            f"packet.target.{key}",
            nullable=True,
        )
    projections = _list(
        _required(target, "existing_reshet_projection", "packet.target"),
        "packet.target.existing_reshet_projection",
    )
    for projection_index, raw_projection in enumerate(projections):
        projection_path = f"packet.target.existing_reshet_projection[{projection_index}]"
        projection = _object(raw_projection, projection_path)
        expressions = _list(
            _required(projection, "expressions", projection_path),
            f"{projection_path}.expressions",
        )
        meanings = _list(
            _required(projection, "meanings", projection_path),
            f"{projection_path}.meanings",
        )
        for expression_index, raw_expression in enumerate(expressions):
            expression_path = f"{projection_path}.expressions[{expression_index}]"
            expression = _object(raw_expression, expression_path)
            _string(
                _required(expression, "spelling", expression_path),
                f"{expression_path}.spelling",
            )
            if "transliteration" in expression:
                _string(
                    expression["transliteration"],
                    f"{expression_path}.transliteration",
                    nullable=True,
                )
        for meaning_index, raw_meaning in enumerate(meanings):
            meaning_path = f"{projection_path}.meanings[{meaning_index}]"
            meaning = _object(raw_meaning, meaning_path)
            _string(
                _required(meaning, "meaning", meaning_path),
                f"{meaning_path}.meaning",
            )

    completion = _object(
        _required(target, "completion_gate", "packet.target"),
        "packet.target.completion_gate",
    )
    _string(
        _required(completion, "state", "packet.target.completion_gate"),
        "packet.target.completion_gate.state",
    )
    if "interpretation" in completion:
        _string(
            completion["interpretation"],
            "packet.target.completion_gate.interpretation",
        )

    direct_references = _list(
        _required(packet, "direct_references", "packet"),
        "packet.direct_references",
    )
    for index, raw_reference in enumerate(direct_references):
        path = f"packet.direct_references[{index}]"
        reference = _object(raw_reference, path)
        _string(
            _required(reference, "normalized_strong", path),
            f"{path}.normalized_strong",
            nullable=True,
        )
        _string(_required(reference, "raw_reference", path), f"{path}.raw_reference")
        if "warning" in reference:
            _string(reference["warning"], f"{path}.warning", nullable=True)

    strong_window = _object(
        _required(packet, "strong_window", "packet"), "packet.strong_window"
    )
    window_items = _list(
        _required(strong_window, "items", "packet.strong_window"),
        "packet.strong_window.items",
    )
    for index, raw_item in enumerate(window_items):
        path = f"packet.strong_window.items[{index}]"
        item = _object(raw_item, path)
        _string(_required(item, "strong", path), f"{path}.strong")
        _boolean(_required(item, "present", path), f"{path}.present")
        _string(
            _required(item, "headword", path), f"{path}.headword", nullable=True
        )
        _boolean(
            _required(item, "direct_reference_from_target", path),
            f"{path}.direct_reference_from_target",
        )
        source_meanings = _list(
            _required(item, "source_meanings", path), f"{path}.source_meanings"
        )
        for meaning_index, raw_meaning in enumerate(source_meanings):
            meaning_path = f"{path}.source_meanings[{meaning_index}]"
            meaning = _object(raw_meaning, meaning_path)
            _string(
                _required(meaning, "text", meaning_path), f"{meaning_path}.text"
            )

    summary = _object(_required(packet, "summary", "packet"), "packet.summary")
    _integer(
        _required(summary, "canonical_occurrence_count", "packet.summary"),
        "packet.summary.canonical_occurrence_count",
    )
    _integer(
        _required(summary, "canonical_verse_count", "packet.summary"),
        "packet.summary.canonical_verse_count",
    )
    translation_expressions = _object(
        _required(summary, "translation_expressions", "packet.summary"),
        "packet.summary.translation_expressions",
    )
    for source_id, _ in LOCAL_SOURCE_ORDER:
        rows = _list(
            _required(
                translation_expressions,
                source_id,
                "packet.summary.translation_expressions",
            ),
            f"packet.summary.translation_expressions.{source_id}",
        )
        for row_index, raw_row in enumerate(rows):
            row_path = (
                f"packet.summary.translation_expressions.{source_id}[{row_index}]"
            )
            row = _object(raw_row, row_path)
            _string(_required(row, "value", row_path), f"{row_path}.value")
            _integer(_required(row, "count", row_path), f"{row_path}.count")

    occurrences = _list(
        _required(packet, "canonical_occurrences", "packet"),
        "packet.canonical_occurrences",
    )
    if len(occurrences) != summary["canonical_occurrence_count"]:
        raise EvidenceReviewError(
            "canonical_occurrences 길이와 summary.canonical_occurrence_count가 다름"
        )
    for occurrence_index, raw_occurrence in enumerate(occurrences):
        occurrence_path = f"packet.canonical_occurrences[{occurrence_index}]"
        occurrence = _object(raw_occurrence, occurrence_path)
        for key in (
            "canonical_verse_key",
            "surface",
            "lemma",
            "morphology",
            "normalized_standard_strong",
        ):
            _string(
                _required(occurrence, key, occurrence_path),
                f"{occurrence_path}.{key}",
                nullable=key == "normalized_standard_strong",
            )
        warnings = _validate_string_list(
            _required(occurrence, "warnings", occurrence_path),
            f"{occurrence_path}.warnings",
        )
        if not isinstance(warnings, list):  # pragma: no cover - helper contract
            raise AssertionError("warnings validation failed")
        local_references = _object(
            _required(occurrence, "local_references", occurrence_path),
            f"{occurrence_path}.local_references",
        )
        for source_id, _ in LOCAL_SOURCE_ORDER:
            _validate_local_reference(
                _required(local_references, source_id, f"{occurrence_path}.local_references"),
                f"{occurrence_path}.local_references.{source_id}",
            )

    provenance = _object(
        _required(packet, "provenance", "packet"), "packet.provenance"
    )
    for key in ("strong_sources", "occurrence_sources", "local_reference_sources"):
        _list(_required(provenance, key, "packet.provenance"), f"packet.provenance.{key}")
    work_database = _object(
        _required(provenance, "work_database", "packet.provenance"),
        "packet.provenance.work_database",
    )
    _boolean(
        _required(work_database, "unchanged", "packet.provenance.work_database"),
        "packet.provenance.work_database.unchanged",
    )
    return packet


def load_packet(path: Path) -> dict[str, Any]:
    try:
        raw = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise EvidenceReviewError(f"Evidence Packet을 읽을 수 없음: {path}: {error}") from error
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        raise EvidenceReviewError(f"Evidence Packet JSON parsing 실패: {error}") from error
    return validate_packet(value)


def _inline(value: object, *, empty: str = "—") -> str:
    if value is None:
        return empty
    text = " ".join(str(value).split())
    if not text:
        return empty
    return (
        text.replace("\\", "\\\\")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("|", "\\|")
        .replace("`", "\\`")
    )


def _short_gloss(value: object, limit: int = 80) -> str:
    text = _inline(value)
    if len(text) <= limit:
        return text
    return text[: limit - 1].rstrip() + "…"


def _joined(values: list[object]) -> str:
    rendered = [_inline(value) for value in values if value is not None and str(value)]
    return " / ".join(rendered) if rendered else "—"


def _reshet_expressions(target: dict[str, Any]) -> list[str]:
    values: list[str] = []
    for projection in target["existing_reshet_projection"]:
        for expression in projection["expressions"]:
            spelling = expression["spelling"]
            transliteration = expression.get("transliteration")
            if transliteration:
                values.append(f"{spelling} ({transliteration})")
            else:
                values.append(spelling)
    return values


def _reshet_meanings(target: dict[str, Any]) -> list[str]:
    return [
        meaning["meaning"]
        for projection in target["existing_reshet_projection"]
        for meaning in projection["meanings"]
    ]


def _direct_reference_label(reference: dict[str, Any]) -> str:
    normalized = reference["normalized_strong"]
    if normalized is not None:
        return str(normalized)
    warning = reference.get("warning")
    suffix = f" [{warning}]" if warning else ""
    return f"raw:{reference['raw_reference']}{suffix}"


def _first_source_gloss(item: dict[str, Any]) -> str:
    for meaning in item["source_meanings"]:
        text = meaning["text"]
        if text:
            return _short_gloss(text)
    return "—"


def _compact_reference(reference: dict[str, Any], source_id: str) -> str:
    if reference["status"] == "unmatched":
        return "unmatched"
    values: list[str] = []
    for record in reference["records"]:
        if source_id == "original_language_analysis":
            entries = record.get("matched_source_entries", [])
            entry_values = [
                entry.get("translation")
                for entry in entries
                if entry.get("translation")
            ]
            if entry_values:
                values.extend(entry_values)
                continue
        values.extend(record["matched_translation_tokens"])
    return _joined(values)


def _verified_strong_sources(provenance: dict[str, Any]) -> bool:
    sources = provenance["strong_sources"]
    return bool(sources) and all(source.get("hash_verified") is True for source in sources)


def _verified_occurrence_sources(provenance: dict[str, Any]) -> bool:
    sources = provenance["occurrence_sources"]
    files = [raw_file for source in sources for raw_file in source.get("files", [])]
    return bool(files) and all(raw_file.get("hash_verified") is True for raw_file in files)


def _verified_local_sources(provenance: dict[str, Any]) -> bool:
    sources = provenance["local_reference_sources"]
    return bool(sources) and all(source.get("hash_verified") is True for source in sources)


def _yes_no(value: bool) -> str:
    return "yes" if value else "no"


def _render_target(lines: list[str], packet: dict[str, Any]) -> None:
    target = packet["target"]
    summary = packet["summary"]
    completion = target["completion_gate"]
    strong = _inline(target["normalized_strong"])
    headword = _inline(target["canonical_headword"])
    lines.extend(
        [
            f"# {strong} {headword}".rstrip(),
            "",
            f"- 음역: {_inline(target['transliteration'])}",
            f"- 언어: {_inline(target['language'])}",
            "- 성경 출현: "
            f"{summary['canonical_occurrence_count']}회 / "
            f"{summary['canonical_verse_count']}절",
            f"- 현재 Reshet 표현: {_joined(_reshet_expressions(target))}",
            f"- 현재 Reshet 의미: {_joined(_reshet_meanings(target))}",
            f"- 완료 상태: `{_inline(completion['state'])}`",
        ]
    )
    if completion.get("interpretation"):
        lines.append(f"- 완료 상태 해석: {_inline(completion['interpretation'])}")
    direct = [_direct_reference_label(row) for row in packet["direct_references"]]
    lines.append(f"- 직접 참조: {_joined(direct)}")


def _render_strong_window(lines: list[str], packet: dict[str, Any]) -> None:
    lines.extend(
        [
            "",
            "## Strong ±10",
            "",
            "> 번호 인접성은 relation을 의미하지 않는다. source gloss는 표 읽기를 위해 짧게 표시한다.",
            "",
            "| Strong | 표제어 | 간단 source gloss | direct |",
            "|---|---|---|---|",
        ]
    )
    for item in packet["strong_window"]["items"]:
        lines.append(
            "| "
            f"{_inline(item['strong'])} | "
            f"{_inline(item['headword'])} | "
            f"{_first_source_gloss(item)} | "
            f"{'✓' if item['direct_reference_from_target'] else '—'} |"
        )


def _render_translation_frequencies(lines: list[str], packet: dict[str, Any]) -> None:
    expressions = packet["summary"]["translation_expressions"]
    lines.extend(
        [
            "",
            "## 번역 표현 빈도",
            "",
            "> packet의 raw matched expression을 그대로 집계한 값이다. 형태를 합치거나 meaning 빈도로 해석하지 않는다.",
        ]
    )
    for source_id, label in LOCAL_SOURCE_ORDER:
        lines.extend(["", f"### {label}", ""])
        if source_id == "korean_new_translation":
            lines.append("자동 target 표현 집계 N/A — verse-level reference only")
            continue
        rows = expressions[source_id]
        if not rows:
            lines.append("집계된 target 표현 없음.")
            continue
        lines.extend(["| 표현 | 횟수 |", "|---|---:|"])
        for row in rows:
            lines.append(f"| {_inline(row['value'])} | {row['count']} |")


def _render_occurrence_table(lines: list[str], packet: dict[str, Any]) -> None:
    lines.extend(
        [
            "",
            "## Occurrence 비교표",
            "",
            "| 구절 | 원어형 | 형태 | 개역개정 | 개역한글 | KJV | 원전분해 |",
            "|---|---|---|---|---|---|---|",
        ]
    )
    for occurrence in packet["canonical_occurrences"]:
        references = occurrence["local_references"]
        values = [
            _compact_reference(references[source_id], source_id)
            for source_id, _ in COMPACT_SOURCE_ORDER
        ]
        lines.append(
            "| "
            f"{_inline(occurrence['canonical_verse_key'])} | "
            f"{_inline(occurrence['surface'])} | "
            f"{_inline(occurrence['morphology'])} | "
            + " | ".join(values)
            + " |"
        )


def _render_source_detail(
    lines: list[str], source_id: str, label: str, reference: dict[str, Any]
) -> None:
    lines.extend(["", f"#### {label}", "", f"- 상태: `{_inline(reference['status'])}`"])
    if source_id == "korean_new_translation":
        lines.append("- target 표현: N/A — verse-level reference only")
    if not reference["records"]:
        lines.append("- 자료: unmatched")
        return
    for index, record in enumerate(reference["records"], start=1):
        prefix = f"자료 {index}" if len(reference["records"]) > 1 else "자료"
        lines.append(
            f"- {prefix} 구절: `{_inline(record['source_verse_key'])}`"
        )
        lines.append(f"- {prefix} 본문: {_inline(record['full_verse'])}")
        if source_id != "korean_new_translation":
            lines.append(
                f"- {prefix} matched 표현: "
                f"{_joined(record['matched_translation_tokens'])}"
            )
        if source_id == "original_language_analysis":
            for entry_index, entry in enumerate(
                record.get("matched_source_entries", []), start=1
            ):
                parts = [
                    f"표면형={_inline(entry.get('surface'))}",
                    f"lemma={_inline(entry.get('lemma'))}",
                    f"음역={_inline(entry.get('transliteration'))}",
                    f"형태={_inline(entry.get('morphology'))}",
                    f"번역={_inline(entry.get('translation'))}",
                ]
                lines.append(
                    f"- {prefix} matched source entry {entry_index}: "
                    + "; ".join(parts)
                )


def _render_occurrence_details(lines: list[str], packet: dict[str, Any]) -> None:
    lines.extend(
        [
            "",
            "## Occurrence 상세",
            "",
            "필요한 구절만 펼쳐 원문 전체와 verse-level 참고자료를 확인한다.",
        ]
    )
    for occurrence in packet["canonical_occurrences"]:
        summary = (
            f"{_inline(occurrence['canonical_verse_key'])} — "
            f"{_inline(occurrence['surface'])} / {_inline(occurrence['morphology'])}"
        )
        lines.extend(
            [
                "",
                "<details>",
                f"<summary>{summary}</summary>",
                "",
                f"- canonical verse: `{_inline(occurrence['canonical_verse_key'])}`",
                f"- 원어형: {_inline(occurrence['surface'])}",
                f"- lemma: {_inline(occurrence['lemma'])}",
                f"- morphology: {_inline(occurrence['morphology'])}",
                "- normalized Strong: "
                f"`{_inline(occurrence['normalized_standard_strong'])}`",
            ]
        )
        if occurrence.get("source_reference_raw"):
            lines.append(
                f"- source reference: `{_inline(occurrence['source_reference_raw'])}`"
            )
        if occurrence["warnings"]:
            lines.append(f"- warning: {_joined(occurrence['warnings'])}")
        else:
            lines.append("- warning: —")
        for source_id, label in LOCAL_SOURCE_ORDER:
            _render_source_detail(
                lines,
                source_id,
                label,
                occurrence["local_references"][source_id],
            )
        lines.extend(["", "</details>"])


def _render_provenance(lines: list[str], packet: dict[str, Any]) -> None:
    provenance = packet["provenance"]
    work_database = provenance["work_database"]
    work_unchanged = work_database["unchanged"] is True
    if "sha256_before" in work_database and "sha256_after" in work_database:
        work_unchanged = work_unchanged and (
            work_database["sha256_before"] == work_database["sha256_after"]
        )
    lines.extend(
        [
            "",
            "## Provenance",
            "",
            f"- Evidence Packet schema: `{packet['schema_version']}`",
            "- Strong source verified: "
            f"{_yes_no(_verified_strong_sources(provenance))}",
            "- Occurrence source verified: "
            f"{_yes_no(_verified_occurrence_sources(provenance))}",
            "- Local reference source hashes verified: "
            f"{_yes_no(_verified_local_sources(provenance))}",
            f"- Work DB unchanged: {_yes_no(work_unchanged)}",
            "",
            "> 이 Review는 사람이 읽기 위한 파생 view다. 전체 machine-readable evidence와 정확한 provenance는 입력 JSON을 참조한다.",
        ]
    )


def render_review(value: object) -> str:
    packet = validate_packet(value)
    lines: list[str] = []
    _render_target(lines, packet)
    _render_strong_window(lines, packet)
    _render_translation_frequencies(lines, packet)
    _render_occurrence_table(lines, packet)
    _render_occurrence_details(lines, packet)
    _render_provenance(lines, packet)
    return "\n".join(lines) + "\n"


def serialize_review(value: object) -> bytes:
    return render_review(value).encode("utf-8")


def write_review_file(
    evidence_packet_path: Path, output_path: Path, output: bytes
) -> None:
    if evidence_packet_path.resolve() == output_path.resolve():
        raise EvidenceReviewError(
            "Evidence Packet 입력 파일과 Review 출력 파일은 달라야 함"
        )
    try:
        output_path.write_bytes(output)
    except OSError as error:
        raise EvidenceReviewError(
            f"Markdown Review 파일을 쓸 수 없음: {output_path}: {error}"
        ) from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Evidence Packet JSON을 결정적인 Markdown Review로 렌더링합니다."
    )
    parser.add_argument("evidence_packet", type=Path, help="Evidence Packet JSON 경로")
    parser.add_argument(
        "--output",
        type=Path,
        help="PowerShell 변환을 거치지 않고 UTF-8 Markdown을 직접 기록할 경로",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        packet = load_packet(args.evidence_packet)
        output = serialize_review(packet)
    except EvidenceReviewError as error:
        sys.stderr.reconfigure(encoding="utf-8", errors="strict", newline="\n")
        print(f"오류: {error}", file=sys.stderr)
        return 2
    if args.output is None:
        sys.stdout.buffer.write(output)
    else:
        try:
            write_review_file(args.evidence_packet, args.output, output)
        except EvidenceReviewError as error:
            sys.stderr.reconfigure(encoding="utf-8", errors="strict", newline="\n")
            print(f"오류: {error}", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
