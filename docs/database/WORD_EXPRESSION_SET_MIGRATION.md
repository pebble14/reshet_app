# WORD_EXPRESSION_SET Migration

## 목적

이 문서는 `word_expression_set` migration 실행 절차와 검증 기준을 정리한다.

현재 원칙:

- migration은 앱 시작 시 자동 실행하지 않는다.
- migration은 명시적 SQL 스크립트로만 실행한다.
- `lib/` 아래 Dart 코드는 이번 단계에서 수정하지 않는다.
- canonical read/write 규칙을 그대로 backfill 규칙으로 사용한다.

---

## semantic compare 기준

`word_expression_set.id`는 surrogate key이므로 semantic compare에 포함하지 않는다.

의미 비교 기준 컬럼:

- `word_id`
- `seq`
- `is_representative`
- `spelling`
- `transliteration`
- `pronunciation`

해석 원칙:

- `(word_id, seq)`를 사실상 natural identity로 본다.
- `seq`는 legacy slot 번호가 아니라 canonical compacting 순서다.
- 대표 세트는 항상 `seq = 1`이다.

---

## 실행 순서

1. 앱 종료
2. `data/reshet_work.db` 백업 생성
3. 백업 파일 실생성 확인
4. `001_create_word_expression_set.sql` 실행
5. `002_precheck_word_expression_set_empty.sql` 실행
6. `existing_row_count = 0` 확인
7. `precheck_status = ok_to_backfill` 확인
8. `003_backfill_word_expression_set.sql` 실행
9. `004_verify_word_expression_set.sql` 실행
10. `005_export_word_expression_set_exceptions.sql` 결과를 CSV로 저장
11. 샘플 단어 수동 검증
12. 결과 기록 저장

중단 조건:

- 백업 파일이 실제로 생성되지 않음
- precheck에서 `existing_row_count <> 0`
- precheck에서 `precheck_status = stop_already_populated`
- verify 실패
- semantic diff 불일치
- 샘플 수동 검증 실패

---

## precheck 규칙

backfill 실행 전 `word_expression_set`는 반드시 비어 있어야 한다.

판정 기준:

- `existing_row_count = 0` 이면 진행 가능
- `existing_row_count > 0` 이면 backfill 재실행 금지

이 규칙은 중복 적재 방지를 위한 필수 조건이다.

---

## exception report

포맷:

- CSV

저장 경로:

- `data/backups/migration_reports/`

파일명 규칙:

- `word_expression_set_exceptions_<YYYYMMDDTHHMMSS>.csv`

컬럼:

- `word_id`
- `source_slot`
- `raw_spelling`
- `raw_transliteration`
- `raw_pronunciation`
- `issue_code`
- `resolution`

운영 절차:

1. migration 실행 직후 실행자가 CSV를 생성한다.
2. 실행자가 CSV row 수와 expected issue count 일치 여부를 먼저 확인한다.
3. 사용자 검토 후 read source 전환 전까지 파일을 보관한다.

---

## verify 최소 기록 포맷

저장 경로:

- `data/backups/migration_reports/`

파일명 규칙:

- `word_expression_set_verify_<YYYYMMDDTHHMMSS>.md`

최소 기록 항목:

- 실행 시각
- backup 파일명
- 실행한 SQL 파일 목록
- precheck 결과
- expected row count
- actual row count
- expected issue count
- actual issue count
- semantic diff 결과
- 샘플 수동 확인 통과 여부
- rollback 필요 여부

`actual issue count`는 exception CSV 실제 row 수를 기준으로 기록한다.

---

## 수동 검증 샘플

- 1세트: `E0000_0001`
- 2세트: `E0000_0010`
- 일부 누락: `E0000_0056`
- 일부 누락: `E0000_0076`
- issue-only 포함: `G0185_0000`
- issue-only 포함: `H0000_0024`
- issue-only 포함: `H0896_0000`
- 최대 6세트: `G4572_0000`

---

## rollback

1차 rollback:

- `006_rollback_word_expression_set.sql` 실행

2차 rollback:

- 앱 종료
- 백업 파일로 `data/reshet_work.db` 복원

rollback 실행 조건:

- verify 실패
- semantic diff 불일치
- exception CSV row 수 불일치
- 샘플 수동 검증 실패
