from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import tempfile
import unittest
from unittest import mock

import hebrewstrong_arc_spelling_sync as sync
import strong_source_migration as migration


class HebrewStrongArcSpellingSyncTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.work = self.root / "work.db"
        self.seed = self.root / "seed.db"
        self.result = self.root / "result.json"
        self.backups = self.root / "backups"
        self.manifest = sync.load_manifest(sync.DEFAULT_MANIFEST)
        self._create_database(self.work)
        shutil.copy2(self.work, self.seed)
        payload = dict(self.manifest.payload)
        payload["expected_initial_database_sha256"] = {
            "work": self._sha(self.work),
            "seed": self._sha(self.seed),
        }
        self.fixture_manifest = self.root / "manifest.json"
        self.fixture_manifest.write_text(
            json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _sha(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def _create_database(self, path: Path) -> None:
        spelling_columns = ", ".join(f'"표기{seq}" TEXT' for seq in range(1, 7))
        pronunciation_columns = ", ".join(
            f'"발음{seq}" TEXT' for seq in range(1, 7)
        )
        connection = sqlite3.connect(path)
        try:
            connection.executescript(
                f'''
                PRAGMA foreign_keys = ON;
                CREATE TABLE WORD_TABLE(
                  id TEXT PRIMARY KEY,
                  "언어" TEXT,
                  "스트롱넘버" TEXT,
                  {spelling_columns},
                  {pronunciation_columns},
                  protected_note TEXT
                );
                CREATE TABLE word_expression_set(
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  word_id TEXT NOT NULL,
                  seq INTEGER NOT NULL,
                  is_representative INTEGER NOT NULL,
                  spelling TEXT NOT NULL,
                  transliteration TEXT,
                  pronunciation TEXT,
                  pronunciation_notation TEXT,
                  pronunciation_notation_name TEXT,
                  FOREIGN KEY(word_id) REFERENCES WORD_TABLE(id)
                );
                CREATE TABLE CHANGE_HISTORY(id INTEGER PRIMARY KEY, detail TEXT);
                INSERT INTO CHANGE_HISTORY(detail) VALUES ('protected');
                '''
            )
            for target in self.manifest.targets:
                current = target["current_values"]
                connection.execute(
                    '''
                    INSERT INTO WORD_TABLE(
                      id, "언어", "스트롱넘버", "표기1", "발음1", protected_note
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    ''',
                    (
                        target["word_id"],
                        target["language"],
                        target["strong_id"],
                        current["spelling"],
                        current["pronunciation"],
                        "target-protected",
                    ),
                )
                connection.execute(
                    '''
                    INSERT INTO word_expression_set(
                      word_id, seq, is_representative, spelling, transliteration,
                      pronunciation, pronunciation_notation, pronunciation_notation_name
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ''',
                    (
                        target["word_id"],
                        target["seq"],
                        target["is_representative"],
                        current["spelling"],
                        current["transliteration"],
                        current["pronunciation"],
                        current["pronunciation_notation"],
                        current["pronunciation_notation_name"],
                    ),
                )
            connection.execute(
                '''
                INSERT INTO WORD_TABLE(
                  id, "언어", "스트롱넘버", "표기1", "발음1", protected_note
                ) VALUES ('H9999_0000', '아람어', 'H9999', '비대상', 'pron', 'non-target')
                '''
            )
            connection.execute(
                '''
                INSERT INTO word_expression_set(
                  word_id, seq, is_representative, spelling, transliteration,
                  pronunciation, pronunciation_notation, pronunciation_notation_name
                ) VALUES ('H9999_0000', 1, 1, '비대상', '비대상', 'pron', 'unknown', NULL)
                '''
            )
            connection.commit()
        finally:
            connection.close()

    @staticmethod
    def _semantic_rows(path: Path) -> list[tuple[object, ...]]:
        connection = sqlite3.connect(path)
        try:
            return connection.execute(
                '''
                SELECT w.id, w."언어", w."스트롱넘버", w."표기1", w."발음1",
                       w.protected_note, e.seq, e.is_representative, e.spelling,
                       e.transliteration, e.pronunciation,
                       e.pronunciation_notation, e.pronunciation_notation_name
                FROM WORD_TABLE w
                JOIN word_expression_set e ON e.word_id=w.id
                ORDER BY w.id, e.seq
                '''
            ).fetchall()
        finally:
            connection.close()

    def _patched_source(self):
        return mock.patch.object(
            sync,
            "verify_manifest_source",
            return_value=self.manifest.payload["source"],
        )

    def test_manifest_contract_and_preflight_are_exact(self) -> None:
        manifest_bytes = sync.DEFAULT_MANIFEST.read_bytes()
        result_bytes = sync.DEFAULT_RESULT.read_bytes()
        self.assertNotIn(b"\r\n", manifest_bytes)
        self.assertNotIn(b"\r\n", result_bytes)
        self.assertEqual(
            hashlib.sha256(manifest_bytes).hexdigest(),
            "9333431060a82a793d7d37b79747a46b90c96adf537ef5f96adce5879b7954dd",
        )
        loaded = sync.load_manifest(self.fixture_manifest)
        self.assertEqual(len(loaded.plan), sync.EXPECTED_TARGET_COUNT)
        self.assertEqual(
            loaded.payload["target_projection_sha256"],
            sync.EXPECTED_TARGET_PROJECTION_SHA256,
        )
        work = migration.preflight_database_plan(self.work, list(loaded.plan))
        seed = migration.preflight_database_plan(self.seed, list(loaded.plan))
        self.assertEqual(work, seed)
        self.assertEqual(work["current_count"], 12)
        self.assertEqual(work["already_expected_count"], 0)

    def test_apply_updates_only_normalized_and_legacy_spelling(self) -> None:
        loaded = sync.load_manifest(self.fixture_manifest)
        before = self._semantic_rows(self.work)
        connection = sqlite3.connect(self.work)
        try:
            history_before = connection.execute(
                "SELECT * FROM CHANGE_HISTORY ORDER BY id"
            ).fetchall()
        finally:
            connection.close()

        result = migration.apply_database(self.work, list(loaded.plan))

        counts = result["change_counts"]
        self.assertEqual(counts["spelling_change_count"], 12)
        self.assertEqual(counts["legacy_spelling_slot_change_count"], 12)
        self.assertEqual(counts["pronunciation_change_count"], 0)
        self.assertEqual(counts["notation_change_count"], 0)
        after = self._semantic_rows(self.work)
        before_by_id = {row[0]: row for row in before}
        after_by_id = {row[0]: row for row in after}
        self.assertEqual(before_by_id["H9999_0000"], after_by_id["H9999_0000"])
        for target in loaded.targets:
            row = after_by_id[target["word_id"]]
            self.assertEqual(row[3], target["expected_values"]["spelling"])
            self.assertEqual(row[8], target["expected_values"]["spelling"])
            self.assertEqual(row[4], before_by_id[target["word_id"]][4])
            self.assertEqual(row[9:], before_by_id[target["word_id"]][9:])
        connection = sqlite3.connect(self.work)
        try:
            self.assertEqual(
                connection.execute("SELECT * FROM CHANGE_HISTORY ORDER BY id").fetchall(),
                history_before,
            )
        finally:
            connection.close()
        first_hash = self._sha(self.work)
        second = migration.apply_database(self.work, list(loaded.plan))
        self.assertEqual(second["change_counts"]["actual_changed_expression_count"], 0)
        self.assertEqual(second["change_counts"]["already_expected_noop_count"], 12)
        self.assertEqual(self._sha(self.work), first_hash)

    def test_third_value_rolls_back_prior_target_updates(self) -> None:
        loaded = sync.load_manifest(self.fixture_manifest)
        last = loaded.targets[-1]
        connection = sqlite3.connect(self.work)
        try:
            connection.execute(
                "UPDATE word_expression_set SET spelling='제3값' WHERE word_id=? AND seq=1",
                (last["word_id"],),
            )
            connection.execute(
                'UPDATE WORD_TABLE SET "표기1"=\'제3값\' WHERE id=?',
                (last["word_id"],),
            )
            connection.commit()
        finally:
            connection.close()
        before_hash = self._sha(self.work)
        before_rows = self._semantic_rows(self.work)

        with self.assertRaises(migration.MigrationError):
            migration.apply_database(self.work, list(loaded.plan))

        self.assertEqual(self._sha(self.work), before_hash)
        self.assertEqual(self._semantic_rows(self.work), before_rows)

    def test_duplicate_normalized_slot_fails_closed(self) -> None:
        loaded = sync.load_manifest(self.fixture_manifest)
        first = loaded.targets[0]
        connection = sqlite3.connect(self.work)
        try:
            connection.execute(
                '''
                INSERT INTO word_expression_set(
                  word_id, seq, is_representative, spelling, transliteration,
                  pronunciation, pronunciation_notation, pronunciation_notation_name
                )
                SELECT word_id, seq, is_representative, spelling, transliteration,
                       pronunciation, pronunciation_notation, pronunciation_notation_name
                FROM word_expression_set WHERE word_id=? AND seq=1
                ''',
                (first["word_id"],),
            )
            connection.commit()
        finally:
            connection.close()
        before_hash = self._sha(self.work)

        with self.assertRaises(migration.MigrationError):
            migration.apply_database(self.work, list(loaded.plan))

        self.assertEqual(self._sha(self.work), before_hash)

    def test_second_database_failure_restores_both_backups(self) -> None:
        original_hashes = (self._sha(self.work), self._sha(self.seed))
        with self._patched_source():
            with self.assertRaises(sync.MigrationError):
                sync.run_apply(
                    manifest_path=self.fixture_manifest,
                    work_db=self.work,
                    seed_db=self.seed,
                    backup_root=self.backups,
                    result_output=self.result,
                    confirm_token=sync.CONFIRM_TOKEN,
                    fault_injection="after_work_apply",
                )
        self.assertEqual((self._sha(self.work), self._sha(self.seed)), original_hashes)
        self.assertFalse(self.result.exists())

    def test_runner_applies_and_second_run_is_noop(self) -> None:
        with self._patched_source():
            first = sync.run_apply(
                manifest_path=self.fixture_manifest,
                work_db=self.work,
                seed_db=self.seed,
                backup_root=self.backups,
                result_output=self.result,
                confirm_token=sync.CONFIRM_TOKEN,
            )
            backup_count = len(list(self.backups.iterdir()))
            result_hash = self._sha(self.result)
            second = sync.run_apply(
                manifest_path=self.fixture_manifest,
                work_db=self.work,
                seed_db=self.seed,
                backup_root=self.backups,
                result_output=self.result,
                confirm_token=sync.CONFIRM_TOKEN,
            )
        self.assertEqual(first["work_change_counts"]["spelling_change_count"], 12)
        self.assertEqual(first["seed_change_counts"]["spelling_change_count"], 12)
        self.assertEqual(second["change_count"], 0)
        self.assertFalse(second["backup_created"])
        self.assertFalse(second["transaction_started"])
        self.assertEqual(backup_count, len(list(self.backups.iterdir())))
        self.assertEqual(result_hash, self._sha(self.result))
        self.assertTrue(
            migration.compare_database_projection(self.work, self.seed)[
                "semantic_projection_equal"
            ]
        )

    @unittest.skipUnless(
        sync.DEFAULT_MANIFEST.is_file()
        and (sync.DEFAULT_SOURCE_CACHE / "HebrewStrong.xml").is_file()
        and sync.DEFAULT_WORK_DB.is_file()
        and sync.DEFAULT_SEED_DB.is_file(),
        "tracked manifest, 고정 source cache와 active DB가 필요함",
    )
    def test_official_source_reproduces_same_12_target_projection(self) -> None:
        manifest = sync.load_manifest()
        sync.verify_manifest_source(manifest)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            work = root / "work.db"
            seed = root / "seed.db"
            shutil.copy2(sync.DEFAULT_WORK_DB, work)
            shutil.copy2(sync.DEFAULT_SEED_DB, seed)
            for path in (work, seed):
                connection = sqlite3.connect(path)
                try:
                    for target in manifest.targets:
                        current = target["current_values"]["spelling"]
                        connection.execute(
                            "UPDATE word_expression_set SET spelling=? WHERE word_id=? AND seq=?",
                            (current, target["word_id"], target["seq"]),
                        )
                        connection.execute(
                            'UPDATE WORD_TABLE SET "표기1"=? WHERE id=?',
                            (current, target["word_id"]),
                        )
                    connection.commit()
                finally:
                    connection.close()
            rebuilt = sync.build_manifest_payload(work, seed)
        self.assertEqual(len(rebuilt["targets"]), 12)
        self.assertEqual(rebuilt["targets"], list(manifest.targets))
        self.assertEqual(
            rebuilt["target_projection_sha256"],
            sync.EXPECTED_TARGET_PROJECTION_SHA256,
        )


if __name__ == "__main__":
    unittest.main()
