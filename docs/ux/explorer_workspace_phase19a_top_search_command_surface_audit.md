# ExplorerWorkspace Phase 19-A 상단 검색/명령 surface 감사

> 문서 성격: reference/context 및 audit 기록
>
> 현재 active boundary 요약은 `docs/ux/explorer_workspace_unification.md`의 Phase 19-A 절을 따른다.
>
> 이 문서는 구현 승인, production shell 변경, owner migration 승인 문서가 아니다.

## 1. 감사 목적

Phase 19-A는 상단 검색/명령 surface와 좌측 control surface의 장기 역할을 재정의하기 위한 read-only UX/architecture audit다.

이번 감사는 현재 일반 검색 입력의 mount 위치, 상태 ownership, large-screen/small-screen 분기, Strong Rail 및 우측 Explorer와의 경계를 실제 source 기준으로 확인한다. 상단 검색/명령 surface 도입은 후보로만 평가하며, production code, test code, DB, repository, DTO/model, dependency를 변경하지 않는다.

## 2. 확인 기준

- 기준 HEAD: `92a31613268386aec944cdd3360fb7f6c7e5c038`
- 기준 production home: `HomeScreen`
- 기준 production Explorer owner: `WordExplorerScreen`
- large-screen 분기 기준: `900.0` 이상
- Phase 18 최종 경계 기준:
  - 일반 검색 입력과 `Strong/스트롱` rail-local jump 입력은 분리한다.
  - graph selection passive sync는 Strong Rail passive feedback과 rail-local jump만 수행한다.
  - graph selection은 우측 Explorer를 retarget하거나 remount하지 않는다.
  - small-screen은 기존 검색 결과 item의 detail route 흐름을 유지한다.

## 3. 확인한 주요 파일

- `lib/ui/home_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/explorer_workspace/explorer_workspace.dart`
- `lib/ui/explorer_workspace/explorer_workspace_contract.dart`
- `docs/architecture/explorer_workspace_constitution.md`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`
- `test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart`
- `test/ui/explorer_workspace_phase17c_state_source_guardrail_test.dart`
- `test/ui/home_screen_phase18a_large_split_shell_test.dart`
- `test/ui/home_screen_phase18b_left_control_pane_direction_test.dart`
- `test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart`
- `test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart`
- `test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart`
- `test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart`
- `test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart`
- `test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart`
- `test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart`
- `test/ui/home_screen_phase18n_runtime_guardrail_test.dart`

## 4. 현재 일반 검색 입력 mount 경로

현재 일반 검색 입력은 다음 production build 경로에 mount된다.

```text
main.dart
└─ HomeScreen
   └─ Scaffold.body
      └─ LayoutBuilder
         └─ homeSearchControlArea
            └─ _searchController 기반 일반 검색 TextField
```

`homeSearchControlArea`는 `homePane`의 첫 번째 child다. large-screen에서는 `homePane` 전체가 좌측 `Expanded(flex: 2)`에 mount되고, 우측에는 `WordExplorerScreen`이 `Expanded(flex: 6)`으로 mount된다. 따라서 현재 일반 검색 입력은 좌측 control surface의 상단에 있으며, 좌우 전체 workspace를 가로지르는 상단 surface는 아니다.

small-screen에서도 같은 `homeSearchControlArea`가 `homePane` 상단에 mount된다. 이 분기에는 embedded `WordExplorerScreen`, 별도 `Strong/스트롱` 입력, Strong Rail이 없다.

## 5. 일반 검색 상태와 목록 흐름 ownership

현재 일반 검색과 목록 흐름의 owner는 `HomeScreen` private state다.

| 책임 | 현재 owner/source |
| --- | --- |
| 검색 입력 | `_searchController` |
| 검색 실행 | `_runSearch()` |
| 검색 초기화 | `_clearSearch()` |
| 검색 후보 future | `_searchWordsFuture` |
| default/search 목록 전환 | `_isShowingDefaultStrongList` |
| 검색 후보 read 시작 | `_createSearchWordsFuture()` |
| 기본 Strong 목록 future | `_defaultStrongListFuture` |
| 좌측 목록 scroll | `_listScrollController` |

`_runSearch()`는 `_searchController.text`를 읽고 `_isShowingDefaultStrongList`를 전환한 뒤 `_setVisibleWordListFuture()`를 호출한다. `_createSearchWordsFuture()`는 기존 `_repository.searchStrongExactMap(...)` 또는 `_repository.searchWordsMap(...)` 경로를 사용한다.

검색 후보 목록과 default Strong 목록은 `homeWordListSurface`에서 교체 표시된다. 이 목록 surface는 현재 좌측 control surface에 속한다.

## 6. 현재 Strong/스트롱 입력 mount 및 동작 경로

별도 `Strong/스트롱` 입력은 large-screen `homeSearchControlArea` 내부에만 mount된다.

```text
_strongJumpController
└─ _handleStrongRailJumpChanged(...) / _handleStrongRailJumpSubmitted(...)
   └─ _runStrongRailJump(...)
      └─ _jumpToStrongInRail(...)
         └─ _scrollToStrongRailIndex(...)
```

이 경로는 Strong Rail 내부 scroll 위치만 이동한다. `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`, `_largeScreenExplorerWordId`, `_showWordInLargeScreenExplorerPane(...)`, `Navigator.push`, repository read와 결합하지 않는다.

small-screen에서는 일반 검색 입력의 `_handleSearchChanged(...)`가 Strong 형식 입력을 default Strong 목록 내부 local jump로 사용할 수 있다. 이 동작은 small-screen의 기존 단일 검색 surface 호환 흐름이며, 별도 Strong Rail 또는 embedded Explorer를 도입하지 않는다.

## 7. 현재 좌측 control surface 구성

large-screen 좌측 control surface는 현재 다음 요소를 포함한다.

- 일반 검색 입력, 검색 실행, 검색 초기화
- `Strong/스트롱` rail-local jump 입력
- Strong Rail
- default Strong 목록 또는 검색 후보 목록
- `_largeScreenExplorerWordId` 기반 current target feedback
- graph selection callback 기반 passive selected Strong feedback

Strong Rail item tap과 default/search 목록 item 본문 tap은 명시적 사용자 선택으로 기존 large-screen Explorer retarget request를 발생시킬 수 있다. 반면 Strong local jump와 graph selection passive sync는 retarget request가 아니다.

## 8. 현재 우측 Explorer pane retarget 경로

large-screen에서 명시적 후보/Strong anchor 선택에 따른 우측 Explorer retarget 경로는 다음과 같다.

```text
default Strong item 본문 tap
또는 search result item 본문 tap
또는 Strong Rail item tap
└─ _showWordInLargeScreenExplorerPane(wordId)
   └─ _largeScreenExplorerWordId 갱신
      └─ WordExplorerScreen(
           key: ValueKey(_largeScreenExplorerWordId),
           initialWordId: _largeScreenExplorerWordId,
         ) remount
```

`WordExplorerScreen`은 `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, 내부 history와 repository read를 계속 소유한다.

graph selection은 `WordExplorerScreen.onSelectedStrongWordChanged`를 통해 `HomeScreen`에 passive Strong 정보를 전달할 수 있지만, 이 callback은 `_handleExplorerSelectedStrongWordChanged(...)`에서 rail-local passive state와 rail jump만 갱신한다. graph selection은 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

## 9. large-screen / small-screen 일반 검색 흐름 차이

| 구분 | large-screen | small-screen |
| --- | --- | --- |
| 일반 검색 입력 | 좌측 control surface 상단 | `homePane` 상단 |
| 별도 `Strong/스트롱` 입력 | 있음 | 없음 |
| Strong Rail | 있음 | 없음 |
| 검색 후보 목록 | 좌측 목록 surface | 단일 home 목록 surface |
| 검색 후보 본문 tap | 우측 embedded Explorer retarget | `WordDetailScreen` route 진입 |
| embedded `WordExplorerScreen` | 있음 | 없음 |
| Strong 형식 입력의 자동 jump | large-screen 일반 검색 field에서는 수행하지 않음 | default Strong 목록 local jump 호환 흐름 유지 |

상단 검색/명령 surface 후보를 검토할 때 이 responsive 차이를 제거하거나 통합된 하나의 navigation 결과로 바꾸면 안 된다.

## 10. 상단 검색/명령 surface 도입 가능성 판단

### 10.1 가능성

일반 검색 입력을 large-screen 좌우 split 상단에 보이는 surface로 시각 재배치하는 것은 구조적으로 가능하다.

현재 일반 검색 state와 handler가 `HomeScreen` private state에 있으므로, `HomeScreen` 내부 build composition만 조정하고 동일한 `_searchController`, `_runSearch()`, `_clearSearch()`, `_searchWordsFuture`, `_isShowingDefaultStrongList`를 유지하는 후보를 검토할 수 있다.

### 10.2 state owner migration 없이 가능한가

가능하다. 단, 다음 조건을 모두 유지해야 한다.

- 일반 검색 query와 목록 상태 owner는 `HomeScreen`으로 유지한다.
- 검색 결과/default 목록은 좌측 surface에 유지한다.
- 상단 surface는 기존 검색 handler를 시각적으로 노출하는 presentation boundary로만 취급한다.
- 상단 search submit은 검색 후보 목록 전환만 수행한다.
- 우측 Explorer retarget은 기존과 같이 명시적 검색 후보 item tap 또는 Strong Rail item tap에서만 요청한다.
- `WordExplorerScreen` 내부 owner state와 history는 이전하지 않는다.
- `ExplorerWorkspace`와 `ExplorerWorkspaceState`를 production owner로 사용하지 않는다.

### 10.3 Phase 19-B 이후 후보

Phase 19-B 이후 구현 후보는 large-screen `HomeScreen` 내부의 owner-preserving visual composition 변경으로만 분리해야 한다. Phase 19-A는 해당 구현을 승인하지 않는다.

small-screen 상단 검색 위치 변경, command palette, keyboard command, recent search, persistence, ranking 개선, route 통합은 별도 설계와 승인 없이는 후보에 포함하지 않는다.

## 11. 좌측 control surface에 남겨야 할 역할 제안

일반 검색 입력이 장기적으로 상단 surface 후보가 되더라도 좌측 control surface에는 다음 역할을 남기는 것이 적절하다.

- Strong Rail 및 Strong anchor orientation
- `Strong/스트롱` rail-local jump 입력
- default Strong 목록
- 일반 검색 실행 후의 검색 후보 목록
- 명시적 후보 item 선택과 기존 retarget request 진입점
- current Explorer target feedback
- graph selection 기반 passive selected Strong feedback

좌측 surface는 graph/detail/selected/history owner, repository owner, write/create/edit owner가 되어서는 안 된다.

## 12. Phase 18 guardrail 위반 리스크

상단 검색/명령 surface 후보를 구현할 때 다음 위험이 있다.

1. 상단 search submit 자체가 `_showWordInLargeScreenExplorerPane(...)`를 호출해 명시적 후보 선택 없이 Explorer를 retarget하는 위험
2. 상단 surface가 `_largeScreenExplorerWordId`, graph center, selected word, detail target, history를 직접 소유하는 위험
3. 검색 결과/default 목록까지 상단 surface로 이동해 좌측 후보 목록 역할과 existing list state를 해체하는 위험
4. `Strong/스트롱` 입력을 일반 검색 입력 또는 `_runSearch(...)`와 다시 결합하는 위험
5. Strong local jump가 검색 결과/default 목록 전환 또는 Explorer retarget/remount를 유발하는 위험
6. graph selection passive sync가 상단 검색 상태나 Explorer retarget 경로로 연결되는 위험
7. large-screen 시각 재배치가 small-screen detail route 흐름 변경으로 확장되는 위험
8. `GlobalSearch` 또는 “명령 surface” 표현을 근거로 `ExplorerWorkspace` production mount나 `ExplorerWorkspaceState` source-of-truth 승격을 시도하는 위험
9. “명령 surface”를 keyboard command, command palette, recent search, persistence 구현 승인으로 확대하는 위험
10. AppBar의 DB 초기화/실행 취소 같은 write action을 검색/탐색 entry 역할과 결합하는 위험

## 13. 구현 전 문서로 고정할 금지선

- 상단 검색/명령 surface는 장기 UX 개념 및 presentation candidate다.
- Phase 19-A는 상단 surface 구현을 승인하지 않는다.
- 상단 search submit만으로 Explorer retarget을 수행하지 않는다.
- 일반 검색 결과/default 목록은 좌측 surface에 유지한다.
- 일반 검색 query, 목록 전환, 검색 후보 future owner는 `HomeScreen`에 유지한다.
- 검색 후보 item tap의 기존 explicit retarget request 의미를 유지한다.
- `Strong/스트롱` 입력은 좌측 Strong Rail local jump 전용으로 유지한다.
- graph selection passive sync는 Strong Rail passive feedback과 rail-local jump로만 유지한다.
- graph selection은 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- `WordExplorerScreen` owner state를 이동하지 않는다.
- `ExplorerWorkspace` production shell을 mount하지 않는다.
- `ExplorerWorkspaceState`를 production source-of-truth로 승격하지 않는다.
- 새 DB query, repository read/API, DTO/model, dependency를 추가하지 않는다.
- 좌측 또는 상단 surface에 create/edit/write entry를 추가하지 않는다.
- AppBar의 DB 초기화/실행 취소와 검색/명령 surface 역할을 결합하지 않는다.
- keyboard command, command palette, search ranking 개선, recent search, persistence를 구현하지 않는다.

## 14. 명령어 기반 검증

### 14.1 Phase 18 guardrail 묶음

실행 명령:

```text
flutter test test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart test/ui/explorer_workspace_phase17c_state_source_guardrail_test.dart test/ui/home_screen_phase18a_large_split_shell_test.dart test/ui/home_screen_phase18b_left_control_pane_direction_test.dart test/ui/home_screen_phase18c_left_control_surface_boundary_test.dart test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart test/ui/home_screen_phase18n_runtime_guardrail_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+74`
- `All tests passed!`

### 14.2 전체 analyze

실행 명령:

```text
flutter analyze --no-fatal-infos --no-fatal-warnings
```

실제 결과:

- exit code `1`
- `47 issues found`
- 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건 포함
- 기존 warning/info 포함
- Phase 19-A 범위에서는 수정하지 않음

## 15. UI 수동 테스트 체크리스트

Phase 19-A는 production UI를 변경하지 않으므로 신규 UI 차이를 검증하지 않는다. 아래 체크리스트는 현재 Phase 18 경계가 유지되는지 클라이언트가 확인하는 회귀 기준이다.

| 테스트 시나리오 | 테스트 목적 | 시작 화면 | 조작 순서 및 입력 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- | --- |
| large-screen 일반 검색 `H1` | 일반 검색 submit과 Explorer retarget 분리 확인 | Windows Desktop `HomeScreen`, 창 너비 900px 이상 | 일반 검색 field에 `H1` 입력 후 Enter 또는 검색 버튼 | 좌측 목록만 검색 후보 목록으로 전환되고 우측 Explorer target은 유지됨 | 입력만으로 우측 Explorer가 바뀌거나 목록이 전환되지 않음 | 후보 tap 전까지 Explorer target이 유지됨 |
| 일반 검색 후보 item tap | explicit item tap retarget 확인 | `H1` 검색 후보 목록 | `H1 / אָב / 아브 / 아버지` 후보 item 본문 클릭 | 우측 Explorer가 해당 후보로 retarget됨 | detail route가 별도로 열리거나 Explorer가 유지됨 | 선택한 후보가 우측 Explorer target이 됨 |
| `Strong/스트롱` 입력 `G26` | rail-local jump 역할 확인 | large-screen `HomeScreen` | `Strong/스트롱` field에 `G26` 입력 후 Enter | Strong Rail 위치/feedback만 변경되고 목록과 우측 Explorer는 유지됨 | 검색 결과/default 목록 전환, Explorer retarget/remount 발생 | Rail만 이동하고 기존 검색/Explorer 상태가 유지됨 |
| graph selection passive sync | graph selection의 passive rail sync 확인 | 우측 Explorer graph | `H1 / אָב / 아브 / 아버지` Explorer에서 `H2 / אַב / 아브 / 아버지` 또는 `H85 / אַבְרָהָם / 아브라함/아베라함` node 선택 | Rail이 해당 Strong 위치로 이동하고 secondary passive feedback만 표시됨 | primary target feedback 변경, Explorer remount/retarget 발생 | 우측 Explorer target 유지와 passive feedback을 함께 확인 |
| Strong 번호 없는 graph node 선택 | passive feedback clear 확인 | passive feedback이 표시된 Explorer graph | `אַבָּא / 아빠 / 아버지` node 선택 | 기존 passive selected feedback이 clear되고 Explorer target은 유지됨 | 이전 passive 표시가 남거나 Explorer target 변경 | passive 표시만 사라짐 |
| small-screen 검색/detail route | responsive 경계 확인 | 창 너비 900px 미만 `HomeScreen` | 일반 검색 field에 `H1` 검색 후 후보 item 본문 클릭 | embedded Explorer와 별도 Strong field 없이 detail route가 열림 | embedded Explorer 표시 또는 large-screen retarget 동작 | `WordDetailScreen` route 진입 확인 |

## 16. Phase 19-A 결론

현재 일반 검색 입력은 `HomeScreen` 좌측 control surface 상단에 mount되어 있다. 일반 검색 state와 검색 결과/default 목록 state는 `HomeScreen` private state가 소유하며, 우측 `WordExplorerScreen`은 graph/detail/selected/history owner로 유지된다.

일반 검색 입력을 장기적으로 상단 검색/명령 surface에 시각 재배치하는 후보는 owner migration 없이 검토할 수 있다. 단, 상단 surface는 기존 `HomeScreen` 검색 state를 노출하는 presentation candidate로 제한하고, 검색 결과/default 목록과 explicit 후보 선택 surface는 좌측에 유지해야 한다.

`Strong/스트롱` 입력과 Strong Rail은 좌측 orientation/local jump 역할로 유지한다. “명령 surface”는 장기 UX 개념일 뿐이며 keyboard command, command palette, recent search, persistence, write action 구현 승인이 아니다.

## 17. Phase 19-B 구현 반영 참고

Phase 19-A에서 평가한 owner-preserving presentation 후보는 Phase 19-B에서 최소 구현으로 반영되었다. 이 절은 Phase 19-A 감사 결론을 변경하지 않고 후속 구현 상태를 연결하는 `reference/context` 기록이다.

- large-screen 일반 검색 입력은 좌측 `homePane` 내부에서 좌우 split 전체 위의 `homeWorkspaceSearchSurface`로 시각 재배치되었다.
- 일반 검색 입력은 기존 `_searchController`, `_runSearch(...)`, `_clearSearch(...)`를 그대로 사용하며 검색 state owner는 계속 `HomeScreen`이다.
- `_searchWordsFuture`, `_isShowingDefaultStrongList`, default/search 목록은 좌측 control surface에 유지된다.
- 좌측 `homePane`에는 `Strong/스트롱` 입력, Strong Rail, 목록, current target feedback, passive selected Strong feedback이 유지된다.
- 상단 search submit 자체는 Explorer retarget을 수행하지 않는다.
- 검색 후보 item tap과 Strong Rail item tap의 기존 명시적 large-screen Explorer retarget 경로는 유지된다.
- `Strong/스트롱` rail-local jump와 graph selection passive sync 경로는 변경하지 않았다.
- small-screen 검색 입력과 검색 후보 item tap의 detail route 흐름은 변경하지 않았다.
- DB, repository read/API, DTO/model, dependency, `WordExplorerScreen` owner state, `ExplorerWorkspace` production mount, `ExplorerWorkspaceState` source-of-truth는 변경하지 않았다.

상세 active boundary와 구현 검증 기록은 `docs/ux/explorer_workspace_unification.md`의 `17.117 Phase 19-B 상단 검색 surface presentation 최소 구현`을 따른다.

## 18. Phase 19-C 종료 audit 참고

Phase 19-C는 Phase 19-A 감사 결론이나 당시 source 상태를 변경하지 않는 후속 `reference/context` 기록이다. Phase 19-B에서 반영된 owner-preserving 상단 검색 surface 구조를 기준으로 stale guardrail을 보정하고 Phase 19 종료 가능 여부를 감사했다.

- Phase 18-M guardrail의 넓은 source slice를 현재 mount 구조에 맞춘 surface별 검사로 보정했다.
- Phase 19-C 전용 source guard를 추가해 large-screen 상단 검색, 좌측 Strong/Rail/list, small-screen 기존 흐름, search submit 비-retarget, Strong rail-local jump, graph passive sync, `WordExplorerScreen` owner, workspace production 금지선을 고정했다.
- production code, DB, repository read/API, DTO/model, dependency, UX 기능은 변경하지 않았다.
- Phase 19-B 클라이언트 UI 수동 테스트 통과 상태와 Phase 19-C 명령어 기반 guardrail 통과 결과를 근거로 Phase 19는 종료 가능하다고 판단했다.

상세 active boundary와 종료 판단은 `docs/ux/explorer_workspace_unification.md`의 `17.118 Phase 19-C 상단 검색 surface guardrail hardening 및 종료 audit`을 따른다.
