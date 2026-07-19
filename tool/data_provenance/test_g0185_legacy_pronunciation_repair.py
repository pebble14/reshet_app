from __future__ import annotations

import copy
import json
import shutil
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

import g0185_legacy_pronunciation_repair as repair


class G0185LegacyPronunciationRepairTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.root = Path(__file__).resolve().parents[2]
        cls.tool_dir = Path(__file__).resolve().parent
        cls.manifest = cls.tool_dir / "manifests" / f"{repair.REPAIR_ID}.json"
        cls.source_manifest = cls.tool_dir / "manifests" / "strong_sources.json"
        cls.source_xml = cls.tool_dir / ".source_cache" / "strongsgreek.xml"
        cls.active_work = cls.root / "data" / "reshet_work.db"
        cls.active_seed = cls.root / "data" / "reshet_seed.db"

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.temp_root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _set_legacy_value(self, path: Path, value: str | None) -> None:
        with closing(sqlite3.connect(path)) as connection:
            cursor = connection.execute(
                'UPDATE WORD_TABLE SET "발음2"=? WHERE id=?',
                (value, repair.TARGET_ID),
            )
            self.assertEqual(cursor.rowcount, 1)
            connection.commit()

    def _make_preapply_pair(self) -> tuple[Path, Path]:
        work = self.temp_root / "work.db"
        seed = self.temp_root / "seed.db"
        shutil.copy2(self.active_work, work)
        shutil.copy2(self.active_seed, seed)
        for path in (work, seed):
            with closing(sqlite3.connect(path)) as connection:
                value = connection.execute(
                    'SELECT "발음2" FROM WORD_TABLE WHERE id=?',
                    (repair.TARGET_ID,),
                ).fetchone()[0]
            if value is None:
                self._set_legacy_value(path, repair.EXPECTED_CURRENT_VALUE)
            else:
                self.assertEqual(value, repair.EXPECTED_CURRENT_VALUE)
        repair.assert_no_sidecars((work, seed))
        return work, seed

    def _apply_fixture(
        self,
        work: Path,
        seed: Path,
        *,
        result_name: str = "result.json",
        fault_injection: str | None = None,
    ) -> tuple[dict[str, object], Path, Path]:
        result = self.temp_root / result_name
        backup_root = self.temp_root / "backups"
        report = repair.run_apply(
            manifest_path=self.manifest,
            work_db=work,
            seed_db=seed,
            backup_root=backup_root,
            result_output=result,
            confirm=True,
            source_manifest_path=self.source_manifest,
            source_xml_path=self.source_xml,
            enforce_initial_hashes=False,
            fault_injection=fault_injection,
        )
        return report, result, backup_root

    def _load_result(self, result: Path) -> dict[str, object]:
        value = json.loads(result.read_text(encoding="utf-8"))
        self.assertIsInstance(value, dict)
        return value

    def test_manifest_source_hash_and_target_identity_are_verified(self) -> None:
        manifest = repair.load_manifest(self.manifest)
        source = repair.verify_source_boundary(
            self.source_manifest, self.source_xml, manifest
        )
        self.assertEqual(manifest["target"]["id"], repair.TARGET_ID)
        self.assertEqual(
            manifest["candidate_projection_sha256"],
            "0b3f8240493528aa01d02e71517d66e06e691120a0616c8488e94b302f2bdce7",
        )
        self.assertEqual(source["sha256"], repair.EXPECTED_SOURCE["sha256"])
        self.assertEqual(source["evidence"], manifest["source_evidence"])

    def test_active_database_postflight_is_read_only(self) -> None:
        report = repair.run_dry_run(
            manifest_path=self.manifest,
            work_db=self.active_work,
            seed_db=self.active_seed,
            source_manifest_path=self.source_manifest,
            source_xml_path=self.source_xml,
        )
        result_artifact = (
            self.tool_dir
            / "migrations"
            / f"{repair.REPAIR_ID}_result.json"
        )
        if report["state"] == "current" and not result_artifact.exists():
            self.skipTest("active DB apply 전 preflight 상태")
        self.assertEqual(report["state"], "target")
        self.assertEqual(report["planned_change_count"], 0)
        self.assertEqual(
            report["database_sha256_before"], report["database_sha256_after"]
        )
        self.assertEqual(report["sidecar_count"], 0)

    def test_fixture_removes_exactly_pronunciation2(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result_path, _ = self._apply_fixture(work, seed)
        result = self._load_result(result_path)
        expected = [
            {"column": repair.LEGACY_COLUMN, "from": "G2767", "to": None}
        ]
        self.assertEqual(result["work"]["logical_diff"], expected)
        self.assertEqual(result["seed"]["logical_diff"], expected)
        self.assertEqual(result["change_counts"]["total_database_rows"], 2)

    def test_normalized_expression_is_unchanged(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result_path, _ = self._apply_fixture(work, seed)
        result = self._load_result(result_path)
        for label in ("work", "seed"):
            values = result[label]["protection"]["expression_table_sha256"]
            self.assertEqual(values["pre"], values["post"])

    def test_meaning_relation_and_history_are_unchanged(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result_path, _ = self._apply_fixture(work, seed)
        result = self._load_result(result_path)
        for label in ("work", "seed"):
            for key in (
                "meaning_table_sha256",
                "relation_table_sha256",
                "history_table_sha256",
            ):
                values = result[label]["protection"][key]
                self.assertEqual(values["pre"], values["post"])

    def test_non_target_words_and_target_other_columns_are_unchanged(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result_path, _ = self._apply_fixture(work, seed)
        result = self._load_result(result_path)
        for label in ("work", "seed"):
            for key in ("non_target_word_sha256", "target_immutable_sha256"):
                values = result[label]["protection"][key]
                self.assertEqual(values["pre"], values["post"])

    def test_work_seed_state_mismatch_is_fail_closed_before_backup(self) -> None:
        work, seed = self._make_preapply_pair()
        self._set_legacy_value(seed, None)
        result = self.temp_root / "result.json"
        backup_root = self.temp_root / "backups"
        with self.assertRaisesRegex(repair.RepairError, "적용 상태 불일치"):
            repair.run_apply(
                manifest_path=self.manifest,
                work_db=work,
                seed_db=seed,
                backup_root=backup_root,
                result_output=result,
                confirm=True,
                source_manifest_path=self.source_manifest,
                source_xml_path=self.source_xml,
                enforce_initial_hashes=False,
            )
        self.assertFalse(backup_root.exists())
        self.assertFalse(result.exists())

    def test_source_context_mismatch_is_fail_closed(self) -> None:
        manifest = repair.load_manifest(self.manifest)
        mismatched = copy.deepcopy(manifest)
        mismatched["source_evidence"]["derivation_references"] = [
            {"language": "GREEK", "strong_number": "G0001"}
        ]
        with self.assertRaisesRegex(repair.RepairError, "source XML context 불일치"):
            repair.verify_source_boundary(
                self.source_manifest, self.source_xml, mismatched
            )

    def test_current_value_mismatch_is_fail_closed(self) -> None:
        work, seed = self._make_preapply_pair()
        self._set_legacy_value(work, "unexpected")
        self._set_legacy_value(seed, "unexpected")
        with self.assertRaisesRegex(repair.RepairError, "current value mismatch"):
            repair.run_dry_run(
                manifest_path=self.manifest,
                work_db=work,
                seed_db=seed,
                source_manifest_path=self.source_manifest,
                source_xml_path=self.source_xml,
                enforce_initial_hashes=False,
            )

    def test_update_rowcount_mismatch_rolls_back_and_restores(self) -> None:
        work, seed = self._make_preapply_pair()
        before = {"work": repair.sha256_file(work), "seed": repair.sha256_file(seed)}
        result = self.temp_root / "result.json"
        backup_root = self.temp_root / "backups"
        with self.assertRaisesRegex(repair.RepairError, "backup restore 성공"):
            repair.run_apply(
                manifest_path=self.manifest,
                work_db=work,
                seed_db=seed,
                backup_root=backup_root,
                result_output=result,
                confirm=True,
                source_manifest_path=self.source_manifest,
                source_xml_path=self.source_xml,
                enforce_initial_hashes=False,
                fault_injection="seed_rowcount_mismatch",
            )
        self.assertEqual(repair.sha256_file(work), before["work"])
        self.assertEqual(repair.sha256_file(seed), before["seed"])
        self.assertFalse(result.exists())
        repair.assert_no_sidecars((work, seed))

    def test_second_run_is_noop_without_backup_or_transaction(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result, backup_root = self._apply_fixture(work, seed)
        result_sha = repair.sha256_file(result)
        database_hashes = {"work": repair.sha256_file(work), "seed": repair.sha256_file(seed)}
        backup_directories = sorted(path.name for path in backup_root.iterdir())
        second = repair.run_apply(
            manifest_path=self.manifest,
            work_db=work,
            seed_db=seed,
            backup_root=backup_root,
            result_output=result,
            confirm=True,
            source_manifest_path=self.source_manifest,
            source_xml_path=self.source_xml,
            enforce_initial_hashes=False,
        )
        self.assertEqual(second["change_count"], 0)
        self.assertFalse(second["backup_created"])
        self.assertFalse(second["transaction_started"])
        self.assertTrue(second["result_unchanged"])
        self.assertEqual(repair.sha256_file(result), result_sha)
        self.assertEqual(repair.sha256_file(work), database_hashes["work"])
        self.assertEqual(repair.sha256_file(seed), database_hashes["seed"])
        self.assertEqual(
            sorted(path.name for path in backup_root.iterdir()), backup_directories
        )

    def test_result_artifact_has_deterministic_canonical_bytes(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result_path, _ = self._apply_fixture(work, seed)
        payload = self._load_result(result_path)
        self.assertEqual(result_path.read_bytes(), repair.canonical_json_bytes(payload))
        self.assertEqual(
            payload["candidate_projection_sha256"],
            "0b3f8240493528aa01d02e71517d66e06e691120a0616c8488e94b302f2bdce7",
        )

    def test_g0025_note_difference_is_not_a_parity_blocker(self) -> None:
        work, seed = self._make_preapply_pair()
        report = repair.run_dry_run(
            manifest_path=self.manifest,
            work_db=work,
            seed_db=seed,
            source_manifest_path=self.source_manifest,
            source_xml_path=self.source_xml,
            enforce_initial_hashes=False,
        )
        self.assertTrue(report["parity"]["exact"])
        self.assertTrue(report["parity"]["g0025_note_difference_allowed"])
        self.assertEqual(report["work"]["snapshot"]["g0025_note"], "48-B3 백업 시점")
        self.assertIsNone(report["seed"]["snapshot"]["g0025_note"])

    def test_g0025_note_is_unchanged_by_apply(self) -> None:
        work, seed = self._make_preapply_pair()
        _, result_path, _ = self._apply_fixture(work, seed)
        result = self._load_result(result_path)
        for label in ("work", "seed"):
            values = result[label]["protection"]["g0025_sha256"]
            self.assertEqual(values["pre"], values["post"])

    def test_apply_requires_explicit_confirmation(self) -> None:
        work, seed = self._make_preapply_pair()
        with self.assertRaisesRegex(repair.RepairError, "confirmation flag"):
            repair.run_apply(
                manifest_path=self.manifest,
                work_db=work,
                seed_db=seed,
                backup_root=self.temp_root / "backups",
                result_output=self.temp_root / "result.json",
                confirm=False,
                source_manifest_path=self.source_manifest,
                source_xml_path=self.source_xml,
                enforce_initial_hashes=False,
            )


if __name__ == "__main__":
    unittest.main()
