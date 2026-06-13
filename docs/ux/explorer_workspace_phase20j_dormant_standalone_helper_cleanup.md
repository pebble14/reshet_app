# ExplorerWorkspace Phase 20-J 호출자 없는 Explorer standalone helper 및 stale guard 정리

> 문서 분류: `changelog/status` 및 구현 정리 기록
>
> 한국어 작업명: 호출자 없는 Explorer standalone helper 및 stale guard 정리

## 작업 목적

Phase 20-J는 Phase 20-I 감사에서 확인한 호출자 없는 `HomeScreen._openDefaultStrongWordExplorer(...)` dormant helper와 직접 관련 stale source guard만 정리한다.

이번 작업은 route 통합이나 standalone 전체 제거가 아니다. active detail/graph route, embedded Explorer mount와 retarget 구조, Explorer 내부 owner 정책은 변경하지 않는다.

## 호출자 재확인과 production 변경

로컬 production source에서 `_openDefaultStrongWordExplorer(...)`는 `lib/ui/home_screen.dart`의 정의만 존재했고 실제 호출자는 없었다.

따라서 다음 dormant source만 제거했다.

- `_openDefaultStrongWordExplorer(...)` helper 본체
- helper 전용 compatibility/guardrail 주석
- helper 전용 `ignore: unused_element`
- helper 안의 `WordExplorerScreen(initialWordId: normalizedWordId)` standalone route 생성 source

## stale guard 정리

다음 테스트에서 dormant helper source 문자열 존재만 고정하던 assertion을 제거하거나 현재 active contract에 맞게 수정했다.

- `test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart`
- `test/ui/explorer_workspace_phase4a_hidden_preview_wrapper_test.dart`
- `test/ui/explorer_workspace_phase4b_real_projection_contract_test.dart`
- `test/ui/explorer_workspace_phase4c_passive_sync_boundary_test.dart`
- `test/ui/explorer_workspace_phase4d_preview_interaction_boundary_test.dart`
- `test/ui/home_screen_phase18a_large_split_shell_test.dart`
- `test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart`
- `test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`
- `test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart`
- `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`
- `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart`

Phase 17-B guard는 dormant helper 부재와 active embedded `WordExplorerScreen` 소유권을 확인하도록 수정했다. Phase 18-A guard는 small-screen detail route와 graph route가 계속 존재하는지 명시적으로 확인하도록 수정했다.

## 유지한 active behavior guard

다음 동작과 guard는 변경하지 않았다.

- small-screen default/search 목록 본문 tap → `WordDetailScreen`
- small-screen graph icon → `WordGraphScreen`
- `WordDetailScreen` → `WordGraphScreen`
- large-screen Strong Rail → embedded Explorer retarget
- large-screen transient 검색 후보 tap → embedded Explorer retarget
- embedded `WordExplorerScreen` mount
- `ValueKey(_largeScreenExplorerWordId)` owner instance 재생성 구조
- `WordExplorerScreen` history, selection, center owner 정책
- embedded Explorer full-detail route
- standalone `WordGraphScreen` 내부 navigation

## 변경하지 않은 범위

- route 통합 또는 standalone 전체 제거
- `WordExplorerScreen`, `WordDetailScreen`, `WordGraphScreen` active behavior
- embedded retarget 구조와 owner/history continuity
- DB/API/repository
- DTO/model/public API
- dependency
- `docs/logs/FEATURE_STATUS.md`
- 과거 Phase 문서와 DB 문서

## 명령어 기반 검증 결과

- 변경한 13개 Dart 파일 포맷: 성공
- stale guard 수정 대상 테스트: 79개 성공
- active behavior 유지 대상 테스트: 52개 성공
- 전체 `flutter test`: 352개 성공
- `git diff --check`: 성공
- 전체 `flutter analyze`: 실패
  - Phase 20-J 변경 파일 외 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart`의 기존 getter/method/반환 타입 오류가 포함되어 총 47 issues를 보고했다.
  - Phase 20-J에서 변경한 production helper 삭제와 test assertion 정리에 대한 analyzer error는 보고되지 않았다.

## 클라이언트 UI 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| small-screen 검색 결과 본문 tap | `WordDetailScreen` route가 열린다 | embedded Explorer가 열리거나 detail route가 열리지 않음 | 창 너비 900px 미만 → `H2` 검색 → 결과 본문 클릭 |
| small-screen graph icon tap | `WordGraphScreen` route가 열린다 | graph route 미진입 | 창 너비 900px 미만 → 목록 graph 아이콘 클릭 |
| large-screen Strong Rail tap | 새 route 없이 embedded Explorer target이 바뀐다 | standalone Explorer route가 열림 | 창 너비 900px 이상 → Strong Rail에서 `H2` 등 클릭 |
| large-screen transient 검색 후보 tap | panel이 닫히고 embedded Explorer가 후보 단어로 retarget된다 | submit만으로 retarget되거나 route가 열림 | 창 너비 900px 이상 → 상단 검색 → 후보 본문 클릭 |
| embedded Explorer full-detail action | `WordDetailScreen` route가 열린다 | full-detail route가 사라짐 | embedded Explorer detail pane에서 상세 화면 열기 |
| detail → graph action | `WordGraphScreen` route가 열린다 | graph route가 사라짐 | `WordDetailScreen`에서 graph 보기 |
