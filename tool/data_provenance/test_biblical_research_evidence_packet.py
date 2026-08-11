#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

import biblical_research_evidence_packet as evidence
import strong_source_diff as legacy


class BiblicalResearchEvidencePacketTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _sha(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def _git_blob(path: Path) -> str:
        digest = hashlib.sha1()
        data = path.read_bytes()
        digest.update(f"blob {len(data)}\0".encode("ascii"))
        digest.update(data)
        return digest.hexdigest()

    def _write_occurrence_manifest(self) -> tuple[Path, Path]:
        cache = self.root / "cache"
        oshb = cache / "fixture" / "oshb" / "wlc" / "Gen.xml"
        tagnt = cache / "fixture" / "tagnt" / "TAGNT.txt"
        oshb.parent.mkdir(parents=True)
        tagnt.parent.mkdir(parents=True)
        oshb.write_text("<osis/>", encoding="utf-8")
        tagnt.write_text("fixture\n", encoding="utf-8")
        manifest = self.root / "occurrence.json"
        manifest.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "cache_namespace": "fixture",
                    "sources": [
                        {
                            "id": "oshb",
                            "repository": "https://github.com/example/oshb",
                            "commit": "a" * 40,
                            "files": [
                                {
                                    "path": "wlc/Gen.xml",
                                    "sha256": self._sha(oshb),
                                }
                            ],
                            "license": {"text": "Public Domain"},
                            "attribution": "fixture",
                            "parser_contract": "oshb_wlc_osis_v1",
                            "canonical_profile": {"id": "fixture"},
                        },
                        {
                            "id": "tagnt",
                            "repository": "https://github.com/example/tagnt",
                            "commit": "b" * 40,
                            "files": [
                                {
                                    "path": "TAGNT.txt",
                                    "sha256": self._sha(tagnt),
                                    "git_blob": self._git_blob(tagnt),
                                }
                            ],
                            "license": {"data": "CC BY 4.0"},
                            "attribution": "fixture",
                            "parser_contract": "tagnt_tsv_na27_28_v1",
                            "canonical_profile": {"id": "fixture"},
                        },
                    ],
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        return manifest, cache

    @staticmethod
    def _create_lexicon(path: Path, rows: list[tuple[str, str]]) -> None:
        connection = sqlite3.connect(path)
        try:
            connection.execute(
                "CREATE TABLE Lexicon "
                "(id INTEGER PRIMARY KEY AUTOINCREMENT, scode VARCHAR, dtext VARCHAR)"
            )
            connection.executemany(
                "INSERT INTO Lexicon(scode,dtext) VALUES (?,?)", rows
            )
            connection.commit()
        finally:
            connection.close()

    @staticmethod
    def _create_bible(
        path: Path,
        rows: list[tuple[int, int, int, str]],
        *,
        wrong_schema: bool = False,
    ) -> None:
        connection = sqlite3.connect(path)
        try:
            last_column = "wrong VARCHAR" if wrong_schema else "btext VARCHAR"
            connection.execute(
                "CREATE TABLE Bible ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "book INTEGER, chapter INTEGER, verse INTEGER, "
                f"{last_column})"
            )
            if not wrong_schema:
                connection.executemany(
                    "INSERT INTO Bible(book,chapter,verse,btext) VALUES (?,?,?,?)",
                    rows,
                )
            connection.commit()
        finally:
            connection.close()

    def _write_local_sources(
        self,
        *,
        duplicate_lexicon: bool = False,
        wrong_schema_source: str | None = None,
    ) -> tuple[Path, Path]:
        source_dir = self.root / "local"
        source_dir.mkdir()
        lexicon_rows = [("G1225", "reference")]
        if duplicate_lexicon:
            lexicon_rows = [("G404", "first"), ("G404", "second")]
        self._create_lexicon(source_dir / "HebGrkKo.dct", lexicon_rows)
        bible_sources = [
            (
                "KJV_S.sdb",
                "kjv",
                "strong_tagged_bible_v1",
                "was accused<WG1225>",
            ),
            (
                "개역개정S.sdb",
                "korean_revised",
                "strong_tagged_bible_v1",
                "들린지라<WG1225>",
            ),
            (
                "개역한글S.sdb",
                "korean_revised_legacy",
                "strong_tagged_bible_v1",
                "들린지라<WG1225>",
            ),
            (
                "새번역.bdb",
                "korean_new_translation",
                "verse_only_bible_v1",
                "고발하는 말이 들렸다.",
            ),
            (
                "원전분해.sdb",
                "original_language_analysis",
                "original_analysis_v1",
                "[διεβλήθη] (기본 <WG1225> [διαβάλλω] 디아발로)"
                "@동사 과거 수동 # 들린지라*",
            ),
        ]
        for filename, source_id, _, text in bible_sources:
            self._create_bible(
                source_dir / filename,
                [(42, 16, 1, text)],
                wrong_schema=source_id == wrong_schema_source,
            )
        rows = [
            {
                "filename": "HebGrkKo.dct",
                "expected_sha256": self._sha(source_dir / "HebGrkKo.dct"),
                "role": "lexicon",
            }
        ]
        for filename, source_id, _, _ in bible_sources:
            rows.append(
                {
                    "filename": filename,
                    "expected_sha256": self._sha(source_dir / filename),
                    "role": source_id,
                }
            )
        manifest = self.root / "local.json"
        manifest.write_text(
            json.dumps(
                {
                    "reference_only_boundary": "fixture",
                    "sources": rows,
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        return manifest, source_dir

    @staticmethod
    def _tagnt_line(
        reference: str,
        *,
        editions: str,
        simple_strong: str,
    ) -> str:
        fields = [
            reference,
            "διεβλήθη (dieblēthē)",
            "was accused",
            "G1225=V-API-3S",
            "διαβάλλω=to accuse",
            editions,
            "",
            "",
            "",
            "to accuse",
            "#01",
            simple_strong,
            "",
            "",
            "",
            "",
            "",
        ]
        return "\t".join(fields)

    def test_manifest_and_source_hash_validation(self) -> None:
        manifest, cache = self._write_occurrence_manifest()
        _, specs, paths, provenance = evidence.ensure_occurrence_sources(
            manifest, cache, allow_fetch=False
        )
        self.assertEqual(len(specs), 2)
        self.assertEqual(set(paths), {"oshb", "tagnt"})
        self.assertTrue(all(row["files"][0]["hash_verified"] for row in provenance))

    def test_local_fingerprint_mismatch_fails_closed(self) -> None:
        manifest, source_dir = self._write_local_sources()
        with (source_dir / "KJV_S.sdb").open("ab") as output:
            output.write(b"changed")
        with self.assertRaisesRegex(evidence.EvidencePacketError, "fingerprint"):
            evidence.validate_local_sources(manifest, source_dir)

    def test_local_schema_mismatch_fails_closed(self) -> None:
        manifest, source_dir = self._write_local_sources(
            wrong_schema_source="korean_new_translation"
        )
        with self.assertRaisesRegex(evidence.SourceSchemaError, "schema"):
            evidence.validate_local_sources(manifest, source_dir)

    def test_strong_normalization_rejects_nonstandard_marker(self) -> None:
        self.assertEqual(legacy.normalize_strong_number("G32"), "G0032")
        self.assertEqual(legacy.normalize_strong_number("H0032"), "H0032")
        self.assertIsNone(legacy.normalize_strong_number("G1160b"))
        self.assertIsNone(legacy.normalize_strong_number("G0"))
        self.assertIsNone(legacy.normalize_strong_number("H0"))

    def test_strong_window_is_deterministic_and_marks_direct_reference(self) -> None:
        context = legacy.SourceXmlContextV2("G0032", "headword", 1)
        entry = legacy.SourceEntryV2(
            source_key="G0032",
            source_language_code="G",
            disposition="ready",
            forms=(
                legacy.GreekSourceFormV2(
                    source_key="G0032",
                    source_document_order=1,
                    form_role="primary",
                    spelling="ἄγγελος",
                    transliteration="angelos",
                    pronunciation="angelos",
                    source_language="G",
                    xml_context=context,
                ),
            ),
            meanings=(),
        )
        references = [{"normalized_strong": "G0025"}]
        first = evidence.build_strong_window({"G0032": entry}, "G0032", references)
        second = evidence.build_strong_window({"G0032": entry}, "G0032", references)
        self.assertEqual(first, second)
        self.assertEqual((first["start"], first["end"]), ("G0022", "G0042"))
        self.assertEqual(len(first["items"]), 21)
        self.assertTrue(first["items"][3]["direct_reference_from_target"])

    def test_direct_derivation_extractor_uses_only_source_references(self) -> None:
        source = self.root / "greek.xml"
        source.write_text(
            """<strongsdictionary><entries><entry strongs="1225">
<greek unicode="διαβάλλω"/><strongs_derivation>
from <strongsref language="GREEK" strongs="1223"/> and
<strongsref language="GREEK" strongs="906"/></strongs_derivation>
<strongs_def>compare <strongsref language="GREEK" strongs="999"/></strongs_def>
</entry></entries></strongsdictionary>""",
            encoding="utf-8",
        )
        references = evidence.extract_direct_references(source, "G1225")
        self.assertEqual(
            [row["normalized_strong"] for row in references],
            ["G1223", "G0906"],
        )

    def test_tagnt_canonical_profile_excludes_other_only_variant(self) -> None:
        source = self.root / "TAGNT.txt"
        header = "\t".join([*evidence.TAGNT_HEADER, "", "", "", ""])
        source.write_text(
            "\n".join(
                [
                    header,
                    self._tagnt_line(
                        "Luk.16.1#17=NKO",
                        editions="NA28+NA27+TR+Byz",
                        simple_strong="G1225",
                    ),
                    self._tagnt_line(
                        "Luk.16.1#18=KO",
                        editions="TR+Byz",
                        simple_strong="G1225",
                    ),
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        occurrences, stats = evidence.parse_tagnt_occurrences([source], "G1225")
        self.assertEqual(len(occurrences), 1)
        self.assertEqual(occurrences[0]["canonical_verse_key"], "Luke.16.1")
        self.assertEqual(occurrences[0]["morphology"], "V-API-3S")
        self.assertEqual(stats["canonical_profile_row_count"], 1)

    def test_oshb_occurrence_preserves_augmented_lemma(self) -> None:
        source = self.root / "Num.xml"
        source.write_text(
            """<?xml version="1.0" encoding="UTF-8"?>
<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
<osisText><div><chapter><verse osisID="Num.3.35">
<w lemma="c/32 a" morph="HC/Np">וַ/אֲבִיחַיִל</w>
<w lemma="33" morph="HNp">אַחֵר</w>
</verse></chapter></div></osisText></osis>""",
            encoding="utf-8",
        )
        occurrences, stats = evidence.parse_oshb_occurrences([source], "H0032")
        self.assertEqual(len(occurrences), 1)
        self.assertEqual(occurrences[0]["lemma"], "c/32 a")
        self.assertEqual(
            occurrences[0]["normalized_standard_strong"], "H0032"
        )
        self.assertIn("augmented_strong_lemma_preserved", occurrences[0]["warnings"])
        self.assertEqual(stats["word_token_count"], 2)

    def test_translation_join_and_nonstandard_marker_nonmerge(self) -> None:
        manifest, source_dir = self._write_local_sources()
        _, specs, _ = evidence.validate_local_sources(manifest, source_dir)
        occurrence = {
            "canonical_verse_key": "Luke.16.1",
            "surface": "διεβλήθη",
            "lemma": "διαβάλλω",
            "token_position": 17,
            "source_stable_order": {"file_order": 1, "line_number": 1},
        }
        attached, stats, expressions = evidence.attach_local_references(
            [occurrence], specs, source_dir, "G1225"
        )
        revised = attached[0]["local_references"]["korean_revised"]
        new_translation = attached[0]["local_references"][
            "korean_new_translation"
        ]
        self.assertEqual(revised["status"], "matched")
        self.assertEqual(
            revised["records"][0]["matched_translation_tokens"], ["들린지라"]
        )
        self.assertEqual(new_translation["records"][0]["marker_alignment"], "not_available")
        self.assertEqual(stats["kjv"]["local_target_marker_count"], 1)
        self.assertEqual(expressions["kjv"]["was accused"], 1)
        self.assertEqual(
            evidence._extract_strong_tagged_tokens(
                "다윗<WG1160b> 표준<WG1160> 영<WG0>", "G1160"
            ),
            ["표준"],
        )
        missing_lemma = evidence._original_analysis_entries(
            "[ἄγγελος] (기본 <WG32>)@명사 # 사자*", "G0032"
        )
        self.assertEqual(missing_lemma[0]["surface"], "ἄγγελος")
        self.assertIsNone(missing_lemma[0]["lemma"])
        self.assertIsNone(missing_lemma[0]["transliteration"])

    def test_duplicate_hebgrkko_row_is_not_selected(self) -> None:
        manifest, source_dir = self._write_local_sources(duplicate_lexicon=True)
        _, specs = evidence.load_local_manifest(manifest)
        lexicon = next(
            spec for spec in specs if spec.parser_contract == "lexicon_scode_dtext_v1"
        )
        reference = evidence.load_lexical_reference(lexicon, source_dir, "G0404")
        self.assertEqual(reference["exact_row_count"], 2)
        self.assertIsNone(reference["description"])
        self.assertEqual(
            reference["warning"], "multiple_exact_scode_rows_no_selection"
        )

    def test_completion_gate_hanja_marker_is_candidate_not_approval(self) -> None:
        approved = self.root / "approved.json"
        source_only = self.root / "source_only.json"
        approved.write_text('{"meaning_replacements": []}', encoding="utf-8")
        source_only.write_text('{"entries": []}', encoding="utf-8")
        projection = [
            {
                "word_id": "G1225_0000",
                "meanings": [{"seq": 1, "meaning": "고발하다(告發-)"}],
            }
        ]
        state = evidence.completion_gate_state(
            "G1225", projection, approved, source_only
        )
        self.assertEqual(state["state"], "legacy_hanja_candidate")
        self.assertIn("자동 최종 승인 확정이 아님", state["interpretation"])

    def test_deterministic_json_bytes(self) -> None:
        first = evidence.serialize_packet({"b": 2, "a": ["한글", 1]})
        second = evidence.serialize_packet({"a": ["한글", 1], "b": 2})
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))
        self.assertEqual(first.decode("utf-8"), second.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
