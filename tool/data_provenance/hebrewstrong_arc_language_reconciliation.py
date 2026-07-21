#!/usr/bin/env python3
"""HebrewStrong source ``arc`` 518건의 DB 언어 정합화 도구.

tracked manifest가 UPDATE identity의 유일한 authority다. dry-run은 두 DB를
read-only로 검증하고, apply는 work DB에 seed DB를 ATTACH한 단일 transaction에서
``WORD_TABLE.언어``만 ``히브리어``에서 ``아람어``로 변경한다.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
from typing import Iterable, Sequence

import strong_source_diff as source_parser


MIGRATION_ID = "hebrewstrong_arc_language_reconciliation"
SCHEMA_VERSION = 1
TOOL_VERSION = "1.0.0"
TOOL_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = TOOL_DIR.parent.parent
DEFAULT_MANIFEST = TOOL_DIR / "manifests" / f"{MIGRATION_ID}.json"
DEFAULT_RESULT = TOOL_DIR / "migrations" / f"{MIGRATION_ID}_result.json"
DEFAULT_SOURCE_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_SOURCE_XML = TOOL_DIR / ".source_cache" / "HebrewStrong.xml"
DEFAULT_WORK_DB = REPOSITORY_ROOT / "data" / "reshet_work.db"
DEFAULT_SEED_DB = REPOSITORY_ROOT / "data" / "reshet_seed.db"
DEFAULT_BACKUP_ROOT = REPOSITORY_ROOT / "data" / "backups" / MIGRATION_ID

CURRENT_LANGUAGE = "히브리어"
TARGET_LANGUAGE = "아람어"
SOURCE_LANGUAGE_CODE = "arc"
EXPECTED_SOURCE_COUNTS = {"arc": 653, "heb": 5393, "x-pn": 2628}
EXPECTED_TARGET_COUNT = 518
EXPECTED_ALREADY_TARGET_COUNT = 135
EXPECTED_X_PN_MISSING_COUNT = 12
EXPECTED_TARGET_STRONG_SHA256 = (
    "052e64a957ead92cfde964d1ee265c2a2b384866eaf7b76a0e9ff813554710c1"
)
EXPECTED_SOURCE = {
    "repository": "https://github.com/openscriptures/HebrewLexicon",
    "commit": "21c9add13bc727d3a951361778e97e3ff7afd1ce",
    "path": "HebrewStrong.xml",
    "sha256": "a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4",
    "source_manifest_sha256": (
        "29ef7dc4a7281c77c28bdb1fd6337b25d1e363f200e4ff93fe84bee6f8464fc5"
    ),
    "license": "CC BY 4.0",
    "attribution": "Open Scriptures Hebrew Bible Project",
    "parser_contract": "hebrew_forms_v2",
    "source_language_code": SOURCE_LANGUAGE_CODE,
}

TARGET_FIELDS = [
    "strong_number",
    "word_id",
    "expected_db_strong_number",
    "source_language_code",
    "expected_current_language",
    "target_language",
]
TARGET_PROJECTION_CONTRACT = {
    "fields": TARGET_FIELDS,
    "sort": ["strong_number ASC", "word_id ASC"],
    "format": "JSONL ordered arrays",
    "encoding": "UTF-8",
    "bom": False,
    "ensure_ascii": False,
    "separators": [",", ":"],
    "final_lf": True,
}
PROTECTION_KEYS = (
    "target_word_immutable_sha256",
    "non_target_word_sha256",
    "non_target_word_language_sha256",
    "expression_sha256",
    "expression_provenance_sha256",
    "meaning_sha256",
    "relation_sha256",
    "change_history_sha256",
    "schema_sha256",
    "x_pn_missing_count",
    "x_pn_missing_strong_sha256",
    "target_expression_mismatch_count",
)


class MigrationError(RuntimeError):
    """사전 조건 또는 보호 projection이 맞지 않을 때 fail-closed한다."""


@dataclass(frozen=True)
class Target:
    strong_number: str
    word_id: str
    expected_db_strong_number: str
    source_language_code: str = SOURCE_LANGUAGE_CODE
    expected_current_language: str = CURRENT_LANGUAGE
    target_language: str = TARGET_LANGUAGE

    def row(self) -> list[object]:
        return [getattr(self, field) for field in TARGET_FIELDS]


@dataclass(frozen=True)
class LoadedManifest:
    payload: dict[str, object]
    targets: tuple[Target, ...]
    file_sha256: str
    target_projection_sha256: str


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_json_bytes(payload: object) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n"
    ).encode("utf-8")


def jsonl_sha256(rows: Iterable[Sequence[object]]) -> str:
    digest = hashlib.sha256()
    for row in rows:
        digest.update(
            (
                json.dumps(list(row), ensure_ascii=False, separators=(",", ":"))
                + "\n"
            ).encode("utf-8")
        )
    return digest.hexdigest()


def _portable_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(REPOSITORY_ROOT).as_posix()
    except ValueError:
        return str(resolved)


def _quote(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def _table(schema: str, table: str) -> str:
    return f"{_quote(schema)}.{_quote(table)}"


def normalize_strong(value: object) -> str | None:
    return source_parser.normalize_strong_number(value, "H")


def sidecar_paths(path: Path) -> tuple[Path, Path, Path]:
    resolved = path.resolve()
    return tuple(Path(str(resolved) + suffix) for suffix in ("-wal", "-shm", "-journal"))


def assert_no_sidecars(paths: Sequence[Path]) -> None:
    active = [
        str(sidecar)
        for path in paths
        for sidecar in sidecar_paths(path)
        if sidecar.exists()
    ]
    if active:
        raise MigrationError(f"active SQLite sidecar 발견: {active}")


def open_read_only(path: Path) -> sqlite3.Connection:
    if not path.is_file():
        raise MigrationError(f"DB 파일 누락: {path}")
    connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA query_only = ON")
    if int(connection.execute("PRAGMA query_only").fetchone()[0]) != 1:
        connection.close()
        raise MigrationError(f"SQLite query_only 보장 실패: {path}")
    return connection


def _table_columns(
    connection: sqlite3.Connection, schema: str, table: str
) -> list[str]:
    return [
        str(row[1])
        for row in connection.execute(
            f"PRAGMA {_quote(schema)}.table_info({_quote(table)})"
        )
    ]


def verify_database_health(
    connection: sqlite3.Connection, schema: str = "main"
) -> dict[str, object]:
    required = {
        "WORD_TABLE": {"id", "스트롱넘버", "언어"},
        "word_expression_set": {
            "id",
            "word_id",
            "seq",
            "spelling",
            "pronunciation_notation",
            "pronunciation_notation_name",
        },
        "word_meaning_set": {"id", "word_id", "seq", "meaning"},
        "WORD_RELATION": {"id", "word_id_1", "word_id_2"},
        "CHANGE_HISTORY": {"id", "entity_id"},
    }
    missing: dict[str, list[str]] = {}
    for table_name, expected in required.items():
        absent = expected - set(_table_columns(connection, schema, table_name))
        if absent:
            missing[table_name] = sorted(absent)
    if missing:
        raise MigrationError(f"required schema 누락: {schema}: {missing}")
    integrity_rows = [
        str(row[0])
        for row in connection.execute(f"PRAGMA {_quote(schema)}.integrity_check")
    ]
    foreign_keys = connection.execute(
        f"PRAGMA {_quote(schema)}.foreign_key_check"
    ).fetchall()
    journal_mode = str(
        connection.execute(f"PRAGMA {_quote(schema)}.journal_mode").fetchone()[0]
    ).lower()
    if integrity_rows != ["ok"]:
        raise MigrationError(f"integrity_check 실패: {schema}: {integrity_rows}")
    if foreign_keys:
        raise MigrationError(
            f"foreign_key_check 실패: {schema}: {len(foreign_keys)}"
        )
    return {
        "integrity_check": "ok",
        "foreign_key_violation_count": 0,
        "journal_mode": journal_mode,
        "required_schema_present": True,
    }


def load_source_boundary(
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> tuple[dict[str, object], dict[str, source_parser.SourceEntryV2]]:
    manifest_sha = sha256_file(source_manifest_path)
    if manifest_sha != EXPECTED_SOURCE["source_manifest_sha256"]:
        raise MigrationError(f"source manifest SHA 불일치: {manifest_sha}")
    raw_manifest = json.loads(source_manifest_path.read_text(encoding="utf-8"))
    sources = raw_manifest.get("sources")
    if not isinstance(sources, list):
        raise MigrationError("source manifest sources 형식 불일치")
    matches = [source for source in sources if source.get("language") == "H"]
    if len(matches) != 1:
        raise MigrationError("Hebrew source manifest 항목 수 불일치")
    source = matches[0]
    actual = {
        "repository": source.get("repository"),
        "commit": source.get("commit"),
        "path": source.get("file_path"),
        "sha256": source.get("sha256"),
        "source_manifest_sha256": manifest_sha,
        "license": source.get("license"),
        "attribution": source.get("required_attribution"),
        "parser_contract": "hebrew_forms_v2",
        "source_language_code": SOURCE_LANGUAGE_CODE,
    }
    if actual != EXPECTED_SOURCE:
        raise MigrationError(f"Hebrew source boundary 불일치: {actual}")
    xml_sha = sha256_file(source_xml_path)
    if xml_sha != EXPECTED_SOURCE["sha256"]:
        raise MigrationError(f"source XML SHA 불일치: {xml_sha}")
    dataset = source_parser.parse_hebrew_xml_v2(source_xml_path)
    entries = dict(dataset.entries)
    language_counts: dict[str, int] = {}
    for entry in entries.values():
        language_counts[entry.source_language_code] = (
            language_counts.get(entry.source_language_code, 0) + 1
        )
        if (
            len(entry.forms) != 1
            or entry.forms[0].form_role != "primary"
            or entry.forms[0].source_document_order != 1
        ):
            raise MigrationError(f"source primary form 계약 불일치: {entry.source_key}")
    if language_counts != EXPECTED_SOURCE_COUNTS:
        raise MigrationError(f"source language 집계 불일치: {language_counts}")
    return {
        **actual,
        "entry_count": dataset.entry_count,
        "form_count": dataset.form_count,
        "language_counts": language_counts,
    }, entries


def _word_index(
    connection: sqlite3.Connection, schema: str
) -> dict[str, list[dict[str, object]]]:
    rows = connection.execute(
        f'''
        SELECT id, {_quote("스트롱넘버")} AS strong_number,
               {_quote("언어")} AS language
        FROM {_table(schema, "WORD_TABLE")}
        WHERE {_quote("스트롱넘버")} IS NOT NULL
          AND TRIM({_quote("스트롱넘버")}) <> ''
        ORDER BY id
        '''
    ).fetchall()
    result: dict[str, list[dict[str, object]]] = {}
    for row in rows:
        strong = normalize_strong(row["strong_number"])
        if strong is not None:
            result.setdefault(strong, []).append(dict(row))
    return result


def _source_keys(
    entries: dict[str, source_parser.SourceEntryV2], language_code: str
) -> list[str]:
    return sorted(
        key
        for key, entry in entries.items()
        if entry.source_language_code == language_code
    )


def _strong_set_sha(strongs: Sequence[str]) -> str:
    return hashlib.sha256("".join(f"{strong}\n" for strong in strongs).encode()).hexdigest()


def _target_projection_sha(targets: Sequence[Target]) -> str:
    return jsonl_sha256(target.row() for target in targets)


def _discover_targets(
    connection: sqlite3.Connection,
    schema: str,
    entries: dict[str, source_parser.SourceEntryV2],
) -> tuple[list[Target], dict[str, object]]:
    index = _word_index(connection, schema)
    arc_keys = _source_keys(entries, SOURCE_LANGUAGE_CODE)
    missing = [key for key in arc_keys if not index.get(key)]
    duplicates = [key for key in arc_keys if len(index.get(key, [])) > 1]
    if missing or duplicates:
        raise MigrationError(
            f"source arc word identity 불일치: missing={len(missing)}, "
            f"duplicates={len(duplicates)}"
        )
    targets: list[Target] = []
    already_target = 0
    other_languages: list[tuple[str, object]] = []
    for strong in arc_keys:
        row = index[strong][0]
        language = row["language"]
        if language == CURRENT_LANGUAGE:
            targets.append(
                Target(
                    strong_number=strong,
                    word_id=str(row["id"]),
                    expected_db_strong_number=str(row["strong_number"]),
                )
            )
        elif language == TARGET_LANGUAGE:
            already_target += 1
        else:
            other_languages.append((strong, language))
    targets.sort(key=lambda target: (target.strong_number, target.word_id))
    if (
        len(targets) != EXPECTED_TARGET_COUNT
        or already_target != EXPECTED_ALREADY_TARGET_COUNT
        or other_languages
    ):
        raise MigrationError(
            "source arc 언어 cohort 불일치: "
            f"target={len(targets)}, already_target={already_target}, "
            f"other={other_languages[:5]}"
        )
    if _strong_set_sha([target.strong_number for target in targets]) != (
        EXPECTED_TARGET_STRONG_SHA256
    ):
        raise MigrationError("target Strong set SHA 불일치")
    mismatch_count = _target_expression_mismatch_count(
        connection, schema, targets, entries
    )
    if mismatch_count:
        raise MigrationError(f"target expression 추가·누락: {mismatch_count}")
    return targets, {
        "arc_total_count": len(arc_keys),
        "already_target_count": already_target,
        "target_count": len(targets),
        "target_expression_mismatch_count": mismatch_count,
    }


def build_manifest_payload(
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> dict[str, object]:
    assert_no_sidecars((work_db, seed_db))
    source_info, entries = load_source_boundary(source_manifest_path, source_xml_path)
    work_connection = open_read_only(work_db)
    seed_connection = open_read_only(seed_db)
    try:
        verify_database_health(work_connection)
        verify_database_health(seed_connection)
        work_targets, work_counts = _discover_targets(work_connection, "main", entries)
        seed_targets, seed_counts = _discover_targets(seed_connection, "main", entries)
    finally:
        work_connection.close()
        seed_connection.close()
    if work_targets != seed_targets:
        raise MigrationError("manifest 생성 work·seed target identity 불일치")
    if work_counts != seed_counts:
        raise MigrationError("manifest 생성 work·seed target 집계 불일치")
    payload: dict[str, object] = {
        "schema_version": SCHEMA_VERSION,
        "migration_id": MIGRATION_ID,
        "source": source_info,
        "database_contract": {
            "table": "WORD_TABLE",
            "identity_columns": ["id", "스트롱넘버"],
            "changed_column": "언어",
            "expected_current_language": CURRENT_LANGUAGE,
            "target_language": TARGET_LANGUAGE,
            "target_count_per_database": EXPECTED_TARGET_COUNT,
            "source_arc_total_count": EXPECTED_SOURCE_COUNTS["arc"],
            "already_aramaic_count": EXPECTED_ALREADY_TARGET_COUNT,
            "work_seed_same_manifest": True,
        },
        "expected_initial_database_sha256": {
            "work": sha256_file(work_db),
            "seed": sha256_file(seed_db),
        },
        "target_projection_contract": TARGET_PROJECTION_CONTRACT,
        "target_strong_sha256": EXPECTED_TARGET_STRONG_SHA256,
        "target_projection_sha256": _target_projection_sha(work_targets),
        "targets": [
            {field: getattr(target, field) for field in TARGET_FIELDS}
            for target in work_targets
        ],
    }
    return payload


def write_manifest(payload: dict[str, object], output: Path) -> str:
    raw = canonical_json_bytes(payload)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(raw)
    return hashlib.sha256(raw).hexdigest()


def load_manifest(path: Path = DEFAULT_MANIFEST) -> LoadedManifest:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raise MigrationError("manifest BOM 금지")
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"manifest decoding 실패: {error}") from error
    if canonical_json_bytes(payload) != raw:
        raise MigrationError("manifest canonical 직렬화 불일치")
    if (
        not isinstance(payload, dict)
        or payload.get("schema_version") != SCHEMA_VERSION
        or payload.get("migration_id") != MIGRATION_ID
        or payload.get("source") is None
        or payload.get("database_contract")
        != {
            "table": "WORD_TABLE",
            "identity_columns": ["id", "스트롱넘버"],
            "changed_column": "언어",
            "expected_current_language": CURRENT_LANGUAGE,
            "target_language": TARGET_LANGUAGE,
            "target_count_per_database": EXPECTED_TARGET_COUNT,
            "source_arc_total_count": EXPECTED_SOURCE_COUNTS["arc"],
            "already_aramaic_count": EXPECTED_ALREADY_TARGET_COUNT,
            "work_seed_same_manifest": True,
        }
        or payload.get("target_projection_contract") != TARGET_PROJECTION_CONTRACT
        or payload.get("target_strong_sha256") != EXPECTED_TARGET_STRONG_SHA256
    ):
        raise MigrationError("manifest contract 불일치")
    raw_targets = payload.get("targets")
    if not isinstance(raw_targets, list):
        raise MigrationError("manifest targets 형식 불일치")
    targets: list[Target] = []
    for item in raw_targets:
        if not isinstance(item, dict) or list(item) != TARGET_FIELDS:
            raise MigrationError("manifest target field 순서·schema 불일치")
        targets.append(Target(**item))
    if len(targets) != EXPECTED_TARGET_COUNT:
        raise MigrationError(f"manifest target 수 불일치: {len(targets)}")
    if targets != sorted(targets, key=lambda target: (target.strong_number, target.word_id)):
        raise MigrationError("manifest target 정렬 불일치")
    if len({target.strong_number for target in targets}) != len(targets):
        raise MigrationError("manifest Strong identity 중복")
    if len({target.word_id for target in targets}) != len(targets):
        raise MigrationError("manifest word identity 중복")
    for target in targets:
        if (
            normalize_strong(target.strong_number) != target.strong_number
            or normalize_strong(target.expected_db_strong_number) != target.strong_number
            or target.source_language_code != SOURCE_LANGUAGE_CODE
            or target.expected_current_language != CURRENT_LANGUAGE
            or target.target_language != TARGET_LANGUAGE
        ):
            raise MigrationError(f"manifest target 계약 불일치: {target}")
    strong_sha = _strong_set_sha([target.strong_number for target in targets])
    if strong_sha != EXPECTED_TARGET_STRONG_SHA256:
        raise MigrationError(f"manifest target Strong SHA 불일치: {strong_sha}")
    projection_sha = _target_projection_sha(targets)
    if payload.get("target_projection_sha256") != projection_sha:
        raise MigrationError("manifest target projection SHA 불일치")
    initial_hashes = payload.get("expected_initial_database_sha256")
    if (
        not isinstance(initial_hashes, dict)
        or set(initial_hashes) != {"work", "seed"}
        or not all(
            isinstance(value, str) and len(value) == 64
            for value in initial_hashes.values()
        )
    ):
        raise MigrationError("manifest initial DB SHA 형식 불일치")
    return LoadedManifest(
        payload=payload,
        targets=tuple(targets),
        file_sha256=hashlib.sha256(raw).hexdigest(),
        target_projection_sha256=projection_sha,
    )


def _rows_hash(
    connection: sqlite3.Connection,
    sql: str,
    parameters: Sequence[object] = (),
) -> tuple[int, str]:
    rows = [list(row) for row in connection.execute(sql, parameters).fetchall()]
    return len(rows), jsonl_sha256(rows)


def _table_projection(
    connection: sqlite3.Connection,
    schema: str,
    table: str,
    *,
    excluded_columns: set[str] | None = None,
    where: str | None = None,
    parameters: Sequence[object] = (),
    order_by: str = "rowid",
) -> tuple[int, str]:
    excluded_columns = excluded_columns or set()
    columns = [
        column
        for column in _table_columns(connection, schema, table)
        if column not in excluded_columns
    ]
    if not columns:
        raise MigrationError(f"projection column 없음: {schema}.{table}")
    sql = (
        f"SELECT {', '.join(_quote(column) for column in columns)} "
        f"FROM {_table(schema, table)}"
    )
    if where:
        sql += f" WHERE {where}"
    sql += f" ORDER BY {order_by}"
    return _rows_hash(connection, sql, parameters)


def _schema_sha(connection: sqlite3.Connection, schema: str) -> str:
    _, digest = _rows_hash(
        connection,
        f'''
        SELECT type, name, tbl_name, sql
        FROM {_quote(schema)}.sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        ''',
    )
    return digest


def _target_expression_mismatch_count(
    connection: sqlite3.Connection,
    schema: str,
    targets: Sequence[Target],
    entries: dict[str, source_parser.SourceEntryV2],
) -> int:
    expression_table = _table(schema, "word_expression_set")
    mismatch = 0
    for target in targets:
        actual = [
            int(row[0])
            for row in connection.execute(
                f"SELECT seq FROM {expression_table} WHERE word_id=? ORDER BY seq, id",
                (target.word_id,),
            )
        ]
        expected = [
            form.source_document_order for form in entries[target.strong_number].forms
        ]
        if actual != expected:
            mismatch += 1
    return mismatch


def capture_snapshot(
    connection: sqlite3.Connection,
    schema: str,
    manifest: LoadedManifest,
    entries: dict[str, source_parser.SourceEntryV2],
    *,
    expected_state: str | None = None,
) -> tuple[str, dict[str, object], dict[str, object]]:
    health = verify_database_health(connection, schema)
    index = _word_index(connection, schema)
    arc_keys = _source_keys(entries, SOURCE_LANGUAGE_CODE)
    missing_arc = [key for key in arc_keys if not index.get(key)]
    duplicate_arc = [key for key in arc_keys if len(index.get(key, [])) > 1]
    if missing_arc or duplicate_arc:
        raise MigrationError(
            f"{schema} source arc identity 불일치: missing={len(missing_arc)}, "
            f"duplicates={len(duplicate_arc)}"
        )
    target_rows: list[dict[str, object]] = []
    for target in manifest.targets:
        rows = index.get(target.strong_number, [])
        if len(rows) != 1:
            raise MigrationError(f"{schema} target Strong identity 불일치: {target}")
        row = rows[0]
        if (
            row["id"] != target.word_id
            or row["strong_number"] != target.expected_db_strong_number
        ):
            raise MigrationError(f"{schema} target DB identity 불일치: {target}")
        target_rows.append(row)
    target_languages = {str(row["language"]) for row in target_rows}
    if target_languages == {CURRENT_LANGUAGE}:
        state = "pre_apply"
    elif target_languages == {TARGET_LANGUAGE}:
        state = "post_apply"
    else:
        raise MigrationError(f"{schema} target language 부분 상태: {target_languages}")
    if expected_state is not None and state != expected_state:
        raise MigrationError(f"{schema} state 불일치: {state} != {expected_state}")

    arc_language_counts: dict[str, int] = {}
    for key in arc_keys:
        language = str(index[key][0]["language"])
        arc_language_counts[language] = arc_language_counts.get(language, 0) + 1
    expected_arc_counts = (
        {CURRENT_LANGUAGE: EXPECTED_TARGET_COUNT, TARGET_LANGUAGE: EXPECTED_ALREADY_TARGET_COUNT}
        if state == "pre_apply"
        else {TARGET_LANGUAGE: EXPECTED_SOURCE_COUNTS["arc"]}
    )
    if arc_language_counts != expected_arc_counts:
        raise MigrationError(
            f"{schema} source arc DB 언어 집계 불일치: {arc_language_counts}"
        )

    mismatch_count = _target_expression_mismatch_count(
        connection, schema, manifest.targets, entries
    )
    if mismatch_count:
        raise MigrationError(f"{schema} target expression 추가·누락: {mismatch_count}")
    x_pn_keys = _source_keys(entries, "x-pn")
    x_pn_missing = sorted(key for key in x_pn_keys if not index.get(key))
    if len(x_pn_missing) != EXPECTED_X_PN_MISSING_COUNT:
        raise MigrationError(
            f"{schema} x-pn missing 수 불일치: {len(x_pn_missing)}"
        )

    target_ids = [target.word_id for target in manifest.targets]
    placeholders = ",".join("?" for _ in target_ids)
    word_columns = _table_columns(connection, schema, "WORD_TABLE")
    immutable_columns = [column for column in word_columns if column != "언어"]
    word_table = _table(schema, "WORD_TABLE")
    _, target_immutable_sha = _rows_hash(
        connection,
        f"SELECT {', '.join(_quote(column) for column in immutable_columns)} "
        f"FROM {word_table} WHERE id IN ({placeholders}) ORDER BY id",
        target_ids,
    )
    non_target_count, non_target_sha = _rows_hash(
        connection,
        f"SELECT {', '.join(_quote(column) for column in word_columns)} "
        f"FROM {word_table} WHERE id NOT IN ({placeholders}) ORDER BY id",
        target_ids,
    )
    _, non_target_language_sha = _rows_hash(
        connection,
        f"SELECT id, {_quote('스트롱넘버')}, {_quote('언어')} "
        f"FROM {word_table} WHERE id NOT IN ({placeholders}) ORDER BY id",
        target_ids,
    )
    expression_count, expression_sha = _table_projection(
        connection, schema, "word_expression_set", order_by="word_id, seq, id"
    )
    _, expression_provenance_sha = _rows_hash(
        connection,
        f'''
        SELECT word_id, seq, pronunciation_notation, pronunciation_notation_name
        FROM {_table(schema, "word_expression_set")}
        ORDER BY word_id, seq, id
        ''',
    )
    meaning_count, meaning_sha = _table_projection(
        connection, schema, "word_meaning_set", order_by="word_id, seq, id"
    )
    relation_count, relation_sha = _table_projection(
        connection, schema, "WORD_RELATION", order_by="id"
    )
    history_count, history_sha = _table_projection(
        connection, schema, "CHANGE_HISTORY", order_by="id"
    )
    snapshot = {
        "state": state,
        "source_arc_total_count": len(arc_keys),
        "source_arc_db_language_counts": arc_language_counts,
        "target_count": len(target_rows),
        "target_strong_sha256": _strong_set_sha(
            [target.strong_number for target in manifest.targets]
        ),
        "target_projection_sha256": manifest.target_projection_sha256,
        "target_identity_projection": [target.row() for target in manifest.targets],
        "target_expression_mismatch_count": mismatch_count,
        "x_pn_missing_count": len(x_pn_missing),
        "x_pn_missing_strong_sha256": _strong_set_sha(x_pn_missing),
        "target_word_immutable_sha256": target_immutable_sha,
        "non_target_word_count": non_target_count,
        "non_target_word_sha256": non_target_sha,
        "non_target_word_language_sha256": non_target_language_sha,
        "expression_count": expression_count,
        "expression_sha256": expression_sha,
        "expression_provenance_sha256": expression_provenance_sha,
        "meaning_count": meaning_count,
        "meaning_sha256": meaning_sha,
        "relation_count": relation_count,
        "relation_sha256": relation_sha,
        "change_history_count": history_count,
        "change_history_sha256": history_sha,
        "schema_sha256": _schema_sha(connection, schema),
    }
    return state, health, snapshot


def compare_work_seed(
    work_snapshot: dict[str, object], seed_snapshot: dict[str, object]
) -> dict[str, object]:
    fields = (
        "state",
        "source_arc_total_count",
        "source_arc_db_language_counts",
        "target_count",
        "target_strong_sha256",
        "target_projection_sha256",
        "target_identity_projection",
        "target_expression_mismatch_count",
        "x_pn_missing_count",
        "x_pn_missing_strong_sha256",
    )
    diffs = [field for field in fields if work_snapshot[field] != seed_snapshot[field]]
    if diffs:
        raise MigrationError(f"work·seed cohort/result parity 불일치: {diffs}")
    return {"exact": True, "checked_fields": list(fields), "diff_count": 0}


def verify_protected_unchanged(
    before: dict[str, object], after: dict[str, object], label: str
) -> dict[str, object]:
    diffs = [key for key in PROTECTION_KEYS if before[key] != after[key]]
    count_keys = (
        "non_target_word_count",
        "expression_count",
        "meaning_count",
        "relation_count",
        "change_history_count",
        "source_arc_total_count",
        "target_count",
        "target_strong_sha256",
        "target_projection_sha256",
    )
    diffs.extend(key for key in count_keys if before[key] != after[key])
    if diffs:
        raise MigrationError(f"보호 projection 변경: {label}: {sorted(set(diffs))}")
    return {
        key: {"pre": before[key], "post": after[key]}
        for key in (*PROTECTION_KEYS, *count_keys)
    }


def _read_database_pair(
    work_db: Path,
    seed_db: Path,
    manifest: LoadedManifest,
    entries: dict[str, source_parser.SourceEntryV2],
    expected_state: str | None = None,
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
        work_state, work_health, work_snapshot = capture_snapshot(
            work_connection,
            "main",
            manifest,
            entries,
            expected_state=expected_state,
        )
        seed_state, seed_health, seed_snapshot = capture_snapshot(
            seed_connection,
            "main",
            manifest,
            entries,
            expected_state=expected_state,
        )
        if work_state != seed_state:
            raise MigrationError(
                f"work·seed state 불일치: {work_state} != {seed_state}"
            )
        parity = compare_work_seed(work_snapshot, seed_snapshot)
    finally:
        work_connection.close()
        seed_connection.close()
    return (
        work_state,
        work_health,
        seed_health,
        work_snapshot,
        seed_snapshot,
        parity,
    )


def run_dry_run(
    *,
    manifest_path: Path = DEFAULT_MANIFEST,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    enforce_initial_hashes: bool = True,
) -> dict[str, object]:
    assert_no_sidecars((work_db, seed_db))
    before = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    manifest = load_manifest(manifest_path)
    source_info, entries = load_source_boundary(source_manifest_path, source_xml_path)
    if manifest.payload["source"] != source_info:
        raise MigrationError("manifest와 active source boundary 불일치")
    state, work_health, seed_health, work, seed, parity = _read_database_pair(
        work_db, seed_db, manifest, entries
    )
    if state == "pre_apply" and enforce_initial_hashes:
        expected = manifest.payload["expected_initial_database_sha256"]
        if before != expected:
            raise MigrationError(f"active DB 시작 SHA 불일치: {before} != {expected}")
    after = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    if before != after:
        raise MigrationError("dry-run 전후 DB SHA 변경")
    assert_no_sidecars((work_db, seed_db))
    for snapshot in (work, seed):
        snapshot.pop("target_identity_projection")
    planned = EXPECTED_TARGET_COUNT if state == "pre_apply" else 0
    return {
        "migration_id": MIGRATION_ID,
        "mode": "dry-run",
        "status": (
            f"적용 가능 — DB별 변경 예정 {planned}"
            if planned
            else "이미 적용됨 — 변경 0"
        ),
        "state": state,
        "planned_change_count_per_database": planned,
        "manifest_sha256": manifest.file_sha256,
        "target_projection_sha256": manifest.target_projection_sha256,
        "source": source_info,
        "database_sha256_before": before,
        "database_sha256_after": after,
        "work": {"health": work_health, "snapshot": work},
        "seed": {"health": seed_health, "snapshot": seed},
        "parity": parity,
        "sidecar_count": 0,
    }


def _same_local_volume(left: Path, right: Path) -> bool:
    return left.resolve().drive.lower() == right.resolve().drive.lower()


def create_verified_backups(
    work_db: Path, seed_db: Path, backup_root: Path
) -> tuple[Path, dict[str, object]]:
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S_%fZ")
    backup_dir = backup_root / timestamp
    backup_dir.mkdir(parents=True, exist_ok=False)
    metadata: dict[str, object] = {}
    for label, source in (("work", work_db), ("seed", seed_db)):
        destination = backup_dir / f"reshet_{label}_pre_arc_language.db"
        shutil.copy2(source, destination)
        source_sha = sha256_file(source)
        backup_sha = sha256_file(destination)
        if source_sha != backup_sha or source.stat().st_size != destination.stat().st_size:
            raise MigrationError(f"backup byte 검증 실패: {label}")
        connection = open_read_only(destination)
        try:
            health = verify_database_health(connection)
        finally:
            connection.close()
        metadata[label] = {
            "original_path": _portable_path(source),
            "original_sha256": source_sha,
            "backup_path": _portable_path(destination),
            "backup_sha256": backup_sha,
            "size_bytes": destination.stat().st_size,
            "integrity_check": health["integrity_check"],
            "foreign_key_violation_count": health["foreign_key_violation_count"],
        }
    return backup_dir, metadata


def restore_verified_backups(
    work_db: Path, seed_db: Path, metadata: dict[str, object]
) -> dict[str, object]:
    restored: dict[str, object] = {}
    for label, target in (("work", work_db), ("seed", seed_db)):
        info = metadata.get(label)
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


def _validate_attached_paths(
    connection: sqlite3.Connection, work_db: Path, seed_db: Path
) -> list[dict[str, object]]:
    rows = connection.execute("PRAGMA database_list").fetchall()
    result = [
        {"seq": int(row[0]), "name": str(row[1]), "path": str(Path(row[2]).resolve())}
        for row in rows
        if str(row[1]) in {"main", "seed_db"}
    ]
    paths = {item["name"]: Path(str(item["path"])).resolve() for item in result}
    if paths.get("main") != work_db.resolve() or paths.get("seed_db") != seed_db.resolve():
        raise MigrationError(f"ATTACH database_list 경로 불일치: {result}")
    return [
        {**item, "path": _portable_path(Path(str(item["path"])))} for item in result
    ]


def _update_targets(
    connection: sqlite3.Connection, schema: str, targets: Sequence[Target]
) -> int:
    changed = 0
    for target in targets:
        cursor = connection.execute(
            f'''
            UPDATE {_table(schema, "WORD_TABLE")}
            SET {_quote("언어")} = ?
            WHERE id = ?
              AND {_quote("스트롱넘버")} = ?
              AND {_quote("언어")} = ?
            ''',
            (
                target.target_language,
                target.word_id,
                target.expected_db_strong_number,
                target.expected_current_language,
            ),
        )
        if cursor.rowcount != 1:
            raise MigrationError(
                f"UPDATE rowcount 불일치: {schema}: {target.strong_number}: "
                f"{cursor.rowcount}"
            )
        changed += cursor.rowcount
    return changed


def write_json_atomic(path: Path, payload: dict[str, object]) -> str:
    raw = canonical_json_bytes(payload)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as temporary:
            temporary.write(raw)
            temporary.flush()
            temporary_path = Path(temporary.name)
        temporary_path.replace(path)
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()
    return hashlib.sha256(raw).hexdigest()


def _result_matches_current_state(
    result_output: Path,
    manifest: LoadedManifest,
    work_db: Path,
    seed_db: Path,
    work_snapshot: dict[str, object],
    seed_snapshot: dict[str, object],
) -> dict[str, object]:
    if not result_output.is_file():
        raise MigrationError("이미 적용 상태지만 matching result artifact가 없음")
    payload = json.loads(result_output.read_text(encoding="utf-8"))
    if (
        payload.get("schema_version") != SCHEMA_VERSION
        or payload.get("migration_id") != MIGRATION_ID
        or payload.get("tool_version") != TOOL_VERSION
        or payload.get("input_manifest_sha256") != manifest.file_sha256
        or payload.get("target_projection_sha256")
        != manifest.target_projection_sha256
    ):
        raise MigrationError("matching result identity 불일치")
    for label, path, snapshot in (
        ("work", work_db, work_snapshot),
        ("seed", seed_db, seed_snapshot),
    ):
        section = payload.get(label)
        if not isinstance(section, dict) or section.get("output_sha256") != sha256_file(path):
            raise MigrationError(f"matching result DB SHA 불일치: {label}")
        protection = section.get("protection")
        if not isinstance(protection, dict):
            raise MigrationError(f"matching result protection 누락: {label}")
        for key in PROTECTION_KEYS:
            values = protection.get(key)
            if not isinstance(values, dict) or values.get("post") != snapshot[key]:
                raise MigrationError(f"matching result protection 불일치: {label}.{key}")
    return payload


def _database_result(
    input_sha: str,
    output_sha: str,
    before: dict[str, object],
    after: dict[str, object],
    health_before: dict[str, object],
    health_after: dict[str, object],
    protection: dict[str, object],
) -> dict[str, object]:
    return {
        "input_sha256": input_sha,
        "output_sha256": output_sha,
        "health": {"pre": health_before, "post": health_after},
        "source_arc_db_language_counts": {
            "pre": before["source_arc_db_language_counts"],
            "post": after["source_arc_db_language_counts"],
        },
        "target_state": {"pre": before["state"], "post": after["state"]},
        "protection": protection,
    }


def run_apply(
    *,
    manifest_path: Path = DEFAULT_MANIFEST,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    backup_root: Path = DEFAULT_BACKUP_ROOT,
    result_output: Path = DEFAULT_RESULT,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    confirm_token: str,
    enforce_initial_hashes: bool = True,
    fault_injection: str | None = None,
) -> dict[str, object]:
    if confirm_token != "APPLY_HEBREWSTRONG_ARC_518":
        raise MigrationError("apply confirmation token 불일치")
    if work_db.resolve() == seed_db.resolve():
        raise MigrationError("work와 seed DB 경로가 같음")
    if not _same_local_volume(work_db, seed_db):
        raise MigrationError("work와 seed가 같은 local filesystem/volume이 아님")
    assert_no_sidecars((work_db, seed_db))
    manifest = load_manifest(manifest_path)
    source_info, entries = load_source_boundary(source_manifest_path, source_xml_path)
    if manifest.payload["source"] != source_info:
        raise MigrationError("manifest와 active source boundary 불일치")
    input_hashes = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    (
        state,
        work_health_pre,
        seed_health_pre,
        work_pre,
        seed_pre,
        parity_pre,
    ) = _read_database_pair(work_db, seed_db, manifest, entries)
    if state == "post_apply":
        _result_matches_current_state(
            result_output, manifest, work_db, seed_db, work_pre, seed_pre
        )
        assert_no_sidecars((work_db, seed_db))
        return {
            "migration_id": MIGRATION_ID,
            "mode": "apply",
            "status": "이미 적용됨 — 변경 0",
            "change_count": 0,
            "backup_created": False,
            "transaction_started": False,
            "database_sha256": input_hashes,
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": sha256_file(result_output),
            "result_unchanged": True,
        }
    if state != "pre_apply":
        raise MigrationError(f"지원하지 않는 state: {state}")
    if enforce_initial_hashes:
        expected_hashes = manifest.payload["expected_initial_database_sha256"]
        if input_hashes != expected_hashes:
            raise MigrationError(
                f"active DB 시작 SHA 불일치: {input_hashes} != {expected_hashes}"
            )
    if result_output.exists():
        raise MigrationError("미적용 DB인데 result artifact가 이미 존재함")
    if (
        work_health_pre["journal_mode"] != "delete"
        or seed_health_pre["journal_mode"] != "delete"
    ):
        raise MigrationError("apply 전 journal_mode=delete 조건 불충족")

    backup_dir, backup_metadata = create_verified_backups(
        work_db, seed_db, backup_root
    )
    connection: sqlite3.Connection | None = None
    committed = False
    result_written = False
    try:
        connection = sqlite3.connect(str(work_db.resolve()))
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        main_journal = str(
            connection.execute("PRAGMA main.journal_mode").fetchone()[0]
        ).lower()
        connection.execute("ATTACH DATABASE ? AS seed_db", (str(seed_db.resolve()),))
        seed_journal = str(
            connection.execute("PRAGMA seed_db.journal_mode").fetchone()[0]
        ).lower()
        database_list = _validate_attached_paths(connection, work_db, seed_db)
        if main_journal != "delete" or seed_journal != "delete":
            raise MigrationError(
                f"ATTACH journal_mode 불일치: main={main_journal}, seed={seed_journal}"
            )
        connection.execute("BEGIN IMMEDIATE")
        _, _, work_tx_pre = capture_snapshot(
            connection, "main", manifest, entries, expected_state="pre_apply"
        )
        _, _, seed_tx_pre = capture_snapshot(
            connection, "seed_db", manifest, entries, expected_state="pre_apply"
        )
        compare_work_seed(work_tx_pre, seed_tx_pre)
        if work_tx_pre != work_pre or seed_tx_pre != seed_pre:
            raise MigrationError("transaction 직전 snapshot 변경")

        work_changed = _update_targets(connection, "main", manifest.targets)
        if fault_injection == "after_work_update":
            raise MigrationError("test fault injection: after_work_update")
        seed_changed = _update_targets(connection, "seed_db", manifest.targets)
        if work_changed != EXPECTED_TARGET_COUNT or seed_changed != EXPECTED_TARGET_COUNT:
            raise MigrationError(
                f"apply 변경 수 불일치: work={work_changed}, seed={seed_changed}"
            )
        _, _, work_tx_post = capture_snapshot(
            connection, "main", manifest, entries, expected_state="post_apply"
        )
        _, _, seed_tx_post = capture_snapshot(
            connection, "seed_db", manifest, entries, expected_state="post_apply"
        )
        work_protection_tx = verify_protected_unchanged(
            work_pre, work_tx_post, "work/transaction"
        )
        seed_protection_tx = verify_protected_unchanged(
            seed_pre, seed_tx_post, "seed/transaction"
        )
        parity_tx_post = compare_work_seed(work_tx_post, seed_tx_post)
        connection.commit()
        committed = True
        connection.close()
        connection = None

        if fault_injection == "post_commit_validation":
            raise MigrationError("test fault injection: post_commit_validation")
        assert_no_sidecars((work_db, seed_db))
        (
            _,
            work_health_post,
            seed_health_post,
            work_post,
            seed_post,
            parity_post,
        ) = _read_database_pair(
            work_db, seed_db, manifest, entries, expected_state="post_apply"
        )
        work_protection = verify_protected_unchanged(
            work_pre, work_post, "work/post-commit"
        )
        seed_protection = verify_protected_unchanged(
            seed_pre, seed_post, "seed/post-commit"
        )
        output_hashes = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
        result_payload: dict[str, object] = {
            "schema_version": SCHEMA_VERSION,
            "migration_id": MIGRATION_ID,
            "tool_version": TOOL_VERSION,
            "executed_at_utc": datetime.now(timezone.utc).isoformat(),
            "input_manifest_path": _portable_path(manifest_path),
            "input_manifest_sha256": manifest.file_sha256,
            "target_projection_sha256": manifest.target_projection_sha256,
            "source": source_info,
            "sql": {
                "statement": "UPDATE <schema>.WORD_TABLE SET 언어='아람어' WHERE id=? AND 스트롱넘버=? AND 언어='히브리어'",
                "target_count_per_database": EXPECTED_TARGET_COUNT,
            },
            "attach": {
                "database_list": database_list,
                "journal_mode": {"main": main_journal, "seed_db": seed_journal},
                "same_local_filesystem_volume": True,
                "single_connection_transaction": True,
            },
            "backup": {"directory": _portable_path(backup_dir), **backup_metadata},
            "change_counts": {
                "columns_changed": ["WORD_TABLE.언어"],
                "work": work_changed,
                "seed": seed_changed,
                "total_database_rows": work_changed + seed_changed,
            },
            "parity_pre": parity_pre,
            "parity_transaction_post": parity_tx_post,
            "parity_post": parity_post,
            "transaction_protection": {
                "work": work_protection_tx,
                "seed": seed_protection_tx,
            },
            "second_run": {
                "status": "already_applied_noop_verified",
                "message": "이미 적용됨 — 변경 0",
                "change_count": 0,
                "backup_created": False,
                "transaction_started": False,
                "result_unchanged": True,
            },
            "work": _database_result(
                input_hashes["work"],
                output_hashes["work"],
                work_pre,
                work_post,
                work_health_pre,
                work_health_post,
                work_protection,
            ),
            "seed": _database_result(
                input_hashes["seed"],
                output_hashes["seed"],
                seed_pre,
                seed_post,
                seed_health_pre,
                seed_health_post,
                seed_protection,
            ),
        }
        if fault_injection == "result_write":
            raise MigrationError("test fault injection: result_write")
        result_sha = write_json_atomic(result_output, result_payload)
        result_written = True
        _result_matches_current_state(
            result_output, manifest, work_db, seed_db, work_post, seed_post
        )
        return {
            "migration_id": MIGRATION_ID,
            "mode": "apply",
            "status": (
                f"적용 완료 — work {work_changed}, seed {seed_changed}"
            ),
            "database_sha256_before": input_hashes,
            "database_sha256_after": output_hashes,
            "work_change_count": work_changed,
            "seed_change_count": seed_changed,
            "backup_directory": _portable_path(backup_dir),
            "backup": backup_metadata,
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": result_sha,
            "parity": parity_post,
        }
    except Exception as error:
        if connection is not None:
            try:
                connection.rollback()
            finally:
                connection.close()
        restore_result = restore_verified_backups(work_db, seed_db, backup_metadata)
        if result_written and result_output.exists():
            result_output.unlink()
        raise MigrationError(
            f"apply 실패: {error}; committed={committed}; "
            f"양쪽 backup restore 성공={restore_result}"
        ) from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    generate = subparsers.add_parser("generate-manifest")
    dry_run = subparsers.add_parser("dry-run")
    apply = subparsers.add_parser("apply")
    for child in (generate, dry_run, apply):
        child.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
        child.add_argument("--work-db", default=str(DEFAULT_WORK_DB))
        child.add_argument("--seed-db", default=str(DEFAULT_SEED_DB))
        child.add_argument("--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST))
        child.add_argument("--source-xml", default=str(DEFAULT_SOURCE_XML))
    apply.add_argument("--backup-root", default=str(DEFAULT_BACKUP_ROOT))
    apply.add_argument("--result-output", default=str(DEFAULT_RESULT))
    apply.add_argument("--confirm", required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    args = build_parser().parse_args(argv)
    try:
        if args.command == "generate-manifest":
            payload = build_manifest_payload(
                Path(args.work_db),
                Path(args.seed_db),
                Path(args.source_manifest),
                Path(args.source_xml),
            )
            file_sha = write_manifest(payload, Path(args.manifest))
            print(
                json.dumps(
                    {
                        "status": "manifest 생성 완료",
                        "target_count": len(payload["targets"]),
                        "target_strong_sha256": payload["target_strong_sha256"],
                        "target_projection_sha256": payload[
                            "target_projection_sha256"
                        ],
                        "manifest_sha256": file_sha,
                    },
                    ensure_ascii=False,
                    indent=2,
                )
            )
            return 0
        if args.command == "dry-run":
            result = run_dry_run(
                manifest_path=Path(args.manifest),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                source_manifest_path=Path(args.source_manifest),
                source_xml_path=Path(args.source_xml),
            )
        else:
            result = run_apply(
                manifest_path=Path(args.manifest),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                backup_root=Path(args.backup_root),
                result_output=Path(args.result_output),
                source_manifest_path=Path(args.source_manifest),
                source_xml_path=Path(args.source_xml),
                confirm_token=args.confirm,
            )
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (MigrationError, OSError, sqlite3.Error, ValueError) as error:
        print(f"오류: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
