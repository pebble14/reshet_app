#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

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

    @staticmethod
    def _write_approved_manifest(
        directory: Path,
        filename: str,
        word_id: str,
        meaning: str | None,
        *,
        format_version: int = 1,
        batch_id: str | None = None,
        word_note_replacements: list[dict[str, object]] | None = None,
        supersedes: list[dict[str, str]] | None = None,
        relation_replacements: list[dict[str, object]] | None = None,
        meaning_approvals: list[dict[str, object]] | None = None,
    ) -> Path:
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / filename
        default_batch_label = (
            filename.removesuffix("_approved_content_slice.json")
            .replace("_", "-")
            .upper()
        )
        payload = {
            "format_version": format_version,
            "batch_id": (
                batch_id
                or f"RESHET-TEST-{default_batch_label}-APPROVED-CONTENT-SLICE"
            ),
            "provenance": {"document_id": "test", "document_sha256": "0" * 64},
            "target": {"expected_work_sha256": "0" * 64, "expected_user_version": 0},
            "meaning_replacements": (
                [
                    {
                        "word_id": word_id,
                        "before": [{"seq": 1, "meaning": "before"}],
                        "after": [{"seq": 1, "meaning": meaning}],
                    }
                ]
                if meaning is not None
                else []
            ),
            "relation_creates": [],
        }
        if format_version in (2, 3, 4, 5):
            payload["word_note_replacements"] = word_note_replacements or []
        if format_version in (3, 4, 5):
            payload["supersedes"] = supersedes or []
        if format_version in (4, 5):
            payload["relation_replacements"] = relation_replacements or []
        if format_version == 5:
            payload["meaning_approvals"] = meaning_approvals or []
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return path

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
        bible_rows_by_source: dict[
            str, list[tuple[int, int, int, str]]
        ]
        | None = None,
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
            rows = (
                bible_rows_by_source.get(source_id, [(42, 16, 1, text)])
                if bible_rows_by_source is not None
                else [(42, 16, 1, text)]
            )
            self._create_bible(
                source_dir / filename,
                rows,
                wrong_schema=source_id == wrong_schema_source,
            )
        rows = [
            {
                "filename": "HebGrkKo.dct",
                "expected_sha256": self._sha(source_dir / "HebGrkKo.dct"),
                "role": "lexicon",
                "reference_profile": "not_applicable",
            }
        ]
        for filename, source_id, _, _ in bible_sources:
            rows.append(
                {
                    "filename": filename,
                    "expected_sha256": self._sha(source_dir / filename),
                    "role": source_id,
                    "reference_profile": (
                        "kjv" if source_id == "kjv" else "unverified"
                    ),
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
        lexical_strong = simple_strong.split("_", 1)[0]
        fields = [
            reference,
            "διεβλήθη (dieblēthē)",
            "was accused",
            f"{lexical_strong}=V-API-3S",
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
        self.assertEqual(
            set(references[0]),
            {
                "source_order",
                "source_container",
                "raw_language",
                "raw_reference",
                "normalized_strong",
                "warning",
            },
        )

    def test_relation_discovery_extractor_expands_greek_scope_and_context(self) -> None:
        entry = ET.fromstring(
            """<entry strongs="100">
<strongs_derivation>probably from <strongsref language="GREEK" strongs="101"/>;</strongs_derivation>
<strongs_def>inflected from <strongsref language="GREEK" strongs="102"/>;
equivalent to <strongsref language="GREEK" strongs="103"/>;
compare <strongsref language="GREEK" strongs="104"/>.</strongs_def>
<kjv_def>variant of <strongsref language="GREEK" strongs="105"/>.</kjv_def>
from the same as <strongsref language="GREEK" strongs="106"/>.
</entry>"""
        )

        direct = evidence.extract_entry_reference_relations(entry, "G0100")
        expanded = evidence.extract_relation_discovery_references(entry, "G0100")

        self.assertEqual(
            [row["target_strong"] for row in direct],
            ["G0101"],
        )
        self.assertEqual(
            [row["target_strong"] for row in expanded],
            ["G0101", "G0102", "G0103", "G0104", "G0105", "G0106"],
        )
        self.assertEqual(
            [row["source_container"] for row in expanded],
            [
                "strongs_derivation",
                "strongs_def",
                "strongs_def",
                "strongs_def",
                "kjv_def",
                "entry",
            ],
        )
        self.assertEqual(
            [row["source_order"] for row in expanded],
            list(range(1, 7)),
        )
        contexts = {
            str(row["target_strong"]): str(row["reference_context"])
            for row in expanded
        }
        for target, wording in (
            ("G0101", "probably from"),
            ("G0102", "inflected from"),
            ("G0103", "equivalent to"),
            ("G0104", "compare"),
            ("G0105", "variant of"),
            ("G0106", "from the same as"),
        ):
            with self.subTest(target=target):
                self.assertIn(wording, contexts[target].lower())
                self.assertIn(f"[[{target}]]", contexts[target])

    def test_relation_discovery_extractor_expands_hebrew_scope(self) -> None:
        entry = ET.fromstring(
            """<entry id="H200">
<source>from <w src="H201">201</w>.</source>
<usage>Compare <w src="H202">202</w>.</usage>
<meaning>equivalent to <w src="H203">203</w>.</meaning>
</entry>"""
        )

        direct = evidence.extract_entry_reference_relations(entry, "H0200")
        expanded = evidence.extract_relation_discovery_references(entry, "H0200")

        self.assertEqual([row["target_strong"] for row in direct], ["H0201"])
        self.assertEqual(
            [row["target_strong"] for row in expanded],
            ["H0201", "H0202", "H0203"],
        )
        self.assertEqual(
            [row["source_container"] for row in expanded],
            ["source", "usage", "meaning"],
        )
        self.assertTrue(
            all(row["source_language_code"] == "H" for row in expanded)
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

    def test_h1672_kjv_alternate_is_used_without_unverified_fallback(self) -> None:
        source = self.root / "Ps.xml"
        source.write_text(
            """<?xml version="1.0" encoding="UTF-8"?>
<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
<osisText><div><chapter><verse osisID="Ps.38.19">
<note>KJV:Ps.38.18</note>
<w lemma="1672" morph="HVqi1cs">אֶדְאַג</w>
</verse></chapter></div></osisText></osis>""",
            encoding="utf-8",
        )
        occurrences, _ = evidence.parse_oshb_occurrences([source], "H1672")
        occurrence = occurrences[0]
        self.assertEqual(occurrence["canonical_verse_key"], "Psalms.38.19")
        self.assertEqual(occurrence["source_base_verse_key"], "Psalms.38.19")
        self.assertEqual(
            occurrence["source_reference_alternates"],
            [
                {
                    "kind": "kjv",
                    "raw_reference": "KJV:Ps.38.18",
                    "verse_key": "Psalms.38.18",
                    "parse_status": "parsed",
                }
            ],
        )

        unverified_ids = (
            "korean_revised",
            "korean_revised_legacy",
            "korean_new_translation",
            "original_language_analysis",
        )
        bible_rows = {
            source_id: [(19, 38, 19, "잘못된 같은 번호 절<WH1672>")]
            for source_id in unverified_ids
        }
        bible_rows["kjv"] = [
            (19, 38, 18, "I am troubled<WH1672>"),
            (19, 38, 19, "wrong same-number verse<WH1672>"),
        ]
        manifest, source_dir = self._write_local_sources(
            bible_rows_by_source=bible_rows
        )
        _, specs, _ = evidence.validate_local_sources(manifest, source_dir)
        attached, _, _ = evidence.attach_local_references(
            occurrences, specs, source_dir, "H1672"
        )
        references = attached[0]["local_references"]
        kjv = references["kjv"]
        self.assertEqual(kjv["status"], "matched")
        self.assertEqual(kjv["target_lookup_verse_key"], "Psalms.38.18")
        self.assertEqual(
            kjv["reference_selection_reason"], "explicit_profile_alternate"
        )
        self.assertEqual(kjv["records"][0]["source_verse_key"], "19.38.18")
        for source_id in unverified_ids:
            reference = references[source_id]
            self.assertEqual(reference["status"], "manual_review_required")
            self.assertIsNone(reference["target_lookup_verse_key"])
            self.assertFalse(reference["lookup_performed"])
            self.assertEqual(reference["records"], [])

    def test_g0403_base_and_kjv_alternate_are_resolved_per_target(self) -> None:
        source = self.root / "TAGNT.txt"
        header = "\t".join([*evidence.TAGNT_HEADER, "", "", "", ""])
        source.write_text(
            header
            + "\n"
            + self._tagnt_line(
                "Act.3.20[3.19]#05=NKO",
                editions="NA28+NA27+TR+Byz",
                simple_strong="G0403",
            )
            + "\n",
            encoding="utf-8",
        )
        occurrences, _ = evidence.parse_tagnt_occurrences([source], "G0403")
        occurrence = occurrences[0]
        self.assertEqual(occurrence["canonical_verse_key"], "Acts.3.20")
        self.assertEqual(
            occurrence["source_reference_alternates"][0]["verse_key"],
            "Acts.3.19",
        )

        unverified_ids = (
            "korean_revised",
            "korean_revised_legacy",
            "korean_new_translation",
            "original_language_analysis",
        )
        bible_rows = {
            source_id: [(44, 3, 20, "검증되지 않은 같은 번호 절<WG403>")]
            for source_id in unverified_ids
        }
        bible_rows["kjv"] = [
            (44, 3, 19, "times of refreshing<WG403>"),
            (44, 3, 20, "wrong same-number verse<WG403>"),
        ]
        manifest, source_dir = self._write_local_sources(
            bible_rows_by_source=bible_rows
        )
        _, specs, _ = evidence.validate_local_sources(manifest, source_dir)
        attached, _, _ = evidence.attach_local_references(
            occurrences, specs, source_dir, "G0403"
        )
        references = attached[0]["local_references"]
        self.assertEqual(references["kjv"]["status"], "matched")
        self.assertEqual(
            references["kjv"]["target_lookup_verse_key"], "Acts.3.19"
        )
        self.assertTrue(
            all(
                references[source_id]["status"] == "manual_review_required"
                for source_id in unverified_ids
            )
        )

    def test_explicit_alternate_lookup_miss_does_not_fallback(self) -> None:
        occurrence = {
            "canonical_verse_key": "Psalms.38.19",
            "source_base_verse_key": "Psalms.38.19",
            "source_reference_alternates": [
                {
                    "kind": "kjv",
                    "raw_reference": "KJV:Ps.38.18",
                    "verse_key": "Psalms.38.18",
                    "parse_status": "parsed",
                }
            ],
        }
        source_ids = (
            "kjv",
            "korean_revised",
            "korean_revised_legacy",
            "korean_new_translation",
            "original_language_analysis",
        )
        bible_rows = {
            source_id: [(19, 38, 19, "fallback하면 안 되는 절<WH1672>")]
            for source_id in source_ids
        }
        manifest, source_dir = self._write_local_sources(
            bible_rows_by_source=bible_rows
        )
        _, specs, _ = evidence.validate_local_sources(manifest, source_dir)

        attached, _, _ = evidence.attach_local_references(
            [occurrence], specs, source_dir, "H1672"
        )

        kjv = attached[0]["local_references"]["kjv"]
        self.assertEqual(kjv["target_lookup_verse_key"], "Psalms.38.18")
        self.assertTrue(kjv["lookup_performed"])
        self.assertEqual(kjv["status"], "unmatched")
        self.assertEqual(kjv["records"], [])

    def test_g1344_na_alternate_does_not_replace_occurrence_identity(self) -> None:
        source = self.root / "TAGNT.txt"
        header = "\t".join([*evidence.TAGNT_HEADER, "", "", "", ""])
        source.write_text(
            header
            + "\n"
            + self._tagnt_line(
                "Act.13.39(13.38)#11=NKO",
                editions="NA28+NA27+TR+Byz",
                simple_strong="G1344",
            )
            + "\n",
            encoding="utf-8",
        )
        occurrences, _ = evidence.parse_tagnt_occurrences([source], "G1344")
        occurrence = occurrences[0]
        self.assertEqual(occurrence["canonical_verse_key"], "Acts.13.39")
        self.assertEqual(occurrence["source_base_verse_key"], "Acts.13.39")
        self.assertEqual(
            occurrence["source_reference_alternates"][0],
            {
                "kind": "na",
                "raw_reference": "(13.38)",
                "verse_key": "Acts.13.38",
                "parse_status": "parsed",
            },
        )

        source_ids = (
            "kjv",
            "korean_revised",
            "korean_revised_legacy",
            "korean_new_translation",
            "original_language_analysis",
        )
        bible_rows = {
            source_id: [
                (44, 13, 38, "잘못된 NA 번호 절<WG1344>"),
                (44, 13, 39, "source base 번호 절<WG1344>"),
            ]
            for source_id in source_ids
        }
        manifest, source_dir = self._write_local_sources(
            bible_rows_by_source=bible_rows
        )
        _, specs, _ = evidence.validate_local_sources(manifest, source_dir)
        attached, _, _ = evidence.attach_local_references(
            occurrences, specs, source_dir, "G1344"
        )
        references = attached[0]["local_references"]
        for reference in references.values():
            self.assertEqual(reference["status"], "manual_review_required")
            self.assertIsNone(reference["target_lookup_verse_key"])
            self.assertFalse(reference["lookup_performed"])
            self.assertEqual(reference["records"], [])

    def test_oshb_multiple_and_special_kjv_notes_require_manual_review(self) -> None:
        kjv_spec = evidence.LocalSourceSpec(
            id="kjv",
            filename="KJV_S.sdb",
            expected_sha256="0" * 64,
            role="fixture",
            reference_only=True,
            parser_contract="strong_tagged_bible_v1",
            reference_profile="kjv",
        )
        multiple_source = self.root / "Ps.xml"
        multiple_source.write_text(
            """<osis><osisText><verse osisID="Ps.13.6">
<note>KJV:Ps.13.5</note><w lemma="982" morph="HVqp1cs">בָטַחְתִּי</w>
<note>KJV:Ps.13.6</note></verse></osisText></osis>""",
            encoding="utf-8",
        )
        multiple_occurrences, _ = evidence.parse_oshb_occurrences(
            [multiple_source], "H0982"
        )
        multiple = multiple_occurrences[0]
        self.assertEqual(
            [row["raw_reference"] for row in multiple["source_reference_alternates"]],
            ["KJV:Ps.13.5", "KJV:Ps.13.6"],
        )
        self.assertTrue(multiple["source_reference_ambiguous"])
        multiple_decision = evidence.resolve_target_reference(multiple, kjv_spec)
        self.assertTrue(multiple_decision["manual_review_required"])
        self.assertEqual(
            multiple_decision["reference_selection_reason"],
            "ambiguous_source_reference",
        )

        suffix_source = self.root / "1Kgs.xml"
        suffix_source.write_text(
            """<osis><osisText><verse osisID="1Kgs.22.44">
<note>KJV:1Kgs.22.43!b</note><w lemma="389" morph="HTa">אַךְ</w>
</verse></osisText></osis>""",
            encoding="utf-8",
        )
        suffix_occurrences, _ = evidence.parse_oshb_occurrences(
            [suffix_source], "H0389"
        )
        suffix = suffix_occurrences[0]
        self.assertEqual(
            suffix["source_reference_alternates"][0]["parse_status"],
            "unsupported_suffix",
        )
        self.assertEqual(
            suffix["source_reference_alternates"][0]["raw_reference"],
            "KJV:1Kgs.22.43!b",
        )
        suffix_decision = evidence.resolve_target_reference(suffix, kjv_spec)
        self.assertTrue(suffix_decision["manual_review_required"])
        self.assertIsNone(suffix_decision["target_lookup_verse_key"])

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
            revised["reference_selection_reason"],
            "same_key_no_source_conflict",
        )
        self.assertEqual(revised["target_lookup_verse_key"], "Luke.16.1")
        self.assertFalse(revised["manual_review_required"])
        self.assertTrue(revised["lookup_performed"])
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
        approved = self._write_approved_manifest(
            self.root,
            "p2_approved_content_slice.json",
            "H2020_0000",
            "구원",
        )
        source_only = self.root / "source_only.json"
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

    def test_completion_gate_aggregates_applied_approved_manifests(self) -> None:
        approved = evidence.discover_approved_content_manifests()
        manifest_names = [path.name for path in approved]
        self.assertEqual(manifest_names, sorted(manifest_names))
        self.assertTrue(
            {
                "first_semantic_batch_approved_content_slice.json",
                "h1672_h1674_approved_content_slice.json",
                "p1_historical_approval_approved_content_slice.json",
                "p2_approved_content_slice.json",
                "second_semantic_batch_approved_content_slice.json",
            }.issubset(manifest_names)
        )
        for strong, expected_state, expected_evidence in (
            ("H2020", "explicit_approved", "p2_approved_content_slice.json"),
            (
                "H1674",
                "explicit_approved",
                "h1672_h1674_approved_content_slice.json",
            ),
            (
                "H1618",
                "explicit_approved",
                "first_semantic_batch_approved_content_slice.json",
            ),
            (
                "H1564",
                "explicit_approved",
                "second_semantic_batch_approved_content_slice.json",
            ),
            (
                "H1653",
                "explicit_approved",
                "p1_historical_approval_approved_content_slice.json",
            ),
            (
                "H1655",
                "explicit_approved",
                "p1_historical_approval_approved_content_slice.json",
            ),
            (
                "H1656",
                "explicit_approved",
                "p1_historical_approval_approved_content_slice.json",
            ),
            ("H5337", "unclassified", None),
        ):
            with self.subTest(strong=strong):
                projection, _ = evidence.load_reshet_projection(
                    evidence.DEFAULT_WORK_DB, strong
                )
                state = evidence.completion_gate_state(
                    strong,
                    projection,
                    approved,
                    evidence.DEFAULT_SOURCE_ONLY_MANIFEST,
                )
                self.assertEqual(state["state"], expected_state)
                if expected_evidence is not None:
                    self.assertIn(expected_evidence, state["evidence"])

    def test_completion_gate_v2_uses_meaning_and_ignores_note_projection(self) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1674_v2_approved_content_slice.json",
            "H1674_0000",
            "걱정",
            format_version=2,
            word_note_replacements=[
                {
                    "word_id": "H1674_0000",
                    "before": None,
                    "after": "승인 비고",
                }
            ],
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        projection = [
            {
                "word_id": "H1674_0000",
                "meanings": [{"seq": 1, "meaning": "걱정"}],
                "note": "현재 DB note가 승인값과 달라도 completion에는 미사용",
            }
        ]

        state = evidence.completion_gate_state(
            "H1674", projection, approved, source_only
        )
        self.assertEqual(state["state"], "explicit_approved")
        self.assertEqual(state["evidence"], [approved.name])

    def test_completion_gate_v2_note_only_does_not_approve(self) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1674_note_only_approved_content_slice.json",
            "H1674_0000",
            None,
            format_version=2,
            word_note_replacements=[
                {
                    "word_id": "H1674_0000",
                    "before": None,
                    "after": "승인 비고",
                }
            ],
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        projection = [
            {
                "word_id": "H1674_0000",
                "meanings": [{"seq": 1, "meaning": "걱정"}],
            }
        ]

        state = evidence.completion_gate_state(
            "H1674", projection, approved, source_only
        )
        self.assertEqual(state["state"], "unclassified")
        self.assertEqual(state["evidence"], [])

    def test_completion_gate_v4_relation_only_does_not_approve(self) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1652_relation_only_approved_content_slice.json",
            "H1652_0000",
            None,
            format_version=4,
            relation_replacements=[
                {
                    "relation_id": 7617,
                    "word_id_1": "H1652_0000",
                    "word_id_2": "H1653_0000",
                    "before": {
                        "category_code": "etymological",
                        "relation_type": "root_shared",
                        "status_code": "asserted",
                        "direction_code": "undirected",
                        "description": None,
                        "relation_group_id": None,
                        "note": None,
                        "source": "RESHET-TEST-BEFORE",
                    },
                    "after": {
                        "category_code": "morphological",
                        "relation_type": "derived",
                        "status_code": "asserted",
                        "direction_code": "w1_to_w2",
                        "description": None,
                        "relation_group_id": None,
                        "note": None,
                        "source": "RESHET-TEST-AFTER",
                    },
                }
            ],
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        state = evidence.completion_gate_state(
            "H1652",
            [
                {
                    "word_id": "H1652_0000",
                    "meanings": [{"seq": 1, "meaning": "비를 내리다"}],
                }
            ],
            approved,
            source_only,
        )
        self.assertEqual(state["state"], "unclassified")
        self.assertEqual(state["evidence"], [])

        payload = json.loads(approved.read_text(encoding="utf-8"))
        payload["format_version"] = 3
        approved.write_text(
            json.dumps(payload, ensure_ascii=False), encoding="utf-8"
        )
        with self.assertRaisesRegex(evidence.ManifestError, "format 계약 불일치"):
            evidence._approved_projections_by_strong(approved)

    def test_completion_gate_v5_approves_exact_current_meaning_projection(
        self,
    ) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1674_v5_approved_content_slice.json",
            "H1674_0000",
            None,
            format_version=5,
            meaning_approvals=[
                {
                    "word_id": "H1674_0000",
                    "meanings": [{"seq": 1, "meaning": "걱정"}],
                }
            ],
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        exact_projection = [
            {
                "word_id": "H1674_0000",
                "meanings": [{"seq": 1, "meaning": "걱정"}],
            }
        ]

        state = evidence.completion_gate_state(
            "H1674", exact_projection, approved, source_only
        )
        self.assertEqual(state["state"], "explicit_approved")
        self.assertEqual(state["evidence"], [approved.name])

        mismatch = evidence.completion_gate_state(
            "H1674",
            [
                {
                    "word_id": "H1674_0000",
                    "meanings": [{"seq": 1, "meaning": "다른 값"}],
                }
            ],
            approved,
            source_only,
        )
        self.assertEqual(mismatch["state"], "unclassified")

    def test_completion_gate_v5_approval_contract_fails_closed(self) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1674_v5_invalid_approved_content_slice.json",
            "H1674_0000",
            "교체 값",
            format_version=5,
            meaning_approvals=[
                {
                    "word_id": "H1674_0000",
                    "meanings": [{"seq": 1, "meaning": "현행 값"}],
                }
            ],
        )
        with self.assertRaisesRegex(evidence.ManifestError, "word_id 중복"):
            evidence._approved_projections_by_strong(approved)

        payload = json.loads(approved.read_text(encoding="utf-8"))
        payload["meaning_replacements"] = []
        payload["meaning_approvals"] = [
            {
                "word_id": "H1674_0000",
                "meanings": [
                    {"seq": 2, "meaning": "둘째"},
                    {"seq": 1, "meaning": "첫째"},
                ],
            }
        ]
        approved.write_text(
            json.dumps(payload, ensure_ascii=False), encoding="utf-8"
        )
        with self.assertRaisesRegex(evidence.ManifestError, "형식 불일치"):
            evidence._approved_projections_by_strong(approved)

    def test_completion_gate_v4_keeps_v3_supersession_semantics(self) -> None:
        old_batch_id = "RESHET-TEST-H5229-OLD-APPROVED-CONTENT-SLICE"
        old = self._write_approved_manifest(
            self.root,
            "h5229_old_approved_content_slice.json",
            "H5229_0000",
            "올곧음",
            batch_id=old_batch_id,
        )
        active = self._write_approved_manifest(
            self.root,
            "h5229_v4_active_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            format_version=4,
            supersedes=[
                {"strong_number": "H5229", "batch_id": old_batch_id}
            ],
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        state = evidence.completion_gate_state(
            "H5229",
            [
                {
                    "word_id": "H5229_0000",
                    "meanings": [{"seq": 1, "meaning": "올바름"}],
                }
            ],
            [old, active],
            source_only,
        )
        self.assertEqual(state["state"], "explicit_approved")
        self.assertEqual(state["active_approval_evidence"], [active.name])
        self.assertEqual(state["superseded_approval_evidence"], [old.name])

    def test_completion_gate_v2_note_contract_fails_closed(self) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1674_invalid_note_approved_content_slice.json",
            "H1674_0000",
            "걱정",
            format_version=2,
            word_note_replacements=[
                {
                    "word_id": "H1674_0000",
                    "before": None,
                    "after": "   ",
                }
            ],
        )
        with self.assertRaisesRegex(evidence.ManifestError, "non-empty"):
            evidence._approved_projections_by_strong(approved)

        payload = json.loads(approved.read_text(encoding="utf-8"))
        payload["word_note_replacements"] = [
            {"word_id": "H1674_0000", "before": None, "after": "첫 값"},
            {"word_id": "H1674_0000", "before": None, "after": "둘째 값"},
        ]
        approved.write_text(
            json.dumps(payload, ensure_ascii=False), encoding="utf-8"
        )
        with self.assertRaisesRegex(evidence.ManifestError, "note word_id 중복"):
            evidence._approved_projections_by_strong(approved)

        payload["word_note_replacements"] = []
        payload["unknown_operation"] = []
        approved.write_text(
            json.dumps(payload, ensure_ascii=False), encoding="utf-8"
        )
        with self.assertRaisesRegex(evidence.ManifestError, "format 계약 불일치"):
            evidence._approved_projections_by_strong(approved)

    def test_completion_gate_does_not_approve_projection_mismatch(self) -> None:
        approved = self._write_approved_manifest(
            self.root,
            "h1674_approved_content_slice.json",
            "H1674_0000",
            "걱정",
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        state = evidence.completion_gate_state(
            "H1674",
            [
                {
                    "word_id": "H1674_0000",
                    "meanings": [{"seq": 1, "meaning": "아직 미적용"}],
                }
            ],
            approved,
            source_only,
        )
        self.assertEqual(state["state"], "unclassified")
        self.assertEqual(
            state["evidence"],
            [
                "approved_manifest_current_projection_mismatch:"
                "h1674_approved_content_slice.json"
            ],
        )

    def test_duplicate_approved_projection_is_deterministic_or_fails_closed(
        self,
    ) -> None:
        first = self._write_approved_manifest(
            self.root,
            "z_approved_content_slice.json",
            "H1674_0000",
            "걱정",
        )
        second = self._write_approved_manifest(
            self.root,
            "a_approved_content_slice.json",
            "H1674_0000",
            "걱정",
        )
        conflicting = self._write_approved_manifest(
            self.root,
            "m_approved_content_slice.json",
            "H1674_0000",
            "근심",
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        projection = [
            {
                "word_id": "H1674_0000",
                "meanings": [{"seq": 1, "meaning": "걱정"}],
            }
        ]

        state = evidence.completion_gate_state(
            "H1674", projection, [first, second], source_only
        )
        self.assertEqual(state["state"], "explicit_approved")
        self.assertEqual(state["evidence"], [second.name, first.name])
        with self.assertRaisesRegex(
            evidence.ManifestError, "approved projection이 manifest 간 상충"
        ):
            evidence.completion_gate_state(
                "H1674", projection, [second, conflicting], source_only
            )

    def test_completion_gate_uses_explicit_strong_supersession(self) -> None:
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        for strong, old_meaning, active_meaning, old_batch_id in (
            (
                "H5229",
                "올곧음",
                "올바름",
                "RESHET-EC-SECOND-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE",
            ),
            (
                "H6772",
                "갈증",
                "목마름",
                "RESHET-EC-P2-APPROVED-CONTENT-SLICE",
            ),
        ):
            with self.subTest(strong=strong):
                active_batch_id = (
                    f"RESHET-TEST-{strong}-ACTIVE-APPROVED-CONTENT-SLICE"
                )
                old = self._write_approved_manifest(
                    self.root,
                    f"{strong.lower()}_old_approved_content_slice.json",
                    f"{strong}_0000",
                    old_meaning,
                    batch_id=old_batch_id,
                )
                active = self._write_approved_manifest(
                    self.root,
                    f"{strong.lower()}_active_approved_content_slice.json",
                    f"{strong}_0000",
                    active_meaning,
                    format_version=3,
                    batch_id=active_batch_id,
                    supersedes=[
                        {"strong_number": strong, "batch_id": old_batch_id}
                    ],
                )

                active_state = evidence.completion_gate_state(
                    strong,
                    [
                        {
                            "word_id": f"{strong}_0000",
                            "meanings": [{"seq": 1, "meaning": active_meaning}],
                        }
                    ],
                    [old, active],
                    source_only,
                )
                self.assertEqual(active_state["state"], "explicit_approved")
                self.assertEqual(active_state["evidence"], [active.name])
                self.assertEqual(
                    active_state["active_approval_evidence"], [active.name]
                )
                self.assertEqual(
                    active_state["superseded_approval_evidence"], [old.name]
                )

                old_state = evidence.completion_gate_state(
                    strong,
                    [
                        {
                            "word_id": f"{strong}_0000",
                            "meanings": [{"seq": 1, "meaning": old_meaning}],
                        }
                    ],
                    [old, active],
                    source_only,
                )
                self.assertNotEqual(old_state["state"], "explicit_approved")
                self.assertEqual(
                    old_state["evidence"],
                    [
                        "approved_manifest_current_projection_mismatch:"
                        f"{active.name}"
                    ],
                )
                self.assertEqual(
                    old_state["active_approval_evidence"], [active.name]
                )
                self.assertEqual(
                    old_state["superseded_approval_evidence"], [old.name]
                )

    def test_supersession_is_scoped_to_one_strong_in_a_batch(self) -> None:
        old_batch_id = "RESHET-TEST-MULTI-OLD-APPROVED-CONTENT-SLICE"
        old = self._write_approved_manifest(
            self.root,
            "multi_old_approved_content_slice.json",
            "H5229_0000",
            "올곧음",
            batch_id=old_batch_id,
        )
        old_payload = json.loads(old.read_text(encoding="utf-8"))
        old_payload["meaning_replacements"].append(
            {
                "word_id": "H6772_0000",
                "before": [{"seq": 1, "meaning": "thirst"}],
                "after": [{"seq": 1, "meaning": "갈증"}],
            }
        )
        old.write_text(
            json.dumps(old_payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        active = self._write_approved_manifest(
            self.root,
            "multi_active_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            format_version=3,
            batch_id="RESHET-TEST-MULTI-ACTIVE-APPROVED-CONTENT-SLICE",
            supersedes=[
                {"strong_number": "H5229", "batch_id": old_batch_id}
            ],
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")

        state = evidence.completion_gate_state(
            "H6772",
            [
                {
                    "word_id": "H6772_0000",
                    "meanings": [{"seq": 1, "meaning": "갈증"}],
                }
            ],
            [old, active],
            source_only,
        )
        self.assertEqual(state["state"], "explicit_approved")
        self.assertEqual(state["evidence"], [old.name])
        self.assertNotIn("superseded_approval_evidence", state)

    def test_supersession_reference_contract_fails_closed(self) -> None:
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        projection = [
            {
                "word_id": "H5229_0000",
                "meanings": [{"seq": 1, "meaning": "올바름"}],
            }
        ]
        missing_reference = self._write_approved_manifest(
            self.root,
            "missing_reference_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            format_version=3,
            batch_id="RESHET-TEST-MISSING-REFERENCE-APPROVED-CONTENT-SLICE",
            supersedes=[
                {
                    "strong_number": "H5229",
                    "batch_id": "RESHET-TEST-NOT-FOUND-APPROVED-CONTENT-SLICE",
                }
            ],
        )
        with self.assertRaisesRegex(evidence.ManifestError, "존재하지 않는 batch"):
            evidence.completion_gate_state(
                "H5229", projection, missing_reference, source_only
            )

        wrong_target_batch_id = (
            "RESHET-TEST-WRONG-TARGET-APPROVED-CONTENT-SLICE"
        )
        wrong_target = self._write_approved_manifest(
            self.root,
            "wrong_target_approved_content_slice.json",
            "H6772_0000",
            "갈증",
            batch_id=wrong_target_batch_id,
        )
        active = self._write_approved_manifest(
            self.root,
            "wrong_target_active_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            format_version=3,
            batch_id="RESHET-TEST-WRONG-TARGET-ACTIVE-APPROVED-CONTENT-SLICE",
            supersedes=[
                {
                    "strong_number": "H5229",
                    "batch_id": wrong_target_batch_id,
                }
            ],
        )
        with self.assertRaisesRegex(
            evidence.ManifestError, "target batch에 해당 Strong 승인이 없음"
        ):
            evidence.completion_gate_state(
                "H5229", projection, [wrong_target, active], source_only
            )

    def test_self_and_cycle_supersession_fail_closed(self) -> None:
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        projection = [
            {
                "word_id": "H5229_0000",
                "meanings": [{"seq": 1, "meaning": "올바름"}],
            }
        ]
        self_batch_id = "RESHET-TEST-SELF-APPROVED-CONTENT-SLICE"
        self_superseding = self._write_approved_manifest(
            self.root,
            "self_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            format_version=3,
            batch_id=self_batch_id,
            supersedes=[
                {"strong_number": "H5229", "batch_id": self_batch_id}
            ],
        )
        with self.assertRaisesRegex(evidence.ManifestError, "self-supersession"):
            evidence.completion_gate_state(
                "H5229", projection, self_superseding, source_only
            )

        first_batch_id = "RESHET-TEST-CYCLE-A-APPROVED-CONTENT-SLICE"
        second_batch_id = "RESHET-TEST-CYCLE-B-APPROVED-CONTENT-SLICE"
        first = self._write_approved_manifest(
            self.root,
            "cycle_a_approved_content_slice.json",
            "H5229_0000",
            "올곧음",
            format_version=3,
            batch_id=first_batch_id,
            supersedes=[
                {"strong_number": "H5229", "batch_id": second_batch_id}
            ],
        )
        second = self._write_approved_manifest(
            self.root,
            "cycle_b_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            format_version=3,
            batch_id=second_batch_id,
            supersedes=[
                {"strong_number": "H5229", "batch_id": first_batch_id}
            ],
        )
        with self.assertRaisesRegex(evidence.ManifestError, "supersession cycle"):
            evidence.completion_gate_state(
                "H5229", projection, [first, second], source_only
            )

    def test_duplicate_approved_batch_id_fails_closed(self) -> None:
        duplicate_batch_id = "RESHET-TEST-DUPLICATE-APPROVED-CONTENT-SLICE"
        first = self._write_approved_manifest(
            self.root,
            "duplicate_a_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            batch_id=duplicate_batch_id,
        )
        second = self._write_approved_manifest(
            self.root,
            "duplicate_b_approved_content_slice.json",
            "H5229_0000",
            "올바름",
            batch_id=duplicate_batch_id,
        )
        source_only = self.root / "source_only.json"
        source_only.write_text('{"entries": []}', encoding="utf-8")
        with self.assertRaisesRegex(evidence.ManifestError, "batch_id 중복"):
            evidence.completion_gate_state(
                "H5229",
                [
                    {
                        "word_id": "H5229_0000",
                        "meanings": [{"seq": 1, "meaning": "올바름"}],
                    }
                ],
                [first, second],
                source_only,
            )

    def test_approved_manifest_discovery_uses_tracked_files_only(self) -> None:
        repository = self.root / "repository"
        manifest_dir = repository / "tool" / "data_provenance" / "manifests"
        first = self._write_approved_manifest(
            manifest_dir,
            "z_approved_content_slice.json",
            "H2020_0000",
            "구원",
        )
        second = self._write_approved_manifest(
            manifest_dir,
            "a_approved_content_slice.json",
            "H1674_0000",
            "걱정",
        )
        third = self._write_approved_manifest(
            manifest_dir,
            "m_note_only_approved_content_slice.json",
            "H1618_0000",
            None,
            format_version=2,
            word_note_replacements=[
                {
                    "word_id": "H1618_0000",
                    "before": None,
                    "after": "승인 비고",
                }
            ],
        )
        (manifest_dir / "strong_sources.json").write_text("{}\n", encoding="utf-8")

        def run_git(*arguments: str) -> None:
            subprocess.run(
                ["git", *arguments],
                cwd=repository,
                check=True,
                capture_output=True,
                text=True,
                encoding="utf-8",
            )

        run_git("init")
        run_git("add", "tool/data_provenance/manifests")
        correction = self._write_approved_manifest(
            manifest_dir,
            "approved_meaning_notation_policy_correction.json",
            "H0001_0000",
            "아버지",
        )
        self._write_approved_manifest(
            manifest_dir,
            "pending_approved_content_slice.json",
            "H1618_0000",
            "미적용 후보",
        )

        discovered = evidence.discover_approved_content_manifests(repository)
        self.assertEqual(
            [path.name for path in discovered],
            [second.name, third.name, first.name],
        )

        run_git("add", str(correction.relative_to(repository)))
        discovered = evidence.discover_approved_content_manifests(repository)
        self.assertEqual(
            [path.name for path in discovered],
            [second.name, correction.name, third.name, first.name],
        )

    def test_semantic_hold_ledger_is_separate_from_completion(self) -> None:
        entries = evidence.load_semantic_research_dispositions()
        self.assertEqual(len(entries), 1)
        self.assertEqual(
            entries[0],
            {
                "strong_number": "H1833",
                "status": "hold",
                "reason": (
                    "현재 확인된 lexical source에는 damask 직물 의미와 Damascus "
                    "지명 의미가 함께 존재하며, Amos 3:12 관련 현재 evidence만으로 "
                    "일반 semantic meaning을 하나로 확정하기 어려워 보류한다."
                ),
                "evidence_refs": [
                    "docs/database/DATA_PROVENANCE.md",
                    "reshet_research_output/second_semantic_batch_20260813_1f8fde72/"
                    "H1833_review.md",
                ],
                "reopen_condition": (
                    "provenance가 검증된 critical lexicon/apparatus 또는 동등한 전문 "
                    "source를 확보해 lexical/textual ambiguity를 해소할 수 있을 때 "
                    "재검토한다."
                ),
            },
        )
        hold_strongs = evidence.semantic_hold_strongs()
        self.assertEqual(hold_strongs, {"H1833"})
        self.assertIsNone(
            evidence.APPROVED_MANIFEST_FILENAME_RE.fullmatch(
                evidence.DEFAULT_SEMANTIC_RESEARCH_DISPOSITIONS.name
            )
        )

        approved_manifests = evidence.discover_approved_content_manifests()
        approved_candidates = set().union(
            *(evidence._approved_strongs(path) for path in approved_manifests)
        )
        states: dict[str, str] = {}
        for strong in approved_candidates | hold_strongs:
            projection, _ = evidence.load_reshet_projection(
                evidence.DEFAULT_WORK_DB, strong
            )
            states[strong] = str(
                evidence.completion_gate_state(
                    strong,
                    projection,
                    approved_manifests,
                    evidence.DEFAULT_SOURCE_ONLY_MANIFEST,
                )["state"]
            )

        explicit_approved = {
            strong for strong, state in states.items() if state == "explicit_approved"
        }
        self.assertEqual(explicit_approved, approved_candidates)
        self.assertEqual(hold_strongs & explicit_approved, set())
        for strong in ("H1653", "H1655", "H1656", "H1564"):
            with self.subTest(strong=strong):
                self.assertEqual(states[strong], "explicit_approved")
        self.assertEqual(states["H1833"], "source_only")
        self.assertEqual(states["H2646"], "explicit_approved")

    def test_semantic_hold_ledger_rejects_invalid_contract(self) -> None:
        valid_entry: dict[str, object] = {
            "strong_number": "H1833",
            "status": "hold",
            "reason": "검증 가능한 보류 사유",
            "evidence_refs": ["docs/database/DATA_PROVENANCE.md"],
            "reopen_condition": "새 전문 근거 확보 시 재검토",
        }
        invalid_payloads: dict[str, object] = {
            "unknown_root": {
                "schema_version": 1,
                "entries": [valid_entry],
                "unknown": True,
            },
            "wrong_schema_version": {"schema_version": 2, "entries": [valid_entry]},
            "entries_not_array": {"schema_version": 1, "entries": {}},
            "unknown_entry_field": {
                "schema_version": 1,
                "entries": [{**valid_entry, "unknown": True}],
            },
            "missing_reopen_condition": {
                "schema_version": 1,
                "entries": [
                    {
                        key: value
                        for key, value in valid_entry.items()
                        if key != "reopen_condition"
                    }
                ],
            },
            "invalid_strong": {
                "schema_version": 1,
                "entries": [{**valid_entry, "strong_number": "H1833 "}],
            },
            "unsupported_status": {
                "schema_version": 1,
                "entries": [{**valid_entry, "status": "approved"}],
            },
            "blank_reason": {
                "schema_version": 1,
                "entries": [{**valid_entry, "reason": " "}],
            },
            "padded_reason": {
                "schema_version": 1,
                "entries": [{**valid_entry, "reason": " 보류 "}],
            },
            "empty_evidence_refs": {
                "schema_version": 1,
                "entries": [{**valid_entry, "evidence_refs": []}],
            },
            "blank_evidence_ref": {
                "schema_version": 1,
                "entries": [{**valid_entry, "evidence_refs": [""]}],
            },
            "duplicate_evidence_ref": {
                "schema_version": 1,
                "entries": [
                    {
                        **valid_entry,
                        "evidence_refs": [
                            "docs/database/DATA_PROVENANCE.md",
                            "docs/database/DATA_PROVENANCE.md",
                        ],
                    }
                ],
            },
            "padded_reopen_condition": {
                "schema_version": 1,
                "entries": [{**valid_entry, "reopen_condition": " 재검토 "}],
            },
            "duplicate_strong": {
                "schema_version": 1,
                "entries": [valid_entry, dict(valid_entry)],
            },
        }

        for name, payload in invalid_payloads.items():
            with self.subTest(name=name):
                path = self.root / f"{name}.json"
                path.write_text(
                    json.dumps(payload, ensure_ascii=False) + "\n", encoding="utf-8"
                )
                with self.assertRaises(evidence.ManifestError):
                    evidence.load_semantic_research_dispositions(path)

    def test_reshet_projection_preserves_nullable_word_note_read_only(self) -> None:
        path = self.root / "work.db"
        connection = sqlite3.connect(path)
        try:
            connection.executescript(
                '''
                CREATE TABLE WORD_TABLE (
                  id TEXT PRIMARY KEY,
                  "스트롱넘버" TEXT NOT NULL,
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
                VALUES ('H0001_0000', 'H0001', '히브리어', NULL),
                       ('H0002_0000', 'H0002', '히브리어', '검증 가능한 비고');
                '''
            )
            connection.commit()
        finally:
            connection.close()

        before = self._sha(path)
        null_projection, null_provenance = evidence.load_reshet_projection(
            path, "H0001"
        )
        note_projection, note_provenance = evidence.load_reshet_projection(
            path, "H0002"
        )

        self.assertIsNone(null_projection[0]["word_note"])
        self.assertEqual(note_projection[0]["word_note"], "검증 가능한 비고")
        self.assertEqual(self._sha(path), before)
        self.assertTrue(null_provenance["unchanged"])
        self.assertTrue(note_provenance["query_only"])

    def test_deterministic_json_bytes(self) -> None:
        first = evidence.serialize_packet({"b": 2, "a": ["한글", 1]})
        second = evidence.serialize_packet({"a": ["한글", 1], "b": 2})
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))
        self.assertEqual(first.decode("utf-8"), second.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
