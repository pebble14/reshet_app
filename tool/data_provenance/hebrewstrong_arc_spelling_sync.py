#!/usr/bin/env python3
"""HebrewStrong ``arc`` 12건의 code-point 표기를 dual-store에 정합화한다.

cohort는 고정 HebrewStrong source의 ``arc`` entry와 기존 Strong mapping의
``nfc_spelling_exact_pronunciation`` 자동 대응을 교차해 결정한다. manifest가
UPDATE identity의 유일한 authority이며, 실제 적용은 기존 Strong migration의
precondition·transaction·backup·복원·비대상 projection 보호를 재사용한다.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
import unicodedata
from typing import Iterable, Sequence

import strong_source_mapping as mapping
import strong_source_migration as migration


MIGRATION_ID = "hebrewstrong_arc_spelling_sync"
SCHEMA_VERSION = 1
TOOL_VERSION = "1.0.0"
EXPECTED_TARGET_COUNT = 12
EXPECTED_TARGET_PROJECTION_SHA256 = (
    "0dbaa9ead5f2f4901c8cd05be181f24abdf1ec0bd06d30e03bc9800982d8c316"
)
CONFIRM_TOKEN = "APPLY_HEBREWSTRONG_ARC_SPELLING_12"
TOOL_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = TOOL_DIR.parents[1]
DEFAULT_MANIFEST = TOOL_DIR / "manifests" / f"{MIGRATION_ID}.json"
DEFAULT_RESULT = TOOL_DIR / "migrations" / f"{MIGRATION_ID}_result.json"
DEFAULT_SOURCE_MANIFEST = TOOL_DIR / "manifests" / "strong_sources.json"
DEFAULT_SOURCE_CACHE = TOOL_DIR / ".source_cache"
DEFAULT_WORK_DB = REPOSITORY_ROOT / "data" / "reshet_work.db"
DEFAULT_SEED_DB = REPOSITORY_ROOT / "data" / "reshet_seed.db"
DEFAULT_BACKUP_ROOT = REPOSITORY_ROOT / "data" / "backups" / MIGRATION_ID
TARGET_PROJECTION_FIELDS = (
    "strong_id",
    "word_id",
    "seq",
    "mapping_rule",
    "current_spelling",
    "expected_spelling",
)


class MigrationError(migration.MigrationError):
    """표기 cohort 또는 migration 경계가 어긋났을 때 발생한다."""


@dataclass(frozen=True)
class LoadedManifest:
    payload: dict[str, object]
    targets: tuple[dict[str, object], ...]
    plan: tuple[migration.MigrationPlanRow, ...]
    file_sha256: str


def sha256_file(path: Path) -> str:
    return migration.sha256_file(path)


def _portable_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(REPOSITORY_ROOT).as_posix()
    except ValueError:
        return str(resolved)


def _canonical_json_bytes(payload: object) -> bytes:
    return (
        json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def _jsonl_sha256(rows: Iterable[object]) -> str:
    digest = hashlib.sha256()
    for row in rows:
        digest.update(_canonical_json_bytes(row))
    return digest.hexdigest()


def _code_points(value: str) -> list[str]:
    return [f"U+{ord(character):04X}" for character in value]


def _source_tool_boundary() -> dict[str, object]:
    parser_path = TOOL_DIR / "strong_source_diff.py"
    mapping_path = TOOL_DIR / "strong_source_mapping.py"
    return {
        "parser_tool_path": _portable_path(parser_path),
        "parser_tool_sha256": sha256_file(parser_path),
        "mapping_tool_path": _portable_path(mapping_path),
        "mapping_tool_sha256": sha256_file(mapping_path),
    }


def _load_source_contract(
    source_manifest: Path, source_cache: Path
) -> dict[str, object]:
    raw_v1, _, v1_datasets, _ = mapping.validate_sources(
        source_manifest, source_cache
    )
    raw_v2, _, v2_datasets, v2_statuses = mapping.validate_source_projections_v2(
        source_manifest, source_cache
    )
    if raw_v1 != raw_v2:
        raise MigrationError("v1/v2 source manifest 해석이 다름")
    entries = mapping.combine_v2_datasets(v2_datasets)
    arc_entries = {
        key: entry
        for key, entry in entries.items()
        if entry.source_language_code == "arc"
    }
    if len(arc_entries) != 653:
        raise MigrationError(f"source arc count 불일치: {len(arc_entries)}")
    hebrew_source = next(
        (
            source
            for source in raw_v1.get("sources", [])
            if isinstance(source, dict) and source.get("language") == "H"
        ),
        None,
    )
    hebrew_status = next(
        (status for status in v2_statuses if status.get("language") == "H"), None
    )
    if hebrew_source is None or hebrew_status is None:
        raise MigrationError("Hebrew source boundary가 없음")
    contracts = raw_v1.get("contract_versions")
    if not isinstance(contracts, dict):
        raise MigrationError("source contract_versions가 없음")
    if contracts.get("mapping_contract") != "strong_mapping_v2":
        raise MigrationError("mapping contract 불일치")
    rendering = contracts.get("rendering_contract")
    if not isinstance(rendering, dict) or rendering.get("unicode_normalization") != "none":
        raise MigrationError("Unicode rendering contract 불일치")
    if hebrew_status.get("form_parser_contract") != "hebrew_forms_v2":
        raise MigrationError("Hebrew v2 parser contract 불일치")
    source = {
        "repository": hebrew_source.get("repository"),
        "commit": hebrew_source.get("commit"),
        "path": hebrew_source.get("file_path"),
        "sha256": hebrew_source.get("sha256"),
        "actual_sha256": hebrew_status.get("actual_sha256"),
        "license": hebrew_source.get("license"),
        "license_reference": hebrew_source.get("license_reference"),
        "required_attribution": hebrew_source.get("required_attribution"),
        "source_manifest_path": _portable_path(source_manifest),
        "source_manifest_sha256": sha256_file(source_manifest),
        "source_language_code_counts": {
            code: sum(entry.source_language_code == code for entry in entries.values())
            for code in ("G", "heb", "arc", "x-pn")
        },
        **_source_tool_boundary(),
    }
    if source["sha256"] != source["actual_sha256"]:
        raise MigrationError("manifest/source XML SHA-256 불일치")
    source_candidates = {
        strong_id: candidates
        for dataset in v1_datasets
        for strong_id, candidates in dataset.candidates.items()
    }
    return {
        "raw_manifest": raw_v1,
        "source": source,
        "entries": entries,
        "arc_entries": arc_entries,
        "source_candidates": source_candidates,
    }


def _mapping_plan(
    db_path: Path, source_candidates: dict[str, object]
) -> tuple[mapping.DatabaseSnapshot, list[dict[str, object]]]:
    snapshot = mapping.load_database_snapshot(db_path)
    analyses = mapping.analyze_database(snapshot.words, source_candidates)
    return snapshot, mapping.build_mapping_plan(analyses)


def _cohort_from_database(
    db_path: Path, source_contract: dict[str, object]
) -> dict[str, object]:
    arc_entries = source_contract["arc_entries"]
    if not isinstance(arc_entries, dict):
        raise MigrationError("arc source entry 형식 불일치")
    source_candidates = source_contract["source_candidates"]
    if not isinstance(source_candidates, dict):
        raise MigrationError("source candidate 형식 불일치")
    snapshot, rows = _mapping_plan(db_path, source_candidates)
    arc_rows = [row for row in rows if row.get("strong_id") in arc_entries]
    raw_v2_rows = mapping.build_mapping_v2(
        source_contract["entries"], snapshot.words
    )
    raw_arc_rows = [row for row in raw_v2_rows if row.source_key in arc_entries]
    raw_spelling_mismatches = [
        row
        for row in raw_arc_rows
        if row.current_values is not None
        and row.expected_values is not None
        and row.current_values["spelling"] != row.expected_values["spelling"]
    ]
    selected = [
        row
        for row in arc_rows
        if row.get("language") == "아람어"
        and row.get("primary_disposition") == "auto"
        and row.get("mapping_rule") == "nfc_spelling_exact_pronunciation"
        and row.get("change_classification") == "nfc_only_match"
        and row.get("expected_field_changes") == ["spelling"]
    ]
    if len(selected) != EXPECTED_TARGET_COUNT:
        raise MigrationError(f"재현 cohort가 12건이 아님: {len(selected)}")
    connection = migration._connect(db_path, read_only=True)
    items: list[dict[str, object]] = []
    try:
        for row in selected:
            strong_id = str(row["strong_id"])
            entry = arc_entries[strong_id]
            if len(entry.forms) != 1:
                raise MigrationError(f"source form count 불일치: {strong_id}")
            form = entry.forms[0]
            if form.source_document_order != row["db_seq"]:
                raise MigrationError(f"source/DB expression seq 불일치: {strong_id}")
            current = row["current_values"]
            expected = row["expected_values"]
            if not isinstance(current, dict) or not isinstance(expected, dict):
                raise MigrationError(f"mapping current/expected 누락: {strong_id}")
            if expected["spelling"] != form.spelling:
                raise MigrationError(f"source expected spelling 불일치: {strong_id}")
            if current["spelling"] == expected["spelling"]:
                raise MigrationError(f"raw spelling mismatch가 아님: {strong_id}")
            if unicodedata.normalize("NFC", str(current["spelling"])) != unicodedata.normalize(
                "NFC", str(expected["spelling"])
            ):
                raise MigrationError(f"NFC-equivalent가 아님: {strong_id}")
            legacy_rows = connection.execute(
                'SELECT "표기1" FROM WORD_TABLE WHERE id=?',
                (row["word_id"],),
            ).fetchall()
            if len(legacy_rows) != 1 or legacy_rows[0][0] != current["spelling"]:
                raise MigrationError(f"legacy current spelling 불일치: {strong_id}")
            items.append(
                {
                    "strong_id": strong_id,
                    "word_id": row["word_id"],
                    "language": row["language"],
                    "source_language_code": "arc",
                    "source_form_order": form.source_document_order,
                    "seq": row["db_seq"],
                    "is_representative": row["is_representative"],
                    "mapping_rule": row["mapping_rule"],
                    "change_classification": row["change_classification"],
                    "expected_field_changes": ["spelling"],
                    "current_values": {
                        field: current[field]
                        for field in migration.REQUIRED_CURRENT_FIELDS
                    },
                    "expected_values": {
                        field: expected[field]
                        for field in migration.REQUIRED_CURRENT_FIELDS
                    },
                    "legacy_current_spelling": legacy_rows[0][0],
                    "current_spelling_code_points": _code_points(
                        str(current["spelling"])
                    ),
                    "source_spelling_code_points": _code_points(
                        str(expected["spelling"])
                    ),
                    "nfc_equivalent": True,
                }
            )
    finally:
        connection.close()
    items.sort(key=lambda item: (str(item["strong_id"]), int(item["seq"])))
    disposition_by_word: dict[str, str] = {}
    for row in arc_rows:
        disposition_by_word.setdefault(
            str(row["strong_id"]), str(row["primary_disposition"])
        )
    return {
        "database_sha256": sha256_file(db_path),
        "database_snapshot": snapshot.metadata,
        "arc_source_entry_count": len(arc_entries),
        "arc_expression_count": len(arc_rows),
        "arc_language_counts": dict(
            sorted(Counter(str(row["language"]) for row in arc_rows).items())
        ),
        "arc_word_disposition_counts": dict(
            sorted(Counter(disposition_by_word.values()).items())
        ),
        "arc_expression_disposition_counts": dict(
            sorted(
                Counter(str(row["primary_disposition"]) for row in arc_rows).items()
            )
        ),
        "raw_code_point_spelling_mismatch_count": len(raw_spelling_mismatches),
        "selected_count": len(items),
        "targets": items,
    }


def _target_projection(target: dict[str, object]) -> dict[str, object]:
    return {
        "strong_id": target["strong_id"],
        "word_id": target["word_id"],
        "seq": target["seq"],
        "mapping_rule": target["mapping_rule"],
        "current_spelling": target["current_values"]["spelling"],
        "expected_spelling": target["expected_values"]["spelling"],
    }


def _target_projection_sha(targets: Sequence[dict[str, object]]) -> str:
    return _jsonl_sha256(_target_projection(target) for target in targets)


def _plan_from_targets(
    targets: Sequence[dict[str, object]],
) -> tuple[migration.MigrationPlanRow, ...]:
    plan: list[migration.MigrationPlanRow] = []
    identities: set[tuple[str, int]] = set()
    for target in targets:
        strong_id = target.get("strong_id")
        word_id = target.get("word_id")
        language = target.get("language")
        seq = target.get("seq")
        representative = target.get("is_representative")
        current = target.get("current_values")
        expected = target.get("expected_values")
        if not isinstance(strong_id, str) or not strong_id.startswith("H"):
            raise MigrationError("manifest target Strong ID가 Hebrew가 아님")
        if not isinstance(word_id, str) or language != "아람어":
            raise MigrationError(f"manifest target identity/language 불일치: {strong_id}")
        if seq != 1 or representative != 1:
            raise MigrationError(f"manifest expression slot 불일치: {strong_id}")
        if target.get("source_language_code") != "arc":
            raise MigrationError(f"manifest source language가 arc가 아님: {strong_id}")
        if target.get("mapping_rule") != "nfc_spelling_exact_pronunciation":
            raise MigrationError(f"manifest mapping rule 불일치: {strong_id}")
        if target.get("change_classification") != "nfc_only_match":
            raise MigrationError(f"manifest change classification 불일치: {strong_id}")
        if target.get("expected_field_changes") != ["spelling"]:
            raise MigrationError(f"manifest spelling-only 경계 불일치: {strong_id}")
        database_values = target.get("database_current_values")
        expected_database_values = {
            label: {
                "legacy_spelling": current.get("spelling")
                if isinstance(current, dict)
                else None,
                "normalized_spelling": current.get("spelling")
                if isinstance(current, dict)
                else None,
            }
            for label in ("work", "seed")
        }
        if database_values != expected_database_values:
            raise MigrationError(f"manifest DB별 기존값 불일치: {strong_id}")
        if not isinstance(current, dict) or not isinstance(expected, dict):
            raise MigrationError(f"manifest current/expected 누락: {strong_id}")
        if any(field not in current or field not in expected for field in migration.REQUIRED_CURRENT_FIELDS):
            raise MigrationError(f"manifest value 필드 누락: {strong_id}")
        changed = [
            field
            for field in migration.REQUIRED_CURRENT_FIELDS
            if current[field] != expected[field]
        ]
        if changed != ["spelling"]:
            raise MigrationError(f"manifest 실제 변경 필드가 spelling-only가 아님: {strong_id}")
        if current["spelling"] == expected["spelling"] or unicodedata.normalize(
            "NFC", str(current["spelling"])
        ) != unicodedata.normalize("NFC", str(expected["spelling"])):
            raise MigrationError(f"manifest NFC code-point 경계 불일치: {strong_id}")
        if target.get("current_spelling_code_points") != _code_points(
            str(current["spelling"])
        ) or target.get("source_spelling_code_points") != _code_points(
            str(expected["spelling"])
        ):
            raise MigrationError(f"manifest code point projection 불일치: {strong_id}")
        identity = (word_id, int(seq))
        if identity in identities:
            raise MigrationError(f"manifest target 중복: {identity}")
        identities.add(identity)
        plan.append(
            migration.MigrationPlanRow(
                strong_id=strong_id,
                word_id=word_id,
                language=language,
                seq=int(seq),
                is_representative=int(representative),
                current_values={
                    field: current[field]
                    for field in migration.REQUIRED_CURRENT_FIELDS
                },
                expected_values={
                    field: expected[field]
                    for field in migration.REQUIRED_CURRENT_FIELDS
                },
            )
        )
    return tuple(plan)


def build_manifest_payload(
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest: Path = DEFAULT_SOURCE_MANIFEST,
    source_cache: Path = DEFAULT_SOURCE_CACHE,
) -> dict[str, object]:
    source_contract = _load_source_contract(source_manifest, source_cache)
    work = _cohort_from_database(work_db, source_contract)
    seed = _cohort_from_database(seed_db, source_contract)
    if work["targets"] != seed["targets"]:
        raise MigrationError("work/seed 재현 cohort가 다름")
    reproduced_targets = work["targets"]
    if not isinstance(reproduced_targets, list):
        raise MigrationError("cohort target 형식 불일치")
    targets: list[dict[str, object]] = []
    for work_target, seed_target in zip(
        reproduced_targets, seed["targets"], strict=True
    ):
        target = dict(work_target)
        work_legacy = target.pop("legacy_current_spelling")
        seed_legacy = seed_target["legacy_current_spelling"]
        current_spelling = target["current_values"]["spelling"]
        target["database_current_values"] = {
            "work": {
                "legacy_spelling": work_legacy,
                "normalized_spelling": current_spelling,
            },
            "seed": {
                "legacy_spelling": seed_legacy,
                "normalized_spelling": current_spelling,
            },
        }
        targets.append(target)
    projection_sha = _target_projection_sha(targets)
    if projection_sha != EXPECTED_TARGET_PROJECTION_SHA256:
        raise MigrationError(
            f"이전 12건 projection과 불일치: {projection_sha}"
        )
    plan = _plan_from_targets(targets)
    work_preflight = migration.preflight_database_plan(work_db, list(plan))
    seed_preflight = migration.preflight_database_plan(seed_db, list(plan))
    if work_preflight != seed_preflight:
        raise MigrationError("manifest 생성 전 work/seed preflight가 다름")
    parity = migration.compare_database_projection(work_db, seed_db)
    if not parity["semantic_projection_equal"]:
        raise MigrationError("manifest 생성 전 work/seed 의미 projection이 다름")
    raw_manifest = source_contract["raw_manifest"]
    contracts = raw_manifest["contract_versions"]
    return {
        "schema_version": SCHEMA_VERSION,
        "migration_id": MIGRATION_ID,
        "tool_version": TOOL_VERSION,
        "source": source_contract["source"],
        "contracts": {
            "form_parser_contract": "hebrew_forms_v2",
            "historical_pairing_parser_contract": "hebrew_direct_w_v1",
            "mapping_contract": contracts["mapping_contract"],
            "matching_key": "normalized Strong ID",
            "source_entry_selection": "entry direct child w exactly one",
            "db_word_connection": "normalized Strong ID with exactly one current word",
            "expression_slot": "source document order equals word_expression_set.seq",
            "mapping_rule": "raw spelling + exact pronunciation, NFC spelling + exact pronunciation, raw spelling, NFC spelling 순서의 degree-1 pair",
            "cohort_selector": "source_language_code=arc AND primary_disposition=auto AND mapping_rule=nfc_spelling_exact_pronunciation AND expected_field_changes=[spelling]",
            "unicode_normalization": "comparison uses NFC equivalence; stored source spelling preserves source code points without normalization",
        },
        "cohort": {
            "source_arc_entry_count": work["arc_source_entry_count"],
            "source_arc_expression_count": work["arc_expression_count"],
            "source_arc_language_counts": work["arc_language_counts"],
            "source_arc_word_disposition_counts": work[
                "arc_word_disposition_counts"
            ],
            "source_arc_expression_disposition_counts": work[
                "arc_expression_disposition_counts"
            ],
            "raw_code_point_spelling_mismatch_count": work[
                "raw_code_point_spelling_mismatch_count"
            ],
            "selected_target_count": len(targets),
            "excluded_non_auto_word_count": work[
                "arc_word_disposition_counts"
            ].get("exception", 0),
            "excluded_reason": "기존 mapping에서 auto bijection이 확정되지 않음",
        },
        "expected_initial_database_sha256": {
            "work": work["database_sha256"],
            "seed": seed["database_sha256"],
        },
        "target_projection_contract": {
            "fields": list(TARGET_PROJECTION_FIELDS),
            "sort": ["strong_id ASC", "seq ASC"],
            "format": "JSONL object",
            "encoding": "UTF-8",
            "bom": False,
            "ensure_ascii": False,
            "sort_keys": True,
            "separators": [",", ":"],
            "final_lf": True,
        },
        "target_projection_sha256": projection_sha,
        "allowed_changes": [
            "word_expression_set.spelling",
            "WORD_TABLE.표기1",
        ],
        "protected_boundaries": [
            "target identity/language/seq/is_representative/transliteration/pronunciation/notation",
            "cohort 밖 word_expression_set와 WORD_TABLE expression slot",
            "WORD_TABLE 비표기 semantic field",
            "word_meaning_set",
            "WORD_RELATION",
            "CHANGE_HISTORY",
            "schema",
        ],
        "targets": targets,
    }


def write_manifest(payload: dict[str, object], output: Path) -> str:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return sha256_file(output)


def load_manifest(path: Path = DEFAULT_MANIFEST) -> LoadedManifest:
    try:
        raw = path.read_bytes()
        payload = json.loads(raw.decode("utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise MigrationError(f"manifest를 읽을 수 없음: {error}") from error
    if not isinstance(payload, dict):
        raise MigrationError("manifest 최상위 값이 object가 아님")
    if payload.get("schema_version") != SCHEMA_VERSION or payload.get(
        "migration_id"
    ) != MIGRATION_ID:
        raise MigrationError("manifest identity/schema 불일치")
    targets = payload.get("targets")
    if not isinstance(targets, list) or len(targets) != EXPECTED_TARGET_COUNT:
        raise MigrationError("manifest target count 불일치")
    projection_sha = _target_projection_sha(targets)
    if (
        payload.get("target_projection_sha256") != projection_sha
        or projection_sha != EXPECTED_TARGET_PROJECTION_SHA256
    ):
        raise MigrationError("manifest target projection SHA 불일치")
    plan = _plan_from_targets(targets)
    return LoadedManifest(
        payload=payload,
        targets=tuple(targets),
        plan=plan,
        file_sha256=hashlib.sha256(raw).hexdigest(),
    )


def verify_manifest_source(
    manifest: LoadedManifest,
    source_manifest: Path = DEFAULT_SOURCE_MANIFEST,
    source_cache: Path = DEFAULT_SOURCE_CACHE,
) -> dict[str, object]:
    contract = _load_source_contract(source_manifest, source_cache)
    if manifest.payload.get("source") != contract["source"]:
        raise MigrationError("manifest/source provenance 불일치")
    entries = contract["arc_entries"]
    for target in manifest.targets:
        strong_id = str(target["strong_id"])
        entry = entries.get(strong_id)
        if entry is None or len(entry.forms) != 1:
            raise MigrationError(f"manifest source target를 재현할 수 없음: {strong_id}")
        form = entry.forms[0]
        if (
            form.source_document_order != target["seq"]
            or form.spelling != target["expected_values"]["spelling"]
        ):
            raise MigrationError(f"manifest/source spelling slot 불일치: {strong_id}")
    return contract["source"]


def _state_from_preflights(
    work: dict[str, object], seed: dict[str, object]
) -> str:
    if work != seed:
        raise MigrationError("work/seed target preflight가 다름")
    current = int(work["current_count"])
    expected = int(work["already_expected_count"])
    if current == EXPECTED_TARGET_COUNT and expected == 0:
        return "pre_apply"
    if current == 0 and expected == EXPECTED_TARGET_COUNT:
        return "post_apply"
    raise MigrationError(
        f"mixed/unsupported target state: current={current}, expected={expected}"
    )


def run_dry_run(
    *,
    manifest_path: Path = DEFAULT_MANIFEST,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest: Path = DEFAULT_SOURCE_MANIFEST,
    source_cache: Path = DEFAULT_SOURCE_CACHE,
) -> dict[str, object]:
    migration._assert_no_active_journal((work_db, seed_db))
    manifest = load_manifest(manifest_path)
    source = verify_manifest_source(manifest, source_manifest, source_cache)
    work = migration.preflight_database_plan(work_db, list(manifest.plan))
    seed = migration.preflight_database_plan(seed_db, list(manifest.plan))
    state = _state_from_preflights(work, seed)
    parity = migration.compare_database_projection(work_db, seed_db)
    if not parity["semantic_projection_equal"]:
        raise MigrationError("work/seed Strong 의미 projection이 다름")
    hashes = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    if state == "pre_apply" and hashes != manifest.payload.get(
        "expected_initial_database_sha256"
    ):
        raise MigrationError("active DB 시작 SHA-256 불일치")
    return {
        "migration_id": MIGRATION_ID,
        "mode": "dry-run",
        "state": state,
        "manifest_sha256": manifest.file_sha256,
        "target_count": EXPECTED_TARGET_COUNT,
        "target_projection_sha256": EXPECTED_TARGET_PROJECTION_SHA256,
        "source": source,
        "database_sha256": hashes,
        "work": work,
        "seed": seed,
        "parity": parity,
    }


def validate_temporary_apply(
    work_db: Path,
    seed_db: Path,
    plan: Sequence[migration.MigrationPlanRow],
) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix="reshet_arc_spelling_") as directory:
        root = Path(directory)
        work_copy = root / "work.db"
        seed_copy = root / "seed.db"
        shutil.copy2(work_db, work_copy)
        shutil.copy2(seed_db, seed_copy)
        work_result = migration.apply_database(work_copy, list(plan))
        seed_result = migration.apply_database(seed_copy, list(plan))
        parity = migration.compare_database_projection(work_copy, seed_copy)
        if not parity["semantic_projection_equal"]:
            raise MigrationError("임시 복사본 적용 후 work/seed parity 실패")
        work_hash = sha256_file(work_copy)
        seed_hash = sha256_file(seed_copy)
        second_work = migration.apply_database(work_copy, list(plan))
        second_seed = migration.apply_database(seed_copy, list(plan))
        if (
            second_work["change_counts"]["actual_changed_expression_count"] != 0
            or second_seed["change_counts"]["actual_changed_expression_count"] != 0
            or sha256_file(work_copy) != work_hash
            or sha256_file(seed_copy) != seed_hash
        ):
            raise MigrationError("임시 복사본 두 번째 실행이 no-op가 아님")
        return {
            "work_change_counts": work_result["change_counts"],
            "seed_change_counts": seed_result["change_counts"],
            "parity_after": parity,
            "second_run": {
                "work_change_counts": second_work["change_counts"],
                "seed_change_counts": second_seed["change_counts"],
                "database_hash_unchanged": True,
            },
        }


def _validate_change_counts(result: dict[str, object], label: str) -> None:
    counts = result["change_counts"]
    expected = {
        "auto_word_count": EXPECTED_TARGET_COUNT,
        "auto_expression_count": EXPECTED_TARGET_COUNT,
        "actual_changed_word_count": EXPECTED_TARGET_COUNT,
        "actual_changed_expression_count": EXPECTED_TARGET_COUNT,
        "spelling_change_count": EXPECTED_TARGET_COUNT,
        "pronunciation_change_count": 0,
        "notation_change_count": 0,
        "notation_only_change_count": 0,
        "nfc_equivalent_spelling_change_count": EXPECTED_TARGET_COUNT,
        "legacy_spelling_slot_change_count": EXPECTED_TARGET_COUNT,
        "legacy_pronunciation_slot_change_count": 0,
        "already_expected_noop_count": 0,
    }
    if counts != expected:
        raise MigrationError(f"{label} change counts 불일치: {counts}")


def _result_matches_current(
    result_path: Path,
    manifest: LoadedManifest,
    work_db: Path,
    seed_db: Path,
) -> dict[str, object]:
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise MigrationError(f"result artifact를 읽을 수 없음: {error}") from error
    current_hashes = {"work": sha256_file(work_db), "seed": sha256_file(seed_db)}
    if (
        not isinstance(result, dict)
        or result.get("migration_id") != MIGRATION_ID
        or result.get("input_manifest_sha256") != manifest.file_sha256
        or result.get("database_sha256_after") != current_hashes
    ):
        raise MigrationError("result artifact와 현재 post-apply state가 다름")
    return result


def _table_rows(connection: sqlite3.Connection, table: str) -> list[sqlite3.Row]:
    quoted = '"' + table.replace('"', '""') + '"'
    return connection.execute(f"SELECT * FROM {quoted} ORDER BY rowid").fetchall()


def _compare_backup_current(
    *,
    backup_path: Path,
    current_path: Path,
    manifest: LoadedManifest,
    arc_strong_ids: Sequence[str],
) -> dict[str, object]:
    before = sqlite3.connect(backup_path)
    after = sqlite3.connect(current_path)
    before.row_factory = sqlite3.Row
    after.row_factory = sqlite3.Row
    try:
        before_tables = [
            str(row[0])
            for row in before.execute(
                "SELECT name FROM sqlite_master "
                "WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
            )
        ]
        after_tables = [
            str(row[0])
            for row in after.execute(
                "SELECT name FROM sqlite_master "
                "WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
            )
        ]
        schema_sql = (
            "SELECT type, name, tbl_name, sql FROM sqlite_master "
            "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name"
        )
        schema_equal = before.execute(schema_sql).fetchall() == after.execute(
            schema_sql
        ).fetchall()
        row_counts_equal = all(
            len(_table_rows(before, table)) == len(_table_rows(after, table))
            for table in before_tables
        )
        target_ids = {str(target["word_id"]) for target in manifest.targets}
        target_keys = {
            (str(target["word_id"]), int(target["seq"]))
            for target in manifest.targets
        }
        expected = {
            (str(target["word_id"]), int(target["seq"])): str(
                target["expected_values"]["spelling"]
            )
            for target in manifest.targets
        }
        before_words = {
            str(row["id"]): dict(row)
            for row in before.execute("SELECT * FROM WORD_TABLE")
        }
        after_words = {
            str(row["id"]): dict(row)
            for row in after.execute("SELECT * FROM WORD_TABLE")
        }
        before_expressions = {
            (str(row["word_id"]), int(row["seq"])): dict(row)
            for row in before.execute("SELECT * FROM word_expression_set")
        }
        after_expressions = {
            (str(row["word_id"]), int(row["seq"])): dict(row)
            for row in after.execute("SELECT * FROM word_expression_set")
        }
        non_target_words_equal = all(
            before_words[key] == after_words[key]
            for key in before_words
            if key not in target_ids
        )
        non_target_expressions_equal = all(
            before_expressions[key] == after_expressions[key]
            for key in before_expressions
            if key not in target_keys
        )
        target_word_diffs = {
            key: [
                column
                for column in before_words[key]
                if before_words[key][column] != after_words[key][column]
            ]
            for key in target_ids
        }
        target_expression_diffs = {
            key: [
                column
                for column in before_expressions[key]
                if before_expressions[key][column]
                != after_expressions[key][column]
            ]
            for key in target_keys
        }
        other_changed_tables = [
            table
            for table in before_tables
            if table not in {"WORD_TABLE", "word_expression_set"}
            and _table_rows(before, table) != _table_rows(after, table)
        ]
        target_expected_count = sum(
            after_words[word_id]["표기1"] == expected[(word_id, seq)]
            and after_expressions[(word_id, seq)]["spelling"]
            == expected[(word_id, seq)]
            for word_id, seq in target_keys
        )
        placeholders = ",".join("?" for _ in arc_strong_ids)
        language_counts = dict(
            after.execute(
                f'''SELECT "언어", COUNT(*) FROM WORD_TABLE
                    WHERE UPPER(TRIM("스트롱넘버")) IN ({placeholders})
                    GROUP BY "언어"''',
                arc_strong_ids,
            ).fetchall()
        )
        arc_word_count = int(
            after.execute(
                f'''SELECT COUNT(*) FROM WORD_TABLE
                    WHERE UPPER(TRIM("스트롱넘버")) IN ({placeholders})''',
                arc_strong_ids,
            ).fetchone()[0]
        )
        arc_expression_count = int(
            after.execute(
                f'''SELECT COUNT(*)
                    FROM word_expression_set e
                    JOIN WORD_TABLE w ON w.id=e.word_id
                    WHERE UPPER(TRIM(w."스트롱넘버")) IN ({placeholders})''',
                arc_strong_ids,
            ).fetchone()[0]
        )
        health = migration.verify_database_health(after)
        target_projection = [
            [
                word_id,
                after_words[word_id]["표기1"],
                after_expressions[(word_id, 1)]["spelling"],
            ]
            for word_id in sorted(target_ids)
        ]
        verification = {
            "schema_equal": schema_equal,
            "table_sets_equal": before_tables == after_tables,
            "row_counts_equal": row_counts_equal,
            "target_word_changed_columns": sorted(
                {tuple(columns) for columns in target_word_diffs.values()}
            ),
            "target_expression_changed_columns": sorted(
                {tuple(columns) for columns in target_expression_diffs.values()}
            ),
            "target_word_change_count": sum(
                bool(columns) for columns in target_word_diffs.values()
            ),
            "target_expression_change_count": sum(
                bool(columns) for columns in target_expression_diffs.values()
            ),
            "target_expected_count": target_expected_count,
            "target_final_projection_sha256": hashlib.sha256(
                _canonical_json_bytes(target_projection)
            ).hexdigest(),
            "non_target_word_rows_equal": non_target_words_equal,
            "non_target_expression_rows_equal": non_target_expressions_equal,
            "other_changed_tables": other_changed_tables,
            "source_arc_word_count": arc_word_count,
            "source_arc_expression_count": arc_expression_count,
            "source_arc_language_counts": language_counts,
            **health,
        }
        expected_boundary = {
            "schema_equal": True,
            "table_sets_equal": True,
            "row_counts_equal": True,
            "target_word_changed_columns": [("표기1",)],
            "target_expression_changed_columns": [("spelling",)],
            "target_word_change_count": EXPECTED_TARGET_COUNT,
            "target_expression_change_count": EXPECTED_TARGET_COUNT,
            "target_expected_count": EXPECTED_TARGET_COUNT,
            "non_target_word_rows_equal": True,
            "non_target_expression_rows_equal": True,
            "other_changed_tables": [],
            "source_arc_word_count": 653,
            "source_arc_expression_count": 654,
            "source_arc_language_counts": {"아람어": 653},
            "integrity_check": "ok",
            "foreign_key_violation_count": 0,
            "required_schema_present": True,
        }
        mismatches = {
            key: (verification.get(key), expected_value)
            for key, expected_value in expected_boundary.items()
            if verification.get(key) != expected_value
        }
        if mismatches:
            raise MigrationError(f"backup/current 불변 검증 실패: {mismatches}")
        return verification
    finally:
        after.close()
        before.close()


def run_verify(
    *,
    manifest_path: Path = DEFAULT_MANIFEST,
    result_path: Path = DEFAULT_RESULT,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest: Path = DEFAULT_SOURCE_MANIFEST,
    source_cache: Path = DEFAULT_SOURCE_CACHE,
) -> dict[str, object]:
    migration._assert_no_active_journal((work_db, seed_db))
    manifest = load_manifest(manifest_path)
    source_contract = _load_source_contract(source_manifest, source_cache)
    result = _result_matches_current(
        result_path, manifest, work_db, seed_db
    )
    backup_directory = Path(str(result["backup"]["directory"]))
    if not backup_directory.is_absolute():
        backup_directory = REPOSITORY_ROOT / backup_directory
    arc_strong_ids = sorted(source_contract["arc_entries"])
    work = _compare_backup_current(
        backup_path=backup_directory / "reshet_work_pre_arc_spelling.db",
        current_path=work_db,
        manifest=manifest,
        arc_strong_ids=arc_strong_ids,
    )
    seed = _compare_backup_current(
        backup_path=backup_directory / "reshet_seed_pre_arc_spelling.db",
        current_path=seed_db,
        manifest=manifest,
        arc_strong_ids=arc_strong_ids,
    )
    parity = migration.compare_database_projection(work_db, seed_db)
    if not parity["semantic_projection_equal"]:
        raise MigrationError("verify 시 work/seed Strong projection 불일치")
    if work["target_final_projection_sha256"] != seed[
        "target_final_projection_sha256"
    ]:
        raise MigrationError("verify 시 work/seed target final projection 불일치")
    return {
        "migration_id": MIGRATION_ID,
        "mode": "verify",
        "status": "검증 완료",
        "manifest_sha256": manifest.file_sha256,
        "result_sha256": sha256_file(result_path),
        "work": work,
        "seed": seed,
        "work_seed_final_targets_equal": True,
        "parity": parity,
    }


def run_apply(
    *,
    manifest_path: Path = DEFAULT_MANIFEST,
    work_db: Path = DEFAULT_WORK_DB,
    seed_db: Path = DEFAULT_SEED_DB,
    source_manifest: Path = DEFAULT_SOURCE_MANIFEST,
    source_cache: Path = DEFAULT_SOURCE_CACHE,
    backup_root: Path = DEFAULT_BACKUP_ROOT,
    result_output: Path = DEFAULT_RESULT,
    confirm_token: str,
    fault_injection: str | None = None,
) -> dict[str, object]:
    if confirm_token != CONFIRM_TOKEN:
        raise MigrationError("apply confirmation token 불일치")
    preview = run_dry_run(
        manifest_path=manifest_path,
        work_db=work_db,
        seed_db=seed_db,
        source_manifest=source_manifest,
        source_cache=source_cache,
    )
    manifest = load_manifest(manifest_path)
    if preview["state"] == "post_apply":
        _result_matches_current(result_output, manifest, work_db, seed_db)
        return {
            "migration_id": MIGRATION_ID,
            "mode": "apply",
            "status": "이미 적용됨 — 변경 0",
            "change_count": 0,
            "backup_created": False,
            "transaction_started": False,
            "database_sha256": preview["database_sha256"],
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": sha256_file(result_output),
            "result_unchanged": True,
        }
    if result_output.exists():
        raise MigrationError("미적용 DB인데 result artifact가 이미 존재함")
    migration._verify_write_lock_available(work_db)
    migration._verify_write_lock_available(seed_db)
    temporary_validation = validate_temporary_apply(
        work_db, seed_db, manifest.plan
    )
    executed_at = datetime.now(timezone.utc)
    backup_dir = backup_root / executed_at.strftime("%Y%m%dT%H%M%S_%fZ")
    work_backup = migration.create_verified_backup(
        work_db, backup_dir, "reshet_work_pre_arc_spelling"
    )
    seed_backup = migration.create_verified_backup(
        seed_db, backup_dir, "reshet_seed_pre_arc_spelling"
    )
    result_written = False
    try:
        work_result = migration.apply_database(work_db, list(manifest.plan))
        if fault_injection == "after_work_apply":
            raise MigrationError("test fault injection: after_work_apply")
        seed_result = migration.apply_database(seed_db, list(manifest.plan))
        _validate_change_counts(work_result, "work")
        _validate_change_counts(seed_result, "seed")
        parity_after = migration.compare_database_projection(work_db, seed_db)
        if not parity_after["semantic_projection_equal"]:
            raise MigrationError("active 적용 후 work/seed parity 실패")
        post = run_dry_run(
            manifest_path=manifest_path,
            work_db=work_db,
            seed_db=seed_db,
            source_manifest=source_manifest,
            source_cache=source_cache,
        )
        if post["state"] != "post_apply":
            raise MigrationError("active 적용 후 post_apply state가 아님")
        output_hashes = post["database_sha256"]
        result_payload = {
            "schema_version": SCHEMA_VERSION,
            "migration_id": MIGRATION_ID,
            "tool_version": TOOL_VERSION,
            "executed_at_utc": executed_at.isoformat(),
            "input_manifest_path": _portable_path(manifest_path),
            "input_manifest_sha256": manifest.file_sha256,
            "target_projection_sha256": EXPECTED_TARGET_PROJECTION_SHA256,
            "source": preview["source"],
            "database_sha256_before": preview["database_sha256"],
            "database_sha256_after": output_hashes,
            "logical_target_count": EXPECTED_TARGET_COUNT,
            "physical_update_counts": {
                "work_normalized": EXPECTED_TARGET_COUNT,
                "work_legacy": EXPECTED_TARGET_COUNT,
                "seed_normalized": EXPECTED_TARGET_COUNT,
                "seed_legacy": EXPECTED_TARGET_COUNT,
                "already_expected": 0,
            },
            "sql": {
                "normalized": "UPDATE word_expression_set SET spelling=?, pronunciation=?, pronunciation_notation=?, pronunciation_notation_name=? WHERE word_id=? AND seq=?",
                "legacy": "UPDATE WORD_TABLE SET 표기1=?, 발음1=? WHERE id=?",
                "semantic_changes": [
                    "word_expression_set.spelling",
                    "WORD_TABLE.표기1",
                ],
            },
            "temporary_copy_validation": temporary_validation,
            "backup": {
                "directory": _portable_path(backup_dir),
                "work": migration._portable_backup_info(work_backup),
                "seed": migration._portable_backup_info(seed_backup),
            },
            "work": work_result,
            "seed": seed_result,
            "parity_before": preview["parity"],
            "parity_after": parity_after,
            "second_run_contract": {
                "status": "already_applied_noop_verified",
                "expected_change_count": 0,
                "backup_created": False,
                "transaction_started": False,
                "result_unchanged": True,
            },
            "runtime_migration_added": False,
        }
        migration._write_json_atomic(result_output, result_payload)
        result_written = True
        _result_matches_current(result_output, manifest, work_db, seed_db)
        return {
            "migration_id": MIGRATION_ID,
            "mode": "apply",
            "status": "적용 완료 — work 12, seed 12",
            "database_sha256_before": preview["database_sha256"],
            "database_sha256_after": output_hashes,
            "work_change_counts": work_result["change_counts"],
            "seed_change_counts": seed_result["change_counts"],
            "backup_directory": _portable_path(backup_dir),
            "result_artifact_path": _portable_path(result_output),
            "result_artifact_sha256": sha256_file(result_output),
            "parity": parity_after,
        }
    except Exception as error:
        restore_results: dict[str, object] = {}
        restore_errors: list[str] = []
        for label, db_path, backup in (
            ("work", work_db, work_backup),
            ("seed", seed_db, seed_backup),
        ):
            try:
                restore_results[label] = migration.restore_verified_backup(
                    db_path, backup
                )
            except Exception as restore_error:
                restore_errors.append(f"{label}: {restore_error}")
        if result_written and result_output.exists():
            result_output.unlink()
        if restore_errors:
            raise MigrationError(
                f"apply 실패 후 복원도 실패: cause={error}; restore={restore_errors}"
            ) from error
        raise MigrationError(
            f"apply 실패, 양쪽 backup 복원 완료: cause={error}; restore={restore_results}"
        ) from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    generate = subparsers.add_parser("generate-manifest")
    dry_run = subparsers.add_parser("dry-run")
    apply = subparsers.add_parser("apply")
    verify = subparsers.add_parser("verify")
    for child in (generate, dry_run, apply, verify):
        child.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
        child.add_argument("--work-db", default=str(DEFAULT_WORK_DB))
        child.add_argument("--seed-db", default=str(DEFAULT_SEED_DB))
        child.add_argument(
            "--source-manifest", default=str(DEFAULT_SOURCE_MANIFEST)
        )
        child.add_argument("--source-cache", default=str(DEFAULT_SOURCE_CACHE))
    apply.add_argument("--backup-root", default=str(DEFAULT_BACKUP_ROOT))
    apply.add_argument("--result-output", default=str(DEFAULT_RESULT))
    apply.add_argument("--confirm", required=True)
    verify.add_argument("--result", default=str(DEFAULT_RESULT))
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
                Path(args.source_cache),
            )
            manifest_sha = write_manifest(payload, Path(args.manifest))
            result = {
                "status": "manifest 생성 완료",
                "target_count": len(payload["targets"]),
                "target_projection_sha256": payload[
                    "target_projection_sha256"
                ],
                "manifest_sha256": manifest_sha,
            }
        elif args.command == "dry-run":
            result = run_dry_run(
                manifest_path=Path(args.manifest),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                source_manifest=Path(args.source_manifest),
                source_cache=Path(args.source_cache),
            )
        elif args.command == "apply":
            result = run_apply(
                manifest_path=Path(args.manifest),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                source_manifest=Path(args.source_manifest),
                source_cache=Path(args.source_cache),
                backup_root=Path(args.backup_root),
                result_output=Path(args.result_output),
                confirm_token=args.confirm,
            )
        else:
            result = run_verify(
                manifest_path=Path(args.manifest),
                result_path=Path(args.result),
                work_db=Path(args.work_db),
                seed_db=Path(args.seed_db),
                source_manifest=Path(args.source_manifest),
                source_cache=Path(args.source_cache),
            )
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (MigrationError, migration.MigrationError, OSError, sqlite3.Error, ValueError) as error:
        print(f"오류: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
