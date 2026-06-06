# CHANGELOG

## 2026-06-06 Phase 20-C large-screen transient search result surface 최소 구현

- large-screen `HomeScreen`의 상단 일반 검색 입력 아래에 같은 widget tree 기반 inline attached transient search result panel을 추가했다. `OverlayEntry`, route-level overlay, global focus manager는 도입하지 않았다.
- transient panel은 기존 `_searchWordsFuture`를 재사용해 loading, 오류, 검색 결과 없음, 검색 후보 목록을 표시한다.
- 검색 state owner는 계속 `_HomeScreenState` private state다. `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` 책임과 기존 검색 repository/API 의미를 이동하거나 변경하지 않았다.
- non-empty query submit은 large-screen transient panel을 열거나 갱신할 수 있지만 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- transient panel의 명시적 검색 후보 item 본문 tap은 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로로 Explorer를 retarget한 뒤 panel을 닫는다.
- `검색 결과 닫기`는 panel presentation만 닫고 Explorer target, query, search future, 좌측 검색 결과 목록을 유지한다. 기존 `초기화`는 default Strong 목록 상태로 복귀하고 panel을 닫지만 Explorer target은 유지한다.
- 기존 좌측 `homeWordListSurface`의 검색 결과/default Strong 목록, Strong Rail을 삭제, 축소, 이동하지 않았다. large-screen transient panel과 좌측 검색 결과의 중복 표시는 Phase 20-C 점진 전환 상태로 허용한다.
- `Strong/스트롱` rail-local jump, graph selection passive sync, `WordExplorerScreen` graph/detail/selected/history owner, `ExplorerWorkspace` production mount 금지, `ExplorerWorkspaceState` source-of-truth 승격 금지를 유지했다.
- small-screen에는 transient panel을 적용하지 않고 기존 `homePane → detail route` 흐름을 유지했다.
- DB, repository read/API, DTO/model, dependency, `pubspec.yaml`, `pubspec.lock`은 변경하지 않았다.
- `test/ui/home_screen_phase20c_transient_search_result_surface_guardrail_test.dart`를 추가해 inline panel, owner, submit 비-retarget, 후보 tap retarget 후 dismiss, dismiss/clear 비-retarget, Strong/passive sync 비결합, 좌측 중복 목록, small-screen 흐름, workspace 금지선을 source 기준으로 확인한다.
- `test/ui/home_screen_phase20c_transient_search_result_surface_runtime_test.dart`를 추가해 격리 복사 DB에서 `H2`, `G26`, `PHASE20C_RESULT_NOT_FOUND_20260606` 데이터를 사용하여 submit, dismiss, clear, 후보 선택, no-result, small-screen detail route를 runtime으로 확인한다.
- 명령어 기반 검증 결과:
  - Phase 20-C 신규 source guardrail: 통과, `+9`, `All tests passed!`.
  - Phase 20-C 신규 실제 DB 기반 runtime widget guardrail: 통과, `+3`, `All tests passed!`.
  - 기존 Phase 19-B/19-C guardrail: 통과, `+14`, `All tests passed!`.
  - 기존 Phase 18-N 실제 DB 기반 runtime guardrail: 통과, `+3`, `All tests passed!`.
  - 기존 Phase 17-B/C, Phase 18-K/M owner·passive sync·Strong 분리 guardrail: 통과, `+26`, `All tests passed!`.
  - Phase 20-C 변경 파일 대상 analyze: exit code `0`. 기존 `HomeScreen` warning/info 5건만 확인했고 신규 오류는 없다.
- 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings` 실제 실행 결과는 기존 기준과 동일한 `47 issues found`, exit code `1`이다. error 13건은 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치이며 Phase 20-C 변경과 분리해 이번 범위에서 수정하지 않았다.
- Codex는 UI 기반 수동 테스트를 수행하지 않았다. 클라이언트는 large-screen `H2` submit 비-retarget, 후보 tap retarget 후 panel 닫힘, dismiss/초기화 비-retarget, `G26` Strong rail-local jump, 좌측 중복 목록/default Strong 유지, small-screen `H2` detail route를 확인해야 한다.
- 상세 구현·검증 기록은 `docs/ux/explorer_workspace_phase20c_transient_search_result_surface_minimum_slice.md`에 추가했고 active boundary 요약은 `docs/ux/explorer_workspace_unification.md`에 반영했다.
- 커밋, main 병합, origin push는 수행하지 않았다.

## 2026-06-06 Phase 20-B Search Result Surface Contract Audit

- Phase 20-A에서 확인한 large-screen 검색 결과/default Strong 목록의 좌측 surface 역할 충돌을 검색 결과 surface 계약 관점에서 구체화하는 read-only docs/audit를 진행했다.
- 현재 일반 검색 state와 목록 전환은 `HomeScreen` private state가 소유하고, large-screen 일반 검색 입력은 workspace 상단에 있으며, 검색 결과와 default Strong 목록은 같은 좌측 `homeWordListSurface`를 공유한다는 production 경계를 확인했다.
- 검색 결과는 특정 query에 종속된 semantic candidate/result entry이고 default Strong 목록은 empty-query browse/discovery 후보이므로, 같은 좌측 surface를 공유하는 현재 구조가 persistent navigation/orientation 보조와 global result/default browse 표시 책임을 함께 맡는 역할 충돌을 기록했다.
- large-screen 검색 결과 surface를 `query-bound transient result surface` 후보로 정의했다. 검색 submit은 result 갱신 또는 표시까지만 허용하고, submit만으로 Explorer를 retarget하지 않으며, large-screen 검색 후보 item 본문 tap과 같은 사용자의 명시적 선택 동작에서만 기존 Explorer retarget 경로를 사용한다는 계약을 고정했다.
- default Strong 목록은 search result가 아니라 `browse/discovery surface` 후보로 정의했다. Phase 20-B에서는 삭제, 축소, 이동 또는 대체를 결론 내리지 않고 역할 재정의 대상으로만 기록했다.
- large-screen transient result surface의 exact presentation, lifecycle, dismiss/focus 복귀, search state owner 이동과 실제 surface 이동 구현은 Phase 20-C 이후 별도 설계·승인 후보로 넘겼다.
- `Strong/스트롱` rail-local jump, graph selection passive sync, `WordExplorerScreen` graph/detail/selected/history owner, `ExplorerWorkspace` production mount 금지, `ExplorerWorkspaceState` source-of-truth 승격 금지 계약을 유지했다.
- small-screen 일반 검색 입력과 검색 결과 item tap의 기존 `homePane → detail route` 흐름을 유지하며 Phase 20-B에서 변경하지 않았다.
- production code, test code, DB/data/sql, dependency, `pubspec.yaml`, `pubspec.lock`, UI와 route는 변경하지 않았다.
- Phase 20-B는 UI 변경이 없으므로 Codex가 UI 수동 테스트를 수행하지 않았다. Phase 20-C 이후 구현 시 사용할 클라이언트 UI 체크리스트 후보를 상세 감사 문서에 기록했다.
- 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`는 기존 `47 issues found`, exit code `1` 선행 기술 부채와 섞지 않기 위해 실행하지 않았다.
- 상세 감사 기록은 `docs/ux/explorer_workspace_phase20b_search_result_surface_contract_audit.md`에 추가했고, active boundary 요약은 `docs/ux/explorer_workspace_unification.md`에 반영했다.

## 2026-06-06 Phase 20-A Surface & Navigation Role Audit

- Phase 19 이후 large-screen workspace의 상단 검색 surface, 좌측 control surface, graph/detail standalone route와 small-screen flow의 장기 역할을 실제 production source 기준으로 확인한 read-only docs/audit를 진행했다.
- 현재 large-screen 상단 일반 검색 입력과 좌측 `Strong/스트롱` 입력의 역할은 분리되어 있지만, 검색 결과와 default Strong 전체 목록이 좌측에 남아 있어 좌측 surface가 persistent navigation/orientation 보조와 global discovery/result 표시를 함께 담당하는 역할 충돌이 있다고 판단했다.
- large-screen 일반 검색 결과를 상단 검색에 딸린 transient result surface로 표현하는 방향은 후속 구현 후보로 기록했다. Phase 20-A에서는 result surface 이동, exact presentation, state owner 이동, submit 기반 Explorer retarget을 구현하거나 확정하지 않았다.
- default Strong 전체 목록은 Strong Rail과 같은 persistent navigation보다 browse/discovery 성격이 강하다고 판단했다. large-screen에서 계속 필요하다면 명시적 browse/discovery surface로 재정의하는 장기 전환 후보로 기록했으며 제거, 이동, 축소는 확정하지 않았다.
- `HomeScreen`, `WordExplorerScreen`, `WordDetailScreen`, `WordGraphScreen`의 graph/detail standalone route와 entrypoint를 확인했다. large-screen standalone route를 줄이는 방향은 pane 중심 continuity를 위한 장기 전환 후보지만 small-screen/mobile flow, full detail 역할, standalone graph 탐색 때문에 전역 제거는 아직 부적절하다고 기록했다.
- large-screen standalone route 후속 후보 순서는 form factor/action intent별 inventory 고정, pane action 설계, `HomeScreen` large-screen entrypoint부터 workspace-aware redirect 후보 검토, full detail 역할 분리, standalone 내부 의존성 감사, small-screen 유지 상태의 large-screen 전용 전환 검토, history/read/refresh 경계 설계 이후 제거 가능성 재검토 순으로 정리했다.
- small-screen `homePane → detail route`는 즉시 유지하고, 장기적으로 `mobile Explorer presentation`으로 재정의 가능한지는 별도 audit 대상으로 남겼다.
- `ExplorerWorkspace` 표현은 UX/architecture 개념 및 기존 preview-only boundary 설명으로만 사용했다. production `ExplorerWorkspace` widget mount와 `ExplorerWorkspaceState` source-of-truth 승격은 금지 상태를 유지했다.
- production code, test/guardrail, DB/data/sql, dependency, `pubspec.yaml`, `pubspec.lock`, route redirect, standalone route 제거, UI 변경은 수행하지 않았다.
- Phase 19의 large-screen 상단 검색, 좌측 일반 검색 입력 부재, small-screen 기존 home flow, search submit 비-retarget, `Strong/스트롱` rail-local jump, graph selection passive sync, `WordExplorerScreen` owner 경계를 위반하지 않았다.
- Phase 20-A는 docs/audit-only이므로 Flutter test와 전체 analyze를 재실행하지 않았다. 기존 전체 analyze의 `47 issues found`, exit code `1`은 선행 기술 부채이며 Phase 20-A에서 새로 발생한 문제가 아니다.
- 상세 감사 기록은 `docs/ux/explorer_workspace_phase20a_surface_navigation_role_audit.md`에 추가했고, active boundary 요약은 `docs/ux/explorer_workspace_unification.md`에 반영했다.

## 2026-06-06 Phase 19-C 상단 검색 surface guardrail hardening 및 종료 audit

- Phase 19-B 이후 large-screen 상단 검색 surface, 좌측 control surface, Strong Rail, 우측 Explorer owner 경계가 다시 섞이지 않도록 guardrail과 문서를 보강했다.
- `test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart`의 넓은 stale source slice를 `homeSearchControlArea`, `homeStrongControlArea`, `homeWorkspaceSearchSurface`, `homePane`별 검사로 보정했다.
- Phase 18-M guard에서 Strong changed/submitted/run handler를 각각 분리해 `_runSearch(...)`, 검색 결과/default 목록 전환, Explorer retarget/remount, repository read와 결합되지 않는 경계를 고정했다.
- `test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart`를 추가해 large-screen 상단 검색 mount, 좌측 Strong/Rail/list 유지, small-screen 기존 흐름, search submit 비-retarget, graph passive sync, `WordExplorerScreen` owner, `ExplorerWorkspace` production mount 금지, `ExplorerWorkspaceState` source-of-truth 승격 금지를 확인한다.
- production code, DB, repository read/API, DTO/model, dependency, UX 기능은 변경하지 않았다.
- keyboard access, command palette, search ranking, recent search, persistence, AppBar write action과 상단 검색 surface 결합은 구현하지 않았다.
- 명령어 기반 검증 결과:
  - Phase 19-B 신규 guardrail 단독 실행: 통과, `+7`, `All tests passed!`.
  - Phase 18-C/M 및 Phase 19-B source guard 묶음: 통과, `+21`, `All tests passed!`.
  - Phase 18-N runtime widget guardrail 단독 실행: 통과, `+3`, `All tests passed!`.
  - Phase 17-B/C 및 Phase 18-A/B/C/D/F/G/I/K/M/N, Phase 19-B guardrail 묶음: 통과, `+82`, `All tests passed!`.
  - Phase 19-C 신규 guardrail 단독 실행: 통과, `+7`, `All tests passed!`.
  - 보정한 Phase 18-M 및 신규 Phase 19-C guardrail 묶음: 통과, `+13`, `All tests passed!`.
  - 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`. Phase 19-C 신규 문제는 확인되지 않았다.
- Phase 19-B UI 수동 테스트는 클라이언트 기준으로 통과했다. Phase 19-C는 production UI 변경이 없으므로 Codex는 UI 수동 테스트를 수행하지 않았으며 재확인은 필요하지 않다고 판단했다.
- 승인된 Phase 19 목표와 검증 기준이 충족되어 Phase 19는 종료 가능하다고 판단했다.
- 커밋, main 병합, origin push는 수행하지 않았다.

## 2026-06-06 Phase 19-B 상단 검색 surface presentation 최소 구현

- large-screen `HomeScreen`에서 일반 검색 입력을 좌측 control surface 내부에서 좌우 split 전체 위의 workspace 상단 surface로 시각 재배치했다.
- 변경은 `HomeScreen.build()` 내부 widget composition에 한정했다. `_searchController`, `_runSearch(...)`, `_clearSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`는 계속 `HomeScreen` private state가 소유한다.
- large-screen 좌측 control surface에는 `Strong/스트롱` rail-local jump 입력, Strong Rail, default Strong 목록 또는 검색 후보 목록, current Explorer target feedback, graph selection 기반 passive selected Strong feedback을 유지했다.
- 상단 search submit은 기존 검색 목록 전환만 수행하며 Explorer retarget을 수행하지 않는다. 검색 후보 item tap과 Strong Rail item tap의 기존 명시적 large-screen Explorer retarget 경로는 유지했다.
- `Strong/스트롱` 입력 handler와 rail-local jump 경로, graph selection passive sync 경로는 변경하지 않았다.
- small-screen은 기존 일반 검색 입력, 검색 후보 목록, 후보 item tap의 detail route 흐름을 유지했다.
- `test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart`의 stale mount 기준을 Phase 19-B에 맞게 보정하고, large-screen 좌측에 일반 검색 입력이 남지 않으며 Strong 입력만 유지되는 경계를 명시했다.
- `test/ui/home_screen_phase19b_top_search_surface_presentation_test.dart`를 추가해 large-screen 상단 검색 mount, 좌측 Strong/Rail/list 유지, search submit 비-retarget, 명시적 후보 item retarget, owner 및 Phase 18 금지선, small-screen 흐름을 확인한다.
- DB, repository read/API, DTO/model, dependency, `WordExplorerScreen` owner state, `ExplorerWorkspace` production mount, `ExplorerWorkspaceState` source-of-truth, 좌측/상단 create/edit/write entry는 변경하지 않았다.
- keyboard access, command palette, search ranking, recent search, persistence, AppBar write action과 검색 surface 결합은 구현하지 않았다.
- 명령어 기반 검증 결과:
  - Phase 18-C/M 및 Phase 19-B 관련 source guardrail: 통과, `+21`, `All tests passed!`.
  - Phase 19-B 신규 guardrail 단독 실행: 통과, `+7`, `All tests passed!`.
  - 기존 Phase 18-N runtime widget guardrail 단독 실행: 통과, `+3`, `All tests passed!`.
  - Phase 17-B/C 및 Phase 18-A/B/C/D/F/G/I/K/M/N, Phase 19-B guardrail 묶음: 통과, `+82`, `All tests passed!`.
  - Phase 19-B 변경 파일 대상 analyze: exit code `0`. 기존 `HomeScreen` warning/info 5건만 확인했고 신규 오류는 없다.
  - 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`. 이번 범위에서 수정하지 않았다.
- UI 테스트는 Codex가 수행하지 않는다. large-screen 상단 검색 위치, 좌측 Strong/Rail/list 유지, 검색 후보 item retarget, search submit 비-retarget, Strong rail-local jump, graph passive sync, small-screen detail route를 클라이언트 체크리스트로 확인한다.
- 커밋, main 병합, origin push는 수행하지 않았다.

## 2026-06-06 Phase 19-A 상단 검색/명령 surface read-only audit

- Phase 19-A는 상단 검색/명령 surface와 좌측 control surface의 장기 역할을 재정의하기 위한 read-only UX/architecture audit 단계다. production code, test code, DB, repository read/API, DTO/model, dependency는 변경하지 않았다.
- 현재 일반 검색 입력은 `HomeScreen`의 `Scaffold.body > LayoutBuilder > homeSearchControlArea > homePane` 경로에 mount되며, large-screen에서는 좌측 `Expanded(flex: 2)` 안에 위치하는 좌측 control surface 상단 입력임을 확인했다.
- 일반 검색 query, `_runSearch(...)`, `_clearSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`, default/search 목록 전환은 `HomeScreen` private state가 계속 소유한다. 검색 결과/default 목록은 좌측 surface에 유지하는 경계로 기록했다.
- 일반 검색 입력을 large-screen 상단 검색/명령 surface 후보로 시각 재배치하는 것은 `HomeScreen` 내부 owner-preserving presentation 변경 후보로 평가할 수 있으며, `WordExplorerScreen` owner state migration 없이 가능하다고 판단했다. Phase 19-A는 이를 구현하지 않고 Phase 19-B 이후 별도 후보로 분리했다.
- 상단 search submit 자체는 Explorer retarget을 수행하지 않으며, 우측 Explorer retarget request는 기존 명시적 검색 후보 item tap 또는 Strong Rail item tap에서만 발생해야 한다고 기록했다.
- `Strong/스트롱` 입력은 좌측 Strong Rail local jump 전용으로 유지하고, 일반 검색 실행, 검색 결과/default 목록 전환, Explorer retarget/remount와 결합하지 않는 경계를 유지했다.
- graph selection passive sync는 Strong Rail passive selected feedback과 rail-local jump만 수행하며, `_largeScreenExplorerWordId` 변경 또는 `_showWordInLargeScreenExplorerPane(...)` 호출로 확장하지 않는 경계를 유지했다.
- 좌측 control surface 유지 역할은 Strong Rail/orientation, `Strong/스트롱` local jump, default Strong 목록, 검색 후보 목록, explicit 후보 item 선택, current target feedback, passive selected Strong feedback으로 정리했다.
- “명령 surface”는 장기 UX 개념으로만 기록했다. keyboard command, command palette, recent search, persistence, search ranking 개선을 승인하지 않으며 AppBar의 DB 초기화/실행 취소 같은 write action과 결합하지 않는다.
- `WordExplorerScreen` owner state migration, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경, 좌측 또는 상단 create/edit/write entry 추가는 없다.
- 상세 감사 기록은 `docs/ux/explorer_workspace_phase19a_top_search_command_surface_audit.md`에 추가했고, active boundary 요약은 `docs/ux/explorer_workspace_unification.md`에 반영했다.
- 명령어 기반 검증 결과:
  - Phase 17-B/C 및 Phase 18-A/B/C/D/F/G/I/K/M/N guardrail 묶음: 통과, `+74`, `All tests passed!`.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`. Phase 19-A 범위에서 수정하지 않았다.
- UI 테스트는 Codex가 수행하지 않는다. Phase 19-A는 production UI 변경이 없으며, 기존 Phase 18 역할 경계를 확인하는 클라이언트 회귀 체크리스트를 감사 문서에 기록했다.
- 커밋, main 병합, origin push는 수행하지 않았다.

## 2026-06-06 Phase 18-N Phase 18 종료 전 guardrail hardening

- Phase 18-N은 Phase 19 이동 전 Phase 18 종료 조건을 보강한 guardrail/docs 단계다. production 기능과 `lib/` code는 변경하지 않았다.
- active UX 문서의 Phase 18-L `Phase 18-M 최소 구현 후보` 표현을 역사적 audit 후보로 명확히 구분하고, 현재 기준은 Phase 18-M 완료 구현과 Phase 18-N 최종 역할 경계를 따르도록 정리했다.
- `test/ui/home_screen_phase18n_runtime_guardrail_test.dart`를 추가해 격리 복사 DB에서 production `HomeScreen`을 mount하고 large-screen 일반 검색 submit, `Strong/스트롱` rail-local jump, 검색 목록 유지, Explorer 비-retarget/remount, passive callback 경계, small-screen 검색 결과 item의 detail route 흐름을 runtime으로 확인한다.
- graph node 직접 탭은 `CustomPaint`와 계산 좌표 기반 구조상 production key 추가 없이 안정적으로 고정하기 어려워 이번 runtime guard 범위에서 제외했다. graph selection callback 연결과 async stale guard는 기존 Phase 18-K source guard를 유지하고, 새 runtime guard는 mounted `WordExplorerScreen`의 production passive callback 이후 `HomeScreen` 경계를 확인한다.
- UI 테스트는 Codex가 수행하지 않으며, large-screen 일반 검색 `H1`, 검색 후보 item retarget, `Strong/스트롱` 입력 `G26`, graph selection passive selected/jump, Strong 번호 없는 node의 passive clear, small-screen 검색/detail route를 클라이언트 체크리스트로 남겼다.
- 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경, Strong Rail/Search/graph selection/passive sync 동작 변경, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격은 없다.
- 명령어 기반 검증 결과:
  - `flutter test test/ui/home_screen_phase18n_runtime_guardrail_test.dart --reporter expanded`: 통과, `+3`.
  - Phase 17-B/C, Phase 18-A/B/C/D/F/G/I/K/M, Phase 18-N guardrail 묶음: 통과, `+74`.
  - `flutter test --reporter compact`: 전체 통과, `+311`.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings test/ui/home_screen_phase18n_runtime_guardrail_test.dart`: 통과, `No issues found!`.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`.

## 2026-06-06 Phase 18-M Search / Strong Jump 역할 분리 구현

- Phase 18-M은 large-screen `HomeScreen` control surface에서 일반 검색 입력과 `Strong/스트롱` rail-local jump 입력을 분리한 최소 구현 단계다.
- `_searchController`와 분리된 `_strongJumpController`를 추가하고, large-screen control surface에 `Strong/스트롱` compact field를 추가했다.
- 일반 검색 field는 기존 `_runSearch(...)`, `_clearSearch(...)`, 검색 후보 목록, 검색 후보 item tap의 우측 Explorer retarget 흐름을 유지한다.
- `Strong/스트롱` field는 기존 `_jumpToStrongInRail(...)` rail-local helper만 호출하며, `_largeScreenExplorerWordId` 변경, `_showWordInLargeScreenExplorerPane(...)` 호출, `_runSearch(...)` 결합, 검색 결과/default list 전환, `WordExplorerScreen` remount를 유발하지 않는다.
- small-screen branch는 기존 `homePane` 반환 흐름과 기존 검색 field 흐름을 유지한다.
- 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경은 없다.
- 명령어 기반 테스트 결과:
  - `flutter test test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart --reporter expanded`: 통과, `+6`.
  - `flutter test test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart --reporter expanded`: 통과, `+31`.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings lib/ui/home_screen.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart`: exit code 0. 기존 `_dbMessage` unused warning 1건과 기존 `print` info 4건을 보고했다.
  - `git diff -- pubspec.yaml pubspec.lock`: 변경 없음.
- UI 테스트는 수행하지 않았으며, 클라이언트 확인 대상으로 large-screen 일반 검색 후보 흐름, 검색 후보 item retarget, `Strong/스트롱` 입력의 rail-local jump, small-screen 기존 검색 흐름을 남겼다.
- 커밋, main 병합, origin push는 수행하지 않았다.

## 2026-06-05 Phase 18-L Search / Strong Jump role separation audit

- Phase 18-L은 `Search / Strong Jump role separation audit`를 수행한 read-only audit 문서화 단계다. 이번 작업에서는 production code, test code, DB, dependency를 변경하지 않았다.
- 현재 일반 검색과 Strong jump는 같은 `_searchController`, 같은 `TextField`, 같은 입력 surface를 공유하는 것으로 정리했다.
- Strong-like 입력의 `onChanged` 경로는 `_handleSearchChanged(...)`에서 `_jumpToStrongInRail(...)`로 이어지는 rail-local jump 경로로 분리되어 있다.
- `_jumpToStrongInRail(...)` 경로는 `_largeScreenExplorerWordId`를 변경하지 않고, `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않으며, 검색 결과 목록 초기화, default/search list 전환, Explorer pane remount를 유발하지 않는다고 기록했다.
- 현재 위험 지점은 같은 입력란에서 Strong-like query 입력 후 submit 또는 search button 경로가 `_runSearch(...)`로 들어갈 수 있다는 점으로 정리했다.
- Phase 18-M은 확정 구현이 아니라 최소 구현 후보로만 기록했다. 후보 방향은 large-screen `HomeScreen` control surface에서 일반 검색 field와 `Strong/스트롱` compact field를 분리하고, Strong/스트롱 field는 rail-local jump 전용으로 제한하는 것이다.
- 일반 검색 field는 기존 검색 후보 목록과 검색 후보 item tap의 Explorer retarget 흐름을 유지하는 후보로 기록했다.
- Phase 18-M 최소 구현 후보는 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경 없이 가능하다고 audit 결과를 정리했다.
- small-screen 흐름 변경, keyboard access, search ranking 개선, recent search/persistence, 좌측 create/edit/write entry, graph/detail/history owner migration, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격은 제외 후보로 유지했다.
- 명령어 기반 확인은 문서 diff, 변경 파일 목록, 브랜치 상태 확인으로 제한한다.
- main 병합과 origin/main push는 수행하지 않는다.

## 2026-06-05 Phase 18-K graph selection Strong Rail passive sync minimum slice

- Phase 18-K는 large-screen `HomeScreen` 우측 `WordExplorerScreen` 내부 graph selection을 좌측 Strong Rail에 passive하게 반영하는 minimum slice다.
- `WordExplorerScreen`에 optional `onSelectedStrongWordChanged` callback을 추가했고, 기존 route usage와 standalone usage는 callback 없이 유지한다.
- `HomeScreen`은 callback에서 rail-local passive selected state만 갱신하며, `_largeScreenExplorerWordId` 변경, `_showWordInLargeScreenExplorerPane(...)` 호출, `WordExplorerScreen` remount를 수행하지 않는다.
- selected display item의 display Strong 번호가 비어 있으면 passive selected state를 clear한다. 이 처리는 retarget이 아니며, Strong Rail이 과거 passive highlight/jump 상태를 계속 유지하지 않도록 하기 위한 최소 처리다.
- Strong Rail feedback은 `_largeScreenExplorerWordId` 기준 target feedback과 graph selected display Strong 기준 passive selected feedback을 분리했다. target feedback은 primary 계열로 유지하고, passive selected feedback은 secondary 계열 보조 표시와 rail-local jump로만 처리한다.
- `_selectWord(...)`에 selection request token stale guard를 추가해 빠른 graph node 선택에서 과거 async selection 결과가 늦게 도착해 callback/state를 되돌리는 상황을 막았다. selection clear도 token을 무효화하고 passive state clear callback을 보낸다.
- 이번 Phase에서는 새 DB query, 새 repository read, 신규 DTO/model, dependency 변경, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, `WordExplorerScreen` owner migration, 좌측 create/edit/write entry, keyboard access, search/list continuity 구현을 수행하지 않았다.
- 명령어 기반 테스트 결과:
  - `flutter test test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart --reporter expanded`: 통과, `+7`.
  - `flutter test test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart --reporter expanded`: 통과, `+8`.
  - `flutter test test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart --reporter expanded`: 통과, `+5`.
  - `flutter test test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart --reporter expanded`: 통과, `+5`.
  - `flutter test test/ui/home_screen_phase18a_large_split_shell_test.dart test/ui/home_screen_phase18b_left_control_pane_direction_test.dart test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart --reporter expanded`: 통과, `+45`.
  - `dart analyze lib/ui/home_screen.dart lib/ui/word_explorer_screen.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart`: 기존 `home_screen.dart`의 `_dbMessage` 미사용 warning 1건과 `print` 사용 info 4건으로 exit code 1.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings lib/ui/home_screen.dart lib/ui/word_explorer_screen.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart`: 같은 기존 warning/info 5건을 보고하고 exit code 0.
- UI 수동 테스트 대상 데이터는 `data/reshet_work.db` 기준으로 `H0001_0000` 중심 단어 `H1 / אָב / 아브 / 아버지`, 연결 단어 `H2 / אַב / 아브 / 아버지`, `H85 / אַבְרָהָם / 아브라함/아베라함`, Strong 번호 없는 연결 단어 `אַבָּא / 아빠 / 아버지`를 사용한다.
- main 병합과 origin/main push는 수행하지 않는다.

## 2026-06-05 Phase 18-J stale HomeScreen source guard cleanup

- Phase 18-J는 Phase 18-C/18-D 시점의 과거 HomeScreen source guard가 Phase 18-G/I 이후 허용된 production Strong Rail 존재 자체를 금지하던 stale 기준을 정리한 cleanup 단계다.
- `test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart`와 `test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart`에서 `StrongRail` / `Strong Rail` 전역 부재 assertion을 제거하고, rail source가 owner/source-of-truth, repository/read, DB query, DTO/model/public API, graph/detail/selected/history owner로 확장되지 않는지 확인하도록 보정했다.
- Strong Rail은 large-screen `HomeScreen` 좌측 control surface 내부의 허용된 production surface로 유지하되, rail tap retarget-only boundary와 rail local jump가 Explorer target을 변경하지 않는 boundary는 유지했다.
- 이번 Phase에서는 production UX 변경, `lib/` production code 변경, graph selection sync, `WordExplorerScreen` callback 추가, `WordGraphScreen` callback 변경, 새 DB query, 새 repository read, 신규 DTO/model/public API, dependency 변경을 수행하지 않았다.
- 명령어 기반 테스트 결과:
  - `flutter test test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart --reporter expanded`: 통과, `+13`.
  - `flutter test test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart --reporter expanded`: 통과, `+8`.
  - `flutter test test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart --reporter expanded`: 통과, `+5`.
  - `flutter test test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart --reporter expanded`: 통과, `+5`.
  - `flutter test test/ui/home_screen_phase18a_large_split_shell_test.dart test/ui/home_screen_phase18b_left_control_pane_direction_test.dart test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart --reporter expanded`: 통과, `+45`.
  - `dart analyze test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart`: 통과, `No issues found!`.
- UI 수동 테스트는 새로 요구하지 않는다. production code 변경이 없으므로 UI 재테스트 대상이 아니다.
- main 병합과 origin/main push는 수행하지 않는다.

## 2026-06-05 Phase 18-I Strong Rail local jump minimum slice

- Phase 18-I는 large-screen 검색창의 Strong 번호 형식 입력을 Strong Rail 내부 local jump로 연결한 최소 슬라이스다.
- rail jump는 `_strongRailScrollController`, `_strongRailListItemExtent`, `_currentStrongRailItems` 기반 helper로 분리했고, 기존 `_jumpToStrongInDefaultList(...)`와 `_scrollToDefaultStrongIndex(...)`는 default Strong list helper로 유지했다.
- `_currentStrongRailItems`는 rail builder가 받은 기존 default Strong list future 결과를 rail-local index lookup cache로만 보관하며, 새 repository read나 DB query를 추가하지 않았다.
- 검색 입력 기반 rail jump는 `_largeScreenExplorerWordId`를 변경하지 않고 `_showWordInLargeScreenExplorerPane(...)`을 호출하지 않으며, `WordExplorerScreen` remount를 발생시키지 않는다.
- rail jump는 `_setVisibleWordListFuture(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`를 변경하지 않으므로 search result list 초기화나 default Strong list 전환을 수행하지 않는다.
- Phase 18-F guard는 default Strong jump helper와 rail local jump helper 검증 범위를 분리하도록 보정했고, Phase 18-G rail tap retarget-only boundary는 유지했다.
- 이번 Phase에서는 graph selection 연동, `WordExplorerScreen` constructor callback 추가, `WordGraphScreen` callback 변경, 새 DB query, 새 repository read, 신규 DTO/model/public API, dependency 변경, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` source-of-truth 승격, `WordExplorerScreen` owner migration, 좌측 단어 추가 버튼, keyboard access, search/list continuity 구현을 수행하지 않았다.
- 명령어 기반 테스트 결과:
  - `flutter test test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart`: 통과, `+5`.
  - `flutter test test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart`: 통과, `+5`.
  - `flutter test test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart`: 통과, `+8`.
  - `flutter test test/ui/home_screen_phase18a_large_split_shell_test.dart test/ui/home_screen_phase18b_left_control_pane_direction_test.dart test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart`: 실행했으나 Phase 18-C/18-D의 과거 pre-rail guard가 Phase 18-G 이후 존재하는 Strong Rail 자체를 금지해 `+43 -2`로 실패했다. 이번 Phase에서는 해당 historical guard를 임의로 완화하지 않았다.
  - `dart analyze lib/ui/home_screen.dart test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart`: 기존 `home_screen.dart`의 `_dbMessage` 미사용 warning 1건과 `print` 사용 info 4건으로 실패했다.
  - `dart analyze test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart`: 통과, `No issues found!`.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings lib/ui/home_screen.dart test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart`: 종료 코드 0, 기존 lint 5건을 non-fatal로 보고했다.
- main 병합과 origin/main push는 수행하지 않는다.

## 2026-06-05 Phase 18-G Strong Rail Level 1 retarget-only minimum slice

- Phase 18-G는 large-screen `HomeScreen` 좌측 control surface 내부에 얇은 Strong Rail을 도입한 Level 1 retarget-only minimum slice다.
- Strong Rail은 기존 default Strong list future를 재사용해 Strong 번호 중심 compact item을 표시하며, tap action은 `_showWordInLargeScreenExplorerPane(item.wordId)` 호출로 제한했다.
- search mode에서는 기존 검색 결과 list surface를 유지하고, rail 도입으로 검색 결과 list가 default Strong list로 전환되거나 초기화되지 않도록 source guard를 추가했다.
- small-screen `return homePane;` 및 list → detail route 흐름은 유지했다.
- Phase 18-F guard test는 Strong Rail production 부재 전제만 Phase 18-G 기준으로 보정했고, keyboard access, search/list continuity, owner/source-of-truth, read/query/API 금지선은 유지했다.
- 이번 Phase에서는 새 DB query, 새 repository read, 신규 DTO/model/public API, dependency 변경, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` source-of-truth 승격, `WordExplorerScreen` owner migration, persistence/restore/rollback authority migration을 수행하지 않았다.
- main 병합과 origin/main push는 수행하지 않는다.

## 2026-06-04 Phase 18-F ExplorerWorkspace left control boundary guardrail/docs 보강

- Phase 18-F는 Phase 18-A~E에서 정리한 large-screen `HomeScreen` 좌측 control surface boundary를 source guard와 문서 기준으로 고정한 단계다.
- 신규 source guard `test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart`를 추가해 `_largeScreenExplorerWordId` 기반 retarget/current target feedback, `WordExplorerScreen` owner state 비소유, `ExplorerWorkspaceState` 비-source-of-truth, small-screen route/detail 흐름 유지를 확인했다.
- create/edit/write 금지 기준은 전역 문자열 금지가 아니라 `HomeScreen` 좌측 control surface와 large-screen split shell 경로에 한정했다. 기존 `WordGraphScreen._showCreateWordFlow()`, `WordEditScreen.fromSeed`, `Icons.note_add` 흐름은 `WordGraphScreen` 내부에 남을 수 있다.
- Strong Rail, keyboard access, search/list continuity 관련 검증도 전역 부재가 아니라 production `HomeScreen`과 `ExplorerWorkspace` production-adjacent surface에 새 구현이 추가되지 않는지 확인하는 source guard로 제한했다.
- 기존 strong jump helper는 기본 Strong 목록 scroll helper 범위를 넘지 않고 Explorer retarget, repository read, Navigator route, `ExplorerWorkspaceState` source-of-truth 흐름으로 확장되지 않는다고 고정했다.
- 이번 Phase에서는 `lib/`, DB, dependency, repository/read contract, DTO/model/public API 변경을 수행하지 않았고 main 병합도 수행하지 않는다.

## 2026-06-04 Phase 18-E HomeScreen left control action boundary audit

- Phase 18-E는 `left control surface action boundary audit`를 수행한 docs/audit-only 단계다.
- Phase 18-A~D까지 large-screen 좌측 control surface가 맡은 현재 책임을 검색 입력/초기화, 기본 Strong 목록, 검색 결과 목록, large-screen Explorer target 갱신, current target feedback으로 정리했다.
- 허용 가능한 action 후보는 기존 `HomeScreen` private state와 기존 read 흐름 안에서 처리 가능한 retarget feedback, search control 정리, guardrail/docs 보강으로 제한했다.
- Strong Rail, 좌측 단어 추가 버튼, scroll/jump behavior, keyboard access, search/list continuity rule은 owner/source-of-truth/action boundary 정의 전까지 금지 후보로 유지했다.
- 좌측 add action은 현재 `WordGraphScreen._showCreateWordFlow()`와 repository/write/edit/relation 흐름에 묶여 있어 public entry, route-level entry, owner boundary 정의가 선행되어야 한다고 기록했다.
- default Strong list와 search result list는 current target feedback과 retarget request surface 범위에서는 같은 control surface 책임으로 묶을 수 있지만, selection owner나 repository/read owner로 확장하지 않는다고 정리했다.
- 다음 Phase 18-F 후보는 docs/guardrail 보강, HomeScreen private feedback polish, Strong anchor/jump design audit 순서로 정리했다.
- 이번 Phase에서는 `lib/`, `test/`, DB, dependency, production code 변경을 수행하지 않았고 main 병합도 수행하지 않는다.

## 2026-06-03 Phase 18-D HomeScreen left target feedback boundary

- Phase 18-D는 large-screen 좌측 control surface에서 현재 우측 `WordExplorerScreen` target을 current target feedback으로 표시한 minimum slice다.
- default Strong list와 search result list 모두 기존 `HomeScreen` private state인 `_largeScreenExplorerWordId`와 각 item의 `wordId` 비교만으로 feedback 기준을 계산한다.
- `ListTile.selected`와 `selectedTileColor`는 Flutter UI feedback 구현 수단으로만 사용하며, selection owner 이전이나 left selection source 도입으로 해석하지 않는다.
- small-screen 기존 `return homePane;` route/detail 흐름은 유지했다.
- Strong Rail, 좌측 단어 추가 버튼, scroll/jump behavior는 구현하지 않았다.
- `WordExplorerScreen` owner state, repository/read owner, `ExplorerWorkspaceState` production source-of-truth 금지선, 새 DB query / 새 repository read / 신규 DTO/model/public API 금지선을 유지했다.

## 2026-06-03 Phase 18-C HomeScreen left control surface boundary

- Phase 18-C는 large-screen `HomeScreen` split shell의 좌측 pane이 단순히 좁아진 목록인지, 장기 left control surface 후보인지 실제 코드 기준으로 조사하고 최소 production-visible UX diff를 적용한 단계다.
- 좌측 pane의 현재 책임은 `HomeScreen` 내부 검색 입력, 기본 Strong 목록, 검색 결과 목록, large-screen target 갱신으로 확인했다.
- large-screen에서 검색 입력 영역을 `homeSearchControlArea`로 분리하고 상단 control surface처럼 보이도록 배경과 하단 경계를 추가했다. 기존 목록은 그 아래에 유지했다.
- 단어 추가 흐름은 `WordGraphScreen` 내부 `_showCreateWordFlow()`와 graph app bar의 `Icons.note_add`에 묶여 있어 좌측 pane으로 이동하지 않았다.
- Strong Rail은 별도 source-of-truth, selection authority, read boundary 정리가 필요하므로 Phase 18-C에서는 구현하지 않고 후보/보류 대상으로 기록했다.
- small-screen 기존 `return homePane;` route/detail 흐름, `WordExplorerScreen` owner state, repository/read owner, `ExplorerWorkspaceState` production source-of-truth 금지선, 새 DB query / 신규 DTO/model/public API 금지선을 유지했다.

## 2026-06-03 Phase 18-B HomeScreen left control pane narrowing

- Phase 18-B는 Strong Rail 완성이 아니라 large-screen `HomeScreen` split shell의 좌측 Home pane을 더 좁은 control pane 방향으로 조정한 minimum slice다.
- large width에서 좌측 Home search/list pane은 `flex: 3`에서 `flex: 2`로 줄이고, 우측 `WordExplorerScreen` Graph/Detail Area는 `flex: 5`에서 `flex: 6`으로 넓혔다.
- small-screen 기존 route/detail 흐름과 `return homePane;` branch는 유지했다.
- `WordExplorerScreen` owner state, repository/read owner, `ExplorerWorkspaceState` production source-of-truth는 변경하지 않았다.
- large-screen 임시 default target은 private constant `H0001_0000`으로 유지했다.

## 2026-06-03 Phase 18-A HomeScreen large-screen split shell

- Phase 18-A는 PC/태블릿 large width에서 `HomeScreen`을 유지한 채 우측에 `WordExplorerScreen` 기반 Explorer pane을 함께 표시하는 첫 production-visible 전환 slice로 진행했다.
- large-screen 기본 Explorer target은 실제 DB에 존재하는 `H0001_0000`을 private constant로 두었고, 추후 H7568 데이터 입력 후 같은 constant만 교체할 수 있게 했다.
- `HomeScreen`의 기존 검색/목록 pane은 좌측에 유지하고, large-screen 목록 선택은 우측 Explorer pane target을 갱신하도록 했다.
- small width에서는 기존 detail/route 진입 흐름을 유지했다.
- small width의 graph/detail은 후속 responsive workspace 정책에서 하나의 workspace 안의 표시 영역으로 재정리해야 하는 follow-up으로 기록했다.
- `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` source-of-truth 승격, `WordExplorerScreen` owner migration, repository/read owner migration은 수행하지 않았다.

## 2026-06-02 Phase 17-B ExplorerWorkspace transition guardrail minimum slice

- Phase 17-B를 test-only guardrail minimum slice로 진행했다.
- `test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart`를 추가했다.
- production route가 `main.dart -> HomeScreen -> WordExplorerScreen` 흐름을 유지하는지 고정했다.
- `HomeScreen` 기본 explorer 진입이 `WordExplorerScreen(initialWordId: normalizedWordId)` 생성 흐름을 유지하는지 고정했다.
- `ExplorerWorkspace`는 production shell 또는 route target으로 mount하지 않았다.
- preview entrypoint, preview screen, preview host, named route wiring은 production 경로에 연결하지 않았다.
- `ExplorerWorkspace` production shell mount, `HomeScreen -> ExplorerWorkspace` route wiring, `WordExplorerScreen` owner migration, `ExplorerWorkspaceState` source-of-truth 승격은 수행하지 않았다.
- repository/read owner migration, persistence authority migration, rollback authority migration은 수행하지 않았다.
- 신규 public API, DTO, model, repository read, DB query는 추가하지 않았다.
- production-visible UX diff는 발생시키지 않았다.

## 2026-06-02 Phase 17-A ExplorerWorkspace implementation candidate selection audit

- Phase 17-A를 docs/audit only로 시작했다.
- Phase 16 boundary 기준으로 Phase 17-B 이후 구현 후보군을 분류했다.
- shell mount, route wiring, owner migration은 직접 구현 후보에서 제외했다.
- `ExplorerWorkspaceState` production source-of-truth 승격을 제외했다.
- projection result 기반 production mutation/read/persistence/restore/rollback을 제외했다.
- `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.
- 실제 구현은 수행하지 않았다.

## 2026-06-02 Phase 16-N ExplorerWorkspace Phase 16 termination audit

- Phase 16-N은 `ExplorerWorkspace Phase 16 termination audit` docs/audit only 단계다.
- 이번 단계는 구현 단계가 아니다.
- Phase 16-A부터 Phase 16-M까지의 audit/boundary 흐름을 종합했다.
- Phase 16은 `ExplorerWorkspace` production transition을 위한 boundary/audit phase로 종료 가능하다고 정리했다.
- `ExplorerWorkspace` shell mount, route wiring, owner migration, `ExplorerWorkspaceState` source-of-truth 승격은 Phase 16에서 승인하지 않았다.
- Phase 17-A는 implementation candidate selection audit으로 시작하며 구현 착수가 아니라고 정리했다.
- 문서 외 변경, 구현 변경, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-M ExplorerWorkspace implementation entry / guardrail redefinition audit

- Phase 16-M은 `ExplorerWorkspace implementation entry / guardrail redefinition audit` docs/audit only 단계다.
- 이번 단계는 구현 단계가 아니다.
- Phase 16-D/E/F/G/H/I/J/K/L의 owner/authority boundary를 종합했다.
- `ExplorerWorkspace` shell mount, route wiring, owner migration, `ExplorerWorkspaceState` source-of-truth 승격은 아직 승인하지 않는다.
- Phase 17-A 후보를 implementation candidate selection audit 또는 guardrail/test 후보 선정으로 제한한다.
- 문서 외 변경, 구현 변경, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-L ExplorerWorkspace rollback authority boundary design

- Phase 16-L은 `ExplorerWorkspace rollback authority boundary design` docs/design only 단계다.
- 이번 단계는 rollback authority migration이 아니다.
- 현재 production rollback authority는 `ExplorerWorkspace`에 없다고 정리했다.
- `ExplorerWorkspaceState`, projection result, `_history`, history snapshot, `ExplorerWorkspaceHistoryEntry`, `WordNavigationHistoryController`는 rollback source-of-truth 또는 rollback/restore authority가 아니라고 정리했다.
- navigation history owner와 rollback authority를 분리했다.
- persistence authority와 rollback authority를 분리했다.
- back/forward navigation은 rollback authority가 아니라고 정리했다.
- 문서 외 변경, 구현 변경, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-K ExplorerWorkspace persistence authority boundary design

- Phase 16-K를 `ExplorerWorkspace persistence authority boundary design` docs/design only 단계로 진행했다.
- 이번 단계는 persistence authority migration이 아니다.
- 현재 production persistence authority는 `ExplorerWorkspace`에 없다고 정리했다.
- `ExplorerWorkspaceState`, projection result, `_history`, history snapshot 계열 값은 persistence source-of-truth 또는 restore authority가 아니라고 정리했다.
- `ExplorerWorkspaceHistoryEntry` 계열 표현은 persistence API나 restore controller가 아니며, `WordNavigationHistoryController`는 in-memory back/forward controller라고 정리했다.
- navigation history owner와 persistence authority를 분리했다.
- route/selection/detail/center/history/repository-read owner와 persistence authority를 분리했다.
- 문서 외 변경, 구현 변경, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-J ExplorerWorkspace repository/read owner boundary design

- Phase 16-J를 `ExplorerWorkspace repository/read owner boundary design` docs/design only 단계로 진행했다.
- 이번 단계는 repository/read owner migration이 아니다.
- 현재 production repository/read owner는 `WordExplorerScreen` 내부 흐름으로 문서화했다.
- `WordRepository`는 현재 `WordExplorerScreen` 내부에서 직접 보유된다고 정리했다.
- `_loadSplitViewDisplayItem(...)`, `_selectWord(...)`, `_initializeExplorerBootstrap()`, `_refreshSelectedWord(...)`의 read 흐름을 현재 production 기준으로 정리했다.
- `_isDetailLoading`, `_detailError`, `_detailUnavailableMessage`는 현재 `WordExplorerScreen` 내부 상태로 정리했다.
- `ExplorerWorkspaceState`는 read result/loading/error/unavailable source-of-truth가 아니라 projection representation으로 고정했다.
- selection/detail/center/history/route owner와 repository-read owner를 분리했다.
- 문서 외 변경, 구현 변경, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-I ExplorerWorkspace navigation history owner boundary design

- Phase 16-I를 `ExplorerWorkspace navigation history owner boundary design` docs/design only 단계로 진행했다.
- 이번 단계는 navigation history owner migration이 아니다.
- 현재 production navigation history owner는 `WordExplorerScreen` 내부 상태로 문서화했다.
- `_history`는 Explorer 내부 navigation history 표시와 back/forward 이동 판단의 production visible UI source-of-truth로 정리했다.
- `ExplorerWorkspaceState.history` 계열 값은 projection representation으로 고정했다.
- selection/detail/center/repository-read/route owner와 navigation history owner를 분리했다.
- `ExplorerWorkspace`는 navigation history controller, rollback authority, production shell이 아니라고 정리했다.
- 문서 외 변경, 구현 변경, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-H ExplorerWorkspace detail target owner boundary design

- Phase 16-H를 `ExplorerWorkspace detail target owner boundary design` docs/design only 단계로 진행했다.
- 이번 단계는 detail target owner migration이 아니다.
- 현재 production detail target owner를 `WordExplorerScreen` 내부 상태로 문서화했다.
- `_selectedWordDisplayItem`은 detail pane 표시 대상의 production visible UI source-of-truth로 정리했다.
- `_selectedWordId`와 `_selectedWordDisplayItem`은 관련되지만 동일 개념으로 병합하지 않는다고 정리했다.
- `ExplorerWorkspaceState.detailTargetWordId` 계열 값은 projection representation으로 고정했다.
- selection/detail/center/history/repository-read owner를 분리했다.
- shell mount, route wiring, owner migration, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-G ExplorerWorkspace graph center owner boundary design

- Phase 16-G를 `ExplorerWorkspace graph center owner boundary design` docs/design only 단계로 진행했다.
- 현재 production 기준 graph center owner는 `WordExplorerScreen` 내부 상태로 문서화했다.
- `_centerWordId`는 현재 Explorer graph center의 production visible UI source-of-truth로 정리했다.
- `ExplorerWorkspaceState.centerWordId`는 graph center owner state가 아니라 projection representation으로 고정했다.
- `ExplorerWorkspace`는 graph center controller가 아니며 production shell도 아니라고 명시했다.
- graph center owner와 selection owner, detail target owner, navigation history owner를 분리했다.
- shell mount, route wiring, owner migration, projection result 기반 selection/detail/center/history mutation은 not approved 상태로 유지한다.
- `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 수행하지 않았다.

## 2026-06-02 Phase 16-F ExplorerWorkspace selection owner boundary design

- Phase 16-F를 `selection owner boundary design` docs/design only 단계로 진행했다.
- 현재 production selection owner는 `WordExplorerScreen` 내부 상태로 문서화했다.
- `_selectedWordId`는 현재 선택 단어 id의 production visible UI source-of-truth로, `_selectedWordDisplayItem`은 현재 detail pane 표시 대상의 production visible UI source-of-truth로 구분했다.
- `ExplorerWorkspaceState.selectedWordId` / `detailTargetWordId` 계열 값은 owner state가 아니라 projection representation으로 정리했다.
- selection owner와 detail target owner, graph center owner, navigation history owner를 분리했다.
- `ExplorerWorkspaceState`는 selection event controller가 아니며 selection mutation, history mutation, detail target 결정, graph center 변경을 소유하지 않는다고 명시했다.
- selection owner migration, shell mount, route wiring, projection result 기반 selection/history/detail/center mutation은 승인되지 않은 상태로 유지한다.
- `lib/`, `test/`, DB, dependency, platform 파일 변경은 수행하지 않았다.
- Phase 16-G의 1차 후보는 `graph center owner boundary design`으로 두고, 대안 후보는 `detail target owner boundary design` 또는 `selection guardrail design`으로 정리했다.

## 2026-06-01 Phase 16-E ExplorerWorkspace projection/source-of-truth boundary design

- Phase 16-E를 `projection/source-of-truth boundary design` docs/design only 단계로 진행했다.
- 현재 production visible UI source-of-truth는 `WordExplorerScreen` 내부 상태로 문서화했다.
- `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, `_history`, detail loading/error/unavailable state, `WordRepository` read result를 현재 production 구조 기준 source-of-truth로 정리했다.
- `ExplorerWorkspaceState`는 production visible UI source-of-truth가 아니라 projection / contract representation으로 문서화했다.
- `_readOnlyWorkspaceProjection`은 source-of-truth가 아니라 read-only projection entry로 정리했다.
- `WordExplorerWorkspaceProjectionAdapter.project(...)`는 source-of-truth adapter가 아니라 projection adapter로 정리했다.
- `ExplorerWorkspaceState`가 selection, center, detail, history, repository/read, persistence authority, rollback authority가 아님을 명시했다.
- owner migration, route wiring, shell mount, projection result persistence/history/source-of-truth usage는 승인되지 않은 상태로 유지한다.
- `lib/`, `test/`, DB, dependency, platform 파일 변경은 수행하지 않았다.
- Phase 16-F의 1차 후보는 `selection owner boundary design`으로 두고, 대안 후보는 `projection guardrail design`으로 정리했다.

## 2026-06-01 Phase 16-D ExplorerWorkspace route owner boundary design

- Phase 16-D를 `route owner boundary design` docs/design only 단계로 진행했다.
- 현재 production canonical route는 `main.dart -> HomeScreen -> WordExplorerScreen`로 유지한다.
- `HomeScreen`은 현재 production route entry owner에 가장 가까운 위치로 문서화했다.
- `WordExplorerScreen`은 현재 Explorer production route target으로 문서화했다.
- `ExplorerWorkspace`는 route owner가 아니며 preview/read-only/projection boundary로 유지한다.
- `ExplorerWorkspaceState`는 route state source-of-truth가 아니며 production visible UI source-of-truth로 승격하지 않는다고 명시했다.
- ExplorerWorkspace shell mount, route wiring, route registration, route collapse, canonical owner migration, Navigator authority migration, owner/controller/coordinator migration은 금지선으로 유지한다.
- Provider / Repository / persistence authority migration, 신규 repository read, 신규 DB query, 신규 DTO/model/public API 추가, `lib/`, `test/`, dependency 변경은 수행하지 않았다.
- Phase 16-E의 1차 후보는 `Phase 16-E projection/source-of-truth boundary design`으로 두고, 대안 후보는 `Phase 16-E route owner guardrail design`으로 정리했다.

## 2026-06-01 Phase 16-C ExplorerWorkspace transition path sequencing audit

- Phase 16-C를 `transition path sequencing audit` docs/audit only 단계로 진행했다.
- 이번 단계는 구현, UX 변경, shell mount, route wiring 단계가 아니다.
- Phase 16-B blocker inventory를 기반으로 blocker 처리 순서를 문서상 정리했다.
- route owner를 최우선 sequencing 항목으로 두고, projection/source-of-truth, selection owner, graph center owner, detail target owner, navigation history owner, repository/read owner, persistence authority, guardrail redefinition, rollback boundary 순으로 검토하는 구조를 기록했다.
- 각 항목을 `audit only`, `design documentation required`, `guardrail test required`, `implementation phase required` 유형으로 분류했다.
- 현재 production canonical route는 `main.dart -> HomeScreen -> WordExplorerScreen`로 유지한다.
- `ExplorerWorkspace`는 production owner가 아니라 preview/read-only/projection boundary로 유지한다.
- `ExplorerWorkspaceState`는 production visible UI source-of-truth로 승격하지 않는다.
- Phase 16-D 후보는 `Phase 16-D route owner boundary design` 또는 `Phase 16-D owner migration order design` 계열로 제안한다.
- 변경 범위는 docs/audit only이며 `lib/`, `test/`, 플랫폼, dependency 파일은 변경하지 않는다.

## 2026-06-01 Phase 16-B ExplorerWorkspace production transition blocker inventory

- Phase 16-B를 `production transition blocker inventory` docs/audit only 단계로 진행했다.
- 이번 단계는 구현, UX 변경, shell mount, route wiring 단계가 아니다.
- 현재 production canonical route는 `main.dart -> HomeScreen -> WordExplorerScreen`로 유지한다.
- `ExplorerWorkspace`는 production owner가 아니라 preview/read-only/projection boundary로 유지한다.
- `ExplorerWorkspaceState`는 production visible UI source-of-truth로 승격하지 않는다.
- route owner blocker, repository/read owner blocker, selection owner blocker, graph center owner blocker, detail target owner blocker, navigation history owner blocker, persistence authority blocker, projection/source-of-truth blocker, guardrail redefinition blocker, rollback boundary blocker를 문서상 정리했다.
- Phase 16-C 후보는 `transition path sequencing audit` 또는 `owner migration order design` 계열로 제안한다.
- 변경 범위는 docs/audit only이며 `lib/`, `test/`, 플랫폼, dependency 파일은 변경하지 않는다.

## 2026-06-01 Phase 16-A ExplorerWorkspace production transition readiness audit

- Phase 16-A를 `ExplorerWorkspace production transition readiness audit`로 시작했다.
- 이번 단계는 구현, UX 변경, shell mount, route wiring 단계가 아니라 docs/audit only 단계다.
- 현재 production canonical route는 `main.dart -> HomeScreen -> WordExplorerScreen`로 유지하며, Phase 16-A에서는 이 구조를 변경하지 않는다.
- 현재 `ExplorerWorkspace`는 production owner가 아니라 preview/read-only/projection boundary로 유지한다.
- `ExplorerWorkspaceState`는 production visible UI source-of-truth가 아니라 projection/contract boundary로 해석한다.
- production transition 논의 전에 route owner, repository/read owner, selection owner, graph center owner, detail target owner, navigation history owner, persistence authority, projection/source-of-truth boundary를 문서상 점검해야 한다고 기록했다.
- Phase 16-B의 1차 후보는 `production transition blocker inventory`로 제안한다. 이 후보는 구현 단계가 아니라 추가 audit 단계로 해석한다.
- 변경 범위는 docs/audit only이며 `lib/`, `test/`, 플랫폼, dependency 파일은 변경하지 않는다.

## 2026-06-01 Phase 15-C termination audit

- Phase 15-C를 구현, test fix, UI 변경 단계가 아니라 Phase 15 전체 종료 가능 여부를 판단하는 termination audit 단계로 기록했다.
- Phase 15-A는 minimum production-visible UX diff candidate selection audit로 진행되었고, Phase 15-B 후보를 `WordExplorerScreen` detail pane 선택 없음 empty state 안내 가독성 개선 하나로 제한했다.
- Phase 15-A에서 context strip 추가 개선은 보류했고, graph/history/navigation 표시 개선과 `ExplorerWorkspace` shell mount 또는 route 전환 후보는 제외했다.
- Phase 15-B는 `WordExplorerScreen` detail pane 선택 없음 empty state 안내를 개선했다. 실제 UI 문구는 `그래프에서 단어를 선택하세요`, `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`, `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`이다.
- Phase 15-B 구현 범위는 `_buildNoSelectionDetailPanel()` 내부 표시 개선으로 제한했고, `ConstrainedBox(maxWidth: 360)` 추가와 신규 guardrail test 추가만 수행했다.
- Phase 15-B 테스트 결과는 신규 empty state guardrail `+4: All tests passed!`, Phase 12-B context strip guardrail `+4: All tests passed!`, Phase 14-B context strip readability `+5: All tests passed!`, composition boundary `+6: All tests passed!`, 전체 `flutter test --reporter compact` `+237: All tests passed!`로 기록한다.
- 클라이언트 UI 기반 테스트는 성공 확인됨으로 기록한다.
- Phase 15 전체에서 `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, 새 repository read, 새 DB query, dependency 변경, 플랫폼 파일 변경은 수행하지 않았다.
- Phase 15는 후보 선정, 최소 UX diff 구현, 명령어 기반 테스트, 클라이언트 UI 확인, 문서 최신화까지 완료했으므로 종료 가능하다.
- Phase 15-C는 docs/audit only 변경이며 `lib/`, `test/`, production code 변경이 없으므로 전체 `flutter test`는 실행하지 않는다. Phase 15-B에서 전체 `flutter test --reporter compact`는 `+237: All tests passed!`로 이미 확인되었다.

## 2026-05-31 Phase 15-B WordExplorerScreen 선택 없음 empty state 안내 가독성 개선

- Phase 15-B를 production-visible UX diff 단계로 기록했다.
- 변경 대상은 `WordExplorerScreen` detail pane 선택 없음 empty state 안내이며, 구현 범위는 `lib/ui/word_explorer_screen.dart`의 `_buildNoSelectionDetailPanel()` 내부 표시 개선으로 제한했다.
- 실제 UI 문구는 `그래프에서 단어를 선택하세요`, `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`, `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`로 정리했다.
- 기존 아이콘 기반 empty state 구조와 `Center`, `Padding`, `Column` 기반 레이아웃을 유지하고, 읽기 폭 제한을 위해 `_buildNoSelectionDetailPanel()` 내부에 `ConstrainedBox(maxWidth: 360)`만 추가했다.
- route/shell/owner/repository/DTO/projection source-of-truth/DB query 변경은 없다. `_buildDetailPaneContextStrip()`, `_readOnlyWorkspaceProjection`, `HomeScreen`, `WordGraphScreen`, `WordInfoPanel`, domain/model/public API도 변경하지 않았다.
- 신규 guardrail test `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart`를 추가해 empty state 문구, 사용자 기준 표현, 금지 marker 부재, 기존 context strip과 `HomeScreen -> WordExplorerScreen` 진입 구조 유지를 확인했다.
- 테스트 결과 `flutter test test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart --reporter expanded`는 `+4: All tests passed!`, Phase 12-B context strip 테스트는 `+4: All tests passed!`, Phase 14-B context strip readability 테스트는 `+5: All tests passed!`, composition boundary test는 `+6: All tests passed!`, 전체 `flutter test --reporter compact`는 `+237: All tests passed!`로 통과했다.
- 클라이언트 UI 기반 테스트는 CodeX 수행 대상이 아니며, 클라이언트 UI 기반 테스트 성공 확인됨으로 기록한다. 클라이언트가 확인한 실제 UI 문구는 `그래프에서 단어를 선택하세요`, `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`, `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`이다.

## 2026-05-31 Phase 15-A minimum production-visible UX diff candidate selection audit

- Phase 15-A를 구현 단계가 아니라 docs/audit only 단계로 기록했다.
- Phase 14-B 이후 추가 minimum production-visible UX diff를 재개할 수 있는지 후보군을 비교했다.
- Phase 15-B 후보는 `WordExplorerScreen` detail pane 선택 없음 empty state 안내 가독성 개선 하나로 제한했다.
- 후보 B인 context strip 추가 개선은 Phase 14-B 직후 같은 영역을 연속 수정하는 것이므로 보류했다.
- 후보 C인 graph/history/navigation 관련 표시 개선은 navigation/history owner, availability probe, repository probe와 결합될 위험이 있어 제외했다.
- 후보 D인 `ExplorerWorkspace` shell mount 또는 route 전환은 명시적 금지선에 해당하므로 제외했다.
- `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, 새 repository read, 새 DB query는 계속 금지한다.
- 이번 단계에서는 production code, test code, dependency, 플랫폼 파일을 변경하지 않는다.
- 전체 `flutter test --reporter compact`는 docs/audit only 변경이며 production code/test code 변경이 없으므로 실행하지 않는 것으로 판단한다.

## 2026-05-31 Phase 14-C termination audit

- Phase 14-C를 구현, test fix, UI 변경 단계가 아니라 Phase 14 전체 종료 가능 여부를 판단하는 termination audit 단계로 기록했다.
- Phase 14-A는 minimum production-visible UX diff candidate selection audit로 진행되었고, 후보를 `WordExplorerScreen` detail pane 상단 read-only context strip 표시 가독성 개선 하나로 제한했다.
- Phase 14-A에서 `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 금지선을 재확인했다.
- Phase 14-B는 `WordExplorerScreen` detail pane 상단 read-only context strip 표시 가독성 개선을 구현했다. 중심 단어와 선택 단어를 가능한 경우 대표 표기 / Strong 번호 / transliteration 기반으로 표시하고, 값이 부족하면 기존 word id fallback을 유지하며, 선택 없음 상태는 `선택 없음`으로 유지했다.
- Phase 14-B 구현은 빈 segment를 생략해 빈 괄호, 중복 구분자, 의미 없는 공백을 방지하는 범위에 머물렀다.
- Phase 14 전체에서 `ExplorerWorkspace` shell mount, route wiring / route registration 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, projection result persistence/history/source-of-truth 사용, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, 새 repository read, 새 DB query, route collapse, canonical owner migration, Level 3 production-visible consumer 승격은 수행하지 않았다.
- Phase 14-B 테스트 결과는 Phase 12-B context strip 테스트 `+4: All tests passed!`, Phase 14-B context strip readability 테스트 `+5: All tests passed!`, composition boundary test `+6: All tests passed!`, 전체 `flutter test --reporter compact` `+233: All tests passed!`로 기록한다. 클라이언트 UI 기반 테스트도 성공 확인되었다.
- Phase 14는 후보 선정, 최소 UX diff 구현, 테스트/문서/UI 확인까지 완료했고 remaining red가 없으므로 종료 가능하다. 다음 Phase에서도 별도 승인 전까지 shell mount, route wiring, owner/authority migration은 계속 금지한다.
- Phase 14-C는 docs/audit only 변경이므로 전체 `flutter test`는 실행하지 않는다. Phase 14-B에서 전체 `flutter test --reporter compact`는 `+233: All tests passed!`로 이미 확인되었다.

## 2026-05-31 Phase 14-B WordExplorerScreen context strip 표시 가독성 개선

- Phase 14-B를 production-visible UX diff 단계로 기록했다. 변경 목적은 기존 `WordExplorerScreen` detail pane 상단 read-only context strip을 raw word id 중심 표시에서 대표 표기 / Strong 번호 / transliteration 중심의 사람이 읽기 쉬운 표시로 개선하는 것이다.
- 변경 범위는 `lib/ui/word_explorer_screen.dart` 내부 private helper 기반 표시 조합, Phase 12-B guardrail 테스트 현행화, Phase 14-B source-level 가독성 테스트 추가, 관련 UX 문서 반영으로 제한했다.
- 중심 단어 표시는 기존 `_centerDisplaySeed`의 대표 표기, Strong 번호, transliteration 값을 우선 사용하고, 값이 부족하면 기존 `_centerWordId` fallback을 유지한다.
- 선택 단어 표시는 기존 `_selectedWordDisplayItem`의 대표 표기, Strong 번호, 첫 번째 비어 있지 않은 transliteration 값을 우선 사용하고, 선택 단어 display item이 없으면 기존 `_selectedWordId` fallback을 유지한다. 선택이 없으면 `선택 없음`을 유지한다.
- 빈 값은 표시 segment에서 제외해 빈 괄호, 중복 구분자, 의미 없는 공백이 생기지 않도록 했다.
- 새 repository read, 새 DB query, route wiring 변경, Navigator 변경, Provider / Repository / persistence authority 변경, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, `ExplorerWorkspace` shell mount는 수행하지 않았다.
- 테스트 결과 `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart --reporter expanded`는 `+4: All tests passed!`, `flutter test test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart --reporter expanded`는 `+5: All tests passed!`, `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded`는 `+6: All tests passed!`, 전체 `flutter test --reporter compact`는 `+233: All tests passed!`로 통과했다.
- 변경 범위 확인 결과 tracked 변경 파일 4개와 untracked 신규 테스트 파일 1개가 모두 허용 파일 안에 있었다. 플랫폼 경로와 `pubspec.yaml`, `pubspec.lock` 변경은 없고, `git diff --check`는 whitespace 오류 없이 문서 2개의 줄바꿈 경고만 출력했다.

## 2026-05-31 Phase 14-A minimum production-visible UX diff candidate selection audit

- Phase 14-A를 docs/audit only 단계로 기록했다. 목적은 Phase 13 composition boundary guardrail green 이후 추가 production-visible UX diff 재개 가능성을 판단하기 위한 minimum production-visible UX diff candidate selection audit를 수행하는 것이다.
- 이번 단계에서는 구현을 하지 않는다.
- 이번 단계에서는 production-visible UX diff를 수행하지 않는다.
- 유지 금지선은 ExplorerWorkspace shell mount 금지, route wiring / route registration 변경 금지, `HomeScreen -> WordExplorerScreen` 진입 구조 변경 금지, owner/controller/coordinator migration 금지, Provider / Repository / Navigator / persistence authority migration 금지, DTO/model/public API 추가 금지, projection result persistence/history/source-of-truth 사용 금지, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 금지, route collapse 금지, canonical owner migration 금지, Level 3 production-visible consumer 승격 금지로 정리했다.
- Phase 14-A의 우선 후보는 `WordExplorerScreen` detail pane 상단 read-only context strip 표시 가독성 개선 하나로 제한했다.
- 이 후보는 Phase 12-B에서 도입한 context strip의 후속 최소 개선으로 기록하되, Phase 14-A에서는 구현하지 않고 후보로만 남긴다.
- 후보 평가는 기존 private/local state 사용 가능성, `ExplorerWorkspaceState` projection visible UI source-of-truth 미사용 가능성, route/owner/authority 변경 없음 여부를 기준으로 정리했다.
- Phase 14-B는 후보가 하나로 제한되고 금지선, 테스트 조건, UI 확인 방법이 명확해진 뒤 별도 feature 브랜치에서 진행해야 한다.
- 전체 `flutter test`는 문서/audit only 변경이면 미실행 가능하며, 미실행 시 사유를 명확히 기록한다.

## 2026-05-31 Phase 13-C termination audit

- Phase 13-C를 구현, test fix, UX 변경 단계가 아니라 Phase 13 전체 종료 가능 여부를 판단하는 termination audit 단계로 기록했다.
- Phase 13-A는 Phase 4-E blanket `explorer_workspace/` import ban의 원래 목적을 재확인하고, read-only projection/adapter import allowed 기준과 preview/shell/route/authority 유입 forbidden 기준을 문서화했다.
- Phase 13-B는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`를 현행 정책에 맞게 수정했고, read-only projection/adapter import 허용과 preview/shell/route/history/authority 유입 차단을 함께 유지했다.
- Phase 13-B 결과 기존 remaining red 1건이 해소되었다.
- Phase 13-C에서는 추가 production-visible UX diff를 수행하지 않는다.
- 이후 추가 UX diff를 재개하려면 별도 Phase에서 `ExplorerWorkspace` shell mount 금지 유지 여부, route wiring 변경 여부, owner/controller/coordinator migration 여부, Provider / Repository / Navigator / persistence authority migration 여부, DTO/model/public API 추가 여부, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 여부, rollback 가능한 최소 production-visible UX diff인지 여부를 다시 확인해야 한다.
- 명령어 기반 확인 결과, 전체 `flutter test --reporter compact`는 `+228: All tests passed!`로 통과했고 composition boundary test 개별 실행은 `+6: All tests passed!`로 통과했다. 문서 반영 검색은 확인되었고, `lib/`, `test/`, 플랫폼, dependency 변경 없음, production UI diff 없음, 변경 파일 문서 2개, whitespace 오류 없음으로 확인했다.

## 2026-05-31 Phase 13-B composition boundary guardrail test 현행화

- Phase 13-B를 production code 변경이 아니라 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`의 test guardrail fix 단계로 기록했다.
- Phase 13-A에서 문서화한 allowed / forbidden 기준을 테스트에 반영해, `explorer_workspace/` 전체 production source blanket ban을 read-only projection/adapter import 허용 정책으로 현행화한다.
- `WordExplorerScreen` 내부의 `explorer_workspace_contract.dart`, `word_explorer_workspace_projection_adapter.dart`, `ExplorerWorkspaceState`, `ExplorerWorkspaceLayoutPreset`, `ExplorerWorkspaceTransitionOrigin` 참조는 allowed boundary로 유지한다.
- `ExplorerWorkspacePreviewScreen`, `ExplorerWorkspacePreviewInteractionHost`, `ExplorerWorkspacePreviewInput`, `ExplorerWorkspaceHistoryEntry`, `explorer_workspace.dart`, preview screen/interaction host import, `ExplorerWorkspace shell` mount, route/owner/Provider/Repository/Navigator/persistence authority 유입은 forbidden boundary로 유지한다.
- 이번 단계에서는 `lib/`, 플랫폼, dependency, DB, repository/provider/navigator/route production code를 수정하지 않는다.
- 추가 production-visible UX diff는 하지 않는다. UI 기반 테스트도 수행 대상이 아니며 클라이언트 UI 확인 대상이 없다.
- 명령어 기반 확인 결과, 개별 composition boundary test는 `+6: All tests passed!`로 통과했고 전체 `flutter test --reporter compact`는 `+228: All tests passed!`로 통과했다.
- 문서 반영 검색은 확인되었고, `lib/`, 플랫폼, dependency 파일 변경은 없으며 변경 파일은 테스트 파일 1개와 문서 2개로 제한되었다. `git diff --check`도 출력 없음으로 확인했다.

## 2026-05-31 Phase 13-A composition boundary guardrail 재정의 audit

- Phase 13-A를 구현이나 test fix가 아니라 docs/audit 단계로 기록했다. 목적은 Phase 4-E production import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 흐름의 충돌을 문서 기준으로 재정의하는 것이다.
- Phase 4-E guardrail의 원래 목적은 preview-only composition이 production owner 또는 source of truth로 유입되는 것을 막는 것이었다고 정리했다.
- Phase 7 이후 `WordExplorerScreen`의 read-only projection/adapter import는 `ExplorerWorkspace` shell mount, route 변경, owner migration이 아니며, 기존 owner state를 `ExplorerWorkspaceState` snapshot으로 읽는 one-way read-only boundary라고 구분했다.
- 현재 남은 red 1건은 production 기능 오류가 아니라 Phase 4-E blanket import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 정책의 불일치로 기록했다.
- `explorer_workspace/` import를 전면 금지하는 기존 guardrail은 노후화되었으며, allowed import와 forbidden import를 분리한 새 composition boundary guardrail로 재정의해야 한다고 기록했다.
- allowed 범위는 `WordExplorerScreen` 내부 read-only projection adapter import, `ExplorerWorkspaceState` / `ExplorerWorkspaceLayoutPreset` / `ExplorerWorkspaceTransitionOrigin` read-only 참조, 기존 owner state를 projection으로 읽는 assert/probe 용도, repository / Navigator / persistence / route authority를 이전하지 않는 참조로 제한했다.
- forbidden 범위는 `ExplorerWorkspace` shell mount, `ExplorerWorkspacePreviewScreen` production route 연결, `ExplorerWorkspacePreviewInteractionHost` production 연결, `ExplorerWorkspacePreviewInput` production route/input contract 소비, `ExplorerWorkspaceHistoryEntry` production history/source-of-truth 사용, `main.dart` route/default home 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, 추가 production-visible UX diff로 분리했다.
- 이번 단계에서는 `explorer_workspace_phase4e_composition_boundary_test.dart`, `lib/`, `test/`, UI, 플랫폼, dependency 파일을 수정하지 않았다.
- 전체 `flutter test`는 실행하지 않았다. 이번 단계는 문서/audit 변경만 수행했기 때문이다.
- 명령어 기반 확인 결과, 문서 반영 검색은 확인되었고 `lib/`, `test/`, 플랫폼, dependency 파일 변경은 없으며 production UI diff와 whitespace 오류도 없었다.
- 커밋 전 최신 커밋은 `ca0b32e docs: ExplorerWorkspace Phase 12-M 종료 audit 정리`로 확인했다.

## 2026-05-26 Phase 12-M termination audit

- Phase 12-M을 구현 단계가 아니라 Phase 12 종료 audit 단계로 기록했다. 목적은 Phase 12-A부터 Phase 12-L까지의 결과를 종합해 Phase 12 종료 가능 여부와 Phase 13 carryover를 확정하는 것이다.
- Phase 12-A는 minimum production-visible candidate selection audit로 full `ExplorerWorkspace` shell mount를 직접 후보에서 제외했고, Phase 12-B는 기존 `HomeScreen -> WordExplorerScreen` 경로 안에서 `WordExplorerScreen` detail pane 상단 read-only context strip을 추가했다.
- Phase 12-C부터 Phase 12-L까지는 첫 production-visible UX diff 평가, baseline red inventory, package/import baseline fix, remaining baseline red review, `word_info_panel_test.dart` baseline 현행화, remaining baseline red triage, `word_repository_read_source_policy_test.dart` baseline 현행화, final red decision audit, representative query expectation baseline 현행화, termination and boundary carryover audit를 순서대로 정리했다.
- Phase 12에서 실제로 발생한 production-visible UX 변경은 `WordExplorerScreen` detail pane 상단 read-only context strip 추가 하나로 한정한다.
- Phase 12에서는 `ExplorerWorkspace` shell mount, route 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI 사용을 수행하지 않았고, 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지했다.
- 새로 개발과 병렬 개발은 보류했고, 기존 방식의 점진 안정화 전략을 유지했다.
- baseline test red는 전체 `flutter test --reporter compact` 기준 `+204 -6 -> +227 -1`로 개선되었다.
- 남은 red는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건이다.
- 남은 red는 production 기능 오류가 아니라, Phase 4-E production import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 범위의 정책 불일치로 기록했다.
- 남은 red는 Phase 12-M에서 직접 수정하지 않고 Phase 13 guardrail 재정의 또는 별도 boundary policy phase로 이월한다.
- Phase 12는 첫 production-visible UX diff 도입과 baseline red 대폭 축소라는 핵심 목적을 달성했다. 남은 composition boundary red 1건은 Phase 13 guardrail 재정의 과제로 이월 가능하므로 Phase 12는 종료 가능하다.
- Phase 13 첫 작업은 composition boundary guardrail 재정의 여부 판단으로 시작해야 하며, 추가 production-visible UX diff는 guardrail 정리 이후 재검토한다.
- `ExplorerWorkspace` shell mount, route 변경, owner/controller/coordinator migration은 별도 승인 전까지 금지한다.
- Phase 13은 새 ChatGPT 채팅에서 시작하는 것을 권장한다.
- 이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않았다.
- 명령어 기반 확인 결과, 전체 `flutter test --reporter compact`는 `+227 -1`로 종료되었고 남은 실패는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건이었다.
- 남은 red 개별 실행 결과는 `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` 기준 `+5 -1`이며, 실패 지점은 `production import tree does not reference preview composition`이다.
- Phase 12-M 기록 검색은 확인되었고, `lib/`, `test/`, 플랫폼, dependency 파일 변경은 없으며, production UI diff와 whitespace 오류도 없었다.

## 2026-05-26 Phase 12-L termination and boundary carryover audit

- Phase 12-L을 수정 단계가 아니라 `termination and boundary carryover audit` 단계로 기록했다. 목적은 Phase 12 종료 가능성과 마지막 `composition boundary` red의 Phase 13 이월 여부를 실제 명령 결과 기준으로 판단하는 것이다.
- Phase 12는 첫 production-visible UX diff를 제한적으로 도입했고, `WordExplorerScreen` detail pane 상단에 read-only context strip을 추가했다.
- 기존 `HomeScreen -> WordExplorerScreen` 진입 경로는 유지했다.
- `ExplorerWorkspace` shell mount, route 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI 사용은 수행하지 않았다.
- Phase 12-D 이후 baseline red는 전체 `flutter test --reporter compact` 기준 `+204 -6`에서 `+227 -1`로 개선되었다.
- Phase 12-L 기준 전체 `flutter test --reporter compact` 결과는 `+227 -1`이며, 남은 red는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건이다.
- 남은 red 개별 실행 결과는 `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` 기준 `+5 -1`이다.
- 실패 내용은 `lib/ui/word_explorer_screen.dart`의 `explorer_workspace/` contract/adapter import로 인해 `production import tree does not reference preview composition` source-level guardrail이 불일치하는 것이다.
- 이 실패는 단순 오래된 API 참조나 기대값 현행화가 아니라, Phase 4-E production import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 범위가 충돌하는 문제로 판단했다.
- 따라서 Phase 12에서 임의로 테스트를 수정하지 않고, Phase 13 전환 정책 또는 별도 guardrail 재정의 phase로 이월한다.
- Phase 12는 첫 production-visible UX diff 도입과 baseline red 대폭 축소라는 핵심 목적을 달성했다. 남은 composition boundary red 1건은 Phase 13 guardrail 재정의 과제로 이월 가능하므로 Phase 12-M 종료 audit로 진행할 수 있다.
- 추가 production-visible UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화 전략을 유지한다.
- 이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않았다.

## 2026-05-26 Phase 12-K representative query expectation baseline 현행화

- Phase 12-K의 목적은 Phase 12-J에서 test-only fix 후보로 선정한 `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`의 representative query expectation을 현행 seed DB/fixture 결과와 production duplicate candidate 정책에 맞춰 현행화하는 것이다.
- `duplicate candidates use representative spelling for non-strong matches` 계열 기대값을 기존 1건에서 현행 반환 3건 기준으로 조정했다.
- 실제 반환 3건은 seed DB 기존 후보 `H3722_0000`(`כָּפַר`, `H3722`, 의미 `덮다`), `H3723_0000`(`כָּפָר`, `H3723`, 의미 `마을/촌락`) 2건과 테스트 삽입 후보 `T9000_H1_DUPLICATE_NON_STRONG`(`כְּפַר`, strong 없음, 의미 `non strong meaning`) 1건이다.
- 테스트는 단순 count assertion 삭제가 아니라 candidate id, language, strong number, representative spelling, primary meaning을 검증하도록 조정했다.
- production code와 `WordRepository` production 구현은 변경하지 않았다.
- seed DB와 fixture DB는 변경하지 않았다.
- ExplorerWorkspace UX, `WordExplorerScreen`, context strip, route/shell/authority/API는 변경하지 않았다.
- Phase 12-J remaining red 중 representative query 1건을 정리 대상으로 기록하고, 남은 baseline red는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건으로 유지한다.
- 명령어 기반 확인 결과, representative query contract test는 `+6: All tests passed!`로 통과했고 전체 `flutter test --reporter compact` 결과는 기존 `+226 -2`에서 `+227 -1`로 변했다. 새 branch-only 실패는 없으며 남은 실패는 기존 `explorer_workspace_phase4e_composition_boundary_test.dart` 1건과 일치한다.
- 추가 production-visible UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화를 계속한다.

## 2026-05-26 Phase 12-J final red decision audit

- Phase 12-J를 수정 단계가 아니라 docs/audit 및 final red decision audit 단계로 기록했다. 목적은 Phase 12-I 이후 남은 baseline red 2건의 성격을 실제 명령 결과 기준으로 판단하고 Phase 12-K 또는 Phase 13 방향을 결정하는 것이다.
- Phase 12-I 이후 main 기준 전체 `flutter test --reporter compact` 결과는 `+226 -2`로 유지되었다.
- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`는 `duplicate candidates use representative spelling for non-strong matches`에서 기대 1건 대비 실제 `DuplicateCandidateDisplayItem` 3건 반환으로 실패했다.
- seed DB 확인 결과, 테스트 삽입 전에도 히브리어 대표 표기 정규화 기준 `כפר` 후보가 `H3722_0000`, `H3723_0000` 2건 존재했다. 따라서 실제 3건은 seed DB 2건과 테스트 삽입 1건의 합계로 설명되며, 현 판단은 데이터 정책 변경이 아니라 representative query expectation test 현행화 대상이다.
- `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`는 `production import tree does not reference preview composition`에서 `lib/ui/word_explorer_screen.dart`의 `explorer_workspace/` contract/adapter import 때문에 source-level guardrail 불일치로 실패했다.
- 현재 `explorer_workspace/` 참조는 preview composition mount가 아니라 Phase 7 이후 read-only projection chain, Phase 8 hidden probe, Phase 10 candidate representation reader, Phase 12-B context strip guardrail 흐름에서 발생한다. 따라서 이 항목은 단순 금지어 테스트 현행화가 아니라 ExplorerWorkspace composition boundary guardrail 재정의 대상으로 판단했다.
- Phase 12-J 결론은 선택지 D로 기록했다. Phase 12-K 후보는 `word_repository_phase8h1_representative_query_contract_test.dart`의 representative query expectation test 현행화이며, `explorer_workspace_phase4e_composition_boundary_test.dart`는 Phase 13 전환 정책 또는 별도 guardrail 재정의 phase로 이월한다.
- Phase 12 종료 audit 가능 조건은 Phase 12-K 이후 남은 실패가 composition boundary 1건으로 축소되는지 확인하고, 해당 guardrail을 Phase 13 전환 정책으로 명시 이월하는 것이다. zero-red를 Phase 12 종료 필수 조건으로 삼는 경우에는 composition boundary guardrail 재정의까지 Phase 12 안에서 처리해야 한다.
- 이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않았다.
- 추가 production-visible UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화를 계속한다.

## 2026-05-26 Phase 12-I read source policy test baseline fix

- Phase 12-I의 목적은 Phase 12-H remaining red 중 `test/data/repositories/word_repository_read_source_policy_test.dart` 1건을 현행 `WordRepository` API 기준으로 정리하는 것이다.
- 오래된 `WordRepository` API 참조인 `getWordMapByIdForSplitViewSingleWord`, `getWordDetailMapByIdForReadSourcePhase2Only`를 현행 typed API인 `getWordDetailLikeDisplayItemByIdForSplitView`, `getWordDetailLikeDisplayItemByIdForDetailScreen` 기준으로 현행화했다.
- 테스트 파일 내부에 `WordDetailLikeDisplayItem` import를 추가하고, `_expectSameDetailDisplay(...)` helper가 raw row와 typed display item을 비교할 수 있도록 최소 조정했다.
- 현행 production code에서 `getWordMapById`, `getWordMapByIdForExplorerSingleWord`는 `_phase8ARawSingleWordContexts`에 포함되어 `ReadSourcePolicy.normalizedWithFallback` 경로를 사용하므로, 관련 read source policy assertion을 실제 production 경로에 맞춰 조정했다. 전역 기본값 `debugCurrentReadSourcePolicy == ReadSourcePolicy.legacy`는 유지된다.
- 이번 단계는 test baseline fix이며 UX 변경이 아니다.
- production code와 `WordRepository` production 구현은 변경하지 않았다.
- ExplorerWorkspace UX, `WordExplorerScreen`, context strip, route/shell/authority/API는 변경하지 않았다.
- Phase 12-H remaining red 중 `word_repository_read_source_policy_test.dart` 1건을 정리했다.
- 전체 `flutter test --reporter compact` 결과는 기존 `+209 -3`에서 `+226 -2`로 변했다. read source policy loading 실패는 제거되었고 새 branch-only 실패는 없다.
- 남은 baseline red 2건은 `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`이며 별도 phase로 유지한다.
- 추가 UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화를 계속한다.

## 2026-05-26 Phase 12-H remaining baseline red triage

- Phase 12-H를 fix 단계가 아니라 docs/audit 단계로 기록했다. 목적은 Phase 12-G 이후 남은 baseline red 3건을 다시 확인하고 다음 fix 후보 1건을 선정하는 것이다.
- Phase 12-G 이후 main 기준 전체 flutter test 결과: +209 -3
- 남은 baseline red는 `word_repository_read_source_policy_test.dart`, `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`다.
- `word_repository_read_source_policy_test.dart`는 loading 단계 컴파일 실패이며 오래된 `WordRepository` API 참조로 재분류했다. 현행 `WordRepository`에 대응 가능한 typed API가 이미 있어 production code 변경 없이 테스트 현행화 가능성이 가장 높으므로 다음 fix 후보 1순위로 기록했다.
- `word_repository_phase8h1_representative_query_contract_test.dart`는 `DuplicateCandidateDisplayItem` 기대값 불일치로 재분류했다. 기대 1건 대비 실제 3건이 반환되며 seed DB / 정규화 / 대표 후보 정책 판단이 필요하므로 바로 fix보다 stabilization 또는 정책 검토가 필요하다.
- `explorer_workspace_phase4e_composition_boundary_test.dart`는 production import tree의 `explorer_workspace/` 참조 금지 guardrail 불일치로 재분류했다. ExplorerWorkspace 경계 정책 재정의가 필요하므로 단순 테스트 수정으로 처리하지 않는다.
- Phase 12-I 진입 조건은 `test/data/repositories/word_repository_read_source_policy_test.dart` 단일 fix로 제한하고, production `WordRepository` 구현 변경은 원칙적으로 금지하며, 테스트를 현행 Repository API에 맞추는 방향으로 한정한다고 기록했다.
- Phase 12-I에서는 다른 남은 red 2건을 함께 수정하지 않고, 전체 `flutter test` 결과가 `+209 -3`에서 어떻게 변하는지 비교하며, 새 branch-only 실패가 없어야 한다.
- 이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않았다.
- 추가 production-visible UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화를 계속한다.

## 2026-05-25 Phase 12-G word_info_panel_test baseline fix

- Phase 12-G의 목적은 Phase 12-F remaining red 중 `test/ui/word_info_panel_test.dart` 1건을 현행 `WordInfoPanel` API 기준으로 정리하는 것이다.
- `word_info_panel_test.dart`의 오래된 `WordInfoPanel(wordMap:)` 호출을 현행 `WordDetailLikeDisplayItem` 기반 `displayItem:` 호출로 전환했다.
- 제거된 `buildWordRepresentativeSpelling` helper 참조는 현행 production API에 대응되지 않으므로 `WordInfoPanel` widget baseline 테스트 범위에서 제외했다.
- 이번 단계는 test baseline fix이며 UX 변경이 아니다.
- production code와 `WordInfoPanel` production 구현은 변경하지 않았다.
- ExplorerWorkspace UX, `WordExplorerScreen`, context strip, route/shell/authority/API는 변경하지 않았다.
- Phase 12-F remaining red 중 `word_info_panel_test.dart` 1건을 정리 대상으로 기록하고, 남은 baseline red는 별도 phase로 유지한다.
- 남은 baseline red는 `word_repository_read_source_policy_test.dart`, `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`다.
- 추가 UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 전환과 baseline 안정화를 계속한다.

## 2026-05-25 Phase 12-F remaining baseline red review

- Phase 12-F를 수정 작업이 아니라 docs/audit 단계로 기록했다. 이번 단계의 목적은 Phase 12-E 이후 `main` 기준으로 남은 baseline red를 다시 확인하고 다음 fix 후보를 선정하는 것이다.
- Phase 12-E 이후 main 기준 전체 flutter test 결과: +206 -4
- `flutter test --reporter compact`와 `flutter test --reporter expanded` 모두 `+206 -4`로 종료되었고, 현재 확인된 새 실패는 없다.
- Phase 12-D inventory 대비 제거/통과 항목은 `widget_test.dart`와 `explorer_workspace_phase5a_layout_orchestration_test.dart`로 구분했다. `widget_test.dart`는 Phase 12-E에서 제거되었고, `explorer_workspace_phase5a_layout_orchestration_test.dart`는 개별 실행에서 `+8: All tests passed!`로 확인했다.
- 남은 baseline red 항목은 `word_repository_read_source_policy_test.dart`, `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`, `word_info_panel_test.dart`다.
- `word_repository_read_source_policy_test.dart`는 오래된 Repository API 참조, `word_repository_phase8h1_representative_query_contract_test.dart`는 duplicate candidate 기대값 불일치, `explorer_workspace_phase4e_composition_boundary_test.dart`는 source-level guardrail 불일치, `word_info_panel_test.dart`는 오래된 `WordInfoPanel` API 참조로 재분류했다.
- 다음 fix 후보 1순위는 `test/ui/word_info_panel_test.dart`로 기록했다. 실패가 loading 단계 컴파일 실패로 명확하고, 현행 `WordDetailLikeDisplayItem` 기반 `displayItem` contract에 맞춘 좁은 테스트 현행화 후보이기 때문이다.
- Phase 12-F는 다음 fix 후보를 선정하지만, Phase 12-G가 반드시 fix 단계로 확정된 것은 아니다. 현재 개발 속도와 구조 부담을 고려하여, 다음 단계는 `word_info_panel_test` fix 또는 incremental migration vs rebuild feasibility audit 중 하나로 별도 판단한다.
- 추가 production-visible UX diff는 baseline red 정리 또는 별도 수용 정책이 더 명확해질 때까지 계속 보류한다.
- 이번 단계에서는 코드, 테스트, 플랫폼, dependency 파일을 수정하지 않았다.

## 2026-05-25 Phase 12-E widget_test package/import baseline fix

- Phase 12-E의 목적을 Phase 12-D baseline red inventory 6건 중 `widget_test.dart` package/import 오류 1건 정리로 한정했다.
- `test/widget_test.dart`에서 오래된 `package:study/main.dart` import와 존재하지 않는 `MyApp` 참조를 제거하고, 현행 `package:reshet_app/main.dart` / `ReshetApp` 기준의 root widget smoke test로 정리했다.
- 기존 counter app 템플릿 assertion은 제거하고, 테스트 목적을 `ReshetApp` root widget이 첫 frame에서 예외 없이 빌드되는지 확인하는 수준으로 제한했다.
- 이번 단계는 UX 변경이 아니며 production code는 수정하지 않았다.
- ExplorerWorkspace UX 확장, `WordExplorerScreen` context strip 조정, route/shell/authority/API 변경은 수행하지 않았다.
- `flutter test test/widget_test.dart --reporter expanded`는 통과했고, 전체 `flutter test --reporter compact`는 기존 Phase 12-D inventory 기준 `+204 -6`에서 현재 `+206 -4`로 바뀌었다.
- 남은 baseline red 항목은 `word_repository_read_source_policy_test.dart`, `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`, `word_info_panel_test.dart`이며 별도 phase 또는 test stabilization 단계로 유지한다.
- Phase 12-D inventory에 있던 `explorer_workspace_phase5a_layout_orchestration_test.dart`는 Phase 12-E 개별 확인에서 통과했지만, 이번 단계의 의도적 수정 대상은 아니다.
- 추가 UX diff는 계속 보류한다.

## 2026-05-25 Phase 12-D baseline test red inventory

- Phase 12-D를 테스트 수정 단계가 아니라 docs/audit 단계로 기록했다.
- main baseline 기준 전체 `flutter test` 결과는 `+204 -6` red 상태로 확인했다.
- 실패 6건을 inventory 형태로 정리했다. 대상은 `word_repository_read_source_policy_test.dart`, `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`, `explorer_workspace_phase5a_layout_orchestration_test.dart`, `word_info_panel_test.dart`, `widget_test.dart`다.
- 실패 유형은 오래된 Repository API 참조, duplicate candidate 기대값 불일치, ExplorerWorkspace source-level guardrail 불일치, 문서 guardrail 문구 불일치, 오래된 `WordInfoPanel` API 참조, `package:study` / `MyApp` import 경로 불일치로 분류했다.
- 현재 inventory 기준으로 Phase 12-B/C 변경 파일 또는 신규 Phase 12-B 테스트가 직접 유발한 branch-only 실패는 확인되지 않았다. 확인된 실패는 기존 baseline test debt로 분류한다.
- 즉시 작은 fix 브랜치로 검토 가능한 항목은 package/import 오류와 오래된 API 참조 계열이다. 다만 실제 수정은 Phase 12-D가 아니라 별도 `fix/` 또는 test stabilization 단계에서 수행한다.
- 별도 test stabilization phase가 필요한 항목으로 duplicate candidate query 의미 확인, ExplorerWorkspace guardrail 재정의, 넓은 read source policy 테스트 현행화를 남겼다.
- 다음 단계 선택지는 A: 작은 fix 브랜치로 즉시 정리, B: 별도 test stabilization phase로 분리, C: baseline red 수용 정책 문서화 후 UX 확장 제한으로 정리했다.
- Phase 12-E 진입 조건으로 먼저 고칠 실패 선택, fix 범위 구분, production code 변경 사전 승인, ExplorerWorkspace UX 변경과 테스트 안정화 작업 분리, 수정 후 좁은 테스트와 전체 `flutter test` 기준 정의를 기록했다.
- 이번 단계에서는 코드, 테스트, 플랫폼, dependency 파일을 수정하지 않았다.

## 2026-05-25 Phase 12-C 첫 production-visible UX diff 평가

- Phase 12-C를 구현 단계가 아니라 docs/audit 단계로 기록했다.
- Phase 12-B context strip은 첫 production-visible UX diff로 성공한 것으로 평가했다. 변경 범위가 작고 rollback 가능하며, 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지했고, `ExplorerWorkspace` shell mount, route 변경, authority migration, projection visible UI 사용이 없었다.
- 이 평가는 추가 UX 구현 승인으로 이어지지 않으며, 추가 production-visible UX diff는 별도 범위 정의, 테스트 기준, 금지선 재확인, 사용자 승인을 거쳐야 한다고 명시했다.
- raw ID 표시는 현재 최소 read-only UX diff로는 허용 가능하지만, 장기 사용자 UX로는 lemma/spelling 등 사람이 읽을 수 있는 표시로 조정 검토가 필요할 수 있다고 기록했다.
- 다음 단계 선택지를 A: context strip 유지 후 다음 제한 UX diff 검토, B: context strip 표시 방식 조정 검토, C: 추가 UX diff 전 baseline `flutter test` red 정리로 정리했다.
- 권장 판단은 Phase 12-B는 성공으로 보되, 추가 production-visible UX 확장 전 baseline `flutter test` red 정리를 우선 검토하는 것으로 기록했다.
- Phase 12-D 또는 다음 Phase 진입 조건으로 baseline test red 정리 여부 또는 수용 정책, context strip 유지/조정 여부, 추가 UX diff 범위, 기존 진입 경로 유지, shell mount 없음, route 변경 없음, owner/controller/coordinator migration 없음, Provider / Repository / Navigator / persistence authority migration 없음, DTO/model/public API 추가 없음, `ExplorerWorkspaceState` projection visible UI 사용 없음 등을 명시했다.
- Phase 12-C 자체는 UI 테스트를 수행하지 않으며, Phase 12-B 클라이언트 UI 테스트 성공은 참조 기록으로만 사용한다고 기록했다.
- 이번 단계에서는 코드, 테스트, 플랫폼, dependency 파일을 수정하지 않았다.

## 2026-05-25 Phase 12-B WordExplorerScreen 최소 read-only context strip

- Phase 12-B를 full `ExplorerWorkspace` shell mount가 아니라 기존 `HomeScreen -> WordExplorerScreen` production 진입 경로 안의 제한적 read-only UX diff 구현 단계로 기록했다.
- `lib/ui/word_explorer_screen.dart`의 detail pane 상단에 `중심 단어: ... · 선택: ...` 형식의 작은 context strip을 추가했다.
- context strip은 기존 `WordExplorerScreen` 내부 상태인 `_centerWordId`, `_selectedWordId`만 읽으며 클릭, 편집, 이동 동작을 추가하지 않는다.
- `ExplorerWorkspaceState` projection 또는 hidden visual probe 결과를 visible UI 입력으로 사용하지 않았다.
- route wiring / route registration, `HomeScreen -> WordExplorerScreen` 진입 구조, `ExplorerWorkspace` shell mount, owner/controller/coordinator, Provider / Repository / Navigator / persistence authority, DTO/model/public API는 변경하지 않았다.
- `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`는 4 tests passed로 통과했다.
- 기존 `HomeScreen -> WordExplorerScreen` 진입 후 detail pane 상단 context strip 표시와 선택 ID 변경 흐름을 클라이언트가 확인했다.
- 전체 `flutter test`는 Phase 12-B 브랜치에서 `+204 -6`, main baseline에서 `+200 -6`으로 실패했다. 실패 계열은 main baseline과 동일 또는 동종이며, `word_explorer_screen.dart` 또는 신규 Phase 12-B 테스트가 유발한 branch-only 실패는 확인되지 않았다.
- 전체 `flutter test` red는 Phase 12-B 신규 회귀가 아니라 기존 baseline red로 분리한다. Phase 12-B 병합 판단은 좁은 관련 테스트 통과, 클라이언트 UI 테스트 성공, 금지선 유지 여부를 기준으로 한다.

## 2026-05-25 Phase 12-A minimum production-visible candidate selection audit

- Phase 12-A를 구현 단계가 아니라 `minimum production-visible candidate selection audit` 단계로 기록했다.
- Phase 12의 목적을 ExplorerWorkspace의 즉시 production-visible 전환이 아니라 가장 작은 production-visible 후보 범주를 문서/audit 기준으로 선정하는 것으로 정의했다.
- `ExplorerWorkspace` shell mount는 route 변경, owner/controller/coordinator migration, production UI diff, authority migration을 동시에 압박할 수 있으므로 Phase 12-A 직접 후보에서 제외했다.
- production UI diff의 상태를 검토 대상은 가능, 구현 승인은 아직 아님, Phase 12-B 이후 제한 후보는 가능이라는 세 단계로 분리했다.
- 기존 `HomeScreen -> WordExplorerScreen` 경로 안의 제한적 read-only UX diff는 Phase 12-B의 후보 범주가 될 수 있으나, Phase 12-A는 해당 UX diff를 구현하거나 승인하지 않는다고 기록했다.
- Phase 12-B 또는 feature 브랜치 진입 조건으로 candidate 범주 명확화, 기존 진입 경로 유지, shell mount 없음, route 변경 없음, owner/controller/coordinator migration 없음, Provider / Repository / Navigator / persistence authority migration 없음, DTO/model/public API 추가 없음, 작고 rollback 가능한 UI diff, 수동 테스트 기준 문서화를 명시했다.
- production UI diff 구현, `ExplorerWorkspace` shell mount, route wiring / route registration change, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, projection result persistence/history/source-of-truth usage, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration, owner/controller/coordinator migration, Level 3 production visible consumer는 계속 `not approved`로 유지한다.
- UI 기반 수동 테스트는 Phase 12-A에서 수행하지 않으며, 이번 변경은 화면에서 확인할 새 동작을 만들지 않는다고 기록했다.

## 2026-05-25 Phase 11-D Phase 11 termination audit

- Phase 11-D를 Phase 11 전체 종료 가능 여부를 판단하는 termination audit 단계로 기록하고, implementation 단계가 아니라고 명시했다.
- Phase 11-A readiness review, Phase 11-B shell mount precondition audit, Phase 11-C production-visible candidate boundary review의 완료 내용을 모두 docs/audit 결과로만 요약했다.
- Phase 11 전체에서 확정된 것은 production-visible 전환 readiness 조건, `ExplorerWorkspace` shell mount precondition, production-visible candidate boundary, Phase 10/11 결과의 승격 금지 기준, 후속 feature 단계 전 금지선이라고 정리했다.
- Phase 10-D `candidate representation reader`는 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local read-only 구조이며 public API / DTO / model / route contract / shell contract로 승격하지 않는다고 재확인했다.
- Phase 11이 production-visible 구현, `ExplorerWorkspace` shell mount, route 변경, public API / DTO / model 추가, 실제 사용자-visible UX 변경을 승인하거나 발생시킨 것이 아니라고 명시했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration change, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, projection result persistence/history/source-of-truth usage, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration, owner/controller/coordinator migration, Level 3 production visible consumer는 계속 `not approved`로 유지한다.
- UI 기반 수동 테스트는 Phase 11-D에서 수행하지 않으며, 이번 변경은 화면에서 확인할 새 동작을 만들지 않는다고 기록했다.

## 2026-05-25 Phase 11-C production-visible candidate boundary review

- Phase 11-C를 production-visible feature 구현 단계가 아니라, Phase 11-A readiness review와 Phase 11-B shell mount precondition audit 이후 production-visible 후보 검토 시 넘지 말아야 할 경계와 후보 조건을 정리하는 boundary review 단계로 기록했다.
- production-visible candidate 최소 조건을 candidate 위치, 책임, Level 2 / Level 3 경계, production-visible 전환 가능성, shell mount 관계, route와 entry 구조, 테스트 기준으로 분리했다.
- Phase 10-D `candidate representation reader`는 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local read-only 구조이며 public API / DTO / model / route contract / shell contract로 승격하지 않는다고 재확인했다.
- Phase 10 / 11-A / 11-B 결과가 production visual consumer exposure, runtime/UI integration, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, Level 3 production-visible consumer 승인이 아니라고 명시했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration change, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, projection result persistence/history/source-of-truth usage, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration, owner/controller/coordinator migration, Level 3 production visible consumer는 계속 `not approved`로 유지한다.
- UI 기반 수동 테스트는 Phase 11-C에서 수행하지 않으며, production-visible UX 변경이나 shell mount 구현이 별도 feature 단계에서 승인된 뒤 테스트 목적, 시작 화면, 조작 순서, 사람이 식별 가능한 테스트 데이터, 기대 화면 변화, 실패 증상, 완료 판단 기준을 포함해 수행해야 한다고 기록했다.

## 2026-05-25 Phase 11-B ExplorerWorkspace shell mount precondition audit

- Phase 11-B를 `ExplorerWorkspace` shell mount 구현 단계가 아니라 shell mount 검토 전 precondition, 위험 요소, 금지선, 검증 기준을 문서화하는 audit 단계로 기록했다.
- 현재 production entry 구조는 `main.dart -> HomeScreen`, `HomeScreen -> Navigator.push -> WordExplorerScreen`로 유지하며, `ExplorerWorkspace`는 아직 production owner/controller/coordinator가 아니라고 명시했다.
- shell mount 검토가 production-visible UX 승인, production UI diff 승인, route collapse 승인, owner migration 승인으로 이어지지 않는다고 분리했다.
- production entry, route, ownership, persistence authority, UI diff, public contract, Phase 10 helper-local reader 해석, 테스트 기준별 precondition과 위험 요소를 정리했다.
- Phase 10-D `candidate representation reader`는 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local 구조이며 public API / DTO / model / route contract / shell contract로 승격하지 않는다고 재확인했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, projection result persistence/history/source-of-truth usage, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration, Level 3 production visible consumer는 계속 `not approved`로 유지한다.
- UI 기반 수동 테스트는 Phase 11-B에서 수행하지 않으며, production-visible UX 변경이나 shell mount 구현이 별도 feature 단계에서 승인된 뒤 시작 화면, 조작 순서, 테스트 데이터, 기대 화면 변화, 실패 증상, 완료 판단 기준을 포함해 수행해야 한다고 기록했다.

## 2026-05-24 Phase 11-A production-visible readiness review

- Phase 11의 목적을 Phase 10 `candidate representation reader` 이후 production-visible 전환 검토 조건과 금지선을 분리해 확인하는 단계로 기록했다.
- Phase 11-A를 production-visible UX 구현 단계가 아닌 readiness review 문서/audit 단계로 제한했다.
- 사용자-visible UX 변화는 Phase 11-A 범위가 아니며, 실제 UX 변화는 readiness review와 shell mount precondition audit 이후 별도 승인된 feature 단계에서만 가능하다고 명시했다.
- `ExplorerWorkspace` shell mount는 화면 노출, entry path, state ownership, route stack, history/persistence 해석, callback authority에 영향을 줄 수 있으므로 별도 precondition audit이 필요하다고 정리했다.
- Phase 10의 `candidate representation reader`는 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local 구조이며 public API / DTO / model / route contract / shell contract 승격이 아니라고 재확인했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경은 계속 `not approved`로 유지한다.
- Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, projection result persistence/history/source-of-truth 사용, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration, Level 3 production visible consumer는 계속 `not approved`로 유지한다.

## 2026-05-24 Phase 10-E candidate representation reader termination audit

- Phase 10-E를 구현이 아니라 Phase 10-D `candidate representation reader`가 Phase 10-A/B/C의 금지선과 최소 구현 조건을 지켰는지 확인하는 termination audit 단계로 기록했다.
- `readCandidateRepresentation`은 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local local function으로만 존재하며, 선언과 호출 모두 helper 내부에만 있다고 확인했다.
- `candidateSlots`, `candidateLabels`는 helper-local candidate structure로만 유지되며 helper 외부 노출, return, field/getter, public contract 승격이 없다고 정리했다.
- public API / DTO / model / route contract / shell contract 승격, production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경은 없다고 기록했다.
- Provider / Repository / Navigator / persistence authority migration, projection result persistence/history/source-of-truth 사용, runtime/UI integration, production visual consumer exposure가 없다고 기록했다.
- Phase 10-D 신규 테스트는 UI pump나 runtime integration이 아닌 source-level guardrail test이며, 기존 guardrail 테스트와 Phase 10-D 신규 테스트가 모두 통과했다고 정리했다.
- production-visible UI, shell mount, route wiring, runtime integration이 없으므로 UI 기반 수동 테스트는 아직 대상이 아니라고 명시했다.
- Phase 10은 종료 가능 상태로 판단할 수 있으나, Phase 11 production-visible 논의는 별도 승인 대상으로 분리한다고 기록했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, projection result persistence/history/source-of-truth 사용, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration은 계속 `not approved`로 유지한다.

## 2026-05-24 Phase 10-D candidate representation reader 최소 구현

- Phase 10-D에서 `candidate representation reader`를 production preview, mounted widget, production-visible consumer가 아닌 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local read-only reader로 제한해 시작했다.
- `candidateSlots`, `candidateLabels`는 helper 내부 local candidate structure로만 읽고, public API, DTO, model, route contract, shell contract, persistence/history/source-of-truth payload로 승격하지 않는 기준을 유지했다.
- 신규 source-level guardrail test 후보를 `test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart`로 두고, UI pump, route 실행, runtime integration 검증이 아니라 문자열/범위 기반 검증으로 제한했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence 구현 변경, DTO/model/public API 추가는 계속 `not approved`로 유지한다.

## 2026-05-24 Phase 10-C candidate preview consumer preflight audit

- Phase 10-C를 implementation이 아니라 Phase 10-D feature 구현 전 명칭, 파일 후보, 테스트 전략, 금지 import / 금지 참조, 진입 조건을 고정하는 preflight audit 단계로 기록했다.
- Phase 10-C가 implementation approval이 아니며 Level 2 visual consumer 구현, 새 widget/class/helper 구현, 새 테스트 파일 작성, 기존 테스트 파일 수정, `lib/` / `test/` 수정, production UI diff, shell mount, route wiring / route registration 변경을 승인하지 않는다고 명시했다.
- `candidate preview-only consumer`가 production preview 또는 mounted widget consumer로 오해될 위험을 줄이기 위해 `candidate representation reader`, `candidate preview probe`, `candidate visual probe consumer`, `candidate structure preview`, `candidate preview-only consumer` 명칭 후보를 비교했다.
- 다음 feature 브랜치 검토 후보명으로 `candidate representation reader`를 권장하되, 이는 구현 승인명이 아니라 helper-local candidate representation을 읽는 read-only 후보명이라고 제한했다.
- Phase 10-D 구현 파일 후보를 허용 가능 후보, 위험 후보, 금지 후보로 분리하고, route/shell/Provider/Repository/Navigator/persistence/DTO/model/public API 경로는 별도 승인 전 금지 후보로 기록했다.
- 테스트 전략을 기존 테스트 재사용 가능 항목, 기존 테스트 확장 가능 항목, 새 source-level test 후보, 새 hidden/probe-adjacent test 후보, 아직 UI 기반 수동 테스트로 검증할 수 없는 항목으로 분리했다.
- `candidateSlots`, `candidateLabels`는 helper-local candidate structure로만 소비 가능하며 production-visible surface, route contract, shell contract, persistence/history/source-of-truth payload, public API, DTO, model로 승격할 수 없다고 재확인했다.
- Phase 10-D feature 브랜치 진입 조건으로 후보명 확정, 구현 위치 후보 확정, 테스트 파일 후보 확정, 금지 import / 금지 참조 기준 확정, production UI diff 없음, shell mount 없음, route 변경 없음, owner/persistence migration 없음, DTO/model/public API 추가 없음, 사용자 승인을 기록했다.

## 2026-05-24 Phase 10-B Level 2 minimum consumer target review

- Phase 10-B를 implementation이 아니라 첫 Level 2 minimum consumer 후보를 고르는 docs/audit 기반 target review 단계로 기록했다.
- Phase 10-B가 implementation approval이 아니며 production 연결, production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경을 승인하지 않는다고 명시했다.
- Level 2 minimum consumer 후보 기준을 production source-of-truth 미소유, unmounted, non-route, non-owner, non-persistent, non-production-visible, helper-local boundary 유지 기준으로 정리했다.
- 후보 유형으로 `candidate preview-only consumer`, hidden visual probe extension, source-level visual structure reader, test-only representation consumer, ExplorerWorkspace shell-adjacent but unmounted consumer를 비교했다.
- `candidate preview-only consumer` 계열을 가장 안전한 다음 feature 브랜치 검토 후보로 권장하되, 이 preview가 production preview를 뜻하지 않고 test-or-hidden-probe-adjacent helper-local candidate representation이라고 제한했다.
- `candidateSlots`, `candidateLabels`는 helper-local candidate structure로만 소비 가능하며 public API, DTO, model, route contract, shell contract, persistence/history/source-of-truth payload로 승격할 수 없다고 재확인했다.
- Phase 10-C 진입 전 테스트 기준을 기존 테스트 재사용 가능 항목, 기존 테스트 확장 필요 항목, 새 source-level 또는 hidden/probe test 후보, UI 기반 수동 테스트로는 아직 검증할 수 없는 항목으로 분리했다.
- `lib/`, `test/`, production UI, shell mount, route, Provider / Repository / Navigator / persistence, DTO/model/public API 변경은 모두 `not approved`로 유지했다.

## 2026-05-24 Phase 10-A Level 2 production-adjacent visual consumer implementation scope review

- Phase 10을 production 연결 단계가 아니라 Level 2 implementation scope의 최소 범위를 확정하는 단계로 기록했다.
- Phase 10-A를 docs/audit 기반 scope review 단계로 제한하고, implementation approval이나 feature implementation 단계가 아니라고 명시했다.
- Level 2 최소 구현 단위 검토 기준을 read-only projection snapshot 입력, helper-local candidate structure 출력, production 권한 미획득, helper-local boundary 유지 기준으로 정리했다.
- `candidateSlots`, `candidateLabels`는 helper-local candidate structure이며 public API, DTO, model, route contract, shell contract, persistence/history/source-of-truth payload로 승격할 수 없다고 재확인했다.
- UI diff 없이 검증 가능한 항목과 검증 불가능한 항목을 분리하고, 실제 사용자 UX 만족도와 production-visible 사용성은 Phase 10-A 검증 범위가 아니라고 기록했다.
- production UI diff, `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence 변경, owner migration, persistence authority migration, DTO/model/public API 추가, production visible exposure는 모두 `not approved`로 유지했다.
- Phase 10 이후 분기 가능성은 추가 docs/audit, 별도 승인 후 Level 2 최소 구현 브랜치, source-level guardrail test 보강 검토, Phase 11 이후 production-visible 검토 후보로만 기록하고 Phase 10-A에서 바로 feature 구현으로 넘어가지 않는다고 명시했다.

## 2026-05-24 Phase 9-F Level 2 entry / candidate / guardrail hardening termination audit

- Phase 9-F를 구현 단계가 아니라 Phase 9-A~E의 Level 2 entry / candidate / guardrail hardening 흐름을 종합하는 termination audit 단계로 기록했다.
- Phase 9-A Level 2 진입 조건, Phase 9-B 후보 선정 경계, Phase 9-C source-level guardrail planning, Phase 9-D guardrail test hardening target audit, Phase 9-E 기존 Phase 8-G source-level test 제한 보강을 종료 audit 관점에서 요약했다.
- Phase 9-E 테스트 보강은 기존 Phase 8-G 테스트 파일 안에서만 수행됐고, 새 테스트 파일 생성과 production code 수정이 없으며 관련 테스트 결과가 `+17: All tests passed!`였다고 기록했다.
- Phase 9에서 승인된 것은 Level 2 진입/후보/guardrail 기준 문서화와 기존 Phase 8-G source-level test 제한 보강뿐이며, Level 2 구현, shell mount, production UI diff, route/owner/persistence 변경은 승인되지 않았다고 분리했다.
- Phase 10 또는 후속 단계 후보는 Level 2 production-adjacent visual consumer 구현 여부, production UI diff 승인 절차, shell mount precondition checklist, route/shell/owner migration 여부 검토로 제한하되 모두 별도 승인 전까지 `not approved`로 유지했다.
- 현재 기준 Phase 9는 종료 가능 상태로 판단하되, 후속 단계가 자동 승인되는 것은 아니라고 명시했다.

## 2026-05-24 Phase 9-E Level 2 source-level guardrail test hardening

- Phase 9-E를 production 구현 단계가 아니라 기존 Phase 8-G source-level test를 제한적으로 보강하는 단계로 기록했다.
- 새 테스트 파일은 만들지 않고 `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`에 candidate marker public surface 누출 방지와 production entry marker 노출 방지 guardrail을 추가했다.
- `candidateSlots`, `candidateLabels`가 public API, DTO, model, public export, route contract, shell contract 성격의 경로로 새어 나가지 않는지 source-level로 보강했다.
- `main.dart`, `home_screen.dart`, workspace contract/shell source에 hidden probe 또는 candidate marker가 production entry처럼 노출되지 않는지 확인하도록 했다.
- production UI diff는 source-level test만으로 완전 판정하지 않고 `git diff --name-only -- lib android ios macos windows linux web` 기반 path-level audit을 병행한다고 기록했다.
- route/shell/Navigator/Provider/Repository/persistence 구현 변경, `ExplorerWorkspace` shell mount, production UI diff, Level 2/Level 3 visual consumer 구현, output DTO/model 추가, public API 추가는 모두 `not approved`로 유지했다.

## 2026-05-24 Phase 9-D Level 2 source-level guardrail test hardening target audit

- Phase 9-D를 source-level test 구현 단계가 아니라 Level 2 source-level guardrail test hardening 대상 후보를 확인하는 docs/audit 단계로 기록했다.
- 기존 관련 테스트인 `word_explorer_screen_phase7f_projection_boundary_test.dart`, `word_explorer_screen_phase8c_hidden_visual_probe_test.dart`, `word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`의 역할과 현재 guardrail 커버리지를 정리했다.
- projection boundary, hidden visual probe assert-only/read-only boundary, `candidateSlots` / `candidateLabels` helper-local boundary, public API / DTO / model marker 미노출, shell mount / route / persistence 미연결은 기존 테스트가 일부 커버한다고 기록했다.
- 전체 `lib/` model / DTO / public export 경로, 전체 route wiring / route registration 변화, future Level 2 production-adjacent path의 Navigator / Provider / Repository / persistence 참조 방지, production UI diff 판정은 coverage gap 후보로 남겼다.
- 테스트 구현이 필요할 경우 기존 Phase 8-G 테스트 보강을 우선 후보로 두되, Phase 9-D에서는 새 테스트 파일명, test name, assertion 구현 방식을 확정하지 않는다고 명시했다.
- source-level test implementation, test file creation/modification, code file modification, runtime/UI integration, shell mount, route wiring, authority migration, output DTO/model, public API, Level 2 구현, production UI diff는 모두 `not approved`로 유지했다.

## 2026-05-24 Phase 9-C Level 2 visual consumer source-level guardrail planning

- Phase 9-C를 source-level test 구현 단계가 아니라 Level 2 visual consumer 후보를 보호하기 위한 source-level guardrail 후보 문서화 단계로 기록했다.
- public API / DTO / model / route contract / shell contract 승격 방지 guardrail 후보를 Phase 9-D 이후 검토 대상으로 제한했다.
- `candidateSlots`, `candidateLabels`가 `_debugValidateHiddenVisualProbe(...)` helper 내부 local structure 밖으로 노출되지 않도록 하는 guardrail 후보를 정리했다.
- projection result persistence/history/source-of-truth usage, shell mount, route wiring, Navigator, Provider, Repository, persistence 참조 추가를 막는 guardrail 후보를 문서화했다.
- production UI diff 방지 path-level guardrail 후보를 기록하되, Phase 9-C에서는 코드와 테스트 파일을 수정하지 않는다고 분리했다.
- Phase 9-D 이후 source-level test hardening 후보는 별도 설계, 수정 파일 목록, command 기반 검증 계획, 사용자 승인 전까지 구현하지 않는다고 명시했다.
- source-level test implementation, Level 2 구현, Level 3 visible consumer, production UI diff, shell mount, route collapse, authority migration, output DTO/model, public API는 모두 `not approved`로 유지했다.

## 2026-05-24 Phase 9-B Level 2 visual consumer candidate selection boundary

- Phase 9-B를 Level 2 구현 단계가 아니라 Level 2 visual consumer 후보 선정 기준을 문서화하는 planning/audit 단계로 기록했다.
- Level 2 후보 선정 기준을 read-only projection snapshot 유지, production route 미노출, production visible UI surface 아님, production owner state 미대체, projection result 비저장 기준으로 제한했다.
- production-adjacent visual consumer 후보가 selection, route, Provider, Repository, Navigator, persistence, history, public API, DTO/model, production UI exposure 권한을 갖지 않아야 한다고 정리했다.
- 후보 선정은 `candidate only`, `planning only`, `not implementation approval`, `not production exposure approval`, `not shell mount approval`, `not authority migration` 문구와 함께 사용해야 한다고 기록했다.
- Phase 9-C 이후 후보는 source-level guardrail 검토로만 제한하고, Phase 9-B에서는 코드와 테스트 파일을 수정하지 않는다고 분리했다.
- production UI diff, `ExplorerWorkspace` shell mount, route 변경, owner migration은 계속 별도 승인 대상으로 유지했다.
- runtime/UI integration, production visual consumer exposure, shell mount, route collapse, owner migration, authority migration, output DTO/model, public API, Level 2 구현, Level 3 visible consumer, production UI diff는 모두 `not approved`로 유지했다.

## 2026-05-24 Phase 9-A Level 2 visual consumer entry boundary planning

- Phase 9-A를 Level 2 구현 단계가 아니라 Level 2 visual consumer 진입 조건을 정의하는 planning 단계로 기록했다.
- Level 2 visual consumer를 production-adjacent visual consumer 후보를 가리키는 임시 planning 용어로 제한하고, owner / controller / coordinator / route owner / shell owner / persistence owner가 아니라고 명시했다.
- Level 2 진입 전 사전 조건으로 Level 1 hidden visual probe의 assert-only / read-only / non-owner boundary 유지, `candidateSlots` / `candidateLabels` local helper structure 유지, public API / DTO / persistence / route / shell contract 미승격을 기록했다.
- production-adjacent visual consumer 검토 위험으로 production UI diff 우회, shadow owner, shell mount 승인 오해, projection result의 history/source-of-truth 사용 위험을 정리했다.
- `ExplorerWorkspace` shell mount는 Phase 9-A에서 승인하지 않고 shell mount 검토 precondition만 문서화할 수 있다고 분리했다.
- production UI diff는 별도 명시 승인 단계에서만 다루며 Phase 9-A에서는 `not approved` 상태로 유지한다고 기록했다.
- Phase 9-B 후보 범위는 Level 2 candidate selection 기준, risk audit 보강, source-level guardrail 후보, shell mount precondition checklist 보강으로 제한하고, 구현 범위는 Phase 9-A에서 제외했다.
- 이번 변경은 문서 2개만 포함하며 코드, 테스트, route, shell, Provider, Repository, Navigator, persistence 구현 변경은 없다.

## 2026-05-23 Phase 8-H hidden probe contract termination audit

- Phase 8-A~G의 visual consumer entry boundary, Level 1 hidden visual probe, output contract planning, source-level test hardening 흐름을 종합 감사했다.
- Level 1 hidden visual probe는 assert-only / read-only / non-owner boundary 안에 머무르며 production route, `ExplorerWorkspace` shell mount, runtime/UI integration으로 연결되지 않는다고 정리했다.
- `candidateSlots`, `candidateLabels`는 `_debugValidateHiddenVisualProbe(...)` helper 내부 local candidate structure이며 public API, output DTO/model, route argument, shell prop, persistence payload가 아니라고 재확인했다.
- 관련 source-level test인 `word_explorer_screen_phase7f_projection_boundary_test.dart`, `word_explorer_screen_phase8c_hidden_visual_probe_test.dart`, `word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`의 통과 결과를 Phase 8 종료 가능 판단 근거로 기록했다.
- 전체 `flutter analyze`는 기존 저장소 이슈로 실패하는 상태이며, 이번 변경 파일인 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`는 analyzer 오류 대상이 아니라고 구분해 기록한다.
- Level 2 / Level 3 consumer 진입, runtime/UI integration, production visual consumer exposure, `ExplorerWorkspace` shell mount, route collapse, owner migration은 계속 `not approved`로 유지했다.
- Phase 8-H 기준으로 Phase 8은 종료 가능하다고 판단하되, 이는 Level 2 진입, production route 노출, shell mount, runtime/UI integration 승인을 의미하지 않는다고 명시했다.
- 다음 단계 후보는 Phase 9-A planning 수준의 Level 2 visual consumer entry boundary planning, production-adjacent visual consumer risk audit, `ExplorerWorkspace` shell mount precondition planning으로만 제한했다.

## 2026-05-23 Phase 8-G hidden probe output contract source-level test hardening

- `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`를 추가해 hidden probe output contract의 non-contract boundary를 source-level로 보강했다.
- `candidateSlots`, `candidateLabels`가 `_debugValidateHiddenVisualProbe(...)` helper 내부 local variable 범위에 머무르고 helper 밖 public API, field, getter, DTO/model, route argument, shell prop으로 노출되지 않는지 확인하도록 했다.
- hidden visual probe helper가 assert-only / read-only / non-owner boundary 안에 머물며 `setState`, `Navigator`, `WordRepository`, `Provider`, DB/persistence, logging, async 흐름에 연결되지 않는지 재확인했다.
- persistence schema, route contract, `ExplorerWorkspace` shell contract, output DTO/model, public API는 추가하지 않았다.
- `lib/`와 platform 경로는 수정하지 않았고 production UI diff는 없다.
- Level 1 boundary는 유지하며 Level 2 production-adjacent visual consumer와 Level 3 production visible consumer 진입은 계속 `not approved`로 유지했다.
- Phase 8-H 후보는 Level 2 승격이 아니라 Phase 8 hidden probe contract stabilization audit, visual consumer Level 1 boundary termination audit, Phase 8-G test hardening audit으로 제한했다.

## 2026-05-23 Phase 8-F hidden probe output contract hardening plan

- Phase 8-E output contract를 source-level hardening 관점에서 검토하는 planning 단계로 기록했다.
- 현재 Phase 7-F/8-C source-level test가 Level 1 hidden probe boundary, read-only input, side-effect 금지, route/shell 미연결, projection result 비저장 상태를 보호한다고 정리했다.
- `candidateSlots`, `candidateLabels`가 helper 내부 local candidate structure에 머무르며 public API, output DTO/model, persistence schema, route contract, `ExplorerWorkspace` shell contract가 아니라고 기록했다.
- output contract hardening은 현재 boundary 보호를 유지하되 non-contract 오해 방지 test 후보가 남아 있는 상태로 평가했다.
- Phase 8-G 후보를 hidden probe output contract source-level test hardening, visual candidate naming risk test, public API / DTO / persistence schema 오해 방지 테스트로 제한했다.
- Level 1 boundary는 유지하며 Level 2 production-adjacent visual consumer와 Level 3 production visible consumer 진입은 `not approved` 상태로 유지했다.
- runtime/UI integration, production visual consumer exposure, `ExplorerWorkspace` shell mount, route collapse, owner migration, Provider / Repository / Navigator / persistence authority migration은 계속 `not approved`로 유지했다.
- 이번 변경은 문서 변경만 포함하며 코드, 테스트, platform 경로 변경과 UI 기반 수동 테스트 대상은 없다.

## 2026-05-23 Phase 8-E hidden visual probe output contract planning

- Phase 8-E는 구현 단계가 아니라 Phase 8-C hidden visual probe가 내부적으로 도출하는 visual candidate의 output contract를 문서화하는 planning 단계로 기록했다.
- input은 `WordExplorerScreen` 내부 build-local read-only `ExplorerWorkspaceState` projection snapshot으로 제한되며, field/cache/history/source of truth로 저장되지 않는다고 정리했다.
- `candidateSlots`, `candidateLabels`는 helper 내부 local candidate structure이며 향후 visual consumer 렌더링 가능성을 검증하기 위한 내부 후보 구조라고 기록했다.
- candidate 구조는 production UI contract, public API, persistence schema, route contract, `ExplorerWorkspace` shell contract, canonical state 또는 source of truth가 아니라고 명시했다.
- Level 1 boundary는 유지하며 Level 2 production-adjacent visual consumer와 Level 3 production visible consumer 진입은 `not approved` 상태로 유지했다.
- runtime/UI integration, production visual consumer exposure, `ExplorerWorkspace` shell mount, route collapse, owner migration, Provider / Repository / Navigator / DB / persistence authority migration은 계속 `not approved`로 유지했다.
- Phase 8-F 후보는 output contract source-level hardening, visual candidate structure naming audit, hidden probe contract test expansion으로만 제한하고 구현 승인은 하지 않았다.
- 이번 변경은 문서 변경만 포함하며 UI 기반 수동 테스트 대상은 없다.

## 2026-05-23 Phase 8-D hidden visual probe stabilization audit

- Phase 8-D는 구현 단계가 아니라 Phase 8-C hidden visual probe가 Level 1 boundary 안에 머무는지 확인하는 stabilization audit 단계로 기록했다.
- `lib/ui/word_explorer_screen.dart`의 `_debugValidateHiddenVisualProbe(...)`가 `WordExplorerScreen.build(...)` 내부 assert-only 경계에서 호출되며 read-only projection snapshot만 소비한다고 정리했다.
- hidden visual probe는 owner/controller/coordinator authority를 이전하지 않고, Provider / Repository / Navigator / DB / persistence authority migration을 수행하지 않는다고 기록했다.
- production route 노출, `ExplorerWorkspace` shell mount, `main.dart` / `HomeScreen` / Navigator route 변경, production visible UI diff가 없다고 기록했다.
- projection result persistence/history/source-of-truth usage가 없고, source-level boundary test가 존재한다고 기록했다.
- 관련 테스트 `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`, `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` 결과를 `+11: All tests passed!`로 기록했다.
- `flutter analyze`는 기존 저장소 이슈로 실패하며, 이번 변경 파일인 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`는 analyzer 오류 목록에 포함되지 않는 상태로 구분했다.
- Phase 8-E는 Level 2 승격이 아니라 hidden visual probe output contract planning, source-level hardening, visual candidate structure audit 후보로만 기록했다.

## 2026-05-23 Phase 8-C hidden visual probe 구현

- `lib/ui/word_explorer_screen.dart`의 기존 build-local read-only projection read 및 assert-only consumer 경계 안에 `_debugValidateHiddenVisualProbe(...)` helper를 추가했다.
- hidden visual probe는 `ExplorerWorkspaceState` projection snapshot을 입력으로 받아 graph/detail visual candidate slot과 read-only label 구성 가능성만 검증하며, side effect 없이 assert-only 범위에서만 동작한다.
- `ExplorerWorkspace` shell mount, production route 노출, `HomeScreen` / `main.dart` / Navigator route 변경, production visible UI diff는 추가하지 않았다.
- Provider / Repository / Navigator / DB / persistence authority migration은 수행하지 않았고, projection result를 field, cache, history payload, source of truth로 저장하지 않았다.
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`를 추가해 hidden visual probe가 read-only / non-owner / non-route / non-shell-mount 경계를 유지하는지 source-level로 검증하도록 했다.
- `docs/ux/explorer_workspace_unification.md`에 `17.44 Phase 8-C hidden visual probe implementation` 섹션을 추가해 Level 1 boundary 유지, 미승인 항목 유지, Phase 8-D 후보 조건을 기록했다.

## 2026-05-23 Phase 8-B visual consumer candidate selection 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.43 Phase 8-B visual consumer candidate selection` 섹션을 추가해 Phase 8-A visual consumer entry boundary 이후 첫 visual consumer 후보군을 문서상으로 비교했다.
- Candidate A `Level 1 hidden visual probe`를 Phase 8-C 첫 구현 후보로 선정하되, Phase 8-B에서는 실제 hidden visual probe를 구현하지 않는다고 기록했다.
- Candidate B `Level 2 production-adjacent visual consumer`는 production 인접성에 따른 runtime/UI diff와 owner boundary 오해 가능성 때문에 보류로 기록했다.
- Candidate C `Level 3 production visible consumer`는 production route 노출과 production UI diff를 동반하므로 Phase 8-B에서 `not approved`로 유지했다.
- runtime/UI integration, `ExplorerWorkspace` shell mount, route collapse, canonical owner migration, Provider / Repository / Navigator / persistence authority migration은 계속 `not approved` 상태로 유지했다.
- `ExplorerWorkspace`가 owner, controller, coordinator가 아니며 owner boundary는 이전되지 않았다고 다시 고정했다.
- 이번 변경은 문서 변경만 포함하며 production UI diff는 없다.

## 2026-05-23 Phase 8-A visual consumer entry boundary 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.42 Phase 8-A visual consumer entry boundary` 섹션을 추가해 Phase 7 read-only projection chain 이후 visual consumer가 projection snapshot을 읽기 전에 필요한 entry boundary를 문서화했다.
- Phase 8은 `ExplorerWorkspace` shell을 production에 mount하는 단계가 아니며, runtime/UI integration과 visual consumer production exposure는 계속 `not approved` 상태라고 명시했다.
- `ExplorerWorkspace` shell mount, route collapse, canonical owner migration, Provider / Repository / Navigator / persistence authority migration은 승인되지 않았고 owner boundary 미이전 상태를 유지한다고 기록했다.
- projection result persistence, projection result history usage, projection result source-of-truth usage는 모두 `not approved`로 고정했다.
- 이번 변경은 문서 변경만 포함하며 production UI diff는 없다.

## 2026-05-23 Phase 7-H projection chain stabilization audit 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.41 Phase 7-H projection chain stabilization audit` 섹션을 추가해 Phase 7-A~7-G projection chain의 closure / stabilization audit 결과를 문서화했다.
- audit 결과 Phase 7 문서 흐름, read-only projection adapter, `WordExplorerScreen` private projection getter, build-local read + debug assert-only consumer, production entry / explorer route 유지, owner boundary 비침범, runtime/UI diff 없음이 서로 일치한다고 기록했다.
- Phase 7은 현재 기준 `closable`로 판단했지만, 이는 runtime/UI 구현 승인, visual consumer 승인, `ExplorerWorkspace` shell mount 승인, feature 브랜치 생성 승인이 아니라고 명시했다.
- visual consumer status와 shell mount status는 계속 `not approved`로 유지하며, 두 결정은 다음 phase unresolved 항목으로 이관했다.
- 대상 전체 `dart analyze`의 기존 `home_screen.dart` warning/info 5건과 sandbox 내부 Flutter test timeout / telemetry 접근 문제는 Phase 7-H 직접 경계와 분리된 검증 환경 이슈로 기록했다.

## 2026-05-23 Phase 7-G projection consumer boundary planning 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.40 Phase 7-G projection consumer boundary planning 기준`을 추가해, Phase 7-F read-only projection result의 현재 소비 상태와 안전한 consumer 경계 후보 A/B/C/D 비교를 문서화했다.
- 현재 projection boundary는 `WordExplorerScreen` 내부 private getter `_readOnlyWorkspaceProjection`과 build-local read + debug assert에만 머무르며, field/history/source of truth, UI prop, widget tree, route, `Navigator`, repository, persistence로 연결되지 않는다는 점을 기준으로 고정했다.
- 추천 consumer 경계는 후보 B `debug/assert-only consumer`로 기록했지만, 이는 implementation approval이 아니고 feature 브랜치 생성 승인도 아니며 visual consumer 구현 승인이나 `ExplorerWorkspace` shell mount 승인도 아니다.
- 후보 C visual consumer 연결은 production widget tree 변경, runtime/UI diff, preview host의 `_state` / `setState`로 인한 shadow owner 위험 때문에 현 단계에서는 비추천으로 기록했다.
- 후속 feature 브랜치 전환 전에는 visual consumer 필요성에 대한 별도 승인, production mount를 UI diff가 있는 기능 변경으로 취급하는 기준, `ExplorerWorkspace` non-owner 문구와 테스트 설계, route / `Navigator` / Repository / DB / Provider 영향 검토, 명령어 기반 검증 시나리오와 클라이언트 UI 확인 절차 확정, Flutter 테스트 실행 환경 정상화가 선행되어야 한다고 명시했다.

## 2026-05-23 Phase 7-F WordExplorer read-only projection boundary implementation

- `lib/ui/word_explorer_screen.dart`에 private read-only projection boundary `_readOnlyWorkspaceProjection`을 추가하고, current owner state를 `WordExplorerWorkspaceProjectionAdapter.project(...)` 호출로 파생 `ExplorerWorkspaceState` snapshot에만 투영하도록 정리했다.
- projection 입력은 `graphCenterWordId <- _centerWordId`, `selectedWordId <- _selectedWordId`, `detailTargetWordId <- (_selectedWordDisplayItem != null ? normalizedSelectedWordId : null)` 기준으로 유지하되, center/selected/detail 후보가 blank string이면 adapter로 전달하지 않도록 caller-local 방어를 추가했다.
- `layoutPreset`은 `ExplorerWorkspaceLayoutPreset.balanced`, `origin`은 `ExplorerWorkspaceTransitionOrigin.routeAlias`로 projection 호출 인자에만 고정했고, field/history/source of truth/runtime policy state로 확장하지 않았다.
- projection 결과는 `build()` 시작부 local final과 debug assert에서만 참조하며, UI prop, widget tree, route, Navigator, persistence, repository 호출에는 연결하지 않았다.
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`를 추가해 private projection getter 존재, blank guard, detail payload gating, field/history 비저장, 비시각 경계 유지 여부를 source-level로 검증했다.
- `docs/ux/explorer_workspace_unification.md`에 Phase 7-F 구현 기록을 추가해 current owner 유지, derived snapshot 경계, 금지 확장 미적용 상태를 문서화했다.

## 2026-05-22 Phase 7-E projection adapter integration boundary planning

- Phase 7-E를 adapter 연결 전 경계 조사와 proposal 문서화 단계로 기록했다. 이번 단계는 구현 단계가 아니며 `WordExplorerScreen` 수정 승인, feature 브랜치 생성 승인, runtime/UI 구현 승인으로 간주하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 `17.38 Phase 7-E projection adapter integration boundary planning` 섹션을 추가해 current owner state 조사 결과, build/callback/setState 경계, adapter 연결 후보 A/B/C 비교, 추천 후보 B, forbidden expansion, unresolved / precondition, feature 전환 전 조건을 정리했다.
- current code 기준 projection 입력 출처를 `graphCenterWordId <- _centerWordId`, `selectedWordId <- _selectedWordId`, `detailTargetWordId <- (_selectedWordDisplayItem != null ? _selectedWordId : null)`로 기록했지만, 이는 후속 feature 구현 전 검토 기준이지 구현 승인 사항은 아니다.
- 추천 후보는 `private getter or private method read-only projection`으로 기록했지만, projection result를 field/history/source of truth로 저장하지 않는 derived snapshot 경계로만 취급해야 하며 implementation approval은 아니다.
- implementation status는 `not approved`, feature branch status는 `not approved`로 유지하며, 제안된 후속 feature 브랜치명 `feature/explorer-workspace-phase7f-wordexplorer-projection-boundary` 역시 생성 승인 없이 제안으로만 남긴다.

## 2026-05-22 Phase 7-D read-only projection adapter implementation

- `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart`를 추가해 `WordExplorerScreen`이 이미 소유한 projection candidate 값을 `ExplorerWorkspaceState`로 변환하는 read-only adapter를 구현했다.
- adapter는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`을 모두 명시적 입력으로 받으며, 내부에서 mutation, navigation, persistence, fetch, refresh, synchronization을 수행하지 않는다.
- `detailTargetWordId`는 current owner가 제공한 detail target 의미 값을 read-only projection하는 범위로만 다루며, helper 내부에서 `selectedWordId`로 자동 추론하지 않는다.
- source of truth는 계속 `WordExplorerScreen`에 남아 있고, `ExplorerWorkspace`는 runtime owner가 아니라 projection consumer로 유지한다.
- production mount, route collapse, Navigator rewiring, Repository/DB/Provider authority 변경은 수행하지 않았고 runtime/UI diff가 없도록 범위를 제한했다.
- `test/ui/explorer_workspace_phase7d_readonly_projection_adapter_test.dart`를 추가해 explicit projection, non-inference boundary, 금지 import/호출 부재를 source-level로 검증했다.

## 2026-05-22 Phase 7-C Candidate A feature implementation entry plan

- Phase 7-C를 ExplorerWorkspace 후보 A의 feature 구현 진입 계획을 문서로 고정하는 단계로 기록했다. 이번 단계는 implementation이 아니며, feature 브랜치 생성이나 runtime/UI 구현을 승인하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 `17.36 Phase 7-C Candidate A feature implementation entry plan` 섹션을 추가해 후보 A의 목적, 허용 책임, 금지 책임, current contract 기준 projection 범위, forbidden expansion, feature 브랜치 전환 전 조건, 명령어 기반 검증 계획, UI 확인 기준을 정리했다.
- source of truth는 계속 `WordExplorerScreen`에 남아 있어야 하며, `ExplorerWorkspace`는 projection consumer일 뿐 runtime owner가 아니라고 다시 고정했다.
- implementation status는 `not approved`, feature branch status는 `not approved`로 유지했고, recommended next feature branch는 제안으로만 기록했다.

## 2026-05-21 Phase 7-B first implementation unit candidate selection

- Phase 7-B를 ExplorerWorkspace Phase 7의 첫 구현 단위 후보를 실제 코드 기준으로 조사하고 비교하는 문서 단계로 기록했다. 이번 단계는 implementation이 아니며, feature 브랜치 생성이나 runtime/UI 구현을 승인하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 Phase 7-B 조사 기준, current owner / authority 조사 결과, 후보 A/B/C 비교, 추천 후보, forbidden expansion, feature 브랜치 전환 전 조건을 추가했다.
- 추천 첫 구현 후보는 `WordExplorer -> ExplorerWorkspaceState` 읽기 전용 projection adapter로 기록했지만, 이는 implementation approval이 아니며 source of truth는 계속 `WordExplorerScreen`에 남아 있어야 한다고 명시했다.
- implementation status는 `not approved`, feature branch status는 `not approved`로 유지했다.

## 2026-05-21 Phase 7-A implementation entry boundary planning

- Phase 7-A를 ExplorerWorkspace Phase 6 runtime coordination planning 이후 implementation 진입 전에 허용 범위와 금지선을 고정하는 문서 단계로 기록한다. 이번 단계는 implementation이 아니라 implementation entry boundary planning이며, 후속 feature 브랜치 생성이나 runtime/UI 구현을 자동 승인하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 Phase 7에서 허용 가능한 첫 구현 단위의 조건, 아직 금지해야 할 구현 유형, docs 브랜치에서 feature 브랜치로 전환 가능한 기준, implementation entry checklist를 추가한다.
- runtime/UI 구현 금지, route collapse 금지, canonical owner migration 금지, Provider/Repository/Navigator/persistence authority 이전 금지, coordination candidate의 implementation permission 해석 금지를 Phase 7-A 경계로 다시 고정한다.
- Codex 명령어 기반 검증 항목을 문서에 명시하고, UI 기반 확인은 이번 단계의 수행 대상이 아니며 후속 feature 브랜치에서 UI 동작 변경이 생길 때만 클라이언트 기준으로 분리해 작성한다고 기록한다.

## 2026-05-21 Phase 6-D authority-preserving coordination guardrail policy

- Phase 6-D를 ExplorerWorkspace Phase 6-B coordination candidate inventory와 Phase 6-C authority-crossing risk classification을 owner-preserving guardrail policy로 고정하는 문서 단계로 기록한다. 이번 단계는 implementation planning이 아니며, guardrail policy도 runtime/UI implementation permission이 아니다.
- `allowed wording`, `caution wording`, `forbidden wording`, `allowed planning action`, `review-required planning action`, `blocked planning action`, `authority drift detection criteria`, `escalation criteria`, `implementation status: not approved`를 문서에 추가해 boundary violation 해석을 방지한다.
- `caution wording`은 자유 사용 표현이 아니며 반드시 `reference`, `candidate`, `non-owner`, `caller-local`, `not approved`, `current owner 유지` 같은 제한 문구와 함께 써야 한다. 제한 문구 없이 사용되면 authority drift 위험 표현으로 간주한다.
- review-required planning action은 current owner / authority, forbidden expansion, `implementation status: not approved`를 함께 적어야 하며, 별도 승인 없이 implementation planning으로 넘어갈 수 없다고 고정한다.
- blocked planning action은 구현 단계뿐 아니라 문서상 계획 단계에서도 금지되는 확장으로 정의한다.
- `ExplorerWorkspace`를 runtime coordinator/controller/owner로 승격하지 않으며, Provider/Repository/Navigator/persistence authority와 existing production route 기본값은 그대로 유지한다. route collapse 승인, canonical owner migration, implementation roadmap처럼 읽히는 표현은 금지한다.

## 2026-05-20 Phase 6-C authority-crossing risk classification

- Phase 6-C를 ExplorerWorkspace Phase 6-B candidate의 authority-crossing risk classification 단계로 기록한다. 이번 단계는 implementation planning도 implementation prioritization도 아니며, runtime planning 확장 승인이나 authority migration 승인을 뜻하지 않는다.
- risk level은 `medium`, `high`, `blocked`만 사용하고 `low` 후보는 이번 단계에서 식별하지 않았다. `medium`도 implementation-ready가 아니며 boundary 문서화가 상대적으로 쉬운 후보라는 뜻으로만 제한한다.
- `high`는 owner/controller/coordinator drift, runtime synchronization, route collapse, canonical owner migration 위험이 높은 후보로 정의한다.
- `blocked`는 candidate 자체 폐기를 뜻하지 않으며, reference candidate로 유지할 수 있다. 다만 reference vocabulary / inventory 수준을 넘는 runtime planning 확장, implementation planning, authority migration, route collapse 정당화는 현재 금지된다는 뜻으로 제한한다.
- `ExplorerWorkspace`를 runtime coordinator/controller/owner로 승격하지 않으며, Provider/Repository/Navigator/persistence authority와 existing production route 기본값은 그대로 유지한다. runtime/UI 코드는 변경하지 않는다.

## 2026-05-20 Phase 6-B owner-preserving runtime coordination candidate inventory

- Phase 6-B를 ExplorerWorkspace Phase 6-A 경계를 유지한 owner-preserving runtime coordination candidate inventory 단계로 기록한다. 이번 단계는 implementation 단계가 아니며 runtime execution model, runtime synchronization architecture, route collapse, canonical owner migration을 승인하지 않는다.
- inventory 분류는 `passive coordination candidate`와 `explicit request coordination candidate`로만 제한한다. 여기서 explicit request coordination candidate는 runtime action/execution 의미가 아니라 명시적 요청 후보를 약하게 기록하는 reference vocabulary다.
- 모든 candidate에 current owner / authority 유지, candidate별 forbidden expansion, `implementation status: not approved`를 함께 기록한다.
- `ExplorerWorkspace`를 coordinator, controller, owner로 승격하지 않으며, Provider/Repository/Navigator/persistence authority, existing production route 기본값, `WordExplorerScreen` production authority는 그대로 유지한다. runtime/UI 코드는 변경하지 않는다.

## 2026-05-20 Phase 6-A runtime coordination boundary audit

- Phase 6-A를 ExplorerWorkspace Phase 6 진입 전 문서 경계 audit 단계로 기록한다. 이 단계는 runtime/UI 구현 단계가 아니며, runtime execution model 승인 문서도 아니다.
- `docs/ux/explorer_workspace_unification.md`에서 `workspace action`, `restore action`, `semantic transition`, route alias/collapse, staged roadmap 표현을 preview/reference interaction vocabulary와 historical/reference roadmap 기록으로 다시 고정했다.
- `runtime coordination planning`은 planning input과 reference candidate 정리만 뜻하며, runtime orchestration implementation readiness, runtime synchronization architecture 승인, eventual runtime structure 확정을 의미하지 않음을 명시했다.
- `ExplorerWorkspace`를 권한 주체나 실행 주체처럼 읽게 만드는 표현을 약화하고, coordination vocabulary가 canonical owner migration, route collapse 승인, Provider/Repository/Navigator/persistence authority 재배치의 근거로 해석되지 않도록 경계를 보강했다.
- Provider/Repository/Navigator/persistence authority, existing production route 기본값, `WordExplorerScreen` production authority는 유지하며 runtime/UI 코드는 변경하지 않았다.

## 2026-05-20 Phase 5-I ExplorerWorkspace terminology hardening

- Phase 5-I를 ExplorerWorkspace Phase 5 종료 안정화를 위한 terminology hardening 단계로 기록한다. 이 단계는 새 설계 추가가 아니라 기존 문서 표현을 preview-only orchestration semantics boundary에 맞춰 약화하는 작업이다.
- `owner`, `canonical path`, `수렴`, `semantic navigation spine`, `global/universal entry point`처럼 runtime ownership, production commitment, canonical authority로 오해될 수 있는 표현을 candidate, reference direction, future evaluation target, non-owner semantics로 정리했다.
- Phase 5 종료는 preview-only orchestration semantics의 boundary stabilization만 뜻하며, production migration, runtime coordination implementation, route collapse, canonical owner migration, repository/Navigator/persistence authority 이전을 의미하지 않음을 명시했다.
- 다음 단계는 implementation이 아니라 runtime coordination planning 단계로만 해석해야 하며, 기존 Phase 5-F/G/H boundary 의미는 변경하지 않는다.

## 2026-05-20 Phase 5-H ExplorerWorkspace semantic transition boundary

- Phase 5-H를 workspace 내부의 focus/context/surface 전환을 semantic transition boundary로 정리하는 문서 단계로 기록한다. 이 단계는 production migration이나 route collapse 단계가 아니다.
- semantic context transition은 workspace-local orchestration semantics로만 정리하고, route navigation이나 canonical selection 변경으로 확장하지 않는다.
- focus transition boundary와 foreground surface transition은 authority 이동이 아니라 foreground/emphasis 전환으로만 정리한다.
- temporary focus carry-over는 temporary orchestration continuity로만 제한하고, persistence, repository authority, Navigator authority로 확장하지 않는다.
- graph/detail/context transition 관계와 fixed entry surface transition request를 owner migration 없이 workspace-local coordination 관점에서만 정리했다.
- transition semantics와 canonical selection boundary를 분리하고, runtime/UI 코드 무변경, repository/Navigator/persistence authority 비이전 경계를 유지한다.

## 2026-05-20 Phase 5-G ExplorerWorkspace workspace composition boundary

- Phase 5-G를 `ExplorerWorkspace` 내부 surface들의 workspace composition boundary를 문서로 정리하는 단계로 기록한다. 이 단계는 production migration이나 route collapse 단계가 아니다.
- workspace composition boundary는 ownership boundary가 아니라 surface coordination contract로만 정리한다. 여러 surface의 공존을 canonical owner 병합으로 해석하지 않는다.
- orchestration layer composition은 UI-level coordination으로만 두고 authority layer로 확장하지 않는다.
- surface registration은 문서상 semantics로만 두고 runtime plugin 구조, dynamic registration API, detachable runtime module로 확장하지 않는다.
- workspace-local lifecycle coordination은 canonical lifecycle이 아니라 local coordination lifecycle로만 정리한다.
- detachable surface는 실제 분리 구현이 아니라 해석 후보로만 제한하고, composition contract와 authority boundary를 계속 분리한다.

## 2026-05-20 Phase 5-F ExplorerWorkspace graph/detail hierarchy and temporary focus lifecycle

- Phase 5-F를 `GraphPanel` / `DetailPane` hierarchy와 temporary focus lifecycle을 문서로 정리하는 단계로 기록한다. 이 단계는 production migration이나 route collapse 단계가 아니다.
- Graph / Detail hierarchy는 ownership hierarchy가 아니라 orchestration/foreground hierarchy 후보로만 정리한다. Graph와 Detail 사이에 canonical owner 관계를 부여하지 않는다.
- contextual foreground semantics는 authority semantics가 아니라 현재 context에서 어느 surface가 전경에 놓이는지 설명하는 비권위 표현으로만 정리한다.
- temporary focus lifecycle은 `focus acquisition`, `focus decay`, `focus disposal`의 UI-level temporary lifecycle로만 정리하고, canonical selection, repository authority, Navigator authority, persistence authority로 확장하지 않는다.
- graph/detail synchronization boundary, semantic context transition, temporary expansion vs canonical selection boundary를 owner migration 없이 workspace coordination 관점에서만 정리했다.
- `WordExplorerScreen` production authority 유지, runtime/UI 코드 무변경, repository/Navigator/persistence authority 비이전 경계를 유지한다.

## 2026-05-19 Phase 5-E ExplorerWorkspace global creation entry surface candidate

- Phase 5-E를 `AddWordFixedAction`을 global creation entry surface candidate로 정리하는 문서/경계 단계로 기록한다. 이 단계는 preview-only boundary 안에 머무르며 production replacement가 아니다.
- Add Word는 creation entry / explicit creation request surface 후보로만 정의한다. canonical insertion authority, repository owner, persistence owner, route owner로 확대하지 않는다.
- Add Word action은 semantic creation request 후보일 뿐이며, repository write, persistence 저장, route push, center 변경, selection 확정, detail target 확정을 직접 소유하지 않는다.
- Rail/Search/Graph/Detail과의 관계는 workspace composition 안에서의 후보 관계로만 정리하고, owner 이전 또는 production path 재배선의 근거로 해석하지 않는다.
- `WordExplorerScreen` production authority, route collapse 금지, repository/Navigator/persistence authority 비이전, runtime/UI 코드 무변경 경계를 유지한다.

## 2026-05-19 Phase 5-D ExplorerWorkspace fixed search anchor / semantic entry point candidate

- Phase 5-D를 `GlobalSearch`를 fixed search anchor / semantic entry point candidate로 정리하는 문서/경계 단계로 기록한다. 이 단계는 preview-only boundary 안에 머무르며 production replacement가 아니다.
- Search는 corpus entry, workspace orientation, explicit retarget request surface 후보로만 정의한다. canonical selection owner, graph/detail owner, route owner, persistence owner로 확대하지 않는다.
- Search result 선택은 semantic retarget request 후보일 뿐이며, graph center 확정, detail target 확정, canonical selection 확정, route push, history restore를 직접 소유하지 않는다.
- `temporary focus initiation`과의 관계는 후보 관계로만 정리하고, focus owner 이전, persistent focus policy, persisted layout 결정 주체로 해석하지 않는다.
- `WordExplorerScreen` production authority, route collapse 금지, repository/Navigator/persistence authority 비이전, runtime/UI 코드 무변경 경계를 유지한다.

## 2026-05-19 Phase 5-C ExplorerWorkspace fixed navigation rail candidate

- Phase 5-C를 `StrongRail`의 semantic 역할을 fixed navigation rail candidate로 정리하는 문서/경계 단계로 기록한다. 이 단계는 preview-only boundary 안에 머무르며 production replacement가 아니다.
- `StrongRail`은 strong anchor 접근과 workspace orientation을 위한 stable navigation spine 후보로만 정의한다. graph/detail data owner, repository owner, Navigator owner, persistence/history authority로 확대하지 않는다.
- `persistent narrow rail`은 rail이 좁은 폭으로 계속 남는 시각적 fixed rail 후보라는 뜻으로만 사용한다. persisted layout 저장, route restore, Navigator history 결합, repository-backed preference 의미는 포함하지 않는다.
- rail과 graph/detail orchestration의 관계를 보조적 navigation axis 후보로 제한하고, `WordExplorerScreen` production authority, route collapse 금지, repository/Navigator/persistence authority 비이전 경계를 유지한다.
- `active`/`focused`/`preview` 표현은 새 canonical state가 아니라 기존 workspace state와 preview-only 표현에서 파생되는 비권위 표시로만 정리했다.

## 2026-05-19 Phase 5-B ExplorerWorkspace layout state policy / preset UX refinement

- Phase 5-B를 preview-only layout state policy와 preset UX semantics를 더 명확히 고정하는 단계로 기록한다. 이 단계는 production replacement가 아니다.
- `ExplorerWorkspacePreviewInteractionHost`의 preview-local visibility state를 `graph + detail`, `graph only`, `detail only` 세 상태로 고정하고 `graph hidden + detail hidden` empty workspace 상태를 금지했다.
- preset은 recommended orchestration snapshot, visibility는 current local workspace state로 분리했다. preset 전환이 local visibility state를 강제로 초기화하거나 authority를 이전하지 않도록 유지했다.
- `balanced`를 preview 기본 preset으로 유지하고, `graphFocused`와 `detailFocused`는 canonical/persistence authority가 아닌 preview orchestration semantics로만 설명하도록 UI와 문서를 정리했다.
- `ExplorerWorkspace`에 최소 하나의 semantic panel visible assert를 추가하고, 마지막 visible panel 숨기기 방어를 preview-only UX에서 더 명확히 드러냈다.
- `WordExplorerScreen` production owner, production route 기본값, repository ownership, Navigator ownership, canonical authority, persistence/history authority는 변경하지 않았다.
- Phase 5-B widget/source regression test와 UX/architecture/changelog 문서를 현행화했다.

## 2026-05-19 Phase 5-A preview-only layout orchestration

- Phase 5-A를 preview-only layout orchestration 검증 단계로 기록한다. 이 단계는 production replacement가 아니다.
- `ExplorerWorkspacePreviewInteractionHost`에 preview host 내부 local orchestration state를 추가해 `balanced`, `graphFocused`, `detailFocused` preset 전환과 graph/detail panel visibility 조율을 preview 내부에서만 검증한다.
- preset 전환은 semantic id와 canonical item은 유지한 채 layout만 조율하도록 제한한다. panel visibility와 split ratio는 preview host local state에서만 관리한다.
- `WordExplorerScreen` production owner, production route 기본값, repository ownership, Navigator ownership, canonical authority, persistence/history authority는 유지한다.
- dummy/fallback display item, fake canonical item, production route 교체, route collapse는 이번 단계에서도 추가하지 않는다.
- Phase 5-A widget test와 source-level regression test를 추가하고, 관련 UX/architecture 문서를 현행화했다.
## 2026-05-19 Phase 5-A-1 route 미연결 preview access boundary

- Phase 5-A-1을 route 미연결 preview access boundary 단계로 기록한다. 이 단계는 production route 변경 없이 preview UI 직접 확인용 최소 실행 진입점을 여는 작업이다.
- `lib/main_explorer_workspace_preview.dart` 엔트리 포인트를 추가하고 `flutter run -t lib/main_explorer_workspace_preview.dart` 실행으로 preview-only host를 별도 app 루트에서 띄울 수 있게 했다.
- preview access는 production route, `HomeScreen`, `WordExplorerScreen`, production Navigator tree에 연결하지 않는다.
- preview access는 기존 preview-only input만 사용하며 repository ownership, persistence/history access, display item projection, dummy/fallback display item 추가를 수행하지 않는다.
- Phase 5-A-1 widget/source boundary test와 관련 UX/architecture 문서를 추가했다.

## 2026-05-16 Phase 4-E ExplorerWorkspace preview-only composition boundary

- Phase 4-E를 production replacement가 아니라 ExplorerWorkspace preview-only composition boundary를 고정하는 문서 및 source-level regression test 단계로 기록했다.
- `ExplorerWorkspacePreviewScreen`은 production owner 또는 source of truth가 아니며, workspace-local orchestration은 ownership 이전이 아님을 명시했다.
- Projection lifecycle은 UI-level lifecycle로 제한하고 repository/data lifecycle, Navigator history, route restore, canonical selection ownership과 분리했다.
- production route 기본값, `HomeScreen` production entry, `WordExplorerScreen` production owner, repository/read owner, Navigator owner는 변경하지 않았다.
- preview composition/orchestration boundary가 production import tree, repository ownership, route collapse, dummy id/display item fallback으로 확장되지 않도록 regression test를 추가했다.

## 2026-05-16 Phase 4-D ExplorerWorkspace preview-local interaction boundary

- Phase 4-D를 ExplorerWorkspace preview 내부에서만 동작하는 preview-local interaction boundary 검증 단계로 기록했다.
- `ExplorerWorkspacePreviewInteractionHost`를 추가해 `ExplorerWorkspacePreviewInput`에 이미 들어온 non-empty id만 사용한 graph/detail target 전환을 preview 내부 ephemeral state로 제한했다.
- 기존 `ExplorerWorkspacePreviewScreen`은 read-only projection wrapper로 유지했고, production route 기본값과 `HomeScreen` production entry는 변경하지 않았다.
- DB 조회, repository/read owner 이전, Navigator 호출, route alias 기반 interaction, `WordGraphScreen`/`WordDetailScreen`/`WordExplorerScreen` 직접 embed, dummy id/display item 생성은 수행하지 않았다.
- Phase 4-D boundary regression test를 추가해 preview-local interaction이 production owner, read boundary, route boundary로 확장되지 않는지 검증하도록 했다.

## 2026-05-16 Phase 4-C ExplorerWorkspace passive synchronization boundary

- Phase 4-C를 passive synchronization 허용 범위 검증 단계로 기록하고, production replacement 또는 owner migration 단계가 아님을 명시했다.
- `ExplorerWorkspacePreviewInput` 기반 real projection에서 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`가 동시에 들어와도 병합, 추론, 동기화 ownership으로 확장되지 않는지 boundary regression test를 추가했다.
- projection 관계가 callback/state mutation API, Navigator/history owner, repository/read source owner, search result/display item/explorer history source 연결로 확장되지 않도록 source-level 검증을 보강했다.
- production `lib/` 코드는 변경하지 않았고, production route 기본값과 `WordExplorerScreen` production owner 구조를 유지했다.

## 2026-05-16 Phase 4-B ExplorerWorkspace real projection input

- `ExplorerWorkspacePreviewInput`을 추가해 hidden preview wrapper가 production-compatible real id projection shape를 받을 수 있는 경계를 분리했다.
- projection input은 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`만 보유하며 callback, repository, Navigator, display item, history source를 보유하지 않는다.
- `ExplorerWorkspacePreviewScreen`은 input을 소비해 `ExplorerWorkspace`에 read-only projection으로 전달하는 역할만 유지한다.
- `WordExplorerScreen` production owner, production route 기본값, production import tree isolation, Navigator history / workspace history 분리는 변경하지 않았다.
- DB existence check, state owner migration, repository/read owner migration, route collapse, `WordGraphScreen`/`WordDetailScreen` 직접 embed, dummy id/display item 생성은 수행하지 않았다.

## 2026-05-16 Phase 4-A ExplorerWorkspace production-hidden preview wrapper

- `ExplorerWorkspacePreviewScreen`을 추가해 production route에 연결하지 않는 숨겨진 preview host boundary를 만들었다.
- wrapper는 `ExplorerWorkspaceState.forExplorerEntry`, `forGraphRouteAlias`, `forDetailRouteAlias` 기반 semantic input만 조립하고 `ExplorerWorkspace`에 전달한다.
- `main.dart`와 `HomeScreen` production entry는 변경하지 않았고, `WordExplorerScreen` production owner 구조를 유지했다.
- state owner migration, repository/read owner 이전, `WordGraphScreen`/`WordDetailScreen` 직접 embed, dummy id/display item 생성은 수행하지 않았다.
- source-level boundary test로 preview wrapper가 production entry에 연결되지 않고 route ownership을 갖지 않는지 검증하도록 보강했다.

## 2026-05-13 Phase 8-3A

- GraphBuilder legacy/public helper inventory 결과를 first slice로 반영해 `GraphBuilder.buildFromRepository`, `GraphBuilder.buildFromVisibleGraphData`, `getWordByIdForGraphSingleWord`에 dormant compatibility `@Deprecated` 표시를 추가했다.
- active graph production path는 `WordGraphScreen` → `getVisibleGraphDataForGraph` → `WordGraphDataCache` → `GraphBuilder.buildMergedVisibleGraphData` 구조로 계속 유지한다.
- API 삭제, method signature 변경, graph screen center bootstrap 변경, stale test 정리, DB schema/UI 구조 변경은 수행하지 않았다.

## 2026-05-12 Phase 8-2

- **Explorer bootstrap graph center read 한정**으로 raw center map 의존을 줄였다.
- `WordExplorerScreen` 초기 bootstrap을 `getWordMapByIdForGraphCenterSingleWord` raw row 해석에서 `getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord` typed contract 소비로 전환했다.
- bootstrap center seed는 `wordId`, representative spelling, strong display, representative transliteration의 기존 표시 의미를 유지하며, selected detail display fallback 순서는 기존 제어 흐름을 보존했다.
- `test/ui/word_explorer_screen_phase8h16_bootstrap_center_display_contract_test.dart`를 추가해 typed center display 우선순위와 split-view/id-only fallback 의미가 기존 bootstrap seed와 일치하는지 검증했다.
- 클라이언트 UI 확인 결과, Explorer 초기 bootstrap coherence와 fallback 체감 확인이 모두 성공했다.
- `GraphBuilder`, graph screen 자체 center bootstrap, `WordEditScreen(word: Map)`, `getWordMapByIdForGraphCenterSingleWord`, public legacy API, DB schema, UI 구조는 변경하지 않았다.

## 2026-05-10 Phase 8-1

- **Home/Detail graph navigation existence check 한정**으로 raw map read 의존을 줄였다.
- `HomeScreen`과 `WordDetailScreen`의 graph 진입 전 확인을 `getWordMapByIdForGraphCenterSingleWord` raw row null-check에서 `wordExistsForGraphNavigation(String id)` boolean probe로 전환했다.
- `wordExistsForGraphNavigation`은 `WORD_TABLE.id` 존재 여부만 확인하며, 표시 필드와 expression row를 요구하지 않는다.
- Explorer bootstrap, `GraphBuilder`, `WordEditScreen(word: Map)`, `getWordMapByIdForGraphCenterSingleWord`, public legacy API, DB schema, UI 구조는 변경하지 않았다.

## 2026-05-10 edit input/output typed boundary

- Production edit input boundary를 typed `WordEditSeed` contract 기준으로 완료했다.
- Edit save output/result를 raw `Map<String, dynamic>` route result에서 typed
  `WordEditSaveResult` contract로 전환했다.
- Graph create post-save payload read를 `GraphCreatePostSavePayload`와
  repository-owned post-save payload API로 분리했다.
- `WordGraphScreen`은 graph create post-save relation payload를 만들 때 더 이상
  raw `editedWordMap` / `postSaveWordMap` carrier에 의존하지 않는다.
- DB table/column/index storage는 변경하지 않았다.
- Active UX authority와 active repository/data authority 문서는 재정의하지 않았다.
- Legacy compatibility는 유지한다. `WordEditScreen(word: Map)`과 raw read API는
  compatibility 및 후속 cleanup 판단 대상으로 남겨둔다.

## 2026-04-25 Phase 8-H 완료

- Phase 8-H 완료 기준과 다음 Phase 이관 항목을 문서화했다.
- 완료 범위는 graph seed / public seed의 `centerWordId` 축소, graph/explorer `_centerWordId` authority 정리, visible node / builder-cache carrier 최소 typed contract 정리, selection / center change callback id 중심 정리다.
- 완료 범위에는 explorer tooltip/history display baseline의 `_ExplorerCenterDisplaySeed` / tooltip display contract 분리, pending side-car 제거, explorer bootstrap / graph visible data projection / graph create-relation post-save 경계의 `Word.fromMap` 우회 제거가 포함된다.
- UX 정책 변경 없음.
- 비대상/이관 항목으로 history selected state 정책 판단, global / generic `Word.fromMap` 정리, analyzer/test baseline 정리를 남겼다.
- global Word.fromMap 제거는 다음 Phase 대상이다.
- history selected state는 UX 정책 판단 대상이다.

## 2026-04-25 Phase 8-H-42

- graph create/relation post-save Word.fromMap residual cleanup first slice를 적용했다.
- `WordGraphScreen`의 create/relation post-save 경계에서 `Word.fromMap(currentWordMap)` 우회와 `getWordByIdForGraphSingleWord(newId)` 기반 full `Word` carrier 생성을 제거했다.
- 후속 관계 생성과 새 graph 전환은 local payload의 `wordId`, `representativeSpelling`만 사용하도록 정리했다.
- relation dialog 대표 표기 fallback, graph refresh, cache invalidation 흐름은 유지했다.
- global `Word.fromMap`, repository public API, graph center payload 전체, UX, history selected state 정책은 변경하지 않았다.

## 2026-04-25 Phase 8-H-40

- graph visible data Word.fromMap residual cleanup first slice를 적용했다.
- repository 내부 graph visible data projection에서 `Word.fromMap(row)` 우회를 제거하고, row의 `id`, `표기1`, `스트롱넘버`, `음역1` 값을 직접 trim해 `GraphVisibleWord`를 생성하도록 정리했다.
- `VisibleWordGraphData.connectedWords` 반환 contract와 기존 order 보장 방식은 유지했다.
- global `Word.fromMap`, repository public API, graph builder/cache, SQL read policy, DB schema, UX는 변경하지 않았다.

## 2026-04-25 Phase 8-H-38

- explorer bootstrap word carrier cleanup first slice를 적용했다.
- `WordExplorerScreen` bootstrap center display seed 생성에서 `Word.fromMap(centerWordMap)` 사용 1곳을 제거했다.
- `_ExplorerCenterDisplaySeed`는 `centerWordMap`의 `id`, `스트롱넘버`, `표기1`, `음역1` 최소 필드만 직접 읽어 생성한다.
- history selected state 정책, global `Word.fromMap`, graph 내부 `Word.fromMap`, repository/DB, graph callback contract, tooltip UX는 변경하지 않았다.

## 2026-04-25 Phase 8-H-37

- `pending display seed side-car final cleanup first slice`를 적용했다.
- `WordExplorerScreen`에서 legacy `onChangeCenterWord(Word)` handler 전달을 중단하고, center change 주경로를 `onChangeCenterWordId`로 유지했다.
- `_pendingCenterDisplaySeedFallback` 필드와 소비 helper를 제거했다.
- center display seed는 `_loadSplitViewDisplayItem(centerWordId)` 결과의 detail-like display item으로 확정하고, split-view read가 `null`인 예외 경로에서만 id-only fallback을 허용한다.
- tooltip UX, history selected state 정책, `Word.fromMap` 일반 경계, `onChangeCenterWord(Word)` public API, repository/DB는 변경하지 않았다.

## 2026-04-25 Phase 8-H-36

- pending center fallback side-car cleanup first slice를 적용했다.
- `WordExplorerScreen`의 pending center fallback carrier를 `Word?`에서 `_ExplorerCenterDisplaySeed?`로 축소했다.
- `centerWordId` callback을 authoritative path로 유지하고, legacy `onChangeCenterWord(Word)`는 explorer에서 display seed 보정값으로 즉시 축소 저장하도록 제한했다.
- pending display seed fallback은 id 일치 시에만 소비하고, mismatch 시 폐기한다.
- tooltip UX, history selected state 정책, history payload schema, `onChangeCenterWord(Word)` public API, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-25 Phase 8-H-34

- explorer center state contract first slice를 적용했다.
- `WordExplorerScreen` center authoritative state를 `_centerWordId`로 줄이고, tooltip/history baseline 값은 private `_ExplorerCenterDisplaySeed`로 분리했다.
- graph seed 전달은 기존 `centerWordId` 기준을 유지했고, `_pendingCenterWordChangeFallback`은 id 일치 시 display seed 보정용 compatibility side-car로 유지했다.
- history selected state 복원 정책, tooltip UX, history payload schema, graph callback/public API, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-25 Phase 8-H-33

- graph center change callback contract first slice를 적용했다.
- `WordGraphScreen`에 `onChangeCenterWordId`를 추가하고, same-node center change dispatch의 주 payload를 `centerWordId`로 축소했다.
- 기존 `onChangeCenterWord(Word)`는 compatibility/local fallback side-car로 유지했다.
- `WordExplorerScreen`은 center change를 id callback으로 소비하고, fallback `Word`는 id 일치 시에만 임시 보조 carrier로 사용하도록 제한했다.
- explorer `_centerWord`, history payload, tooltip contract, selection callback, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계, graph/explorer UX 정책은 변경하지 않았다.

## 2026-04-24 Phase 8-H-32

- graph center state contract first slice를 적용했다.
- `WordGraphScreen` 내부 center authoritative state를 `_centerWordId`로 전환하고, cache key / stale guard / reload 기준 / pending center focus 기준을 `_centerWordId`로 통일했다.
- `_centerWord`는 compatibility/local fallback carrier로 유지하고, center display는 기존 `GraphCenterWordDisplayItem` 경로를 유지했다.
- `onChangeCenterWord`, selection callback, explorer/history, graph builder public signature, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-23 Phase 8-H-30

- graph selection callback contract first slice를 적용했다.
- `WordGraphScreen`에 `onSelectWordId`를 selection callback 주경로로 추가하고, 기존 `onSelectWord`는 compatibility fallback으로 유지했다.
- `WordExplorerScreen._selectWord`의 주 입력을 `selectedWordId`로 전환하고, detail panel 갱신은 기존 split-view id reread 경로를 유지했다.
- `onChangeCenterWord`, `_centerWord`, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계, graph/history/tooltip UX 정책은 변경하지 않았다.

## 2026-04-23 Phase 8-H-28

- graph UI state visible node contract first slice를 적용했다.
- `GraphVisibleNode`를 추가해 `WordGraphScreen` 내부 `_graphWordsById` 저장 carrier를 full `Word`에서 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration` 최소 필드로 줄였다.
- `GraphWordLabelDisplayItem` 주 label 경로, `_centerWord`, `ValueChanged<Word>` callback, explorer callback, `WordGraphScreen` public API는 유지했다.
- repository/DB, `Word.fromMap` 일반 경계, graph builder/cache carrier는 변경하지 않았다.

## 2026-04-22 Phase 8-H-26

- graph builder/cache carrier contract first slice를 적용했다.
- `GraphVisibleWord`를 추가해 graph builder/cache 경계의 connected carrier를 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration` 최소 필드로 줄였다.
- `VisibleWordGraphData.connectedWords`, `WordGraphDataCache`, `GraphBuilder`의 base/expansion 입력 carrier를 full `Word` 대신 graph visible carrier로 연결했다.
- `GraphWordLabelDisplayItem` 주경로, `WordGraphScreen` public API / `_centerWord` / `_graphWordsById` / callback 시그니처, repository/DB read policy, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-22 Phase 8-H-24

- graph seed public API contract first slice를 적용했다.
- `WordGraphScreen`의 주 seed contract를 `centerWordId`로 전환하고, 기존 `centerWord: Word`는 compatibility entrypoint로 남겨 id-only seed로 축소했다.
- home/detail/explorer/graph 내부 graph 진입 caller는 full `Word` 대신 `centerWordId`를 전달하도록 최소 변경했다.
- center display reread, graph label reread, graph data build, `graph_builder`, `word_graph_cache`, repository/DB, `Word.fromMap` 일반 경계, explorer/history payload, graph UX 정책은 변경하지 않았다.

## 2026-04-22 Phase 8-H-22

- graph seed id contract first slice를 적용했다.
- `WordGraphScreen(centerWord: Word)` public API는 유지하면서, graph 내부 seed 소비 경계가 caller `Word`의 표시 필드 대신 `centerWord.id.trim()`만 bootstrap 기준으로 신뢰하도록 정리했다.
- 초기 load와 center update 비교/적용 경계에서 trim된 center id를 사용하고, center display / graph label / graph data는 기존 graph 내부 reread 결과 경로를 유지했다.
- `graph_builder`, `word_graph_cache`, repository, DB, `Word.fromMap` 일반 경계, explorer/history payload, graph UX 정책은 변경하지 않았다.

## 2026-04-21 Phase 8-H-20

- explorer history payload ID contract first slice를 적용했다.
- `_ExplorerHistorySnapshot`의 중심 payload를 `Word` 전체에서 `centerWordId`로 줄이고, payload는 `centerWordId`, `selectedWordId`만 보유하도록 정리했다.
- `_applyHistoryEntry`는 `Word(id: centerWordId)`로 기존 graph center reread 흐름에 연결하고, `_isSameHistoryLocation`은 `centerWordId`, `selectedWordId`만 비교한다.
- tooltip display contract, availability probe contract, `WordGraphScreen(centerWord: Word)`, graph seed public API, `Word.fromMap` 일반 경계, repository/DB는 변경하지 않았다.
- history back/forward UX, selected history 복원 정책, 삭제된 entry fallback 정책은 변경하지 않았다.

## 2026-04-21 Phase 8-H-18

- explorer history tooltip display contract first slice를 적용했다.
- `WordNavigationHistoryTooltipDisplay`를 추가해 tooltip 표시가 `wordId`, 대표 표기, display Strong, 대표 음역 최소 필드를 사용하도록 분리했다.
- `_buildHistoryTooltip`은 더 이상 `entry.payload.centerWord.transliteration1`을 직접 읽지 않고, tooltip display contract의 표시 줄만 소비한다.
- `_ExplorerHistorySnapshot`, back/forward navigation 의미, graph seed, `WordGraphScreen(centerWord: Word)`, `Word.fromMap` 일반 경계, repository/DB는 변경하지 않았다.

## 2026-04-21 Phase 8-H-16

- explorer history availability probe contract first slice를 적용했다.
- `WordExplorerScreen._isHistoryEntryAvailable`의 back/forward 직전 availability 재검증을 `getWordMapByIdForExplorerSingleWord` full map 조회에서 `probeExistingWordIdsForExplorerHistory` id existence probe로 전환했다.
- `_ExplorerHistorySnapshot`, history tooltip/display, graph seed, `Word.fromMap` 일반 경계, explorer UX 정책은 변경하지 않았다.

## 2026-04-20 Phase 8-H-15

- duplicate candidate projection alias contract first slice를 적용했다.
- `findDuplicateCandidates`의 strong exact / normalized strong / non-strong projection row alias를 `word_id`, `language`, `strong_number`, `representative_spelling`, `primary_meaning` canonical 집합으로 맞췄다.
- `_buildDuplicateCandidateDisplayItem`는 canonical alias만 소비하도록 줄였고, `DuplicateCandidateDisplayItem` public field 구조와 duplicate warning UI는 유지했다.
- strong exact / normalized strong / non-strong duplicate 비교 규칙과 create/edit/graph 흐름은 변경하지 않았다.

## 2026-04-19 Phase 8-H-12

- home search ranking candidate contract first slice를 적용했다.
- `HomeSearchRankingCandidate`를 추가해 `searchWordsMap` 내부 ranking helper 입력을 raw row 전체에서 `wordId`, `strongNumber`, indexed spellings / transliterations / meanings 최소 필드로 축소했다.
- `searchWordsMap`의 public 반환형 `List<HomeSearchResultDisplayItem>`과 display projection `_resolveHomeSearchDisplayItemsForPhase32(...)` 흐름은 유지했다.
- strong exact / prefix / partial, spelling exact / prefix / partial, transliteration exact / prefix / partial, meaning partial ranking priority와 id tie-break 정렬 의미는 유지했다.
- `searchStrongExactMap`, `getStrongWordsMap`, `home_screen.dart`, graph / explorer / detail / edit / duplicate / relation add search 경로는 변경하지 않았다.

## 2026-04-18 Phase 8-H-11

- graph center full display contract first slice를 적용했다.
- `GraphCenterWordDisplayItem`을 추가해 center node full display에 필요한 `wordId`, `language`, `displayStrongNumber`, `representativeSpelling`, `representativeTransliteration`, `representativePronunciation`, `primaryMeaning` 최소 필드를 분리했다.
- `WordGraphScreen._buildCenterNode`는 center display contract를 소비하도록 전환했고, `centerWord: Word`, `connectedWords`, graph navigation / selection / expansion / cache key / callback payload는 기존 흐름을 유지했다.
- peripheral node label, secondary label, relation display name은 Phase 8-H-9 결과를 유지했고, `Word.fromMap` 일반 경계 제거는 이번 단계 범위에 포함하지 않았다.
- `test/data/repositories/word_repository_phase8h11_graph_center_display_contract_test.dart`, `test/ui/word_graph_screen_phase8h11_center_display_contract_test.dart`를 추가해 center display projection과 helper widget 표시 경계를 검증했다.

## 2026-04-18 Phase 8-H-9

- graph word label display contract first slice를 적용했다.
- `GraphWordLabelDisplayItem`을 추가해 graph peripheral title, secondary label, relation display name, graph builder label에 필요한 `wordId`, `representativeSpelling`, `representativeTransliteration`, `displayStrongNumber` 최소 필드를 분리했다.
- `VisibleWordGraphData`는 기존 `connectedWords` 흐름을 유지하면서 label 전용 `wordLabels`를 병행 공급하도록 확장했다.
- `GraphBuilder`, `WordGraphScreen`, `WordGraphDataCache`는 label contract 보존과 소비에 필요한 범위만 최소 수정했고, center node full display와 `Word.fromMap` 일반 경계는 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h9_graph_label_display_contract_test.dart`, `test/domain/graph/graph_builder_phase8h9_graph_label_contract_test.dart`를 추가해 representative label projection과 graph builder label fallback을 검증했다.

## 2026-04-18 Phase 8-H-7

- edit 초기 seed 전용 typed contract `WordEditSeed`를 추가했다.
- `WordEditScreen`은 언어, 스트롱넘버, 비고, 의미, expression read result, hidden-slot issue를 seed contract를 통해 초기화하도록 정리했다.
- expression controller group 생성은 `CanonicalExpressionReadResult` 기반 helper를 추가해 연결하고, 기존 legacy row helper는 compatibility 용도로 유지했다.
- hidden-slot issue의 write exclusion 의미와 edit 저장 / validation / submit 정책은 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h7_edit_seed_contract_test.dart`를 추가하고, `word_edit_screen_test.dart`를 보강해 seed 동일성을 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 edit seed typed contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-14 Phase 8-H-5

- `getStrongWordsMap()` 경로에 home default strong list display contract first slice를 적용했다.
- `HomeDefaultStrongListItem`은 기본 strong 목록 consumer에 실제 필요한 `wordId`, `displayStrongNumber`, `representativeSpelling` 최소 필드만 남기도록 정리했다.
- repository strong-list branch는 representative spelling 표시를 기본 strong 목록 전용 typed contract로 projection하고, strong-list mismatch 보호는 최소 contract 기준으로만 제한했다.
- `HomeScreen` 기본 strong 목록 consumer는 새 필드명만 읽도록 최소 수정했고, home search 결과 / 상세 진입 / 기타 흐름은 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h5_home_strong_display_contract_test.dart`를 추가해 representative projection과 legacy fallback baseline을 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 home default strong list display contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-13 Phase 8-H-4

- `searchWords()`의 검색 semantics는 유지한 채 graph relation add search 전용 typed contract first slice를 적용했다.
- graph relation add search 반환 경계는 raw `Word` 대신 `wordId`, `representativeSpelling`, `primaryMeaning`, `displayStrongNumber` 최소 필드만 노출하도록 축소했다.
- `WordGraphScreen` 관계 추가 대상 선택 다이얼로그는 raw slot field 대신 동일 typed contract만 소비하도록 정리했다.
- create-after-save 이후 관계 추가 흐름은 유지하면서 `_showCreateRelationDialog` 입력도 관계 생성에 필요한 최소 인자로 축소했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 graph relation add search contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-13 Phase 8-H-3

- `findDuplicateCandidates`의 query semantics와 strong / non-strong duplicate 판정 규칙은 유지한 채 duplicate warning 전용 typed display contract first slice를 적용했다.
- duplicate candidate 반환 경계는 raw `Map<String, dynamic>` 대신 `wordId`, `language`, `strongNumber`, `representativeSpelling`, `primaryMeaning` 최소 필드만 노출하도록 축소했다.
- `WordEditScreen`, `WordGraphScreen` duplicate warning dialog는 동일한 typed contract만 소비하도록 정리했다.
- duplicate display contract 회귀를 확인하도록 기존 representative query contract test의 duplicate candidate 검증을 보강했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 display contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-H-1

- `findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups`를 representative spelling / transliteration 기준 query first slice로 전환했다.
- `findDuplicateCandidates`는 strong 우선 규칙을 유지한 채 non-strong duplicate 비교축을 representative spelling 기준으로 전환했다.
- representative row가 존재하는데 transliteration이 blank인 경우 legacy `음역1`로 복귀하지 않도록 제한했다.
- duplicate warning dialog는 기존 contract를 유지하면서 안내 문구를 representative 표기 기준으로만 최소 조정했다.
- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`를 추가해 collision / duplicate representative query first slice를 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 Phase 8-H-1 first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-B

- `createWord`, `updateWord`의 expression write 흐름을 canonical expression set -> normalized `word_expression_set` row 저장 -> `WORD_TABLE` 6-slot projection 생성 순서로 재정렬했다.
- `WORD_TABLE` expression slot은 write authority가 아니라 projection/compatibility 출력물로 낮췄고, 이번 단계에서는 6-slot 범위를 유지했다.
- `deleteWord`, `undoLastChange` history는 기존 `WORD_TABLE` compatibility snapshot을 유지하면서 normalized snapshot을 함께 저장하도록 보강했다.
- `undoLastChange`는 신규 history row에서 normalized restore를 우선 사용하고, 기존 history row는 legacy fallback을 유지한다.
- Phase 8-B repository 테스트를 보강해 create/update/delete/undo, save/undo reread, normalized-restore 우선 / legacy-fallback 규칙을 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 write authority first switch와 projection/compatibility 유지 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-A

- `getWordMapById`, `getWordMapByIdForExplorerSingleWord` 두 raw single-word public read를 Phase 8-A first slice로 `NORMALIZED_WITH_FALLBACK` 경로에 편입했다.
- 두 경로는 새 fallback/resolver를 만들지 않고 기존 detail-like single-word materialization helper를 재사용한다.
- 반환 contract는 계속 raw `Map<String, dynamic>`로 유지하고, visible mismatch가 생기면 기존 legacy fallback을 그대로 사용한다.
- `getWordsByIds`, `getWordsMap`, 기타 generic batch/list read는 이번 단계에서 바꾸지 않았다.
- Phase 8-A 전용 repository 테스트를 추가해 경로 전환과 expression projection 보존을 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에 raw single-word 2경로 first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-11 Phase 7-11

- detail-like display shared contract `WordDetailLikeDisplayItem`를 추가했다.
- `getWordDetailLikeDisplayItemByIdForDetailScreen`, `getWordDetailLikeDisplayItemByIdForSplitView`의 public 반환형을 raw `Map<String, dynamic>`에서 shared contract로 전환했다.
- repository 내부에 `raw row -> fallback 반영 -> detail-like display contract` 경계를 추가하고, graph/safe-zone raw single-word read는 기존 raw 경계를 유지했다.
- `WordInfoPanel`이 raw map 기반 helper와 직접 key 해석을 제거하고 typed display renderer로 전환됐다.
- `WordDetailScreen`과 `WordExplorerScreen`이 공통 detail-like contract를 panel에 전달하도록 정리됐고, 편집/이동 같은 화면별 동작은 on-demand raw reread로 분리했다.
- `HomeScreen` detail navigation은 새 detail contract를 전달하는 최소 caller 적응만 반영했다.
- `docs/database/read_source_migration.md`에 Phase 7-11 detail-like shared contract 적용 범위와 구조 결과를 반영했다.

## 2026-04-11 Phase 7-7

- home search result display 전용 controlled contract `HomeSearchResultDisplayItem`을 추가했다.
- `searchStrongExactMap`, `searchWordsMap`의 public 반환형을 raw `Map<String, dynamic>` 목록에서 contract 목록으로 전환했다.
- repository 내부에서 `raw row -> fallback 반영 -> display contract 생성` 경계를 고정했다.
- `HomeScreen` search branch가 raw row, `Word.fromMap`, `buildHomeWordDisplaySummary`, raw subtitle 추출 없이 contract만 소비하도록 정리했다.
- `searchWordsMap('')`는 더 이상 `getWordsMap(limit: limit)` browse path로 내려가지 않고 빈 결과를 반환한다.
- `docs/database/read_source_migration.md`에 Phase 7-7 contract 적용 범위와 구조 결과를 반영했다.

## 2026-04-11 Phase 7-4

- Home search branch가 detail / explorer / graph navigation에 search row 전체를 직접 넘기지 않도록 `wordId` 기준 helper로 정리했다.
- search result navigation은 detail `getWordDetailLikeDisplayItemByIdForDetailScreen`, graph `getWordMapByIdForGraphCenterSingleWord`, explorer `initialWordId` bootstrap 구조로 분리했다.
- `WordExplorerScreen` route payload를 `initialWordId`로 줄이고 init bootstrap에서 graph center read + split-view read를 사용하도록 바꿨다.
- explorer history snapshot은 full selected row 대신 selected word id만 보관하도록 정리했다.

## 2026-04-11

### 변경
- controlled zone 판정 기준을 `docs/database/read_source_migration.md` 에 정책 문장으로 문서화했다.
- graph display / history probe / legacy generic read context의 3계층 구조 구분을 확정했다.
- read 승격 절차를 `generic -> owner-specific 분리 -> 반환 계약 고정 -> 관측/검증 가능성 확보 -> controlled 판정` 기준으로 고정했다.
- explorer history existence probe 전용 API `probeExistingWordIdsForExplorerHistory` 를 추가했다.
- explorer history availability 판단은 더 이상 generic `getWordsByIds` full row read를 사용하지 않고 `Set<String>` probe 결과를 직접 사용한다.
- history probe 구현은 `SELECT id FROM WORD_TABLE WHERE id IN (...)` 로 최소화했고 `getWordsByIds` 자체는 그대로 유지했다.
- probe는 display/read-source 해석 대상이 아니므로 기존 `ReadSourceDebugCollector` 를 재사용하지 않고 query 실행부 근처에 전용 collector TODO 만 남겼다.
- history probe 전용 repository 테스트를 추가하고 구조 검증 명령으로 explorer caller의 generic batch 의존 제거를 확인했다.

## 2026-04-10

### 변경
- `readForGraphSingleWord` 를 legacy single read 에서 controlled `normalizedWithFallback` 경로로 승격했다.
- `getWordMapByIdForGraphSingleWord` 는 public API contract 와 기존 `readForGraphSingleWord` context 를 유지한 채 graph single-word 전용 controlled read 로 전환했다.
- graph single-word stable / display-mismatch fallback 을 닫는 repository 테스트와 `tool/verify_graph_single_word_context.dart` 검증 스크립트를 추가했다.
- `getWordsByIds` 는 generic legacy zone 으로 그대로 유지했고 split/detail/save/undo safe zone 은 변경하지 않았다.
- `docs/database/read_source_migration.md` 에 Phase 5 범위와 검증 결과를 반영했다.

## 2026-04-09

### 변경
- graph batch read 를 `readForGraphBatch` 단일 policy zone 으로 승격했다.
- `getWordsByIdsForGraphBatch` 에 graph batch 전용 adapter 를 도입하고 detail/split safe zone 의 detail-like display guard 를 재사용했다.
- generic `getWordsByIds` 는 그대로 `LEGACY` 로 유지하고 collector context 분리를 보존했다.
- repository 테스트에 graph batch normalized success / display-mismatch fallback 검증을 추가했다.
- `tool/verify_graph_batch_context.dart` 를 Phase 4-E 기준 command 검증 스크립트로 갱신했다.
- `docs/database/read_source_migration.md` 에 Phase 4-E 범위와 검증 결과를 반영했다.

## 2026-04-08

### 변경
- split view 표시 read를 detail-like `normalizedWithFallback` 경로로 상향했다.
- `readForSplitViewSingleWord` context를 `NORMALIZED_WITH_FALLBACK` 대상에 편입했다.
- split view wrapper와 explorer history probe wrapper를 분리 유지했다.
- repository 정책 테스트에 split view normalized success / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 Phase 4-B 기준 상태를 반영했다.

## 2026-04-04

### 변경
- 문서 구조를 `/docs` 기준으로 정리했다.
- read source 전환 1차 기반을 repository 내부에 도입했다.
- 기본 read source policy는 아직 `LEGACY`로 유지한다.
- normalized read adapter와 fallback 판정/관측 모델을 연결했다.
- 실제 normalized read 활성 전환은 아직 수행하지 않았다.
- `WordDetailScreen` 전용 제한 경로 `getWordDetailLikeDisplayItemByIdForDetailScreen`를 추가했다.
- 상세 화면은 `widget.word` 초기 표시를 유지한 채 백그라운드에서만 phase 2 read를 시도한다.
- fallback reason에 `user_visible_display_mismatch`를 추가하고 in-memory observation 항목을 확장했다.
- repository 테스트에 detail-only success / empty fallback / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 phase 2 제한 적용 범위, rollback, 관측 기준을 반영했다.
