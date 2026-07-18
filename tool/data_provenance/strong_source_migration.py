#!/usr/bin/env python3
"""Phase 50-R Greek auto Strong plan을 검증하고 두 private DB에 원자적으로 적용한다."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import sqlite3
import sys
import unicodedata
from urllib.parse import quote


TOOL_VERSION = "1.0.0"
EXPECTED_GREEK_SOURCE = {
    "repository": "https://github.com/morphgnt/strongs-dictionary-xml",
    "commit": "dd6758b82f46b620804a8ea677d715844679eea1",
    "file_path": "strongsgreek.xml",
    "sha256": "91474213b208a4e487d35f85c10e5c90737acc69082dad15dec5431406003545",
    "license": "CC0 1.0",
    "parser_contract": "greek_headword_v1",
}
DEFAULT_SOURCE_MANIFEST = Path(__file__).with_name("manifests") / "strong_sources.json"
DEFAULT_SOURCE_CACHE = Path(__file__).with_name(".source_cache")
REQUIRED_CURRENT_FIELDS = (
    "spelling",
    "transliteration",
    "pronunciation",
    "pronunciation_notation",
    "pronunciation_notation_name",
)
MUTABLE_FIELDS = (
    "spelling",
    "pronunciation",
    "pronunciation_notation",
    "pronunciation_notation_name",
)
LEGACY_SPELLING_COLUMNS = tuple(f"표기{seq}" for seq in range(1, 7))
LEGACY_PRONUNCIATION_COLUMNS = tuple(f"발음{seq}" for seq in range(1, 7))
LEGACY_MUTABLE_COLUMNS = set(LEGACY_SPELLING_COLUMNS + LEGACY_PRONUNCIATION_COLUMNS)
G0153_STRONG_ID = "G0153"
G0153_WORD_ID = "G0153_0000"
G0153_SEQ = 1
G0153_CANONICAL_PRONUNCIATION = "ahee-skhoo'-nom-ahee"
G0153_LEGACY_BEFORE = " " + G0153_CANONICAL_PRONUNCIATION


class MigrationError(RuntimeError):
    """migration 계약이나 검증이 어긋났을 때 발생한다."""


@dataclass(frozen=True)
class MigrationPlanRow:
    strong_id: str
    word_id: str
    language: str
    seq: int
    is_representative: int
    current_values: dict[str, object]
    expected_values: dict[str, object]

    @property
    def identity(self) -> tuple[str, int]:
        return self.word_id, self.seq


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _json_digest(payload: object) -> str:
    encoded = json.dumps(
        payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _read_json_object(path: Path) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise MigrationError(f"JSON 파일을 읽을 수 없음: {path}: {error}") from error
    if not isinstance(payload, dict):
        raise MigrationError(f"JSON 최상위 값은 object여야 함: {path}")
    return payload


def _read_jsonl(path: Path) -> list[tuple[dict[str, object], bytes]]:
    try:
        raw_lines = path.read_bytes().splitlines(keepends=True)
    except OSError as error:
        raise MigrationError(f"mapping plan을 읽을 수 없음: {path}: {error}") from error
    rows: list[tuple[dict[str, object], bytes]] = []
    for line_number, raw_line in enumerate(raw_lines, start=1):
        if not raw_line.strip():
            continue
        try:
            row = json.loads(raw_line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise MigrationError(
                f"mapping plan {line_number}행이 유효한 UTF-8 JSON이 아님: {error}"
            ) from error
        if not isinstance(row, dict):
            raise MigrationError(f"mapping plan {line_number}행은 object여야 함")
        rows.append((row, raw_line))
    if not rows:
        raise MigrationError("mapping plan이 비어 있음")
    return rows


def prepare_greek_auto_plan(source_plan: Path, output_plan: Path) -> dict[str, object]:
    """전체 결정적 plan에서 Greek auto 행만 raw-byte 보존 방식으로 추출한다."""
    selected_lines: list[bytes] = []
    selected_words: set[str] = set()
    disposition_counts: Counter[str] = Counter()
    language_counts: Counter[str] = Counter()
    for row, raw_line in _read_jsonl(source_plan):
        disposition = str(row.get("primary_disposition"))
        strong_id = str(row.get("strong_id"))
        disposition_counts[disposition] += 1
        language_counts[strong_id[:1]] += 1
        if disposition == "auto" and strong_id.startswith("G"):
            selected_lines.append(raw_line if raw_line.endswith(b"\n") else raw_line + b"\n")
            selected_words.add(strong_id)
    if not selected_lines:
        raise MigrationError("Greek auto migration 입력이 0행임")
    output_plan.parent.mkdir(parents=True, exist_ok=True)
    output_plan.write_bytes(b"".join(selected_lines))
    load_migration_plan(output_plan)
    return {
        "source_plan_sha256": sha256_file(source_plan),
        "migration_plan_sha256": sha256_file(output_plan),
        "greek_auto_word_count": len(selected_words),
        "greek_auto_expression_count": len(selected_lines),
        "source_disposition_expression_counts": dict(sorted(disposition_counts.items())),
        "source_language_expression_counts": dict(sorted(language_counts.items())),
    }


def _require_values(
    row: dict[str, object], field_name: str, line_number: int
) -> dict[str, object]:
    values = row.get(field_name)
    if not isinstance(values, dict):
        raise MigrationError(f"plan {line_number}행 {field_name}는 object여야 함")
    missing = [field for field in REQUIRED_CURRENT_FIELDS if field not in values]
    if missing:
        raise MigrationError(
            f"plan {line_number}행 {field_name} 필수 필드 누락: {', '.join(missing)}"
        )
    if not isinstance(values["spelling"], str) or not values["spelling"]:
        raise MigrationError(f"plan {line_number}행 spelling은 비어 있지 않은 문자열이어야 함")
    return values


def load_migration_plan(path: Path) -> list[MigrationPlanRow]:
    """apply 입력이 Greek auto-only이며 허용 필드 계약을 지키는지 검증한다."""
    result: list[MigrationPlanRow] = []
    identities: set[tuple[str, int]] = set()
    for line_number, (raw, _) in enumerate(_read_jsonl(path), start=1):
        strong_id = raw.get("strong_id")
        word_id = raw.get("word_id")
        language = raw.get("language")
        seq = raw.get("db_seq")
        representative = raw.get("is_representative")
        disposition = raw.get("primary_disposition")
        if disposition != "auto":
            raise MigrationError(
                f"plan {line_number}행에 auto 외 disposition 포함: {disposition!r}"
            )
        if not isinstance(strong_id, str) or not re.fullmatch(r"G\d{4}", strong_id):
            raise MigrationError(f"plan {line_number}행에 Greek 외 Strong ID 포함: {strong_id!r}")
        if language != "헬라어":
            raise MigrationError(f"plan {line_number}행 language가 헬라어가 아님: {language!r}")
        if not isinstance(word_id, str) or not word_id:
            raise MigrationError(f"plan {line_number}행 word_id가 올바르지 않음")
        if not isinstance(seq, int) or isinstance(seq, bool) or not 1 <= seq <= 6:
            raise MigrationError(f"plan {line_number}행 seq가 legacy 1~6 범위 밖임: {seq!r}")
        if representative not in (0, 1):
            raise MigrationError(f"plan {line_number}행 is_representative가 0/1이 아님")
        current = _require_values(raw, "current_values", line_number)
        expected = _require_values(raw, "expected_values", line_number)
        if current["transliteration"] != expected["transliteration"]:
            raise MigrationError(f"plan {line_number}행이 transliteration 변경을 요구함")
        if expected["pronunciation"] is None:
            raise MigrationError(f"plan {line_number}행 source pronunciation이 없음")
        if expected["pronunciation_notation"] != "strong_dictionary":
            raise MigrationError(f"plan {line_number}행 expected notation이 strong_dictionary가 아님")
        if expected["pronunciation_notation_name"] is not None:
            raise MigrationError(f"plan {line_number}행 expected notation_name이 NULL이 아님")
        declared_changes = raw.get("expected_field_changes")
        if not isinstance(declared_changes, list) or any(
            field not in MUTABLE_FIELDS for field in declared_changes
        ):
            raise MigrationError(f"plan {line_number}행에 허용되지 않은 field change가 있음")
        identity = (word_id, seq)
        if identity in identities:
            raise MigrationError(f"plan identity 중복: word_id={word_id}, seq={seq}")
        identities.add(identity)
        result.append(
            MigrationPlanRow(
                strong_id=strong_id,
                word_id=word_id,
                language=language,
                seq=seq,
                is_representative=int(representative),
                current_values={field: current[field] for field in REQUIRED_CURRENT_FIELDS},
                expected_values={field: expected[field] for field in REQUIRED_CURRENT_FIELDS},
            )
        )
    return result


def verify_source_provenance(manifest_path: Path, cache_dir: Path) -> dict[str, object]:
    manifest = _read_json_object(manifest_path)
    sources = manifest.get("sources")
    if manifest.get("schema_version") != 1 or not isinstance(sources, list):
        raise MigrationError("source manifest schema 계약이 올바르지 않음")
    greek = next(
        (source for source in sources if isinstance(source, dict) and source.get("language") == "G"),
        None,
    )
    if greek is None:
        raise MigrationError("source manifest에 Greek source가 없음")
    mismatches = {
        key: (greek.get(key), expected)
        for key, expected in EXPECTED_GREEK_SOURCE.items()
        if greek.get(key) != expected
    }
    if mismatches:
        raise MigrationError(f"고정 Greek source 계약 불일치: {mismatches}")
    source_path = cache_dir / EXPECTED_GREEK_SOURCE["file_path"]
    if not source_path.is_file():
        raise MigrationError(f"Greek source cache가 없음: {source_path}")
    actual_hash = sha256_file(source_path)
    if actual_hash != EXPECTED_GREEK_SOURCE["sha256"]:
        raise MigrationError(
            f"Greek source SHA-256 불일치: expected={EXPECTED_GREEK_SOURCE['sha256']}, "
            f"actual={actual_hash}"
        )
    return {
        "source_manifest_sha256": sha256_file(manifest_path),
        "greek_xml_sha256": actual_hash,
        "repository": greek["repository"],
        "commit": greek["commit"],
        "license": greek["license"],
        "parser_contract": greek["parser_contract"],
    }


def _connect(path: Path, *, read_only: bool) -> sqlite3.Connection:
    path = path.resolve()
    if not path.is_file():
        raise MigrationError(f"DB 파일을 찾을 수 없음: {path}")
    mode = "ro" if read_only else "rw"
    uri = f"file:{quote(path.as_posix(), safe='/:')}?mode={mode}"
    connection = sqlite3.connect(uri, uri=True, isolation_level=None, timeout=1.0)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    if read_only:
        connection.execute("PRAGMA query_only = ON")
    return connection


def _table_columns(connection: sqlite3.Connection, table: str) -> list[str]:
    return [str(row["name"]) for row in connection.execute(f'PRAGMA table_info("{table}")')]


def verify_database_health(connection: sqlite3.Connection) -> dict[str, object]:
    integrity_rows = connection.execute("PRAGMA integrity_check").fetchall()
    integrity = [str(row[0]) for row in integrity_rows]
    if integrity != ["ok"]:
        raise MigrationError(f"PRAGMA integrity_check 실패: {integrity[:10]}")
    foreign_key_rows = connection.execute("PRAGMA foreign_key_check").fetchall()
    if foreign_key_rows:
        raise MigrationError(f"PRAGMA foreign_key_check 위반: {len(foreign_key_rows)}건")
    required_tables = {"WORD_TABLE", "word_expression_set", "CHANGE_HISTORY"}
    actual_tables = {
        str(row[0])
        for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }
    missing_tables = sorted(required_tables - actual_tables)
    if missing_tables:
        raise MigrationError(f"필수 table 누락: {missing_tables}")
    expression_columns = set(_table_columns(connection, "word_expression_set"))
    required_expression_columns = {
        "word_id",
        "seq",
        "is_representative",
        *REQUIRED_CURRENT_FIELDS,
    }
    missing_expression = sorted(required_expression_columns - expression_columns)
    if missing_expression:
        raise MigrationError(f"word_expression_set 필수 열 누락: {missing_expression}")
    word_columns = set(_table_columns(connection, "WORD_TABLE"))
    required_word_columns = {
        "id",
        "언어",
        "스트롱넘버",
        *LEGACY_SPELLING_COLUMNS,
        *LEGACY_PRONUNCIATION_COLUMNS,
    }
    missing_word = sorted(required_word_columns - word_columns)
    if missing_word:
        raise MigrationError(f"WORD_TABLE 필수 열 누락: {missing_word}")
    return {
        "integrity_check": "ok",
        "foreign_key_violation_count": 0,
        "required_schema_present": True,
    }


def _rows_as_lists(connection: sqlite3.Connection, sql: str) -> list[list[object]]:
    return [list(row) for row in connection.execute(sql).fetchall()]


def _projection(connection: sqlite3.Connection) -> list[list[object]]:
    return _rows_as_lists(
        connection,
        '''
        SELECT
          w.id, w."스트롱넘버", w."언어", e.seq, e.is_representative,
          e.spelling, e.transliteration, e.pronunciation,
          e.pronunciation_notation, e.pronunciation_notation_name
        FROM WORD_TABLE AS w
        JOIN word_expression_set AS e ON e.word_id = w.id
        WHERE w."스트롱넘버" IS NOT NULL AND TRIM(w."스트롱넘버") <> ''
        ORDER BY w.id, e.seq
        ''',
    )


def compare_database_projection(left_path: Path, right_path: Path) -> dict[str, object]:
    left = _connect(left_path, read_only=True)
    right = _connect(right_path, read_only=True)
    try:
        verify_database_health(left)
        verify_database_health(right)
        left_projection = _projection(left)
        right_projection = _projection(right)
    finally:
        right.close()
        left.close()
    return {
        "semantic_projection_equal": left_projection == right_projection,
        "left_projection_count": len(left_projection),
        "right_projection_count": len(right_projection),
        "left_projection_sha256": _json_digest(left_projection),
        "right_projection_sha256": _json_digest(right_projection),
    }


def _quote_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def _capture_protection_snapshot(
    connection: sqlite3.Connection, target_identities: set[tuple[str, int]]
) -> dict[str, object]:
    word_columns = _table_columns(connection, "WORD_TABLE")
    immutable_word_columns = [
        column for column in word_columns if column not in LEGACY_MUTABLE_COLUMNS
    ]
    immutable_word_sql = ", ".join(_quote_identifier(column) for column in immutable_word_columns)
    immutable_word_rows = _rows_as_lists(
        connection,
        f"SELECT {immutable_word_sql} FROM WORD_TABLE ORDER BY id",
    )
    immutable_expression_rows = _rows_as_lists(
        connection,
        '''
        SELECT id, word_id, seq, is_representative, transliteration
        FROM word_expression_set
        ORDER BY id
        ''',
    )
    mutable_rows = connection.execute(
        '''
        SELECT word_id, seq, spelling, pronunciation,
               pronunciation_notation, pronunciation_notation_name
        FROM word_expression_set
        ORDER BY word_id, seq
        '''
    ).fetchall()
    non_target_mutable = [
        list(row)
        for row in mutable_rows
        if (str(row["word_id"]), int(row["seq"])) not in target_identities
    ]
    legacy_columns = [*LEGACY_SPELLING_COLUMNS, *LEGACY_PRONUNCIATION_COLUMNS]
    legacy_sql = ", ".join(_quote_identifier(column) for column in legacy_columns)
    legacy_rows = connection.execute(
        f'SELECT id, {legacy_sql} FROM WORD_TABLE ORDER BY id'
    ).fetchall()
    masked_legacy: list[list[object]] = []
    for row in legacy_rows:
        word_id = str(row["id"])
        values: list[object] = [word_id]
        for column in legacy_columns:
            seq = int(re.search(r"\d+$", column).group())
            if (word_id, seq) in target_identities:
                values.append("<phase50r-target>")
            else:
                values.append(row[column])
        masked_legacy.append(values)
    history_rows = _rows_as_lists(connection, "SELECT * FROM CHANGE_HISTORY ORDER BY rowid")
    schema_rows = _rows_as_lists(
        connection,
        '''
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        ''',
    )
    return {
        "word_count": int(connection.execute("SELECT COUNT(*) FROM WORD_TABLE").fetchone()[0]),
        "expression_count": int(
            connection.execute("SELECT COUNT(*) FROM word_expression_set").fetchone()[0]
        ),
        "word_immutable_sha256": _json_digest(immutable_word_rows),
        "expression_immutable_sha256": _json_digest(immutable_expression_rows),
        "non_target_expression_sha256": _json_digest(non_target_mutable),
        "non_target_legacy_sha256": _json_digest(masked_legacy),
        "change_history_row_count": len(history_rows),
        "change_history_sha256": _json_digest(history_rows),
        "schema_sha256": _json_digest(schema_rows),
    }


def _normalized_values(row: sqlite3.Row) -> dict[str, object]:
    return {field: row[field] for field in REQUIRED_CURRENT_FIELDS}


def _select_normalized(
    connection: sqlite3.Connection, plan_row: MigrationPlanRow
) -> sqlite3.Row:
    rows = connection.execute(
        '''
        SELECT spelling, transliteration, pronunciation,
               pronunciation_notation, pronunciation_notation_name,
               is_representative
        FROM word_expression_set
        WHERE word_id = ? AND seq = ?
        ''',
        (plan_row.word_id, plan_row.seq),
    ).fetchall()
    if len(rows) != 1:
        raise MigrationError(
            f"normalized row count 불일치: word_id={plan_row.word_id}, "
            f"seq={plan_row.seq}, count={len(rows)}"
        )
    return rows[0]


def _select_legacy(
    connection: sqlite3.Connection, plan_row: MigrationPlanRow
) -> sqlite3.Row:
    spelling_column = _quote_identifier(f"표기{plan_row.seq}")
    pronunciation_column = _quote_identifier(f"발음{plan_row.seq}")
    rows = connection.execute(
        f'''
        SELECT {spelling_column} AS spelling, {pronunciation_column} AS pronunciation
        FROM WORD_TABLE
        WHERE id = ?
        ''',
        (plan_row.word_id,),
    ).fetchall()
    if len(rows) != 1:
        raise MigrationError(
            f"legacy row count 불일치: word_id={plan_row.word_id}, count={len(rows)}"
        )
    return rows[0]


def _normalize_greek_strong(value: object) -> str | None:
    compact = re.sub(r"\s+", "", str(value or "")).upper()
    matched = re.fullmatch(r"G?0*(\d+)", compact)
    if matched is None:
        return None
    return f"G{int(matched.group(1)):04d}"


def _verify_word_identity(
    connection: sqlite3.Connection, plan_row: MigrationPlanRow
) -> None:
    rows = connection.execute(
        '''
        SELECT "스트롱넘버" AS strong_number, "언어" AS language
        FROM WORD_TABLE
        WHERE id = ?
        ''',
        (plan_row.word_id,),
    ).fetchall()
    if len(rows) != 1:
        raise MigrationError(
            f"WORD_TABLE identity row count 불일치: word_id={plan_row.word_id}, count={len(rows)}"
        )
    actual_strong = _normalize_greek_strong(rows[0]["strong_number"])
    if actual_strong != plan_row.strong_id:
        raise MigrationError(
            f"Strong ID precondition 실패: word_id={plan_row.word_id}, "
            f"plan={plan_row.strong_id}, db={rows[0]['strong_number']!r}"
        )
    if rows[0]["language"] != plan_row.language:
        raise MigrationError(
            f"language precondition 실패: word_id={plan_row.word_id}, "
            f"plan={plan_row.language!r}, db={rows[0]['language']!r}"
        )


def preflight_database_plan(
    db_path: Path, plan: list[MigrationPlanRow]
) -> dict[str, object]:
    """backup과 write 전에 모든 target current/expected 및 legacy parity를 읽기 전용 검증한다."""
    connection = _connect(db_path, read_only=True)
    try:
        health = verify_database_health(connection)
        status_counts: Counter[str] = Counter()
        for plan_row in plan:
            _verify_word_identity(connection, plan_row)
            normalized = _select_normalized(connection, plan_row)
            actual = _normalized_values(normalized)
            if int(normalized["is_representative"]) != plan_row.is_representative:
                raise MigrationError(
                    f"is_representative precondition 실패: {plan_row.word_id}/{plan_row.seq}"
                )
            if actual == plan_row.current_values:
                status_counts["current_count"] += 1
            elif actual == plan_row.expected_values:
                status_counts["already_expected_count"] += 1
            else:
                raise MigrationError(
                    f"current/expected precondition 실패: {plan_row.word_id}/{plan_row.seq}"
                )
            legacy = _select_legacy(connection, plan_row)
            if legacy["spelling"] != actual["spelling"] or legacy["pronunciation"] != actual["pronunciation"]:
                raise MigrationError(
                    f"migration 전 normalized/legacy 불일치: {plan_row.word_id}/{plan_row.seq}"
                )
        return {
            **health,
            "target_expression_count": len(plan),
            "current_count": status_counts["current_count"],
            "already_expected_count": status_counts["already_expected_count"],
            "legacy_parity": True,
            "identity_precondition": True,
        }
    finally:
        connection.close()


def _verify_plan_row_state(
    connection: sqlite3.Connection, plan_row: MigrationPlanRow
) -> None:
    normalized = _select_normalized(connection, plan_row)
    actual = _normalized_values(normalized)
    if actual != plan_row.expected_values:
        raise MigrationError(
            f"expected 값 검증 실패: word_id={plan_row.word_id}, seq={plan_row.seq}"
        )
    if int(normalized["is_representative"]) != plan_row.is_representative:
        raise MigrationError(
            f"is_representative 변경 감지: word_id={plan_row.word_id}, seq={plan_row.seq}"
        )
    legacy = _select_legacy(connection, plan_row)
    if legacy["spelling"] != actual["spelling"] or legacy["pronunciation"] != actual["pronunciation"]:
        raise MigrationError(
            f"normalized/legacy parity 실패: word_id={plan_row.word_id}, seq={plan_row.seq}"
        )


def apply_database(db_path: Path, plan: list[MigrationPlanRow]) -> dict[str, object]:
    input_sha256 = sha256_file(db_path)
    target_identities = {row.identity for row in plan}
    metrics: Counter[str] = Counter()
    changed_words: set[str] = set()
    connection = _connect(db_path, read_only=False)
    try:
        verify_database_health(connection)
        connection.execute("BEGIN IMMEDIATE")
        before = _capture_protection_snapshot(connection, target_identities)
        for plan_row in plan:
            _verify_word_identity(connection, plan_row)
            normalized = _select_normalized(connection, plan_row)
            actual = _normalized_values(normalized)
            if int(normalized["is_representative"]) != plan_row.is_representative:
                raise MigrationError(
                    f"is_representative precondition 실패: {plan_row.word_id}/{plan_row.seq}"
                )
            legacy = _select_legacy(connection, plan_row)
            if legacy["spelling"] != actual["spelling"] or legacy["pronunciation"] != actual["pronunciation"]:
                raise MigrationError(
                    f"migration 전 normalized/legacy 불일치: {plan_row.word_id}/{plan_row.seq}"
                )
            if actual == plan_row.expected_values:
                metrics["already_expected_noop_count"] += 1
                continue
            if actual != plan_row.current_values:
                raise MigrationError(
                    f"current-value precondition 실패: {plan_row.word_id}/{plan_row.seq}"
                )

            spelling_changed = actual["spelling"] != plan_row.expected_values["spelling"]
            pronunciation_changed = (
                actual["pronunciation"] != plan_row.expected_values["pronunciation"]
            )
            notation_changed = (
                actual["pronunciation_notation"]
                != plan_row.expected_values["pronunciation_notation"]
                or actual["pronunciation_notation_name"]
                != plan_row.expected_values["pronunciation_notation_name"]
            )
            cursor = connection.execute(
                '''
                UPDATE word_expression_set
                SET spelling = ?, pronunciation = ?,
                    pronunciation_notation = ?, pronunciation_notation_name = ?
                WHERE word_id = ? AND seq = ?
                ''',
                (
                    plan_row.expected_values["spelling"],
                    plan_row.expected_values["pronunciation"],
                    plan_row.expected_values["pronunciation_notation"],
                    plan_row.expected_values["pronunciation_notation_name"],
                    plan_row.word_id,
                    plan_row.seq,
                ),
            )
            if cursor.rowcount != 1:
                raise MigrationError(
                    f"normalized update row count 불일치: {plan_row.word_id}/{plan_row.seq}"
                )
            if spelling_changed or pronunciation_changed:
                spelling_column = _quote_identifier(f"표기{plan_row.seq}")
                pronunciation_column = _quote_identifier(f"발음{plan_row.seq}")
                legacy_cursor = connection.execute(
                    f'''
                    UPDATE WORD_TABLE
                    SET {spelling_column} = ?, {pronunciation_column} = ?
                    WHERE id = ?
                    ''',
                    (
                        plan_row.expected_values["spelling"],
                        plan_row.expected_values["pronunciation"],
                        plan_row.word_id,
                    ),
                )
                if legacy_cursor.rowcount != 1:
                    raise MigrationError(
                        f"legacy update row count 불일치: {plan_row.word_id}/{plan_row.seq}"
                    )
            metrics["actual_changed_expression_count"] += 1
            changed_words.add(plan_row.word_id)
            if spelling_changed:
                metrics["spelling_change_count"] += 1
                metrics["legacy_spelling_slot_change_count"] += 1
                if unicodedata.normalize("NFC", str(actual["spelling"])) == unicodedata.normalize(
                    "NFC", str(plan_row.expected_values["spelling"])
                ):
                    metrics["nfc_equivalent_spelling_change_count"] += 1
            if pronunciation_changed:
                metrics["pronunciation_change_count"] += 1
                metrics["legacy_pronunciation_slot_change_count"] += 1
            if notation_changed:
                metrics["notation_change_count"] += 1
            if notation_changed and not spelling_changed and not pronunciation_changed:
                metrics["notation_only_change_count"] += 1

        for plan_row in plan:
            _verify_plan_row_state(connection, plan_row)
        after = _capture_protection_snapshot(connection, target_identities)
        if before != after:
            differing = sorted(key for key in before if before[key] != after[key])
            raise MigrationError(f"보호 대상 변경 감지: {differing}")
        transaction_health = verify_database_health(connection)
        connection.execute("COMMIT")
    except Exception:
        if connection.in_transaction:
            connection.execute("ROLLBACK")
        raise
    finally:
        connection.close()

    output_sha256 = sha256_file(db_path)
    result_metrics = {
        "auto_word_count": len({row.word_id for row in plan}),
        "auto_expression_count": len(plan),
        "actual_changed_word_count": len(changed_words),
    }
    for key in (
        "actual_changed_expression_count",
        "spelling_change_count",
        "pronunciation_change_count",
        "notation_change_count",
        "notation_only_change_count",
        "nfc_equivalent_spelling_change_count",
        "legacy_spelling_slot_change_count",
        "legacy_pronunciation_slot_change_count",
        "already_expected_noop_count",
    ):
        result_metrics[key] = metrics[key]
    return {
        "input_sha256": input_sha256,
        "output_sha256": output_sha256,
        "change_counts": result_metrics,
        "protection": after,
        "health": transaction_health,
    }


def create_verified_backup(db_path: Path, backup_dir: Path, label: str) -> dict[str, object]:
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup_path = backup_dir / f"{label}.db"
    if backup_path.exists():
        raise MigrationError(f"backup 대상이 이미 존재함: {backup_path}")
    original_hash = sha256_file(db_path)
    shutil.copyfile(db_path, backup_path)
    backup_hash = sha256_file(backup_path)
    if backup_hash != original_hash:
        raise MigrationError(f"backup byte parity 실패: {db_path} -> {backup_path}")
    connection = _connect(backup_path, read_only=True)
    try:
        health = verify_database_health(connection)
    finally:
        connection.close()
    return {
        "path": str(backup_path.resolve()),
        "original_sha256": original_hash,
        "backup_sha256": backup_hash,
        "byte_identical": True,
        "integrity_check": health["integrity_check"],
    }


def restore_verified_backup(db_path: Path, backup_info: dict[str, object]) -> dict[str, object]:
    backup_path = Path(str(backup_info["path"]))
    expected_hash = str(backup_info["original_sha256"])
    shutil.copyfile(backup_path, db_path)
    restored_hash = sha256_file(db_path)
    if restored_hash != expected_hash:
        raise MigrationError(
            f"restore SHA-256 불일치: expected={expected_hash}, actual={restored_hash}"
        )
    connection = _connect(db_path, read_only=True)
    try:
        health = verify_database_health(connection)
    finally:
        connection.close()
    return {
        "restored_sha256": restored_hash,
        "matches_original": True,
        "integrity_check": health["integrity_check"],
    }


def _portable_backup_info(backup_info: dict[str, object]) -> dict[str, object]:
    """tracked manifest에는 local backup 경로를 제외한 검증 결과만 남긴다."""
    return {
        key: backup_info[key]
        for key in (
            "original_sha256",
            "backup_sha256",
            "byte_identical",
            "integrity_check",
        )
    }


def _portable_backup_record(record: object) -> dict[str, object] | None:
    if not isinstance(record, dict):
        return None
    work = record.get("work")
    seed = record.get("seed")
    if not isinstance(work, dict) or not isinstance(seed, dict):
        raise MigrationError("backup record의 work·seed 검증 결과가 올바르지 않음")
    return {
        "role": record.get("role"),
        "work": _portable_backup_info(work),
        "seed": _portable_backup_info(seed),
    }


def _json_safe(value: object) -> object:
    if isinstance(value, bytes):
        return {"__bytes_hex__": value.hex()}
    return value


def _capture_g0153_repair_protection(
    connection: sqlite3.Connection,
) -> dict[str, object]:
    """G0153 WORD_TABLE.발음1만 mask하고 나머지 전체 logical DB를 고정한다."""
    table_names = [
        str(row[0])
        for row in connection.execute(
            '''
            SELECT name FROM sqlite_master
            WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
            ORDER BY name
            '''
        ).fetchall()
    ]
    table_digests: dict[str, str] = {}
    table_row_counts: dict[str, int] = {}
    for table_name in table_names:
        columns = _table_columns(connection, table_name)
        rows = connection.execute(
            f"SELECT * FROM {_quote_identifier(table_name)}"
        ).fetchall()
        payload_rows: list[list[object]] = []
        for row in rows:
            values: list[object] = []
            for column in columns:
                value = row[column]
                if (
                    table_name == "WORD_TABLE"
                    and row["id"] == G0153_WORD_ID
                    and column == "발음1"
                ):
                    value = "<phase50r-g0153-repair-target>"
                values.append(_json_safe(value))
            payload_rows.append(values)
        table_digests[table_name] = _json_digest(
            {"columns": columns, "rows": payload_rows}
        )
        table_row_counts[table_name] = len(rows)
    schema_rows = _rows_as_lists(
        connection,
        '''
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        ''',
    )
    return {
        "schema_sha256": _json_digest(schema_rows),
        "table_sha256": table_digests,
        "table_row_counts": table_row_counts,
    }


def verify_g0153_exact_precondition(
    connection: sqlite3.Connection, *, repaired: bool
) -> dict[str, object]:
    word_rows = connection.execute(
        '''
        SELECT id, "스트롱넘버" AS strong_number, "언어" AS language,
               "표기1" AS legacy_spelling,
               "음역1" AS legacy_transliteration,
               "발음1" AS legacy_pronunciation
        FROM WORD_TABLE
        WHERE id = ?
        ''',
        (G0153_WORD_ID,),
    ).fetchall()
    expression_rows = connection.execute(
        '''
        SELECT word_id, seq, is_representative, spelling, transliteration,
               pronunciation, pronunciation_notation, pronunciation_notation_name
        FROM word_expression_set
        WHERE word_id = ?
        ORDER BY seq
        ''',
        (G0153_WORD_ID,),
    ).fetchall()
    target_rows = [row for row in expression_rows if int(row["seq"]) == G0153_SEQ]
    if len(word_rows) != 1 or len(target_rows) != 1:
        raise MigrationError(
            "G0153 exact row count 불일치: "
            f"word={len(word_rows)}, target_expression={len(target_rows)}"
        )
    word = word_rows[0]
    target = target_rows[0]
    if _normalize_greek_strong(word["strong_number"]) != G0153_STRONG_ID:
        raise MigrationError(f"G0153 Strong precondition 불일치: {word['strong_number']!r}")
    if word["language"] != "헬라어":
        raise MigrationError(f"G0153 language precondition 불일치: {word['language']!r}")
    if target["pronunciation"] != G0153_CANONICAL_PRONUNCIATION:
        raise MigrationError(
            f"G0153 normalized pronunciation 불일치: {target['pronunciation']!r}"
        )
    expected_legacy = (
        G0153_CANONICAL_PRONUNCIATION if repaired else G0153_LEGACY_BEFORE
    )
    if word["legacy_pronunciation"] != expected_legacy:
        raise MigrationError(
            f"G0153 legacy 발음1 exact precondition 불일치: "
            f"expected={expected_legacy!r}, actual={word['legacy_pronunciation']!r}"
        )
    mismatches: list[dict[str, object]] = []
    for expression in expression_rows:
        seq = int(expression["seq"])
        if not 1 <= seq <= 6:
            raise MigrationError(f"G0153 expression seq가 legacy 범위 밖임: {seq}")
        legacy = connection.execute(
            f'''
            SELECT {_quote_identifier(f"표기{seq}")} AS spelling,
                   {_quote_identifier(f"음역{seq}")} AS transliteration,
                   {_quote_identifier(f"발음{seq}")} AS pronunciation
            FROM WORD_TABLE WHERE id = ?
            ''',
            (G0153_WORD_ID,),
        ).fetchone()
        for field_name in ("spelling", "transliteration", "pronunciation"):
            if expression[field_name] != legacy[field_name]:
                mismatches.append({"seq": seq, "field": field_name})
    expected_mismatches = [] if repaired else [{"seq": 1, "field": "pronunciation"}]
    if mismatches != expected_mismatches:
        raise MigrationError(
            f"G0153 승인 대상 외 legacy 불일치 감지: {mismatches}"
        )
    return {
        "word_row_count": 1,
        "target_expression_row_count": 1,
        "total_expression_count": len(expression_rows),
        "normalized_pronunciation": target["pronunciation"],
        "legacy_pronunciation": word["legacy_pronunciation"],
        "normalized_length": len(str(target["pronunciation"])),
        "legacy_length": len(str(word["legacy_pronunciation"])),
        "normalized_spelling": target["spelling"],
        "legacy_spelling": word["legacy_spelling"],
        "normalized_transliteration": target["transliteration"],
        "legacy_transliteration": word["legacy_transliteration"],
        "is_representative": int(target["is_representative"]),
        "legacy_mismatches": mismatches,
    }


def compare_legacy_projection(left_path: Path, right_path: Path) -> dict[str, object]:
    columns = [
        "id",
        *LEGACY_SPELLING_COLUMNS,
        *(f"음역{seq}" for seq in range(1, 7)),
        *LEGACY_PRONUNCIATION_COLUMNS,
    ]
    select_columns = ", ".join(_quote_identifier(column) for column in columns)
    left = _connect(left_path, read_only=True)
    right = _connect(right_path, read_only=True)
    try:
        left_rows = _rows_as_lists(
            left, f"SELECT {select_columns} FROM WORD_TABLE ORDER BY id"
        )
        right_rows = _rows_as_lists(
            right, f"SELECT {select_columns} FROM WORD_TABLE ORDER BY id"
        )
    finally:
        right.close()
        left.close()
    return {
        "legacy_projection_equal": left_rows == right_rows,
        "left_row_count": len(left_rows),
        "right_row_count": len(right_rows),
        "left_sha256": _json_digest(left_rows),
        "right_sha256": _json_digest(right_rows),
    }


def repair_g0153_database(db_path: Path) -> dict[str, object]:
    input_sha256 = sha256_file(db_path)
    connection = _connect(db_path, read_only=False)
    try:
        verify_database_health(connection)
        connection.execute("BEGIN IMMEDIATE")
        precondition = verify_g0153_exact_precondition(connection, repaired=False)
        before = _capture_g0153_repair_protection(connection)
        cursor = connection.execute(
            '''
            UPDATE WORD_TABLE
            SET "발음1" = ?
            WHERE id = ? AND "발음1" = ?
            ''',
            (
                G0153_CANONICAL_PRONUNCIATION,
                G0153_WORD_ID,
                G0153_LEGACY_BEFORE,
            ),
        )
        if cursor.rowcount != 1:
            raise MigrationError(f"G0153 repair update row count 불일치: {cursor.rowcount}")
        postcondition = verify_g0153_exact_precondition(connection, repaired=True)
        after = _capture_g0153_repair_protection(connection)
        if before != after:
            differing = sorted(key for key in before if before[key] != after[key])
            raise MigrationError(f"G0153 승인 필드 외 변경 감지: {differing}")
        health = verify_database_health(connection)
        connection.execute("COMMIT")
    except Exception:
        if connection.in_transaction:
            connection.execute("ROLLBACK")
        raise
    finally:
        connection.close()
    return {
        "input_sha256": input_sha256,
        "output_sha256": sha256_file(db_path),
        "precondition": precondition,
        "postcondition": postcondition,
        "protection": after,
        "health": health,
    }


def run_g0153_repair(
    *,
    work_db: Path,
    seed_db: Path,
    backup_root: Path,
    report_output: Path,
    apply: bool,
) -> dict[str, object]:
    _assert_no_active_journal((work_db, seed_db))
    preconditions: dict[str, object] = {}
    for label, path in (("work", work_db), ("seed", seed_db)):
        connection = _connect(path, read_only=True)
        try:
            verify_database_health(connection)
            preconditions[label] = verify_g0153_exact_precondition(
                connection, repaired=False
            )
        finally:
            connection.close()
    if preconditions["work"] != preconditions["seed"]:
        raise MigrationError("G0153 work/seed exact precondition이 다름")
    semantic_before = compare_database_projection(work_db, seed_db)
    legacy_before = compare_legacy_projection(work_db, seed_db)
    if not semantic_before["semantic_projection_equal"]:
        raise MigrationError("G0153 repair 전 work/seed semantic projection 불일치")
    if not legacy_before["legacy_projection_equal"]:
        raise MigrationError("G0153 repair 전 work/seed legacy projection 불일치")
    phase_start = {
        "work_sha256": sha256_file(work_db),
        "seed_sha256": sha256_file(seed_db),
    }
    preview = {
        "tool_version": TOOL_VERSION,
        "mode": "apply" if apply else "preview",
        "preflight_repair": {
            "strong_id": G0153_STRONG_ID,
            "word_id": G0153_WORD_ID,
            "seq": G0153_SEQ,
            "field": "WORD_TABLE.발음1",
            "reason": "normalized·legacy compatibility projection mismatch",
            "before_length": len(G0153_LEGACY_BEFORE),
            "after_length": len(G0153_CANONICAL_PRONUNCIATION),
            "normalized_changed": False,
            "applied_to": ["work", "seed"] if apply else [],
        },
        "exact_precondition": preconditions["work"],
        "hash_boundaries": {"phase_start": phase_start},
        "semantic_parity_before": semantic_before,
        "legacy_parity_before": legacy_before,
    }
    if not apply:
        return preview

    _verify_write_lock_available(work_db)
    _verify_write_lock_available(seed_db)
    _assert_no_active_journal((work_db, seed_db))
    executed_at = datetime.now(timezone.utc)
    backup_dir = backup_root / executed_at.strftime(
        "pre_repair_%Y%m%dT%H%M%S_%fZ"
    )
    work_backup = create_verified_backup(
        work_db, backup_dir, "reshet_work_pre_repair"
    )
    seed_backup = create_verified_backup(
        seed_db, backup_dir, "reshet_seed_pre_repair"
    )
    report_temporary = report_output.with_suffix(report_output.suffix + ".tmp")
    try:
        work_result = repair_g0153_database(work_db)
        seed_result = repair_g0153_database(seed_db)
        semantic_after = compare_database_projection(work_db, seed_db)
        legacy_after = compare_legacy_projection(work_db, seed_db)
        if not semantic_after["semantic_projection_equal"]:
            raise MigrationError("G0153 repair 후 work/seed semantic projection 불일치")
        if not legacy_after["legacy_projection_equal"]:
            raise MigrationError("G0153 repair 후 work/seed legacy projection 불일치")
        report = {
            **preview,
            "executed_at_utc": executed_at.isoformat(),
            "preflight_repair": {
                **preview["preflight_repair"],
                "applied_to": ["work", "seed"],
            },
            "hash_boundaries": {
                "phase_start": phase_start,
                "post_repair": {
                    "work_sha256": work_result["output_sha256"],
                    "seed_sha256": seed_result["output_sha256"],
                },
            },
            "work": work_result,
            "seed": seed_result,
            "pre_repair_backup": {
                "role": "G0153 repair 실패 복구용",
                "work": work_backup,
                "seed": seed_backup,
            },
            "semantic_parity_after": semantic_after,
            "legacy_parity_after": legacy_after,
        }
        _write_json_atomic(report_output, report)
        return report
    except Exception as error:
        restore_errors: list[str] = []
        restore_results: dict[str, object] = {}
        for label, db_path, backup in (
            ("work", work_db, work_backup),
            ("seed", seed_db, seed_backup),
        ):
            try:
                restore_results[label] = restore_verified_backup(db_path, backup)
            except Exception as restore_error:
                restore_errors.append(f"{label}: {restore_error}")
        try:
            restore_results["semantic_parity"] = compare_database_projection(
                work_db, seed_db
            )
            restore_results["legacy_parity"] = compare_legacy_projection(
                work_db, seed_db
            )
        except Exception as parity_error:
            restore_errors.append(f"parity: {parity_error}")
        if report_temporary.exists():
            report_temporary.unlink()
        if restore_errors:
            raise MigrationError(
                f"G0153 repair 실패 후 복구 검증도 실패함: cause={error}; "
                f"restore_errors={restore_errors}"
            ) from error
        raise MigrationError(
            f"G0153 repair 실패, 두 DB pre-repair 상태 복구 완료: "
            f"cause={error}; restore={restore_results}"
        ) from error


def _assert_no_active_journal(db_paths: tuple[Path, Path]) -> None:
    active = [
        str(Path(str(db_path) + suffix))
        for db_path in db_paths
        for suffix in ("-wal", "-shm", "-journal")
        if Path(str(db_path) + suffix).exists()
    ]
    if active:
        raise MigrationError(f"활성 SQLite sidecar가 있어 중단함: {active}")


def _verify_write_lock_available(db_path: Path) -> None:
    connection = _connect(db_path, read_only=False)
    try:
        connection.execute("BEGIN IMMEDIATE")
        connection.execute("ROLLBACK")
    except sqlite3.Error as error:
        if connection.in_transaction:
            connection.execute("ROLLBACK")
        raise MigrationError(f"DB write lock preflight 실패: {db_path}: {error}") from error
    finally:
        connection.close()


def _validate_mapping_summary(
    summary_path: Path, plan: list[MigrationPlanRow]
) -> dict[str, int]:
    summary = _read_json_object(summary_path)
    by_language = summary.get("disposition_counts_by_language")
    if not isinstance(by_language, dict) or not isinstance(by_language.get("G"), dict):
        raise MigrationError("mapping summary에 Greek disposition 집계가 없음")
    greek = by_language["G"]
    expected_words = len({row.strong_id for row in plan})
    if greek.get("auto") != expected_words:
        raise MigrationError(
            f"Greek auto plan/summary word count 불일치: plan={expected_words}, "
            f"summary={greek.get('auto')}"
        )
    missing_count = summary.get("source_pronunciation_missing_count")
    if missing_count != 0:
        raise MigrationError(f"source pronunciation missing 경계 변화: {missing_count}")
    return {
        "greek_auto_word_count": int(greek["auto"]),
        "greek_exception_word_count": int(greek.get("exception", 0)),
        "greek_source_only_hold_word_count": int(greek.get("hold", 0)),
        "source_pronunciation_missing_count": int(missing_count),
    }


def _write_json_atomic(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def _validate_repair_report(
    report_path: Path | None, work_db: Path, seed_db: Path
) -> dict[str, object] | None:
    if report_path is None:
        return None
    report = _read_json_object(report_path)
    repair = report.get("preflight_repair")
    boundaries = report.get("hash_boundaries")
    if not isinstance(repair, dict) or not isinstance(boundaries, dict):
        raise MigrationError("G0153 repair report 필수 항목 누락")
    required_repair = {
        "strong_id": G0153_STRONG_ID,
        "word_id": G0153_WORD_ID,
        "seq": G0153_SEQ,
        "field": "WORD_TABLE.발음1",
        "before_length": 21,
        "after_length": 20,
        "normalized_changed": False,
        "applied_to": ["work", "seed"],
    }
    mismatches = {
        key: (repair.get(key), expected)
        for key, expected in required_repair.items()
        if repair.get(key) != expected
    }
    if mismatches:
        raise MigrationError(f"G0153 repair report 계약 불일치: {mismatches}")
    post_repair = boundaries.get("post_repair")
    phase_start = boundaries.get("phase_start")
    if not isinstance(post_repair, dict) or not isinstance(phase_start, dict):
        raise MigrationError("G0153 repair hash boundary 누락")
    current_hashes = {
        "work_sha256": sha256_file(work_db),
        "seed_sha256": sha256_file(seed_db),
    }
    if post_repair != current_hashes:
        raise MigrationError(
            f"G0153 post-repair hash와 현재 DB가 다름: "
            f"report={post_repair}, current={current_hashes}"
        )
    return {
        "report_sha256": sha256_file(report_path),
        "preflight_repair": repair,
        "phase_start": phase_start,
        "post_repair": post_repair,
        "pre_repair_backup": report.get("pre_repair_backup"),
    }


def run_migration(
    *,
    plan_path: Path,
    mapping_summary_path: Path,
    work_db: Path,
    seed_db: Path,
    source_manifest: Path,
    source_cache: Path,
    backup_root: Path,
    manifest_output: Path,
    apply: bool,
    repair_report_path: Path | None = None,
) -> dict[str, object]:
    plan = load_migration_plan(plan_path)
    source = verify_source_provenance(source_manifest, source_cache)
    summary_boundary = _validate_mapping_summary(mapping_summary_path, plan)
    repair_record = _validate_repair_report(repair_report_path, work_db, seed_db)
    _assert_no_active_journal((work_db, seed_db))
    work_preflight = preflight_database_plan(work_db, plan)
    seed_preflight = preflight_database_plan(seed_db, plan)
    if work_preflight != seed_preflight:
        raise MigrationError("migration 전 work/seed target preflight 집계가 다름")
    parity_before = compare_database_projection(work_db, seed_db)
    if not parity_before["semantic_projection_equal"]:
        raise MigrationError("migration 전 work/seed 의미 projection이 다름")
    preview = {
        "tool_version": TOOL_VERSION,
        "mode": "apply" if apply else "preview",
        "source": source,
        "mapping_plan_sha256": sha256_file(plan_path),
        "mapping_summary_sha256": sha256_file(mapping_summary_path),
        **summary_boundary,
        "greek_auto_expression_count": len(plan),
        "work_input_sha256": sha256_file(work_db),
        "seed_input_sha256": sha256_file(seed_db),
        "target_preflight": work_preflight,
        "parity_before": parity_before,
        "repair_report_sha256": (
            repair_record["report_sha256"] if repair_record is not None else None
        ),
    }
    if not apply:
        return preview

    _verify_write_lock_available(work_db)
    _verify_write_lock_available(seed_db)
    _assert_no_active_journal((work_db, seed_db))
    executed_at = datetime.now(timezone.utc)
    run_backup_dir = backup_root / executed_at.strftime(
        "post_repair_pre_migration_%Y%m%dT%H%M%S_%fZ"
    )
    work_backup = create_verified_backup(
        work_db, run_backup_dir, "reshet_work_post_repair_pre_migration"
    )
    seed_backup = create_verified_backup(
        seed_db, run_backup_dir, "reshet_seed_post_repair_pre_migration"
    )
    manifest_temporary = manifest_output.with_suffix(manifest_output.suffix + ".tmp")
    try:
        work_result = apply_database(work_db, plan)
        seed_result = apply_database(seed_db, plan)
        parity_after = compare_database_projection(work_db, seed_db)
        if not parity_after["semantic_projection_equal"]:
            raise MigrationError("migration 후 work/seed 의미 projection이 다름")
        if work_result["change_counts"] != seed_result["change_counts"]:
            raise MigrationError("work/seed migration 변경 집계가 다름")
        manifest = {
            "schema_version": 1,
            "phase": "50-R",
            "tool_version": TOOL_VERSION,
            "executed_at_utc": executed_at.isoformat(),
            "source": source,
            "mapping_plan_sha256": preview["mapping_plan_sha256"],
            "mapping_summary_sha256": preview["mapping_summary_sha256"],
            "repair_report_sha256": preview["repair_report_sha256"],
            "preflight_repair": (
                repair_record["preflight_repair"]
                if repair_record is not None
                else None
            ),
            "hash_boundaries": {
                "phase_start": (
                    repair_record["phase_start"]
                    if repair_record is not None
                    else {
                        "work_sha256": work_result["input_sha256"],
                        "seed_sha256": seed_result["input_sha256"],
                    }
                ),
                "post_repair_pre_migration": {
                    "work_sha256": work_result["input_sha256"],
                    "seed_sha256": seed_result["input_sha256"],
                },
                "post_migration": {
                    "work_sha256": work_result["output_sha256"],
                    "seed_sha256": seed_result["output_sha256"],
                },
            },
            "scope": {
                **summary_boundary,
                "greek_auto_expression_count": len(plan),
                "hebrew_expression_change_count": 0,
                "greek_exception_expression_change_count": 0,
                "greek_source_only_created_row_count": 0,
                "change_history_used": False,
            },
            "work": work_result,
            "seed": seed_result,
            "backup": {
                "pre_repair": _portable_backup_record(
                    repair_record["pre_repair_backup"]
                    if repair_record is not None
                    else None
                ),
                "post_repair_pre_migration": _portable_backup_record({
                    "role": "Greek auto migration 실패 복구용",
                    "work": work_backup,
                    "seed": seed_backup,
                }),
            },
            "parity_before": parity_before,
            "parity_after": parity_after,
        }
        _write_json_atomic(manifest_output, manifest)
        return manifest
    except Exception as error:
        restore_errors: list[str] = []
        restore_results: dict[str, object] = {}
        for label, db_path, backup in (
            ("work", work_db, work_backup),
            ("seed", seed_db, seed_backup),
        ):
            try:
                restore_results[label] = restore_verified_backup(db_path, backup)
            except Exception as restore_error:  # 복구 실패를 원래 오류와 함께 보존한다.
                restore_errors.append(f"{label}: {restore_error}")
        try:
            restore_results["parity"] = compare_database_projection(work_db, seed_db)
        except Exception as parity_error:
            restore_errors.append(f"parity: {parity_error}")
        if manifest_temporary.exists():
            manifest_temporary.unlink()
        if restore_errors:
            raise MigrationError(
                f"migration 실패 후 복구 검증도 실패함: cause={error}; "
                f"restore_errors={restore_errors}"
            ) from error
        raise MigrationError(
            f"migration 실패, 두 DB 복구 검증 완료: cause={error}; "
            f"restore={restore_results}"
        ) from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Phase 50-R Greek auto Strong migration 도구"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser(
        "prepare-plan", help="전체 canonical plan에서 Greek auto-only apply plan 생성"
    )
    prepare.add_argument("--source-plan", required=True)
    prepare.add_argument("--output-plan", required=True)

    repair = subparsers.add_parser(
        "repair-g0153",
        help="기본 preview, 명시적 --apply에서만 G0153 legacy 발음1 exact repair",
    )
    repair.add_argument("--work-db", required=True)
    repair.add_argument("--seed-db", required=True)
    repair.add_argument("--backup-root", required=True)
    repair.add_argument("--report-output", required=True)
    repair.add_argument("--apply", action="store_true")

    migrate = subparsers.add_parser(
        "migrate", help="기본 preview, 명시적 --apply에서만 work/seed DB 반영"
    )
    migrate.add_argument("--plan", required=True)
    migrate.add_argument("--mapping-summary", required=True)
    migrate.add_argument("--work-db", required=True)
    migrate.add_argument("--seed-db", required=True)
    migrate.add_argument("--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST))
    migrate.add_argument("--source-cache", default=str(DEFAULT_SOURCE_CACHE))
    migrate.add_argument("--backup-root", required=True)
    migrate.add_argument("--manifest-output", required=True)
    migrate.add_argument("--repair-report")
    migrate.add_argument("--apply", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    args = build_parser().parse_args(argv)
    try:
        if args.command == "prepare-plan":
            result = prepare_greek_auto_plan(Path(args.source_plan), Path(args.output_plan))
        elif args.command == "repair-g0153":
            result = run_g0153_repair(
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                backup_root=Path(args.backup_root),
                report_output=Path(args.report_output),
                apply=bool(args.apply),
            )
        else:
            result = run_migration(
                plan_path=Path(args.plan),
                mapping_summary_path=Path(args.mapping_summary),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                source_manifest=Path(args.source_manifest),
                source_cache=Path(args.source_cache),
                backup_root=Path(args.backup_root),
                manifest_output=Path(args.manifest_output),
                apply=bool(args.apply),
                repair_report_path=(
                    Path(args.repair_report) if args.repair_report else None
                ),
            )
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (MigrationError, OSError, sqlite3.Error, ValueError) as error:
        print(f"오류: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
