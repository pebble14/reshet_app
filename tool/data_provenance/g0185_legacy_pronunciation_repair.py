#!/usr/bin/env python3
"""G0185 legacy pronunciation parity repair.

The approved manifest is the only target boundary. The tool removes only
``WORD_TABLE.발음2`` for ``G0185_0000`` from work and seed together.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Sequence


TOOL_VERSION = "1.0.0"
REPAIR_ID = "g0185_legacy_pronunciation_repair"
SCHEMA_VERSION = 1

TOOL_DIR = Path(__file__).resolve().parent
DEFAULT_MANIFEST = TOOL_DIR / "manifests" / f"{REPAIR_ID}.json"
DEFAULT_SOURCE_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_SOURCE_XML = TOOL_DIR / ".source_cache" / "strongsgreek.xml"

TARGET_ID = "G0185_0000"
TARGET_STRONG = "G0185"
TARGET_LANGUAGE = "헬라어"
LEGACY_COLUMN = "발음2"
EXPECTED_CURRENT_VALUE = "G2767"
EXPECTED_TARGET_VALUE = None
G0025_ID = "G0025_0000"
G0025_WORK_NOTE = "48-B3 백업 시점"

EXPECTED_SOURCE = {
    "commit": "dd6758b82f46b620804a8ea677d715844679eea1",
    "license": "CC0 1.0",
    "path": "strongsgreek.xml",
    "repository": "https://github.com/morphgnt/strongs-dictionary-xml",
    "sha256": "91474213b208a4e487d35f85c10e5c90737acc69082dad15dec5431406003545",
}

EXPECTED_INITIAL_SHA256 = {
    "seed": "c25cf32acdc8c1351ef84fed45bc304d7a72924660fbf135ae6c1e3bf5660697",
    "work": "9aa81325dc20e48c3fe59236a8d95f5d3602700bd3912d9bbdfaa92cc3cbeef4",
}

PROJECTION_FIELDS = [
    "word_id",
    "language",
    "strong_number",
    "legacy_column",
    "expected_current_value",
    "expected_target_value",
    "source_primary_spelling",
    "source_primary_transliteration",
    "source_primary_pronunciation",
    "source_derivation_reference",
    "normalized_expression_count",
    "normalized_expression_seq",
]

EXPECTED_PROJECTION_CONTRACT = {
    "bom": False,
    "encoding": "UTF-8",
    "ensure_ascii": False,
    "fields": PROJECTION_FIELDS,
    "final_lf": True,
    "format": "JSONL ordered arrays",
    "separators": [",", ":"],
    "sort": ["word_id ASC"],
}

EXPECTED_NORMALIZED_EXPRESSION = [
    {
        "is_representative": 1,
        "pronunciation": "ak-er'-ah-yos",
        "pronunciation_notation": "strong_dictionary",
        "pronunciation_notation_name": None,
        "seq": 1,
        "spelling": "ἀκέραιος",
        "transliteration": "아케라이오스",
        "word_id": TARGET_ID,
    }
]

EXPECTED_CANDIDATE_PROJECTION = [
    {
        "expected_current_value": EXPECTED_CURRENT_VALUE,
        "expected_target_value": EXPECTED_TARGET_VALUE,
        "language": TARGET_LANGUAGE,
        "legacy_column": LEGACY_COLUMN,
        "normalized_expression_count": 1,
        "normalized_expression_seq": 1,
        "source_derivation_reference": "G2767",
        "source_primary_pronunciation": "ak-er'-ah-yos",
        "source_primary_spelling": "ἀκέραιος",
        "source_primary_transliteration": "akéraios",
        "strong_number": TARGET_STRONG,
        "word_id": TARGET_ID,
    }
]

EXPECTED_PARITY_CONTRACT = {
    "compared": [
        "WORD_TABLE semantic projection excluding 비고",
        "word_expression_set semantic projection excluding surrogate id",
        "word_meaning_set semantic projection excluding surrogate id",
        "WORD_RELATION semantic projection excluding surrogate id",
    ],
    "excluded": [
        "WORD_TABLE.비고",
        "surrogate row id",
        "SQLite 물리 layout",
        "CHANGE_HISTORY의 DB별 정상 차이",
    ],
}

EXPECTED_PROTECTED_TARGETS = [
    "schema",
    "word_expression_set",
    "word_meaning_set",
    "WORD_RELATION",
    "CHANGE_HISTORY",
    "G0185 이외 WORD_TABLE 전체",
    "G0185 발음2 이외 모든 WORD_TABLE 컬럼",
    "G0025 모든 컬럼",
]

PROTECTION_KEYS = (
    "schema_sha256",
    "expression_table_count",
    "expression_table_sha256",
    "meaning_table_count",
    "meaning_table_sha256",
    "relation_table_count",
    "relation_table_sha256",
    "history_table_count",
    "history_table_sha256",
    "non_target_word_count",
    "non_target_word_sha256",
    "target_immutable_sha256",
    "g0025_sha256",
)

PARITY_KEYS = (
    "schema_sha256",
    "word_semantic_count",
    "word_semantic_sha256",
    "expression_semantic_count",
    "expression_semantic_sha256",
    "meaning_semantic_count",
    "meaning_semantic_sha256",
    "relation_semantic_count",
    "relation_semantic_sha256",
    "target_immutable_sha256",
)


class RepairError(RuntimeError):
    """Fail-closed G0185 repair error."""


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


def jsonl_sha256(rows: Iterable[Sequence[object]]) -> str:
    digest = hashlib.sha256()
    for row in rows:
        digest.update(
            (json.dumps(list(row), ensure_ascii=False, separators=(",", ":")) + "\n").encode(
                "utf-8"
            )
        )
    return digest.hexdigest()


def _read_json_object(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise RepairError(f"JSON 읽기 실패: {path}: {error}") from error
    if not isinstance(value, dict):
        raise RepairError(f"JSON top-level object가 아님: {path}")
    return value


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def normalize_strong(value: object) -> str | None:
    match = re.fullmatch(r"G\s*0*(\d+)", str(value or "").strip(), re.IGNORECASE)
    if match is None:
        return None
    number = int(match.group(1))
    if not 1 <= number <= 5624:
        return None
    return f"G{number:04d}"


def load_manifest(path: Path) -> dict[str, object]:
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise RepairError(f"input manifest 읽기 실패: {path}: {error}") from error
    if raw.startswith(b"\xef\xbb\xbf"):
        raise RepairError("input manifest에 UTF-8 BOM이 있음")
    try:
        manifest = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise RepairError(f"input manifest JSON parsing 실패: {error}") from error
    if not isinstance(manifest, dict):
        raise RepairError("input manifest top-level object가 아님")
    if canonical_json_bytes(manifest) != raw:
        raise RepairError("input manifest canonical byte 형식 불일치")

    required = {
        "allowed_changes",
        "candidate_projection",
        "candidate_projection_contract",
        "candidate_projection_sha256",
        "expected_initial_database_sha256",
        "parity_contract",
        "protected_targets",
        "repair",
        "schema_version",
        "source",
        "source_evidence",
        "target",
    }
    if set(manifest) != required:
        raise RepairError("input manifest top-level field 불일치")
    if manifest["schema_version"] != SCHEMA_VERSION or manifest["repair"] != REPAIR_ID:
        raise RepairError("input manifest schema_version 또는 repair 불일치")
    if manifest["source"] != EXPECTED_SOURCE:
        raise RepairError("input manifest source boundary 불일치")
    if manifest["expected_initial_database_sha256"] != EXPECTED_INITIAL_SHA256:
        raise RepairError("input manifest active DB 시작 SHA 불일치")
    if manifest["candidate_projection_contract"] != EXPECTED_PROJECTION_CONTRACT:
        raise RepairError("candidate projection contract 불일치")
    if manifest["allowed_changes"] != [f"WORD_TABLE.{LEGACY_COLUMN}"]:
        raise RepairError("허용 변경 컬럼 불일치")
    if manifest["parity_contract"] != EXPECTED_PARITY_CONTRACT:
        raise RepairError("parity contract 불일치")
    if manifest["protected_targets"] != EXPECTED_PROTECTED_TARGETS:
        raise RepairError("보호 대상 contract 불일치")

    target = manifest["target"]
    if not isinstance(target, dict):
        raise RepairError("target object 누락")
    expected_target = {
        "expected_current_legacy_value": EXPECTED_CURRENT_VALUE,
        "expected_normalized_expression": EXPECTED_NORMALIZED_EXPRESSION,
        "expected_spelling2": None,
        "expected_target_legacy_value": None,
        "expected_transliteration2": None,
        "id": TARGET_ID,
        "language": TARGET_LANGUAGE,
        "legacy_column": LEGACY_COLUMN,
        "strong_number": TARGET_STRONG,
    }
    if target != expected_target:
        raise RepairError("target identity 또는 expected state 불일치")

    projection = manifest["candidate_projection"]
    if projection != EXPECTED_CANDIDATE_PROJECTION:
        raise RepairError("candidate projection target 불일치")
    row = projection[0]
    if not isinstance(row, dict) or set(row) != set(PROJECTION_FIELDS):
        raise RepairError("candidate projection field 불일치")
    projection_sha = jsonl_sha256([[row[field] for field in PROJECTION_FIELDS]])
    if projection_sha != manifest["candidate_projection_sha256"]:
        raise RepairError("candidate projection SHA 재현 실패")
    manifest["_file_sha256"] = sha256_bytes(raw)
    return manifest


def parse_source_evidence(path: Path) -> dict[str, object]:
    try:
        root = ET.parse(path).getroot()
    except (ET.ParseError, OSError) as error:
        raise RepairError(f"Greek source parsing 실패: {path}: {error}") from error
    entries = next((node for node in root if _local_name(node.tag) == "entries"), None)
    if entries is None:
        raise RepairError("Greek source entries node가 없음")
    target_entry = next(
        (
            node
            for node in entries
            if _local_name(node.tag) == "entry"
            and normalize_strong(f"G{node.get('strongs') or ''}") == TARGET_STRONG
        ),
        None,
    )
    if target_entry is None:
        raise RepairError("Greek source G0185 entry가 없음")

    head_forms: list[dict[str, object]] = []
    derivation_references: list[dict[str, str]] = []
    for child in target_entry:
        name = _local_name(child.tag)
        if name == "greek":
            head_forms.append(
                {
                    "pronunciation": None,
                    "spelling": child.get("unicode"),
                    "transliteration": child.get("translit"),
                }
            )
        elif name == "pronunciation" and head_forms and head_forms[-1]["pronunciation"] is None:
            head_forms[-1]["pronunciation"] = child.get("strongs")
        elif name == "strongs_derivation":
            for reference in child.iter():
                if _local_name(reference.tag) != "strongsref":
                    continue
                language = str(reference.get("language") or "").upper()
                strong = normalize_strong(f"G{reference.get('strongs') or ''}")
                if language == "GREEK" and strong is not None:
                    derivation_references.append(
                        {"language": language, "strong_number": strong}
                    )
    return {
        "derivation_references": derivation_references,
        "entry": TARGET_STRONG,
        "head_forms": head_forms,
    }


def verify_source_boundary(
    source_manifest_path: Path,
    source_xml_path: Path,
    manifest: dict[str, object],
) -> dict[str, object]:
    source_manifest = _read_json_object(source_manifest_path)
    sources = source_manifest.get("sources")
    if not isinstance(sources, list):
        raise RepairError("source manifest sources가 list가 아님")
    matches = [
        item
        for item in sources
        if isinstance(item, dict)
        and item.get("repository") == EXPECTED_SOURCE["repository"]
        and item.get("commit") == EXPECTED_SOURCE["commit"]
        and item.get("file_path") == EXPECTED_SOURCE["path"]
    ]
    if len(matches) != 1:
        raise RepairError("Greek source manifest 고정 경계 불일치")
    source_record = matches[0]
    for key in ("sha256", "license"):
        if source_record.get(key) != EXPECTED_SOURCE[key]:
            raise RepairError(f"Greek source manifest {key} 불일치")
    actual_sha = sha256_file(source_xml_path)
    if actual_sha != EXPECTED_SOURCE["sha256"]:
        raise RepairError(
            f"Greek source XML SHA 불일치: expected={EXPECTED_SOURCE['sha256']}, actual={actual_sha}"
        )
    evidence = parse_source_evidence(source_xml_path)
    if evidence != manifest["source_evidence"]:
        raise RepairError("G0185 source XML context 불일치")
    return {
        **EXPECTED_SOURCE,
        "evidence": evidence,
        "source_manifest_path": _portable_path(source_manifest_path),
        "source_manifest_sha256": sha256_file(source_manifest_path),
        "xml_path": _portable_path(source_xml_path),
    }


def _quote_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def _schema_table(schema: str, table: str) -> str:
    return f"{_quote_identifier(schema)}.{_quote_identifier(table)}"


def open_read_only(path: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro&immutable=1", uri=True)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA query_only = ON")
    if int(connection.execute("PRAGMA query_only").fetchone()[0]) != 1:
        connection.close()
        raise RepairError(f"SQLite query_only 보장 실패: {path}")
    return connection


def _table_columns(connection: sqlite3.Connection, schema: str, table: str) -> list[str]:
    return [
        str(row[1])
        for row in connection.execute(
            f"PRAGMA {_quote_identifier(schema)}.table_info({_quote_identifier(table)})"
        )
    ]


def verify_database_health(
    connection: sqlite3.Connection, schema: str = "main"
) -> dict[str, object]:
    required = {
        "WORD_TABLE": {"id", "언어", "스트롱넘버", "표기2", "음역2", "발음2", "비고", "graph_expand_mode"},
        "word_expression_set": {
            "id",
            "word_id",
            "seq",
            "is_representative",
            "spelling",
            "transliteration",
            "pronunciation",
            "pronunciation_notation",
            "pronunciation_notation_name",
        },
        "word_meaning_set": {"id", "word_id", "seq", "meaning"},
        "WORD_RELATION": {"id", "word_id_1", "word_id_2"},
        "CHANGE_HISTORY": {"id", "entity_id", "before_json", "after_json"},
    }
    missing: dict[str, list[str]] = {}
    for table, expected in required.items():
        absent = expected - set(_table_columns(connection, schema, table))
        if absent:
            missing[table] = sorted(absent)
    if missing:
        raise RepairError(f"required schema 누락: {missing}")
    integrity = [
        str(row[0])
        for row in connection.execute(f"PRAGMA {_quote_identifier(schema)}.integrity_check")
    ]
    foreign_keys = connection.execute(
        f"PRAGMA {_quote_identifier(schema)}.foreign_key_check"
    ).fetchall()
    journal_mode = str(
        connection.execute(f"PRAGMA {_quote_identifier(schema)}.journal_mode").fetchone()[0]
    ).lower()
    if integrity != ["ok"]:
        raise RepairError(f"integrity_check 실패: {schema}: {integrity}")
    if foreign_keys:
        raise RepairError(f"foreign_key_check 실패: {schema}: {len(foreign_keys)}")
    return {
        "foreign_key_violation_count": 0,
        "integrity_check": "ok",
        "journal_mode": journal_mode,
        "required_schema_present": True,
    }


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
        raise RepairError(f"active SQLite sidecar 발견: {active}")


def _rows_as_lists(
    connection: sqlite3.Connection,
    schema: str,
    table: str,
    *,
    excluded_columns: set[str] | None = None,
    where: str | None = None,
    parameters: Sequence[object] = (),
    semantic_sort: bool = False,
) -> tuple[list[str], list[list[object]]]:
    excluded_columns = excluded_columns or set()
    columns = [
        column
        for column in _table_columns(connection, schema, table)
        if column not in excluded_columns
    ]
    if not columns:
        raise RepairError(f"projection column이 없음: {schema}.{table}")
    sql = f"SELECT {', '.join(_quote_identifier(column) for column in columns)} FROM {_schema_table(schema, table)}"
    if where:
        sql += f" WHERE {where}"
    rows = [list(row) for row in connection.execute(sql, parameters).fetchall()]
    if semantic_sort:
        rows.sort(key=lambda row: json.dumps(row, ensure_ascii=False, separators=(",", ":")))
    return columns, rows


def _projection(
    connection: sqlite3.Connection,
    schema: str,
    table: str,
    **kwargs: object,
) -> tuple[int, str]:
    _, rows = _rows_as_lists(connection, schema, table, **kwargs)
    return len(rows), jsonl_sha256(rows)


def _schema_hash(connection: sqlite3.Connection, schema: str) -> str:
    rows = connection.execute(
        f"""
        SELECT type, name, tbl_name, sql
        FROM {_quote_identifier(schema)}.sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        """
    ).fetchall()
    return jsonl_sha256([list(row) for row in rows])


def _dict_rows(
    connection: sqlite3.Connection,
    sql: str,
    parameters: Sequence[object] = (),
) -> list[dict[str, object]]:
    return [dict(row) for row in connection.execute(sql, parameters).fetchall()]


def capture_snapshot(connection: sqlite3.Connection, schema: str) -> dict[str, object]:
    word_table = _schema_table(schema, "WORD_TABLE")
    expression_table = _schema_table(schema, "word_expression_set")
    meaning_table = _schema_table(schema, "word_meaning_set")
    relation_table = _schema_table(schema, "WORD_RELATION")
    history_table = _schema_table(schema, "CHANGE_HISTORY")

    target_rows = _dict_rows(
        connection, f"SELECT * FROM {word_table} WHERE id=?", (TARGET_ID,)
    )
    if len(target_rows) != 1:
        raise RepairError(f"G0185 target row count 불일치: {schema}: {len(target_rows)}")
    target = target_rows[0]
    target_columns = _table_columns(connection, schema, "WORD_TABLE")
    immutable_values = [target[column] for column in target_columns if column != LEGACY_COLUMN]

    expression_rows = _dict_rows(
        connection,
        f"SELECT * FROM {expression_table} WHERE word_id=? ORDER BY seq, id",
        (TARGET_ID,),
    )
    meaning_rows = _dict_rows(
        connection,
        f"SELECT * FROM {meaning_table} WHERE word_id=? ORDER BY seq, id",
        (TARGET_ID,),
    )
    relation_rows = _dict_rows(
        connection,
        f"SELECT * FROM {relation_table} WHERE word_id_1=? OR word_id_2=? ORDER BY id",
        (TARGET_ID, TARGET_ID),
    )
    history_rows = _dict_rows(
        connection,
        f"SELECT * FROM {history_table} WHERE entity_id=? OR before_json LIKE ? OR after_json LIKE ? ORDER BY id",
        (TARGET_ID, f"%{TARGET_ID}%", f"%{TARGET_ID}%"),
    )
    g0025_rows = _dict_rows(
        connection, f"SELECT * FROM {word_table} WHERE id=?", (G0025_ID,)
    )
    if len(g0025_rows) != 1:
        raise RepairError(f"G0025 row count 불일치: {schema}: {len(g0025_rows)}")

    expression_count, expression_hash = _projection(
        connection, schema, "word_expression_set", semantic_sort=True
    )
    meaning_count, meaning_hash = _projection(
        connection, schema, "word_meaning_set", semantic_sort=True
    )
    relation_count, relation_hash = _projection(
        connection, schema, "WORD_RELATION", semantic_sort=True
    )
    history_count, history_hash = _projection(
        connection, schema, "CHANGE_HISTORY", semantic_sort=True
    )
    non_target_count, non_target_hash = _projection(
        connection,
        schema,
        "WORD_TABLE",
        where="id <> ?",
        parameters=(TARGET_ID,),
        semantic_sort=True,
    )

    word_semantic_count, word_semantic_hash = _projection(
        connection,
        schema,
        "WORD_TABLE",
        excluded_columns={"비고"},
        semantic_sort=True,
    )
    expression_semantic_count, expression_semantic_hash = _projection(
        connection,
        schema,
        "word_expression_set",
        excluded_columns={"id"},
        semantic_sort=True,
    )
    meaning_semantic_count, meaning_semantic_hash = _projection(
        connection,
        schema,
        "word_meaning_set",
        excluded_columns={"id"},
        semantic_sort=True,
    )
    relation_semantic_count, relation_semantic_hash = _projection(
        connection,
        schema,
        "WORD_RELATION",
        excluded_columns={"id"},
        semantic_sort=True,
    )

    return {
        "expression_rows": expression_rows,
        "expression_table_count": expression_count,
        "expression_table_sha256": expression_hash,
        "expression_semantic_count": expression_semantic_count,
        "expression_semantic_sha256": expression_semantic_hash,
        "g0025_note": g0025_rows[0]["비고"],
        "g0025_sha256": jsonl_sha256(
            [[g0025_rows[0][column] for column in target_columns]]
        ),
        "history_rows": history_rows,
        "history_table_count": history_count,
        "history_table_sha256": history_hash,
        "meaning_rows": meaning_rows,
        "meaning_table_count": meaning_count,
        "meaning_table_sha256": meaning_hash,
        "meaning_semantic_count": meaning_semantic_count,
        "meaning_semantic_sha256": meaning_semantic_hash,
        "non_target_word_count": non_target_count,
        "non_target_word_sha256": non_target_hash,
        "relation_rows": relation_rows,
        "relation_table_count": relation_count,
        "relation_table_sha256": relation_hash,
        "relation_semantic_count": relation_semantic_count,
        "relation_semantic_sha256": relation_semantic_hash,
        "schema_sha256": _schema_hash(connection, schema),
        "target": target,
        "target_immutable_sha256": jsonl_sha256([immutable_values]),
        "word_semantic_count": word_semantic_count,
        "word_semantic_sha256": word_semantic_hash,
    }


def _normalized_semantic(rows: Sequence[dict[str, object]]) -> list[dict[str, object]]:
    fields = [
        "word_id",
        "seq",
        "is_representative",
        "spelling",
        "transliteration",
        "pronunciation",
        "pronunciation_notation",
        "pronunciation_notation_name",
    ]
    return [{field: row[field] for field in fields} for row in rows]


def validate_database_state(
    connection: sqlite3.Connection,
    schema: str,
    manifest: dict[str, object],
    *,
    label: str,
    expected_state: str | None,
) -> tuple[str, dict[str, object], dict[str, object]]:
    health = verify_database_health(connection, schema)
    snapshot = capture_snapshot(connection, schema)
    target = snapshot["target"]
    if not isinstance(target, dict):
        raise RepairError(f"target snapshot 형식 불일치: {schema}")
    if (
        target["id"] != TARGET_ID
        or target["언어"] != TARGET_LANGUAGE
        or target["스트롱넘버"] != TARGET_STRONG
    ):
        raise RepairError(f"target identity mismatch: {schema}")
    if target["표기2"] is not None or target["음역2"] is not None:
        raise RepairError(f"표기2·음역2 predicate 경계 불일치: {schema}")
    value = target[LEGACY_COLUMN]
    if value == EXPECTED_CURRENT_VALUE:
        state = "current"
    elif value is EXPECTED_TARGET_VALUE:
        state = "target"
    else:
        raise RepairError(f"current value mismatch: {schema}: {value!r}")
    if expected_state is not None and state != expected_state:
        raise RepairError(
            f"DB target state 불일치: {schema}: expected={expected_state}, actual={state}"
        )
    expected_expression = manifest["target"]["expected_normalized_expression"]
    if _normalized_semantic(snapshot["expression_rows"]) != expected_expression:
        raise RepairError(f"normalized expression mismatch: {schema}")
    expected_note = G0025_WORK_NOTE if label == "work" else None
    if snapshot["g0025_note"] != expected_note:
        raise RepairError(
            f"G0025 비고 경계 불일치: {label}: {snapshot['g0025_note']!r}"
        )
    return state, health, snapshot


def compare_work_seed_parity(
    work: dict[str, object], seed: dict[str, object]
) -> dict[str, object]:
    differences = [key for key in PARITY_KEYS if work[key] != seed[key]]
    if differences:
        raise RepairError(f"work·seed semantic parity 불일치: {differences}")
    if work["g0025_note"] != G0025_WORK_NOTE or seed["g0025_note"] is not None:
        raise RepairError("G0025 비고 제외 경계 불일치")
    return {
        "compared_keys": list(PARITY_KEYS),
        "exact": True,
        "excluded": ["WORD_TABLE.비고", "surrogate row id", "CHANGE_HISTORY", "SQLite 물리 layout"],
        "g0025_note_difference_allowed": True,
        "target_immutable_sha256": work["target_immutable_sha256"],
        "word_semantic_sha256": work["word_semantic_sha256"],
    }


def verify_protection_unchanged(
    before: dict[str, object], after: dict[str, object], label: str
) -> list[dict[str, object]]:
    changed = [key for key in PROTECTION_KEYS if before[key] != after[key]]
    if changed:
        raise RepairError(f"보호 projection 변경: {label}: {changed}")
    before_target = before["target"]
    after_target = after["target"]
    if not isinstance(before_target, dict) or not isinstance(after_target, dict):
        raise RepairError(f"target projection 형식 불일치: {label}")
    diff = [
        {
            "column": column,
            "from": before_target[column],
            "to": after_target[column],
        }
        for column in before_target
        if before_target[column] != after_target[column]
    ]
    expected_diff = [
        {"column": LEGACY_COLUMN, "from": EXPECTED_CURRENT_VALUE, "to": None}
    ]
    if diff != expected_diff:
        raise RepairError(f"허용된 단일 셀 외 target diff 발생: {label}: {diff}")
    return diff


def _portable_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return str(resolved)


def _same_local_volume(left: Path, right: Path) -> bool:
    left_resolved = left.resolve()
    right_resolved = right.resolve()
    return (
        os.path.splitdrive(str(left_resolved))[0].casefold()
        == os.path.splitdrive(str(right_resolved))[0].casefold()
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
        destination = backup_dir / f"reshet_{label}_pre_g0185_repair.db"
        source_sha = sha256_file(source)
        shutil.copy2(source, destination)
        backup_sha = sha256_file(destination)
        if source_sha != backup_sha:
            raise RepairError(f"backup byte SHA 불일치: {label}")
        connection = open_read_only(destination)
        try:
            health = verify_database_health(connection)
        finally:
            connection.close()
        result[label] = {
            "backup_path": _portable_path(destination),
            "backup_sha256": backup_sha,
            "foreign_key_violation_count": health["foreign_key_violation_count"],
            "integrity_check": health["integrity_check"],
            "original_path": _portable_path(source),
            "original_sha256": source_sha,
            "size_bytes": destination.stat().st_size,
        }
    return backup_dir, result


def restore_verified_backups(
    work_db: Path, seed_db: Path, backup_metadata: dict[str, object]
) -> dict[str, object]:
    restored: dict[str, object] = {}
    for label, target in (("work", work_db), ("seed", seed_db)):
        info = backup_metadata[label]
        if not isinstance(info, dict):
            raise RepairError(f"backup metadata 누락: {label}")
        backup_path = Path(str(info["backup_path"]))
        if not backup_path.is_absolute():
            backup_path = Path.cwd() / backup_path
        for sidecar in sidecar_paths(target):
            if sidecar.exists():
                sidecar.unlink()
        shutil.copy2(backup_path, target)
        actual_sha = sha256_file(target)
        if actual_sha != info["original_sha256"]:
            raise RepairError(f"backup restore SHA 불일치: {label}")
        connection = open_read_only(target)
        try:
            health = verify_database_health(connection)
        finally:
            connection.close()
        restored[label] = {
            "foreign_key_violation_count": health["foreign_key_violation_count"],
            "integrity_check": health["integrity_check"],
            "sha256": actual_sha,
        }
    assert_no_sidecars((work_db, seed_db))
    return restored


def write_json_atomic(path: Path, payload: dict[str, object]) -> str:
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
    actual_sha = sha256_file(path)
    if actual_sha != sha256_bytes(data):
        raise RepairError("result artifact atomic write SHA 검증 실패")
    return actual_sha


def _load_boundaries(
    manifest_path: Path,
    source_manifest_path: Path,
    source_xml_path: Path,
) -> tuple[dict[str, object], dict[str, object]]:
    manifest = load_manifest(manifest_path)
    source = verify_source_boundary(source_manifest_path, source_xml_path, manifest)
    return manifest, source


def _validate_initial_hashes(
    hashes: dict[str, str], manifest: dict[str, object]
) -> None:
    if hashes != manifest["expected_initial_database_sha256"]:
        raise RepairError(
            f"active DB 시작 SHA 불일치: expected={manifest['expected_initial_database_sha256']}, actual={hashes}"
        )


def _read_database_pair(
    work_db: Path,
    seed_db: Path,
    manifest: dict[str, object],
    expected_state: str | None,
) -> tuple[
    str,
    dict[str, object],
    dict[str, object],
    dict[str, object],
    dict[str, object],
    dict[str, object],
]:
    work_connection = open_read_only(work_db)
    seed_connection = open_read_only(seed_db)
    try:
        work_state, work_health, work_snapshot = validate_database_state(
            work_connection,
            "main",
            manifest,
            label="work",
            expected_state=expected_state,
        )
        seed_state, seed_health, seed_snapshot = validate_database_state(
            seed_connection,
            "main",
            manifest,
            label="seed",
            expected_state=expected_state,
        )
        if work_state != seed_state:
            raise RepairError(
                f"work·seed 적용 상태 불일치: work={work_state}, seed={seed_state}"
            )
        parity = compare_work_seed_parity(work_snapshot, seed_snapshot)
    finally:
        work_connection.close()
        seed_connection.close()
    return work_state, work_health, seed_health, work_snapshot, seed_snapshot, parity


def run_dry_run(
    *,
    manifest_path: Path,
    work_db: Path,
    seed_db: Path,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    enforce_initial_hashes: bool = True,
) -> dict[str, object]:
    assert_no_sidecars((work_db, seed_db))
    manifest, source = _load_boundaries(
        manifest_path, source_manifest_path, source_xml_path
    )
    input_hashes = {"seed": sha256_file(seed_db), "work": sha256_file(work_db)}
    state, work_health, seed_health, work_snapshot, seed_snapshot, parity = (
        _read_database_pair(work_db, seed_db, manifest, None)
    )
    if state == "current" and enforce_initial_hashes:
        _validate_initial_hashes(input_hashes, manifest)
    output_hashes = {"seed": sha256_file(seed_db), "work": sha256_file(work_db)}
    assert_no_sidecars((work_db, seed_db))
    if input_hashes != output_hashes:
        raise RepairError("dry-run 전후 DB SHA가 변경됨")
    planned = 2 if state == "current" else 0
    return {
        "candidate_projection_sha256": manifest["candidate_projection_sha256"],
        "database_sha256_after": output_hashes,
        "database_sha256_before": input_hashes,
        "manifest_sha256": manifest["_file_sha256"],
        "mode": "dry-run",
        "parity": parity,
        "planned_change_count": planned,
        "repair": REPAIR_ID,
        "sidecar_count": 0,
        "source": source,
        "state": state,
        "status": "적용 가능 — 변경 예정 2" if planned else "이미 적용됨 — 변경 0",
        "work": {"health": work_health, "snapshot": work_snapshot},
        "seed": {"health": seed_health, "snapshot": seed_snapshot},
    }


def _validate_attached_paths(
    connection: sqlite3.Connection, work_db: Path, seed_db: Path
) -> list[dict[str, object]]:
    rows = connection.execute("PRAGMA database_list").fetchall()
    result = [
        {"name": str(row[1]), "path": str(Path(row[2]).resolve()), "seq": int(row[0])}
        for row in rows
        if str(row[1]) in {"main", "seed_db"}
    ]
    paths = {item["name"]: Path(str(item["path"])).resolve() for item in result}
    if paths.get("main") != work_db.resolve() or paths.get("seed_db") != seed_db.resolve():
        raise RepairError(f"ATTACH database_list 경로 불일치: {result}")
    return [
        {**item, "path": _portable_path(Path(str(item["path"])))} for item in result
    ]


def _update_target(
    connection: sqlite3.Connection, schema: str
) -> int:
    cursor = connection.execute(
        f"""
        UPDATE {_schema_table(schema, 'WORD_TABLE')}
        SET {_quote_identifier(LEGACY_COLUMN)} = NULL
        WHERE id = ?
          AND {_quote_identifier('스트롱넘버')} = ?
          AND {_quote_identifier('언어')} = ?
          AND {_quote_identifier(LEGACY_COLUMN)} = ?
          AND {_quote_identifier('표기2')} IS NULL
          AND {_quote_identifier('음역2')} IS NULL
        """,
        (TARGET_ID, TARGET_STRONG, TARGET_LANGUAGE, EXPECTED_CURRENT_VALUE),
    )
    if cursor.rowcount != 1:
        raise RepairError(f"UPDATE rowcount 불일치: {schema}: {cursor.rowcount}")
    return cursor.rowcount


def _result_matches_current_state(
    result_output: Path,
    manifest: dict[str, object],
    work_db: Path,
    seed_db: Path,
    work_snapshot: dict[str, object],
    seed_snapshot: dict[str, object],
) -> dict[str, object]:
    result = _read_json_object(result_output)
    if result.get("schema_version") != SCHEMA_VERSION or result.get("repair") != REPAIR_ID:
        raise RepairError("matching result schema/repair 불일치")
    if result.get("tool_version") != TOOL_VERSION:
        raise RepairError("matching result tool_version 불일치")
    if result.get("input_manifest_sha256") != manifest["_file_sha256"]:
        raise RepairError("matching result input manifest SHA 불일치")
    if result.get("candidate_projection_sha256") != manifest["candidate_projection_sha256"]:
        raise RepairError("matching result candidate projection SHA 불일치")
    for label, path, snapshot in (
        ("work", work_db, work_snapshot),
        ("seed", seed_db, seed_snapshot),
    ):
        section = result.get(label)
        if not isinstance(section, dict) or section.get("output_sha256") != sha256_file(path):
            raise RepairError(f"matching result {label} output SHA 불일치")
        protection = section.get("protection")
        if not isinstance(protection, dict):
            raise RepairError(f"matching result {label} protection 누락")
        for key in PROTECTION_KEYS:
            values = protection.get(key)
            if not isinstance(values, dict) or values.get("post") != snapshot[key]:
                raise RepairError(f"matching result {label} protection 불일치: {key}")
    return result


def _database_result(
    input_sha: str,
    output_sha: str,
    before: dict[str, object],
    after: dict[str, object],
    health_before: dict[str, object],
    health_after: dict[str, object],
    diff: list[dict[str, object]],
) -> dict[str, object]:
    return {
        "counts": {
            key: {"post": after[key], "pre": before[key]}
            for key in (
                "expression_table_count",
                "meaning_table_count",
                "relation_table_count",
                "history_table_count",
                "non_target_word_count",
            )
        },
        "health": {"post": health_after, "pre": health_before},
        "input_sha256": input_sha,
        "logical_diff": diff,
        "output_sha256": output_sha,
        "protection": {
            key: {"post": after[key], "pre": before[key]} for key in PROTECTION_KEYS
        },
        "target_post": after["target"],
        "target_pre": before["target"],
    }


def run_apply(
    *,
    manifest_path: Path,
    work_db: Path,
    seed_db: Path,
    backup_root: Path,
    result_output: Path,
    confirm: bool,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    enforce_initial_hashes: bool = True,
    fault_injection: str | None = None,
) -> dict[str, object]:
    if not confirm:
        raise RepairError("apply에는 명시적 confirmation flag가 필요함")
    if work_db.resolve() == seed_db.resolve():
        raise RepairError("work와 seed DB 경로가 같음")
    if not _same_local_volume(work_db, seed_db):
        raise RepairError("work와 seed가 같은 local filesystem/volume이 아님")
    assert_no_sidecars((work_db, seed_db))
    manifest, source = _load_boundaries(
        manifest_path, source_manifest_path, source_xml_path
    )
    input_hashes = {"seed": sha256_file(seed_db), "work": sha256_file(work_db)}
    state, work_health_pre, seed_health_pre, work_pre, seed_pre, parity_pre = (
        _read_database_pair(work_db, seed_db, manifest, None)
    )
    if state == "target":
        if not result_output.exists():
            raise RepairError("이미 적용 상태지만 matching result artifact가 없음")
        _result_matches_current_state(
            result_output, manifest, work_db, seed_db, work_pre, seed_pre
        )
        assert_no_sidecars((work_db, seed_db))
        return {
            "backup_created": False,
            "change_count": 0,
            "database_sha256": input_hashes,
            "mode": "apply",
            "parity": parity_pre,
            "repair": REPAIR_ID,
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": sha256_file(result_output),
            "result_unchanged": True,
            "status": "이미 적용됨 — 변경 0",
            "transaction_started": False,
        }
    if state != "current":
        raise RepairError(f"지원하지 않는 target state: {state}")
    if enforce_initial_hashes:
        _validate_initial_hashes(input_hashes, manifest)
    if result_output.exists():
        raise RepairError("미적용 DB인데 result artifact가 이미 존재함")
    if work_health_pre["journal_mode"] != "delete" or seed_health_pre["journal_mode"] != "delete":
        raise RepairError("apply 전 journal_mode=delete 조건 불충족")

    backup_dir, backup_metadata = create_verified_backups(
        work_db, seed_db, backup_root
    )
    connection: sqlite3.Connection | None = None
    committed = False
    result_written = False
    rollback_error: Exception | None = None
    try:
        connection = sqlite3.connect(str(work_db.resolve()))
        connection.row_factory = sqlite3.Row
        main_journal = str(connection.execute("PRAGMA main.journal_mode").fetchone()[0]).lower()
        connection.execute("ATTACH DATABASE ? AS seed_db", (str(seed_db.resolve()),))
        seed_journal = str(connection.execute("PRAGMA seed_db.journal_mode").fetchone()[0]).lower()
        database_list = _validate_attached_paths(connection, work_db, seed_db)
        if main_journal != "delete" or seed_journal != "delete":
            raise RepairError(
                f"ATTACH journal_mode 조건 불충족: main={main_journal}, seed={seed_journal}"
            )
        assert_no_sidecars((work_db, seed_db))
        connection.execute("BEGIN IMMEDIATE")
        _, _, work_tx_pre = validate_database_state(
            connection, "main", manifest, label="work", expected_state="current"
        )
        _, _, seed_tx_pre = validate_database_state(
            connection, "seed_db", manifest, label="seed", expected_state="current"
        )
        compare_work_seed_parity(work_tx_pre, seed_tx_pre)
        if work_tx_pre != work_pre or seed_tx_pre != seed_pre:
            raise RepairError("transaction 직전 protection snapshot이 변경됨")

        work_changed = _update_target(connection, "main")
        if fault_injection == "after_work_update":
            raise RepairError("test fault injection: after_work_update")
        if fault_injection == "seed_rowcount_mismatch":
            connection.execute(
                f"UPDATE {_schema_table('seed_db', 'WORD_TABLE')} SET {_quote_identifier(LEGACY_COLUMN)}='fault' WHERE id=?",
                (TARGET_ID,),
            )
        seed_changed = _update_target(connection, "seed_db")

        _, _, work_tx_post = validate_database_state(
            connection, "main", manifest, label="work", expected_state="target"
        )
        _, _, seed_tx_post = validate_database_state(
            connection, "seed_db", manifest, label="seed", expected_state="target"
        )
        work_diff = verify_protection_unchanged(
            work_pre, work_tx_post, "work/transaction"
        )
        seed_diff = verify_protection_unchanged(
            seed_pre, seed_tx_post, "seed/transaction"
        )
        parity_tx_post = compare_work_seed_parity(work_tx_post, seed_tx_post)
        connection.commit()
        committed = True
        connection.close()
        connection = None

        if fault_injection == "post_commit_validation":
            raise RepairError("test fault injection: post_commit_validation")

        assert_no_sidecars((work_db, seed_db))
        (
            _,
            work_health_post,
            seed_health_post,
            work_post,
            seed_post,
            parity_post,
        ) = _read_database_pair(work_db, seed_db, manifest, "target")
        verify_protection_unchanged(work_pre, work_post, "work/post-commit")
        verify_protection_unchanged(seed_pre, seed_post, "seed/post-commit")
        output_hashes = {"seed": sha256_file(seed_db), "work": sha256_file(work_db)}
        result_payload: dict[str, object] = {
            "attach": {
                "database_list": database_list,
                "journal_mode": {"main": main_journal, "seed_db": seed_journal},
                "same_local_filesystem_volume": True,
                "single_connection_transaction": True,
            },
            "backup": {"directory": _portable_path(backup_dir), **backup_metadata},
            "candidate_projection_sha256": manifest["candidate_projection_sha256"],
            "change_counts": {
                "columns_changed": [f"WORD_TABLE.{LEGACY_COLUMN}"],
                "seed": seed_changed,
                "total_database_rows": work_changed + seed_changed,
                "work": work_changed,
            },
            "executed_at_utc": datetime.now(timezone.utc).isoformat(),
            "input_manifest_path": _portable_path(manifest_path),
            "input_manifest_sha256": manifest["_file_sha256"],
            "parity_post": parity_post,
            "parity_pre": parity_pre,
            "parity_transaction_post": parity_tx_post,
            "repair": REPAIR_ID,
            "schema_version": SCHEMA_VERSION,
            "second_run": {
                "backup_created": False,
                "change_count": 0,
                "message": "이미 적용됨 — 변경 0",
                "result_unchanged": True,
                "status": "already_applied_noop_verified",
                "transaction_started": False,
            },
            "source": source,
            "sql": {
                "predicate": "id='G0185_0000' AND 스트롱넘버='G0185' AND 언어='헬라어' AND 발음2='G2767' AND 표기2 IS NULL AND 음역2 IS NULL",
                "statement": "UPDATE WORD_TABLE SET 발음2=NULL WHERE <fail-closed predicate>",
            },
            "tool_version": TOOL_VERSION,
            "work": _database_result(
                input_hashes["work"],
                output_hashes["work"],
                work_pre,
                work_post,
                work_health_pre,
                work_health_post,
                work_diff,
            ),
            "seed": _database_result(
                input_hashes["seed"],
                output_hashes["seed"],
                seed_pre,
                seed_post,
                seed_health_pre,
                seed_health_post,
                seed_diff,
            ),
        }
        if fault_injection == "result_write":
            raise RepairError("test fault injection: result_write")
        result_sha = write_json_atomic(result_output, result_payload)
        result_written = True
        _result_matches_current_state(
            result_output, manifest, work_db, seed_db, work_post, seed_post
        )
        return {
            "backup": backup_metadata,
            "backup_directory": _portable_path(backup_dir),
            "database_sha256_after": output_hashes,
            "database_sha256_before": input_hashes,
            "mode": "apply",
            "parity": parity_post,
            "repair": REPAIR_ID,
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": result_sha,
            "seed_change_count": seed_changed,
            "status": "적용 완료 — work 1, seed 1",
            "work_change_count": work_changed,
        }
    except Exception as error:
        if connection is not None:
            try:
                connection.rollback()
            except Exception as rollback_failure:  # pragma: no cover
                rollback_error = rollback_failure
            finally:
                connection.close()
        restore_error: Exception | None = None
        restore_result: dict[str, object] | None = None
        try:
            restore_result = restore_verified_backups(
                work_db, seed_db, backup_metadata
            )
        except Exception as restore_failure:  # pragma: no cover
            restore_error = restore_failure
        if result_written and result_output.exists():
            result_output.unlink()
        details = [f"apply 실패: {error}", f"committed={committed}"]
        details.append(
            f"rollback 실패={rollback_error}" if rollback_error else "rollback 오류 없음"
        )
        details.append(
            f"backup restore 실패={restore_error}"
            if restore_error
            else f"backup restore 성공={restore_result}"
        )
        raise RepairError("; ".join(details)) from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="G0185 legacy pronunciation parity repair")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("dry-run", "apply"):
        child = subparsers.add_parser(command)
        child.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
        child.add_argument("--work-db", required=True)
        child.add_argument("--seed-db", required=True)
        child.add_argument("--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST))
        child.add_argument("--source-xml", default=str(DEFAULT_SOURCE_XML))
        if command == "apply":
            child.add_argument("--backup-root", required=True)
            child.add_argument("--result-output", required=True)
            child.add_argument(
                "--confirm-g0185-legacy-pronunciation-repair",
                action="store_true",
            )
    return parser


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    args = build_parser().parse_args(argv)
    common = {
        "manifest_path": Path(args.manifest),
        "seed_db": Path(args.seed_db),
        "source_manifest_path": Path(args.source_manifest),
        "source_xml_path": Path(args.source_xml),
        "work_db": Path(args.work_db),
    }
    try:
        if args.command == "dry-run":
            result = run_dry_run(**common)
        else:
            result = run_apply(
                **common,
                backup_root=Path(args.backup_root),
                result_output=Path(args.result_output),
                confirm=args.confirm_g0185_legacy_pronunciation_repair,
            )
    except RepairError as error:
        print(f"G0185 repair 실패: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
