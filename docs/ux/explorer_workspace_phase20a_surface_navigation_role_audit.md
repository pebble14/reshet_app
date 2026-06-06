# ExplorerWorkspace Phase 20-A Surface & Navigation Role Audit

> 문서 성격: reference/context 및 read-only UX/architecture audit 기록
>
> 기준 HEAD: `4b9624c72f9d8e2e2658915dfc6fedf10cea09af`
>
> 현재 active boundary 요약은 `docs/ux/explorer_workspace_unification.md`의 Phase 20-A 항목을 따른다.
>
> 이 문서는 production `ExplorerWorkspace` widget mount, `ExplorerWorkspaceState` source-of-truth 승격, route 변경 또는 UI 구현을 승인하지 않는다.

## 1. 감사 목적과 범위

Phase 20-A는 Phase 19 이후 large-screen workspace의 surface 역할과 graph/detail navigation 역할을 실제 production source와 기존 UX/architecture 문서를 기준으로 확인하는 read-only docs/audit 단계다.

이번 감사는 다음 질문을 다룬다.

1. large-screen 상단 일반 검색 surface와 좌측 control surface의 현재 책임이 충돌하는가?
2. 일반 검색 결과와 default Strong 목록을 좌측에 계속 표시하는 구조는 장기 역할에 적합한가?
3. large-screen 일반 검색 결과를 상단 검색에 딸린 일시적 result surface로 표현하는 후속 구현 후보는 적절한가?
4. 좌측 control surface를 Strong 기반 탐색 보조 surface로 좁힐 수 있는가?
5. graph/detail standalone route는 large-screen workspace pane 흐름과 어떤 관계인가?
6. small-screen 기존 route 흐름은 즉시 유지해야 하는가?

이번 단계는 production code, test/guardrail, DB/data/sql, dependency, route redirect, standalone route 제거, UI 변경을 수행하지 않는다.

## 2. 확인한 파일

### 2.1 production code 파일

- `lib/main.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/word_graph_screen.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/main_explorer_workspace_preview.dart`
- `lib/ui/explorer_workspace/explorer_workspace.dart`
- `lib/ui/explorer_workspace/explorer_workspace_contract.dart`

### 2.2 route/navigation 관련 파일

- `lib/main.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/word_graph_screen.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/main_explorer_workspace_preview.dart`

### 2.3 확인한 관련 문서

- `docs/ux/explorer_workspace_phase19a_top_search_command_surface_audit.md`
- `docs/ux/explorer_workspace_unification.md`
- `docs/ux/workspace_ux_architecture.md`
- `docs/ux/navigation_policy.md`
- `docs/ux/responsive_layout_policy.md`
- `docs/ux/search_policy.md`
- `docs/architecture/explorer_workspace_constitution.md`
- `docs/logs/CHANGELOG.md`

## 3. 현재 production mount 구조

production 앱 시작점은 `lib/main.dart`의 `MaterialApp(home: const HomeScreen())`이다.

large-screen 기준 production mount 구조는 다음과 같다.

```text
HomeScreen
└─ Scaffold.body
   └─ LayoutBuilder
      └─ large-screen Column
         ├─ homeWorkspaceSearchSurface
         │  └─ 일반 검색 입력
         └─ Row
            ├─ homePane
            │  ├─ Strong/스트롱 rail-local jump 입력
            │  └─ Strong Rail + default/search 목록
            └─ WordExplorerScreen
               ├─ WordGraphScreen
               └─ detail pane
```

small-screen에서는 `homePane`만 반환한다. 이 흐름에는 기존 일반 검색 입력과 default/search 목록이 있고, embedded `WordExplorerScreen`, 별도 `Strong/스트롱` 입력, Strong Rail은 없다.

## 4. large-screen surface 현재 역할

### 4.1 상단 일반 검색 surface

large-screen 일반 검색 입력은 `homeWorkspaceSearchSurface`에 mount된다.

현재 역할은 다음과 같다.

- `_searchController` 기반 일반 query 입력
- `_runSearch()` 기반 검색 실행
- `_clearSearch()` 기반 검색 초기화
- `_searchWordsFuture`, `_isShowingDefaultStrongList` 기반 좌측 목록 상태 전환 요청

검색 submit은 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. 따라서 상단 surface는 현재 explicit Explorer retarget owner가 아니다.

### 4.2 좌측 control surface

large-screen 좌측 `homePane`은 현재 다음 역할을 함께 가진다.

- `Strong/스트롱` rail-local jump 입력
- Strong Rail
- Strong anchor orientation
- current Explorer target feedback
- graph selection 기반 passive selected Strong feedback
- default Strong 전체 목록
- 일반 검색 실행 후 검색 결과 목록
- default/search 목록 item의 explicit Explorer retarget entry
- 목록 item의 상세/그래프 standalone route entry

좌측 surface는 graph center, selected word, detail target, history owner가 아니다. 해당 production owner는 계속 `WordExplorerScreen`이다.

## 5. 좌측 목록 역할 충돌 판단

현재 좌측 surface에는 서로 다른 성격의 책임이 공존한다.

| 책임 | 성격 |
| --- | --- |
| Strong Rail, Strong jump, current target, passive selected feedback | persistent navigation/orientation 보조 |
| 일반 검색 결과 목록 | query에 종속된 global discovery/result entry |
| default Strong 목록 | empty-query browse/discovery와 navigation 후보가 혼합된 목록 |
| 상세/그래프 아이콘 | standalone route entry |

Phase 20-A 판단은 역할 충돌이 존재한다는 것이다.

상단 일반 검색 입력은 global semantic entry 역할을 갖지만 결과가 좌측 navigation 보조 surface에 표시된다. 이 때문에 검색 입력과 결과가 시각적으로 분리되고, 좌측 surface는 Strong navigation 보조와 query-specific discovery 결과 표시를 동시에 담당한다.

이 판단은 현재 구조가 즉시 잘못되었거나 제거되어야 한다는 뜻이 아니다. Phase 19 금지선에 따라 검색 결과/default 목록은 현재 좌측에 유지한다. 다만 장기 UX 역할 기준에서는 좌측 surface를 navigation-oriented하게 좁히기 위한 후속 설계가 필요하다.

## 6. large-screen 검색 결과 surface 후보 판단

large-screen 일반 검색 결과를 상단 검색에 딸린 transient result surface로 표현하는 방향은 후속 구현 후보로 검토할 가치가 있다.

이 후보의 UX 근거는 다음과 같다.

- query와 결과를 같은 search interaction context로 읽을 수 있다.
- query-specific result가 좌측 persistent navigation/orientation surface를 계속 점유하지 않게 할 수 있다.
- 결과 item은 semantic entry 역할을 유지하면서도 search result lifecycle을 더 명확히 표현할 수 있다.
- 결과 선택 이후에는 기존처럼 명시적 action을 통해 Explorer target으로 진입할 수 있다.

그러나 Phase 20-A에서는 다음 사항을 확정하거나 구현하지 않는다.

- transient result surface의 exact layout
- overlay, popover, panel, drawer 등 표현 방식
- 결과 surface의 open/close lifecycle
- 검색 submit 이후 focus/keyboard 동작
- 결과 선택 후 닫힘 여부
- 검색 결과 state owner 이동
- Explorer retarget 동작 변경

후속 구현 후보가 검토되더라도 상단 search submit만으로 Explorer를 retarget해서는 안 된다. 명시적 결과 선택 이전에는 현재 Explorer target과 `WordExplorerScreen` owner state가 유지되어야 한다.

## 7. default Strong 목록 역할 판단

default Strong 목록은 현재 empty-query 상태에서 좌측에 표시되고, large-screen item tap은 Explorer retarget을 요청한다. 동시에 동일한 Strong data는 얇은 Strong Rail에서도 사용된다.

Phase 20-A 판단은 default Strong 전체 목록을 Strong Rail과 동일한 persistent navigation으로 해석하기 어렵다는 것이다.

- Strong Rail은 지속적인 orientation과 known anchor 접근을 제공하는 navigation spine 역할에 가깝다.
- default Strong 전체 목록은 많은 항목을 읽고 탐색하는 browse/discovery 성격이 더 강하다.
- 두 surface가 동일 데이터를 사용하더라도 UX 역할은 같지 않다.

따라서 default Strong 목록이 large-screen에 계속 필요하다면 `browse/discovery surface` 또는 명시적으로 열리는 Strong browse surface로 재정의하는 장기 전환 후보가 적절하다.

Phase 20-A에서는 default Strong 목록의 제거, 이동, 축소를 확정하지 않는다. small-screen에서는 Strong Rail이 없고 기존 home flow가 default Strong 목록에 의존하므로 즉시 유지해야 한다.

## 8. graph/detail standalone route 및 entrypoint 감사

### 8.1 `HomeScreen` entrypoint

`lib/ui/home_screen.dart`에서 다음 standalone entrypoint가 확인된다.

- default Strong item의 상세 아이콘 → `WordDetailScreen`
- default Strong item의 그래프 아이콘 → `WordGraphScreen`
- 검색 결과 item의 상세 아이콘 → `WordDetailScreen`
- 검색 결과 item의 그래프 아이콘 → `WordGraphScreen`
- small-screen default/search item 본문 tap → `WordDetailScreen`
- `_openDefaultStrongWordExplorer(...)` → `WordExplorerScreen` route entry

`_openDefaultStrongWordExplorer(...)`는 현재 unused compatibility/guardrail entry로 남아 있다.

large-screen에서 목록 item 본문 tap은 embedded `WordExplorerScreen`을 retarget하지만, 동일 item의 상세/그래프 아이콘은 standalone route를 연다. 동일 surface 안에서 pane 중심 흐름과 standalone route 흐름이 함께 노출되는 상태다.

### 8.2 `WordExplorerScreen` entrypoint

`lib/ui/word_explorer_screen.dart`에서 graph와 detail pane은 같은 `WordExplorerScreen` 내부에 mount된다. 이 화면은 graph center, selected word, detail target, navigation history의 production owner다.

선택된 단어의 detail panel에서 별도 상세 열기 action을 사용하면 `WordDetailScreen` route를 연다. 따라서 embedded detail pane이 존재하더라도 full detail standalone route가 별도 reading/edit/delete flow로 유지된다.

### 8.3 `WordDetailScreen` entrypoint

`lib/ui/word_detail_screen.dart`의 그래프 action은 `WordGraphScreen` standalone route를 연다.

### 8.4 `WordGraphScreen` entrypoint

`lib/ui/word_graph_screen.dart`는 callback이 제공된 embedded 사용과 callback이 없는 standalone 사용을 모두 지원한다.

- embedded 사용에서는 selection/center change callback을 부모 `WordExplorerScreen`에 전달한다.
- callback이 없는 standalone 사용에서는 동일 node 재선택 시 새 `WordGraphScreen` route를 push할 수 있다.
- standalone create flow에서 새 단어를 중심으로 하는 `WordGraphScreen` route replacement가 존재한다.

### 8.5 판단

large-screen에서 graph/detail standalone route를 줄이는 방향은 workspace pane 중심 continuity와 일치하는 장기 전환 후보다. 특히 `HomeScreen` large-screen 목록에서 embedded Explorer가 이미 존재하는데 상세/그래프 아이콘이 별도 route를 여는 흐름은 workspace fragmentation 위험이 있다.

그러나 standalone route의 전역 제거는 아직 부적절하다.

- small-screen/mobile flow가 detail route를 현재 primary presentation으로 사용한다.
- `WordDetailScreen`의 full detail reading/edit/delete 역할은 embedded detail pane과 완전히 같지 않다.
- `WordGraphScreen` standalone mode는 callback이 없는 route 환경에서 자체 탐색과 create 후 replacement를 처리한다.
- route history와 `WordExplorerScreen` internal history는 현재 별도이며 통합 설계가 없다.
- repository reread와 복귀 후 refresh 책임이 각 화면에 남아 있다.

따라서 제거 확정이 아니라 form factor별 entrypoint 축소와 redirect 가능성을 별도 설계해야 한다.

## 9. large-screen standalone route 축소/redirect 후보 순서

후속 구현 후보의 안전한 순서는 다음과 같다.

1. route/entrypoint inventory를 form factor와 action intent별로 고정한다.
2. large-screen에서 `detail reading`, `graph context`, `Explorer retarget`이 어떤 pane action으로 대응되는지 별도 설계한다.
3. `HomeScreen` large-screen default/search 목록의 상세/그래프 아이콘부터 pane 중심 action 또는 workspace-aware redirect 후보로 검토한다.
4. `WordExplorerScreen` 내부 full detail route는 edit/delete/expanded reading 필요성을 분리해 유지 또는 대체 후보를 판단한다.
5. `WordDetailScreen → WordGraphScreen`과 standalone `WordGraphScreen` 내부 route 탐색 의존성을 별도 감사한다.
6. small-screen/mobile route 흐름을 유지한 상태에서 large-screen 전용 redirect 또는 비활성화 후보를 검토한다.
7. route history, Explorer internal history, repository reread, 복귀 refresh 경계가 설계된 뒤에만 standalone route 제거 가능성을 재검토한다.

이 순서는 구현 승인이나 route 변경 확정이 아니다. 각 항목은 별도 설계, 승인, 구현, 검증이 필요한 후속 후보다.

## 10. small-screen/mobile flow 판단

small-screen `homePane → detail route` 흐름은 즉시 유지해야 한다.

- small-screen에는 embedded `WordExplorerScreen`, Strong Rail, 별도 Strong jump surface가 없다.
- 한 번에 하나의 primary semantic surface를 제공하는 현재 route 흐름은 mobile viewer/flow UX와 호환된다.
- detail route를 제거하면 small-screen의 primary reading surface가 사라질 수 있다.
- large-screen pane 중심 전환을 그대로 small-screen에 적용하면 desktop workspace의 축소판이 될 위험이 있다.

장기적으로 small-screen 흐름을 `mobile Explorer presentation`으로 재정의할 수 있는지는 audit 대상으로 남긴다. 이 후보는 기존 route를 즉시 제거하는 방식이 아니라 search, detail, graph, return path 사이의 semantic continuity를 mobile flow에 맞게 정의하는 별도 설계가 선행되어야 한다.

## 11. Phase 19 금지선 확인

Phase 20-A에서 다음 Phase 19 금지선을 유지한다.

- large-screen 일반 검색 입력은 workspace 상단 surface에 유지한다.
- large-screen 좌측 control surface에는 일반 검색 입력을 추가하지 않는다.
- small-screen 일반 검색 입력은 기존 `homePane` 흐름을 유지한다.
- 검색 submit만으로 Explorer를 retarget하지 않는다.
- 검색 결과/default 목록은 현재 좌측 control surface에 유지한다.
- `Strong/스트롱` 입력은 좌측 rail-local jump 전용으로 유지한다.
- `Strong/스트롱` 입력을 `_runSearch(...)` 또는 검색 결과/default 목록 전환과 결합하지 않는다.
- graph selection passive sync는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- `WordExplorerScreen`은 graph/detail/selected/history production owner로 유지한다.
- production `ExplorerWorkspace` widget mount를 수행하지 않는다.
- `ExplorerWorkspaceState`를 production source-of-truth로 승격하지 않는다.

Phase 20-A 문서의 `ExplorerWorkspace` 표현은 UX/architecture 개념 또는 기존 preview-only boundary를 설명하는 용도로만 사용한다.

## 12. 구현하지 않은 항목

- production code 수정
- test/guardrail 추가 또는 수정
- DB/data/sql 변경
- dependency 변경
- `pubspec.yaml`, `pubspec.lock` 변경
- search result surface 이동 구현
- default Strong 목록 이동, 제거, 축소
- route redirect 또는 route 비활성화
- graph/detail standalone route 제거
- small-screen/mobile presentation 변경
- `ExplorerWorkspace` production mount
- `ExplorerWorkspaceState` source-of-truth 승격
- 기존 전체 analyze `47 issues found` 수정

## 13. 향후 클라이언트 UI 확인 기준

Phase 20-A는 read-only docs/audit 작업이므로 Codex는 UI 수동 테스트를 수행하지 않는다. 후속 구현 phase가 승인되는 경우 다음 기준을 클라이언트 UI 체크리스트 후보로 사용할 수 있다.

| 테스트 목적 | 시작 화면 | 조작 순서와 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- |
| large-screen search result lifecycle | Windows Desktop `HomeScreen`, 900px 이상 | 일반 검색에 `H1` 입력 후 submit | 후보 구현 범위에 맞는 search result surface가 표시되고 submit만으로 Explorer target은 바뀌지 않음 | submit 즉시 Explorer retarget 또는 좌측 navigation feedback 손실 | 명시적 후보 선택 전 Explorer target 유지 |
| 좌측 navigation 보조 역할 | large-screen `HomeScreen` | `Strong/스트롱`에 `G26` 입력 | Strong Rail 위치/feedback만 변경 | 검색 실행, 결과 surface 전환, Explorer retarget | rail-local 변화만 발생 |
| large-screen route 축소 후보 | large-screen 검색/default result | `H1 / אָב / 아브 / 아버지`의 상세/그래프 action 사용 | 승인된 후속 설계에 따른 pane 중심 또는 workspace-aware 동작 | 별도 route가 의도치 않게 열리거나 context가 손실됨 | workspace context와 return path 유지 |
| small-screen 기존 flow 유지 | 창 너비 900px 미만 `HomeScreen` | 일반 검색에 `H1` 입력 후 후보 본문 tap | 기존 detail route 진입 | embedded desktop Explorer 표시 또는 primary detail flow 손실 | detail route와 뒤로가기 흐름 유지 |

## 14. 명령어 기반 검증 계획

Phase 20-A 문서 변경 후 다음 명령어로 범위를 확인한다.

```text
git status --short --branch
git diff --name-only
git diff --check
git diff --name-only -- lib test data sql pubspec.yaml pubspec.lock
```

기대 결과는 변경 파일이 다음 세 문서뿐이고 금지 경로 변경이 없는 것이다.

```text
docs/ux/explorer_workspace_phase20a_surface_navigation_role_audit.md
docs/ux/explorer_workspace_unification.md
docs/logs/CHANGELOG.md
```

Phase 20-A는 docs/audit-only 작업이므로 Flutter test와 전체 analyze를 재실행하지 않는다. 기존 전체 analyze의 `47 issues found`, exit code `1`은 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함한 선행 기술 부채이며 Phase 20-A에서 새로 발생한 문제가 아니다.

## 15. 결론

large-screen 상단 일반 검색 surface와 좌측 control surface의 입력 역할은 Phase 19에서 분리되었다. 그러나 검색 결과와 default Strong 전체 목록이 좌측에 유지되면서 좌측 surface는 persistent navigation/orientation 보조와 global discovery/result 표시를 함께 담당한다.

large-screen 검색 결과를 상단 검색에 딸린 transient result surface로 표현하는 것은 역할 충돌을 줄일 수 있는 후속 구현 후보다. default Strong 전체 목록은 Strong Rail과 동일한 persistent navigation으로 보기보다 browse/discovery surface로 재정의하는 장기 전환 후보가 적절하다.

large-screen graph/detail standalone route는 pane 중심 continuity와 충돌하는 entrypoint부터 단계적으로 줄이는 방향을 후속 후보로 검토할 수 있다. 다만 small-screen/mobile flow, full detail 역할, standalone graph 탐색, route/internal history와 repository refresh 경계 때문에 전역 제거는 아직 부적절하다.

small-screen `homePane → detail route`는 즉시 유지한다. 장기적으로 mobile Explorer presentation으로 재정의 가능한지는 별도 audit와 설계 대상으로 남긴다.
