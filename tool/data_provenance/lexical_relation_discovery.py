#!/usr/bin/env python3
"""고정 Strong source의 명시적 lexical relation을 bounded traversal한다."""

from __future__ import annotations

import argparse
from collections import defaultdict, deque
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

import biblical_research_evidence_packet as evidence
import strong_source_diff as legacy
import strong_source_mapping as strong_mapping


TOOL_VERSION = "1.2.0"
DEFAULT_MAX_DEPTH = 2
MIN_MAX_DEPTH = 1
MAX_MAX_DEPTH = 3


class LexicalRelationDiscoveryError(evidence.EvidencePacketError):
    pass


def _strong_sort_key(value: str) -> tuple[int, int]:
    return (0 if value[0] == "G" else 1, int(value[1:]))


def _edge_sort_key(edge: dict[str, object]) -> tuple[object, ...]:
    return (
        _strong_sort_key(str(edge["from_strong"])),
        _strong_sort_key(str(edge["to_strong"])),
        str(edge["relation_wording"] or ""),
        str(edge["source"]),
        int(edge["source_order"]),
    )


def _validate_max_depth(max_depth: int) -> None:
    if not MIN_MAX_DEPTH <= max_depth <= MAX_MAX_DEPTH:
        raise LexicalRelationDiscoveryError(
            f"max depth는 {MIN_MAX_DEPTH}~{MAX_MAX_DEPTH}만 허용됨: {max_depth}"
        )


def _relation_candidates(
    current: str,
    outgoing: dict[str, list[dict[str, object]]],
    incoming: dict[str, list[dict[str, object]]],
) -> list[tuple[dict[str, object], str, str]]:
    candidates = [
        (edge, "outgoing", str(edge["to_strong"]))
        for edge in outgoing.get(current, [])
    ]
    candidates.extend(
        (edge, "incoming", str(edge["from_strong"]))
        for edge in incoming.get(current, [])
    )
    candidates.sort(
        key=lambda item: (
            0 if item[1] == "outgoing" else 1,
            _strong_sort_key(item[2]),
            _edge_sort_key(item[0]),
        )
    )
    return candidates


def _relation_edge_key(edge: dict[str, object]) -> tuple[str, str, str, str]:
    return (
        str(edge["from_strong"]),
        str(edge["to_strong"]),
        str(edge["relation_wording"] or ""),
        str(edge["source"]),
    )


def build_relation_indexes(
    source_paths: dict[str, Path],
    source_provenance: list[dict[str, object]],
) -> tuple[
    dict[str, list[dict[str, object]]],
    dict[str, list[dict[str, object]]],
    dict[str, int],
]:
    """각 고정 XML을 한 번 읽어 outgoing과 in-memory reverse index를 만든다."""
    source_ids = {
        str(row["language"]): str(row["id"])
        for row in source_provenance
        if row.get("language") in {"G", "H"}
    }
    edge_by_key: dict[tuple[str, str, str, str], dict[str, object]] = {}
    entry_count = 0
    reference_count = 0
    reference_evidence_occurrence_count = 0
    invalid_reference_count = 0
    reference_container_counts: defaultdict[str, int] = defaultdict(int)

    for prefix in sorted(source_paths):
        source_path = source_paths[prefix]
        source_id = source_ids.get(prefix)
        if source_id is None:
            raise LexicalRelationDiscoveryError(
                f"Strong source provenance language 누락: {prefix}"
            )
        try:
            root = ET.parse(source_path).getroot()
        except ET.ParseError as error:
            raise evidence.SourceSchemaError(
                f"Strong relation XML parsing 실패: {source_path}: {error}"
            ) from error

        for entry in root.iter():
            if legacy.local_name(entry.tag) != "entry":
                continue
            raw_strong = entry.get("strongs") if prefix == "G" else entry.get("id")
            source_strong = legacy.normalize_strong_number(raw_strong, prefix)
            if source_strong is None:
                continue
            entry_count += 1
            references = evidence.extract_relation_discovery_references(
                entry, source_strong
            )
            reference_count += len(references)
            for reference in references:
                reference_container_counts[
                    f"{prefix}:{reference['source_container']}"
                ] += 1
                target = reference["normalized_strong"]
                if not isinstance(target, str):
                    invalid_reference_count += 1
                    continue
                reference_evidence_occurrence_count += 1
                relation_wording = reference["relation_wording"]
                edge_key = (
                    source_strong,
                    target,
                    str(relation_wording or ""),
                    source_id,
                )
                if edge_key in edge_by_key:
                    occurrences = edge_by_key[edge_key]["reference_evidence"]
                    if not isinstance(occurrences, list):
                        raise LexicalRelationDiscoveryError(
                            "relation edge reference evidence 내부 계약 불일치"
                        )
                    occurrences.append(reference)
                    edge_by_key[edge_key]["reference_evidence_count"] = len(
                        occurrences
                    )
                    continue
                edge_by_key[edge_key] = {
                    "from_strong": source_strong,
                    "to_strong": target,
                    "relation_wording": relation_wording,
                    "source": source_id,
                    "source_container": reference["source_container"],
                    "source_order": reference["source_order"],
                    "source_text": reference["source_text"],
                    "reference_context": reference["reference_context"],
                    "reference_evidence_count": 1,
                    "reference_evidence": [reference],
                }

    outgoing: defaultdict[str, list[dict[str, object]]] = defaultdict(list)
    incoming: defaultdict[str, list[dict[str, object]]] = defaultdict(list)
    edges = sorted(edge_by_key.values(), key=_edge_sort_key)
    for edge in edges:
        outgoing[str(edge["from_strong"])].append(edge)
        incoming[str(edge["to_strong"])].append(edge)
    return (
        dict(outgoing),
        dict(incoming),
        {
            "entry_count": entry_count,
            "reference_count": reference_count,
            "reference_evidence_occurrence_count": reference_evidence_occurrence_count,
            "explicit_edge_count": len(edges),
            "invalid_reference_count": invalid_reference_count,
            "reference_container_counts": dict(sorted(reference_container_counts.items())),
        },
    )


def discover_relation_graph(
    target: str,
    max_depth: int,
    outgoing: dict[str, list[dict[str, object]]],
    incoming: dict[str, list[dict[str, object]]],
) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    _validate_max_depth(max_depth)
    node_by_strong: dict[str, dict[str, object]] = {
        target: {
            "strong": target,
            "depth": 0,
            "parent": None,
            "direction": None,
            "relation_wording": None,
            "source": None,
            "discovery_path": [],
        }
    }
    queue: deque[str] = deque([target])
    emitted_edges: set[tuple[str, str, str, str]] = set()
    relations: list[dict[str, object]] = []

    while queue:
        current = queue.popleft()
        current_node = node_by_strong[current]
        current_depth = int(current_node["depth"])
        if current_depth >= max_depth:
            continue

        for edge, direction, discovered_strong in _relation_candidates(
            current, outgoing, incoming
        ):
            edge_key = _relation_edge_key(edge)
            if edge_key in emitted_edges:
                continue
            emitted_edges.add(edge_key)
            depth = current_depth + 1
            discovered_new_node = discovered_strong not in node_by_strong
            relation = {
                **edge,
                "direction": direction,
                "depth": depth,
                "parent": current,
                "discovered_strong": discovered_strong,
                "discovered_new_node": discovered_new_node,
            }
            relations.append(relation)

            if not discovered_new_node:
                continue
            path_step = {
                "from_strong": edge["from_strong"],
                "to_strong": edge["to_strong"],
                "direction": direction,
                "relation_wording": edge["relation_wording"],
                "source": edge["source"],
                "parent": current,
                "strong": discovered_strong,
            }
            node_by_strong[discovered_strong] = {
                "strong": discovered_strong,
                "depth": depth,
                "parent": current,
                "direction": direction,
                "relation_wording": edge["relation_wording"],
                "source": edge["source"],
                "discovery_path": [
                    *list(current_node["discovery_path"]),
                    path_step,
                ],
            }
            queue.append(discovered_strong)

    discovered_nodes = sorted(
        node_by_strong.values(),
        key=lambda node: (int(node["depth"]), _strong_sort_key(str(node["strong"]))),
    )
    relations.sort(
        key=lambda edge: (
            int(edge["depth"]),
            _strong_sort_key(str(edge["parent"])),
            0 if edge["direction"] == "outgoing" else 1,
            _strong_sort_key(str(edge["discovered_strong"])),
            _edge_sort_key(edge),
        )
    )
    return discovered_nodes, relations


def discover_relation_closure(
    seeds: list[str] | tuple[str, ...],
    outgoing: dict[str, list[dict[str, object]]],
    incoming: dict[str, list[dict[str, object]]],
    *,
    previous: dict[str, object] | None = None,
    max_nodes: int | None = None,
) -> dict[str, object]:
    """양방향 connected lexical component를 BFS로 확장하고 resume 상태를 반환한다.

    ``max_nodes``는 이번 호출에서 확장할 frontier node 수만 제한한다. 발견된
    component의 semantic 경계가 아니며, 제한에 도달하면 미확장 frontier를 그대로
    보존한다.
    """
    if max_nodes is not None and (type(max_nodes) is not int or max_nodes < 1):
        raise LexicalRelationDiscoveryError("max nodes는 1 이상의 정수여야 함")

    normalized_seeds: list[str] = []
    for raw in seeds:
        normalized = legacy.normalize_strong_number(raw)
        if normalized is None:
            raise LexicalRelationDiscoveryError(
                f"유효한 standard Strong 번호가 아님: {raw!r}"
            )
        if normalized not in normalized_seeds:
            normalized_seeds.append(normalized)
    normalized_seeds.sort(key=_strong_sort_key)
    if not normalized_seeds:
        raise LexicalRelationDiscoveryError("closure seed Strong이 비어 있음")

    if previous is None:
        node_by_strong: dict[str, dict[str, object]] = {
            seed: {
                "strong": seed,
                "depth": 0,
                "parent": None,
                "direction": None,
                "relation_wording": None,
                "source": None,
                "discovery_path": [],
                "additional_discovery_reasons": [],
            }
            for seed in normalized_seeds
        }
        relations: list[dict[str, object]] = []
        visited: list[str] = []
        frontier_values = list(normalized_seeds)
    else:
        if previous.get("seeds") != normalized_seeds:
            raise LexicalRelationDiscoveryError("resume closure seed 계약 불일치")
        raw_nodes = previous.get("discovered_nodes")
        raw_relations = previous.get("relations")
        raw_visited = previous.get("visited")
        raw_frontier = previous.get("frontier")
        if not all(
            isinstance(value, list)
            for value in (raw_nodes, raw_relations, raw_visited, raw_frontier)
        ):
            raise LexicalRelationDiscoveryError("resume closure 배열 계약 불일치")
        node_by_strong = {}
        for raw_node in raw_nodes:
            if not isinstance(raw_node, dict):
                raise LexicalRelationDiscoveryError("resume closure node 계약 불일치")
            strong = raw_node.get("strong")
            if not isinstance(strong, str) or strong in node_by_strong:
                raise LexicalRelationDiscoveryError(
                    "resume closure node Strong 계약 불일치"
                )
            node_by_strong[strong] = dict(raw_node)
        relations = []
        for raw_relation in raw_relations:
            if not isinstance(raw_relation, dict):
                raise LexicalRelationDiscoveryError(
                    "resume closure relation 계약 불일치"
                )
            relations.append(dict(raw_relation))
        if not all(isinstance(value, str) for value in raw_visited + raw_frontier):
            raise LexicalRelationDiscoveryError(
                "resume closure visited/frontier 계약 불일치"
            )
        visited = list(raw_visited)
        frontier_values = list(raw_frontier)
        all_state_nodes = set(visited) | set(frontier_values)
        if (
            len(visited) != len(set(visited))
            or len(frontier_values) != len(set(frontier_values))
            or set(visited) & set(frontier_values)
            or all_state_nodes != set(node_by_strong)
        ):
            raise LexicalRelationDiscoveryError(
                "resume closure visited/frontier와 node 집합 불일치"
            )

    frontier: deque[str] = deque(frontier_values)
    emitted_edges = {_relation_edge_key(edge) for edge in relations}
    expanded_this_run = 0
    while frontier and (max_nodes is None or expanded_this_run < max_nodes):
        current = frontier.popleft()
        current_node = node_by_strong[current]
        current_depth = int(current_node["depth"])
        for edge, direction, discovered_strong in _relation_candidates(
            current, outgoing, incoming
        ):
            edge_key = _relation_edge_key(edge)
            if edge_key in emitted_edges:
                continue
            emitted_edges.add(edge_key)
            depth = current_depth + 1
            discovered_new_node = discovered_strong not in node_by_strong
            relation = {
                **edge,
                "direction": direction,
                "depth": depth,
                "parent": current,
                "discovered_strong": discovered_strong,
                "discovered_new_node": discovered_new_node,
            }
            relations.append(relation)
            reason = {
                "from_strong": edge["from_strong"],
                "to_strong": edge["to_strong"],
                "direction": direction,
                "relation_wording": edge["relation_wording"],
                "source": edge["source"],
                "parent": current,
            }
            if discovered_new_node:
                path_step = {**reason, "strong": discovered_strong}
                node_by_strong[discovered_strong] = {
                    "strong": discovered_strong,
                    "depth": depth,
                    "parent": current,
                    "direction": direction,
                    "relation_wording": edge["relation_wording"],
                    "source": edge["source"],
                    "discovery_path": [
                        *list(current_node["discovery_path"]),
                        path_step,
                    ],
                    "additional_discovery_reasons": [],
                }
                frontier.append(discovered_strong)
            else:
                additional = node_by_strong[discovered_strong].setdefault(
                    "additional_discovery_reasons", []
                )
                if not isinstance(additional, list):
                    raise LexicalRelationDiscoveryError(
                        "closure additional discovery 내부 계약 불일치"
                    )
                additional.append(reason)
        visited.append(current)
        expanded_this_run += 1

    discovered_nodes = sorted(
        node_by_strong.values(),
        key=lambda node: (int(node["depth"]), _strong_sort_key(str(node["strong"]))),
    )
    relations.sort(
        key=lambda edge: (
            int(edge["depth"]),
            _strong_sort_key(str(edge["parent"])),
            0 if edge["direction"] == "outgoing" else 1,
            _strong_sort_key(str(edge["discovered_strong"])),
            _edge_sort_key(edge),
        )
    )
    discovery_complete = not frontier
    return {
        "seeds": normalized_seeds,
        "discovered_nodes": discovered_nodes,
        "relations": relations,
        "visited": visited,
        "frontier": list(frontier),
        "discovery_complete": discovery_complete,
        "stopped_reason": None if discovery_complete else "max_nodes_reached",
        "expanded_this_run": expanded_this_run,
    }


def build_numeric_window(
    entries: dict[str, legacy.SourceEntryV2],
    target: str,
) -> dict[str, object]:
    window = evidence.build_strong_window(entries, target, [])
    return {
        **window,
        "items": [
            {
                key: value
                for key, value in item.items()
                if key != "direct_reference_from_target"
            }
            for item in window["items"]
        ],
    }


def build_discovery(
    requested_strong: str,
    *,
    max_depth: int = DEFAULT_MAX_DEPTH,
    strong_manifest: Path = evidence.DEFAULT_STRONG_MANIFEST,
    cache_dir: Path = evidence.DEFAULT_CACHE,
    allow_fetch: bool = True,
) -> dict[str, object]:
    _validate_max_depth(max_depth)
    normalized = legacy.normalize_strong_number(requested_strong)
    if normalized is None:
        raise LexicalRelationDiscoveryError(
            f"유효한 standard Strong 번호가 아님: {requested_strong!r}"
        )

    entries, source_paths, provenance = evidence.load_strong_sources(
        strong_manifest,
        cache_dir,
        allow_fetch=allow_fetch,
    )
    if normalized not in entries:
        raise LexicalRelationDiscoveryError(
            f"고정 Strong source entry가 없음: {normalized}"
        )
    outgoing, incoming, index_stats = build_relation_indexes(
        source_paths, provenance
    )
    discovered_nodes, relations = discover_relation_graph(
        normalized,
        max_depth,
        outgoing,
        incoming,
    )
    source_entry = entries[normalized]
    target_source = evidence._source_entry_payload(source_entry)
    return {
        "schema_version": 1,
        "tool": {
            "name": "Reshet Lexical Relation Discovery",
            "version": TOOL_VERSION,
            "output": "deterministic_utf8_pretty_json",
        },
        "target": {
            "requested_strong": requested_strong,
            "normalized_strong": normalized,
            "source_language_code": source_entry.source_language_code,
            "canonical_headword": target_source["headword"],
            "transliteration": target_source["transliteration"],
            "pronunciation": target_source["pronunciation"],
            "source_disposition": target_source["source_disposition"],
        },
        "max_depth": max_depth,
        "numeric_window": build_numeric_window(entries, normalized),
        "relations": relations,
        "discovered_nodes": discovered_nodes,
        "source_provenance": {
            "manifest": {
                "path": strong_manifest.name,
                "sha256": evidence.sha256_file(strong_manifest),
            },
            "sources": provenance,
            "relation_index": index_stats,
        },
        "scope": {
            "relation_source": "fixed_strong_xml_explicit_references_only",
            "numeric_window": "target_only_numeric_neighbors_not_traversal_seeds",
            "database_read_or_write": False,
            "semantic_assertion": False,
        },
    }


def serialize_discovery(payload: dict[str, object]) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "고정 Strong source의 outgoing/incoming lexical relation을 "
            "제한된 깊이로 탐색합니다."
        )
    )
    parser.add_argument("strong", help="G32, G1225, H2646 같은 standard Strong 번호")
    parser.add_argument(
        "--max-depth",
        type=int,
        choices=range(MIN_MAX_DEPTH, MAX_MAX_DEPTH + 1),
        default=DEFAULT_MAX_DEPTH,
        help="relation traversal 최대 깊이(기본 2, 허용 1~3)",
    )
    parser.add_argument(
        "--strong-manifest",
        type=Path,
        default=evidence.DEFAULT_STRONG_MANIFEST,
    )
    parser.add_argument("--cache-dir", type=Path, default=evidence.DEFAULT_CACHE)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="cache가 없을 때 다운로드하지 않고 fail-closed",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        payload = build_discovery(
            args.strong,
            max_depth=args.max_depth,
            strong_manifest=args.strong_manifest,
            cache_dir=args.cache_dir,
            allow_fetch=not args.offline,
        )
    except (
        evidence.EvidencePacketError,
        FileNotFoundError,
        strong_mapping.ManifestError,
        legacy.SourceSchemaError,
    ) as error:
        sys.stderr.reconfigure(encoding="utf-8", errors="strict", newline="\n")
        print(f"오류: {error}", file=sys.stderr)
        return 2
    sys.stdout.buffer.write(serialize_discovery(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
