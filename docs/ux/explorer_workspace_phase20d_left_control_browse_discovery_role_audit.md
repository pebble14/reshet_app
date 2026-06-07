# ExplorerWorkspace Phase 20-D 좌측 control surface browse/discovery 역할 분리 감사

> 문서 성격: `reference/context` 및 docs/audit 기록
>
> 감사 브랜치: `docs/explorer-workspace-phase20d-left-control-browse-discovery-role-audit`
>
> 기준 HEAD: `fb981e8847e2bfd788bb9eacb22932cd5fd28678`
>
> active boundary 요약은 `docs/ux/explorer_workspace_unification.md`의 Phase 20-D 항목을 따른다.

## 1. 목적

Phase 20-D는 Phase 20-C 이후 large-screen 좌측 control surface에 함께 남아 있는 query-bound 검색 결과 목록, default Strong 목록, Strong Rail의 역할을 실제 production source와 guardrail 기준으로 분리하는 docs/audit-only 단계다.

이번 감사는 좌측 목록을 제거하거나 이동하는 구현 단계가 아니다. production code, test code, DB/data/sql, dependency, route, UI를 변경하지 않고 다음 질문에 답한다.

1. large-screen 검색 결과의 장기 귀속 surface는 어디인가.
2. 좌측 query-bound 검색 결과 목록은 현재 어떤 전환 상태인가.
3. default Strong 목록과 Strong Rail은 같은 역할인가.
4. small-screen 검색 결과 흐름을 large-screen 역할 분리와 함께 변경해야 하는가.
5. Phase 20-E에서 검토할 수 있는 최소 구현 지점은 어디인가.

## 2. 감사 범위와 금지선

### 2.1 감사 범위

- `lib/ui/home_screen.dart`
- `test/ui/home_screen_phase20c_transient_search_result_surface_guardrail_test.dart`
- `test/ui/home_screen_phase20c_transient_search_result_surface_runtime_test.dart`
- `test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart`
- `test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart`
- `test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart`
- `test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart`
- `test/ui/explorer_workspace_phase17c_state_source_guardrail_test.dart`
- Phase 20-A~C UX 문서와 active boundary 기록

### 2.2 유지 금지선

- large-screen 좌측 목록 제거 구현 금지
- default Strong 목록 삭제·축소·이동 구현 금지
- small-screen `homePane → detail route` 변경 금지
- `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` owner 변경 금지
- `_runSearch(...)` 의미 변경 금지
- 검색 submit 기반 Explorer retarget 금지
- `Strong/스트롱` 입력과 일반 검색 결합 금지
- `Strong/스트롱` 입력 기반 transient search result panel open 금지
- graph passive sync 기반 `_largeScreenExplorerWordId` 변경 금지
- graph passive sync 기반 `_showWordInLargeScreenExplorerPane(...)` 호출 금지
- production `ExplorerWorkspace` mount 금지
- `ExplorerWorkspaceState` production source-of-truth 승격 금지

## 3. 실제 production source 구조

### 3.1 검색 state owner

`lib/ui/home_screen.dart:45-104` 기준으로 일반 검색 state와 read 실행 책임은 계속 `_HomeScreenState` private state에 있다.

| 책임 | 실제 owner/source |
| --- | --- |
| 일반 검색 입력 | `_searchController` |
| Strong rail-local 입력 | `_strongJumpController` |
| default Strong read | `_defaultStrongListFuture` |
| query-bound 검색 결과 read | `_searchWordsFuture` |
| default/search mode | `_isShowingDefaultStrongList` |
| transient panel 표시 여부 | `_isLargeScreenTransientSearchResultVisible` |
| large-screen Explorer target | `_largeScreenExplorerWordId` |

`_createSearchWordsFuture()`는 `_searchController.text`를 읽고 기존 repository 검색 API를 사용한다. Phase 20-D에서 owner, repository/API 의미, typed contract를 변경하지 않는다.

### 3.2 large-screen 상단 검색과 transient result surface

large-screen 일반 검색 입력은 `lib/ui/home_screen.dart:1205-1233`의 `homeSearchControlArea`에 있고, `homeWorkspaceSearchSurface`를 통해 좌우 split 전체 위에 mount된다.

transient result panel은 `lib/ui/home_screen.dart:1038-1137`의 `_buildLargeScreenTransientSearchResultSurface()`에서 렌더링된다.

- `_searchWordsFuture`를 직접 사용한다.
- loading, 오류, 검색 결과 없음, 후보 목록을 표시한다.
- 후보 item 본문 tap은 `_showWordInLargeScreenExplorerPane(wordId)`를 호출한 뒤 panel을 닫는다.
- panel 자체는 query 또는 result owner가 아니다.

large-screen workspace composition은 `lib/ui/home_screen.dart:1441-1472`에 있다.

```text
homeWorkspaceSearchSurface
→ 조건부 _buildLargeScreenTransientSearchResultSurface()
→ split row
   ├─ homePane
   └─ WordExplorerScreen
```

따라서 Phase 20-C 이후 large-screen query-bound search result의 상단 귀속 surface는 이미 production-visible하게 존재한다.

### 3.3 좌측 검색 결과/default Strong 목록

`lib/ui/home_screen.dart:1296-1395`의 `homeWordListSurface`는 `_isShowingDefaultStrongList` 값에 따라 두 presentation을 교체한다.

```text
_isShowingDefaultStrongList == true
→ _buildDefaultStrongListView()

_isShowingDefaultStrongList == false
→ FutureBuilder<List<HomeSearchResultDisplayItem>>(
     future: _searchWordsFuture,
   )
```

large-screen에서는 `lib/ui/home_screen.dart:1397-1409`의 `homeLeftControlListSurface`가 Strong Rail 옆에 같은 `homeWordListSurface`를 mount한다.

```text
homeLeftControlListSurface
├─ _buildStrongLevelOneRetargetRail()
└─ homeWordListSurface
```

query-bound mode일 때 상단 transient panel과 좌측 검색 결과 목록은 같은 `_searchWordsFuture`를 각각 렌더링한다. 이는 Phase 20-C 이후 남은 transition/legacy duplicate presentation이다.

### 3.4 small-screen과 공유되는 목록 구조

large-screen 좌측 목록과 small-screen 목록은 별도 builder가 아니다. 두 form factor는 같은 `homeWordListSurface`를 공유한다.

- large-screen: `homeLeftControlListSurface` 안에서 Strong Rail 옆에 mount
- small-screen: `homeLeftControlListSurface = homeWordListSurface`
- small-screen branch: `lib/ui/home_screen.dart:1437-1439`에서 `return homePane`

검색 결과 item 본문 tap도 같은 tile builder 안에서 width를 확인해 분기한다.

- large-screen: `_showWordInLargeScreenExplorerPane(wordId)`
- small-screen: `await _openWordDetail(wordId)`

현재 widget/builder는 공유하지만 UX 의미는 다르다. large-screen query-bound 결과는 상단 transient surface에 귀속될 수 있지만, small-screen 결과 목록은 `homePane → detail route`의 primary 검색 결과 surface다.

## 4. interaction 호출 경로 감사

### 4.1 검색 submit

```text
large/small 일반 검색 onSubmitted 또는 검색 버튼
→ _runSearch()
→ _isShowingDefaultStrongList = false
→ large-screen이면 _isLargeScreenTransientSearchResultVisible = true
→ _setVisibleWordListFuture()
→ _searchWordsFuture = _createSearchWordsFuture()
```

`_runSearch()`는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. 검색 submit과 Explorer retarget은 분리되어 있다.

### 4.2 clear

```text
초기화 버튼
→ _clearSearch()
→ _searchController.clear()
→ _isShowingDefaultStrongList = true
→ _isLargeScreenTransientSearchResultVisible = false
→ _setVisibleWordListFuture()
```

clear는 default Strong mode로 복귀하지만 Explorer target은 변경하지 않는다.

### 4.3 검색 후보 item tap

상단 transient 후보 item과 좌측/shared 검색 결과 item은 모두 사용자의 명시적 후보 선택으로 large-screen Explorer를 retarget할 수 있다.

- transient 후보: retarget 후 panel dismiss
- shared 목록 후보 large-screen: retarget
- shared 목록 후보 small-screen: detail route

submit과 후보 선택은 섞이지 않았지만, 같은 query-bound 결과가 large-screen에서 두 presentation에 중복 노출된다.

### 4.4 Strong 입력과 Strong Rail tap

`Strong/스트롱` 입력은 `_strongJumpController`와 `_handleStrongRailJumpChanged(...)`, `_handleStrongRailJumpSubmitted(...)`, `_runStrongRailJump(...)`, `_jumpToStrongInRail(...)` 경로를 사용한다.

이 경로는 일반 검색, 검색 결과/default mode 전환, transient panel lifecycle, Explorer retarget과 결합하지 않는다.

Strong Rail item tap은 별도 명시적 compact navigation action으로 `_showWordInLargeScreenExplorerPane(item.wordId)`를 호출한다. Strong 입력의 rail-local jump와 Strong Rail item tap의 Explorer retarget은 서로 다른 interaction이다.

### 4.5 graph passive sync

`_handleExplorerSelectedStrongWordChanged(...)`는 passive selected state를 갱신하고 `_jumpToStrongInRail(...)`만 호출한다.

이 경로는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. graph passive sync는 Explorer retarget이 아니다.

## 5. default Strong 목록과 Strong Rail 역할 분리

### 5.1 공유하는 데이터와 분리된 presentation

default Strong 목록과 Strong Rail은 `_defaultStrongListFuture`를 공유하지만 별도 builder와 controller를 사용한다.

| 구분 | Strong Rail | default Strong 목록 |
| --- | --- | --- |
| builder | `_buildStrongLevelOneRetargetRail()` | `_buildDefaultStrongListView()` |
| controller | `_strongRailScrollController` | `_listScrollController` |
| presentation | compact Strong 번호 item | 전체 목록형 단어 item |
| 주요 역할 | compact navigation/orientation | empty-query browse/discovery 후보 |
| item tap | large-screen Explorer retarget | large-screen retarget / small-screen detail route |
| 추가 action | target/passive feedback | 상세/그래프 standalone action |

같은 데이터를 사용한다는 사실만으로 역할이 중복된다고 결론 낼 수 없다. Strong Rail은 compact navigation이고, default Strong 목록은 더 많은 정보와 action을 제공하는 browse/discovery 후보로 구분한다.

### 5.2 default Strong 목록은 검색 결과 fallback이 아님

코드상 default Strong 목록은 검색 결과가 없을 때 fallback으로 호출되지 않는다.

- empty query submit 또는 clear가 `_isShowingDefaultStrongList = true`로 명시 전환한다.
- `_setVisibleWordListFuture()`는 default mode에서 `_searchWordsFuture = null`로 두고 `_defaultStrongListFuture`를 생성한다.
- query-bound 검색 결과가 비어 있으면 해당 검색 `FutureBuilder` 안에서 `검색 결과 없음`을 표시하며 default Strong 목록으로 자동 전환하지 않는다.

따라서 default Strong 목록은 search result fallback이 아니라 별도 empty-query browse/discovery surface 후보로 분리 가능한 구조다.

다만 `_buildDefaultStrongListView()`의 empty-state 문구도 현재 `검색 결과 없음`을 사용한다. 이 표현은 역할 의미를 흐릴 수 있지만 Phase 20-D에서는 문구를 변경하지 않는다.

## 6. Phase 20-C guardrail이 고정한 중복 상태

Phase 20-C source guardrail은 `keeps left duplicate lists and small-screen detail route` 검증에서 다음을 명시적으로 요구한다.

- `homeWordListSurface`가 `_isShowingDefaultStrongList` 분기를 유지할 것
- `_buildDefaultStrongListView()`를 유지할 것
- query-bound `FutureBuilder<List<HomeSearchResultDisplayItem>>`를 유지할 것
- large-screen 목록 item의 Explorer retarget을 유지할 것
- small-screen 목록 item의 detail route를 유지할 것

Phase 20-C runtime guardrail도 large-screen 검색 후 좌측 검색 후보가 남아 있음을 명시적으로 확인한다.

따라서 현재 중복은 우연한 잔여가 아니라 Phase 20-C 최소 구현의 점진 전환 guardrail이 허용하고 고정한 상태다. Phase 20-E에서 large-screen 좌측 query-bound duplicate presentation을 제거하려면 Phase 20-C 중복 유지 assertion을 새 active boundary에 맞게 재정의해야 한다.

## 7. Phase 20-D UX 계약

1. large-screen query-bound search result는 상단 transient result surface에 귀속한다.
2. large-screen 좌측 query-bound search result list는 Phase 20-C 이후 남은 transition/legacy duplicate presentation으로 분류한다.
3. default Strong 목록은 search result가 아니라 browse/discovery surface 후보로 분류한다.
4. Phase 20-D에서 default Strong 목록의 삭제, 축소, 이동, 대체를 확정하지 않는다.
5. Strong Rail은 compact navigation/orientation이고 default Strong 목록은 browse/discovery 후보로 구분한다.
6. large-screen 좌측 목록과 small-screen `homePane` 목록은 현재 같은 `homeWordListSurface`를 공유하지만 UX 의미는 다를 수 있다.
7. small-screen `homePane → detail route` 검색 결과 흐름을 유지한다.
8. 검색 state owner와 `_runSearch(...)` 의미를 유지한다.
9. 검색 submit은 Explorer retarget을 유발하지 않는다.
10. `Strong/스트롱` 입력, Strong Rail, graph passive sync 역할 경계를 유지한다.
11. production `ExplorerWorkspace` mount와 `ExplorerWorkspaceState` production source-of-truth 승격 금지를 유지한다.

## 8. Phase 20-D에서 확정하지 않는 항목

- default Strong 목록의 최종 위치
- default Strong 목록의 삭제, 축소, 이동, 대체
- default Strong browse/discovery surface의 exact presentation
- Strong Rail과 default Strong 목록의 장기 병합 또는 공존 여부
- 좌측 상세/그래프 standalone action의 large-screen 장기 역할
- small-screen 검색, browse, detail, graph navigation 재설계
- 검색 state owner 이동
- `_runSearch(...)` 의미 변경
- repository/API, DTO/model, DB/data/sql 변경
- production `ExplorerWorkspace` 전환

## 9. Phase 20-E 최소 구현 후보

Phase 20-E 최소 구현 후보는 `homeLeftControlListSurface` composition에서 large-screen query-bound 목록 presentation만 분리하거나 제거하는 범위로 제한하는 것이 적절하다.

현재 최소 지점은 `lib/ui/home_screen.dart:1397-1409`의 responsive composition이다.

```text
large-screen
├─ Strong Rail 유지
├─ default Strong mode이면 default Strong 목록 유지
└─ query-bound mode이면 좌측 duplicate result presentation 제외 후보

small-screen
└─ 기존 homeWordListSurface와 homePane → detail route 유지
```

Phase 20-E에서도 우선 변경하지 않는 항목:

- `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` owner와 의미
- `_buildLargeScreenTransientSearchResultSurface()`의 query-bound 결과 역할
- default Strong 목록
- Strong Rail과 `Strong/스트롱` 입력
- small-screen `homePane → detail route`
- 검색 submit 비-retarget
- graph passive sync 비-retarget
- `WordExplorerScreen` owner state
- production `ExplorerWorkspace` 및 `ExplorerWorkspaceState` 금지선

Phase 20-E 구현 시에는 Phase 20-C source/runtime guardrail의 좌측 duplicate 유지 assertion만 새 역할 계약에 맞게 좁혀 재정의하고, small-screen과 default Strong 유지 assertion은 계속 방어해야 한다.

## 10. 검증 방침

Phase 20-D는 docs/audit-only이므로 Codex는 UI 테스트를 수행했다고 보고하지 않는다. 명령어 기반 검증은 관련 source guardrail, owner/role separation guardrail, diff 범위, dependency 비변경, working tree 상태를 기준으로 수행한다.

전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`는 기존 `47 issues found`, exit code `1` 기술 부채와 Phase 20-D 문서 변경을 섞지 않기 위해 실행하지 않는다.

### 10.1 Phase 20-C 중복 상태와 small-screen 경계

```text
flutter test test/ui/home_screen_phase20c_transient_search_result_surface_guardrail_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+9`
- `All tests passed!`
- large-screen transient panel, 좌측 duplicate 검색 결과, small-screen detail route, 검색 owner와 production workspace 금지선 유지 확인

### 10.2 검색/Strong/passive sync/workspace owner 경계

```text
flutter test test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart test/ui/explorer_workspace_phase17c_state_source_guardrail_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+33`
- `All tests passed!`
- 상단 검색, 좌측 Strong/Rail/list, small-screen 흐름, submit 비-retarget, Strong/search 분리, graph passive sync 비-retarget, `ExplorerWorkspace` production mount 금지, `ExplorerWorkspaceState` production source-of-truth 승격 금지 확인

초기 sandbox 내부 실행은 출력 없이 timeout되었고 assertion 실패는 보고되지 않았다. 같은 source guardrail을 sandbox 밖에서 다시 실행해 위 통과 결과를 확인했다.
