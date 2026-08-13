#!/usr/bin/env python3
"""Strong 하나의 성경 어휘 연구 Evidence Packet을 결정적 JSON으로 생성한다."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import sqlite3
import subprocess
import sys
import xml.etree.ElementTree as ET
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

import strong_source_diff as legacy
import strong_source_mapping as strong_mapping


TOOL_VERSION = "1.2.0"
TOOL_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = TOOL_DIR.parent.parent
DEFAULT_STRONG_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_OCCURRENCE_MANIFEST = (
    TOOL_DIR / "manifests" / "biblical_occurrence_sources.json"
)
DEFAULT_LOCAL_MANIFEST = (
    TOOL_DIR / "manifests" / "local_research_reference_sources.json"
)
DEFAULT_APPROVED_MANIFEST = (
    TOOL_DIR / "manifests" / "p2_approved_content_slice.json"
)
APPROVED_MANIFEST_FILENAME_RE = re.compile(
    r"^[a-z0-9][a-z0-9_]*_approved_content_slice\.json$"
)
APPROVED_BATCH_ID_SUFFIX = "-APPROVED-CONTENT-SLICE"
DEFAULT_SOURCE_ONLY_MANIFEST = (
    TOOL_DIR / "manifests" / "phase50w_hebrew20_source_import.json"
)
DEFAULT_CACHE = TOOL_DIR / ".source_cache"
DEFAULT_WORK_DB = REPOSITORY_ROOT / "data" / "reshet_work.db"

SUPPORTED_OCCURRENCE_CONTRACTS = {
    "oshb_wlc_osis_v1",
    "tagnt_tsv_na27_28_v1",
}
LOCAL_SOURCE_PROFILES = {
    "HebGrkKo.dct": (
        "hebgrkko_lexicon",
        "lexicon_scode_dtext_v1",
        "not_applicable",
    ),
    "KJV_S.sdb": ("kjv", "strong_tagged_bible_v1", "kjv"),
    "개역개정S.sdb": (
        "korean_revised",
        "strong_tagged_bible_v1",
        "unverified",
    ),
    "개역한글S.sdb": (
        "korean_revised_legacy",
        "strong_tagged_bible_v1",
        "unverified",
    ),
    "새번역.bdb": (
        "korean_new_translation",
        "verse_only_bible_v1",
        "unverified",
    ),
    "원전분해.sdb": (
        "original_language_analysis",
        "original_analysis_v1",
        "unverified",
    ),
}

BOOK_SPECS = (
    (1, "Genesis", "Gen"),
    (2, "Exodus", "Exod"),
    (3, "Leviticus", "Lev"),
    (4, "Numbers", "Num"),
    (5, "Deuteronomy", "Deut"),
    (6, "Joshua", "Josh"),
    (7, "Judges", "Judg"),
    (8, "Ruth", "Ruth"),
    (9, "1Samuel", "1Sam"),
    (10, "2Samuel", "2Sam"),
    (11, "1Kings", "1Kgs"),
    (12, "2Kings", "2Kgs"),
    (13, "1Chronicles", "1Chr"),
    (14, "2Chronicles", "2Chr"),
    (15, "Ezra", "Ezra"),
    (16, "Nehemiah", "Neh"),
    (17, "Esther", "Esth"),
    (18, "Job", "Job"),
    (19, "Psalms", "Ps"),
    (20, "Proverbs", "Prov"),
    (21, "Ecclesiastes", "Eccl"),
    (22, "SongOfSongs", "Song"),
    (23, "Isaiah", "Isa"),
    (24, "Jeremiah", "Jer"),
    (25, "Lamentations", "Lam"),
    (26, "Ezekiel", "Ezek"),
    (27, "Daniel", "Dan"),
    (28, "Hosea", "Hos"),
    (29, "Joel", "Joel"),
    (30, "Amos", "Amos"),
    (31, "Obadiah", "Obad"),
    (32, "Jonah", "Jonah"),
    (33, "Micah", "Mic"),
    (34, "Nahum", "Nah"),
    (35, "Habakkuk", "Hab"),
    (36, "Zephaniah", "Zeph"),
    (37, "Haggai", "Hag"),
    (38, "Zechariah", "Zech"),
    (39, "Malachi", "Mal"),
    (40, "Matthew", "Mat"),
    (41, "Mark", "Mrk"),
    (42, "Luke", "Luk"),
    (43, "John", "Jhn"),
    (44, "Acts", "Act"),
    (45, "Romans", "Rom"),
    (46, "1Corinthians", "1Co"),
    (47, "2Corinthians", "2Co"),
    (48, "Galatians", "Gal"),
    (49, "Ephesians", "Eph"),
    (50, "Philippians", "Php"),
    (51, "Colossians", "Col"),
    (52, "1Thessalonians", "1Th"),
    (53, "2Thessalonians", "2Th"),
    (54, "1Timothy", "1Ti"),
    (55, "2Timothy", "2Ti"),
    (56, "Titus", "Tit"),
    (57, "Philemon", "Phm"),
    (58, "Hebrews", "Heb"),
    (59, "James", "Jas"),
    (60, "1Peter", "1Pe"),
    (61, "2Peter", "2Pe"),
    (62, "1John", "1Jn"),
    (63, "2John", "2Jn"),
    (64, "3John", "3Jn"),
    (65, "Jude", "Jud"),
    (66, "Revelation", "Rev"),
)
BOOK_BY_NUMBER = {number: name for number, name, _ in BOOK_SPECS}
BOOK_NUMBER_BY_NAME = {name: number for number, name, _ in BOOK_SPECS}
BOOK_BY_SOURCE_CODE = {code: name for _, name, code in BOOK_SPECS}

TAGNT_HEADER = (
    "Word & Type",
    "Greek",
    "English translation",
    "dStrongs = Grammar",
    "Dictionary form =  Gloss",
    "editions",
    "Meaning variants",
    "Spelling variants",
    "Spanish translation",
    "Sub-meaning",
    "Conjoin word",
    "sStrong+Instance",
    "Alt Strongs",
)
TAGNT_REFERENCE_RE = re.compile(
    r"^(?P<book>[1-3A-Za-z]{3})\."
    r"(?P<chapter>\d+)\."
    r"(?P<verse>\d+)"
    r"(?P<alternates>(?:[\[\({]\d+\.\d+[\]\)}])*)"
    r"#(?P<position>\d+)=(?P<word_type>.+)$"
)
TAGNT_ALTERNATE_RE = re.compile(
    r"(?P<open>[\[\({])(?P<chapter>\d+)\.(?P<verse>\d+)[\]\)}]"
)
TAGNT_ROUGH_ROW_RE = re.compile(r"^[1-3A-Za-z]{3}\.")
STANDARD_TAGNT_STRONG_RE = re.compile(r"^(?P<strong>[GH]\d+)(?:_[A-Za-z])?$")
OSHB_KJV_NOTE_RE = re.compile(
    r"^KJV:(?P<book>[1-3A-Za-z]+)\."
    r"(?P<chapter>\d+)\."
    r"(?P<verse>\d+)"
    r"(?P<suffix>.*)$"
)
LOCAL_STRONG_MARKER_RE = re.compile(
    r"<W(?P<prefix>[GH])(?P<number>\d+)(?P<suffix>[A-Za-z]?)>"
)
HANJA_IN_PARENTHESES_RE = re.compile(
    r"[\(（][^\)）]*[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff][^\)）]*[\)）]"
)


class EvidencePacketError(RuntimeError):
    """Evidence Packet 생성 계약을 만족하지 못할 때 발생한다."""


class ManifestError(EvidencePacketError):
    """고정 manifest 구조가 올바르지 않을 때 발생한다."""


class SourceSchemaError(EvidencePacketError):
    """고정 source의 parser 계약이 달라졌을 때 발생한다."""


@dataclass(frozen=True)
class SourceFileSpec:
    path: str
    sha256: str
    git_blob: str | None = None


@dataclass(frozen=True)
class OccurrenceSourceSpec:
    id: str
    repository: str
    commit: str
    files: tuple[SourceFileSpec, ...]
    license: dict[str, str]
    attribution: str
    parser_contract: str
    canonical_profile: dict[str, str]


@dataclass(frozen=True)
class LocalSourceSpec:
    id: str
    filename: str
    expected_sha256: str
    role: str
    reference_only: bool
    parser_contract: str
    reference_profile: str


def _read_json_object(path: Path, label: str) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"{label}을 읽을 수 없음: {path}: {error}") from error
    if not isinstance(payload, dict):
        raise ManifestError(f"{label} 최상위 값은 object여야 함")
    return payload


def _required_string(payload: dict[str, object], key: str, label: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value:
        raise ManifestError(f"{label}.{key}는 비어 있지 않은 문자열이어야 함")
    return value


def _validate_relative_path(value: str, label: str) -> None:
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or not path.name:
        raise ManifestError(f"안전하지 않은 {label}: {value!r}")


def _validate_github_repository(value: str, label: str) -> None:
    parsed = urlparse(value)
    parts = [part for part in parsed.path.split("/") if part]
    if parsed.scheme != "https" or parsed.netloc != "github.com" or len(parts) != 2:
        raise ManifestError(f"{label}은 owner/name 형식의 GitHub HTTPS URL이어야 함")


def load_occurrence_manifest(
    path: Path,
) -> tuple[dict[str, object], str, list[OccurrenceSourceSpec]]:
    payload = _read_json_object(path, "occurrence source manifest")
    if payload.get("schema_version") != 1:
        raise ManifestError("occurrence source manifest schema_version은 1이어야 함")
    namespace = _required_string(payload, "cache_namespace", "manifest")
    if not re.fullmatch(r"[a-z0-9_]+", namespace):
        raise ManifestError("cache_namespace 형식이 올바르지 않음")
    raw_sources = payload.get("sources")
    if not isinstance(raw_sources, list) or not raw_sources:
        raise ManifestError("occurrence source manifest sources가 비어 있음")

    specs: list[OccurrenceSourceSpec] = []
    seen_ids: set[str] = set()
    seen_contracts: set[str] = set()
    for index, raw in enumerate(raw_sources):
        label = f"sources[{index}]"
        if not isinstance(raw, dict):
            raise ManifestError(f"{label}은 object여야 함")
        source_id = _required_string(raw, "id", label)
        repository = _required_string(raw, "repository", label)
        commit = _required_string(raw, "commit", label)
        attribution = _required_string(raw, "attribution", label)
        parser_contract = _required_string(raw, "parser_contract", label)
        license_payload = raw.get("license")
        profile = raw.get("canonical_profile")
        raw_files = raw.get("files")
        if source_id in seen_ids or not re.fullmatch(r"[a-z0-9_]+", source_id):
            raise ManifestError(f"중복 또는 잘못된 source id: {source_id!r}")
        _validate_github_repository(repository, f"{label}.repository")
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise ManifestError(f"{label}.commit은 40자리 소문자 Git SHA여야 함")
        if parser_contract not in SUPPORTED_OCCURRENCE_CONTRACTS:
            raise ManifestError(f"지원하지 않는 occurrence parser: {parser_contract}")
        if parser_contract in seen_contracts:
            raise ManifestError(f"중복 occurrence parser contract: {parser_contract}")
        if not isinstance(license_payload, dict) or not license_payload:
            raise ManifestError(f"{label}.license는 비어 있지 않은 object여야 함")
        if not all(
            isinstance(key, str)
            and key
            and isinstance(value, str)
            and value
            for key, value in license_payload.items()
        ):
            raise ManifestError(f"{label}.license 값이 올바르지 않음")
        if not isinstance(profile, dict) or not profile:
            raise ManifestError(f"{label}.canonical_profile이 비어 있음")
        if not all(
            isinstance(key, str)
            and key
            and isinstance(value, str)
            and value
            for key, value in profile.items()
        ):
            raise ManifestError(f"{label}.canonical_profile 값이 올바르지 않음")
        if not isinstance(raw_files, list) or not raw_files:
            raise ManifestError(f"{label}.files가 비어 있음")

        files: list[SourceFileSpec] = []
        seen_paths: set[str] = set()
        for file_index, raw_file in enumerate(raw_files):
            file_label = f"{label}.files[{file_index}]"
            if not isinstance(raw_file, dict):
                raise ManifestError(f"{file_label}은 object여야 함")
            file_path = _required_string(raw_file, "path", file_label)
            sha256 = _required_string(raw_file, "sha256", file_label).lower()
            git_blob = raw_file.get("git_blob")
            _validate_relative_path(file_path, f"{file_label}.path")
            if file_path in seen_paths:
                raise ManifestError(f"중복 source file path: {file_path}")
            if not re.fullmatch(r"[0-9a-f]{64}", sha256):
                raise ManifestError(f"{file_label}.sha256 형식이 올바르지 않음")
            if git_blob is not None and (
                not isinstance(git_blob, str)
                or not re.fullmatch(r"[0-9a-f]{40}", git_blob)
            ):
                raise ManifestError(f"{file_label}.git_blob 형식이 올바르지 않음")
            files.append(SourceFileSpec(file_path, sha256, git_blob))
            seen_paths.add(file_path)

        specs.append(
            OccurrenceSourceSpec(
                id=source_id,
                repository=repository,
                commit=commit,
                files=tuple(files),
                license=dict(license_payload),
                attribution=attribution,
                parser_contract=parser_contract,
                canonical_profile=dict(profile),
            )
        )
        seen_ids.add(source_id)
        seen_contracts.add(parser_contract)

    if seen_contracts != SUPPORTED_OCCURRENCE_CONTRACTS:
        raise ManifestError("OSHB와 TAGNT occurrence source가 각각 정확히 하나 필요함")
    return payload, namespace, specs


def load_local_manifest(
    path: Path,
) -> tuple[dict[str, object], list[LocalSourceSpec]]:
    payload = _read_json_object(path, "local reference source manifest")
    if set(payload) != {"reference_only_boundary", "sources"}:
        raise ManifestError(
            "local reference manifest는 reference_only_boundary와 sources만 허용함"
        )
    boundary = payload.get("reference_only_boundary")
    if not isinstance(boundary, str) or not boundary:
        raise ManifestError("local reference-only 경계가 비어 있음")
    raw_sources = payload.get("sources")
    if not isinstance(raw_sources, list) or not raw_sources:
        raise ManifestError("local reference manifest sources가 비어 있음")

    specs: list[LocalSourceSpec] = []
    seen_filenames: set[str] = set()
    contracts: Counter[str] = Counter()
    for index, raw in enumerate(raw_sources):
        label = f"sources[{index}]"
        if not isinstance(raw, dict):
            raise ManifestError(f"{label}은 object여야 함")
        if set(raw) != {
            "filename",
            "expected_sha256",
            "role",
            "reference_profile",
        }:
            raise ManifestError(
                f"{label}은 filename, expected_sha256, role, "
                "reference_profile만 허용함"
            )
        filename = _required_string(raw, "filename", label)
        expected = _required_string(raw, "expected_sha256", label).lower()
        role = _required_string(raw, "role", label)
        reference_profile = _required_string(raw, "reference_profile", label)
        if filename in seen_filenames or Path(filename).name != filename:
            raise ManifestError(f"중복 또는 안전하지 않은 filename: {filename!r}")
        if not re.fullmatch(r"[0-9a-f]{64}", expected):
            raise ManifestError(f"{label}.expected_sha256 형식이 올바르지 않음")
        profile = LOCAL_SOURCE_PROFILES.get(filename)
        if profile is None:
            raise ManifestError(f"지원하지 않는 local source filename: {filename}")
        source_id, parser_contract, expected_reference_profile = profile
        if reference_profile != expected_reference_profile:
            raise ManifestError(
                f"{label}.reference_profile 불일치: "
                f"expected={expected_reference_profile!r}; "
                f"actual={reference_profile!r}"
            )
        specs.append(
            LocalSourceSpec(
                id=source_id,
                filename=filename,
                expected_sha256=expected,
                role=role,
                reference_only=True,
                parser_contract=parser_contract,
                reference_profile=reference_profile,
            )
        )
        seen_filenames.add(filename)
        contracts[parser_contract] += 1

    if set(seen_filenames) != set(LOCAL_SOURCE_PROFILES) or contracts != Counter(
        {
            "lexicon_scode_dtext_v1": 1,
            "strong_tagged_bible_v1": 3,
            "verse_only_bible_v1": 1,
            "original_analysis_v1": 1,
        }
    ):
        raise ManifestError("local reference source 6개와 parser 구성 계약이 일치하지 않음")
    return payload, specs


def sha256_file(path: Path) -> str:
    return legacy.sha256_file(path)


def git_blob_sha1_file(path: Path) -> str:
    digest = hashlib.sha1()
    digest.update(f"blob {path.stat().st_size}\0".encode("ascii"))
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def occurrence_cache_path(
    cache_dir: Path,
    namespace: str,
    source: OccurrenceSourceSpec,
    file_spec: SourceFileSpec,
) -> Path:
    return cache_dir.joinpath(namespace, source.id, *PurePosixPath(file_spec.path).parts)


def _raw_github_url(source: OccurrenceSourceSpec, file_spec: SourceFileSpec) -> str:
    parsed = urlparse(source.repository)
    owner, repository = [part for part in parsed.path.split("/") if part]
    if repository.endswith(".git"):
        repository = repository[:-4]
    encoded_path = quote(file_spec.path, safe="/")
    return (
        f"https://raw.githubusercontent.com/{owner}/{repository}/"
        f"{source.commit}/{encoded_path}"
    )


def _validate_source_file(path: Path, file_spec: SourceFileSpec, label: str) -> None:
    actual_sha256 = sha256_file(path)
    if actual_sha256 != file_spec.sha256:
        raise EvidencePacketError(
            f"{label} SHA-256 불일치: expected={file_spec.sha256}; "
            f"actual={actual_sha256}"
        )
    if file_spec.git_blob is not None:
        actual_blob = git_blob_sha1_file(path)
        if actual_blob != file_spec.git_blob:
            raise EvidencePacketError(
                f"{label} Git blob 불일치: expected={file_spec.git_blob}; "
                f"actual={actual_blob}"
            )


def ensure_occurrence_sources(
    manifest_path: Path,
    cache_dir: Path,
    *,
    allow_fetch: bool = True,
) -> tuple[
    dict[str, object],
    list[OccurrenceSourceSpec],
    dict[str, list[Path]],
    list[dict[str, object]],
]:
    raw_manifest, namespace, specs = load_occurrence_manifest(manifest_path)
    missing: list[tuple[OccurrenceSourceSpec, SourceFileSpec, Path]] = []
    for source in specs:
        for file_spec in source.files:
            target = occurrence_cache_path(cache_dir, namespace, source, file_spec)
            if target.is_file():
                _validate_source_file(target, file_spec, f"{source.id}/{file_spec.path}")
            else:
                missing.append((source, file_spec, target))

    if missing and not allow_fetch:
        missing_paths = [f"{source.id}/{item.path}" for source, item, _ in missing]
        raise FileNotFoundError(f"occurrence source cache 누락: {missing_paths}")

    for source, file_spec, target in missing:
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name(target.name + ".download")
        request = Request(
            _raw_github_url(source, file_spec),
            headers={"User-Agent": "Reshet-Evidence-Packet-MVP1"},
        )
        try:
            with urlopen(request, timeout=120) as response, temporary.open("wb") as output:
                for chunk in iter(lambda: response.read(1024 * 1024), b""):
                    output.write(chunk)
            _validate_source_file(
                temporary, file_spec, f"{source.id}/{file_spec.path} download"
            )
            os.replace(temporary, target)
        except OSError as error:
            raise EvidencePacketError(
                f"occurrence source 다운로드 실패: {source.id}/{file_spec.path}: {error}"
            ) from error
        finally:
            if temporary.exists():
                temporary.unlink()

    paths_by_source: dict[str, list[Path]] = {}
    provenance: list[dict[str, object]] = []
    for source in specs:
        source_paths: list[Path] = []
        file_rows: list[dict[str, object]] = []
        for file_spec in source.files:
            target = occurrence_cache_path(cache_dir, namespace, source, file_spec)
            if not target.is_file():
                raise FileNotFoundError(f"occurrence source cache 누락: {target}")
            _validate_source_file(target, file_spec, f"{source.id}/{file_spec.path}")
            source_paths.append(target)
            file_rows.append(
                {
                    "path": file_spec.path,
                    "sha256": file_spec.sha256,
                    "size_bytes": target.stat().st_size,
                    "hash_verified": True,
                    "git_blob": file_spec.git_blob,
                    "git_blob_verified": file_spec.git_blob is not None,
                }
            )
        paths_by_source[source.id] = source_paths
        provenance.append(
            {
                "id": source.id,
                "repository": source.repository,
                "commit": source.commit,
                "files": file_rows,
                "license": source.license,
                "attribution": source.attribution,
                "parser_contract": source.parser_contract,
                "canonical_profile": source.canonical_profile,
            }
        )
    return raw_manifest, specs, paths_by_source, provenance


def load_strong_sources(
    manifest_path: Path,
    cache_dir: Path,
    *,
    allow_fetch: bool = True,
) -> tuple[
    dict[str, legacy.SourceEntryV2],
    dict[str, Path],
    list[dict[str, object]],
]:
    _, specs = strong_mapping.load_source_manifest(manifest_path)
    missing = []
    for spec in specs:
        path = strong_mapping.source_cache_path(cache_dir, spec)
        if path.is_file():
            actual = sha256_file(path)
            if actual != spec.sha256:
                raise EvidencePacketError(
                    f"Strong source hash 불일치: {spec.id}; "
                    f"expected={spec.sha256}; actual={actual}"
                )
        else:
            missing.append(path)
    if missing:
        if not allow_fetch:
            raise FileNotFoundError(f"Strong source cache 누락: {missing}")
        strong_mapping.fetch_sources(manifest_path, cache_dir)

    _, specs, datasets, statuses = strong_mapping.validate_source_projections_v2(
        manifest_path, cache_dir
    )
    entries = {key: entry for dataset in datasets for key, entry in dataset.entries.items()}
    paths_by_prefix = {
        spec.language: strong_mapping.source_cache_path(cache_dir, spec) for spec in specs
    }
    provenance = [
        {
            "id": status["id"],
            "language": status["language"],
            "repository": status["repository"],
            "commit": status["commit"],
            "file_path": status["file_path"],
            "sha256": status["actual_sha256"],
            "hash_verified": status["hash_verified"],
            "form_parser_contract": status["form_parser_contract"],
            "meaning_projection_contract": status["meaning_projection_contract"],
            "entry_count": status["entry_count"],
            "form_count": status["form_count"],
            "meaning_count": status["meaning_count"],
            "license": status["license"],
            "required_attribution": status["required_attribution"],
        }
        for status in statuses
    ]
    return entries, paths_by_prefix, provenance


def _entry_key(element: ET.Element, prefix: str) -> str | None:
    raw = element.get("strongs") if prefix == "G" else element.get("id")
    return legacy.normalize_strong_number(raw, prefix)


def extract_direct_references(source_path: Path, target: str) -> list[dict[str, object]]:
    prefix = target[0]
    try:
        root = ET.parse(source_path).getroot()
    except ET.ParseError as error:
        raise SourceSchemaError(f"Strong reference XML parsing 실패: {source_path}: {error}") from error
    entry = next(
        (
            node
            for node in root.iter()
            if legacy.local_name(node.tag) == "entry" and _entry_key(node, prefix) == target
        ),
        None,
    )
    if entry is None:
        return []

    references: list[dict[str, object]] = []
    for child in list(entry):
        container = legacy.local_name(child.tag)
        if prefix == "G" and container != "strongs_derivation":
            continue
        if prefix == "H" and container != "source":
            continue
        for node in child.iter():
            name = legacy.local_name(node.tag)
            if prefix == "G" and name == "strongsref":
                raw_language = node.get("language") or ""
                raw_reference = node.get("strongs") or ""
                reference_prefix = {"GREEK": "G", "HEBREW": "H"}.get(
                    raw_language.upper()
                )
            elif prefix == "H" and name == "w" and node.get("src"):
                raw_language = "HEBREW"
                raw_reference = node.get("src") or ""
                reference_prefix = "H"
            else:
                continue
            normalized = (
                legacy.normalize_strong_number(raw_reference, reference_prefix)
                if reference_prefix is not None
                else None
            )
            references.append(
                {
                    "source_order": len(references) + 1,
                    "source_container": container,
                    "raw_language": raw_language,
                    "raw_reference": raw_reference,
                    "normalized_strong": normalized,
                    "warning": None if normalized is not None else "nonstandard_reference",
                }
            )
    return references


def _source_entry_payload(entry: legacy.SourceEntryV2 | None) -> dict[str, object]:
    if entry is None or not entry.forms:
        return {
            "present": entry is not None,
            "headword": None,
            "transliteration": None,
            "pronunciation": None,
            "source_meanings": [],
            "source_disposition": entry.disposition if entry is not None else "absent",
        }
    primary = entry.forms[0]
    return {
        "present": True,
        "headword": primary.spelling,
        "transliteration": primary.transliteration,
        "pronunciation": primary.pronunciation,
        "source_meanings": [
            {"role": meaning.meaning_role, "text": meaning.text}
            for meaning in entry.meanings
        ],
        "source_disposition": entry.disposition,
    }


def build_strong_window(
    entries: dict[str, legacy.SourceEntryV2],
    target: str,
    direct_references: list[dict[str, object]],
) -> dict[str, object]:
    prefix = target[0]
    number = int(target[1:])
    start = max(1, number - 10)
    end = min(legacy.STRONG_LIMITS[prefix], number + 10)
    referenced = {
        item["normalized_strong"]
        for item in direct_references
        if item["normalized_strong"] is not None
    }
    items: list[dict[str, object]] = []
    for value in range(start, end + 1):
        strong = f"{prefix}{value:04d}"
        entry_payload = _source_entry_payload(entries.get(strong))
        items.append(
            {
                "strong": strong,
                **entry_payload,
                "direct_reference_from_target": strong in referenced,
            }
        )
    return {
        "interpretation": "numeric_neighbors_only_not_semantic_relations",
        "start": f"{prefix}{start:04d}",
        "end": f"{prefix}{end:04d}",
        "items": items,
    }


def _source_reference_state(
    source_base_verse_key: str,
    alternates: list[dict[str, object]],
) -> tuple[bool, bool]:
    conflict = False
    ambiguous = False
    keys_by_kind: dict[str, set[str]] = defaultdict(set)
    for alternate in alternates:
        kind = str(alternate["kind"])
        verse_key = alternate.get("verse_key")
        if alternate.get("parse_status") != "parsed" or not isinstance(
            verse_key, str
        ):
            conflict = True
            ambiguous = True
            continue
        keys_by_kind[kind].add(verse_key)
        if verse_key != source_base_verse_key:
            conflict = True
    if any(len(keys) > 1 for keys in keys_by_kind.values()):
        ambiguous = True
    return conflict, ambiguous


def _parse_tagnt_reference(raw: str) -> dict[str, object]:
    match = TAGNT_REFERENCE_RE.fullmatch(raw)
    if match is None:
        raise SourceSchemaError(f"TAGNT reference 형식 불일치: {raw!r}")
    source_code = match.group("book")
    book = BOOK_BY_SOURCE_CODE.get(source_code)
    if book is None or BOOK_NUMBER_BY_NAME[book] < 40:
        raise SourceSchemaError(f"지원하지 않는 TAGNT book code: {source_code}")
    base_chapter = int(match.group("chapter"))
    base_verse = int(match.group("verse"))
    alternate_values: dict[str, list[str]] = {
        "kjv": [],
        "na": [],
        "other": [],
    }
    source_alternates: list[dict[str, object]] = []
    kind_by_open = {"[": "kjv", "(": "na", "{": "other"}
    for alternate in TAGNT_ALTERNATE_RE.finditer(match.group("alternates")):
        kind = kind_by_open[alternate.group("open")]
        chapter_verse = (
            f"{alternate.group('chapter')}.{alternate.group('verse')}"
        )
        alternate_values[kind].append(chapter_verse)
        source_alternates.append(
            {
                "kind": kind,
                "raw_reference": alternate.group(0),
                "verse_key": f"{book}.{chapter_verse}",
                "parse_status": "parsed",
            }
        )
    source_base_verse_key = f"{book}.{base_chapter}.{base_verse}"
    conflict, ambiguous = _source_reference_state(
        source_base_verse_key, source_alternates
    )
    legacy_alternates = {
        kind: values[0] if len(values) == 1 else None
        for kind, values in alternate_values.items()
    }
    return {
        "book": book,
        "book_number": BOOK_NUMBER_BY_NAME[book],
        "canonical_chapter": base_chapter,
        "canonical_verse": base_verse,
        "canonical_verse_key": source_base_verse_key,
        "source_reference_raw": raw.split("#", 1)[0],
        "source_base_verse_key": source_base_verse_key,
        "versification_alternates": legacy_alternates,
        "source_reference_alternates": source_alternates,
        "source_reference_conflict": conflict,
        "source_reference_ambiguous": ambiguous,
        "token_position": int(match.group("position")),
        "word_type": match.group("word_type"),
    }


def _normalize_tagnt_simple_strong(raw: str) -> str | None:
    match = STANDARD_TAGNT_STRONG_RE.fullmatch(raw.strip())
    if match is None:
        return None
    return legacy.normalize_strong_number(match.group("strong"))


def _split_once(value: str, separator: str) -> tuple[str, str | None]:
    if separator not in value:
        return value.strip(), None
    left, right = value.split(separator, 1)
    return left.strip(), right.strip()


def _tagnt_surface(raw: str) -> tuple[str, str | None]:
    raw = raw.strip()
    if raw.endswith(")") and " (" in raw:
        surface, transliteration = raw.rsplit(" (", 1)
        return surface, transliteration[:-1]
    return raw, None


def parse_tagnt_occurrences(
    paths: list[Path],
    target: str,
) -> tuple[list[dict[str, object]], dict[str, object]]:
    if target[0] != "G":
        raise ValueError("TAGNT parser target은 G Strong이어야 함")
    occurrences: list[dict[str, object]] = []
    total_rows = 0
    canonical_rows = 0
    header_count = 0
    for file_order, path in enumerate(paths, start=1):
        try:
            lines = path.read_text(encoding="utf-8-sig").splitlines()
        except (OSError, UnicodeError) as error:
            raise SourceSchemaError(f"TAGNT UTF-8 read 실패: {path}: {error}") from error
        file_header_count = 0
        for line_number, line in enumerate(lines, start=1):
            if line.startswith("Word & Type\t"):
                fields = line.split("\t")
                if len(fields) != 17 or tuple(fields[:13]) != TAGNT_HEADER:
                    raise SourceSchemaError(
                        f"TAGNT header 계약 불일치: {path.name}:{line_number}"
                    )
                header_count += 1
                file_header_count += 1
                continue
            if not TAGNT_ROUGH_ROW_RE.match(line):
                continue
            fields = line.split("\t")
            if len(fields) != 17:
                raise SourceSchemaError(
                    f"TAGNT field 수 불일치: {path.name}:{line_number}: {len(fields)}"
                )
            reference = _parse_tagnt_reference(fields[0])
            total_rows += 1
            edition_tokens = set(re.findall(r"[A-Za-z]+\d*", fields[5]))
            if not ({"NA27", "NA28"} & edition_tokens):
                continue
            canonical_rows += 1
            normalized = _normalize_tagnt_simple_strong(fields[11])
            if normalized != target:
                continue
            lexical_tag, morphology = _split_once(fields[3], "=")
            lemma, gloss = _split_once(fields[4], "=")
            surface, surface_transliteration = _tagnt_surface(fields[1])
            if not all((surface, lexical_tag, morphology, lemma)):
                raise SourceSchemaError(
                    f"TAGNT target 필드 누락: {path.name}:{line_number}"
                )
            occurrences.append(
                {
                    "canonical_verse_key": reference["canonical_verse_key"],
                    "surface": surface,
                    "surface_transliteration": surface_transliteration,
                    "lemma": lemma,
                    "lexical_tag_raw": lexical_tag,
                    "strong_instance_raw": fields[11],
                    "normalized_standard_strong": normalized,
                    "morphology": morphology,
                    "token_position": reference["token_position"],
                    "source_stable_order": {
                        "file_order": file_order,
                        "line_number": line_number,
                    },
                    "source_file": path.name,
                    "source_reference_raw": reference["source_reference_raw"],
                    "source_base_verse_key": reference["source_base_verse_key"],
                    "versification_alternates": reference["versification_alternates"],
                    "source_reference_alternates": reference[
                        "source_reference_alternates"
                    ],
                    "source_reference_conflict": reference[
                        "source_reference_conflict"
                    ],
                    "source_reference_ambiguous": reference[
                        "source_reference_ambiguous"
                    ],
                    "textual_membership": {
                        "word_type": reference["word_type"],
                        "editions_raw": fields[5],
                        "canonical_profile_match": True,
                    },
                    "source_gloss": gloss,
                    "warnings": [],
                }
            )
        if file_header_count == 0:
            raise SourceSchemaError(f"TAGNT header를 찾을 수 없음: {path}")
    occurrences.sort(key=_occurrence_sort_key)
    return occurrences, {
        "parser_contract": "tagnt_tsv_na27_28_v1",
        "file_count": len(paths),
        "header_count": header_count,
        "data_row_count": total_rows,
        "canonical_profile_row_count": canonical_rows,
        "matched_occurrence_count": len(occurrences),
        "canonical_membership_field": "editions",
        "canonical_membership_values": ["NA27", "NA28"],
    }


KNOWN_OSHB_LEMMA_CODES = {"a", "b", "c", "d", "i", "k", "l", "m", "s"}
OSHB_STRONG_COMPONENT_RE = re.compile(r"^(?P<number>\d+)(?:\s+(?P<suffix>[a-z]))?$")


def parse_oshb_lemma(raw: str) -> dict[str, object]:
    normalized: list[str] = []
    warnings: list[str] = []
    augmented = False
    for component in raw.split("/"):
        value = component.strip()
        match = OSHB_STRONG_COMPONENT_RE.fullmatch(value)
        if match is not None:
            strong = legacy.normalize_strong_number(match.group("number"), "H")
            if strong is None:
                warnings.append(f"nonstandard_numeric_component:{value}")
            else:
                normalized.append(strong)
            if match.group("suffix") is not None:
                augmented = True
            continue
        if value in KNOWN_OSHB_LEMMA_CODES:
            continue
        warnings.append(f"unrecognized_lemma_component:{value}")
    unique = list(dict.fromkeys(normalized))
    if augmented:
        warnings.append("augmented_strong_lemma_preserved")
    if len(unique) > 1:
        warnings.append("multiple_standard_strong_components")
    return {
        "raw": raw,
        "standard_strongs": unique,
        "normalized_standard_strong": unique[0] if len(unique) == 1 else None,
        "warnings": warnings,
    }


def _parse_oshb_verse_key(raw: str) -> tuple[str, int, int, int]:
    match = re.fullmatch(r"([1-3A-Za-z]+)\.(\d+)\.(\d+)", raw)
    if match is None:
        raise SourceSchemaError(f"OSHB verse osisID 형식 불일치: {raw!r}")
    book = BOOK_BY_SOURCE_CODE.get(match.group(1))
    if book is None or BOOK_NUMBER_BY_NAME[book] > 39:
        raise SourceSchemaError(f"지원하지 않는 OSHB book code: {match.group(1)}")
    return book, BOOK_NUMBER_BY_NAME[book], int(match.group(2)), int(match.group(3))


def _parse_oshb_reference_alternates(
    verse: ET.Element,
) -> list[dict[str, object]]:
    alternates: list[dict[str, object]] = []
    for child in list(verse):
        if legacy.local_name(child.tag) != "note":
            continue
        raw_reference = "".join(child.itertext()).strip()
        if not raw_reference.startswith("KJV:"):
            continue
        alternate: dict[str, object] = {
            "kind": "kjv",
            "raw_reference": raw_reference,
            "verse_key": None,
            "parse_status": "unsupported_format",
        }
        match = OSHB_KJV_NOTE_RE.fullmatch(raw_reference)
        if match is not None:
            book = BOOK_BY_SOURCE_CODE.get(match.group("book"))
            if book is None or BOOK_NUMBER_BY_NAME[book] > 39:
                alternate["parse_status"] = "unsupported_book"
            elif match.group("suffix"):
                alternate["parse_status"] = "unsupported_suffix"
                alternate["suffix"] = match.group("suffix")
            else:
                alternate["verse_key"] = (
                    f"{book}.{int(match.group('chapter'))}."
                    f"{int(match.group('verse'))}"
                )
                alternate["parse_status"] = "parsed"
        alternates.append(alternate)
    return alternates


def parse_oshb_occurrences(
    paths: list[Path],
    target: str,
) -> tuple[list[dict[str, object]], dict[str, object]]:
    if target[0] != "H":
        raise ValueError("OSHB parser target은 H Strong이어야 함")
    occurrences: list[dict[str, object]] = []
    verse_count = 0
    word_count = 0
    warning_count = 0
    for file_order, path in enumerate(paths, start=1):
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as error:
            raise SourceSchemaError(f"OSHB XML parsing 실패: {path}: {error}") from error
        if legacy.local_name(root.tag) != "osis":
            raise SourceSchemaError(f"OSHB root tag 불일치: {path}: {root.tag}")
        file_verses = [
            node for node in root.iter() if legacy.local_name(node.tag) == "verse"
        ]
        if not file_verses:
            raise SourceSchemaError(f"OSHB verse가 없는 corpus 파일: {path}")
        for verse in file_verses:
            verse_id = verse.get("osisID") or ""
            book, book_number, chapter, verse_number = _parse_oshb_verse_key(verse_id)
            source_base_verse_key = f"{book}.{chapter}.{verse_number}"
            source_alternates = _parse_oshb_reference_alternates(verse)
            reference_conflict, reference_ambiguous = _source_reference_state(
                source_base_verse_key, source_alternates
            )
            parsed_kjv_alternates = [
                str(alternate["verse_key"])
                for alternate in source_alternates
                if alternate["parse_status"] == "parsed"
            ]
            legacy_kjv_alternate = None
            if len(source_alternates) == 1 and len(parsed_kjv_alternates) == 1:
                _, alternate_chapter, alternate_verse = parse_canonical_verse_key(
                    parsed_kjv_alternates[0]
                )
                legacy_kjv_alternate = f"{alternate_chapter}.{alternate_verse}"
            verse_count += 1
            words = [
                node for node in verse.iter() if legacy.local_name(node.tag) == "w"
            ]
            for token_position, word in enumerate(words, start=1):
                word_count += 1
                raw_lemma = word.get("lemma")
                morphology = word.get("morph")
                surface = "".join(word.itertext())
                if raw_lemma is None or morphology is None or not surface:
                    raise SourceSchemaError(
                        f"OSHB w 필수 필드 누락: {path.name}:{verse_id}:{token_position}"
                    )
                lemma = parse_oshb_lemma(raw_lemma)
                if target not in lemma["standard_strongs"]:
                    continue
                warning_count += len(lemma["warnings"])
                occurrences.append(
                    {
                        "canonical_verse_key": source_base_verse_key,
                        "surface": surface,
                        "surface_transliteration": None,
                        "lemma": raw_lemma,
                        "lexical_tag_raw": raw_lemma,
                        "strong_instance_raw": None,
                        "normalized_standard_strong": lemma[
                            "normalized_standard_strong"
                        ],
                        "morphology": morphology,
                        "token_position": token_position,
                        "source_stable_order": {
                            "file_order": file_order,
                            "token_position": token_position,
                        },
                        "source_file": path.name,
                        "source_reference_raw": verse_id,
                        "source_base_verse_key": source_base_verse_key,
                        "versification_alternates": {
                            "kjv": legacy_kjv_alternate,
                            "na": None,
                            "other": None,
                        },
                        "source_reference_alternates": source_alternates,
                        "source_reference_conflict": reference_conflict,
                        "source_reference_ambiguous": reference_ambiguous,
                        "textual_membership": {
                            "canonical_profile_match": True,
                            "profile": "WLC/OSHB w token",
                        },
                        "source_gloss": None,
                        "warnings": lemma["warnings"],
                        "_book_number": book_number,
                    }
                )
    for occurrence in occurrences:
        occurrence.pop("_book_number", None)
    occurrences.sort(key=_occurrence_sort_key)
    return occurrences, {
        "parser_contract": "oshb_wlc_osis_v1",
        "file_count": len(paths),
        "verse_count": verse_count,
        "word_token_count": word_count,
        "matched_occurrence_count": len(occurrences),
        "matched_warning_count": warning_count,
        "augmented_lemma_policy": "raw_preserved_deterministic_numeric_component_only",
    }


def _occurrence_sort_key(item: dict[str, object]) -> tuple[object, ...]:
    book, chapter, verse = parse_canonical_verse_key(str(item["canonical_verse_key"]))
    stable = item.get("source_stable_order") or {}
    return (
        BOOK_NUMBER_BY_NAME[book],
        chapter,
        verse,
        int(item["token_position"]),
        int(stable.get("file_order", 0)),
        int(stable.get("line_number", stable.get("token_position", 0))),
    )


def parse_canonical_verse_key(value: str) -> tuple[str, int, int]:
    match = re.fullmatch(r"([1-3A-Za-z]+)\.(\d+)\.(\d+)", value)
    if match is None or match.group(1) not in BOOK_NUMBER_BY_NAME:
        raise EvidencePacketError(f"canonical verse key 형식 불일치: {value!r}")
    return match.group(1), int(match.group(2)), int(match.group(3))


def _open_sqlite_read_only(path: Path) -> tuple[sqlite3.Connection, str]:
    if not path.is_file():
        raise FileNotFoundError(f"SQLite 파일을 찾을 수 없음: {path}")
    uri = "file:" + path.resolve().as_posix() + "?mode=ro&immutable=1"
    try:
        connection = sqlite3.connect(uri, uri=True)
    except sqlite3.Error as error:
        raise EvidencePacketError(f"SQLite read-only open 실패: {path}: {error}") from error
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA query_only = ON")
    query_only = int(connection.execute("PRAGMA query_only").fetchone()[0])
    if query_only != 1:
        connection.close()
        raise EvidencePacketError(f"SQLite query_only 보장 실패: {path}")
    integrity = str(connection.execute("PRAGMA integrity_check").fetchone()[0])
    if integrity != "ok":
        connection.close()
        raise EvidencePacketError(f"SQLite integrity_check 실패: {path}: {integrity}")
    return connection, integrity


def _table_columns(connection: sqlite3.Connection, table: str) -> list[str]:
    return [str(row["name"]) for row in connection.execute(f'PRAGMA table_info("{table}")')]


def validate_local_sources(
    manifest_path: Path,
    source_dir: Path,
) -> tuple[dict[str, object], list[LocalSourceSpec], list[dict[str, object]]]:
    raw_manifest, specs = load_local_manifest(manifest_path)
    if not source_dir.is_dir():
        raise FileNotFoundError(f"local source directory를 찾을 수 없음: {source_dir}")
    statuses: list[dict[str, object]] = []
    for spec in specs:
        path = source_dir / spec.filename
        if not path.is_file():
            raise FileNotFoundError(f"local source 파일을 찾을 수 없음: {path}")
        actual = sha256_file(path)
        if actual != spec.expected_sha256:
            raise EvidencePacketError(
                f"local source fingerprint 불일치: {spec.filename}; "
                f"expected={spec.expected_sha256}; actual={actual}"
            )
        connection, integrity = _open_sqlite_read_only(path)
        try:
            if spec.parser_contract == "lexicon_scode_dtext_v1":
                expected_columns = ["id", "scode", "dtext"]
                actual_columns = _table_columns(connection, "Lexicon")
                if actual_columns != expected_columns:
                    raise SourceSchemaError(
                        f"{spec.filename} Lexicon schema 불일치: {actual_columns}"
                    )
                row_count = int(
                    connection.execute("SELECT COUNT(*) FROM Lexicon").fetchone()[0]
                )
                invalid_verse_count = None
            else:
                expected_columns = ["id", "book", "chapter", "verse", "btext"]
                actual_columns = _table_columns(connection, "Bible")
                if actual_columns != expected_columns:
                    raise SourceSchemaError(
                        f"{spec.filename} Bible schema 불일치: {actual_columns}"
                    )
                row_count = int(
                    connection.execute("SELECT COUNT(*) FROM Bible").fetchone()[0]
                )
                invalid_verse_count = int(
                    connection.execute(
                        """
                        SELECT COUNT(*) FROM Bible
                        WHERE typeof(book) <> 'integer'
                           OR book NOT BETWEEN 1 AND 66
                           OR typeof(chapter) <> 'integer'
                           OR chapter < 1
                           OR typeof(verse) <> 'integer'
                           OR verse < 1
                        """
                    ).fetchone()[0]
                )
        finally:
            connection.close()
        statuses.append(
            {
                "id": spec.id,
                "filename": spec.filename,
                "role": spec.role,
                "reference_only": True,
                "parser_contract": spec.parser_contract,
                "reference_profile": spec.reference_profile,
                "expected_sha256": spec.expected_sha256,
                "actual_sha256": actual,
                "hash_verified": True,
                "query_only": True,
                "immutable": True,
                "integrity_check": integrity,
                "row_count": row_count,
                "invalid_verse_row_count": invalid_verse_count,
            }
        )
    return raw_manifest, specs, statuses


def _local_strong_code(target: str) -> str:
    return f"{target[0]}{int(target[1:])}"


def load_lexical_reference(
    spec: LocalSourceSpec,
    source_dir: Path,
    target: str,
) -> dict[str, object]:
    path = source_dir / spec.filename
    connection, _ = _open_sqlite_read_only(path)
    try:
        rows = connection.execute(
            "SELECT id, scode, dtext FROM Lexicon WHERE scode = ? ORDER BY id",
            (_local_strong_code(target),),
        ).fetchall()
    finally:
        connection.close()
    count = len(rows)
    if count == 1:
        description = rows[0]["dtext"]
        warning = None
    elif count == 0:
        description = None
        warning = "no_exact_scode_row"
    else:
        description = None
        warning = "multiple_exact_scode_rows_no_selection"
    return {
        "source_id": spec.id,
        "scode": _local_strong_code(target),
        "exact_row_count": count,
        "description": description,
        "warning": warning,
        "selection_policy": "description은 exact scode가 정확히 1행일 때만 제공",
    }


def _translation_token_before_marker(text: str, start: int, previous_end: int) -> str:
    value = text[previous_end:start].strip()
    value = re.sub(r"^[\s,.;:!?…·—–\-()]+", "", value).strip()
    return value


def _extract_strong_tagged_tokens(text: str, target: str) -> list[str]:
    tokens: list[str] = []
    previous_end = 0
    for marker in LOCAL_STRONG_MARKER_RE.finditer(text):
        suffix = marker.group("suffix")
        normalized = None
        if not suffix:
            normalized = legacy.normalize_strong_number(
                marker.group("prefix") + marker.group("number")
            )
        if normalized == target:
            token = _translation_token_before_marker(text, marker.start(), previous_end)
            if token:
                tokens.append(token)
        previous_end = marker.end()
    return tokens


def _plain_translation_text(text: str) -> str:
    without_markers = LOCAL_STRONG_MARKER_RE.sub("", text)
    return " ".join(without_markers.replace("\r", "\n").split())


def _original_analysis_entries(text: str, target: str) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    normalized_text = text.replace("\r\n", "\n").replace("\r", "\n")
    for line in normalized_text.split("\n"):
        markers = list(LOCAL_STRONG_MARKER_RE.finditer(line))
        matching = []
        for marker in markers:
            if marker.group("suffix"):
                continue
            normalized = legacy.normalize_strong_number(
                marker.group("prefix") + marker.group("number")
            )
            if normalized == target:
                matching.append(marker)
        for marker in matching:
            surface_match = re.match(r"\[([^\]]*)\]", line)
            after_marker = line[marker.end() :]
            lemma_match = re.match(r"\s*(?:\[([^\]]*)\]\s*([^\)]*))?\)", after_marker)
            morphology_match = re.search(r"\)@([^#]*)#\s*(.*?)\*\s*$", line)
            translation = (
                morphology_match.group(2).strip() if morphology_match is not None else None
            )
            entries.append(
                {
                    "surface": surface_match.group(1) if surface_match is not None else None,
                    "lemma": lemma_match.group(1) if lemma_match is not None else None,
                    "transliteration": (
                        lemma_match.group(2).strip()
                        if (
                            lemma_match is not None
                            and lemma_match.group(2) is not None
                            and lemma_match.group(2).strip()
                        )
                        else None
                    ),
                    "morphology": (
                        morphology_match.group(1).strip()
                        if morphology_match is not None
                        else None
                    ),
                    "translation": translation,
                    "raw_line": line,
                }
            )
    return entries


def _canonical_key_from_local(book: int, chapter: int, verse: int) -> str:
    book_name = BOOK_BY_NUMBER.get(book)
    if book_name is None:
        raise SourceSchemaError(f"지원하지 않는 local book number: {book}")
    return f"{book_name}.{chapter}.{verse}"


def resolve_target_reference(
    occurrence: dict[str, object],
    spec: LocalSourceSpec,
) -> dict[str, object]:
    if spec.reference_profile == "not_applicable":
        raise ValueError("verse reference resolver에 lexicon source를 사용할 수 없음")
    source_base_verse_key = str(
        occurrence.get("source_base_verse_key")
        or occurrence["canonical_verse_key"]
    )
    raw_alternates = occurrence.get("source_reference_alternates", [])
    if not isinstance(raw_alternates, list) or not all(
        isinstance(alternate, dict) for alternate in raw_alternates
    ):
        raise EvidencePacketError("source reference alternate 구조가 올바르지 않음")
    alternates = [dict(alternate) for alternate in raw_alternates]
    conflict, ambiguous = _source_reference_state(
        source_base_verse_key, alternates
    )
    profile_candidates = {
        str(alternate["verse_key"])
        for alternate in alternates
        if alternate.get("kind") == spec.reference_profile
        and alternate.get("parse_status") == "parsed"
        and isinstance(alternate.get("verse_key"), str)
    }

    manual_review_required = False
    target_lookup_verse_key: str | None
    if ambiguous:
        target_lookup_verse_key = None
        manual_review_required = True
        selection_reason = "ambiguous_source_reference"
    elif conflict and spec.reference_profile == "unverified":
        target_lookup_verse_key = None
        manual_review_required = True
        selection_reason = "explicit_conflict_unverified_target"
    elif conflict:
        if len(profile_candidates) == 1:
            target_lookup_verse_key = next(iter(profile_candidates))
            selection_reason = "explicit_profile_alternate"
        else:
            target_lookup_verse_key = None
            manual_review_required = True
            selection_reason = "explicit_conflict_no_compatible_profile_alternate"
    elif spec.reference_profile != "unverified" and len(profile_candidates) == 1:
        target_lookup_verse_key = next(iter(profile_candidates))
        selection_reason = "explicit_profile_alternate"
    else:
        target_lookup_verse_key = source_base_verse_key
        selection_reason = "same_key_no_source_conflict"

    return {
        "target_source": spec.id,
        "target_reference_profile": spec.reference_profile,
        "source_base_verse_key": source_base_verse_key,
        "source_reference_conflict": conflict,
        "source_reference_ambiguous": ambiguous,
        "target_lookup_verse_key": target_lookup_verse_key,
        "reference_selection_reason": selection_reason,
        "manual_review_required": manual_review_required,
    }


def load_local_verse_index(
    spec: LocalSourceSpec,
    source_dir: Path,
    canonical_keys: set[str],
    target: str,
) -> tuple[dict[str, list[dict[str, object]]], dict[str, object], Counter[str]]:
    requested: list[tuple[int, int, int]] = []
    for key in sorted(canonical_keys, key=_verse_key_sort_key):
        book, chapter, verse = parse_canonical_verse_key(key)
        requested.append((BOOK_NUMBER_BY_NAME[book], chapter, verse))
    index: dict[str, list[dict[str, object]]] = defaultdict(list)
    expressions: Counter[str] = Counter()
    marker_count = 0
    connection, _ = _open_sqlite_read_only(source_dir / spec.filename)
    try:
        for offset in range(0, len(requested), 250):
            chunk = requested[offset : offset + 250]
            placeholders = ",".join("(?,?,?)" for _ in chunk)
            params = [value for item in chunk for value in item]
            rows = connection.execute(
                f"""
                SELECT id, book, chapter, verse, btext
                FROM Bible
                WHERE (book, chapter, verse) IN ({placeholders})
                ORDER BY book, chapter, verse, id
                """,
                params,
            ).fetchall()
            for row in rows:
                key = _canonical_key_from_local(
                    int(row["book"]), int(row["chapter"]), int(row["verse"])
                )
                raw_text = "" if row["btext"] is None else str(row["btext"])
                if spec.parser_contract == "verse_only_bible_v1":
                    record = {
                        "source_row_id": int(row["id"]),
                        "source_verse_key": (
                            f"{row['book']}.{row['chapter']}.{row['verse']}"
                        ),
                        "full_verse": " ".join(raw_text.replace("\r", "\n").split()),
                        "matched_translation_tokens": [],
                        "marker_alignment": "not_available",
                    }
                elif spec.parser_contract == "original_analysis_v1":
                    source_entries = _original_analysis_entries(raw_text, target)
                    matched_tokens = [
                        str(item["translation"])
                        for item in source_entries
                        if item["translation"]
                    ]
                    marker_count += len(source_entries)
                    expressions.update(matched_tokens)
                    record = {
                        "source_row_id": int(row["id"]),
                        "source_verse_key": (
                            f"{row['book']}.{row['chapter']}.{row['verse']}"
                        ),
                        "full_verse": raw_text.replace("\r\n", "\n").replace(
                            "\r", "\n"
                        ),
                        "matched_translation_tokens": matched_tokens,
                        "matched_source_entries": source_entries,
                        "marker_alignment": "standard_strong_only",
                    }
                else:
                    matched_tokens = _extract_strong_tagged_tokens(raw_text, target)
                    marker_count += len(matched_tokens)
                    expressions.update(matched_tokens)
                    record = {
                        "source_row_id": int(row["id"]),
                        "source_verse_key": (
                            f"{row['book']}.{row['chapter']}.{row['verse']}"
                        ),
                        "full_verse": _plain_translation_text(raw_text),
                        "matched_translation_tokens": matched_tokens,
                        "marker_alignment": "standard_strong_only",
                    }
                index[key].append(record)
    finally:
        connection.close()
    matched_keys = set(index)
    return dict(index), {
        "requested_canonical_verse_count": len(canonical_keys),
        "matched_canonical_verse_count": len(matched_keys),
        "unmatched_canonical_verse_count": len(canonical_keys - matched_keys),
        "local_target_marker_count": marker_count,
        "marker_count_is_canonical_occurrence_count": False,
    }, expressions


def _verse_key_sort_key(value: str) -> tuple[int, int, int]:
    book, chapter, verse = parse_canonical_verse_key(value)
    return BOOK_NUMBER_BY_NAME[book], chapter, verse


def attach_local_references(
    occurrences: list[dict[str, object]],
    specs: list[LocalSourceSpec],
    source_dir: Path,
    target: str,
) -> tuple[
    list[dict[str, object]],
    dict[str, dict[str, object]],
    dict[str, Counter[str]],
]:
    bible_specs = [
        spec for spec in specs if spec.parser_contract != "lexicon_scode_dtext_v1"
    ]
    decisions = {
        spec.id: [
            resolve_target_reference(occurrence, spec)
            for occurrence in occurrences
        ]
        for spec in bible_specs
    }
    indexes: dict[str, dict[str, list[dict[str, object]]]] = {}
    join_stats: dict[str, dict[str, object]] = {}
    expressions: dict[str, Counter[str]] = {}
    for spec in bible_specs:
        lookup_keys = {
            str(decision["target_lookup_verse_key"])
            for decision in decisions[spec.id]
            if isinstance(decision["target_lookup_verse_key"], str)
        }
        index, stats, source_expressions = load_local_verse_index(
            spec, source_dir, lookup_keys, target
        )
        indexes[spec.id] = index
        join_stats[spec.id] = {
            **stats,
            "reference_profile": spec.reference_profile,
            "automatic_lookup_occurrence_count": sum(
                not bool(decision["manual_review_required"])
                for decision in decisions[spec.id]
            ),
            "manual_review_required_occurrence_count": sum(
                bool(decision["manual_review_required"])
                for decision in decisions[spec.id]
            ),
        }
        expressions[spec.id] = source_expressions

    attached: list[dict[str, object]] = []
    status_counts: dict[str, Counter[str]] = {
        spec.id: Counter() for spec in bible_specs
    }
    for occurrence_index, occurrence in enumerate(occurrences):
        references: dict[str, object] = {}
        for spec in bible_specs:
            decision = decisions[spec.id][occurrence_index]
            lookup_key = decision["target_lookup_verse_key"]
            if decision["manual_review_required"]:
                records: list[dict[str, object]] = []
                status = "manual_review_required"
                lookup_performed = False
            else:
                if not isinstance(lookup_key, str):
                    raise AssertionError("automatic lookup key가 없음")
                records = indexes[spec.id].get(lookup_key, [])
                lookup_performed = True
                if not records:
                    status = "unmatched"
                elif len(records) == 1:
                    status = "matched"
                else:
                    status = "multiple_source_rows_preserved"
            status_counts[spec.id][status] += 1
            references[spec.id] = {
                **decision,
                "status": status,
                "requested_canonical_verse_key": lookup_key,
                "lookup_performed": lookup_performed,
                "records": records,
            }
        attached.append({**occurrence, "local_references": references})
    for spec in bible_specs:
        join_stats[spec.id]["join_status_counts"] = dict(
            sorted(status_counts[spec.id].items())
        )
    return attached, join_stats, expressions


def load_reshet_projection(
    work_db: Path,
    target: str,
) -> tuple[list[dict[str, object]], dict[str, object]]:
    before = sha256_file(work_db)
    connection, integrity = _open_sqlite_read_only(work_db)
    try:
        required_tables = {
            "WORD_TABLE": {"id", "언어", "스트롱넘버"},
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
            actual = set(_table_columns(connection, table))
            if not required <= actual:
                raise SourceSchemaError(
                    f"work DB {table} 필수 column 누락: {sorted(required - actual)}"
                )
        words = connection.execute(
            '''
            SELECT id, "스트롱넘버" AS strong_number, "언어" AS language
            FROM WORD_TABLE
            WHERE "스트롱넘버" = ?
            ORDER BY id
            ''',
            (target,),
        ).fetchall()
        projection: list[dict[str, object]] = []
        for word in words:
            expressions = connection.execute(
                '''
                SELECT seq, is_representative, spelling, transliteration,
                       pronunciation, pronunciation_notation,
                       pronunciation_notation_name
                FROM word_expression_set
                WHERE word_id = ?
                ORDER BY seq
                ''',
                (word["id"],),
            ).fetchall()
            meanings = connection.execute(
                '''
                SELECT seq, meaning
                FROM word_meaning_set
                WHERE word_id = ?
                ORDER BY seq
                ''',
                (word["id"],),
            ).fetchall()
            projection.append(
                {
                    "word_id": word["id"],
                    "strong_number": word["strong_number"],
                    "language": word["language"],
                    "expressions": [dict(row) for row in expressions],
                    "meanings": [dict(row) for row in meanings],
                }
            )
    finally:
        connection.close()
    after = sha256_file(work_db)
    if before != after:
        raise EvidencePacketError("work DB SHA-256이 read-only 실행 중 변경됨")
    return projection, {
        "filename": work_db.name,
        "sha256_before": before,
        "sha256_after": after,
        "unchanged": True,
        "query_only": True,
        "immutable": True,
        "integrity_check": integrity,
    }


def _strong_from_word_id(value: object) -> str | None:
    match = re.match(r"^([GH]\d+)_", str(value))
    return legacy.normalize_strong_number(match.group(1)) if match else None


def _approved_projections_by_strong(
    path: Path,
) -> dict[str, list[dict[str, object]]]:
    payload = _read_json_object(path, "approved content manifest")
    expected_keys = {
        "format_version",
        "batch_id",
        "provenance",
        "target",
        "meaning_replacements",
        "relation_creates",
    }
    batch_id = payload.get("batch_id")
    if (
        set(payload) != expected_keys
        or payload.get("format_version") != 1
        or not isinstance(batch_id, str)
        or not batch_id.endswith(APPROVED_BATCH_ID_SUFFIX)
        or not isinstance(payload.get("provenance"), dict)
        or not isinstance(payload.get("target"), dict)
        or not isinstance(payload.get("relation_creates"), list)
    ):
        raise ManifestError(f"approved content manifest format 계약 불일치: {path.name}")
    rows = payload.get("meaning_replacements")
    if not isinstance(rows, list):
        raise ManifestError("approved content manifest meaning_replacements가 배열이 아님")
    projections: dict[str, list[dict[str, object]]] = defaultdict(list)
    word_ids: set[str] = set()
    for index, row in enumerate(rows):
        row_label = f"{path.name} meaning_replacements[{index}]"
        if not isinstance(row, dict) or set(row) != {"word_id", "before", "after"}:
            raise ManifestError(f"{row_label}의 필드가 approved content 계약과 다름")
        word_id = row.get("word_id")
        strong = _strong_from_word_id(word_id)
        if not isinstance(word_id, str) or strong is None:
            raise ManifestError(f"{row_label}.word_id가 Strong word ID가 아님")
        before = row.get("before")
        after = row.get("after")
        if not isinstance(before, list) or not isinstance(after, list) or any(
            not isinstance(value, dict)
            or set(value) != {"seq", "meaning"}
            or type(value.get("seq")) is not int
            or not isinstance(value.get("meaning"), str)
            for value in [*before, *after]
        ):
            raise ManifestError(f"{row_label}의 meaning projection 형식 불일치")
        if word_id in word_ids:
            raise ManifestError(f"approved content manifest word_id 중복: {word_id}")
        word_ids.add(word_id)
        projections[strong].append(
            {
                "word_id": word_id,
                "meanings": [
                    {"seq": value["seq"], "meaning": value["meaning"]}
                    for value in after
                ],
            }
        )
    return {
        strong: sorted(values, key=lambda value: str(value["word_id"]))
        for strong, values in projections.items()
    }


def _approved_strongs(path: Path) -> set[str]:
    return set(_approved_projections_by_strong(path))


def discover_approved_content_manifests(
    repository_root: Path = REPOSITORY_ROOT,
) -> tuple[Path, ...]:
    root = repository_root.resolve()
    manifest_dir = root / "tool" / "data_provenance" / "manifests"
    relative_manifest_dir = manifest_dir.relative_to(root).as_posix()
    try:
        tracked = subprocess.run(
            [
                "git",
                "-c",
                "core.quotepath=false",
                "ls-files",
                "-z",
                "--",
                relative_manifest_dir,
            ],
            cwd=root,
            check=True,
            capture_output=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise ManifestError(
            f"tracked approved content manifest Git 확인 실패: {error}"
        ) from error
    relative_paths = sorted(
        PurePosixPath(value.decode("utf-8")).as_posix()
        for value in tracked.stdout.split(b"\0")
        if value
    )
    approved_relative_paths = tuple(
        relative
        for relative in relative_paths
        if PurePosixPath(relative).parent.as_posix() == relative_manifest_dir
        and APPROVED_MANIFEST_FILENAME_RE.fullmatch(PurePosixPath(relative).name)
    )
    if not approved_relative_paths:
        raise ManifestError("tracked approved content manifest가 없음")

    paths = tuple(
        root.joinpath(*PurePosixPath(relative).parts)
        for relative in approved_relative_paths
    )
    for path in paths:
        _approved_projections_by_strong(path)
    return paths


def _ordered_approved_manifests(
    approved_manifests: Path | list[Path] | tuple[Path, ...],
) -> tuple[Path, ...]:
    values = (
        (approved_manifests,)
        if isinstance(approved_manifests, Path)
        else tuple(approved_manifests)
    )
    if not values:
        raise ManifestError("approved content manifest override가 비어 있음")
    unique: dict[Path, Path] = {}
    for value in values:
        path = Path(value)
        unique[path.resolve()] = path
    return tuple(
        sorted(unique.values(), key=lambda path: (path.name, path.as_posix()))
    )


def _projection_matches_approved(
    projection: list[dict[str, object]],
    approved_projection: list[dict[str, object]],
) -> bool:
    current_projection: list[dict[str, object]] = []
    for word in projection:
        word_id = word.get("word_id")
        meanings = word.get("meanings")
        if not isinstance(word_id, str) or not isinstance(meanings, list):
            return False
        current_meanings = [
            {"seq": row.get("seq"), "meaning": row.get("meaning")}
            for row in meanings
            if isinstance(row, dict)
        ]
        if len(current_meanings) != len(meanings):
            return False
        current_projection.append(
            {"word_id": word_id, "meanings": current_meanings}
        )
    return (
        sorted(current_projection, key=lambda value: str(value["word_id"]))
        == approved_projection
    )


def _source_only_entry(path: Path, target: str) -> dict[str, object] | None:
    payload = _read_json_object(path, "source-only import manifest")
    rows = payload.get("entries")
    if not isinstance(rows, list):
        raise ManifestError("source-only import manifest entries가 배열이 아님")
    matches = [
        row
        for row in rows
        if isinstance(row, dict)
        and legacy.normalize_strong_number(row.get("strong_number")) == target
    ]
    if len(matches) > 1:
        raise ManifestError(f"source-only manifest target 중복: {target}")
    return matches[0] if matches else None


def _projection_matches_source_only(
    projection: list[dict[str, object]],
    entry: dict[str, object],
) -> bool:
    if len(projection) != 1:
        return False
    current = projection[0]
    if current["word_id"] != entry.get("word_id"):
        return False
    expected_expressions = [
        {
            key: row.get(key)
            for key in (
                "seq",
                "is_representative",
                "spelling",
                "transliteration",
                "pronunciation",
                "pronunciation_notation",
                "pronunciation_notation_name",
            )
        }
        for row in entry.get("expressions", [])
        if isinstance(row, dict)
    ]
    expected_meanings = [
        {"seq": row.get("seq"), "meaning": row.get("text")}
        for row in entry.get("meanings", [])
        if isinstance(row, dict)
    ]
    return (
        current["expressions"] == expected_expressions
        and current["meanings"] == expected_meanings
    )


def completion_gate_state(
    target: str,
    projection: list[dict[str, object]],
    approved_manifest: Path | list[Path] | tuple[Path, ...],
    source_only_manifest: Path,
) -> dict[str, object]:
    approved_manifests = _ordered_approved_manifests(approved_manifest)
    target_approvals: list[tuple[Path, list[dict[str, object]]]] = []
    for path in approved_manifests:
        approved_projection = _approved_projections_by_strong(path).get(target)
        if approved_projection is not None:
            target_approvals.append((path, approved_projection))

    approved_mismatch_evidence: list[str] = []
    if target_approvals:
        expected_projection = target_approvals[0][1]
        conflicting = [
            path.name
            for path, candidate in target_approvals[1:]
            if candidate != expected_projection
        ]
        if conflicting:
            names = ", ".join(
                sorted({target_approvals[0][0].name, *conflicting})
            )
            raise ManifestError(
                f"동일 Strong의 approved projection이 manifest 간 상충함: {target}: {names}"
            )
        evidence = sorted(path.name for path, _ in target_approvals)
        if _projection_matches_approved(projection, expected_projection):
            return {
                "state": "explicit_approved",
                "evidence": evidence,
                "interpretation": (
                    "tracked 승인 content manifest의 명시적 meaning 대상이며 "
                    "현재 DB projection이 승인 after와 exact 일치"
                ),
                "application_approval_ledger": "not_applicable_mvp1",
            }
        approved_mismatch_evidence = [
            f"approved_manifest_current_projection_mismatch:{name}"
            for name in evidence
        ]
    meanings = [
        str(row["meaning"])
        for word in projection
        for row in word.get("meanings", [])
        if row.get("meaning") is not None
    ]
    if any(HANJA_IN_PARENTHESES_RE.search(value) for value in meanings):
        return {
            "state": "legacy_hanja_candidate",
            "evidence": [
                *approved_mismatch_evidence,
                "existing_meaning_parenthesized_hanja_marker",
            ],
            "interpretation": (
                "강한 과거 작업 marker이며 자동 최종 승인 확정이 아님. "
                "한자 부재를 미작업으로 해석하지 않음"
            ),
            "application_approval_ledger": "not_applicable_mvp1",
        }
    source_only = _source_only_entry(source_only_manifest, target)
    if source_only is not None and _projection_matches_source_only(projection, source_only):
        return {
            "state": "source_only",
            "evidence": [
                *approved_mismatch_evidence,
                source_only_manifest.name,
                "current_projection_exact_match",
            ],
            "interpretation": "승인된 source-only import projection이 현재 DB와 exact 일치",
            "application_approval_ledger": "not_applicable_mvp1",
        }
    evidence = list(approved_mismatch_evidence)
    if source_only is not None:
        evidence.append("source_only_manifest_current_projection_mismatch")
    return {
        "state": "unclassified",
        "evidence": evidence,
        "interpretation": "한자 부재만으로 작업 여부를 추론하지 않음",
        "application_approval_ledger": "not_applicable_mvp1",
    }


def _counter_payload(counter: Counter[str]) -> list[dict[str, object]]:
    return [
        {"value": value, "count": count}
        for value, count in sorted(counter.items(), key=lambda item: (-item[1], item[0]))
    ]


def build_summary(
    occurrences: list[dict[str, object]],
    join_stats: dict[str, dict[str, object]],
    translation_expressions: dict[str, Counter[str]],
) -> dict[str, object]:
    surfaces = Counter(str(item["surface"]) for item in occurrences)
    lemmas = Counter(str(item["lemma"]) for item in occurrences)
    verses = {str(item["canonical_verse_key"]) for item in occurrences}
    return {
        "canonical_occurrence_count": len(occurrences),
        "canonical_verse_count": len(verses),
        "surface_forms": _counter_payload(surfaces),
        "lemmas": _counter_payload(lemmas),
        "translation_expressions": {
            source_id: _counter_payload(counter)
            for source_id, counter in sorted(translation_expressions.items())
        },
        "local_join": {key: join_stats[key] for key in sorted(join_stats)},
        "counting_boundary": (
            "canonical occurrence count는 OSHB/TAGNT에서만 계산하며 "
            "로컬 marker count로 대체하지 않음"
        ),
    }


def _manifest_provenance(path: Path) -> dict[str, object]:
    return {"path": path.name, "sha256": sha256_file(path)}


def _assert_local_hashes_unchanged(
    specs: list[LocalSourceSpec],
    source_dir: Path,
) -> None:
    for spec in specs:
        actual = sha256_file(source_dir / spec.filename)
        if actual != spec.expected_sha256:
            raise EvidencePacketError(
                f"local source가 실행 중 변경됨: {spec.filename}: {actual}"
            )


def build_evidence_packet(
    requested_strong: str,
    *,
    local_sources: Path,
    work_db: Path = DEFAULT_WORK_DB,
    strong_manifest: Path = DEFAULT_STRONG_MANIFEST,
    occurrence_manifest: Path = DEFAULT_OCCURRENCE_MANIFEST,
    local_manifest: Path = DEFAULT_LOCAL_MANIFEST,
    approved_manifest: Path | list[Path] | tuple[Path, ...] | None = None,
    source_only_manifest: Path = DEFAULT_SOURCE_ONLY_MANIFEST,
    cache_dir: Path = DEFAULT_CACHE,
    allow_fetch: bool = True,
) -> dict[str, object]:
    normalized = legacy.normalize_strong_number(requested_strong)
    if normalized is None:
        raise EvidencePacketError(
            f"유효한 standard Strong 번호가 아님: {requested_strong!r}"
        )

    approved_manifests = (
        discover_approved_content_manifests()
        if approved_manifest is None
        else _ordered_approved_manifests(approved_manifest)
    )

    entries, strong_paths, strong_provenance = load_strong_sources(
        strong_manifest, cache_dir, allow_fetch=allow_fetch
    )
    direct_references = extract_direct_references(
        strong_paths[normalized[0]], normalized
    )
    strong_window = build_strong_window(entries, normalized, direct_references)
    reshet_projection, work_db_provenance = load_reshet_projection(work_db, normalized)
    completion_gate = completion_gate_state(
        normalized,
        reshet_projection,
        approved_manifests,
        source_only_manifest,
    )

    (
        _,
        occurrence_specs,
        occurrence_paths,
        occurrence_provenance,
    ) = ensure_occurrence_sources(
        occurrence_manifest, cache_dir, allow_fetch=allow_fetch
    )
    occurrence_source = next(
        spec
        for spec in occurrence_specs
        if (
            normalized[0] == "G"
            and spec.parser_contract == "tagnt_tsv_na27_28_v1"
        )
        or (
            normalized[0] == "H" and spec.parser_contract == "oshb_wlc_osis_v1"
        )
    )
    if normalized[0] == "G":
        occurrences, occurrence_parser_stats = parse_tagnt_occurrences(
            occurrence_paths[occurrence_source.id], normalized
        )
    else:
        occurrences, occurrence_parser_stats = parse_oshb_occurrences(
            occurrence_paths[occurrence_source.id], normalized
        )

    _, local_specs, local_provenance = validate_local_sources(
        local_manifest, local_sources
    )
    lexicon_spec = next(
        spec
        for spec in local_specs
        if spec.parser_contract == "lexicon_scode_dtext_v1"
    )
    lexical_reference = load_lexical_reference(
        lexicon_spec, local_sources, normalized
    )
    attached_occurrences, join_stats, translation_expressions = attach_local_references(
        occurrences, local_specs, local_sources, normalized
    )
    _assert_local_hashes_unchanged(local_specs, local_sources)

    target_source = _source_entry_payload(entries.get(normalized))
    source_entry = entries.get(normalized)
    target = {
        "requested_strong": requested_strong,
        "normalized_strong": normalized,
        "language": "Greek" if normalized[0] == "G" else "Hebrew/Aramaic",
        "source_language_code": (
            source_entry.source_language_code if source_entry is not None else None
        ),
        "canonical_headword": target_source["headword"],
        "transliteration": target_source["transliteration"],
        "pronunciation": target_source["pronunciation"],
        "source_meanings": target_source["source_meanings"],
        "source_disposition": target_source["source_disposition"],
        "existing_reshet_projection": reshet_projection,
        "completion_gate": completion_gate,
        "source_references": [
            {
                "id": row["id"],
                "commit": row["commit"],
                "file_path": row["file_path"],
                "sha256": row["sha256"],
            }
            for row in strong_provenance
            if row["language"] == normalized[0]
        ],
    }

    for row in occurrence_provenance:
        if row["id"] == occurrence_source.id:
            row["parser_result"] = occurrence_parser_stats
        else:
            row["parser_result"] = {
                "status": "not_parsed_for_target_language",
                "target_language": normalized[0],
            }

    packet = {
        "schema_version": 1,
        "tool": {
            "name": "Reshet Biblical Research Evidence Packet Generator",
            "version": TOOL_VERSION,
            "output": "deterministic_utf8_pretty_json",
        },
        "scope": {
            "mvp": 1,
            "included": [
                "completion_gate",
                "target_strong",
                "strong_numeric_window_plus_minus_10",
                "direct_source_references",
                "canonical_biblical_occurrences",
                "local_reference_verse_join",
                "occurrence_translation_expression_summary",
                "source_fingerprint_provenance",
            ],
            "not_applicable": [
                "LXX_alignment",
                "Hebrew_Greek_cross_language_analysis",
                "LLM_meaning_candidates",
                "semantic_relation_auto_classification",
                "approval_ledger",
                "dashboard_UI",
                "database_write",
                "runtime_schema_change",
                "markdown_renderer",
            ],
        },
        "target": target,
        "strong_window": strong_window,
        "direct_references": direct_references,
        "lexical_reference": lexical_reference,
        "canonical_occurrences": attached_occurrences,
        "summary": build_summary(
            attached_occurrences, join_stats, translation_expressions
        ),
        "provenance": {
            "strong_sources": strong_provenance,
            "occurrence_sources": occurrence_provenance,
            "local_reference_sources": local_provenance,
            "work_database": work_db_provenance,
            "manifests": [
                _manifest_provenance(strong_manifest),
                _manifest_provenance(occurrence_manifest),
                _manifest_provenance(local_manifest),
                *[
                    _manifest_provenance(path)
                    for path in approved_manifests
                ],
                _manifest_provenance(source_only_manifest),
            ],
            "local_sources_argument": str(local_sources),
        },
    }
    return packet


def serialize_packet(packet: dict[str, object]) -> bytes:
    return (
        json.dumps(packet, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Strong 하나의 결정적 성경 연구 Evidence Packet JSON을 생성합니다."
    )
    parser.add_argument("strong", help="G32, G1225, H32 같은 standard Strong 번호")
    parser.add_argument(
        "--local-sources",
        type=Path,
        required=True,
        help="승인된 로컬 연구 참고자료 6개가 있는 디렉터리",
    )
    parser.add_argument("--work-db", type=Path, default=DEFAULT_WORK_DB)
    parser.add_argument("--cache-dir", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--strong-manifest", type=Path, default=DEFAULT_STRONG_MANIFEST)
    parser.add_argument(
        "--occurrence-manifest", type=Path, default=DEFAULT_OCCURRENCE_MANIFEST
    )
    parser.add_argument("--local-manifest", type=Path, default=DEFAULT_LOCAL_MANIFEST)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="cache가 없을 때 다운로드하지 않고 fail-closed",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        packet = build_evidence_packet(
            args.strong,
            local_sources=args.local_sources,
            work_db=args.work_db,
            strong_manifest=args.strong_manifest,
            occurrence_manifest=args.occurrence_manifest,
            local_manifest=args.local_manifest,
            cache_dir=args.cache_dir,
            allow_fetch=not args.offline,
        )
    except (
        EvidencePacketError,
        FileNotFoundError,
        strong_mapping.ManifestError,
        legacy.SourceSchemaError,
    ) as error:
        sys.stderr.reconfigure(encoding="utf-8", errors="strict", newline="\n")
        print(f"오류: {error}", file=sys.stderr)
        return 2
    sys.stdout.buffer.write(serialize_packet(packet))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
