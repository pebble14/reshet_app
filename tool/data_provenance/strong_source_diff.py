#!/usr/bin/env python3
"""Open Scriptures XML과 Reshet DB를 읽기 전용으로 비교한다."""

from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import sys
import unicodedata
import xml.etree.ElementTree as ET


TOOL_VERSION = "1.0.0"
STRONG_LIMITS = {"G": 5624, "H": 8674}
EXPRESSION_FIELDS = [
    "word_id",
    "strong_number",
    "language",
    "seq",
    "is_representative",
    "db_spelling",
    "db_spelling_nfc",
    "db_transliteration",
    "db_pronunciation",
    "db_pronunciation_type",
    "source_spelling_candidates",
    "source_transliteration_candidates",
    "source_pronunciation_candidates",
    "source_candidate_count",
    "spelling_raw_equal",
    "spelling_nfc_equal",
    "pronunciation_raw_equal",
    "pronunciation_trimmed_equal",
    "comparison_status",
    "secondary_classification",
    "note",
]
WORD_FIELDS = [
    "word_id",
    "strong_number",
    "language",
    "representative_seq",
    "representative_spelling",
    "representative_pronunciation",
    "source_candidate_count",
    "comparison_status",
    "note",
]


class SourceSchemaError(RuntimeError):
    """입력 XML이 승인된 Open Scriptures 구조와 맞지 않을 때 발생한다."""


@dataclass(frozen=True)
class SourceCandidate:
    spelling: str = ""
    transliteration: str = ""
    pronunciation: str = ""


@dataclass
class SourceDataset:
    prefix: str
    path: Path
    root_tag: str
    entry_tag: str
    entry_count: int
    invalid_entry_count: int
    candidates: dict[str, list[SourceCandidate]] = field(default_factory=dict)

    @property
    def candidate_count(self) -> int:
        return sum(len(items) for items in self.candidates.values())


@dataclass(frozen=True)
class DbExpression:
    word_id: str
    strong_number: str
    language: str
    seq: int
    is_representative: int
    spelling: str
    transliteration: str
    pronunciation: str


@dataclass
class WordRecord:
    word_id: str
    strong_number: str
    language: str
    expressions: list[DbExpression] = field(default_factory=list)


def normalize_strong_number(
    value: object, expected_prefix: str | None = None
) -> str | None:
    """Strong 번호를 G/H + 4자리 형식으로 바꾸고 범위를 검증한다."""

    if value is None:
        return None
    raw = str(value).strip()
    if expected_prefix is not None:
        expected_prefix = expected_prefix.upper()
        if expected_prefix not in STRONG_LIMITS:
            raise ValueError(f"지원하지 않는 Strong prefix: {expected_prefix}")
    if expected_prefix and re.fullmatch(r"\d+", raw):
        prefix = expected_prefix
        digits = raw
    else:
        match = re.fullmatch(r"([GHgh])\s*0*(\d+)", raw)
        if not match:
            return None
        prefix = match.group(1).upper()
        digits = match.group(2)
        if expected_prefix and prefix != expected_prefix:
            return None
    number = int(digits)
    if number < 1 or number > STRONG_LIMITS[prefix]:
        return None
    return f"{prefix}{number:04d}"


def classify_pronunciation(value: str | None) -> str:
    text = "" if value is None else value.strip()
    if not text:
        return "empty"
    compact = "".join(character for character in text if not character.isspace())
    if compact.isdigit():
        return "digits_only"

    ipa_markers = set("ˈˌəɛɪʊθðŋʃʒɔæɒɜɚɝʌçɡɾʔχβɣ")
    if any(character in ipa_markers for character in text) or (
        text.startswith(("/", "[")) and text.endswith(("/", "]"))
    ):
        return "ipa_like"

    scripts: set[str] = set()
    has_digit = False
    for character in text:
        if character.isdigit():
            has_digit = True
        if not character.isalpha():
            continue
        name = unicodedata.name(character, "")
        if "HANGUL" in name:
            scripts.add("HANGUL")
        elif "LATIN" in name:
            scripts.add("LATIN")
        elif "GREEK" in name:
            scripts.add("GREEK")
        elif "HEBREW" in name:
            scripts.add("HEBREW")
        else:
            scripts.add("OTHER")

    if scripts == {"HANGUL"} and not has_digit:
        return "hangul"
    if scripts == {"LATIN"} and not has_digit:
        if any(character in "'-‐‑‒–—’ʼʻʹ" for character in text):
            return "strong_style"
        if all(
            character.isalpha()
            or character.isspace()
            or unicodedata.combining(character)
            for character in text
        ):
            return "latin_plain"
    if len(scripts) > 1 or (scripts and has_digit) or scripts == {"LATIN"}:
        return "mixed"
    return "other"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_metadata(path: Path) -> dict[str, object]:
    stat = path.stat()
    return {
        "size_bytes": stat.st_size,
        "mtime_utc": datetime.fromtimestamp(
            stat.st_mtime, timezone.utc
        ).isoformat(),
        "sha256": sha256_file(path),
    }


def display_path(raw_path: str, resolved_path: Path) -> str:
    supplied = Path(raw_path)
    return resolved_path.name if supplied.is_absolute() else supplied.as_posix()


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _schema_error(
    path: Path,
    root_tag: str,
    expected: str,
    extracted_count: int,
) -> SourceSchemaError:
    return SourceSchemaError(
        f"XML schema 불일치: 파일={path}; root tag={root_tag!r}; "
        f"예상 핵심 구조={expected}; 추출 항목 수={extracted_count}"
    )


def parse_greek_xml(path: Path) -> SourceDataset:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as error:
        raise SourceSchemaError(
            f"XML parsing 실패: 파일={path}; root tag=확인 불가; "
            f"예상 핵심 구조=strongsdictionary/entries/entry; 추출 항목 수=0; {error}"
        ) from error
    if local_name(root.tag) != "strongsdictionary":
        raise _schema_error(
            path, root.tag, "strongsdictionary/entries/entry@strongs", 0
        )
    entries_node = next(
        (child for child in root if local_name(child.tag) == "entries"), None
    )
    entries = (
        [child for child in entries_node if local_name(child.tag) == "entry"]
        if entries_node is not None
        else []
    )
    if not entries:
        raise _schema_error(
            path, root.tag, "strongsdictionary/entries/entry@strongs", 0
        )

    candidates: dict[str, list[SourceCandidate]] = defaultdict(list)
    invalid_count = 0
    for entry in entries:
        strong = normalize_strong_number(entry.get("strongs"), "G")
        if strong is None:
            invalid_count += 1
            continue
        entry_candidates: list[SourceCandidate] = []
        for child in entry:
            child_name = local_name(child.tag)
            if child_name in {"strongs_derivation", "strongs_def", "kjv_def"}:
                break
            if child_name == "greek":
                entry_candidates.append(
                    SourceCandidate(
                        spelling=child.get("unicode", ""),
                        transliteration=child.get("translit", ""),
                    )
                )
            elif child_name == "pronunciation":
                pronunciation = child.get("strongs", "")
                if entry_candidates and not entry_candidates[-1].pronunciation:
                    previous = entry_candidates[-1]
                    entry_candidates[-1] = SourceCandidate(
                        previous.spelling,
                        previous.transliteration,
                        pronunciation,
                    )
                else:
                    entry_candidates.append(
                        SourceCandidate(pronunciation=pronunciation)
                    )
        if not entry_candidates:
            entry_candidates.append(SourceCandidate())
        candidates[strong].extend(entry_candidates)

    extracted = sum(len(items) for items in candidates.values())
    if extracted == 0:
        raise _schema_error(
            path,
            root.tag,
            "entry@strongs + 머리부 greek@unicode/translit + pronunciation@strongs",
            0,
        )
    return SourceDataset(
        prefix="G",
        path=path,
        root_tag=root.tag,
        entry_tag="entry",
        entry_count=len(entries),
        invalid_entry_count=invalid_count,
        candidates=dict(candidates),
    )


def parse_hebrew_xml(path: Path) -> SourceDataset:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as error:
        raise SourceSchemaError(
            f"XML parsing 실패: 파일={path}; root tag=확인 불가; "
            f"예상 핵심 구조=lexicon/entry; 추출 항목 수=0; {error}"
        ) from error
    if local_name(root.tag) != "lexicon":
        raise _schema_error(path, root.tag, "lexicon/entry@id/w", 0)
    entries = [child for child in root if local_name(child.tag) == "entry"]
    if not entries:
        raise _schema_error(path, root.tag, "lexicon/entry@id/w", 0)

    candidates: dict[str, list[SourceCandidate]] = defaultdict(list)
    invalid_count = 0
    for entry in entries:
        strong = normalize_strong_number(entry.get("id"), "H")
        if strong is None:
            invalid_count += 1
            continue
        words = [child for child in entry if local_name(child.tag) == "w"]
        if not words:
            candidates[strong].append(SourceCandidate())
            continue
        for word in words:
            candidates[strong].append(
                SourceCandidate(
                    spelling=(word.text or "").strip(),
                    transliteration=word.get("xlit", ""),
                    pronunciation=word.get("pron", ""),
                )
            )

    extracted = sum(len(items) for items in candidates.values())
    if extracted == 0:
        raise _schema_error(
            path, root.tag, "entry@id + 직접 자식 w 본문/@xlit/@pron", 0
        )
    return SourceDataset(
        prefix="H",
        path=path,
        root_tag=root.tag,
        entry_tag="entry",
        entry_count=len(entries),
        invalid_entry_count=invalid_count,
        candidates=dict(candidates),
    )


def open_read_only_database(
    path: Path,
) -> tuple[sqlite3.Connection, int, str]:
    connection = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA query_only = ON")
    query_only = int(connection.execute("PRAGMA query_only").fetchone()[0])
    integrity_check = str(
        connection.execute("PRAGMA integrity_check").fetchone()[0]
    )
    if query_only != 1:
        connection.close()
        raise RuntimeError(f"SQLite query_only 보장 실패: {query_only}")
    if integrity_check != "ok":
        connection.close()
        raise RuntimeError(f"SQLite integrity_check 실패: {integrity_check}")
    return connection, query_only, integrity_check


def load_database(
    path: Path,
) -> tuple[list[WordRecord], int, str]:
    connection, query_only, integrity_check = open_read_only_database(path)
    try:
        rows = connection.execute(
            '''
            SELECT
              w.id AS word_id,
              w."스트롱넘버" AS strong_number,
              w."언어" AS language,
              e.seq AS seq,
              e.is_representative AS is_representative,
              e.spelling AS spelling,
              e.transliteration AS transliteration,
              e.pronunciation AS pronunciation
            FROM WORD_TABLE AS w
            LEFT JOIN word_expression_set AS e ON e.word_id = w.id
            WHERE w."스트롱넘버" IS NOT NULL
              AND TRIM(w."스트롱넘버") <> ''
            ORDER BY w.id, e.seq
            '''
        ).fetchall()
    finally:
        connection.close()

    words: dict[str, WordRecord] = {}
    for row in rows:
        word = words.setdefault(
            row["word_id"],
            WordRecord(
                word_id=row["word_id"],
                strong_number=row["strong_number"] or "",
                language=row["language"] or "",
            ),
        )
        if row["seq"] is None:
            continue
        word.expressions.append(
            DbExpression(
                word_id=row["word_id"],
                strong_number=row["strong_number"] or "",
                language=row["language"] or "",
                seq=int(row["seq"]),
                is_representative=int(row["is_representative"]),
                spelling=row["spelling"] or "",
                transliteration=row["transliteration"] or "",
                pronunciation=row["pronunciation"] or "",
            )
        )
    return list(words.values()), query_only, integrity_check


def _unique_candidates(
    candidates: list[SourceCandidate],
) -> list[SourceCandidate]:
    return list(dict.fromkeys(candidates))


def _spelling_match(db_spelling: str, candidate: SourceCandidate) -> bool:
    return db_spelling == candidate.spelling or unicodedata.normalize(
        "NFC", db_spelling
    ) == unicodedata.normalize("NFC", candidate.spelling)


def _pronunciation_match(
    db_pronunciation: str, candidate: SourceCandidate
) -> bool:
    return db_pronunciation == candidate.pronunciation or (
        db_pronunciation.strip() == candidate.pronunciation.strip()
    )


def select_source_candidate(
    expression: DbExpression,
    candidates: list[SourceCandidate],
) -> tuple[list[SourceCandidate], bool]:
    unique = _unique_candidates(candidates)
    if len(unique) <= 1:
        return unique, False
    full_matches = [
        candidate
        for candidate in unique
        if _spelling_match(expression.spelling, candidate)
        and expression.pronunciation == candidate.pronunciation
    ]
    if len(full_matches) == 1:
        return full_matches, False
    spelling_matches = [
        candidate
        for candidate in unique
        if _spelling_match(expression.spelling, candidate)
    ]
    if len(spelling_matches) == 1:
        return spelling_matches, False
    pronunciation_matches = [
        candidate
        for candidate in unique
        if _pronunciation_match(expression.pronunciation, candidate)
    ]
    if len(pronunciation_matches) == 1:
        return pronunciation_matches, False
    return unique, True


def _candidate_values(
    candidates: list[SourceCandidate], attribute: str
) -> list[str]:
    return list(
        dict.fromkeys(
            value
            for candidate in candidates
            if (value := getattr(candidate, attribute)) != ""
        )
    )


def compare_expression(
    expression: DbExpression,
    source_candidates: dict[str, list[SourceCandidate]],
) -> dict[str, object]:
    canonical = normalize_strong_number(expression.strong_number)
    all_candidates = source_candidates.get(canonical or "", [])
    selected: list[SourceCandidate] = []
    ambiguous = False
    if all_candidates:
        selected, ambiguous = select_source_candidate(expression, all_candidates)

    spelling_raw = False
    spelling_nfc = False
    pronunciation_raw = False
    pronunciation_trimmed = False
    note = ""
    if canonical is None:
        status = "invalid_strong_number"
        note = f"유효하지 않은 DB Strong 번호: {expression.strong_number!r}"
    elif not all_candidates:
        status = "source_missing"
        note = "대응하는 source 항목이 없음"
    elif ambiguous:
        status = "source_ambiguous"
        note = "복수 source 후보 중 안전한 대응을 결정할 수 없음"
    else:
        spelling_raw = any(
            expression.spelling == candidate.spelling for candidate in selected
        )
        spelling_nfc = any(
            unicodedata.normalize("NFC", expression.spelling)
            == unicodedata.normalize("NFC", candidate.spelling)
            for candidate in selected
        )
        pronunciation_raw = any(
            expression.pronunciation == candidate.pronunciation
            for candidate in selected
        )
        pronunciation_trimmed = any(
            expression.pronunciation.strip() == candidate.pronunciation.strip()
            for candidate in selected
        )
        source_has_pronunciation = any(
            candidate.pronunciation != "" for candidate in selected
        )
        if not expression.pronunciation and source_has_pronunciation:
            status = "db_pronunciation_empty"
            note = "DB pronunciation이 비어 있음"
        elif expression.pronunciation and not source_has_pronunciation:
            status = "source_pronunciation_empty"
            note = "source pronunciation이 비어 있음"
        elif spelling_raw and pronunciation_raw:
            status = "exact_match"
        elif not spelling_raw and spelling_nfc and pronunciation_raw:
            status = "normalized_spelling_match"
            note = "spelling은 NFC 기준으로만 일치"
        elif (spelling_raw or spelling_nfc) and not pronunciation_raw:
            status = "spelling_match_pronunciation_diff"
        elif pronunciation_raw and not (spelling_raw or spelling_nfc):
            status = "pronunciation_match_spelling_diff"
        else:
            status = "both_diff"

    return {
        "word_id": expression.word_id,
        "strong_number": canonical or expression.strong_number,
        "language": expression.language,
        "seq": expression.seq,
        "is_representative": expression.is_representative,
        "db_spelling": expression.spelling,
        "db_spelling_nfc": unicodedata.normalize("NFC", expression.spelling),
        "db_transliteration": expression.transliteration,
        "db_pronunciation": expression.pronunciation,
        "db_pronunciation_type": classify_pronunciation(
            expression.pronunciation
        ),
        "source_spelling_candidates": _candidate_values(
            all_candidates, "spelling"
        ),
        "source_transliteration_candidates": _candidate_values(
            all_candidates, "transliteration"
        ),
        "source_pronunciation_candidates": _candidate_values(
            all_candidates, "pronunciation"
        ),
        "source_candidate_count": len(all_candidates),
        "spelling_raw_equal": spelling_raw,
        "spelling_nfc_equal": spelling_nfc,
        "pronunciation_raw_equal": pronunciation_raw,
        "pronunciation_trimmed_equal": pronunciation_trimmed,
        "comparison_status": status,
        "secondary_classification": (
            "representative" if expression.is_representative else ""
        ),
        "note": note,
    }


def classify_secondary_rows(rows: list[dict[str, object]]) -> None:
    by_word: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in rows:
        by_word[str(row["word_id"])].append(row)
    for word_rows in by_word.values():
        representative = next(
            (row for row in word_rows if row["is_representative"] == 1), None
        )
        representative_matches = representative is not None and representative[
            "comparison_status"
        ] in {"exact_match", "normalized_spelling_match"}
        for row in word_rows:
            if row["is_representative"] == 1:
                continue
            status = str(row["comparison_status"])
            if status in {"exact_match", "normalized_spelling_match"}:
                classification = "source_candidate_match"
            elif status == "source_missing" or (
                row["source_candidate_count"] <= 1 and representative_matches
            ):
                classification = "source_variant_not_found"
            else:
                classification = "source_candidate_mismatch"
            row["secondary_classification"] = classification
            if classification == "source_variant_not_found":
                suffix = "source에서 대응 secondary variant를 찾지 못함"
                row["note"] = (
                    f"{row['note']}; {suffix}" if row["note"] else suffix
                )


def build_word_rows(
    words: list[WordRecord],
    expression_rows: list[dict[str, object]],
    source_candidates: dict[str, list[SourceCandidate]],
) -> list[dict[str, object]]:
    rows_by_word: dict[str, list[dict[str, object]]] = defaultdict(list)
    for row in expression_rows:
        rows_by_word[str(row["word_id"])].append(row)
    output: list[dict[str, object]] = []
    for word in words:
        canonical = normalize_strong_number(word.strong_number)
        representatives = [
            row
            for row in rows_by_word.get(word.word_id, [])
            if row["is_representative"] == 1
        ]
        if len(representatives) == 1:
            representative = representatives[0]
            output.append(
                {
                    "word_id": word.word_id,
                    "strong_number": canonical or word.strong_number,
                    "language": word.language,
                    "representative_seq": representative["seq"],
                    "representative_spelling": representative["db_spelling"],
                    "representative_pronunciation": representative[
                        "db_pronunciation"
                    ],
                    "source_candidate_count": representative[
                        "source_candidate_count"
                    ],
                    "comparison_status": representative["comparison_status"],
                    "note": representative["note"],
                }
            )
            continue
        status = (
            "multiple_representatives"
            if len(representatives) > 1
            else "no_representative"
        )
        output.append(
            {
                "word_id": word.word_id,
                "strong_number": canonical or word.strong_number,
                "language": word.language,
                "representative_seq": "",
                "representative_spelling": "",
                "representative_pronunciation": "",
                "source_candidate_count": len(
                    source_candidates.get(canonical or "", [])
                ),
                "comparison_status": status,
                "note": "대표 expression이 없음"
                if not representatives
                else "대표 expression이 여러 개임",
            }
        )
    return output


def _ratio(numerator: int, denominator: int) -> dict[str, object]:
    return {
        "numerator": numerator,
        "denominator": denominator,
        "ratio": numerator / denominator if denominator else None,
    }


def _nested_counts(
    rows: list[dict[str, object]], key: str
) -> dict[str, object]:
    overall = Counter(str(row[key]) for row in rows)
    by_language: dict[str, Counter[str]] = defaultdict(Counter)
    by_role: dict[str, Counter[str]] = defaultdict(Counter)
    by_language_and_role: dict[str, dict[str, Counter[str]]] = defaultdict(
        lambda: defaultdict(Counter)
    )
    for row in rows:
        strong = normalize_strong_number(row["strong_number"])
        language = strong[0] if strong else "invalid"
        role = "representative" if row["is_representative"] == 1 else "secondary"
        value = str(row[key])
        by_language[language][value] += 1
        by_role[role][value] += 1
        by_language_and_role[language][role][value] += 1
    return {
        "overall": dict(sorted(overall.items())),
        "by_language": {
            language: dict(sorted(counts.items()))
            for language, counts in sorted(by_language.items())
        },
        "by_role": {
            role: dict(sorted(counts.items()))
            for role, counts in sorted(by_role.items())
        },
        "by_language_and_role": {
            language: {
                role: dict(sorted(counts.items()))
                for role, counts in sorted(roles.items())
            }
            for language, roles in sorted(by_language_and_role.items())
        },
    }


def build_summary(
    words: list[WordRecord],
    expression_rows: list[dict[str, object]],
    datasets: list[SourceDataset],
    source_candidates: dict[str, list[SourceCandidate]],
) -> dict[str, object]:
    word_counts = Counter()
    covered_counts = Counter()
    invalid_word_count = 0
    for word in words:
        canonical = normalize_strong_number(word.strong_number)
        if canonical is None:
            invalid_word_count += 1
            continue
        prefix = canonical[0]
        word_counts[prefix] += 1
        if canonical in source_candidates:
            covered_counts[prefix] += 1

    coverage_by_language = {
        prefix: _ratio(covered_counts[prefix], word_counts[prefix])
        for prefix in ("G", "H")
    }
    total_words = sum(word_counts.values())
    total_covered = sum(covered_counts.values())
    role_counts = Counter(
        "representative" if row["is_representative"] == 1 else "secondary"
        for row in expression_rows
    )
    return {
        "database": {
            "strong_word_count": len(words),
            "valid_strong_word_count": total_words,
            "invalid_strong_word_count": invalid_word_count,
            "expression_count": len(expression_rows),
            "word_count_by_language": {
                prefix: word_counts[prefix] for prefix in ("G", "H")
            },
        },
        "source": {
            "entry_count": sum(dataset.entry_count for dataset in datasets),
            "candidate_count": sum(
                dataset.candidate_count for dataset in datasets
            ),
            "entry_count_by_language": {
                dataset.prefix: dataset.entry_count for dataset in datasets
            },
            "candidate_count_by_language": {
                dataset.prefix: dataset.candidate_count for dataset in datasets
            },
            "invalid_entry_count": sum(
                dataset.invalid_entry_count for dataset in datasets
            ),
        },
        "coverage": {
            "overall": _ratio(total_covered, total_words),
            "by_language": coverage_by_language,
        },
        "comparison_status_counts": _nested_counts(
            expression_rows, "comparison_status"
        ),
        "role_counts": dict(sorted(role_counts.items())),
        "secondary_classification_counts": _nested_counts(
            [
                row
                for row in expression_rows
                if row["is_representative"] == 0
            ],
            "secondary_classification",
        ),
        "pronunciation_type_counts": _nested_counts(
            expression_rows, "db_pronunciation_type"
        ),
        "matches": {
            "raw_spelling": sum(
                bool(row["spelling_raw_equal"]) for row in expression_rows
            ),
            "nfc_only_spelling": sum(
                not bool(row["spelling_raw_equal"])
                and bool(row["spelling_nfc_equal"])
                for row in expression_rows
            ),
            "pronunciation_raw": sum(
                bool(row["pronunciation_raw_equal"])
                for row in expression_rows
            ),
            "pronunciation_trimmed_only": sum(
                not bool(row["pronunciation_raw_equal"])
                and bool(row["pronunciation_trimmed_equal"])
                for row in expression_rows
            ),
            "db_empty_pronunciation": sum(
                row["db_pronunciation_type"] == "empty"
                for row in expression_rows
            ),
            "source_missing": sum(
                row["comparison_status"] == "source_missing"
                for row in expression_rows
            ),
            "source_ambiguous": sum(
                row["comparison_status"] == "source_ambiguous"
                for row in expression_rows
            ),
        },
    }


def _csv_value(value: object) -> object:
    if isinstance(value, list):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return value


def write_csv(
    path: Path, fieldnames: list[str], rows: list[dict[str, object]]
) -> None:
    with path.open("w", encoding="utf-8", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({key: _csv_value(row.get(key, "")) for key in fieldnames})


def parse_strong_filters(values: list[str] | None) -> list[str]:
    if not values:
        return []
    result: list[str] = []
    for value in values:
        for item in value.split(","):
            canonical = normalize_strong_number(item)
            if canonical is None:
                raise ValueError(f"유효하지 않은 --strong 값: {item!r}")
            if canonical not in result:
                result.append(canonical)
    return result


def run_diff(
    db_raw: str,
    greek_raw: str | None,
    hebrew_raw: str | None,
    output_raw: str,
    strong_filters: list[str] | None = None,
    pretty: bool = False,
) -> dict[str, object]:
    db_path = Path(db_raw).resolve()
    output_dir = Path(output_raw).resolve()
    if not db_path.is_file():
        raise FileNotFoundError(f"DB 파일을 찾을 수 없음: {db_path}")
    if not greek_raw and not hebrew_raw:
        raise ValueError("--greek-xml 또는 --hebrew-xml 중 하나 이상이 필요함")

    db_before = file_metadata(db_path)
    datasets: list[SourceDataset] = []
    source_manifest: list[dict[str, object]] = []
    for prefix, raw_path, parser in (
        ("G", greek_raw, parse_greek_xml),
        ("H", hebrew_raw, parse_hebrew_xml),
    ):
        if raw_path is None:
            continue
        source_path = Path(raw_path).resolve()
        if not source_path.is_file():
            raise FileNotFoundError(f"source XML 파일을 찾을 수 없음: {source_path}")
        dataset = parser(source_path)
        datasets.append(dataset)
        metadata = file_metadata(source_path)
        source_manifest.append(
            {
                "language": prefix,
                "path": display_path(raw_path, source_path),
                **metadata,
                "root_tag": dataset.root_tag,
                "entry_tag": dataset.entry_tag,
                "entry_count": dataset.entry_count,
                "candidate_count": dataset.candidate_count,
                "invalid_entry_count": dataset.invalid_entry_count,
            }
        )

    words, query_only, integrity_check = load_database(db_path)
    db_after = file_metadata(db_path)
    if db_before != db_after:
        raise RuntimeError(
            "DB 파일 무결성 변경 감지: 실행 전후 크기, mtime 또는 SHA-256이 다름"
        )

    filters = strong_filters or []
    if filters:
        filter_set = set(filters)
        words = [
            word
            for word in words
            if normalize_strong_number(word.strong_number) in filter_set
        ]

    source_candidates: dict[str, list[SourceCandidate]] = {}
    for dataset in datasets:
        source_candidates.update(dataset.candidates)
    expression_rows = [
        compare_expression(expression, source_candidates)
        for word in words
        for expression in word.expressions
    ]
    classify_secondary_rows(expression_rows)
    word_rows = build_word_rows(words, expression_rows, source_candidates)
    summary = build_summary(words, expression_rows, datasets, source_candidates)

    manifest = {
        "tool_version": TOOL_VERSION,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "database": {
            "path": display_path(db_raw, db_path),
            "size_bytes": db_before["size_bytes"],
            "mtime_utc_before": db_before["mtime_utc"],
            "mtime_utc_after": db_after["mtime_utc"],
            "sha256_before": db_before["sha256"],
            "sha256_after": db_after["sha256"],
            "unchanged": db_before == db_after,
            "query_only": query_only,
            "integrity_check": integrity_check,
        },
        "sources": source_manifest,
        "cli_options": {
            "db": display_path(db_raw, db_path),
            "greek_xml": (
                display_path(greek_raw, Path(greek_raw).resolve())
                if greek_raw
                else None
            ),
            "hebrew_xml": (
                display_path(hebrew_raw, Path(hebrew_raw).resolve())
                if hebrew_raw
                else None
            ),
            "output_dir": Path(output_raw).name,
            "strong": filters,
            "pretty": pretty,
        },
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output_dir / "summary.json").write_text(
        json.dumps(
            summary,
            ensure_ascii=False,
            indent=2 if pretty else None,
            separators=None if pretty else (",", ":"),
        )
        + "\n",
        encoding="utf-8",
    )
    write_csv(output_dir / "expression_diff.csv", EXPRESSION_FIELDS, expression_rows)
    write_csv(output_dir / "word_summary.csv", WORD_FIELDS, word_rows)
    return {
        "manifest": manifest,
        "summary": summary,
        "expression_rows": expression_rows,
        "word_rows": word_rows,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Open Scriptures Strong XML과 Reshet DB의 read-only dry-run diff"
    )
    parser.add_argument("--db", required=True, help="비교할 SQLite DB 경로")
    parser.add_argument("--greek-xml", help="Open Scriptures Greek XML 경로")
    parser.add_argument("--hebrew-xml", help="Open Scriptures Hebrew XML 경로")
    parser.add_argument("--output-dir", required=True, help="결과 디렉터리")
    parser.add_argument(
        "--strong",
        action="append",
        help="특정 Strong 번호. 반복 또는 쉼표 구분 가능",
    )
    parser.add_argument("--pretty", action="store_true", help="summary JSON 들여쓰기")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if not args.greek_xml and not args.hebrew_xml:
        parser.error("--greek-xml 또는 --hebrew-xml 중 하나 이상이 필요합니다")
    try:
        filters = parse_strong_filters(args.strong)
    except ValueError as error:
        parser.error(str(error))
    try:
        result = run_diff(
            db_raw=args.db,
            greek_raw=args.greek_xml,
            hebrew_raw=args.hebrew_xml,
            output_raw=args.output_dir,
            strong_filters=filters,
            pretty=args.pretty,
        )
    except (OSError, sqlite3.Error, SourceSchemaError, RuntimeError, ValueError) as error:
        print(f"오류: {error}", file=sys.stderr)
        return 1
    summary = result["summary"]
    print(
        "dry-run 완료: "
        f"words={summary['database']['strong_word_count']}, "
        f"expressions={summary['database']['expression_count']}, "
        f"output={Path(args.output_dir).name}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
