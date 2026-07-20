#!/usr/bin/env python3
"""고정 Strong 원천과 Reshet expression을 word 단위로 read-only 매핑한다."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import sqlite3
import sys
import unicodedata
from urllib.parse import urlparse
from urllib.request import Request, urlopen

import strong_source_diff as legacy


TOOL_VERSION = "1.0.0"
DEFAULT_MANIFEST = Path(__file__).with_name("manifests") / "strong_sources.json"
DEFAULT_CACHE = Path(__file__).with_name(".source_cache")
REQUIRED_SOURCE_FIELDS = {
    "id",
    "language",
    "repository",
    "commit",
    "version",
    "file_path",
    "download_location",
    "sha256",
    "license",
    "license_reference",
    "required_attribution",
    "modification_notice",
    "fields_used",
    "fields_excluded",
    "parser_contract",
}
PARSER_CONTRACTS = {
    "G": {
        "greek_headword_v1": legacy.parse_greek_xml,
        "greek_forms_v2": legacy.parse_greek_xml_v2,
    },
    "H": {
        "hebrew_direct_w_v1": legacy.parse_hebrew_xml,
        "hebrew_forms_v2": legacy.parse_hebrew_xml_v2,
    },
}
DEFAULT_PARSER_CONTRACTS = {
    "G": "greek_headword_v1",
    "H": "hebrew_direct_w_v1",
}
V2_FORM_PARSER_CONTRACTS = {
    "G": "greek_forms_v2",
    "H": "hebrew_forms_v2",
}
V2_MEANING_PROJECTION_CONTRACTS = {
    "G": "greek_meanings_v2",
    "H": "hebrew_meanings_v2",
}
SOURCE_LANGUAGE_MAPPING = {
    "G": "헬라어",
    "heb": "히브리어",
    "arc": "아람어",
    "x-pn": None,
}
MAPPING_RULES = (
    "raw_spelling_exact_pronunciation",
    "nfc_spelling_exact_pronunciation",
    "raw_spelling",
    "nfc_spelling",
)


class ManifestError(RuntimeError):
    """tracked source manifest 계약이 올바르지 않을 때 발생한다."""


@dataclass(frozen=True)
class SourceSpec:
    id: str
    language: str
    repository: str
    commit: str
    version: str | None
    file_path: str
    download_location: str
    sha256: str
    license: str
    license_reference: str
    required_attribution: str | None
    modification_notice: str
    fields_used: tuple[str, ...]
    fields_excluded: tuple[str, ...]
    parser_contract: str
    parser_contracts: tuple[str, ...]
    meaning_projection_contract: str | None


@dataclass(frozen=True)
class MappingExpression:
    word_id: str
    strong_number: str
    language: str
    seq: int
    is_representative: int
    spelling: str
    transliteration: str | None
    pronunciation: str | None
    pronunciation_notation: str | None
    pronunciation_notation_name: str | None


@dataclass
class MappingWord:
    word_id: str
    strong_number: str
    language: str
    expressions: list[MappingExpression] = field(default_factory=list)


@dataclass(frozen=True)
class CandidateRef:
    diagnostic_id: str
    source_ordinal: int
    candidate: legacy.SourceCandidate


@dataclass(frozen=True)
class Pairing:
    candidate: CandidateRef
    expression: MappingExpression
    mapping_rule: str


@dataclass
class WordAnalysis:
    strong_id: str
    word: MappingWord | None
    candidates: list[CandidateRef]
    primary_disposition: str
    reason_codes: list[str]
    pairings: list[Pairing] = field(default_factory=list)
    unmatched_candidates: list[CandidateRef] = field(default_factory=list)
    unmatched_expressions: list[MappingExpression] = field(default_factory=list)


@dataclass
class DatabaseSnapshot:
    path: Path
    words: list[MappingWord]
    projection: list[tuple[object, ...]]
    metadata: dict[str, object]


@dataclass(frozen=True)
class MappingV2Row:
    source_key: str
    source_form_order: int | None
    source_form_role: str | None
    source_language: str | None
    source_spelling: str | None
    source_transliteration: str | None
    source_pronunciation: str | None
    source_meaning_rows: tuple[tuple[int, str], ...]
    xml_context: legacy.SourceXmlContextV2 | None
    current_word_id: str | None
    current_expression_seq: int | None
    expected_expression_seq: int | None
    current_values: dict[str, object] | None
    expected_values: dict[str, object] | None
    action: str
    hold_reason: str | None


def _require_string(source: dict[str, object], field_name: str) -> str:
    value = source[field_name]
    if not isinstance(value, str) or not value:
        raise ManifestError(f"source {field_name}는 비어 있지 않은 문자열이어야 함")
    return value


def _expected_download_location(repository: str, commit: str, file_path: str) -> str:
    parsed = urlparse(repository)
    repository_parts = [part for part in parsed.path.split("/") if part]
    if parsed.scheme != "https" or parsed.netloc != "github.com":
        raise ManifestError(f"공식 GitHub repository URL이 아님: {repository}")
    if len(repository_parts) != 2:
        raise ManifestError(f"repository owner/name 형식이 아님: {repository}")
    owner, name = repository_parts
    if name.endswith(".git"):
        name = name[:-4]
    return (
        f"https://raw.githubusercontent.com/{owner}/{name}/"
        f"{commit}/{file_path}"
    )


def _validate_relative_source_path(file_path: str) -> None:
    path = PurePosixPath(file_path)
    if path.is_absolute() or ".." in path.parts or not path.name:
        raise ManifestError(f"안전하지 않은 source file_path: {file_path!r}")


def load_source_manifest(path: Path) -> tuple[dict[str, object], list[SourceSpec]]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"source manifest를 읽을 수 없음: {path}: {error}") from error
    if not isinstance(raw, dict) or raw.get("schema_version") != 1:
        raise ManifestError("source manifest schema_version은 1이어야 함")
    contract_versions = raw.get("contract_versions")
    if contract_versions is not None and not isinstance(contract_versions, dict):
        raise ManifestError("source manifest contract_versions는 object여야 함")
    raw_sources = raw.get("sources")
    if not isinstance(raw_sources, list) or not raw_sources:
        raise ManifestError("source manifest sources는 비어 있지 않은 배열이어야 함")

    specs: list[SourceSpec] = []
    seen_ids: set[str] = set()
    seen_languages: set[str] = set()
    for raw_source in raw_sources:
        if not isinstance(raw_source, dict):
            raise ManifestError("각 source 항목은 object여야 함")
        missing = sorted(REQUIRED_SOURCE_FIELDS - set(raw_source))
        if missing:
            raise ManifestError(f"source manifest 필수 필드 누락: {missing}")
        source_id = _require_string(raw_source, "id")
        language = _require_string(raw_source, "language")
        repository = _require_string(raw_source, "repository")
        commit = _require_string(raw_source, "commit")
        file_path = _require_string(raw_source, "file_path")
        download_location = _require_string(raw_source, "download_location")
        sha256 = _require_string(raw_source, "sha256").lower()
        license_name = _require_string(raw_source, "license")
        license_reference = _require_string(raw_source, "license_reference")
        modification_notice = _require_string(raw_source, "modification_notice")
        parser_contract = _require_string(raw_source, "parser_contract")
        parser_contracts = raw_source.get("parser_contracts", [parser_contract])
        meaning_projection_contract = raw_source.get("meaning_projection_contract")
        fields_used = raw_source["fields_used"]
        fields_excluded = raw_source["fields_excluded"]
        attribution = raw_source["required_attribution"]
        version = raw_source["version"]

        if source_id in seen_ids:
            raise ManifestError(f"중복 source id: {source_id}")
        if language in seen_languages:
            raise ManifestError(f"중복 source language: {language}")
        if language not in PARSER_CONTRACTS:
            raise ManifestError(f"지원하지 않는 source language: {language}")
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise ManifestError(f"commit은 40자리 Git SHA여야 함: {commit}")
        if not re.fullmatch(r"[0-9a-f]{64}", sha256):
            raise ManifestError(f"sha256은 64자리 소문자 hex여야 함: {sha256}")
        if version is not None and not isinstance(version, str):
            raise ManifestError("version은 문자열 또는 null이어야 함")
        if attribution is not None and not isinstance(attribution, str):
            raise ManifestError("required_attribution은 문자열 또는 null이어야 함")
        if not isinstance(fields_used, list) or not all(
            isinstance(value, str) and value for value in fields_used
        ):
            raise ManifestError("fields_used는 비어 있지 않은 문자열 배열이어야 함")
        if not isinstance(fields_excluded, list) or not all(
            isinstance(value, str) and value for value in fields_excluded
        ):
            raise ManifestError("fields_excluded는 비어 있지 않은 문자열 배열이어야 함")
        if not isinstance(parser_contracts, list) or not all(
            isinstance(value, str) and value for value in parser_contracts
        ):
            raise ManifestError("parser_contracts는 비어 있지 않은 문자열 배열이어야 함")
        if len(parser_contracts) != len(set(parser_contracts)):
            raise ManifestError("parser_contracts에는 중복을 둘 수 없음")
        if meaning_projection_contract is not None and not isinstance(
            meaning_projection_contract, str
        ):
            raise ManifestError("meaning_projection_contract는 문자열 또는 null이어야 함")
        _validate_relative_source_path(file_path)
        expected_location = _expected_download_location(repository, commit, file_path)
        if download_location != expected_location:
            raise ManifestError(
                "download_location이 repository·commit·file_path에서 재구성한 "
                f"공식 URL과 다름: {download_location}"
            )
        expected_contract = DEFAULT_PARSER_CONTRACTS[language]
        if parser_contract != expected_contract:
            raise ManifestError(
                f"{language} parser_contract 불일치: "
                f"expected={expected_contract}, actual={parser_contract}"
            )
        unsupported_contracts = sorted(
            set(parser_contracts) - set(PARSER_CONTRACTS[language])
        )
        if unsupported_contracts:
            raise ManifestError(
                f"{language} 지원하지 않는 parser_contracts: {unsupported_contracts}"
            )
        if parser_contract not in parser_contracts:
            raise ManifestError("parser_contract는 parser_contracts에 포함되어야 함")

        specs.append(
            SourceSpec(
                id=source_id,
                language=language,
                repository=repository,
                commit=commit,
                version=version,
                file_path=file_path,
                download_location=download_location,
                sha256=sha256,
                license=license_name,
                license_reference=license_reference,
                required_attribution=attribution,
                modification_notice=modification_notice,
                fields_used=tuple(fields_used),
                fields_excluded=tuple(fields_excluded),
                parser_contract=parser_contract,
                parser_contracts=tuple(parser_contracts),
                meaning_projection_contract=meaning_projection_contract,
            )
        )
        seen_ids.add(source_id)
        seen_languages.add(language)

    if seen_languages != set(PARSER_CONTRACTS):
        raise ManifestError("source manifest에는 G와 H 원천이 각각 정확히 하나 필요함")
    return raw, sorted(specs, key=lambda spec: spec.language)


def source_cache_path(cache_dir: Path, spec: SourceSpec) -> Path:
    return cache_dir.joinpath(*PurePosixPath(spec.file_path).parts)


def fetch_sources(manifest_path: Path, cache_dir: Path) -> list[dict[str, object]]:
    _, specs = load_source_manifest(manifest_path)
    fetched: list[dict[str, object]] = []
    for spec in specs:
        target = source_cache_path(cache_dir, spec)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_file() and legacy.sha256_file(target) == spec.sha256:
            fetched.append(
                {"id": spec.id, "path": str(target), "status": "already_verified"}
            )
            continue
        temporary = target.with_name(target.name + ".download")
        request = Request(spec.download_location, headers={"User-Agent": "Reshet-Phase50Q"})
        try:
            with urlopen(request, timeout=60) as response, temporary.open("wb") as output:
                for chunk in iter(lambda: response.read(1024 * 1024), b""):
                    output.write(chunk)
            actual_hash = legacy.sha256_file(temporary)
            if actual_hash != spec.sha256:
                raise RuntimeError(
                    f"source hash 불일치: id={spec.id}; "
                    f"expected={spec.sha256}; actual={actual_hash}"
                )
            os.replace(temporary, target)
        finally:
            if temporary.exists():
                temporary.unlink()
        fetched.append({"id": spec.id, "path": str(target), "status": "downloaded"})
    return fetched


def validate_sources(
    manifest_path: Path,
    cache_dir: Path,
) -> tuple[dict[str, object], list[SourceSpec], list[legacy.SourceDataset], list[dict[str, object]]]:
    raw_manifest, specs = load_source_manifest(manifest_path)
    datasets: list[legacy.SourceDataset] = []
    statuses: list[dict[str, object]] = []
    for spec in specs:
        source_path = source_cache_path(cache_dir, spec)
        if not source_path.is_file():
            raise FileNotFoundError(
                f"source cache 파일을 찾을 수 없음: {source_path}; fetch 명령 필요"
            )
        actual_hash = legacy.sha256_file(source_path)
        if actual_hash != spec.sha256:
            raise RuntimeError(
                f"source hash 불일치: id={spec.id}; "
                f"expected={spec.sha256}; actual={actual_hash}"
            )
        parser = PARSER_CONTRACTS[spec.language][spec.parser_contract]
        dataset = parser(source_path)
        datasets.append(dataset)
        statuses.append(
            {
                "id": spec.id,
                "language": spec.language,
                "repository": spec.repository,
                "commit": spec.commit,
                "version": spec.version,
                "file_path": spec.file_path,
                "cache_path": str(source_path.resolve()),
                "expected_sha256": spec.sha256,
                "actual_sha256": actual_hash,
                "hash_verified": True,
                "parser_contract": spec.parser_contract,
                "root_tag": dataset.root_tag,
                "entry_count": dataset.entry_count,
                "candidate_count": dataset.candidate_count,
                "invalid_entry_count": dataset.invalid_entry_count,
                "license": spec.license,
                "required_attribution": spec.required_attribution,
            }
        )
    return raw_manifest, specs, datasets, statuses


def validate_source_projections_v2(
    manifest_path: Path,
    cache_dir: Path,
) -> tuple[
    dict[str, object],
    list[SourceSpec],
    list[legacy.SourceDatasetV2],
    list[dict[str, object]],
]:
    raw_manifest, specs = load_source_manifest(manifest_path)
    datasets: list[legacy.SourceDatasetV2] = []
    statuses: list[dict[str, object]] = []
    for spec in specs:
        parser_contract = V2_FORM_PARSER_CONTRACTS[spec.language]
        meaning_contract = V2_MEANING_PROJECTION_CONTRACTS[spec.language]
        if parser_contract not in spec.parser_contracts:
            raise ManifestError(
                f"{spec.language} v2 parser contract가 manifest에 없음: {parser_contract}"
            )
        if spec.meaning_projection_contract != meaning_contract:
            raise ManifestError(
                f"{spec.language} meaning projection contract 불일치: "
                f"expected={meaning_contract}, actual={spec.meaning_projection_contract}"
            )
        source_path = source_cache_path(cache_dir, spec)
        if not source_path.is_file():
            raise FileNotFoundError(
                f"source cache 파일을 찾을 수 없음: {source_path}; fetch 명령 필요"
            )
        actual_hash = legacy.sha256_file(source_path)
        if actual_hash != spec.sha256:
            raise RuntimeError(
                f"source hash 불일치: id={spec.id}; "
                f"expected={spec.sha256}; actual={actual_hash}"
            )
        parser = PARSER_CONTRACTS[spec.language][parser_contract]
        dataset = parser(source_path)
        if not isinstance(dataset, legacy.SourceDatasetV2):
            raise RuntimeError(f"v2 parser 결과 형식 불일치: {parser_contract}")
        datasets.append(dataset)
        statuses.append(
            {
                "id": spec.id,
                "language": spec.language,
                "repository": spec.repository,
                "commit": spec.commit,
                "file_path": spec.file_path,
                "expected_sha256": spec.sha256,
                "actual_sha256": actual_hash,
                "hash_verified": True,
                "default_parser_contract": spec.parser_contract,
                "form_parser_contract": parser_contract,
                "meaning_projection_contract": meaning_contract,
                "entry_count": dataset.entry_count,
                "form_count": dataset.form_count,
                "meaning_count": dataset.meaning_count,
                "license": spec.license,
                "required_attribution": spec.required_attribution,
            }
        )
    return raw_manifest, specs, datasets, statuses


def load_database_snapshot(path: Path) -> DatabaseSnapshot:
    path = path.resolve()
    if not path.is_file():
        raise FileNotFoundError(f"DB 파일을 찾을 수 없음: {path}")
    before = legacy.file_metadata(path)
    connection, query_only, integrity_check = legacy.open_read_only_database(path)
    try:
        word_columns = connection.execute("PRAGMA table_info(WORD_TABLE)").fetchall()
        graph_default_raw = next(
            (
                row["dflt_value"]
                for row in word_columns
                if str(row["name"]) == "graph_expand_mode"
            ),
            None,
        )
        rows = connection.execute(
            '''
            SELECT
              w.id AS word_id,
              w."스트롱넘버" AS strong_number,
              w."언어" AS language,
              e.seq AS seq,
              e.is_representative AS is_representative,
              e.spelling AS spelling,
              e.transliteration AS transliteration,
              e.pronunciation AS pronunciation,
              e.pronunciation_notation AS pronunciation_notation,
              e.pronunciation_notation_name AS pronunciation_notation_name
            FROM WORD_TABLE AS w
            LEFT JOIN word_expression_set AS e ON e.word_id = w.id
            WHERE w."스트롱넘버" IS NOT NULL
              AND TRIM(w."스트롱넘버") <> ''
            ORDER BY w.id, e.seq
            '''
        ).fetchall()
    finally:
        connection.close()

    words_by_id: dict[str, MappingWord] = {}
    projection: list[tuple[object, ...]] = []
    for row in rows:
        word = words_by_id.setdefault(
            str(row["word_id"]),
            MappingWord(
                word_id=str(row["word_id"]),
                strong_number=str(row["strong_number"] or ""),
                language=str(row["language"] or ""),
            ),
        )
        if row["seq"] is None:
            continue
        expression = MappingExpression(
            word_id=word.word_id,
            strong_number=word.strong_number,
            language=word.language,
            seq=int(row["seq"]),
            is_representative=int(row["is_representative"]),
            spelling=str(row["spelling"]),
            transliteration=row["transliteration"],
            pronunciation=row["pronunciation"],
            pronunciation_notation=row["pronunciation_notation"],
            pronunciation_notation_name=row["pronunciation_notation_name"],
        )
        word.expressions.append(expression)
        projection.append(
            (
                word.word_id,
                word.strong_number,
                word.language,
                expression.seq,
                expression.is_representative,
                expression.spelling,
                expression.transliteration,
                expression.pronunciation,
                expression.pronunciation_notation,
                expression.pronunciation_notation_name,
            )
        )

    after = legacy.file_metadata(path)
    if before != after:
        raise RuntimeError(
            "DB 파일 무결성 변경 감지: 실행 전후 크기, mtime 또는 SHA-256이 다름"
        )
    graph_expand_mode_default = (
        str(graph_default_raw).strip("'\"") if graph_default_raw is not None else None
    )
    metadata = {
        "path": str(path),
        "size_bytes": before["size_bytes"],
        "mtime_utc_before": before["mtime_utc"],
        "mtime_utc_after": after["mtime_utc"],
        "sha256_before": before["sha256"],
        "sha256_after": after["sha256"],
        "unchanged": before == after,
        "query_only": query_only,
        "integrity_check": integrity_check,
        "graph_expand_mode_default": graph_expand_mode_default,
    }
    return DatabaseSnapshot(
        path=path,
        words=list(words_by_id.values()),
        projection=projection,
        metadata=metadata,
    )


def combine_v2_datasets(
    datasets: list[legacy.SourceDatasetV2],
) -> dict[str, legacy.SourceEntryV2]:
    entries: dict[str, legacy.SourceEntryV2] = {}
    for dataset in datasets:
        overlap = set(entries) & set(dataset.entries)
        if overlap:
            raise RuntimeError(f"v2 source key 중복: {sorted(overlap)[:10]}")
        entries.update(dataset.entries)
    return dict(sorted(entries.items()))


def _source_language(entry: legacy.SourceEntryV2) -> str | None:
    return SOURCE_LANGUAGE_MAPPING.get(entry.source_language_code)


def _form_source_values(form: legacy.SourceFormV2) -> dict[str, object]:
    pronunciation = form.pronunciation
    return {
        "spelling": form.spelling,
        "transliteration": form.transliteration,
        "pronunciation": pronunciation,
        "pronunciation_notation": (
            "strong_dictionary" if pronunciation is not None else None
        ),
        "pronunciation_notation_name": None,
        "is_representative": 1 if form.source_document_order == 1 else 0,
    }


def _mapping_expression_values(expression: MappingExpression) -> dict[str, object]:
    return {
        "spelling": expression.spelling,
        "transliteration": expression.transliteration,
        "pronunciation": expression.pronunciation,
        "pronunciation_notation": expression.pronunciation_notation,
        "pronunciation_notation_name": expression.pronunciation_notation_name,
        "is_representative": expression.is_representative,
    }


def _expected_existing_values(
    form: legacy.SourceFormV2,
    expression: MappingExpression | None,
) -> dict[str, object]:
    values = _form_source_values(form)
    if (
        expression is not None
        and expression.transliteration is not None
        and expression.transliteration.strip()
    ):
        values["transliteration"] = expression.transliteration
    return values


def build_mapping_v2(
    entries: dict[str, legacy.SourceEntryV2],
    words: list[MappingWord],
) -> list[MappingV2Row]:
    words_by_strong: dict[str, list[MappingWord]] = defaultdict(list)
    for word in words:
        strong = legacy.normalize_strong_number(word.strong_number)
        if strong is not None:
            words_by_strong[strong].append(word)

    rows: list[MappingV2Row] = []
    for source_key, entry in sorted(entries.items()):
        meanings = tuple((meaning.seq, meaning.text) for meaning in entry.meanings)
        source_language = _source_language(entry)
        targets = sorted(
            words_by_strong.get(source_key, []), key=lambda word: word.word_id
        )
        word = targets[0] if len(targets) == 1 else None
        if not entry.forms:
            rows.append(
                MappingV2Row(
                    source_key=source_key,
                    source_form_order=None,
                    source_form_role=None,
                    source_language=source_language,
                    source_spelling=None,
                    source_transliteration=None,
                    source_pronunciation=None,
                    source_meaning_rows=meanings,
                    xml_context=None,
                    current_word_id=word.word_id if word is not None else None,
                    current_expression_seq=None,
                    expected_expression_seq=None,
                    current_values=None,
                    expected_values=None,
                    action="exclude",
                    hold_reason="source_not_used",
                )
            )
            continue

        for form in entry.forms:
            current_expression = None
            if word is not None:
                current_expression = next(
                    (
                        expression
                        for expression in word.expressions
                        if expression.seq == form.source_document_order
                    ),
                    None,
                )
            current_values = (
                _mapping_expression_values(current_expression)
                if current_expression is not None
                else None
            )
            expected_values = _expected_existing_values(form, current_expression)
            if len(targets) > 1:
                action = "hold"
                hold_reason = "multiple_current_word_targets"
            elif entry.source_language_code == "x-pn":
                action = "hold"
                hold_reason = "source_language_x_pn_unresolved"
            elif source_language is None:
                action = "hold"
                hold_reason = "source_language_unresolved"
            elif word is None:
                action = "insert_word_candidate"
                hold_reason = None
            elif word.language != source_language:
                action = "hold"
                hold_reason = "source_db_language_mismatch_deferred"
            elif current_expression is None:
                action = "insert_expression_candidate"
                hold_reason = None
            elif current_values == expected_values:
                action = "no_change"
                hold_reason = None
            else:
                action = "update_expression_candidate"
                hold_reason = None
            rows.append(
                MappingV2Row(
                    source_key=source_key,
                    source_form_order=form.source_document_order,
                    source_form_role=form.form_role,
                    source_language=source_language,
                    source_spelling=form.spelling,
                    source_transliteration=form.transliteration,
                    source_pronunciation=form.pronunciation,
                    source_meaning_rows=meanings,
                    xml_context=form.xml_context,
                    current_word_id=word.word_id if word is not None else None,
                    current_expression_seq=(
                        current_expression.seq
                        if current_expression is not None
                        else None
                    ),
                    expected_expression_seq=form.source_document_order,
                    current_values=current_values,
                    expected_values=expected_values,
                    action=action,
                    hold_reason=hold_reason,
                )
            )
    return rows


def mapping_v2_row_payload(row: MappingV2Row) -> dict[str, object]:
    context = row.xml_context
    return {
        "source_key": row.source_key,
        "source_form_order": row.source_form_order,
        "source_form_role": row.source_form_role,
        "source_language": row.source_language,
        "source_spelling": row.source_spelling,
        "source_transliteration": row.source_transliteration,
        "source_pronunciation": row.source_pronunciation,
        "source_meaning_rows": [
            {"seq": seq, "text": text} for seq, text in row.source_meaning_rows
        ],
        "xml_context": (
            {
                "source_key": context.source_key,
                "section": context.section,
                "direct_child_position": context.direct_child_position,
                "paired_direct_child_position": context.paired_direct_child_position,
            }
            if context is not None
            else None
        ),
        "current_word_id": row.current_word_id,
        "current_expression_seq": row.current_expression_seq,
        "expected_expression_seq": row.expected_expression_seq,
        "current_values": row.current_values,
        "expected_values": row.expected_values,
        "action": row.action,
        "hold_reason": row.hold_reason,
    }


def build_source_only_import_projections(
    entries: dict[str, legacy.SourceEntryV2],
    words: list[MappingWord],
    graph_expand_mode_default: str,
) -> list[dict[str, object]]:
    if not graph_expand_mode_default:
        raise ValueError("graph_expand_mode canonical default가 필요함")
    represented = {
        strong
        for word in words
        if (strong := legacy.normalize_strong_number(word.strong_number)) is not None
    }
    projections: list[dict[str, object]] = []
    for source_key, entry in sorted(entries.items()):
        if source_key in represented or not entry.forms:
            continue
        language = _source_language(entry)
        if language is None:
            continue
        if len(entry.forms) > 6:
            raise ValueError(f"legacy expression slot 6개 초과: {source_key}")
        if len(entry.meanings) > 7:
            raise ValueError(f"legacy meaning slot 7개 초과: {source_key}")
        expressions = [
            {
                "seq": form.source_document_order,
                "is_representative": 1 if form.source_document_order == 1 else 0,
                "spelling": form.spelling,
                "transliteration": form.transliteration,
                "pronunciation": form.pronunciation,
                "pronunciation_notation": (
                    "strong_dictionary" if form.pronunciation is not None else None
                ),
                "pronunciation_notation_name": None,
            }
            for form in entry.forms
        ]
        meanings = [
            {"seq": meaning.seq, "text": meaning.text}
            for meaning in entry.meanings
        ]
        legacy_expressions: dict[str, object] = {}
        for index in range(1, 7):
            expression = expressions[index - 1] if index <= len(expressions) else None
            legacy_expressions[f"표기{index}"] = (
                expression["spelling"] if expression is not None else None
            )
            legacy_expressions[f"음역{index}"] = (
                expression["transliteration"] if expression is not None else None
            )
            legacy_expressions[f"발음{index}"] = (
                expression["pronunciation"] if expression is not None else None
            )
        legacy_meanings = {
            f"의미{index}": (
                meanings[index - 1]["text"] if index <= len(meanings) else None
            )
            for index in range(1, 8)
        }
        projections.append(
            {
                "source_key": source_key,
                "word_id": f"{source_key}_0000",
                "strong_number": source_key,
                "language": language,
                "source_language_code": entry.source_language_code,
                "note": None,
                "graph_expand_mode": graph_expand_mode_default,
                "expressions": expressions,
                "meanings": meanings,
                "legacy_expression_projection": legacy_expressions,
                "legacy_meaning_projection": legacy_meanings,
                "relations": [],
                "action": "insert_word_candidate",
                "reason": "source_only_clear_language",
            }
        )
    return projections


def serialize_source_only_projections(
    projections: list[dict[str, object]],
) -> bytes:
    ordered = sorted(projections, key=lambda item: str(item["source_key"]))
    lines = [
        json.dumps(
            item,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        for item in ordered
    ]
    return (("\n".join(lines) + "\n") if lines else "").encode("utf-8")


def source_only_projection_sha256(projections: list[dict[str, object]]) -> str:
    return hashlib.sha256(serialize_source_only_projections(projections)).hexdigest()


def source_only_item_sha256(projection: dict[str, object]) -> str:
    return hashlib.sha256(serialize_source_only_projections([projection])).hexdigest()


def compare_database_projections(left_path: Path, right_path: Path) -> dict[str, object]:
    left = load_database_snapshot(left_path)
    right = load_database_snapshot(right_path)
    equal = left.projection == right.projection
    left_only = sorted(set(left.projection) - set(right.projection), key=repr)
    right_only = sorted(set(right.projection) - set(left.projection), key=repr)
    return {
        "semantic_projection_equal": equal,
        "projection_fields": [
            "word_id",
            "strong_number",
            "language",
            "seq",
            "is_representative",
            "spelling",
            "transliteration",
            "pronunciation",
            "pronunciation_notation",
            "pronunciation_notation_name",
        ],
        "left": {**left.metadata, "projection_row_count": len(left.projection)},
        "right": {**right.metadata, "projection_row_count": len(right.projection)},
        "left_only_count": len(left_only),
        "right_only_count": len(right_only),
        "left_only_sample": left_only[:20],
        "right_only_sample": right_only[:20],
    }


def _candidate_tuple(candidate: legacy.SourceCandidate) -> tuple[str, str, str]:
    return candidate.spelling, candidate.transliteration, candidate.pronunciation


def _candidate_id(strong_id: str, candidate: legacy.SourceCandidate) -> str:
    payload = json.dumps(
        _candidate_tuple(candidate), ensure_ascii=False, separators=(",", ":")
    ).encode("utf-8")
    return f"{strong_id}:{hashlib.sha256(payload).hexdigest()[:16]}"


def candidate_refs(
    strong_id: str, candidates: list[legacy.SourceCandidate]
) -> list[CandidateRef]:
    refs = [
        CandidateRef(
            diagnostic_id=_candidate_id(strong_id, candidate),
            source_ordinal=index,
            candidate=candidate,
        )
        for index, candidate in enumerate(candidates, start=1)
    ]
    return sorted(
        refs,
        key=lambda ref: (_candidate_tuple(ref.candidate), ref.diagnostic_id),
    )


def _matches(
    rule: str,
    candidate: legacy.SourceCandidate,
    expression: MappingExpression,
) -> bool:
    raw_spelling = candidate.spelling == expression.spelling
    nfc_spelling = unicodedata.normalize("NFC", candidate.spelling) == unicodedata.normalize(
        "NFC", expression.spelling
    )
    exact_pronunciation = candidate.pronunciation == (expression.pronunciation or "")
    if rule == "raw_spelling_exact_pronunciation":
        return raw_spelling and exact_pronunciation
    if rule == "nfc_spelling_exact_pronunciation":
        return nfc_spelling and exact_pronunciation
    if rule == "raw_spelling":
        return raw_spelling
    if rule == "nfc_spelling":
        return nfc_spelling
    raise ValueError(f"알 수 없는 mapping rule: {rule}")


def deterministic_bijection(
    strong_id: str,
    candidates: list[legacy.SourceCandidate],
    expressions: list[MappingExpression],
) -> tuple[list[Pairing], list[CandidateRef], list[MappingExpression]]:
    refs = candidate_refs(strong_id, candidates)
    remaining_candidates = set(range(len(refs)))
    remaining_expressions = set(range(len(expressions)))
    pairings: list[Pairing] = []

    for rule in MAPPING_RULES:
        while True:
            edges: dict[int, set[int]] = {
                candidate_index: {
                    expression_index
                    for expression_index in remaining_expressions
                    if _matches(
                        rule,
                        refs[candidate_index].candidate,
                        expressions[expression_index],
                    )
                }
                for candidate_index in remaining_candidates
            }
            reverse_edges: dict[int, set[int]] = {
                expression_index: {
                    candidate_index
                    for candidate_index in remaining_candidates
                    if expression_index in edges[candidate_index]
                }
                for expression_index in remaining_expressions
            }
            unique_pairs = [
                (candidate_index, next(iter(matches)))
                for candidate_index, matches in edges.items()
                if len(matches) == 1
                and len(reverse_edges[next(iter(matches))]) == 1
            ]
            if not unique_pairs:
                break
            for candidate_index, expression_index in sorted(
                unique_pairs,
                key=lambda pair: (
                    refs[pair[0]].diagnostic_id,
                    expressions[pair[1]].word_id,
                    expressions[pair[1]].seq,
                ),
            ):
                pairings.append(
                    Pairing(refs[candidate_index], expressions[expression_index], rule)
                )
                remaining_candidates.remove(candidate_index)
                remaining_expressions.remove(expression_index)

    unmatched_candidates = [refs[index] for index in sorted(remaining_candidates)]
    unmatched_expressions = [
        expressions[index]
        for index in sorted(
            remaining_expressions,
            key=lambda index: (expressions[index].word_id, expressions[index].seq),
        )
    ]
    return pairings, unmatched_candidates, unmatched_expressions


def _is_placeholder_strong(value: str) -> bool:
    return bool(re.fullmatch(r"[GHgh]\s*0+", value.strip()))


def _append_reason(reasons: list[str], reason: str) -> None:
    if reason not in reasons:
        reasons.append(reason)


def analyze_word(
    word: MappingWord,
    source_candidates: list[legacy.SourceCandidate] | None,
) -> WordAnalysis:
    raw_strong = word.strong_number
    if _is_placeholder_strong(raw_strong):
        return WordAnalysis(raw_strong, word, [], "hold", ["placeholder"])
    canonical = legacy.normalize_strong_number(raw_strong)
    if canonical is None:
        return WordAnalysis(raw_strong, word, [], "hold", ["invalid_strong_id"])
    if source_candidates is None:
        return WordAnalysis(canonical, word, [], "hold", ["source_entry_missing"])

    refs = candidate_refs(canonical, source_candidates)
    candidate_tuples = [_candidate_tuple(candidate) for candidate in source_candidates]
    if len(candidate_tuples) != len(set(candidate_tuples)):
        return WordAnalysis(
            canonical,
            word,
            refs,
            "exception",
            ["source_duplicate_candidate"],
            unmatched_candidates=refs,
            unmatched_expressions=list(word.expressions),
        )
    if not source_candidates or all(not candidate.spelling for candidate in source_candidates):
        return WordAnalysis(
            canonical,
            word,
            refs,
            "hold",
            ["no_usable_headword"],
            unmatched_candidates=refs,
            unmatched_expressions=list(word.expressions),
        )
    if any(not candidate.spelling for candidate in source_candidates):
        return WordAnalysis(
            canonical,
            word,
            refs,
            "hold",
            ["unsupported_source_structure"],
            unmatched_candidates=refs,
            unmatched_expressions=list(word.expressions),
        )

    reasons: list[str] = []
    representatives = [
        expression for expression in word.expressions if expression.is_representative == 1
    ]
    if len(representatives) != 1 or representatives[0].seq != 1:
        _append_reason(reasons, "multiple_or_missing_representative_integrity_issue")
    if not word.expressions:
        _append_reason(reasons, "expression_structure_change_required")
    if len(source_candidates) != len(word.expressions):
        _append_reason(reasons, "source_db_cardinality_mismatch")
        _append_reason(reasons, "expression_structure_change_required")

    pairings, unmatched_candidates, unmatched_expressions = deterministic_bijection(
        canonical, source_candidates, word.expressions
    )
    if unmatched_candidates or unmatched_expressions:
        _append_reason(reasons, "ambiguous_bijection")
    if unmatched_candidates:
        _append_reason(reasons, "unmatched_source_candidate")
    if unmatched_expressions:
        _append_reason(reasons, "unmatched_db_expression")

    disposition = "exception" if reasons else "auto"
    return WordAnalysis(
        strong_id=canonical,
        word=word,
        candidates=refs,
        primary_disposition=disposition,
        reason_codes=reasons,
        pairings=pairings,
        unmatched_candidates=unmatched_candidates,
        unmatched_expressions=unmatched_expressions,
    )


def analyze_database(
    words: list[MappingWord],
    source_candidates: dict[str, list[legacy.SourceCandidate]],
) -> list[WordAnalysis]:
    analyses = [
        analyze_word(
            word,
            source_candidates.get(legacy.normalize_strong_number(word.strong_number) or ""),
        )
        for word in words
    ]
    words_by_strong: dict[str, list[WordAnalysis]] = defaultdict(list)
    for analysis in analyses:
        canonical = legacy.normalize_strong_number(analysis.strong_id)
        if canonical is not None:
            words_by_strong[canonical].append(analysis)
    for same_strong in words_by_strong.values():
        if len(same_strong) <= 1:
            continue
        for analysis in same_strong:
            analysis.primary_disposition = "exception"
            _append_reason(analysis.reason_codes, "multiple_db_targets_for_strong_id")

    represented = set(words_by_strong)
    for strong_id, candidates in source_candidates.items():
        if strong_id in represented:
            continue
        refs = candidate_refs(strong_id, candidates)
        reasons = ["db_target_missing"]
        if not candidates or all(not candidate.spelling for candidate in candidates):
            reasons.append("no_usable_headword")
        elif any(not candidate.spelling for candidate in candidates):
            reasons.append("unsupported_source_structure")
        candidate_tuples = [_candidate_tuple(candidate) for candidate in candidates]
        if len(candidate_tuples) != len(set(candidate_tuples)):
            reasons.append("source_duplicate_candidate")
        analyses.append(
            WordAnalysis(
                strong_id=strong_id,
                word=None,
                candidates=refs,
                primary_disposition="hold",
                reason_codes=reasons,
                unmatched_candidates=refs,
            )
        )
    return sorted(
        analyses,
        key=lambda analysis: (
            analysis.strong_id,
            analysis.word.word_id if analysis.word else "",
        ),
    )


def build_change(pairing: Pairing) -> dict[str, object]:
    expression = pairing.expression
    source = pairing.candidate.candidate
    source_has_pronunciation = source.pronunciation != ""
    expected_pronunciation = (
        source.pronunciation if source_has_pronunciation else expression.pronunciation
    )
    expected_notation = (
        "strong_dictionary"
        if source_has_pronunciation
        else expression.pronunciation_notation
    )
    expected_notation_name = (
        None if source_has_pronunciation else expression.pronunciation_notation_name
    )
    spelling_change = expression.spelling != source.spelling
    pronunciation_change = expression.pronunciation != expected_pronunciation
    notation_code_change = expression.pronunciation_notation != expected_notation
    notation_name_change = (
        expression.pronunciation_notation_name != expected_notation_name
    )
    notation_change = notation_code_change or notation_name_change
    field_changes: list[str] = []
    if spelling_change:
        field_changes.append("spelling")
    if pronunciation_change:
        field_changes.append("pronunciation")
    if notation_code_change:
        field_changes.append("pronunciation_notation")
    if notation_name_change:
        field_changes.append("pronunciation_notation_name")

    if not source_has_pronunciation:
        classification = "source_pronunciation_missing"
    elif (
        spelling_change
        and unicodedata.normalize("NFC", expression.spelling)
        == unicodedata.normalize("NFC", source.spelling)
        and not pronunciation_change
        and not notation_change
    ):
        classification = "nfc_only_match"
    else:
        change_key = (spelling_change, pronunciation_change, notation_change)
        classifications = {
            (False, False, False): "exact_no_change",
            (True, False, False): "spelling_only_update",
            (False, True, False): "pronunciation_only_update",
            (True, True, False): "spelling_and_pronunciation_update",
            (False, False, True): "notation_only_update",
            (True, False, True): "spelling_and_notation_update",
            (False, True, True): "pronunciation_and_notation_update",
            (True, True, True): "spelling_pronunciation_and_notation_update",
        }
        classification = classifications[change_key]

    return {
        "mapping_rule": pairing.mapping_rule,
        "current_spelling": expression.spelling,
        "source_spelling": source.spelling,
        "current_pronunciation": expression.pronunciation,
        "source_pronunciation": source.pronunciation or None,
        "current_pronunciation_notation": expression.pronunciation_notation,
        "current_pronunciation_notation_name": expression.pronunciation_notation_name,
        "expected_pronunciation": expected_pronunciation,
        "expected_pronunciation_notation": expected_notation,
        "expected_pronunciation_notation_name": expected_notation_name,
        "spelling_change": spelling_change,
        "pronunciation_change": pronunciation_change,
        "notation_change": notation_change,
        "expected_field_changes": field_changes,
        "change_classification": classification,
    }


def _candidate_payload(ref: CandidateRef) -> dict[str, object]:
    return {
        "diagnostic_id": ref.diagnostic_id,
        "source_ordinal": ref.source_ordinal,
        "spelling": ref.candidate.spelling,
        "pronunciation": ref.candidate.pronunciation or None,
    }


def _current_values(expression: MappingExpression) -> dict[str, object]:
    return {
        "spelling": expression.spelling,
        "transliteration": expression.transliteration,
        "pronunciation": expression.pronunciation,
        "pronunciation_notation": expression.pronunciation_notation,
        "pronunciation_notation_name": expression.pronunciation_notation_name,
    }


def build_mapping_plan(analyses: list[WordAnalysis]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for analysis in analyses:
        word = analysis.word
        if word is None:
            rows.append(
                {
                    "strong_id": analysis.strong_id,
                    "word_id": None,
                    "language": analysis.strong_id[:1],
                    "db_seq": None,
                    "is_representative": None,
                    "source_candidate_diagnostic_id": None,
                    "source_candidate_ordinal": None,
                    "mapping_rule": None,
                    "current_values": None,
                    "expected_values": None,
                    "expected_field_changes": [],
                    "change_classification": None,
                    "primary_disposition": analysis.primary_disposition,
                    "reason_codes": analysis.reason_codes,
                }
            )
            continue
        pairing_by_expression = {
            (pairing.expression.word_id, pairing.expression.seq): pairing
            for pairing in analysis.pairings
        }
        expressions = sorted(word.expressions, key=lambda expression: expression.seq)
        if not expressions:
            rows.append(
                {
                    "strong_id": analysis.strong_id,
                    "word_id": word.word_id,
                    "language": word.language,
                    "db_seq": None,
                    "is_representative": None,
                    "source_candidate_diagnostic_id": None,
                    "source_candidate_ordinal": None,
                    "mapping_rule": None,
                    "current_values": None,
                    "expected_values": None,
                    "expected_field_changes": [],
                    "change_classification": None,
                    "primary_disposition": analysis.primary_disposition,
                    "reason_codes": analysis.reason_codes,
                }
            )
            continue
        for expression in expressions:
            pairing = pairing_by_expression.get((expression.word_id, expression.seq))
            if analysis.primary_disposition == "auto" and pairing is not None:
                change = build_change(pairing)
                expected_values = {
                    "spelling": change["source_spelling"],
                    "transliteration": expression.transliteration,
                    "pronunciation": change["expected_pronunciation"],
                    "pronunciation_notation": change[
                        "expected_pronunciation_notation"
                    ],
                    "pronunciation_notation_name": change[
                        "expected_pronunciation_notation_name"
                    ],
                }
                candidate_id = pairing.candidate.diagnostic_id
                source_ordinal = pairing.candidate.source_ordinal
                mapping_rule = pairing.mapping_rule
                field_changes = change["expected_field_changes"]
                classification = change["change_classification"]
            else:
                expected_values = _current_values(expression)
                candidate_id = None
                source_ordinal = None
                mapping_rule = None
                field_changes = []
                classification = None
            rows.append(
                {
                    "strong_id": analysis.strong_id,
                    "word_id": expression.word_id,
                    "language": expression.language,
                    "db_seq": expression.seq,
                    "is_representative": expression.is_representative,
                    "source_candidate_diagnostic_id": candidate_id,
                    "source_candidate_ordinal": source_ordinal,
                    "mapping_rule": mapping_rule,
                    "current_values": _current_values(expression),
                    "expected_values": expected_values,
                    "expected_field_changes": field_changes,
                    "change_classification": classification,
                    "primary_disposition": analysis.primary_disposition,
                    "reason_codes": analysis.reason_codes,
                }
            )
    return rows


def _uncertainty_text(reasons: list[str]) -> str:
    return "자동 변경을 금지한 진단 코드: " + ", ".join(reasons)


def _recommended_follow_up(analysis: WordAnalysis) -> str:
    prefix = analysis.strong_id[:1].upper()
    if analysis.primary_disposition == "hold":
        return "원천·DB 대상 경계 확인 후 별도 tooling 또는 data audit로 분리"
    if prefix == "G":
        return "Greek exception Read-only Audit"
    if prefix == "H":
        return "Hebrew exception Read-only Audit"
    return "deterministic mapping 보완 Tooling Slice"


def build_exception_manifest(
    analyses: list[WordAnalysis], generated_at: str
) -> dict[str, object]:
    items: list[dict[str, object]] = []
    for analysis in analyses:
        if analysis.primary_disposition == "auto":
            continue
        expressions = analysis.word.expressions if analysis.word else []
        items.append(
            {
                "strong_id": analysis.strong_id,
                "word_id": analysis.word.word_id if analysis.word else None,
                "language": (
                    analysis.word.language if analysis.word else analysis.strong_id[:1]
                ),
                "db_expressions": [
                    {
                        "seq": expression.seq,
                        "is_representative": expression.is_representative,
                        "spelling": expression.spelling,
                        "pronunciation": expression.pronunciation,
                        "pronunciation_notation": expression.pronunciation_notation,
                        "pronunciation_notation_name": expression.pronunciation_notation_name,
                    }
                    for expression in sorted(expressions, key=lambda item: item.seq)
                ],
                "source_candidates": [
                    _candidate_payload(candidate) for candidate in analysis.candidates
                ],
                "primary_disposition": analysis.primary_disposition,
                "reason_codes": analysis.reason_codes,
                "uncertainty": _uncertainty_text(analysis.reason_codes),
                "recommended_follow_up": _recommended_follow_up(analysis),
            }
        )
    return {"schema_version": 1, "generated_at_utc": generated_at, "items": items}


def build_summary(
    snapshot: DatabaseSnapshot,
    datasets: list[legacy.SourceDataset],
    analyses: list[WordAnalysis],
    mapping_plan: list[dict[str, object]],
) -> dict[str, object]:
    disposition_counts = Counter(
        analysis.primary_disposition for analysis in analyses
    )
    disposition_by_language: dict[str, Counter[str]] = defaultdict(Counter)
    for analysis in analyses:
        prefix = legacy.normalize_strong_number(analysis.strong_id)
        language = prefix[0] if prefix else "invalid"
        disposition_by_language[language][analysis.primary_disposition] += 1
    mapping_rule_counts = Counter(
        str(row["mapping_rule"])
        for row in mapping_plan
        if row["mapping_rule"] is not None
    )
    classification_counts = Counter(
        str(row["change_classification"])
        for row in mapping_plan
        if row["change_classification"] is not None
    )
    field_change_counts = Counter(
        field_name
        for row in mapping_plan
        for field_name in row["expected_field_changes"]
    )
    reason_code_counts = Counter(
        reason
        for analysis in analyses
        for reason in analysis.reason_codes
    )
    source_multiple_dispositions = Counter(
        analysis.primary_disposition
        for analysis in analyses
        if len(analysis.candidates) > 1
    )
    db_multiple_dispositions = Counter(
        analysis.primary_disposition
        for analysis in analyses
        if analysis.word is not None and len(analysis.word.expressions) > 1
    )
    candidate_map = {
        strong_id: candidates
        for dataset in datasets
        for strong_id, candidates in dataset.candidates.items()
    }
    return {
        "source": {
            "entry_count": sum(dataset.entry_count for dataset in datasets),
            "candidate_count": sum(dataset.candidate_count for dataset in datasets),
            "entry_count_by_language": {
                dataset.prefix: dataset.entry_count for dataset in datasets
            },
            "candidate_count_by_language": {
                dataset.prefix: dataset.candidate_count for dataset in datasets
            },
            "multiple_candidate_entry_count": sum(
                len(candidates) > 1 for candidates in candidate_map.values()
            ),
        },
        "database": {
            "strong_word_count": len(snapshot.words),
            "expression_count": len(snapshot.projection),
            "multiple_expression_word_count": sum(
                len(word.expressions) > 1 for word in snapshot.words
            ),
        },
        "disposition_counts": {
            key: disposition_counts[key] for key in ("auto", "exception", "hold")
        },
        "disposition_counts_by_language": {
            language: {
                key: counts[key] for key in ("auto", "exception", "hold")
            }
            for language, counts in sorted(disposition_by_language.items())
        },
        "mapping_rule_counts": dict(sorted(mapping_rule_counts.items())),
        "change_classification_counts": dict(sorted(classification_counts.items())),
        "expected_field_change_counts": {
            "spelling": field_change_counts["spelling"],
            "pronunciation": field_change_counts["pronunciation"],
            "notation": max(
                field_change_counts["pronunciation_notation"],
                field_change_counts["pronunciation_notation_name"],
            ),
        },
        "reason_code_counts": dict(sorted(reason_code_counts.items())),
        "notation_only_count": classification_counts["notation_only_update"],
        "source_pronunciation_missing_count": classification_counts[
            "source_pronunciation_missing"
        ],
        "cardinality_mismatch_count": sum(
            "source_db_cardinality_mismatch" in analysis.reason_codes
            for analysis in analyses
        ),
        "source_multiple_candidate_count": sum(
            len(analysis.candidates) > 1 for analysis in analyses
        ),
        "source_multiple_candidate_disposition_counts": {
            key: source_multiple_dispositions[key]
            for key in ("auto", "exception", "hold")
        },
        "db_multiple_expression_count": sum(
            analysis.word is not None and len(analysis.word.expressions) > 1
            for analysis in analyses
        ),
        "db_multiple_expression_disposition_counts": {
            key: db_multiple_dispositions[key]
            for key in ("auto", "exception", "hold")
        },
        "placeholder_count": sum(
            "placeholder" in analysis.reason_codes for analysis in analyses
        ),
        "source_only_count": sum(
            "db_target_missing" in analysis.reason_codes for analysis in analyses
        ),
        "db_only_count": sum(
            "source_entry_missing" in analysis.reason_codes for analysis in analyses
        ),
    }


def run_dry_run(
    manifest_path: Path,
    cache_dir: Path,
    db_path: Path,
    output_dir: Path,
) -> dict[str, object]:
    generated_at = datetime.now(timezone.utc).isoformat()
    raw_manifest, _, datasets, source_statuses = validate_sources(
        manifest_path, cache_dir
    )
    snapshot = load_database_snapshot(db_path)
    source_candidates = {
        strong_id: candidates
        for dataset in datasets
        for strong_id, candidates in dataset.candidates.items()
    }
    analyses = analyze_database(snapshot.words, source_candidates)
    mapping_plan = build_mapping_plan(analyses)
    summary = build_summary(snapshot, datasets, analyses, mapping_plan)
    exception_manifest = build_exception_manifest(analyses, generated_at)
    manifest_identity = legacy.sha256_file(manifest_path)
    execution_manifest = {
        "tool_version": TOOL_VERSION,
        "generated_at_utc": generated_at,
        "source_manifest": {
            "path": str(manifest_path.resolve()),
            "schema_version": raw_manifest["schema_version"],
            "sha256": manifest_identity,
        },
        "sources": source_statuses,
        "database": snapshot.metadata,
        "cli_options": {
            "source_manifest": str(manifest_path.resolve()),
            "source_cache": str(cache_dir.resolve()),
            "db": str(db_path.resolve()),
            "output_dir": str(output_dir.resolve()),
        },
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "manifest.json").write_text(
        json.dumps(execution_manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output_dir / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    with (output_dir / "mapping_plan.jsonl").open("w", encoding="utf-8") as output:
        for row in mapping_plan:
            output.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")
    (output_dir / "exception_manifest.json").write_text(
        json.dumps(
            exception_manifest,
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n",
        encoding="utf-8",
    )
    return {
        "manifest": execution_manifest,
        "summary": summary,
        "mapping_plan": mapping_plan,
        "exception_manifest": exception_manifest,
        "analyses": analyses,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="고정 Strong 원천의 word 단위 결정적 read-only mapping 도구"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_source_options(command: argparse.ArgumentParser) -> None:
        command.add_argument(
            "--source-manifest", default=str(DEFAULT_MANIFEST), help="tracked source manifest"
        )
        command.add_argument(
            "--source-cache", default=str(DEFAULT_CACHE), help="ignored local source cache"
        )

    fetch = subparsers.add_parser("fetch", help="manifest의 고정 URL에서 source 확보")
    add_source_options(fetch)

    validate = subparsers.add_parser("validate", help="source hash와 parser schema 검증")
    add_source_options(validate)

    dry_run = subparsers.add_parser("dry-run", help="한 DB의 read-only mapping plan 생성")
    add_source_options(dry_run)
    dry_run.add_argument("--db", required=True)
    dry_run.add_argument("--output-dir", required=True)

    parity = subparsers.add_parser("parity", help="두 DB의 Strong 의미 projection 비교")
    parity.add_argument("--left-db", required=True)
    parity.add_argument("--right-db", required=True)
    parity.add_argument("--output")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "fetch":
            result = fetch_sources(Path(args.source_manifest), Path(args.source_cache))
            print(json.dumps(result, ensure_ascii=False, indent=2))
        elif args.command == "validate":
            _, _, _, statuses = validate_sources(
                Path(args.source_manifest), Path(args.source_cache)
            )
            print(json.dumps(statuses, ensure_ascii=False, indent=2))
        elif args.command == "dry-run":
            result = run_dry_run(
                Path(args.source_manifest),
                Path(args.source_cache),
                Path(args.db),
                Path(args.output_dir),
            )
            counts = result["summary"]["disposition_counts"]
            print(
                "dry-run 완료: "
                f"auto={counts['auto']}, exception={counts['exception']}, "
                f"hold={counts['hold']}, output={Path(args.output_dir)}"
            )
        elif args.command == "parity":
            result = compare_database_projections(
                Path(args.left_db), Path(args.right_db)
            )
            payload = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
            if args.output:
                Path(args.output).write_text(payload, encoding="utf-8")
            print(payload, end="")
            if not result["semantic_projection_equal"]:
                return 1
        else:
            parser.error(f"지원하지 않는 command: {args.command}")
    except (
        FileNotFoundError,
        ManifestError,
        OSError,
        RuntimeError,
        sqlite3.Error,
        legacy.SourceSchemaError,
        ValueError,
    ) as error:
        print(f"오류: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
