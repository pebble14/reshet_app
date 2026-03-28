# relation_default_pilot_status

## 현재 상태
- 브랜치: `feature/relation-default-pilot-review`
- 상태: 파일럿 조사 완료, 정책 미확정으로 보류
- 목적: `WORD_RELATION` 기본값 관계(`unspecified/related/unknown`) 일부를 표본 조사해, 검증 가능한 분류 기준과 수동 검토 절차를 만드는 것

## 왜 지금 main에 머지하지 않는가
- relation policy가 아직 확정되지 않았다.
- `direction_code`는 보수적으로 다뤄야 하고, 일부 행은 근거가 있어도 정책 승인 전 자동 반영이 위험하다.
- mixed case, phrase linkage, proper noun/renaming 케이스는 현재 코드 체계에 바로 넣기 어렵다.
- 이번 브랜치는 개발 완료본이 아니라 조사/보류 브랜치로 유지하는 편이 안전하다.

## 현재 산출물
- `docs/relation_default_pilot_review_table.md`
- `docs/draft_update_word_relation_pilot.sql`
- `docs/relation_default_pilot_manual_checklist.md`

## 재개 시 먼저 볼 파일 순서
1. `docs/relation_default_pilot_status.md`
2. `docs/relation_default_pilot_review_table.md`
3. `docs/draft_update_word_relation_pilot.sql`
4. `docs/relation_default_pilot_manual_checklist.md`

## 재개 전에 선행되어야 할 조건
- relation policy 우선 확정 후 재개
- `direction_code` 적용 기준을 명시적으로 합의
- proper noun, renaming, phrase linkage, mixed case의 예외 처리 기준 정리
- SQL 초안은 실행 전 재검토를 전제로 유지

## 재개 시 먼저 할 일
- relation policy 우선 확정
- SQL 포함 15건 재검토
- 중간 confidence 3건 재판단
- mixed/phrase/proper noun 예외 정책 결정

## 사람이 먼저 검토할 핵심 항목 5개
1. SQL 포함 15건의 `direction_code`와 `direction_basis`가 실제 row order와 맞는지 검증
2. 중간 confidence 3건(`5`, `10`, `7482`)을 실행 후보로 둘지 재판단
3. `97`의 보류 유지가 맞는지, Latin lemma 직접 근거를 닫을 수 있는지 확인
4. `7480`을 `variant`로 볼지, renaming 계열로 분리할지 정책 결정
5. `5368`, `7543` 같은 mixed/phrase 케이스를 현재 relation policy 밖으로 계속 둘지 결정

## 지금 하지 않는 것
- `main` 머지
- DB 수정
- SQL 실행
- 전수 확장

## 메모
- 이 브랜치는 보류 상태를 안전하게 유지하기 위한 조사 브랜치다.
- 기존 산출물은 유지하고, 정책이 정해진 뒤에만 후속 판단을 이어간다.
