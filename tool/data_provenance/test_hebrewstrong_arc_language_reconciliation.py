from __future__ import annotations

import hashlib
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
import unittest

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import hebrewstrong_arc_language_reconciliation as migration


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


@unittest.skipUnless(
    migration.DEFAULT_MANIFEST.is_file()
    and migration.DEFAULT_SOURCE_MANIFEST.is_file()
    and migration.DEFAULT_SOURCE_XML.is_file()
    and migration.DEFAULT_WORK_DB.is_file()
    and migration.DEFAULT_SEED_DB.is_file(),
    "tracked manifest, 고정 source cache와 repository DB가 필요함",
)
class HebrewStrongArcLanguageReconciliationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.work = self.root / "reshet_work.db"
        self.seed = self.root / "reshet_seed.db"
        self.backups = self.root / "backups"
        self.result = self.root / "result.json"
        shutil.copy2(migration.DEFAULT_WORK_DB, self.work)
        shutil.copy2(migration.DEFAULT_SEED_DB, self.seed)
        self.manifest = migration.load_manifest(migration.DEFAULT_MANIFEST)
        self._prepare_pre_apply(self.work)
        self._prepare_pre_apply(self.seed)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _prepare_pre_apply(self, path: Path) -> None:
        connection = sqlite3.connect(path)
        try:
            connection.execute("BEGIN IMMEDIATE")
            for target in self.manifest.targets:
                connection.execute(
                    '''
                    UPDATE WORD_TABLE
                    SET "언어" = ?
                    WHERE id = ? AND "스트롱넘버" = ?
                    ''',
                    (
                        migration.CURRENT_LANGUAGE,
                        target.word_id,
                        target.expected_db_strong_number,
                    ),
                )
            connection.commit()
        finally:
            connection.close()

    def _dry_run(self) -> dict[str, object]:
        return migration.run_dry_run(
            manifest_path=migration.DEFAULT_MANIFEST,
            work_db=self.work,
            seed_db=self.seed,
            source_manifest_path=migration.DEFAULT_SOURCE_MANIFEST,
            source_xml_path=migration.DEFAULT_SOURCE_XML,
            enforce_initial_hashes=False,
        )

    def _apply(self, *, fault_injection: str | None = None) -> dict[str, object]:
        return migration.run_apply(
            manifest_path=migration.DEFAULT_MANIFEST,
            work_db=self.work,
            seed_db=self.seed,
            backup_root=self.backups,
            result_output=self.result,
            source_manifest_path=migration.DEFAULT_SOURCE_MANIFEST,
            source_xml_path=migration.DEFAULT_SOURCE_XML,
            confirm_token="APPLY_HEBREWSTRONG_ARC_518",
            enforce_initial_hashes=False,
            fault_injection=fault_injection,
        )

    def test_dry_run_reproduces_518_without_write(self) -> None:
        before = (_sha256(self.work), _sha256(self.seed))
        report = self._dry_run()
        self.assertEqual(report["state"], "pre_apply")
        self.assertEqual(report["planned_change_count_per_database"], 518)
        self.assertEqual(before, (_sha256(self.work), _sha256(self.seed)))

    def test_wrong_precondition_fails_without_additional_write(self) -> None:
        connection = sqlite3.connect(self.work)
        try:
            connection.execute(
                'UPDATE WORD_TABLE SET "언어"=? WHERE id=?',
                ("테스트", self.manifest.targets[0].word_id),
            )
            connection.commit()
        finally:
            connection.close()
        before = (_sha256(self.work), _sha256(self.seed))
        with self.assertRaises(migration.MigrationError):
            self._dry_run()
        self.assertEqual(before, (_sha256(self.work), _sha256(self.seed)))

    def test_fault_after_work_update_restores_both_databases(self) -> None:
        before = (_sha256(self.work), _sha256(self.seed))
        with self.assertRaises(migration.MigrationError):
            self._apply(fault_injection="after_work_update")
        self.assertEqual(before, (_sha256(self.work), _sha256(self.seed)))
        self.assertFalse(self.result.exists())

    def test_apply_and_second_run_noop(self) -> None:
        first = self._apply()
        self.assertEqual(first["work_change_count"], 518)
        self.assertEqual(first["seed_change_count"], 518)
        post_hashes = (_sha256(self.work), _sha256(self.seed))
        result_sha = _sha256(self.result)
        backup_count = len(list(self.backups.iterdir()))

        postflight = self._dry_run()
        self.assertEqual(postflight["state"], "post_apply")
        second = self._apply()
        self.assertEqual(second["change_count"], 0)
        self.assertFalse(second["backup_created"])
        self.assertEqual(post_hashes, (_sha256(self.work), _sha256(self.seed)))
        self.assertEqual(result_sha, _sha256(self.result))
        self.assertEqual(backup_count, len(list(self.backups.iterdir())))


if __name__ == "__main__":
    unittest.main()
