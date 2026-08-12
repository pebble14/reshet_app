#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest

import lxx_human_reference_lookup as lxx


H1674_ROWS = [
    (6, 22, 24, "αλλ^ ενεκεν ευλαβειας ρηματος"),
    (24, 30, 29, "τη δαμασκω κατησχυνθη ημαθ και αρφαδ"),
    (26, 12, 18, "υιε ανθρωπου τον αρτον σου μετ^ οδυνης φαγεσαι"),
    (26, 12, 19, "και ερεις προς τον λαον της γης"),
]


class LxxHumanReferenceLookupTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.source_dir = self.root / "private source location"
        self.source_dir.mkdir()
        self.source_path = self.source_dir / lxx.SOURCE_FILENAME
        self._create_database(self.source_path, H1674_ROWS)
        self.manifest = self._write_manifest(
            self.root / "manifest.json", self.source_path
        )
        self.initial_sha256 = self._sha256(self.source_path)

    def tearDown(self) -> None:
        if self.source_path.exists():
            self.assertEqual(self._sha256(self.source_path), self.initial_sha256)
            self._assert_no_sidecars(self.source_path)
        self.temporary.cleanup()

    @staticmethod
    def _sha256(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def _create_database(
        path: Path,
        rows: list[tuple[int, int, int, str | None]],
        *,
        wrong_schema: bool = False,
    ) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(path)
        try:
            text_column = "wrong VARCHAR" if wrong_schema else "btext VARCHAR"
            connection.execute(
                "CREATE TABLE Bible ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "book INTEGER, chapter INTEGER, verse INTEGER, "
                f"{text_column})"
            )
            if not wrong_schema:
                connection.executemany(
                    "INSERT INTO Bible(book,chapter,verse,btext) VALUES (?,?,?,?)",
                    rows,
                )
            connection.commit()
        finally:
            connection.close()

    def _write_manifest(
        self,
        manifest_path: Path,
        source_path: Path,
        *,
        expected_sha256: str | None = None,
        expected_size_bytes: int | None = None,
    ) -> Path:
        payload = json.loads(lxx.DEFAULT_MANIFEST.read_text(encoding="utf-8"))
        source = payload["source"]
        source["expected_sha256"] = expected_sha256 or self._sha256(source_path)
        source["expected_size_bytes"] = (
            source_path.stat().st_size
            if expected_size_bytes is None
            else expected_size_bytes
        )
        manifest_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return manifest_path

    @staticmethod
    def _assert_no_sidecars(path: Path) -> None:
        for suffix in ("-journal", "-wal", "-shm"):
            if (path.parent / f"{path.name}{suffix}").exists():
                raise AssertionError(f"예상하지 않은 SQLite sidecar: {suffix}")

    def _lookup(
        self,
        reference: str,
        *,
        source_dir: Path | None = None,
        manifest: Path | None = None,
    ) -> dict[str, object]:
        return lxx.lookup_reference(
            reference,
            source_dir=source_dir or self.source_dir,
            manifest_path=manifest or self.manifest,
        )

    def test_h1674_explicit_verse_lookups(self) -> None:
        expected = {
            "Joshua 22:24": H1674_ROWS[0][3],
            "Jeremiah 30:29": H1674_ROWS[1][3],
            "Ezekiel 12:18": H1674_ROWS[2][3],
            "Ezekiel 12:19": H1674_ROWS[3][3],
        }
        for reference, greek_text in expected.items():
            with self.subTest(reference=reference):
                result = self._lookup(reference)
                self.assertEqual(result["lookup_status"], "matched")
                self.assertEqual(result["raw_greek_verse_text"], greek_text)
                self.assertEqual(lxx.exit_code_for_result(result), 0)

    def test_unmatched_never_maps_jeremiah_49_23_to_30_29(self) -> None:
        unmatched = self._lookup("Jeremiah 49:23")
        explicit_match = self._lookup("Jeremiah 30:29")

        self.assertEqual(unmatched["lookup_status"], "unmatched")
        self.assertIsNone(unmatched["source_row_identity"])
        self.assertIsNone(unmatched["raw_greek_verse_text"])
        self.assertFalse(unmatched["lookup_policy"]["automatic_mapping"])
        self.assertFalse(unmatched["lookup_policy"]["text_search_fallback"])
        self.assertEqual(explicit_match["lookup_status"], "matched")
        self.assertIn("δαμασκω", explicit_match["raw_greek_verse_text"])

    def test_source_identity_mismatch_fails_closed(self) -> None:
        cases = {
            "source_hash_mismatch": {
                "expected_sha256": "0" * 64,
                "expected_size_bytes": None,
            },
            "source_size_mismatch": {
                "expected_sha256": None,
                "expected_size_bytes": self.source_path.stat().st_size + 1,
            },
        }
        for expected_code, overrides in cases.items():
            with self.subTest(expected_code=expected_code):
                manifest = self._write_manifest(
                    self.root / f"{expected_code}.json",
                    self.source_path,
                    **overrides,
                )
                with self.assertRaises(lxx.LookupError) as caught:
                    self._lookup("Joshua 22:24", manifest=manifest)
                self.assertEqual(caught.exception.code, expected_code)

    def test_missing_source_file_fails_closed(self) -> None:
        missing_dir = self.root / "missing source"
        missing_dir.mkdir()
        with self.assertRaises(lxx.LookupError) as caught:
            self._lookup("Joshua 22:24", source_dir=missing_dir)
        self.assertEqual(caught.exception.code, "source_file_missing")

    def test_schema_mismatch_fails_closed(self) -> None:
        wrong_dir = self.root / "wrong schema"
        wrong_source = wrong_dir / lxx.SOURCE_FILENAME
        self._create_database(wrong_source, [], wrong_schema=True)
        manifest = self._write_manifest(
            self.root / "wrong_schema.json", wrong_source
        )
        with self.assertRaises(lxx.LookupError) as caught:
            self._lookup(
                "Joshua 22:24", source_dir=wrong_dir, manifest=manifest
            )
        self.assertEqual(caught.exception.code, "source_schema_mismatch")

    def test_duplicate_reference_is_explicit_failure(self) -> None:
        duplicate_dir = self.root / "duplicate"
        duplicate_source = duplicate_dir / lxx.SOURCE_FILENAME
        self._create_database(
            duplicate_source,
            [H1674_ROWS[0], H1674_ROWS[0]],
        )
        manifest = self._write_manifest(
            self.root / "duplicate.json", duplicate_source
        )
        result = self._lookup(
            "Joshua 22:24", source_dir=duplicate_dir, manifest=manifest
        )

        self.assertEqual(result["lookup_status"], "duplicate_reference")
        self.assertIsNone(result["source_row_identity"])
        self.assertIsNone(result["raw_greek_verse_text"])
        self.assertEqual(lxx.exit_code_for_result(result), 2)

    def test_empty_text_is_explicit_malformed_result(self) -> None:
        malformed_dir = self.root / "malformed"
        malformed_source = malformed_dir / lxx.SOURCE_FILENAME
        self._create_database(malformed_source, [(6, 22, 24, "   ")])
        manifest = self._write_manifest(
            self.root / "malformed.json", malformed_source
        )
        result = self._lookup(
            "Joshua 22:24", source_dir=malformed_dir, manifest=manifest
        )

        self.assertEqual(result["lookup_status"], "malformed_source_row")
        self.assertIsNone(result["raw_greek_verse_text"])
        self.assertEqual(lxx.exit_code_for_result(result), 2)

    def test_deterministic_cli_json_marks_human_reference_without_path(self) -> None:
        command = [
            sys.executable,
            str(Path(lxx.__file__).resolve()),
            "Joshua 22:24",
            "--local-sources",
            str(self.source_dir.resolve()),
            "--manifest",
            str(self.manifest.resolve()),
        ]
        first = subprocess.run(command, capture_output=True, check=False)
        second = subprocess.run(command, capture_output=True, check=False)

        self.assertEqual(first.returncode, 0, first.stderr.decode("utf-8"))
        self.assertEqual(first.stdout, second.stdout)
        self.assertEqual(first.stderr, b"")
        payload = json.loads(first.stdout.decode("utf-8"))
        self.assertEqual(first.stdout, lxx.serialize_result(payload))
        self.assertEqual(payload["source"]["role"], "human_reference")
        self.assertEqual(payload["source"]["provenance_status"], "unverified")
        self.assertFalse(payload["source"]["canonical_evidence"])
        self.assertTrue(payload["source"]["manual_review_required"])
        self.assertEqual(payload["boundary_markers"], list(lxx.BOUNDARY_MARKERS))
        self.assertNotIn(str(self.source_dir.resolve()), first.stdout.decode("utf-8"))

    def test_cli_source_failure_is_json_stderr_without_path(self) -> None:
        missing_dir = self.root / "missing cli source"
        missing_dir.mkdir()
        command = [
            sys.executable,
            str(Path(lxx.__file__).resolve()),
            "Joshua 22:24",
            "--local-sources",
            str(missing_dir.resolve()),
            "--manifest",
            str(self.manifest.resolve()),
        ]
        completed = subprocess.run(command, capture_output=True, check=False)

        self.assertEqual(completed.returncode, 2)
        self.assertEqual(completed.stdout, b"")
        payload = json.loads(completed.stderr.decode("utf-8"))
        self.assertEqual(payload["lookup_status"], "source_validation_failed")
        self.assertEqual(payload["error"]["code"], "source_file_missing")
        self.assertNotIn(str(missing_dir.resolve()), completed.stderr.decode("utf-8"))

    def test_read_only_connection_rejects_write_and_preserves_source(self) -> None:
        before = self._sha256(self.source_path)
        connection = lxx._open_sqlite_read_only(self.source_path)
        try:
            with self.assertRaises(sqlite3.OperationalError):
                connection.execute(
                    "INSERT INTO Bible(book,chapter,verse,btext) VALUES (6,22,25,'x')"
                )
        finally:
            connection.close()

        self.assertEqual(self._sha256(self.source_path), before)
        self._assert_no_sidecars(self.source_path)

    def test_tracked_manifest_has_no_absolute_path_and_keeps_boundary(self) -> None:
        manifest_text = lxx.DEFAULT_MANIFEST.read_text(encoding="utf-8")
        spec = lxx.load_manifest()

        self.assertEqual(spec.filename, "LXXStp.bdb")
        self.assertEqual(spec.source_id, lxx.SOURCE_ID)
        self.assertNotIn("reshet_research_sources", manifest_text)
        self.assertNotIn("C:\\", manifest_text)
        self.assertNotIn("/Users/", manifest_text)


if __name__ == "__main__":
    unittest.main()
