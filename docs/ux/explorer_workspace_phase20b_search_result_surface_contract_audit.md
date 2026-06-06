# ExplorerWorkspace Phase 20-B Search Result Surface Contract Audit

> 문서 성격: reference/context 및 read-only UX/architecture contract audit 기록
>
> 기준 HEAD: `fcf338ee432b580e9df9579293904c9b53abbd92`
>
> 현재 active boundary 요약은 `docs/ux/explorer_workspace_unification.md`의 Phase 20-B 항목을 따른다.
>
> 이 문서는 large-screen transient search result surface 구현, production `ExplorerWorkspace` widget mount, `ExplorerWorkspaceState` source-of-truth 승격 또는 small-screen 흐름 변경을 승인하지 않는다.

## 1. 감사 목적과 범위

Phase 20-B는 Phase 20-A에서 확인한 large-screen 검색 결과/default Strong 목록의 좌측 surface 역할 충돌을 검색 결과 surface 계약 관점에서 구체화하는 read-only docs/audit 단계다.

이번 감사는 다음 질문을 다룬다.

1. 현재 검색 결과 목록은 어떤 state, surface, interaction 경계를 사용하는가?
2. 검색 결과와 default Strong 목록이 같은 좌측 목록 surface를 공유할 때 어떤 역할 충돌이 발생하는가?
3. large-screen 검색 결과를 상단 검색에 딸린 query-bound transient result surface로 이동하기 전에 어떤 계약을 지켜야 하는가?
4. default Strong 목록을 search result가 아닌 browse/discovery surface 후보로 재정의할 수 있는가?
5. 검색 submit과 검색 후보 item tap의 Explorer retarget 경계를 어떻게 분리해야 하는가?
6. small-screen 기존 `homePane → detail route` 흐름을 어떻게 유지해야 하는가?

이번 단계는 production code, test/guardrail, DB/data/sql, dependency, `pubspec.yaml`, `pubspec.lock`, UI 또는 route를 변경하지 않는다.

## 2. 확인한 파일

### 2.1 production code

- `lib/ui/home_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/explorer_workspace/explorer_workspace.dart`
- `lib/ui/explorer_workspace/explorer_workspace_contract.dart`

### 2.2 기존 guardrail

- `test/ui/home_screen_phase19b_top_search_surface_presentation_test.dart`
- `test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart`
- `test/ui/home_screen_phase18n_runtime_guardrail_test.dart`

### 2.3 UX/architecture 문서

- `docs/ux/explorer_workspace_phase19a_top_search_command_surface_audit.md`
- `docs/ux/explorer_workspace_phase20a_surface_navigation_role_audit.md`
- `docs/ux/explorer_workspace_unification.md`
- `docs/ux/workspace_ux_architecture.md`
- `docs/ux/search_policy.md`
- `docs/ux/navigation_policy.md`
- `docs/ux/interaction_policy.md`
- `docs/ux/responsive_layout_policy.md`
- `docs/architecture/explorer_workspace_constitution.md`
- `docs/logs/CHANGELOG.md`

## 3. 현재 production 검색 결과 흐름

### 3.1 검색 state owner

일반 검색 state와 목록 전환 책임은 계속 `HomeScreen` private state가 소유한다.

| 책임 | 현재 owner/source |
| --- | --- |
| 일반 검색 입력 | `_searchController` |
| 검색 실행 | `_runSearch()` |
| 검색 초기화 | `_clearSearch()` |
| 검색 결과 future | `_searchWordsFuture` |
| default/search 목록 전환 | `_isShowingDefaultStrongList` |
| visible 목록 future 선택 | `_setVisibleWordListFuture()` |
| large-screen Explorer target | `_largeScreenExplorerWordId` |
| large-screen Explorer retarget request | `_showWordInLargeScreenExplorerPane(...)` |

`_runSearch()`는 query가 비어 있으면 default Strong 목록 상태로 전환하고, query가 있으면 검색 결과 목록 상태로 전환한다. 이 경로는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

### 3.2 large-screen surface 경로

현재 large-screen 구조는 다음과 같다.

```text
HomeScreen
└─ large-screen workspace
   ├─ homeWorkspaceSearchSurface
   │  └─ 일반 검색 입력
   └─ split row
      ├─ homePane
      │  ├─ Strong/스트롱 rail-local jump 입력
      │  └─ homeLeftControlListSurface
      │     ├─ Strong Rail
      │     └─ homeWordListSurface
      │        ├─ default Strong 목록
      │        └─ 검색 결과 목록
      └─ WordExplorerScreen
```

검색 입력은 workspace 상단에 있지만 검색 결과는 default Strong 목록과 같은 `homeWordListSurface`를 공유하며 좌측 `homePane`에 표시된다.

### 3.3 small-screen surface 경로

small-screen은 `homePane`만 반환한다.

```text
HomeScreen
└─ homePane
   ├─ 일반 검색 입력
   └─ homeWordListSurface
      ├─ default Strong 목록
      └─ 검색 결과 목록
```

small-screen에는 별도 `Strong/스트롱` 입력, Strong Rail, embedded `WordExplorerScreen`이 없다. 검색 후보 item 본문 tap은 기존 `WordDetailScreen` route를 연다.

## 4. 현재 유지되는 계약

Phase 20-B에서 다음 현재 계약을 유지한다.

### 4.1 검색 입력과 결과 갱신

- large-screen 일반 검색 입력은 workspace 상단 `homeWorkspaceSearchSurface`에 유지한다.
- large-screen 좌측 control surface에는 일반 검색 입력을 추가하지 않는다.
- small-screen 일반 검색 입력은 기존 `homePane` 흐름에 유지한다.
- 검색 submit은 query에 맞는 결과 state 갱신과 결과 표시 요청까지만 수행한다.
- 검색 submit만으로 Explorer를 retarget하지 않는다.

### 4.2 명시적 선택과 Explorer retarget

- large-screen 검색 후보 item 본문 tap은 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로를 유지한다.
- large-screen Strong Rail item tap은 기존 명시적 Explorer retarget 경로를 유지한다.
- Explorer retarget은 이와 같은 사용자의 명시적 선택 동작에서만 발생해야 한다.
- 검색 submit, `Strong/스트롱` 입력, graph selection passive sync는 Explorer retarget 요청이 아니다.

### 4.3 Strong Rail과 passive sync

- `Strong/스트롱` 입력은 좌측 rail-local jump 전용이다.
- `Strong/스트롱` 입력은 `_runSearch(...)`와 결합하지 않는다.
- `Strong/스트롱` 입력은 검색 결과/default 목록 전환을 유발하지 않는다.
- graph selection passive sync는 `_largeScreenExplorerWordId`를 변경하지 않는다.
- graph selection passive sync는 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

### 4.4 owner와 responsive 경계

- `WordExplorerScreen`은 graph center, selected word, detail target, history의 production owner로 유지한다.
- `ExplorerWorkspace` production shell mount 금지 상태를 유지한다.
- `ExplorerWorkspaceState` production source-of-truth 승격 금지 상태를 유지한다.
- small-screen 검색 후보 item tap은 기존 detail route 흐름을 유지한다.

## 5. 현재 구조의 역할 충돌

현재 `homeWordListSurface`는 query 유무에 따라 서로 다른 역할의 목록을 교체 표시한다.

| 목록 | 현재 trigger | 현재 surface | UX 역할 |
| --- | --- | --- | --- |
| 검색 결과 목록 | non-empty query submit | 좌측 `homeWordListSurface` | query-bound semantic candidate/result entry |
| default Strong 목록 | empty query 또는 검색 초기화 | 좌측 `homeWordListSurface` | empty-query browse/discovery 후보 |

두 목록은 같은 widget 위치와 scroll surface를 공유하지만 장기 UX 역할은 같지 않다.

- 검색 결과는 특정 query와 결과 lifecycle에 종속된다.
- default Strong 목록은 query가 없는 상태에서 corpus를 훑고 항목을 발견하는 browse/discovery 성격이 강하다.
- 좌측 surface는 이미 Strong Rail, rail-local jump, current target feedback, passive selected feedback을 통해 persistent navigation/orientation 보조 역할을 맡고 있다.
- query-specific 검색 결과까지 좌측에 표시되면서 상단 검색 입력과 결과가 시각적으로 분리되고, 좌측 surface가 navigation 보조와 global result 표시를 함께 담당한다.
- default Strong 목록을 검색 결과와 동일한 lifecycle로 해석하면 empty query와 no result의 의미가 섞일 수 있다.

Phase 20-B 판단은 현재 공유 구조가 즉시 제거되어야 한다는 것이 아니다. 현재 production 구조는 유지하되, 후속 large-screen 전환에서는 검색 결과와 default Strong 목록의 역할을 분리해야 한다.

## 6. large-screen 검색 결과 surface 장기 계약

large-screen 검색 결과 surface는 `query-bound transient result surface` 후보로 정의한다.

이 정의는 Phase 20-B에서 실제 surface 이동을 구현한다는 뜻이 아니다. 후속 구현을 검토할 때 지켜야 할 계약을 의미한다.

### 6.1 query-bound 계약

- 검색 결과 surface는 현재 일반 검색 query와 결과에 종속된다.
- query가 없는 default 상태를 search result로 표현하지 않는다.
- 검색 결과 loading, result, no-result 상태는 같은 query context 안에서 해석되어야 한다.
- stale query 결과가 현재 query의 결과처럼 표시되어서는 안 된다.

### 6.2 transient 계약

- 검색 결과 surface는 persistent navigation spine 또는 Explorer owner가 아니다.
- 검색 결과 surface는 현재 workspace context를 대체하지 않고 검색 후보 선택을 지원한다.
- surface가 표시되어도 명시적 후보 선택 전까지 기존 Explorer target과 `WordExplorerScreen` owner state를 유지한다.
- exact overlay, popover, anchored panel, inline expansion 등 표현 방식과 dismiss lifecycle은 Phase 20-B에서 확정하지 않는다.

### 6.3 submit과 선택 계약

- 검색 submit은 result surface 갱신 또는 표시까지만 허용한다.
- 검색 submit만으로 `_largeScreenExplorerWordId`를 변경하지 않는다.
- 검색 submit만으로 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- large-screen 검색 후보 item 본문 tap은 기존 Explorer retarget 경로를 유지해야 한다.
- 후보 item 선택 후 transient surface의 닫힘 여부와 focus 복귀 방식은 후속 설계 대상이다.

### 6.4 owner 계약

- 후속 presentation 변경이 있더라도 검색 query와 결과 state owner를 이동하는 결정은 별도 설계와 승인이 필요하다.
- transient result surface를 근거로 `ExplorerWorkspaceState`를 production source-of-truth로 승격하지 않는다.
- transient result surface가 graph center, selected word, detail target, history를 소유하지 않는다.
- 새 DB query, repository read/API, DTO/model 또는 dependency 도입은 Phase 20-B 계약에 포함되지 않는다.

## 7. default Strong 목록 장기 역할 계약

default Strong 목록은 search result가 아니라 `browse/discovery surface` 후보로 정의한다.

- default Strong 목록은 empty-query 상태에서 corpus를 훑고 semantic object를 발견하는 역할 후보이다.
- default Strong 목록과 Strong Rail이 같은 Strong data를 사용해도 UX 역할은 같지 않다.
- Strong Rail은 persistent navigation/orientation 보조이고, default Strong 목록은 browse/discovery 후보이다.
- default Strong 목록 item의 large-screen 명시적 tap은 현재 Explorer retarget 경로를 유지한다.
- small-screen에서는 기존 home browse/default 목록 역할을 유지한다.

Phase 20-B에서는 default Strong 목록의 삭제, 축소, 이동 또는 대체를 결론 내리지 않는다. large-screen에서 browse/discovery surface를 어떤 방식으로 제공할지는 Phase 20-C 이후 별도 설계와 승인 대상으로 남긴다.

## 8. Phase 20-B에서 고정할 금지선

1. production code를 수정하지 않는다.
2. test code를 수정하지 않는다.
3. DB/data/sql을 수정하지 않는다.
4. dependency, `pubspec.yaml`, `pubspec.lock`을 수정하지 않는다.
5. large-screen transient search result surface를 구현하지 않는다.
6. 검색 결과/default 목록은 현재 좌측 control surface에 유지한다.
7. default Strong 목록을 삭제하거나 축소하는 결정을 내리지 않는다.
8. large-screen 일반 검색 입력을 좌측 control surface로 되돌리지 않는다.
9. 검색 submit만으로 Explorer를 retarget하지 않는다.
10. `Strong/스트롱` 입력을 `_runSearch(...)` 또는 검색 결과/default 목록 전환과 결합하지 않는다.
11. graph selection passive sync를 Explorer retarget 경로로 확장하지 않는다.
12. `WordExplorerScreen`의 graph/detail/selected/history owner 책임을 이동하지 않는다.
13. production `ExplorerWorkspace` widget을 mount하지 않는다.
14. `ExplorerWorkspaceState`를 production source-of-truth로 승격하지 않는다.
15. small-screen `homePane → detail route` 검색 결과 흐름을 변경하지 않는다.
16. UI 수동 테스트를 수행했다고 보고하지 않는다.

## 9. Phase 20-C 이후 구현 후보

다음 항목은 Phase 20-B의 구현 결과가 아니라 별도 설계, 승인, 구현, 검증이 필요한 후속 후보다.

1. large-screen 상단 일반 검색에 딸린 query-bound transient result surface의 최소 presentation 구현
2. 현재 `homeWordListSurface` 공유 구조에서 large-screen 검색 결과 presentation만 분리하는 responsive composition 후보
3. query 변경, submit, clear, loading, no-result, stale result, dismiss를 포함한 transient result lifecycle 설계
4. 명시적 검색 후보 item tap 이후 기존 Explorer retarget 경로 유지와 surface dismiss/focus 복귀 계약 구현
5. 검색 submit 비-retarget, Strong rail-local jump, graph passive sync, owner 금지선을 고정하는 source/runtime guardrail 보강
6. default Strong 목록을 large-screen browse/discovery surface로 재정의하는 별도 UX 설계
7. default Strong 목록의 유지 위치와 진입 방식 감사
8. small-screen 기존 `homePane → detail route`를 유지하는 responsive regression guard

후속 구현은 search state owner 이동, repository/API 변경, default Strong 목록 삭제/축소, small-screen presentation 변경을 자동으로 승인하지 않는다.

## 10. Phase 20-C 이후 클라이언트 UI 체크리스트 후보

Phase 20-B는 UI를 변경하지 않으므로 Codex는 UI 수동 테스트를 수행하지 않는다. 후속 구현 phase가 승인되면 클라이언트가 다음 기준을 확인한다.

| 테스트 목적 | 시작 화면 | 조작 순서와 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- |
| large-screen query-bound result 표시 | Windows Desktop `HomeScreen`, 창 너비 900px 이상 | 상단 일반 검색에 `H1` 입력 후 Enter 또는 검색 버튼 | 승인된 transient result surface에 `H1` 후보가 표시되고 기존 Explorer target은 유지됨 | 결과가 좌측 navigation 역할과 섞이거나 submit 즉시 Explorer가 바뀜 | 후보 item 선택 전 Explorer target 유지 |
| large-screen 명시적 후보 선택 retarget | `H1` 검색 결과가 표시된 large-screen 화면 | `H1 / אָב / 아브 / 아버지` 후보 item 본문 tap | 기존 Explorer retarget 경로로 우측 Explorer가 선택 후보를 표시 | 후보 tap이 무시되거나 submit 시점에 이미 retarget됨 | 명시적 item tap 시에만 Explorer target 변경 |
| query clear와 default browse 구분 | large-screen 검색 결과 표시 상태 | 상단 일반 검색 초기화 버튼 사용 | search result lifecycle이 종료되고 승인된 default browse/discovery presentation이 표시됨 | default Strong 목록이 search result처럼 남거나 삭제됨 | search result와 default browse 역할이 구분됨 |
| Strong rail-local jump 경계 | large-screen `HomeScreen` | `Strong/스트롱` 입력에 `G26` 입력 후 Enter | Strong Rail 위치/feedback만 변경 | 검색 결과 surface 전환, Explorer retarget/remount | rail-local 변화만 발생 |
| graph passive sync 경계 | large-screen 우측 Explorer graph | `H1 / אָב / 아브 / 아버지` Explorer에서 `H2 / אַב / 아브 / 아버지` node 선택 | Strong Rail passive feedback과 rail-local 위치만 변경 | Explorer target remount/retarget 또는 검색 결과 lifecycle 변경 | passive sync만 발생 |
| small-screen 기존 흐름 유지 | Windows Desktop `HomeScreen`, 창 너비 900px 미만 | 일반 검색에 `H1` 입력 후 `H1 / אָב / 아브 / 아버지` 후보 item 본문 tap | 기존 `homePane` 검색 결과 흐름에서 `WordDetailScreen` route 진입 | large-screen transient surface 또는 embedded Explorer 표시 | detail route와 뒤로가기 흐름 유지 |

## 11. 명령어 기반 검증 계획

Phase 20-B 문서 변경 후 다음 명령어로 기존 경계와 변경 범위를 확인한다.

```text
flutter test test/ui/home_screen_phase19b_top_search_surface_presentation_test.dart test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart test/ui/home_screen_phase18n_runtime_guardrail_test.dart --reporter expanded
git diff --check
git diff --name-only
git diff --name-only -- lib test data sql pubspec.yaml pubspec.lock
git status --short --branch
```

기대 결과는 관련 guardrail이 통과하고 변경 파일이 다음 세 문서뿐이며 금지 경로 변경이 없는 것이다.

```text
docs/logs/CHANGELOG.md
docs/ux/explorer_workspace_phase20b_search_result_surface_contract_audit.md
docs/ux/explorer_workspace_unification.md
```

전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`는 실행하지 않는다. 기존 `47 issues found`, exit code `1`은 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함한 선행 기술 부채이며 Phase 20-B audit와 섞지 않는다.

## 12. 결론

현재 large-screen 일반 검색 입력은 workspace 상단에 있지만 검색 결과와 default Strong 목록은 같은 좌측 `homeWordListSurface`를 공유한다. 이 구조는 query-bound 검색 결과와 empty-query browse/discovery 후보를 같은 lifecycle과 위치로 표현하고, 좌측 surface에 persistent navigation/orientation 보조와 global result 표시 책임을 함께 부여한다.

Phase 20-B는 large-screen 검색 결과 surface를 query-bound transient result surface 후보로 정의하고, default Strong 목록을 search result가 아닌 browse/discovery surface 후보로 정의한다. 검색 submit은 result 갱신 또는 표시까지만 수행하며 Explorer retarget은 large-screen 검색 후보 item tap과 같은 사용자의 명시적 선택 동작에서만 허용한다.

Phase 20-B에서는 실제 surface 이동, default Strong 목록 삭제/축소, state owner 이동, small-screen 흐름 변경을 구현하지 않는다. small-screen `homePane → detail route`는 유지하며, large-screen 최소 구현과 responsive guardrail은 Phase 20-C 이후 별도 승인 대상으로 넘긴다.
