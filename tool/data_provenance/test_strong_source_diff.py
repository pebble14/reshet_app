#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

import strong_source_diff as diff


class StrongSourceDiffTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.db = self.root / "fixture.db"
        self.greek = self.root / "strongsgreek.xml"
        self.hebrew = self.root / "HebrewStrong.xml"
        self.output = self.root / "output"
        self._write_database()
        self._write_greek_xml()
        self._write_hebrew_xml()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _write_database(self) -> None:
        connection = sqlite3.connect(self.db)
        connection.executescript(
            '''
            CREATE TABLE WORD_TABLE (
              id TEXT PRIMARY KEY,
              "언어" TEXT,
              "스트롱넘버" TEXT
            );
            CREATE TABLE word_expression_set (
              id INTEGER PRIMARY KEY,
              word_id TEXT NOT NULL,
              seq INTEGER NOT NULL,
              is_representative INTEGER NOT NULL,
              spelling TEXT NOT NULL,
              transliteration TEXT,
              pronunciation TEXT
            );
            '''
        )
        connection.executemany(
            'INSERT INTO WORD_TABLE(id, "언어", "스트롱넘버") VALUES (?, ?, ?)',
            [
                ("G0001_0000", "헬라어", "G0001"),
                ("G0025_0000", "헬라어", "G0025"),
                ("H0157_0000", "히브리어", "H0157"),
                ("H9999_0000", "히브리어", "H9999"),
            ],
        )
        connection.executemany(
            '''
            INSERT INTO word_expression_set(
              word_id, seq, is_representative, spelling, transliteration, pronunciation
            ) VALUES (?, ?, ?, ?, ?, ?)
            ''',
            [
                ("G0001_0000", 1, 1, "Α", "알파", "al'-fah"),
                ("G0001_0000", 2, 0, "α", "알파", "al'-fah"),
                ("G0025_0000", 1, 1, "ἀγαπάω", "아가파오", "ag-ap-ah'-o"),
                ("H0157_0000", 1, 1, "אָהַב", "아하브", "aw-hab'"),
                ("H0157_0000", 2, 0, "אָהֵב", "아헤브", "aw-habe'"),
                ("H9999_0000", 1, 1, "בדיקה", "테스트", "123"),
            ],
        )
        connection.commit()
        connection.close()

    def _write_greek_xml(self) -> None:
        self.greek.write_text(
            '''<?xml version="1.0" encoding="utf-8"?>
<strongsdictionary><prologue>fixture</prologue><entries>
  <entry strongs="00001"><strongs>1</strongs>
    <greek unicode="Α" translit="A"/><pronunciation strongs="al'-fah"/>
    <strongs_derivation>fixture</strongs_derivation>
    <greek unicode="무시" translit="ignored"/>
  </entry>
  <entry strongs="00025"><strongs>25</strongs>
    <greek unicode="ἀγαπάω" translit="agapáō"/>
    <pronunciation strongs="ag-ap-ah'-o"/>
  </entry>
</entries></strongsdictionary>
''',
            encoding="utf-8",
        )

    def _write_hebrew_xml(self) -> None:
        self.hebrew.write_text(
            '''<?xml version="1.0" encoding="utf-8"?>
<lexicon xmlns="http://openscriptures.github.com/morphhb/namespace">
  <entry id="H157"><w pron="aw-hab'" xlit="ʼâhab">אָהַב</w></entry>
</lexicon>
''',
            encoding="utf-8",
        )

    @staticmethod
    def expression(
        spelling: str,
        pronunciation: str,
        strong: str = "G0001",
        representative: int = 1,
    ) -> diff.DbExpression:
        return diff.DbExpression(
            word_id="word",
            strong_number=strong,
            language="fixture",
            seq=1,
            is_representative=representative,
            spelling=spelling,
            transliteration="",
            pronunciation=pronunciation,
        )

    def test_01_normalize_strong_number(self) -> None:
        for value in ("G1", "G0001", "g1", "G 1"):
            self.assertEqual(diff.normalize_strong_number(value), "G0001")
        for value in ("H157", "H0157", "h0157"):
            self.assertEqual(diff.normalize_strong_number(value), "H0157")
        self.assertEqual(diff.normalize_strong_number("00001", "G"), "G0001")

    def test_02_invalid_strong_number(self) -> None:
        for value in (None, "", "1", "G0", "G5625", "H8675", "X1"):
            self.assertIsNone(diff.normalize_strong_number(value))
        row = diff.compare_expression(
            self.expression("x", "y", strong="H9999"), {}
        )
        self.assertEqual(row["comparison_status"], "invalid_strong_number")

    def test_03_raw_spelling_exact(self) -> None:
        row = diff.compare_expression(
            self.expression("Α", "al'-fah"),
            {"G0001": [diff.SourceCandidate("Α", "A", "al'-fah")]},
        )
        self.assertEqual(row["comparison_status"], "exact_match")
        self.assertTrue(row["spelling_raw_equal"])

    def test_04_nfc_only_spelling_match(self) -> None:
        row = diff.compare_expression(
            self.expression("ἀγαπάω", "ag-ap-ah'-o", strong="G0025"),
            {
                "G0025": [
                    diff.SourceCandidate("ἀγαπάω", "agapáō", "ag-ap-ah'-o")
                ]
            },
        )
        self.assertFalse(row["spelling_raw_equal"])
        self.assertTrue(row["spelling_nfc_equal"])
        self.assertEqual(row["comparison_status"], "normalized_spelling_match")

    def test_05_pronunciation_exact(self) -> None:
        row = diff.compare_expression(
            self.expression("x", "exact"),
            {"G0001": [diff.SourceCandidate("y", "", "exact")]},
        )
        self.assertTrue(row["pronunciation_raw_equal"])
        self.assertEqual(
            row["comparison_status"], "pronunciation_match_spelling_diff"
        )

    def test_06_pronunciation_mismatch(self) -> None:
        row = diff.compare_expression(
            self.expression("x", "db"),
            {"G0001": [diff.SourceCandidate("x", "", "source")]},
        )
        self.assertEqual(
            row["comparison_status"], "spelling_match_pronunciation_diff"
        )

    def test_07_empty_pronunciation(self) -> None:
        db_empty = diff.compare_expression(
            self.expression("x", ""),
            {"G0001": [diff.SourceCandidate("x", "", "source")]},
        )
        source_empty = diff.compare_expression(
            self.expression("x", "db"),
            {"G0001": [diff.SourceCandidate("x", "", "")]},
        )
        self.assertEqual(db_empty["comparison_status"], "db_pronunciation_empty")
        self.assertEqual(
            source_empty["comparison_status"], "source_pronunciation_empty"
        )

    def test_08_source_missing(self) -> None:
        row = diff.compare_expression(self.expression("x", "y"), {})
        self.assertEqual(row["comparison_status"], "source_missing")

    def test_09_multiple_source_candidate(self) -> None:
        candidates = {
            "G0001": [
                diff.SourceCandidate("a", "", "one"),
                diff.SourceCandidate("b", "", "two"),
            ]
        }
        ambiguous = diff.compare_expression(
            self.expression("c", "three"), candidates
        )
        selected = diff.compare_expression(self.expression("b", "two"), candidates)
        self.assertEqual(ambiguous["comparison_status"], "source_ambiguous")
        self.assertEqual(selected["comparison_status"], "exact_match")

    def test_10_representative_and_secondary(self) -> None:
        rows = [
            diff.compare_expression(
                self.expression("a", "one", representative=1),
                {"G0001": [diff.SourceCandidate("a", "", "one")]},
            ),
            diff.compare_expression(
                diff.DbExpression(
                    "word", "G0001", "fixture", 2, 0, "b", "", "two"
                ),
                {"G0001": [diff.SourceCandidate("a", "", "one")]},
            ),
        ]
        diff.classify_secondary_rows(rows)
        self.assertEqual(rows[0]["secondary_classification"], "representative")
        self.assertEqual(
            rows[1]["secondary_classification"], "source_variant_not_found"
        )

    def test_11_pronunciation_type(self) -> None:
        cases = {
            "": "empty",
            "123": "digits_only",
            "잊혀짐": "hangul",
            "ag-ap-ah'-o": "strong_style",
            "metil": "latin_plain",
            "ˈmi.zon": "ipa_like",
            "matmon 마트문": "mixed",
            "אבד": "other",
        }
        for value, expected in cases.items():
            with self.subTest(value=value):
                self.assertEqual(diff.classify_pronunciation(value), expected)

    def test_12_output_csv_and_json_created(self) -> None:
        result = diff.run_diff(
            str(self.db),
            str(self.greek),
            str(self.hebrew),
            str(self.output),
            pretty=True,
        )
        for name in (
            "manifest.json",
            "summary.json",
            "expression_diff.csv",
            "word_summary.csv",
        ):
            self.assertTrue((self.output / name).is_file())
        summary = json.loads((self.output / "summary.json").read_text("utf-8"))
        self.assertEqual(
            summary["database"]["expression_count"],
            len(result["expression_rows"]),
        )
        self.assertIn("secondary_classification_counts", summary)

    def test_13_read_only_database_connection(self) -> None:
        connection, query_only, integrity = diff.open_read_only_database(self.db)
        try:
            self.assertEqual(query_only, 1)
            self.assertEqual(integrity, "ok")
            with self.assertRaises(sqlite3.OperationalError):
                connection.execute(
                    'UPDATE WORD_TABLE SET "언어" = "x" WHERE id = "missing"'
                )
        finally:
            connection.close()

    def test_14_database_hash_unchanged(self) -> None:
        before = diff.sha256_file(self.db)
        diff.run_diff(
            str(self.db),
            str(self.greek),
            str(self.hebrew),
            str(self.output),
        )
        after = diff.sha256_file(self.db)
        self.assertEqual(before, after)

    def test_15_xml_schema_mismatch_fails(self) -> None:
        invalid = self.root / "invalid.xml"
        invalid.write_text("<unexpected><entry/></unexpected>", encoding="utf-8")
        with self.assertRaisesRegex(
            diff.SourceSchemaError, "root tag=.*예상 핵심 구조=.*추출 항목 수=0"
        ):
            diff.parse_greek_xml(invalid)

    def test_16_actual_fixture_schema_and_variant_boundary(self) -> None:
        greek = diff.parse_greek_xml(self.greek)
        hebrew = diff.parse_hebrew_xml(self.hebrew)
        self.assertEqual(greek.root_tag, "strongsdictionary")
        self.assertEqual(len(greek.candidates["G0001"]), 1)
        self.assertEqual(greek.candidates["G0001"][0].spelling, "Α")
        self.assertIn("H0157", hebrew.candidates)

    def test_17_strong_filter(self) -> None:
        result = diff.run_diff(
            str(self.db),
            str(self.greek),
            str(self.hebrew),
            str(self.output),
            strong_filters=["G0001"],
        )
        self.assertEqual(result["summary"]["database"]["strong_word_count"], 1)
        self.assertTrue(
            all(row["strong_number"] == "G0001" for row in result["expression_rows"])
        )


if __name__ == "__main__":
    unittest.main()
