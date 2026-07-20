#!/usr/bin/env python3
"""Phase 50-W HebrewStrong 20건 source-only import를 fail-closed로 준비한다."""

from __future__ import annotations

import argparse
from copy import deepcopy
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
from typing import Iterable, Sequence

import strong_source_diff as source_parser
import strong_source_mapping as source_mapping


PHASE = "50-W"
TOOL_VERSION = "1.0.0"
SCHEMA_VERSION = 1
APPLY_CONFIRMATION = "phase50w-hebrew20-source-import"

TOOL_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = TOOL_DIR.parent.parent
DEFAULT_MANIFEST = (
    TOOL_DIR / "manifests" / "phase50w_hebrew20_source_import.json"
)
DEFAULT_SOURCE_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_SOURCE_XML = TOOL_DIR / ".source_cache" / "HebrewStrong.xml"
DEFAULT_WORK_DB = REPOSITORY_ROOT / "data" / "reshet_work.db"
DEFAULT_SEED_DB = REPOSITORY_ROOT / "data" / "reshet_seed.db"
DEFAULT_RESULT = (
    TOOL_DIR / "migrations" / "phase50w_hebrew20_source_import_result.json"
)

TARGET_STRONGS = (
    "H1564",
    "H1618",
    "H1653",
    "H1655",
    "H1656",
    "H1674",
    "H1833",
    "H2020",
    "H2251",
    "H2491",
    "H2646",
    "H3958",
    "H4200",
    "H4461",
    "H5005",
    "H5229",
    "H5807",
    "H6306",
    "H6378",
    "H6772",
)
EXCLUDED_X_PN_STRONGS = (
    "H1649",
    "H1721",
    "H2044",
    "H2647",
    "H2650",
    "H3160",
    "H3184",
    "H3265",
    "H3959",
    "H5011",
    "H7288",
    "H8206",
)

EXPECTED_PRE_COUNTS = {
    "word": 15009,
    "expression": 15237,
    "meaning": 18149,
    "relation": 7416,
    "strong_word": 14165,
    "strong_expression": 14365,
    "strong_meaning": 16727,
}
EXPECTED_POST_COUNTS = {
    "word": 15029,
    "expression": 15257,
    "meaning": 18188,
    "relation": 7416,
    "strong_word": 14185,
    "strong_expression": 14385,
    "strong_meaning": 16766,
}
EXPECTED_ACTION_COUNTS = {
    "WORD_TABLE_insert": 20,
    "word_expression_set_insert": 20,
    "word_meaning_set_insert": 39,
    "WORD_RELATION_insert": 0,
    "CHANGE_HISTORY_insert": 0,
}
RESULT_STATUS = "applied"
ROLLBACK_STRATEGY = (
    "apply 또는 postflight 실패 시 work·seed 양쪽 verified backup 복원"
)

WORD_COLUMNS = (
    "id",
    "언어",
    "스트롱넘버",
    *(f"표기{index}" for index in range(1, 7)),
    *(f"음역{index}" for index in range(1, 7)),
    *(f"발음{index}" for index in range(1, 7)),
    *(f"관련{index}" for index in range(1, 8)),
    *(f"의미{index}" for index in range(1, 8)),
    "비고",
    "graph_expand_mode",
)
EXPRESSION_COLUMNS = (
    "id",
    "word_id",
    "seq",
    "is_representative",
    "spelling",
    "transliteration",
    "pronunciation",
    "pronunciation_notation",
    "pronunciation_notation_name",
)
MEANING_COLUMNS = ("id", "word_id", "seq", "meaning")


class MigrationError(RuntimeError):
    """입력 또는 DB 상태가 승인된 계약과 다를 때 발생한다."""


@dataclass(frozen=True)
class LoadedManifest:
    payload: dict[str, object]
    entries: tuple[dict[str, object], ...]
    file_sha256: str
    production_payload_sha256: str
    parser_projection_sha256: str


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_json_bytes(payload: object) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        + "\n"
    ).encode("utf-8")


def jsonl_sha256(rows: Iterable[object]) -> str:
    digest = hashlib.sha256()
    for row in rows:
        digest.update(canonical_json_bytes(row))
    return digest.hexdigest()


def _portable_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(REPOSITORY_ROOT.resolve()).as_posix()
    except ValueError:
        return str(resolved)


def build_result_contract_fields(*, backup_directory: str) -> dict[str, object]:
    return {
        "status": RESULT_STATUS,
        "sidecar": {
            "work": {"wal": 0, "shm": 0, "journal": 0},
            "seed": {"wal": 0, "shm": 0, "journal": 0},
        },
        "rollback": {
            "triggered": False,
            "strategy": ROLLBACK_STRATEGY,
            "verified_by_test": True,
            "backup_directory": backup_directory,
        },
    }


def _without_payload_hash(entry: dict[str, object]) -> dict[str, object]:
    payload = deepcopy(entry)
    payload.pop("payload_sha256", None)
    return payload


def serialize_production_payload(entries: Sequence[dict[str, object]]) -> bytes:
    ordered = sorted(entries, key=lambda item: str(item["source_key"]))
    return b"".join(
        canonical_json_bytes(_without_payload_hash(entry)) for entry in ordered
    )


def production_payload_sha256(entries: Sequence[dict[str, object]]) -> str:
    return sha256_bytes(serialize_production_payload(entries))


def payload_item_sha256(entry: dict[str, object]) -> str:
    return sha256_bytes(canonical_json_bytes(_without_payload_hash(entry)))


def _source_contract_paths() -> tuple[Path, Path]:
    return (
        TOOL_DIR / "strong_source_diff.py",
        TOOL_DIR / "strong_source_mapping.py",
    )


def _load_hebrew_source(
    source_manifest_path: Path, source_xml_path: Path
) -> tuple[
    dict[str, object],
    source_mapping.SourceSpec,
    source_parser.SourceDatasetV2,
]:
    raw_manifest, specs = source_mapping.load_source_manifest(source_manifest_path)
    hebrew_specs = [spec for spec in specs if spec.language == "H"]
    if len(hebrew_specs) != 1:
        raise MigrationError(f"Hebrew source spec 수 불일치: {len(hebrew_specs)}")
    spec = hebrew_specs[0]
    if spec.repository != "https://github.com/openscriptures/HebrewLexicon":
        raise MigrationError(f"Hebrew repository 불일치: {spec.repository}")
    if spec.commit != "21c9add13bc727d3a951361778e97e3ff7afd1ce":
        raise MigrationError(f"Hebrew commit 불일치: {spec.commit}")
    if spec.file_path != "HebrewStrong.xml":
        raise MigrationError(f"Hebrew source file 불일치: {spec.file_path}")
    if spec.sha256 != "a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4":
        raise MigrationError(f"Hebrew source SHA contract 불일치: {spec.sha256}")
    if spec.license != "CC BY 4.0":
        raise MigrationError(f"Hebrew license 불일치: {spec.license}")
    if spec.required_attribution != "Open Scriptures Hebrew Bible Project":
        raise MigrationError("Hebrew required attribution 불일치")
    if "hebrew_forms_v2" not in spec.parser_contracts:
        raise MigrationError("hebrew_forms_v2 parser contract 누락")
    if spec.meaning_projection_contract != "hebrew_meanings_v2":
        raise MigrationError("hebrew_meanings_v2 contract 불일치")
    if not source_xml_path.is_file():
        raise MigrationError(f"Hebrew source cache 누락: {source_xml_path}")
    actual_source_sha = sha256_file(source_xml_path)
    if actual_source_sha != spec.sha256:
        raise MigrationError(
            f"Hebrew source SHA 불일치: expected={spec.sha256}, actual={actual_source_sha}"
        )
    dataset = source_parser.parse_hebrew_xml_v2(source_xml_path)
    if dataset.entry_count != 8674 or dataset.invalid_entry_count != 0:
        raise MigrationError(
            f"Hebrew v2 entry 집계 불일치: {dataset.entry_count}/{dataset.invalid_entry_count}"
        )
    return raw_manifest, spec, dataset


def _legacy_expression_projection(
    expressions: Sequence[dict[str, object]],
) -> dict[str, object]:
    result: dict[str, object] = {}
    for index in range(1, 7):
        expression = expressions[index - 1] if index <= len(expressions) else None
        result[f"표기{index}"] = (
            expression["spelling"] if expression is not None else None
        )
        result[f"음역{index}"] = (
            expression["transliteration"] if expression is not None else None
        )
        result[f"발음{index}"] = (
            expression["pronunciation"] if expression is not None else None
        )
    return result


def _production_entry(entry: source_parser.SourceEntryV2) -> dict[str, object]:
    if entry.source_key not in TARGET_STRONGS:
        raise MigrationError(f"승인되지 않은 target entry: {entry.source_key}")
    if entry.source_language_code not in {"heb", "arc"}:
        raise MigrationError(
            f"target source language 불일치: {entry.source_key}: {entry.source_language_code}"
        )
    if len(entry.forms) != 1:
        raise MigrationError(f"target direct form 수 불일치: {entry.source_key}")
    if not 1 <= len(entry.meanings) <= 7:
        raise MigrationError(f"target meaning slot 범위 불일치: {entry.source_key}")
    form = entry.forms[0]
    if form.source_document_order != 1:
        raise MigrationError(f"target source document order 불일치: {entry.source_key}")
    if form.pronunciation is None:
        raise MigrationError(f"target source pronunciation 누락: {entry.source_key}")
    language = "히브리어" if entry.source_language_code == "heb" else "아람어"
    expressions: list[dict[str, object]] = [
        {
            "seq": 1,
            "is_representative": 1,
            "spelling": form.spelling,
            "transliteration": form.transliteration,
            "pronunciation": form.pronunciation,
            "pronunciation_notation": "strong_dictionary",
            "pronunciation_notation_name": None,
        }
    ]
    meanings = [
        {"seq": meaning.seq, "text": meaning.text} for meaning in entry.meanings
    ]
    legacy_meanings = {
        f"의미{index}": (
            meanings[index - 1]["text"] if index <= len(meanings) else None
        )
        for index in range(1, 8)
    }
    payload: dict[str, object] = {
        "source_key": entry.source_key,
        "source_document_order": form.source_document_order,
        "source_language_code": entry.source_language_code,
        "word_id": f"{entry.source_key}_0000",
        "language": language,
        "strong_number": entry.source_key,
        "note": None,
        "graph_expand_mode": "default",
        "expressions": expressions,
        "meanings": meanings,
        "legacy_expression_projection": _legacy_expression_projection(expressions),
        "legacy_meaning_projection": legacy_meanings,
        "legacy_relation_projection": {
            f"관련{index}": None for index in range(1, 8)
        },
        "relations": [],
        "change_history": [],
        "action": "insert",
        "reason": "source_only_clear_language",
    }
    payload["payload_sha256"] = payload_item_sha256(payload)
    return payload


def build_manifest_payload(
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> dict[str, object]:
    raw_source_manifest, source_spec, dataset = _load_hebrew_source(
        source_manifest_path, source_xml_path
    )
    missing = [key for key in TARGET_STRONGS if key not in dataset.entries]
    if missing:
        raise MigrationError(f"target source entry 누락: {missing}")
    entries = [_production_entry(dataset.entries[key]) for key in TARGET_STRONGS]
    language_counts = {
        "히브리어": sum(entry["language"] == "히브리어" for entry in entries),
        "아람어": sum(entry["language"] == "아람어" for entry in entries),
    }
    if language_counts != {"히브리어": 19, "아람어": 1}:
        raise MigrationError(f"target language 집계 불일치: {language_counts}")
    if next(entry for entry in entries if entry["source_key"] == "H1655")[
        "language"
    ] != "아람어":
        raise MigrationError("H1655 source language가 아람어가 아님")
    meaning_count = sum(len(entry["meanings"]) for entry in entries)
    if meaning_count != 39:
        distribution = {
            str(entry["source_key"]): len(entry["meanings"]) for entry in entries
        }
        raise MigrationError(
            f"target meaning 총계 불일치: {meaning_count}: {distribution}"
        )

    excluded: list[dict[str, object]] = []
    for key in EXCLUDED_X_PN_STRONGS:
        source_entry = dataset.entries.get(key)
        if source_entry is None or source_entry.source_language_code != "x-pn":
            raise MigrationError(f"x-pn 제외 source 불일치: {key}")
        excluded.append(
            {
                "source_key": key,
                "source_language_code": "x-pn",
                "action": "hold",
                "reason": "source_language_x_pn_unresolved",
            }
        )

    parser_projections = source_mapping.build_source_only_import_projections(
        dataset.entries, [], "default"
    )
    parser_targets = [
        projection
        for projection in parser_projections
        if projection["source_key"] in TARGET_STRONGS
    ]
    if [projection["source_key"] for projection in parser_targets] != list(
        TARGET_STRONGS
    ):
        raise MigrationError("parser v2 source-only target identity 불일치")
    parser_projection_sha = source_mapping.source_only_projection_sha256(
        parser_targets
    )

    parser_path, mapping_path = _source_contract_paths()
    source_contracts = raw_source_manifest.get("contract_versions")
    if not isinstance(source_contracts, dict):
        raise MigrationError("strong_sources contract_versions 누락")
    return {
        "schema_version": SCHEMA_VERSION,
        "phase": PHASE,
        "manifest_contract": "phase50w_hebrew20_source_import_v1",
        "source": {
            "repository": source_spec.repository,
            "commit": source_spec.commit,
            "file": source_spec.file_path,
            "source_sha256": source_spec.sha256,
            "license": source_spec.license,
            "attribution": source_spec.required_attribution,
            "modification_notice": source_contracts.get(
                "source_modification_rendering_notice"
            ),
            "source_manifest_path": _portable_path(source_manifest_path),
            "source_manifest_sha256": sha256_file(source_manifest_path),
            "parser_source_path": _portable_path(parser_path),
            "parser_source_sha256": sha256_file(parser_path),
            "mapping_source_path": _portable_path(mapping_path),
            "mapping_source_sha256": sha256_file(mapping_path),
            "form_parser_contract": "hebrew_forms_v2",
            "meaning_projection_contract": "hebrew_meanings_v2",
            "parser_v2_source_only_projection_sha256": parser_projection_sha,
        },
        "serialization_contract": {
            "encoding": "UTF-8",
            "bom": False,
            "line_ending": "LF",
            "final_lf": True,
            "manifest_format": "compact JSON object",
            "manifest_key_order": "sort_keys",
            "production_payload_format": "compact JSONL object",
            "production_payload_order": "source_key ASC",
            "production_payload_hash_excludes": ["payload_sha256"],
        },
        "production_payload_sha256": production_payload_sha256(entries),
        "counts": {
            "target_word_count": 20,
            "language": language_counts,
            "expression_count": 20,
            "meaning_count": meaning_count,
            "relation_count": 0,
            "change_history_count": 0,
            "excluded_x_pn_count": 12,
            "pre_apply": EXPECTED_PRE_COUNTS,
            "post_apply": EXPECTED_POST_COUNTS,
            "actions_per_database": EXPECTED_ACTION_COUNTS,
        },
        "entries": entries,
        "excluded": excluded,
    }


def write_manifest(
    output: Path,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> dict[str, object]:
    payload = build_manifest_payload(source_manifest_path, source_xml_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    data = canonical_json_bytes(payload)
    output.write_bytes(data)
    if output.read_bytes() != data:
        raise MigrationError("manifest deterministic bytes write 검증 실패")
    return {
        "mode": "build-manifest",
        "path": _portable_path(output),
        "sha256": sha256_file(output),
        "production_payload_sha256": payload["production_payload_sha256"],
        "parser_v2_source_only_projection_sha256": payload["source"][
            "parser_v2_source_only_projection_sha256"
        ],
        "target_count": len(payload["entries"]),
        "meaning_count": payload["counts"]["meaning_count"],
    }


def load_manifest(
    path: Path = DEFAULT_MANIFEST,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> LoadedManifest:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise MigrationError("manifest UTF-8 BOM 금지 계약 위반")
    if not data.endswith(b"\n") or b"\r\n" in data:
        raise MigrationError("manifest LF/final LF 계약 위반")
    try:
        payload = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"manifest UTF-8/JSON parsing 실패: {error}") from error
    if not isinstance(payload, dict):
        raise MigrationError("manifest root는 object여야 함")
    if canonical_json_bytes(payload) != data:
        raise MigrationError("manifest deterministic canonical bytes 불일치")
    expected = build_manifest_payload(source_manifest_path, source_xml_path)
    if payload != expected:
        raise MigrationError("manifest와 parser v2 재산출 production payload 불일치")
    entries_raw = payload.get("entries")
    if not isinstance(entries_raw, list) or not all(
        isinstance(entry, dict) for entry in entries_raw
    ):
        raise MigrationError("manifest entries 형식 불일치")
    entries = tuple(entries_raw)
    if [entry["source_key"] for entry in entries] != list(TARGET_STRONGS):
        raise MigrationError("manifest target identity/order 불일치")
    for entry in entries:
        if entry.get("payload_sha256") != payload_item_sha256(entry):
            raise MigrationError(f"개별 payload SHA 불일치: {entry['source_key']}")
    production_sha = production_payload_sha256(entries)
    if payload.get("production_payload_sha256") != production_sha:
        raise MigrationError("production payload SHA 불일치")
    source = payload.get("source")
    if not isinstance(source, dict):
        raise MigrationError("manifest source section 누락")
    parser_sha = source.get("parser_v2_source_only_projection_sha256")
    if not isinstance(parser_sha, str):
        raise MigrationError("parser v2 projection SHA 누락")
    return LoadedManifest(
        payload=payload,
        entries=entries,
        file_sha256=sha256_file(path),
        production_payload_sha256=production_sha,
        parser_projection_sha256=parser_sha,
    )


def _quote(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def open_read_only(path: Path) -> sqlite3.Connection:
    resolved = path.resolve()
    if not resolved.is_file():
        raise MigrationError(f"DB 파일 누락: {path}")
    connection = sqlite3.connect(
        resolved.as_uri() + "?mode=ro&immutable=1", uri=True
    )
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA query_only = ON")
    if int(connection.execute("PRAGMA query_only").fetchone()[0]) != 1:
        connection.close()
        raise MigrationError(f"SQLite query_only 보장 실패: {path}")
    return connection


def sidecar_paths(path: Path) -> tuple[Path, Path, Path]:
    resolved = path.resolve()
    return (
        Path(str(resolved) + "-wal"),
        Path(str(resolved) + "-shm"),
        Path(str(resolved) + "-journal"),
    )


def assert_no_sidecars(paths: Sequence[Path]) -> None:
    active = [
        str(sidecar)
        for path in paths
        for sidecar in sidecar_paths(path)
        if sidecar.exists()
    ]
    if active:
        raise MigrationError(f"active SQLite sidecar 발견: {active}")


def _table_columns(connection: sqlite3.Connection, table: str) -> list[str]:
    return [
        str(row[1])
        for row in connection.execute(f"PRAGMA table_info({_quote(table)})")
    ]


def verify_database_health(connection: sqlite3.Connection) -> dict[str, object]:
    required = {
        "WORD_TABLE": set(WORD_COLUMNS),
        "word_expression_set": set(EXPRESSION_COLUMNS),
        "word_meaning_set": set(MEANING_COLUMNS),
        "WORD_RELATION": {"id", "word_id_1", "word_id_2"},
        "CHANGE_HISTORY": {"id", "entity_id"},
    }
    missing: dict[str, list[str]] = {}
    for table, columns in required.items():
        absent = columns - set(_table_columns(connection, table))
        if absent:
            missing[table] = sorted(absent)
    if missing:
        raise MigrationError(f"required schema 누락: {missing}")
    integrity = [str(row[0]) for row in connection.execute("PRAGMA integrity_check")]
    foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
    journal_mode = str(connection.execute("PRAGMA journal_mode").fetchone()[0]).lower()
    if integrity != ["ok"]:
        raise MigrationError(f"integrity_check 실패: {integrity}")
    if foreign_keys:
        raise MigrationError(f"foreign_key_check 실패: {len(foreign_keys)}")
    return {
        "integrity_check": "ok",
        "foreign_key_violation_count": 0,
        "required_schema_present": True,
        "journal_mode": journal_mode,
    }


def _row_dicts(
    connection: sqlite3.Connection,
    table: str,
    *,
    order_by: str,
) -> list[dict[str, object]]:
    return [
        dict(row)
        for row in connection.execute(
            f"SELECT * FROM {_quote(table)} ORDER BY {order_by}"
        )
    ]


def _rows_sha(rows: Iterable[object]) -> str:
    return jsonl_sha256(rows)


def _schema_sha(connection: sqlite3.Connection) -> str:
    rows = connection.execute(
        """
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        """
    ).fetchall()
    return _rows_sha([list(row) for row in rows])


def _database_counts(connection: sqlite3.Connection) -> dict[str, int]:
    return {
        "word": int(connection.execute("SELECT COUNT(*) FROM WORD_TABLE").fetchone()[0]),
        "expression": int(
            connection.execute("SELECT COUNT(*) FROM word_expression_set").fetchone()[0]
        ),
        "meaning": int(
            connection.execute("SELECT COUNT(*) FROM word_meaning_set").fetchone()[0]
        ),
        "relation": int(
            connection.execute("SELECT COUNT(*) FROM WORD_RELATION").fetchone()[0]
        ),
        "strong_word": int(
            connection.execute(
                'SELECT COUNT(*) FROM WORD_TABLE WHERE "스트롱넘버" IS NOT NULL AND TRIM("스트롱넘버") <> \"\"'
            ).fetchone()[0]
        ),
        "strong_expression": int(
            connection.execute(
                """
                SELECT COUNT(*)
                FROM word_expression_set AS e
                JOIN WORD_TABLE AS w ON w.id=e.word_id
                WHERE w."스트롱넘버" IS NOT NULL AND TRIM(w."스트롱넘버") <> ''
                """
            ).fetchone()[0]
        ),
        "strong_meaning": int(
            connection.execute(
                """
                SELECT COUNT(*)
                FROM word_meaning_set AS m
                JOIN WORD_TABLE AS w ON w.id=m.word_id
                WHERE w."스트롱넘버" IS NOT NULL AND TRIM(w."스트롱넘버") <> ''
                """
            ).fetchone()[0]
        ),
    }


def _expected_word_row(entry: dict[str, object]) -> dict[str, object]:
    legacy_expressions = entry["legacy_expression_projection"]
    legacy_meanings = entry["legacy_meaning_projection"]
    legacy_relations = entry["legacy_relation_projection"]
    assert isinstance(legacy_expressions, dict)
    assert isinstance(legacy_meanings, dict)
    assert isinstance(legacy_relations, dict)
    row: dict[str, object] = {
        "id": entry["word_id"],
        "언어": entry["language"],
        "스트롱넘버": entry["strong_number"],
        "비고": entry["note"],
        "graph_expand_mode": entry["graph_expand_mode"],
    }
    row.update(legacy_expressions)
    row.update(legacy_relations)
    row.update(legacy_meanings)
    return {column: row[column] for column in WORD_COLUMNS}


def _expected_expression_rows(entry: dict[str, object]) -> list[dict[str, object]]:
    expressions = entry["expressions"]
    assert isinstance(expressions, list)
    return [
        {
            "word_id": entry["word_id"],
            "seq": expression["seq"],
            "is_representative": expression["is_representative"],
            "spelling": expression["spelling"],
            "transliteration": expression["transliteration"],
            "pronunciation": expression["pronunciation"],
            "pronunciation_notation": expression["pronunciation_notation"],
            "pronunciation_notation_name": expression[
                "pronunciation_notation_name"
            ],
        }
        for expression in expressions
    ]


def _expected_meaning_rows(entry: dict[str, object]) -> list[dict[str, object]]:
    meanings = entry["meanings"]
    assert isinstance(meanings, list)
    return [
        {
            "word_id": entry["word_id"],
            "seq": meaning["seq"],
            "meaning": meaning["text"],
        }
        for meaning in meanings
    ]


def validate_database_state(
    connection: sqlite3.Connection,
    entries: Sequence[dict[str, object]],
    expected_state: str | None = None,
) -> tuple[str, dict[str, object]]:
    health = verify_database_health(connection)
    states: list[str] = []
    for entry in entries:
        word_id = str(entry["word_id"])
        strong = str(entry["strong_number"])
        identity_rows = [
            dict(row)
            for row in connection.execute(
                'SELECT * FROM WORD_TABLE WHERE id=? OR "스트롱넘버"=? ORDER BY id',
                (word_id, strong),
            )
        ]
        expressions = [
            dict(row)
            for row in connection.execute(
                """
                SELECT word_id, seq, is_representative, spelling, transliteration,
                       pronunciation, pronunciation_notation,
                       pronunciation_notation_name
                FROM word_expression_set WHERE word_id=? ORDER BY seq, id
                """,
                (word_id,),
            )
        ]
        meanings = [
            dict(row)
            for row in connection.execute(
                "SELECT word_id, seq, meaning FROM word_meaning_set WHERE word_id=? ORDER BY seq, id",
                (word_id,),
            )
        ]
        relation_count = int(
            connection.execute(
                "SELECT COUNT(*) FROM WORD_RELATION WHERE word_id_1=? OR word_id_2=?",
                (word_id, word_id),
            ).fetchone()[0]
        )
        history_count = int(
            connection.execute(
                "SELECT COUNT(*) FROM CHANGE_HISTORY WHERE entity_id=?", (word_id,)
            ).fetchone()[0]
        )
        if not identity_rows:
            if expressions or meanings or relation_count or history_count:
                raise MigrationError(f"orphan target projection 존재: {strong}")
            states.append("pre_apply")
            continue
        if len(identity_rows) != 1:
            raise MigrationError(f"identity collision: {strong}: {len(identity_rows)}")
        actual_word = {column: identity_rows[0][column] for column in WORD_COLUMNS}
        if actual_word != _expected_word_row(entry):
            raise MigrationError(f"manifest와 다른 WORD_TABLE target: {strong}")
        if expressions != _expected_expression_rows(entry):
            raise MigrationError(f"manifest와 다른 expression target: {strong}")
        if meanings != _expected_meaning_rows(entry):
            raise MigrationError(f"manifest와 다른 meaning target: {strong}")
        if relation_count != 0 or history_count != 0:
            raise MigrationError(
                f"예상하지 않은 relation/history target: {strong}: {relation_count}/{history_count}"
            )
        states.append("post_apply")
    unique_states = set(states)
    if len(unique_states) != 1:
        raise MigrationError(f"partial target state: {sorted(unique_states)}")
    state = states[0]
    if expected_state is not None and state != expected_state:
        raise MigrationError(
            f"DB target state 불일치: expected={expected_state}, actual={state}"
        )
    counts = _database_counts(connection)
    expected_counts = (
        EXPECTED_PRE_COUNTS if state == "pre_apply" else EXPECTED_POST_COUNTS
    )
    if counts != expected_counts:
        raise MigrationError(
            f"{state} 전체/Strong 집계 불일치: expected={expected_counts}, actual={counts}"
        )
    return state, health


def capture_snapshot(
    connection: sqlite3.Connection, entries: Sequence[dict[str, object]]
) -> dict[str, object]:
    target_ids = {str(entry["word_id"]) for entry in entries}
    words = _row_dicts(connection, "WORD_TABLE", order_by="id")
    expressions = _row_dicts(
        connection, "word_expression_set", order_by="word_id, seq, id"
    )
    meanings = _row_dicts(
        connection, "word_meaning_set", order_by="word_id, seq, id"
    )
    relations = _row_dicts(connection, "WORD_RELATION", order_by="id")
    history = _row_dicts(connection, "CHANGE_HISTORY", order_by="id")
    non_target_words = [row for row in words if str(row["id"]) not in target_ids]
    non_target_expressions = [
        row for row in expressions if str(row["word_id"]) not in target_ids
    ]
    non_target_meanings = [
        row for row in meanings if str(row["word_id"]) not in target_ids
    ]

    parity_words: list[dict[str, object]] = []
    for row in words:
        semantic = dict(row)
        if semantic["id"] == "G0025_0000":
            semantic["비고"] = "<G0025_DB별_차이_허용>"
        parity_words.append(semantic)
    parity_expressions = [
        {key: value for key, value in row.items() if key != "id"}
        for row in expressions
    ]
    parity_meanings = [
        {key: value for key, value in row.items() if key != "id"} for row in meanings
    ]
    parity_relations = [
        {key: value for key, value in row.items() if key != "id"}
        for row in relations
    ]
    g0185 = next((row for row in words if row["id"] == "G0185_0000"), None)
    g0025 = next((row for row in words if row["id"] == "G0025_0000"), None)
    return {
        "counts": _database_counts(connection),
        "protected": {
            "existing_WORD_TABLE_sha256": _rows_sha(non_target_words),
            "existing_expression_sha256": _rows_sha(non_target_expressions),
            "existing_meaning_sha256": _rows_sha(non_target_meanings),
            "WORD_RELATION_sha256": _rows_sha(relations),
            "CHANGE_HISTORY_sha256": _rows_sha(history),
            "schema_sha256": _schema_sha(connection),
            "G0185_sha256": _rows_sha([g0185]),
            "G0025_sha256": _rows_sha([g0025]),
        },
        "parity": {
            "word_semantic_sha256": _rows_sha(parity_words),
            "expression_semantic_sha256": _rows_sha(parity_expressions),
            "meaning_semantic_sha256": _rows_sha(parity_meanings),
            "relation_semantic_sha256": _rows_sha(parity_relations),
            "schema_sha256": _schema_sha(connection),
        },
        "g0185_pronunciation2": g0185["발음2"] if g0185 is not None else None,
        "g0025_note": g0025["비고"] if g0025 is not None else None,
    }


def compare_work_seed_parity(
    work: dict[str, object], seed: dict[str, object]
) -> dict[str, object]:
    work_parity = work["parity"]
    seed_parity = seed["parity"]
    assert isinstance(work_parity, dict) and isinstance(seed_parity, dict)
    differences = [
        key for key in work_parity if work_parity[key] != seed_parity.get(key)
    ]
    if differences:
        raise MigrationError(f"work·seed semantic parity 불일치: {differences}")
    if work["g0025_note"] != "48-B3 백업 시점" or seed["g0025_note"] is not None:
        raise MigrationError(
            f"G0025 기준값 불일치: work={work['g0025_note']!r}, seed={seed['g0025_note']!r}"
        )
    if work["g0185_pronunciation2"] is not None or seed[
        "g0185_pronunciation2"
    ] is not None:
        raise MigrationError("G0185 발음2=NULL 기준 불일치")
    return {
        "exact": True,
        "compared_keys": list(work_parity),
        "excluded": [
            "surrogate row id",
            "G0025 WORD_TABLE.비고의 승인된 work·seed 차이",
            "CHANGE_HISTORY의 승인된 DB별 이력 차이",
            "SQLite 물리 layout",
        ],
        **work_parity,
    }


def verify_protected_unchanged(
    before: dict[str, object], after: dict[str, object], label: str
) -> None:
    if before["protected"] != after["protected"]:
        before_values = before["protected"]
        after_values = after["protected"]
        assert isinstance(before_values, dict) and isinstance(after_values, dict)
        differences = [
            key
            for key in before_values
            if before_values[key] != after_values.get(key)
        ]
        raise MigrationError(f"protected projection 변경: {label}: {differences}")
    if after["counts"] != EXPECTED_POST_COUNTS:
        raise MigrationError(f"post-apply 집계 불일치: {label}: {after['counts']}")


def _boundary_hashes(
    manifest_path: Path,
    source_manifest_path: Path,
    source_xml_path: Path,
    result_output: Path,
) -> dict[str, object]:
    parser_path, mapping_path = _source_contract_paths()
    return {
        "manifest_sha256": sha256_file(manifest_path),
        "source_manifest_sha256": sha256_file(source_manifest_path),
        "source_xml_sha256": sha256_file(source_xml_path),
        "parser_source_sha256": sha256_file(parser_path),
        "mapping_source_sha256": sha256_file(mapping_path),
        "result_artifact": (
            {"exists": True, "sha256": sha256_file(result_output)}
            if result_output.exists()
            else {"exists": False, "sha256": None}
        ),
    }


def run_dry_run(
    *,
    manifest_path: Path = DEFAULT_MANIFEST,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    result_output: Path = DEFAULT_RESULT,
) -> dict[str, object]:
    assert_no_sidecars((work_db, seed_db))
    loaded = load_manifest(manifest_path, source_manifest_path, source_xml_path)
    database_sha_before = {
        "work": sha256_file(work_db),
        "seed": sha256_file(seed_db),
    }
    boundary_before = _boundary_hashes(
        manifest_path, source_manifest_path, source_xml_path, result_output
    )
    work_connection = open_read_only(work_db)
    seed_connection = open_read_only(seed_db)
    try:
        work_state, work_health = validate_database_state(
            work_connection, loaded.entries, "pre_apply"
        )
        seed_state, seed_health = validate_database_state(
            seed_connection, loaded.entries, "pre_apply"
        )
        work_snapshot = capture_snapshot(work_connection, loaded.entries)
        seed_snapshot = capture_snapshot(seed_connection, loaded.entries)
        parity = compare_work_seed_parity(work_snapshot, seed_snapshot)
    finally:
        work_connection.close()
        seed_connection.close()
    database_sha_after = {
        "work": sha256_file(work_db),
        "seed": sha256_file(seed_db),
    }
    boundary_after = _boundary_hashes(
        manifest_path, source_manifest_path, source_xml_path, result_output
    )
    assert_no_sidecars((work_db, seed_db))
    if database_sha_before != database_sha_after:
        raise MigrationError("dry-run 전후 active DB SHA 변경")
    if boundary_before != boundary_after:
        raise MigrationError("dry-run 전후 source/manifest/result boundary 변경")
    return {
        "mode": "dry-run",
        "phase": PHASE,
        "tool_version": TOOL_VERSION,
        "status": "적용 가능 — active DB 미적용",
        "manifest": {
            "path": _portable_path(manifest_path),
            "sha256": loaded.file_sha256,
            "production_payload_sha256": loaded.production_payload_sha256,
            "parser_v2_source_only_projection_sha256": loaded.parser_projection_sha256,
        },
        "source": loaded.payload["source"],
        "database_sha256_before": database_sha_before,
        "database_sha256_after": database_sha_after,
        "work": {
            "state": work_state,
            "health": work_health,
            "counts": work_snapshot["counts"],
            "protected": work_snapshot["protected"],
            "g0185_pronunciation2": work_snapshot["g0185_pronunciation2"],
            "g0025_note": work_snapshot["g0025_note"],
        },
        "seed": {
            "state": seed_state,
            "health": seed_health,
            "counts": seed_snapshot["counts"],
            "protected": seed_snapshot["protected"],
            "g0185_pronunciation2": seed_snapshot["g0185_pronunciation2"],
            "g0025_note": seed_snapshot["g0025_note"],
        },
        "parity": parity,
        "planned_actions_per_database": EXPECTED_ACTION_COUNTS,
        "expected_post_counts": EXPECTED_POST_COUNTS,
        "sidecar_count": 0,
        "change_count": 0,
        "active_backup_created": False,
        "result_artifact_created": False,
    }


def _same_local_volume(left: Path, right: Path) -> bool:
    left_resolved = left.resolve()
    right_resolved = right.resolve()
    left_drive = os.path.splitdrive(str(left_resolved))[0].casefold()
    right_drive = os.path.splitdrive(str(right_resolved))[0].casefold()
    return (
        left_drive == right_drive
        and left_resolved.stat().st_dev == right_resolved.stat().st_dev
    )


def create_verified_backups(
    work_db: Path, seed_db: Path, backup_root: Path
) -> tuple[Path, dict[str, object]]:
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S_%fZ")
    backup_dir = backup_root / timestamp
    backup_dir.mkdir(parents=True, exist_ok=False)
    result: dict[str, object] = {}
    for label, source in (("work", work_db), ("seed", seed_db)):
        destination = backup_dir / f"reshet_{label}_pre_phase50w.db"
        source_sha = sha256_file(source)
        shutil.copy2(source, destination)
        backup_sha = sha256_file(destination)
        if source_sha != backup_sha:
            raise MigrationError(f"backup SHA 불일치: {label}")
        connection = open_read_only(destination)
        try:
            health = verify_database_health(connection)
        finally:
            connection.close()
        result[label] = {
            "original_path": _portable_path(source),
            "backup_path": _portable_path(destination),
            "original_sha256": source_sha,
            "backup_sha256": backup_sha,
            "size_bytes": destination.stat().st_size,
            "integrity_check": health["integrity_check"],
            "foreign_key_violation_count": health["foreign_key_violation_count"],
        }
    return backup_dir, result


def restore_verified_backups(
    work_db: Path,
    seed_db: Path,
    backup_metadata: dict[str, object],
) -> dict[str, object]:
    restored: dict[str, object] = {}
    for label, target in (("work", work_db), ("seed", seed_db)):
        info = backup_metadata.get(label)
        if not isinstance(info, dict):
            raise MigrationError(f"backup metadata 누락: {label}")
        backup_path = Path(str(info["backup_path"]))
        if not backup_path.is_absolute():
            backup_path = REPOSITORY_ROOT / backup_path
        for sidecar in sidecar_paths(target):
            if sidecar.exists():
                sidecar.unlink()
        shutil.copy2(backup_path, target)
        actual_sha = sha256_file(target)
        if actual_sha != info["original_sha256"]:
            raise MigrationError(f"backup restore SHA 불일치: {label}")
        connection = open_read_only(target)
        try:
            health = verify_database_health(connection)
        finally:
            connection.close()
        restored[label] = {
            "sha256": actual_sha,
            "integrity_check": health["integrity_check"],
            "foreign_key_violation_count": health["foreign_key_violation_count"],
        }
    assert_no_sidecars((work_db, seed_db))
    return restored


def _insert_entries(
    connection: sqlite3.Connection,
    entries: Sequence[dict[str, object]],
    *,
    fault_injection: str | None = None,
    label: str,
) -> dict[str, int]:
    word_columns = ",".join(_quote(column) for column in WORD_COLUMNS)
    word_placeholders = ",".join("?" for _ in WORD_COLUMNS)
    counts = dict(EXPECTED_ACTION_COUNTS)
    actual = {key: 0 for key in counts}
    for entry in entries:
        word = _expected_word_row(entry)
        cursor = connection.execute(
            f"INSERT INTO WORD_TABLE({word_columns}) VALUES ({word_placeholders})",
            tuple(word[column] for column in WORD_COLUMNS),
        )
        if cursor.rowcount != 1:
            raise MigrationError(f"WORD_TABLE INSERT rowcount 불일치: {entry['source_key']}")
        actual["WORD_TABLE_insert"] += 1
        for expression in _expected_expression_rows(entry):
            cursor = connection.execute(
                """
                INSERT INTO word_expression_set(
                  word_id, seq, is_representative, spelling, transliteration,
                  pronunciation, pronunciation_notation,
                  pronunciation_notation_name
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                tuple(expression.values()),
            )
            if cursor.rowcount != 1:
                raise MigrationError("word_expression_set INSERT rowcount 불일치")
            actual["word_expression_set_insert"] += 1
        for meaning in _expected_meaning_rows(entry):
            cursor = connection.execute(
                "INSERT INTO word_meaning_set(word_id, seq, meaning) VALUES (?, ?, ?)",
                tuple(meaning.values()),
            )
            if cursor.rowcount != 1:
                raise MigrationError("word_meaning_set INSERT rowcount 불일치")
            actual["word_meaning_set_insert"] += 1
        if fault_injection == f"{label}_insert" and actual["WORD_TABLE_insert"] == 1:
            raise MigrationError(f"test fault injection: {label}_insert")
    if actual != counts:
        raise MigrationError(f"전체 INSERT action 집계 불일치: {label}: {actual}")
    return actual


def _write_json_atomic(path: Path, payload: dict[str, object]) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = canonical_json_bytes(payload)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            temporary.write(data)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()
    if path.read_bytes() != data:
        raise MigrationError("result artifact atomic write 검증 실패")
    return sha256_file(path)


def _validate_result_matches(
    result_output: Path,
    loaded: LoadedManifest,
    work_db: Path,
    seed_db: Path,
) -> dict[str, object]:
    if not result_output.is_file():
        raise MigrationError("post_apply 상태에 matching result artifact가 없음")
    data = result_output.read_bytes()
    if data.startswith(b"\xef\xbb\xbf") or not data.endswith(b"\n") or b"\r\n" in data:
        raise MigrationError("result artifact encoding/LF 계약 불일치")
    try:
        payload = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"result artifact parsing 실패: {error}") from error
    if canonical_json_bytes(payload) != data:
        raise MigrationError("result artifact deterministic bytes 불일치")
    if payload.get("phase") != PHASE or payload.get("tool_version") != TOOL_VERSION:
        raise MigrationError("result artifact phase/tool version 불일치")
    if payload.get("input_manifest_sha256") != loaded.file_sha256:
        raise MigrationError("result artifact input manifest SHA 불일치")
    if payload.get("production_payload_sha256") != loaded.production_payload_sha256:
        raise MigrationError("result artifact production payload SHA 불일치")
    backup = payload.get("backup")
    if not isinstance(backup, dict) or not isinstance(backup.get("directory"), str):
        raise MigrationError("result artifact backup directory 계약 불일치")
    expected_contract = build_result_contract_fields(
        backup_directory=backup["directory"]
    )
    for key, expected in expected_contract.items():
        if payload.get(key) != expected:
            raise MigrationError(f"result artifact {key} 계약 불일치")
    output_sha = payload.get("database_sha256_after")
    if output_sha != {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}:
        raise MigrationError("result artifact current DB SHA 불일치")
    return payload


def run_apply(
    *,
    confirmation: str,
    manifest_path: Path,
    work_db: Path,
    seed_db: Path,
    backup_root: Path,
    result_output: Path,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    fault_injection: str | None = None,
) -> dict[str, object]:
    if confirmation != APPLY_CONFIRMATION:
        raise MigrationError("apply confirmation token 불일치")
    if work_db.resolve() == seed_db.resolve():
        raise MigrationError("work와 seed DB 경로가 같음")
    if not _same_local_volume(work_db, seed_db):
        raise MigrationError("work와 seed가 같은 local filesystem/volume이 아님")
    assert_no_sidecars((work_db, seed_db))
    loaded = load_manifest(manifest_path, source_manifest_path, source_xml_path)
    input_hashes = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}

    work_read = open_read_only(work_db)
    seed_read = open_read_only(seed_db)
    try:
        work_state, work_health_pre = validate_database_state(
            work_read, loaded.entries
        )
        seed_state, seed_health_pre = validate_database_state(
            seed_read, loaded.entries
        )
        work_pre = capture_snapshot(work_read, loaded.entries)
        seed_pre = capture_snapshot(seed_read, loaded.entries)
        parity_pre = compare_work_seed_parity(work_pre, seed_pre)
    finally:
        work_read.close()
        seed_read.close()
    if work_state != seed_state:
        raise MigrationError(
            f"work·seed 적용 상태 불일치: work={work_state}, seed={seed_state}"
        )
    if work_state == "post_apply":
        _validate_result_matches(
            result_output, loaded, work_db, seed_db
        )
        assert_no_sidecars((work_db, seed_db))
        return {
            "mode": "apply",
            "phase": PHASE,
            "status": "이미 적용됨 — 변경 0",
            "change_count": 0,
            "database_sha256": input_hashes,
            "backup_created": False,
            "transaction_started": False,
            "result_rewritten": False,
            "result_artifact_sha256": sha256_file(result_output),
            "parity": parity_pre,
        }
    if work_state != "pre_apply":
        raise MigrationError(f"지원하지 않는 DB state: {work_state}")
    if result_output.exists():
        raise MigrationError("pre_apply DB인데 result artifact가 이미 존재함")
    if work_health_pre["journal_mode"] != "delete" or seed_health_pre[
        "journal_mode"
    ] != "delete":
        raise MigrationError("apply 전 journal_mode=delete 조건 불충족")

    backup_dir, backup_metadata = create_verified_backups(
        work_db, seed_db, backup_root
    )
    work_connection: sqlite3.Connection | None = None
    seed_connection: sqlite3.Connection | None = None
    work_committed = False
    seed_committed = False
    result_written = False
    try:
        work_connection = sqlite3.connect(str(work_db.resolve()))
        seed_connection = sqlite3.connect(str(seed_db.resolve()))
        for connection in (work_connection, seed_connection):
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys = ON")
            if str(connection.execute("PRAGMA journal_mode").fetchone()[0]).lower() != "delete":
                raise MigrationError("transaction journal_mode=delete 조건 불충족")
            connection.execute("BEGIN IMMEDIATE")
        validate_database_state(work_connection, loaded.entries, "pre_apply")
        validate_database_state(seed_connection, loaded.entries, "pre_apply")
        work_tx_pre = capture_snapshot(work_connection, loaded.entries)
        seed_tx_pre = capture_snapshot(seed_connection, loaded.entries)
        if work_tx_pre != work_pre or seed_tx_pre != seed_pre:
            raise MigrationError("transaction 직전 snapshot 변경")
        compare_work_seed_parity(work_tx_pre, seed_tx_pre)

        work_actions = _insert_entries(
            work_connection,
            loaded.entries,
            fault_injection=fault_injection,
            label="work",
        )
        seed_actions = _insert_entries(
            seed_connection,
            loaded.entries,
            fault_injection=fault_injection,
            label="seed",
        )
        validate_database_state(work_connection, loaded.entries, "post_apply")
        validate_database_state(seed_connection, loaded.entries, "post_apply")
        work_tx_post = capture_snapshot(work_connection, loaded.entries)
        seed_tx_post = capture_snapshot(seed_connection, loaded.entries)
        verify_protected_unchanged(work_pre, work_tx_post, "work/transaction")
        verify_protected_unchanged(seed_pre, seed_tx_post, "seed/transaction")
        parity_tx_post = compare_work_seed_parity(work_tx_post, seed_tx_post)

        work_connection.commit()
        work_committed = True
        if fault_injection == "after_work_commit":
            raise MigrationError("test fault injection: after_work_commit")
        seed_connection.commit()
        seed_committed = True
        work_connection.close()
        work_connection = None
        seed_connection.close()
        seed_connection = None
        if fault_injection == "post_commit_validation":
            raise MigrationError("test fault injection: post_commit_validation")

        assert_no_sidecars((work_db, seed_db))
        work_post_read = open_read_only(work_db)
        seed_post_read = open_read_only(seed_db)
        try:
            _, work_health_post = validate_database_state(
                work_post_read, loaded.entries, "post_apply"
            )
            _, seed_health_post = validate_database_state(
                seed_post_read, loaded.entries, "post_apply"
            )
            work_post = capture_snapshot(work_post_read, loaded.entries)
            seed_post = capture_snapshot(seed_post_read, loaded.entries)
            verify_protected_unchanged(work_pre, work_post, "work/post-commit")
            verify_protected_unchanged(seed_pre, seed_post, "seed/post-commit")
            parity_post = compare_work_seed_parity(work_post, seed_post)
        finally:
            work_post_read.close()
            seed_post_read.close()
        output_hashes = {
            "work": sha256_file(work_db),
            "seed": sha256_file(seed_db),
        }
        result_payload: dict[str, object] = {
            "schema_version": SCHEMA_VERSION,
            "phase": PHASE,
            "tool_version": TOOL_VERSION,
            "executed_at_utc": datetime.now(timezone.utc).isoformat(),
            "input_manifest_path": _portable_path(manifest_path),
            "input_manifest_sha256": loaded.file_sha256,
            "production_payload_sha256": loaded.production_payload_sha256,
            "parser_v2_source_only_projection_sha256": loaded.parser_projection_sha256,
            "source": loaded.payload["source"],
            "actions_per_database": {
                "work": work_actions,
                "seed": seed_actions,
            },
            "database_sha256_before": input_hashes,
            "database_sha256_after": output_hashes,
            "counts": {
                "work": {"pre": work_pre["counts"], "post": work_post["counts"]},
                "seed": {"pre": seed_pre["counts"], "post": seed_post["counts"]},
            },
            "protection": {
                "work": {"pre": work_pre["protected"], "post": work_post["protected"]},
                "seed": {"pre": seed_pre["protected"], "post": seed_post["protected"]},
            },
            "health": {
                "work": {"pre": work_health_pre, "post": work_health_post},
                "seed": {"pre": seed_health_pre, "post": seed_health_post},
            },
            "parity_pre": parity_pre,
            "parity_transaction_post": parity_tx_post,
            "parity_post": parity_post,
            "backup": {
                "directory": _portable_path(backup_dir),
                **backup_metadata,
            },
            **build_result_contract_fields(
                backup_directory=_portable_path(backup_dir)
            ),
            "second_run": {
                "status": "already_applied_noop_verified",
                "message": "이미 적용됨 — 변경 0",
                "backup_created": False,
                "transaction_started": False,
                "result_rewritten": False,
            },
        }
        if fault_injection == "result_write":
            raise MigrationError("test fault injection: result_write")
        result_sha = _write_json_atomic(result_output, result_payload)
        result_written = True
        _validate_result_matches(result_output, loaded, work_db, seed_db)
        return {
            "mode": "apply",
            "phase": PHASE,
            "status": "적용 완료 — work·seed 각 20/20/39",
            "actions_per_database": EXPECTED_ACTION_COUNTS,
            "database_sha256_before": input_hashes,
            "database_sha256_after": output_hashes,
            "backup_directory": _portable_path(backup_dir),
            "backup": backup_metadata,
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": result_sha,
            "parity": parity_post,
            "sidecar_count": 0,
        }
    except Exception as error:
        for connection in (work_connection, seed_connection):
            if connection is not None:
                try:
                    connection.rollback()
                finally:
                    connection.close()
        restore_result = restore_verified_backups(
            work_db, seed_db, backup_metadata
        )
        if result_written and result_output.exists():
            result_output.unlink()
        raise MigrationError(
            f"apply 실패: {error}; work_committed={work_committed}; "
            f"seed_committed={seed_committed}; backup restore 성공={restore_result}"
        ) from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Phase 50-W HebrewStrong 20건 source import migration"
    )
    subparsers = parser.add_subparsers(dest="command")

    dry_run = subparsers.add_parser("dry-run")
    dry_run.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    dry_run.add_argument("--work-db", default=str(DEFAULT_WORK_DB))
    dry_run.add_argument("--seed-db", default=str(DEFAULT_SEED_DB))
    dry_run.add_argument("--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST))
    dry_run.add_argument("--source-xml", default=str(DEFAULT_SOURCE_XML))
    dry_run.add_argument("--result-output", default=str(DEFAULT_RESULT))

    build = subparsers.add_parser("build-manifest")
    build.add_argument("--output", default=str(DEFAULT_MANIFEST))
    build.add_argument("--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST))
    build.add_argument("--source-xml", default=str(DEFAULT_SOURCE_XML))

    apply = subparsers.add_parser("apply")
    apply.add_argument("--confirm", required=True)
    apply.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    apply.add_argument("--work-db", required=True)
    apply.add_argument("--seed-db", required=True)
    apply.add_argument("--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST))
    apply.add_argument("--source-xml", default=str(DEFAULT_SOURCE_XML))
    apply.add_argument("--backup-root", required=True)
    apply.add_argument("--result-output", required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    parser = build_parser()
    args = parser.parse_args(argv)
    command = args.command or "dry-run"
    try:
        if command == "build-manifest":
            result = write_manifest(
                Path(args.output),
                Path(args.source_manifest),
                Path(args.source_xml),
            )
        elif command == "apply":
            result = run_apply(
                confirmation=args.confirm,
                manifest_path=Path(args.manifest),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                backup_root=Path(args.backup_root),
                result_output=Path(args.result_output),
                source_manifest_path=Path(args.source_manifest),
                source_xml_path=Path(args.source_xml),
            )
        else:
            result = run_dry_run(
                manifest_path=Path(getattr(args, "manifest", DEFAULT_MANIFEST)),
                work_db=Path(getattr(args, "work_db", DEFAULT_WORK_DB)),
                seed_db=Path(getattr(args, "seed_db", DEFAULT_SEED_DB)),
                source_manifest_path=Path(
                    getattr(args, "source_manifest", DEFAULT_SOURCE_MANIFEST)
                ),
                source_xml_path=Path(
                    getattr(args, "source_xml", DEFAULT_SOURCE_XML)
                ),
                result_output=Path(getattr(args, "result_output", DEFAULT_RESULT)),
            )
    except (MigrationError, source_mapping.ManifestError, source_parser.SourceSchemaError) as error:
        print(f"Phase 50-W 실패: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
