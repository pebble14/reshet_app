# ExplorerWorkspace Phase 20-V detail delete caller-result 감사

## 문서 역할

이 문서는 Phase 20-V의 1차 감사 판단과 source guard/docs-only 작업을 기록하는 `reference/context`, `migration/history`, `changelog/status` 문서다. 현재 active authority는 `docs/ux/explorer_workspace_unification.md`의 Phase 20-V active boundary다.

## 목적

Phase 20-V는 Explorer가 여는 full-detail `WordDetailScreen` route의 delete action도 edit/graph처럼 caller-request result로 분기할 수 있는지 확인했다. 감사 결과 production 최소 구현은 진행하지 않고, 현재 delete owner 경계를 source guard와 문서로 고정한다.

## 1차 감사 결과

- `WordDetailScreen._confirmDelete()`는 relation count 조회, confirm dialog, 진행 상태, delete write, graph cache clear, 성공·실패 feedback과 completed delete result 반환을 한 흐름으로 소유한다.
- Edit와 graph의 caller-result mode는 caller에 action 실행을 요청하며, Explorer에는 각각 재사용 가능한 edit 실행 경로와 graph center retarget 경로가 있다.
- Explorer에는 relation count, confirm, delete write, graph cache clear와 성공·실패 feedback을 수행하는 delete executor 경로가 없다.
- Explorer는 `WordDetailDeletedResult`를 받은 뒤 `wordId`를 검증하고 기존 center/non-center 복구를 수행하는 completed delete result 해석자다.
- Home과 small-screen은 기본 `WordDetailScreen` route의 local delete owner 흐름을 계속 사용한다.

## Delete request-result mode가 최소 구현으로 부적절한 이유

`WordDetailDeleteActionMode.returnToCaller` 또는 `WordDetailDeleteRequestedResult`만 추가하면 delete action은 실행되지 않는다. 의미 있는 caller-request 분기를 완성하려면 Explorer 또는 승인된 공통 delete executor가 다음 책임을 새로 가져야 한다.

- relation count 조회와 confirm dialog
- 중복 실행 방지와 진행 상태
- `DeleteWordCommand` 및 `WordWriteService.execute(...)` 호출
- `WordGraphDataCache.clear()` 실행
- 성공·실패 feedback
- completed delete result 또는 caller별 복구 연결

이는 delete owner 이동이며 Phase 20-V의 production 변경 금지 범위와 충돌한다. 따라서 Phase 20-V에서는 caller-request mode를 도입하지 않는다.

## 현재 확정 경계

- Delete 실행 owner는 `WordDetailScreen._confirmDelete()`다.
- `WordDetailScreen`은 delete 성공 후 `WordDetailDeletedResult(wordId: _wordId)`를 반환한다.
- `WordDetailDeletedResult`는 delete 요청이 아니라 completed delete result다.
- Explorer full-detail route는 edit와 graph action mode만 caller-result로 전달한다.
- Explorer는 completed delete result의 `wordId`를 검증하고 delete 후 복구를 수행하며 delete executor가 아니다.
- Explorer에는 `DeleteWordCommand` 실행과 `WordGraphDataCache.clear()` owner를 추가하지 않는다.
- `WordDetailDeleteActionMode`, `deleteActionMode`, `WordDetailDeleteRequestedResult`는 도입하지 않는다.
- Home/small-screen 기본 detail route와 full-detail route를 유지한다.
- Embedded detail pane에 delete 버튼을 추가하지 않는다.
- Phase 20-U의 center empty-state/history 후속 정리는 포함하지 않는다.

## Source guard

신규 source guard:

```text
test/ui/explorer_workspace_phase20v_delete_owner_boundary_guardrail_test.dart
```

검증 항목:

- `_confirmDelete()` 안에서 relation count 조회, `DeleteWordCommand`, graph cache clear, completed delete result 반환이 순서대로 유지된다.
- Delete caller-request mode와 requested result가 production source에 존재하지 않는다.
- Explorer full-detail route가 edit/graph caller mode만 전달한다.
- Explorer가 completed delete result의 `wordId`를 검증하고 mismatch 시 delete 복구 없이 refresh 후 반환한다.
- Explorer에 delete command 실행, write service와 graph cache clear owner가 없다.
- Home 기본 detail route가 delete mode 없이 기존 route 복귀 후 목록 refresh를 유지한다.

## 후속 Phase에서 delete owner 이동을 검토하기 위한 조건

후속 Phase에서 caller-request delete 또는 공통 delete executor를 검토하려면 다음을 먼저 설계하고 별도 승인을 받아야 한다.

- Delete action 실행 surface와 executor owner
- Relation count, confirm dialog, 진행 상태와 중복 실행 방지 owner
- Write 및 graph cache invalidation owner
- 성공·실패 feedback context와 표시 시점
- Completed result와 center/non-center 복구 연결
- Home/small-screen 기본 delete 흐름 보존 또는 대체 정책
- 실제 DB delete 테스트를 위한 전용 데이터 생성, 백업, 복구와 clean 확인 정책

## 명령어 기반 검증 기준

```text
flutter test --no-pub test/ui/explorer_workspace_phase20v_delete_owner_boundary_guardrail_test.dart
flutter test --no-pub test/ui/explorer_workspace_phase20n_typed_detail_route_result_guardrail_test.dart test/ui/explorer_workspace_phase20o_detail_graph_request_result_guardrail_test.dart test/ui/explorer_workspace_phase20q_detail_edit_request_result_guardrail_test.dart test/ui/word_explorer_phase20s_delete_result_contract_guardrail_test.dart test/ui/explorer_workspace_phase20v_delete_owner_boundary_guardrail_test.dart
dart analyze lib/ui/word_detail_screen.dart lib/ui/word_detail_route_result.dart lib/ui/word_explorer_screen.dart lib/ui/home_screen.dart test/ui/explorer_workspace_phase20v_delete_owner_boundary_guardrail_test.dart
git diff --check
git status --short --branch
```

실제 결과:

- Phase 20-V 신규 source guard 단독 실행: exit code `0`, `+7`, `All tests passed!`
- Phase 20-N/O/Q/S/V 관련 source guard 5개 실행: exit code `0`, `+34`, `All tests passed!`
- 신규 Phase 20-V source guard 단독 analyze: exit code `0`, `No issues found!`
- 감사 대상 production 파일과 신규 guard 대상 analyze: exit code `1`, 기존 `lib/ui/home_screen.dart` 진단 5건만 재확인
- 기존 진단 5건: `unused_field` 1건, `avoid_print` 4건
- `git diff --check`: exit code `0`, whitespace 오류 없음
- `git diff --exit-code -- lib pubspec.yaml pubspec.lock`: exit code `0`, production 및 dependency 파일 변경 없음
- Production `lib/`의 `WordDetailDeleteActionMode`, `deleteActionMode`, `WordDetailDeleteRequestedResult` 검색: exit code `1`, 일치 항목 없음
- `word_explorer_screen.dart`의 `DeleteWordCommand`, `WordWriteService`, `WordGraphDataCache.clear()` 검색: exit code `1`, 일치 항목 없음

Phase 20-V에서는 UI 테스트, 실제 DB delete 테스트와 실데이터 수정·삭제를 수행하지 않는다.
