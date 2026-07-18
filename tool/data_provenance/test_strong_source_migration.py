#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import tempfile
import unittest
from unittest import mock

import strong_source_migration as migration


class StrongSourceMigrationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.work_db = self.root / "reshet_work.db"
        self.seed_db = self.root / "reshet_seed.db"
        self.plan_path = self.root / "greek_auto_plan.jsonl"
        self._write_database(self.work_db)
        shutil.copyfile(self.work_db, self.seed_db)
        self.auto_rows = [
            self._plan_row(
                "G1000",
                "G1000_0000",
                1,
                1,
                current_spelling="λογος",
                expected_spelling="λόγος",
                current_pronunciation="old-logos",
                expected_pronunciation="log'-os",
            ),
            self._plan_row(
                "G3179",
                "G3179_0000",
                1,
                1,
                current_spelling="μεθίστημι",
                expected_spelling="μεθίστημι",
                current_pronunciation="meth-is'-tay-mee",
                expected_pronunciation="meth-is'-tay-mee",
            ),
            self._plan_row(
                "G3179",
                "G3179_0000",
                2,
                0,
                current_spelling="μεθιστάνω",
                expected_spelling="μεθιστάνω",
                current_pronunciation="old-second",
                expected_pronunciation="meth-is-tan'-o",
            ),
        ]
        self._write_plan(self.plan_path, self.auto_rows)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @staticmethod
    def _sha(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    @staticmethod
    def _plan_row(
        strong_id: str,
        word_id: str,
        seq: int,
        representative: int,
        *,
        current_spelling: str,
        expected_spelling: str,
        current_pronunciation: str,
        expected_pronunciation: str,
        disposition: str = "auto",
        language: str = "헬라어",
    ) -> dict[str, object]:
        changes: list[str] = []
        if current_spelling != expected_spelling:
            changes.append("spelling")
        if current_pronunciation != expected_pronunciation:
            changes.append("pronunciation")
        changes.append("pronunciation_notation")
        return {
            "strong_id": strong_id,
            "word_id": word_id,
            "language": language,
            "db_seq": seq,
            "is_representative": representative,
            "source_candidate_diagnostic_id": f"{strong_id}:fixture",
            "source_candidate_ordinal": 999,
            "mapping_rule": "fixture",
            "current_values": {
                "spelling": current_spelling,
                "transliteration": f"xlit-{strong_id}-{seq}",
                "pronunciation": current_pronunciation,
                "pronunciation_notation": "unknown",
                "pronunciation_notation_name": None,
            },
            "expected_values": {
                "spelling": expected_spelling,
                "transliteration": f"xlit-{strong_id}-{seq}",
                "pronunciation": expected_pronunciation,
                "pronunciation_notation": "strong_dictionary",
                "pronunciation_notation_name": None,
            },
            "expected_field_changes": changes,
            "change_classification": "fixture",
            "primary_disposition": disposition,
            "reason_codes": [],
        }

    @staticmethod
    def _write_plan(path: Path, rows: list[dict[str, object]]) -> None:
        path.write_text(
            "".join(
                json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n"
                for row in rows
            ),
            encoding="utf-8",
        )

    @staticmethod
    def _create_word_table(connection: sqlite3.Connection) -> None:
        legacy_columns = ",\n".join(
            [f'"표기{seq}" TEXT' for seq in range(1, 7)]
            + [f'"음역{seq}" TEXT' for seq in range(1, 7)]
            + [f'"발음{seq}" TEXT' for seq in range(1, 7)]
        )
        connection.execute(
            f'''
            CREATE TABLE WORD_TABLE (
              id TEXT PRIMARY KEY,
              "언어" TEXT,
              "스트롱넘버" TEXT,
              {legacy_columns},
              비고 TEXT
            )
            '''
        )

    def _write_database(self, path: Path) -> None:
        connection = sqlite3.connect(path)
        try:
            self._create_word_table(connection)
            connection.executescript(
                '''
                CREATE TABLE word_expression_set (
                  id INTEGER PRIMARY KEY,
                  word_id TEXT NOT NULL,
                  seq INTEGER NOT NULL,
                  is_representative INTEGER NOT NULL,
                  spelling TEXT NOT NULL,
                  transliteration TEXT,
                  pronunciation TEXT,
                  pronunciation_notation TEXT,
                  pronunciation_notation_name TEXT,
                  FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id)
                );
                CREATE TABLE CHANGE_HISTORY (
                  id INTEGER PRIMARY KEY,
                  action TEXT NOT NULL,
                  payload TEXT NOT NULL
                );
                INSERT INTO CHANGE_HISTORY(id, action, payload)
                VALUES (1, 'fixture', '{"보존":true}');
                '''
            )
            words = [
                ("G1000_0000", "헬라어", "G1000", "guard-auto"),
                ("G3179_0000", "헬라어", "G3179", "guard-multiple"),
                ("G0153_0000", "헬라어", "G0153", "repair-target"),
                ("G1543_0000", "헬라어", "G1543", "guard-exception"),
                ("G3475_0000", "헬라어", "G3475", "guard-exception"),
                ("H0001_0000", "히브리어", "H1", "guard-hebrew"),
            ]
            connection.executemany(
                'INSERT INTO WORD_TABLE(id, "언어", "스트롱넘버", 비고) VALUES (?, ?, ?, ?)',
                words,
            )
            expressions = [
                (
                    "G1000_0000",
                    1,
                    1,
                    "λογος",
                    "xlit-G1000-1",
                    "old-logos",
                    "unknown",
                ),
                (
                    "G3179_0000",
                    1,
                    1,
                    "μεθίστημι",
                    "xlit-G3179-1",
                    "meth-is'-tay-mee",
                    "unknown",
                ),
                (
                    "G3179_0000",
                    2,
                    0,
                    "μεθιστάνω",
                    "xlit-G3179-2",
                    "old-second",
                    "unknown",
                ),
                (
                    "G0153_0000",
                    1,
                    1,
                    "αἰσχύνομαι",
                    "아이스퀴노마이",
                    migration.G0153_CANONICAL_PRONUNCIATION,
                    "unknown",
                ),
                (
                    "G1543_0000",
                    1,
                    1,
                    "fixture-exception-1543",
                    "xlit-G1543-1",
                    "exception-pronunciation-1543",
                    "unknown",
                ),
                (
                    "G3475_0000",
                    1,
                    1,
                    "fixture-exception-3475",
                    "xlit-G3475-1",
                    "exception-pronunciation-3475",
                    "unknown",
                ),
                (
                    "H0001_0000",
                    1,
                    1,
                    "אָב",
                    "xlit-H0001-1",
                    "av",
                    "unknown",
                ),
            ]
            connection.executemany(
                '''
                INSERT INTO word_expression_set(
                  word_id, seq, is_representative, spelling, transliteration,
                  pronunciation, pronunciation_notation, pronunciation_notation_name
                ) VALUES (?, ?, ?, ?, ?, ?, ?, NULL)
                ''',
                expressions,
            )
            for word_id, seq, _, spelling, transliteration, pronunciation, _ in expressions:
                connection.execute(
                    f'''
                    UPDATE WORD_TABLE
                    SET "표기{seq}" = ?, "음역{seq}" = ?, "발음{seq}" = ?
                    WHERE id = ?
                    ''',
                    (spelling, transliteration, pronunciation, word_id),
                )
            connection.commit()
        finally:
            connection.close()

    def _set_g0153_legacy_before(self) -> None:
        for path in (self.work_db, self.seed_db):
            connection = sqlite3.connect(path)
            try:
                connection.execute(
                    '''
                    UPDATE WORD_TABLE SET "발음1" = ? WHERE id = ?
                    ''',
                    (migration.G0153_LEGACY_BEFORE, migration.G0153_WORD_ID),
                )
                connection.commit()
            finally:
                connection.close()

    @staticmethod
    def _expression_rows(path: Path) -> list[tuple[object, ...]]:
        connection = sqlite3.connect(path)
        try:
            return connection.execute(
                '''
                SELECT word_id, seq, is_representative, spelling, transliteration,
                       pronunciation, pronunciation_notation, pronunciation_notation_name
                FROM word_expression_set
                ORDER BY word_id, seq
                '''
            ).fetchall()
        finally:
            connection.close()

    @staticmethod
    def _history_rows(path: Path) -> list[tuple[object, ...]]:
        connection = sqlite3.connect(path)
        try:
            return connection.execute(
                "SELECT * FROM CHANGE_HISTORY ORDER BY rowid"
            ).fetchall()
        finally:
            connection.close()

    def test_prepare_filters_greek_auto_and_rejects_non_auto_apply_input(self) -> None:
        full_plan = self.root / "full_mapping_plan.jsonl"
        output_plan = self.root / "filtered_plan.jsonl"
        exception = dict(self.auto_rows[0], primary_disposition="exception")
        hold = dict(self.auto_rows[0], primary_disposition="hold")
        hebrew = self._plan_row(
            "H0001",
            "H0001_0000",
            1,
            1,
            current_spelling="אָב",
            expected_spelling="אָב",
            current_pronunciation="av",
            expected_pronunciation="av",
            language="히브리어",
        )
        self._write_plan(full_plan, [self.auto_rows[0], exception, hold, hebrew])

        result = migration.prepare_greek_auto_plan(full_plan, output_plan)

        self.assertEqual(result["greek_auto_word_count"], 1)
        self.assertEqual(result["greek_auto_expression_count"], 1)
        self.assertEqual(len(migration.load_migration_plan(output_plan)), 1)
        for label, invalid_row in (
            ("exception", exception),
            ("hold", hold),
            ("Hebrew", hebrew),
        ):
            with self.subTest(label=label):
                invalid_path = self.root / f"invalid_{label}.jsonl"
                self._write_plan(invalid_path, [invalid_row])
                with self.assertRaises(migration.MigrationError):
                    migration.load_migration_plan(invalid_path)

    def test_apply_updates_normalized_legacy_and_preserves_protected_data(self) -> None:
        plan = migration.load_migration_plan(self.plan_path)
        history_before = self._history_rows(self.work_db)
        expressions_before = self._expression_rows(self.work_db)
        exception_and_hebrew_before = [
            row for row in expressions_before if row[0] in {"G1543_0000", "G3475_0000", "H0001_0000"}
        ]

        work_result = migration.apply_database(self.work_db, plan)
        seed_result = migration.apply_database(self.seed_db, plan)

        self.assertEqual(work_result["change_counts"], seed_result["change_counts"])
        counts = work_result["change_counts"]
        self.assertEqual(counts["auto_word_count"], 2)
        self.assertEqual(counts["auto_expression_count"], 3)
        self.assertEqual(counts["actual_changed_word_count"], 2)
        self.assertEqual(counts["actual_changed_expression_count"], 3)
        self.assertEqual(counts["spelling_change_count"], 2)
        self.assertEqual(counts["pronunciation_change_count"], 2)
        self.assertEqual(counts["notation_change_count"], 3)
        self.assertEqual(counts["already_expected_noop_count"], 0)
        self.assertEqual(self._history_rows(self.work_db), history_before)

        expressions_after = self._expression_rows(self.work_db)
        exception_and_hebrew_after = [
            row for row in expressions_after if row[0] in {"G1543_0000", "G3475_0000", "H0001_0000"}
        ]
        self.assertEqual(exception_and_hebrew_after, exception_and_hebrew_before)
        by_identity = {(row[0], row[1]): row for row in expressions_after}
        for plan_row in plan:
            actual = by_identity[plan_row.identity]
            self.assertEqual(actual[2], plan_row.is_representative)
            self.assertEqual(actual[4], plan_row.expected_values["transliteration"])
            self.assertEqual(actual[3], plan_row.expected_values["spelling"])
            self.assertEqual(actual[5], plan_row.expected_values["pronunciation"])
            self.assertEqual(actual[6], "strong_dictionary")
            self.assertIsNone(actual[7])
        connection = sqlite3.connect(self.work_db)
        try:
            for plan_row in plan:
                legacy = connection.execute(
                    f'SELECT "표기{plan_row.seq}", "발음{plan_row.seq}" '
                    "FROM WORD_TABLE WHERE id = ?",
                    (plan_row.word_id,),
                ).fetchone()
                self.assertEqual(legacy[0], plan_row.expected_values["spelling"])
                self.assertEqual(legacy[1], plan_row.expected_values["pronunciation"])
        finally:
            connection.close()
        parity = migration.compare_database_projection(self.work_db, self.seed_db)
        self.assertTrue(parity["semantic_projection_equal"])

        first_output_hash = self._sha(self.work_db)
        second = migration.apply_database(self.work_db, plan)
        self.assertEqual(second["change_counts"]["already_expected_noop_count"], 3)
        self.assertEqual(second["change_counts"]["actual_changed_expression_count"], 0)
        self.assertEqual(self._sha(self.work_db), first_output_hash)

    def test_current_mismatch_rolls_back_prior_update(self) -> None:
        plan = migration.load_migration_plan(self.plan_path)
        connection = sqlite3.connect(self.work_db)
        try:
            connection.execute(
                '''
                UPDATE word_expression_set
                SET spelling = 'unexpected'
                WHERE word_id = 'G3179_0000' AND seq = 1
                '''
            )
            connection.execute(
                '''
                UPDATE WORD_TABLE SET "표기1" = 'unexpected'
                WHERE id = 'G3179_0000'
                '''
            )
            connection.commit()
        finally:
            connection.close()
        before_hash = self._sha(self.work_db)
        before_rows = self._expression_rows(self.work_db)

        with self.assertRaises(migration.MigrationError):
            migration.apply_database(self.work_db, plan)

        self.assertEqual(self._sha(self.work_db), before_hash)
        self.assertEqual(self._expression_rows(self.work_db), before_rows)

    def test_duplicate_identity_row_count_mismatch_rolls_back(self) -> None:
        plan = migration.load_migration_plan(self.plan_path)[:1]
        connection = sqlite3.connect(self.work_db)
        try:
            connection.execute(
                '''
                INSERT INTO word_expression_set(
                  word_id, seq, is_representative, spelling, transliteration,
                  pronunciation, pronunciation_notation, pronunciation_notation_name
                )
                SELECT word_id, seq, is_representative, spelling, transliteration,
                       pronunciation, pronunciation_notation, pronunciation_notation_name
                FROM word_expression_set
                WHERE word_id = 'G1000_0000' AND seq = 1
                '''
            )
            connection.commit()
        finally:
            connection.close()
        before_hash = self._sha(self.work_db)

        with self.assertRaises(migration.MigrationError):
            migration.apply_database(self.work_db, plan)

        self.assertEqual(self._sha(self.work_db), before_hash)

    def test_temp_copy_backup_restore_and_initial_parity(self) -> None:
        parity = migration.compare_database_projection(self.work_db, self.seed_db)
        self.assertTrue(parity["semantic_projection_equal"])
        original_hash = self._sha(self.work_db)
        backup = migration.create_verified_backup(
            self.work_db, self.root / "backups", "work_before"
        )
        self.assertTrue(backup["byte_identical"])
        self.assertEqual(backup["integrity_check"], "ok")
        portable_backup = migration._portable_backup_info(backup)
        self.assertNotIn("path", portable_backup)
        self.assertEqual(portable_backup["backup_sha256"], backup["backup_sha256"])
        connection = sqlite3.connect(self.work_db)
        try:
            connection.execute(
                "UPDATE word_expression_set SET spelling = 'mutated' WHERE id = 1"
            )
            connection.commit()
        finally:
            connection.close()
        self.assertNotEqual(self._sha(self.work_db), original_hash)

        restored = migration.restore_verified_backup(self.work_db, backup)

        self.assertTrue(restored["matches_original"])
        self.assertEqual(restored["integrity_check"], "ok")
        self.assertEqual(self._sha(self.work_db), original_hash)

    def test_migrate_parser_defaults_to_preview(self) -> None:
        args = migration.build_parser().parse_args(
            [
                "migrate",
                "--plan",
                "plan.jsonl",
                "--mapping-summary",
                "summary.json",
                "--work-db",
                "work.db",
                "--seed-db",
                "seed.db",
                "--backup-root",
                "backups",
                "--manifest-output",
                "manifest.json",
            ]
        )
        self.assertFalse(args.apply)

    def test_g0153_exact_repair_preserves_all_other_logical_data(self) -> None:
        self._set_g0153_legacy_before()
        report_path = self.root / "g0153_repair.json"
        phase_start_hashes = {
            "work_sha256": self._sha(self.work_db),
            "seed_sha256": self._sha(self.seed_db),
        }
        expression_before = self._expression_rows(self.work_db)
        history_before = self._history_rows(self.work_db)

        report = migration.run_g0153_repair(
            work_db=self.work_db,
            seed_db=self.seed_db,
            backup_root=self.root / "pre_repair_backups",
            report_output=report_path,
            apply=True,
        )

        self.assertTrue(report_path.is_file())
        self.assertEqual(report["hash_boundaries"]["phase_start"], phase_start_hashes)
        self.assertEqual(report["preflight_repair"]["before_length"], 21)
        self.assertEqual(report["preflight_repair"]["after_length"], 20)
        self.assertFalse(report["preflight_repair"]["normalized_changed"])
        self.assertEqual(report["preflight_repair"]["applied_to"], ["work", "seed"])
        self.assertEqual(self._expression_rows(self.work_db), expression_before)
        self.assertEqual(self._history_rows(self.work_db), history_before)
        for path in (self.work_db, self.seed_db):
            connection = migration._connect(path, read_only=True)
            try:
                postcondition = migration.verify_g0153_exact_precondition(
                    connection, repaired=True
                )
            finally:
                connection.close()
            self.assertEqual(postcondition["legacy_length"], 20)
            self.assertEqual(postcondition["legacy_mismatches"], [])
        self.assertTrue(
            migration.compare_legacy_projection(self.work_db, self.seed_db)[
                "legacy_projection_equal"
            ]
        )

    def test_g0153_second_database_failure_restores_both_pre_repair_hashes(self) -> None:
        self._set_g0153_legacy_before()
        report_path = self.root / "failed_g0153_repair.json"
        original_hashes = (self._sha(self.work_db), self._sha(self.seed_db))
        original_repair = migration.repair_g0153_database
        calls = 0

        def fail_second(path: Path) -> dict[str, object]:
            nonlocal calls
            calls += 1
            if calls == 1:
                return original_repair(path)
            raise migration.MigrationError("fixture seed failure")

        with mock.patch.object(
            migration, "repair_g0153_database", side_effect=fail_second
        ):
            with self.assertRaises(migration.MigrationError):
                migration.run_g0153_repair(
                    work_db=self.work_db,
                    seed_db=self.seed_db,
                    backup_root=self.root / "failed_pre_repair_backups",
                    report_output=report_path,
                    apply=True,
                )

        self.assertEqual(
            (self._sha(self.work_db), self._sha(self.seed_db)), original_hashes
        )
        self.assertFalse(report_path.exists())
        for path in (self.work_db, self.seed_db):
            connection = migration._connect(path, read_only=True)
            try:
                migration.verify_g0153_exact_precondition(connection, repaired=False)
            finally:
                connection.close()


if __name__ == "__main__":
    unittest.main()
