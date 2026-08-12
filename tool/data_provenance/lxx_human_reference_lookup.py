#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import sys

from biblical_research_evidence_packet import BOOK_NUMBER_BY_NAME


DEFAULT_MANIFEST = (
    Path(__file__).resolve().parent
    / "manifests"
    / "lxx_human_reference_source.json"
)

MANIFEST_SCHEMA_VERSION = 1
OUTPUT_SCHEMA_VERSION = 1
SOURCE_ID = "bethlehem_bible_lxxstp_human_reference"
SOURCE_FILENAME = "LXXStp.bdb"
SOURCE_ROLE = "human_reference"
PROVENANCE_STATUS = "unverified"
PARSER_CONTRACT = "bible_table_explicit_verse_text_v1"

BOUNDARY_MARKERS = (
    "human_reference",
    "provenance_unverified",
    "not_canonical_evidence",
    "manual_review_required",
)
PERMITTED_APPLICATION_BOUNDARY = (
    "explicit_verse_lookup_only",
    "local_read_only_access",
    "manual_review_required",
)
PROHIBITED_USES = (
    "canonical_occurrence_counting",
    "automatic_verse_mapping",
    "automatic_lemma_or_morphology_inference",
    "automatic_hebrew_greek_alignment",
    "bulk_import",
    "reshet_db_corpus_replication",
)
ORIGIN_CONTRACT = {
    "label": "Bethlehem Bible",
    "confirmation": "user_confirmed",
}
PROVENANCE_CONTRACT = {
    "status": PROVENANCE_STATUS,
    "upstream_provenance_verified": False,
}
LICENSE_CONTRACT = {
    "status": "unverified",
    "upstream_license_verified": False,
}
SQLITE_CONTRACT = {
    "table": "Bible",
    "columns": [
        {
            "name": "id",
            "declared_type": "INTEGER",
            "primary_key_position": 1,
        },
        {
            "name": "book",
            "declared_type": "INTEGER",
            "primary_key_position": 0,
        },
        {
            "name": "chapter",
            "declared_type": "INTEGER",
            "primary_key_position": 0,
        },
        {
            "name": "verse",
            "declared_type": "INTEGER",
            "primary_key_position": 0,
        },
        {
            "name": "btext",
            "declared_type": "VARCHAR",
            "primary_key_position": 0,
        },
    ],
}


class LookupError(RuntimeError):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class SourceSpec:
    source_id: str
    filename: str
    expected_sha256: str
    expected_size_bytes: int


@dataclass(frozen=True)
class RequestedReference:
    book: str
    book_number: int
    chapter: int
    verse: int

    @property
    def display(self) -> str:
        return f"{self.book} {self.chapter}:{self.verse}"


def _require_object(value: object, label: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise LookupError("manifest_invalid", f"manifest {label} 객체가 필요함")
    return value


def _require_exact(
    source: dict[str, object],
    key: str,
    expected: object,
) -> None:
    if source.get(key) != expected:
        raise LookupError(
            "manifest_boundary_mismatch",
            f"manifest {key} Human Reference 경계 불일치",
        )


def load_manifest(path: Path = DEFAULT_MANIFEST) -> SourceSpec:
    if not path.is_file():
        raise LookupError("manifest_missing", f"manifest 파일을 찾을 수 없음: {path.name}")
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise LookupError(
            "manifest_invalid", f"manifest를 읽거나 해석할 수 없음: {path.name}"
        ) from error

    manifest = _require_object(raw, "root")
    if manifest.get("schema_version") != MANIFEST_SCHEMA_VERSION:
        raise LookupError("manifest_invalid", "manifest schema_version 불일치")
    source = _require_object(manifest.get("source"), "source")

    _require_exact(source, "id", SOURCE_ID)
    _require_exact(source, "filename", SOURCE_FILENAME)
    _require_exact(source, "origin", ORIGIN_CONTRACT)
    _require_exact(source, "provenance", PROVENANCE_CONTRACT)
    _require_exact(source, "license", LICENSE_CONTRACT)
    _require_exact(source, "role", SOURCE_ROLE)
    _require_exact(source, "canonical_evidence", False)
    _require_exact(source, "automatic_alignment_source", False)
    _require_exact(source, "manual_review_required", True)
    _require_exact(source, "parser_contract", PARSER_CONTRACT)
    _require_exact(source, "sqlite_contract", SQLITE_CONTRACT)
    _require_exact(
        source,
        "permitted_application_boundary",
        list(PERMITTED_APPLICATION_BOUNDARY),
    )
    _require_exact(source, "prohibited_uses", list(PROHIBITED_USES))

    expected_sha256 = source.get("expected_sha256")
    if not isinstance(expected_sha256, str) or re.fullmatch(
        r"[0-9a-f]{64}", expected_sha256
    ) is None:
        raise LookupError("manifest_invalid", "manifest expected_sha256 형식 불일치")
    expected_size_bytes = source.get("expected_size_bytes")
    if type(expected_size_bytes) is not int or expected_size_bytes <= 0:
        raise LookupError("manifest_invalid", "manifest expected_size_bytes 형식 불일치")

    return SourceSpec(
        source_id=SOURCE_ID,
        filename=SOURCE_FILENAME,
        expected_sha256=expected_sha256,
        expected_size_bytes=expected_size_bytes,
    )


def parse_reference(value: str) -> RequestedReference:
    match = re.fullmatch(r"([1-3A-Za-z]+)\s+([0-9]+):([0-9]+)", value.strip())
    if match is None:
        raise LookupError(
            "request_invalid",
            "reference 형식은 'Joshua 22:24'처럼 입력해야 함",
        )
    book = match.group(1)
    book_number = BOOK_NUMBER_BY_NAME.get(book)
    if book_number is None:
        raise LookupError("request_invalid", f"지원하지 않는 canonical book 이름: {book}")
    chapter = int(match.group(2))
    verse = int(match.group(3))
    if chapter < 1:
        raise LookupError("request_invalid", "chapter는 1 이상이어야 함")
    return RequestedReference(
        book=book,
        book_number=book_number,
        chapter=chapter,
        verse=verse,
    )


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    try:
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError as error:
        raise LookupError(
            "source_read_failed", f"source 파일을 읽을 수 없음: {path.name}"
        ) from error
    return digest.hexdigest()


def _open_sqlite_read_only(path: Path) -> sqlite3.Connection:
    uri = path.resolve().as_uri() + "?mode=ro&immutable=1"
    try:
        connection = sqlite3.connect(uri, uri=True)
    except sqlite3.Error as error:
        raise LookupError(
            "source_open_failed", f"SQLite read-only open 실패: {path.name}"
        ) from error
    connection.row_factory = sqlite3.Row
    try:
        connection.execute("PRAGMA query_only = ON")
        query_only = int(connection.execute("PRAGMA query_only").fetchone()[0])
    except sqlite3.Error as error:
        connection.close()
        raise LookupError(
            "source_query_only_failed", f"SQLite query_only 설정 실패: {path.name}"
        ) from error
    if query_only != 1:
        connection.close()
        raise LookupError(
            "source_query_only_failed", f"SQLite query_only 보장 실패: {path.name}"
        )
    return connection


def _validate_schema(connection: sqlite3.Connection) -> None:
    try:
        table = connection.execute(
            "SELECT name, type FROM sqlite_master WHERE name = ?",
            (SQLITE_CONTRACT["table"],),
        ).fetchone()
        if table is None or table["type"] != "table":
            raise LookupError("source_schema_mismatch", "Bible table 계약 불일치")
        rows = connection.execute('PRAGMA table_info("Bible")').fetchall()
    except sqlite3.Error as error:
        raise LookupError(
            "source_schema_mismatch", "Bible schema를 확인할 수 없음"
        ) from error
    actual_columns = [
        {
            "name": str(row["name"]),
            "declared_type": str(row["type"]).upper(),
            "primary_key_position": int(row["pk"]),
        }
        for row in rows
    ]
    if actual_columns != SQLITE_CONTRACT["columns"]:
        raise LookupError("source_schema_mismatch", "Bible column 계약 불일치")


def _validate_source(
    spec: SourceSpec,
    source_dir: Path,
) -> tuple[sqlite3.Connection, dict[str, object]]:
    if not source_dir.is_dir():
        raise LookupError("source_directory_missing", "local source 디렉터리를 찾을 수 없음")
    source_path = source_dir / spec.filename
    if not source_path.is_file():
        raise LookupError("source_file_missing", f"source 파일을 찾을 수 없음: {spec.filename}")
    try:
        actual_size = source_path.stat().st_size
    except OSError as error:
        raise LookupError(
            "source_read_failed", f"source metadata를 읽을 수 없음: {spec.filename}"
        ) from error
    if actual_size != spec.expected_size_bytes:
        raise LookupError(
            "source_size_mismatch",
            f"source size 불일치: expected={spec.expected_size_bytes}; "
            f"actual={actual_size}",
        )
    actual_sha256 = _sha256_file(source_path)
    if actual_sha256 != spec.expected_sha256:
        raise LookupError(
            "source_hash_mismatch",
            f"source SHA-256 불일치: expected={spec.expected_sha256}; "
            f"actual={actual_sha256}",
        )

    connection = _open_sqlite_read_only(source_path)
    try:
        _validate_schema(connection)
    except Exception:
        connection.close()
        raise
    identity = {
        "filename": spec.filename,
        "manifest_identity_verified": True,
        "schema_contract_verified": True,
        "sha256": actual_sha256,
        "size_bytes": actual_size,
        "sqlite_immutable": True,
        "sqlite_query_only": True,
        "sqlite_read_only": True,
    }
    return connection, identity


def _base_result(
    spec: SourceSpec,
    requested: RequestedReference,
    identity: dict[str, object],
) -> dict[str, object]:
    return {
        "boundary_markers": list(BOUNDARY_MARKERS),
        "lookup_policy": {
            "automatic_mapping": False,
            "explicit_reference_only": True,
            "text_search_fallback": False,
        },
        "lookup_status": "unmatched",
        "raw_greek_verse_text": None,
        "requested_reference": {
            "book": requested.book,
            "book_number": requested.book_number,
            "chapter": requested.chapter,
            "display": requested.display,
            "verse": requested.verse,
        },
        "schema_version": OUTPUT_SCHEMA_VERSION,
        "source": {
            "automatic_alignment_source": False,
            "canonical_evidence": False,
            "id": spec.source_id,
            "license_status": "unverified",
            "manual_review_required": True,
            "provenance_status": PROVENANCE_STATUS,
            "role": SOURCE_ROLE,
        },
        "source_identity": identity,
        "source_row_identity": None,
    }


def _row_is_valid(row: sqlite3.Row, requested: RequestedReference) -> bool:
    return (
        type(row["id"]) is int
        and row["id"] > 0
        and type(row["book"]) is int
        and row["book"] == requested.book_number
        and type(row["chapter"]) is int
        and row["chapter"] == requested.chapter
        and type(row["verse"]) is int
        and row["verse"] == requested.verse
        and isinstance(row["btext"], str)
        and bool(row["btext"].strip())
    )


def lookup_reference(
    reference: str,
    *,
    source_dir: Path,
    manifest_path: Path = DEFAULT_MANIFEST,
) -> dict[str, object]:
    requested = parse_reference(reference)
    spec = load_manifest(manifest_path)
    connection, identity = _validate_source(spec, source_dir)
    try:
        rows = connection.execute(
            """
            SELECT id, book, chapter, verse, btext
            FROM Bible
            WHERE book = ? AND chapter = ? AND verse = ?
            ORDER BY id
            LIMIT 2
            """,
            (requested.book_number, requested.chapter, requested.verse),
        ).fetchall()
    except sqlite3.Error as error:
        raise LookupError("source_query_failed", "explicit verse SELECT 실패") from error
    finally:
        connection.close()

    result = _base_result(spec, requested, identity)
    if not rows:
        return result
    if len(rows) > 1:
        result["lookup_status"] = "duplicate_reference"
        return result
    row = rows[0]
    if not _row_is_valid(row, requested):
        result["lookup_status"] = "malformed_source_row"
        return result
    result["lookup_status"] = "matched"
    result["raw_greek_verse_text"] = row["btext"]
    result["source_row_identity"] = {
        "book_number": row["book"],
        "chapter": row["chapter"],
        "id": row["id"],
        "verse": row["verse"],
    }
    return result


def serialize_result(result: dict[str, object]) -> bytes:
    return (
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def serialize_error(error: LookupError) -> bytes:
    lookup_status = (
        "request_invalid"
        if error.code == "request_invalid"
        else "source_validation_failed"
    )
    return serialize_result(
        {
            "error": {"code": error.code, "message": str(error)},
            "lookup_status": lookup_status,
            "schema_version": OUTPUT_SCHEMA_VERSION,
        }
    )


def exit_code_for_result(result: dict[str, object]) -> int:
    return 0 if result.get("lookup_status") in {"matched", "unmatched"} else 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "LXXStp.bdb에서 사람이 명시한 한 verse만 Human Reference로 조회합니다."
        )
    )
    parser.add_argument("reference", help="Joshua 22:24 형식의 명시적 verse")
    parser.add_argument(
        "--local-sources",
        type=Path,
        required=True,
        help="LXXStp.bdb가 있는 로컬 연구 source 디렉터리",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help="Human Reference source manifest 경로",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        result = lookup_reference(
            args.reference,
            source_dir=args.local_sources,
            manifest_path=args.manifest,
        )
    except LookupError as error:
        sys.stderr.buffer.write(serialize_error(error))
        return 2
    sys.stdout.buffer.write(serialize_result(result))
    return exit_code_for_result(result)


if __name__ == "__main__":
    raise SystemExit(main())
