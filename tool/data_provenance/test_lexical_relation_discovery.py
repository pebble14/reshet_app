#!/usr/bin/env python3

from __future__ import annotations

import tempfile
from pathlib import Path
import unittest

import lexical_relation_discovery as discovery


class LexicalRelationDiscoveryTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        source = self.root / "HebrewStrong.xml"
        source.write_text(
            """<lexicon>
<entry id="H0100"><source>from <w src="H0101">101</w>;</source></entry>
<entry id="H0101"><source>compare <w src="H0102">102</w>,
<w src="H0103">103</w>, <w src="H0103">103</w>;</source></entry>
<entry id="H0102"><source>the same as <w src="H0101">101</w>;</source></entry>
<entry id="H0103"><source>a primitive root;</source></entry>
<entry id="H0104"><source>plural of <w src="H0100">100</w>;</source></entry>
<entry id="H0105"><source>an orthographical variation of
<w src="H0104">104</w>;</source></entry>
</lexicon>""",
            encoding="utf-8",
        )
        self.outgoing, self.incoming, self.stats = discovery.build_relation_indexes(
            {"H": source},
            [{"language": "H", "id": "fixture_hebrew"}],
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _graph(
        self, max_depth: int = 2
    ) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
        return discovery.discover_relation_graph(
            "H0100",
            max_depth,
            self.outgoing,
            self.incoming,
        )

    def test_direct_outgoing_one_hop(self) -> None:
        nodes, relations = self._graph(max_depth=1)
        node = next(item for item in nodes if item["strong"] == "H0101")
        edge = next(
            item
            for item in relations
            if item["from_strong"] == "H0100"
            and item["to_strong"] == "H0101"
        )
        self.assertEqual((node["depth"], node["parent"]), (1, "H0100"))
        self.assertEqual(edge["direction"], "outgoing")

    def test_incoming_reverse_discovery(self) -> None:
        nodes, relations = self._graph(max_depth=1)
        node = next(item for item in nodes if item["strong"] == "H0104")
        edge = next(
            item
            for item in relations
            if item["from_strong"] == "H0104"
            and item["to_strong"] == "H0100"
        )
        self.assertEqual((node["depth"], node["parent"]), (1, "H0100"))
        self.assertEqual(edge["direction"], "incoming")

    def test_second_hop_discovery_and_path(self) -> None:
        nodes, _ = self._graph()
        by_strong = {str(item["strong"]): item for item in nodes}
        self.assertEqual(
            {strong for strong, node in by_strong.items() if node["depth"] == 2},
            {"H0102", "H0103", "H0105"},
        )
        path = by_strong["H0103"]["discovery_path"]
        self.assertEqual(
            [step["strong"] for step in path],
            ["H0101", "H0103"],
        )
        self.assertEqual([step["relation_wording"] for step in path], ["from", "compare"])

    def test_cycle_protection_keeps_nodes_and_edges_finite(self) -> None:
        nodes, relations = self._graph()
        self.assertEqual(len(nodes), len({item["strong"] for item in nodes}))
        self.assertEqual(len(relations), 6)
        cycle_edge = next(
            item
            for item in relations
            if item["from_strong"] == "H0102"
            and item["to_strong"] == "H0101"
        )
        self.assertFalse(cycle_edge["discovered_new_node"])

    def test_duplicate_edge_is_deduplicated(self) -> None:
        self.assertEqual(self.stats["reference_count"], 7)
        self.assertEqual(self.stats["reference_evidence_occurrence_count"], 7)
        self.assertEqual(self.stats["explicit_edge_count"], 6)
        duplicate_target_edges = [
            edge
            for edge in self.outgoing["H0101"]
            if edge["to_strong"] == "H0103"
        ]
        self.assertEqual(len(duplicate_target_edges), 1)
        edge = duplicate_target_edges[0]
        self.assertEqual(edge["reference_evidence_count"], 2)
        occurrences = edge["reference_evidence"]
        self.assertEqual(
            [row["source_order"] for row in occurrences],
            [2, 3],
        )
        self.assertNotEqual(
            occurrences[0]["reference_context"],
            occurrences[1]["reference_context"],
        )

    def test_expanded_containers_are_indexed_in_both_directions(self) -> None:
        greek = self.root / "GreekStrong.xml"
        greek.write_text(
            """<strongsdictionary><entries>
<entry strongs="200"><strongs_derivation>from <strongsref language="GREEK" strongs="201"/></strongs_derivation></entry>
<entry strongs="202"><strongs_def>compare <strongsref language="GREEK" strongs="201"/></strongs_def></entry>
<entry strongs="203"><kjv_def>variant of <strongsref language="GREEK" strongs="201"/></kjv_def></entry>
<entry strongs="204">from the same as <strongsref language="GREEK" strongs="201"/>.</entry>
<entry strongs="205"><strongs_def>probably from <strongsref language="GREEK" strongs="201"/>;
inflected from <strongsref language="GREEK" strongs="201"/>.</strongs_def></entry>
</entries></strongsdictionary>""",
            encoding="utf-8",
        )
        hebrew = self.root / "HebrewStrongExpanded.xml"
        hebrew.write_text(
            """<lexicon>
<entry id="H0200"><source>from <w src="H0201">201</w>.</source></entry>
<entry id="H0202"><usage>Compare <w src="H0201">201</w>.</usage></entry>
<entry id="H0203"><meaning>equivalent to <w src="H0201">201</w>.</meaning></entry>
</lexicon>""",
            encoding="utf-8",
        )

        outgoing, incoming, stats = discovery.build_relation_indexes(
            {"G": greek, "H": hebrew},
            [
                {"language": "G", "id": "fixture_greek"},
                {"language": "H", "id": "fixture_hebrew"},
            ],
        )

        self.assertEqual(
            stats["reference_container_counts"],
            {
                "G:entry": 1,
                "G:kjv_def": 1,
                "G:strongs_def": 3,
                "G:strongs_derivation": 1,
                "H:meaning": 1,
                "H:source": 1,
                "H:usage": 1,
            },
        )
        self.assertEqual(stats["reference_count"], 9)
        self.assertEqual(stats["reference_evidence_occurrence_count"], 9)
        self.assertEqual(stats["explicit_edge_count"], 8)
        self.assertEqual(stats["invalid_reference_count"], 0)
        self.assertEqual(
            {edge["from_strong"] for edge in incoming["G0201"]},
            {"G0200", "G0202", "G0203", "G0204", "G0205"},
        )
        self.assertEqual(
            {edge["from_strong"] for edge in incoming["H0201"]},
            {"H0200", "H0202", "H0203"},
        )
        self.assertTrue(
            all(
                outgoing[source]
                for source in (
                    "G0200",
                    "G0202",
                    "G0203",
                    "G0204",
                    "G0205",
                    "H0200",
                    "H0202",
                    "H0203",
                )
            )
        )
        multiple_evidence = next(
            edge
            for edge in outgoing["G0205"]
            if edge["to_strong"] == "G0201"
        )
        self.assertEqual(multiple_evidence["reference_evidence_count"], 2)
        contexts = [
            str(row["reference_context"])
            for row in multiple_evidence["reference_evidence"]
        ]
        self.assertIn("probably from [[G0201]]", contexts[0])
        self.assertIn("inflected from [[G0201]]", contexts[1])

        nodes, relations = discovery.discover_relation_graph(
            "G0201", 1, outgoing, incoming
        )
        self.assertEqual(
            {node["strong"] for node in nodes},
            {"G0200", "G0201", "G0202", "G0203", "G0204", "G0205"},
        )
        self.assertTrue(all(edge["direction"] == "incoming" for edge in relations))

    def test_max_depth_is_enforced_and_bounded(self) -> None:
        nodes, relations = self._graph(max_depth=1)
        self.assertEqual({node["strong"] for node in nodes}, {"H0100", "H0101", "H0104"})
        self.assertTrue(all(edge["depth"] == 1 for edge in relations))
        for invalid in (0, 4):
            with self.subTest(invalid=invalid):
                with self.assertRaises(discovery.LexicalRelationDiscoveryError):
                    self._graph(max_depth=invalid)

    def test_closure_reaches_component_without_fixed_depth_cutoff(self) -> None:
        result = discovery.discover_relation_closure(
            ["H100"], self.outgoing, self.incoming
        )
        self.assertTrue(result["discovery_complete"])
        self.assertIsNone(result["stopped_reason"])
        self.assertEqual(result["frontier"], [])
        self.assertEqual(
            {node["strong"] for node in result["discovered_nodes"]},
            {"H0100", "H0101", "H0102", "H0103", "H0104", "H0105"},
        )
        self.assertEqual(len(result["visited"]), 6)
        self.assertEqual(len(result["relations"]), 6)

    def test_closure_preserves_multi_path_as_additional_discovery(self) -> None:
        result = discovery.discover_relation_closure(
            ["H0100"], self.outgoing, self.incoming
        )
        node = next(
            item for item in result["discovered_nodes"] if item["strong"] == "H0102"
        )
        reasons = node["additional_discovery_reasons"]
        self.assertTrue(
            any(
                reason["from_strong"] == "H0102"
                and reason["to_strong"] == "H0101"
                for reason in reasons
            )
        )

    def test_closure_preserves_diamond_multi_path_without_duplicate_node(self) -> None:
        source = self.root / "DiamondHebrewStrong.xml"
        source.write_text(
            """<lexicon>
<entry id="H0200"><source>from <w src="H0201">201</w> and <w src="H0202">202</w>;</source></entry>
<entry id="H0201"><source>from <w src="H0203">203</w>;</source></entry>
<entry id="H0202"><source>from <w src="H0203">203</w>;</source></entry>
<entry id="H0203"><source>a primitive root;</source></entry>
</lexicon>""",
            encoding="utf-8",
        )
        outgoing, incoming, _ = discovery.build_relation_indexes(
            {"H": source}, [{"language": "H", "id": "fixture_diamond"}]
        )

        result = discovery.discover_relation_closure(
            ["H0200"], outgoing, incoming
        )
        nodes = [
            node for node in result["discovered_nodes"] if node["strong"] == "H0203"
        ]
        self.assertEqual(len(nodes), 1)
        self.assertEqual(nodes[0]["parent"], "H0201")
        self.assertTrue(
            any(
                reason["parent"] == "H0202"
                and reason["from_strong"] == "H0202"
                and reason["to_strong"] == "H0203"
                for reason in nodes[0]["additional_discovery_reasons"]
            )
        )
        paths_to_target = [
            relation
            for relation in result["relations"]
            if relation["to_strong"] == "H0203"
        ]
        self.assertEqual(
            {(row["from_strong"], row["to_strong"]) for row in paths_to_target},
            {("H0201", "H0203"), ("H0202", "H0203")},
        )

    def test_closure_max_nodes_preserves_frontier_and_resumes(self) -> None:
        partial = discovery.discover_relation_closure(
            ["H0100"], self.outgoing, self.incoming, max_nodes=1
        )
        self.assertFalse(partial["discovery_complete"])
        self.assertEqual(partial["stopped_reason"], "max_nodes_reached")
        self.assertEqual(partial["visited"], ["H0100"])
        self.assertEqual(partial["frontier"], ["H0101", "H0104"])

        resumed = partial
        while not resumed["discovery_complete"]:
            resumed = discovery.discover_relation_closure(
                ["H0100"],
                self.outgoing,
                self.incoming,
                previous=resumed,
                max_nodes=1,
            )
        complete = discovery.discover_relation_closure(
            ["H0100"], self.outgoing, self.incoming
        )
        for key in ("discovered_nodes", "relations", "visited", "frontier"):
            self.assertEqual(resumed[key], complete[key])

    def test_closure_seed_and_result_are_deterministic(self) -> None:
        first = discovery.discover_relation_closure(
            ["H104", "H0100", "H100"], self.outgoing, self.incoming
        )
        second = discovery.discover_relation_closure(
            ["H0100", "H0104"], self.outgoing, self.incoming
        )
        self.assertEqual(first, second)

    def test_numeric_window_is_target_only_and_relation_free(self) -> None:
        window = discovery.build_numeric_window({}, "H0100")
        self.assertEqual(
            window["interpretation"],
            "numeric_neighbors_only_not_semantic_relations",
        )
        self.assertEqual((window["start"], window["end"]), ("H0090", "H0110"))
        self.assertEqual(len(window["items"]), 21)
        related_numeric_neighbor = next(
            item for item in window["items"] if item["strong"] == "H0101"
        )
        self.assertNotIn("direct_reference_from_target", related_numeric_neighbor)
        self.assertNotIn("relation_wording", related_numeric_neighbor)

    def test_relation_wording_and_provenance_are_preserved(self) -> None:
        _, relations = self._graph()
        wording_by_pair = {
            (edge["from_strong"], edge["to_strong"]): edge["relation_wording"]
            for edge in relations
        }
        self.assertEqual(wording_by_pair[("H0100", "H0101")], "from")
        self.assertEqual(wording_by_pair[("H0101", "H0102")], "compare")
        self.assertEqual(wording_by_pair[("H0102", "H0101")], "the same as")
        self.assertEqual(wording_by_pair[("H0104", "H0100")], "plural of")
        self.assertEqual(
            wording_by_pair[("H0105", "H0104")],
            "an orthographical variation of",
        )
        self.assertTrue(all(edge["source"] == "fixture_hebrew" for edge in relations))

    def test_output_is_deterministic(self) -> None:
        first_nodes, first_relations = self._graph()
        second_nodes, second_relations = self._graph()
        first = discovery.serialize_discovery(
            {"discovered_nodes": first_nodes, "relations": first_relations}
        )
        second = discovery.serialize_discovery(
            {"discovered_nodes": second_nodes, "relations": second_relations}
        )
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))


if __name__ == "__main__":
    unittest.main()
