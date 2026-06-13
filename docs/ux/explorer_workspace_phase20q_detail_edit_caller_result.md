# ExplorerWorkspace Phase 20-Q detail edit caller result

## 문서 역할

이 문서는 Phase 20-Q 구현과 검증을 기록하는 `migration/history` 및 `changelog/status` 문서다. 현재 active authority는 `docs/ux/explorer_workspace_unification.md`의 Phase 20-Q active boundary다.

## 목적

large-screen embedded Explorer가 `상세 작업 화면 열기`로 연 full-detail `WordDetailScreen`에서 `편집`을 실행할 때, detail route가 edit route를 직접 열지 않고 typed result를 caller에 반환하도록 분기한다.

```dart
WordDetailEditRequestedResult(wordId: _wordId)
```

`WordExplorerScreen`은 이 result를 받아 새 edit flow를 만들지 않고 기존 `_openEditSelectedWord()`를 재사용한다.

## 변경 전 책임 경계

- 기본/small-screen/`HomeScreen` detail edit:
  - `WordDetailScreen._openEdit()`이 detail 전용 edit seed를 읽는다.
  - `WordDetailScreen`이 `WordEditScreen.fromSeed(...)`를 직접 연다.
  - 저장 성공 후 detail local reread와 local snackbar를 수행한다.
- Explorer direct edit:
  - `WordExplorerScreen._openEditSelectedWord()`가 Explorer 전용 edit seed를 읽는다.
  - 저장 성공 후 selected detail을 refresh한다.
  - center word와 동일하면 center display seed를 동기화한다.
  - 표시 변경 시 graph revision을 증가시킨다.
  - 현재 history snapshot을 replace하고 Explorer context snackbar를 표시한다.
- Embedded full-detail route의 edit도 변경 전에는 기본 detail local edit 경로를 사용했다.

## 변경 후 책임 경계

- `WordDetailRouteResult`에 `WordDetailEditRequestedResult`를 추가한다.
- `WordDetailScreen`에 `WordDetailEditActionMode`를 추가한다.
- 기본 mode는 `localRoute`로 유지한다.
- large-screen embedded Explorer가 여는 full-detail route만 `returnToCaller`를 전달한다.
- `returnToCaller` mode의 `_openEdit()`은 detail edit seed를 읽기 전에 typed result를 반환한다.
- `WordExplorerScreen._openSelectedWordDetail()`은 edit result를 받으면 `_openEditSelectedWord()`를 호출하고 즉시 반환한다.
- edit result 처리 후 일반/null 복귀용 `_refreshSelectedWord(...)`를 추가 실행하지 않는다.

## 유지되는 경로

- 기본/small-screen/`HomeScreen` detail edit local route
- detail 전용 edit seed read
- `WordEditScreen.fromSeed(...)`
- detail local reread와 local snackbar
- Explorer direct edit의 Explorer 전용 edit seed와 저장 후 refresh 정책
- `WordDetailDeletedResult`와 delete 처리
- `_confirmDelete()`
- `WordDetailGraphRequestedResult`와 embedded graph center retarget
- 기본 standalone graph route
- 일반/null full-detail 복귀 refresh

## 금지 사항

- delete flow와 `_confirmDelete()` 변경 금지
- graph action 및 typed graph result 의미 변경 금지
- small-screen/`HomeScreen` 기본 detail route 변경 금지
- `WordEditScreen`, `WordInfoPanel` 변경 금지
- 새 edit flow 또는 repository method 추가 금지
- DB schema/API/repository/domain/dependency 변경 금지
- 실데이터를 수정·삭제 UI 테스트 대상으로 사용하는 것 금지
- 테스트 데이터, 작업 DB, DB 백업 파일 커밋 금지

## 테스트 데이터 보호 정책

- UI 검색어는 `PHASE20Q`로 통일한다.
- Codex가 `reshet_work.db` 백업을 먼저 생성한다.
- 기존 write path인 `WordWriteService -> WordRepository.createWord()`로 테스트 전용 단어를 생성한다.
- 관계 포함 삭제 테스트 데이터는 생성하지 않는다.
- 클라이언트는 다음 데이터만 사용한다.
  - `PHASE20Q_EDIT_TARGET`: edit 저장/취소와 small-screen 기본 detail edit 확인
  - `PHASE20Q_DELETE_TARGET`: delete 기존 동작 확인
  - `PHASE20Q_GRAPH_TARGET`: graph action 기존 동작 확인
- UI 테스트 전에는 테스트 데이터를 유지한다.
- UI 테스트 완료 후 테스트 데이터 삭제 또는 백업 복구를 수행하고 `PHASE20Q` 조회 0건과 DB clean 상태를 확인한다.
- 테스트 데이터 정리와 DB clean 확인 전에는 커밋하지 않는다.

## 명령어 기반 테스트

### 신규 guardrail

```text
flutter test test/ui/explorer_workspace_phase20q_detail_edit_request_result_guardrail_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+7`
- `All tests passed!`

검증 항목:

- typed edit request result와 `wordId`
- 기본 `localRoute` mode
- caller mode에서 detail edit seed read 전 typed result 반환
- Explorer full-detail route만 caller mode 사용
- 기존 `_openEditSelectedWord()` 재사용
- delete, edit, graph, 일반/null refresh 분기 순서
- 기존 delete와 graph action contract 유지

### 추가 명령어 기반 검증

```text
flutter test \
  test/ui/explorer_workspace_phase20q_detail_edit_request_result_guardrail_test.dart \
  test/ui/explorer_workspace_phase20o_detail_graph_request_result_guardrail_test.dart \
  test/ui/explorer_workspace_phase20n_typed_detail_route_result_guardrail_test.dart \
  test/ui/explorer_workspace_phase20m_embedded_detail_action_clarity_guardrail_test.dart \
  --reporter expanded
```

실제 결과:

- 통과
- `+23`
- `All tests passed!`

```text
flutter analyze \
  lib/ui/word_detail_route_result.dart \
  lib/ui/word_detail_screen.dart \
  lib/ui/word_explorer_screen.dart \
  test/ui/explorer_workspace_phase20q_detail_edit_request_result_guardrail_test.dart
```

실제 결과:

- exit code `0`
- `No issues found!`

```text
flutter test --reporter compact
```

실제 결과:

- 통과
- `+376`
- `All tests passed!`
- PHASE20Q 테스트 데이터 생성 전과 생성 후 각각 실행했으며 두 실행 모두 같은 결과로 통과

```text
flutter analyze
```

실제 결과:

- exit code `1`
- 기존 기준과 같은 `47 issues found`
- 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` error 13건 포함
- Phase 20-Q 변경 파일 대상 신규 진단 없음

`git diff --check`는 whitespace 오류 없이 통과했다. 필수 검색에서 `WordDetailEditRequestedResult`, `WordDetailEditActionMode`, Explorer caller mode와 edit/delete/graph result 분기를 확인했다.

## DB 테스트 데이터 준비 결과

### 백업

- repo 외부 백업 경로:
  - `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_db_backups/reshet_work_phase20q_before_ui_20260614_000542.db`
- 백업 직후 원본과 백업 SHA-256:
  - `C2E145404B8017F0E919C07CDCC9DEE48FAF2B2248F67DBC5AEC8A4B9C4CDD03`
- 백업 생성 후 `git status --short --branch`에 DB 또는 백업 파일이 나타나지 않음을 확인했다.
- `data/reshet_work.db`, `data/reshet_seed.db`는 `.gitignore`의 `*.db` 규칙으로 제외된다.

### 생성 방식

- 기존 write path인 `WordWriteService -> WordRepository.createWord()`를 사용했다.
- SQL 직접 삽입은 수행하지 않았다.
- 임시 준비 runner는 실행 후 삭제했으며 변경 파일 또는 커밋 대상에 남아 있지 않다.
- 관계 포함 삭제 테스트 데이터와 `WORD_RELATION` 행은 생성하지 않았다.

### 실제 schema 확인 SQL

```sql
SELECT name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;

PRAGMA table_info(WORD_TABLE);
PRAGMA table_info(word_expression_set);
PRAGMA table_info(WORD_RELATION);
```

필요한 실제 테이블과 컬럼을 확인한 후 기존 write path를 실행했다.

### 생성 및 UI 검색 검증

앱의 실제 `WordRepository.searchWordsMap('PHASE20Q')` 결과:

| word id | 대표 표기 | 대표 음역 | 검색 결과 의미 |
| --- | --- | --- | --- |
| `E0000_0156` | `PHASE20Q_EDIT_TARGET` | `Phase 20-Q edit target` | `Phase 20-Q 수정 테스트 전용 단어` |
| `E0000_0157` | `PHASE20Q_DELETE_TARGET` | `Phase 20-Q delete target` | `Phase 20-Q 삭제 테스트 전용 단어` |
| `E0000_0158` | `PHASE20Q_GRAPH_TARGET` | `Phase 20-Q graph target` | `Phase 20-Q 그래프 동작 확인 전용 단어` |

읽기 전용 SQL:

```sql
SELECT
  wes.word_id,
  wes.spelling,
  wes.transliteration,
  wes.is_representative,
  COUNT(wr.id) AS relation_count
FROM word_expression_set wes
LEFT JOIN WORD_RELATION wr
  ON wr.word_id_1 = wes.word_id
  OR wr.word_id_2 = wes.word_id
WHERE wes.spelling LIKE '%PHASE20Q%'
GROUP BY
  wes.word_id,
  wes.spelling,
  wes.transliteration,
  wes.is_representative
ORDER BY wes.word_id;
```

실제 결과:

| word id | spelling | transliteration | representative | relation count |
| --- | --- | --- | --- | --- |
| `E0000_0156` | `PHASE20Q_EDIT_TARGET` | `Phase 20-Q edit target` | `1` | `0` |
| `E0000_0157` | `PHASE20Q_DELETE_TARGET` | `Phase 20-Q delete target` | `1` | `0` |
| `E0000_0158` | `PHASE20Q_GRAPH_TARGET` | `Phase 20-Q graph target` | `1` | `0` |

추가 확인:

- `SELECT COUNT(*) ... WHERE spelling LIKE '%PHASE20Q%'`: `3`
- `PRAGMA integrity_check`: `ok`
- UI 검색어: `PHASE20Q`

## 클라이언트 UI 테스트 및 DB 정리 결과

- 클라이언트가 아래 Phase 20-Q UI 수동 테스트를 모두 성공 확인했다.
  - large-screen embedded full-detail edit caller result 분기와 저장 후 Explorer refresh
  - large-screen embedded full-detail edit 취소
  - small-screen/`HomeScreen` 기본 detail local edit 보존
  - `PHASE20Q_DELETE_TARGET` 기반 delete 기존 동작 보존
  - `PHASE20Q_GRAPH_TARGET` 기반 embedded graph action 기존 동작 보존
- 앱/Flutter/Dart 관련 프로세스가 없는 상태를 확인한 뒤 외부 백업을 현재 `data/reshet_work.db`로 복원했다.
- 복원에 사용한 백업:
  - `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_db_backups/reshet_work_phase20q_before_ui_20260614_000542.db`
- 백업 DB와 복원 DB SHA-256:
  - `C2E145404B8017F0E919C07CDCC9DEE48FAF2B2248F67DBC5AEC8A4B9C4CDD03`
- 복원 후 사람 식별 가능한 normalized expression 조회:

```sql
SELECT word_id, spelling, transliteration
FROM word_expression_set
WHERE spelling LIKE '%PHASE20Q%'
   OR COALESCE(transliteration, '') LIKE '%PHASE20Q%'
ORDER BY word_id, seq;
```

실제 결과:

- `0 rows`

추가 복구 검증:

- `phase20q_row_count`: `0`
- `PRAGMA integrity_check`: `ok`
- `git status --short --branch`에 DB 또는 백업 파일 없음
- `data/reshet_seed.db` 변경 없음
- 복원된 DB 상태에서 전체 `flutter test --reporter compact`: `+376`, `All tests passed!`
- 복원된 DB 상태에서 전체 `flutter analyze`: 기존 기준과 같은 `47 issues found`
- Phase 20-Q 변경 파일 대상 `flutter analyze`: `No issues found!`

## 클라이언트 UI 기반 수동 테스트 체크리스트

Codex는 UI 테스트를 수행했다고 보고하지 않는다. 아래 모든 수정·삭제 테스트는 Codex가 생성한 `PHASE20Q` 테스트 전용 데이터만 대상으로 한다.

### 시나리오 1: large-screen embedded full-detail edit 분기

- 테스트 목적: full-detail edit action이 caller result로 반환되고 Explorer direct edit 경로를 재사용하는지 확인
- 시작 화면: Windows Desktop large-screen `HomeScreen`의 embedded Explorer
- 조작 순서:
  1. `PHASE20Q`를 검색한다.
  2. `PHASE20Q_EDIT_TARGET`을 Explorer pane에 연다.
  3. 오른쪽 detail pane에서 `상세 작업 화면 열기`를 클릭한다.
  4. 열린 full-detail route에서 `편집`을 클릭한다.
  5. 의미 또는 비고에 `UI_TEST_EDITED`를 추가하고 저장한다.
- 입력할 테스트 데이터: `PHASE20Q_EDIT_TARGET`, `UI_TEST_EDITED`
- 기대되는 화면 변화: full-detail route가 닫힌 뒤 edit 화면이 열리고, 저장 후 Explorer pane으로 복귀하며 selected detail과 필요 시 center/graph가 갱신되고 Explorer context snackbar가 표시됨
- 실패 시 확인할 증상: full-detail 위 edit route 중첩, 저장 후 stale detail/graph, 잘못된 snackbar context, 실데이터 변경
- 테스트 완료 판단 기준: 테스트 전용 단어만 수정되고 Explorer 저장 후 refresh 정책이 확인됨

### 시나리오 2: large-screen embedded full-detail edit 취소

- 테스트 목적: edit 취소 시 Explorer 상태와 데이터가 유지되는지 확인
- 시작 화면: `PHASE20Q_EDIT_TARGET`이 선택된 large-screen embedded Explorer
- 조작 순서: full-detail route에서 `편집`을 클릭하고 edit 화면에서 저장하지 않고 뒤로 이동
- 입력할 테스트 데이터: `PHASE20Q_EDIT_TARGET`
- 기대되는 화면 변화: Explorer pane으로 복귀하고 저장 snackbar 없이 selection과 graph center가 유지됨
- 실패 시 확인할 증상: detail 소실, center/selection/history 변경, 취소했는데 데이터 변경
- 테스트 완료 판단 기준: 테스트 데이터와 Explorer 상태가 취소 전과 동일함

### 시나리오 3: small-screen/Home 기본 detail edit 보존

- 테스트 목적: 기본 detail local edit 경로가 유지되는지 확인
- 시작 화면: Windows Desktop small-screen `HomeScreen`
- 조작 순서:
  1. `PHASE20Q_EDIT_TARGET`을 검색해 detail route를 연다.
  2. `편집`을 클릭한다.
  3. 의미 또는 비고를 테스트용 값으로 수정하고 저장한다.
- 입력할 테스트 데이터: `PHASE20Q_EDIT_TARGET`
- 기대되는 화면 변화: 기존처럼 detail route 위에서 edit route가 열리고 저장 후 같은 detail route 내용이 갱신됨
- 실패 시 확인할 증상: edit 클릭 시 detail route 닫힘, Explorer 전용 흐름 진입, 실데이터 변경
- 테스트 완료 판단 기준: 기본 detail local edit와 reread가 유지됨

### 시나리오 4: delete 기존 동작 보존

- 테스트 목적: Phase 20-Q 변경이 기존 delete 경로에 영향을 주지 않았는지 확인
- 시작 화면: `PHASE20Q_DELETE_TARGET` full-detail route
- 조작 순서: `삭제`를 실행하고 확인 dialog에서 승인
- 입력할 테스트 데이터: `PHASE20Q_DELETE_TARGET`
- 기대되는 화면 변화: 확인 dialog와 기존 snackbar가 표시되고 테스트 단어만 삭제됨
- 실패 시 확인할 증상: 실데이터 삭제, delete 후 center/selection/history 복구 오류, 검색 결과 잔존
- 테스트 완료 판단 기준: `PHASE20Q_DELETE_TARGET`만 삭제되고 기존 delete 정책이 유지됨

### 시나리오 5: graph action 기존 동작 보존

- 테스트 목적: embedded full-detail graph action의 Phase 20-O 경계를 확인
- 시작 화면: `PHASE20Q_GRAPH_TARGET`이 선택된 large-screen embedded Explorer
- 조작 순서: full-detail route를 열고 `그래프 보기`를 클릭
- 입력할 테스트 데이터: `PHASE20Q_GRAPH_TARGET`
- 기대되는 화면 변화: standalone graph route를 열지 않고 embedded Explorer graph center가 target으로 retarget됨
- 실패 시 확인할 증상: standalone graph route 표시, center retarget 실패, selection/history 오류
- 테스트 완료 판단 기준: embedded graph center retarget과 기존 Phase 20-O 정책이 확인됨

## 현재 상태

Phase 20-Q 구현, source guardrail, 명령어 기반 검증, 클라이언트 UI 수동 테스트와 테스트 데이터 정리를 완료했다. 외부 백업 복원 후 `PHASE20Q` 조회 0건, DB integrity와 SHA-256 일치, git 상태의 DB/백업 파일 비노출을 확인했다.
