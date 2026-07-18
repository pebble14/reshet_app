import json
import shutil
import sqlite3
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path


TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import phase50t_greek_legacy_strong_notation as migration


REPOSITORY_ROOT = TOOL_DIR.parent.parent
ACTIVE_WORK = REPOSITORY_ROOT / "data" / "reshet_work.db"
ACTIVE_SEED = REPOSITORY_ROOT / "data" / "reshet_seed.db"
ACTIVE_RESULT = (
    TOOL_DIR
    / "migrations"
    / "phase50t_greek_legacy_strong_notation_result.json"
)
MANIFEST = (
    TOOL_DIR / "manifests" / "phase50t_greek_legacy_strong_notation.json"
)


class Phase50TGreekLegacyStrongNotationTest(unittest.TestCase):
    @staticmethod
    def _quote_identifier(value: str) -> str:
        return '"' + value.replace('"', '""') + '"'

    @classmethod
    def _logical_table_snapshot(cls, path: Path) -> dict[str, object]:
        connection = sqlite3.connect(path)
        try:
            tables = [
                str(row[0])
                for row in connection.execute(
                    "SELECT name FROM sqlite_master "
                    "WHERE type='table' AND name NOT LIKE 'sqlite_%' "
                    "ORDER BY name"
                )
            ]
            snapshot: dict[str, object] = {}
            for table in tables:
                quoted_table = cls._quote_identifier(table)
                info = list(connection.execute(f"PRAGMA table_info({quoted_table})"))
                columns = [str(row[1]) for row in info]
                quoted_columns = ", ".join(
                    cls._quote_identifier(column) for column in columns
                )
                primary_key = [
                    str(row[1])
                    for row in sorted(
                        (row for row in info if int(row[5]) > 0),
                        key=lambda row: int(row[5]),
                    )
                ]
                if primary_key:
                    order_by = ", ".join(
                        cls._quote_identifier(column) for column in primary_key
                    )
                    rows = tuple(
                        connection.execute(
                            f"SELECT {quoted_columns} FROM {quoted_table} "
                            f"ORDER BY {order_by}"
                        )
                    )
                    key_kind = "primary_key"
                    key_columns = tuple(primary_key)
                else:
                    rows = tuple(
                        connection.execute(
                            f"SELECT rowid, {quoted_columns} FROM {quoted_table} "
                            "ORDER BY rowid"
                        )
                    )
                    key_kind = "rowid"
                    key_columns = ("rowid",)
                snapshot[table] = {
                    "columns": tuple(columns),
                    "key_kind": key_kind,
                    "key_columns": key_columns,
                    "rows": rows,
                }
            return snapshot
        finally:
            connection.close()

    @classmethod
    def _validate_fixture_pair(
        cls,
        work: Path,
        seed: Path,
        *,
        expected_state: str | None,
    ) -> tuple[dict[str, object], dict[str, object], str]:
        migration.assert_no_sidecars((work, seed))
        snapshots: dict[str, dict[str, object]] = {}
        states: dict[str, str] = {}
        for label, path in (("work", work), ("seed", seed)):
            connection = migration.open_read_only(path)
            try:
                state, _, snapshot = migration.validate_database_state(
                    connection,
                    "main",
                    cls.loaded_manifest.targets,
                    cls.source_entries,
                    cls.phase50r_auto,
                    cls.source_only_hold,
                    expected_state,
                )
            finally:
                connection.close()
            states[label] = state
            snapshots[label] = snapshot
        if states["work"] != states["seed"]:
            raise migration.MigrationError(
                "fixture work·seed 상태 불일치: "
                f"work={states['work']}, seed={states['seed']}"
            )
        migration.compare_work_seed_parity(snapshots["work"], snapshots["seed"])
        return snapshots["work"], snapshots["seed"], states["work"]

    @classmethod
    def _expression_changes(
        cls,
        before: dict[str, object],
        after: dict[str, object],
    ) -> dict[tuple[str, int], dict[str, tuple[object, object]]]:
        before_table = before["word_expression_set"]
        after_table = after["word_expression_set"]
        if not isinstance(before_table, dict) or not isinstance(after_table, dict):
            raise AssertionError("word_expression_set snapshot 형식 불일치")
        columns = tuple(before_table["columns"])
        if columns != tuple(after_table["columns"]):
            raise AssertionError("word_expression_set column 불일치")
        word_index = columns.index("word_id")
        seq_index = columns.index("seq")
        before_rows = {
            (str(row[word_index]), int(row[seq_index])): row
            for row in before_table["rows"]
        }
        after_rows = {
            (str(row[word_index]), int(row[seq_index])): row
            for row in after_table["rows"]
        }
        if set(before_rows) != set(after_rows):
            raise AssertionError("word_expression_set identity set 변경")
        changes: dict[tuple[str, int], dict[str, tuple[object, object]]] = {}
        for identity in sorted(before_rows):
            before_row = before_rows[identity]
            after_row = after_rows[identity]
            column_changes = {
                column: (before_row[index], after_row[index])
                for index, column in enumerate(columns)
                if before_row[index] != after_row[index]
            }
            if column_changes:
                changes[identity] = column_changes
        return changes

    @classmethod
    def _reverse_post_apply_copy(cls, path: Path) -> int:
        connection = sqlite3.connect(path)
        changed = 0
        try:
            connection.execute("BEGIN IMMEDIATE")
            for target in cls.loaded_manifest.targets:
                cursor = connection.execute(
                    "UPDATE word_expression_set "
                    "SET pronunciation_notation='unknown' "
                    "WHERE word_id=? AND seq=? AND pronunciation=? "
                    "AND pronunciation_notation='strong_dictionary' "
                    "AND pronunciation_notation_name IS NULL",
                    (
                        target.word_id,
                        target.seq,
                        target.expected_current_pronunciation,
                    ),
                )
                if cursor.rowcount != 1:
                    raise AssertionError(
                        "test-only 역변환 rowcount 불일치: "
                        f"{target.identity}: {cursor.rowcount}"
                    )
                changed += cursor.rowcount
            if changed != migration.TARGET_EXPRESSION_COUNT:
                raise AssertionError(
                    f"test-only 역변환 총 rowcount 불일치: {changed}"
                )
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            connection.close()
        return changed

    @classmethod
    def _prepare_pre_apply_fixture(
        cls,
        source_work: Path,
        source_seed: Path,
        destination_root: Path,
    ) -> tuple[Path, Path, dict[str, object]]:
        destination_root.mkdir(parents=True, exist_ok=True)
        work = destination_root / "work.db"
        seed = destination_root / "seed.db"
        source_hashes = {
            "work": migration.sha256_file(source_work),
            "seed": migration.sha256_file(source_seed),
        }
        shutil.copy2(source_work, work)
        shutil.copy2(source_seed, seed)
        before_snapshots = cls._validate_fixture_pair(
            work, seed, expected_state=None
        )
        before_work, before_seed, source_state = before_snapshots
        report: dict[str, object] = {
            "source_state": source_state,
            "reverse_counts": {"work": 0, "seed": 0},
            "changed_tables": {"work": [], "seed": []},
            "expression_changes": {"work": {}, "seed": {}},
        }
        if source_state == "target":
            logical_before = {
                "work": cls._logical_table_snapshot(work),
                "seed": cls._logical_table_snapshot(seed),
            }
            report["reverse_counts"] = {
                "work": cls._reverse_post_apply_copy(work),
                "seed": cls._reverse_post_apply_copy(seed),
            }
            logical_after = {
                "work": cls._logical_table_snapshot(work),
                "seed": cls._logical_table_snapshot(seed),
            }
            target_identities = {
                target.identity for target in cls.loaded_manifest.targets
            }
            for label in ("work", "seed"):
                changed_tables = [
                    table
                    for table in sorted(logical_before[label])
                    if logical_before[label][table] != logical_after[label][table]
                ]
                if changed_tables != ["word_expression_set"]:
                    raise AssertionError(
                        f"test-only 역변환 table 범위 이탈: {label}: "
                        f"{changed_tables}"
                    )
                changes = cls._expression_changes(
                    logical_before[label], logical_after[label]
                )
                if set(changes) != target_identities:
                    raise AssertionError(
                        f"test-only 역변환 identity 범위 이탈: {label}"
                    )
                expected_change = {
                    "pronunciation_notation": ("strong_dictionary", "unknown")
                }
                if any(change != expected_change for change in changes.values()):
                    raise AssertionError(
                        f"test-only 역변환 column·transition 불일치: {label}"
                    )
                report["changed_tables"][label] = changed_tables
                report["expression_changes"][label] = changes
        elif source_state != "current":
            raise migration.MigrationError(
                f"허용하지 않는 fixture source 상태: {source_state}"
            )

        after_work, after_seed, after_state = cls._validate_fixture_pair(
            work, seed, expected_state="current"
        )
        if after_state != "current":
            raise AssertionError(f"pre-apply fixture 상태 불일치: {after_state}")
        if source_state == "target":
            for label, before, after in (
                ("work", before_work, after_work),
                ("seed", before_seed, after_seed),
            ):
                changed_protections = [
                    key
                    for key in migration.PROTECTION_KEYS
                    if before[key] != after[key]
                ]
                if changed_protections:
                    raise AssertionError(
                        f"test-only 역변환 보호 projection 변경: "
                        f"{label}: {changed_protections}"
                    )
        migration.assert_no_sidecars((work, seed))
        if migration.sha256_file(source_work) != source_hashes["work"]:
            raise AssertionError("fixture source work DB가 변경됨")
        if migration.sha256_file(source_seed) != source_hashes["seed"]:
            raise AssertionError("fixture source seed DB가 변경됨")
        return work, seed, report

    @classmethod
    def setUpClass(cls) -> None:
        (
            cls.loaded_manifest,
            _,
            cls.source_entries,
            cls.phase50r_auto,
            cls.source_only_hold,
        ) = migration._load_boundaries(
            MANIFEST,
            migration.DEFAULT_SOURCE_MANIFEST,
            migration.DEFAULT_SOURCE_XML,
            migration.DEFAULT_PHASE50R_AUTO_PLAN,
            migration.DEFAULT_PHASE50R_EXCEPTION_MANIFEST,
        )
        cls.active_hashes_before = {
            "work": migration.sha256_file(ACTIVE_WORK),
            "seed": migration.sha256_file(ACTIVE_SEED),
            "result": migration.sha256_file(ACTIVE_RESULT),
        }
        cls.class_temp = tempfile.TemporaryDirectory(prefix="phase50t_tests_")
        cls.class_root = Path(cls.class_temp.name)
        (
            cls.pre_source_work,
            cls.pre_source_seed,
            cls.class_setup_report,
        ) = cls._prepare_pre_apply_fixture(
            ACTIVE_WORK,
            ACTIVE_SEED,
            cls.class_root / "pre_source",
        )
        cls.applied_work = cls.class_root / "applied_work.db"
        cls.applied_seed = cls.class_root / "applied_seed.db"
        shutil.copy2(cls.pre_source_work, cls.applied_work)
        shutil.copy2(cls.pre_source_seed, cls.applied_seed)
        cls.applied_result = cls.class_root / "applied_result.json"
        cls.applied_report = migration.run_apply(
            manifest_path=MANIFEST,
            work_db=cls.applied_work,
            seed_db=cls.applied_seed,
            backup_root=cls.class_root / "backups",
            result_output=cls.applied_result,
        )
        active_hashes_after = {
            "work": migration.sha256_file(ACTIVE_WORK),
            "seed": migration.sha256_file(ACTIVE_SEED),
            "result": migration.sha256_file(ACTIVE_RESULT),
        }
        if active_hashes_after != cls.active_hashes_before:
            raise AssertionError("test fixture setup이 active artifact를 변경함")

    @classmethod
    def tearDownClass(cls) -> None:
        try:
            active_hashes_after = {
                "work": migration.sha256_file(ACTIVE_WORK),
                "seed": migration.sha256_file(ACTIVE_SEED),
                "result": migration.sha256_file(ACTIVE_RESULT),
            }
            if active_hashes_after != cls.active_hashes_before:
                raise AssertionError("test suite가 active artifact를 변경함")
        finally:
            cls.class_temp.cleanup()

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="phase50t_case_")
        self.root = Path(self.temp.name)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _copy_databases(self) -> tuple[Path, Path]:
        work = self.root / "work.db"
        seed = self.root / "seed.db"
        shutil.copy2(self.pre_source_work, work)
        shutil.copy2(self.pre_source_seed, seed)
        return work, seed

    def _write_manifest(self, payload: dict[str, object], *, canonical: bool = True) -> Path:
        path = self.root / "manifest.json"
        if canonical:
            path.write_bytes(migration.canonical_json_bytes(payload))
        else:
            path.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
        return path

    def _payload_copy(self) -> dict[str, object]:
        return json.loads(MANIFEST.read_text(encoding="utf-8"))

    def _update_target_expression(
        self, db: Path, sql_fragment: str, parameters: tuple[object, ...]
    ) -> None:
        target = self.loaded_manifest.targets[0]
        connection = sqlite3.connect(db)
        try:
            connection.execute(
                f"UPDATE word_expression_set SET {sql_fragment} WHERE word_id=? AND seq=?",
                (*parameters, target.word_id, target.seq),
            )
            connection.commit()
        finally:
            connection.close()

    def _assert_fault_restores_both(self, fault: str) -> None:
        work, seed = self._copy_databases()
        before = {
            "work": migration.sha256_file(work),
            "seed": migration.sha256_file(seed),
        }
        result = self.root / "result.json"
        with self.assertRaisesRegex(migration.MigrationError, "backup restore 성공"):
            migration.run_apply(
                manifest_path=MANIFEST,
                work_db=work,
                seed_db=seed,
                backup_root=self.root / "backups",
                result_output=result,
                fault_injection=fault,
            )
        self.assertEqual(migration.sha256_file(work), before["work"])
        self.assertEqual(migration.sha256_file(seed), before["seed"])
        self.assertFalse(result.exists())
        migration.assert_no_sidecars((work, seed))
        for path in (work, seed):
            connection = migration.open_read_only(path)
            try:
                self.assertEqual(
                    migration.verify_database_health(connection)["integrity_check"],
                    "ok",
                )
            finally:
                connection.close()

    def test_pre_apply_source_fixture_setup_succeeds_without_reverse(self) -> None:
        before = {
            "work": migration.sha256_file(self.pre_source_work),
            "seed": migration.sha256_file(self.pre_source_seed),
        }
        work, seed, report = self._prepare_pre_apply_fixture(
            self.pre_source_work,
            self.pre_source_seed,
            self.root / "prepared_pre_source",
        )
        self.assertEqual(report["source_state"], "current")
        self.assertEqual(report["reverse_counts"], {"work": 0, "seed": 0})
        self.assertEqual(report["changed_tables"], {"work": [], "seed": []})
        self._validate_fixture_pair(work, seed, expected_state="current")
        self.assertEqual(migration.sha256_file(self.pre_source_work), before["work"])
        self.assertEqual(migration.sha256_file(self.pre_source_seed), before["seed"])

    def test_post_apply_source_is_reversed_only_in_temporary_copies(self) -> None:
        report = self.class_setup_report
        self.assertEqual(report["source_state"], "target")
        self.assertEqual(
            report["reverse_counts"],
            {
                "work": migration.TARGET_EXPRESSION_COUNT,
                "seed": migration.TARGET_EXPRESSION_COUNT,
            },
        )
        self.assertEqual(
            report["changed_tables"],
            {
                "work": ["word_expression_set"],
                "seed": ["word_expression_set"],
            },
        )
        for label in ("work", "seed"):
            changes = report["expression_changes"][label]
            self.assertEqual(len(changes), migration.TARGET_EXPRESSION_COUNT)
            self.assertTrue(
                all(
                    change
                    == {
                        "pronunciation_notation": (
                            "strong_dictionary",
                            "unknown",
                        )
                    }
                    for change in changes.values()
                )
            )
        active_hashes_after = {
            "work": migration.sha256_file(ACTIVE_WORK),
            "seed": migration.sha256_file(ACTIVE_SEED),
            "result": migration.sha256_file(ACTIVE_RESULT),
        }
        self.assertEqual(active_hashes_after, self.active_hashes_before)
        migration.assert_no_sidecars((ACTIVE_WORK, ACTIVE_SEED))

    def test_fixture_setup_rejects_partial_application_state(self) -> None:
        work, seed = self._copy_databases()
        for path in (work, seed):
            self._update_target_expression(
                path,
                "pronunciation_notation=?",
                ("strong_dictionary",),
            )
        with self.assertRaisesRegex(migration.MigrationError, "부분 적용 상태"):
            self._prepare_pre_apply_fixture(
                work,
                seed,
                self.root / "partial_destination",
            )

    def test_fixture_setup_rejects_work_seed_state_mismatch(self) -> None:
        with self.assertRaisesRegex(
            migration.MigrationError,
            "fixture work·seed 상태 불일치",
        ):
            self._prepare_pre_apply_fixture(
                self.pre_source_work,
                ACTIVE_SEED,
                self.root / "mismatched_destination",
            )

    def test_manifest_schema_canonical_hash_projection_and_counts(self) -> None:
        loaded = self.loaded_manifest
        self.assertEqual(loaded.payload["schema_version"], 1)
        self.assertEqual(loaded.payload["phase"], "50-T")
        self.assertEqual(
            loaded.file_sha256,
            "3b69360633c18d38ebb4c221bfaaefe7d64c8b9de0f815c84983167b9d0e2775",
        )
        self.assertEqual(
            loaded.candidate_projection_sha256,
            migration.EXPECTED_CANDIDATE_PROJECTION_SHA256,
        )
        self.assertEqual(len(loaded.targets), 190)
        self.assertEqual(len({target.word_id for target in loaded.targets}), 183)
        self.assertEqual(
            MANIFEST.read_bytes(), migration.canonical_json_bytes(loaded.payload)
        )

    def test_noncanonical_manifest_is_rejected(self) -> None:
        path = self._write_manifest(self._payload_copy(), canonical=False)
        with self.assertRaisesRegex(migration.MigrationError, "canonical"):
            migration.load_input_manifest(path)

    def test_candidate_projection_hash_mismatch_is_rejected(self) -> None:
        payload = self._payload_copy()
        payload["candidate_projection_sha256"] = "0" * 64
        path = self._write_manifest(payload)
        with self.assertRaisesRegex(migration.MigrationError, "projection SHA"):
            migration.load_input_manifest(path)

    def test_duplicate_identity_is_rejected(self) -> None:
        payload = self._payload_copy()
        targets = payload["targets"]
        self.assertIsInstance(targets, list)
        targets[1]["word_id"] = targets[0]["word_id"]
        targets[1]["seq"] = targets[0]["seq"]
        path = self._write_manifest(payload)
        with self.assertRaisesRegex(migration.MigrationError, "identity 중복"):
            migration.load_input_manifest(path)

    def test_source_boundary_mismatch_is_rejected(self) -> None:
        payload = self._payload_copy()
        payload["source"]["commit"] = "invalid"
        path = self._write_manifest(payload)
        with self.assertRaisesRegex(migration.MigrationError, "source boundary"):
            migration.load_input_manifest(path)

    def test_source_primary_exact_and_alternate_only_rejected(self) -> None:
        source_info, source = migration.verify_source_boundary(
            migration.DEFAULT_SOURCE_MANIFEST,
            migration.DEFAULT_SOURCE_XML,
            self.loaded_manifest,
        )
        self.assertEqual(
            source_info["greek_xml_sha256"], migration.EXPECTED_SOURCE["sha256"]
        )
        original = self.loaded_manifest.targets[0]
        alternate_only = replace(
            original,
            source_key="G1683",
            source_primary_pronunciation="em-ow-to'",
        )
        fake = migration.LoadedManifest(
            payload=self.loaded_manifest.payload,
            targets=(alternate_only,),
            file_sha256=self.loaded_manifest.file_sha256,
            candidate_projection_sha256=self.loaded_manifest.candidate_projection_sha256,
        )
        with self.assertRaisesRegex(migration.MigrationError, "alternate-only"):
            migration.verify_source_boundary(
                migration.DEFAULT_SOURCE_MANIFEST,
                migration.DEFAULT_SOURCE_XML,
                fake,
            )
        self.assertIn("em-ow-to'", source["G1683"].alternate)

    def test_dry_run_validates_scope_exclusions_parity_and_is_read_only(self) -> None:
        work, seed = self._copy_databases()
        before = {
            "work": migration.sha256_file(work),
            "seed": migration.sha256_file(seed),
        }
        report = migration.run_dry_run(
            manifest_path=MANIFEST, work_db=work, seed_db=seed
        )
        self.assertEqual(report["status"], "적용 가능 — 변경 예정 190")
        self.assertEqual(report["database_sha256_before"], before)
        self.assertEqual(report["database_sha256_after"], before)
        self.assertTrue(report["parity"]["exact"])
        for label in ("work", "seed"):
            snapshot = report[label]["snapshot"]
            self.assertEqual(snapshot["target_word_count"], 183)
            self.assertEqual(snapshot["target_expression_count"], 190)
            self.assertEqual(snapshot["e4_count"], 11)
            self.assertEqual(snapshot["e5_count"], 23)
            self.assertEqual(snapshot["phase50r_auto_count"], 5389)
            self.assertEqual(snapshot["target_notation_counts"], {"unknown": 190})
        self.assertEqual(report["sidecar_count"], 0)
        migration.assert_no_sidecars((work, seed))

    def test_current_notation_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        for path in (work, seed):
            self._update_target_expression(
                path, "pronunciation_notation=?", ("ipa_phonemic",)
            )
        with self.assertRaisesRegex(migration.MigrationError, "current notation"):
            migration.run_dry_run(manifest_path=MANIFEST, work_db=work, seed_db=seed)

    def test_notation_name_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        for path in (work, seed):
            self._update_target_expression(
                path, "pronunciation_notation_name=?", ("unexpected",)
            )
        with self.assertRaisesRegex(migration.MigrationError, "notation_name"):
            migration.run_dry_run(manifest_path=MANIFEST, work_db=work, seed_db=seed)

    def test_pronunciation_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        for path in (work, seed):
            self._update_target_expression(path, "pronunciation=?", ("mismatch",))
        with self.assertRaisesRegex(migration.MigrationError, "pronunciation mismatch"):
            migration.run_dry_run(manifest_path=MANIFEST, work_db=work, seed_db=seed)

    def test_legacy_pronunciation_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        target = self.loaded_manifest.targets[0]
        column = f"발음{target.seq}"
        for path in (work, seed):
            connection = sqlite3.connect(path)
            try:
                connection.execute(
                    f'UPDATE WORD_TABLE SET "{column}"=? WHERE id=?',
                    ("legacy mismatch", target.word_id),
                )
                connection.commit()
            finally:
                connection.close()
        with self.assertRaisesRegex(migration.MigrationError, "legacy pronunciation"):
            migration.run_dry_run(manifest_path=MANIFEST, work_db=work, seed_db=seed)

    def test_work_seed_projection_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        target = self.loaded_manifest.targets[0]
        connection = sqlite3.connect(work)
        try:
            connection.execute(
                "UPDATE word_expression_set SET is_representative=0 WHERE word_id=? AND seq=?",
                target.identity,
            )
            connection.commit()
        finally:
            connection.close()
        with self.assertRaisesRegex(migration.MigrationError, "work·seed projection parity"):
            migration.run_dry_run(manifest_path=MANIFEST, work_db=work, seed_db=seed)

    def test_e4_e5_explicit_identities_are_excluded(self) -> None:
        identities = {target.identity for target in self.loaded_manifest.targets}
        self.assertNotIn(("G1683_0000", 2), identities)
        self.assertNotIn(("G4452_0000", 1), identities)
        self.assertNotIn(("G0728_0000", 2), identities)
        self.assertNotIn(("G2576_0000", 2), identities)

    def test_phase50r_auto_is_excluded(self) -> None:
        auto = migration.load_phase50r_auto_identities(
            migration.DEFAULT_PHASE50R_AUTO_PLAN
        )
        targets = {target.identity for target in self.loaded_manifest.targets}
        self.assertEqual(len(auto), 5389)
        self.assertFalse(auto & targets)

    def test_hebrew_and_aramaic_are_excluded(self) -> None:
        self.assertEqual(
            {target.language for target in self.loaded_manifest.targets}, {"헬라어"}
        )
        self.assertTrue(
            all(target.strong_number.startswith("G") for target in self.loaded_manifest.targets)
        )

    def test_apply_changes_only_notation_and_protects_projections(self) -> None:
        report = self.applied_report
        self.assertEqual(report["work_change_count"], 190)
        self.assertEqual(report["seed_change_count"], 190)
        result = json.loads(self.applied_result.read_text(encoding="utf-8"))
        self.assertEqual(
            result["change_counts"]["columns_changed"],
            ["word_expression_set.pronunciation_notation"],
        )
        for label in ("work", "seed"):
            protection = result[label]["protection"]
            for values in protection.values():
                self.assertEqual(values["pre"], values["post"])
            counts = result[label]["counts"]
            for values in counts.values():
                self.assertEqual(values["pre"], values["post"])
            self.assertEqual(counts["e4_count"]["post"], 11)
            self.assertEqual(counts["e5_count"]["post"], 23)
            self.assertEqual(counts["phase50r_auto_count"]["post"], 5389)
            self.assertEqual(
                result[label]["health"]["post"]["integrity_check"], "ok"
            )
        self.assertTrue(result["parity_post"]["exact"])

    def test_partial_application_state_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        for path in (work, seed):
            self._update_target_expression(
                path, "pronunciation_notation=?", ("strong_dictionary",)
            )
        with self.assertRaisesRegex(migration.MigrationError, "부분 적용 상태"):
            migration.run_apply(
                manifest_path=MANIFEST,
                work_db=work,
                seed_db=seed,
                backup_root=self.root / "backups",
                result_output=self.root / "result.json",
            )

    def test_second_run_is_noop_and_preserves_db_and_result_hashes(self) -> None:
        before = {
            "work": migration.sha256_file(self.applied_work),
            "seed": migration.sha256_file(self.applied_seed),
            "result": migration.sha256_file(self.applied_result),
        }
        report = migration.run_apply(
            manifest_path=MANIFEST,
            work_db=self.applied_work,
            seed_db=self.applied_seed,
            backup_root=self.class_root / "unused_second_run_backups",
            result_output=self.applied_result,
        )
        self.assertEqual(report["status"], "이미 적용됨 — 변경 0")
        self.assertEqual(report["change_count"], 0)
        self.assertFalse(report["backup_created"])
        self.assertFalse(report["transaction_started"])
        self.assertEqual(migration.sha256_file(self.applied_work), before["work"])
        self.assertEqual(migration.sha256_file(self.applied_seed), before["seed"])
        self.assertEqual(migration.sha256_file(self.applied_result), before["result"])

    def test_work_update_failure_restores_both_databases(self) -> None:
        self._assert_fault_restores_both("work_update")

    def test_seed_update_failure_restores_both_databases(self) -> None:
        self._assert_fault_restores_both("seed_update")

    def test_post_commit_validation_failure_restores_both_databases(self) -> None:
        self._assert_fault_restores_both("post_commit_validation")

    def test_result_write_failure_restores_both_databases(self) -> None:
        self._assert_fault_restores_both("result_write")

    def test_result_manifest_count_and_hash_contract(self) -> None:
        result = json.loads(self.applied_result.read_text(encoding="utf-8"))
        self.assertEqual(result["target_word_count"], 183)
        self.assertEqual(result["target_expression_count"], 190)
        self.assertEqual(
            result["input_manifest_sha256"], self.loaded_manifest.file_sha256
        )
        self.assertEqual(
            result["candidate_projection_sha256"],
            migration.EXPECTED_CANDIDATE_PROJECTION_SHA256,
        )
        self.assertEqual(
            result["second_run"]["message"], "이미 적용됨 — 변경 0"
        )
        self.assertEqual(
            migration.sha256_file(self.applied_result),
            migration.sha256_bytes(self.applied_result.read_bytes()),
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
