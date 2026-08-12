#!/usr/bin/env python3

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import tempfile
import unittest

import biblical_research_evidence_review as review


def _reference(
    *,
    status: str = "matched",
    full_verse: str = "표본 절",
    tokens: list[str] | None = None,
    entries: list[dict[str, str | None]] | None = None,
) -> dict[str, object]:
    records: list[dict[str, object]] = []
    if status != "unmatched":
        record: dict[str, object] = {
            "source_row_id": 1,
            "source_verse_key": "Matthew.1.20",
            "full_verse": full_verse,
            "matched_translation_tokens": tokens or [],
        }
        if entries is not None:
            record["matched_source_entries"] = entries
        records.append(record)
    return {
        "status": status,
        "requested_canonical_verse_key": "Matthew.1.20",
        "records": records,
    }


def _occurrence(
    verse: str,
    surface: str,
    morphology: str,
    *,
    legacy_status: str = "matched",
) -> dict[str, object]:
    return {
        "canonical_verse_key": verse,
        "surface": surface,
        "lemma": "ἄγγελος",
        "lexical_tag_raw": "G32",
        "normalized_standard_strong": "G0032",
        "morphology": morphology,
        "source_reference_raw": verse.replace("Matthew", "Mat"),
        "warnings": [],
        "local_references": {
            "korean_revised": _reference(tokens=["사자가", "사자에게"]),
            "korean_revised_legacy": _reference(
                status=legacy_status, tokens=["사자가"]
            ),
            "kjv": _reference(full_verse="KJV sample verse", tokens=["messenger"]),
            "original_language_analysis": _reference(
                full_verse="원전분해 표본 절",
                tokens=["사자가"],
                entries=[
                    {
                        "surface": surface,
                        "lemma": "ἄγγελος",
                        "morphology": "명사 주격 남성 단수",
                        "translation": "사자가",
                        "transliteration": "앙겔로스",
                    }
                ],
            ),
            "korean_new_translation": _reference(
                full_verse="새번역 표본 절", tokens=["자동추측어"]
            ),
        },
    }


def _packet() -> dict[str, object]:
    long_gloss = "source definition " * 8
    return {
        "schema_version": 1,
        "tool": {
            "name": "Reshet Biblical Research Evidence Packet Generator",
            "version": "1.0.0",
            "output": "deterministic_utf8_pretty_json",
        },
        "target": {
            "requested_strong": "G32",
            "normalized_strong": "G0032",
            "language": "Greek",
            "canonical_headword": "ἄγγελος",
            "transliteration": "ángelos",
            "existing_reshet_projection": [
                {
                    "word_id": "G0032_0000",
                    "strong_number": "G0032",
                    "language": "헬라어",
                    "expressions": [
                        {
                            "seq": 1,
                            "spelling": "ἄγγελος",
                            "transliteration": "ángelos",
                        }
                    ],
                    "meanings": [
                        {"seq": 1, "meaning": "사자(使者)"},
                        {"seq": 2, "meaning": "심부름꾼"},
                    ],
                }
            ],
            "completion_gate": {
                "state": "legacy_hanja_candidate",
                "interpretation": "강한 과거 작업 marker이며 최종 승인이 아님",
                "evidence": {},
                "application_approval_ledger": "not_applicable_mvp1",
            },
        },
        "direct_references": [
            {
                "normalized_strong": "G0071",
                "raw_reference": "71",
                "warning": None,
            }
        ],
        "strong_window": {
            "start": "G0022",
            "end": "G0042",
            "interpretation": "번호 인접성은 relation이 아님",
            "items": [
                {
                    "strong": "G0031",
                    "present": True,
                    "headword": "ἀγγελία",
                    "source_meanings": [{"text": long_gloss}],
                    "direct_reference_from_target": True,
                },
                {
                    "strong": "G0032",
                    "present": True,
                    "headword": "ἄγγελος",
                    "source_meanings": [{"text": "a messenger"}],
                    "direct_reference_from_target": False,
                },
                {
                    "strong": "G0033",
                    "present": False,
                    "headword": None,
                    "source_meanings": [],
                    "direct_reference_from_target": False,
                },
            ],
        },
        "summary": {
            "canonical_occurrence_count": 2,
            "canonical_verse_count": 2,
            "translation_expressions": {
                "korean_revised": [
                    {"value": "사자가", "count": 2},
                    {"value": "사자의", "count": 1},
                ],
                "korean_revised_legacy": [{"value": "사자가", "count": 1}],
                "kjv": [{"value": "messenger", "count": 2}],
                "original_language_analysis": [{"value": "사자가", "count": 2}],
                "korean_new_translation": [{"value": "자동추측어", "count": 99}],
            },
        },
        "canonical_occurrences": [
            _occurrence("Matthew.1.20", "ἄγγελος", "N-NSM"),
            _occurrence(
                "Matthew.4.11", "ἄγγελοι", "N-NPM", legacy_status="unmatched"
            ),
        ],
        "provenance": {
            "strong_sources": [{"hash_verified": True}],
            "occurrence_sources": [
                {"files": [{"hash_verified": True}, {"hash_verified": True}]}
            ],
            "local_reference_sources": [
                {"hash_verified": True} for _ in range(6)
            ],
            "work_database": {
                "unchanged": True,
                "sha256_before": "a" * 64,
                "sha256_after": "a" * 64,
            },
        },
    }


class BiblicalResearchEvidenceReviewTest(unittest.TestCase):
    def test_normal_packet_renders_sections_without_mutation(self) -> None:
        packet = _packet()
        before = deepcopy(packet)
        output = review.render_review(packet)
        self.assertIn("## Strong ±10", output)
        self.assertIn("## 번역 표현 빈도", output)
        self.assertIn("## Occurrence 비교표", output)
        self.assertIn("## Occurrence 상세", output)
        self.assertIn("## Provenance", output)
        self.assertEqual(packet, before)

    def test_missing_required_structure_fails_closed(self) -> None:
        packet = _packet()
        del packet["summary"]
        with self.assertRaisesRegex(review.EvidenceReviewError, "summary 필드"):
            review.render_review(packet)

    def test_unsupported_schema_fails_closed(self) -> None:
        packet = _packet()
        packet["schema_version"] = 2
        with self.assertRaisesRegex(review.EvidenceReviewError, "지원하지 않는"):
            review.render_review(packet)

    def test_target_summary_keeps_completion_state_and_direct_reference(self) -> None:
        output = review.render_review(_packet())
        self.assertIn("# G0032 ἄγγελος", output)
        self.assertIn("- 음역: ángelos", output)
        self.assertIn("- 성경 출현: 2회 / 2절", output)
        self.assertIn("사자(使者) / 심부름꾼", output)
        self.assertIn("완료 상태: `legacy_hanja_candidate`", output)
        self.assertIn("직접 참조: G0071", output)

    def test_strong_window_table_marks_direct_and_shortens_gloss(self) -> None:
        output = review.render_review(_packet())
        row = next(line for line in output.splitlines() if line.startswith("| G0031 |"))
        self.assertIn("| ἀγγελία |", row)
        self.assertTrue(row.endswith("| ✓ |"))
        self.assertIn("…", row)

    def test_translation_frequency_preserves_raw_forms_and_order(self) -> None:
        output = review.render_review(_packet())
        first = output.index("| 사자가 | 2 |")
        second = output.index("| 사자의 | 1 |")
        self.assertLess(first, second)
        self.assertIn("| messenger | 2 |", output)

    def test_occurrence_table_preserves_multiple_tokens_and_unmatched(self) -> None:
        output = review.render_review(_packet())
        first_row = next(
            line for line in output.splitlines() if line.startswith("| Matthew.1.20 |")
        )
        second_row = next(
            line for line in output.splitlines() if line.startswith("| Matthew.4.11 |")
        )
        self.assertIn("사자가 / 사자에게", first_row)
        self.assertIn("| unmatched |", second_row)
        self.assertIn("| messenger | 사자가 |", first_row)

    def test_new_translation_target_expression_is_never_rendered(self) -> None:
        output = review.render_review(_packet())
        self.assertNotIn("자동추측어", output)
        self.assertIn("자동 target 표현 집계 N/A — verse-level reference only", output)
        self.assertIn("target 표현: N/A — verse-level reference only", output)

    def test_details_include_full_verse_and_structured_source_entry(self) -> None:
        output = review.render_review(_packet())
        self.assertIn("<details>", output)
        self.assertIn("<summary>Matthew.1.20 — ἄγγελος / N-NSM</summary>", output)
        self.assertIn(
            "<li>canonical verse: <code>Matthew.1.20</code></li>", output
        )
        for label in ("개역개정", "개역한글", "KJV", "원전분해", "새번역"):
            self.assertIn(f"<h4>{label}</h4>", output)
        self.assertIn("새번역 표본 절", output)
        self.assertIn("matched source entry 1", output)
        self.assertIn("번역=사자가", output)

    def test_details_escape_html_without_damaging_multilingual_text(self) -> None:
        packet = _packet()
        occurrence = packet["canonical_occurrences"][0]
        original_reference = occurrence["local_references"][
            "original_language_analysis"
        ]
        original_reference["records"][0]["full_verse"] = (
            "דְּאָגָה <WH1674> & 원전분해 표본 절"
        )

        output = review.render_review(packet)

        self.assertIn("ἄγγελος", output)
        self.assertIn(
            "דְּאָגָה &lt;WH1674&gt; &amp; 원전분해 표본 절", output
        )
        self.assertNotIn("<WH1674>", output)

    def test_provenance_is_compact_verification_summary(self) -> None:
        output = review.render_review(_packet())
        self.assertIn("Evidence Packet schema: `1`", output)
        self.assertIn("Strong source verified: yes", output)
        self.assertIn("Occurrence source verified: yes", output)
        self.assertIn("Local reference source hashes verified: yes", output)
        self.assertIn("Work DB unchanged: yes", output)

    def test_markdown_bytes_are_deterministic(self) -> None:
        packet = _packet()
        first = review.serialize_review(packet)
        second = review.serialize_review(packet)
        self.assertEqual(first, second)
        self.assertTrue(first.endswith(b"\n"))

    def test_output_file_is_bomless_utf8_and_matches_serialization(self) -> None:
        packet = _packet()
        expected = review.serialize_review(packet)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            input_path = root / "packet.json"
            output_path = root / "review.md"
            input_path.write_text("{}", encoding="utf-8")
            review.write_review_file(input_path, output_path, expected)
            first = output_path.read_bytes()
            review.write_review_file(input_path, output_path, expected)
            second = output_path.read_bytes()

        self.assertEqual(first, expected)
        self.assertEqual(second, expected)
        self.assertFalse(first.startswith(b"\xef\xbb\xbf"))
        decoded = first.decode("utf-8")
        self.assertIn("번역 표현 빈도", decoded)
        self.assertIn("ἄγγελος", decoded)

    def test_input_file_cannot_be_output_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "packet.json"
            path.write_bytes(b"original")
            with self.assertRaisesRegex(review.EvidenceReviewError, "달라야 함"):
                review.write_review_file(path, path, b"replacement")
            self.assertEqual(path.read_bytes(), b"original")


if __name__ == "__main__":
    unittest.main()
