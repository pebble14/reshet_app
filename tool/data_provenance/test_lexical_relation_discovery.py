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
        self.assertEqual(self.stats["explicit_edge_count"], 6)
        duplicate_target_edges = [
            edge
            for edge in self.outgoing["H0101"]
            if edge["to_strong"] == "H0103"
        ]
        self.assertEqual(len(duplicate_target_edges), 1)

    def test_max_depth_is_enforced_and_bounded(self) -> None:
        nodes, relations = self._graph(max_depth=1)
        self.assertEqual({node["strong"] for node in nodes}, {"H0100", "H0101", "H0104"})
        self.assertTrue(all(edge["depth"] == 1 for edge in relations))
        for invalid in (0, 4):
            with self.subTest(invalid=invalid):
                with self.assertRaises(discovery.LexicalRelationDiscoveryError):
                    self._graph(max_depth=invalid)

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
