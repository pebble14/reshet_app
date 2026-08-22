#!/usr/bin/env python3
"""전체 canonical Strong의 semantic 진행 현황 derivative report를 생성한다."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
from typing import Iterable

import biblical_research_evidence_packet as evidence
import lexical_relation_discovery as discovery
import semantic_research_batch as research_batch
import strong_source_diff as legacy
import strong_source_mapping as strong_mapping


TOOL_NAME = "Reshet Semantic Progress Report"
TOOL_VERSION = "1.1.0"
SCHEMA_VERSION = 1
JSON_FILENAME = "semantic_progress.json"
CSV_FILENAME = "semantic_progress.csv"
MARKDOWN_FILENAME = "semantic_progress.md"
DEFAULT_OUTPUT_DIR = (
    evidence.REPOSITORY_ROOT.parent
    / "reshet_research_output"
    / "semantic_progress"
)

CSV_COLUMNS = (
    "strong",
    "language",
    "headword",
    "part_of_speech",
    "canonical_occurrence_count",
    "semantic_status",
    "progress_detail",
    "completion_gate_state",
    "current_expression",
    "current_meaning_count",
    "current_meanings",
    "word_note_present",
    "word_note",
    "lexical_out_degree",
    "lexical_in_degree",
    "lexical_direct_degree",
    "db_present",
    "approval_authority",
    "hold_reason",
    "hold_reopen_condition",
)


class SemanticProgressReportError(RuntimeError):
    """진행 현황 snapshot을 안전하게 만들 수 없는 상태."""


def _strong_sort_key(value: str) -> tuple[int, int]:
    return (0 if value[0] == "G" else 1, int(value[1:]))


def _json_bytes(value: object) -> bytes:
    return (
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def _identity_bytes(value: object) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _fingerprint(path: Path) -> dict[str, object]:
    if not path.is_file():
        raise FileNotFoundError(f"fingerprint 대상 파일을 찾을 수 없음: {path}")
    return {
        "path": path.name,
        "sha256": evidence.sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def _atomic_replace(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
    except OSError as error:
        raise SemanticProgressReportError(
            f"atomic progress artifact 기록 실패: {path}: {error}"
        ) from error
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def _language_mapping(strong_manifest: Path) -> dict[str, str]:
    raw_manifest, _ = strong_mapping.load_source_manifest(strong_manifest)
    contract_versions = raw_manifest.get("contract_versions")
    if not isinstance(contract_versions, dict):
        raise SemanticProgressReportError(
            "Strong source manifest contract_versions가 객체가 아님"
        )
    raw_mapping = contract_versions.get("language_mapping")
    if not isinstance(raw_mapping, dict):
        raise SemanticProgressReportError(
            "Strong source manifest language_mapping이 객체가 아님"
        )
    mapping = {
        str(key): str(value)
        for key, value in raw_mapping.items()
        if isinstance(key, str) and isinstance(value, str) and value
    }
    if set(mapping) != set(raw_mapping) or not {"G", "heb", "arc", "x-pn"} <= set(
        mapping
    ):
        raise SemanticProgressReportError(
            "Strong source manifest language_mapping 계약 불일치"
        )
    return mapping


def build_canonical_universe(
    entry_items: Iterable[tuple[str, legacy.SourceEntryV2]],
    language_mapping: dict[str, str],
) -> list[dict[str, object]]:
    """canonical Strong entry를 정규화 검증하고 결정적 전체 universe로 만든다."""

    seen: set[str] = set()
    rows: list[dict[str, object]] = []
    for raw_strong, entry in entry_items:
        normalized = legacy.normalize_strong_number(raw_strong)
        if normalized is None or normalized != raw_strong:
            raise SemanticProgressReportError(
                f"canonical Strong source key 형식 불일치: {raw_strong!r}"
            )
        if normalized in seen:
            raise SemanticProgressReportError(
                f"canonical Strong source 정규화 중복: {normalized}"
            )
        seen.add(normalized)
        if entry.source_key != normalized:
            raise SemanticProgressReportError(
                "canonical Strong source entry key 불일치: "
                f"mapping={normalized}; entry={entry.source_key}"
            )
        language = language_mapping.get(entry.source_language_code)
        if language is None:
            raise SemanticProgressReportError(
                f"canonical Strong source language mapping 누락: "
                f"{normalized}: {entry.source_language_code!r}"
            )
        primary_form = entry.forms[0] if entry.forms else None
        headword = primary_form.spelling if primary_form is not None else None
        part_of_speech = (
            getattr(primary_form, "part_of_speech", None)
            if primary_form is not None
            else None
        )
        issues: list[str] = []
        if not isinstance(headword, str) or not headword:
            headword = None
            issues.append("canonical_headword_missing")
        if part_of_speech is not None and not isinstance(part_of_speech, str):
            raise SemanticProgressReportError(
                f"canonical part_of_speech 형식 불일치: {normalized}"
            )
        rows.append(
            {
                "strong": normalized,
                "language": language,
                "source_language_code": entry.source_language_code,
                "language_group": (
                    "Greek" if normalized[0] == "G" else "Hebrew/Aramaic"
                ),
                "headword": headword,
                "part_of_speech": part_of_speech,
                "source_disposition": entry.disposition,
                "issues": issues,
            }
        )
    if not rows:
        raise SemanticProgressReportError("canonical Strong universe가 비어 있음")
    return sorted(rows, key=lambda row: _strong_sort_key(str(row["strong"])))


def _validate_loaded_source_counts(
    entries: dict[str, legacy.SourceEntryV2],
    strong_provenance: list[dict[str, object]],
) -> None:
    try:
        source_entry_count = sum(int(row["entry_count"]) for row in strong_provenance)
    except (KeyError, TypeError, ValueError) as error:
        raise SemanticProgressReportError(
            "Strong source entry_count provenance 계약 불일치"
        ) from error
    if source_entry_count != len(entries):
        raise SemanticProgressReportError(
            "canonical Strong source entry 수와 정규화 집합 크기가 다름: "
            f"source={source_entry_count}; normalized={len(entries)}; "
            "invalid 또는 duplicate source key 가능"
        )


def _validate_work_schema(connection: object) -> None:
    required_tables = {
        "WORD_TABLE": {"id", "언어", "스트롱넘버", "비고"},
        "word_expression_set": {
            "word_id",
            "seq",
            "is_representative",
            "spelling",
            "transliteration",
            "pronunciation",
            "pronunciation_notation",
            "pronunciation_notation_name",
        },
        "word_meaning_set": {"word_id", "seq", "meaning"},
    }
    for table, required in required_tables.items():
        actual = set(evidence._table_columns(connection, table))
        if not required <= actual:
            raise evidence.SourceSchemaError(
                f"work DB {table} 필수 column 누락: {sorted(required - actual)}"
            )


def load_work_database(
    work_db: Path,
) -> tuple[
    dict[str, list[dict[str, object]]],
    list[dict[str, object]],
    dict[str, object],
]:
    """work DB를 한 read-only connection에서 전체 projection으로 읽는다."""

    before = evidence.sha256_file(work_db)
    connection, integrity = evidence._open_sqlite_read_only(work_db)
    try:
        _validate_work_schema(connection)
        words = connection.execute(
            '''
            SELECT id, "스트롱넘버" AS strong_number, "언어" AS language,
                   "비고" AS word_note
            FROM WORD_TABLE
            ORDER BY id
            '''
        ).fetchall()
        expressions_by_word: defaultdict[str, list[dict[str, object]]] = defaultdict(
            list
        )
        for row in connection.execute(
            '''
            SELECT word_id, seq, is_representative, spelling, transliteration,
                   pronunciation, pronunciation_notation,
                   pronunciation_notation_name
            FROM word_expression_set
            ORDER BY word_id, seq
            '''
        ):
            payload = dict(row)
            word_id = str(payload.pop("word_id"))
            expressions_by_word[word_id].append(payload)
        meanings_by_word: defaultdict[str, list[dict[str, object]]] = defaultdict(list)
        for row in connection.execute(
            '''
            SELECT word_id, seq, meaning
            FROM word_meaning_set
            ORDER BY word_id, seq
            '''
        ):
            payload = dict(row)
            word_id = str(payload.pop("word_id"))
            meanings_by_word[word_id].append(payload)
    finally:
        connection.close()

    projections: defaultdict[str, list[dict[str, object]]] = defaultdict(list)
    anomalies: list[dict[str, object]] = []
    non_strong_row_count = 0
    for word in words:
        word_id = str(word["id"])
        raw_strong = word["strong_number"]
        if raw_strong is None or (
            isinstance(raw_strong, str) and not raw_strong.strip()
        ):
            non_strong_row_count += 1
            continue
        normalized = legacy.normalize_strong_number(raw_strong)
        if normalized is None or normalized != raw_strong:
            anomalies.append(
                {
                    "scope": "work_database",
                    "strong": None,
                    "raw_strong": raw_strong,
                    "word_ids": [word_id],
                    "issues": ["invalid_or_noncanonical_db_strong"],
                }
            )
            continue
        projections[normalized].append(
            {
                "word_id": word_id,
                "strong_number": raw_strong,
                "language": word["language"],
                "word_note": word["word_note"],
                "expressions": expressions_by_word.get(word_id, []),
                "meanings": meanings_by_word.get(word_id, []),
            }
        )

    after = evidence.sha256_file(work_db)
    if before != after:
        raise SemanticProgressReportError(
            "work DB SHA-256이 progress read-only 실행 중 변경됨"
        )
    projection_map = {
        strong: sorted(values, key=lambda value: str(value["word_id"]))
        for strong, values in projections.items()
    }
    return projection_map, anomalies, {
        "filename": work_db.name,
        "sha256_before": before,
        "sha256_after": after,
        "unchanged": True,
        "query_only": True,
        "immutable": True,
        "integrity_check": integrity,
        "word_table_row_count": len(words),
        "strong_tagged_row_count": sum(
            len(values) for values in projection_map.values()
        ),
        "non_strong_row_count": non_strong_row_count,
    }


def load_canonical_occurrence_counts(
    occurrence_manifest: Path,
    cache_dir: Path,
    *,
    allow_fetch: bool,
) -> tuple[
    dict[str, int],
    list[dict[str, object]],
    list[Path],
]:
    """manifest가 고정한 OSHB/TAGNT를 source별 한 번씩 읽어 집계한다."""

    _, specs, paths_by_source, provenance = evidence.ensure_occurrence_sources(
        occurrence_manifest, cache_dir, allow_fetch=allow_fetch
    )
    counts: dict[str, int] = {}
    source_paths: list[Path] = []
    for spec in specs:
        paths = paths_by_source[spec.id]
        source_paths.extend(paths)
        if spec.parser_contract == "tagnt_tsv_na27_28_v1":
            source_counts, parser_result = evidence.count_tagnt_canonical_occurrences(
                paths
            )
        elif spec.parser_contract == "oshb_wlc_osis_v1":
            source_counts, parser_result = evidence.count_oshb_canonical_occurrences(
                paths
            )
        else:
            raise SemanticProgressReportError(
                f"지원하지 않는 canonical occurrence parser: {spec.parser_contract}"
            )
        overlap = set(counts) & set(source_counts)
        if overlap:
            raise SemanticProgressReportError(
                "canonical occurrence source 간 Strong 중복: "
                f"{sorted(overlap, key=_strong_sort_key)[:10]}"
            )
        counts.update(source_counts)
        for row in provenance:
            if row.get("id") == spec.id:
                row["parser_result"] = parser_result
                break
    return counts, provenance, source_paths


def lexical_degrees(
    strong: str,
    outgoing: dict[str, list[dict[str, object]]],
    incoming: dict[str, list[dict[str, object]]],
) -> tuple[int, int, int]:
    """방향별 및 합집합 기준 distinct directly related Strong 수."""

    out_nodes = {
        str(edge["to_strong"])
        for edge in outgoing.get(strong, [])
        if isinstance(edge.get("to_strong"), str)
    }
    in_nodes = {
        str(edge["from_strong"])
        for edge in incoming.get(strong, [])
        if isinstance(edge.get("from_strong"), str)
    }
    return len(out_nodes), len(in_nodes), len(out_nodes | in_nodes)


def _projection_summary(
    projection: list[dict[str, object]],
) -> dict[str, object]:
    expressions: list[str] = []
    representative_expressions: list[str] = []
    meanings: list[str] = []
    word_notes: list[str | None] = []
    for word in projection:
        word_notes.append(
            str(word["word_note"]) if word.get("word_note") is not None else None
        )
        for expression in word.get("expressions", []):
            if not isinstance(expression, dict):
                continue
            spelling = expression.get("spelling")
            if not isinstance(spelling, str) or not spelling:
                continue
            expressions.append(spelling)
            if expression.get("is_representative") == 1:
                representative_expressions.append(spelling)
        for meaning in word.get("meanings", []):
            if not isinstance(meaning, dict):
                continue
            value = meaning.get("meaning")
            if isinstance(value, str):
                meanings.append(value)
    current_expression = (
        representative_expressions[0]
        if representative_expressions
        else expressions[0] if expressions else None
    )
    word_note = word_notes[0] if len(word_notes) == 1 else None
    return {
        "current_expression": current_expression,
        "current_expressions": expressions,
        "current_meanings": meanings,
        "current_meaning_count": len(meanings),
        "word_note_present": any(value is not None for value in word_notes),
        "word_note": word_note,
        "word_notes": word_notes,
    }


def _approval_authority(completion_gate: dict[str, object]) -> list[str]:
    if completion_gate.get("state") != "explicit_approved":
        return []
    evidence_rows = completion_gate.get("evidence")
    if not isinstance(evidence_rows, list) or not all(
        isinstance(value, str) for value in evidence_rows
    ):
        raise SemanticProgressReportError(
            "explicit_approved completion evidence 계약 불일치"
        )
    return list(evidence_rows)


def assemble_progress_snapshot(
    *,
    canonical_rows: list[dict[str, object]],
    projections: dict[str, list[dict[str, object]]],
    database_anomalies: list[dict[str, object]],
    occurrence_counts: dict[str, int],
    outgoing: dict[str, list[dict[str, object]]],
    incoming: dict[str, list[dict[str, object]]],
    relation_index: dict[str, object],
    completion_authority: evidence.CompletionGateAuthority,
    dispositions: list[dict[str, object]],
    source_fingerprints: dict[str, object],
    work_database: dict[str, object],
) -> dict[str, object]:
    universe = {str(row["strong"]) for row in canonical_rows}
    disposition_by_strong = {
        str(row["strong_number"]): row for row in dispositions
    }
    anomalies = [dict(row) for row in database_anomalies]

    for strong, projection in sorted(
        projections.items(), key=lambda item: _strong_sort_key(item[0])
    ):
        if strong not in universe:
            anomalies.append(
                {
                    "scope": "work_database",
                    "strong": strong,
                    "raw_strong": strong,
                    "word_ids": [str(row["word_id"]) for row in projection],
                    "issues": ["db_strong_not_in_canonical_universe"],
                }
            )
    for strong in sorted(set(occurrence_counts) - universe, key=_strong_sort_key):
        anomalies.append(
            {
                "scope": "canonical_occurrence_source",
                "strong": strong,
                "issues": ["occurrence_strong_not_in_canonical_universe"],
                "canonical_occurrence_count": occurrence_counts[strong],
            }
        )
    for strong in sorted(set(disposition_by_strong) - universe, key=_strong_sort_key):
        anomalies.append(
            {
                "scope": "semantic_disposition",
                "strong": strong,
                "issues": ["hold_strong_not_in_canonical_universe"],
            }
        )

    rows: list[dict[str, object]] = []
    for canonical in canonical_rows:
        strong = str(canonical["strong"])
        projection = projections.get(strong, [])
        issues = list(canonical.get("issues", []))
        if not projection:
            issues.append("canonical_strong_missing_from_work_db")
        elif len(projection) > 1:
            issues.append("multiple_work_db_rows_for_strong")
        completion_gate = evidence.completion_gate_state_from_authority(
            strong, projection, completion_authority
        )
        disposition = disposition_by_strong.get(strong)
        semantic_status = research_batch.semantic_status_from_authority(
            strong, completion_gate, disposition
        )
        projection_summary = _projection_summary(projection)
        if issues:
            progress_detail = "anomaly"
            anomalies.append(
                {
                    "scope": "canonical_strong",
                    "strong": strong,
                    "issues": issues,
                    "word_ids": [str(word["word_id"]) for word in projection],
                }
            )
        elif semantic_status == "explicit_approved":
            progress_detail = "approved"
        elif semantic_status == "hold":
            progress_detail = "hold"
        elif projection_summary["current_meaning_count"]:
            progress_detail = "unapproved_with_meaning"
        else:
            progress_detail = "unapproved_without_meaning"
        out_degree, in_degree, direct_degree = lexical_degrees(
            strong, outgoing, incoming
        )
        rows.append(
            {
                "strong": strong,
                "language": canonical["language"],
                "source_language_code": canonical["source_language_code"],
                "language_group": canonical["language_group"],
                "headword": canonical["headword"],
                "part_of_speech": canonical["part_of_speech"],
                "canonical_occurrence_count": occurrence_counts.get(strong, 0),
                "db_present": bool(projection),
                **projection_summary,
                "semantic_status": semantic_status,
                "progress_detail": progress_detail,
                "completion_gate": completion_gate,
                "approval_authority": _approval_authority(completion_gate),
                "hold_reason": disposition.get("reason") if disposition else None,
                "hold_reopen_condition": (
                    disposition.get("reopen_condition") if disposition else None
                ),
                "lexical_out_degree": out_degree,
                "lexical_in_degree": in_degree,
                "lexical_direct_degree": direct_degree,
            }
        )

    status_counts = Counter(str(row["semantic_status"]) for row in rows)
    detail_counts = Counter(str(row["progress_detail"]) for row in rows)
    total = len(rows)
    explicit_approved = status_counts["explicit_approved"]
    hold = status_counts["hold"]
    summary = {
        "total_canonical_strongs": total,
        "greek_total": sum(row["language_group"] == "Greek" for row in rows),
        "hebrew_aramaic_total": sum(
            row["language_group"] == "Hebrew/Aramaic" for row in rows
        ),
        "explicit_approved": explicit_approved,
        "hold": hold,
        "unapproved": status_counts["unapproved"],
        "unapproved_with_meaning": detail_counts["unapproved_with_meaning"],
        "unapproved_without_meaning": detail_counts["unapproved_without_meaning"],
        "anomaly_count": len(anomalies),
        "anomalous_canonical_strong_count": detail_counts["anomaly"],
        "semantic_approval_ratio": round(explicit_approved / total, 12),
        "decision_disposition_ratio": round((explicit_approved + hold) / total, 12),
        "ratio_definitions": {
            "semantic_approval_ratio": {
                "numerator": "explicit_approved",
                "denominator": "total_canonical_strongs",
            },
            "decision_disposition_ratio": {
                "numerator": "explicit_approved + hold",
                "denominator": "total_canonical_strongs",
                "hold_is_semantic_approval": False,
            },
        },
    }
    if explicit_approved + hold + status_counts["unapproved"] != total:
        raise SemanticProgressReportError("semantic status summary 합계 불일치")
    if summary["greek_total"] + summary["hebrew_aramaic_total"] != total:
        raise SemanticProgressReportError("canonical language summary 합계 불일치")

    identity_payload = {
        "tool_version": TOOL_VERSION,
        "work_database_sha256": work_database["sha256_after"],
        "source_fingerprints": source_fingerprints,
    }
    return {
        "schema_version": SCHEMA_VERSION,
        "tool": {
            "name": TOOL_NAME,
            "version": TOOL_VERSION,
            "output_contract": "deterministic_read_only_derivative_snapshot",
        },
        "snapshot_identity": {
            "sha256": _sha256_bytes(_identity_bytes(identity_payload)),
            "basis": [
                "tool_version",
                "work_database_sha256",
                "source_fingerprints",
            ],
        },
        "contracts": {
            "authority_boundary": (
                "이 report는 derivative progress view이며 approval input이 아니다. "
                "승인 manifest, 현재 work DB exact projection, completion gate와 "
                "semantic hold ledger가 authority다."
            ),
            "canonical_universe": (
                "strong_sources.json이 고정한 Greek 및 Hebrew/Aramaic v2 source "
                "entry의 정규화·중복 검증 집합"
            ),
            "semantic_status": ["explicit_approved", "hold", "unapproved"],
            "progress_detail": [
                "approved",
                "hold",
                "unapproved_with_meaning",
                "unapproved_without_meaning",
                "anomaly",
            ],
            "canonical_occurrence_count": (
                "biblical_occurrence_sources.json의 OSHB/TAGNT canonical profile에서 "
                "집계하며 translation DB tagged hit 수를 사용하지 않음"
            ),
            "lexical_degrees": {
                "lexical_out_degree": "distinct outgoing related Strong 수",
                "lexical_in_degree": "distinct incoming related Strong 수",
                "lexical_direct_degree": (
                    "outgoing/incoming distinct related Strong 합집합 수"
                ),
                "authority": "advisory_only_not_semantic_or_relation_assertion",
            },
            "anomaly": (
                "canonical source/DB/occurrence/disposition mapping을 추측으로 "
                "보정할 수 없는 불일치. canonical row의 anomaly는 progress_detail로도 표시"
            ),
        },
        "source_fingerprints": source_fingerprints,
        "work_database": work_database,
        "relation_index": relation_index,
        "summary": summary,
        "rows": rows,
        "anomalies": anomalies,
    }


def collect_progress_snapshot(
    *,
    work_db: Path = evidence.DEFAULT_WORK_DB,
    cache_dir: Path = evidence.DEFAULT_CACHE,
    strong_manifest: Path = evidence.DEFAULT_STRONG_MANIFEST,
    occurrence_manifest: Path = evidence.DEFAULT_OCCURRENCE_MANIFEST,
    source_only_manifest: Path = evidence.DEFAULT_SOURCE_ONLY_MANIFEST,
    dispositions_manifest: Path = evidence.DEFAULT_SEMANTIC_RESEARCH_DISPOSITIONS,
    approved_manifests: tuple[Path, ...] | list[Path] | None = None,
    allow_fetch: bool = False,
) -> tuple[dict[str, object], dict[Path, str]]:
    entries, strong_paths, strong_provenance = evidence.load_strong_sources(
        strong_manifest, cache_dir, allow_fetch=allow_fetch
    )
    _validate_loaded_source_counts(entries, strong_provenance)
    canonical_rows = build_canonical_universe(
        entries.items(), _language_mapping(strong_manifest)
    )
    outgoing, incoming, relation_index = discovery.build_relation_indexes(
        strong_paths, strong_provenance
    )
    selected_approved = (
        tuple(approved_manifests)
        if approved_manifests is not None
        else evidence.discover_approved_content_manifests()
    )
    completion_authority = evidence.load_completion_gate_authority(
        selected_approved, source_only_manifest
    )
    selected_approved = tuple(
        manifest.path for manifest in completion_authority.approved_manifests
    )
    dispositions = evidence.load_semantic_research_dispositions(dispositions_manifest)
    occurrence_counts, occurrence_provenance, occurrence_paths = (
        load_canonical_occurrence_counts(
            occurrence_manifest, cache_dir, allow_fetch=allow_fetch
        )
    )
    projections, database_anomalies, work_database = load_work_database(work_db)

    source_fingerprints = {
        "strong_manifest": _fingerprint(strong_manifest),
        "strong_sources": strong_provenance,
        "occurrence_manifest": _fingerprint(occurrence_manifest),
        "occurrence_sources": occurrence_provenance,
        "approved_content_manifests": [
            _fingerprint(path) for path in selected_approved
        ],
        "source_only_manifest": _fingerprint(source_only_manifest),
        "semantic_research_dispositions": _fingerprint(dispositions_manifest),
        "work_database_sha256": work_database["sha256_after"],
    }
    input_paths = {
        strong_manifest,
        occurrence_manifest,
        source_only_manifest,
        dispositions_manifest,
        work_db,
        *strong_paths.values(),
        *occurrence_paths,
        *selected_approved,
    }
    input_hashes = {path: evidence.sha256_file(path) for path in input_paths}
    snapshot = assemble_progress_snapshot(
        canonical_rows=canonical_rows,
        projections=projections,
        database_anomalies=database_anomalies,
        occurrence_counts=occurrence_counts,
        outgoing=outgoing,
        incoming=incoming,
        relation_index=relation_index,
        completion_authority=completion_authority,
        dispositions=dispositions,
        source_fingerprints=source_fingerprints,
        work_database=work_database,
    )
    _assert_inputs_unchanged(input_hashes)
    return snapshot, input_hashes


def _csv_value(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return str(value)


def render_csv(snapshot: dict[str, object]) -> bytes:
    rows = snapshot.get("rows")
    if not isinstance(rows, list):
        raise SemanticProgressReportError("snapshot rows가 배열이 아님")
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=CSV_COLUMNS, lineterminator="\n")
    writer.writeheader()
    for raw_row in rows:
        if not isinstance(raw_row, dict):
            raise SemanticProgressReportError("snapshot row가 객체가 아님")
        row = dict(raw_row)
        completion_gate = row.get("completion_gate")
        row["completion_gate_state"] = (
            completion_gate.get("state") if isinstance(completion_gate, dict) else None
        )
        writer.writerow(
            {column: _csv_value(row.get(column)) for column in CSV_COLUMNS}
        )
    return output.getvalue().encode("utf-8-sig")


def _markdown_cell(value: object) -> str:
    if value is None or value == "":
        return "—"
    if isinstance(value, list):
        if not value:
            return "—"
        rendered = "<br>".join(_markdown_cell(item) for item in value)
    else:
        rendered = str(value)
    return rendered.replace("|", "\\|").replace("\r\n", "<br>").replace("\n", "<br>")


def _ratio_text(summary: dict[str, object], key: str) -> str:
    value = float(summary[key])
    definition = summary["ratio_definitions"][key]
    if not isinstance(definition, dict):
        raise SemanticProgressReportError("ratio definition 계약 불일치")
    numerator_label = str(definition["numerator"])
    denominator_label = str(definition["denominator"])
    if key == "semantic_approval_ratio":
        numerator = int(summary["explicit_approved"])
    else:
        numerator = int(summary["explicit_approved"]) + int(summary["hold"])
    denominator = int(summary["total_canonical_strongs"])
    return (
        f"{value:.4%} ({numerator:,} / {denominator:,}); "
        f"정의: `{numerator_label} / {denominator_label}`"
    )


def render_markdown(snapshot: dict[str, object]) -> bytes:
    summary = snapshot.get("summary")
    rows = snapshot.get("rows")
    anomalies = snapshot.get("anomalies")
    fingerprints = snapshot.get("source_fingerprints")
    work_database = snapshot.get("work_database")
    if not all(
        isinstance(value, expected)
        for value, expected in (
            (summary, dict),
            (rows, list),
            (anomalies, list),
            (fingerprints, dict),
            (work_database, dict),
        )
    ):
        raise SemanticProgressReportError("Markdown snapshot root 계약 불일치")
    assert isinstance(summary, dict)
    assert isinstance(rows, list)
    assert isinstance(anomalies, list)
    assert isinstance(fingerprints, dict)
    assert isinstance(work_database, dict)
    strong_sources = fingerprints.get("strong_sources")
    approved = fingerprints.get("approved_content_manifests")
    disposition = fingerprints.get("semantic_research_dispositions")
    if (
        not isinstance(strong_sources, list)
        or not isinstance(approved, list)
        or not isinstance(disposition, dict)
    ):
        raise SemanticProgressReportError("Markdown source fingerprint 계약 불일치")

    lines = [
        "# Reshet Semantic Progress",
        "",
        "> 이 문서는 read-only derivative progress view다. semantic approval input이 아니며, "
        "승인 manifest·현재 work DB exact projection·completion gate·hold ledger가 "
        "authority다.",
        "",
        "## Snapshot",
        "",
        f"- work DB SHA-256: `{work_database['sha256_after']}`",
        "- Strong sources: "
        + ", ".join(
            f"`{row['id']}@{str(row['commit'])[:12]}:{str(row['sha256'])[:12]}`"
            for row in strong_sources
        ),
        f"- approved-content manifest 수: {len(approved):,}",
        f"- hold ledger SHA-256: `{disposition['sha256']}`",
        f"- snapshot identity: `{snapshot['snapshot_identity']['sha256']}`",
        "",
        "## 전체 현황",
        "",
        "| 항목 | 수 |",
        "|---|---:|",
        f"| 전체 canonical Strong | {int(summary['total_canonical_strongs']):,} |",
        f"| Greek | {int(summary['greek_total']):,} |",
        f"| Hebrew/Aramaic | {int(summary['hebrew_aramaic_total']):,} |",
        f"| explicit_approved | {int(summary['explicit_approved']):,} |",
        f"| hold | {int(summary['hold']):,} |",
        f"| unapproved | {int(summary['unapproved']):,} |",
        f"| unapproved_with_meaning | {int(summary['unapproved_with_meaning']):,} |",
        "| unapproved_without_meaning | "
        f"{int(summary['unapproved_without_meaning']):,} |",
        f"| anomaly | {int(summary['anomaly_count']):,} |",
        "",
        "anomaly canonical row도 `semantic_status` 3상태를 유지하며, "
        "`progress_detail=anomaly`가 미승인 meaning 유무 분류보다 우선한다.",
        "",
        "## 진행률",
        "",
        f"- semantic approval ratio: {_ratio_text(summary, 'semantic_approval_ratio')}",
        "- decision/disposition ratio: "
        f"{_ratio_text(summary, 'decision_disposition_ratio')}",
        "- hold는 승인 또는 semantic 완료로 표현하지 않는다.",
        "",
        "## Hold 목록",
        "",
    ]
    hold_rows = [
        row
        for row in rows
        if isinstance(row, dict) and row.get("semantic_status") == "hold"
    ]
    if hold_rows:
        lines.extend(
            [
                "| Strong | headword | 현재 meaning | hold reason | reopen condition |",
                "|---|---|---|---|---|",
            ]
        )
        for row in hold_rows:
            lines.append(
                "| "
                + " | ".join(
                    _markdown_cell(value)
                    for value in (
                        row.get("strong"),
                        row.get("headword"),
                        row.get("current_meanings"),
                        row.get("hold_reason"),
                        row.get("hold_reopen_condition"),
                    )
                )
                + " |"
            )
    else:
        lines.append("없음")

    lines.extend(["", "## Anomaly", ""])
    if anomalies:
        lines.extend(
            [
                "| scope | Strong/raw | issues | word IDs |",
                "|---|---|---|---|",
            ]
        )
        for anomaly in anomalies:
            if not isinstance(anomaly, dict):
                raise SemanticProgressReportError("anomaly row가 객체가 아님")
            strong_or_raw = anomaly.get("strong") or anomaly.get("raw_strong")
            lines.append(
                "| "
                + " | ".join(
                    _markdown_cell(value)
                    for value in (
                        anomaly.get("scope"),
                        strong_or_raw,
                        anomaly.get("issues"),
                        anomaly.get("word_ids"),
                    )
                )
                + " |"
            )
    else:
        lines.append("없음")

    lines.extend(
        [
            "",
            "## 다음 대상 선택 안내",
            "",
            "전체 row는 JSON/CSV에 있다. 자동 scoring이나 다음 Strong 자동 추천은 하지 않는다.",
            "",
            "CSV에서 예를 들어 다음 조건으로 직접 필터할 수 있다.",
            "",
            "```text",
            "semantic_status = unapproved",
            "canonical_occurrence_count > 0",
            "```",
            "",
            "또는:",
            "",
            "```text",
            "progress_detail = unapproved_without_meaning",
            "```",
            "",
            "`lexical_out_degree`, `lexical_in_degree`, `lexical_direct_degree`는 "
            "cluster 규모와 lexical hub 가능성을 예상하는 advisory metadata일 뿐이다. "
            "semantic approval, relation assertion, hub 확정 근거가 아니다.",
            "",
        ]
    )
    return "\n".join(lines).encode("utf-8")


def _assert_inputs_unchanged(input_hashes: dict[Path, str]) -> None:
    changed = [
        path
        for path, expected in input_hashes.items()
        if not path.is_file() or evidence.sha256_file(path) != expected
    ]
    if changed:
        raise SemanticProgressReportError(
            f"progress 실행 중 input hash 변경 감지: {changed}"
        )


def generate_progress_report(
    output_dir: Path,
    **kwargs: object,
) -> tuple[dict[str, object], list[dict[str, object]]]:
    snapshot, input_hashes = collect_progress_snapshot(**kwargs)
    rendered = {
        JSON_FILENAME: _json_bytes(snapshot),
        CSV_FILENAME: render_csv(snapshot),
        MARKDOWN_FILENAME: render_markdown(snapshot),
    }
    for filename, content in rendered.items():
        _atomic_replace(output_dir / filename, content)
    _assert_inputs_unchanged(input_hashes)
    row_count = len(snapshot["rows"])
    artifacts = [
        {
            "path": str((output_dir / filename).resolve()),
            "sha256": _sha256_bytes(content),
            "size_bytes": len(content),
            "row_count": row_count if filename != MARKDOWN_FILENAME else None,
        }
        for filename, content in rendered.items()
    ]
    return snapshot, artifacts


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "canonical Strong, 현재 work DB, approved manifests, hold ledger, "
            "canonical occurrence와 lexical index를 읽어 derivative 진행 현황을 생성한다."
            " 고정 source cache가 누락되면 다운로드하지 않고 fail-closed한다."
        )
    )
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--work-db", type=Path, default=evidence.DEFAULT_WORK_DB)
    parser.add_argument("--cache-dir", type=Path, default=evidence.DEFAULT_CACHE)
    parser.add_argument(
        "--strong-manifest", type=Path, default=evidence.DEFAULT_STRONG_MANIFEST
    )
    parser.add_argument(
        "--occurrence-manifest",
        type=Path,
        default=evidence.DEFAULT_OCCURRENCE_MANIFEST,
    )
    parser.add_argument(
        "--source-only-manifest",
        type=Path,
        default=evidence.DEFAULT_SOURCE_ONLY_MANIFEST,
    )
    parser.add_argument(
        "--dispositions-manifest",
        type=Path,
        default=evidence.DEFAULT_SEMANTIC_RESEARCH_DISPOSITIONS,
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        snapshot, artifacts = generate_progress_report(
            args.output_dir,
            work_db=args.work_db,
            cache_dir=args.cache_dir,
            strong_manifest=args.strong_manifest,
            occurrence_manifest=args.occurrence_manifest,
            source_only_manifest=args.source_only_manifest,
            dispositions_manifest=args.dispositions_manifest,
            allow_fetch=False,
        )
    except (
        OSError,
        ValueError,
        evidence.EvidencePacketError,
        research_batch.SemanticResearchBatchError,
        SemanticProgressReportError,
    ) as error:
        print(f"semantic progress report 생성 실패: {error}", file=sys.stderr)
        return 1

    summary = snapshot["summary"]
    print("semantic progress report 생성 완료")
    print(f"전체 canonical Strong: {summary['total_canonical_strongs']}")
    print(
        "semantic 상태: "
        f"explicit_approved={summary['explicit_approved']}, "
        f"hold={summary['hold']}, unapproved={summary['unapproved']}"
    )
    print(f"anomaly: {summary['anomaly_count']}")
    for artifact in artifacts:
        print(
            f"artifact: {artifact['path']} "
            f"sha256={artifact['sha256']} size={artifact['size_bytes']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
