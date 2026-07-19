#!/usr/bin/env python3
"""Phase 50-V Hebrew·Aramaic XML exact pronunciation metadata migration.

The checked-in manifest is the only UPDATE identity authority.  Manifest
generation and dry-run read the active databases with SQLite ``mode=ro`` and
``query_only``.  The apply entry point exists for a later, explicit approval;
it changes only ``word_expression_set.pronunciation_notation``.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import sqlite3
import tempfile
from typing import Iterable, Sequence
import xml.etree.ElementTree as ET


PHASE = "50-V"
SCHEMA_VERSION = 1
TOOL_DIR = Path(__file__).resolve().parent
ROOT_DIR = TOOL_DIR.parent.parent
DEFAULT_MANIFEST = (
    TOOL_DIR / "manifests" / "phase50v_hebrew_aramaic_strong_notation.json"
)
DEFAULT_SOURCE_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_SOURCE_XML = TOOL_DIR / ".source_cache" / "HebrewStrong.xml"
DEFAULT_WORK_DB = ROOT_DIR / "data" / "reshet_work.db"
DEFAULT_SEED_DB = ROOT_DIR / "data" / "reshet_seed.db"
DEFAULT_BACKUP_ROOT = ROOT_DIR / "data" / "backups" / "phase50v"

HEBREW = "히브리어"
ARAMAIC = "아람어"
LANGUAGE_ORDER = {HEBREW: 0, ARAMAIC: 1}
EXPECTED_WORD_COUNTS = {HEBREW: 698, ARAMAIC: 40}
EXPECTED_EXPRESSION_COUNTS = {HEBREW: 730, ARAMAIC: 41}
EXPECTED_WORD_COUNT = 738
EXPECTED_EXPRESSION_COUNT = 771
EXPECTED_HISTORICAL_PHASE50S_COUNT = 756
EXPECTED_XML_ONLY_COUNT = 15
EXPECTED_MANIFEST_FILE_SHA256 = (
    "6b0c0c3c18c1f4142ca6dacbdc9a5742ed8d20e7bea61a0167227406ea0aa9d7"
)
EXPECTED_CANDIDATE_PROJECTION_SHA256 = (
    "ffed5f3c430597b42f5f318b023fe23ac5b09792e4e7a58e04f14266a23b03c8"
)

EXPECTED_SOURCE = {
    "repository": "https://github.com/openscriptures/HebrewLexicon",
    "commit": "21c9add13bc727d3a951361778e97e3ff7afd1ce",
    "path": "HebrewStrong.xml",
    "sha256": "a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4",
    "license": "CC BY 4.0",
    "attribution": "Open Scriptures Hebrew Bible Project",
    "parser_contract": "hebrew_direct_w_v1",
}

PROJECTION_FIELDS = [
    "language",
    "strong_number",
    "word_id",
    "seq",
    "is_representative",
    "expected_current_pronunciation",
    "expected_legacy_pronunciation",
    "expected_current_notation",
    "expected_target_notation",
    "expected_notation_name",
    "source_repository",
    "source_commit",
    "source_path",
    "source_file_sha256",
    "source_key",
    "source_pronunciation",
    "parser_contract",
    "comparison_grade",
    "classification_reason",
    "historical_phase50s_member",
    "xml_only_reason",
    "historical_source_difference",
]

PROJECTION_CONTRACT = {
    "fields": PROJECTION_FIELDS,
    "sort": [
        "language order: 히브리어, 아람어",
        "word_id ASC",
        "seq ASC",
    ],
    "format": "JSONL ordered arrays",
    "encoding": "UTF-8",
    "bom": False,
    "ensure_ascii": False,
    "separators": [",", ":"],
    "final_lf": True,
}

TOP_LEVEL_FIELDS = [
    "schema_version",
    "phase",
    "source",
    "candidate_projection_contract",
    "candidate_projection_sha256",
    "target_word_count",
    "target_expression_count",
    "language_counts",
    "historical_phase50s_expression_count",
    "xml_only_expression_count",
    "targets",
]

XML_ONLY: dict[tuple[str, int], tuple[str, str]] = {
    ("H0217_0000", 1): (
        "xml_dat_pronunciation_difference",
        "XML·DB primary는 oor이고 raw DAT primary는 ore",
    ),
    ("H1325_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H1355_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H2178_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H2920_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H3028_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H3487_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H4481_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H5705_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H5922_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H5972_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H6447_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H6655_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H7229_0000", 1): (
        "dat_language_marker_difference",
        "DB 언어는 히브리어이고 raw DAT는 Aramaic으로 표시",
    ),
    ("H8256_0000", 2): (
        "xml_dat_pronunciation_difference",
        "XML·DB primary는 shik-maw'이고 raw DAT primary는 shaw-kawm'",
    ),
}


class MigrationError(RuntimeError):
    """Fail-closed Phase 50-V validation error."""


@dataclass(frozen=True)
class SourceEntry:
    key: str
    primary_pronunciation: str


@dataclass(frozen=True)
class ParsedSource:
    entries: dict[str, SourceEntry]
    entry_count: int
    direct_w_count: int
    nested_w_excluded_count: int


@dataclass(frozen=True)
class Target:
    language: str
    strong_number: str
    word_id: str
    seq: int
    is_representative: int
    expected_current_pronunciation: str
    expected_legacy_pronunciation: str
    expected_current_notation: str
    expected_target_notation: str
    expected_notation_name: None
    source_repository: str
    source_commit: str
    source_path: str
    source_file_sha256: str
    source_key: str
    source_pronunciation: str
    parser_contract: str
    comparison_grade: str
    classification_reason: str
    historical_phase50s_member: bool
    xml_only_reason: str | None
    historical_source_difference: str | None

    @property
    def identity(self) -> tuple[str, int]:
        return self.word_id, self.seq

    def projection_row(self) -> list[object]:
        return [getattr(self, field) for field in PROJECTION_FIELDS]


@dataclass(frozen=True)
class LoadedManifest:
    payload: dict[str, object]
    targets: tuple[Target, ...]
    file_sha256: str
    candidate_projection_sha256: str


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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


def canonical_json_bytes(payload: object) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n"
    ).encode("utf-8")


def normalize_strong_number(value: object) -> str | None:
    match = re.fullmatch(r"[Hh]\s*0*(\d+)", str(value or "").strip())
    if not match:
        return None
    number = int(match.group(1))
    return f"H{number:04d}" if 1 <= number <= 8674 else None


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def parse_hebrew_source(
    path: Path, expected_entry_count: int = 8674
) -> ParsedSource:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as error:
        raise MigrationError(f"Hebrew XML parsing 실패: {error}") from error
    if _local_name(root.tag) != "lexicon":
        raise MigrationError(f"Hebrew XML root 불일치: {root.tag!r}")

    entries: dict[str, SourceEntry] = {}
    direct_w_count = 0
    nested_w_count = 0
    for entry in [child for child in root if _local_name(child.tag) == "entry"]:
        key = normalize_strong_number(entry.get("id"))
        if key is None:
            raise MigrationError(f"source Strong identity 불일치: {entry.get('id')!r}")
        if key in entries:
            raise MigrationError(f"source entry identity 중복: {key}")
        direct_words = [child for child in entry if _local_name(child.tag) == "w"]
        descendant_words = [
            child
            for child in entry.iter()
            if child is not entry and _local_name(child.tag) == "w"
        ]
        nested_w_count += len(descendant_words) - len(direct_words)
        direct_w_count += len(direct_words)
        if not direct_words:
            raise MigrationError(f"source direct w 누락: {key}")
        candidate_values = [
            (
                (word.text or "").strip(),
                word.get("xlit", ""),
                word.get("pron", ""),
            )
            for word in direct_words
        ]
        if len(candidate_values) != len(set(candidate_values)):
            raise MigrationError(f"source direct w candidate 중복: {key}")
        primary = candidate_values[0][2]
        if not primary:
            raise MigrationError(f"source primary pronunciation 누락: {key}")
        entries[key] = SourceEntry(key, primary)

    if len(entries) != expected_entry_count:
        raise MigrationError(
            f"source entry 수 불일치: {len(entries)} != {expected_entry_count}"
        )
    return ParsedSource(entries, len(entries), direct_w_count, nested_w_count)


def verify_source_boundary(
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> tuple[dict[str, object], ParsedSource]:
    payload = json.loads(source_manifest_path.read_text(encoding="utf-8"))
    sources = payload.get("sources")
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
        "license": source.get("license"),
        "attribution": source.get("required_attribution"),
        "parser_contract": source.get("parser_contract"),
    }
    if actual != EXPECTED_SOURCE:
        raise MigrationError(f"source manifest boundary 불일치: {actual}")
    file_sha = sha256_file(source_xml_path)
    if file_sha != EXPECTED_SOURCE["sha256"]:
        raise MigrationError(f"source file SHA 불일치: {file_sha}")
    parsed = parse_hebrew_source(source_xml_path)
    return {
        **actual,
        "source_manifest_sha256": sha256_file(source_manifest_path),
        "source_xml_sha256": file_sha,
        "entry_count": parsed.entry_count,
        "direct_w_count": parsed.direct_w_count,
        "nested_w_excluded_count": parsed.nested_w_excluded_count,
    }, parsed


def _target_sort_key(target: Target) -> tuple[int, str, int]:
    return LANGUAGE_ORDER[target.language], target.word_id, target.seq


def _target_dict(target: Target) -> dict[str, object]:
    return {field: getattr(target, field) for field in PROJECTION_FIELDS}


def _projection_hash(targets: Sequence[Target]) -> str:
    return jsonl_sha256(target.projection_row() for target in targets)


def _source_payload() -> dict[str, object]:
    return {
        "repository": EXPECTED_SOURCE["repository"],
        "commit": EXPECTED_SOURCE["commit"],
        "path": EXPECTED_SOURCE["path"],
        "sha256": EXPECTED_SOURCE["sha256"],
        "license": EXPECTED_SOURCE["license"],
        "attribution": EXPECTED_SOURCE["attribution"],
        "parser_contract": EXPECTED_SOURCE["parser_contract"],
    }


def _language_counts(targets: Sequence[Target]) -> dict[str, object]:
    result: dict[str, object] = {}
    for language in (HEBREW, ARAMAIC):
        rows = [target for target in targets if target.language == language]
        result[language] = {
            "word_count": len({target.word_id for target in rows}),
            "expression_count": len(rows),
        }
    return result


def _validate_target_contract(targets: Sequence[Target]) -> None:
    if len(targets) != EXPECTED_EXPRESSION_COUNT:
        raise MigrationError(
            f"target expression 수 불일치: {len(targets)} != {EXPECTED_EXPRESSION_COUNT}"
        )
    if len({target.word_id for target in targets}) != EXPECTED_WORD_COUNT:
        raise MigrationError("target word 수 불일치")
    identities = [target.identity for target in targets]
    if len(identities) != len(set(identities)):
        raise MigrationError("manifest identity 중복")
    if list(targets) != sorted(targets, key=_target_sort_key):
        raise MigrationError("manifest target 정렬 불일치")
    counts = _language_counts(targets)
    for language in (HEBREW, ARAMAIC):
        actual = counts[language]
        if actual["word_count"] != EXPECTED_WORD_COUNTS[language]:
            raise MigrationError(f"{language} word 수 불일치")
        if actual["expression_count"] != EXPECTED_EXPRESSION_COUNTS[language]:
            raise MigrationError(f"{language} expression 수 불일치")
    historical = sum(target.historical_phase50s_member for target in targets)
    xml_only = [target for target in targets if not target.historical_phase50s_member]
    if historical != EXPECTED_HISTORICAL_PHASE50S_COUNT:
        raise MigrationError("Phase 50-S 포함 수 불일치")
    if len(xml_only) != EXPECTED_XML_ONLY_COUNT:
        raise MigrationError("XML 전용 수 불일치")
    if {target.identity for target in xml_only} != set(XML_ONLY):
        raise MigrationError("XML 전용 identity 불일치")
    for target in targets:
        if target.language not in LANGUAGE_ORDER:
            raise MigrationError(f"target language 불일치: {target.identity}")
        if normalize_strong_number(target.strong_number) != target.strong_number:
            raise MigrationError(f"target Strong identity 불일치: {target.identity}")
        if target.source_key != target.strong_number:
            raise MigrationError(f"target source_key 불일치: {target.identity}")
        if target.seq not in range(1, 7) or target.is_representative not in {0, 1}:
            raise MigrationError(f"target seq·representative 불일치: {target.identity}")
        if (
            not target.expected_current_pronunciation
            or target.expected_current_pronunciation
            != target.expected_legacy_pronunciation
            or target.expected_current_pronunciation != target.source_pronunciation
        ):
            raise MigrationError(f"target pronunciation exact 계약 불일치: {target.identity}")
        if (
            target.expected_current_notation != "unknown"
            or target.expected_target_notation != "strong_dictionary"
            or target.expected_notation_name is not None
            or target.comparison_grade != "primary_exact"
            or target.classification_reason
            != "XML primary exact; work·seed 및 normalized·legacy exact"
        ):
            raise MigrationError(f"target metadata 계약 불일치: {target.identity}")
        if (
            target.source_repository != EXPECTED_SOURCE["repository"]
            or target.source_commit != EXPECTED_SOURCE["commit"]
            or target.source_path != EXPECTED_SOURCE["path"]
            or target.source_file_sha256 != EXPECTED_SOURCE["sha256"]
            or target.parser_contract != EXPECTED_SOURCE["parser_contract"]
        ):
            raise MigrationError(f"target source boundary 불일치: {target.identity}")
        historical = XML_ONLY.get(target.identity)
        if historical is None:
            if (
                not target.historical_phase50s_member
                or target.xml_only_reason is not None
                or target.historical_source_difference is not None
            ):
                raise MigrationError(f"Phase 50-S member 표시 불일치: {target.identity}")
        elif (
            target.historical_phase50s_member
            or target.xml_only_reason != historical[0]
            or target.historical_source_difference != historical[1]
        ):
            raise MigrationError(f"XML 전용 설명 불일치: {target.identity}")


def load_input_manifest(path: Path = DEFAULT_MANIFEST) -> LoadedManifest:
    raw = path.read_bytes()
    file_sha = hashlib.sha256(raw).hexdigest()
    if file_sha != EXPECTED_MANIFEST_FILE_SHA256:
        raise MigrationError(f"manifest file SHA 불일치: {file_sha}")
    if raw.startswith(b"\xef\xbb\xbf"):
        raise MigrationError("manifest BOM 금지")
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"manifest decoding 실패: {error}") from error
    if not isinstance(payload, dict) or list(payload) != TOP_LEVEL_FIELDS:
        raise MigrationError("manifest top-level field 순서·schema 불일치")
    if canonical_json_bytes(payload) != raw:
        raise MigrationError("manifest canonical 직렬화 불일치")
    if payload["schema_version"] != SCHEMA_VERSION or payload["phase"] != PHASE:
        raise MigrationError("manifest phase·schema 불일치")
    if payload["source"] != _source_payload():
        raise MigrationError("manifest source boundary 불일치")
    if payload["candidate_projection_contract"] != PROJECTION_CONTRACT:
        raise MigrationError("manifest projection contract 불일치")
    raw_targets = payload.get("targets")
    if not isinstance(raw_targets, list):
        raise MigrationError("manifest targets 형식 불일치")
    targets: list[Target] = []
    for item in raw_targets:
        if not isinstance(item, dict) or list(item) != PROJECTION_FIELDS:
            raise MigrationError("manifest target field 순서·schema 불일치")
        targets.append(Target(**item))
    _validate_target_contract(targets)
    projection_sha = _projection_hash(targets)
    if payload["candidate_projection_sha256"] != projection_sha:
        raise MigrationError("manifest candidate projection SHA 불일치")
    if projection_sha != EXPECTED_CANDIDATE_PROJECTION_SHA256:
        raise MigrationError("pinned candidate projection SHA 불일치")
    if payload["target_word_count"] != EXPECTED_WORD_COUNT:
        raise MigrationError("manifest target_word_count 불일치")
    if payload["target_expression_count"] != EXPECTED_EXPRESSION_COUNT:
        raise MigrationError("manifest target_expression_count 불일치")
    if payload["language_counts"] != _language_counts(targets):
        raise MigrationError("manifest language_counts 불일치")
    if (
        payload["historical_phase50s_expression_count"]
        != EXPECTED_HISTORICAL_PHASE50S_COUNT
        or payload["xml_only_expression_count"] != EXPECTED_XML_ONLY_COUNT
    ):
        raise MigrationError("manifest historical relation 수 불일치")
    return LoadedManifest(
        payload=payload,
        targets=tuple(targets),
        file_sha256=file_sha,
        candidate_projection_sha256=projection_sha,
    )


def _sidecar_paths(path: Path) -> tuple[Path, Path, Path]:
    resolved = path.resolve()
    return tuple(Path(str(resolved) + suffix) for suffix in ("-wal", "-shm", "-journal"))


def assert_no_sidecars(paths: Sequence[Path]) -> None:
    active = [str(sidecar) for path in paths for sidecar in _sidecar_paths(path) if sidecar.exists()]
    if active:
        raise MigrationError(f"active SQLite sidecar 발견: {active}")


def _open_read_only(path: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA query_only = ON")
    if int(connection.execute("PRAGMA query_only").fetchone()[0]) != 1:
        connection.close()
        raise MigrationError("SQLite query_only 보장 실패")
    return connection


def _legacy_case(prefix: str, alias: str = "w") -> str:
    return " ".join(
        f'WHEN {seq} THEN {alias}."{prefix}{seq}"' for seq in range(1, 7)
    )


def _load_database(path: Path) -> dict[str, object]:
    connection = _open_read_only(path)
    try:
        integrity = str(connection.execute("PRAGMA integrity_check").fetchone()[0])
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        rows = [
            dict(row)
            for row in connection.execute(
                f'''
                SELECT
                  e.id AS expression_id,
                  w."스트롱넘버" AS strong_number,
                  w."언어" AS language,
                  e.word_id,
                  e.seq,
                  e.is_representative,
                  e.spelling,
                  e.transliteration,
                  e.pronunciation,
                  e.pronunciation_notation,
                  e.pronunciation_notation_name,
                  CASE e.seq {_legacy_case("표기")} ELSE NULL END AS legacy_spelling,
                  CASE e.seq {_legacy_case("음역")} ELSE NULL END AS legacy_transliteration,
                  CASE e.seq {_legacy_case("발음")} ELSE NULL END AS legacy_pronunciation
                FROM word_expression_set AS e
                JOIN WORD_TABLE AS w ON w.id = e.word_id
                ORDER BY e.word_id, e.seq, e.id
                '''
            )
        ]
        schema = connection.execute(
            "SELECT type,name,tbl_name,sql FROM sqlite_master "
            "WHERE name NOT LIKE 'sqlite_%' ORDER BY type,name"
        ).fetchall()
        word_columns = [row[1] for row in connection.execute("PRAGMA table_info(WORD_TABLE)")]
        word_select = ",".join('"' + column.replace('"', '""') + '"' for column in word_columns)
        word_rows = connection.execute(
            f"SELECT {word_select} FROM WORD_TABLE ORDER BY id"
        ).fetchall()
        history_columns = [
            row[1] for row in connection.execute("PRAGMA table_info(CHANGE_HISTORY)")
        ]
        if history_columns:
            history_select = ",".join(
                '"' + column.replace('"', '""') + '"'
                for column in history_columns
            )
            history_rows = connection.execute(
                f"SELECT {history_select} FROM CHANGE_HISTORY ORDER BY rowid"
            ).fetchall()
        else:
            history_rows = []
    finally:
        connection.close()
    if integrity != "ok":
        raise MigrationError(f"integrity_check 실패: {integrity}")
    if foreign_keys:
        raise MigrationError(f"foreign_key_check 위반: {len(foreign_keys)}")
    return {
        "rows": rows,
        "health": {"integrity_check": integrity, "foreign_key_violation_count": 0},
        "schema_sha256": jsonl_sha256([list(row) for row in schema]),
        "word_table_sha256": jsonl_sha256([list(row) for row in word_rows]),
        "change_history_sha256": jsonl_sha256(
            [list(row) for row in history_rows]
        ),
    }


def _candidate_rows(
    rows: Sequence[dict[str, object]],
    source: ParsedSource,
    notation: str,
) -> list[dict[str, object]]:
    result: list[dict[str, object]] = []
    for row in rows:
        strong = normalize_strong_number(row["strong_number"])
        entry = source.entries.get(strong or "")
        if (
            row["language"] in LANGUAGE_ORDER
            and entry is not None
            and row["pronunciation"] is not None
            and row["pronunciation"] == row["legacy_pronunciation"]
            and row["pronunciation"] == entry.primary_pronunciation
            and row["pronunciation_notation"] == notation
            and row["pronunciation_notation_name"] is None
        ):
            copy = dict(row)
            copy["strong_number"] = strong
            result.append(copy)
    return result


def _row_parity_projection(row: dict[str, object]) -> list[object]:
    return [
        normalize_strong_number(row["strong_number"]),
        row["language"],
        row["word_id"],
        row["seq"],
        row["is_representative"],
        row["spelling"],
        row["transliteration"],
        row["pronunciation"],
        row["pronunciation_notation"],
        row["pronunciation_notation_name"],
        row["legacy_spelling"],
        row["legacy_transliteration"],
        row["legacy_pronunciation"],
    ]


def _expression_projection(
    row: dict[str, object], *, include_notation: bool
) -> list[object]:
    values = [
        row["expression_id"],
        normalize_strong_number(row["strong_number"]),
        row["language"],
        row["word_id"],
        row["seq"],
        row["is_representative"],
        row["spelling"],
        row["transliteration"],
        row["pronunciation"],
    ]
    if include_notation:
        values.append(row["pronunciation_notation"])
    values.extend(
        [
            row["pronunciation_notation_name"],
            row["legacy_spelling"],
            row["legacy_transliteration"],
            row["legacy_pronunciation"],
        ]
    )
    return values


def _target_from_row(row: dict[str, object], source: ParsedSource) -> Target:
    strong = normalize_strong_number(row["strong_number"])
    if strong is None:
        raise MigrationError(f"DB Strong identity 불일치: {row['strong_number']!r}")
    identity = str(row["word_id"]), int(row["seq"])
    xml_only = XML_ONLY.get(identity)
    return Target(
        language=str(row["language"]),
        strong_number=strong,
        word_id=str(row["word_id"]),
        seq=int(row["seq"]),
        is_representative=int(row["is_representative"]),
        expected_current_pronunciation=str(row["pronunciation"]),
        expected_legacy_pronunciation=str(row["legacy_pronunciation"]),
        expected_current_notation="unknown",
        expected_target_notation="strong_dictionary",
        expected_notation_name=None,
        source_repository=EXPECTED_SOURCE["repository"],
        source_commit=EXPECTED_SOURCE["commit"],
        source_path=EXPECTED_SOURCE["path"],
        source_file_sha256=EXPECTED_SOURCE["sha256"],
        source_key=strong,
        source_pronunciation=source.entries[strong].primary_pronunciation,
        parser_contract=EXPECTED_SOURCE["parser_contract"],
        comparison_grade="primary_exact",
        classification_reason="XML primary exact; work·seed 및 normalized·legacy exact",
        historical_phase50s_member=xml_only is None,
        xml_only_reason=None if xml_only is None else xml_only[0],
        historical_source_difference=None if xml_only is None else xml_only[1],
    )


def build_manifest_payload(
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> dict[str, object]:
    assert_no_sidecars((work_db, seed_db))
    _, source = verify_source_boundary(source_manifest_path, source_xml_path)
    work = _load_database(work_db)
    seed = _load_database(seed_db)
    work_pre = _candidate_rows(work["rows"], source, "unknown")
    seed_pre = _candidate_rows(seed["rows"], source, "unknown")
    work_post = _candidate_rows(work["rows"], source, "strong_dictionary")
    seed_post = _candidate_rows(seed["rows"], source, "strong_dictionary")
    if len(work_pre) == len(seed_pre) == EXPECTED_EXPRESSION_COUNT:
        work_rows, seed_rows = work_pre, seed_pre
    elif len(work_post) == len(seed_post) == EXPECTED_EXPRESSION_COUNT:
        work_rows, seed_rows = work_post, seed_post
    else:
        raise MigrationError(
            "manifest 생성 DB 상태 불일치: "
            f"work_pre={len(work_pre)}, seed_pre={len(seed_pre)}, "
            f"work_post={len(work_post)}, seed_post={len(seed_post)}"
        )
    if [_row_parity_projection(row) for row in work_rows] != [
        _row_parity_projection(row) for row in seed_rows
    ]:
        raise MigrationError("manifest 생성 work·seed projection parity 불일치")
    targets = sorted(
        (_target_from_row(row, source) for row in work_rows), key=_target_sort_key
    )
    _validate_target_contract(targets)
    payload: dict[str, object] = {
        "schema_version": SCHEMA_VERSION,
        "phase": PHASE,
        "source": _source_payload(),
        "candidate_projection_contract": PROJECTION_CONTRACT,
        "candidate_projection_sha256": _projection_hash(targets),
        "target_word_count": EXPECTED_WORD_COUNT,
        "target_expression_count": EXPECTED_EXPRESSION_COUNT,
        "language_counts": _language_counts(targets),
        "historical_phase50s_expression_count": EXPECTED_HISTORICAL_PHASE50S_COUNT,
        "xml_only_expression_count": EXPECTED_XML_ONLY_COUNT,
        "targets": [_target_dict(target) for target in targets],
    }
    return payload


def write_manifest(payload: dict[str, object], output: Path) -> None:
    raw = canonical_json_bytes(payload)
    projection_sha = str(payload.get("candidate_projection_sha256", ""))
    if projection_sha != EXPECTED_CANDIDATE_PROJECTION_SHA256:
        raise MigrationError("생성 manifest projection SHA 불일치")
    file_sha = hashlib.sha256(raw).hexdigest()
    if file_sha != EXPECTED_MANIFEST_FILE_SHA256:
        raise MigrationError(f"생성 manifest file SHA 불일치: {file_sha}")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(raw)


def _validate_manifest_source(targets: Sequence[Target], source: ParsedSource) -> None:
    for target in targets:
        if (
            target.source_repository != EXPECTED_SOURCE["repository"]
            or target.source_commit != EXPECTED_SOURCE["commit"]
            or target.source_path != EXPECTED_SOURCE["path"]
            or target.source_file_sha256 != EXPECTED_SOURCE["sha256"]
            or target.parser_contract != EXPECTED_SOURCE["parser_contract"]
        ):
            raise MigrationError(f"manifest source metadata 불일치: {target.identity}")
        entry = source.entries.get(target.source_key)
        if entry is None or entry.primary_pronunciation != target.source_pronunciation:
            raise MigrationError(f"manifest source primary 불일치: {target.identity}")


def _validate_database_snapshot(
    label: str,
    database: dict[str, object],
    manifest: LoadedManifest,
    source: ParsedSource,
) -> dict[str, object]:
    rows = database["rows"]
    by_identity: dict[tuple[str, int], dict[str, object]] = {}
    for row in rows:
        identity = str(row["word_id"]), int(row["seq"])
        if identity in by_identity:
            raise MigrationError(f"{label} DB expression identity 중복: {identity}")
        by_identity[identity] = row

    notation_counts: dict[str, int] = {}
    target_rows: list[dict[str, object]] = []
    for target in manifest.targets:
        row = by_identity.get(target.identity)
        if row is None:
            raise MigrationError(f"{label} target identity 누락: {target.identity}")
        actual_strong = normalize_strong_number(row["strong_number"])
        checks = {
            "Strong identity": (actual_strong, target.strong_number),
            "language": (row["language"], target.language),
            "is_representative": (int(row["is_representative"]), target.is_representative),
            "pronunciation": (row["pronunciation"], target.expected_current_pronunciation),
            "legacy pronunciation": (
                row["legacy_pronunciation"],
                target.expected_legacy_pronunciation,
            ),
            "notation_name": (row["pronunciation_notation_name"], None),
        }
        for name, (actual, expected) in checks.items():
            if actual != expected:
                raise MigrationError(
                    f"{label} {name} mismatch: {target.identity}; {actual!r} != {expected!r}"
                )
        entry = source.entries.get(target.source_key)
        if (
            entry is None
            or entry.primary_pronunciation != target.source_pronunciation
            or row["pronunciation"] != entry.primary_pronunciation
        ):
            raise MigrationError(f"{label} source exact mismatch: {target.identity}")
        notation = str(row["pronunciation_notation"])
        notation_counts[notation] = notation_counts.get(notation, 0) + 1
        target_rows.append(row)

    if notation_counts == {"unknown": EXPECTED_EXPRESSION_COUNT}:
        state = "pre_apply"
        expected_changes = EXPECTED_EXPRESSION_COUNT
        expected_notation = "unknown"
    elif notation_counts == {"strong_dictionary": EXPECTED_EXPRESSION_COUNT}:
        state = "post_apply"
        expected_changes = 0
        expected_notation = "strong_dictionary"
    else:
        raise MigrationError(f"{label} current notation 부분·불일치 상태: {notation_counts}")

    recomputed = _candidate_rows(rows, source, expected_notation)
    recomputed_identities = {(str(row["word_id"]), int(row["seq"])) for row in recomputed}
    manifest_identities = {target.identity for target in manifest.targets}
    if recomputed_identities != manifest_identities:
        raise MigrationError(
            f"{label} selector identity diff: "
            f"extra={len(recomputed_identities - manifest_identities)}, "
            f"missing={len(manifest_identities - recomputed_identities)}"
        )

    immutable_rows = [
        [value for index, value in enumerate(_row_parity_projection(row)) if index != 8]
        for row in target_rows
    ]
    target_projection = [_row_parity_projection(row) for row in target_rows]
    target_keys = {target.identity for target in manifest.targets}
    non_target_rows = [
        row
        for row in rows
        if (str(row["word_id"]), int(row["seq"])) not in target_keys
    ]
    legacy_mixed = sum(
        1
        for row in target_rows
        if row["pronunciation_notation"] in {"legacy", "mixed"}
    )
    return {
        "state": state,
        "expected_change_count": expected_changes,
        "target_word_count": len({str(row["word_id"]) for row in target_rows}),
        "target_expression_count": len(target_rows),
        "language_counts": _language_counts(manifest.targets),
        "target_notation_counts": notation_counts,
        "normalized_legacy_diff_count": sum(
            row["pronunciation"] != row["legacy_pronunciation"] for row in target_rows
        ),
        "source_exact_diff_count": sum(
            row["pronunciation"]
            != source.entries[normalize_strong_number(row["strong_number"]) or ""].primary_pronunciation
            for row in target_rows
        ),
        "pronunciation_null_count": sum(row["pronunciation"] is None for row in target_rows),
        "notation_name_non_null_count": sum(
            row["pronunciation_notation_name"] is not None for row in target_rows
        ),
        "legacy_mixed_label_intersection_count": legacy_mixed,
        "greek_phase50r_auto_intersection_count": sum(
            str(row["word_id"]).startswith("G") for row in target_rows
        ),
        "greek_phase50t_intersection_count": sum(
            str(row["word_id"]).startswith("G") for row in target_rows
        ),
        "greek_e4_e5_intersection_count": sum(
            str(row["word_id"]).startswith("G") for row in target_rows
        ),
        "target_projection": target_projection,
        "target_immutable_sha256": jsonl_sha256(immutable_rows),
        "target_identity_count": len(target_keys),
        "schema_sha256": database["schema_sha256"],
        "word_table_sha256": database["word_table_sha256"],
        "change_history_sha256": database["change_history_sha256"],
        "expression_immutable_sha256": jsonl_sha256(
            [_expression_projection(row, include_notation=False) for row in rows]
        ),
        "non_target_expression_sha256": jsonl_sha256(
            [
                _expression_projection(row, include_notation=True)
                for row in non_target_rows
            ]
        ),
        "health": database["health"],
        "metadata_outside_expected_change_count": 0,
    }


def run_dry_run(
    manifest_path: Path = DEFAULT_MANIFEST,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> dict[str, object]:
    paths = (work_db, seed_db)
    assert_no_sidecars(paths)
    before = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    manifest = load_input_manifest(manifest_path)
    source_info, source = verify_source_boundary(source_manifest_path, source_xml_path)
    _validate_manifest_source(manifest.targets, source)
    work = _validate_database_snapshot(
        "work", _load_database(work_db), manifest, source
    )
    seed = _validate_database_snapshot(
        "seed", _load_database(seed_db), manifest, source
    )
    if work["state"] != seed["state"]:
        raise MigrationError("work·seed 적용 상태 불일치")
    if work["target_projection"] != seed["target_projection"]:
        raise MigrationError("work·seed projection parity 불일치")
    work.pop("target_projection")
    seed.pop("target_projection")
    after = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    if before != after:
        raise MigrationError("dry-run 중 DB SHA 변경")
    assert_no_sidecars(paths)
    change_count = int(work["expected_change_count"])
    return {
        "phase": PHASE,
        "status": (
            f"적용 가능 — 변경 예정 {change_count}"
            if change_count
            else "이미 적용됨 — 변경 0"
        ),
        "state": work["state"],
        "manifest_sha256": manifest.file_sha256,
        "candidate_projection_sha256": manifest.candidate_projection_sha256,
        "source": source_info,
        "database_sha256_before": before,
        "database_sha256_after": after,
        "sidecar_count": 0,
        "work": work,
        "seed": seed,
        "parity": {"exact": True, "diff_count": 0},
        "first_run_expected_change_count": change_count,
        "second_run_expected_change_count": 0,
        "metadata_outside_expected_change_count": 0,
    }


def _update_database(path: Path, targets: Sequence[Target]) -> int:
    connection = sqlite3.connect(path)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("BEGIN IMMEDIATE")
        changed = 0
        for target in targets:
            cursor = connection.execute(
                """
                UPDATE word_expression_set
                SET pronunciation_notation = 'strong_dictionary'
                WHERE word_id = ? AND seq = ?
                  AND pronunciation = ?
                  AND pronunciation_notation = 'unknown'
                  AND pronunciation_notation_name IS NULL
                """,
                (
                    target.word_id,
                    target.seq,
                    target.expected_current_pronunciation,
                ),
            )
            if cursor.rowcount != 1:
                raise MigrationError(
                    f"UPDATE rowcount 불일치: {target.identity}; {cursor.rowcount}"
                )
            changed += cursor.rowcount
        connection.commit()
        return changed
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def _restore_backups(
    work_backup: Path,
    seed_backup: Path,
    work_db: Path,
    seed_db: Path,
) -> None:
    shutil.copy2(work_backup, work_db)
    shutil.copy2(seed_backup, seed_db)


def run_apply(
    manifest_path: Path,
    work_db: Path,
    seed_db: Path,
    backup_root: Path,
    result_output: Path | None = None,
    source_manifest_path: Path = DEFAULT_SOURCE_MANIFEST,
    source_xml_path: Path = DEFAULT_SOURCE_XML,
) -> dict[str, object]:
    preflight = run_dry_run(
        manifest_path, work_db, seed_db, source_manifest_path, source_xml_path
    )
    if preflight["state"] == "post_apply":
        return {
            "phase": PHASE,
            "status": "이미 적용됨 — 변경 0",
            "change_count": 0,
            "backup_created": False,
            "transaction_started": False,
        }
    manifest = load_input_manifest(manifest_path)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S_%fZ")
    backup_dir = backup_root / stamp
    backup_dir.mkdir(parents=True, exist_ok=False)
    work_backup = backup_dir / work_db.name
    seed_backup = backup_dir / seed_db.name
    shutil.copy2(work_db, work_backup)
    shutil.copy2(seed_db, seed_backup)
    if sha256_file(work_backup) != sha256_file(work_db) or sha256_file(
        seed_backup
    ) != sha256_file(seed_db):
        raise MigrationError("pre-apply backup SHA 검증 실패")
    try:
        work_changes = _update_database(work_db, manifest.targets)
        seed_changes = _update_database(seed_db, manifest.targets)
        if work_changes != EXPECTED_EXPRESSION_COUNT or seed_changes != EXPECTED_EXPRESSION_COUNT:
            raise MigrationError("apply 변경 수 불일치")
        postflight = run_dry_run(
            manifest_path, work_db, seed_db, source_manifest_path, source_xml_path
        )
        if postflight["state"] != "post_apply":
            raise MigrationError("post-apply state 검증 실패")
        protected_fields = (
            "target_immutable_sha256",
            "non_target_expression_sha256",
            "expression_immutable_sha256",
            "word_table_sha256",
            "change_history_sha256",
            "schema_sha256",
        )
        for label in ("work", "seed"):
            for field in protected_fields:
                if preflight[label][field] != postflight[label][field]:
                    raise MigrationError(
                        f"metadata 외 projection 변경: {label}.{field}"
                    )
        result = {
            "schema_version": 1,
            "phase": PHASE,
            "status": "적용 완료",
            "input_manifest_sha256": manifest.file_sha256,
            "candidate_projection_sha256": manifest.candidate_projection_sha256,
            "work_change_count": work_changes,
            "seed_change_count": seed_changes,
            "columns_changed": ["word_expression_set.pronunciation_notation"],
            "metadata_outside_change_count": 0,
            "backup_directory": str(backup_dir),
            "postflight": postflight,
        }
        if result_output is not None:
            result_output.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(
                dir=result_output.parent, delete=False
            ) as temporary:
                temporary.write(canonical_json_bytes(result))
                temporary_path = Path(temporary.name)
            temporary_path.replace(result_output)
        return result
    except Exception:
        _restore_backups(work_backup, seed_backup, work_db, seed_db)
        raise


def _path(value: str) -> Path:
    return Path(value)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action", choices=("generate-manifest", "dry-run", "apply")
    )
    parser.add_argument("--manifest", type=_path, default=DEFAULT_MANIFEST)
    parser.add_argument("--work-db", type=_path, default=DEFAULT_WORK_DB)
    parser.add_argument("--seed-db", type=_path, default=DEFAULT_SEED_DB)
    parser.add_argument(
        "--source-manifest", type=_path, default=DEFAULT_SOURCE_MANIFEST
    )
    parser.add_argument("--source-xml", type=_path, default=DEFAULT_SOURCE_XML)
    parser.add_argument("--backup-root", type=_path, default=DEFAULT_BACKUP_ROOT)
    parser.add_argument("--result-output", type=_path)
    parser.add_argument(
        "--confirm-active-db-write",
        action="store_true",
        help="apply를 명시적으로 승인한 후에만 사용한다.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.action == "generate-manifest":
            payload = build_manifest_payload(
                args.work_db,
                args.seed_db,
                args.source_manifest,
                args.source_xml,
            )
            write_manifest(payload, args.manifest)
            print(
                "manifest 생성 완료: "
                f"expressions={payload['target_expression_count']}, "
                f"projection_sha={payload['candidate_projection_sha256']}"
            )
            return 0
        if args.action == "dry-run":
            report = run_dry_run(
                args.manifest,
                args.work_db,
                args.seed_db,
                args.source_manifest,
                args.source_xml,
            )
            print(json.dumps(report, ensure_ascii=False, indent=2))
            return 0
        if not args.confirm_active_db_write:
            raise MigrationError("apply에는 --confirm-active-db-write가 필요함")
        report = run_apply(
            args.manifest,
            args.work_db,
            args.seed_db,
            args.backup_root,
            args.result_output,
            args.source_manifest,
            args.source_xml,
        )
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    except (MigrationError, OSError, sqlite3.Error, ValueError) as error:
        print(f"오류: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
