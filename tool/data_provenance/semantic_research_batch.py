#!/usr/bin/env python3
"""Recursive lexical cluster의 human semantic research preparation을 자동화한다."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from typing import Any

import biblical_research_evidence_packet as evidence
import biblical_research_evidence_review as review
import lexical_relation_discovery as discovery
import strong_source_diff as legacy
import strong_source_mapping as strong_mapping


TOOL_NAME = "Reshet Recursive Lexical Research Preparation"
TOOL_VERSION = "1.0.0"
STATE_SCHEMA_VERSION = 1
RELATION_SCHEMA_VERSION = 1
STATE_FILENAME = "00_research_state.json"
QUEUE_FILENAME = "00_review_queue.md"
ARTIFACT_FILENAME_RE = re.compile(
    r"^[GH][0-9]+_(?:evidence_packet\.json|lexical_relations\.json|review\.md)$"
)


class SemanticResearchBatchError(RuntimeError):
    """전역 계약 불일치 또는 안전하게 계속할 수 없는 상태."""


class ArtifactConflictError(SemanticResearchBatchError):
    """기존 artifact와 resume state의 관계를 입증할 수 없는 상태."""


def _strong_sort_key(value: str) -> tuple[int, int]:
    return (0 if value[0] == "G" else 1, int(value[1:]))


def normalize_seeds(values: list[str] | tuple[str, ...]) -> list[str]:
    normalized: set[str] = set()
    for value in values:
        strong = legacy.normalize_strong_number(value)
        if strong is None:
            raise SemanticResearchBatchError(
                f"유효한 standard Strong 번호가 아님: {value!r}"
            )
        normalized.add(strong)
    if not normalized:
        raise SemanticResearchBatchError("출발 Strong이 비어 있음")
    return sorted(normalized, key=_strong_sort_key)


def artifact_stem(strong: str) -> str:
    normalized = legacy.normalize_strong_number(strong)
    if normalized is None:
        raise SemanticResearchBatchError(
            f"artifact filename용 Strong이 유효하지 않음: {strong!r}"
        )
    return f"{normalized[0]}{int(normalized[1:])}"


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _json_bytes(value: object) -> bytes:
    return (
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def _json_safe(value: object) -> Any:
    return json.loads(
        json.dumps(value, ensure_ascii=False, sort_keys=True, default=str)
    )


def _atomic_replace(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
    except OSError as error:
        raise SemanticResearchBatchError(
            f"atomic artifact 기록 실패: {path}: {error}"
        ) from error
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def _resolved_path(path: Path) -> str:
    return path.resolve().as_posix()


def _run_options(
    *,
    output_dir: Path,
    local_sources: Path,
    work_db: Path,
    cache_dir: Path,
    strong_manifest: Path,
    occurrence_manifest: Path,
    local_manifest: Path,
    source_only_manifest: Path,
    dispositions_manifest: Path,
    allow_fetch: bool,
) -> dict[str, object]:
    return {
        "output_dir": _resolved_path(output_dir),
        "local_sources": _resolved_path(local_sources),
        "work_db": _resolved_path(work_db),
        "cache_dir": _resolved_path(cache_dir),
        "strong_manifest": _resolved_path(strong_manifest),
        "occurrence_manifest": _resolved_path(occurrence_manifest),
        "local_manifest": _resolved_path(local_manifest),
        "source_only_manifest": _resolved_path(source_only_manifest),
        "dispositions_manifest": _resolved_path(dispositions_manifest),
        "allow_fetch": allow_fetch,
        "max_nodes_identity": "excluded_per_execution_safety_limit",
    }


def _manifest_fingerprint(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise FileNotFoundError(f"manifest를 찾을 수 없음: {path}")
    return {
        "path": _resolved_path(path),
        "sha256": evidence.sha256_file(path),
    }


def _load_sources_and_authority(
    *,
    local_sources: Path,
    work_db: Path,
    cache_dir: Path,
    strong_manifest: Path,
    occurrence_manifest: Path,
    local_manifest: Path,
    source_only_manifest: Path,
    dispositions_manifest: Path,
    allow_fetch: bool,
) -> dict[str, object]:
    entries, source_paths, strong_provenance = evidence.load_strong_sources(
        strong_manifest, cache_dir, allow_fetch=allow_fetch
    )
    outgoing, incoming, index_stats = discovery.build_relation_indexes(
        source_paths, strong_provenance
    )
    approved_manifests = evidence.discover_approved_content_manifests()
    dispositions = evidence.load_semantic_research_dispositions(
        dispositions_manifest
    )
    (
        _,
        _,
        _,
        occurrence_provenance,
    ) = evidence.ensure_occurrence_sources(
        occurrence_manifest, cache_dir, allow_fetch=allow_fetch
    )
    _, local_specs, local_provenance = evidence.validate_local_sources(
        local_manifest, local_sources
    )
    if not work_db.is_file():
        raise FileNotFoundError(f"work DB를 찾을 수 없음: {work_db}")
    work_sha256 = evidence.sha256_file(work_db)
    source_fingerprints = {
        "strong_manifest": _manifest_fingerprint(strong_manifest),
        "strong_sources": _json_safe(strong_provenance),
        "occurrence_manifest": _manifest_fingerprint(occurrence_manifest),
        "occurrence_sources": _json_safe(occurrence_provenance),
        "local_manifest": _manifest_fingerprint(local_manifest),
        "local_reference_sources": _json_safe(local_provenance),
        "approved_content_manifests": [
            _manifest_fingerprint(path) for path in approved_manifests
        ],
        "source_only_manifest": _manifest_fingerprint(source_only_manifest),
        "semantic_research_dispositions": _manifest_fingerprint(
            dispositions_manifest
        ),
        "work_database": {
            "path": _resolved_path(work_db),
            "sha256": work_sha256,
        },
    }
    return {
        "entries": entries,
        "outgoing": outgoing,
        "incoming": incoming,
        "relation_index": index_stats,
        "strong_provenance": strong_provenance,
        "approved_manifests": approved_manifests,
        "dispositions": dispositions,
        "local_specs": local_specs,
        "local_provenance": local_provenance,
        "source_fingerprints": source_fingerprints,
    }


def _assert_run_sources_unchanged(
    *,
    bundle: dict[str, object],
    local_sources: Path,
    work_db: Path,
) -> None:
    fingerprints = bundle["source_fingerprints"]
    if not isinstance(fingerprints, dict):
        raise SemanticResearchBatchError("source fingerprint 내부 계약 불일치")
    work = fingerprints.get("work_database")
    if not isinstance(work, dict) or evidence.sha256_file(work_db) != work.get(
        "sha256"
    ):
        raise SemanticResearchBatchError("work DB가 batch read-only 실행 중 변경됨")
    local_rows = fingerprints.get("local_reference_sources")
    if not isinstance(local_rows, list):
        raise SemanticResearchBatchError("local source fingerprint 계약 불일치")
    for row in local_rows:
        if not isinstance(row, dict):
            raise SemanticResearchBatchError("local source fingerprint row 불일치")
        path = local_sources / str(row["filename"])
        if evidence.sha256_file(path) != row.get("actual_sha256"):
            raise SemanticResearchBatchError(
                f"local source가 batch 실행 중 변경됨: {path.name}"
            )


def _check_new_output(output_dir: Path) -> None:
    if not output_dir.exists():
        return
    if not output_dir.is_dir():
        raise SemanticResearchBatchError(
            f"output 경로가 디렉터리가 아님: {output_dir}"
        )
    conflicts = sorted(
        path.name
        for path in output_dir.iterdir()
        if path.is_file()
        and (
            path.name in {STATE_FILENAME, QUEUE_FILENAME}
            or ARTIFACT_FILENAME_RE.fullmatch(path.name) is not None
        )
    )
    if conflicts:
        raise ArtifactConflictError(
            "resume state 없는 기존 research artifact가 있음: "
            + ", ".join(conflicts)
        )


def _load_state(path: Path) -> dict[str, object]:
    if not path.is_file():
        raise SemanticResearchBatchError(f"resume state를 찾을 수 없음: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SemanticResearchBatchError(
            f"resume state를 읽거나 parsing할 수 없음: {path}: {error}"
        ) from error
    if not isinstance(value, dict):
        raise SemanticResearchBatchError("resume state root가 object가 아님")
    return value


def _validate_resume_state(
    state: dict[str, object],
    *,
    seeds: list[str],
    options: dict[str, object],
    source_fingerprints: dict[str, object],
) -> None:
    if state.get("schema_version") != STATE_SCHEMA_VERSION:
        raise SemanticResearchBatchError("resume state schema가 호환되지 않음")
    tool = state.get("tool")
    if not isinstance(tool, dict) or tool != {
        "name": TOOL_NAME,
        "version": TOOL_VERSION,
    }:
        raise SemanticResearchBatchError("resume state tool/version이 호환되지 않음")
    if state.get("seeds") != seeds:
        raise SemanticResearchBatchError("resume seed/cluster identity 불일치")
    if state.get("options") != options:
        raise SemanticResearchBatchError("resume relevant option 불일치")
    if state.get("source_fingerprints") != source_fingerprints:
        raise SemanticResearchBatchError("resume source fingerprint 불일치")
    if not isinstance(state.get("cluster"), dict) or not isinstance(
        state.get("nodes"), list
    ):
        raise SemanticResearchBatchError("resume state cluster/node 계약 불일치")


def _artifact_paths(strong: str) -> dict[str, str]:
    stem = artifact_stem(strong)
    return {
        "evidence_packet": f"{stem}_evidence_packet.json",
        "lexical_relations": f"{stem}_lexical_relations.json",
        "review": f"{stem}_review.md",
    }


def _node_map(state: dict[str, object]) -> dict[str, dict[str, object]]:
    raw_nodes = state.get("nodes")
    if not isinstance(raw_nodes, list):
        raise SemanticResearchBatchError("state nodes가 배열이 아님")
    nodes: dict[str, dict[str, object]] = {}
    for raw_node in raw_nodes:
        if not isinstance(raw_node, dict):
            raise SemanticResearchBatchError("state node가 object가 아님")
        strong = raw_node.get("strong")
        if not isinstance(strong, str) or strong in nodes:
            raise SemanticResearchBatchError("state node Strong 중복/형식 불일치")
        nodes[strong] = raw_node
    return nodes


def _validate_recorded_artifacts(
    state: dict[str, object], output_dir: Path
) -> None:
    recorded_paths: set[str] = set()
    for node in _node_map(state).values():
        preparation = node.get("preparation")
        if not isinstance(preparation, dict):
            raise SemanticResearchBatchError("state preparation 계약 불일치")
        artifacts = preparation.get("artifacts")
        if not isinstance(artifacts, dict):
            raise SemanticResearchBatchError("state artifacts 계약 불일치")
        for record in artifacts.values():
            if not isinstance(record, dict):
                raise SemanticResearchBatchError("state artifact row 계약 불일치")
            relative = record.get("path")
            expected_hash = record.get("sha256")
            if not isinstance(relative, str) or not isinstance(expected_hash, str):
                raise SemanticResearchBatchError("state artifact path/hash 계약 불일치")
            path = output_dir / relative
            if path.parent.resolve() != output_dir.resolve():
                raise SemanticResearchBatchError("state artifact가 flat output을 벗어남")
            if not path.is_file():
                raise ArtifactConflictError(f"기록된 artifact가 없음: {relative}")
            actual_hash = evidence.sha256_file(path)
            if actual_hash != expected_hash:
                raise ArtifactConflictError(
                    f"기록된 artifact hash 불일치: {relative}"
                )
            recorded_paths.add(relative)

    for node in _node_map(state).values():
        for relative in _artifact_paths(str(node["strong"])).values():
            if (output_dir / relative).exists() and relative not in recorded_paths:
                raise ArtifactConflictError(
                    f"state에 기록되지 않은 기존 artifact가 있음: {relative}"
                )


def _sync_nodes_from_cluster(state: dict[str, object]) -> None:
    cluster = state["cluster"]
    if not isinstance(cluster, dict) or not isinstance(
        cluster.get("discovered_nodes"), list
    ):
        raise SemanticResearchBatchError("cluster discovered_nodes 계약 불일치")
    existing = _node_map(state)
    synced: list[dict[str, object]] = []
    for discovery_node in cluster["discovered_nodes"]:
        if not isinstance(discovery_node, dict):
            raise SemanticResearchBatchError("cluster node 계약 불일치")
        strong = str(discovery_node["strong"])
        node = existing.get(strong)
        if node is None:
            node = {
                "strong": strong,
                "artifact_stem": artifact_stem(strong),
                "discovery": discovery_node,
                "classification": None,
                "completion_gate": None,
                "disposition": None,
                "current_reshet_projection": None,
                "preparation": {
                    "state": "pending_cluster",
                    "artifacts": {},
                    "error": None,
                },
            }
        else:
            node["discovery"] = discovery_node
        synced.append(node)
    state["nodes"] = synced


def _classify_nodes(
    state: dict[str, object],
    *,
    bundle: dict[str, object],
    work_db: Path,
    source_only_manifest: Path,
) -> None:
    nodes = _node_map(state)
    classified = [node["classification"] is not None for node in nodes.values()]
    if any(classified):
        if not all(classified):
            raise SemanticResearchBatchError("부분 authority classification state 불일치")
        return
    raw_dispositions = bundle.get("dispositions")
    approved_manifests = bundle.get("approved_manifests")
    if not isinstance(raw_dispositions, list) or not isinstance(
        approved_manifests, (list, tuple)
    ):
        raise SemanticResearchBatchError("authority bundle 계약 불일치")
    dispositions = {
        str(row["strong_number"]): row
        for row in raw_dispositions
        if isinstance(row, dict)
    }
    for node in nodes.values():
        strong = str(node["strong"])
        projection, _ = evidence.load_reshet_projection(work_db, strong)
        completion_gate = evidence.completion_gate_state(
            strong,
            projection,
            list(approved_manifests),
            source_only_manifest,
        )
        is_approved = completion_gate.get("state") == "explicit_approved"
        disposition = dispositions.get(strong)
        is_hold = disposition is not None
        if is_approved and is_hold:
            raise SemanticResearchBatchError(
                f"active explicit_approved와 hold authority가 겹침: {strong}"
            )
        if is_approved:
            classification = "explicit_approved"
        elif is_hold:
            classification = "hold"
        else:
            classification = "unapproved"
        node["classification"] = classification
        node["completion_gate"] = completion_gate
        node["disposition"] = disposition
        node["current_reshet_projection"] = projection
        node["preparation"] = {
            "state": "reused" if classification != "unapproved" else "pending",
            "artifacts": {},
            "error": None,
        }


def _preparation_label(node: dict[str, object]) -> str:
    preparation = node["preparation"]
    if not isinstance(preparation, dict):
        raise SemanticResearchBatchError("node preparation 계약 불일치")
    state = preparation.get("state")
    return {
        "ready": "READY",
        "evidence_ready": "PARTIAL",
        "error": "ERROR",
        "reused": "existing",
        "pending": "PENDING",
        "pending_cluster": "DISCOVERY",
    }.get(str(state), str(state))


def _related_status(node: dict[str, object]) -> tuple[str, str]:
    classification = str(node.get("classification") or "unapproved")
    preparation = node.get("preparation")
    preparation_state = (
        str(preparation.get("state")) if isinstance(preparation, dict) else "pending"
    )
    if classification == "explicit_approved":
        return "explicit_approved", "reused"
    if classification == "hold":
        return "hold", "reused"
    if preparation_state in {"evidence_ready", "ready"}:
        return "prepared", "READY"
    if preparation_state == "error":
        return "error", "ERROR"
    return "unapproved", "PENDING"


def build_node_relation_context(
    state: dict[str, object], strong: str
) -> dict[str, object]:
    nodes = _node_map(state)
    target = nodes[strong]
    cluster = state["cluster"]
    if not isinstance(cluster, dict) or not isinstance(cluster.get("relations"), list):
        raise SemanticResearchBatchError("cluster relation 계약 불일치")
    incident: list[dict[str, object]] = []
    for raw_relation in cluster["relations"]:
        if not isinstance(raw_relation, dict):
            raise SemanticResearchBatchError("cluster relation row 계약 불일치")
        from_strong = str(raw_relation["from_strong"])
        to_strong = str(raw_relation["to_strong"])
        if strong == from_strong:
            direction = "outgoing"
            related_strong = to_strong
        elif strong == to_strong:
            direction = "incoming"
            related_strong = from_strong
        else:
            continue
        related_status, related_preparation = _related_status(
            nodes[related_strong]
        )
        incident.append(
            {
                "from_strong": from_strong,
                "to_strong": to_strong,
                "node_direction": direction,
                "source": str(raw_relation["source"]),
                "source_container": str(raw_relation["source_container"]),
                "relation_wording": raw_relation.get("relation_wording"),
                "source_text": raw_relation.get("source_text"),
                "reference_context": raw_relation.get("reference_context"),
                "reference_evidence": raw_relation.get("reference_evidence", []),
                "related_strong": related_strong,
                "related_status": related_status,
                "related_preparation": related_preparation,
            }
        )
    incident.sort(
        key=lambda row: (
            0 if row["node_direction"] == "outgoing" else 1,
            _strong_sort_key(str(row["related_strong"])),
            str(row["source"]),
            str(row["relation_wording"] or ""),
        )
    )
    return {
        "schema_version": RELATION_SCHEMA_VERSION,
        "tool": {"name": TOOL_NAME, "version": TOOL_VERSION},
        "target": {
            "normalized_strong": strong,
            "status": target["classification"],
            "preparation": "READY",
            "completion_gate": target["completion_gate"],
            "disposition": target["disposition"],
        },
        "relations": incident,
        "scope": {
            "research_discovery_only": True,
            "semantic_relation_assertion": False,
            "database_write": False,
        },
    }


def _record_error(
    node: dict[str, object], *, phase: str, error: Exception
) -> None:
    preparation = node["preparation"]
    if not isinstance(preparation, dict):
        raise SemanticResearchBatchError("node preparation 계약 불일치")
    preparation["state"] = "error"
    preparation["error"] = {
        "phase": phase,
        "type": type(error).__name__,
        "message": str(error),
    }


def _write_node_artifact(
    *,
    node: dict[str, object],
    logical_name: str,
    output_dir: Path,
    content: bytes,
) -> None:
    preparation = node["preparation"]
    if not isinstance(preparation, dict) or not isinstance(
        preparation.get("artifacts"), dict
    ):
        raise SemanticResearchBatchError("node artifact state 계약 불일치")
    artifacts = preparation["artifacts"]
    relative = _artifact_paths(str(node["strong"]))[logical_name]
    expected_hash = _sha256_bytes(content)
    existing_record = artifacts.get(logical_name)
    if existing_record is not None:
        if not isinstance(existing_record, dict):
            raise SemanticResearchBatchError("기록된 node artifact 계약 불일치")
        if existing_record != {"path": relative, "sha256": expected_hash}:
            raise ArtifactConflictError(
                f"resume artifact 내용/기록 불일치: {relative}"
            )
        path = output_dir / relative
        if not path.is_file() or evidence.sha256_file(path) != expected_hash:
            raise ArtifactConflictError(f"resume artifact hash 불일치: {relative}")
        return
    path = output_dir / relative
    if path.exists():
        raise ArtifactConflictError(
            f"state 없이 예상하지 못한 기존 artifact가 있음: {relative}"
        )
    _atomic_replace(path, content)
    artifacts[logical_name] = {"path": relative, "sha256": expected_hash}


def render_review_queue(state: dict[str, object]) -> bytes:
    nodes = list(_node_map(state).values())

    def queue_key(node: dict[str, object]) -> tuple[int, tuple[int, int]]:
        preparation = node["preparation"]
        state_value = (
            str(preparation.get("state"))
            if isinstance(preparation, dict)
            else "pending_cluster"
        )
        group = {
            "error": 0,
            "ready": 1,
            "evidence_ready": 2,
            "pending": 3,
            "pending_cluster": 4,
            "reused": 5,
        }.get(state_value, 6)
        return group, _strong_sort_key(str(node["strong"]))

    lines = [
        "# Semantic research review queue",
        "",
        "> 이 파일은 automation derivative이며 semantic authority가 아니다. 승인 manifest, completion gate, disposition ledger와 canonical DB가 authority다.",
        "",
        "READY는 research preparation 완료 및 human semantic review 대기 상태만 뜻한다.",
        "",
        "| Strong | preparation | disposition | completion_gate | discovery | artifacts/error |",
        "|---|---|---|---|---|---|",
    ]
    for node in sorted(nodes, key=queue_key):
        preparation = node["preparation"]
        if not isinstance(preparation, dict):
            raise SemanticResearchBatchError("queue preparation 계약 불일치")
        disposition = node.get("disposition")
        disposition_label = (
            str(disposition.get("status"))
            if isinstance(disposition, dict)
            else "—"
        )
        completion = node.get("completion_gate")
        completion_label = (
            str(completion.get("state")) if isinstance(completion, dict) else "—"
        )
        discovery_node = node.get("discovery")
        parent = (
            discovery_node.get("parent")
            if isinstance(discovery_node, dict)
            else None
        )
        discovery_label = (
            "seed"
            if parent is None
            else f"{parent}에서 {discovery_node.get('direction')}"
        )
        error = preparation.get("error")
        if isinstance(error, dict):
            artifact_label = (
                f"{error.get('phase')}: {error.get('type')}: {error.get('message')}"
            )
        else:
            artifacts = preparation.get("artifacts")
            artifact_names = (
                sorted(
                    str(record["path"])
                    for record in artifacts.values()
                    if isinstance(record, dict) and "path" in record
                )
                if isinstance(artifacts, dict)
                else []
            )
            artifact_label = (
                ", ".join(artifact_names)
                if artifact_names
                else ("reused" if preparation.get("state") == "reused" else "—")
            )
        escaped = [
            str(node["artifact_stem"]),
            _preparation_label(node),
            disposition_label,
            completion_label,
            discovery_label,
            artifact_label,
        ]
        escaped = [value.replace("|", "\\|").replace("\n", " ") for value in escaped]
        lines.append("| " + " | ".join(escaped) + " |")
    return ("\n".join(lines) + "\n").encode("utf-8")


def _persist_control_files(state: dict[str, object], output_dir: Path) -> None:
    _atomic_replace(output_dir / STATE_FILENAME, _json_bytes(state))
    _atomic_replace(output_dir / QUEUE_FILENAME, render_review_queue(state))


def _initial_state(
    *,
    seeds: list[str],
    options: dict[str, object],
    source_fingerprints: dict[str, object],
    relation_index: object,
    strong_provenance: object,
) -> dict[str, object]:
    return {
        "schema_version": STATE_SCHEMA_VERSION,
        "tool": {"name": TOOL_NAME, "version": TOOL_VERSION},
        "seeds": seeds,
        "source_fingerprints": source_fingerprints,
        "options": options,
        "cluster": {
            "seeds": seeds,
            "discovered_nodes": [],
            "relations": [],
            "visited": [],
            "frontier": seeds,
            "discovery_complete": False,
            "stopped_reason": None,
            "relation_index": _json_safe(relation_index),
            "source_provenance": _json_safe(strong_provenance),
        },
        "nodes": [],
        "discovery_complete": False,
        "research_complete": False,
        "stopped_reason": None,
        "global_error": None,
    }


def _finalize_state(state: dict[str, object]) -> None:
    if not state.get("discovery_complete"):
        state["research_complete"] = False
        state["stopped_reason"] = "max_nodes_reached"
        return
    preparations = [
        node["preparation"]
        for node in _node_map(state).values()
        if isinstance(node.get("preparation"), dict)
    ]
    if any(preparation.get("state") == "error" for preparation in preparations):
        state["research_complete"] = False
        state["stopped_reason"] = "node_preparation_error"
    elif any(
        preparation.get("state") in {"pending", "pending_cluster", "evidence_ready"}
        for preparation in preparations
    ):
        state["research_complete"] = False
        state["stopped_reason"] = "max_nodes_reached"
    else:
        state["research_complete"] = True
        state["stopped_reason"] = None


def run_batch(
    seeds: list[str] | tuple[str, ...],
    *,
    local_sources: Path,
    output_dir: Path,
    work_db: Path = evidence.DEFAULT_WORK_DB,
    cache_dir: Path = evidence.DEFAULT_CACHE,
    strong_manifest: Path = evidence.DEFAULT_STRONG_MANIFEST,
    occurrence_manifest: Path = evidence.DEFAULT_OCCURRENCE_MANIFEST,
    local_manifest: Path = evidence.DEFAULT_LOCAL_MANIFEST,
    source_only_manifest: Path = evidence.DEFAULT_SOURCE_ONLY_MANIFEST,
    dispositions_manifest: Path = evidence.DEFAULT_SEMANTIC_RESEARCH_DISPOSITIONS,
    allow_fetch: bool = True,
    resume: bool = False,
    max_nodes: int | None = None,
) -> dict[str, object]:
    if max_nodes is not None and (type(max_nodes) is not int or max_nodes < 1):
        raise SemanticResearchBatchError("max nodes는 1 이상의 정수여야 함")
    normalized_seeds = normalize_seeds(seeds)
    options = _run_options(
        output_dir=output_dir,
        local_sources=local_sources,
        work_db=work_db,
        cache_dir=cache_dir,
        strong_manifest=strong_manifest,
        occurrence_manifest=occurrence_manifest,
        local_manifest=local_manifest,
        source_only_manifest=source_only_manifest,
        dispositions_manifest=dispositions_manifest,
        allow_fetch=allow_fetch,
    )
    if resume:
        if not output_dir.is_dir():
            raise SemanticResearchBatchError(
                f"resume output directory를 찾을 수 없음: {output_dir}"
            )
    else:
        _check_new_output(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

    bundle = _load_sources_and_authority(
        local_sources=local_sources,
        work_db=work_db,
        cache_dir=cache_dir,
        strong_manifest=strong_manifest,
        occurrence_manifest=occurrence_manifest,
        local_manifest=local_manifest,
        source_only_manifest=source_only_manifest,
        dispositions_manifest=dispositions_manifest,
        allow_fetch=allow_fetch,
    )
    source_fingerprints = bundle.get("source_fingerprints")
    if not isinstance(source_fingerprints, dict):
        raise SemanticResearchBatchError("source fingerprint bundle 계약 불일치")
    state_path = output_dir / STATE_FILENAME
    if resume:
        state = _load_state(state_path)
        _validate_resume_state(
            state,
            seeds=normalized_seeds,
            options=options,
            source_fingerprints=source_fingerprints,
        )
        _validate_recorded_artifacts(state, output_dir)
    else:
        state = _initial_state(
            seeds=normalized_seeds,
            options=options,
            source_fingerprints=source_fingerprints,
            relation_index=bundle.get("relation_index"),
            strong_provenance=bundle.get("strong_provenance"),
        )

    entries = bundle.get("entries")
    if not isinstance(entries, dict):
        raise SemanticResearchBatchError("Strong entry bundle 계약 불일치")
    missing_seeds = [strong for strong in normalized_seeds if strong not in entries]
    if missing_seeds:
        raise SemanticResearchBatchError(
            "고정 Strong source entry가 없는 seed: " + ", ".join(missing_seeds)
        )
    outgoing = bundle.get("outgoing")
    incoming = bundle.get("incoming")
    if not isinstance(outgoing, dict) or not isinstance(incoming, dict):
        raise SemanticResearchBatchError("relation index bundle 계약 불일치")

    previous_cluster = state.get("cluster")
    if not isinstance(previous_cluster, dict):
        raise SemanticResearchBatchError("state cluster 계약 불일치")
    closure_input = {
        key: previous_cluster[key]
        for key in (
            "seeds",
            "discovered_nodes",
            "relations",
            "visited",
            "frontier",
            "discovery_complete",
            "stopped_reason",
        )
        if key in previous_cluster
    }
    closure = discovery.discover_relation_closure(
        normalized_seeds,
        outgoing,
        incoming,
        previous=(closure_input if closure_input["discovered_nodes"] else None),
        max_nodes=max_nodes,
    )
    expanded_this_run = int(closure.pop("expanded_this_run"))
    closure["expanded_node_count"] = len(closure["visited"])
    closure["relation_index"] = previous_cluster.get("relation_index")
    closure["source_provenance"] = previous_cluster.get("source_provenance")
    state["cluster"] = closure
    state["discovery_complete"] = bool(closure["discovery_complete"])
    _sync_nodes_from_cluster(state)
    state["research_complete"] = False
    state["stopped_reason"] = closure["stopped_reason"]
    state["global_error"] = None
    _persist_control_files(state, output_dir)
    if not state["discovery_complete"]:
        _assert_run_sources_unchanged(
            bundle=bundle, local_sources=local_sources, work_db=work_db
        )
        return state

    try:
        _classify_nodes(
            state,
            bundle=bundle,
            work_db=work_db,
            source_only_manifest=source_only_manifest,
        )
    except Exception as error:
        state["discovery_complete"] = False
        closure["discovery_complete"] = False
        closure["stopped_reason"] = "authority_classification_error"
        state["research_complete"] = False
        state["stopped_reason"] = "authority_classification_error"
        state["global_error"] = {
            "phase": "authority_classification",
            "type": type(error).__name__,
            "message": str(error),
        }
        _persist_control_files(state, output_dir)
        raise
    _persist_control_files(state, output_dir)

    remaining = None if max_nodes is None else max_nodes - expanded_this_run
    nodes_in_discovery_order = list(_node_map(state).values())
    for node in nodes_in_discovery_order:
        preparation = node["preparation"]
        if not isinstance(preparation, dict) or preparation.get("state") != "pending":
            continue
        if remaining is not None and remaining <= 0:
            break
        strong = str(node["strong"])
        try:
            packet = evidence.build_evidence_packet(
                strong,
                local_sources=local_sources,
                work_db=work_db,
                strong_manifest=strong_manifest,
                occurrence_manifest=occurrence_manifest,
                local_manifest=local_manifest,
                approved_manifest=list(bundle["approved_manifests"]),
                source_only_manifest=source_only_manifest,
                cache_dir=cache_dir,
                allow_fetch=allow_fetch,
            )
            _write_node_artifact(
                node=node,
                logical_name="evidence_packet",
                output_dir=output_dir,
                content=evidence.serialize_packet(packet),
            )
            preparation["state"] = "evidence_ready"
            preparation["error"] = None
        except Exception as error:  # 개별 Strong 실패 격리 계약
            _record_error(node, phase="evidence_packet", error=error)
        if remaining is not None:
            remaining -= 1
        _persist_control_files(state, output_dir)

    unapproved_nodes = [
        node
        for node in nodes_in_discovery_order
        if node.get("classification") == "unapproved"
    ]
    evidence_terminal = all(
        isinstance(node.get("preparation"), dict)
        and node["preparation"].get("state")
        in {"evidence_ready", "ready", "error"}
        for node in unapproved_nodes
    )
    if evidence_terminal:
        for node in unapproved_nodes:
            preparation = node["preparation"]
            if not isinstance(preparation, dict) or preparation.get("state") != "evidence_ready":
                continue
            strong = str(node["strong"])
            try:
                packet_record = preparation["artifacts"]["evidence_packet"]
                packet_path = output_dir / str(packet_record["path"])
                packet = review.load_packet(packet_path)
                relation_context = build_node_relation_context(state, strong)
                _write_node_artifact(
                    node=node,
                    logical_name="lexical_relations",
                    output_dir=output_dir,
                    content=_json_bytes(relation_context),
                )
                _write_node_artifact(
                    node=node,
                    logical_name="review",
                    output_dir=output_dir,
                    content=review.serialize_review(packet, relation_context),
                )
                preparation["state"] = "ready"
                preparation["error"] = None
            except Exception as error:  # 개별 Strong 실패 격리 계약
                _record_error(node, phase="relation_review", error=error)
            _persist_control_files(state, output_dir)

    _assert_run_sources_unchanged(
        bundle=bundle, local_sources=local_sources, work_db=work_db
    )
    _finalize_state(state)
    _persist_control_files(state, output_dir)
    return state


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "하나 이상의 Strong에서 양방향 lexical cluster를 closure 탐색하고 "
            "미승인 node의 semantic research 자료를 준비합니다."
        )
    )
    parser.add_argument("strong", nargs="+", help="출발 Strong 하나 이상")
    parser.add_argument(
        "--local-sources",
        type=Path,
        required=True,
        help="승인된 로컬 연구 참고자료 6개가 있는 디렉터리",
    )
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--work-db", type=Path, default=evidence.DEFAULT_WORK_DB)
    parser.add_argument("--cache-dir", type=Path, default=evidence.DEFAULT_CACHE)
    parser.add_argument(
        "--strong-manifest", type=Path, default=evidence.DEFAULT_STRONG_MANIFEST
    )
    parser.add_argument(
        "--occurrence-manifest",
        type=Path,
        default=evidence.DEFAULT_OCCURRENCE_MANIFEST,
    )
    parser.add_argument(
        "--local-manifest", type=Path, default=evidence.DEFAULT_LOCAL_MANIFEST
    )
    parser.add_argument(
        "--source-only-manifest",
        type=Path,
        default=evidence.DEFAULT_SOURCE_ONLY_MANIFEST,
    )
    parser.add_argument(
        "--dispositions-manifest",
        type=Path,
        default=evidence.DEFAULT_SEMANTIC_RESEARCH_DISPOSITIONS,
    )
    parser.add_argument(
        "--max-nodes",
        type=int,
        help=(
            "이번 실행에서 확장/준비할 node 안전 제한. semantic boundary가 아니며 "
            "미완료 frontier는 state에 보존"
        ),
    )
    parser.add_argument(
        "--resume", action="store_true", help="기존 00_research_state.json에서 재개"
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="cache가 없을 때 다운로드하지 않고 fail-closed",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        state = run_batch(
            args.strong,
            local_sources=args.local_sources,
            output_dir=args.output_dir,
            work_db=args.work_db,
            cache_dir=args.cache_dir,
            strong_manifest=args.strong_manifest,
            occurrence_manifest=args.occurrence_manifest,
            local_manifest=args.local_manifest,
            source_only_manifest=args.source_only_manifest,
            dispositions_manifest=args.dispositions_manifest,
            allow_fetch=not args.offline,
            resume=args.resume,
            max_nodes=args.max_nodes,
        )
    except (
        SemanticResearchBatchError,
        evidence.EvidencePacketError,
        FileNotFoundError,
        strong_mapping.ManifestError,
        legacy.SourceSchemaError,
    ) as error:
        sys.stderr.reconfigure(encoding="utf-8", errors="strict", newline="\n")
        print(f"오류: {error}", file=sys.stderr)
        return 2
    return 0 if state.get("research_complete") is True else 1


if __name__ == "__main__":
    raise SystemExit(main())
