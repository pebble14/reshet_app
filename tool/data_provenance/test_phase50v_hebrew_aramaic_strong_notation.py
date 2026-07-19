from __future__ import annotations

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
import unittest


TOOL_DIR = Path(__file__).resolve().parent
ROOT_DIR = TOOL_DIR.parent.parent
sys.path.insert(0, str(TOOL_DIR))

import phase50v_hebrew_aramaic_strong_notation as migration


MANIFEST = migration.DEFAULT_MANIFEST
ACTIVE_WORK = migration.DEFAULT_WORK_DB
ACTIVE_SEED = migration.DEFAULT_SEED_DB


class Phase50VHebrewAramaicStrongNotationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.loaded = migration.load_input_manifest(MANIFEST)

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="phase50v_test_")
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _copy_databases(self) -> tuple[Path, Path]:
        work = self.root / "reshet_work.db"
        seed = self.root / "reshet_seed.db"
        shutil.copy2(ACTIVE_WORK, work)
        shutil.copy2(ACTIVE_SEED, seed)
        return work, seed

    def _prepare_pre_apply_fixture(self, paths: tuple[Path, Path]) -> None:
        identities = [target.identity for target in self.loaded.targets]
        for path in paths:
            connection = sqlite3.connect(path)
            try:
                connection.executemany(
                    "UPDATE word_expression_set "
                    "SET pronunciation_notation='unknown' "
                    "WHERE word_id=? AND seq=? "
                    "AND pronunciation_notation='strong_dictionary'",
                    identities,
                )
                connection.commit()
            finally:
                connection.close()

    def _mutate_expression(
        self,
        paths: tuple[Path, ...],
        sql_fragment: str,
        parameters: tuple[object, ...],
    ) -> None:
        target = self.loaded.targets[0]
        for path in paths:
            connection = sqlite3.connect(path)
            try:
                connection.execute(
                    f"UPDATE word_expression_set SET {sql_fragment} "
                    "WHERE word_id=? AND seq=?",
                    (*parameters, *target.identity),
                )
                connection.commit()
            finally:
                connection.close()

    def test_source_hash_direct_child_parser_and_nested_reference_exclusion(self) -> None:
        info, source = migration.verify_source_boundary()
        self.assertEqual(info["source_xml_sha256"], migration.EXPECTED_SOURCE["sha256"])
        self.assertEqual(info["entry_count"], 8674)
        self.assertEqual(info["direct_w_count"], 8674)
        self.assertEqual(info["nested_w_excluded_count"], 9110)
        self.assertEqual(source.entries["H0001"].primary_pronunciation, "awb")

        fixture = self.root / "HebrewStrong.xml"
        fixture.write_text(
            "<lexicon><entry id=\"H1\"><w pron=\"direct\">lemma</w>"
            "<definition><w pron=\"nested\">reference</w></definition>"
            "</entry></lexicon>",
            encoding="utf-8",
        )
        parsed = migration.parse_hebrew_source(fixture, expected_entry_count=1)
        self.assertEqual(parsed.entries["H0001"].primary_pronunciation, "direct")
        self.assertEqual(parsed.direct_w_count, 1)
        self.assertEqual(parsed.nested_w_excluded_count, 1)

    def test_manifest_schema_counts_relation_and_projection_contract(self) -> None:
        loaded = self.loaded
        self.assertEqual(loaded.payload["phase"], "50-V")
        self.assertEqual(len(loaded.targets), 771)
        self.assertEqual(len({target.word_id for target in loaded.targets}), 738)
        self.assertEqual(
            loaded.payload["language_counts"],
            {
                "히브리어": {"word_count": 698, "expression_count": 730},
                "아람어": {"word_count": 40, "expression_count": 41},
            },
        )
        historical = [
            target for target in loaded.targets if target.historical_phase50s_member
        ]
        xml_only = [
            target for target in loaded.targets if not target.historical_phase50s_member
        ]
        self.assertEqual(len(historical), 756)
        self.assertEqual(len(xml_only), 15)
        self.assertEqual(
            {target.identity for target in xml_only}, set(migration.XML_ONLY)
        )
        reasons: dict[str, int] = {}
        for target in xml_only:
            self.assertIsNotNone(target.historical_source_difference)
            reason = str(target.xml_only_reason)
            reasons[reason] = reasons.get(reason, 0) + 1
        self.assertEqual(
            reasons,
            {
                "dat_language_marker_difference": 13,
                "xml_dat_pronunciation_difference": 2,
            },
        )

    def test_manifest_is_deterministic_and_matches_checked_in_bytes(self) -> None:
        rebuilt = migration.build_manifest_payload()
        self.assertEqual(rebuilt, self.loaded.payload)
        self.assertEqual(MANIFEST.read_bytes(), migration.canonical_json_bytes(rebuilt))
        self.assertEqual(
            rebuilt["candidate_projection_sha256"],
            self.loaded.candidate_projection_sha256,
        )

    def test_manifest_tamper_is_fail_closed(self) -> None:
        payload = deepcopy(self.loaded.payload)
        payload["targets"][0]["expected_current_pronunciation"] = "tampered"
        path = self.root / "tampered.json"
        path.write_bytes(migration.canonical_json_bytes(payload))
        with self.assertRaisesRegex(migration.MigrationError, "manifest file SHA"):
            migration.load_input_manifest(path)

    def test_active_postflight_is_read_only_and_matches_all_counts(self) -> None:
        before = {
            "work": migration.sha256_file(ACTIVE_WORK),
            "seed": migration.sha256_file(ACTIVE_SEED),
        }
        report = migration.run_dry_run()
        self.assertEqual(report["status"], "이미 적용됨 — 변경 0")
        self.assertEqual(report["database_sha256_before"], before)
        self.assertEqual(report["database_sha256_after"], before)
        self.assertEqual(report["first_run_expected_change_count"], 0)
        self.assertEqual(report["second_run_expected_change_count"], 0)
        self.assertEqual(report["metadata_outside_expected_change_count"], 0)
        self.assertTrue(report["parity"]["exact"])
        for label in ("work", "seed"):
            snapshot = report[label]
            self.assertEqual(snapshot["target_word_count"], 738)
            self.assertEqual(snapshot["target_expression_count"], 771)
            self.assertEqual(
                snapshot["target_notation_counts"], {"strong_dictionary": 771}
            )
            self.assertEqual(snapshot["normalized_legacy_diff_count"], 0)
            self.assertEqual(snapshot["source_exact_diff_count"], 0)
            self.assertEqual(snapshot["pronunciation_null_count"], 0)
            self.assertEqual(snapshot["notation_name_non_null_count"], 0)
            self.assertEqual(snapshot["legacy_mixed_label_intersection_count"], 0)
            self.assertEqual(snapshot["greek_phase50r_auto_intersection_count"], 0)
            self.assertEqual(snapshot["greek_phase50t_intersection_count"], 0)
            self.assertEqual(snapshot["greek_e4_e5_intersection_count"], 0)
        migration.assert_no_sidecars((ACTIVE_WORK, ACTIVE_SEED))

    def test_current_pronunciation_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        self._mutate_expression((work, seed), "pronunciation=?", ("mismatch",))
        with self.assertRaisesRegex(migration.MigrationError, "pronunciation.*mismatch"):
            migration.run_dry_run(MANIFEST, work, seed)

    def test_legacy_pronunciation_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        target = self.loaded.targets[0]
        for path in (work, seed):
            connection = sqlite3.connect(path)
            try:
                connection.execute(
                    f'UPDATE WORD_TABLE SET "발음{target.seq}"=? WHERE id=?',
                    ("legacy mismatch", target.word_id),
                )
                connection.commit()
            finally:
                connection.close()
        with self.assertRaisesRegex(migration.MigrationError, "legacy pronunciation"):
            migration.run_dry_run(MANIFEST, work, seed)

    def test_notation_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        self._mutate_expression(
            (work, seed), "pronunciation_notation=?", ("ipa_phonemic",)
        )
        with self.assertRaisesRegex(migration.MigrationError, "notation"):
            migration.run_dry_run(MANIFEST, work, seed)

    def test_notation_name_non_null_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        self._mutate_expression(
            (work, seed), "pronunciation_notation_name=?", ("unexpected",)
        )
        with self.assertRaisesRegex(migration.MigrationError, "notation_name"):
            migration.run_dry_run(MANIFEST, work, seed)

    def test_work_seed_projection_mismatch_is_fail_closed(self) -> None:
        work, seed = self._copy_databases()
        self._mutate_expression((work,), "spelling=?", ("work-only mismatch",))
        with self.assertRaisesRegex(
            migration.MigrationError, "work·seed projection parity"
        ):
            migration.run_dry_run(MANIFEST, work, seed)

    def test_greek_phase50r_and_phase50t_identity_sets_are_disjoint(self) -> None:
        targets = {target.identity for target in self.loaded.targets}
        self.assertTrue(
            all(target.strong_number.startswith("H") for target in self.loaded.targets)
        )
        phase50r_path = (
            TOOL_DIR / ".source_cache" / "phase50r" / "greek_auto_plan.jsonl"
        )
        phase50r = {
            (row["word_id"], int(row["db_seq"]))
            for row in (
                json.loads(line)
                for line in phase50r_path.read_text(encoding="utf-8").splitlines()
                if line
            )
        }
        phase50t_payload = json.loads(
            (
                TOOL_DIR
                / "manifests"
                / "phase50t_greek_legacy_strong_notation.json"
            ).read_text(encoding="utf-8")
        )
        phase50t = {
            (row["word_id"], int(row["seq"])) for row in phase50t_payload["targets"]
        }
        self.assertFalse(targets & phase50r)
        self.assertFalse(targets & phase50t)

    def test_apply_on_temporary_copies_changes_only_metadata_and_second_run_is_noop(self) -> None:
        work, seed = self._copy_databases()
        self._prepare_pre_apply_fixture((work, seed))
        before_work = migration._load_database(work)
        before_seed = migration._load_database(seed)
        result = migration.run_apply(
            MANIFEST,
            work,
            seed,
            self.root / "backups",
            self.root / "result.json",
        )
        self.assertEqual(result["work_change_count"], 771)
        self.assertEqual(result["seed_change_count"], 771)
        self.assertEqual(
            result["columns_changed"],
            ["word_expression_set.pronunciation_notation"],
        )
        self.assertEqual(result["metadata_outside_change_count"], 0)
        after_work = migration._load_database(work)
        after_seed = migration._load_database(seed)
        for before, after in (
            (before_work, after_work),
            (before_seed, after_seed),
        ):
            self.assertEqual(before["schema_sha256"], after["schema_sha256"])
            self.assertEqual(before["word_table_sha256"], after["word_table_sha256"])
            before_rows = {
                (row["word_id"], row["seq"]): row for row in before["rows"]
            }
            after_rows = {
                (row["word_id"], row["seq"]): row for row in after["rows"]
            }
            self.assertEqual(set(before_rows), set(after_rows))
            notation_changes = 0
            for identity, old in before_rows.items():
                new = after_rows[identity]
                for field in old:
                    if field == "pronunciation_notation":
                        if old[field] != new[field]:
                            notation_changes += 1
                            self.assertEqual(old[field], "unknown")
                            self.assertEqual(new[field], "strong_dictionary")
                    else:
                        self.assertEqual(old[field], new[field], (identity, field))
            self.assertEqual(notation_changes, 771)

        before_second = {
            "work": migration.sha256_file(work),
            "seed": migration.sha256_file(seed),
            "result": migration.sha256_file(self.root / "result.json"),
        }
        second = migration.run_apply(
            MANIFEST,
            work,
            seed,
            self.root / "unused-second-run-backups",
            self.root / "result.json",
        )
        self.assertEqual(second["status"], "이미 적용됨 — 변경 0")
        self.assertEqual(second["change_count"], 0)
        self.assertFalse(second["backup_created"])
        self.assertFalse(second["transaction_started"])
        self.assertEqual(migration.sha256_file(work), before_second["work"])
        self.assertEqual(migration.sha256_file(seed), before_second["seed"])
        self.assertEqual(
            migration.sha256_file(self.root / "result.json"),
            before_second["result"],
        )


if __name__ == "__main__":
    unittest.main()
