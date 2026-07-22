#!/usr/bin/env python3

from __future__ import annotations

from collections import Counter
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

import strong_source_diff as legacy
import strong_source_mapping as mapping


class StrongSourceMappingTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.cache = self.root / "cache"
        self.cache.mkdir()
        self.greek = self.cache / "strongsgreek.xml"
        self.hebrew = self.cache / "HebrewStrong.xml"
        self.manifest = self.root / "strong_sources.json"
        self.db = self.root / "fixture.db"
        self.output = self.root / "output"
        self._write_greek_xml()
        self._write_hebrew_xml()
        self._write_manifest()
        self._write_database()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _sha(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def _source(
        self,
        source_id: str,
        language: str,
        repository: str,
        commit: str,
        file_path: str,
        sha256: str,
        parser_contract: str,
    ) -> dict[str, object]:
        owner_name = repository.removeprefix("https://github.com/")
        v2_form_contract = (
            "greek_forms_v2" if language == "G" else "hebrew_forms_v2"
        )
        meaning_contract = (
            "greek_meanings_v2" if language == "G" else "hebrew_meanings_v2"
        )
        return {
            "id": source_id,
            "language": language,
            "repository": repository,
            "commit": commit,
            "version": "fixture",
            "file_path": file_path,
            "download_location": (
                f"https://raw.githubusercontent.com/{owner_name}/"
                f"{commit}/{file_path}"
            ),
            "sha256": sha256,
            "license": "CC0 1.0" if language == "G" else "CC BY 4.0",
            "license_reference": "https://example.invalid/license",
            "required_attribution": None if language == "G" else "fixture",
            "modification_notice": "fixture extraction",
            "fields_used": ["headword"],
            "fields_excluded": ["definition"],
            "parser_contract": parser_contract,
            "parser_contracts": [parser_contract, v2_form_contract],
            "meaning_projection_contract": meaning_contract,
        }

    def _write_manifest(self) -> None:
        greek_commit = "a" * 40
        hebrew_commit = "b" * 40
        payload = {
            "schema_version": 1,
            "contract_versions": {
                "mapping_contract": "strong_mapping_v2",
            },
            "sources": [
                self._source(
                    "greek_fixture",
                    "G",
                    "https://github.com/example/greek",
                    greek_commit,
                    self.greek.name,
                    self._sha(self.greek),
                    "greek_headword_v1",
                ),
                self._source(
                    "hebrew_fixture",
                    "H",
                    "https://github.com/example/hebrew",
                    hebrew_commit,
                    self.hebrew.name,
                    self._sha(self.hebrew),
                    "hebrew_direct_w_v1",
                ),
            ],
        }
        self.manifest.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )

    def _write_greek_xml(self) -> None:
        self.greek.write_text(
            '''<?xml version="1.0" encoding="utf-8"?>
<strongsdictionary><entries>
  <entry strongs="1">
    <greek unicode="Α" translit="A"/>
    <pronunciation strongs="alpha"/>
    <strongs_def><greek unicode="무시" translit="ignored"/></strongs_def>
    <greek unicode="역시무시" translit="ignored"/>
  </entry>
</entries></strongsdictionary>
''',
            encoding="utf-8",
        )

    def _write_hebrew_xml(self) -> None:
        self.hebrew.write_text(
            '''<?xml version="1.0" encoding="utf-8"?>
<lexicon xmlns="http://openscriptures.github.com/morphhb/namespace">
  <entry id="H1">
    <w pron="aleph" xlit="alef" xml:lang="heb" pos="n">א</w>
    <note><w pron="ignored" xlit="ignored">무시</w></note>
  </entry>
</lexicon>
''',
            encoding="utf-8",
        )

    def _write_database(self) -> None:
        connection = sqlite3.connect(self.db)
        connection.executescript(
            '''
            CREATE TABLE WORD_TABLE (
              id TEXT PRIMARY KEY,
              "언어" TEXT,
              "스트롱넘버" TEXT,
              graph_expand_mode TEXT NOT NULL DEFAULT 'default'
            );
            CREATE TABLE word_expression_set (
              id INTEGER PRIMARY KEY,
              word_id TEXT NOT NULL,
              seq INTEGER NOT NULL,
              is_representative INTEGER NOT NULL,
              spelling TEXT NOT NULL,
              transliteration TEXT,
              pronunciation TEXT,
              pronunciation_notation TEXT,
              pronunciation_notation_name TEXT
            );
            INSERT INTO WORD_TABLE(id, "언어", "스트롱넘버")
              VALUES ('G0001_0000', '헬라어', 'G0001'),
                     ('H0001_0000', '히브리어', 'H0001');
            INSERT INTO word_expression_set(
              word_id, seq, is_representative, spelling, transliteration,
              pronunciation, pronunciation_notation, pronunciation_notation_name
            ) VALUES
              ('G0001_0000', 1, 1, 'Α', 'A', 'alpha', 'unknown', NULL),
              ('H0001_0000', 1, 1, 'א', 'alef', 'aleph', 'unknown', NULL);
            '''
        )
        connection.commit()
        connection.close()

    @staticmethod
    def expression(
        spelling: str,
        pronunciation: str | None,
        *,
        seq: int = 1,
        representative: int = 1,
        notation: str | None = "unknown",
    ) -> mapping.MappingExpression:
        return mapping.MappingExpression(
            word_id="word",
            strong_number="G0001",
            language="헬라어",
            seq=seq,
            is_representative=representative,
            spelling=spelling,
            transliteration=None,
            pronunciation=pronunciation,
            pronunciation_notation=notation,
            pronunciation_notation_name=None,
        )

    @staticmethod
    def word(
        expressions: list[mapping.MappingExpression], strong: str = "G0001"
    ) -> mapping.MappingWord:
        return mapping.MappingWord("word", strong, "헬라어", expressions)

    def test_01_official_source_manifest_schema(self) -> None:
        raw, specs = mapping.load_source_manifest(self.manifest)
        self.assertEqual(raw["schema_version"], 1)
        self.assertEqual(raw["contract_versions"]["mapping_contract"], "strong_mapping_v2")
        self.assertEqual([spec.language for spec in specs], ["G", "H"])
        self.assertEqual(
            [spec.parser_contract for spec in specs],
            ["greek_headword_v1", "hebrew_direct_w_v1"],
        )
        self.assertEqual(
            [spec.parser_contracts for spec in specs],
            [
                ("greek_headword_v1", "greek_forms_v2"),
                ("hebrew_direct_w_v1", "hebrew_forms_v2"),
            ],
        )
        for field_name in mapping.REQUIRED_SOURCE_FIELDS:
            self.assertIn(field_name, raw["sources"][0])

    def test_02_source_hash_match_and_parser_schema(self) -> None:
        _, _, datasets, statuses = mapping.validate_sources(
            self.manifest, self.cache
        )
        self.assertTrue(all(status["hash_verified"] for status in statuses))
        self.assertEqual([dataset.entry_count for dataset in datasets], [1, 1])
        self.assertEqual(
            mapping.fetch_sources(self.manifest, self.cache)[0]["status"],
            "already_verified",
        )

    def test_03_source_hash_mismatch_fails_before_parsing(self) -> None:
        self.greek.write_text("<broken>", encoding="utf-8")
        with self.assertRaisesRegex(RuntimeError, "source hash 불일치"):
            mapping.validate_sources(self.manifest, self.cache)

    def test_04_greek_parser_headword_boundary(self) -> None:
        dataset = legacy.parse_greek_xml(self.greek)
        self.assertEqual(dataset.candidates["G0001"], [legacy.SourceCandidate("Α", "A", "alpha")])

    def test_05_hebrew_parser_direct_child_w_boundary(self) -> None:
        dataset = legacy.parse_hebrew_xml(self.hebrew)
        self.assertEqual(dataset.candidates["H0001"], [legacy.SourceCandidate("א", "alef", "aleph")])

    def test_06_raw_spelling_and_pronunciation_mapping(self) -> None:
        pairs, left_candidates, left_expressions = mapping.deterministic_bijection(
            "G0001",
            [legacy.SourceCandidate("a", "", "p")],
            [self.expression("a", "p")],
        )
        self.assertEqual(pairs[0].mapping_rule, "raw_spelling_exact_pronunciation")
        self.assertEqual((left_candidates, left_expressions), ([], []))

    def test_07_nfc_spelling_and_pronunciation_mapping(self) -> None:
        pairs, _, _ = mapping.deterministic_bijection(
            "G0001",
            [legacy.SourceCandidate("é", "", "p")],
            [self.expression("e\u0301", "p")],
        )
        self.assertEqual(pairs[0].mapping_rule, "nfc_spelling_exact_pronunciation")

    def test_08_raw_spelling_only_mapping(self) -> None:
        pairs, _, _ = mapping.deterministic_bijection(
            "G0001",
            [legacy.SourceCandidate("a", "", "source")],
            [self.expression("a", "db")],
        )
        self.assertEqual(pairs[0].mapping_rule, "raw_spelling")

    def test_09_nfc_spelling_only_mapping(self) -> None:
        pairs, _, _ = mapping.deterministic_bijection(
            "G0001",
            [legacy.SourceCandidate("é", "", "source")],
            [self.expression("e\u0301", "db")],
        )
        self.assertEqual(pairs[0].mapping_rule, "nfc_spelling")

    def test_10_mutual_uniqueness_is_required(self) -> None:
        candidates = [
            legacy.SourceCandidate("a", "one", "p1"),
            legacy.SourceCandidate("a", "two", "p2"),
        ]
        expressions = [self.expression("a", "x", seq=1), self.expression("a", "y", seq=2)]
        pairs, left_candidates, left_expressions = mapping.deterministic_bijection(
            "G0001", candidates, expressions
        )
        self.assertEqual(pairs, [])
        self.assertEqual((len(left_candidates), len(left_expressions)), (2, 2))

    def test_11_earlier_pair_removal_allows_later_rule_pair(self) -> None:
        candidates = [
            legacy.SourceCandidate("a", "one", "p1"),
            legacy.SourceCandidate("a", "two", "p2"),
        ]
        expressions = [self.expression("a", "p1", seq=1), self.expression("a", "x", seq=2)]
        pairs, _, _ = mapping.deterministic_bijection("G0001", candidates, expressions)
        self.assertEqual(
            [pair.mapping_rule for pair in pairs],
            ["raw_spelling_exact_pronunciation", "raw_spelling"],
        )

    def test_12_complete_bijection_is_auto(self) -> None:
        candidates = [
            legacy.SourceCandidate("a", "", "p1"),
            legacy.SourceCandidate("b", "", "p2"),
        ]
        expressions = [self.expression("a", "p1"), self.expression("b", "x", seq=2, representative=0)]
        result = mapping.analyze_word(self.word(expressions), candidates)
        self.assertEqual(result.primary_disposition, "auto")
        self.assertEqual(len(result.pairings), 2)

    def test_13_partial_mapping_with_residue_is_exception(self) -> None:
        candidates = [
            legacy.SourceCandidate("a", "one", "p1"),
            legacy.SourceCandidate("b", "two", "p2"),
        ]
        expressions = [self.expression("a", "p1"), self.expression("x", "x", seq=2, representative=0)]
        result = mapping.analyze_word(self.word(expressions), candidates)
        self.assertEqual(result.primary_disposition, "exception")
        self.assertIn("unmatched_source_candidate", result.reason_codes)
        self.assertIn("unmatched_db_expression", result.reason_codes)

    def test_14_cardinality_mismatch_is_exception(self) -> None:
        result = mapping.analyze_word(
            self.word([self.expression("a", "p"), self.expression("b", "q", seq=2, representative=0)]),
            [legacy.SourceCandidate("a", "", "p")],
        )
        self.assertIn("source_db_cardinality_mismatch", result.reason_codes)
        self.assertIn("expression_structure_change_required", result.reason_codes)

    def test_15_pronunciation_only_match_is_not_used(self) -> None:
        pairs, _, _ = mapping.deterministic_bijection(
            "G0001",
            [legacy.SourceCandidate("source", "", "same")],
            [self.expression("db", "same")],
        )
        self.assertEqual(pairs, [])

    def test_16_trimmed_pronunciation_is_not_exact(self) -> None:
        pairs, _, _ = mapping.deterministic_bijection(
            "G0001",
            [legacy.SourceCandidate("a", "", "same")],
            [self.expression("a", " same ")],
        )
        self.assertEqual(pairs[0].mapping_rule, "raw_spelling")

    def test_17_source_order_does_not_change_mapping(self) -> None:
        candidates = [
            legacy.SourceCandidate("a", "", "p1"),
            legacy.SourceCandidate("b", "", "p2"),
        ]
        expressions = [self.expression("b", "p2"), self.expression("a", "p1", seq=2, representative=0)]
        first = mapping.deterministic_bijection("G0001", candidates, expressions)[0]
        second = mapping.deterministic_bijection("G0001", list(reversed(candidates)), expressions)[0]
        project = lambda pairs: sorted(
            (pair.candidate.diagnostic_id, pair.expression.spelling, pair.mapping_rule)
            for pair in pairs
        )
        self.assertEqual(project(first), project(second))

    def test_18_db_seq_does_not_change_pair_choice(self) -> None:
        candidates = [legacy.SourceCandidate("a", "", "p1"), legacy.SourceCandidate("b", "", "p2")]
        first = [self.expression("a", "p1", seq=1), self.expression("b", "p2", seq=2, representative=0)]
        second = [self.expression("a", "p1", seq=2, representative=0), self.expression("b", "p2", seq=1)]
        project = lambda expressions: sorted(
            (pair.candidate.candidate.spelling, pair.expression.spelling)
            for pair in mapping.deterministic_bijection("G0001", candidates, expressions)[0]
        )
        self.assertEqual(project(first), project(second))

    def test_19_representative_is_not_a_pairing_criterion(self) -> None:
        candidate = [legacy.SourceCandidate("a", "", "p")]
        representative = mapping.deterministic_bijection(
            "G0001", candidate, [self.expression("a", "p", representative=1)]
        )[0]
        secondary = mapping.deterministic_bijection(
            "G0001", candidate, [self.expression("a", "p", representative=0)]
        )[0]
        self.assertEqual(representative[0].mapping_rule, secondary[0].mapping_rule)

    def test_20_duplicate_source_candidate_is_exception(self) -> None:
        candidate = legacy.SourceCandidate("a", "", "p")
        result = mapping.analyze_word(self.word([self.expression("a", "p")]), [candidate, candidate])
        self.assertEqual(result.primary_disposition, "exception")
        self.assertIn("source_duplicate_candidate", result.reason_codes)

    def test_21_placeholder_is_hold(self) -> None:
        result = mapping.analyze_word(self.word([self.expression("a", "p")], "G0000"), [])
        self.assertEqual(result.primary_disposition, "hold")
        self.assertEqual(result.reason_codes, ["placeholder"])

    def test_22_invalid_strong_id_is_hold(self) -> None:
        result = mapping.analyze_word(self.word([self.expression("a", "p")], "X1"), [])
        self.assertEqual(result.primary_disposition, "hold")
        self.assertEqual(result.reason_codes, ["invalid_strong_id"])

    def test_23_missing_source_pronunciation_preserves_db_metadata(self) -> None:
        result = mapping.analyze_word(
            self.word([self.expression("a", "legacy", notation="unknown")]),
            [legacy.SourceCandidate("a", "", "")],
        )
        change = mapping.build_change(result.pairings[0])
        self.assertEqual(result.primary_disposition, "auto")
        self.assertEqual(change["change_classification"], "source_pronunciation_missing")
        self.assertEqual(change["expected_pronunciation"], "legacy")
        self.assertEqual(change["expected_pronunciation_notation"], "unknown")

    def test_24_notation_only_expected_change(self) -> None:
        result = mapping.analyze_word(
            self.word([self.expression("a", "p", notation="unknown")]),
            [legacy.SourceCandidate("a", "", "p")],
        )
        change = mapping.build_change(result.pairings[0])
        self.assertEqual(change["change_classification"], "notation_only_update")
        self.assertTrue(change["notation_change"])
        self.assertEqual(
            change["expected_field_changes"], ["pronunciation_notation"]
        )

    def test_24b_nfc_only_change_classification(self) -> None:
        result = mapping.analyze_word(
            self.word([self.expression("e\u0301", "p", notation="strong_dictionary")]),
            [legacy.SourceCandidate("é", "", "p")],
        )
        change = mapping.build_change(result.pairings[0])
        self.assertEqual(change["change_classification"], "nfc_only_match")
        self.assertEqual(change["expected_field_changes"], ["spelling"])

    def test_25_ambiguous_mapping_is_exception(self) -> None:
        candidates = [legacy.SourceCandidate("a", "one", "p1"), legacy.SourceCandidate("a", "two", "p2")]
        expressions = [self.expression("a", "x"), self.expression("a", "y", seq=2, representative=0)]
        result = mapping.analyze_word(self.word(expressions), candidates)
        self.assertEqual(result.primary_disposition, "exception")
        self.assertIn("ambiguous_bijection", result.reason_codes)

    def test_26_source_only_item_is_hold(self) -> None:
        analyses = mapping.analyze_database([], {"G0001": [legacy.SourceCandidate("a", "", "p")]})
        self.assertEqual(analyses[0].primary_disposition, "hold")
        self.assertIn("db_target_missing", analyses[0].reason_codes)

    def test_27_db_only_item_is_hold(self) -> None:
        analyses = mapping.analyze_database(
            [self.word([self.expression("a", "p")], "G0002")], {}
        )
        self.assertEqual(analyses[0].primary_disposition, "hold")
        self.assertIn("source_entry_missing", analyses[0].reason_codes)

    def test_28_exception_manifest_required_fields(self) -> None:
        analysis = mapping.analyze_word(
            self.word([self.expression("x", "x")]),
            [legacy.SourceCandidate("a", "", "p")],
        )
        item = mapping.build_exception_manifest([analysis], "fixture")["items"][0]
        self.assertTrue(
            {
                "strong_id",
                "word_id",
                "language",
                "db_expressions",
                "source_candidates",
                "primary_disposition",
                "reason_codes",
                "uncertainty",
                "recommended_follow_up",
            }.issubset(item)
        )
        self.assertTrue(
            {"seq", "is_representative", "spelling", "pronunciation", "pronunciation_notation"}.issubset(
                item["db_expressions"][0]
            )
        )

    def test_29_database_is_read_only_and_hash_unchanged(self) -> None:
        before = legacy.sha256_file(self.db)
        snapshot = mapping.load_database_snapshot(self.db)
        after = legacy.sha256_file(self.db)
        self.assertEqual(before, after)
        self.assertEqual(snapshot.metadata["query_only"], 1)
        self.assertEqual(snapshot.metadata["integrity_check"], "ok")
        connection, _, _ = legacy.open_read_only_database(self.db)
        try:
            with self.assertRaises(sqlite3.OperationalError):
                connection.execute("DELETE FROM WORD_TABLE")
        finally:
            connection.close()

    def test_30_dry_run_outputs_and_semantic_parity(self) -> None:
        result = mapping.run_dry_run(self.manifest, self.cache, self.db, self.output)
        for filename in (
            "manifest.json",
            "summary.json",
            "mapping_plan.jsonl",
            "exception_manifest.json",
        ):
            self.assertTrue((self.output / filename).is_file())
        self.assertEqual(result["summary"]["disposition_counts"]["auto"], 2)
        self.assertEqual(
            result["summary"]["expected_field_change_counts"]["notation"], 2
        )
        parity = mapping.compare_database_projections(self.db, self.db)
        self.assertTrue(parity["semantic_projection_equal"])
        self.assertEqual(parity["left_only_count"], 0)

    def test_31_v2_contract_is_explicit_and_v1_default_is_unchanged(self) -> None:
        _, _, v1_datasets, v1_statuses = mapping.validate_sources(
            self.manifest, self.cache
        )
        _, _, v2_datasets, v2_statuses = mapping.validate_source_projections_v2(
            self.manifest, self.cache
        )
        self.assertEqual(
            [status["parser_contract"] for status in v1_statuses],
            ["greek_headword_v1", "hebrew_direct_w_v1"],
        )
        self.assertTrue(
            all(isinstance(dataset, legacy.SourceDataset) for dataset in v1_datasets)
        )
        self.assertTrue(
            all(isinstance(dataset, legacy.SourceDatasetV2) for dataset in v2_datasets)
        )
        self.assertEqual(
            [status["form_parser_contract"] for status in v2_statuses],
            ["greek_forms_v2", "hebrew_forms_v2"],
        )

    def test_32_mapping_v2_preserves_source_order_and_db_transliteration(self) -> None:
        context = legacy.SourceXmlContextV2("G1520", "headword", 2, 3)
        alternate_context = legacy.SourceXmlContextV2("G1520", "headword", 4, None)
        entry = legacy.SourceEntryV2(
            source_key="G1520",
            source_language_code="G",
            disposition="ready",
            forms=(
                legacy.GreekSourceFormV2(
                    "G1520", 1, "primary", "εἷς", "heîs", "hice", "G", context
                ),
                legacy.GreekSourceFormV2(
                    "G1520", 2, "alternate", "ἕν", "hén", None, "G", alternate_context
                ),
            ),
            meanings=(),
        )
        expression = mapping.MappingExpression(
            "G1520_0000",
            "G1520",
            "헬라어",
            1,
            1,
            "εἷς",
            "기존 음역",
            "hice",
            "strong_dictionary",
            None,
        )
        word = mapping.MappingWord("G1520_0000", "G1520", "헬라어", [expression])
        rows = mapping.build_mapping_v2({"G1520": entry}, [word])
        self.assertEqual([row.source_form_order for row in rows], [1, 2])
        self.assertEqual(rows[0].expected_values["transliteration"], "기존 음역")
        self.assertEqual(rows[0].action, "no_change")
        self.assertEqual(rows[1].action, "insert_expression_candidate")
        self.assertIsNone(rows[1].source_pronunciation)
        self.assertIsNone(rows[1].expected_values["pronunciation_notation"])

    def test_33_source_only_projection_holds_x_pn_and_is_deterministic(self) -> None:
        def entry(key: str, language_code: str) -> legacy.SourceEntryV2:
            context = legacy.SourceXmlContextV2(key, "headword", 1)
            return legacy.SourceEntryV2(
                source_key=key,
                source_language_code=language_code,
                disposition=(
                    "source_language_unresolved"
                    if language_code == "x-pn"
                    else "ready"
                ),
                forms=(
                    legacy.HebrewSourceFormV2(
                        key,
                        1,
                        "primary",
                        "א",
                        "alef",
                        "aleph",
                        language_code,
                        "n",
                        context,
                    ),
                ),
                meanings=(
                    legacy.SourceMeaningV2(key, 1, "meaning", "meaning", context),
                ),
            )

        entries = {"H1649": entry("H1649", "x-pn"), "H1655": entry("H1655", "arc")}
        rows = mapping.build_mapping_v2(entries, [])
        hold = next(row for row in rows if row.source_key == "H1649")
        self.assertEqual(hold.action, "hold")
        self.assertEqual(hold.hold_reason, "source_language_x_pn_unresolved")
        projections = mapping.build_source_only_import_projections(entries, [], "default")
        self.assertEqual([item["source_key"] for item in projections], ["H1655"])
        self.assertEqual(projections[0]["language"], "아람어")
        self.assertEqual(projections[0]["expressions"][0]["is_representative"], 1)
        self.assertEqual(
            mapping.serialize_source_only_projections(projections),
            mapping.serialize_source_only_projections(list(reversed(projections))),
        )

    @unittest.skipUnless(
        (Path(__file__).with_name(".source_cache") / "strongsgreek.xml").is_file()
        and (Path(__file__).with_name(".source_cache") / "HebrewStrong.xml").is_file()
        and (Path(__file__).parents[2] / "data" / "reshet_work.db").is_file(),
        "고정 Strong source cache와 active work DB가 필요함",
    )
    def test_34_official_mapping_v2_source_only_projection(self) -> None:
        repository = Path(__file__).parents[2]
        manifest = Path(__file__).with_name("manifests") / "strong_sources.json"
        cache = Path(__file__).with_name(".source_cache")
        _, _, datasets, _ = mapping.validate_source_projections_v2(manifest, cache)
        entries = mapping.combine_v2_datasets(datasets)
        snapshot = mapping.load_database_snapshot(repository / "data" / "reshet_work.db")
        rows = mapping.build_mapping_v2(entries, snapshot.words)
        projections = mapping.build_source_only_import_projections(
            entries,
            snapshot.words,
            str(snapshot.metadata["graph_expand_mode_default"]),
        )

        expected_source_only: set[str] = set()
        expected_x_pn = {
            "H1649", "H1721", "H2044", "H2647", "H2650", "H3160",
            "H3184", "H3265", "H3959", "H5011", "H7288", "H8206",
        }
        self.assertEqual({item["source_key"] for item in projections}, expected_source_only)
        self.assertEqual(
            Counter(item["language"] for item in projections),
            Counter(),
        )
        self.assertEqual(projections, [])
        self.assertEqual(
            {
                row.source_key
                for row in rows
                if row.current_word_id is None
                and row.hold_reason == "source_language_x_pn_unresolved"
            },
            expected_x_pn,
        )
        g1520_alternate = next(
            row
            for row in rows
            if row.source_key == "G1520" and row.source_form_order == 2
        )
        self.assertEqual(g1520_alternate.action, "insert_expression_candidate")
        self.assertIsNone(g1520_alternate.source_pronunciation)
        self.assertEqual(
            len(
                {
                    row.source_key
                    for row in rows
                    if row.hold_reason == "source_db_language_mismatch_deferred"
                }
            ),
            0,
        )
        self.assertEqual(
            sum(
                row.current_word_id is not None and "meaning" in row.action
                for row in rows
            ),
            0,
        )
        serialized = mapping.serialize_source_only_projections(projections)
        self.assertFalse(serialized.startswith(b"\xef\xbb\xbf"))
        self.assertEqual(serialized, b"")
        self.assertEqual(len(serialized.decode("utf-8").splitlines()), 0)
        self.assertEqual(
            mapping.source_only_projection_sha256(projections),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        )


if __name__ == "__main__":
    unittest.main()
