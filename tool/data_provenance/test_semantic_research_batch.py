#!/usr/bin/env python3

from __future__ import annotations

from contextlib import ExitStack
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

import biblical_research_evidence_packet as evidence
import lexical_relation_discovery as discovery
import semantic_research_batch as batch


class SemanticResearchBatchTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.local_sources = self.root / "local_sources"
        self.local_sources.mkdir()
        self.work_db = self.root / "work.db"
        self.work_db.write_bytes(b"read-only fixture database")
        source = self.root / "HebrewStrong.xml"
        source.write_text(
            """<lexicon>
<entry id="H0100"><source>from <w src="H0101">101</w>;</source></entry>
<entry id="H0101"><source>from <w src="H0102">102</w>;</source></entry>
<entry id="H0102"><source>from <w src="H0103">103</w>;</source></entry>
<entry id="H0103"><source>a primitive root;</source></entry>
</lexicon>""",
            encoding="utf-8",
        )
        self.outgoing, self.incoming, self.index_stats = (
            discovery.build_relation_indexes(
                {"H": source}, [{"language": "H", "id": "fixture_hebrew"}]
            )
        )
        self.packet_builder = MagicMock(side_effect=self._packet)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _bundle(self, *, fingerprint_suffix: str = "") -> dict[str, object]:
        return {
            "entries": {strong: object() for strong in ("H0100", "H0101", "H0102", "H0103")},
            "outgoing": self.outgoing,
            "incoming": self.incoming,
            "relation_index": self.index_stats,
            "strong_provenance": [],
            "approved_manifests": [],
            "dispositions": [
                {
                    "strong_number": "H0102",
                    "status": "hold",
                    "reason": "fixture semantic 판단 보류",
                    "evidence_refs": ["fixture"],
                    "reopen_condition": "새 전문 근거 확보",
                }
            ],
            "local_specs": [],
            "local_provenance": [],
            "source_fingerprints": {
                "fixture": "stable" + fingerprint_suffix,
                "work_database": {
                    "path": self.work_db.resolve().as_posix(),
                    "sha256": evidence.sha256_file(self.work_db),
                },
                "local_reference_sources": [],
            },
        }

    @staticmethod
    def _projection(_path: Path, strong: str) -> tuple[list[dict[str, object]], dict[str, object]]:
        return (
            [
                {
                    "word_id": f"{strong}_0000",
                    "strong_number": strong,
                    "language": "히브리어",
                    "word_note": f"{strong} 현재 비고",
                    "expressions": [],
                    "meanings": [],
                }
            ],
            {"unchanged": True},
        )

    @staticmethod
    def _gate(
        strong: str,
        _projection: list[dict[str, object]],
        _approved: list[Path],
        _source_only: Path,
    ) -> dict[str, object]:
        return {
            "state": "explicit_approved" if strong == "H0101" else "source_only",
            "evidence": ["fixture"],
            "interpretation": "fixture completion",
        }

    @staticmethod
    def _packet(strong: str, **_kwargs: object) -> dict[str, object]:
        return {
            "schema_version": 1,
            "tool": {"name": "fixture"},
            "target": {"normalized_strong": strong},
        }

    @staticmethod
    def _load_packet(path: Path) -> dict[str, object]:
        return json.loads(path.read_text(encoding="utf-8"))

    @staticmethod
    def _render_review(
        packet: dict[str, object], relation_context: dict[str, object]
    ) -> bytes:
        strong = packet["target"]["normalized_strong"]
        related = ",".join(
            f"{row['related_strong']}:{row['related_status']}"
            for row in relation_context["relations"]
        )
        return f"# {strong}\n{related}\n".encode("utf-8")

    def _patch_runtime(
        self,
        *,
        bundle: dict[str, object] | None = None,
        packet_builder: MagicMock | None = None,
        gate: object | None = None,
    ) -> ExitStack:
        stack = ExitStack()
        selected_bundle = bundle or self._bundle()
        stack.enter_context(
            patch.object(
                batch,
                "_load_sources_and_authority",
                side_effect=lambda **_kwargs: deepcopy(selected_bundle),
            )
        )
        stack.enter_context(
            patch.object(batch.evidence, "load_reshet_projection", side_effect=self._projection)
        )
        stack.enter_context(
            patch.object(
                batch.evidence,
                "completion_gate_state",
                side_effect=gate or self._gate,
            )
        )
        stack.enter_context(
            patch.object(
                batch.evidence,
                "build_evidence_packet",
                packet_builder or self.packet_builder,
            )
        )
        stack.enter_context(
            patch.object(batch.review, "load_packet", side_effect=self._load_packet)
        )
        stack.enter_context(
            patch.object(batch.review, "serialize_review", side_effect=self._render_review)
        )
        return stack

    def _run(
        self,
        output_dir: Path,
        *,
        resume: bool = False,
        max_nodes: int | None = None,
        allow_fetch: bool = True,
    ) -> dict[str, object]:
        return batch.run_batch(
            ["H100", "H0100"],
            local_sources=self.local_sources,
            output_dir=output_dir,
            work_db=self.work_db,
            allow_fetch=allow_fetch,
            resume=resume,
            max_nodes=max_nodes,
        )

    def test_cluster_first_skips_approved_hold_and_prepares_all_unapproved(self) -> None:
        output = self.root / "output"
        with self._patch_runtime():
            state = self._run(output)

        self.assertTrue(state["discovery_complete"])
        self.assertTrue(state["research_complete"])
        nodes = {row["strong"]: row for row in state["nodes"]}
        self.assertEqual(set(nodes), {"H0100", "H0101", "H0102", "H0103"})
        self.assertEqual(nodes["H0101"]["classification"], "explicit_approved")
        self.assertEqual(nodes["H0102"]["classification"], "hold")
        self.assertEqual(nodes["H0101"]["preparation"]["state"], "reused")
        self.assertEqual(nodes["H0102"]["preparation"]["state"], "reused")
        self.assertEqual(nodes["H0100"]["preparation"]["state"], "ready")
        self.assertEqual(nodes["H0103"]["preparation"]["state"], "ready")
        self.assertEqual(
            [call.args[0] for call in self.packet_builder.call_args_list],
            ["H0100", "H0103"],
        )
        self.assertTrue((output / "H100_evidence_packet.json").is_file())
        self.assertTrue((output / "H100_lexical_relations.json").is_file())
        self.assertTrue((output / "H100_review.md").is_file())
        self.assertFalse((output / "H0100_review.md").exists())
        self.assertTrue((output / "H103_review.md").is_file())
        self.assertFalse(any(path.is_dir() for path in output.iterdir()))

        h100_relations = json.loads(
            (output / "H100_lexical_relations.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            h100_relations["relations"][0]["related_status"],
            "explicit_approved",
        )
        h103_relations = json.loads(
            (output / "H103_lexical_relations.json").read_text(encoding="utf-8")
        )
        self.assertEqual(h103_relations["relations"][0]["related_status"], "hold")
        queue = (output / batch.QUEUE_FILENAME).read_text(encoding="utf-8")
        self.assertIn("H100 | READY", queue)
        self.assertIn("H101 | existing", queue)
        self.assertIn("H102 | existing | hold", queue)

    def test_approved_hold_overlap_fails_closed_before_preparation(self) -> None:
        output = self.root / "overlap"

        def overlapping_gate(
            strong: str,
            projection: list[dict[str, object]],
            approved: list[Path],
            source_only: Path,
        ) -> dict[str, object]:
            if strong == "H0102":
                return {"state": "explicit_approved", "evidence": ["fixture"]}
            return self._gate(strong, projection, approved, source_only)

        with self._patch_runtime(gate=overlapping_gate):
            with self.assertRaisesRegex(
                batch.SemanticResearchBatchError, "authority가 겹침"
            ):
                self._run(output)
        self.packet_builder.assert_not_called()
        state = json.loads(
            (output / batch.STATE_FILENAME).read_text(encoding="utf-8")
        )
        self.assertFalse(state["discovery_complete"])
        self.assertFalse(state["cluster"]["discovery_complete"])
        self.assertEqual(state["stopped_reason"], "authority_classification_error")
        self.assertEqual(
            state["global_error"]["phase"], "authority_classification"
        )

    def test_max_nodes_preserves_frontier_then_resume_completes(self) -> None:
        output = self.root / "resume"
        states: list[dict[str, object]] = []
        with self._patch_runtime():
            states.append(self._run(output, max_nodes=1))
            while not states[-1]["research_complete"]:
                states.append(self._run(output, resume=True, max_nodes=1))

        first = states[0]
        self.assertFalse(first["discovery_complete"])
        self.assertEqual(first["stopped_reason"], "max_nodes_reached")
        self.assertEqual(first["cluster"]["visited"], ["H0100"])
        self.assertEqual(first["cluster"]["frontier"], ["H0101"])
        self.assertGreaterEqual(len(states), 6)
        self.assertTrue(states[-1]["research_complete"])
        self.assertEqual(states[-1]["cluster"]["frontier"], [])
        self.assertTrue((output / "H103_review.md").is_file())

    def test_resume_fingerprint_and_option_mismatch_fail_closed(self) -> None:
        output = self.root / "mismatch"
        with self._patch_runtime():
            self._run(output, max_nodes=1)

        with self._patch_runtime(bundle=self._bundle(fingerprint_suffix="-changed")):
            with self.assertRaisesRegex(
                batch.SemanticResearchBatchError, "source fingerprint 불일치"
            ):
                self._run(output, resume=True, max_nodes=1)

        with self._patch_runtime():
            with self.assertRaisesRegex(
                batch.SemanticResearchBatchError, "relevant option 불일치"
            ):
                self._run(
                    output,
                    resume=True,
                    max_nodes=1,
                    allow_fetch=False,
                )

    def test_node_failure_isolated_and_main_exit_is_nonzero(self) -> None:
        output = self.root / "failure"

        def fail_one(strong: str, **kwargs: object) -> dict[str, object]:
            if strong == "H0103":
                raise RuntimeError("fixture preparation failure")
            return self._packet(strong, **kwargs)

        failing_builder = MagicMock(side_effect=fail_one)
        with self._patch_runtime(packet_builder=failing_builder):
            state = self._run(output)

        nodes = {row["strong"]: row for row in state["nodes"]}
        self.assertFalse(state["research_complete"])
        self.assertEqual(state["stopped_reason"], "node_preparation_error")
        self.assertEqual(nodes["H0103"]["preparation"]["state"], "error")
        self.assertEqual(nodes["H0100"]["preparation"]["state"], "ready")
        self.assertFalse((output / "H103_evidence_packet.json").exists())
        self.assertTrue((output / "H100_review.md").is_file())
        queue_lines = (output / batch.QUEUE_FILENAME).read_text(encoding="utf-8").splitlines()
        first_data_row = next(line for line in queue_lines if line.startswith("| H"))
        self.assertTrue(first_data_row.startswith("| H103 | ERROR"))

        main_output = self.root / "main_failure"
        with self._patch_runtime(packet_builder=MagicMock(side_effect=fail_one)):
            exit_code = batch.main(
                [
                    "H100",
                    "--local-sources",
                    str(self.local_sources),
                    "--output-dir",
                    str(main_output),
                    "--work-db",
                    str(self.work_db),
                ]
            )
        self.assertEqual(exit_code, 1)

    def test_atomic_failure_preserves_existing_final_file(self) -> None:
        path = self.root / "atomic.json"
        path.write_bytes(b"existing final")
        with patch.object(batch.os, "replace", side_effect=OSError("fixture replace failure")):
            with self.assertRaisesRegex(
                batch.SemanticResearchBatchError, "atomic artifact 기록 실패"
            ):
                batch._atomic_replace(path, b"new content")
        self.assertEqual(path.read_bytes(), b"existing final")
        self.assertEqual(list(self.root.glob(".atomic.json.*.tmp")), [])

    def test_existing_artifact_without_state_fails_closed(self) -> None:
        output = self.root / "conflict"
        output.mkdir()
        (output / "H100_review.md").write_text("unexpected", encoding="utf-8")
        with self.assertRaisesRegex(batch.ArtifactConflictError, "state 없는"):
            self._run(output)

    def test_completed_artifacts_are_reused_and_hash_mismatch_fails(self) -> None:
        output = self.root / "reuse"
        with self._patch_runtime():
            self._run(output)

        no_rebuild = MagicMock(side_effect=AssertionError("재생성되면 안 됨"))
        with self._patch_runtime(packet_builder=no_rebuild):
            resumed = self._run(output, resume=True)
        self.assertTrue(resumed["research_complete"])
        no_rebuild.assert_not_called()

        artifact = output / "H100_evidence_packet.json"
        artifact.write_text("changed", encoding="utf-8")
        with self._patch_runtime(packet_builder=no_rebuild):
            with self.assertRaisesRegex(
                batch.ArtifactConflictError, "artifact hash 불일치"
            ):
                self._run(output, resume=True)


if __name__ == "__main__":
    unittest.main()
