from __future__ import annotations

import json
from pathlib import Path
import shutil
import sqlite3
import tempfile
import unittest

import phase50w_hebrew20_source_import as migration


class Phase50WHebrew20SourceImportTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest_path = migration.DEFAULT_MANIFEST
        cls.source_manifest_path = migration.DEFAULT_SOURCE_MANIFEST
        cls.source_xml_path = migration.DEFAULT_SOURCE_XML
        cls.work_db = migration.DEFAULT_WORK_DB
        cls.seed_db = migration.DEFAULT_SEED_DB
        cls.verified_backup_dir = (
            migration.REPOSITORY_ROOT
            / "data"
            / "backups"
            / "phase50w"
            / "20260720T153431_661359Z"
        )
        cls.pre_work_db = (
            cls.verified_backup_dir / "reshet_work_pre_phase50w.db"
        )
        cls.pre_seed_db = (
            cls.verified_backup_dir / "reshet_seed_pre_phase50w.db"
        )
        cls.loaded = migration.load_manifest(
            cls.manifest_path,
            cls.source_manifest_path,
            cls.source_xml_path,
        )

    def _copy_pair(self, root: Path) -> tuple[Path, Path]:
        work = root / "work.db"
        seed = root / "seed.db"
        shutil.copy2(self.pre_work_db, work)
        shutil.copy2(self.pre_seed_db, seed)
        return work, seed

    def _insert_exact_entry(
        self,
        connection: sqlite3.Connection,
        entry: dict[str, object],
        *,
        include_expression: bool = True,
        include_meaning: bool = True,
    ) -> None:
        word = migration._expected_word_row(entry)
        columns = ",".join(migration._quote(column) for column in migration.WORD_COLUMNS)
        placeholders = ",".join("?" for _ in migration.WORD_COLUMNS)
        connection.execute(
            f"INSERT INTO WORD_TABLE({columns}) VALUES ({placeholders})",
            tuple(word[column] for column in migration.WORD_COLUMNS),
        )
        if include_expression:
            for expression in migration._expected_expression_rows(entry):
                connection.execute(
                    """
                    INSERT INTO word_expression_set(
                      word_id, seq, is_representative, spelling, transliteration,
                      pronunciation, pronunciation_notation,
                      pronunciation_notation_name
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    tuple(expression.values()),
                )
        if include_meaning:
            for meaning in migration._expected_meaning_rows(entry):
                connection.execute(
                    "INSERT INTO word_meaning_set(word_id, seq, meaning) VALUES (?, ?, ?)",
                    tuple(meaning.values()),
                )

    def _insert_all_exact(self, path: Path) -> None:
        connection = sqlite3.connect(path)
        try:
            connection.execute("PRAGMA foreign_keys = ON")
            for entry in self.loaded.entries:
                self._insert_exact_entry(connection, entry)
            connection.commit()
        finally:
            connection.close()

    def test_01_manifest_schema_deterministic_bytes_and_source_boundary(self) -> None:
        data = self.manifest_path.read_bytes()
        self.assertFalse(data.startswith(b"\xef\xbb\xbf"))
        self.assertTrue(data.endswith(b"\n"))
        self.assertNotIn(b"\r\n", data)
        payload = json.loads(data.decode("utf-8"))
        self.assertEqual(data, migration.canonical_json_bytes(payload))
        self.assertEqual(payload["schema_version"], 1)
        self.assertEqual(payload["phase"], "50-W")
        self.assertEqual(
            payload["source"]["source_sha256"],
            "a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4",
        )
        self.assertEqual(
            payload["source"]["source_manifest_sha256"],
            migration.sha256_file(self.source_manifest_path),
        )
        self.assertEqual(
            payload["source"]["parser_source_sha256"],
            migration.sha256_file(migration.TOOL_DIR / "strong_source_diff.py"),
        )
        self.assertEqual(
            payload["source"]["mapping_source_sha256"],
            migration.sha256_file(migration.TOOL_DIR / "strong_source_mapping.py"),
        )
        self.assertEqual(payload["source"]["form_parser_contract"], "hebrew_forms_v2")
        self.assertEqual(
            payload["source"]["meaning_projection_contract"],
            "hebrew_meanings_v2",
        )
        self.assertEqual(
            self.loaded.parser_projection_sha256,
            "acde4da26bdf17a4116f4671027d869adbf4cf5056eafae0e870b03b70b219f3",
        )

    def test_02_exact_target_payload_meanings_and_legacy_projection(self) -> None:
        entries = self.loaded.entries
        self.assertEqual(
            [entry["source_key"] for entry in entries],
            list(migration.TARGET_STRONGS),
        )
        self.assertEqual(sum(entry["language"] == "히브리어" for entry in entries), 19)
        self.assertEqual(sum(entry["language"] == "아람어" for entry in entries), 1)
        self.assertEqual(
            next(entry for entry in entries if entry["source_key"] == "H1655")[
                "language"
            ],
            "아람어",
        )
        self.assertEqual(sum(len(entry["meanings"]) for entry in entries), 39)
        self.assertEqual(
            {entry["source_key"]: len(entry["meanings"]) for entry in entries}[
                "H1656"
            ],
            1,
        )
        for entry in entries:
            with self.subTest(strong=entry["source_key"]):
                self.assertEqual(entry["word_id"], f"{entry['source_key']}_0000")
                self.assertEqual(entry["strong_number"], entry["source_key"])
                self.assertIsNone(entry["note"])
                self.assertEqual(entry["graph_expand_mode"], "default")
                self.assertEqual(entry["source_document_order"], 1)
                self.assertEqual(len(entry["expressions"]), 1)
                expression = entry["expressions"][0]
                self.assertEqual(expression["seq"], 1)
                self.assertEqual(expression["is_representative"], 1)
                self.assertEqual(expression["pronunciation_notation"], "strong_dictionary")
                self.assertIsNone(expression["pronunciation_notation_name"])
                legacy = entry["legacy_expression_projection"]
                self.assertEqual(legacy["표기1"], expression["spelling"])
                self.assertEqual(legacy["음역1"], expression["transliteration"])
                self.assertEqual(legacy["발음1"], expression["pronunciation"])
                for index in range(2, 7):
                    self.assertIsNone(legacy[f"표기{index}"])
                    self.assertIsNone(legacy[f"음역{index}"])
                    self.assertIsNone(legacy[f"발음{index}"])
                for meaning in entry["meanings"]:
                    self.assertEqual(
                        entry["legacy_meaning_projection"][f"의미{meaning['seq']}"],
                        meaning["text"],
                    )
                self.assertTrue(
                    all(value is None for value in entry["legacy_relation_projection"].values())
                )
                self.assertEqual(entry["relations"], [])
                self.assertEqual(entry["change_history"], [])
                self.assertEqual(
                    entry["payload_sha256"], migration.payload_item_sha256(entry)
                )
        self.assertEqual(
            self.loaded.production_payload_sha256,
            migration.production_payload_sha256(entries),
        )

    def test_03_x_pn_twelve_are_excluded(self) -> None:
        excluded = self.loaded.payload["excluded"]
        self.assertEqual(
            [entry["source_key"] for entry in excluded],
            list(migration.EXCLUDED_X_PN_STRONGS),
        )
        self.assertTrue(
            all(entry["source_language_code"] == "x-pn" for entry in excluded)
        )
        self.assertTrue(
            all(entry["reason"] == "source_language_x_pn_unresolved" for entry in excluded)
        )
        self.assertFalse(
            set(migration.EXCLUDED_X_PN_STRONGS)
            & {str(entry["source_key"]) for entry in self.loaded.entries}
        )

    def test_04_verified_pre_apply_copy_dry_run_is_read_only(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            work, seed = self._copy_pair(root)
            result_output = root / "result.json"
            before = {
                "work": migration.sha256_file(work),
                "seed": migration.sha256_file(seed),
            }
            result = migration.run_dry_run(
                manifest_path=self.manifest_path,
                work_db=work,
                seed_db=seed,
                source_manifest_path=self.source_manifest_path,
                source_xml_path=self.source_xml_path,
                result_output=result_output,
            )
            after = {
                "work": migration.sha256_file(work),
                "seed": migration.sha256_file(seed),
            }
            self.assertEqual(before, after)
            self.assertEqual(result["work"]["state"], "pre_apply")
            self.assertEqual(result["seed"]["state"], "pre_apply")
            self.assertEqual(
                result["planned_actions_per_database"],
                migration.EXPECTED_ACTION_COUNTS,
            )
            self.assertEqual(result["sidecar_count"], 0)
            self.assertFalse(result["active_backup_created"])
            self.assertFalse(result["result_artifact_created"])
            self.assertFalse(result_output.exists())
            migration.assert_no_sidecars((work, seed))

    def test_05_one_existing_and_partial_state_fail_closed_before_backup(self) -> None:
        for partial_kind in ("complete_entry", "word_only"):
            with self.subTest(partial_kind=partial_kind):
                with tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    work, seed = self._copy_pair(root)
                    for path in (work, seed):
                        connection = sqlite3.connect(path)
                        try:
                            self._insert_exact_entry(
                                connection,
                                self.loaded.entries[0],
                                include_expression=partial_kind == "complete_entry",
                                include_meaning=partial_kind == "complete_entry",
                            )
                            connection.commit()
                        finally:
                            connection.close()
                    backup_root = root / "backups"
                    with self.assertRaises(migration.MigrationError):
                        migration.run_apply(
                            confirmation=migration.APPLY_CONFIRMATION,
                            manifest_path=self.manifest_path,
                            work_db=work,
                            seed_db=seed,
                            backup_root=backup_root,
                            result_output=root / "result.json",
                            source_manifest_path=self.source_manifest_path,
                            source_xml_path=self.source_xml_path,
                        )
                    self.assertFalse(backup_root.exists())

    def test_06_work_seed_mixed_state_fails_before_backup(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            work, seed = self._copy_pair(root)
            self._insert_all_exact(work)
            backup_root = root / "backups"
            with self.assertRaises(migration.MigrationError):
                migration.run_apply(
                    confirmation=migration.APPLY_CONFIRMATION,
                    manifest_path=self.manifest_path,
                    work_db=work,
                    seed_db=seed,
                    backup_root=backup_root,
                    result_output=root / "result.json",
                    source_manifest_path=self.source_manifest_path,
                    source_xml_path=self.source_xml_path,
                )
            self.assertFalse(backup_root.exists())

    def test_07_wrong_target_values_fail_closed(self) -> None:
        mutations = {
            "spelling": (
                "UPDATE word_expression_set SET spelling='잘못된 표기' WHERE word_id='H1564_0000'",
            ),
            "meaning": (
                "UPDATE word_meaning_set SET meaning='잘못된 의미' WHERE word_id='H1564_0000' AND seq=1",
            ),
            "language": (
                "UPDATE WORD_TABLE SET \"언어\"='아람어' WHERE id='H1564_0000'",
            ),
            "strong_number": (
                "UPDATE WORD_TABLE SET \"스트롱넘버\"='H9999' WHERE id='H1564_0000'",
            ),
        }
        for label, statements in mutations.items():
            with self.subTest(label=label):
                with tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    work, seed = self._copy_pair(root)
                    for path in (work, seed):
                        self._insert_all_exact(path)
                        connection = sqlite3.connect(path)
                        try:
                            for statement in statements:
                                connection.execute(statement)
                            connection.commit()
                        finally:
                            connection.close()
                    backup_root = root / "backups"
                    with self.assertRaises(migration.MigrationError):
                        migration.run_apply(
                            confirmation=migration.APPLY_CONFIRMATION,
                            manifest_path=self.manifest_path,
                            work_db=work,
                            seed_db=seed,
                            backup_root=backup_root,
                            result_output=root / "result.json",
                            source_manifest_path=self.source_manifest_path,
                            source_xml_path=self.source_xml_path,
                        )
                    self.assertFalse(backup_root.exists())

    def test_08_temp_apply_protection_integrity_and_second_run_noop(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            work, seed = self._copy_pair(root)
            before_connections = (migration.open_read_only(work), migration.open_read_only(seed))
            try:
                work_before = migration.capture_snapshot(
                    before_connections[0], self.loaded.entries
                )
                seed_before = migration.capture_snapshot(
                    before_connections[1], self.loaded.entries
                )
            finally:
                before_connections[0].close()
                before_connections[1].close()
            backup_root = root / "backups"
            result_output = root / "result.json"
            result = migration.run_apply(
                confirmation=migration.APPLY_CONFIRMATION,
                manifest_path=self.manifest_path,
                work_db=work,
                seed_db=seed,
                backup_root=backup_root,
                result_output=result_output,
                source_manifest_path=self.source_manifest_path,
                source_xml_path=self.source_xml_path,
            )
            self.assertEqual(
                result["actions_per_database"], migration.EXPECTED_ACTION_COUNTS
            )
            self.assertTrue(result_output.is_file())
            result_bytes = result_output.read_bytes()
            self.assertFalse(result_bytes.startswith(b"\xef\xbb\xbf"))
            self.assertTrue(result_bytes.endswith(b"\n"))
            self.assertNotIn(b"\r\n", result_bytes)
            result_payload = json.loads(result_bytes.decode("utf-8"))
            self.assertEqual(
                result_bytes,
                migration.canonical_json_bytes(result_payload),
            )
            self.assertEqual(result_payload["status"], "applied")
            self.assertEqual(
                result_payload["sidecar"],
                {
                    "work": {"wal": 0, "shm": 0, "journal": 0},
                    "seed": {"wal": 0, "shm": 0, "journal": 0},
                },
            )
            self.assertEqual(
                result_payload["rollback"],
                {
                    "triggered": False,
                    "strategy": (
                        "apply 또는 postflight 실패 시 work·seed 양쪽 "
                        "verified backup 복원"
                    ),
                    "verified_by_test": True,
                    "backup_directory": result_payload["backup"]["directory"],
                },
            )
            backup_files = sorted(backup_root.rglob("*.db"))
            self.assertEqual(len(backup_files), 2)
            for backup in backup_files:
                connection = migration.open_read_only(backup)
                try:
                    health = migration.verify_database_health(connection)
                finally:
                    connection.close()
                self.assertEqual(health["integrity_check"], "ok")
                self.assertEqual(health["foreign_key_violation_count"], 0)

            post_connections = (migration.open_read_only(work), migration.open_read_only(seed))
            try:
                work_state, work_health = migration.validate_database_state(
                    post_connections[0], self.loaded.entries, "post_apply"
                )
                seed_state, seed_health = migration.validate_database_state(
                    post_connections[1], self.loaded.entries, "post_apply"
                )
                work_after = migration.capture_snapshot(
                    post_connections[0], self.loaded.entries
                )
                seed_after = migration.capture_snapshot(
                    post_connections[1], self.loaded.entries
                )
            finally:
                post_connections[0].close()
                post_connections[1].close()
            self.assertEqual(work_state, "post_apply")
            self.assertEqual(seed_state, "post_apply")
            self.assertEqual(work_health["integrity_check"], "ok")
            self.assertEqual(seed_health["foreign_key_violation_count"], 0)
            migration.verify_protected_unchanged(work_before, work_after, "work/test")
            migration.verify_protected_unchanged(seed_before, seed_after, "seed/test")
            migration.compare_work_seed_parity(work_after, seed_after)
            self.assertIsNone(work_after["g0185_pronunciation2"])
            self.assertIsNone(seed_after["g0185_pronunciation2"])
            self.assertEqual(work_after["g0025_note"], "48-B3 백업 시점")
            self.assertIsNone(seed_after["g0025_note"])
            migration.assert_no_sidecars((work, seed))

            hashes_before_noop = {
                "work": migration.sha256_file(work),
                "seed": migration.sha256_file(seed),
                "result": migration.sha256_file(result_output),
            }
            backup_paths_before_noop = sorted(str(path) for path in backup_root.rglob("*"))
            noop = migration.run_apply(
                confirmation=migration.APPLY_CONFIRMATION,
                manifest_path=self.manifest_path,
                work_db=work,
                seed_db=seed,
                backup_root=backup_root,
                result_output=result_output,
                source_manifest_path=self.source_manifest_path,
                source_xml_path=self.source_xml_path,
            )
            self.assertEqual(noop["change_count"], 0)
            self.assertFalse(noop["backup_created"])
            self.assertFalse(noop["transaction_started"])
            self.assertFalse(noop["result_rewritten"])
            self.assertEqual(
                hashes_before_noop,
                {
                    "work": migration.sha256_file(work),
                    "seed": migration.sha256_file(seed),
                    "result": migration.sha256_file(result_output),
                },
            )
            self.assertEqual(
                backup_paths_before_noop,
                sorted(str(path) for path in backup_root.rglob("*")),
            )
            migration.assert_no_sidecars((work, seed))

    def test_09_fault_after_one_commit_restores_both_backups(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            work, seed = self._copy_pair(root)
            before = {
                "work": migration.sha256_file(work),
                "seed": migration.sha256_file(seed),
            }
            backup_root = root / "backups"
            result_output = root / "result.json"
            with self.assertRaisesRegex(migration.MigrationError, "backup restore 성공"):
                migration.run_apply(
                    confirmation=migration.APPLY_CONFIRMATION,
                    manifest_path=self.manifest_path,
                    work_db=work,
                    seed_db=seed,
                    backup_root=backup_root,
                    result_output=result_output,
                    source_manifest_path=self.source_manifest_path,
                    source_xml_path=self.source_xml_path,
                    fault_injection="after_work_commit",
                )
            self.assertEqual(
                before,
                {
                    "work": migration.sha256_file(work),
                    "seed": migration.sha256_file(seed),
                },
            )
            self.assertFalse(result_output.exists())
            self.assertEqual(len(list(backup_root.rglob("*.db"))), 2)
            migration.assert_no_sidecars((work, seed))
            work_connection = migration.open_read_only(work)
            seed_connection = migration.open_read_only(seed)
            try:
                migration.validate_database_state(
                    work_connection, self.loaded.entries, "pre_apply"
                )
                migration.validate_database_state(
                    seed_connection, self.loaded.entries, "pre_apply"
                )
            finally:
                work_connection.close()
                seed_connection.close()


if __name__ == "__main__":
    unittest.main()
