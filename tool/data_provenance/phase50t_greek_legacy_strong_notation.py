#!/usr/bin/env python3
"""Phase 50-T Greek legacy Strong pronunciation notation migration.

The approved manifest is the only source of UPDATE identities.  The tool keeps
Phase 50-R untouched and changes only
``word_expression_set.pronunciation_notation`` in work and seed together.
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
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Sequence


TOOL_VERSION = "1.0.0"
PHASE = "50-T"
SCHEMA_VERSION = 1
TARGET_WORD_COUNT = 183
TARGET_EXPRESSION_COUNT = 190
EXPECTED_E4_COUNT = 11
EXPECTED_E5_COUNT = 23
EXPECTED_PHASE50R_AUTO_COUNT = 5389
EXPECTED_SOURCE_ONLY_HOLD_WORD_COUNT = 101
EXPECTED_CANDIDATE_PROJECTION_SHA256 = (
    "0e20117dc7a7319172574bf395a7130f5ee235b5de73958a76c72715f1abecbf"
)

TOOL_DIR = Path(__file__).resolve().parent
DEFAULT_MANIFEST = (
    TOOL_DIR / "manifests" / "phase50t_greek_legacy_strong_notation.json"
)
DEFAULT_SOURCE_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_SOURCE_XML = TOOL_DIR / ".source_cache" / "strongsgreek.xml"
DEFAULT_PHASE50R_AUTO_PLAN = (
    TOOL_DIR / ".source_cache" / "phase50r" / "greek_auto_plan.jsonl"
)
DEFAULT_PHASE50R_EXCEPTION_MANIFEST = (
    TOOL_DIR
    / ".source_cache"
    / "phase50r"
    / "work"
    / "exception_manifest.json"
)

LANGUAGE_COLUMN = "언어"
STRONG_COLUMN = "스트롱넘버"
HELLENIC_LANGUAGE = "헬라어"
HEBREW_LANGUAGE = "히브리어"
ARAMAIC_LANGUAGE = "아람어"
LEGACY_SPELLING = "표기"
LEGACY_TRANSLITERATION = "음역"
LEGACY_PRONUNCIATION = "발음"

EXPECTED_SOURCE = {
    "repository": "https://github.com/morphgnt/strongs-dictionary-xml",
    "commit": "dd6758b82f46b620804a8ea677d715844679eea1",
    "path": "strongsgreek.xml",
    "sha256": "91474213b208a4e487d35f85c10e5c90737acc69082dad15dec5431406003545",
    "license": "CC0 1.0",
    "parser_contract": "greek_headword_v1",
}

PROJECTION_FIELDS = [
    "language",
    "strong_number",
    "word_id",
    "seq",
    "expected_current_pronunciation",
    "source_repository",
    "source_commit",
    "source_path",
    "source_key",
    "source_primary_pronunciation",
    "source_alternate_pronunciation",
    "comparison_grade",
    "expected_current_notation",
    "expected_target_notation",
    "expected_notation_name",
    "classification_reason",
]

EXPECTED_PROJECTION_CONTRACT = {
    "fields": PROJECTION_FIELDS,
    "sort": ["word_id ASC", "seq ASC"],
    "format": "JSONL ordered arrays",
    "encoding": "UTF-8",
    "bom": False,
    "ensure_ascii": False,
    "separators": [",", ":"],
    "final_lf": True,
}


class MigrationError(RuntimeError):
    """Fail-closed Phase 50-T error."""


@dataclass(frozen=True)
class Target:
    language: str
    strong_number: str
    word_id: str
    seq: int
    expected_current_pronunciation: str
    source_repository: str
    source_commit: str
    source_path: str
    source_key: str
    source_primary_pronunciation: str
    source_alternate_pronunciation: str | None
    comparison_grade: str
    expected_current_notation: str
    expected_target_notation: str
    expected_notation_name: str | None
    classification_reason: str

    @property
    def identity(self) -> tuple[str, int]:
        return (self.word_id, self.seq)

    def projection_row(self) -> list[object]:
        return [getattr(self, field) for field in PROJECTION_FIELDS]


@dataclass(frozen=True)
class SourceEntry:
    primary: tuple[str, ...]
    alternate: tuple[str, ...]


@dataclass(frozen=True)
class LoadedManifest:
    payload: dict[str, object]
    targets: tuple[Target, ...]
    file_sha256: str
    candidate_projection_sha256: str


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
        json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def jsonl_sha256(rows: Iterable[Sequence[object]]) -> str:
    digest = hashlib.sha256()
    for row in rows:
        digest.update(
            (
                json.dumps(
                    list(row), ensure_ascii=False, separators=(",", ":")
                )
                + "\n"
            ).encode("utf-8")
        )
    return digest.hexdigest()


def normalize_strong_number(value: object) -> str | None:
    match = re.fullmatch(r"([GHgh])\s*0*(\d+)", str(value or "").strip())
    if match is None:
        return None
    prefix = match.group(1).upper()
    number = int(match.group(2))
    limit = 5624 if prefix == "G" else 8674
    if not 1 <= number <= limit:
        return None
    return f"{prefix}{number:04d}"


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def parse_greek_source(path: Path) -> dict[str, SourceEntry]:
    try:
        root = ET.parse(path).getroot()
    except (ET.ParseError, OSError) as error:
        raise MigrationError(f"Greek source parsing 실패: {path}: {error}") from error
    if _local_name(root.tag) != "strongsdictionary":
        raise MigrationError(f"Greek source root 불일치: {root.tag!r}")
    entries_node = next(
        (child for child in root if _local_name(child.tag) == "entries"), None
    )
    if entries_node is None:
        raise MigrationError("Greek source entries node가 없음")

    result: dict[str, SourceEntry] = {}
    for entry in entries_node:
        if _local_name(entry.tag) != "entry":
            continue
        strong = normalize_strong_number(f"G{entry.get('strongs') or ''}")
        if strong is None:
            continue
        primary: list[str] = []
        alternate: list[str] = []
        for child in entry:
            name = _local_name(child.tag)
            if name in {"strongs_derivation", "strongs_def", "kjv_def"}:
                alternate.extend(
                    descendant.get("strongs", "")
                    for descendant in child.iter()
                    if _local_name(descendant.tag) == "pronunciation"
                    and descendant.get("strongs")
                )
                continue
            if name == "greek":
                primary.append("")
            elif name == "pronunciation":
                pronunciation = child.get("strongs", "")
                if primary and not primary[-1]:
                    primary[-1] = pronunciation
                else:
                    primary.append(pronunciation)
        result[strong] = SourceEntry(
            primary=tuple(value for value in primary if value),
            alternate=tuple(dict.fromkeys(value for value in alternate if value)),
        )
    if not result:
        raise MigrationError("Greek source에서 Strong entry를 추출하지 못함")
    return result


def _read_json_object(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"JSON 읽기 실패: {path}: {error}") from error
    if not isinstance(value, dict):
        raise MigrationError(f"JSON top-level object가 아님: {path}")
    return value


def load_input_manifest(path: Path) -> LoadedManifest:
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise MigrationError(f"input manifest 읽기 실패: {path}: {error}") from error
    if raw.startswith(b"\xef\xbb\xbf"):
        raise MigrationError("input manifest에 UTF-8 BOM이 있음")
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"input manifest JSON parsing 실패: {error}") from error
    if not isinstance(payload, dict):
        raise MigrationError("input manifest top-level object가 아님")
    if canonical_json_bytes(payload) != raw:
        raise MigrationError("input manifest canonical byte 형식 불일치")

    required_top = {
        "schema_version",
        "phase",
        "source",
        "candidate_projection_contract",
        "candidate_projection_sha256",
        "target_word_count",
        "target_expression_count",
        "targets",
    }
    if set(payload) != required_top:
        raise MigrationError(
            "input manifest top-level field 불일치: "
            f"expected={sorted(required_top)}, actual={sorted(payload)}"
        )
    if payload["schema_version"] != SCHEMA_VERSION or payload["phase"] != PHASE:
        raise MigrationError("input manifest schema_version 또는 phase 불일치")
    if payload["source"] != EXPECTED_SOURCE:
        raise MigrationError("input manifest source boundary 불일치")
    if payload["candidate_projection_contract"] != EXPECTED_PROJECTION_CONTRACT:
        raise MigrationError("candidate projection contract 불일치")
    if payload["target_word_count"] != TARGET_WORD_COUNT:
        raise MigrationError("target word count 불일치")
    if payload["target_expression_count"] != TARGET_EXPRESSION_COUNT:
        raise MigrationError("target expression count 불일치")
    raw_targets = payload["targets"]
    if not isinstance(raw_targets, list):
        raise MigrationError("targets가 list가 아님")
    if len(raw_targets) != TARGET_EXPRESSION_COUNT:
        raise MigrationError(f"target expression 수 불일치: {len(raw_targets)}")

    targets: list[Target] = []
    for index, raw_target in enumerate(raw_targets):
        if not isinstance(raw_target, dict) or set(raw_target) != set(PROJECTION_FIELDS):
            raise MigrationError(f"target[{index}] field 불일치")
        try:
            target = Target(**raw_target)
        except TypeError as error:
            raise MigrationError(f"target[{index}] parsing 실패: {error}") from error
        if target.language != HELLENIC_LANGUAGE:
            raise MigrationError(f"target[{index}] Greek language 불일치")
        if normalize_strong_number(target.strong_number) != target.strong_number:
            raise MigrationError(f"target[{index}] Greek Strong identity 불일치")
        if not target.strong_number.startswith("G"):
            raise MigrationError(f"target[{index}] Greek Strong prefix가 아님")
        if target.source_key != target.strong_number:
            raise MigrationError(f"target[{index}] source_key 불일치")
        if not isinstance(target.seq, int) or not 1 <= target.seq <= 6:
            raise MigrationError(f"target[{index}] seq 범위 불일치")
        if not target.expected_current_pronunciation.strip():
            raise MigrationError(f"target[{index}] pronunciation이 blank")
        if target.source_primary_pronunciation != target.expected_current_pronunciation:
            raise MigrationError(f"target[{index}] source primary exact 불일치")
        if target.source_alternate_pronunciation is not None:
            raise MigrationError(f"target[{index}] E0 alternate field는 null이어야 함")
        if target.comparison_grade != "E0":
            raise MigrationError(f"target[{index}] E0가 아님")
        if target.expected_current_notation != "unknown":
            raise MigrationError(f"target[{index}] current notation 불일치")
        if target.expected_target_notation != "strong_dictionary":
            raise MigrationError(f"target[{index}] target notation 불일치")
        if target.expected_notation_name is not None:
            raise MigrationError(f"target[{index}] notation name이 null이 아님")
        if (
            target.source_repository != EXPECTED_SOURCE["repository"]
            or target.source_commit != EXPECTED_SOURCE["commit"]
            or target.source_path != EXPECTED_SOURCE["path"]
        ):
            raise MigrationError(f"target[{index}] source boundary 불일치")
        if (
            target.classification_reason
            != "source primary exact; work-seed and normalized-legacy exact"
        ):
            raise MigrationError(f"target[{index}] classification reason 불일치")
        targets.append(target)

    expected_order = sorted(targets, key=lambda item: (item.word_id, item.seq))
    if targets != expected_order:
        raise MigrationError("target 정렬이 word_id ASC, seq ASC가 아님")
    identities = [target.identity for target in targets]
    if len(set(identities)) != len(identities):
        raise MigrationError("target identity 중복")
    if len({target.word_id for target in targets}) != TARGET_WORD_COUNT:
        raise MigrationError("target distinct word count 불일치")

    projection_sha = jsonl_sha256(
        target.projection_row() for target in targets
    )
    declared_sha = payload["candidate_projection_sha256"]
    if declared_sha != EXPECTED_CANDIDATE_PROJECTION_SHA256:
        raise MigrationError("declared candidate projection SHA 불일치")
    if projection_sha != declared_sha:
        raise MigrationError(
            "candidate projection SHA 재현 실패: "
            f"expected={declared_sha}, actual={projection_sha}"
        )
    return LoadedManifest(
        payload=payload,
        targets=tuple(targets),
        file_sha256=sha256_bytes(raw),
        candidate_projection_sha256=projection_sha,
    )


def verify_source_boundary(
    source_manifest_path: Path,
    source_xml_path: Path,
    manifest: LoadedManifest,
) -> tuple[dict[str, object], dict[str, SourceEntry]]:
    source_manifest = _read_json_object(source_manifest_path)
    sources = source_manifest.get("sources")
    if not isinstance(sources, list):
        raise MigrationError("source manifest sources가 list가 아님")
    greek = next(
        (
            item
            for item in sources
            if isinstance(item, dict) and item.get("language") == "G"
        ),
        None,
    )
    if greek is None:
        raise MigrationError("source manifest Greek entry가 없음")
    manifest_source_values = {
        "repository": greek.get("repository"),
        "commit": greek.get("commit"),
        "path": greek.get("file_path"),
        "sha256": greek.get("sha256"),
        "license": greek.get("license"),
        "parser_contract": greek.get("parser_contract"),
    }
    if manifest_source_values != EXPECTED_SOURCE:
        raise MigrationError("source manifest Greek boundary 불일치")
    xml_sha = sha256_file(source_xml_path)
    if xml_sha != EXPECTED_SOURCE["sha256"]:
        raise MigrationError(
            f"cached Greek XML SHA 불일치: expected={EXPECTED_SOURCE['sha256']}, actual={xml_sha}"
        )
    source = parse_greek_source(source_xml_path)
    for target in manifest.targets:
        entry = source.get(target.source_key)
        if entry is None:
            raise MigrationError(f"source key 누락: {target.source_key}")
        if target.source_primary_pronunciation not in entry.primary:
            relation = (
                "alternate-only"
                if target.source_primary_pronunciation in entry.alternate
                else "source mismatch"
            )
            raise MigrationError(
                f"source primary exact 실패: {target.identity}: {relation}"
            )
    return (
        {
            "source_manifest_path": _portable_path(source_manifest_path),
            "source_manifest_sha256": sha256_file(source_manifest_path),
            "greek_xml_path": _portable_path(source_xml_path),
            "greek_xml_sha256": xml_sha,
            **EXPECTED_SOURCE,
            "parsed_entry_count": len(source),
        },
        source,
    )


def load_phase50r_auto_identities(path: Path) -> set[tuple[str, int]]:
    identities: set[tuple[str, int]] = set()
    try:
        with path.open(encoding="utf-8") as source:
            for line_number, line in enumerate(source, start=1):
                if not line.strip():
                    continue
                value = json.loads(line)
                identity = (str(value["word_id"]), int(value["db_seq"]))
                if identity in identities:
                    raise MigrationError(
                        f"Phase 50-R auto identity 중복: line={line_number}, identity={identity}"
                    )
                identities.add(identity)
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        if isinstance(error, MigrationError):
            raise
        raise MigrationError(f"Phase 50-R auto plan 읽기 실패: {path}: {error}") from error
    if len(identities) != EXPECTED_PHASE50R_AUTO_COUNT:
        raise MigrationError(
            f"Phase 50-R auto count 불일치: {len(identities)}"
        )
    return identities


def load_source_only_hold_strongs(path: Path) -> set[str]:
    payload = _read_json_object(path)
    items = payload.get("items")
    if not isinstance(items, list):
        raise MigrationError("Phase 50-R exception items가 list가 아님")
    result = {
        str(item.get("strong_id"))
        for item in items
        if isinstance(item, dict)
        and item.get("primary_disposition") == "hold"
        and "db_target_missing" in (item.get("reason_codes") or [])
        and str(item.get("strong_id", "")).startswith("G")
    }
    if len(result) != EXPECTED_SOURCE_ONLY_HOLD_WORD_COUNT:
        raise MigrationError(f"Greek source-only hold count 불일치: {len(result)}")
    return result


def _quote_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def _schema_table(schema: str, table: str) -> str:
    return f"{_quote_identifier(schema)}.{_quote_identifier(table)}"


def open_read_only(path: Path) -> sqlite3.Connection:
    resolved = path.resolve()
    connection = sqlite3.connect(
        resolved.as_uri() + "?mode=ro&immutable=1", uri=True
    )
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
            f"PRAGMA {_quote_identifier(schema)}.table_info({_quote_identifier(table)})"
        )
    ]


def verify_database_health(
    connection: sqlite3.Connection, schema: str = "main"
) -> dict[str, object]:
    required_expression_columns = {
        "id",
        "word_id",
        "seq",
        "is_representative",
        "spelling",
        "transliteration",
        "pronunciation",
        "pronunciation_notation",
        "pronunciation_notation_name",
    }
    expression_columns = set(
        _table_columns(connection, schema, "word_expression_set")
    )
    word_columns = set(_table_columns(connection, schema, "WORD_TABLE"))
    missing_expression = required_expression_columns - expression_columns
    required_word = {"id", LANGUAGE_COLUMN, STRONG_COLUMN}
    for prefix in (
        LEGACY_SPELLING,
        LEGACY_TRANSLITERATION,
        LEGACY_PRONUNCIATION,
    ):
        required_word.update(f"{prefix}{seq}" for seq in range(1, 7))
    missing_word = required_word - word_columns
    if missing_expression or missing_word:
        raise MigrationError(
            f"required schema 누락: expression={sorted(missing_expression)}, word={sorted(missing_word)}"
        )
    integrity = [
        str(row[0])
        for row in connection.execute(
            f"PRAGMA {_quote_identifier(schema)}.integrity_check"
        )
    ]
    foreign_keys = connection.execute(
        f"PRAGMA {_quote_identifier(schema)}.foreign_key_check"
    ).fetchall()
    journal_mode = str(
        connection.execute(
            f"PRAGMA {_quote_identifier(schema)}.journal_mode"
        ).fetchone()[0]
    ).lower()
    if integrity != ["ok"]:
        raise MigrationError(f"integrity_check 실패: {schema}: {integrity}")
    if foreign_keys:
        raise MigrationError(
            f"foreign_key_check 실패: {schema}: {len(foreign_keys)}"
        )
    return {
        "integrity_check": "ok",
        "foreign_key_violation_count": 0,
        "required_schema_present": True,
        "journal_mode": journal_mode,
    }


def sidecar_paths(path: Path) -> tuple[Path, Path, Path]:
    return (
        Path(str(path.resolve()) + "-wal"),
        Path(str(path.resolve()) + "-shm"),
        Path(str(path.resolve()) + "-journal"),
    )


def assert_no_sidecars(paths: Sequence[Path]) -> None:
    active = [str(sidecar) for path in paths for sidecar in sidecar_paths(path) if sidecar.exists()]
    if active:
        raise MigrationError(f"active SQLite sidecar 발견: {active}")


def _legacy_case(prefix: str, alias: str = "w") -> str:
    return " ".join(
        f'WHEN {seq} THEN {alias}.{_quote_identifier(f"{prefix}{seq}")}'
        for seq in range(1, 7)
    )


def _expression_rows(
    connection: sqlite3.Connection, schema: str = "main"
) -> list[dict[str, object]]:
    word_table = _schema_table(schema, "WORD_TABLE")
    expression_table = _schema_table(schema, "word_expression_set")
    sql = f'''
        SELECT
          e.id AS expression_id,
          w.{_quote_identifier(STRONG_COLUMN)} AS strong_number,
          w.{_quote_identifier(LANGUAGE_COLUMN)} AS language,
          e.word_id,
          e.seq,
          e.is_representative,
          e.spelling,
          e.transliteration,
          e.pronunciation,
          e.pronunciation_notation,
          e.pronunciation_notation_name,
          CASE e.seq {_legacy_case(LEGACY_SPELLING)} ELSE NULL END AS legacy_spelling,
          CASE e.seq {_legacy_case(LEGACY_TRANSLITERATION)} ELSE NULL END AS legacy_transliteration,
          CASE e.seq {_legacy_case(LEGACY_PRONUNCIATION)} ELSE NULL END AS legacy_pronunciation
        FROM {expression_table} AS e
        JOIN {word_table} AS w ON w.id = e.word_id
        ORDER BY e.word_id, e.seq, e.id
    '''
    return [dict(row) for row in connection.execute(sql)]


def _word_table_projection(
    connection: sqlite3.Connection, schema: str = "main"
) -> tuple[int, str]:
    columns = ["id", STRONG_COLUMN, LANGUAGE_COLUMN]
    for prefix in (
        LEGACY_SPELLING,
        LEGACY_TRANSLITERATION,
        LEGACY_PRONUNCIATION,
    ):
        columns.extend(f"{prefix}{seq}" for seq in range(1, 7))
    select_columns = ", ".join(_quote_identifier(column) for column in columns)
    rows = connection.execute(
        f"SELECT {select_columns} FROM {_schema_table(schema, 'WORD_TABLE')} ORDER BY id"
    ).fetchall()
    return len(rows), jsonl_sha256([list(row) for row in rows])


def _schema_hash(connection: sqlite3.Connection, schema: str = "main") -> str:
    rows = connection.execute(
        f'''
        SELECT type, name, tbl_name, sql
        FROM {_quote_identifier(schema)}.sqlite_master
        WHERE name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        '''
    ).fetchall()
    return jsonl_sha256([list(row) for row in rows])


def _change_history_projection(
    connection: sqlite3.Connection, schema: str = "main"
) -> tuple[int, str]:
    columns = _table_columns(connection, schema, "CHANGE_HISTORY")
    if not columns:
        raise MigrationError("CHANGE_HISTORY schema가 없음")
    select_columns = ", ".join(_quote_identifier(column) for column in columns)
    rows = connection.execute(
        f"SELECT {select_columns} FROM {_schema_table(schema, 'CHANGE_HISTORY')} ORDER BY rowid"
    ).fetchall()
    return len(rows), jsonl_sha256([list(row) for row in rows])


def _notation_counts(rows: Sequence[dict[str, object]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        key = (
            "<NULL>"
            if row["pronunciation_notation"] is None
            else str(row["pronunciation_notation"])
        )
        counts[key] = counts.get(key, 0) + 1
    return dict(sorted(counts.items()))


def _language_notation_counts(
    rows: Sequence[dict[str, object]], languages: set[str]
) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        if row["language"] not in languages:
            continue
        notation = (
            "<NULL>"
            if row["pronunciation_notation"] is None
            else str(row["pronunciation_notation"])
        )
        key = f"{row['language']}|{notation}"
        counts[key] = counts.get(key, 0) + 1
    return dict(sorted(counts.items()))


def _projection_hash(
    rows: Iterable[dict[str, object]], fields: Sequence[str]
) -> str:
    return jsonl_sha256([[row[field] for field in fields] for row in rows])


def _excluded_grade_rows(
    rows: Sequence[dict[str, object]], source: dict[str, SourceEntry]
) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    e4: list[dict[str, object]] = []
    e5: list[dict[str, object]] = []
    for row in rows:
        strong = normalize_strong_number(row["strong_number"])
        if (
            strong is None
            or not strong.startswith("G")
            or row["language"] != HELLENIC_LANGUAGE
            or row["pronunciation"] is None
            or not str(row["pronunciation"]).strip()
            or row["pronunciation_notation"] != "unknown"
            or row["pronunciation_notation_name"] is not None
        ):
            continue
        entry = source.get(strong, SourceEntry((), ()))
        pronunciation = str(row["pronunciation"])
        if pronunciation in entry.primary:
            continue
        if pronunciation in entry.alternate:
            e4.append(row)
        else:
            e5.append(row)
    return e4, e5


def capture_snapshot(
    connection: sqlite3.Connection,
    schema: str,
    targets: Sequence[Target],
    source: dict[str, SourceEntry],
    phase50r_auto: set[tuple[str, int]],
) -> dict[str, object]:
    rows = _expression_rows(connection, schema)
    target_keys = {target.identity for target in targets}
    target_rows = [
        row for row in rows if (str(row["word_id"]), int(row["seq"])) in target_keys
    ]
    non_target_rows = [
        row for row in rows if (str(row["word_id"]), int(row["seq"])) not in target_keys
    ]
    strong_rows = [
        row
        for row in rows
        if row["strong_number"] is not None
        and str(row["strong_number"]).strip()
    ]
    auto_rows = [
        row
        for row in rows
        if (str(row["word_id"]), int(row["seq"])) in phase50r_auto
    ]
    hebrew_aramaic_rows = [
        row
        for row in rows
        if row["language"] in {HEBREW_LANGUAGE, ARAMAIC_LANGUAGE}
    ]
    e4_rows, e5_rows = _excluded_grade_rows(rows, source)
    target_fields = [
        "strong_number",
        "language",
        "word_id",
        "seq",
        "is_representative",
        "spelling",
        "transliteration",
        "pronunciation",
        "pronunciation_notation_name",
        "legacy_spelling",
        "legacy_transliteration",
        "legacy_pronunciation",
    ]
    expression_fields = [
        "expression_id",
        "word_id",
        "seq",
        "is_representative",
        "spelling",
        "transliteration",
        "pronunciation",
        "pronunciation_notation",
        "pronunciation_notation_name",
    ]
    expression_semantic_fields = expression_fields[1:]
    strong_fields = [
        "strong_number",
        "word_id",
        "seq",
        "pronunciation",
        "pronunciation_notation",
        "pronunciation_notation_name",
        "language",
        "is_representative",
        "legacy_pronunciation",
    ]
    target_state_fields = [
        "strong_number",
        "word_id",
        "seq",
        "pronunciation",
        "pronunciation_notation",
        "pronunciation_notation_name",
        "legacy_pronunciation",
    ]
    excluded_fields = [
        "strong_number",
        "word_id",
        "seq",
        "pronunciation",
        "pronunciation_notation",
        "pronunciation_notation_name",
        "legacy_pronunciation",
    ]
    word_count, word_hash = _word_table_projection(connection, schema)
    change_count, change_hash = _change_history_projection(connection, schema)
    return {
        "expression_row_count": len(rows),
        "word_row_count": word_count,
        "target_expression_count": len(target_rows),
        "target_word_count": len({str(row["word_id"]) for row in target_rows}),
        "target_notation_counts": _notation_counts(target_rows),
        "notation_counts": _notation_counts(rows),
        "hebrew_aramaic_notation_counts": _language_notation_counts(
            rows, {HEBREW_LANGUAGE, ARAMAIC_LANGUAGE}
        ),
        "target_immutable_sha256": _projection_hash(target_rows, target_fields),
        "target_state_sha256": _projection_hash(target_rows, target_state_fields),
        "non_target_expression_sha256": _projection_hash(
            non_target_rows, expression_fields
        ),
        "non_target_expression_semantic_sha256": _projection_hash(
            non_target_rows, expression_semantic_fields
        ),
        "word_table_sha256": word_hash,
        "legacy_projection_sha256": _projection_hash(
            strong_rows,
            ["word_id", "seq", "pronunciation", "legacy_pronunciation"],
        ),
        "strong_projection_count": len(strong_rows),
        "strong_projection_sha256": _projection_hash(strong_rows, strong_fields),
        "schema_sha256": _schema_hash(connection, schema),
        "change_history_row_count": change_count,
        "change_history_sha256": change_hash,
        "e4_count": len(e4_rows),
        "e4_sha256": _projection_hash(e4_rows, excluded_fields),
        "e5_count": len(e5_rows),
        "e5_sha256": _projection_hash(e5_rows, excluded_fields),
        "phase50r_auto_count": len(auto_rows),
        "phase50r_auto_sha256": _projection_hash(auto_rows, excluded_fields),
        "hebrew_aramaic_expression_count": len(hebrew_aramaic_rows),
        "hebrew_aramaic_sha256": _projection_hash(
            hebrew_aramaic_rows, expression_fields
        ),
    }


def validate_database_state(
    connection: sqlite3.Connection,
    schema: str,
    targets: Sequence[Target],
    source: dict[str, SourceEntry],
    phase50r_auto: set[tuple[str, int]],
    source_only_hold: set[str],
    expected_state: str | None,
) -> tuple[str, dict[str, object], dict[str, object]]:
    health = verify_database_health(connection, schema)
    rows = _expression_rows(connection, schema)
    mapping = {
        (str(row["word_id"]), int(row["seq"])): row for row in rows
    }
    if len(mapping) != len(rows):
        raise MigrationError(f"expression identity 중복: {schema}")
    notations: set[str] = set()
    for target in targets:
        row = mapping.get(target.identity)
        if row is None:
            raise MigrationError(f"target row 누락: {schema}: {target.identity}")
        if normalize_strong_number(row["strong_number"]) != target.strong_number:
            raise MigrationError(f"Strong identity mismatch: {schema}: {target.identity}")
        if row["language"] != target.language:
            raise MigrationError(f"language mismatch: {schema}: {target.identity}")
        if row["pronunciation"] != target.expected_current_pronunciation:
            raise MigrationError(f"pronunciation mismatch: {schema}: {target.identity}")
        if row["pronunciation_notation_name"] is not None:
            raise MigrationError(f"notation_name mismatch: {schema}: {target.identity}")
        if row["legacy_pronunciation"] != target.expected_current_pronunciation:
            raise MigrationError(
                f"legacy pronunciation mismatch: {schema}: {target.identity}"
            )
        entry = source.get(target.source_key)
        if entry is None or target.expected_current_pronunciation not in entry.primary:
            raise MigrationError(f"source primary exact 실패: {schema}: {target.identity}")
        notation = str(row["pronunciation_notation"])
        if notation not in {
            target.expected_current_notation,
            target.expected_target_notation,
        }:
            raise MigrationError(f"current notation mismatch: {schema}: {target.identity}")
        notations.add(notation)
    if len(notations) != 1:
        raise MigrationError(f"부분 적용 상태: {schema}: {sorted(notations)}")
    state = (
        "current"
        if notations == {"unknown"}
        else "target"
        if notations == {"strong_dictionary"}
        else "invalid"
    )
    if expected_state is not None and state != expected_state:
        raise MigrationError(
            f"DB target state 불일치: {schema}: expected={expected_state}, actual={state}"
        )

    target_keys = {target.identity for target in targets}
    if target_keys & phase50r_auto:
        raise MigrationError("Phase 50-R auto와 Phase 50-T target 교집합 발생")
    if {target.strong_number for target in targets} & source_only_hold:
        raise MigrationError("Greek source-only hold와 target 교집합 발생")
    if any(target.language in {HEBREW_LANGUAGE, ARAMAIC_LANGUAGE} for target in targets):
        raise MigrationError("Hebrew·Aramaic target 교집합 발생")

    snapshot = capture_snapshot(
        connection, schema, targets, source, phase50r_auto
    )
    if snapshot["target_expression_count"] != TARGET_EXPRESSION_COUNT:
        raise MigrationError(f"target expression count 불일치: {schema}")
    if snapshot["target_word_count"] != TARGET_WORD_COUNT:
        raise MigrationError(f"target word count 불일치: {schema}")
    if snapshot["e4_count"] != EXPECTED_E4_COUNT:
        raise MigrationError(f"Greek E4 count 불일치: {schema}: {snapshot['e4_count']}")
    if snapshot["e5_count"] != EXPECTED_E5_COUNT:
        raise MigrationError(f"Greek E5 count 불일치: {schema}: {snapshot['e5_count']}")
    if snapshot["phase50r_auto_count"] != EXPECTED_PHASE50R_AUTO_COUNT:
        raise MigrationError(
            f"Phase 50-R auto DB count 불일치: {schema}: {snapshot['phase50r_auto_count']}"
        )
    return state, health, snapshot


PARITY_KEYS = (
    "target_expression_count",
    "target_word_count",
    "target_notation_counts",
    "target_immutable_sha256",
    "target_state_sha256",
    "non_target_expression_semantic_sha256",
    "legacy_projection_sha256",
    "strong_projection_count",
    "strong_projection_sha256",
    "e4_count",
    "e4_sha256",
    "e5_count",
    "e5_sha256",
    "phase50r_auto_count",
    "phase50r_auto_sha256",
    "hebrew_aramaic_expression_count",
    "hebrew_aramaic_sha256",
    "notation_counts",
    "hebrew_aramaic_notation_counts",
)


def compare_work_seed_parity(
    work: dict[str, object], seed: dict[str, object]
) -> dict[str, object]:
    differences = [key for key in PARITY_KEYS if work[key] != seed[key]]
    if differences:
        raise MigrationError(f"work·seed projection parity 불일치: {differences}")
    return {
        "exact": True,
        "compared_keys": list(PARITY_KEYS),
        "strong_projection_count": work["strong_projection_count"],
        "strong_projection_sha256": work["strong_projection_sha256"],
        "target_state_sha256": work["target_state_sha256"],
        "non_target_expression_semantic_sha256": work[
            "non_target_expression_semantic_sha256"
        ],
    }


PROTECTION_KEYS = (
    "expression_row_count",
    "word_row_count",
    "target_expression_count",
    "target_word_count",
    "target_immutable_sha256",
    "non_target_expression_sha256",
    "word_table_sha256",
    "legacy_projection_sha256",
    "schema_sha256",
    "change_history_row_count",
    "change_history_sha256",
    "e4_count",
    "e4_sha256",
    "e5_count",
    "e5_sha256",
    "phase50r_auto_count",
    "phase50r_auto_sha256",
    "hebrew_aramaic_expression_count",
    "hebrew_aramaic_sha256",
    "hebrew_aramaic_notation_counts",
)


def verify_protection_unchanged(
    before: dict[str, object], after: dict[str, object], label: str
) -> None:
    changed = [key for key in PROTECTION_KEYS if before[key] != after[key]]
    if changed:
        raise MigrationError(f"보호 projection 변경: {label}: {changed}")
    expected_notation = dict(before["notation_counts"])
    if expected_notation.get("unknown", 0) < TARGET_EXPRESSION_COUNT:
        raise MigrationError(f"notation pre-count가 부족함: {label}")
    expected_notation["unknown"] -= TARGET_EXPRESSION_COUNT
    expected_notation["strong_dictionary"] = (
        expected_notation.get("strong_dictionary", 0) + TARGET_EXPRESSION_COUNT
    )
    expected_notation = {
        key: value for key, value in sorted(expected_notation.items()) if value
    }
    if after["notation_counts"] != expected_notation:
        raise MigrationError(
            f"notation 집계 변화가 190건 unknown→strong_dictionary와 다름: {label}"
        )
    if after["target_notation_counts"] != {
        "strong_dictionary": TARGET_EXPRESSION_COUNT
    }:
        raise MigrationError(f"target post notation 불일치: {label}")


def _load_boundaries(
    manifest_path: Path,
    source_manifest_path: Path,
    source_xml_path: Path,
    phase50r_auto_plan: Path,
    phase50r_exception_manifest: Path,
) -> tuple[
    LoadedManifest,
    dict[str, object],
    dict[str, SourceEntry],
    set[tuple[str, int]],
    set[str],
]:
    manifest = load_input_manifest(manifest_path)
    source_info, source = verify_source_boundary(
        source_manifest_path, source_xml_path, manifest
    )
    auto = load_phase50r_auto_identities(phase50r_auto_plan)
    source_only = load_source_only_hold_strongs(phase50r_exception_manifest)
    return manifest, source_info, source, auto, source_only


def run_dry_run(
    *,
    manifest_path: Path,
    work_db: Path,
    seed_db: Path,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    phase50r_auto_plan: Path = DEFAULT_PHASE50R_AUTO_PLAN,
    phase50r_exception_manifest: Path = DEFAULT_PHASE50R_EXCEPTION_MANIFEST,
) -> dict[str, object]:
    assert_no_sidecars((work_db, seed_db))
    manifest, source_info, source, auto, source_only = _load_boundaries(
        manifest_path,
        source_manifest_path,
        source_xml_path,
        phase50r_auto_plan,
        phase50r_exception_manifest,
    )
    input_hashes = {
        "work": sha256_file(work_db),
        "seed": sha256_file(seed_db),
    }
    work_connection = open_read_only(work_db)
    seed_connection = open_read_only(seed_db)
    try:
        work_state, work_health, work_snapshot = validate_database_state(
            work_connection,
            "main",
            manifest.targets,
            source,
            auto,
            source_only,
            "current",
        )
        seed_state, seed_health, seed_snapshot = validate_database_state(
            seed_connection,
            "main",
            manifest.targets,
            source,
            auto,
            source_only,
            "current",
        )
        parity = compare_work_seed_parity(work_snapshot, seed_snapshot)
    finally:
        work_connection.close()
        seed_connection.close()
    output_hashes = {
        "work": sha256_file(work_db),
        "seed": sha256_file(seed_db),
    }
    assert_no_sidecars((work_db, seed_db))
    if input_hashes != output_hashes:
        raise MigrationError("dry-run 전후 DB SHA가 변경됨")
    return {
        "mode": "dry-run",
        "phase": PHASE,
        "tool_version": TOOL_VERSION,
        "status": "적용 가능 — 변경 예정 190",
        "manifest": {
            "path": manifest_path.as_posix(),
            "sha256": manifest.file_sha256,
            "candidate_projection_sha256": manifest.candidate_projection_sha256,
            "target_word_count": TARGET_WORD_COUNT,
            "target_expression_count": TARGET_EXPRESSION_COUNT,
        },
        "source": source_info,
        "database_sha256_before": input_hashes,
        "database_sha256_after": output_hashes,
        "work": {
            "state": work_state,
            "health": work_health,
            "snapshot": work_snapshot,
        },
        "seed": {
            "state": seed_state,
            "health": seed_health,
            "snapshot": seed_snapshot,
        },
        "parity": parity,
        "sidecar_count": 0,
        "change_count": 0,
        "planned_change_count": TARGET_EXPRESSION_COUNT * 2,
    }


def _same_local_volume(left: Path, right: Path) -> bool:
    left_resolved = left.resolve()
    right_resolved = right.resolve()
    left_drive = os.path.splitdrive(str(left_resolved))[0].casefold()
    right_drive = os.path.splitdrive(str(right_resolved))[0].casefold()
    return left_drive == right_drive and left_resolved.stat().st_dev == right_resolved.stat().st_dev


def _portable_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return str(resolved)


def create_verified_backups(
    work_db: Path, seed_db: Path, backup_root: Path
) -> tuple[Path, dict[str, object]]:
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S_%fZ")
    backup_dir = backup_root / timestamp
    backup_dir.mkdir(parents=True, exist_ok=False)
    result: dict[str, object] = {}
    for label, source in (("work", work_db), ("seed", seed_db)):
        destination = backup_dir / f"reshet_{label}_pre_phase50t.db"
        source_sha = sha256_file(source)
        shutil.copy2(source, destination)
        backup_sha = sha256_file(destination)
        if source_sha != backup_sha:
            raise MigrationError(f"backup byte SHA 불일치: {label}")
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
            "foreign_key_violation_count": health[
                "foreign_key_violation_count"
            ],
        }
    return backup_dir, result


def restore_verified_backups(
    work_db: Path,
    seed_db: Path,
    backup_metadata: dict[str, object],
) -> dict[str, object]:
    restored: dict[str, object] = {}
    for label, target in (("work", work_db), ("seed", seed_db)):
        info = backup_metadata[label]
        if not isinstance(info, dict):
            raise MigrationError(f"backup metadata 누락: {label}")
        backup_path = Path(str(info["backup_path"]))
        if not backup_path.is_absolute():
            backup_path = Path.cwd() / backup_path
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
            "foreign_key_violation_count": health[
                "foreign_key_violation_count"
            ],
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
    expected_sha = sha256_bytes(data)
    if actual_sha != expected_sha:
        raise MigrationError("result manifest atomic write SHA 검증 실패")
    return actual_sha


def _validate_attached_paths(
    connection: sqlite3.Connection, work_db: Path, seed_db: Path
) -> list[dict[str, object]]:
    rows = connection.execute("PRAGMA database_list").fetchall()
    resolved_rows = [
        {"seq": int(row[0]), "name": str(row[1]), "path": str(Path(row[2]).resolve())}
        for row in rows
        if str(row[1]) in {"main", "seed_db"}
    ]
    paths = {
        item["name"]: Path(str(item["path"])).resolve()
        for item in resolved_rows
    }
    if paths.get("main") != work_db.resolve() or paths.get("seed_db") != seed_db.resolve():
        raise MigrationError(f"ATTACH database_list 경로 불일치: {resolved_rows}")
    return [
        {**item, "path": _portable_path(Path(str(item["path"])))}
        for item in resolved_rows
    ]


def _update_targets(
    connection: sqlite3.Connection,
    schema: str,
    targets: Sequence[Target],
    fault_injection: str | None,
) -> int:
    table = _schema_table(schema, "word_expression_set")
    sql = f'''
        UPDATE {table}
        SET pronunciation_notation = 'strong_dictionary'
        WHERE word_id = ?
          AND seq = ?
          AND pronunciation = ?
          AND pronunciation_notation = 'unknown'
          AND pronunciation_notation_name IS NULL
    '''
    changed = 0
    fault_name = "work_update" if schema == "main" else "seed_update"
    for target in targets:
        cursor = connection.execute(
            sql,
            (
                target.word_id,
                target.seq,
                target.expected_current_pronunciation,
            ),
        )
        if cursor.rowcount != 1:
            raise MigrationError(
                f"UPDATE rowcount 불일치: {schema}: {target.identity}: {cursor.rowcount}"
            )
        changed += cursor.rowcount
        if fault_injection == fault_name and changed == 1:
            raise MigrationError(f"test fault injection: {fault_name}")
    if changed != TARGET_EXPRESSION_COUNT:
        raise MigrationError(f"전체 UPDATE rowcount 불일치: {schema}: {changed}")
    return changed


def _result_matches_current_state(
    result_output: Path,
    manifest: LoadedManifest,
    work_db: Path,
    seed_db: Path,
    work_snapshot: dict[str, object],
    seed_snapshot: dict[str, object],
) -> dict[str, object]:
    result = _read_json_object(result_output)
    if result.get("schema_version") != SCHEMA_VERSION or result.get("phase") != PHASE:
        raise MigrationError("matching result manifest schema/phase 불일치")
    if result.get("tool_version") != TOOL_VERSION:
        raise MigrationError("matching result manifest tool_version 불일치")
    if result.get("input_manifest_sha256") != manifest.file_sha256:
        raise MigrationError("matching result input manifest SHA 불일치")
    if (
        result.get("candidate_projection_sha256")
        != manifest.candidate_projection_sha256
    ):
        raise MigrationError("matching result candidate projection SHA 불일치")
    for label, db_path, snapshot in (
        ("work", work_db, work_snapshot),
        ("seed", seed_db, seed_snapshot),
    ):
        section = result.get(label)
        if not isinstance(section, dict):
            raise MigrationError(f"matching result {label} section 누락")
        if section.get("output_sha256") != sha256_file(db_path):
            raise MigrationError(f"matching result {label} output SHA 불일치")
        protection = section.get("protection")
        if not isinstance(protection, dict):
            raise MigrationError(f"matching result {label} protection 누락")
        for result_key, snapshot_key in (
            ("target_immutable_sha256", "target_immutable_sha256"),
            ("non_target_expression_sha256", "non_target_expression_sha256"),
            ("word_table_sha256", "word_table_sha256"),
            ("legacy_projection_sha256", "legacy_projection_sha256"),
            ("schema_sha256", "schema_sha256"),
            ("change_history_sha256", "change_history_sha256"),
        ):
            values = protection.get(result_key)
            if not isinstance(values, dict) or values.get("post") != snapshot[snapshot_key]:
                raise MigrationError(
                    f"matching result {label} protection 불일치: {result_key}"
                )
    return result


def run_apply(
    *,
    manifest_path: Path,
    work_db: Path,
    seed_db: Path,
    backup_root: Path,
    result_output: Path,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
    phase50r_auto_plan: Path = DEFAULT_PHASE50R_AUTO_PLAN,
    phase50r_exception_manifest: Path = DEFAULT_PHASE50R_EXCEPTION_MANIFEST,
    fault_injection: str | None = None,
) -> dict[str, object]:
    if work_db.resolve() == seed_db.resolve():
        raise MigrationError("work와 seed DB 경로가 같음")
    if not _same_local_volume(work_db, seed_db):
        raise MigrationError("work와 seed가 같은 local filesystem/volume이 아님")
    assert_no_sidecars((work_db, seed_db))
    manifest, source_info, source, auto, source_only = _load_boundaries(
        manifest_path,
        source_manifest_path,
        source_xml_path,
        phase50r_auto_plan,
        phase50r_exception_manifest,
    )
    input_hashes = {
        "work": sha256_file(work_db),
        "seed": sha256_file(seed_db),
    }

    work_read = open_read_only(work_db)
    seed_read = open_read_only(seed_db)
    try:
        work_state, work_health_pre, work_pre = validate_database_state(
            work_read,
            "main",
            manifest.targets,
            source,
            auto,
            source_only,
            None,
        )
        seed_state, seed_health_pre, seed_pre = validate_database_state(
            seed_read,
            "main",
            manifest.targets,
            source,
            auto,
            source_only,
            None,
        )
        parity_pre = compare_work_seed_parity(work_pre, seed_pre)
    finally:
        work_read.close()
        seed_read.close()
    if work_state != seed_state:
        raise MigrationError(
            f"work·seed 적용 상태 불일치: work={work_state}, seed={seed_state}"
        )
    if work_state == "target":
        if not result_output.exists():
            raise MigrationError("이미 적용 상태지만 matching result manifest가 없음")
        _result_matches_current_state(
            result_output,
            manifest,
            work_db,
            seed_db,
            work_pre,
            seed_pre,
        )
        assert_no_sidecars((work_db, seed_db))
        return {
            "mode": "apply",
            "phase": PHASE,
            "tool_version": TOOL_VERSION,
            "status": "이미 적용됨 — 변경 0",
            "change_count": 0,
            "database_sha256": input_hashes,
            "result_manifest_path": result_output.as_posix(),
            "result_manifest_sha256": sha256_file(result_output),
            "backup_created": False,
            "transaction_started": False,
            "parity": parity_pre,
        }
    if work_state != "current":
        raise MigrationError(f"지원하지 않는 target state: {work_state}")
    if result_output.exists():
        raise MigrationError("미적용 DB인데 result manifest가 이미 존재함")
    if work_health_pre["journal_mode"] != "delete" or seed_health_pre[
        "journal_mode"
    ] != "delete":
        raise MigrationError("apply 전 journal_mode=delete 조건 불충족")

    backup_dir, backup_metadata = create_verified_backups(
        work_db, seed_db, backup_root
    )
    connection: sqlite3.Connection | None = None
    committed = False
    rollback_error: Exception | None = None
    result_written = False
    try:
        connection = sqlite3.connect(str(work_db.resolve()))
        connection.row_factory = sqlite3.Row
        main_journal = str(connection.execute("PRAGMA main.journal_mode").fetchone()[0]).lower()
        connection.execute("ATTACH DATABASE ? AS seed_db", (str(seed_db.resolve()),))
        seed_journal = str(
            connection.execute("PRAGMA seed_db.journal_mode").fetchone()[0]
        ).lower()
        database_list = _validate_attached_paths(connection, work_db, seed_db)
        if main_journal != "delete" or seed_journal != "delete":
            raise MigrationError(
                f"ATTACH journal_mode 조건 불충족: main={main_journal}, seed={seed_journal}"
            )
        assert_no_sidecars((work_db, seed_db))
        connection.execute("BEGIN IMMEDIATE")
        _, _, work_tx_pre = validate_database_state(
            connection,
            "main",
            manifest.targets,
            source,
            auto,
            source_only,
            "current",
        )
        _, _, seed_tx_pre = validate_database_state(
            connection,
            "seed_db",
            manifest.targets,
            source,
            auto,
            source_only,
            "current",
        )
        compare_work_seed_parity(work_tx_pre, seed_tx_pre)
        if work_tx_pre != work_pre or seed_tx_pre != seed_pre:
            raise MigrationError("transaction 직전 protection snapshot이 변경됨")

        work_changed = _update_targets(
            connection, "main", manifest.targets, fault_injection
        )
        seed_changed = _update_targets(
            connection, "seed_db", manifest.targets, fault_injection
        )
        _, _, work_tx_post = validate_database_state(
            connection,
            "main",
            manifest.targets,
            source,
            auto,
            source_only,
            "target",
        )
        _, _, seed_tx_post = validate_database_state(
            connection,
            "seed_db",
            manifest.targets,
            source,
            auto,
            source_only,
            "target",
        )
        verify_protection_unchanged(work_pre, work_tx_post, "work/transaction")
        verify_protection_unchanged(seed_pre, seed_tx_post, "seed/transaction")
        parity_tx_post = compare_work_seed_parity(work_tx_post, seed_tx_post)
        connection.commit()
        committed = True
        connection.close()
        connection = None

        if fault_injection == "post_commit_validation":
            raise MigrationError("test fault injection: post_commit_validation")

        assert_no_sidecars((work_db, seed_db))
        work_post_read = open_read_only(work_db)
        seed_post_read = open_read_only(seed_db)
        try:
            _, work_health_post, work_post = validate_database_state(
                work_post_read,
                "main",
                manifest.targets,
                source,
                auto,
                source_only,
                "target",
            )
            _, seed_health_post, seed_post = validate_database_state(
                seed_post_read,
                "main",
                manifest.targets,
                source,
                auto,
                source_only,
                "target",
            )
            verify_protection_unchanged(work_pre, work_post, "work/post-commit")
            verify_protection_unchanged(seed_pre, seed_post, "seed/post-commit")
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
            "input_manifest_sha256": manifest.file_sha256,
            "candidate_projection_sha256": manifest.candidate_projection_sha256,
            "source": source_info,
            "target_word_count": TARGET_WORD_COUNT,
            "target_expression_count": TARGET_EXPRESSION_COUNT,
            "change_counts": {
                "work": work_changed,
                "seed": seed_changed,
                "total_database_rows": work_changed + seed_changed,
                "columns_changed": ["word_expression_set.pronunciation_notation"],
            },
            "work": _result_database_section(
                input_hashes["work"],
                output_hashes["work"],
                work_pre,
                work_post,
                work_health_pre,
                work_health_post,
            ),
            "seed": _result_database_section(
                input_hashes["seed"],
                output_hashes["seed"],
                seed_pre,
                seed_post,
                seed_health_pre,
                seed_health_post,
            ),
            "parity_pre": parity_pre,
            "parity_transaction_post": parity_tx_post,
            "parity_post": parity_post,
            "attach": {
                "single_connection_transaction": True,
                "same_local_filesystem_volume": True,
                "journal_mode": {"main": main_journal, "seed_db": seed_journal},
                "database_list": database_list,
            },
            "backup": {
                "directory": _portable_path(backup_dir),
                **backup_metadata,
            },
            "second_run": {
                "status": "already_applied_noop_verified",
                "message": "이미 적용됨 — 변경 0",
                "database_change_count": 0,
                "result_manifest_unchanged": True,
            },
        }
        if fault_injection == "result_write":
            raise MigrationError("test fault injection: result_write")
        result_sha = write_json_atomic(result_output, result_payload)
        result_written = True
        _result_matches_current_state(
            result_output,
            manifest,
            work_db,
            seed_db,
            work_post,
            seed_post,
        )
        return {
            "mode": "apply",
            "phase": PHASE,
            "tool_version": TOOL_VERSION,
            "status": "적용 완료 — work 190, seed 190",
            "change_count": work_changed + seed_changed,
            "work_change_count": work_changed,
            "seed_change_count": seed_changed,
            "database_sha256_before": input_hashes,
            "database_sha256_after": output_hashes,
            "backup_directory": _portable_path(backup_dir),
            "backup": backup_metadata,
            "result_manifest_path": result_output.as_posix(),
            "result_manifest_sha256": result_sha,
            "notation_counts_before": {
                "work": work_pre["notation_counts"],
                "seed": seed_pre["notation_counts"],
            },
            "notation_counts_after": {
                "work": work_post["notation_counts"],
                "seed": seed_post["notation_counts"],
            },
            "parity": parity_post,
        }
    except Exception as error:
        if connection is not None:
            try:
                connection.rollback()
            except Exception as rollback_failure:  # pragma: no cover - rare OS failure
                rollback_error = rollback_failure
            finally:
                connection.close()
        restore_error: Exception | None = None
        restore_result: dict[str, object] | None = None
        try:
            restore_result = restore_verified_backups(
                work_db, seed_db, backup_metadata
            )
        except Exception as restore_failure:  # pragma: no cover - rare OS failure
            restore_error = restore_failure
        if result_written and result_output.exists():
            result_output.unlink()
        details = [f"apply 실패: {error}", f"committed={committed}"]
        if rollback_error is not None:
            details.append(f"rollback 실패={rollback_error}")
        else:
            details.append("rollback 오류 없음")
        if restore_error is not None:
            details.append(f"backup restore 실패={restore_error}")
        else:
            details.append(f"backup restore 성공={restore_result}")
        raise MigrationError("; ".join(details)) from error


def _result_database_section(
    input_sha: str,
    output_sha: str,
    before: dict[str, object],
    after: dict[str, object],
    health_before: dict[str, object],
    health_after: dict[str, object],
) -> dict[str, object]:
    return {
        "input_sha256": input_sha,
        "output_sha256": output_sha,
        "notation_counts": {
            "pre": before["notation_counts"],
            "post": after["notation_counts"],
        },
        "protection": {
            key: {"pre": before[key], "post": after[key]}
            for key in (
                "target_immutable_sha256",
                "non_target_expression_sha256",
                "word_table_sha256",
                "legacy_projection_sha256",
                "schema_sha256",
                "change_history_sha256",
            )
        },
        "counts": {
            key: {"pre": before[key], "post": after[key]}
            for key in (
                "target_word_count",
                "target_expression_count",
                "word_row_count",
                "expression_row_count",
                "change_history_row_count",
                "e4_count",
                "e5_count",
                "phase50r_auto_count",
                "hebrew_aramaic_expression_count",
            )
        },
        "health": {"pre": health_before, "post": health_after},
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Phase 50-T Greek legacy Strong notation metadata migration"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("dry-run", "apply"):
        child = subparsers.add_parser(command)
        child.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
        child.add_argument("--work-db", required=True)
        child.add_argument("--seed-db", required=True)
        child.add_argument(
            "--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST)
        )
        child.add_argument("--source-xml", default=str(DEFAULT_SOURCE_XML))
        child.add_argument(
            "--phase50r-auto-plan", default=str(DEFAULT_PHASE50R_AUTO_PLAN)
        )
        child.add_argument(
            "--phase50r-exception-manifest",
            default=str(DEFAULT_PHASE50R_EXCEPTION_MANIFEST),
        )
        if command == "apply":
            child.add_argument("--backup-root", required=True)
            child.add_argument("--result-output", required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    parser = build_parser()
    args = parser.parse_args(argv)
    common = {
        "manifest_path": Path(args.manifest),
        "work_db": Path(args.work_db),
        "seed_db": Path(args.seed_db),
        "source_manifest_path": Path(args.source_manifest),
        "source_xml_path": Path(args.source_xml),
        "phase50r_auto_plan": Path(args.phase50r_auto_plan),
        "phase50r_exception_manifest": Path(args.phase50r_exception_manifest),
    }
    try:
        if args.command == "dry-run":
            result = run_dry_run(**common)
        else:
            result = run_apply(
                **common,
                backup_root=Path(args.backup_root),
                result_output=Path(args.result_output),
            )
    except MigrationError as error:
        print(f"Phase 50-T 실패: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
