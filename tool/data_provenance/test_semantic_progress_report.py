#!/usr/bin/env python3

from __future__ import annotations

import csv
import hashlib
import io
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

import biblical_research_evidence_packet as evidence
import semantic_progress_report as progress
import semantic_research_batch as research_batch
import strong_source_diff as legacy


class SemanticProgressReportTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.source_only = self.root / "source_only.json"
        self.source_only.write_text(
            json.dumps({"entries": []}) + "\n", encoding="utf-8"
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _sha(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def _entry(
        strong: str,
        spelling: str,
        *,
        language_code: str,
        part_of_speech: str | None = None,
    ) -> legacy.SourceEntryV2:
        context = legacy.SourceXmlContextV2(
            source_key=strong,
            section="headword",
            direct_child_position=1,
        )
        if strong.startswith("G"):
            form: legacy.SourceFormV2 = legacy.GreekSourceFormV2(
                source_key=strong,
                source_document_order=1,
                form_role="primary",
                spelling=spelling,
                transliteration=None,
                pronunciation=None,
                source_language="G",
                xml_context=context,
            )
        else:
            form = legacy.HebrewSourceFormV2(
                source_key=strong,
                source_document_order=1,
                form_role="primary",
                spelling=spelling,
                transliteration=None,
                pronunciation=None,
                source_language_code=language_code,
                part_of_speech=part_of_speech,
                xml_context=context,
            )
        return legacy.SourceEntryV2(
            source_key=strong,
            source_language_code=language_code,
            disposition="ready",
            forms=(form,),
            meanings=(),
        )

    @staticmethod
    def _language_mapping() -> dict[str, str]:
        return {
            "G": "헬라어",
            "heb": "히브리어",
            "arc": "아람어",
            "x-pn": "unresolved",
        }

    @staticmethod
    def _projection(
        strong: str,
        *,
        meaning: str | None,
        expression: str = "표현",
        note: str | None = None,
    ) -> list[dict[str, object]]:
        return [
            {
                "word_id": f"{strong}_0000",
                "strong_number": strong,
                "language": "히브리어",
                "word_note": note,
                "expressions": [
                    {
                        "seq": 1,
                        "is_representative": 1,
                        "spelling": expression,
                        "transliteration": None,
                        "pronunciation": None,
                        "pronunciation_notation": None,
                        "pronunciation_notation_name": None,
                    }
                ],
                "meanings": (
                    [{"seq": 1, "meaning": meaning}] if meaning is not None else []
                ),
            }
        ]

    def _write_approved_manifest(
        self,
        filename: str,
        *,
        strong: str | None,
        meaning: str | None,
        format_version: int = 1,
        batch_id: str | None = None,
        supersedes: list[dict[str, str]] | None = None,
        relation_creates: list[dict[str, object]] | None = None,
    ) -> Path:
        path = self.root / filename
        payload: dict[str, object] = {
            "format_version": format_version,
            "batch_id": batch_id
            or f"RESHET-TEST-{path.stem.upper()}-APPROVED-CONTENT-SLICE",
            "provenance": {"fixture": True},
            "target": {"fixture": True},
            "meaning_replacements": (
                [
                    {
                        "word_id": f"{strong}_0000",
                        "before": [{"seq": 1, "meaning": "before"}],
                        "after": [{"seq": 1, "meaning": meaning}],
                    }
                ]
                if strong is not None and meaning is not None
                else []
            ),
            "relation_creates": relation_creates or [],
        }
        if format_version in (2, 3, 4):
            payload["word_note_replacements"] = []
        if format_version in (3, 4):
            payload["supersedes"] = supersedes or []
        if format_version == 4:
            payload["relation_replacements"] = []
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return path

    def _canonical_rows(
        self, entries: list[tuple[str, legacy.SourceEntryV2]]
    ) -> list[dict[str, object]]:
        return progress.build_canonical_universe(entries, self._language_mapping())

    def _authority(
        self, manifests: list[Path]
    ) -> evidence.CompletionGateAuthority:
        return evidence.load_completion_gate_authority(manifests, self.source_only)

    @staticmethod
    def _fingerprints(approved: list[Path]) -> dict[str, object]:
        return {
            "strong_manifest": {"path": "strong_sources.json", "sha256": "1" * 64},
            "strong_sources": [
                {
                    "id": "fixture",
                    "commit": "a" * 40,
                    "sha256": "2" * 64,
                }
            ],
            "occurrence_manifest": {
                "path": "biblical_occurrence_sources.json",
                "sha256": "3" * 64,
            },
            "occurrence_sources": [],
            "approved_content_manifests": [
                {"path": path.name, "sha256": "4" * 64} for path in approved
            ],
            "source_only_manifest": {
                "path": "source_only.json",
                "sha256": "5" * 64,
            },
            "semantic_research_dispositions": {
                "path": "semantic_research_dispositions.json",
                "sha256": "6" * 64,
            },
            "work_database_sha256": "7" * 64,
        }

    @staticmethod
    def _work_database() -> dict[str, object]:
        return {
            "filename": "work.db",
            "sha256_before": "7" * 64,
            "sha256_after": "7" * 64,
            "unchanged": True,
            "query_only": True,
            "immutable": True,
            "integrity_check": "ok",
        }

    def _snapshot(
        self,
        *,
        canonical_rows: list[dict[str, object]],
        projections: dict[str, list[dict[str, object]]],
        manifests: list[Path],
        dispositions: list[dict[str, object]] | None = None,
        database_anomalies: list[dict[str, object]] | None = None,
        occurrence_counts: dict[str, int] | None = None,
        outgoing: dict[str, list[dict[str, object]]] | None = None,
        incoming: dict[str, list[dict[str, object]]] | None = None,
    ) -> dict[str, object]:
        return progress.assemble_progress_snapshot(
            canonical_rows=canonical_rows,
            projections=projections,
            database_anomalies=database_anomalies or [],
            occurrence_counts=occurrence_counts or {},
            outgoing=outgoing or {},
            incoming=incoming or {},
            relation_index={"explicit_edge_count": 0},
            completion_authority=self._authority(manifests),
            dispositions=dispositions or [],
            source_fingerprints=self._fingerprints(manifests),
            work_database=self._work_database(),
        )

    def test_canonical_universe_normalizes_orders_and_preserves_language_fields(
        self,
    ) -> None:
        rows = self._canonical_rows(
            [
                (
                    "H0010",
                    self._entry(
                        "H0010", "עשר", language_code="heb", part_of_speech="n"
                    ),
                ),
                ("G0002", self._entry("G0002", "Ἀαρών", language_code="G")),
                ("G0001", self._entry("G0001", "ἄλφα", language_code="G")),
            ]
        )

        self.assertEqual([row["strong"] for row in rows], ["G0001", "G0002", "H0010"])
        self.assertEqual(rows[0]["language"], "헬라어")
        self.assertEqual(rows[2]["part_of_speech"], "n")
        with self.assertRaisesRegex(progress.SemanticProgressReportError, "형식 불일치"):
            self._canonical_rows(
                [("G1", self._entry("G0001", "ἄλφα", language_code="G"))]
            )

        missing_headword = legacy.SourceEntryV2(
            source_key="G0003",
            source_language_code="G",
            disposition="source_not_used",
            forms=(),
            meanings=(),
        )
        missing_row = self._canonical_rows([("G0003", missing_headword)])[0]
        self.assertIsNone(missing_row["headword"])
        self.assertEqual(missing_row["issues"], ["canonical_headword_missing"])
        with self.assertRaisesRegex(
            progress.SemanticProgressReportError, "집합 크기가 다름"
        ):
            progress._validate_loaded_source_counts(
                {"G0001": self._entry("G0001", "ἄλφα", language_code="G")},
                [{"entry_count": 2}],
            )

    def test_canonical_universe_rejects_normalized_duplicate(self) -> None:
        entry = self._entry("G0001", "ἄλφα", language_code="G")
        with self.assertRaisesRegex(progress.SemanticProgressReportError, "중복"):
            self._canonical_rows([("G0001", entry), ("G0001", entry)])

    def test_explicit_approved_uses_exact_completion_gate(self) -> None:
        manifest = self._write_approved_manifest(
            "approved_content_slice.json", strong="H0001", meaning="승인 의미"
        )
        canonical = self._canonical_rows(
            [("H0001", self._entry("H0001", "אָב", language_code="heb"))]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={"H0001": self._projection("H0001", meaning="승인 의미")},
            manifests=[manifest],
        )

        row = snapshot["rows"][0]
        self.assertEqual(row["semantic_status"], "explicit_approved")
        self.assertEqual(row["progress_detail"], "approved")
        self.assertEqual(row["approval_authority"], [manifest.name])

    def test_relation_only_manifest_is_not_meaning_approval(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json",
            strong=None,
            meaning=None,
            relation_creates=[
                {
                    "word_id_1": "H0001_0000",
                    "word_id_2": "H0002_0000",
                    "direction": "w1_to_w2",
                }
            ],
        )
        canonical = self._canonical_rows(
            [("H0001", self._entry("H0001", "אָב", language_code="heb"))]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={"H0001": self._projection("H0001", meaning="기존 의미")},
            manifests=[relation_only],
        )

        row = snapshot["rows"][0]
        self.assertEqual(row["semantic_status"], "unapproved")
        self.assertEqual(row["progress_detail"], "unapproved_with_meaning")

    def test_superseded_projection_is_not_current_approval(self) -> None:
        old_batch = "RESHET-TEST-OLD-APPROVED-CONTENT-SLICE"
        old = self._write_approved_manifest(
            "old_approved_content_slice.json",
            strong="H0001",
            meaning="과거 의미",
            batch_id=old_batch,
        )
        current = self._write_approved_manifest(
            "current_approved_content_slice.json",
            strong="H0001",
            meaning="현재 의미",
            format_version=3,
            batch_id="RESHET-TEST-CURRENT-APPROVED-CONTENT-SLICE",
            supersedes=[{"strong_number": "H0001", "batch_id": old_batch}],
        )
        authority = self._authority([old, current])

        old_gate = evidence.completion_gate_state_from_authority(
            "H0001", self._projection("H0001", meaning="과거 의미"), authority
        )
        current_gate = evidence.completion_gate_state_from_authority(
            "H0001", self._projection("H0001", meaning="현재 의미"), authority
        )
        self.assertNotEqual(old_gate["state"], "explicit_approved")
        self.assertEqual(current_gate["state"], "explicit_approved")
        self.assertEqual(current_gate["superseded_approval_evidence"], [old.name])

    def test_hold_is_preserved_without_becoming_approval(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [("H0001", self._entry("H0001", "אָב", language_code="heb"))]
        )
        disposition = {
            "strong_number": "H0001",
            "status": "hold",
            "reason": "근거 부족",
            "evidence_refs": ["fixture"],
            "reopen_condition": "새 근거 확보",
        }
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={"H0001": self._projection("H0001", meaning="기존 의미")},
            manifests=[relation_only],
            dispositions=[disposition],
        )

        row = snapshot["rows"][0]
        self.assertEqual(row["semantic_status"], "hold")
        self.assertEqual(row["progress_detail"], "hold")
        self.assertEqual(row["hold_reason"], "근거 부족")

    def test_approved_hold_overlap_fails_closed(self) -> None:
        manifest = self._write_approved_manifest(
            "approved_content_slice.json", strong="H0001", meaning="승인 의미"
        )
        canonical = self._canonical_rows(
            [("H0001", self._entry("H0001", "אָב", language_code="heb"))]
        )
        disposition = {
            "strong_number": "H0001",
            "status": "hold",
            "reason": "충돌 fixture",
            "evidence_refs": ["fixture"],
            "reopen_condition": "충돌 해소",
        }
        with self.assertRaisesRegex(
            research_batch.SemanticResearchBatchError, "authority가 겹침"
        ):
            self._snapshot(
                canonical_rows=canonical,
                projections={"H0001": self._projection("H0001", meaning="승인 의미")},
                manifests=[manifest],
                dispositions=[disposition],
            )

    def test_unapproved_with_and_without_meaning_are_separate(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [
                ("H0001", self._entry("H0001", "אָב", language_code="heb")),
                ("H0002", self._entry("H0002", "אֵם", language_code="heb")),
            ]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={
                "H0001": self._projection("H0001", meaning="기존 의미"),
                "H0002": self._projection("H0002", meaning=None),
            },
            manifests=[relation_only],
        )

        self.assertEqual(
            [row["progress_detail"] for row in snapshot["rows"]],
            ["unapproved_with_meaning", "unapproved_without_meaning"],
        )
        self.assertEqual(snapshot["summary"]["unapproved_with_meaning"], 1)
        self.assertEqual(snapshot["summary"]["unapproved_without_meaning"], 1)

    def test_missing_db_row_is_canonical_anomaly(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [("G0001", self._entry("G0001", "ἄλφα", language_code="G"))]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={},
            manifests=[relation_only],
        )

        self.assertFalse(snapshot["rows"][0]["db_present"])
        self.assertEqual(snapshot["rows"][0]["progress_detail"], "anomaly")
        self.assertIn(
            "canonical_strong_missing_from_work_db",
            snapshot["anomalies"][0]["issues"],
        )

    def test_db_only_strong_is_reported_as_anomaly(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [("G0001", self._entry("G0001", "ἄλφα", language_code="G"))]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={
                "G0001": self._projection("G0001", meaning="기존 의미"),
                "H9999": self._projection("H9999", meaning="비정상"),
            },
            manifests=[relation_only],
        )

        self.assertTrue(
            any(
                anomaly.get("strong") == "H9999"
                and "db_strong_not_in_canonical_universe" in anomaly["issues"]
                for anomaly in snapshot["anomalies"]
            )
        )

    @staticmethod
    def _tagnt_line(reference: str, editions: str, strong: str) -> str:
        return "\t".join(
            [
                reference,
                "λόγος (logos)",
                "word",
                f"{strong}=N-NSM",
                "λόγος=word",
                editions,
                "",
                "",
                "",
                "word",
                "#01",
                strong,
                "",
                "",
                "",
                "",
                "",
            ]
        )

    def test_canonical_occurrence_counts_use_one_pass_parser_contracts(self) -> None:
        tagnt = self.root / "TAGNT.txt"
        header = "\t".join([*evidence.TAGNT_HEADER, "", "", "", ""])
        tagnt.write_text(
            "\n".join(
                [
                    header,
                    self._tagnt_line("Mat.1.1#01=NKO", "NA28", "G0001"),
                    self._tagnt_line("Mat.1.1#02=NKO", "NA27", "G0001"),
                    self._tagnt_line("Mat.1.1#03=KO", "TR+Byz", "G0002"),
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        oshb = self.root / "Gen.xml"
        oshb.write_text(
            """<osis><osisText><div><chapter><verse osisID="Gen.1.1">
<w lemma="1/2" morph="HN">אָב</w><w lemma="2" morph="HN">אֵם</w>
</verse></chapter></div></osisText></osis>""",
            encoding="utf-8",
        )

        greek_counts, greek_stats = evidence.count_tagnt_canonical_occurrences(
            [tagnt]
        )
        hebrew_counts, hebrew_stats = evidence.count_oshb_canonical_occurrences(
            [oshb]
        )
        self.assertEqual(greek_counts, {"G0001": 2})
        self.assertEqual(hebrew_counts, {"H0001": 1, "H0002": 2})
        self.assertEqual(greek_stats["mode"], "all_strongs_index")
        self.assertEqual(hebrew_stats["indexed_occurrence_count"], 3)

    def test_lexical_degrees_deduplicate_related_nodes(self) -> None:
        outgoing = {
            "H0001": [
                {"to_strong": "H0002"},
                {"to_strong": "H0002"},
                {"to_strong": "H0003"},
            ]
        }
        incoming = {
            "H0001": [
                {"from_strong": "H0002"},
                {"from_strong": "H0004"},
                {"from_strong": "H0004"},
            ]
        }
        self.assertEqual(
            progress.lexical_degrees("H0001", outgoing, incoming), (2, 2, 3)
        )

    def test_csv_utf8_escaping_and_deterministic_order(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [
                ("H0001", self._entry("H0001", "אָב", language_code="heb")),
                ("G0001", self._entry("G0001", "λόγος", language_code="G")),
            ]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={
                "G0001": self._projection(
                    "G0001", meaning="말씀, 말", expression="λόγος"
                ),
                "H0001": self._projection(
                    "H0001", meaning="아버지\n부친", expression="אָב"
                ),
            },
            manifests=[relation_only],
        )

        csv_bytes = progress.render_csv(snapshot)
        decoded = csv_bytes.decode("utf-8-sig")
        rows = list(csv.DictReader(io.StringIO(decoded)))
        self.assertEqual([row["strong"] for row in rows], ["G0001", "H0001"])
        self.assertIn("λόγος", decoded)
        self.assertIn("אָב", decoded)
        self.assertIn("아버지", decoded)
        self.assertEqual(csv_bytes, progress.render_csv(snapshot))

    def test_json_csv_markdown_summary_counts_match(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [
                ("G0001", self._entry("G0001", "λόγος", language_code="G")),
                ("H0001", self._entry("H0001", "אָב", language_code="heb")),
            ]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={
                "G0001": self._projection("G0001", meaning="말씀"),
                "H0001": self._projection("H0001", meaning=None),
            },
            manifests=[relation_only],
            occurrence_counts={"G0001": 5, "H0001": 2},
        )

        parsed_json = json.loads(progress._json_bytes(snapshot).decode("utf-8"))
        parsed_csv = list(
            csv.DictReader(
                io.StringIO(progress.render_csv(snapshot).decode("utf-8-sig"))
            )
        )
        markdown = progress.render_markdown(snapshot).decode("utf-8")
        self.assertEqual(len(parsed_json["rows"]), 2)
        self.assertEqual(len(parsed_csv), 2)
        self.assertEqual(parsed_json["summary"]["unapproved"], 2)
        self.assertIn("| 전체 canonical Strong | 2 |", markdown)
        self.assertIn("| unapproved | 2 |", markdown)

    def test_work_database_loader_is_read_only_and_preserves_note(self) -> None:
        work_db = self.root / "work.db"
        connection = sqlite3.connect(work_db)
        try:
            connection.executescript(
                '''
                CREATE TABLE WORD_TABLE (
                  id TEXT PRIMARY KEY,
                  "스트롱넘버" TEXT,
                  "언어" TEXT NOT NULL,
                  "비고" TEXT
                );
                CREATE TABLE word_expression_set (
                  word_id TEXT NOT NULL,
                  seq INTEGER NOT NULL,
                  is_representative INTEGER NOT NULL,
                  spelling TEXT NOT NULL,
                  transliteration TEXT,
                  pronunciation TEXT,
                  pronunciation_notation TEXT,
                  pronunciation_notation_name TEXT
                );
                CREATE TABLE word_meaning_set (
                  word_id TEXT NOT NULL,
                  seq INTEGER NOT NULL,
                  meaning TEXT
                );
                INSERT INTO WORD_TABLE(id, "스트롱넘버", "언어", "비고")
                VALUES ('H0001_0000', 'H0001', '히브리어', '현재 비고'),
                       ('local_0001', NULL, '한국어', NULL),
                       ('bad_0001', 'H9999', '히브리어', NULL);
                INSERT INTO word_expression_set
                VALUES ('H0001_0000', 1, 1, 'אָב', NULL, NULL, NULL, NULL);
                INSERT INTO word_meaning_set VALUES ('H0001_0000', 1, '아버지');
                '''
            )
            connection.commit()
        finally:
            connection.close()
        before = self._sha(work_db)

        projections, anomalies, provenance = progress.load_work_database(work_db)

        self.assertEqual(self._sha(work_db), before)
        self.assertEqual(len(anomalies), 1)
        self.assertEqual(
            anomalies[0]["issues"], ["invalid_or_noncanonical_db_strong"]
        )
        self.assertEqual(projections["H0001"][0]["word_note"], "현재 비고")
        self.assertEqual(provenance["non_strong_row_count"], 1)
        self.assertTrue(provenance["query_only"])

    def test_atomic_refresh_is_deterministic_and_keeps_inputs_unchanged(self) -> None:
        relation_only = self._write_approved_manifest(
            "relation_only_approved_content_slice.json", strong=None, meaning=None
        )
        canonical = self._canonical_rows(
            [("G0001", self._entry("G0001", "λόγος", language_code="G"))]
        )
        snapshot = self._snapshot(
            canonical_rows=canonical,
            projections={"G0001": self._projection("G0001", meaning="말씀")},
            manifests=[relation_only],
        )
        input_file = self.root / "input.txt"
        input_file.write_text("불변", encoding="utf-8")
        input_hashes = {input_file: self._sha(input_file)}
        output = self.root / "output"

        with patch.object(
            progress,
            "collect_progress_snapshot",
            return_value=(snapshot, input_hashes),
        ):
            progress.generate_progress_report(output)
            first = {
                path.name: path.read_bytes()
                for path in output.iterdir()
                if path.is_file()
            }
            progress.generate_progress_report(output)
            second = {
                path.name: path.read_bytes()
                for path in output.iterdir()
                if path.is_file()
            }

        self.assertEqual(first, second)
        self.assertEqual(
            set(first),
            {
                progress.JSON_FILENAME,
                progress.CSV_FILENAME,
                progress.MARKDOWN_FILENAME,
            },
        )
        self.assertEqual(self._sha(input_file), input_hashes[input_file])
        self.assertFalse(any(path.suffix == ".tmp" for path in output.iterdir()))


if __name__ == "__main__":
    unittest.main()
