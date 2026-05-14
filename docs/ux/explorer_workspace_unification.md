# Explorer 단일 Workspace 통합 Architecture Phase 2-A

## 1. 문서 성격

- 문서 분류: `reference/context`
- 목적: 현재 구현의 route, screen, state ownership, navigation 흐름 조사 기록을 보존하고, Explorer 단일 workspace 전환을 위한 Phase 2-A architecture 정의를 정리한다.
- authority 경계:
  - 이 문서는 기존 UX authority 문서를 변경하지 않는다.
  - `docs/ux/workspace_ux_architecture.md`, `docs/ux/navigation_policy.md`, `docs/ux/responsive_layout_policy.md`, `docs/ux/search_policy.md`, `docs/ux/interaction_policy.md`의 정책을 대체하지 않는다.
  - 현재 구현 snapshot, migration 후보, Phase 2-A workspace architecture vocabulary를 기록하는 참고 문서로 사용한다.
  - 이 문서는 Flutter widget 구조, route 구현, repository contract, DB/API contract를 변경하지 않는다.

Phase 2-A에서는 구현하지 않는다.

- route 제거 없음
- screen 병합 없음
- graph production path 변경 없음
- DB/API 변경 없음
- raw carrier 확장 없음

## 2. 조사 기준

### 2.1 기준 커밋과 브랜치 상태

- Phase 2-A 문서화 기준 HEAD: `e136e585b82da909b382d00f969ffd5e3d131765`
- 조사 시점 branch state: `main = origin/main`
- 조사 시작 시 working tree: clean

### 2.2 조사 범위

- route / screen 구조
- 화면별 state ownership
- navigation 흐름
- edit/create 후 post-save 후속 상태
- graph bootstrap과 production path 유지 여부
- 단일 workspace 통합 시 위험 지점

## 3. 현재 구조 요약

### 3.1 앱 진입 구조

- `lib/main.dart`
  - `ReshetApp`의 `home`은 `HomeScreen`이다.
- `lib/ui/home_screen.dart`
  - 현재 앱의 진입 허브다.
  - 기본 strong list, search result list, detail route, explorer route, graph route로 분기한다.

### 3.2 현재 screen 구성

| 역할 | 화면 | 현재 책임 |
| --- | --- | --- |
| 진입 허브 | `HomeScreen` | strong list, 검색, 화면 분기 |
| explorer split view | `WordExplorerScreen` | graph와 detail panel 동시 구성, center/selection/history coordination |
| graph only | `WordGraphScreen` | 그래프 렌더링, 중심 단어, 선택 노드, visible graph data, viewport |
| detail mode | `WordDetailScreen` | 단일 단어 상세 읽기, 편집, 삭제, graph 진입 |
| edit mode | `WordEditScreen` | 단어 수정 저장 후 결과 반환 |

### 3.3 현재 route 진입 방식

| 시작 위치 | 대상 | 실제 진입 |
| --- | --- | --- |
| Home 기본 strong list / 검색 결과 | Detail | `Navigator.push(... WordDetailScreen(...))` |
| Home 기본 strong list / 검색 결과 | Explorer | `Navigator.push(... WordExplorerScreen(initialWordId: ...))` |
| Home 기본 strong list / 검색 결과 | Graph | `Navigator.push(... WordGraphScreen(centerWordId: ...))` |
| Detail | Graph | `Navigator.push(... WordGraphScreen(centerWordId: _wordId))` |
| Explorer detail panel | Detail | `Navigator.push(... WordDetailScreen(...))` |
| Graph standalone node 재탭 | Graph recenter | `Navigator.push(... WordGraphScreen(centerWordId: word.id))` |
| Graph create 후 relation 미생성 | Graph recenter | callback이 없으면 `pushReplacement(... WordGraphScreen(centerWordId: ...))` |

### 3.4 navigation payload 구조

| 흐름 | payload |
| --- | --- |
| Home -> Detail | `wordId`, `WordDetailLikeDisplayItem initialDisplayItem` |
| Home -> Explorer | `initialWordId` |
| Home -> Graph | `centerWordId` |
| Detail -> Graph | `centerWordId = _wordId` |
| Explorer -> Detail | `selectedWordId`, `WordDetailLikeDisplayItem selectedDisplayItem` |
| Graph -> parent callback | `selectedWordId`, `centerWordId` |
| Edit close result | `WordEditSaveResult(wordId)` |
| Graph create post-save | `GraphCreatePostSavePayload(wordId, representativeSpelling)` |

## 4. 상태 ownership 조사

### 4.1 상태별 현재 owner

| 상태 | 현재 owner | 실제 보유 방식 |
| --- | --- | --- |
| selected word | `WordExplorerScreen`, `WordGraphScreen` | Explorer는 `_selectedWordId`, `_selectedWordDisplayItem`; Graph는 `_selectedWordId` |
| graph center | `WordExplorerScreen`, `WordGraphScreen` | Explorer는 `_centerWordId`; Graph는 `_centerWordId`를 center authority로 사용 |
| detail target | `WordExplorerScreen`, `WordDetailScreen` | Explorer detail panel은 `_selectedWordDisplayItem`; Detail route는 `_wordId`, `_displayItem` |
| search query | `HomeScreen` | `_searchController`, `_isShowingDefaultStrongList`, `_searchWordsFuture` |
| strong list selection / jump context | `HomeScreen` | `_currentDefaultStrongItems`, `_listScrollController`, strong jump debounce |
| graph viewport | `WordGraphScreen` | `TransformationController`, `_currentScale`, viewport interaction state |
| visible graph data | `WordGraphScreen` + `WordGraphDataCache` | screen local graph state + base/expansion cache |
| edit/create 후 post-save navigation state | caller별 분산 | Detail, Explorer, Graph가 각각 후속 refresh/route/callback 처리 |

### 4.2 selected word ownership

#### `WordExplorerScreen`

- graph panel에 `selectedWordId`를 전달한다.
- graph의 `onSelectWordId`를 받아 `_selectWord(...)`로 detail panel을 갱신한다.
- 선택 단어의 detail display item은 `getWordDetailLikeDisplayItemByIdForSplitView(...)`로 다시 읽는다.
- history payload에는 `centerWordId`, `selectedWordId`가 함께 저장된다.

#### `WordGraphScreen`

- standalone 모드와 embedded 모드 모두 `_selectedWordId`를 내부에 보유한다.
- embedded 모드에서는 parent callback이 있으면 selection을 parent에 전달한다.
- standalone 모드에서는 같은 노드를 다시 누를 때 그래프 route recenter가 발생할 수 있다.

### 4.3 graph center ownership

#### `WordExplorerScreen`

- 초기 `initialWordId`를 `_centerWordId`로 보유한다.
- graph의 `onChangeCenterWordId` callback을 받으면 Explorer가 center를 갱신한다.
- history 복원도 Explorer의 center 기준으로 동작한다.

#### `WordGraphScreen`

- `centerWordId`를 normalized id로 받아 `_centerWordId` authority를 가진다.
- 자체 center bootstrap과 graph visible data 로딩을 수행한다.
- Explorer embedded 모드에서도 Graph 내부 center load는 그대로 수행된다.

### 4.4 detail target ownership

#### Explorer detail panel

- `_selectedWordDisplayItem`을 detail panel의 읽기 대상처럼 사용한다.
- `WordInfoPanel`로 rendering한다.
- detail route 진입 시 현재 display item을 payload로 넘긴다.

#### Detail route

- `WordDetailScreen`은 `wordId`와 `initialDisplayItem`을 받는다.
- 진입 직후 `getWordDetailLikeDisplayItemByIdForDetailScreen(...)`로 reread한다.
- 따라서 Explorer detail panel과 detail route는 같은 단어를 다른 read context로 다시 읽는다.

### 4.5 search query와 strong list ownership

- 현재 `GlobalSearch`에 가까운 상태는 `HomeScreen` 안에만 있다.
- `HomeScreen`이 검색어, default strong list, strong jump scroll state를 독점한다.
- Explorer route에 진입하면 Home의 search/list state는 route 뒤쪽 상태로 남고, Explorer 내부 workspace 상태와 통합되어 있지 않다.

### 4.6 graph viewport / visible graph data ownership

#### viewport

- `WordGraphScreen`
  - `TransformationController`
  - `_currentScale`
  - `_isViewportInteracting`
  - `_lastViewportInteractionAt`

#### visible graph data

- `WordGraphScreen`
  - `_graphViewData`
  - `_baseGraphData`
  - `_expansionDataBySourceId`
  - `_expandedDepthOneWordIds`
  - `_fullyRevealedExpansionSourceIds`
- `WordGraphDataCache`
  - center 기준 base graph cache
  - center/source 기준 expansion cache

## 5. navigation 흐름 조사

### 5.1 Explorer -> Detail

1. Explorer detail panel에서 `상세 화면에서 열기` 실행
2. `WordExplorerScreen._openSelectedWordDetail()`
3. `WordDetailScreen(wordId, initialDisplayItem)` push
4. Detail route는 자체 reread 수행
5. 복귀 후 Explorer는 선택 단어를 `_refreshSelectedWord(...)`로 다시 읽고 graph 갱신 여부를 판단

### 5.2 Explorer -> Graph

- Explorer는 route 이동 없이 `WordGraphScreen`을 직접 child로 보유한다.
- 현재 Explorer 내부에서 graph panel은 이미 workspace panel처럼 동작한다.
- graph center 변화는 route가 아니라 callback 기반 parent state update로 처리된다.

### 5.3 Detail -> Graph

1. Detail 화면의 `그래프 보기`
2. `wordExistsForGraphNavigation(_wordId)` existence check
3. `WordGraphScreen(centerWordId: _wordId)` push

### 5.4 Graph -> Detail

- standalone `WordGraphScreen`에는 detail route 진입이 없다.
- embedded graph에서는 node selection이 `WordExplorerScreen`의 detail panel 갱신으로 이어진다.
- 따라서 현재 “Graph -> Detail” 의미는 두 갈래다.
  - standalone graph: detail 진입 없음
  - Explorer embedded graph: detail panel update

### 5.5 Add Word 후 이동

#### Graph create flow

1. 그래프 화면에서 신규 단어 create 시작
2. 생성 직후 `WordEditScreen.fromSeed(...)`로 보정 편집 진입
3. 저장 성공 시 `WordEditSaveResult`
4. repository에서 `GraphCreatePostSavePayload` 조회
5. 이후 분기
   - relation 생성 선택:
     - relation 생성 후 graph reload
     - 새 단어를 `_selectedWordId`로 두고 parent selection callback 수행 가능
   - relation 미생성:
     - callback이 있으면 center change dispatch
     - callback이 없으면 standalone graph를 새 center 기준으로 `pushReplacement`

### 5.6 Edit Word 후 이동

#### Detail edit

1. `WordDetailScreen._openEdit()`
2. `WordEditScreen.fromSeed(...)`
3. 저장 성공 시 `WordEditSaveResult`
4. Detail 화면이 자체 reread 수행

#### Explorer edit

1. `WordExplorerScreen._openEditSelectedWord()`
2. `WordEditScreen.fromSeed(...)`
3. 저장 성공 시 selected word reread
4. center word와 동일하면 center seed도 동기화
5. display 변경이 있으면 graph revision 증가

### 5.7 Graph node click 후 이동 또는 detail 갱신

#### 첫 클릭

- selected node가 아니면:
  - `_selectedWordId` 갱신
  - `onSelectWordId` callback이 있으면 Explorer detail panel 갱신
  - depth-two expansion도 병행될 수 있음

#### 같은 노드 재클릭

- parent center callback이 있으면:
  - `onChangeCenterWordId`로 Explorer center 갱신
- selection callback만 있으면:
  - selection만 다시 통지
- callback이 없으면:
  - standalone graph가 새 `WordGraphScreen(centerWordId: word.id)` route를 push

## 6. 현재 graph production path 유지 여부

현재 active graph production path는 유지되고 있다.

```text
WordGraphScreen
-> getVisibleGraphDataForGraph
-> GraphVisibleWord / GraphWordLabelDisplayItem / WordRelationEdgeInfo
-> WordGraphDataCache
-> GraphBuilder.buildMergedVisibleGraphData
```

구현 기준 확인:

- `WordGraphScreen._loadConnectedWords()`
  - `getVisibleGraphDataForGraph(...)`
  - `WordGraphDataCache.putBaseGraph(...)`
- `WordGraphScreen._expandDepthTwoForSelection(...)`
  - `getVisibleGraphDataForGraph(word.id)`
  - `WordGraphDataCache.putExpansion(...)`
- `WordGraphScreen._buildGraphData()`
  - `GraphBuilder.buildMergedVisibleGraphData(...)`

Phase 2-A의 문서 초안은 이 production path를 변경하지 않는다.

## 7. 중복 또는 충돌 가능성

### 7.1 동일 selection의 다중 ownership

- `WordExplorerScreen`과 `WordGraphScreen`이 모두 selected word를 보유한다.
- embedded mode에서는 callback으로 coherence를 맞추지만, owner가 분리되어 있다.
- 향후 단일 workspace로 이동할 때 selection source of truth를 어디에 둘지 명확히 정리해야 한다.

### 7.2 graph center와 detail target 분리

- Explorer에서는 center와 selected detail target이 분리될 수 있다.
- 이는 관계 탐색 UX에 필요한 구조지만, workspace 전체 기준으로는
  - `graphCenter`
  - `selectedWord`
  - `detailTarget`
  의 의미가 겹치지 않도록 정의가 필요하다.

### 7.3 bootstrap graph center 흐름 중복

- Explorer bootstrap:
  - `getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(...)`
  - split view detail read
- Graph bootstrap:
  - `getWordMapByIdForGraphCenterSingleWord(...)`
  - `getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(...)`
- center 진입 의도는 같지만, screen별 bootstrap 책임은 분산되어 있다.

### 7.4 route 이동으로 동일 데이터를 다시 읽는 흐름

- Explorer detail panel -> Detail route:
  - 기존 selected display item을 넘긴 뒤 detail route가 다시 reread
- Home -> Detail:
  - route 진입 전에 detail display item을 조회하고, Detail route가 다시 reread
- Detail -> Graph:
  - existence check 후 graph screen이 center bootstrap과 graph data를 별도로 읽음

단일 workspace 전환 시 route transition이 줄어들면 이런 reread의 일부는 구조적으로 재검토 대상이 된다. Phase 2-A에서는 검토만 기록한다.

### 7.5 standalone graph와 explorer embedded graph의 의미 차이

- 같은 `WordGraphScreen`이
  - 독립 route screen
  - Explorer panel
  두 역할을 모두 수행한다.
- node 재클릭 의미도 caller callback 유무에 따라 달라진다.
- 통합 workspace에서는 이 동작을 panel state transition으로 재정의할 필요가 있다.

### 7.6 raw carrier 또는 raw map 재도입 위험

다음 경계는 현재 transition/hybrid 상태이므로 위험 지점으로만 기록한다.

- `WordEditScreen(word: Map)` legacy compatibility constructor
- `WordGraphScreen`의 center bootstrap 내부 raw word read
- `WordGraphScreen`의 compatibility callback
  - `onSelectWord`
  - `onChangeCenterWord`
- repository 내부 일부 `Map<String, dynamic>` 기반 compatibility/helper path

통합 workspace 설계가 새 public boundary를 만들 때 이 경계를 다시 확장하면 raw carrier 재도입 위험이 있다. Phase 2-A에서는 확장하지 않고 위험으로만 기록한다.

## 8. ExplorerWorkspace 상태 ownership

### 8.1 목표 composition

```text
ExplorerWorkspace
├─ StrongRail
├─ GlobalSearch
├─ GraphPanel
├─ DetailPane
└─ AddWordFixedAction
```

`ExplorerWorkspace`는 route나 screen 병합 구현이 아니라, 장기적으로 workspace-level semantic state를 소유할 단일 coordination boundary를 의미한다.

이 문서에서 `StrongRail`은 기존 authority 문서의 `Strong Rail` 역할을 Explorer workspace composition 안에서 부르는 패널명이다. 명칭은 구현 class 도입을 뜻하지 않는다.

### 8.2 semantic state ownership

`ExplorerWorkspace`가 semantic state의 owner다. Panel은 받은 state를 표시하고 사용자 event를 workspace action으로 전달한다.

| 상태 | owner | 의미 | 변경 원칙 |
| --- | --- | --- | --- |
| `selectedWordId` | `ExplorerWorkspace` | 사용자가 현재 선택한 semantic object | selection action에서만 변경 |
| `graphCenterWordId` | `ExplorerWorkspace` | graph relation context의 anchor | 명시적 center action에서만 변경 |
| `detailTargetWordId` | `ExplorerWorkspace` | `DetailPane`이 읽는 대상 | detail target action에서만 변경 |
| `layoutPreset` | `ExplorerWorkspace` | workspace panel emphasis 상태 | layout action 또는 route alias action에서만 변경 |
| `origin` | `ExplorerWorkspace` history snapshot | transition의 semantic 진입 출처 | snapshot 생성 시 기록 |

`selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 서로 다른 의미를 가진다. 세 값이 동일할 수는 있지만, 동일성을 전제로 병합하지 않는다.

### 8.3 graph center 변경 제한

`graphCenterWordId`는 명시적 center action에서만 변경한다.

다음 event는 center 변경이 아니다.

- graph node hover
- graph node 단순 selection
- detail pane reading target 변경
- layout preset 변경
- hidden panel 전환
- 검색어 입력

다음 event는 center action으로 정의될 수 있다.

- graph node에 대한 명시적 center 요청
- Detail context를 graph 중심으로 여는 요청
- workspace snapshot restore
- 신규 단어 생성 후 명시적으로 graph center를 새 단어로 전환하는 요청

이 제한은 graph 탐색 중 `selectedWordId`와 `detailTargetWordId`가 바뀌어도 graph anchor가 우발적으로 이동하지 않도록 하기 위한 것이다.

## 9. Panel orchestration

Panel은 semantic state를 직접 소유하지 않는다. Panel은 표시와 event emit을 담당하며, 모든 semantic transition은 `ExplorerWorkspace` action으로 귀결된다.

| Panel | 역할 | 받는 state | emit하는 event | 소유하지 않는 것 |
| --- | --- | --- | --- | --- |
| `StrongRail` | Strong 기반 semantic anchor 접근과 workspace orientation 제공 | `selectedWordId`, `graphCenterWordId`, `layoutPreset` | strong anchor 선택, workspace entry 요청 | detail data, graph data, selected/detail/center 직접 변경 |
| `GlobalSearch` | corpus 진입을 위한 global search entry 제공 | 현재 workspace context, 필요 시 query/result 표시 상태 | search result 선택, result를 detail 또는 graph context로 여는 요청 | graph traversal, detail reading, center 직접 변경 |
| `GraphPanel` | relation graph surface 표시와 graph interaction event 전달 | `graphCenterWordId`, `selectedWordId`, `layoutPreset` | graph node 선택, graph center 요청, graph 관련 add 요청 | workspace semantic state, route stack, detail target |
| `DetailPane` | `detailTargetWordId`의 읽기 surface 제공 | `detailTargetWordId`, `selectedWordId`, `layoutPreset` | detail target 관련 graph 요청, edit 요청, linked word 선택 요청 | graph center, search state, route authority |
| `AddWordFixedAction` | exploration 중 생성 흐름에 진입하는 persistent action 제공 | `selectedWordId`, `graphCenterWordId`, `detailTargetWordId` | add word 시작, 생성 결과를 workspace action으로 전달 | 저장소 쓰기 contract, graph production path, center 직접 변경 |

Panel 내부에 필요한 transient UI state는 허용될 수 있다. 단, transient UI state는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`의 owner가 될 수 없다.

## 10. layoutPreset 정책

`layoutPreset`은 route가 아니라 workspace 안의 presentation state다. PC split-view를 기준 canonical layout으로 두고, 각 preset은 같은 semantic state를 서로 다른 강조로 표현한다.

| preset | 의미 | PC split-view 기준 배치 |
| --- | --- | --- |
| `balanced` | graph와 detail을 함께 보는 기본 workspace | StrongRail은 persistent navigation spine으로 유지하고, GraphPanel과 DetailPane을 동시에 읽을 수 있는 균형 배치로 둔다. |
| `graphFocused` | graph 탐색과 relation context 확인을 우선 | GraphPanel을 주 surface로 넓게 두고, DetailPane은 context 유지가 가능한 보조 reading surface로 둔다. |
| `detailFocused` | detail reading과 편집 전후 확인을 우선 | DetailPane을 주 surface로 넓게 두고, GraphPanel은 현재 relation context를 잃지 않는 보조 surface로 둔다. |

`layoutPreset` 변경은 semantic object 변경을 뜻하지 않는다. `balanced`, `graphFocused`, `detailFocused` 사이를 이동해도 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 action이 명시하지 않는 한 유지된다.

## 11. Navigation semantic 재정의

### 11.1 route 이동에서 workspace state transition으로

장기 목표에서 navigation은 route 이동이 아니라 workspace state transition으로 정의한다.

| 현재 흐름 | workspace semantic 해석 |
| --- | --- |
| Home 또는 Search result -> Detail | `detailTargetWordId` 설정 + `detailFocused` |
| Home 또는 Search result -> Explorer | entry word를 `selectedWordId`와 `detailTargetWordId`로 설정하고, graph 진입 의도가 명시된 경우에만 `graphCenterWordId`를 설정 |
| Home 또는 Search result -> Graph | entry word를 명시적 center action으로 `graphCenterWordId`에 설정 + `graphFocused` |
| Explorer -> Detail | 현재 selection 또는 detail target 유지 + `detailFocused` |
| Explorer -> Graph | 현재 graph center 유지 또는 명시적 center action + `graphFocused` |
| Detail -> Graph | `detailTargetWordId`를 명시적 center action으로 `graphCenterWordId`에 반영 + `graphFocused` |
| Graph node selection | `selectedWordId`와 필요 시 `detailTargetWordId` 변경, `graphCenterWordId`는 유지 |
| Graph node center 요청 | `graphCenterWordId` 변경 |
| Add Word 후 이동 | 생성 결과를 workspace action으로 반영하되 center 변경은 명시적 center action에 한정 |
| Edit Word 후 이동 | 기존 semantic state를 유지하고 display/data refresh만 수행 |

### 11.2 route alias 방향

Graph route와 Detail route는 장기적으로 별도 semantic destination이 아니라 workspace preset alias로 재정의한다.

| 기존 route 의미 | 장기 alias 의미 |
| --- | --- |
| Graph route | `ExplorerWorkspace(layoutPreset: graphFocused)` |
| Detail route | `ExplorerWorkspace(layoutPreset: detailFocused)` |
| Explorer route | `ExplorerWorkspace(layoutPreset: balanced)` 또는 이전 workspace snapshot restore |

이 alias 정의는 즉시 route 제거를 뜻하지 않는다. 기존 route는 compatibility layer로 유지하면서 내부 semantic을 workspace state transition으로 먼저 수렴한다.

## 12. Route collapse 전략

Route 제거는 마지막 단계다. route를 먼저 제거하면 active graph production path, detail reread 흐름, edit/create 후속 이동의 의미가 동시에 흔들릴 수 있다.

Collapse 순서는 다음과 같다.

1. semantic collapse
2. implementation collapse
3. route collapse

### 12.1 semantic collapse

기존 route 이동의 의미를 `ExplorerWorkspace` state transition으로 문서화하고 typed contract로 고정한다. 이 단계에서는 route, screen, graph production path를 변경하지 않는다.

### 12.2 implementation collapse

기존 route가 내부적으로 같은 workspace state와 panel orchestration을 사용하도록 점진적으로 연결한다. Graph/Detail route는 compatibility layer로 남는다.

### 12.3 route collapse

compatibility layer가 더 이상 behavior 차이를 만들지 않는 것이 확인된 뒤 route 제거를 검토한다. route collapse는 Phase 2-A의 범위가 아니다.

## 13. Responsive composition

PC split-view를 canonical layout으로 둔다. 이 기준에서 `StrongRail`, `GlobalSearch`, `GraphPanel`, `DetailPane`, `AddWordFixedAction`은 하나의 `ExplorerWorkspace` 안에서 조율된다.

좁은 화면에서는 composition만 바뀐다. semantic state는 유지된다.

- `DetailPane`이 숨겨져도 `detailTargetWordId`는 제거되지 않는다.
- `GraphPanel`이 축소되거나 다른 surface로 전환되어도 `graphCenterWordId`는 제거되지 않는다.
- `StrongRail`이 compact 표현으로 바뀌어도 semantic navigation spine 역할은 유지된다.
- `GlobalSearch`가 overlay 또는 transient entry로 표현되어도 workspace context와 분리되지 않는다.

Hidden panel은 상태 제거를 의미하지 않는다. 이는 `responsive_layout_policy.md`의 원칙인 "surface가 transient하더라도 semantic context가 transient해져서는 안 된다"와 같은 방향이다.

## 14. Workspace history

Workspace history는 route history가 아니라 workspace snapshot history로 정의한다.

Snapshot 저장 대상은 다음과 같다.

| field | 의미 |
| --- | --- |
| `selectedWordId` | 사용자가 선택한 semantic object |
| `graphCenterWordId` | graph relation context anchor |
| `detailTargetWordId` | detail reading target |
| `layoutPreset` | workspace presentation emphasis |
| `origin` | snapshot을 만든 semantic entry source |

`origin`은 route 이름이 아니라 semantic 출처를 기록한다. 예시는 다음과 같다.

- `strongRail`
- `globalSearch`
- `graphNode`
- `detailPane`
- `addWordFlow`
- `editReturn`
- `snapshotRestore`

History restore는 panel이 직접 수행하지 않는다. `ExplorerWorkspace`의 restore action이 snapshot을 적용하고, 각 panel은 적용된 state를 표시한다.

## 15. 상태 충돌 방지 전략

모든 semantic transition은 `ExplorerWorkspace` action으로만 발생한다. Panel은 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`를 직접 소유하거나 변경하지 않는다.

### 15.1 action별 변경 가능 state 범위

| action | 변경 가능 state | 변경 금지 state | 비고 |
| --- | --- | --- | --- |
| `selectSemanticWord(wordId, origin)` | `selectedWordId`, `detailTargetWordId`, `origin` | `graphCenterWordId` | 단순 선택은 graph center 변경이 아니다. |
| `setDetailTarget(wordId, origin)` | `detailTargetWordId`, `origin` | `graphCenterWordId` | detail reading target만 바꾼다. |
| `centerGraphOnWord(wordId, origin)` | `graphCenterWordId`, `origin` | 없음 | 명시적 center action이다. |
| `setLayoutPreset(layoutPreset, origin)` | `layoutPreset`, `origin` | `selectedWordId`, `graphCenterWordId`, `detailTargetWordId` | presentation 변경만 수행한다. |
| `openDetailFocus(wordId, origin)` | `detailTargetWordId`, `layoutPreset`, `origin` | `graphCenterWordId` | Detail route alias의 semantic action이다. |
| `openGraphFocus(wordId, origin)` | `graphCenterWordId`, `layoutPreset`, `origin` | 없음 | Graph route alias의 semantic action이며 명시적 center action이다. |
| `restoreWorkspaceSnapshot(snapshot)` | `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin` | 없음 | snapshot history 복원 전용이다. |
| `refreshAfterEdit(wordId, origin)` | `origin` 및 display/data refresh trigger | `selectedWordId`, `graphCenterWordId`, `detailTargetWordId` | edit 결과는 기존 semantic context를 보존한다. |
| `completeAddWord(wordId, origin)` | `selectedWordId`, `detailTargetWordId`, `origin` | `graphCenterWordId` | 생성 후 center 변경이 필요하면 별도 center action을 사용한다. |

### 15.2 충돌 방지 원칙

- graph center 변경은 `centerGraphOnWord`, `openGraphFocus`, `restoreWorkspaceSnapshot` 같은 명시적 center action에만 허용한다.
- selection과 detail target 동기화는 action contract에 명시된 경우에만 수행한다.
- layout 변경은 semantic object 변경과 분리한다.
- panel-local callback은 곧바로 상태를 바꾸지 않고 workspace action 요청으로만 전달한다.
- compatibility route는 내부적으로 workspace action을 호출하는 adapter로 제한한다.

## 16. Embedded graph vs standalone graph

Embedded `GraphPanel`이 장기 canonical graph experience다. 이는 graph가 application shell이 아니라 workspace 안의 contextual semantic surface라는 authority 문서의 방향과 일치한다.

Standalone graph는 장기적으로 다음 중 하나로 재정의한다.

- compatibility layer
- `graphFocused` preset alias

현재 active graph production path는 마지막까지 보호한다.

```text
WordGraphScreen
-> getVisibleGraphDataForGraph
-> GraphVisibleWord / GraphWordLabelDisplayItem / WordRelationEdgeInfo
-> WordGraphDataCache
-> GraphBuilder.buildMergedVisibleGraphData
```

Phase 2-A는 이 path를 변경하지 않는다. GraphPanel embed 단계에서도 production path 변경과 workspace embed 변경은 분리해서 검토해야 한다.

## 17. 단계적 migration architecture

Explorer 단일 workspace 전환은 다음 순서를 따른다.

| Phase | 목표 | 비고 |
| --- | --- | --- |
| Phase 2-A | architecture 문서 확정 | 이번 문서화 작업이다. 구현 변경은 없다. |
| Phase 2-B | 최소 typed contract 도입 | layout preset, transition origin, workspace state, history entry를 먼저 정의한다. |
| Phase 2-C | `ExplorerWorkspace` shell 도입 | route 제거 없이 placeholder shell boundary를 만든다. |
| Phase 2-D | panel orchestration callback boundary 도입 | 실제 panel 연결 없이 placeholder event boundary를 먼저 둔다. |
| Phase 2-E | `GraphPanel` embed | active graph production path를 보호하면서 embedded graph를 canonical path로 이동한다. |
| Phase 2-F | `DetailPane` embed | detail reading surface를 workspace 안으로 수렴한다. |
| Phase 2-G | route alias 전환 | Graph/Detail route를 `graphFocused`/`detailFocused` alias로 전환한다. |
| Phase 2-H | 내부 navigation 축소 | route push 중심 흐름을 workspace action 중심 흐름으로 줄인다. |
| Phase 2-I | route collapse 검토 | compatibility layer 제거 가능성을 검토한다. |

Phase 2-I 전에는 route 제거를 완료 상태로 선언하지 않는다. Phase 2-E 전에는 embedded graph가 canonical graph experience라고 구현 완료 선언하지 않는다. Phase 2-B 전에는 public boundary를 raw carrier로 확장하지 않는다.

### 17.1 Phase 2-B 최소 contract 도입 결과

Phase 2-B에서는 `lib/ui/explorer_workspace/explorer_workspace_contract.dart`에 다음 최소 typed contract만 추가한다.

- `ExplorerWorkspaceLayoutPreset`
- `ExplorerWorkspaceTransitionOrigin`
- `ExplorerWorkspaceState`
- `ExplorerWorkspaceHistoryEntry`

`ExplorerWorkspaceState`와 `ExplorerWorkspaceHistoryEntry`는 id, semantic origin, layout preset만 담는다. `graphData`, `detailData`, display item, `Map<String, dynamic>` carrier는 포함하지 않는다.

`ExplorerWorkspaceAction`과 `ExplorerWorkspacePanelEvent`는 이번 단계에서 만들지 않는다. 두 타입은 `ExplorerWorkspace` shell과 panel orchestration 연결이 시작되는 Phase 2-C 또는 Phase 2-D 이후 검토 대상으로 남긴다.

### 17.2 Phase 2-C placeholder shell 도입 결과

Phase 2-C에서는 `lib/ui/explorer_workspace/explorer_workspace.dart`에 `ExplorerWorkspace` placeholder shell을 추가한다.

이 shell은 `ExplorerWorkspaceState`를 필수 입력으로 받으며, `layoutPreset`에 따라 `StrongRail`, `GlobalSearch`, `GraphPanel`, `DetailPane`, `AddWordFixedAction` placeholder의 배치와 강조만 조정한다.

이번 단계에서는 route에 연결하지 않는다. 기존 `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`의 state ownership, graph production path, detail reread 흐름도 변경하지 않는다.

### 17.3 Phase 2-D callback boundary 도입 결과

Phase 2-D에서는 `ExplorerWorkspace`에 optional callback boundary만 추가한다.

- `onStrongSelected`
- `onSearchResultSelected`
- `onGraphNodeSelected`
- `onGraphCenterRequested`
- `onDetailRelationSelected`
- `onAddWordRequested`

placeholder에는 실제 word id가 없으므로 `ValueChanged<String>` callback은 호출하지 않는다. `AddWordFixedAction` placeholder만 id 없이 가능한 `onAddWordRequested`를 호출할 수 있다.

`ExplorerWorkspaceAction`과 `ExplorerWorkspacePanelEvent` 타입은 이번 단계에서도 만들지 않는다. 두 타입은 실제 panel orchestration 연결 또는 state owner 전환을 검토하는 후속 Phase에서 다시 판단한다.

### 17.4 Phase 2-E GraphPanel override slot 도입 결과

Phase 2-E에서는 `ExplorerWorkspace`에 optional `graphPanelOverride` slot만 추가한다.

이 단계는 `WordGraphScreen` 직접 embed가 아니며, 기본 렌더링은 기존 `GraphPanel` placeholder를 유지한다. override가 제공될 때만 GraphPanel 영역을 외부 widget으로 대체한다.

`ExplorerWorkspace`는 `WordGraphScreen`을 import하지 않고, dummy id를 만들지 않으며, graph production path와 state ownership을 변경하지 않는다.

## 18. Phase 2-A 비범위

Phase 2-A에서는 다음을 하지 않는다.

- route 제거
- screen 병합
- graph production path 변경
- graph node interaction 변경
- DB/API 변경
- repository contract 변경
- raw carrier 정리 또는 확대
- Flutter widget 구조 수정
- cache 정책 수정
- navigation behavior 구현
- 신규 문서 생성

## 19. 정리

Phase 2-A의 결론은 `ExplorerWorkspace`가 semantic state ownership과 panel orchestration의 중심이 되어야 한다는 것이다.

`selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 분리된 상태로 유지한다. 특히 `graphCenterWordId`는 명시적 center action에서만 변경한다. Panel은 표시와 event 전달을 담당하며, semantic transition은 workspace action으로만 발생한다.

장기적으로 embedded `GraphPanel`이 canonical graph experience가 되고, standalone graph와 detail route는 compatibility layer 또는 layout preset alias로 재정의된다. 단, route collapse는 마지막 단계이며 active graph production path는 마지막까지 보호한다.

Phase 2-A에서는 구현하지 않는다. Phase 2-B에서는 최소 typed contract만 도입하고 기존 구현 흐름은 바꾸지 않는다.
