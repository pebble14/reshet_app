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

기본/small-screen/`HomeScreen` detail edit:

1. `WordDetailScreen._openEdit()`
2. `WordEditScreen.fromSeed(...)`
3. 저장 성공 시 `WordEditSaveResult`
4. Detail 화면이 자체 reread 수행

large-screen embedded Explorer가 연 full-detail route:

1. `WordDetailScreen._openEdit()`이 `WordDetailEditRequestedResult` 반환
2. `WordExplorerScreen._openSelectedWordDetail()`이 result 해석
3. 기존 `WordExplorerScreen._openEditSelectedWord()` 재사용
4. Explorer edit 정책에 따라 selected word, center seed, graph revision과 history snapshot 갱신

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

`ExplorerWorkspace`는 route나 screen 병합 구현이 아니라, 장기 reference vocabulary 관점에서 workspace-level semantic state를 설명하기 위한 candidate coordination boundary를 의미한다. 이는 현재 runtime 권한 주체 선언이나 production migration commitment를 뜻하지 않는다.

이 문서에서 `StrongRail`은 기존 authority 문서의 `Strong Rail` 역할을 Explorer workspace composition 안에서 부르는 패널명이다. 명칭은 구현 class 도입을 뜻하지 않는다.

### 8.2 semantic state reference vocabulary

`ExplorerWorkspace`는 이 문서 안에서 semantic state를 설명하기 위한 preview-only coordination semantics의 기준축 후보로만 사용된다. 이때 `workspace action request`라는 표현은 panel event와 semantic state 사이의 관계를 설명하기 위한 preview/reference interaction vocabulary일 뿐이다. 이는 runtime interaction contract, runtime synchronization architecture, runtime execution model 승인, runtime authority 경계, canonical authority를 뜻하지 않는다.

| 상태 | reference boundary | 의미 | 변경 원칙 |
| --- | --- | --- | --- |
| `selectedWordId` | `ExplorerWorkspace` candidate boundary | 사용자가 현재 선택한 semantic object | selection action에서만 변경 |
| `graphCenterWordId` | `ExplorerWorkspace` candidate boundary | graph relation context의 anchor | 명시적 center action에서만 변경 |
| `detailTargetWordId` | `ExplorerWorkspace` candidate boundary | `DetailPane`이 읽는 대상 | detail target action에서만 변경 |
| `layoutPreset` | `ExplorerWorkspace` candidate boundary | workspace panel emphasis 상태 | layout action 또는 route alias action에서만 변경 |
| `origin` | `ExplorerWorkspace` history snapshot reference | transition의 semantic 진입 출처 | snapshot 생성 시 기록 |

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

Panel은 semantic state를 직접 소유하지 않는다. 이 절에서 `ExplorerWorkspace` action이라는 표현은 panel event와 semantic state 변화를 연결해 설명하는 preview/reference interaction label일 뿐이다. 이는 runtime action contract나 실행 주체 선언을 뜻하지 않는다.

| Panel | 역할 | 받는 state | emit하는 event | 소유하지 않는 것 |
| --- | --- | --- | --- | --- |
| `StrongRail` | Strong 기반 semantic anchor 접근과 workspace orientation 제공 | `selectedWordId`, `graphCenterWordId`, `layoutPreset` | strong anchor 선택, workspace entry 요청 | detail data, graph data, selected/detail/center 직접 변경 |
| `GlobalSearch` | corpus 진입을 위한 global search entry 제공 | 현재 workspace context, 필요 시 query/result 표시 상태 | search result 선택, result를 detail 또는 graph context로 여는 요청 | graph traversal, detail reading, center 직접 변경 |
| `GraphPanel` | relation graph surface 표시와 graph interaction event 전달 | `graphCenterWordId`, `selectedWordId`, `layoutPreset` | graph node 선택, graph center 요청, graph 관련 add 요청 | workspace semantic state, route stack, detail target |
| `DetailPane` | `detailTargetWordId`의 읽기 surface 제공 | `detailTargetWordId`, `selectedWordId`, `layoutPreset` | detail target 관련 graph 요청, edit 요청, linked word 선택 요청 | graph center, search state, route authority |
| `AddWordFixedAction` | exploration 중 생성 흐름에 진입하는 persistent action 제공 | `selectedWordId`, `graphCenterWordId`, `detailTargetWordId` | add word 시작, 생성 후속 요청 후보 전달 | 저장소 쓰기 contract, graph production path, center 직접 변경 |

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

### 11.1 route 이동의 workspace state transition 해석 후보

장기 reference 관점에서는 navigation을 route 이동이 아니라 `workspace state transition`이라는 preview/reference semantics로 해석해 기록한다. 이 표현은 runtime contract, runtime execution model, eventual runtime structure 확정을 뜻하지 않는다.

아래 표의 `workspace state transition`, `center action`, `graphFocused`, `detailFocused`는 planning input과 reference candidate 수준의 vocabulary이며, runtime orchestration implementation readiness나 route 구조 승인을 의미하지 않는다.

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
| Add Word 후 이동 | 생성 후속 해석 후보를 기록하되 center 변경은 명시적 center action 후보에 한정 |
| Edit Word 후 이동 | 기존 semantic state를 유지하고 display/data refresh만 수행 |

### 11.2 route alias reference direction

Graph route와 Detail route는 장기 reference 관점에서 별도 semantic destination이 아니라 workspace preset alias 후보로 해석해 볼 수 있다.

| 기존 route 의미 | 장기 alias 의미 |
| --- | --- |
| Graph route | `ExplorerWorkspace(layoutPreset: graphFocused)` |
| Detail route | `ExplorerWorkspace(layoutPreset: detailFocused)` |
| Explorer route | `ExplorerWorkspace(layoutPreset: balanced)` 또는 이전 workspace snapshot restore |

이 alias 정의는 즉시 route 제거를 뜻하지 않는다. 기존 route는 compatibility layer로 유지한 채, 내부 semantic을 `workspace state transition` reference vocabulary로 읽어 볼 수 있다는 정도만 기록한다. 이 문장은 runtime planning 승인이나 route collapse 선결정을 뜻하지 않는다.

## 12. route collapse 관련 reference 메모

이 절의 route collapse 언급은 historical/reference roadmap 메모다. route 제거 순서, runtime orchestration implementation readiness, eventual route structure 확정을 승인하지 않는다.

당시 reference 논의에서는 다음 같은 단계적 분해 표현을 사용했다.

1. semantic collapse
2. implementation collapse
3. route collapse

### 12.1 semantic collapse

기존 route 이동의 의미를 `ExplorerWorkspace` state transition reference로 문서화해 볼 수 있다는 메모다. 이 단계는 typed contract 확정, route 변경, screen 변경, graph production path 변경 승인을 뜻하지 않는다.

### 12.2 implementation collapse

기존 route가 장기적으로 같은 workspace semantics를 공유할 수 있는지 검토 후보로만 남긴다. Graph/Detail route는 여전히 compatibility layer reference로만 기록한다.

### 12.3 route collapse

compatibility layer 차이 축소 여부가 확인되더라도 별도 승인 없이는 route 제거를 결정하지 않는다. route collapse는 Phase 2-A의 범위가 아니다.

## 13. Responsive composition

PC split-view를 canonical layout으로 둔다. 이 기준에서 `StrongRail`, `GlobalSearch`, `GraphPanel`, `DetailPane`, `AddWordFixedAction`은 하나의 `ExplorerWorkspace` 안에서 조율된다.

좁은 화면에서는 composition만 바뀐다. semantic state는 유지된다.

- `DetailPane`이 숨겨져도 `detailTargetWordId`는 제거되지 않는다.
- `GraphPanel`이 축소되거나 다른 surface로 전환되어도 `graphCenterWordId`는 제거되지 않는다.
- `StrongRail`이 compact 표현으로 바뀌어도 navigation spine candidate 역할은 유지된다.
- `GlobalSearch`가 overlay 또는 transient entry로 표현되어도 workspace context와 분리되지 않는다.

Hidden panel은 상태 제거를 의미하지 않는다. 이는 `responsive_layout_policy.md`의 원칙인 "surface가 transient하더라도 semantic context가 transient해져서는 안 된다"와 같은 방향이다.

## 14. Workspace history

이 문서에서 `workspace history`는 route history와 구분해 보기 위한 preview/reference snapshot vocabulary다. 이는 runtime history contract, persisted snapshot authority, restore execution model 승인을 뜻하지 않는다.

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

History restore 관련 서술도 preview/reference interaction vocabulary로만 제한한다. 여기서 `restore action`은 snapshot 복원 의미를 설명하기 위한 label일 뿐이며, `ExplorerWorkspace` runtime restore contract나 복원 실행 주체 선언을 뜻하지 않는다. panel은 적용 후보 state를 표시하는 surface로만 기록한다.

## 15. 상태 충돌 방지 전략

이 절에서 semantic transition은 `ExplorerWorkspace` action이라는 preview/reference interaction label로만 묶어 서술한다. 이는 runtime action contract나 실행 흐름 승인을 뜻하는 문장이 아니다. Panel은 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`를 직접 소유하거나 변경하지 않는다.

### 15.1 preview/reference action label별 변경 가능 state 해석 범위

아래 action 이름은 preview/reference interaction vocabulary이며, runtime API나 실행 contract를 확정하지 않는다.

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
- panel-local callback에 대한 서술은 곧바로 상태를 바꾸는 runtime callback contract가 아니라, preview/reference interaction 요청 관계를 설명하는 수준에 한정한다.
- compatibility route 관련 서술도 내부 semantic을 preview/reference interaction vocabulary에 대응시켜 설명하는 adapter candidate 수준으로만 제한한다. runtime bridge 구현 승인을 뜻하지 않는다.

## 16. Embedded graph vs standalone graph

Embedded `GraphPanel`은 장기 reference direction에서 평가되는 graph experience candidate다. 이는 graph가 application shell이 아니라 workspace 안의 contextual semantic surface라는 authority 문서의 방향과 일치한다. 이 표현은 production replacement를 의미하지 않는다.

Standalone graph에 대해서는 장기 reference 관점에서 다음 같은 재해석 후보만 기록한다.

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

## 17. historical/reference roadmap 기록

아래 표와 하위 절은 Explorer 단일 workspace 관련 논의에서 누적된 historical/reference roadmap 기록이다.

이 기록은 deterministic roadmap, 승인된 runtime planning 순서, future implementation inevitability, eventual runtime structure 확정을 뜻하지 않는다. 또한 아래 단계명과 type/action 이름은 historical label일 뿐이며 현재 Phase 6 runtime contract나 runtime execution model 승인 문구가 아니다.

| Phase | 목표 | 비고 |
| --- | --- | --- |
| Phase 2-A | architecture 문서 확정 | 이번 문서화 작업이다. 구현 변경은 없다. |
| Phase 2-B | 최소 typed contract 도입 | layout preset, transition origin, workspace state, history entry를 먼저 정리 후보로 둔다. |
| Phase 2-C | `ExplorerWorkspace` shell 도입 | route 제거 없이 placeholder shell boundary를 두는 방향을 검토한다. |
| Phase 2-D | panel orchestration callback boundary 도입 | 실제 panel 연결 없이 placeholder event boundary를 먼저 두는 방향을 검토한다. |
| Phase 2-E | `GraphPanel` embed | active graph production path를 보호하면서 embedded graph를 future evaluation target으로 두는 reference direction을 정리 후보로 남긴다. |
| Phase 2-F | `DetailPane` embed | detail reading surface를 workspace composition candidate로 평가하는 reference direction을 정리 후보로 남긴다. |
| Phase 2-G | route alias 전환 | Graph/Detail route를 `graphFocused`/`detailFocused` alias로 해석하는 후보를 기록한다. |
| Phase 2-H | 내부 navigation 축소 | route push 중심 흐름을 preview/reference interaction vocabulary 중심 해석으로 줄여 볼 수 있는지 검토한다. |
| Phase 2-I | route collapse 검토 | compatibility layer 제거 가능성을 historical/reference 관점에서만 검토한다. |

Phase 2-I 전에는 route 제거를 완료 상태로 선언하지 않는다. Phase 2-E 전에는 embedded graph를 production replacement나 canonical graph experience로 완료 선언하지 않는다. Phase 2-B 전에는 public boundary를 raw carrier로 확장하지 않는다. 특히 Phase 2-G~2-I의 `route alias 전환`, `내부 navigation 축소`, `route collapse 검토`는 runtime orchestration implementation readiness, route collapse 승인, canonical owner migration inevitability를 뜻하지 않는다.

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

### 17.5 Phase 2-F DetailPane override slot 도입 결과

Phase 2-F에서는 `ExplorerWorkspace`에 optional `detailPaneOverride` slot만 추가한다.

이 단계는 `WordDetailScreen` 직접 embed가 아니며, 기본 렌더링은 기존 `DetailPane` placeholder를 유지한다. override가 제공될 때만 DetailPane 영역을 외부 widget으로 대체한다.

`ExplorerWorkspace`는 `WordDetailScreen`, `WordInfoPanel`, repository를 import하지 않고, dummy id를 만들지 않으며, detail reread 흐름과 display item ownership을 변경하지 않는다.

### 17.6 Phase 2-G route alias factory 도입 결과

Phase 2-G에서는 기존 route와 `Navigator` 호출을 변경하지 않고, `ExplorerWorkspaceState` 안에 route alias semantic을 생성하는 named factory만 추가한다.

추가된 factory는 Explorer entry, Graph route alias, Detail route alias, snapshot restore state를 typed contract로 표현한다. 기존 Graph/Detail/Explorer route는 compatibility layer로 유지한다.

route alias factory는 빈 word id를 허용하지 않고 `ArgumentError`로 차단한다. 특히 Graph route alias는 non-empty `graphCenterWordId`를 요구하며, dummy id를 만들지 않는다.

### 17.7 Phase 2-H 내부 navigation 축소 후보 검증 결과

Phase 2-H에서는 `Navigator` 호출과 기존 route를 변경하지 않고, 내부 navigation 축소 후보를 route alias semantic 관점에서 분류한다.

구현 반영은 route alias factory 단위 테스트로 제한한다. 이 테스트는 Explorer entry, Graph route alias, Detail route alias, snapshot restore, empty id 예외, trim 동작을 검증한다.

기존 Graph/Detail/Explorer route는 compatibility layer로 유지한다. Graph/detail production path, edit/add return flow, screen state ownership은 변경하지 않는다.

### 17.8 Phase 2-I workspace history semantic 검증 결과

Phase 2-I에서는 `ExplorerWorkspaceHistoryEntry` 구조를 변경하지 않고, workspace history의 push/replace/restore 기준을 문서와 테스트로 고정한다.

History push 후보는 명시적 `graphCenterWordId` 변경, route alias entry, 의도적인 detail focus 전환, route alias 성격의 `layoutPreset` 전환이다. 단순 `selectedWordId` 변경, 같은 semantic 대상 reread, edit/add return refresh는 현재 history entry를 replace하거나 history에 넣지 않는다. Snapshot restore는 새 history push가 아니라 저장된 snapshot 적용으로만 다룬다.

History에는 graph zoom/pan, hover/focus, detail scroll, 임시 edit input, loading/error transient state, display item, graph/detail data, raw `Map<String, dynamic>` carrier, repository/cache 상태를 넣지 않는다.

기존 `WordExplorerScreen` 내부 history는 변경하지 않는다. Flutter `Navigator` route history와 `ExplorerWorkspace` snapshot history는 route collapse 전까지 분리해서 유지한다.

### 17.9 Phase 3-A bootstrap/coexistence 조사 및 smoke 검증 범위

Phase 3-A에서는 `ExplorerWorkspace`를 production route에 연결하지 않는다. `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`의 `Navigator` 호출, route 등록, route 제거는 변경하지 않는다.

`WordExplorerScreen`은 기존 production explorer split-view owner로 유지한다. 현재 `WordExplorerScreen`은 graph center, selected word, detail panel, explorer history를 직접 소유하므로, `ExplorerWorkspace`가 이 상태를 병행 소유하거나 대체하지 않는다.

이번 단계의 bootstrap 검증은 route 미연결 widget smoke test로 제한한다. `ExplorerWorkspaceState.forExplorerEntry`, `forGraphRouteAlias`, `forDetailRouteAlias`가 `MaterialApp(home: ExplorerWorkspace(...))` 안에서 placeholder shell을 렌더링할 수 있는지만 확인한다.

`graphPanelOverride`와 `detailPaneOverride`는 passive widget 주입 가능성만 검증한다. `WordGraphScreen` 또는 `WordDetailScreen`을 실제 embed하지 않으며, repository, DB, graph production path, detail reread 흐름, state owner 이전은 수행하지 않는다.

Phase 3-A의 첫 실제 연결 후보는 production bootstrap이 아니라 `test/ui/explorer_workspace_phase3a_bootstrap_smoke_test.dart`의 route 미연결 smoke test다. 이 테스트는 placeholder 렌더링, override slot 표시, `AddWordFixedAction` placeholder callback 호출만 검증한다.

### 17.10 Phase 3-B coexistence boundary 조사 및 구조 검증 범위

Phase 3-B에서는 `ExplorerWorkspace`와 기존 `WordExplorerScreen`의 공존 경계를 고정한다. `WordExplorerScreen`은 production explorer owner로 유지하며, `ExplorerWorkspace`는 아직 replacement가 아니다.

`WordExplorerScreen`이 현재 소유하는 graph center, selected word, split-view detail display item, explorer history, `WordGraphScreen` child callback bridge, detail route push 흐름은 route collapse 전까지 `ExplorerWorkspace`로 이전하지 않는다.

`ExplorerWorkspace`는 state owner 중복을 만들지 않는다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`를 표현할 수는 있지만, production `WordExplorerScreen`의 `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, 내부 history를 동시에 조작하거나 대체하지 않는다.

`ExplorerWorkspace`는 graph/detail/route/repository와 직접 결합하지 않는다. `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, `WordInfoPanel`, repository 계층을 import하지 않고, `Navigator` route push를 소유하지 않는다.

route collapse 전까지 Flutter `Navigator` route history와 `ExplorerWorkspace` snapshot history는 분리해서 유지한다. 기존 route stack은 compatibility layer로 유지하고, workspace history는 source-level coexistence boundary와 smoke/test/preview 범위에서만 검증한다.

Phase 3-B의 구현 검증은 `test/ui/explorer_workspace_phase3b_coexistence_boundary_test.dart`의 source-level 구조 테스트로 제한한다. 이 테스트는 `ExplorerWorkspace`가 production screen, route push, repository와 직접 결합하지 않았음을 확인한다.

### 17.11 Phase 3-C passive projection 기준 및 smoke 검증 범위

Phase 3-C에서는 `ExplorerWorkspace` 안의 projection을 read-only state projection으로 제한한다. Projection은 `ExplorerWorkspaceState`에 이미 있는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin` 값만 표시할 수 있다.

Projection은 repository/read API를 호출하지 않는다. `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, `WordInfoPanel` 같은 production screen 또는 panel을 import하지 않고, graph/detail production path에 접근하지 않는다.

Projection은 display item을 보유하지 않는다. spelling, meaning, strong number, transliteration, pronunciation처럼 실제 단어 데이터처럼 보이는 값은 표시하지 않는다.

Projection은 state owner가 아니다. Callback을 통해 workspace state를 변경하지 않고, 기존 `WordExplorerScreen`의 center, selection, detail display item, history ownership도 대체하지 않는다.

`graphPanelOverride`와 `detailPaneOverride`가 제공되면 해당 placeholder의 projection도 함께 대체된다. Override slot은 production embed가 아니라 passive widget 주입 가능성으로만 유지한다.

Phase 3-C의 구현 검증은 `test/ui/explorer_workspace_phase3c_passive_projection_test.dart`의 route 미연결 widget smoke test로 제한한다. 이 테스트는 raw state label 표시와 override slot 대체 동작만 검증한다.

### 17.12 Phase 3-D production-adjacent adapter boundary 기준 및 구조 검증 범위

Phase 3-D에서는 production-adjacent adapter boundary를 문서와 source-level test로만 고정한다. 이번 단계의 adapter는 production screen embed가 아니며, adapter widget, adapter interface, type alias도 만들지 않는다.

Adapter는 `ExplorerWorkspaceState` 기반 passive projection까지만 허용한다. Adapter가 표시할 수 있는 값은 workspace state의 raw id, layout preset, origin 같은 read-only state label로 제한한다.

Adapter는 repository/read API를 호출하지 않는다. Display item을 보유하지 않고, spelling, meaning, strong number처럼 실제 단어 데이터처럼 보이는 값을 표시하지 않는다.

Adapter는 `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, `WordInfoPanel`을 import하지 않는다. Graph/detail production path, route stack, repository 계층을 직접 소유하거나 호출하지 않는다.

Adapter는 `Navigator`나 route push를 소유하지 않는다. Route collapse 전까지 기존 `Navigator` route history와 workspace snapshot history는 계속 분리한다.

Override slot과 adapter의 책임은 분리한다. `graphPanelOverride`와 `detailPaneOverride`는 외부 passive widget을 대체 주입하는 slot이고, adapter boundary는 workspace state를 production-adjacent surface로 넘기기 전에 허용 입력과 금지 의존성을 제한하는 규칙이다.

Phase 3-D의 구현 검증은 `test/ui/explorer_workspace_phase3d_adapter_boundary_test.dart`의 source-level boundary test로 제한한다. 이 테스트는 현재 `ExplorerWorkspace` source가 production screen, repository/read API, route wiring을 직접 참조하지 않는지 확인한다.

### 17.13 Phase 3-E 종료 기준 및 Phase 4 진입 조건

Phase 3-E에서는 Phase 2와 Phase 3에서 고정한 ExplorerWorkspace 경계를 정리하고, production 연결 전에 필요한 조건을 문서로만 남긴다. 이번 단계에서는 production code, route, Navigator, repository, DB/API, 기존 screen ownership을 변경하지 않는다.

Phase 2/3 결과는 다음 범위까지 완료된 것으로 본다.

- `ExplorerWorkspaceState`, layout preset, transition origin, history entry를 통한 최소 semantic contract를 정의했다.
- `ExplorerWorkspace` placeholder shell을 추가했지만 production route에는 연결하지 않았다.
- 선택, graph center, detail relation, add word 요청은 optional callback boundary로만 노출했다.
- `graphPanelOverride`와 `detailPaneOverride` slot을 추가했지만 `WordGraphScreen`과 `WordDetailScreen`을 embed하지 않았다.
- Explorer entry, graph route alias, detail route alias, snapshot restore factory를 추가해 route alias semantic을 typed contract로 표현했다.
- workspace history의 push, replace, restore 의미를 문서와 테스트로 고정했지만 기존 Navigator history와는 분리했다.
- `WordExplorerScreen`은 production explorer owner로 유지하고, `ExplorerWorkspace`는 아직 replacement가 아님을 coexistence boundary로 고정했다.
- Passive projection은 `ExplorerWorkspaceState`에 이미 있는 raw id, layout preset, origin label만 표시할 수 있도록 제한했다.
- Production-adjacent adapter는 구현하지 않고, adapter boundary를 source-level 규칙으로만 고정했다.

Production 연결 전 남은 핵심 문제는 다음과 같다.

- `WordExplorerScreen`이 보유한 center, selected, detail display item, explorer history ownership을 언제 어떻게 이전할지 결정되지 않았다.
- `WordGraphScreen`은 non-empty `centerWordId`, graph repository/cache/loading state, route fallback을 직접 보유하므로 그대로 embed하면 state owner가 중복될 수 있다.
- `WordDetailScreen`은 `initialDisplayItem`과 detail reread/display ownership을 요구하므로 dummy display item 없이 연결할 typed contract가 필요하다.
- Route collapse 전략이 확정되지 않았고, 기존 Navigator route stack과 workspace snapshot history의 관계도 아직 분리 상태다.
- Production read owner가 `ExplorerWorkspace`, adapter, 기존 screen 중 어디에 위치해야 하는지 결정되지 않았다.
- Callback boundary가 실제 production action contract로 확장될 기준이 아직 정리되지 않았다.

Phase 3 종료 기준은 다음 조건을 만족하는 상태로 제안한다.

- `ExplorerWorkspace`가 production screen, repository/read API, DB/API, Navigator route wiring을 직접 소유하지 않는다는 경계가 문서와 테스트로 유지된다.
- Route 미연결 widget smoke test가 shell, factory entry, override slot, passive projection을 검증한다.
- Source-level boundary test가 production screen import, repository import, route push 참조를 차단한다.
- `WordExplorerScreen`이 production owner로 유지되고, state owner 이전이 발생하지 않는다.
- Phase 4에서 논의해야 할 state owner migration, graph/detail read boundary, route/history 통합 조건이 명시되어 있다.

Phase 4 진입 조건은 다음 항목이 사전에 승인된 경우로 제한한다.

- Preview route를 허용할지, 허용한다면 dev-only 또는 production-hidden으로 둘지 결정한다.
- 첫 production-connected wrapper가 preview-only인지, 실제 production flow 후보인지 결정한다.
- `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, history ownership 이전 전략을 확정한다.
- Graph 연결 전 `WordGraphScreen` 직접 embed가 아닌 graph presentation/data boundary 분리 전략을 확정한다.
- Detail 연결 전 `initialDisplayItem` 공급 방식과 display item owner를 dummy 없이 정의한다.
- Navigator route history와 workspace snapshot history를 분리 유지할지, 일부 통합할지 기준을 정한다.
- Repository/read API 호출 owner를 명시하고, UI에서 data source나 repository를 우회하지 않도록 한다.

조기 production 연결 위험은 다음과 같다.

- `WordExplorerScreen`과 `ExplorerWorkspace`가 같은 center/selected/detail state를 동시에 소유할 수 있다.
- Route collapse를 먼저 진행하면 기존 graph, detail, edit, add word route 흐름에 회귀가 생길 수 있다.
- Adapter가 passive projection 경계를 넘어 production data owner로 커질 수 있다.
- `graphCenterWordId`, `selectedWordId`, `detailTargetWordId` 동기화가 어긋나면 graph focus와 detail display 의미가 불일치할 수 있다.
- `WordGraphScreen`의 center 요구사항이나 `WordDetailScreen`의 `initialDisplayItem` 요구사항을 맞추기 위해 dummy id 또는 dummy display item을 만들 위험이 있다.

다음 단계는 바로 Phase 4 production 연결로 진입하기보다, Phase 3-F를 문서 전용 단계로 둘지 검토하는 것이 안전하다. Phase 3-F를 둔다면 목적은 Phase 4 migration plan과 first production-connected wrapper decision을 정리하는 것이며, 이 단계에서도 production code 변경 없이 preview route 허용 여부, first wrapper 범위, state owner migration prerequisite만 확정한다.

### 17.14 Phase 3-F 첫 production 연결 전략

Phase 3-F에서는 Phase 4로 넘어가기 전에 첫 production 연결 후보의 우선순위를 문서로만 정리한다. 이번 단계에서는 production code, test, route, Navigator, repository, DB/API, 기존 screen ownership을 변경하지 않는다.

Phase 4의 첫 production 연결 후보는 다음과 같이 분류한다.

| 후보 | 설명 | 위험도 | 추천 여부 |
| --- | --- | --- | --- |
| route 미연결 preview | 기존 route와 무관하게 `ExplorerWorkspace`를 독립 preview surface로 검증한다. | 낮음 | 추천 |
| production-hidden wrapper | production route 기본값을 바꾸지 않고 숨겨진 wrapper로 제한 검증한다. | 낮음-중간 | 조건부 추천 |
| preview route | 명시적으로 허용된 dev-only 또는 hidden route에서만 wrapper를 연다. | 중간 | 사전 승인 후 검토 |
| 기존 `WordExplorerScreen` 내부 삽입 | 기존 production owner 내부에 `ExplorerWorkspace`를 배치한다. | 높음 | 현 단계 비추천 |
| 직접 route collapse | 기존 graph/detail/explorer route를 workspace route로 합친다. | 매우 높음 | 금지에 가깝게 보류 |

가장 안전한 Phase 4 시작안은 production route 기본값을 변경하지 않는 preview-only 또는 production-hidden 검토다. 이 시작안에서도 `WordExplorerScreen` replacement는 금지한다. `WordGraphScreen`과 `WordDetailScreen` 직접 embed도 금지하며, graph/detail production path는 기존 흐름을 유지한다.

State owner migration은 다음 순서로 검토한다.

1. `selectedWordId`는 passive selection label과 callback 의미가 충분히 안정된 뒤 migration 후보가 된다.
2. `graphCenterWordId`는 graph focus 의미와 center action 의미가 분리된 뒤 migration 후보가 된다.
3. `detailTargetWordId`는 selected state와 detail focus state의 불일치 기준이 정리된 뒤 migration 후보가 된다.
4. History는 Navigator route history와 workspace snapshot history의 관계가 결정된 뒤 migration 후보가 된다.
5. Display item owner는 `WordDetailScreen.initialDisplayItem` 공급 방식과 repository/read owner가 정리된 뒤 마지막으로 검토한다.

Navigator history와 workspace history는 당분간 분리 유지한다. Route collapse 전에는 두 history를 통합하지 않는다. Preview 단계에서는 workspace history만 독립적으로 검증하고, 기존 Navigator route stack의 production behavior는 compatibility layer로 보존한다.

Phase 4 진입 시에도 다음 항목은 금지한다.

- 기존 route 제거 금지
- production route 기본값 변경 금지
- dummy id 또는 dummy display item 생성 금지
- repository/read owner 무단 이전 금지
- `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`의 production responsibility 무단 이전 금지
- `WordGraphScreen` 또는 `WordDetailScreen` 직접 embed 금지
- UI에서 repository, DB, data source를 우회하는 read path 추가 금지

Phase 4 시작 전에는 다음 항목을 별도로 승인받아야 한다.

- preview route 허용 여부와 노출 범위
- first wrapper가 route 미연결 preview인지 production-hidden wrapper인지
- UI 테스트 필요 여부와 테스트 주체
- 기존 route로 되돌리는 rollback 기준
- state owner migration을 시작할 최소 조건
- repository/read owner를 변경하지 않는다는 보존 조건

Phase 4의 첫 작업은 production 연결 자체가 아니라, 승인된 preview 범위에서 wrapper가 기존 production owner와 충돌하지 않는지 확인하는 단계로 시작하는 것이 안전하다.

### 17.15 Phase 4-A production-hidden preview wrapper 기준

Phase 4-A는 production-connected preview boundary 단계이며, production replacement 단계가 아니다.

`ExplorerWorkspace`는 아직 production owner가 아니다. `WordExplorerScreen`이 계속 production explorer owner이며, 기존 앱 진입 흐름과 production route 기본값은 변경하지 않는다.

이번 단계의 wrapper는 production route에 연결하지 않는 숨겨진 preview host다. wrapper는 production-compatible semantic input을 `ExplorerWorkspaceState` factory로 조립하고 `ExplorerWorkspace`에 전달하는 역할만 가진다.

Phase 4-A에서는 state owner migration을 시작하지 않는다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, explorer history, graph/detail read owner는 기존 production screen에서 이전하지 않는다.

Phase 4-A에서는 `WordGraphScreen`과 `WordDetailScreen`을 직접 embed하지 않는다. repository/read API owner도 이전하지 않으며, dummy id 또는 dummy display item을 만들지 않는다.

Navigator route history와 workspace history는 계속 분리한다. Route alias factory는 semantic alias를 만들기 위한 typed contract이며, Navigator route ownership이나 route collapse를 뜻하지 않는다.

Phase 4-A의 검증 기준은 wrapper가 존재하더라도 `main.dart`와 `HomeScreen` production entry에서 접근되지 않고, 기존 `WordExplorerScreen(initialWordId: ...)` 진입이 유지되는 것이다.

### 17.16 Phase 4-B real projection input 기준

Phase 4-B는 production replacement 단계가 아니라, production-compatible real projection input을 hidden preview wrapper가 어디까지 안전하게 수용할 수 있는지 제한적으로 검증하는 단계다.

`ExplorerWorkspacePreviewInput`은 read-only projection contract로만 둔다. 허용 필드는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`으로 제한하며, search result, display item, explorer history source는 이번 단계에서 연결하지 않는다.

Projection input은 real id 문자열 shape를 받을 수 있지만 DB existence check를 수행하지 않는다. DB 존재 여부 검증은 repository/read owner 영역이며, preview contract가 맡지 않는다.

`ExplorerWorkspacePreviewScreen`은 `ExplorerWorkspacePreviewInput`을 소비하는 preview wrapper다. Wrapper는 production route 기본값을 변경하지 않고, `WordExplorerScreen` production owner를 대체하지 않으며, `WordGraphScreen` 또는 `WordDetailScreen`을 직접 embed하지 않는다.

Phase 4-B에서는 state owner migration, orchestration owner migration, repository/read owner migration, Navigator owner migration을 시작하지 않는다. Projection 전달은 허용하지만 ownership 이전은 금지한다.

이 단계는 rollback 가능한 production-hidden preview wrapper 검증 단계다. 문제가 확인되면 production route나 기존 `WordExplorerScreen` 흐름을 되돌릴 필요 없이 preview input contract와 wrapper 연결만 제거할 수 있어야 한다.

### 17.17 Phase 4-C passive synchronization 허용 범위 검증 기준

Phase 4-C는 passive synchronization 허용 범위 검증 단계이며, production replacement 또는 owner migration 단계가 아니다.

이번 단계에서 passive synchronization은 `ExplorerWorkspacePreviewInput` 기반 real projection의 read-only 관계를 확인하는 의미로만 사용한다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`를 동시에 받을 수는 있지만, 세 값을 병합하거나 서로 추론하거나 하나의 state owner로 승격하지 않는다.

여러 projection id가 서로 다른 값이어도 이는 owner migration을 뜻하지 않는다. Preview wrapper는 caller가 제공한 projection 값을 `ExplorerWorkspaceState`로 옮겨 표시하는 adapter 역할만 유지한다.

Phase 4-C에서는 callback/state mutation API를 추가하지 않는다. Preview wrapper는 `ExplorerWorkspace` callback을 연결하지 않고, production state를 변경하거나 orchestration owner가 되지 않는다.

Navigator history와 workspace history는 계속 분리한다. Projection 관계는 route push, route replacement, route collapse, history source 연결을 생성하지 않는다.

Repository/read source owner도 이전하지 않는다. Preview boundary는 DB existence check, graph data read, detail display read, search result projection, display item projection, explorer history source 연결을 수행하지 않는다.

`WordExplorerScreen`은 production explorer owner로 유지한다. `main.dart`, `HomeScreen`, production route 기본값은 변경하지 않으며, `WordGraphScreen` 또는 `WordDetailScreen`을 직접 embed하지 않는다. Dummy id 또는 dummy display item도 생성하지 않는다.

Phase 4-C의 구현 검증은 boundary regression test와 문서 기록으로 제한한다. Production `lib/` 코드 변경이 필요해 보이면 이 단계에서는 중단하고 별도 설계 검토로 분리한다.

### 17.18 Phase 4-D preview-local interaction boundary 기준

Phase 4-D는 ExplorerWorkspace preview 내부에서만 동작하는 제한적 interaction boundary 검증 단계이며, production replacement 또는 owner migration 단계가 아니다.

이번 단계에서 허용하는 interaction은 별도 preview-only host의 ephemeral state로 제한한다. 기존 `ExplorerWorkspacePreviewScreen`은 계속 read-only projection wrapper로 유지하며, Phase 4-D interaction host는 production route 또는 production entry에 연결하지 않는다.

Preview-local interaction은 `ExplorerWorkspacePreviewInput`에 이미 들어온 non-empty id만 사용할 수 있다. Interaction host는 graph target 또는 detail target을 preview 내부 state로 전환할 수 있지만, DB existence check, graph data read, detail display read, search result projection, display item projection은 수행하지 않는다.

Interaction 결과는 preview host 내부에서만 소비한다. Preview interaction은 `Navigator` 호출, route push, route replacement, route alias factory 호출, workspace history와 Navigator history의 결합으로 확장하지 않는다.

Repository/read owner는 이전하지 않는다. Phase 4-D preview interaction host는 `WordRepository`, repository read API, DB/API, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, `WordInfoPanel`을 참조하지 않는다.

Dummy id 또는 dummy display item은 생성하지 않는다. Preview host는 caller가 제공하지 않은 id를 만들지 않으며, spelling, meaning, strong number 같은 실제 단어 display carrier도 합성하지 않는다.

`WordExplorerScreen`은 계속 production explorer owner다. `HomeScreen` production entry, `main.dart`의 production route 기본값, 기존 graph/detail/explorer route 흐름은 변경하지 않는다.

Phase 4-D의 구현 검증은 `test/ui/explorer_workspace_phase4d_preview_interaction_boundary_test.dart`의 preview-local widget test와 source-level boundary regression test로 제한한다. 이 테스트는 preview host가 내부 state 전환만 수행하고 production owner, repository/read boundary, Navigator route boundary, route alias interaction으로 확장되지 않는지 확인한다.

### 17.19 Phase 4-E preview-only composition boundary 기준

Phase 4-E는 ExplorerWorkspace preview 구조가 preview-only composition/orchestration candidate로 어디까지 확장 가능한지 문서와 regression test로 고정하는 단계다. 이 단계는 production replacement가 아니며, `ExplorerWorkspacePreviewScreen`은 production owner 또는 source of truth가 아니다.

Preview-only composition boundary는 workspace-local orchestration을 검토하기 위한 비권위 조립 경계다. Layout preset, panel visibility, graph/detail panel composition은 preview 내부 표현을 조립하는 기준으로만 사용할 수 있으며, production route 기본값, `HomeScreen` production entry, `WordExplorerScreen` production owner를 대체하지 않는다.

Interaction과 orchestration은 분리해서 해석한다. Interaction은 preview host 내부에서 발생하는 event와 ephemeral state 전환이며, orchestration은 preview 내부 panel 배치, visibility, projection 전달 순서를 조립하는 UI-level coordination이다. Orchestration이 repository read owner, Navigator owner, canonical selection owner, route owner로 해석되면 안 된다.

Orchestration을 ownership으로 확대 해석하는 위험은 production owner 침범이다. 특히 preview composition이 repository/read API 호출, data source 접근, Navigator route history 병합, route collapse, persisted state, route restore, canonical selection ownership으로 확장되면 Phase 4-E 범위를 벗어난다.

Projection lifecycle은 UI-level lifecycle이다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId` 같은 projection 값은 preview가 받은 입력을 표시하거나 preview-local interaction에 반영하는 수명만 가진다. 이 lifecycle은 repository/data lifecycle, DB existence validation, graph data read, detail display read, search result projection lifecycle이 아니다.

Preview 구조는 rollback 가능해야 한다. 문제가 확인되면 production route, `HomeScreen`, `WordExplorerScreen`, repository contract, Navigator history를 되돌리지 않고 preview wrapper, preview interaction host, preview composition test와 문서 경계만 제거하거나 축소할 수 있어야 한다.

Phase 4-E의 검증은 source-level boundary regression test와 문서 기록으로 제한한다. Production `lib/` import tree에 preview 구조를 유입하지 않고, `WordGraphScreen`/`WordDetailScreen` 직접 embed, dummy id, dummy display item fallback, repository ownership, Navigator ownership이 추가되지 않는지 확인한다.

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

Phase 2-A의 정리 대상은 `ExplorerWorkspace`를 semantic state reference vocabulary와 panel orchestration candidate boundary를 inventory하는 reference candidate로 보수적으로 검토하는 데 있다.

`selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 분리된 상태로 유지한다. 특히 `graphCenterWordId`는 명시적 center action에서만 변경한다. 이때 `workspace action`, `semantic transition` 같은 표현은 preview/reference interaction vocabulary일 뿐이며, runtime 실행 주체나 authority semantics를 뜻하지 않는다.

당시 reference 논의에서는 embedded `GraphPanel`을 canonical graph experience의 migration candidate direction으로 평가할 수 있다고 기록했고, standalone graph와 detail route도 compatibility layer 또는 layout preset alias 방향의 검토 후보로 남겼다. 이는 production replacement, route collapse 승인, canonical owner migration inevitability를 의미하지 않으며 active graph production path는 마지막까지 보호한다.

이 문서는 runtime execution model 승인 문서가 아니라, Phase 2-A부터 Phase 5-I까지 누적된 reference semantics와 boundary를 보수적으로 보존하는 문서다.
### 17.20 Phase 5-A preview-only layout orchestration 기준

Phase 5-A는 preview-only layout orchestration 단계다. 이 단계는 production replacement 단계가 아니다. `WordExplorerScreen` production owner와 production route 기본값은 유지한다.

이번 단계에서 ExplorerWorkspace preview는 preview-only layout reference shell로만 서술된다. 허용 범위는 preview 내부 `balanced`, `graphFocused`, `detailFocused` preset 전환, graph/detail panel visibility orchestration, split ratio orchestration, preview composition layout 조정이다.

Phase 5-A의 preset 전환은 semantic id와 canonical item은 유지한 채 layout만 조율해야 한다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 preset 전환만으로 변경되지 않는다. panel visibility와 split ratio는 preview host 내부 local orchestration state로만 관리한다.

이번 단계에서 ExplorerWorkspace preview는 repository, Navigator, canonical authority, persistence/history authority의 주체가 아니다. Preview orchestration이 repository read/write, route stack, route restore, canonical selection, persistence/history 권한 경계로 해석되면 범위를 벗어난다.

Preview 내부 panel visibility와 split ratio 조율은 production route 교체나 route collapse를 정당화하지 않는다. `WordExplorerScreen` 제거 또는 대체, `HomeScreen` production entry 변경, preview 구조의 production navigation 연결은 금지한다.

Phase 5-A에서도 dummy/fallback display item은 추가하지 않는다. fake display item, fallback placeholder item, 임시 canonical item 생성은 허용하지 않는다. 검증은 preview-local widget test, source-level boundary regression test, 문서 현행화로 제한한다.
### 17.21 Phase 5-A-1 route 미연결 preview access boundary 기준

Phase 5-A-1은 route 미연결 preview access boundary 단계다. 이 단계의 목적은 production route를 변경하지 않고 클라이언트가 ExplorerWorkspace preview UI를 직접 확인할 수 있는 최소 실행 진입점을 제공하는 것이다.

이번 단계는 별도 preview 실행 엔트리 포인트만 추가한다. 실행 기준은 `flutter run -t lib/main_explorer_workspace_preview.dart`이며, 이 엔트리 포인트는 production route에 연결하지 않는다.

Phase 5-A-1의 preview access는 production Navigator tree에 preview를 연결하지 않는다. `HomeScreen`, `WordExplorerScreen`, `main.dart`의 production entry, route table, `onGenerateRoute`, hidden button, hidden gesture는 변경하지 않는다.

이 엔트리 포인트는 기존 preview/test harness와 동일한 preview-only input만 사용한다. repository read/write, persistence/history access, canonical authority, display item projection, dummy/fallback display item 생성은 허용하지 않는다.

따라서 Phase 5-A-1은 preview 접근성만 보강하는 boundary다. preview access가 production-connected wrapper, production navigation flow, production owner migration으로 해석되면 안 된다.
### 17.22 Phase 5-B layout state policy / preset UX refinement 기준

Phase 5-B는 ExplorerWorkspace preview 안에서 layout state policy와 preset UX semantics를 더 명확히 고정하는 단계다. 이 단계도 production replacement가 아니다. `WordExplorerScreen` production owner, production route 기본값, repository owner, Navigator owner, canonical authority, persistence/history authority는 유지한다.

이번 단계에서 ExplorerWorkspace preview는 계속 preview-only orchestration reference shell로만 서술된다. preset과 panel visibility state는 같은 개념으로 결합하지 않는다.

- `layoutPreset`은 권장 orchestration snapshot이다.
- panel visibility state는 현재 local workspace state다.
- preset 전환은 현재 local workspace state를 강제로 canonical layout으로 되돌리는 동작이 아니다.

Preset semantics는 다음과 같이 고정한다.

| preset | 의미 | 허용 해석 |
| --- | --- | --- |
| `balanced` | graph/detail 균형 상태 | preview 기본 진입 preset이며, graph와 detail을 함께 읽는 기본 workspace snapshot이다. |
| `graphFocused` | graph 탐색 집중 상태 | graph surface를 주로 읽도록 강조하지만 detail을 보조 surface로 유지할 수 있다. |
| `detailFocused` | detail 해석 집중 상태 | detail surface를 주로 읽도록 강조하지만 graph relation context를 보조 surface로 유지할 수 있다. |

Preset은 authority가 아니다.

- preset은 canonical authority가 아니다.
- preset은 persistence authority가 아니다.
- preset은 preview orchestration state일 뿐이다.

Preview-only layout state policy는 다음과 같이 유지한다.

| 항목 | 정책 |
| --- | --- |
| 기본 visibility | graph + detail |
| 허용 layout state | `graph + detail`, `graph only`, `detail only` |
| 금지 layout state | `graph hidden + detail hidden` |
| invariant | 최소 하나의 semantic panel visible 유지 |

`balanced default`를 유지하는 사유는 다음과 같다.

- preview 기본 상태에서 graph relation context와 detail reading context를 동시에 확인할 수 있어야 한다.
- `balanced`는 unified Explorer UX의 기본 split-view 후보를 가장 보수적으로 보여준다.
- `graphFocused` 또는 `detailFocused`를 기본값으로 두면 특정 surface가 canonical default처럼 오해될 수 있으므로, authority 비이전 원칙과 맞지 않는다.

Phase 5-B의 refinement는 과도한 UI 변경이 아니다. 허용 범위는 preset 라벨 정리, 상태명 정리, panel visibility protection 명확화, preview-only 설명 문구 정리까지다. production route 연결, `WordExplorerScreen` 변경, repository 주입 구조 변경, Navigator 구조 변경, DB 변경, persistent layout 저장 추가는 이번 단계 범위를 벗어난다.

미래 unified Explorer UX와의 관계는 다음과 같다.

- 이번 단계는 unified Explorer UX의 최종 production semantics를 확정하는 단계가 아니다.
- 다만 장기적으로 `preset = recommended orchestration snapshot`, `visibility state = current local workspace state` 구조를 유지할 수 있는 최소 preview policy를 검증한다.
- route collapse, authority migration, persistence layout 정책은 별도 승인과 별도 단계 없이는 진행하지 않는다.
### 17.23 Phase 5-C fixed navigation rail candidate 기준

Phase 5-C는 future unified Explorer UX 관점에서 `StrongRail`을 fixed navigation rail candidate로 정의하는 문서/경계 정리 단계다. 이 단계는 preview-only boundary 안에 머무르며 production replacement 단계가 아니다. `WordExplorerScreen` production owner, production route 기본값, repository owner, Navigator owner, persistence/history authority는 유지한다.

`StrongRail`의 semantic 역할은 기존 Strong 기반 진입 의미를 workspace 안의 stable navigation spine으로 다시 설명하는 것이다. Rail은 strong anchor 접근, 현재 workspace orientation, 현재 semantic context의 기준축을 제공할 수 있다. 그러나 rail이 graph data, detail data, repository read/write, route push, history restore를 직접 소유해서는 안 된다. Rail이 내보내는 것은 explicit workspace entry request 또는 explicit anchor request뿐이며, selected/detail/center authority 자체를 가져가면 안 된다.

이번 단계에서 `persistent narrow rail`은 storage 또는 persistence 의미가 아니다. 이는 preview composition 안에서 rail이 폭이 좁은 상태로 계속 남아 있을 수 있는 시각적 고정 rail 후보라는 뜻으로만 사용한다. 따라서 persistent narrow rail 가능성을 문서화하더라도 persisted layout 저장, route restore 기준, Navigator history 결합, repository-backed preference, production shell ownership으로 해석하면 안 된다.

Graph/detail orchestration과의 관계도 제한한다. `StrongRail`은 graph/detail panel 바깥에 남는 stable orientation axis 후보일 뿐이며, `GraphPanel`과 `DetailPane`의 read owner를 흡수하지 않는다. `layoutPreset`이 `balanced`, `graphFocused`, `detailFocused` 사이를 오가더라도 rail은 graph/detail emphasis를 보조하는 navigation spine 후보로만 남는다. 이 관계는 route collapse, `WordExplorerScreen` replacement, graph/detail production path 재배선의 근거가 아니다.

`active`, `focused`, `preview` state 표현은 새 canonical state 추가가 아니라 기존 workspace state에서 파생되는 표현으로만 제한한다.

- `active` 표현은 현재 rail에서 의미상 가리키는 strong anchor 또는 현재 semantic context를 나타내는 read-only highlight 후보다.
- `focused` 표현은 `layoutPreset`이 어느 surface를 상대적으로 강조하는지 보여주는 보조 표현이며 rail 자체가 focus authority를 소유하지 않는다.
- `preview` 표현은 현재 구성이 preview-only boundary 안에 있음을 드러내는 비권위 표시이며 persistence, production navigation, repository ownership을 뜻하지 않는다.

따라서 Phase 5-C에서 추가로 도입하는 rail semantics는 unified Explorer UX의 기준축 후보를 문서로 고정하는 역할만 가진다. 장기적으로 rail이 unified workspace orientation의 기준축이 될 수는 있지만, 이번 단계에서 `WordExplorerScreen` authority 이전, route collapse, production navigation replacement, repository/Navigator/persistence authority migration을 시작하지 않는다. `HomeScreen`의 현재 strong list 진입 의미와 `WordExplorerScreen`의 production explorer authority도 계속 분리해서 유지한다.

### 17.24 Phase 5-D fixed search anchor / semantic entry point candidate 기준

Phase 5-D는 future unified Explorer UX 관점에서 `GlobalSearch`를 fixed search anchor / semantic entry point candidate로 정리하는 문서/경계 단계다. 이 단계도 preview-only boundary 안에 머무르며 production replacement 단계가 아니다. `WordExplorerScreen` production owner, production route 기본값, repository owner, Navigator owner, persistence/history authority는 유지한다.

이번 단계에서 Search는 corpus 진입과 workspace retarget initiation을 담당하는 semantic entry surface 후보로만 정의한다. Search는 현재 workspace context를 기준으로 사용자가 다른 word context로 명시적으로 이동할 수 있게 하는 entry point이며, 현재 semantic context를 다시 잡아 주는 orientation surface 후보이기도 하다. 그러나 Search가 canonical selection owner가 되거나 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`를 직접 소유해서는 안 된다.

Search가 내보내는 것은 explicit retarget request 수준으로 제한한다. Search result 선택은 workspace에 "어느 semantic target을 다음 context로 열지"를 요청하는 event 후보일 뿐이며, 그 자체로 graph center 변경, detail target 확정, canonical selection 확정, route push, history restore를 직접 수행하는 owner가 아니다. Search는 entry / orientation / explicit retarget request surface로만 해석해야 하며, graph/detail ownership, route ownership, persistence ownership으로 확대 해석하면 안 된다.

Graph/detail과의 관계도 제한한다. `GlobalSearch`는 `GraphPanel`이나 `DetailPane`의 read owner를 흡수하지 않으며, graph traversal, detail reading, selected word authority를 직접 갖지 않는다. Search가 어떤 result를 통해 graph 쪽 또는 detail 쪽으로 이동 후보를 제시할 수는 있지만, 이는 "어느 surface를 다음에 열지"에 대한 semantic suggestion 또는 retarget request일 뿐이다. 따라서 Search는 graph/detail production path 재배선, `WordExplorerScreen` replacement, route collapse의 근거가 아니다.

`temporary focus initiation`과의 관계는 후보 관계로만 정리한다. Search result는 장기 unified Explorer UX에서 특정 surface를 잠시 전면에 두거나 먼저 열어 보게 만드는 temporary focus initiation candidate가 될 수 있다. 그러나 이것은 focus owner 이전이나 canonical focus state 도입을 뜻하지 않는다. Search가 `layoutPreset`, persistent focus policy, route alias, persisted workspace layout을 직접 결정하거나 저장하는 주체가 되면 안 된다.

Search anchor semantics 역시 비권위 표현으로만 유지한다.

- `entry` 의미는 corpus 안의 다른 semantic target으로 들어가는 시작점 후보라는 뜻이다.
- `orientation` 의미는 현재 workspace context를 잃지 않은 채 사용자가 다른 target을 찾도록 돕는 기준 surface라는 뜻이다.
- `explicit retarget request` 의미는 사용자가 명시적으로 고른 target을 preview/reference interaction label로 전달하는 요청 surface라는 뜻이다.

따라서 Phase 5-D에서 추가로 도입하는 search semantics는 unified Explorer UX에서 Search를 fixed anchor / semantic entry point candidate로 해석할 수 있는 상한선만 문서로 고정한다. 이번 단계에서 Search는 canonical selection owner, graph/detail owner, route owner, persistence owner가 아니며, `WordExplorerScreen` authority 이전, production navigation replacement, repository/Navigator/persistence authority migration, route collapse를 시작하지 않는다. runtime/UI 코드 변경도 이번 단계 범위에 포함하지 않는다.

### 17.25 Phase 5-E global creation entry surface candidate 기준

Phase 5-E는 future unified Explorer UX 관점에서 `AddWordFixedAction`을 global creation entry surface candidate로 정리하는 문서/경계 단계다. 이 단계도 preview-only boundary 안에 머무르며 production replacement 단계가 아니다. `WordExplorerScreen` production owner, production route 기본값, repository owner, Navigator owner, persistence/history authority는 유지한다.

이번 단계에서 Add Word는 creation entry / explicit creation request surface 후보로만 정의한다. Add Word는 사용자가 현재 workspace context 안에서 새 word 생성 흐름을 명시적으로 시작하는 global creation entry point candidate다. 그러나 Add Word가 canonical insertion authority가 되거나, 생성 결과를 canonical state에 삽입하는 owner가 되거나, 생성 완료 이후 semantic state를 스스로 확정하는 주체가 되어서는 안 된다.

Add Word가 내보내는 것은 explicit creation request 수준으로 제한한다. 사용자의 Add Word action은 "생성 흐름을 시작하라"는 workspace-level request 후보일 뿐이며, 그 자체로 repository write 수행, persistence 저장, route push, route replacement, history restore, center 변경, selection 확정, detail target 확정을 직접 소유하지 않는다. 따라서 Add Word는 repository ownership, persistence ownership, route ownership을 갖지 않으며, creation entry / explicit creation request surface로만 해석해야 한다.

Rail/Search/Graph/Detail과의 관계도 후보 관계로만 정리한다. `AddWordFixedAction`은 `StrongRail`, `GlobalSearch`, `GraphPanel`, `DetailPane`과 함께 unified Explorer UX 안에서 조합될 수 있는 creation entry candidate일 뿐이며, 이들 surface의 owner를 흡수하지 않는다. Rail과의 관계는 workspace-level persistent action axis 후보 관계, Search와의 관계는 corpus entry와 creation entry가 병치될 수 있는 후보 관계, Graph/Detail과의 관계는 현재 context를 보조한 채 생성 흐름을 시작할 수 있는 후보 관계로만 본다. 이 관계는 graph/detail production path 재배선, repository write owner 이전, `WordExplorerScreen` replacement, route collapse의 근거가 아니다.

Creation entry semantics 역시 비권위 표현으로만 유지한다.

- `creation entry` 의미는 새 word 생성 흐름으로 들어가는 시작점 후보라는 뜻이다.
- `explicit creation request` 의미는 사용자가 명시적으로 생성 시작 의도를 preview/reference interaction label로 전달하는 요청 surface라는 뜻이다.
- `global` 의미는 특정 panel owner가 아니라 workspace composition 전반에서 접근 가능한 action 후보라는 뜻이다.

따라서 Phase 5-E에서 추가로 도입하는 Add Word semantics는 unified Explorer UX에서 Add Word를 global creation entry surface candidate로 해석할 수 있는 상한선만 문서로 고정한다. 이번 단계에서 Add Word는 canonical insertion authority, repository owner, persistence owner, route owner가 아니며, `WordExplorerScreen` authority 이전, production navigation replacement, repository/Navigator/persistence authority migration, route collapse를 시작하지 않는다. runtime/UI 코드 변경도 이번 단계 범위에 포함하지 않는다.

### 17.26 Phase 5-F graph/detail hierarchy and temporary focus lifecycle 기준

Phase 5-F는 unified Explorer UX 관점에서 `GraphPanel`과 `DetailPane`의 hierarchy 후보와 temporary focus lifecycle을 정리하는 문서/경계 단계다. 이 단계는 production migration 단계가 아니며, route collapse 단계도 아니다. `WordExplorerScreen` production owner, canonical state owner, repository owner, Navigator owner, persistence/history authority는 유지한다. runtime/UI 코드 변경도 이번 단계 범위에 포함하지 않는다.

이번 단계에서 Graph / Detail hierarchy는 ownership hierarchy가 아니라 orchestration/foreground hierarchy 후보로만 정의한다. `GraphPanel`과 `DetailPane`은 서로의 owner가 아니며, 둘 중 하나가 다른 쪽의 canonical state를 직접 소유하거나 결정하지 않는다. hierarchy라는 표현은 현재 semantic context에서 어느 surface가 일시적으로 foreground reading surface가 되는지, 어떤 surface가 contextual support surface로 남는지에 대한 상대적 foreground order 후보를 뜻한다.

`graphFocused`, `detailFocused`, `balanced` 같은 배치는 foreground semantics를 조정할 수 있지만 authority semantics를 바꾸지 않는다. foreground semantics는 사용자가 지금 어느 surface를 우선 읽고 조작하는지에 대한 contextual emphasis일 뿐이며, canonical selection, graph center, detail target ownership을 재지정하지 않는다. 따라서 foreground semantics를 authority semantics로 해석하면 안 된다.

Graph/detail synchronization boundary도 ownership 이전이 아니라 workspace-level coordination boundary로 제한한다. Graph가 detail 쪽 foreground를 유도하는 signal을 보낼 수 있고, Detail이 graph 쪽 foreground를 유도하는 signal을 보낼 수는 있다. 그러나 이는 `ExplorerWorkspace` action을 통한 contextual synchronization 후보일 뿐이며, Graph가 Detail owner가 되거나 Detail이 Graph owner가 되는 근거가 아니다. `graphCenterWordId`, `detailTargetWordId`, `selectedWordId`는 focus나 foreground만으로 병합되거나 자동 승격되지 않는다.

Temporary focus lifecycle은 UI-level temporary lifecycle로만 정리한다.

- `focus acquisition`은 explicit graph center request, explicit detail-open request, linked context request, search retarget request, temporary expansion reveal 같은 계기로 특정 surface가 foreground 후보가 되는 단계다.
- `focus decay`는 다른 surface에 대한 명시적 요청, layout emphasis 변경, temporary trigger 소멸로 인해 foreground 강도가 약해지고 해당 surface가 contextual support surface로 돌아가는 단계다.
- `focus disposal`은 temporary foreground 의미가 종료되어도 canonical selection, repository state, Navigator history, persisted layout을 변경하지 않은 채 temporary focus만 제거되는 단계다.

이 lifecycle은 canonical selection lifecycle과 다르다. temporary focus는 canonical selection으로 자동 확장되지 않으며, temporary focus acquisition만으로 `selectedWordId`가 canonical semantic selection으로 확정되지 않는다. temporary focus는 persistence 대상으로 저장되지 않으며 repository authority, Navigator authority, history authority를 만들지 않는다.

Semantic context transition 역시 foreground 재배치 후보로만 해석한다. 사용자의 explicit action이나 contextual request가 Graph/Detail 사이의 foreground를 바꿀 수는 있지만, 이는 route migration이나 owner migration을 뜻하지 않는다. semantic context transition은 "어느 surface가 현재 context를 전경에서 설명하는가"를 조정하는 수준으로만 제한하며, production route 기본값, canonical state owner, repository/Navigator/persistence authority를 바꾸지 않는다.

Temporary expansion과 canonical selection의 경계도 분리한다. temporary expansion은 graph relation reveal, detail context reveal, linked context preview처럼 현재 context를 잠시 넓혀 보여 주는 후보 의미다. 이는 foreground acquisition의 계기가 될 수는 있지만 canonical selection과 동일하지 않다. temporary expansion은 selection action 없이도 종료될 수 있으며, canonical selection owner나 persistence target으로 승격되지 않는다.

따라서 Phase 5-F에서 추가로 도입하는 graph/detail hierarchy와 temporary focus semantics는 unified Explorer UX에서 foreground orchestration을 어떻게 해석할지에 대한 상한선만 문서로 고정한다. 이번 단계에서 production migration, route collapse, canonical state owner 이전, repository/Navigator/persistence authority migration, Graph와 Detail 간 ownership 부여, temporary focus의 canonical selection 확장은 시작하지 않는다.

### 17.27 Phase 5-G workspace composition boundary 기준

Phase 5-G는 unified Explorer UX 관점에서 `ExplorerWorkspace` 내부 surface들이 어떤 composition contract로 함께 존재하는지 정리하는 문서/경계 단계다. 이 단계는 production migration 단계가 아니며, route collapse 단계도 아니다. canonical state owner, repository owner, Navigator owner, persistence/history authority는 유지한다. runtime/UI 코드 변경도 이번 단계 범위에 포함하지 않는다.

이번 단계에서 workspace composition boundary는 ownership boundary가 아니라 surface coordination contract로만 정의한다. `StrongRail`, `GlobalSearch`, `GraphPanel`, `DetailPane`, `AddWordFixedAction`, temporary focus candidate는 같은 workspace 안에서 함께 존재할 수 있지만, 이 공존 자체가 owner 병합이나 canonical contract 이전을 뜻하지 않는다. composition boundary의 목적은 "어떤 surface가 어떤 semantic contract로 나란히 배치되고 조율되는가"를 문서로 고정하는 것이다.

Orchestration layer composition도 UI-level coordination으로만 제한한다. orchestration layer는 surface 간 표시 순서, foreground 후보, local visibility, temporary emphasis, contextual entry ordering을 조정할 수 있다. 그러나 orchestration layer가 canonical state owner를 흡수하거나 repository/Navigator/persistence authority를 재배치하는 계층으로 해석되면 안 된다. orchestration layer composition은 authority layer가 아니라 composition layer다.

Surface registration semantics는 문서상 semantics로만 둔다. registration은 어떤 surface가 workspace composition contract 안에서 어떤 역할 이름과 제약으로 참여하는지 설명하는 표현일 뿐이며, runtime plugin 구조, dynamic module loading, detachable runtime extension, registration API 설계로 확장하지 않는다. 따라서 registration은 설계 vocabulary이지 구현 hook이 아니다.

Workspace-local lifecycle coordination은 canonical lifecycle이 아니라 local coordination lifecycle로만 정리한다. 어떤 surface가 foreground에 오르는지, 어떤 entry surface가 현재 context에서 활성 후보인지, temporary focus가 언제 생기고 사라지는지는 workspace-local coordination 수준에서 조율할 수 있다. 그러나 이 lifecycle은 canonical selection lifecycle, repository data lifecycle, Navigator route lifecycle, persisted workspace lifecycle과 동일하지 않다.

Detachable surface semantics도 해석 후보로만 제한한다. detachable surface라는 표현은 특정 surface가 장기적으로 다른 composition shape에서 분리되어 보일 수 있다는 해석 후보를 뜻할 뿐이며, 실제 분리 구현, 독립 route, 독립 process, runtime detachable module, window 분리 구현을 뜻하지 않는다. detachable surface를 실제 구현 계획으로 읽으면 이번 단계 범위를 벗어난다.

Fixed entry surface / graph / detail / temporary focus 사이의 composition 관계는 다음과 같이 제한한다.

- fixed entry surface는 workspace 진입과 retarget initiation을 위한 entry candidate로 composition에 참여한다.
- graph surface와 detail surface는 contextual reading surface로 composition에 참여한다.
- temporary focus는 foreground emphasis candidate로 composition에 참여한다.
- 이 참여 관계는 coordination contract이지 ownership contract가 아니다.

Composition contract와 authority boundary는 분리해서 유지한다. composition contract는 "함께 존재하는 방식"을 설명하고, authority boundary는 "누가 canonical state와 persistence를 소유하는가"를 설명한다. composition contract가 확대되어 canonical owner 재배치, repository/Navigator/persistence authority migration, route ownership 재정의로 이어지면 안 된다.

따라서 Phase 5-G에서 추가로 도입하는 workspace composition semantics는 unified Explorer UX에서 surface들이 어떤 coordination contract로 함께 존재할 수 있는지에 대한 상한선만 문서로 고정한다. 이번 단계에서 production migration, route collapse, canonical state owner 이전, runtime plugin 구조 확장, workspace-local lifecycle의 canonical lifecycle 확장, detachable surface의 실제 분리 구현은 시작하지 않는다.

### 17.28 Phase 5-H semantic transition boundary 기준

Phase 5-H는 unified Explorer UX 관점에서 workspace 안의 focus/context/surface가 전환될 때 무엇이 유지되고 무엇이 해제되는지 정리하는 문서/경계 단계다. 이 단계는 production migration 단계가 아니며, route collapse 단계도 아니다. canonical state owner, repository owner, Navigator owner, persistence/history authority는 유지한다. runtime/UI 코드 변경도 이번 단계 범위에 포함하지 않는다.

이번 단계에서 semantic context transition은 workspace-local orchestration semantics로만 정의한다. transition은 현재 workspace 안에서 어느 semantic context가 foreground에서 해석되는지, 어떤 contextual support surface가 남는지, temporary focus continuity가 어디까지 유지되는지를 조정하는 해석 후보다. 그러나 이 transition이 route navigation 자체이거나 canonical selection 변경 자체라고 단정하면 안 된다.

Focus transition boundary는 authority boundary가 아니라 foreground orchestration boundary다. focus transition은 어떤 surface가 현재 전경에서 읽히고 어떤 surface가 보조 context로 남는지를 조정할 수 있지만, 이 전환만으로 canonical state owner가 바뀌지 않는다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 explicit semantic action 없이 focus transition만으로 자동 변경되거나 병합되지 않는다.

Foreground surface transition 역시 ownership 이동이 아니라 surface emphasis 전환으로만 해석한다. `GraphPanel`에서 `DetailPane`으로, `DetailPane`에서 `GraphPanel`으로, fixed entry surface에서 graph/detail foreground로 전환되는 경우가 있더라도 이는 현재 전경 설명 surface의 변화일 뿐이다. foreground surface transition을 Graph owner에서 Detail owner로, 또는 entry surface에서 canonical owner로 이동하는 근거로 읽으면 안 된다.

Temporary focus carry-over는 temporary orchestration continuity로만 제한한다. 이전 foreground에서 형성된 temporary focus가 다음 foreground surface에서도 잠시 해석 continuity를 가질 수는 있다. 그러나 이 carry-over는 persistence 대상이 아니며 repository authority, Navigator authority, canonical selection authority를 만들지 않는다. carry-over가 유지되더라도 temporary focus disposal은 언제든 가능해야 하며, disposal은 persisted state나 route history를 남기지 않은 채 temporary orchestration state만 해제하는 의미로만 해석한다.

Graph/detail/context transition 관계도 workspace-local coordination으로만 정리한다. Graph context가 detail foreground로 이어질 수 있고, detail context가 graph foreground로 이어질 수 있으며, 둘 다 shared semantic context를 잠시 참조할 수 있다. 그러나 이 관계는 transition request와 foreground continuity의 문제이지, Graph와 Detail 사이의 ownership 배분 문제가 아니다. graph/detail/context transition은 route migration, data authority migration, canonical owner migration의 근거가 아니다.

Fixed entry surface는 transition request를 발생시키는 후보 surface로만 설명한다. `StrongRail`, `GlobalSearch`, `AddWordFixedAction` 같은 fixed entry surface는 현재 workspace context에 대해 retarget, creation, foreground change 같은 transition request를 발생시킬 수 있다. 그러나 request를 발생시킨다는 사실만으로 entry surface가 transition 결과 state를 직접 소유하지는 않는다. entry surface는 request source일 뿐, transition owner가 아니다.

Transition semantics와 canonical selection boundary도 분리한다. transition은 foreground context를 바꾸거나 temporary focus continuity를 조정할 수 있지만, canonical selection boundary를 넘지 않는다. temporary focus carry-over, foreground surface transition, semantic context retarget은 explicit selection action 없이 canonical selection으로 승격되지 않는다. 따라서 transition 결과와 canonical selection 결과는 서로 다른 contract로 유지해야 한다.

Semantic transition lifecycle은 다음과 같이 해석한다.

- `transition acquisition`은 explicit retarget request, explicit foreground change request, linked context request, temporary focus continuity trigger 같은 계기로 새로운 foreground context가 후보가 되는 단계다.
- `transition carry-over`는 이전 foreground의 temporary focus가 다음 surface에서 잠시 continuity를 유지하는 단계다.
- `transition disposal`은 continuity가 더 이상 필요 없을 때 temporary focus와 foreground emphasis만 해제하고 canonical state는 그대로 두는 단계다.

따라서 Phase 5-H에서 추가로 도입하는 semantic transition semantics는 unified Explorer UX에서 workspace 내부 transition을 어떤 orchestration boundary로 해석할지에 대한 상한선만 문서로 고정한다. 이번 단계에서 production migration, route collapse, canonical state owner 이전, repository/Navigator/persistence authority migration, transition의 route navigation 확장, transition의 canonical selection 단정, temporary focus carry-over의 persistence 확장은 시작하지 않는다.

### 17.29 Phase 5-I 용어 약화 및 종료 안정화 기준

Phase 5-I는 새 설계를 추가하는 단계가 아니라, Phase 5-A부터 Phase 5-H까지 사용한 reference vocabulary를 preview-only orchestration semantics boundary 안으로 다시 고정하는 terminology hardening 단계다. 이 단계는 production migration, runtime coordination 구현, route collapse, canonical owner migration을 의미하지 않는다.

이번 단계에서는 `owner`, `canonical path`, `수렴`, `semantic navigation spine`, `global entry point`, `universal entry point`처럼 runtime ownership, production commitment, canonical authority로 오해될 수 있는 표현을 candidate / reference direction / future evaluation target / non-owner semantics로 약화한다. 이 약화는 기존 Phase 5-F/G/H boundary 의미를 바꾸는 것이 아니라, 같은 경계를 더 보수적으로 읽히게 만드는 문서 정리다.

따라서 Phase 5 종료는 preview-only orchestration semantics의 boundary stabilization 완료만 뜻한다. 이는 production replacement 승인, runtime coordination implementation 시작, route collapse 개시, canonical state owner migration, repository/Navigator/persistence authority 이전을 의미하지 않는다.

다음 단계인 Phase 6은 implementation 단계가 아니라 runtime coordination planning 단계로 진입해야 한다. 별도 승인 없는 route collapse, production migration, canonical owner migration, persistence authority 재배치는 Phase 5 종료만으로 정당화되지 않는다.

### 17.30 Phase 6-A runtime coordination boundary audit 기준

Phase 6-A는 runtime coordination planning으로 읽힐 수 있는 기존 문서 표현의 경계를 다시 고정하는 audit 단계다. 이 절은 새 runtime 구조를 확정하거나 future implementation inevitability를 선언하는 문장이 아니다.

- `historical/reference roadmap`:
  - 이 문서의 Phase 표, phase label, typed contract/action 이름, route alias/collapse 언급은 historical/reference roadmap 기록이다.
  - 이는 deterministic roadmap, 승인된 runtime planning 순서, eventual runtime structure 확정을 뜻하지 않는다.
- `planning은 implementation readiness가 아님`:
  - `runtime coordination planning`은 planning input과 reference candidate를 정리하는 수준으로만 해석한다.
  - 이는 runtime orchestration implementation readiness, runtime synchronization architecture 승인, runtime contract 확정으로 이어지지 않는다.
- `preview/reference semantics != runtime contract`:
  - 이 문서의 preview/reference semantics는 runtime contract와 동일하지 않다.
  - `workspace action`, `restore action`, `semantic transition`, `orchestration`, `synchronization`, `history snapshot`, `route alias`는 preview/reference interaction vocabulary 또는 planning input label일 뿐이다.
  - 현재 문서는 runtime execution model 승인 문서가 아니다.
- `ExplorerWorkspace 비권위화`:
  - `ExplorerWorkspace`는 권한 주체나 실행 주체가 아니다.
  - `ExplorerWorkspace` 명칭은 workspace-level semantic reference를 묶어 설명하기 위한 label일 뿐이며, 현재 runtime 주체 선언이나 실행 모델 선언이 아니다.
- `coordination vocabulary의 확장 금지`:
  - coordination/orchestration/synchronization vocabulary는 권한 주체나 실행 주체 semantics로 확장하지 않는다.
  - 이 vocabulary는 canonical owner migration, Provider/Repository/Navigator/persistence authority 재배치, route collapse 승인, production replacement의 근거가 아니다.
- `현재 authority 유지`:
  - runtime/UI 코드 수정 없이 현재 Provider/Repository/Navigator/persistence authority, existing production route 기본값, `WordExplorerScreen` production authority 경계를 유지한다.
  - 별도 승인 없는 canonical owner migration, route collapse, persistence authority 재배치는 정당화되지 않는다.

### 17.31 Phase 6-B owner-preserving runtime coordination candidate inventory 기준

Phase 6-B는 Phase 6-A 경계를 유지한 채 ExplorerWorkspace 문맥에서 논의 가능한 runtime coordination 후보를 owner-preserving inventory로만 정리하는 문서 단계다. 이번 단계는 implementation 단계가 아니며 runtime execution model, runtime synchronization architecture, route collapse, canonical owner migration, Provider/Repository/Navigator/persistence authority 이전을 승인하지 않는다.

이번 inventory는 `passive coordination candidate`와 `explicit request coordination candidate`로만 구분한다. 여기서 explicit request coordination candidate는 runtime action 또는 execution 주체를 뜻하지 않으며, 사용자의 명시적 요청 후보를 reference vocabulary로 약하게 분류하는 표현이다. `ExplorerWorkspace`는 여전히 coordinator, controller, owner가 아니며 workspace-level semantic reference label로만 유지한다.

#### 17.31.1 passive coordination candidate inventory

- candidate 1
  - coordination candidate: semantic state projection inventory
  - 현재 owner / authority: `WordExplorerScreen`이 graph center, selected word, split-view detail display item, explorer history를 직접 보유하고, `WordGraphScreen`이 graph center, selected word, viewport, visible graph data를 직접 보유하며, `WordDetailScreen`이 detail reread와 display ownership을 유지한다.
  - owner-preserving planning scope: `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`를 projection/reference inventory로만 정리한다.
  - forbidden expansion: state 병합, automatic synchronization, canonical owner 선언, Provider/Repository/Navigator/persistence authority 이전
  - implementation status: not approved
- candidate 2
  - coordination candidate: workspace surface composition contract inventory
  - 현재 owner / authority: `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, Flutter `Navigator`가 기존 production entry, screen, route authority를 유지한다.
  - owner-preserving planning scope: `StrongRail`, `GlobalSearch`, `GraphPanel`, `DetailPane`, `AddWordFixedAction`, temporary focus candidate의 공존 관계를 composition/reference inventory로만 정리한다.
  - forbidden expansion: `ExplorerWorkspace`를 coordinator/controller/owner로 서술, canonical contract 이전, registration API 또는 runtime plugin 구조 확정
  - implementation status: not approved
- candidate 3
  - coordination candidate: route alias / layout preset reference mapping inventory
  - 현재 owner / authority: existing Graph/Detail/Explorer route 의미와 route stack authority는 Flutter `Navigator`와 기존 production route가 유지한다.
  - owner-preserving planning scope: `graphFocused`, `detailFocused`, `balanced`, snapshot restore를 route alias reference mapping으로만 inventory화한다.
  - forbidden expansion: route collapse 승인, route 제거 순서 확정, runtime route rewiring, route ownership 재정의
  - implementation status: not approved
- candidate 4
  - coordination candidate: workspace snapshot / restore vocabulary inventory
  - 현재 owner / authority: `WordExplorerScreen` 내부 history와 Flutter `Navigator` route history는 분리된 채로 유지되며, persistence authority도 기존 production 경계를 유지한다.
  - owner-preserving planning scope: snapshot field와 `restore action` label을 history/restore reference vocabulary로만 정리한다.
  - forbidden expansion: restore execution owner 지정, persisted snapshot authority 이전, `Navigator` history 병합, display item/graph data/raw carrier 저장
  - implementation status: not approved
- candidate 5
  - coordination candidate: graph/detail foreground synchronization and temporary focus boundary inventory
  - 현재 owner / authority: `WordExplorerScreen`이 split-view semantic 조율을 유지하고, `WordGraphScreen`이 graph interaction local authority를 유지하며, `WordDetailScreen`이 detail reading authority를 유지한다.
  - owner-preserving planning scope: foreground, temporary focus, carry-over, disposal을 non-owner coordination boundary 후보로만 정리한다.
  - forbidden expansion: Graph/Detail ownership 부여, canonical selection 자동 승격, persisted focus policy 확정, runtime synchronization architecture 승인
  - implementation status: not approved

#### 17.31.2 explicit request coordination candidate inventory

- candidate 1
  - coordination candidate: fixed navigation entry request candidate
  - 현재 owner / authority: `HomeScreen`의 현재 strong entry 의미, Flutter `Navigator`의 route push authority, `WordExplorerScreen`의 production explorer authority가 유지된다.
  - owner-preserving planning scope: `StrongRail`의 explicit workspace entry request, explicit anchor request를 request candidate vocabulary로만 정리한다.
  - forbidden expansion: Rail의 selected/detail/center authority 흡수, route push ownership 부여, persisted layout 결정 주체화
  - implementation status: not approved
- candidate 2
  - coordination candidate: search retarget request candidate
  - 현재 owner / authority: `HomeScreen`이 search query와 result entry state를 유지하고, 실제 후속 route와 reading authority는 기존 production screen과 `Navigator`가 유지한다.
  - owner-preserving planning scope: `GlobalSearch`의 explicit retarget request, semantic suggestion, temporary focus initiation candidate를 request vocabulary로만 정리한다.
  - forbidden expansion: Search의 canonical selection owner화, graph/detail owner화, route push/history restore ownership 부여, persistence authority 이전
  - implementation status: not approved
- candidate 3
  - coordination candidate: explicit graph focus / center request candidate
  - 현재 owner / authority: `WordExplorerScreen`과 `WordGraphScreen`이 graph center authority와 selection 관련 production authority를 계속 유지한다.
  - owner-preserving planning scope: `centerGraphOnWord`, `openGraphFocus`, linked center request를 explicit center request candidate로만 inventory화한다.
  - forbidden expansion: automatic center propagation, graph execution coordinator 선언, route rewrite 승인, canonical owner migration 정당화
  - implementation status: not approved
- candidate 4
  - coordination candidate: explicit detail focus / linked context request candidate
  - 현재 owner / authority: `WordExplorerScreen`이 split-view detail target과 selected display context를 유지하고, `WordDetailScreen`이 detail route reread와 display ownership을 유지한다.
  - owner-preserving planning scope: `setDetailTarget`, `openDetailFocus`, linked context request를 explicit detail request candidate로만 정리한다.
  - forbidden expansion: detail target owner migration, graph-to-detail automatic route execution, display owner transfer, persistence authority 이전
  - implementation status: not approved
- candidate 5
  - coordination candidate: add-word follow-up request candidate
  - 현재 owner / authority: create 이후 후속 흐름은 기존 caller screen, repository post-save helper, Flutter `Navigator`, persistence authority가 유지한다.
  - owner-preserving planning scope: `AddWordFixedAction`, `completeAddWord`, creation follow-up interpretation을 explicit creation/follow-up request candidate로만 정리한다.
  - forbidden expansion: repository write owner 이전, canonical insertion authority 부여, auto center change 정책 확정, route replacement 정책 고정
  - implementation status: not approved
- candidate 6
  - coordination candidate: post-edit refresh request candidate
  - 현재 owner / authority: `WordDetailScreen`, `WordExplorerScreen`, `WordGraphScreen`이 각 caller 위치에서 reread/refresh 후속 authority를 유지한다.
  - owner-preserving planning scope: `refreshAfterEdit`를 semantic owner 변경 없는 explicit refresh request candidate로만 정리한다.
  - forbidden expansion: refresh coordinator 신설, semantic owner 변경, repository/Navigator/persistence authority 흡수
  - implementation status: not approved

#### 17.31.3 inventory-wide forbidden expansion

- `ExplorerWorkspace`를 runtime coordinator, runtime controller, runtime owner로 승격하지 않는다.
- 어떤 candidate도 canonical owner migration proposal, route collapse 승인 근거, runtime execution model 확정, runtime synchronization architecture 승인으로 해석하지 않는다.
- Provider/Repository/Navigator/persistence authority는 기존 production 경계에 그대로 둔다.
- `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, `HomeScreen`, Flutter `Navigator`의 현재 authority를 inventory만으로 재배치하지 않는다.
- `implementation-ready`, `approved for implementation`, `eventual execution owner`처럼 implementation readiness로 읽히는 표현을 추가하지 않는다.

### 17.32 Phase 6-C authority-crossing risk classification 기준

Phase 6-C는 Phase 6-B에서 정리한 coordination candidate가 어떤 지점에서 current owner / authority 경계를 침범하거나 그렇게 읽힐 위험이 큰지 분류하는 문서 단계다. 이번 단계는 implementation planning이 아니며, implementation prioritization도 아니다. risk classification 결과는 runtime planning 확장 승인, implementation planning 진입 승인, authority migration 승인, route collapse 승인, implementation roadmap 순서 확정을 뜻하지 않는다.

이번 분류는 candidate 자체의 가치 판단이 아니라 boundary drift 위험을 문서화하는 용도로만 사용한다. `ExplorerWorkspace`는 여전히 runtime coordinator, runtime controller, runtime owner가 아니며 workspace-level semantic reference label로만 유지한다. Provider/Repository/Navigator/persistence authority와 기존 production route 기본값도 그대로 유지한다.

#### 17.32.1 risk level definition

- `low`:
  - 현재 authority 경계 안에서 drift 가능성이 매우 낮은 후보를 뜻한다.
  - 이번 Phase 6-C에서는 해당 조건을 만족하는 candidate를 식별하지 않았다.
  - `low`도 implementation-ready 또는 implementation 우선순위를 뜻하지 않는다.
- `medium`:
  - boundary 문서화 자체는 상대적으로 가능하지만, current owner / authority 보호 장치와 forbidden expansion을 함께 적지 않으면 authority-crossing으로 읽히기 쉬운 후보를 뜻한다.
  - `medium`은 implementation-ready가 아니며, reference vocabulary / inventory 수준에서만 상대적으로 문서화가 쉽다는 뜻으로 제한한다.
- `high`:
  - owner/controller/coordinator drift, runtime synchronization architecture 해석, route collapse 근거화, canonical owner migration 정당화 위험이 높은 후보를 뜻한다.
  - `high`는 현 시점에서 구현 우선순위가 높다는 뜻이 아니며, 오히려 문서 경계가 쉽게 무너질 수 있음을 경고하는 분류다.
- `blocked`:
  - candidate 자체 폐기를 뜻하지 않는다.
  - candidate는 문서상 reference candidate로 유지할 수 있다.
  - 다만 reference vocabulary / inventory 수준을 넘는 runtime planning 확장, implementation planning, authority migration, route collapse 정당화로 이어지는 해석은 현재 금지된다는 뜻이다.

#### 17.32.2 passive coordination candidate authority-crossing risk classification

- candidate name: `semantic state projection inventory`
  - candidate type: `passive coordination candidate`
  - current owner / authority: `WordExplorerScreen`이 graph center, selected word, split-view detail display item, explorer history를 직접 보유하고, `WordGraphScreen`이 graph center, selected word, viewport, visible graph data를 직접 보유하며, `WordDetailScreen`이 detail reread와 display ownership을 유지한다.
  - authority-crossing risk: `high`
  - risk reason: `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`를 함께 적는 순간 workspace canonical state, Provider source of truth, automatic synchronization contract처럼 읽히기 쉽다.
  - forbidden expansion: state 병합, automatic synchronization, canonical owner 선언, Provider/Repository/Navigator/persistence authority 이전
  - implementation status: `not approved`
- candidate name: `workspace surface composition contract inventory`
  - candidate type: `passive coordination candidate`
  - current owner / authority: `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, Flutter `Navigator`가 기존 production entry, screen, route authority를 유지한다.
  - authority-crossing risk: `medium`
  - risk reason: surface composition 설명이 `ExplorerWorkspace` runtime coordinator/controller/owner 의미로 drift할 위험은 있지만, composition/reference inventory로 한정하면 current owner를 직접 대체하지는 않는다.
  - forbidden expansion: `ExplorerWorkspace`를 coordinator/controller/owner로 서술, canonical contract 이전, registration API 또는 runtime plugin 구조 확정
  - implementation status: `not approved`
- candidate name: `route alias / layout preset reference mapping inventory`
  - candidate type: `passive coordination candidate`
  - current owner / authority: existing Graph/Detail/Explorer route 의미와 route stack authority는 Flutter `Navigator`와 기존 production route가 유지한다.
  - authority-crossing risk: `high`
  - risk reason: route alias, layout preset, snapshot restore 매핑은 runtime route rewiring, route ownership 재정의, route collapse 승인 근거로 오해되기 쉽다.
  - forbidden expansion: route collapse 승인, route 제거 순서 확정, runtime route rewiring, route ownership 재정의
  - implementation status: `not approved`
- candidate name: `workspace snapshot / restore vocabulary inventory`
  - candidate type: `passive coordination candidate`
  - current owner / authority: `WordExplorerScreen` 내부 history와 Flutter `Navigator` route history는 분리된 채로 유지되며, persistence authority도 기존 production 경계를 유지한다.
  - authority-crossing risk: `blocked`
  - risk reason: snapshot/restore vocabulary는 reference 수준을 조금만 넘겨도 restore execution owner 지정, persisted snapshot authority 이전, `Navigator` history 병합, display item/graph data/raw carrier 저장 정책으로 곧바로 확장되기 쉽다.
  - forbidden expansion: restore execution owner 지정, persisted snapshot authority 이전, `Navigator` history 병합, display item/graph data/raw carrier 저장
  - implementation status: `not approved`
- candidate name: `graph/detail foreground synchronization and temporary focus boundary inventory`
  - candidate type: `passive coordination candidate`
  - current owner / authority: `WordExplorerScreen`이 split-view semantic 조율을 유지하고, `WordGraphScreen`이 graph interaction local authority를 유지하며, `WordDetailScreen`이 detail reading authority를 유지한다.
  - authority-crossing risk: `high`
  - risk reason: foreground, temporary focus, carry-over, disposal vocabulary는 runtime synchronization architecture, canonical selection 자동 승격, persisted focus policy로 읽히기 쉽다.
  - forbidden expansion: Graph/Detail ownership 부여, canonical selection 자동 승격, persisted focus policy 확정, runtime synchronization architecture 승인
  - implementation status: `not approved`

#### 17.32.3 explicit request coordination candidate authority-crossing risk classification

- candidate name: `fixed navigation entry request candidate`
  - candidate type: `explicit request coordination candidate`
  - current owner / authority: `HomeScreen`의 현재 strong entry 의미, Flutter `Navigator`의 route push authority, `WordExplorerScreen`의 production explorer authority가 유지된다.
  - authority-crossing risk: `medium`
  - risk reason: explicit entry request는 request vocabulary로 유지할 수 있지만, route push owner나 persisted layout 결정 주체처럼 읽히기 쉽다.
  - forbidden expansion: Rail의 selected/detail/center authority 흡수, route push ownership 부여, persisted layout 결정 주체화
  - implementation status: `not approved`
- candidate name: `search retarget request candidate`
  - candidate type: `explicit request coordination candidate`
  - current owner / authority: `HomeScreen`이 search query와 result entry state를 유지하고, 실제 후속 route와 reading authority는 기존 production screen과 `Navigator`가 유지한다.
  - authority-crossing risk: `medium`
  - risk reason: `GlobalSearch` retarget request는 전역 search owner, canonical selection owner, route push/history restore owner처럼 drift할 위험이 있다.
  - forbidden expansion: Search의 canonical selection owner화, graph/detail owner화, route push/history restore ownership 부여, persistence authority 이전
  - implementation status: `not approved`
- candidate name: `explicit graph focus / center request candidate`
  - candidate type: `explicit request coordination candidate`
  - current owner / authority: `WordExplorerScreen`과 `WordGraphScreen`이 graph center authority와 selection 관련 production authority를 계속 유지한다.
  - authority-crossing risk: `high`
  - risk reason: `centerGraphOnWord`, `openGraphFocus`, linked center request는 graph center source of truth, automatic center propagation, route rewrite 근거로 읽히기 쉽다.
  - forbidden expansion: automatic center propagation, graph execution coordinator 선언, route rewrite 승인, canonical owner migration 정당화
  - implementation status: `not approved`
- candidate name: `explicit detail focus / linked context request candidate`
  - candidate type: `explicit request coordination candidate`
  - current owner / authority: `WordExplorerScreen`이 split-view detail target과 selected display context를 유지하고, `WordDetailScreen`이 detail route reread와 display ownership을 유지한다.
  - authority-crossing risk: `high`
  - risk reason: `setDetailTarget`, `openDetailFocus`, linked context request는 detail owner migration, graph-to-detail automatic route execution, display owner transfer로 읽히기 쉽다.
  - forbidden expansion: detail target owner migration, graph-to-detail automatic route execution, display owner transfer, persistence authority 이전
  - implementation status: `not approved`
- candidate name: `add-word follow-up request candidate`
  - candidate type: `explicit request coordination candidate`
  - current owner / authority: create 이후 후속 흐름은 기존 caller screen, repository post-save helper, Flutter `Navigator`, persistence authority가 유지한다.
  - authority-crossing risk: `blocked`
  - risk reason: create 이후 follow-up request는 reference 수준을 넘는 순간 repository write owner, post-save execution owner, route replacement 정책, auto center change 정책 문제로 바로 확장되기 쉽다.
  - forbidden expansion: repository write owner 이전, canonical insertion authority 부여, auto center change 정책 확정, route replacement 정책 고정
  - implementation status: `not approved`
- candidate name: `post-edit refresh request candidate`
  - candidate type: `explicit request coordination candidate`
  - current owner / authority: `WordDetailScreen`, `WordExplorerScreen`, `WordGraphScreen`이 각 caller 위치에서 reread/refresh 후속 authority를 유지한다.
  - authority-crossing risk: `medium`
  - risk reason: `refreshAfterEdit`는 caller-local reread를 넘어서 refresh coordinator, shared invalidation owner, global refresh execution 주체처럼 읽힐 수 있다.
  - forbidden expansion: refresh coordinator 신설, semantic owner 변경, repository/Navigator/persistence authority 흡수
  - implementation status: `not approved`

#### 17.32.4 risk interpretation guardrail

- risk classification은 implementation prioritization이 아니다.
- `medium`은 implementation-ready가 아니며, boundary 문서화가 상대적으로 쉬운 후보라는 뜻으로만 제한한다.
- `high`는 owner/controller/coordinator drift, runtime synchronization, route collapse, canonical owner migration 위험이 높다는 뜻이지 구현 우선순위가 높다는 뜻이 아니다.
- `blocked`는 candidate 자체 폐기를 뜻하지 않으며, reference candidate로는 유지할 수 있다. 다만 reference vocabulary / inventory 수준을 넘는 runtime planning 확장, implementation planning, authority migration, route collapse 정당화는 현재 금지된다.
- `ExplorerWorkspace`를 runtime coordinator/controller/owner로 서술하지 않는다.
- Provider/Repository/Navigator/persistence authority는 기존 production 경계에 그대로 둔다.
- route collapse 승인 문장, implementation roadmap 순서처럼 읽히는 문장, implementation-ready 표현을 추가하지 않는다.

### 17.33 Phase 6-D authority-preserving coordination guardrail policy 기준

Phase 6-D는 Phase 6-B coordination candidate inventory와 Phase 6-C authority-crossing risk classification을 owner-preserving guardrail policy로 고정하는 문서 단계다. 이번 단계는 implementation planning이 아니며, guardrail policy 자체도 runtime/UI implementation permission이 아니다. 이 단계는 runtime implementation 승인, route collapse 승인, canonical owner migration 승인, owner/controller/coordinator 재배치 승인으로 해석하지 않는다.

`ExplorerWorkspace`는 여전히 runtime coordinator, runtime controller, runtime owner가 아니며 workspace-level semantic reference label로만 유지한다. Provider/Repository/Navigator/persistence authority와 기존 production route 기본값도 그대로 유지한다. coordination candidate는 owner migration proposal이 아니고, risk classification은 implementation prioritization이 아니며, allowed wording 또한 implementation approval을 뜻하지 않는다.

#### 17.33.1 wording policy

- allowed wording:
  - `reference vocabulary`, `candidate inventory`, `owner-preserving boundary`, `current owner / authority 유지`, `non-owner coordination label`, `reference-only mapping`, `caller-local reread`, `implementation status: not approved`
  - allowed wording은 문서상 허용 가능한 boundary 표현일 뿐이며 implementation approval, implementation-ready, runtime execution permission으로 해석하지 않는다.
- caution wording:
  - `coordination`, `workspace action request`, `temporary focus`, `foreground synchronization`, `route alias`, `snapshot / restore`, `retarget`, `refresh`
  - caution wording은 자유롭게 사용 가능한 표현이 아니다.
  - 반드시 `reference`, `candidate`, `non-owner`, `caller-local`, `not approved`, `current owner 유지` 같은 제한 문구와 함께 사용해야 한다.
  - 제한 문구 없이 사용될 경우 authority drift 위험 표현으로 간주한다.
- forbidden wording:
  - `ExplorerWorkspace`를 runtime coordinator/controller/owner로 표현하는 문장
  - workspace canonical state, canonical state owner, single source of truth를 `ExplorerWorkspace` candidate에 부여하는 문장
  - `implementation-ready`, `approved for implementation`, `ready to wire`, `eventual execution owner`처럼 implementation approval로 읽히는 문장
  - route collapse 승인, route rewrite 승인, implementation roadmap, canonical owner migration 진행처럼 계획 또는 승인으로 읽히는 문장
  - automatic synchronization, global refresh coordinator, persisted snapshot owner, restore execution owner처럼 authority 이전 또는 execution owner를 부여하는 문장

#### 17.33.2 planning action policy

- allowed planning action:
  - current owner / authority 재기록
  - forbidden expansion 재명시
  - wording hardening
  - candidate와 authority 사이의 non-owner 관계 설명
  - authority drift detection checklist 정리
  - 위 allowed planning action도 implementation planning 진입 승인이나 runtime/UI implementation permission을 뜻하지 않는다.
- review-required planning action:
  - `medium`, `high`, `blocked` candidate를 다시 언급하는 문장 구조 조정
  - `snapshot / restore`, `route alias`, `temporary focus`, `retarget`, `refresh` 관련 reference vocabulary 보강
  - candidate 간 관계표, boundary comparison, risk note 추가
  - review-required planning action은 current owner / authority, forbidden expansion, `implementation status: not approved`를 함께 적어야 하며, 별도 승인 없이 implementation planning으로 넘어갈 수 없다.
- blocked planning action:
  - implementation roadmap 작성
  - runtime contract, runtime synchronization architecture, runtime execution model 정의
  - Provider wiring, Navigator rewiring, Repository 호출 구조 변경, persistence authority 이동을 전제로 한 계획 작성
  - route collapse 전제 문장, canonical owner migration 전제 문장, runtime coordinator/controller/owner 주체 설계
  - blocked planning action은 구현 단계뿐 아니라 문서상 계획 단계에서도 금지되는 확장이다.

#### 17.33.3 authority drift detection criteria

- `ExplorerWorkspace` 또는 candidate가 `owns`, `controls`, `executes`, `decides`, `restores`, `persists`, `synchronizes` 의미의 책임을 직접 가지는 문장은 authority drift로 본다.
- `reference`, `candidate`, `non-owner`, `caller-local`, `not approved`, `current owner 유지` 같은 제한 문구 없이 caution wording이 단독 사용되면 authority drift 위험 표현으로 본다.
- current owner / authority가 문장에서 생략되거나 `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, `HomeScreen`, Flutter `Navigator`의 현재 authority가 다른 주체로 치환되면 authority drift로 본다.
- risk level이 구현 순서, 구현 우선순위, implementation-ready, implementation permission으로 연결되면 authority drift로 본다.
- route alias가 route replacement 또는 route collapse로, snapshot이 restore execution owner 또는 persisted authority로, refresh가 global coordinator로 읽히게 되면 authority drift로 본다.

#### 17.33.4 escalation criteria

- 문장만으로 owner-preserving 의미를 유지할 수 없는 경우 escalation한다.
- `high` 또는 `blocked` candidate를 reference vocabulary 범위를 넘어 설명해야 하는 요구가 생기면 escalation한다.
- route collapse, canonical owner migration, persistence authority 이동, runtime execution model, automatic synchronization, route rewrite, restore execution owner가 언급되면 별도 승인 없이는 진행하지 않는다.
- 기존 active authority 문서 또는 Phase 6-B/C changelog 의미를 약화하거나 충돌시키는 표현이 필요해지면 escalation한다.

#### 17.33.5 implementation status

- implementation status: `not approved`
- guardrail policy는 implementation permission이 아니다.
- Provider/Repository/Navigator/persistence authority 이전은 승인되지 않았다.
- route collapse 승인 또는 implementation roadmap처럼 읽히는 표현은 금지된다.

### 17.34 Phase 7-A implementation entry boundary planning 기준

Phase 7-A는 Phase 6-D guardrail policy 이후 실제 구현으로 넘어가기 전에 implementation entry boundary를 고정하는 문서 단계다. 이번 단계는 implementation이 아니라 implementation entry boundary planning이며, 첫 구현 단위를 확정하는 단계도 아니다. 이 문서화만으로 후속 feature 브랜치 생성, runtime/UI 구현 시작, implementation permission이 자동 승인되지 않는다.

`ExplorerWorkspace`는 여전히 runtime coordinator, runtime controller, runtime owner가 아니며 workspace-level semantic reference label로만 유지한다. Provider/Repository/Navigator/persistence authority와 기존 production route 기본값도 그대로 유지한다. Phase 6에서 정리한 coordination candidate는 implementation permission이 아니며, implementation-ready 판단 근거로도 사용하지 않는다.

#### 17.34.1 목적

- Phase 7에서 허용 가능한 첫 구현 단위가 만족해야 할 진입 조건만 고정한다.
- 첫 구현 단위 자체를 이번 단계에서 선택하거나 확정하지 않는다.
- docs 브랜치 문서 작업과 runtime implementation 시작 사이의 경계를 분리한다.
- implementation entry checklist와 verification expectation을 미리 문서화해 boundary drift를 방지한다.

#### 17.34.2 명시적 비승인 경계

- runtime/UI 구현은 이번 단계에서 금지한다.
- route collapse는 이번 단계에서 금지한다.
- canonical owner migration은 이번 단계에서 금지한다.
- Provider/Repository/Navigator/persistence authority 이전은 이번 단계에서 금지한다.
- coordination candidate를 implementation permission, implementation-ready, automatic next step으로 해석하는 것은 금지한다.
- docs 브랜치에서의 Phase 7-A 문서화는 후속 feature 브랜치 또는 runtime wiring을 자동 승인하지 않는다.

#### 17.34.3 Phase 7에서 허용 가능한 첫 구현 단위의 조건

- 별도 사용자 승인 이후에만 feature 브랜치로 분리할 수 있다.
- 구현 단위는 하나의 명확한 목적과 좁은 범위를 가져야 하며, 여러 coordination candidate를 한 번에 묶지 않는다.
- 구현 제안에는 current owner / authority 유지 대상과 forbidden expansion을 함께 적어야 한다.
- 구현 단위는 route collapse, canonical owner migration, Provider/Repository/Navigator/persistence authority 이전 없이 설명 가능해야 한다.
- 구현 단위는 `ExplorerWorkspace`를 execution owner, synchronization owner, persistence owner로 승격하지 않아야 한다.
- 명령어 기반 검증 항목과, runtime/UI 변경이 발생하는 경우 클라이언트 UI 확인 기준을 분리해 제시해야 한다.
- 첫 구현 단위는 이번 문서 단계에서 확정하지 않으며, 위 조건 충족 여부만 후속 진입 심사 기준으로 사용한다.

#### 17.34.4 아직 금지해야 할 구현 유형

- `ExplorerWorkspace`를 runtime coordinator/controller/owner로 전제하는 구현
- Provider wiring 변경, Repository 호출 경계 재배치, Navigator rewiring, persistence authority 이동
- route alias를 route replacement나 route collapse로 확장하는 구현
- canonical workspace state owner, global refresh coordinator, automatic synchronization owner를 도입하는 구현
- snapshot / restore를 persisted execution owner 또는 restore authority로 확장하는 구현
- current production route 기본값, `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, Flutter `Navigator`의 현재 authority를 치환하는 구현

#### 17.34.5 docs 브랜치에서 feature 브랜치로 전환 가능한 기준

- Phase 7-A 문서 변경이 커밋되어 review 가능한 boundary 기준으로 고정되어 있어야 한다.
- 사용자가 implementation 시작과 feature 브랜치 생성을 별도로 승인해야 한다.
- 첫 구현 단위 제안에 대상 파일, 변경 목적, current owner / authority 유지 방식, forbidden expansion이 명시되어야 한다.
- 제안이 route collapse, canonical owner migration, authority 이전 없이 성립함을 문서로 재확인해야 한다.
- 명령어 기반 검증 항목이 준비되어 있어야 하고, runtime/UI 변경이 있으면 클라이언트 UI 확인 기준도 분리되어 있어야 한다.
- 위 기준이 충족되기 전에는 docs 브랜치 커밋만으로 feature 브랜치로 넘어갈 수 없다.

#### 17.34.6 implementation entry checklist

- Phase 7-A 문서 경계가 최신 기준으로 반영되어 있는가
- 첫 구현 단위가 하나의 좁은 목적만 다루는가
- current owner / authority 유지 대상이 명시되어 있는가
- forbidden expansion과 non-goal이 함께 적혀 있는가
- route collapse, canonical owner migration, Provider/Repository/Navigator/persistence authority 이전이 범위에 포함되지 않는가
- coordination candidate를 implementation permission으로 해석하지 않았는가
- 수정 대상 파일과 변경 위치가 사전에 제시되었는가
- Codex 명령어 기반 검증 항목이 준비되었는가
- runtime/UI 변경 시 클라이언트 UI 확인 기준이 별도 섹션으로 준비되었는가
- 별도 사용자 승인 없이 feature 브랜치 생성이나 구현 시작으로 넘어가지 않는가

#### 17.34.7 Codex 명령어 기반 검증 항목

- `git diff --check`
- `git diff --stat`
- `git status --short --branch`
- `git diff --name-only`
- `rg -n "Phase 7-A|implementation entry boundary planning|runtime/UI 구현|route collapse|canonical owner migration|Provider/Repository/Navigator/persistence authority|implementation permission" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md`
- 위 항목은 boundary 문서화와 변경 파일 범위 검증을 위한 command baseline이며, 후속 feature 브랜치 구현 검증은 해당 구현 범위에 맞는 별도 명령어 기반 테스트를 추가해야 한다.

#### 17.34.8 클라이언트 UI 기반 확인 기준

- 이번 Phase 7-A는 UI 기반 확인 수행 대상이 아니다.
- Codex는 이번 단계에서 UI 테스트를 수행했다고 보고하지 않는다.
- 후속 feature 브랜치에서 runtime/UI 동작 변경이 발생하는 경우에만 클라이언트 확인 절차를 별도로 작성한다.
- 그 절차에는 테스트 목적, 시작 화면, 조작 순서, 입력할 테스트 데이터, 기대되는 화면 변화, 실패 시 확인할 증상, 테스트 완료 판단 기준이 포함되어야 한다.
- 구체적 UI 확인 시나리오는 첫 구현 단위가 승인된 후 해당 feature 브랜치 제안서에서 확정한다.

#### 17.34.9 implementation status

- implementation status: `not approved`
- Phase 7-A 문서화는 feature 브랜치 생성 승인이나 runtime/UI implementation permission이 아니다.
- 첫 구현 단위는 아직 선택되지 않았으며, 진입 조건과 금지선만 고정된 상태다.

### 17.35 Phase 7-B first implementation unit candidate selection 기준

Phase 7-B는 실제 구현 단계가 아니라, current code 기준으로 첫 구현 단위 후보를 조사하고 비교한 뒤 추천 후보를 문서화하는 단계다. 이 단계는 feature 브랜치 생성, runtime/UI 구현 시작, implementation permission을 자동 승인하지 않는다. Phase 7-A에서 고정한 runtime/UI 구현 금지, route collapse 금지, canonical owner migration 금지, Provider/Repository/Navigator/persistence authority 이전 금지 경계도 그대로 유지한다.

#### 17.35.1 조사 기준

- ExplorerWorkspace 관련 파일의 현재 역할, production route 연결 여부, preview/hidden/wrapper 성격, owner 침범 여부를 확인한다.
- production route / Navigator 관련 파일의 current entry, route 기본값, screen 간 `Navigator.push` 경로를 확인한다.
- Provider / Repository / persistence authority 관련 파일과 current owner / authority 위치를 실제 코드 기준으로 확인한다.
- 조사 결과를 바탕으로 첫 구현 후보를 비교하되, recommendation을 implementation approval로 해석하지 않는다.

#### 17.35.2 current owner / authority 조사 결과

- ExplorerWorkspace 계열 파일은 현재 production route에 연결되지 않았고 production owner를 침범하지 않는다.
- production route authority는 여전히 `main.dart`, `HomeScreen`, 기존 screen들의 `Navigator.push` 경로에 있다.
- 실제 Provider 계층은 현재 부재한다.
- search state owner는 `HomeScreen`이다.
- explorer split-view의 selected/center/detail/history owner는 `WordExplorerScreen`이다.
- graph state owner는 `WordGraphScreen`이다.
- detail route owner는 `WordDetailScreen`이다.
- persistence read/write의 주 경로는 `WordRepository`다.
- word create/update/delete command wrapper는 `WordWriteService`다.
- DB bootstrap/reset은 `HomeScreen`에서 `DatabaseService`를 직접 호출하는 예외가 있다.
- ExplorerWorkspace 계열은 repository, `DatabaseService`, `Navigator`를 직접 소유하지 않는다.

#### 17.35.3 first implementation unit 후보 비교

- 후보 A: `WordExplorer -> ExplorerWorkspaceState` 읽기 전용 projection adapter
  - 장점: current owner를 유지한 채 `WordExplorerScreen`의 state를 one-way projection으로만 정리할 수 있어 범위가 가장 좁다.
  - 위험: projection이 source of truth처럼 오해되면 shadow owner로 해석될 위험이 있다.
  - UI 확인 필요 여부: 원칙적으로 불필요하다. runtime/UI diff가 없어야 한다.
  - authority crossing 위험: 낮다.
- 후보 B: `WordExplorerScreen panel composition 추출`
  - 장점: 후속 composition 준비도를 높이고 split-view 구조를 더 명시적으로 분리할 수 있다.
  - 위험: production widget tree를 직접 건드리므로 regression 면적이 커진다.
  - UI 확인 필요 여부: 필요하다.
  - authority crossing 위험: 낮지만 production UI drift 위험은 후보 A보다 높다.
- 후보 C: `WordGraphScreen embedded boundary 명시화`
  - 장점: embedded callback 경계와 standalone self-navigation 경계를 실제 runtime 경로에서 직접 정리할 수 있다.
  - 위험: graph standalone navigation과 callback 분기 구조를 건드리므로 route/Navigator drift 위험이 상대적으로 크다.
  - UI 확인 필요 여부: 필요하다.
  - authority crossing 위험: 중간이다.

#### 17.35.4 추천 후보

- 추천 후보는 `WordExplorer -> ExplorerWorkspaceState` 읽기 전용 projection adapter다.
- 이 추천은 implementation approval이 아니며, 후속 feature 브랜치 생성 승인이나 runtime/UI 구현 승인도 아니다.
- 후보 A의 핵심은 `WordExplorerScreen`의 현재 owner state를 one-way projection으로 `ExplorerWorkspaceState`에 투영하는 것이다.
- source of truth는 계속 `WordExplorerScreen`에 남아 있어야 한다.
- `ExplorerWorkspace`는 projection consumer일 뿐 runtime owner가 아니다.

#### 17.35.5 후보 A의 forbidden expansion

- production mount 금지
- route collapse 금지
- callback mutation API 추가 금지
- Navigator rewiring 금지
- Repository / DB import 금지
- Provider 도입 금지
- canonical owner migration 금지
- `ExplorerWorkspace`를 execution owner, synchronization owner, persistence owner로 승격 금지

#### 17.35.6 feature 브랜치 전환 전 조건

- 사용자의 별도 승인 필요
- 대상 파일을 `WordExplorerScreen`, projection helper, 필요 시 test로 좁게 고정
- `main.dart`, `HomeScreen`, `WordGraphScreen` standalone navigation, `WordDetailScreen`, `WordRepository`, `DatabaseService`는 첫 구현 범위에서 제외
- 명령어 기반 검증 계획 확정
- 최소 `dart analyze`와 source-level/unit test 기준 제시
- runtime/UI diff가 생기지 않는 구현으로 제한
- UI diff가 생긴다면 feature 전환 전에 클라이언트 UI 확인 기준을 별도 문서화

#### 17.35.7 implementation status

- implementation status: `not approved`
- feature branch status: `not approved`
- recommended first candidate: `WordExplorer -> ExplorerWorkspaceState read-only projection adapter`
- 추천 후보는 후속 검토 대상이지 구현 승인 사항이 아니다.

### 17.36 Phase 7-C Candidate A feature implementation entry plan 기준

Phase 7-C는 실제 구현 단계가 아니라, 후보 A를 후속 feature 브랜치로 넘기기 전에 feature 구현 진입 계획을 문서로 고정하는 단계다. 이 단계는 feature 브랜치 생성, runtime/UI 구현 시작, route collapse, canonical owner migration, Provider/Repository/Navigator/persistence authority 이전을 자동 승인하지 않는다. Phase 7-A와 Phase 7-B에서 고정한 금지선도 그대로 유지한다.

#### 17.36.1 후보 A의 목적

- 후보 A의 목적은 `WordExplorerScreen`의 현재 owner state를 one-way read-only projection으로 `ExplorerWorkspaceState`에 투영하는 adapter 진입 범위를 고정하는 것이다.
- source of truth는 계속 `WordExplorerScreen`에 남아 있어야 한다.
- `ExplorerWorkspace`는 projection consumer일 뿐 runtime owner가 아니다.
- 목표는 runtime/UI diff가 없는 feature 진입 범위를 문서로 좁히는 것이다.

#### 17.36.2 projection adapter의 허용 책임

- 현재 `WordExplorerScreen`이 이미 소유한 state를 읽기 전용 값으로 변환한다.
- `ExplorerWorkspaceState` 생성에 필요한 최소 projection만 수행한다.
- current owner가 이미 가진 값을 semantic projection으로 정리하되, 추가 owner를 만들지 않는다.
- mutation, navigation, persistence, fetch, refresh, synchronization을 수행하지 않는다.
- callback owner나 command owner가 되지 않는다.
- UI mount를 수행하지 않는다.

#### 17.36.3 projection adapter의 금지 책임

- selected/center/detail/history state의 source of truth가 되지 않는다.
- `ExplorerWorkspace`를 runtime coordinator, controller, owner로 승격하지 않는다.
- repository 또는 DB 접근을 수행하지 않는다.
- `Navigator` 호출을 수행하지 않는다.
- Provider를 도입하지 않는다.
- production route를 연결하지 않는다.
- route collapse를 수행하지 않는다.
- callback mutation API를 추가하지 않는다.
- persistence write/read trigger를 추가하지 않는다.
- graph/detail/search owner를 이전하지 않는다.

#### 17.36.4 future feature 브랜치에서 허용 가능한 예상 수정 범위

- `lib/ui/word_explorer_screen.dart`
- `lib/ui/explorer_workspace/` 하위 projection helper 신규 파일 1개
- 필요 시 source-level/unit test 1개
- 단, Phase 7-C에서는 위 파일들을 수정하지 않는다.

#### 17.36.5 future feature 브랜치에서 제외해야 할 파일

- `lib/main.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_graph_screen.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/data/repositories/word_repository.dart`
- `lib/domain/word/word_write_service.dart`
- `lib/database/database_service.dart`
- DB 파일
- route / Navigator / persistence 관련 파일

#### 17.36.6 `ExplorerWorkspaceState` projection 범위

- current code 기준 `ExplorerWorkspaceState`의 현재 contract field는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`이다.
- 따라서 current contract 기준 projection 가능 필드 범위는 위 다섯 필드로 한정해 기록한다.
- 다만 후보 A의 adapter는 `WordExplorerScreen`이 이미 소유한 값만 read-only projection 대상으로 삼아야 하며, 존재하지 않는 owner state나 추측 기반 필드를 새로 만들면 안 된다.
- `selectedWordId`와 `graphCenterWordId`는 현재 `WordExplorerScreen` owner state에 대응하는 값으로만 다룬다.
- `detailTargetWordId`는 현재 `WordExplorerScreen`이 이미 관리하는 detail 대상 의미 범위 안에서만 다루며, 별도 detail owner를 추가하지 않는다.
- `layoutPreset`과 `origin`은 current contract field라는 사실까지만 고정하며, 새로운 runtime policy state, synchronization state, authority state로 확장하지 않는다.

#### 17.36.7 forbidden expansion

- production mount 금지
- route collapse 금지
- Navigator rewiring 금지
- Repository / DB import 금지
- Provider 도입 금지
- canonical owner migration 금지
- callback mutation API 추가 금지
- runtime/UI diff를 유발하는 구조 확장 금지
- `ExplorerWorkspace`를 runtime execution owner, synchronization owner, persistence owner로 승격 금지

#### 17.36.8 feature 브랜치 전환 전 조건

- 사용자의 별도 승인 필요
- feature 브랜치명이 확정되어야 한다.
- 수정 대상 파일과 수정 금지 파일이 확정되어야 한다.
- projection adapter 책임이 read-only projection으로 제한되어야 한다.
- forbidden expansion이 명시되어야 한다.
- 명령어 기반 검증 계획이 확정되어야 한다.
- runtime/UI diff 없음이 목표로 고정되어야 한다.

#### 17.36.9 명령어 기반 검증 계획

- 후속 feature 브랜치에서 최소 `dart analyze`를 수행한다.
- 가능하면 projection helper에 대한 source-level/unit test를 추가한다.
- `git diff --name-only`로 허용 파일 외 수정 여부를 확인한다.
- `rg`로 projection helper에 `Navigator`, Repository, `DatabaseService`, Provider import가 생기지 않았는지 확인한다.
- 코드 diff 기준으로 runtime/UI diff가 의도치 않게 생기지 않았는지 검토한다.

#### 17.36.10 UI 확인 기준

- Phase 7-C 자체는 UI 확인 수행 대상이 아니다.
- 후속 feature 브랜치에서도 runtime/UI diff가 없도록 제한하는 것이 목표다.
- 만약 UI diff가 발생한다면 feature 구현 범위 재검토 대상으로 보고하고, 클라이언트 UI 확인 기준을 별도 문서화해야 한다.
- Codex는 UI 테스트를 수행했다고 보고하지 않는다.

#### 17.36.11 후속 feature 브랜치명 제안

- recommended next feature branch: `feature/explorer-workspace-phase7d-readonly-projection-adapter`
- 위 이름은 제안일 뿐이며 생성 승인이나 implementation approval이 아니다.

#### 17.36.12 implementation status

- implementation status: `not approved`
- feature branch status: `not approved`
- recommended next feature branch: `feature/explorer-workspace-phase7d-readonly-projection-adapter`
- Phase 7-C 문서화는 후보 A 구현 승인이나 feature 브랜치 생성 승인이 아니다.

### 17.37 Phase 7-D read-only projection adapter implementation

Phase 7-D는 Phase 7-C에서 고정한 후보 A 범위 안에서 `WordExplorerScreen -> ExplorerWorkspaceState` 읽기 전용 projection adapter를 실제 코드로 추가한 단계다. 이번 단계의 목적은 production wiring이나 owner migration이 아니라, current owner가 이미 가진 값을 `ExplorerWorkspaceState` contract로 옮기는 최소 helper 경계를 구현하고 검증하는 데 있다.

- source of truth는 계속 `WordExplorerScreen`에 남아 있다.
- `ExplorerWorkspace`는 runtime owner가 아니며 projection consumer로만 유지한다.
- adapter는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`을 명시적 입력으로 받아 read-only projection만 수행한다.
- `detailTargetWordId`는 helper 내부에서 `selectedWordId`로 자동 추론하지 않는다. current owner가 제공한 detail target 의미 값을 그대로 projection한다.
- `layoutPreset`, `origin`은 adapter 호출 인자로만 취급하며 runtime policy state, synchronization state, authority state로 확장하지 않는다.
- production mount, route collapse, Navigator rewiring, Repository/DB import, Provider 도입, callback mutation API, persistence trigger 추가는 수행하지 않는다.
- 이번 단계의 목표는 runtime/UI diff 없음이며, UI 테스트는 Codex 수행 대상이 아니다.

### 17.38 Phase 7-E projection adapter integration boundary planning

Phase 7-E는 Phase 7-D에서 추가한 read-only projection adapter를 향후 `WordExplorerScreen`에 연결할 수 있는지 실제 코드 기준으로 조사하고, 안전한 연결 경계를 proposal로 정리하는 단계다. 이번 단계는 구현 단계가 아니며 `WordExplorerScreen` 수정 승인, feature 브랜치 생성 승인, runtime/UI 구현 승인으로 간주하지 않는다. Phase 7-A~7-D에서 고정한 runtime/UI 구현 금지, route collapse 금지, canonical owner migration 금지, Provider/Repository/Navigator/persistence authority 이전 금지 경계를 그대로 유지한다.

#### 17.38.1 current owner state 조사 결과

- `_centerWordId`는 현재 `WordExplorerScreen` 내부 graph center source of truth다.
- `_selectedWordId`와 `_selectedWordDisplayItem`이 현재 선택/상세 상태를 구성한다.
- detail panel 렌더는 `_selectedWordDisplayItem` 존재 여부에 의해 결정된다.
- detail route 진입은 `_selectedWordId`와 `_selectedWordDisplayItem` 둘 다 필요하다.
- `_history`는 `centerWordId`와 `selectedWordId`를 payload에 저장하지만 `_applyHistoryEntry()`는 selection/detail을 복원하지 않고 null로 비운다.
- current code 기준 projection 입력 출처는 다음이 가장 가깝다.
  - `graphCenterWordId <- _centerWordId`
  - `selectedWordId <- _selectedWordId`
  - `detailTargetWordId <- (_selectedWordDisplayItem != null ? _selectedWordId : null)`
- 위 mapping은 후속 feature 구현 전 검토 기준이지 구현 승인 사항은 아니다.

#### 17.38.2 build / callback / setState 경계 조사 결과

- split-view build는 `WordExplorerScreen`의 `Row` 경계에 있다.
- `WordGraphScreen`은 split-view 내부에 embed되어 있다.
- detail panel은 `_buildDetailPanel()` 경계에서 렌더된다.
- graph node selection은 `_selectWord(...)`로 연결된다.
- center 변경은 `_selectWord(..., changeCenterWord: true)`로 연결된다.
- clear는 `_clearSelectedWordPanel()`로 연결된다.
- detail navigation은 `_openEditSelectedWord()`와 `_openSelectedWordDetail()`로 연결된다.
- 현재 `setState` 경로는 current owner state를 직접 갱신하는 mutation 영역이므로 adapter 호출은 mutation 메서드 내부보다 read-only projection method 또는 build 경계의 파생값으로 제한하는 편이 안전하다.

#### 17.38.3 adapter 연결 후보 비교

- 후보 A: `build` 내부 local final projection
  - 장점: 삽입 위치가 단순하고 추가 owner를 만들지 않는다.
  - 위험: dead local code가 되기 쉽고 `layoutPreset` / `origin` 임시값을 build에서 즉석 합성하게 된다.
  - runtime/UI diff 가능성: UI에 연결하지 않으면 없음.
  - owner migration 위험: 낮음.
  - UI 확인 필요 여부: 현재 단계에서는 없음.
- 후보 B: private getter 또는 private method로 projection 생성만 제공
  - 장점: read-only projection 생성 경계를 한 점으로 고정하고 empty guard, detail target 규칙을 한 곳에 모을 수 있다.
  - 위험: `layoutPreset` / `origin` 임시값 정책은 별도 합의가 필요하다.
  - runtime/UI diff 가능성: visual consumer에 연결하지 않으면 없음.
  - owner migration 위험: 가장 낮음.
  - UI 확인 필요 여부: 현재 단계에서는 없음.
- 후보 C: `ExplorerWorkspace` shell 또는 preview contract 연결
  - 장점: 최종 shell 방향과 contract 사용성을 일찍 점검할 수 있다.
  - 위험: production mount, visual consumer 연결, shadow owner 해석으로 확장될 위험이 크다.
  - runtime/UI diff 가능성: 높음.
  - owner migration 위험: 높음.
  - UI 확인 필요 여부: 필요할 가능성이 높다.

#### 17.38.4 추천 후보

- 추천 후보는 후보 B `private getter or private method read-only projection`이다.
- 이 추천은 implementation approval이 아니며 feature 브랜치 생성 승인도 아니다.
- 후보 B의 핵심은 `WordExplorerScreen` 내부에 read-only projection 생성 경계를 두되, 그 결과를 field/history/source of truth로 저장하지 않는 것이다.
- projection result는 owner state가 아니라 derived snapshot으로만 취급해야 한다.

#### 17.38.5 후보 B의 forbidden expansion

- `ExplorerWorkspaceState`를 field에 저장 금지
- history payload 또는 source of truth로 저장 금지
- 추가 `setState` 금지
- production mount 금지
- route collapse 금지
- Navigator rewiring 금지
- Repository / DB import 금지
- Provider 도입 금지
- persistence trigger 추가 금지
- graph/detail/search owner 이전 금지
- `ExplorerWorkspace` runtime owner 승격 금지
- visual consumer 연결 금지
- shell mount 금지

#### 17.38.6 unresolved / precondition

- `layoutPreset` / `origin` 임시값 정책은 후속 feature 구현 전에 별도 합의가 필요하다.
- `_centerWordId.trim().isEmpty` guard 필요 여부를 후속 feature 구현 전에 명시해야 한다.
- `detailTargetWordId`는 `_selectedWordDisplayItem != null`일 때만 `_selectedWordId`를 반영하는 방향이 current code 기준 가장 보수적이지만, 이것도 후속 feature 구현 전 검토 기준으로만 기록한다.
- 위 항목들은 구현 확정이 아니라 feature 전환 전 조건이다.

#### 17.38.7 후속 feature 브랜치 전환 전 조건

- 사용자의 별도 승인 필요
- `WordExplorerScreen` 수정 범위를 private projection method와 필요 시 단일 read-only 호출 지점으로 제한
- adapter 호출이 read-only projection으로만 제한됨
- projection result를 field/history/source of truth로 저장하지 않음
- 추가 `setState` 없음
- runtime/UI diff 없음
- Navigator / route / Repository / DB / Provider 영향 없음
- 명령어 기반 검증 계획 확정
- UI 확인 필요 여부 분리

#### 17.38.8 후속 feature 브랜치명 제안

- 예시 제안: `feature/explorer-workspace-phase7f-wordexplorer-projection-boundary`
- 위 이름은 제안일 뿐이며 생성 승인 아님

#### 17.38.9 implementation status

- implementation status: `not approved`
- feature branch status: `not approved`
- recommended integration candidate: `private getter or private method read-only projection`
- Phase 7-E 문서화는 `WordExplorerScreen` 수정 승인이나 adapter 연결 구현 승인이 아니다.

### 17.39 Phase 7-F WordExplorer read-only projection boundary implementation

Phase 7-F는 Phase 7-E에서 정리한 integration boundary를 실제 `WordExplorerScreen` 내부에 caller-local read-only projection 형태로 추가한 구현 단계다. 이번 단계의 목적은 current owner state를 `ExplorerWorkspaceState` derived snapshot으로만 투영하는 경계를 고정하는 것이며, production mount, route collapse, owner migration, visual consumer 연결은 포함하지 않는다.

- source of truth는 계속 `WordExplorerScreen`에 남아 있다.
- `ExplorerWorkspace`는 runtime owner가 아니며, 이번 단계에서도 production mount되지 않는다.
- projection 결과는 field/history/source of truth/runtime policy state로 저장하지 않는다.
- 목표는 runtime/UI diff 없이 projection boundary만 추가하는 것이다.

#### 17.39.1 구현 범위

- `lib/ui/word_explorer_screen.dart`
  - private helper `_normalizeReadOnlyProjectionWordId(...)`
  - private getter `_readOnlyWorkspaceProjection`
  - `build()` 시작부 local final + debug assert
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
  - source-level boundary 검증
- `docs/logs/CHANGELOG.md`
  - 단계 기록 추가

#### 17.39.2 projection 입력 경계

- `graphCenterWordId <- _centerWordId`
- `selectedWordId <- _selectedWordId`
- `detailTargetWordId <- (_selectedWordDisplayItem != null ? normalizedSelectedWordId : null)`
- `_centerWordId.trim().isEmpty`이면 projection을 생성하지 않는다.
- `_selectedWordId`가 null이 아니어도 trim 결과가 empty이면 adapter로 전달하지 않는다.
- current owner가 detail payload를 가진 경우에만 selected id를 detail target projection input으로 전달한다.

#### 17.39.3 metadata 고정값

- `layoutPreset: ExplorerWorkspaceLayoutPreset.balanced`
- `origin: ExplorerWorkspaceTransitionOrigin.routeAlias`

위 두 값은 이번 단계에서 projection 호출 인자로만 사용되는 임시 metadata다. layout policy state, synchronization state, authority state로 확장하지 않는다.

#### 17.39.4 금지 확장 미적용 확인

- `ExplorerWorkspaceState` field 저장 없음
- `_history` payload 저장 없음
- 추가 `setState` 없음
- UI prop / widget tree 연결 없음
- `ExplorerWorkspace` shell mount / production mount 없음
- route collapse / Navigator rewiring 없음
- Repository / DB / Provider authority 추가 없음
- graph/detail/search owner 이전 없음

#### 17.39.5 검증 관점

- source-level test는 private projection getter 존재, blank guard, detail payload gating, field/history 비저장, non-visual boundary 유지를 고정한다.
- 명령어 기반 검증은 `dart analyze`, 관련 test, `git diff --check`, forbidden pattern grep, `git status`로 분리해 수행한다.
- UI 테스트는 이번 단계에서 Codex 수행 대상이 아니며, runtime/UI diff가 없는 구현으로 제한한다.

### 17.40 Phase 7-G projection consumer boundary planning 기준

Phase 7-G는 구현 단계가 아니라 Phase 7-F에서 추가된 read-only projection result를 실제 어디에서 소비할 수 있는지 조사하고, 어떤 consumer 경계가 가장 안전한지 proposal로 정리하는 계획 단계다. 이번 단계는 feature 브랜치 생성 승인, visual consumer 구현 승인, `ExplorerWorkspace` shell mount 승인, runtime/UI 구현 승인으로 해석하지 않는다. Phase 7-A~7-F에서 고정한 금지선도 계속 유지한다.

#### 17.40.1 현재 projection boundary 상태

- `_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 private getter다.
- projection result는 `build()` 시작부 local final과 debug `assert`에서만 참조된다.
- projection result는 field, history payload, source of truth, runtime policy state로 저장되지 않는다.
- projection result는 UI prop, widget tree, route, `Navigator`, repository 호출, persistence 호출에 연결되지 않는다.
- 현재 visual consumer도 없고 authority consumer도 없다.
- 현재 유일한 소비는 build-local derived read와 assert invariant 검증이다.

#### 17.40.2 ExplorerWorkspace shell / preview / contract 현황

- `ExplorerWorkspaceState`는 typed projection contract로만 유지한다.
- `ExplorerWorkspace` shell은 stateless placeholder다.
- preview screen은 `ExplorerWorkspaceState.fromPreviewInput(input) -> ExplorerWorkspace(state: state)` passive wrapper다.
- preview interaction host는 preview-local `_state`와 `setState`를 가진 preview-local owner다.
- production entry는 계속 `main.dart -> HomeScreen`이다.
- 실제 explorer 진입은 계속 `HomeScreen -> Navigator.push -> WordExplorerScreen`이다.

#### 17.40.3 projection consumer 후보 비교

- 후보 A `no consumer 유지`
  - 장점: 가장 보수적이며 runtime/UI diff가 없다.
  - 위험: projection result가 실제 downstream shape과 얼마나 맞는지 exercise 범위가 작다.
  - owner migration 위험: 매우 낮다.
  - UI 확인 필요 여부: 없다.

- 후보 B `debug/assert-only consumer 유지`
  - 장점: 실제 `WordExplorerScreen` owner 상태에서 projection result를 계속 계산해 보면서도 visual mount, route 변화, shadow owner 도입을 피한다.
  - 위험: visual consumer 적합성은 여전히 검증하지 못한다.
  - runtime/UI diff 가능성: visible UI diff는 없고 build-local 계산만 추가된다.
  - owner migration 위험: 낮다.
  - UI 확인 필요 여부: 없다.

- 후보 C `ExplorerWorkspace` shell 또는 preview contract에 visual consumer로 전달
  - 장점: visual subtree 기준으로 projection shape를 직접 확인할 수 있다.
  - 위험: production widget tree 변경이 필요하고 runtime/UI diff가 필수이며, preview host의 `_state` / `setState` 때문에 owner migration 또는 shadow owner처럼 읽힐 위험이 크다.
  - runtime/UI diff 가능성: 높다.
  - owner migration 위험: 높다.
  - UI 확인 필요 여부: 있다.

- 후보 D `test-only 또는 non-visual diagnostic consumer`
  - 장점: production mount 없이 projection compatibility를 조금 더 검증할 수 있다.
  - 위험: 실제 production visual consumer 연결 증거는 제공하지 못한다.
  - runtime/UI diff 가능성: 없다.
  - owner migration 위험: 낮다.
  - UI 확인 필요 여부: 없다.

#### 17.40.4 추천 consumer 경계

- 추천 후보: `debug/assert-only consumer`
- 이 추천은 implementation approval이 아니다.
- 이 추천은 feature 브랜치 생성 승인도 아니다.
- 후보 B는 실제 `WordExplorerScreen` owner 상태에서 projection result를 계산해 보면서도 visual mount, route 변화, shadow owner 도입을 피하는 가장 보수적인 소비 경계다.
- projection result는 계속 ephemeral derived value로만 취급해야 한다.

#### 17.40.5 후보 C 보류 이유

- production widget tree 변경이 필수다.
- runtime/UI diff가 필수다.
- preview host의 `_state` / `setState` 때문에 owner migration 또는 shadow owner처럼 읽힐 위험이 크다.
- shell direct mount도 visual consumer 연결이므로 클라이언트 UI 확인이 필요하다.
- production mount, placeholder UI diff, shadow owner 위험이 크므로 현 단계에서는 비추천으로 유지한다.

#### 17.40.6 후속 feature 브랜치 전환 전 조건

- 사용자의 별도 승인 필요
- visual consumer가 정말 필요한지 먼저 승인되어야 한다.
- visual consumer가 필요하면 production mount 자체를 UI diff가 있는 기능 변경으로 취급해야 한다.
- `ExplorerWorkspace`가 canonical owner가 아니라는 문구와 테스트를 먼저 설계해야 한다.
- preview host는 production 후보에서 제외해야 한다.
- 추가 `setState` 필요 여부를 먼저 확인해야 한다.
- route / `Navigator` 영향 여부를 먼저 확인해야 한다.
- Repository / DB / Provider 영향 여부를 먼저 확인해야 한다.
- 명령어 기반 검증 시나리오를 먼저 확정해야 한다.
- 클라이언트 UI 확인 절차를 먼저 확정해야 한다.
- Flutter 테스트 실행 환경 정상화 필요성을 기록하고 해소해야 한다.

#### 17.40.7 runtime/UI diff와 UI 확인 기준

- 후보 B는 visible UI diff가 없고 클라이언트 UI 확인이 필요 없다.
- 후보 C 계열로 넘어가면 runtime/UI diff가 발생한다고 보고, 클라이언트 UI 확인을 필수로 본다.
- Codex는 수행하지 않은 UI 테스트를 수행했다고 보고하지 않는다.

#### 17.40.8 implementation status

- implementation status: `not approved`
- feature branch status: `not approved`
- recommended consumer boundary: `debug/assert-only consumer`
- visual consumer status: `not approved`
- shell mount status: `not approved`
- Phase 7-G 문서화는 projection consumer 구현 승인이나 `ExplorerWorkspace` shell mount 승인이 아니다.

### 17.41 Phase 7-H projection chain stabilization audit

Phase 7-H는 Phase 7-A~7-G에서 정리·구현된 projection chain을 닫을 수 있는지 확인한 closure / stabilization audit 단계다. 이번 단계는 구현 단계가 아니며 runtime/UI 구현 승인, visual consumer 승인, `ExplorerWorkspace` shell mount 승인, feature 브랜치 생성 승인이 아니다.

#### 17.41.1 audit 결과 요약

- Phase 7-A~7-G 문서 흐름은 implementation planning, 제한 구현, consumer boundary planning 순서와 모순 없이 일치한다.
- `WordExplorerWorkspaceProjectionAdapter`는 read-only helper로 유지되며 `Navigator`, Repository, `DatabaseService`, Provider 계층을 import하지 않는다.
- `WordExplorerScreen`의 projection boundary는 private getter `_readOnlyWorkspaceProjection`으로 유지된다.
- projection result는 field, history payload, source of truth, runtime policy state로 저장되지 않는다.
- consumer는 `build()` 내부 local read와 debug `assert` invariant 검증으로만 유지된다.
- visual consumer는 없다.
- `ExplorerWorkspace` shell mount는 없다.
- production entry는 계속 `main.dart -> HomeScreen`이다.
- explorer 진입은 계속 `HomeScreen -> Navigator.push -> WordExplorerScreen`이다.
- owner boundary 침범은 확인되지 않았다.
- runtime/UI diff는 확인되지 않았다.

#### 17.41.2 테스트 / 검증 결과

- Phase 7 직접 경계 파일 기준 `dart analyze`는 통과했다.
- 관련 Flutter test 12개는 sandbox 밖 실행 기준 통과했다.
- 대상 전체 `dart analyze`는 기존 `home_screen.dart` warning/info 5건으로 exit 1이며, Phase 7-H 직접 경계와 직접 관련 없다.
- `git diff --check`는 통과했다.
- sandbox 내부 Flutter test timeout과 Dart telemetry session file 접근 거부는 환경 이슈로 기록한다.

#### 17.41.3 closure 판단

Phase 7은 현재 문서, 코드, 테스트 기준에서 종료 가능 상태로 판단한다. 다만 이 판단은 visual consumer 구현이나 `ExplorerWorkspace` shell production mount를 승인하지 않는다. 두 항목은 승인된 구현이 아니며 다음 phase unresolved 항목으로 이관한다.

#### 17.41.4 다음 phase unresolved 항목

- visual consumer 필요성 별도 승인
- `ExplorerWorkspace` shell production mount 별도 승인
- production mount 시 UI diff가 있는 기능 변경으로 취급
- `ExplorerWorkspace` non-owner 문구와 테스트 설계
- Flutter 테스트 sandbox timeout / telemetry 권한 문제 해소

#### 17.41.5 implementation status

- Phase 7 status: `closable`
- visual consumer status: `not approved`
- shell mount status: `not approved`
- runtime/UI integration status: `not approved`
- visual consumer / shell mount 결정은 next phase required 항목으로 남긴다.

### 17.42 Phase 8-A visual consumer entry boundary

Phase 8은 `ExplorerWorkspace` shell을 production에 mount하는 단계가 아니다. Phase 8은 Phase 7에서 확보된 read-only projection chain을 visual consumer가 안전하게 읽을 수 있는 진입 조건을 정의하는 단계다.

Phase 8-A는 구현 단계가 아니며 runtime/UI integration, visual consumer production exposure, `ExplorerWorkspace` shell mount, route collapse, production UI diff를 승인하지 않는다. 이번 단계의 목적은 visual consumer 후보가 projection result를 읽기 전에 지켜야 할 owner boundary와 금지선을 문서로 고정하는 것이다.

#### 17.42.1 Phase 8 목적

- Phase 8은 Phase 7에서 확보한 `WordExplorerScreen -> ExplorerWorkspaceState` read-only projection chain을 유지한 채, 향후 visual consumer가 그 projection snapshot을 안전하게 읽을 수 있는 진입 조건을 정의한다.
- Phase 8은 `ExplorerWorkspace`를 production route에 연결하거나 shell을 mount하는 단계가 아니다.
- Phase 8은 canonical owner migration, Provider authority migration, Repository authority migration, Navigator authority migration, persistence authority migration을 승인하지 않는다.
- projection result는 source of truth가 아니며, field, history payload, persistence payload, runtime policy state로 저장하지 않는다.

#### 17.42.2 Phase 8-A 범위

- `visual consumer`의 의미와 authority boundary를 정의한다.
- visual consumer level을 Level 0부터 Level 3까지 구분한다.
- Level 1 또는 Level 2 후보로 진입하기 전에 필요한 조건을 정리한다.
- runtime/UI integration 미승인, `ExplorerWorkspace` shell mount 미승인, owner boundary 미이전, production UI diff 없음 기준을 유지한다.
- Phase 8-A는 문서화 단계이며 `lib/`, `test/`, platform directory, route, Provider, Repository, Navigator, DB/persistence를 수정하지 않는다.

#### 17.42.3 visual consumer 정의

`visual consumer`는 `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 읽어 화면 후보를 구성할 수 있는 non-owner view layer다. visual consumer는 repository, provider, navigator, persistence, canonical selection state에 대한 authority를 갖지 않는다.

이 정의에서 `ExplorerWorkspace` 또는 visual consumer는 `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 소비하는 non-owner view layer로만 취급한다. `ExplorerWorkspace`는 owner, controller, coordinator가 아니며 selection, navigation, repository, persistence authority를 갖지 않는다.

visual consumer는 다음을 수행하지 않는다.

- projection result를 source of truth로 사용하지 않는다.
- projection result를 persistence 대상으로 저장하지 않는다.
- projection result를 history payload로 사용하지 않는다.
- Repository, Provider, Navigator, DB/persistence를 직접 호출하지 않는다.
- `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`의 owner가 되지 않는다.

#### 17.42.4 visual consumer level 구분

| level | 이름 | 의미 | Phase 8-A 판단 |
| --- | --- | --- | --- |
| Level 0 | debug assert-only consumer | `WordExplorerScreen` 내부 build-local read와 debug assert처럼 projection snapshot을 비시각 검증에만 사용하는 consumer | 현재 Phase 7 chain의 안정화 기준으로 유지 가능 |
| Level 1 | hidden visual probe | production 노출 없이 read-only projection snapshot을 읽어 visual shape 후보를 숨김 상태로 점검하는 consumer | Phase 8-A에서 진입 조건 검토 가능 |
| Level 2 | production-adjacent visual consumer | production context와 가까운 구조에서 projection snapshot 소비 적합성을 검토하되 production visible exposure는 하지 않는 consumer | 별도 승인 전에는 구현하지 않고 진입 조건만 검토 가능 |
| Level 3 | production visible consumer | production route에서 사용자에게 보이는 visual consumer | Phase 8-A에서 승인하지 않음 |

Phase 8-A는 Level 1 또는 Level 2의 진입 조건을 검토하는 단계이며, Level 3 production visible consumer는 승인하지 않는다.

#### 17.42.5 Phase 8-A에서 허용되는 것

- read-only projection snapshot을 visual consumer가 읽기 전에 필요한 entry boundary 문서화
- visual consumer level과 각 level의 authority 제한 정리
- `ExplorerWorkspace` non-owner boundary, projection result non-source-of-truth boundary 문서화
- Level 1 또는 Level 2 후보가 후속 단계로 넘어가기 위한 조건 기록
- runtime/UI integration, shell mount, route collapse, production UI diff가 아직 승인되지 않았음을 명시

#### 17.42.6 Phase 8-A에서 금지되는 것

아래 항목은 모두 `not approved` 상태다.

- runtime/UI integration: `not approved`
- visual consumer production exposure: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- persistence authority migration: `not approved`
- projection result persistence: `not approved`
- projection result history usage: `not approved`
- projection result source-of-truth usage: `not approved`

또한 다음 표현과 구조는 금지한다.

- `ExplorerWorkspace`가 owner처럼 보이는 표현
- `ExplorerWorkspace`가 controller처럼 보이는 표현
- `ExplorerWorkspace`가 coordinator처럼 보이는 표현
- `ExplorerWorkspace`가 selection, navigation, repository, persistence authority를 갖는 표현
- visual consumer가 canonical selection state, route stack, repository read/write, persistence/history payload의 authority를 갖는 구조

허용 가능한 표현은 `ExplorerWorkspace` 또는 visual consumer가 `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 소비하는 non-owner view layer라는 범위로 제한한다.

#### 17.42.7 projection result source-of-truth boundary

- projection result는 current owner state에서 파생된 read-only snapshot이다.
- projection result는 source of truth가 아니며 source of truth처럼 사용하지 않는다.
- projection result를 persistence에 쓰지 않는다.
- projection result를 history payload로 쓰지 않는다.
- projection result를 canonical selection state로 승격하지 않는다.
- projection result를 runtime policy state, synchronization state, owner state로 저장하지 않는다.

#### 17.42.8 Phase 8-B 후보 조건

Phase 8-B로 넘어가려면 다음 조건을 먼저 만족해야 한다.

- 사용자의 별도 승인이 있어야 한다.
- 대상 level이 Level 1인지 Level 2인지 명시해야 하며, Level 3은 제외해야 한다.
- visual consumer가 read-only projection snapshot만 소비하고, Repository / Provider / Navigator / persistence / DB authority를 갖지 않는다는 검증 기준을 먼저 정해야 한다.
- `ExplorerWorkspace`가 owner, controller, coordinator가 아니라는 문구와 검증 기준을 유지해야 한다.
- projection result가 field, history payload, source of truth, persistence payload로 저장되지 않는다는 검증 기준을 먼저 정해야 한다.
- `ExplorerWorkspace` shell mount, route collapse, production visible exposure, production UI diff가 필요한 경우 Phase 8-B 후보에서 제외하고 별도 승인 단계로 분리해야 한다.
- 코드 수정이 필요한 후속 단계라면 수정 파일 범위, 명령어 기반 검증, UI 확인 필요 여부를 먼저 분리해야 한다.

#### 17.42.9 implementation status

- Phase 8-A status: `documented`
- implementation status: `not approved`
- runtime/UI integration status: `not approved`
- visual consumer production exposure status: `not approved`
- shell mount status: `not approved`
- route collapse status: `not approved`
- owner boundary migration status: `not approved`
- production UI diff status: `not approved`

### 17.43 Phase 8-B visual consumer candidate selection

Phase 8-B는 구현 단계가 아니다. Phase 8-B의 목적은 Phase 8-A에서 정의한 visual consumer entry boundary를 기준으로 첫 visual consumer 구현 후보를 문서상으로 선정하고, Phase 8-C 구현 진입 조건을 정리하는 것이다.

이번 단계에서는 실제 visual consumer를 구현하지 않는다. `ExplorerWorkspace` shell mount, route 추가, production UI 노출, runtime/UI integration, route collapse, canonical owner migration, Provider / Repository / Navigator / persistence authority migration도 수행하지 않는다.

#### 17.43.1 Phase 8-B 목적

- Phase 8-A의 visual consumer entry boundary를 기준으로 visual consumer 후보군을 비교한다.
- 첫 구현 후보를 Level 1 hidden visual probe로 제한할지 문서상으로 판단한다.
- Level 2 production-adjacent visual consumer는 비교 후보로만 다루고 후속 승인 전까지 보류한다.
- Level 3 production visible consumer는 Phase 8-B에서 승인하지 않는다.
- Phase 8-C가 구현 단계로 전환될 경우 지켜야 할 진입 조건, 허용 범위, 금지선을 정리한다.

#### 17.43.2 Phase 8-A와 Phase 8-B의 차이

| 구분 | Phase 8-A | Phase 8-B |
| --- | --- | --- |
| 목적 | visual consumer가 projection snapshot을 읽기 전에 지켜야 할 entry boundary 정의 | entry boundary를 기준으로 첫 visual consumer 후보 선정 |
| 산출물 | visual consumer 정의, level 구분, 금지선 | Candidate A/B/C 비교, Phase 8-C 후보와 진입 조건 |
| 구현 여부 | 구현 없음 | 구현 없음 |
| production route 노출 | `not approved` | `not approved` |
| runtime/UI integration | `not approved` | `not approved` |
| `ExplorerWorkspace` shell mount | `not approved` | `not approved` |
| owner boundary 이전 | `not approved` | `not approved` |

Phase 8-A는 visual consumer가 무엇을 하면 안 되는지와 어떤 level로 분류되는지를 고정했다. Phase 8-B는 그 경계를 바꾸지 않고, 후속 Phase 8-C에서 검토할 첫 구현 후보를 Level 1 hidden visual probe로 제한한다.

#### 17.43.3 visual consumer 후보군 비교

| 비교 기준 | Candidate A: Level 1 hidden visual probe | Candidate B: Level 2 production-adjacent visual consumer | Candidate C: Level 3 production visible consumer |
| --- | --- | --- | --- |
| production route 노출 여부 | 없음 | 없어야 하지만 production context 인접성 검토가 필요함 | 있음 |
| runtime/UI diff 발생 여부 | production UI diff 없음 조건으로 제한 가능 | runtime/UI diff 가능성이 있어 별도 검토 필요 | runtime/UI diff 필수 |
| `ExplorerWorkspace` shell mount 필요 여부 | 필요 없음 | 필요하지 않은 형태만 검토 가능하지만 경계가 불안정함 | shell mount 또는 production visible entry 검토가 필요해짐 |
| owner/controller/coordinator 오해 가능성 | 낮음. 단, non-owner probe 표현을 유지해야 함 | 중간. production 인접성 때문에 owner처럼 읽힐 위험이 커짐 | 높음. 사용자에게 보이는 production consumer는 authority drift 위험이 큼 |
| projection read-only boundary 유지 가능성 | 높음. `WordExplorerScreen` 내부 read-only projection snapshot 소비로 제한 가능 | 가능하지만 source-level 검증과 별도 승인 조건이 더 필요함 | 낮음. production 노출과 함께 selection/navigation authority 오해가 발생하기 쉬움 |
| rollback 용이성 | 높음. 숨김 probe 또는 source-level 검증 단위로 되돌리기 쉬움 | 중간. production 인접 구조가 생기면 rollback 범위가 넓어질 수 있음 | 낮음. production UI/route 노출을 되돌려야 함 |
| Phase 8-C 첫 구현 후보 적합성 | 적합 | 보류 | `not approved` |

#### 17.43.4 Candidate A 평가: Level 1 hidden visual probe

Candidate A는 Phase 8-C 첫 구현 후보로 적합하다.

Level 1 hidden visual probe는 production route에 노출되지 않고, `ExplorerWorkspace` shell mount를 요구하지 않으며, production UI diff를 만들지 않는 범위에서만 검토한다. hidden visual probe는 `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 소비하는 non-owner view/probe layer다.

허용 의미는 다음으로 제한한다.

- `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 비소유 방식으로 관찰한다.
- projection snapshot을 기반으로 숨김 상태의 render 후보 또는 visual shape 후보를 검증한다.
- Repository, Provider, Navigator, DB, persistence를 호출하지 않는다.
- projection result를 field, history payload, persistence payload, source of truth로 저장하지 않는다.
- `ExplorerWorkspace`를 owner, controller, coordinator로 해석하게 만드는 구조를 만들지 않는다.

이 판단은 Phase 8-B에서 실제 hidden visual probe를 구현한다는 뜻이 아니다. Phase 8-B는 Candidate A를 Phase 8-C 첫 구현 후보로 선정하는 문서 단계로만 남긴다.

#### 17.43.5 Candidate B 평가: Level 2 production-adjacent visual consumer

Candidate B는 Phase 8-B에서 보류한다.

Level 2 production-adjacent visual consumer는 production context에 가까운 구조에서 projection snapshot 소비 적합성을 검토할 수 있지만, production visible exposure는 하지 않는 후보다. 이 후보는 production widget tree 인접성 때문에 runtime/UI diff 가능성, owner/controller/coordinator 오해 가능성, rollback 범위 확대 위험을 추가로 검토해야 한다.

Phase 8-B에서는 Candidate B를 비교 후보로만 기록한다. Candidate B로 이동하려면 Level 1 hidden visual probe 결과, production UI diff 여부, owner boundary 검증 방법, 클라이언트 UI 확인 필요 여부를 별도 승인 단계에서 다시 정해야 한다.

#### 17.43.6 Candidate C 평가: Level 3 production visible consumer

Candidate C는 Phase 8-B에서 승인하지 않는다.

Level 3 production visible consumer는 production route에서 사용자에게 보이는 visual consumer다. 이 후보는 production route 노출, runtime/UI diff, route 또는 shell 연결 검토, 사용자 경험 변경을 동반한다. 또한 `ExplorerWorkspace`가 selection, navigation, repository, persistence authority를 갖는 것처럼 읽힐 위험이 높다.

따라서 Phase 8-B에서 Candidate C는 `not approved`로 유지한다. production visible consumer가 필요해지는 경우에는 Phase 8-C 후보가 아니라 별도 설계, 별도 승인, 클라이언트 UI 확인 기준을 갖는 독립 단계로 분리해야 한다.

#### 17.43.7 Phase 8-C 구현 후보 선정

Phase 8-C 후보는 Level 1 hidden visual probe implementation으로 제한한다.

Phase 8-C 후보의 의미는 다음과 같다.

- hidden visual probe는 production route에 노출되지 않는다.
- hidden visual probe는 `ExplorerWorkspace` shell mount를 요구하지 않는다.
- hidden visual probe는 `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 비소유 방식으로 관찰하거나 렌더 후보를 검증하는 수준으로 제한된다.
- hidden visual probe는 `WordExplorerScreen` current owner state를 대체하지 않는다.
- hidden visual probe는 `ExplorerWorkspace`를 owner, controller, coordinator로 승격하지 않는다.

Phase 8-B는 Phase 8-C 후보를 선정하지만, Phase 8-C 구현 자체를 승인하지 않는다. Phase 8-C 구현으로 전환하려면 별도 작업 계획, 수정 파일 목록, 검증 계획, 사용자 승인이 필요하다.

#### 17.43.8 Phase 8-C 진입 조건

Phase 8-C로 진입하려면 다음 조건을 모두 충족해야 한다.

- Phase 8-B 문서 변경이 검토 가능한 상태로 남아 있어야 한다.
- Phase 8-C 작업 계획이 hidden visual probe implementation으로 제한되어야 한다.
- production route 노출 없음, runtime/UI integration 없음, `ExplorerWorkspace` shell mount 없음, route collapse 없음이 작업 계획에 명시되어야 한다.
- 수정 대상 파일과 변경 위치가 사전에 제시되어야 한다.
- hidden visual probe가 read-only projection snapshot만 소비하고 Repository / Provider / Navigator / DB / persistence authority를 갖지 않는 검증 기준이 제시되어야 한다.
- projection result를 persistence, history payload, source of truth, runtime policy state로 사용하지 않는 검증 기준이 제시되어야 한다.
- 명령어 기반 검증 항목이 준비되어야 한다.
- production UI diff가 없는 경우 UI 기반 수동 테스트 대상 없음으로 분리해야 한다.

#### 17.43.9 Phase 8-C에서 허용 가능한 파일/구조 범위

Phase 8-C의 허용 가능한 파일/구조 범위는 별도 승인 전까지 후보로만 기록한다.

- `WordExplorerScreen` 내부에서 이미 생성되는 read-only projection snapshot을 private 또는 build-local 범위에서 소비하는 구조
- production route에 연결되지 않는 hidden probe helper 또는 source-level 검증 구조
- projection snapshot 입력만 받는 non-owner probe layer
- Repository, Provider, Navigator, DB, persistence import 없이 projection contract만 확인하는 source-level test

Phase 8-C에서 실제 파일을 수정하려면 그 시점의 작업 계획에서 대상 파일을 다시 제시해야 한다. Phase 8-B는 `lib/`, `test/`, platform directory를 수정하지 않는다.

#### 17.43.10 Phase 8-C에서도 유지해야 할 금지선

아래 항목은 Phase 8-B 이후에도 모두 `not approved` 상태로 유지한다.

- runtime/UI integration: `not approved`
- visual consumer production exposure: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- persistence authority migration: `not approved`
- projection result persistence: `not approved`
- projection result history usage: `not approved`
- projection result source-of-truth usage: `not approved`

또한 다음 표현과 구조는 계속 금지한다.

- `ExplorerWorkspace`가 owner처럼 보이는 표현
- `ExplorerWorkspace`가 controller처럼 보이는 표현
- `ExplorerWorkspace`가 coordinator처럼 보이는 표현
- `ExplorerWorkspace`가 selection, navigation, repository, persistence authority를 갖는 표현
- hidden visual probe가 production UI로 노출되는 것처럼 읽히는 표현

허용 가능한 표현은 visual consumer 또는 hidden visual probe가 `WordExplorerScreen` 내부에서 생성된 read-only projection snapshot을 소비하는 non-owner view/probe layer라는 의미로 제한한다.

#### 17.43.11 수동 테스트 기준 초안

이번 단계는 문서 작업이므로 UI 기반 수동 테스트 대상은 없다. 검증은 명령어 기반 확인과 문서 검색으로 수행한다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 8-B 목적이 visual consumer 후보 선정으로 명시되어 있는지 확인 | Phase 8-B가 구현 단계가 아니며 후보 선정 단계라고 기록되어야 함 | 구현 승인, route 연결, shell mount 승인처럼 읽히는 문장 | `rg -n "Phase 8-B" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Candidate A/B/C 비교가 문서화되어 있는지 확인 | 세 후보와 비교 기준이 표로 정리되어야 함 | 후보 누락 또는 기준 누락 | `rg -n "Candidate A|Candidate B|Candidate C" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 1 hidden visual probe가 Phase 8-C 첫 구현 후보로 선정되어 있는지 확인 | Candidate A가 Phase 8-C 첫 구현 후보로 적합하다고 기록되어야 함 | Candidate A가 production UI 노출처럼 읽힘 | `rg -n "hidden visual probe" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 2 production-adjacent visual consumer가 보류되어 있는지 확인 | Candidate B가 보류로 기록되어야 함 | Candidate B가 구현 승인처럼 기록됨 | `rg -n "production-adjacent visual consumer" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 3 production visible consumer가 승인되지 않았는지 확인 | Candidate C가 `not approved`로 기록되어야 함 | production visible consumer가 Phase 8-C 후보처럼 기록됨 | `rg -n "production visible consumer" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| runtime/UI integration이 승인되지 않았는지 확인 | runtime/UI integration이 `not approved`로 유지되어야 함 | runtime/UI 구현 승인 문장 | `rg -n "runtime/UI integration" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell mount가 승인되지 않았는지 확인 | shell mount가 `not approved`로 유지되어야 함 | shell mount 허용 문장 | `rg -n "shell mount" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace`가 owner/controller/coordinator가 아님이 유지되어 있는지 확인 | owner/controller/coordinator 승격 금지 문장이 유지되어야 함 | authority drift 표현 | `rg -n "owner|controller|coordinator" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| production UI diff가 없도록 코드 파일 변경이 없는지 확인 | `lib/`, `test/`, platform 경로 변경이 없어야 함 | 코드 또는 platform 경로가 diff에 포함됨 | `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| 변경 파일이 docs 범위로 제한되어 있는지 확인 | 변경 파일은 두 문서만이어야 함 | 다른 파일이 diff에 포함됨 | `git diff --name-only` | 작업 종료 보고에서 기록 |

#### 17.43.12 Phase 8-B status

- Phase 8-B status: `documented`
- selected Phase 8-C candidate: Candidate A `Level 1 hidden visual probe`
- Candidate B status: `deferred`
- Candidate C status: `not approved`
- Phase 8-C implementation status: `not approved`
- runtime/UI integration status: `not approved`
- visual consumer production exposure status: `not approved`
- shell mount status: `not approved`
- route collapse status: `not approved`
- owner boundary migration status: `not approved`
- production UI diff status: `not approved`

### 17.44 Phase 8-C hidden visual probe implementation

Phase 8-C는 Phase 7에서 확보한 `WordExplorerScreen` 내부 read-only projection chain과 Phase 8-A/B에서 정의한 visual consumer boundary를 기준으로 첫 번째 Level 1 hidden visual probe를 구현한 단계다. 이번 단계는 production visible UI를 만들거나 `ExplorerWorkspace` shell을 production에 mount하는 단계가 아니다.

#### 17.44.1 구현 결과

- `WordExplorerScreen` 내부의 build-local projection read 및 기존 assert-only consumer 경계 안에 `_debugValidateHiddenVisualProbe(...)` 검증 helper를 추가했다.
- hidden visual probe는 `ExplorerWorkspaceState` projection snapshot을 입력으로 받아 graph/detail visual candidate slot과 read-only label 구성 가능성만 검증한다.
- hidden visual probe는 assert-only 경계에서만 호출되며 production visible widget tree에 연결되지 않는다.
- hidden visual probe는 `ExplorerWorkspace` shell을 생성하거나 mount하지 않는다.
- hidden visual probe는 `HomeScreen`, `main.dart`, Navigator route, production entry를 변경하지 않는다.
- hidden visual probe는 Provider, Repository, Navigator, DB, persistence authority를 갖지 않는다.
- hidden visual probe는 projection result를 field, cache, history payload, source of truth, runtime policy state로 저장하지 않는다.

#### 17.44.2 Level 1 boundary 유지 근거

이번 구현은 Level 1 hidden visual probe 범위에 머문다.

- read-only projection snapshot만 소비한다.
- projection snapshot 소비는 `WordExplorerScreen`의 기존 debug/assert-only 검증 흐름 안에서 끝난다.
- owner/controller/coordinator 역할을 추가하지 않는다.
- selection, navigation, repository, persistence authority를 이전하지 않는다.
- production route 노출이 없다.
- production visible UI diff가 없다.
- `ExplorerWorkspace` shell mount가 없다.

#### 17.44.3 승인되지 않은 항목 유지

아래 항목은 Phase 8-C 구현 이후에도 승인되지 않은 상태로 유지한다.

- runtime/UI integration: `not approved`
- visual consumer production exposure: `not approved`
- Level 2 production-adjacent visual consumer: `deferred`
- Level 3 production visible consumer: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- persistence authority migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`

#### 17.44.4 Phase 8-D 후보 조건

Phase 8-D 후보를 검토하려면 Phase 8-C의 Level 1 hidden visual probe 결과를 먼저 검토해야 한다. 다음 단계가 Level 2 production-adjacent visual consumer로 이동하는 경우에도 별도 승인 전까지 production route 노출, production visible UI diff, shell mount, route 변경, owner migration은 허용되지 않는다.

Phase 8-D 후보 조건은 다음과 같다.

- Phase 8-C hidden visual probe가 read-only projection snapshot만 소비한다는 검증 결과가 유지되어야 한다.
- production route 노출 없음, `ExplorerWorkspace` shell mount 없음, production visible UI diff 없음이 명령어 기반 확인으로 유지되어야 한다.
- Level 2 후보를 검토하는 경우 production-adjacent 경계가 owner/controller/coordinator로 오해되지 않는 검증 기준을 먼저 제시해야 한다.
- runtime/UI integration 또는 production visible consumer가 필요해지는 경우 Phase 8-D 후보에서 제외하고 별도 설계와 별도 승인 단계로 분리해야 한다.

#### 17.44.5 수동 테스트 기준

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| hidden visual probe가 Level 1 범위로 구현되었는지 확인 | assert-only helper가 read-only projection snapshot만 소비해야 함 | helper가 production widget tree, route, owner state로 연결됨 | `rg -n "hidden visual probe|_debugValidateHiddenVisualProbe" lib test docs` | 작업 종료 보고에서 기록 |
| production route 노출이 없는지 확인 | `main.dart`, `HomeScreen`, Navigator route 변경이 없어야 함 | 새 route, production entry, `Navigator.push` 변경 | `git diff --name-only -- lib/main.dart lib/ui/home_screen.dart lib/ui/word_explorer_screen.dart` 및 route 검색 | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell mount가 없는지 확인 | `WordExplorerScreen`에서 `ExplorerWorkspace(`를 생성하지 않아야 함 | shell mount 또는 preview screen 연결 | `rg -n "ExplorerWorkspace\\(|ExplorerWorkspacePreviewScreen" lib test docs` | 작업 종료 보고에서 기록 |
| owner/controller/coordinator authority 이전이 없는지 확인 | Provider, Repository, Navigator, persistence 접근이 없어야 함 | helper 내부 side effect, repository 호출, history payload 저장 | source-level test 및 forbidden marker 검색 | 작업 종료 보고에서 기록 |
| projection result persistence/history/source-of-truth usage가 없는지 확인 | projection result가 field/cache/history/source of truth로 저장되지 않아야 함 | `_history` payload 또는 field 저장 | source-level test 및 `rg -n "source of truth|history|persistence" lib test docs` | 작업 종료 보고에서 기록 |
| production visible UI diff가 없는지 확인 | production visible widget tree 변경이 없어야 함 | Scaffold body, route, `ExplorerWorkspace` mount 변경 | `git diff -- lib/ui/word_explorer_screen.dart` 검토 | 작업 종료 보고에서 기록 |
| Flutter/Dart 검증 확인 | `flutter analyze`와 관련 테스트 또는 전체 테스트 결과를 보고해야 함 | analyzer error, test failure, 환경 오류 | `flutter analyze`, `flutter test` | 작업 종료 보고에서 기록 |

#### 17.44.6 Phase 8-C status

- Phase 8-C implementation status: `implemented`
- hidden visual probe level: `Level 1`
- production route exposure status: `none`
- `ExplorerWorkspace` shell mount status: `none`
- runtime/UI integration status: `not approved`
- owner/controller/coordinator migration status: `not approved`
- projection result persistence/history/source-of-truth usage status: `none`
- production visible UI diff status: `none`

### 17.45 Phase 8-D hidden visual probe stabilization audit

Phase 8-D는 구현 단계가 아니다. 이번 단계의 목적은 Phase 8-C에서 구현된 Level 1 hidden visual probe가 실제 코드, 테스트, 문서 기준으로 계속 Level 1 boundary 안에 머무는지 감사하고, 승인되지 않은 runtime/UI integration 경계가 유지되는지 정리하는 것이다.

Phase 8-D는 route 변경, `ExplorerWorkspace` shell mount, production UI entry 추가, hidden visual probe 추가 구현, owner/controller/coordinator authority migration을 수행하지 않는다.

#### 17.45.1 실제 확인한 Phase 8-C 구현 경계

감사는 다음 실제 코드와 테스트 위치를 기준으로 수행한다.

- `lib/ui/word_explorer_screen.dart`의 private getter `_readOnlyWorkspaceProjection`
- `lib/ui/word_explorer_screen.dart`의 private helper `_debugValidateHiddenVisualProbe(...)`
- `WordExplorerScreen.build(...)` 내부의 build-local `workspaceProjection` read와 debug `assert(() { ... }())` 호출 경계
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`

`_debugValidateHiddenVisualProbe(...)`는 `ExplorerWorkspaceState` projection snapshot을 입력으로 받아 graph/detail visual candidate slot과 read-only label 구성 가능성만 검증한다. helper는 `setState`, `Navigator`, `MaterialPageRoute`, `WordRepository`, `DatabaseService`, `Provider`, `ExplorerWorkspace(`, `WordGraphScreen(`, `WordDetailScreen(`, `debugPrint`, `print`, async/future/stream, file/database/preferences 접근을 수행하지 않는 source-level forbidden marker 검증 대상이다.

#### 17.45.2 감사 결과 요약

Phase 8-D 기준으로 hidden visual probe는 Level 1 boundary 안에 머문다.

- `_debugValidateHiddenVisualProbe(...)`는 `WordExplorerScreen.build(...)`의 기존 assert-only 경계 안에서만 호출된다.
- hidden visual probe는 read-only projection snapshot만 소비하며, production visible widget tree에 연결되지 않는다.
- owner/controller/coordinator authority 이전은 없다.
- production route 노출은 없다.
- `ExplorerWorkspace` shell mount는 없다.
- `main.dart`, `HomeScreen`, Navigator route 변경은 없다.
- Provider / Repository / Navigator / persistence authority migration은 없다.
- projection result persistence/history/source-of-truth usage는 없다.
- production visible UI diff는 없다.
- source-level boundary test가 존재하며, Phase 7-F projection boundary와 Phase 8-C hidden visual probe boundary를 함께 검증한다.

다만 runtime/UI integration, production exposure, `ExplorerWorkspace` shell mount, Level 2 / Level 3 consumer 진입은 여전히 승인하지 않는다.

#### 17.45.3 Level 1 boundary 유지 근거

| 확인 항목 | 실제 근거 | Phase 8-D 판단 |
| --- | --- | --- |
| assert-only boundary | `WordExplorerScreen.build(...)` 내부 debug `assert(() { ... }())`에서 `_debugValidateHiddenVisualProbe(projection)` 호출 | 유지 |
| read-only projection snapshot 소비 | helper 입력은 `ExplorerWorkspaceState projection`이며 candidate slot과 label 검증만 수행 | 유지 |
| non-owner boundary | helper 내부 forbidden marker 검증에서 state mutation, navigation, repository, provider, persistence 접근을 금지 | 유지 |
| production route 미노출 | `main.dart`, `HomeScreen`에 hidden visual probe 연결이 없고 production entry를 변경하지 않음 | 유지 |
| shell mount 없음 | `WordExplorerScreen`에서 `ExplorerWorkspace(`를 생성하지 않는 source-level test 존재 | 유지 |
| projection result 비저장 | projection result를 field/cache/history payload/source of truth로 저장하지 않는 source-level test 존재 | 유지 |
| production visible UI diff 없음 | Phase 8-D 변경 범위는 문서로 제한되며 `lib/`, `test/`, platform 경로 변경 없음 | 유지 |

#### 17.45.4 유지된 금지선

아래 항목은 Phase 8-D 감사 이후에도 승인되지 않은 상태로 유지한다.

- runtime/UI integration: `not approved`
- visual consumer production exposure: `not approved`
- Level 2 production-adjacent visual consumer: `not approved`
- Level 3 production visible consumer: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- production route 변경: `not approved`
- `main.dart` entry 변경: `not approved`
- `HomeScreen` entry 변경: `not approved`
- Navigator route 변경: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- DB / persistence authority migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- production visible UI diff: `not approved`

#### 17.45.5 검증 상태

Phase 8-D의 관련 테스트 기준은 다음 두 source-level test 파일이다.

- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`

관련 테스트 결과는 `+11: All tests passed!`로 기록한다.

전체 `flutter analyze`는 기존 저장소 이슈로 실패하는 상태다. Phase 8-D 감사 기록에서는 analyze 실패를 Phase 8-D 문서 변경의 오류로 간주하지 않으며, 이번 변경 파일인 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`는 analyzer 오류 목록에 포함되지 않는 것으로 구분한다.

#### 17.45.6 Phase 8-E 후보 조건

Phase 8-E는 hidden visual probe를 Level 2로 올리는 단계가 아니다. Phase 8-E는 별도 승인 전까지 planning/audit 단계 후보로만 취급한다.

Phase 8-E 후보는 다음 범위로 제한할 수 있다.

- hidden visual probe output contract planning
- hidden visual probe source-level hardening
- visual candidate structure audit

Phase 8-D는 Phase 8-E 구현, Level 2 production-adjacent visual consumer 진입, runtime/UI integration, production route 노출, production visible UI diff, `ExplorerWorkspace` shell mount를 승인하지 않는다.

#### 17.45.7 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 8-D 목적이 stabilization audit으로 명시되어 있는지 확인 | Phase 8-D가 구현 단계가 아니라고 기록되어야 함 | 구현 승인 또는 기능 추가처럼 읽히는 문장 | `rg -n "Phase 8-D" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Phase 8-C hidden visual probe가 Level 1 boundary 안에 머무는지 확인 | Level 1 boundary 유지 판단이 기록되어야 함 | Level 2/Level 3 진입 승인처럼 읽힘 | `rg -n "Level 1" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| assert-only/read-only boundary가 유지되는지 확인 | helper가 assert-only 경계에서 read-only projection snapshot만 소비한다고 기록되어야 함 | helper가 runtime state owner 또는 visible widget으로 해석됨 | `rg -n "_debugValidateHiddenVisualProbe|read-only" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| production route 노출이 없는지 확인 | production route 노출 없음이 기록되어야 함 | route 변경, production entry 추가, Navigator route 변경 승인처럼 읽힘 | `rg -n "production route|Navigator route" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell mount가 없는지 확인 | shell mount 없음과 `not approved`가 함께 기록되어야 함 | shell mount 승인 또는 production mount로 해석됨 | `rg -n "ExplorerWorkspace.*shell mount|shell mount" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `main.dart` / `HomeScreen` / Navigator route 변경이 없는지 확인 | entry와 route 변경 없음이 기록되어야 함 | entry 변경 또는 route 변경이 허용된 것처럼 읽힘 | `rg -n "main.dart|HomeScreen|Navigator route" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Provider / Repository / Navigator / persistence authority migration이 없는지 확인 | authority migration 없음과 `not approved`가 기록되어야 함 | owner/controller/coordinator migration으로 해석됨 | `rg -n "Provider|Repository|Navigator|persistence" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| projection result persistence/history/source-of-truth usage가 없는지 확인 | projection result 비저장 상태가 기록되어야 함 | field/history/source of truth 사용 승인처럼 읽힘 | `rg -n "projection result persistence|source-of-truth" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| production visible UI diff가 없는지 확인 | production visible UI diff 없음이 기록되어야 함 | visible UI 변경 승인처럼 읽힘 | `rg -n "production visible UI diff" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 관련 테스트 결과가 문서와 일치하는지 확인 | 두 관련 테스트와 `+11: All tests passed!`가 기록되어야 함 | 테스트 파일 누락 또는 결과 불일치 | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| `flutter analyze` 기존 이슈 상태가 문서에 정확히 기록되어 있는지 확인 | 기존 저장소 이슈로 실패하며 이번 변경 파일은 오류 목록에 포함되지 않는다고 구분되어야 함 | 문서 변경이 analyzer 실패 원인처럼 기록됨 | `flutter analyze` | 작업 종료 보고에서 기록 |
| 변경 파일이 docs 범위로 제한되어 있는지 확인 | 변경 파일은 문서 2개만 있어야 함 | `lib/`, `test/`, platform 경로 변경 발생 | `git diff --name-only` 및 `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 8-D 문서/audit 작업의 대상이 아니다.

### 17.46 Phase 8-E hidden visual probe output contract planning

Phase 8-E는 구현 단계가 아니다. 이번 단계의 목적은 Phase 8-C에서 구현되고 Phase 8-D에서 안정화 감사가 완료된 Level 1 hidden visual probe가 내부적으로 확인하는 visual candidate의 output contract를 문서상으로 정리하는 것이다.

Phase 8-D는 hidden visual probe가 실제 코드, 테스트, 문서 기준으로 Level 1 boundary 안에 머무는지 감사했다. Phase 8-E는 그 boundary를 변경하지 않고, `_debugValidateHiddenVisualProbe(...)`가 read-only projection snapshot에서 어떤 local candidate 구조를 도출해 검증하는지와 그 구조가 무엇을 의미하지 않는지를 정리한다.

#### 17.46.1 hidden visual probe output contract 정의

hidden visual probe output contract는 production UI 계약이 아니다.

이는 assert-only hidden probe가 read-only projection snapshot에서 어떤 visual candidate 구조를 도출할 수 있는지 설명하는 내부 검증 계약이다.

이 계약은 다음 범위로 제한한다.

- hidden visual probe helper 내부에서만 성립한다.
- `WordExplorerScreen.build(...)` 내부 assert-only 경계 밖으로 노출되지 않는다.
- production widget tree, route, shell, public API, persistence schema로 확장된 계약이 아니다.
- `ExplorerWorkspace`를 owner, controller, coordinator로 승격하지 않는다.

#### 17.46.2 input contract

Input은 `WordExplorerScreen` 내부에서 build-local로 읽은 read-only `ExplorerWorkspaceState` projection snapshot이다.

실제 코드 기준 input 경계는 다음과 같다.

- `WordExplorerScreen`의 private getter `_readOnlyWorkspaceProjection`이 현재 owner state를 읽어 `ExplorerWorkspaceState?`를 파생한다.
- `WordExplorerScreen.build(...)`는 `final workspaceProjection = _readOnlyWorkspaceProjection;` 형태로 build-local snapshot을 읽는다.
- debug `assert(() { ... }())` 내부에서 null이 아닌 projection만 `_debugValidateHiddenVisualProbe(projection)`에 전달한다.
- projection은 `ExplorerWorkspaceLayoutPreset.balanced`, `ExplorerWorkspaceTransitionOrigin.routeAlias`, graph/detail/selection id consistency를 assert-only로 확인하는 경계 안에 머문다.

Input contract의 금지선은 다음과 같다.

- input은 field, cache, history payload, source of truth로 저장되지 않는다.
- input은 Repository, Provider, Navigator, DB, persistence authority를 갖지 않는다.
- input은 canonical workspace state가 아니다.
- input은 selection state source of truth가 아니다.
- input은 graph/detail layout authority가 아니다.
- input은 `ExplorerWorkspace` shell mount 또는 production route entry로 전달되지 않는다.

#### 17.46.3 derived visual candidate contract

Derived visual candidate는 `_debugValidateHiddenVisualProbe(...)` helper 내부에서만 구성되는 local candidate structure다.

실제 구현 기준 candidate 구조는 다음 local list로 제한된다.

- `candidateSlots`: `projection.graphCenterWordId != null`이면 `graph`, `projection.detailTargetWordId != null`이면 `detail`을 담는 내부 후보 slot 목록이다.
- `candidateLabels`: `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset.name`, `origin.name` 중 null이 아닌 projection 값을 담는 내부 read-only label 목록이다.

이 구조의 의미는 다음으로 제한한다.

- 향후 visual consumer가 graph/detail slot과 label을 렌더링할 수 있는지 source-level에서 검증하기 위한 내부 후보 구조다.
- helper는 `candidateSlots.isNotEmpty`, `candidateLabels.every((label) => label.trim().isNotEmpty)`, `detailTargetWordId == null || detailTargetWordId == projection.selectedWordId` 조건만 검증한다.
- candidate 구조는 helper 반환값 밖으로 전달되지 않는다.
- candidate 구조는 production widget tree에 mount되지 않는다.
- candidate 구조는 route, shell, owner state, persistence model로 저장되지 않는다.

#### 17.46.4 non-contract 항목

아래 항목은 hidden visual probe output contract가 아니다.

- production UI contract
- public API
- persistence schema
- route contract
- `ExplorerWorkspace` shell contract
- owner/controller/coordinator contract
- Provider / Repository / Navigator authority contract
- DB / persistence authority contract
- canonical workspace state
- selection state source of truth
- graph/detail layout authority
- production visual consumer contract
- output DTO/model contract

#### 17.46.5 금지되는 해석

Phase 8-E 문서화는 다음 의미로 해석하면 안 된다.

- hidden visual probe가 production UI로 노출된다는 의미
- `candidateSlots` 또는 `candidateLabels`가 public model 또는 output DTO로 승격된다는 의미
- `ExplorerWorkspace` shell mount가 승인되었다는 의미
- route collapse 또는 Navigator route 변경이 승인되었다는 의미
- `WordExplorerScreen`의 owner boundary가 `ExplorerWorkspace`로 이전된다는 의미
- Provider / Repository / Navigator / DB / persistence authority가 이전된다는 의미
- projection result를 persistence, history, source of truth로 사용할 수 있다는 의미
- Level 2 production-adjacent visual consumer 또는 Level 3 production visible consumer 진입이 승인되었다는 의미

#### 17.46.6 Phase 8-F 후보 조건

Phase 8-F는 Level 2 승격이 아니다. Phase 8-F는 별도 승인 전까지 hidden visual probe output contract를 source-level test로 더 고정하거나, visual candidate structure naming/hardening을 검토하는 planning 또는 test-hardening 단계 후보로만 취급한다.

가능한 Phase 8-F 후보는 다음 범위로 제한한다.

- hidden visual probe output contract source-level hardening
- visual candidate structure naming audit
- hidden probe contract test expansion

Phase 8-E는 Phase 8-F 구현, Level 2 production-adjacent visual consumer 진입, Level 3 production visible consumer 진입, runtime/UI integration, production route 노출, production visible UI diff, `ExplorerWorkspace` shell mount를 승인하지 않는다.

#### 17.46.7 유지된 금지선

아래 항목은 Phase 8-E 이후에도 승인되지 않은 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- ExplorerWorkspace shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- DB / persistence authority migration: `not approved`
- projection result persistence: `not approved`
- projection result history usage: `not approved`
- projection result source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.46.8 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 8-E 목적이 output contract planning으로 명시되어 있는지 확인 | Phase 8-E가 구현 단계가 아니며 planning 단계라고 기록되어야 함 | 구현 승인 또는 runtime/UI integration처럼 읽히는 문장 | `rg -n "Phase 8-E" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| hidden visual probe output contract가 production UI contract가 아님이 명시되어 있는지 확인 | output contract가 production UI 계약이 아니라고 기록되어야 함 | production visible UI contract로 해석됨 | `rg -n "output contract" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| input이 build-local read-only projection snapshot으로 제한되어 있는지 확인 | input이 `WordExplorerScreen` 내부 build-local read-only `ExplorerWorkspaceState` projection snapshot이라고 기록되어야 함 | field/cache/history/source of truth 저장으로 해석됨 | `rg -n "build-local|read-only|ExplorerWorkspaceState" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| visual candidate structure가 내부 검증용임이 명시되어 있는지 확인 | `candidateSlots`, `candidateLabels`가 helper 내부 local candidate structure라고 기록되어야 함 | public model 또는 output DTO로 해석됨 | `rg -n "visual candidate|candidateSlots|candidateLabels" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| candidate 구조가 public API / persistence schema / route contract가 아님이 명시되어 있는지 확인 | non-contract 항목에 public API, persistence schema, route contract가 포함되어야 함 | 외부 계약 또는 persistence 구조로 해석됨 | `rg -n "public API|persistence schema|route contract" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 1 boundary가 유지되는지 확인 | Phase 8-E가 Level 1 boundary를 유지한다고 기록되어야 함 | Level 2/Level 3 진입 승인처럼 읽힘 | `rg -n "Level 1" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 2/Level 3 consumer 진입이 승인되지 않았는지 확인 | Level 2/Level 3 consumer가 `not approved`로 유지되어야 함 | production-adjacent 또는 visible consumer 진입 승인처럼 읽힘 | `rg -n "Level 2|Level 3|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| runtime/UI integration이 승인되지 않았는지 확인 | runtime/UI integration이 `not approved`로 유지되어야 함 | UI 연결 승인처럼 읽힘 | `rg -n "runtime/UI integration|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| ExplorerWorkspace shell mount가 승인되지 않았는지 확인 | shell mount가 `not approved`로 유지되어야 함 | shell mount 또는 production mount 승인처럼 읽힘 | `rg -n "shell mount|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 코드/test/platform 변경이 없는지 확인 | 변경 파일은 문서 2개만 있어야 함 | `lib/`, `test/`, platform 경로 변경 발생 | `git diff --name-only` 및 `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| 관련 테스트 결과가 문서와 충돌하지 않는지 확인 | Phase 7-F/8-C source-level test가 통과해야 함 | hidden probe boundary test 실패 | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| flutter analyze 기존 이슈 상태가 문서 변경과 분리되어 보고되는지 확인 | analyze 실패 시 기존 저장소 이슈와 문서 변경 영향을 구분해야 함 | 문서 변경이 analyzer 실패 원인처럼 보고됨 | `flutter analyze` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 8-E 문서/planning 작업의 대상이 아니다.

### 17.47 Phase 8-F hidden probe output contract hardening plan

Phase 8-F는 구현 단계가 아니다. 이번 단계의 목적은 Phase 8-E에서 정리한 hidden visual probe output contract가 현재 source-level test로 충분히 고정되어 있는지 실제 코드와 테스트 기준으로 검토하고, 추가 hardening이 필요한 경우 다음 단계 후보를 문서상으로 제한하는 것이다.

Phase 8-E는 hidden visual probe가 내부적으로 도출하는 output contract의 의미와 non-contract 항목을 문서화했다. Phase 8-F는 그 contract를 public API로 승격하지 않고, 현재 Phase 8-C source-level test가 어떤 범위를 보호하는지와 어떤 오해 방지 test 후보가 남아 있는지만 정리한다.

#### 17.47.1 확인한 source 위치

이번 판단은 다음 실제 source를 기준으로 한다.

- `lib/ui/word_explorer_screen.dart`
  - private getter `_readOnlyWorkspaceProjection`
  - private helper `_debugValidateHiddenVisualProbe(...)`
  - `WordExplorerScreen.build(...)` 내부 build-local projection read와 debug `assert(() { ... }())` 호출
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
  - projection getter, build-local read, field/history 비저장, non-visual boundary 검증
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`
  - hidden probe helper, helper 내부 local candidate structure, side-effect forbidden marker, persistence/history 비저장, shell/route 미연결 검증
- `docs/ux/explorer_workspace_unification.md`
  - Phase 8-C, Phase 8-D, Phase 8-E boundary와 output contract 기록
- `docs/logs/CHANGELOG.md`
  - Phase 8-E 종료 기록과 Phase 8-F 후보 제한 기록

#### 17.47.2 현재 source-level test 보호 범위

현재 Phase 7-F/8-C source-level test는 다음 범위를 보호한다.

- `_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 private getter로 유지된다.
- projection snapshot은 `WordExplorerScreen.build(...)` 내부에서 build-local로 읽힌다.
- `_debugValidateHiddenVisualProbe(...)`는 `ExplorerWorkspaceState projection`을 입력으로 받는 private helper다.
- helper는 `candidateSlots`, `candidateLabels` local list를 구성하고 projection의 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset.name`, `origin.name`을 읽는다.
- helper는 `candidateLabels.every((label) => label.trim().isNotEmpty)` 조건을 포함한다.
- helper source 안에 `setState`, `Navigator`, `MaterialPageRoute`, `WordRepository`, `DatabaseService`, `Provider`, `ExplorerWorkspace(`, `WordGraphScreen(`, `WordDetailScreen(`, async/future/stream, file/database/preferences 접근 marker가 없어야 한다.
- projection result는 field, cache, history payload로 저장되지 않아야 한다.
- `ExplorerWorkspace` shell은 production route에 mount되지 않아야 한다.
- `main.dart`와 `HomeScreen`의 production entry point는 hidden probe helper에 연결되지 않아야 한다.

따라서 현재 test는 Level 1 hidden probe boundary, read-only input, side-effect 금지, route/shell 미연결, projection result 비저장 상태를 source-level에서 고정하고 있다.

#### 17.47.3 output contract hardening 필요성 평가

현재 test는 output contract의 구현 위치와 side-effect 금지를 보호하는 데 충분한 1차 경계가 있다. 특히 `candidateSlots`와 `candidateLabels`가 helper 내부 local list로 존재하고, helper가 production widget tree나 route, repository, persistence로 연결되지 않는다는 점은 이미 source-level로 확인된다.

다만 Phase 8-E에서 정리한 non-contract 항목 전체를 직접 고정하는 test는 아직 완전하지 않다. 현재 Phase 8-C test는 helper 내부 candidate 구조가 존재하는지와 외부 연결 marker가 없는지를 확인하지만, 다음 오해 방지 조건을 명시적으로 모두 검사하지는 않는다.

- `candidateSlots` / `candidateLabels`가 helper 밖으로 return되거나 field로 승격되지 않는지
- output DTO/model 또는 public class/API가 새로 추가되지 않는지
- persistence schema, route contract, `ExplorerWorkspace` shell contract로 해석될 새 경계가 생기지 않는지
- visual candidate naming이 production visual consumer contract처럼 확장되지 않는지

따라서 Phase 8-F의 결론은 "현재 Level 1 boundary 보호는 유지되지만, Phase 8-E output contract의 오해 방지까지 더 강하게 고정하려면 Phase 8-G에서 최소 source-level hardening test를 후보로 둘 수 있다"로 제한한다.

#### 17.47.4 `candidateSlots` / `candidateLabels` naming risk 평가

`candidateSlots`, `candidateLabels`는 현재 `_debugValidateHiddenVisualProbe(...)` helper 내부 local variable이다. 실제 코드 기준으로 이 이름은 class, public field, exported API, DTO, persistence payload, route argument, shell prop으로 존재하지 않는다.

Naming risk는 낮지 않다. `candidate`, `slots`, `labels`라는 이름이 visual consumer의 output shape 또는 production rendering contract처럼 읽힐 수 있기 때문이다. 그러나 현재 위험은 helper 내부 local structure에 머물러 있으며, 다음 조건이 유지되면 public API로 해석하지 않는다.

- local variable scope 밖으로 노출하지 않는다.
- helper 반환값은 candidate structure가 아니라 boolean 검증 결과로만 유지한다.
- class, typedef, public method, DTO/model, route argument, persistence schema로 승격하지 않는다.
- `ExplorerWorkspace` shell prop 또는 production visual consumer input으로 전달하지 않는다.
- 문서에서는 "local candidate structure", "internal validation", "not public API" 표현을 함께 유지한다.

Phase 8-G에서 naming risk를 다룬다면 이름 변경 구현이 아니라 source-level test 또는 문서 audit 후보로 제한한다.

#### 17.47.5 public API / DTO / persistence schema 오해 방지 기준

hidden visual probe output contract는 다음으로 해석하지 않는다.

- production UI contract
- public API
- output DTO/model contract
- persistence schema
- route contract
- `ExplorerWorkspace` shell contract
- production visual consumer contract
- canonical workspace state
- selection state source of truth
- projection result persistence/history/source-of-truth usage

오해 방지 기준은 다음과 같다.

- output contract라는 표현은 helper 내부 검증 계약만 뜻한다.
- `candidateSlots` / `candidateLabels`는 helper 내부 local visual candidate structure만 뜻한다.
- `ExplorerWorkspace`는 owner, controller, coordinator, production shell mount 대상이 아니다.
- Level 1 hidden probe boundary는 유지한다.
- Level 2 / Level 3 visual consumer 진입은 승인하지 않는다.

#### 17.47.6 Phase 8-G 후보 조건

Phase 8-G는 구현 승인 단계가 아니다. Phase 8-F는 다음 후보 조건만 남긴다.

- hidden probe output contract source-level test hardening
- visual candidate naming risk test 추가
- public API / DTO / persistence schema 오해 방지 테스트 추가

Phase 8-G 후보는 최소 source-level test 또는 naming risk audit으로 제한한다. Phase 8-F는 Phase 8-G 구현, runtime/UI integration, production visual consumer exposure, shell mount, owner migration을 승인하지 않는다.

#### 17.47.7 유지된 금지선

아래 항목은 Phase 8-F 이후에도 승인되지 않은 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- ExplorerWorkspace shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- persistence authority migration: `not approved`
- projection result persistence: `not approved`
- projection result history usage: `not approved`
- projection result source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.47.8 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 8-F 목적이 output contract hardening planning으로 명시되어 있는지 확인 | Phase 8-F가 구현 단계가 아니라 source-level hardening 검토 planning 단계로 기록되어야 함 | 구현 승인 또는 runtime/UI integration처럼 읽히는 문장 | `rg -n "Phase 8-F" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Phase 8-F가 Level 2 승격 단계가 아님이 명시되어 있는지 확인 | Level 2 승격이 아니며 Level 1 boundary를 유지한다고 기록되어야 함 | production-adjacent visual consumer 진입 승인처럼 읽힘 | `rg -n "Level 1|Level 2" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `candidateSlots` / `candidateLabels`가 public API가 아님이 유지되는지 확인 | 두 이름이 helper 내부 local structure이고 public API가 아니라고 기록되어야 함 | public model, DTO, shell prop처럼 해석됨 | `rg -n "candidateSlots|candidateLabels|public API" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| output DTO/model 추가가 승인되지 않았는지 확인 | output DTO/model addition이 `not approved`로 유지되어야 함 | output contract가 DTO 추가 승인처럼 읽힘 | `rg -n "output DTO/model" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| source-level hardening 필요성 평가가 문서화되어 있는지 확인 | 현재 보호 범위와 추가 hardening 후보가 분리되어 기록되어야 함 | 현 테스트가 모든 non-contract 항목을 완전 보호한다고 과도하게 선언됨 | `rg -n "hardening|source-level test" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Phase 8-G 후보가 test hardening 또는 naming risk audit으로 제한되어 있는지 확인 | Phase 8-G 후보가 source-level test hardening, naming risk test, 오해 방지 테스트로 제한되어야 함 | Phase 8-G가 runtime/UI 구현 후보처럼 읽힘 | `rg -n "Phase 8-G|naming risk|test hardening" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 1 boundary가 유지되는지 확인 | Level 1 hidden probe boundary 유지가 기록되어야 함 | Level 2/Level 3 진입 승인처럼 읽힘 | `rg -n "Level 1" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 2 / Level 3 consumer 진입이 승인되지 않았는지 확인 | Level 2 / Level 3 consumer가 `not approved`로 유지되어야 함 | production-adjacent 또는 visible consumer 진입 승인처럼 읽힘 | `rg -n "Level 2|Level 3|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| runtime/UI integration이 승인되지 않았는지 확인 | runtime/UI integration이 `not approved`로 유지되어야 함 | UI 연결 승인처럼 읽힘 | `rg -n "runtime/UI integration|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| ExplorerWorkspace shell mount가 승인되지 않았는지 확인 | shell mount가 `not approved`로 유지되어야 함 | shell mount 또는 production mount 승인처럼 읽힘 | `rg -n "shell mount|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 코드/test/platform 변경이 없는지 확인 | 변경 파일은 문서 2개만 있어야 함 | `lib/`, `test/`, platform 경로 변경 발생 | `git diff --name-only` 및 `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| 관련 테스트 결과가 문서와 충돌하지 않는지 확인 | Phase 7-F/8-C source-level test가 통과해야 함 | hidden probe boundary test 실패 | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| flutter analyze 기존 이슈 상태가 문서 변경과 분리되어 보고되는지 확인 | analyze 실패 시 기존 저장소 이슈와 문서 변경 영향을 구분해야 함 | 문서 변경이 analyzer 실패 원인처럼 보고됨 | `flutter analyze` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 8-F 문서/planning 작업의 대상이 아니다.

### 17.48 Phase 8-G hidden probe output contract source-level test hardening

Phase 8-G는 기능 확장 단계가 아니다. 이번 단계의 목적은 Phase 8-E/F에서 문서화한 hidden probe output contract boundary를 source-level test로 더 단단히 고정하는 것이다. Production UI, route, shell, persistence, owner authority는 변경하지 않는다.

#### 17.48.1 목적

Phase 8-G의 목적은 hidden visual probe가 계속 Level 1 hidden probe boundary 안에 머무는지 테스트로 확인하는 것이다.

검증 대상은 다음으로 제한한다.

- `candidateSlots` / `candidateLabels`가 helper 내부 local variable 범위에 머무르는지 확인한다.
- `candidateSlots` / `candidateLabels`가 public API, field, getter, public method, exported API로 승격되지 않았는지 확인한다.
- hidden probe output DTO/model이 추가되지 않았는지 확인한다.
- persistence schema, route contract, shell contract로 연결되지 않았는지 확인한다.
- hidden visual probe가 assert-only / read-only / non-owner boundary 안에 머무르는지 확인한다.
- Level 2 / Level 3 consumer 진입이 발생하지 않았는지 확인한다.

#### 17.48.2 추가한 source-level test 범위

Phase 8-G에서는 다음 테스트 파일을 추가한다.

- `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`

이 테스트는 실제 source를 읽어 다음 범위를 확인한다.

- `lib/ui/word_explorer_screen.dart`의 `_debugValidateHiddenVisualProbe(...)` helper 본문과 helper 외부 source를 분리한다.
- `candidateSlots`, `candidateLabels`가 helper 본문에만 존재하고 helper 외부에는 존재하지 않는지 확인한다.
- `candidateSlots`, `candidateLabels`가 `_WordExplorerScreenState` field 영역에 존재하지 않는지 확인한다.
- hidden probe output으로 해석될 public class, typedef, getter, named argument marker가 추가되지 않았는지 확인한다.
- `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `lib/ui/explorer_workspace/explorer_workspace.dart`, `lib/main.dart`, `lib/ui/home_screen.dart`가 hidden probe helper 또는 candidate structure를 노출하지 않는지 확인한다.
- `WordExplorerScreen.build(...)` 내부 assert-only 호출 위치와 helper 내부 forbidden marker를 확인해 read-only / non-owner boundary를 유지한다.

#### 17.48.3 `candidateSlots` / `candidateLabels` public API 오해 방지

`candidateSlots`, `candidateLabels`는 `_debugValidateHiddenVisualProbe(...)` 내부 local candidate structure다. 이 이름은 다음으로 해석하지 않는다.

- public API
- output DTO/model field
- shell prop
- route argument
- persistence payload
- owner state
- production visual consumer input

Phase 8-G 테스트는 helper 범위와 helper 외부 범위를 분리해 두 이름이 local helper scope 밖으로 나가지 않는지 확인한다. 이 검증은 이름 변경 구현이 아니라 현재 boundary를 고정하는 source-level hardening이다.

#### 17.48.4 output DTO/model 미추가 확인

Phase 8-G는 hidden probe output DTO/model을 추가하지 않는다. 테스트는 hidden visual probe output처럼 해석될 수 있는 public class, typedef, getter, named argument marker가 public boundary source에 추가되지 않았는지 확인한다.

이번 단계에서 `ExplorerWorkspaceState` contract, preview input contract, history entry contract, shell widget contract는 변경하지 않는다.

#### 17.48.5 persistence schema / route contract / shell contract 미연결 확인

Phase 8-G는 persistence schema, route contract, shell contract를 만들지 않는다.

유지 기준은 다음과 같다.

- `WordExplorerScreen`은 `ExplorerWorkspace` shell을 import하거나 mount하지 않는다.
- `main.dart`와 `HomeScreen`은 hidden probe helper 또는 candidate structure를 알지 않는다.
- `candidateSlots`, `candidateLabels`는 payload, route arguments, shell state, persistence value로 전달되지 않는다.
- helper 내부는 `setState`, `Navigator`, `WordRepository`, `Provider`, DB/persistence 접근, logging, async/future/stream 흐름을 수행하지 않는다.
- projection result는 field/cache/history/source-of-truth로 저장되지 않는다.

#### 17.48.6 Level 1 boundary 유지

Phase 8-G 이후에도 hidden visual probe는 Level 1 boundary에 머문다.

- 입력은 `WordExplorerScreen.build(...)`에서 build-local로 읽은 read-only `ExplorerWorkspaceState` projection snapshot이다.
- 호출은 debug `assert(() { ... }())` 내부에만 남는다.
- helper 반환값은 candidate output이 아니라 boolean 검증 결과다.
- production widget tree에 새 consumer를 추가하지 않는다.
- production UI diff는 없다.

#### 17.48.7 Level 2 / Level 3 consumer 미승인 유지

Phase 8-G는 Level 2 승격 단계가 아니다. Phase 8-G는 Level 3 production visible consumer 진입도 승인하지 않는다.

아래 항목은 Phase 8-G 이후에도 승인되지 않은 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- ExplorerWorkspace shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- persistence authority migration: `not approved`
- projection result persistence: `not approved`
- projection result history usage: `not approved`
- projection result source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.48.8 Phase 8-H audit 후보 조건

Phase 8-H는 Level 2 승격 단계가 아니다. Phase 8-H는 Phase 8-A~G까지의 visual consumer entry / hidden probe / output contract / test hardening 흐름을 감사하는 termination 또는 stabilization audit 후보로 둔다.

가능한 Phase 8-H 후보는 다음 범위로 제한한다.

- Phase 8 hidden probe contract stabilization audit
- Phase 8 visual consumer Level 1 boundary termination audit
- Phase 8-G test hardening audit

Phase 8-G는 Phase 8-H 구현, Level 2 production-adjacent visual consumer 진입, Level 3 production visible consumer 진입을 승인하지 않는다.

#### 17.48.9 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 8-G 목적이 source-level test hardening인지 확인 | Phase 8-G가 기능 확장이 아니라 boundary hardening으로 기록되어야 함 | runtime/UI integration 또는 production consumer 구현처럼 읽힘 | `rg -n "Phase 8-G" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| `candidateSlots` / `candidateLabels`가 public API로 승격되지 않았는지 확인 | 두 이름이 helper 내부 local structure로만 유지되어야 함 | field, getter, public method, DTO, shell prop처럼 노출됨 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| output DTO/model 추가가 없는지 확인 | hidden probe output DTO/model marker가 source-level test에서 발견되지 않아야 함 | public class, typedef, getter, named argument로 확장됨 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| persistence schema / route contract / shell contract 연결이 없는지 확인 | helper와 candidate structure가 persistence, route, shell boundary에 연결되지 않아야 함 | payload, arguments, shell state, persistence marker가 추가됨 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| hidden visual probe가 assert-only/read-only/non-owner boundary 안에 머무는지 확인 | helper가 assert-only 호출과 side-effect free source 범위 안에 있어야 함 | `setState`, `Navigator`, repository, provider, persistence, logging, async marker가 helper 안에 추가됨 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| Level 1 boundary가 유지되는지 확인 | Level 1 hidden probe boundary 유지가 기록되어야 함 | Level 2/Level 3 진입 승인처럼 읽힘 | `rg -n "Level 1|Level 2|Level 3" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 2 / Level 3 consumer 진입이 승인되지 않았는지 확인 | Level 2 / Level 3 consumer가 `not approved`로 유지되어야 함 | production-adjacent 또는 visible consumer 진입 승인처럼 읽힘 | `rg -n "Level 2|Level 3|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| runtime/UI integration이 승인되지 않았는지 확인 | runtime/UI integration이 `not approved`로 유지되어야 함 | UI 연결 승인처럼 읽힘 | `rg -n "runtime/UI integration|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| ExplorerWorkspace shell mount가 승인되지 않았는지 확인 | shell mount가 `not approved`로 유지되어야 함 | shell mount 또는 production mount 승인처럼 읽힘 | `rg -n "shell mount|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| production UI diff가 없는지 확인 | `lib/` 및 platform 경로 변경이 없어야 함 | production UI 또는 platform 파일 변경 발생 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| 관련 flutter test 결과 확인 | Phase 7-F/8-C/8-G source-level test가 통과해야 함 | 관련 boundary test 실패 | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| flutter analyze 기존 이슈 상태가 이번 변경과 분리되어 보고되는지 확인 | analyze 실패 시 이번 변경 파일 포함 여부를 구분해야 함 | 새 테스트 파일 또는 변경 문서가 analyzer 오류와 직접 연결됨 | `flutter analyze` | 작업 종료 보고에서 기록 |
| 문서와 테스트가 서로 일치하는지 확인 | Phase 8-G 문서의 hardening 범위와 테스트 범위가 일치해야 함 | 문서는 승인하지 않은 경계를 승인처럼 기록하거나 테스트와 다른 범위를 주장함 | 문서 diff와 테스트 diff 검토 | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 8-G source-level test hardening 작업의 대상이 아니다.

### 17.49 Phase 8-H hidden probe contract termination audit

Phase 8-H는 구현 단계가 아니다. 이번 단계의 목적은 Phase 8-A부터 Phase 8-G까지 이어진 visual consumer entry boundary, Level 1 hidden visual probe, output contract planning, source-level test hardening 흐름을 실제 코드, 테스트, 문서 기준으로 종합 감사하고 Phase 8을 종료 가능한 상태로 볼 수 있는지 판단하는 termination/stabilization audit이다.

Phase 8-H는 새 기능, 새 테스트, runtime/UI integration, production route 노출, `ExplorerWorkspace` shell mount, route 변경, Provider / Repository / Navigator / persistence authority migration을 수행하지 않는다. 이번 단계의 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.49.1 Phase 8-A~G 흐름 요약

- Phase 8-A는 Phase 7 read-only projection chain 이후 visual consumer가 projection snapshot을 읽기 전에 지켜야 할 entry boundary를 문서화했다.
- Phase 8-B는 visual consumer 후보를 Level 1, Level 2, Level 3으로 비교하고 첫 구현 후보를 Level 1 hidden visual probe로 제한했다.
- Phase 8-C는 `WordExplorerScreen` 내부 build-local read-only projection read와 기존 assert-only consumer 경계 안에 `_debugValidateHiddenVisualProbe(...)` helper를 추가했다.
- Phase 8-D는 Phase 8-C hidden visual probe가 Level 1 boundary 안에 머무는지 stabilization audit으로 확인했다.
- Phase 8-E는 hidden visual probe가 내부적으로 도출하는 visual candidate의 output contract를 문서상으로 정리했다.
- Phase 8-F는 output contract hardening 필요성을 검토하고 Phase 8-G 후보를 source-level test hardening으로 제한했다.
- Phase 8-G는 `candidateSlots`, `candidateLabels`, output DTO/model, route/shell/persistence 미연결, assert-only/read-only/non-owner boundary를 source-level test로 보강했다.

#### 17.49.2 Phase 8 전체에서 완료된 항목

Phase 8-H 기준으로 실제 확인한 완료 항목은 다음과 같다.

- Level 1 hidden visual probe 구현 완료
- assert-only / read-only / non-owner boundary 유지
- visual consumer entry boundary 문서화 완료
- output contract가 helper 내부 internal validation contract로 제한됨
- `candidateSlots` / `candidateLabels`가 helper 내부 local candidate structure로 제한됨
- `candidateSlots` / `candidateLabels` public API 미승격
- output DTO/model 추가 없음
- persistence schema / route contract / shell contract 연결 없음
- production route 노출 없음
- `ExplorerWorkspace` shell mount 없음
- `main.dart`, `HomeScreen`, Navigator route 변경 없음
- Provider / Repository / Navigator / persistence authority migration 없음
- projection result persistence/history/source-of-truth usage 없음
- source-level test hardening 완료
- 관련 source-level test 통과
- 문서, 코드, 테스트의 Phase 8 boundary 설명 불일치 없음

#### 17.49.3 Level 1 hidden visual probe boundary 최종 상태

`lib/ui/word_explorer_screen.dart` 기준 hidden visual probe는 `WordExplorerScreen.build(...)` 안에서 build-local로 읽은 `_readOnlyWorkspaceProjection` snapshot을 debug `assert(() { ... }())` 내부에서만 소비한다.

최종 boundary는 다음 상태로 유지된다.

- `_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 private getter다.
- `_debugValidateHiddenVisualProbe(...)`는 `ExplorerWorkspaceState projection`을 입력으로 받는 private helper다.
- helper는 `candidateSlots`, `candidateLabels` local list를 구성하고 boolean 검증 결과만 반환한다.
- helper는 `setState`, `Navigator`, `WordRepository`, `Provider`, DB/persistence 접근, logging, async/future/stream 흐름을 수행하지 않는다.
- helper 결과는 production widget tree, route, shell state, persistence payload, history payload로 전달되지 않는다.
- `ExplorerWorkspace`는 이 경계에서 owner, controller, coordinator, production shell mount 대상이 아니다.

#### 17.49.4 visual consumer entry boundary 최종 상태

Phase 8의 visual consumer entry boundary는 Level 1 hidden visual probe까지만 실제 구현된 상태로 종료 가능하다. Level 1은 production 노출 없이 read-only projection snapshot을 숨김 상태에서 검증하는 consumer이며, production UI diff를 만들지 않는다.

Level 2 production-adjacent visual consumer와 Level 3 production visible consumer는 Phase 8-H 기준으로 승인되지 않았다. Phase 8 종료는 Level 2 진입, Level 3 진입, production route 노출, runtime/UI integration, shell mount 승인으로 해석하지 않는다.

#### 17.49.5 output contract / candidate local structure 최종 상태

Phase 8-H 기준 hidden probe output contract는 public output contract가 아니라 `_debugValidateHiddenVisualProbe(...)` helper 내부 검증 계약이다.

- `candidateSlots`는 `projection.graphCenterWordId != null`이면 `graph`, `projection.detailTargetWordId != null`이면 `detail`을 담는 helper 내부 local list다.
- `candidateLabels`는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset.name`, `origin.name` 중 null이 아닌 projection 값을 담는 helper 내부 local list다.
- 두 candidate structure는 helper 밖으로 return되지 않는다.
- 두 candidate structure는 field, getter, public method, exported API, DTO/model, shell prop, route argument, persistence payload가 아니다.
- output contract라는 표현은 helper 내부 internal validation contract만 뜻한다.

#### 17.49.6 source-level test hardening 최종 상태

Phase 8-G에서 추가한 `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`는 Phase 8-E/F에서 정리한 non-contract boundary를 source-level로 고정한다.

관련 source-level test 범위는 다음과 같이 확인한다.

- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`
- `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`

Phase 8-G 종료 기록 기준 관련 테스트 결과는 `+15: All tests passed!`다. Phase 8-H에서는 같은 테스트 묶음을 재실행해 결과를 작업 종료 보고에 기록한다.

#### 17.49.7 flutter analyze 상태

전체 `flutter analyze`는 기존 저장소 이슈로 실패하는 상태다. Phase 8-H 감사 기록에서는 analyze 실패를 이번 문서 변경의 오류로 간주하지 않는다.

Phase 8-H의 변경 파일은 다음 두 문서로 제한되며, Dart analyzer 오류 대상 파일이 아니다.

- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`

작업 종료 보고에서는 전체 analyze 성공/실패 여부, 실패 시 기존 저장소 이슈 여부, 이번 변경 문서 2개가 analyzer 오류 목록에 포함되는지 여부를 분리해 기록한다.

#### 17.49.8 문서 / 코드 / 테스트 일치 여부

Phase 8-H 기준 문서, 코드, 테스트는 다음 기준에서 일치한다.

- 문서는 Level 1 hidden visual probe를 assert-only / read-only / non-owner boundary로 기록한다.
- 코드는 `_debugValidateHiddenVisualProbe(...)`를 `WordExplorerScreen.build(...)` 내부 assert-only 경계에서만 호출한다.
- 테스트는 helper 내부 candidate structure, helper 외부 미노출, public API / DTO/model 미추가, route/shell/persistence 미연결을 source-level로 확인한다.
- 문서는 Level 2 / Level 3 consumer, runtime/UI integration, production route 노출, shell mount, owner/authority migration을 승인하지 않는다.
- 코드와 테스트 변경 없이 Phase 8-H 문서 감사만 수행한다.

#### 17.49.9 Phase 8 종료 가능 여부 판단

Phase 8-H 기준으로 Phase 8은 종료 가능하다.

다만 Phase 8 종료는 Level 2 visual consumer 진입, production route 노출, `ExplorerWorkspace` shell mount, runtime/UI integration 승인을 의미하지 않는다. Phase 8 종료 가능 판단은 Level 1 hidden visual probe contract가 내부 검증 경계 안에서 안정화되었고, output contract가 public boundary로 승격되지 않았으며, 관련 source-level test와 문서 기록이 현재 코드 상태와 일치한다는 의미로 제한한다.

#### 17.49.10 여전히 승인되지 않은 항목

아래 항목은 Phase 8-H 이후에도 모두 `not approved` 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- ExplorerWorkspace shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider authority migration: `not approved`
- Repository authority migration: `not approved`
- Navigator authority migration: `not approved`
- persistence authority migration: `not approved`
- projection result persistence: `not approved`
- projection result history usage: `not approved`
- projection result source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.49.11 Phase 9 또는 다음 단계 후보 조건

Phase 8-H는 Phase 9 구현을 승인하지 않는다. Phase 8-H는 Level 2 production-adjacent visual consumer 진입, Level 3 production visible consumer 진입, runtime/UI integration, production route 노출, `ExplorerWorkspace` shell mount를 승인하지 않는다.

가능한 다음 단계 후보는 별도 Phase 9-A planning으로만 제한한다.

- Phase 9-A: Level 2 visual consumer entry boundary planning
- Phase 9-A: production-adjacent visual consumer risk audit
- Phase 9-A: ExplorerWorkspace shell mount precondition planning

Phase 9-A로 이동하려면 별도 설계, 수정 파일 목록, 검증 계획, 사용자 승인이 필요하다.

#### 17.49.12 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 8-H 목적이 termination/stabilization audit인지 확인 | Phase 8-H가 구현 단계가 아니라 종합 감사 단계로 기록되어야 함 | 기능 구현, 테스트 추가, runtime/UI integration 승인처럼 읽힘 | `rg -n "Phase 8-H|termination audit|stabilization audit" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| Phase 8-A~G 흐름이 누락 없이 요약되었는지 확인 | Phase 8-A부터 Phase 8-G까지 각 단계 목적이 요약되어야 함 | 특정 단계 누락 또는 구현 승인으로 오해되는 문장 | `rg -n "Phase 8-A|Phase 8-B|Phase 8-C|Phase 8-D|Phase 8-E|Phase 8-F|Phase 8-G" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Phase 8 종료 가능 여부가 명확히 기록되었는지 확인 | Phase 8-H 기준 Phase 8은 종료 가능하다고 기록되어야 함 | 종료 가능 여부가 모호하거나 과도한 완료 선언으로 기록됨 | `rg -n "종료 가능" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Phase 8 종료가 Level 2/Level 3 진입 승인으로 해석되지 않는지 확인 | Level 2 / Level 3 consumer가 `not approved`로 유지되어야 함 | production-adjacent 또는 visible consumer 진입 승인처럼 읽힘 | `rg -n "Level 2|Level 3|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 1 hidden visual probe boundary가 유지되는지 확인 | assert-only / read-only / non-owner boundary가 유지되어야 함 | helper가 owner, route, shell, persistence boundary로 해석됨 | `rg -n "Level 1|assert-only|read-only|non-owner" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `candidateSlots` / `candidateLabels` public API 미승격 상태가 유지되는지 확인 | 두 이름이 helper 내부 local structure로 기록되어야 함 | public API, field, getter, DTO/model, shell prop으로 해석됨 | `rg -n "candidateSlots|candidateLabels|public API" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| output DTO/model 추가가 없는지 확인 | output DTO/model addition이 `not approved`로 유지되어야 함 | output contract가 DTO/model 추가 승인처럼 읽힘 | `rg -n "DTO|output contract|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| production route 노출이 없는지 확인 | production route 노출이 승인되지 않아야 함 | route 노출 또는 Navigator 변경 승인처럼 읽힘 | `rg -n "production route|Navigator|route|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell mount가 없는지 확인 | shell mount가 `not approved`로 유지되어야 함 | shell mount 승인처럼 읽힘 | `rg -n "shell mount|ExplorerWorkspace shell mount|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| runtime/UI integration이 승인되지 않았는지 확인 | runtime/UI integration이 `not approved`로 유지되어야 함 | UI 연결 승인처럼 읽힘 | `rg -n "runtime/UI integration|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 코드/test/platform 변경이 없는지 확인 | 변경 파일은 문서 2개만 있어야 함 | `lib/`, `test/`, platform 경로 변경 발생 | `git diff --name-only` 및 `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| 관련 flutter test 결과 확인 | Phase 7-F/8-C/8-G source-level test가 통과해야 함 | 관련 boundary test 실패 | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| flutter analyze 기존 이슈 상태가 이번 문서 변경과 분리되어 보고되는지 확인 | analyze 실패 시 기존 저장소 이슈와 문서 변경 영향을 구분해야 함 | 문서 변경이 analyzer 실패 원인처럼 보고됨 | `flutter analyze` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 8-H 문서/audit 작업의 대상이 아니다.

### 17.50 Phase 9-A Level 2 visual consumer entry boundary planning

Phase 9-A는 Level 2를 구현하는 단계가 아니다. 이번 단계의 목적은 Phase 8-H에서 종료 가능하다고 판단한 Level 1 hidden visual probe contract를 유지한 채, 이후 Level 2 visual consumer 검토에 들어가기 전 필요한 진입 조건과 금지선을 문서화하는 것이다.

Phase 9-A는 runtime/UI integration, production route 노출, `ExplorerWorkspace` shell mount, production UI diff, owner authority migration을 승인하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.50.1 Phase 9-A 판단

Phase 9-A의 판단은 다음과 같이 제한한다.

- Phase 9-A는 Level 2 visual consumer 구현 단계가 아니다.
- Phase 9-A는 Level 2 진입 조건을 정의하는 planning 단계다.
- Phase 9-A는 Phase 8-H 종료 판단을 확장해 production-adjacent visual consumer를 승인하지 않는다.
- Phase 9-A는 `ExplorerWorkspace` shell mount를 승인하지 않는다.
- Phase 9-A는 production UI diff를 승인하지 않는다.
- Phase 9-A는 코드, 테스트, route, shell, Provider, Repository, Navigator, persistence 구현 변경을 포함하지 않는다.

#### 17.50.2 Level 2 visual consumer 임시 정의

Level 2 visual consumer는 후속 단계에서 검토할 수 있는 production-adjacent visual consumer 후보를 가리키는 임시 planning 용어다.

임시 정의는 다음 범위로 제한한다.

- Level 2는 Level 1 hidden visual probe보다 production 구조에 가까운 visual consumer 후보를 뜻한다.
- Level 2는 사용자가 보는 production UI surface 또는 production route 노출을 뜻하지 않는다.
- Level 2는 read-only projection snapshot 또는 helper 내부 visual candidate 해석 가능성을 소비할 수 있는 후보 경계를 검토하는 이름일 뿐이다.
- Level 2는 owner, controller, coordinator, repository read owner, route owner, shell owner, persistence owner가 아니다.
- Level 2 진입 검토는 별도 승인 전에는 구현, mount, route wiring, public API, DTO/model, persistence schema로 이어지지 않는다.

이 정의는 Phase 9-A 안에서만 임시로 사용한다. 이후 Phase에서 Level 2 후보를 실제 구현 대상으로 다루려면 별도 설계, 수정 파일 목록, 명령어 기반 검증 계획, UI 확인 절차, 사용자 승인이 필요하다.

#### 17.50.3 Level 2 진입 사전 조건

Level 2 검토로 이동하기 전에는 다음 조건이 먼저 충족되어야 한다.

- Phase 8-H 기준 Level 1 hidden visual probe가 assert-only / read-only / non-owner boundary 안에 머무르는지 다시 확인한다.
- `candidateSlots`, `candidateLabels`가 helper 내부 local candidate structure에만 머무르는지 확인한다.
- Level 2 후보가 읽을 수 있는 입력은 read-only projection snapshot 또는 그에 대한 문서상 해석으로 제한한다.
- Level 2 후보가 production widget tree, route argument, shell prop, Provider state, Repository return value, Navigator payload, persistence payload를 새 public contract로 만들지 않는다는 기준을 먼저 고정한다.
- Level 2 후보의 위치가 hidden, preview-only, production-adjacent 중 어디에 속하는지 별도 문서 또는 승인 단계에서 구분한다.
- production UI diff가 필요한 경우 Phase 9-A 범위에서 다루지 않고 별도 명시 승인 단계로 분리한다.
- `ExplorerWorkspace` shell mount를 검토하려면 먼저 shell mount precondition을 문서화해야 하며, precondition 문서화는 shell mount 승인으로 해석하지 않는다.
- 검증 계획은 command 기반 확인과 사용자가 수행할 UI 확인 절차를 분리해서 제시해야 한다.

#### 17.50.4 Level 1 hidden visual probe boundary 유지 조건

Phase 9-A 이후에도 Level 1 hidden visual probe는 다음 조건을 유지해야 한다.

- `_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 private read-only projection boundary로 유지한다.
- `_debugValidateHiddenVisualProbe(...)`는 private helper로 유지한다.
- helper 호출은 debug `assert` 내부로 제한한다.
- helper는 `setState`, `Navigator`, `WordRepository`, `Provider`, DB/persistence, logging, async/future/stream 흐름을 수행하지 않는다.
- helper 결과는 production widget tree, route, shell state, persistence payload, history payload, source of truth로 전달하지 않는다.
- `candidateSlots`, `candidateLabels`는 helper 내부 local candidate structure로만 유지한다.

특히 `candidateSlots`, `candidateLabels` 같은 구조는 public API, DTO, persistence schema, route contract, shell contract로 승격되면 안 된다.

#### 17.50.5 production-adjacent visual consumer 검토 위험 요소

production-adjacent visual consumer 검토 시 주요 위험은 다음과 같다.

- hidden consumer가 production widget tree에 가까워지면서 production UI diff를 우회적으로 만들 수 있다.
- consumer가 projection snapshot을 읽는 수준을 넘어 owner 또는 coordinator처럼 해석될 수 있다.
- `ExplorerWorkspace` shell mount precondition 문서가 shell mount 승인으로 오해될 수 있다.
- candidate local structure가 public output DTO/model 또는 public API로 승격될 수 있다.
- route argument, shell prop, Provider state, Repository return value, Navigator payload, persistence payload로 projection result가 확장될 수 있다.
- `WordExplorerScreen` production owner와 `ExplorerWorkspace` candidate boundary가 같은 selection/detail/graph center state를 동시에 소유하는 shadow owner 상태가 생길 수 있다.
- production UI diff와 Level 2 검토가 같은 단계에 섞이면 사용자 승인 범위가 불명확해질 수 있다.
- projection result가 history payload 또는 source of truth처럼 쓰이면 Phase 8에서 보호한 read-only projection chain 의미가 깨질 수 있다.

#### 17.50.6 production UI diff와 ExplorerWorkspace shell mount 분리 원칙

사용자가 볼 수 있는 production UI 변경은 별도 명시 승인 단계에서만 다룬다. Phase 9-A는 production UI diff를 승인하지 않으며, Level 2 검토 문서가 production UI diff의 선승인 근거가 될 수 없다.

`ExplorerWorkspace` shell mount는 Phase 9-A 범위가 아니다. Phase 9-A에서 문서화할 수 있는 것은 shell mount 자체가 아니라 shell mount를 검토하기 위한 precondition뿐이다.

shell mount 검토 precondition 후보는 다음과 같이 제한한다.

- 현재 production owner가 `WordExplorerScreen`에 남아 있는지 확인한다.
- route stack과 workspace snapshot history를 통합할지 분리 유지할지 별도 판단한다.
- Provider / Repository / Navigator / persistence authority migration 여부를 별도 승인 대상으로 분리한다.
- shell mount가 필요한 production UI diff인지, hidden/preview-only 검증인지 먼저 구분한다.
- rollback 가능한 검증 단위와 command 기반 확인 항목을 먼저 정의한다.
- 사용자가 수행할 UI 기반 확인 절차를 별도 승인 단계에서 제시한다.

이 precondition 기록은 `ExplorerWorkspace` shell mount 승인, route 추가/변경 승인, production UI diff 승인, owner migration 승인으로 해석하지 않는다.

#### 17.50.7 Phase 9-A에서 여전히 승인되지 않은 항목

아래 항목은 Phase 9-A 이후에도 모두 `not approved` 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer implementation: `not approved`
- Level 3 production visible consumer: `not approved`
- production UI diff: `not approved`

#### 17.50.8 Phase 9-B 후보 범위와 Phase 9-A 제외 범위

Phase 9-B에서 다룰 수 있는 후보는 다음 planning 또는 audit 범위로 제한한다.

- Level 2 candidate selection 기준 정리
- production-adjacent visual consumer risk audit 보강
- Level 2 후보가 필요로 하는 source-level guardrail 후보 정리
- production UI diff 별도 승인 절차 초안 정리
- `ExplorerWorkspace` shell mount precondition checklist 보강

Phase 9-A에서 다루지 않는 범위는 다음과 같다.

- Level 2 production-adjacent visual consumer 구현
- Level 3 production visible consumer 구현
- `ExplorerWorkspace` shell mount
- production route 노출
- route collapse
- production UI diff
- Provider / Repository / Navigator / persistence authority migration
- output DTO/model 추가
- public API 추가
- projection result persistence/history/source-of-truth 사용

Phase 9-B로 이동하려면 별도 설계, 수정 파일 목록, 검증 계획, 사용자 승인이 필요하다.

#### 17.50.9 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치 및 상태 확인 | Phase 9-A 작업 브랜치이며 변경 전후 상태를 확인할 수 있어야 함 | 다른 브랜치에서 작업하거나 예상하지 못한 변경이 섞임 | `git status --short --branch`, `git branch --show-current`, `git log -1 --oneline` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 변경 파일은 승인된 문서 2개여야 함 | `lib/`, `test/`, platform 경로 또는 새 문서가 포함됨 | `git diff --stat`, `git diff -- docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| Phase 9-A 반영 확인 | 두 문서에 Phase 9-A 기록이 있어야 함 | Phase 9-A 기록 누락 또는 구현 승인처럼 읽히는 문장 | `rg -n "Phase 9-A" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| Level 2 진입 경계 확인 | Level 2가 구현이 아니라 진입 조건 정의로 기록되어야 함 | Level 2 implementation 승인처럼 읽힘 | `rg -n "Level 2" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | 요청된 항목이 `not approved`로 유지되어야 함 | shell mount, production UI diff, owner migration, public API 추가 승인처럼 읽힘 | `rg -n "not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 코드 변경 없음 확인 | 변경 파일 목록이 승인된 문서 2개만 포함해야 함 | 코드, 테스트, platform 변경 발생 | `git diff --name-only` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 9-A 문서/planning 작업의 대상이 아니다.

### 17.51 Phase 9-B Level 2 visual consumer candidate selection boundary

Phase 9-B는 Level 2 visual consumer를 구현하는 단계가 아니다. 이번 단계의 목적은 Phase 9-A에서 정의한 Level 2 진입 조건을 바탕으로, 어떤 후보를 Level 2 visual consumer 후보로 검토할 수 있는지 선정 기준과 금지선을 문서화하는 것이다.

Phase 9-B의 후보 선정은 implementation approval, production exposure approval, route approval, shell mount approval, authority migration approval을 뜻하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.51.1 Level 2 후보 선정 기준

Level 2 visual consumer 후보는 다음 기준을 모두 만족할 때만 문서상 후보로 기록할 수 있다.

- Level 1 hidden visual probe가 유지하는 read-only projection snapshot 의미를 깨지 않는다.
- 후보 입력은 `ExplorerWorkspaceState` read-only projection snapshot 또는 문서상 해석 가능한 helper-local candidate 의미로 제한한다.
- 후보는 production visible UI surface가 아니며, production route에 노출되지 않는다.
- 후보는 `WordExplorerScreen` production owner state를 대체하거나 병행 소유하지 않는다.
- 후보는 `ExplorerWorkspace`를 owner, controller, coordinator, shell owner로 승격하지 않는다.
- 후보는 projection result를 persistence, history payload, source of truth, runtime policy state로 사용하지 않는다.
- 후보 선정은 Phase 9-C 이후 source-level guardrail 검토 후보를 남기는 수준으로 제한한다.

Phase 9-B에서 특정 후보를 기록하더라도 그 후보는 production 적용 대상이 아니다. 후보 기록은 후속 검토 대상을 좁히는 문서상 classification일 뿐이며, 구현하려면 별도 승인 단계가 필요하다.

#### 17.51.2 production-adjacent 후보가 가져서는 안 되는 권한

production-adjacent visual consumer 후보는 다음 권한을 가져서는 안 된다.

- selection, graph center, detail target ownership
- route push, route replacement, route alias execution, route collapse 결정 권한
- Provider state read/write authority 또는 Provider wiring authority
- Repository read/write authority
- Navigator authority
- DB, file, cache, persistence authority
- history snapshot 생성, 저장, 복원 authority
- public API, DTO/model, route argument, shell prop 정의 authority
- production UI exposure 또는 production UI diff 결정 권한

Level 2 후보가 위 권한 중 하나라도 필요해지는 경우, Phase 9-B 후보 선정 범위에서 제외하고 별도 설계와 별도 승인 대상으로 분리해야 한다.

#### 17.51.3 Level 1 boundary를 유지한 Level 2 후보 정의 기준

Level 2 후보 정의는 Level 1 hidden visual probe boundary를 약화하지 않는 방식으로만 가능하다.

유지 조건은 다음과 같다.

- `_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 private read-only projection boundary로 유지한다.
- `_debugValidateHiddenVisualProbe(...)`는 private helper로 유지한다.
- `candidateSlots`, `candidateLabels`는 helper 내부 local candidate structure로 유지한다.
- helper 호출은 debug `assert` 내부로 제한한다.
- helper 결과는 production widget tree, route, shell state, persistence payload, history payload, source of truth로 전달하지 않는다.
- Level 2 후보는 이 helper 내부 구조를 public output contract로 승격하지 않는다.

따라서 Phase 9-B에서 가능한 Level 2 후보 정의는 "read-only projection 의미를 생산 경로에 연결하지 않고 관찰 가능한 후보 경계"까지만 허용한다.

#### 17.51.4 후보 선정이 구현 승인으로 읽히지 않도록 하는 필수 문구

Level 2 후보를 문서에 기록할 때는 다음 제한 문구를 함께 사용해야 한다.

- `candidate only`
- `planning only`
- `not implementation approval`
- `not production exposure approval`
- `not shell mount approval`
- `not route approval`
- `not authority migration`
- `not public API`
- `not DTO/model`
- `not persistence contract`

한국어 설명에는 다음 의미를 함께 기록한다.

- 후보 선정은 구현 순서 확정이 아니다.
- 후보 선정은 production 적용 승인도 아니다.
- 후보 선정은 source-level guardrail 검토 대상을 좁히기 위한 문서상 분류다.
- 후보 선정 이후에도 code/test 변경은 별도 승인 없이는 수행하지 않는다.

#### 17.51.5 후보 선정 이후에도 유지되는 금지선

아래 항목은 Phase 9-B 이후에도 모두 `not approved` 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer implementation: `not approved`
- Level 3 production visible consumer: `not approved`
- production UI diff: `not approved`

#### 17.51.6 Phase 9-C 이후로 넘길 source-level guardrail 후보

Phase 9-C 이후 단계에서 검토할 수 있는 source-level guardrail 후보는 다음으로 제한한다.

- Level 2 후보 명칭이 public widget, public API, DTO/model로 확장되지 않았는지 확인하는 source-level guardrail
- `candidateSlots`, `candidateLabels`가 helper-local structure 밖으로 노출되지 않았는지 확인하는 guardrail
- `ExplorerWorkspace` shell mount, route wiring, Navigator call, Provider/Repository reference가 추가되지 않았는지 확인하는 guardrail
- projection result가 field, history payload, persistence payload, source of truth로 저장되지 않았는지 확인하는 guardrail
- production UI diff가 발생하지 않았는지 확인하는 path-level guardrail

Phase 9-C 후보는 source-level guardrail 검토 후보일 뿐이며, Phase 9-B는 테스트 파일 생성이나 수정도 승인하지 않는다.

#### 17.51.7 별도 승인 대상으로 유지할 범위

다음 항목은 Phase 9-B 문서화와 분리된 별도 승인 대상으로 유지한다.

- production UI diff
- `ExplorerWorkspace` shell mount
- route 추가, route 변경, route collapse
- `main.dart`, `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen` production entry 변경
- Provider / Repository / Navigator / persistence authority migration
- output DTO/model 추가
- public API 추가
- Level 2 production-adjacent visual consumer 구현
- Level 3 production visible consumer 구현

이 항목 중 하나라도 필요해지는 경우 Phase 9-B 범위에서 제외하고, 별도 설계, 수정 파일 목록, command 기반 검증 계획, 사용자 UI 확인 절차, 사용자 승인을 먼저 받아야 한다.

#### 17.51.8 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치 및 상태 확인 | Phase 9-B 작업 브랜치이며 clean main에서 분기했음을 확인할 수 있어야 함 | 다른 브랜치 또는 uncommitted 변경에서 작업함 | `git status --short --branch`, `git branch --show-current`, `git log -1 --oneline` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 변경 파일은 승인된 문서 2개여야 함 | `lib/`, `test/`, platform 경로 또는 새 문서가 포함됨 | `git diff --stat`, `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | markdown diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| Phase 9-B 반영 확인 | 두 문서에 Phase 9-B 기록이 있어야 함 | Phase 9-B 기록 누락 또는 구현 승인처럼 읽히는 문장 | `rg -n "Phase 9-B" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| Level 2 후보 선정 경계 확인 | Level 2가 구현이 아니라 후보 선정 기준으로 기록되어야 함 | Level 2 implementation approval처럼 읽힘 | `rg -n "Level 2 visual consumer" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | 요청된 항목이 `not approved`로 유지되어야 함 | shell mount, production UI diff, owner migration, public API 추가 승인처럼 읽힘 | `rg -n "not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 별도 승인 대상 유지 확인 | production UI diff, shell mount, route collapse, owner migration이 별도 승인 대상으로 남아야 함 | Phase 9-B 안에서 승인처럼 기록됨 | `rg -n "production UI diff|shell mount|route collapse|owner migration" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트와 `flutter test`는 이번 Phase 9-B 문서/audit 작업의 필수 범위가 아니다.

### 17.52 Phase 9-C Level 2 visual consumer source-level guardrail planning

Phase 9-C는 source-level test 구현 단계가 아니다. 이번 단계의 목적은 Phase 9-B에서 정리한 Level 2 visual consumer 후보 선정 기준을 보호하기 위해 어떤 source-level guardrail 후보를 후속 단계에서 검토할 수 있는지 문서화하는 것이다.

Phase 9-C의 guardrail planning은 test implementation approval, Level 2 implementation approval, production exposure approval, shell mount approval, route approval, authority migration approval을 뜻하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.52.1 public boundary 승격 방지 guardrail 후보

Phase 9-D 이후에 검토할 수 있는 public boundary 승격 방지 guardrail 후보는 다음으로 제한한다.

- Level 2 후보 명칭이 public widget class로 추가되지 않았는지 확인하는 source-level guardrail 후보
- Level 2 후보가 exported public API로 추가되지 않았는지 확인하는 guardrail 후보
- Level 2 후보가 output DTO 또는 model로 추가되지 않았는지 확인하는 guardrail 후보
- Level 2 후보가 route argument, route contract, shell prop, shell contract로 연결되지 않았는지 확인하는 guardrail 후보
- hidden probe output contract가 public output contract처럼 확장되지 않았는지 확인하는 guardrail 후보

이 항목은 Phase 9-D 이후 source-level test hardening 후보일 뿐이다. Phase 9-C는 public API, DTO, model, route contract, shell contract 추가를 승인하지 않는다.

#### 17.52.2 `candidateSlots` / `candidateLabels` helper-local 유지 guardrail 후보

`candidateSlots`, `candidateLabels`는 계속 `_debugValidateHiddenVisualProbe(...)` 내부 local candidate structure로만 유지해야 한다.

Phase 9-D 이후에 검토할 수 있는 guardrail 후보는 다음과 같다.

- `candidateSlots`, `candidateLabels`가 helper 본문 내부 local variable로만 존재하는지 확인하는 guardrail 후보
- `_WordExplorerScreenState` field, getter, public method, constructor argument, widget prop으로 노출되지 않았는지 확인하는 guardrail 후보
- helper 반환값이 candidate output이 아니라 boolean 검증 결과로 유지되는지 확인하는 guardrail 후보
- `candidateSlots`, `candidateLabels`가 route arguments, shell state, persistence payload, history payload로 전달되지 않았는지 확인하는 guardrail 후보

Phase 9-C는 이 guardrail 후보를 문서화할 뿐이며, 테스트 파일 생성이나 수정은 승인하지 않는다.

#### 17.52.3 projection result persistence/history/source-of-truth 방지 guardrail 후보

Phase 9-D 이후에 검토할 수 있는 projection result guardrail 후보는 다음으로 제한한다.

- `_readOnlyWorkspaceProjection` 결과가 field/cache/history/source of truth로 저장되지 않는지 확인하는 guardrail 후보
- projection result가 persistence payload, history payload, route payload, shell state로 전달되지 않는지 확인하는 guardrail 후보
- projection result가 Provider state, Repository return value, Navigator payload로 승격되지 않았는지 확인하는 guardrail 후보
- projection result가 runtime policy state 또는 canonical owner state로 해석되는 이름으로 확장되지 않았는지 확인하는 guardrail 후보

Phase 9-C는 projection result persistence/history/source-of-truth usage를 승인하지 않는다.

#### 17.52.4 shell / route / Navigator / Provider / Repository 참조 방지 guardrail 후보

Phase 9-D 이후에 검토할 수 있는 source-level guardrail 후보는 다음으로 제한한다.

- `WordExplorerScreen` production path에 `ExplorerWorkspace` shell mount가 추가되지 않았는지 확인하는 guardrail 후보
- route wiring, route registration, route argument, route collapse 관련 코드가 추가되지 않았는지 확인하는 guardrail 후보
- `Navigator` call 또는 Navigator owner 변경이 추가되지 않았는지 확인하는 guardrail 후보
- `Provider` wiring 또는 Provider state authority가 추가되지 않았는지 확인하는 guardrail 후보
- `Repository` import, read call, write call, repository owner 변경이 추가되지 않았는지 확인하는 guardrail 후보
- DB, cache, persistence import 또는 persistence write/read 흐름이 추가되지 않았는지 확인하는 guardrail 후보

이 항목은 source-level inspection 후보일 뿐이며, Phase 9-C에서 route, shell, Navigator, Provider, Repository, persistence 구현 변경을 수행하지 않는다.

#### 17.52.5 production UI diff 방지 path-level guardrail 후보

Phase 9-D 이후에 검토할 수 있는 production UI diff 방지 guardrail 후보는 다음으로 제한한다.

- `lib/` production UI 경로 변경이 없는지 확인하는 path-level guardrail 후보
- `test/` 변경이 source-level test hardening 승인 없이 추가되지 않았는지 확인하는 guardrail 후보
- `main.dart`, `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen` production entry 변경이 없는지 확인하는 guardrail 후보
- platform 경로 변경이 없는지 확인하는 guardrail 후보
- production visible UI surface, production route exposure, shell mount가 없는지 확인하는 guardrail 후보

Phase 9-C는 production UI diff를 승인하지 않는다.

#### 17.52.6 Phase 9-C 문서화 범위와 Phase 9-D 이후 후보 분리

Phase 9-C에서 문서화할 수 있는 것은 guardrail 후보의 목적, 금지선, 후속 검토 조건뿐이다.

Phase 9-C에서 수행하지 않는 항목은 다음과 같다.

- source-level test 구현
- test file 생성 또는 수정
- code file 수정
- guardrail test name 확정
- test assertion 구현 방식 확정
- Level 2 visual consumer 구현
- production UI diff
- route, shell, Navigator, Provider, Repository, persistence 구현 변경

Phase 9-D 이후로 넘길 수 있는 항목은 다음과 같이 제한한다.

- source-level test hardening 후보 검토
- guardrail test 대상 파일 후보 검토
- guardrail assertion 후보 검토
- 문서와 기존 source-level test의 coverage gap audit
- 테스트를 추가할 경우 별도 승인 절차 정의

Phase 9-D 이후 후보도 자동 승인 상태가 아니다. 별도 설계, 수정 파일 목록, command 기반 검증 계획, 사용자 승인 전에는 테스트 구현을 시작하지 않는다.

#### 17.52.7 guardrail planning 오해 방지 문구

Phase 9-C guardrail planning은 다음 의미로만 사용한다.

- `planning only`
- `guardrail candidate only`
- `not source-level test implementation approval`
- `not Level 2 implementation approval`
- `not production exposure approval`
- `not shell mount approval`
- `not route approval`
- `not authority migration`
- `not public API`
- `not DTO/model`
- `not persistence contract`

한국어 설명에는 다음 제한을 함께 기록한다.

- guardrail 후보 문서화는 test 구현 지시가 아니다.
- guardrail 후보 문서화는 Level 2 visual consumer 구현 승인이 아니다.
- guardrail 후보 문서화는 production UI, route, shell, owner authority 변경 승인이 아니다.
- guardrail 후보는 Phase 9-D 이후 별도 승인 전까지 문서상 검토 후보로만 남긴다.

#### 17.52.8 유지되는 금지선

아래 항목은 Phase 9-C 이후에도 모두 `not approved` 상태로 유지한다.

- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- source-level test implementation: `not approved`
- Level 2 production-adjacent visual consumer implementation: `not approved`
- Level 3 production visible consumer: `not approved`
- production UI diff: `not approved`

#### 17.52.9 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치 및 상태 확인 | Phase 9-C 작업 브랜치이며 clean main에서 분기했음을 확인할 수 있어야 함 | 다른 브랜치 또는 uncommitted 변경에서 작업함 | `git status --short --branch`, `git branch --show-current`, `git log -1 --oneline` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 변경 파일은 승인된 문서 2개여야 함 | `lib/`, `test/`, platform 경로 또는 새 문서가 포함됨 | `git diff --stat`, `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | markdown diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| Phase 9-C 반영 확인 | 두 문서에 Phase 9-C 기록이 있어야 함 | Phase 9-C 기록 누락 또는 구현 승인처럼 읽히는 문장 | `rg -n "Phase 9-C" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| source-level guardrail 후보 확인 | guardrail이 구현이 아니라 후보로 기록되어야 함 | test implementation approval처럼 읽힘 | `rg -n "source-level guardrail|guardrail" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| `candidateSlots` / `candidateLabels` 경계 확인 | helper-local 유지가 기록되어야 함 | public API, DTO, field, getter, shell contract로 해석됨 | `rg -n "candidateSlots|candidateLabels" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| public boundary 미승격 확인 | public API / DTO / model / route contract / shell contract 추가가 승인되지 않아야 함 | public contract 추가 승인처럼 읽힘 | `rg -n "public API|DTO|model|route contract|shell contract" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | 요청된 항목이 `not approved`로 유지되어야 함 | source-level test 구현, Level 2 구현, production UI diff 승인처럼 읽힘 | `rg -n "not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| shell/route/owner 경계 확인 | production UI diff, shell mount, route wiring, Navigator, Provider, Repository, persistence가 미승인 상태로 남아야 함 | runtime wiring 승인처럼 읽힘 | `rg -n "production UI diff|shell mount|route wiring|Navigator|Provider|Repository|persistence" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트와 `flutter test`는 이번 Phase 9-C 문서/audit 작업의 필수 범위가 아니다.

### 17.53 Phase 9-D Level 2 source-level guardrail test hardening target audit

Phase 9-D는 source-level test implementation 단계가 아니다. 이번 단계의 목적은 Phase 9-C에서 문서화한 Level 2 visual consumer source-level guardrail 후보를 기존 테스트가 어디까지 보호하는지 확인하고, 이후 source-level test hardening 대상 후보를 audit으로 분리하는 것이다.

Phase 9-D audit은 테스트 구현 승인, 새 테스트 파일 생성 승인, code file modification 승인, Level 2 production-adjacent visual consumer implementation 승인, production UI diff 승인, shell mount 승인, route wiring 승인, authority migration 승인을 뜻하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.53.1 기존 관련 테스트 파일 목록과 역할

이번 audit에서 확인한 관련 테스트 파일은 다음 세 개다.

| 테스트 파일 | 현재 역할 |
| --- | --- |
| `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` | `_readOnlyWorkspaceProjection` private getter, build-local read, projection result field/history 미저장, projection boundary 내부 forbidden marker 차단을 확인한다. |
| `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | `_debugValidateHiddenVisualProbe(...)` helper가 assert-only 호출 안에 있고, read-only projection을 visual candidate input으로만 소비하며, helper 내부 side effect와 shell mount / production route entry 변경이 없는지 확인한다. |
| `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | `candidateSlots`, `candidateLabels` helper-local boundary, public API / DTO / model marker 미노출, route / shell / persistence contract 미연결, assert-only / read-only / non-owner boundary를 source-level로 보강한다. |

이 목록은 기존 테스트 역할을 정리하는 audit이다. Phase 9-D는 위 테스트를 수정하거나 새 테스트를 생성하지 않는다.

#### 17.53.2 현재 테스트가 커버하는 guardrail 요약

현재 테스트가 이미 커버하는 guardrail은 다음으로 정리한다.

- projection boundary:
  - `_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 private getter로 확인된다.
  - projection snapshot은 `build()` 내부 local read와 debug assert 소비로 제한된다.
  - projection result는 field, cache, history payload, source of truth로 저장되지 않는지 확인된다.
- hidden visual probe assert-only / read-only boundary:
  - `_debugValidateHiddenVisualProbe(...)`는 private helper로 확인된다.
  - helper 호출은 `assert(() { ... })` 내부에 있어야 한다.
  - helper 내부에는 `setState`, `Navigator`, `WordRepository`, `Provider`, DB/persistence, async/future/stream, logging marker가 없어야 한다.
- `candidateSlots`, `candidateLabels` helper-local boundary:
  - 두 이름은 helper 본문 내부 local variable로 존재해야 한다.
  - helper 외부 source와 `_WordExplorerScreenState` field 영역에는 두 이름이 없어야 한다.
  - helper 반환값은 candidate output이 아니라 boolean 검증 결과로 유지된다.
- public API / DTO / model marker 노출 방지:
  - hidden probe output처럼 읽히는 public class, typedef, getter, named argument marker가 제한된 public boundary source에 없어야 한다.
  - `candidateSlots`, `candidateLabels`가 public getter, constructor argument, DTO/model field marker로 노출되지 않아야 한다.
- shell mount / route / persistence 연결 방지:
  - `WordExplorerScreen`은 `explorer_workspace.dart` shell을 import하거나 `ExplorerWorkspace(`를 mount하지 않아야 한다.
  - `main.dart`와 `home_screen.dart`는 hidden probe helper 또는 candidate structure를 알지 않아야 한다.
  - candidate structure는 payload, arguments, shell state, persistence value로 전달되지 않아야 한다.

이 커버리지는 Level 1 hidden visual probe boundary와 Phase 9-C guardrail 후보 일부를 보호한다. 다만 이 audit은 현재 테스트 커버리지를 기록하는 것이며 추가 assertion 구현을 승인하지 않는다.

#### 17.53.3 Phase 9-C guardrail 후보 중 이미 커버된 항목

Phase 9-C에서 문서화한 guardrail 후보 중 이미 기존 테스트가 커버하는 항목은 다음과 같다.

- `candidateSlots`, `candidateLabels`가 helper-local structure 밖으로 노출되지 않는지 확인하는 guardrail
- `_readOnlyWorkspaceProjection` 결과가 field/cache/history payload/source of truth로 저장되지 않는지 확인하는 guardrail
- hidden probe helper가 assert-only / read-only / non-owner boundary 안에 머무르는지 확인하는 guardrail
- helper 내부에서 Navigator, Provider, Repository, DB/persistence, async/future/stream 흐름이 추가되지 않는지 확인하는 guardrail
- `WordExplorerScreen` production path에 `ExplorerWorkspace` shell mount가 추가되지 않는지 확인하는 guardrail
- `main.dart`, `home_screen.dart`, workspace contract, workspace shell source에 helper/candidate marker가 노출되지 않는지 확인하는 guardrail
- hidden probe output이 public API / DTO / model marker로 승격되지 않는지 확인하는 guardrail

이미 커버된 항목은 기존 Phase 7-F / 8-C / 8-G 테스트의 보호 범위로만 해석한다. Phase 9-D는 이 테스트를 확장하지 않는다.

#### 17.53.4 아직 커버되지 않은 coverage gap 후보

Phase 9-C guardrail 후보 중 아직 테스트로 충분히 일반화되지 않은 coverage gap 후보는 다음과 같다.

- 전체 `lib/`의 model / DTO / public export 경로까지 포괄하는 guardrail이 부족하다.
- 전체 route wiring / route registration 변화까지 일반화한 guardrail이 부족하다.
- future Level 2 production-adjacent path 전체에 대한 Navigator / Provider / Repository / persistence 참조 방지 guardrail이 부족하다.
- production UI diff는 source-level test만으로 완전 판정하기 어렵고, path-level audit 확인이 계속 필요하다.
- production entry 변경, platform 경로 변경, route registration 변경은 source marker test와 `git diff --name-only -- lib test android ios macos windows linux web` 확인을 함께 사용해야 한다.

위 gap은 Phase 9-D audit 결과로만 남긴다. gap 기록은 source-level test hardening implementation approval이 아니며, gap마다 별도 설계와 사용자 승인이 필요하다.

#### 17.53.5 테스트 구현 방향 후보

테스트 구현이 별도 승인될 경우의 방향 후보는 다음과 같이 제한한다.

- 우선 후보는 기존 `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` 보강이다.
- 기존 Phase 8-G 테스트 보강은 helper-local, public boundary, route/shell/persistence 미연결 guardrail을 같은 문맥에서 유지할 수 있다는 장점이 있다.
- 별도 추적이 필요한 경우 Phase 9 전용 새 테스트 파일 후보를 둘 수 있지만, Phase 9-D에서는 새 테스트 파일명, test name, assertion 구현 방식을 확정하지 않는다.
- path-level production UI diff 확인은 source-level test만으로 대체하지 않고 command 기반 audit 항목으로 유지한다.

Phase 9-D는 실제 assertion 추가를 승인하지 않는다. 테스트 파일 생성/수정은 별도 승인 단계에서만 검토한다.

#### 17.53.6 이후 별도 승인 단계 원칙

Phase 9-D audit 결과를 바탕으로 source-level test hardening이 필요하다고 판단되더라도, 다음 항목이 별도로 승인되기 전에는 구현을 시작하지 않는다.

- source-level test hardening 대상 파일
- test name 또는 group name
- assertion 후보와 forbidden marker 목록
- command 기반 검증 계획
- 변경 파일 목록
- production UI diff 없음 확인 절차
- 사용자 승인

따라서 Phase 9-D는 이후 작업의 target audit일 뿐이며, Phase 9-D 자체가 source-level test hardening branch 또는 implementation branch로 전환되지 않는다.

#### 17.53.7 Phase 9-D에서 제외되는 범위

Phase 9-D에서 명시적으로 제외되는 범위는 다음과 같다.

- source-level test implementation
- test file creation/modification
- code file modification
- 실제 assertion 추가
- 새 test name 확정
- route, shell, Navigator, Provider, Repository, persistence 구현 변경
- `ExplorerWorkspace` shell mount
- production UI diff
- Level 2 production-adjacent visual consumer implementation
- Level 3 production visible consumer implementation
- output DTO/model addition
- public API addition

#### 17.53.8 유지되는 금지선

아래 항목은 Phase 9-D 이후에도 모두 `not approved` 상태로 유지한다.

- source-level test implementation: `not approved`
- test file creation/modification: `not approved`
- code file modification: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route collapse: `not approved`
- route wiring / route registration change: `not approved`
- canonical owner migration: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- Level 2 production-adjacent visual consumer implementation: `not approved`
- Level 3 production visible consumer: `not approved`
- production UI diff: `not approved`

#### 17.53.9 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치 및 상태 확인 | Phase 9-D 작업 브랜치이며 clean main에서 분기했음을 확인할 수 있어야 함 | 다른 브랜치 또는 uncommitted 변경에서 작업함 | `git status --short --branch`, `git branch --show-current`, `git log -1 --oneline` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 변경 파일은 승인된 문서 2개여야 함 | `lib/`, `test/`, platform 경로 또는 새 문서가 포함됨 | `git diff --stat`, `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | markdown diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| Phase 9-D 반영 확인 | 두 문서에 Phase 9-D 기록이 있어야 함 | Phase 9-D 기록 누락 또는 구현 승인처럼 읽히는 문장 | `rg -n "Phase 9-D" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 기존 테스트 파일 기록 확인 | 세 테스트 파일명이 Phase 9-D audit에 기록되어야 함 | 관련 테스트 역할 누락 | `rg -n "word_explorer_screen_phase7f_projection_boundary_test|word_explorer_screen_phase8c_hidden_visual_probe_test|word_explorer_screen_phase8g_hidden_probe_contract_hardening_test" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| coverage gap / guardrail 확인 | coverage gap과 guardrail 후보가 구현 지시가 아니라 audit으로 기록되어야 함 | source-level test implementation approval처럼 읽힘 | `rg -n "coverage gap|guardrail|source-level test hardening|not approved" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| Level 2 guardrail marker 확인 | candidateSlots, candidateLabels, public API, DTO, model, route wiring, route registration, Navigator, Provider, Repository, persistence, production UI diff가 경계 문맥에서 기록되어야 함 | Level 2 구현 승인 또는 runtime wiring 승인처럼 읽힘 | `rg -n "candidateSlots|candidateLabels|public API|DTO|model|route wiring|route registration|Navigator|Provider|Repository|persistence|production UI diff" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 코드/test/platform 변경 없음 확인 | `lib/`, `test/`, platform 경로 변경이 없어야 함 | 테스트 구현 또는 코드 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트와 `flutter test`는 이번 Phase 9-D 문서/audit 작업의 필수 범위가 아니다.

### 17.54 Phase 9-E Level 2 source-level guardrail test hardening

Phase 9-E는 production 구현 단계가 아니다. 이번 단계의 목적은 Phase 9-D에서 확인한 coverage gap 중 기존 source-level test 패턴으로 보강할 수 있는 항목만 제한적으로 고정하는 것이다.

Phase 9-E는 Level 2 visual consumer implementation, `ExplorerWorkspace` shell mount, production UI diff, route/shell/Navigator/Provider/Repository/persistence 구현 변경, output DTO/model 추가, public API 추가를 승인하지 않는다. 변경 범위는 기존 Phase 8-G source-level test 보강과 이 문서, `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.54.1 보강 대상 선택

Phase 9-E에서는 새 테스트 파일을 만들지 않고 기존 `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`를 보강한다.

이 선택의 이유는 다음과 같다.

- Phase 8-G 테스트가 이미 `candidateSlots`, `candidateLabels` helper-local boundary를 source-level로 확인한다.
- Phase 8-G 테스트가 이미 public API / DTO / model marker 미노출, route / shell / persistence contract 미연결, assert-only / read-only / non-owner boundary를 같은 문맥에서 확인한다.
- Phase 9-D coverage gap 중 candidate marker의 public surface 누출과 production entry marker 노출은 기존 Phase 8-G 파일의 source-read 패턴을 확장하는 방식으로 확인할 수 있다.
- 새 테스트 파일을 만들면 Phase 9-D에서 확정하지 않았던 새 test file / test name / assertion 구현 방식을 별도 설계 없이 고정하는 효과가 있으므로 이번 범위에서 제외한다.

#### 17.54.2 추가된 source-level guardrail

Phase 9-E에서 보강한 guardrail은 다음으로 제한한다.

- `candidateSlots`, `candidateLabels`가 helper 본문 밖의 `lib/**/*.dart` public surface에 노출되지 않는지 확인한다.
- candidate output marker가 public API, DTO, model, public export, route contract, shell contract 성격의 surface로 승격되지 않는지 확인한다.
- `main.dart`, `home_screen.dart`, workspace contract source, workspace shell source에 hidden probe helper 또는 candidate marker가 production entry처럼 노출되지 않는지 확인한다.
- `main.dart`의 기본 production entry가 `home: const HomeScreen()` 상태를 유지하고, Phase 9-E 범위에서 `routes:` 또는 `onGenerateRoute` route registration이 추가되지 않았는지 확인한다.
- 전체 `lib/`에서 `ExplorerWorkspace(`를 단순 금지하지 않는다. 기존 preview 경로와 충돌할 수 있으므로 production entry / main / home / contract / shell 중심의 marker guardrail로 제한한다.

#### 17.54.3 production UI diff 판정 방식

production UI diff는 source-level test만으로 완전 판정하지 않는다.

Phase 9-E에서는 다음 두 검증을 함께 사용한다.

- source-level test: hidden probe와 candidate marker가 public surface, production entry, route contract, shell contract로 노출되지 않는지 확인한다.
- path-level audit: `git diff --name-only -- lib android ios macos windows linux web` 결과가 비어 있는지 확인해 production code와 platform 경로 변경이 없음을 확인한다.

따라서 Phase 9-E의 source-level test 통과는 production UI diff 없음의 보조 근거일 뿐이며, production UI 변경 승인으로 해석하지 않는다.

#### 17.54.4 변경 범위

Phase 9-E에서 수정한 파일 범위는 다음으로 제한한다.

- `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`

`lib/`, `android`, `ios`, `macos`, `windows`, `linux`, `web` 경로는 수정하지 않는다.

#### 17.54.5 유지되는 금지선

아래 항목은 Phase 9-E 이후에도 모두 `not approved` 상태로 유지한다.

- route/shell/Navigator/Provider/Repository/persistence 구현 변경: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- production UI diff: `not approved`
- Level 2 visual consumer implementation: `not approved`
- Level 3 production visible consumer implementation: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- route wiring / route registration change: `not approved`
- canonical owner migration: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`

#### 17.54.6 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치 및 상태 확인 | Phase 9-E 작업 브랜치에서 변경을 수행해야 함 | 다른 브랜치 또는 uncommitted 변경이 섞임 | `git status --short --branch`, `git branch --show-current`, `git log -1 --oneline` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 변경 파일은 승인된 테스트 1개와 문서 2개여야 함 | `lib/`, platform 경로 또는 새 테스트 파일이 포함됨 | `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| source-level test 검증 | Phase 7-F / 8-C / 8-G guardrail 테스트가 통과해야 함 | candidate marker 누출, route/shell/persistence 연결, helper owner marker 추가 | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| guardrail marker 확인 | candidate/public/route/owner/persistence marker가 테스트와 문서에 경계 문맥으로 남아야 함 | Level 2 구현 승인 또는 production wiring 승인처럼 읽힘 | `rg -n "candidateSlots|candidateLabels|public API|DTO|model|route wiring|route registration|Navigator|Provider|Repository|persistence|production UI diff|Phase 9-E" test lib docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| production path 변경 없음 확인 | `lib/`와 platform 경로 변경이 없어야 함 | production code 수정 또는 UI diff 발생 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 9-E source-level test hardening의 필수 범위가 아니다.

### 17.55 Phase 9-F Level 2 entry / candidate / guardrail hardening termination audit

Phase 9-F는 구현 단계가 아니다. 이번 단계의 목적은 Phase 9-A부터 Phase 9-E까지의 Level 2 entry / candidate / guardrail hardening 흐름을 종합해 Phase 9 전체가 종료 가능한지 audit으로 판단하는 것이다.

Phase 9-F audit은 Level 2 visual consumer implementation, `ExplorerWorkspace` shell mount, production UI diff, route/shell/Navigator/Provider/Repository/persistence 구현 변경, output DTO/model 추가, public API 추가를 승인하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.55.1 Phase 9-A~E 완료 항목 요약

Phase 9-A부터 Phase 9-E까지 완료된 항목은 다음으로 정리한다.

| 단계 | 완료된 항목 | 종료 audit 판단 |
| --- | --- | --- |
| Phase 9-A | Level 2 visual consumer 진입 조건 정의 | Level 2를 구현하지 않고 entry precondition만 문서화했다. |
| Phase 9-B | Level 2 visual consumer 후보 선정 경계 정의 | 후보 선정이 구현 승인으로 해석되지 않도록 candidate-only boundary를 고정했다. |
| Phase 9-C | source-level guardrail planning | public API / DTO / model / route contract / shell contract 승격 방지 후보를 planning으로만 정리했다. |
| Phase 9-D | guardrail test hardening target audit | 기존 Phase 7-F / 8-C / 8-G 테스트의 coverage와 remaining gap을 audit으로 분리했다. |
| Phase 9-E | 기존 Phase 8-G source-level test 제한 보강 | 새 테스트 파일 없이 기존 Phase 8-G 테스트 안에서 candidate marker public surface와 production entry marker guardrail을 보강했다. |

#### 17.55.2 Phase 9-E 테스트 보강 결과

Phase 9-E 테스트 보강 결과는 다음으로 제한해 해석한다.

- 보강은 기존 `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` 안에서만 수행했다.
- 새 테스트 파일은 생성하지 않았다.
- production code는 수정하지 않았다.
- `lib/`, `android`, `ios`, `macos`, `windows`, `linux`, `web` 경로는 수정하지 않았다.
- 관련 source-level test 실행 결과는 `+17: All tests passed!`로 확인됐다.
- 이 결과는 Level 1 hidden visual probe와 Level 2 후보 guardrail의 source-level 보호를 강화한 것이며, Level 2 production-adjacent visual consumer 구현 승인이 아니다.

#### 17.55.3 Phase 9에서 승인된 것과 승인되지 않은 것

Phase 9에서 승인된 것은 다음으로 제한한다.

- Level 2 진입 조건 문서화
- Level 2 후보 선정 기준 문서화
- Level 2 후보를 보호하기 위한 source-level guardrail planning 문서화
- guardrail test hardening target audit 문서화
- 기존 Phase 8-G source-level test의 제한적 보강

Phase 9에서 승인되지 않은 것은 다음으로 유지한다.

- Level 2 visual consumer implementation
- Level 3 production visible consumer implementation
- `ExplorerWorkspace` shell mount
- production UI diff
- route wiring / route registration change
- route / shell / Navigator / Provider / Repository / persistence 구현 변경
- Provider / Repository / Navigator / persistence authority migration
- output DTO/model addition
- public API addition
- projection result persistence/history/source-of-truth usage

#### 17.55.4 Phase 9 종료 후에도 유지되는 금지선

아래 항목은 Phase 9 종료 이후에도 모두 `not approved` 상태로 유지한다.

- Level 2 visual consumer implementation: `not approved`
- Level 3 production visible consumer: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- production UI diff: `not approved`
- route wiring / route registration change: `not approved`
- route / shell / Navigator / Provider / Repository / persistence 구현 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- output DTO/model addition: `not approved`
- public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`

#### 17.55.5 Phase 10 또는 후속 단계 후보

Phase 10 또는 후속 단계로 넘길 수 있는 후보는 다음으로 제한한다.

- Level 2 production-adjacent visual consumer 구현 여부 검토
- production UI diff 승인 절차 검토
- `ExplorerWorkspace` shell mount precondition checklist 검토
- route/shell/owner migration 여부 검토
- Level 2 후보가 production entry에 접근하기 전 필요한 command 기반 검증 계획 검토

위 항목은 모두 후보일 뿐이며, 별도 설계, 수정 파일 목록, command 기반 검증 계획, 사용자 승인 전까지는 `not approved` 상태로 유지한다.

#### 17.55.6 Phase 9 종료 가능 판단

현재 기준으로 Phase 9는 종료 가능 상태로 판단한다.

이 판단의 근거는 다음과 같다.

- Phase 9-A~E 문서가 Level 2 entry / candidate / guardrail hardening 흐름을 서로 연결해 기록하고 있다.
- Phase 9-E가 Phase 9-D coverage gap 일부를 기존 Phase 8-G source-level test 보강으로 연결했다.
- Phase 9-E 보강은 production 구현, shell mount, route wiring, owner migration, production UI diff로 확장되지 않았다.
- Level 2 visual consumer implementation, Level 3 production visible consumer, shell mount, production UI diff는 모두 `not approved`로 유지된다.

Phase 9 종료 가능 판단은 Phase 10 또는 후속 단계의 자동 승인으로 해석하지 않는다. 후속 단계는 별도 scope review, 수정 파일 목록, command 기반 검증 계획, 사용자 승인을 받은 뒤에만 시작할 수 있다.

#### 17.55.7 Phase 9-F에서 제외되는 범위

Phase 9-F에서 명시적으로 제외되는 범위는 다음과 같다.

- 코드 파일 수정
- 테스트 파일 수정
- 추가 source-level test 구현
- route/shell/Navigator/Provider/Repository/persistence 구현 변경
- `ExplorerWorkspace` shell mount 승인
- production UI diff 승인
- Level 2 visual consumer 구현 승인
- Level 3 production visible consumer 구현 승인
- output DTO/model 추가
- public API 추가

#### 17.55.8 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치 및 상태 확인 | Phase 9-F 작업 브랜치에서 문서 변경만 수행해야 함 | 다른 브랜치 또는 uncommitted 변경이 섞임 | `git status --short --branch`, `git branch --show-current`, `git log -1 --oneline` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 변경 파일은 승인된 문서 2개여야 함 | `lib/`, `test/`, platform 경로 또는 새 문서가 포함됨 | `git diff --stat`, `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| Phase 9-F 반영 확인 | 두 문서에 Phase 9-F 기록이 있어야 함 | Phase 9-F 기록 누락 또는 구현 승인처럼 읽히는 문장 | `rg -n "Phase 9-F" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| Phase 9-A~E 연결 확인 | Phase 9-A~E 흐름이 종료 audit 안에서 요약되어야 함 | 특정 단계 누락 또는 Phase 9-E test hardening 의미 과장 | `rg -n "Phase 9-A|Phase 9-B|Phase 9-C|Phase 9-D|Phase 9-E" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | Level 2/3 구현, shell mount, production UI diff, route/owner/persistence 변경이 `not approved`로 유지되어야 함 | 후속 단계 자동 승인 또는 구현 승인처럼 읽힘 | `rg -n "not approved|Level 2|Level 3|shell mount|production UI diff|route wiring|route registration|Provider|Repository|Navigator|persistence|public API|DTO|model" docs/ux/explorer_workspace_unification.md` | 작업 종료 보고에서 기록 |
| 코드/test/platform 변경 없음 확인 | `lib/`, `test/`, platform 경로 변경이 없어야 함 | 구현 또는 테스트 수정 발생 | `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트와 `flutter test`는 이번 Phase 9-F 문서/audit 작업의 필수 범위가 아니다.

### 17.56 Phase 10-A Level 2 production-adjacent visual consumer implementation scope review

Phase 10은 production 연결 단계가 아니다. Phase 10의 목적은 Phase 9에서 정리한 Level 2 entry / candidate / guardrail 기준을 바탕으로, production UI diff 없이 검토 가능한 Level 2 implementation scope의 최소 범위를 확정하는 것이다.

Phase 10-A는 docs/audit 기반 scope review 단계다. 이 단계는 implementation approval, feature implementation, production exposure approval, shell mount approval이 아니다. 실제 Level 2 visual consumer 구현은 수행하지 않으며, 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.56.1 Phase 10-A 목적

Phase 10-A의 목적은 Level 2 production-adjacent visual consumer가 이후 별도 구현 브랜치에서 검토될 수 있다면 어떤 최소 단위로 제한되어야 하는지 문서화하는 것이다.

이 목적은 다음을 포함한다.

- Phase 10이 production route, production shell, production visible UI로 연결되는 단계가 아님을 고정한다.
- Level 2 production-adjacent visual consumer의 최소 구현 가능 범위를 입력, 출력, 금지 권한, helper-local boundary 기준으로 분리한다.
- production UI diff 없이 command 기반으로 확인 가능한 항목과 확인할 수 없는 항목을 구분한다.
- Phase 10 이후 가능한 분기를 후보로만 남기고, Phase 10-A에서 feature 구현으로 바로 전환하지 않는다.

#### 17.56.2 Level 2 최소 구현 단위 검토 기준

Level 2 최소 구현 단위는 다음 조건을 모두 만족하는 경우에만 후속 구현 후보로 검토할 수 있다.

| 기준 | 허용 범위 | 금지 범위 |
| --- | --- | --- |
| 읽을 수 있는 입력 | `WordExplorerScreen` 내부 build-local read-only `ExplorerWorkspaceState` projection snapshot | Repository, Data Source, DB, Provider, Navigator, route argument, persistence/history 직접 읽기 |
| 만들 수 있는 출력 | helper-local visual candidate structure 또는 assert/debug 검증용 ephemeral candidate | output DTO/model, public field/getter, public API, route contract, shell contract, persistence payload |
| 상태 수명 | build-local 또는 helper-local ephemeral value | field/cache/history/source-of-truth 저장 |
| 권한 | read-only candidate interpretation | selection owner, route owner, shell owner, repository owner, persistence owner, canonical owner |
| 노출 범위 | production UI diff 없는 internal scope review 후보 | production visible surface, runtime/UI integration, production visual consumer exposure |

Level 2 최소 구현 단위가 만들 수 있는 출력은 production 화면 표시 결과가 아니라 candidate structure 검토 결과여야 한다. 이 출력은 저장되거나 재사용 가능한 public contract가 되어서는 안 되며, 이후 단계에서 별도 승인 없이 widget tree, route, shell, persistence, history로 연결할 수 없다.

#### 17.56.3 helper-local boundary 유지 조건

`candidateSlots`, `candidateLabels`는 helper-local candidate structure로만 유지한다.

다음 조건은 Phase 10에서도 유지한다.

- `candidateSlots`, `candidateLabels`는 `_debugValidateHiddenVisualProbe(...)` 같은 helper 내부 local value 범위를 벗어나지 않는다.
- `candidateSlots`, `candidateLabels`는 public API, DTO, model, public export, route contract, shell contract로 승격하지 않는다.
- `candidateSlots`, `candidateLabels`는 route argument, shell prop, persistence payload, history payload, source-of-truth value가 아니다.
- `candidateSlots`, `candidateLabels`는 Provider / Repository / Navigator / persistence authority migration의 근거가 될 수 없다.
- helper-local candidate structure는 production visible UI의 data contract로 해석하지 않는다.

따라서 Phase 10-A에서 허용되는 판단은 helper-local boundary를 유지할 수 있는 최소 구현 범위의 문서상 검토까지다. 이 판단은 implementation approval이 아니며, 실제 코드 구현은 별도 단계에서 다시 설계, 수정 파일 목록, command 기반 검증 계획, 사용자 승인을 받아야 한다.

#### 17.56.4 UI diff 없이 검증 가능한 항목과 불가능한 항목

Phase 10-A에서 UI diff 없이 검증 가능한 항목은 source/path/document audit로 확인 가능한 항목에 한정한다.

| 구분 | 항목 | 확인 기준 |
| --- | --- | --- |
| 검증 가능 | production 권한 미획득 | Provider / Repository / Navigator / persistence 참조 추가 없음 |
| 검증 가능 | shell/route 미연결 | `ExplorerWorkspace` shell mount, route wiring, route registration 변경 없음 |
| 검증 가능 | public API 미추가 | public getter/field/export/contract 추가 없음 |
| 검증 가능 | DTO/model 미추가 | output DTO/model 파일 또는 class 추가 없음 |
| 검증 가능 | persistence 미사용 | projection result persistence/history/source-of-truth usage 없음 |
| 검증 가능 | production UI diff 없음 | `lib/`, `test/`, platform 경로 변경 없음 |
| 검증 불가능 | 실제 사용자 UX 만족도 | production visible UI가 없으므로 판단 대상 아님 |
| 검증 불가능 | 화면 배치 적절성 | production 화면 배치가 변경되지 않으므로 판단 대상 아님 |
| 검증 불가능 | interaction flow | runtime/UI integration이 없으므로 판단 대상 아님 |
| 검증 불가능 | production-visible 사용성 | production visual consumer exposure가 없으므로 판단 대상 아님 |

검증 불가능 항목은 Phase 10-A의 실패가 아니라 범위 밖 항목이다. 해당 항목은 production-visible 검토가 승인되는 Phase 11 이후 또는 별도 production UI diff 승인 단계에서만 다룰 수 있다.

#### 17.56.5 Phase 10에서도 유지되는 금지선

아래 항목은 Phase 10-A뿐 아니라 Phase 10 전체에서도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence 구현 변경: `not approved`
- owner migration: `not approved`
- persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- production visible exposure: `not approved`
- Level 2 visual consumer implementation: `not approved`
- Level 3 production visible consumer implementation: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`

#### 17.56.6 Phase 10 이후 분기 가능성

Phase 10-A 이후 가능한 분기는 다음 후보로만 남긴다.

- 추가 docs/audit로 Level 2 minimum implementation checklist를 더 세분화한다.
- 별도 사용자 승인 후 Level 2 최소 구현 브랜치로 전환할 수 있다.
- source-level guardrail test 보강이 필요한지 별도 단계에서 검토할 수 있다.
- production-visible 검토는 Phase 11 이후 또는 별도 production UI diff 승인 단계로 분리한다.

위 분기는 모두 후보이며 Phase 10-A의 자동 후속 작업이 아니다. Phase 10-A는 feature implementation으로 바로 넘어가지 않고, 후속 단계는 다시 설계, 수정 파일 목록, command 기반 검증 계획, 사용자 승인을 받아야 한다.

#### 17.56.7 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 변경 파일 확인 | 승인된 문서 2개만 변경되어야 함 | `lib/`, `test/`, platform 경로 또는 승인 외 문서 변경 포함 | `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| production 경로 변경 없음 확인 | `lib/`, `test/`, platform 경로 변경이 없어야 함 | 구현, 테스트, production UI 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| Phase 10-A 반영 확인 | 두 문서에 Phase 10-A 기록이 있어야 함 | Phase 10-A 누락 또는 구현 승인처럼 읽히는 문장 | `rg -n "Phase 10-A" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| helper-local boundary 확인 | `candidateSlots`, `candidateLabels`가 helper-local 제한으로 기록되어야 함 | public API / DTO / model / route contract / shell contract 승격처럼 읽힘 | `rg -n "candidateSlots|candidateLabels|public API|DTO|model|route contract|shell contract" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | production UI diff, shell mount, route, Provider, Repository, Navigator, persistence 변경이 `not approved`로 유지되어야 함 | Phase 10-A가 production 연결 승인처럼 읽힘 | `rg -n "production UI diff|shell mount|route wiring|route registration|Provider|Repository|Navigator|persistence|not approved" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 10-A 문서/audit 작업의 대상이 아니다. 관련 guardrail 확인을 위해 기존 source-level 테스트를 실행할 수는 있으나, 새 UI 테스트 작성이나 UI 수행 완료 보고는 하지 않는다.

### 17.57 Phase 10-B Level 2 minimum consumer target review

Phase 10-B는 implementation이 아니라 target review다. 이번 단계의 목적은 첫 Level 2 minimum consumer 후보를 구현하기 전에 문서/audit 기준으로 비교하고, 다음 feature 브랜치 검토 후보를 하나의 안전한 방향으로 제한하는 것이다.

Phase 10-B는 implementation approval이 아니다. 이 단계는 production 연결, production UI diff, `ExplorerWorkspace` shell mount, route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경을 승인하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.57.1 Phase 10-B 판단 범위

Phase 10-B에서 판단할 수 있는 것은 Level 2 production-adjacent minimum consumer candidate의 문서상 후보성뿐이다.

- 첫 후보가 어떤 입력만 읽을 수 있는지 정리한다.
- 첫 후보가 어떤 출력 또는 표현만 만들 수 있는지 정리한다.
- 첫 후보가 왜 production-adjacent visual consumer 후보인지 정리한다.
- 첫 후보가 왜 production-visible consumer가 아닌지 정리한다.
- Provider / Repository / Navigator / persistence 권한, owner 권한, public API / DTO / model 추가 권한을 갖지 않는다는 기준을 고정한다.
- Phase 10-C로 이동하려면 어떤 테스트 기준을 먼저 고정해야 하는지 분리한다.

이 판단은 feature 구현 진입이 아니다. Phase 10-C가 필요하면 별도 feature 브랜치, 수정 파일 목록, command 기반 검증 계획, 사용자 승인이 다시 필요하다.

#### 17.57.2 Level 2 minimum consumer 후보 기준

첫 Level 2 minimum consumer 후보는 다음 기준을 모두 만족해야 한다.

- production source-of-truth가 아니다.
- production route 또는 production shell에 연결되지 않는다.
- 사용자에게 직접 노출되지 않는다.
- Provider / Repository / Navigator / persistence 권한을 갖지 않는다.
- selection owner, route owner, shell owner, repository owner, persistence owner, canonical owner 역할을 갖지 않는다.
- public API, DTO, model을 추가하지 않는다.
- `candidateSlots`, `candidateLabels`를 helper-local candidate structure로만 소비한다.
- helper-local boundary를 넘지 않는다.
- projection result를 저장하거나 history/source-of-truth로 사용하지 않는다.
- production owner/controller/coordinator 역할을 갖지 않는다.

`candidateSlots`, `candidateLabels`는 helper-local candidate structure다. 이 값은 public API, DTO, model, route contract, shell contract, persistence payload, history payload, source-of-truth value로 승격할 수 없다.

#### 17.57.3 후보 유형 비교

| 후보 유형 | 허용 가능한 입력 | 허용 가능한 출력 | 금지 권한 | production UI diff 위험 | shell mount 위험 | route/owner/persistence 침범 위험 | 테스트 가능성 | Phase 10-C feature 구현 후보 검토 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| candidate preview-only consumer | read-only projection snapshot, helper-local `candidateSlots`, `candidateLabels` | helper-local ephemeral candidate representation, hidden/probe-adjacent assertion output | Provider / Repository / Navigator / persistence, owner, public API, DTO/model | 낮음. unmounted / non-production-visible 조건을 지키면 화면 변경이 없다. | 낮음. shell prop 또는 mount point를 만들 수 없다. | 낮음. non-route / non-owner / non-persistent 조건을 고정한다. | 기존 hidden/probe source-level test와 path-level diff audit로 검토 가능 | 다음 feature 브랜치 검토 후보로 적합하다. 구현 승인으로 해석하지 않는다. |
| hidden visual probe extension | 기존 hidden visual probe의 read-only projection interpretation | assert-only debug validation result | public output contract, route/shell contract, persistence/history 사용 | 낮음. 기존 hidden boundary 안에 머물 때만 허용된다. | 낮음. shell-adjacent가 아니어야 한다. | 중간. 기존 probe가 Level 1 boundary를 약화하지 않는지 확인해야 한다. | 기존 Phase 8-C / Phase 8-G 테스트 확장 후보 | Phase 10-C 후보가 될 수 있으나 Level 1 probe 확장과 Level 2 후보의 경계를 다시 구분해야 한다. |
| source-level visual structure reader | source text의 marker, helper-local candidate naming, path-level diff | source-level audit result | runtime output, widget/class 추가, public export | 낮음. runtime/UI integration이 없다. | 낮음. mount 대상이 없다. | 낮음. source text 기반 확인으로 제한된다. | `rg`, source-level guardrail test로 검토 가능 | 보조 guardrail 후보로 적합하나 첫 consumer 자체로는 visual consumer 성격이 약하다. |
| test-only representation consumer | test fixture 또는 hidden/probe-adjacent read-only candidate representation | test assertion result | production code owner 권한, public API, DTO/model, persistence | 낮음. test-only이면 production UI diff가 없다. | 낮음. shell mount를 만들 수 없다. | 낮음. test scope 밖으로 나가지 않아야 한다. | 테스트 가능성이 가장 높다. | 첫 구현 리스크는 낮지만 production-adjacent consumer로 보기에는 거리가 있다. |
| ExplorerWorkspace shell-adjacent but unmounted consumer | 문서상 shell-adjacent context 해석, read-only projection snapshot | unmounted candidate representation | shell mount, route wiring, route registration, shell owner | 중간. shell-adjacent 명칭이 production UI diff로 오해될 수 있다. | 중간. mount approval로 오해될 수 있다. | 중간. route/shell/owner migration 해석 위험이 있다. | source-level guardrail과 문서 audit은 가능하나 구현 전 금지선이 강해야 한다. | 후순위 검토 후보로 둔다. 첫 minimum consumer 후보로는 위험이 더 크다. |

#### 17.57.4 권장 후보

가장 안전한 후보는 `candidate preview-only consumer` 계열이다. 단, 여기서 preview는 production preview를 뜻하지 않는다. 이 표현은 helper-local candidate representation을 숨은 검증 또는 test/probe-adjacent 맥락에서 미리 읽어 보는 제한된 소비 방식을 가리킨다.

권장 후보는 다음 제한 안에서만 정의한다.

- unmounted
- non-route
- non-owner
- non-persistent
- non-production-visible
- test-or-hidden-probe-adjacent
- helper-local boundary 내부

이 후보가 production-adjacent minimum consumer candidate로 볼 수 있는 이유는 실제 production owner가 만든 read-only projection 의미와 helper-local candidate structure를 해석하는 첫 소비 지점이 될 수 있기 때문이다. 그러나 이 후보는 production-visible consumer가 아니다. 사용자가 보는 widget tree에 mount되지 않고, route로 등록되지 않으며, shell에 연결되지 않고, persistence/history/source-of-truth에 쓰지 않기 때문이다.

따라서 `candidate preview-only consumer`는 Phase 10-C feature 구현 승인 대상이 아니라 다음 feature 브랜치 검토 후보로만 기록한다. Phase 10-C에서 실제 구현을 검토하려면 별도 승인 전까지 구현 파일, 테스트 파일, output contract, guardrail command를 다시 제시해야 한다.

#### 17.57.5 후속 구현 검토 파일과 테스트 범위 후보

다음 항목은 Phase 10-C 이후 별도 승인 시 검토할 수 있는 후보 범위일 뿐이며, Phase 10-B에서 구현 승인으로 해석하지 않는다.

| 구분 | 후보 범위 | 제한 |
| --- | --- | --- |
| production source 후보 | `lib/ui/word_explorer_screen.dart` 내부 helper-local hidden/probe-adjacent 영역 | 새 widget/class, public API, DTO/model, route/shell contract 추가 없이 승인된 범위에서만 검토 |
| 기존 테스트 재사용 후보 | `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` | projection boundary와 source-of-truth 미사용 기준 확인 |
| 기존 테스트 확장 후보 | `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | hidden/probe-adjacent read-only, assert-only boundary 유지 확인 |
| 기존 guardrail 확장 후보 | `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | candidate marker가 public API / DTO / model / route / shell / persistence로 새지 않는지 확인 |
| 문서 audit 후보 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` | target review와 implementation approval을 계속 분리 |

#### 17.57.6 구현 전 테스트 기준

Phase 10-C로 이동하기 전 테스트 기준은 다음처럼 분리한다.

| 구분 | 테스트 기준 | Phase 10-B 처리 |
| --- | --- | --- |
| 기존 테스트 재사용 가능 항목 | projection boundary가 Repository / Data Source / persistence source-of-truth로 확장되지 않는지 확인 | 기존 테스트 실행 결과만 확인할 수 있다. 테스트 코드는 수정하지 않는다. |
| 기존 테스트 재사용 가능 항목 | hidden visual probe가 read-only / assert-only / non-owner boundary를 유지하는지 확인 | 기존 Phase 8-C 테스트 실행 후보로 둔다. |
| 기존 테스트 재사용 가능 항목 | `candidateSlots`, `candidateLabels` marker가 public surface로 노출되지 않는지 확인 | 기존 Phase 8-G guardrail 테스트 실행 후보로 둔다. |
| 기존 테스트 확장 필요 항목 | `candidate preview-only consumer` 명칭 또는 marker가 route wiring, route registration, shell contract로 연결되지 않는지 확인 | Phase 10-C 구현 승인 전 확장 여부를 다시 제안해야 한다. |
| 기존 테스트 확장 필요 항목 | Provider / Repository / Navigator / persistence 참조가 future Level 2 candidate path에 추가되지 않는지 확인 | Phase 10-C 구현 범위가 정해진 뒤 source-level guardrail 확장 후보로 둔다. |
| 새 source-level 또는 hidden/probe test 후보 | 새 helper-local candidate consumer가 생길 경우 unmounted / non-route / non-owner / non-persistent / non-production-visible 조건을 검사 | Phase 10-B에서는 새 테스트 파일을 작성하지 않는다. |
| 새 source-level 또는 hidden/probe test 후보 | output이 DTO/model/public API가 아니라 ephemeral hidden/probe-adjacent representation인지 검사 | Phase 10-C 승인 전 테스트 설계가 필요하다. |
| UI 기반 수동 테스트로는 아직 검증할 수 없는 항목 | production-visible 사용성, 화면 배치, interaction flow, 실제 사용자 UX 만족도 | production visible UI가 없고 shell mount가 없으므로 Phase 10-B 검증 대상이 아니다. |

#### 17.57.7 Phase 10-B에서 여전히 승인되지 않은 항목

아래 항목은 Phase 10-B에서도 별도 승인 전까지 `not approved`로 유지한다.

- Level 2 visual consumer implementation: `not approved`
- Level 3 production visible consumer implementation: `not approved`
- production-visible consumer exposure: `not approved`
- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence 구현 변경: `not approved`
- owner migration: `not approved`
- persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- output DTO/model 추가: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- `lib/` modification: `not approved`
- `test/` modification: `not approved`

#### 17.57.8 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 변경 파일 확인 | 승인된 문서 2개만 변경되어야 함 | `lib/`, `test/`, platform 경로 또는 승인 외 문서 변경 포함 | `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| production 경로 변경 없음 확인 | `lib/`, `test/`, platform 경로 변경이 없어야 함 | 구현, 테스트, production UI 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| Phase 10-B 반영 확인 | 두 문서에 Phase 10-B 기록이 있어야 함 | Phase 10-B 누락 또는 implementation approval처럼 읽히는 문장 | `rg -n "Phase 10-B" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| minimum consumer target review 확인 | minimum consumer, target review, production-adjacent, production-visible 경계가 기록되어야 함 | production-visible consumer 승인처럼 읽힘 | `rg -n "minimum consumer|target review|production-adjacent|production-visible" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| helper-local boundary 확인 | `candidateSlots`, `candidateLabels`가 helper-local 제한으로 기록되어야 함 | public API / DTO / model / route contract / shell contract 승격처럼 읽힘 | `rg -n "candidateSlots|candidateLabels|helper-local|public API|DTO|model|route contract|shell contract" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | production UI diff, shell mount, route, Provider, Repository, Navigator, persistence 변경이 `not approved`로 유지되어야 함 | Phase 10-B가 production 연결 승인처럼 읽힘 | `rg -n "production UI diff|shell mount|route wiring|route registration|Provider|Repository|Navigator|persistence|not approved" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 10-B 문서/audit 작업의 대상이 아니다. production-visible UI, shell mount, route 변경이 없으므로 사용자가 화면에서 확인할 수 있는 새 동작은 만들지 않는다.

### 17.58 Phase 10-C candidate preview consumer preflight audit

Phase 10-C는 implementation이 아니라 preflight audit이다. 이번 단계의 목적은 Phase 10-D 또는 이후 feature 구현으로 이동하기 전에 candidate preview 계열 후보의 명칭, 구현 파일 후보, 테스트 전략, 금지 import / 금지 참조, 중단 조건, feature 브랜치 진입 조건을 문서/audit 기준으로 고정하는 것이다.

Phase 10-C는 implementation approval이 아니다. 이 단계는 Level 2 visual consumer 실제 구현, 새 widget/class 구현, 새 helper 구현, 새 테스트 파일 작성, 기존 테스트 파일 수정, `lib/` 수정, `test/` 수정, production UI diff, `ExplorerWorkspace` shell mount, route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, Provider / Repository / Navigator / persistence 구현 변경, DTO/model/public API 추가를 승인하지 않는다. 변경 범위는 이 문서와 `docs/logs/CHANGELOG.md` 기록으로 제한한다.

#### 17.58.1 Phase 10-C 판단 범위

Phase 10-C에서 고정할 수 있는 것은 구현 전 조건뿐이다.

- Phase 10-D feature 브랜치에서 검토할 후보명을 implementation approval과 분리한다.
- Phase 10-D에서 수정 가능성이 있는 파일 후보를 허용 가능 후보, 위험 후보, 금지 후보로 나눈다.
- 새 테스트 파일을 만들지, 기존 hidden/probe-adjacent 테스트를 확장할지 판단하기 위한 기준만 문서화한다.
- Provider / Repository / Navigator / persistence, route, shell, DTO/model/public API 관련 금지 import / 금지 참조 범위를 문서화한다.
- candidateSlots, candidateLabels가 helper-local candidate structure로만 소비되어야 한다는 기준을 유지한다.
- production-visible consumer, production UI diff, shell mount, route 변경, owner/persistence migration은 별도 승인 전까지 `not approved`로 유지한다.

이 판단은 Phase 10-D 구현 착수, feature 브랜치 생성, 테스트 파일 수정, production source 수정, route/shell 연결을 자동 승인하지 않는다.

#### 17.58.2 candidate preview 계열 명칭 후보 비교

`candidate preview-only consumer`는 Phase 10-B에서 다음 feature 브랜치 검토 후보 계열로 기록되었지만, `preview`라는 단어가 production preview 또는 production-visible preview surface로 오해될 수 있다. Phase 10-C에서는 다음 명칭 후보를 비교하고, 구현 승인 표현 없이 다음 feature 브랜치 검토 후보명만 기록한다.

| 명칭 후보 | production preview 오해 위험 | widget 구현 오해 위험 | helper-local boundary 적합성 | hidden/probe-adjacent 성격 표현 | Phase 10-D feature 구현 후보명 적합성 |
| --- | --- | --- | --- | --- | --- |
| `candidate representation reader` | 낮음. preview라는 단어를 피하고 candidate representation을 읽는 행위로 제한한다. | 낮음. widget, visual surface, consumer mount를 직접 암시하지 않는다. | 높음. helper-local representation reader로 제한하기 쉽다. | 중간. probe 성격은 직접 드러나지 않으므로 hidden/probe-adjacent 제한 문구가 함께 필요하다. | 높음. 다음 feature 브랜치 검토 후보명으로 가장 안전하다. |
| `candidate preview probe` | 중간. preview가 production preview로 오해될 수 있다. | 낮음. probe가 mounted widget보다 검증용 구조를 암시한다. | 높음. helper-local probe로 제한 가능하다. | 높음. hidden/probe-adjacent 성격이 분명하다. | 중간. preview 단어 때문에 추가 제한 설명이 필요하다. |
| `candidate visual probe consumer` | 낮음에서 중간. preview 단어는 없지만 visual consumer가 production visual consumer로 읽힐 수 있다. | 중간. visual과 consumer가 widget 구현으로 오해될 수 있다. | 중간. helper-local boundary 문구가 없으면 production-adjacent UI로 확장될 위험이 있다. | 높음. probe 성격은 잘 표현한다. | 중간. Level 2 visual consumer 구현 승인처럼 읽히지 않도록 제한이 필요하다. |
| `candidate structure preview` | 중간. structure는 안전하지만 preview가 production preview로 오해될 수 있다. | 낮음. widget 구현 암시는 약하다. | 높음. candidate structure를 helper-local로 묶기 쉽다. | 중간. probe 성격은 직접 드러나지 않는다. | 중간. preview 단어의 오해를 제거하지 못한다. |
| `candidate preview-only consumer` | 중간에서 높음. preview-only가 production preview surface로 오해될 수 있다. | 중간. consumer가 widget 소비자 또는 mounted UI로 읽힐 수 있다. | 중간. helper-local 제한을 명시하면 유지 가능하지만 명칭 자체만으로는 부족하다. | 중간. hidden/probe-adjacent 성격은 보조 설명이 필요하다. | 낮음에서 중간. Phase 10-B historical 후보명으로 유지하되 Phase 10-D 후보명으로는 더 안전한 대체명이 필요하다. |

Phase 10-C 기준으로 가장 안전한 다음 feature 브랜치 검토 후보명은 `candidate representation reader`다. 이 명칭은 candidate preview 계열의 의도를 helper-local candidate representation을 읽는 read-only 구조로 좁히며, production preview, mounted widget, route/shell consumer, production-visible surface로 오해될 위험이 가장 낮다.

단, `candidate representation reader`는 구현 승인명이 아니다. 이 명칭은 Phase 10-D 또는 이후 feature 브랜치에서 검토할 후보명일 뿐이며, 구현 파일, 테스트 파일, 금지 import 기준, command 기반 검증 계획, 사용자 승인이 별도로 제시되기 전까지 코드에 추가할 수 없다.

#### 17.58.3 Phase 10-D 구현 파일 후보 preflight 검토

다음 분류는 Phase 10-D에서 실제 구현으로 진입하는 경우의 후보 위치를 문서상으로 검토한 것이다. Phase 10-C에서는 어떤 파일도 만들거나 수정하지 않는다.

| 분류 | 후보 위치 | 검토 기준 | Phase 10-C 판단 |
| --- | --- | --- | --- |
| 허용 가능 후보 | `lib/ui/word_explorer_screen.dart` 내부의 기존 hidden/probe-adjacent debug/assert boundary 인접 영역 | production route/shell에 연결되지 않고, build-local 또는 helper-local read-only candidate representation reader로 제한되며, 새 public API / DTO / model / widget/class를 만들지 않는 경우 | 별도 승인 후 Phase 10-D에서만 검토 가능하다. Phase 10-C에서는 수정하지 않는다. |
| 허용 가능 후보 | 기존 hidden/probe 관련 source-level guardrail의 관찰 대상 경로 | 테스트가 읽는 source marker 또는 path-level diff 기준으로만 다루고 runtime/UI integration을 만들지 않는 경우 | 구현 파일 후보가 아니라 검증 관찰 대상 후보로만 기록한다. |
| 위험 후보 | `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` 확장 | 기존 hidden visual probe boundary를 보강할 수 있지만 Level 1 probe 확장과 Level 2 candidate representation reader 경계가 섞일 수 있다. | Phase 10-D에서 기존 테스트 확장을 선택할 경우 수정 위치와 assertion 기준을 별도 승인받아야 한다. |
| 위험 후보 | `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` 확장 | candidateSlots, candidateLabels, public API, DTO, model, route, shell, persistence 누출 방지에 적합하지만 future Level 2 path의 범위를 명확히 지정해야 한다. | Phase 10-D에서 기존 테스트 확장을 선택할 경우 guardrail marker를 먼저 확정해야 한다. |
| 위험 후보 | 새 source-level test 파일 | 구현 후보의 금지 import / 금지 참조를 분리해서 검증할 수 있지만 새 테스트 파일 작성 승인이 필요하다. | Phase 10-C에서는 작성하지 않는다. Phase 10-D에서 별도 승인 전까지 후보로만 둔다. |
| 위험 후보 | 새 hidden/probe-adjacent test 파일 | unmounted, non-route, non-owner, non-persistent, non-production-visible 조건을 명시적으로 검증할 수 있지만 새 테스트 파일 작성 승인이 필요하다. | Phase 10-C에서는 작성하지 않는다. Phase 10-D에서 별도 승인 전까지 후보로만 둔다. |
| 금지 후보 | `lib/main.dart`, `lib/ui/home_screen.dart`, route registration 파일 또는 route table | route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경으로 이어질 수 있다. | Phase 10-C 및 별도 승인 전 Phase 10-D 후보에서 제외한다. |
| 금지 후보 | `lib/ui/explorer_workspace/` shell contract 또는 shell mount 관련 파일 | `ExplorerWorkspace` shell mount, shell owner, shell prop 추가로 오해될 수 있다. | shell mount 승인 전까지 제외한다. |
| 금지 후보 | Provider / Repository / Data Source / persistence 관련 경로 | Provider / Repository / Navigator / persistence authority migration 또는 source-of-truth 변경으로 이어질 수 있다. | Phase 10-C 목적과 맞지 않으므로 제외한다. |
| 금지 후보 | DTO/model/public export 경로 | candidate representation이 public API, DTO, model, route contract, shell contract로 승격될 위험이 있다. | output DTO/model/public API 추가가 승인되지 않았으므로 제외한다. |
| 금지 후보 | platform 경로, production UI 노출 경로, visible route/screen 경로 | production UI diff, production-visible consumer exposure, runtime/UI integration으로 이어질 수 있다. | Phase 10-C 및 feature 구현 사전 조건에서 제외한다. |

허용 가능 후보로 기록된 위치도 Phase 10-C에서 수정할 수 없다. Phase 10-D에서 허용 가능 후보를 선택하려면 수정할 정확한 파일, 위치, 삽입/교체/삭제 여부, 앞뒤 문맥, 테스트 계획을 다시 제시하고 사용자 승인을 받아야 한다.

#### 17.58.4 구현 전 테스트 전략 preflight 검토

Phase 10-D에서 구현으로 진입한다면 테스트 전략은 다음 기준으로 분리한다.

| 구분 | 테스트 기준 | Phase 10-C 판단 |
| --- | --- | --- |
| 기존 테스트 재사용 가능 항목 | `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`로 projection boundary가 Repository / Data Source / persistence source-of-truth로 확장되지 않는지 확인 | 기존 테스트 실행 후보로 둔다. Phase 10-C에서는 수정하지 않는다. |
| 기존 테스트 재사용 가능 항목 | `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`로 hidden visual probe가 read-only, assert-only, non-owner, non-route, non-shell-mount boundary를 유지하는지 확인 | 기존 테스트 실행 후보로 둔다. Phase 10-C에서는 수정하지 않는다. |
| 기존 테스트 재사용 가능 항목 | `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`로 `candidateSlots`, `candidateLabels`가 public API, DTO, model, route contract, shell contract, persistence payload로 새지 않는지 확인 | 기존 테스트 실행 후보로 둔다. Phase 10-C에서는 수정하지 않는다. |
| 기존 테스트 확장 가능 항목 | candidate representation reader가 Provider / Repository / Navigator / persistence import 또는 참조를 추가하지 않는지 확인 | Phase 10-D에서 구현 위치가 확정된 뒤 기존 guardrail test 확장 후보로 검토한다. |
| 기존 테스트 확장 가능 항목 | candidate representation reader 명칭 또는 marker가 route wiring, route registration, shell mount, production-visible path에 나타나지 않는지 확인 | Phase 10-D에서 기존 테스트 확장을 선택할 경우 assertion 범위를 별도 승인받는다. |
| 새 source-level test 후보 | future Level 2 candidate path 전체에서 금지 import, 금지 class reference, public export, DTO/model marker가 없는지 검사 | Phase 10-C에서는 새 테스트 파일을 만들지 않는다. Phase 10-D에서 별도 승인 후 후보로 검토한다. |
| 새 source-level test 후보 | `git diff --name-only -- lib test android ios macos windows linux web`와 조합해 production UI diff, route/shell/platform 변경이 없는지 path-level로 확인 | Phase 10-D에서 source-level guardrail 설계가 필요할 때 후보로 둔다. |
| 새 hidden/probe-adjacent test 후보 | candidate representation reader가 unmounted, non-route, non-owner, non-persistent, non-production-visible인지 검사 | 새 테스트 파일 작성 또는 기존 hidden/probe test 확장 중 하나를 Phase 10-D에서 선택해야 한다. |
| 새 hidden/probe-adjacent test 후보 | `candidateSlots`, `candidateLabels`가 helper-local candidate structure로만 소비되고 return value, field, getter, route argument, shell prop, persistence payload가 아닌지 검사 | Phase 10-D에서 구현 형태가 확정된 뒤 테스트 설계가 가능하다. |
| 아직 UI 기반 수동 테스트로 검증할 수 없는 항목 | production-visible 화면 배치, interaction flow, 실제 사용자 UX 만족도, shell-mounted 상태, route navigation 결과 | production UI diff와 shell mount가 없으므로 Phase 10-C와 Phase 10-D 최소 후보의 검증 대상이 아니다. production-visible consumer 승인 전까지 UI 테스트 완료로 보고할 수 없다. |

Phase 10-D 구현 전 테스트 기준은 consumer가 unmounted, non-route, non-owner, non-persistent, non-production-visible인지, Provider / Repository / Navigator / persistence import가 없는지, DTO/model/public API 추가가 없는지, candidateSlots와 candidateLabels가 helper-local candidate structure로만 소비되는지, production UI diff와 shell mount가 없는지를 command 기반으로 확인할 수 있어야 한다.

#### 17.58.5 금지 import / 금지 참조 기준

Phase 10-D에서 구현 후보를 제시하기 전 다음 import 또는 참조는 금지 대상으로 둔다. Phase 10-C에서는 실제 import 검사 코드를 작성하지 않는다.

| 금지 범위 | 금지 기준 | 이유 |
| --- | --- | --- |
| Navigator | `Navigator`, route push/pop, route argument, navigation callback 참조 금지 | candidate representation reader가 non-route, unmounted 상태를 유지해야 한다. |
| Provider | Provider import, provider lookup, inherited provider dependency 참조 금지 | production owner 또는 state authority로 승격될 위험을 차단한다. |
| Repository | `WordRepository` 또는 repository 계층 import/호출 금지 | UI → Repository 흐름을 새로 만들거나 source-of-truth를 우회하지 않기 위함이다. |
| persistence | DB, storage, history, cache, persistence payload, source-of-truth write/read 참조 금지 | candidate representation이 non-persistent 상태를 유지해야 한다. |
| route wiring / route registration | route table, `main.dart`, `home_screen.dart`, route alias, shell route 연결 참조 금지 | production route 변경과 route registration 변경을 차단한다. |
| shell mount / shell contract | `ExplorerWorkspace` mount point, shell prop, shell owner, shell coordinator 참조 금지 | shell mount 승인 또는 production UI diff로 오해되는 경로를 차단한다. |
| production owner/controller/coordinator | selection owner, route owner, shell owner, repository owner, persistence owner, canonical owner 역할 참조 금지 | candidate reader가 non-owner 경계를 유지해야 한다. |
| DTO/model/public API | output DTO, public model, public field/getter, public export, route contract, shell contract 추가 금지 | helper-local candidate structure가 public boundary로 승격되는 것을 막는다. |
| production-visible UI | visible widget tree, screen layout, interaction handler, user-facing preview surface 참조 금지 | production-visible consumer exposure와 production UI diff를 차단한다. |

이 금지 기준은 구현 전 중단 조건이다. Phase 10-D 제안에서 위 금지 import 또는 참조가 필요해지는 경우, candidate representation reader 최소 구현 후보로 진행하지 않고 별도 설계 검토로 되돌려야 한다.

#### 17.58.6 구현 전 실패 조건과 중단 조건

Phase 10-D 구현 제안은 다음 조건 중 하나라도 발생하면 중단해야 한다.

- 구현 후보가 mounted widget, production-visible UI, route-connected consumer로 바뀌는 경우
- candidate representation reader가 Provider / Repository / Navigator / persistence import 또는 호출을 필요로 하는 경우
- candidateSlots, candidateLabels가 helper-local boundary 밖으로 return, field, getter, DTO/model, public API, route argument, shell prop, persistence payload로 나가는 경우
- route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경이 필요한 경우
- `ExplorerWorkspace` shell mount 또는 shell contract 변경이 필요한 경우
- production owner/controller/coordinator 역할을 새로 만들거나 이전해야 하는 경우
- production UI diff 또는 runtime/UI integration이 필요한 경우
- 새 테스트 파일 작성 또는 기존 테스트 수정 범위가 사용자 승인 없이 필요해지는 경우
- 구현 위치, 테스트 위치, 금지 import 기준이 확정되지 않은 상태에서 feature 브랜치 전환을 시도하는 경우

위 조건은 실패가 아니라 scope 중단 신호로 취급한다. 중단 시에는 Phase 10-D 구현으로 진행하지 않고 파일 후보와 테스트 전략을 다시 문서/audit 기준으로 검토해야 한다.

#### 17.58.7 Phase 10-D feature 브랜치 진입 조건

Phase 10-D가 feature 구현 브랜치로 진입하려면 다음 조건이 모두 충족되어야 한다.

- 구현 대상 명칭이 확정되어야 한다. Phase 10-C 기준 후보명은 `candidate representation reader`이며, 이는 구현 승인명이 아니라 다음 feature 브랜치 검토 후보명이다.
- 구현 위치 후보가 허용 가능 후보 안에서 확정되어야 한다.
- 수정할 파일 목록과 정확한 수정 위치, 삽입/교체/삭제 여부, 앞뒤 문맥이 제시되어야 한다.
- 새 테스트 파일 작성 여부 또는 기존 테스트 확장 여부가 확정되어야 한다.
- 금지 import / 금지 참조 기준이 테스트 또는 command 기반 audit으로 확인 가능해야 한다.
- production UI diff 없음, shell mount 없음, route wiring / route registration 변경 없음, `HomeScreen -> WordExplorerScreen` 진입 구조 변경 없음이 확인 가능해야 한다.
- Provider / Repository / Navigator / persistence 변경 없음과 owner/persistence migration 없음이 확인 가능해야 한다.
- DTO/model/public API 추가 없음이 확인 가능해야 한다.
- candidateSlots, candidateLabels가 helper-local candidate structure로만 소비된다는 검증 기준이 있어야 한다.
- 명령어 기반 테스트 계획과 UI 기반 수동 테스트 비대상 사유가 제시되어야 한다.
- 사용자 승인 후 feature 브랜치를 생성해야 한다.

Phase 10-D 진입 조건이 충족되지 않으면 feature 구현으로 넘어가지 않는다.

#### 17.58.8 Phase 10-C에서 여전히 승인되지 않은 항목

아래 항목은 Phase 10-C에서도 별도 승인 전까지 `not approved`로 유지한다.

- Level 2 visual consumer implementation: `not approved`
- Level 3 production visible consumer implementation: `not approved`
- production-visible consumer exposure: `not approved`
- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence 구현 변경: `not approved`
- owner migration: `not approved`
- persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- output DTO/model 추가: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- `lib/` modification: `not approved`
- `test/` modification: `not approved`
- 새 widget/class 구현: `not approved`
- 새 helper 구현: `not approved`
- 새 테스트 파일 작성: `not approved`
- 기존 테스트 파일 수정: `not approved`

#### 17.58.9 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 변경 파일 확인 | 승인된 문서 2개만 변경되어야 함 | `lib/`, `test/`, platform 경로 또는 승인 외 문서 변경 포함 | `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 trailing whitespace 오류가 없어야 함 | `git diff --check` 실패 | `git diff --check` | 작업 종료 보고에서 기록 |
| production 경로 변경 없음 확인 | `lib/`, `test/`, platform 경로 변경이 없어야 함 | 구현, 테스트, production UI 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| Phase 10-C 반영 확인 | 두 문서에 Phase 10-C preflight audit 기록이 있어야 함 | Phase 10-C 누락 또는 implementation approval처럼 읽히는 문장 | `rg -n "Phase 10-C|preflight audit" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 명칭 후보 확인 | candidate preview 계열과 candidate representation reader 비교가 기록되어야 함 | production preview 또는 widget 구현 승인처럼 읽힘 | `rg -n "candidate preview|candidate representation|candidate visual probe" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| helper-local boundary 확인 | `candidateSlots`, `candidateLabels`가 helper-local 제한으로 기록되어야 함 | public API / DTO / model / route contract / shell contract 승격처럼 읽힘 | `rg -n "candidateSlots|candidateLabels|helper-local|public API|DTO|model|route contract|shell contract" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | production UI diff, shell mount, route, Provider, Repository, Navigator, persistence 변경이 `not approved`로 유지되어야 함 | Phase 10-C가 production 연결 승인처럼 읽힘 | `rg -n "production UI diff|shell mount|route wiring|route registration|Provider|Repository|Navigator|persistence|not approved" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 10-C 문서/audit 작업의 대상이 아니다. production-visible UI, shell mount, route 변경이 없으므로 사용자가 화면에서 확인할 수 있는 새 동작은 만들지 않는다.

### 17.59 Phase 10-D candidate representation reader 최소 구현 시작

Phase 10-D는 `candidate representation reader`를 최소 구현으로 시작한다. 이번 단계의 구현은 production preview, mounted widget, production-visible consumer가 아니며, 기존 `_debugValidateHiddenVisualProbe(...)` 내부에서 helper-local candidate representation을 read-only로 읽는 제한적 구조로만 둔다.

#### 17.59.1 구현 범위

- 구현 위치는 `lib/ui/word_explorer_screen.dart`의 `_debugValidateHiddenVisualProbe(...)` 내부로 제한한다.
- `candidateSlots`, `candidateLabels`는 helper 내부 local candidate structure로만 유지한다.
- reader는 local function 범위에만 존재하며 private symbol보다 좁은 helper-local boundary로 취급한다.
- 기존 직접 predicate는 local reader 호출로 대체하되, widget tree, route, shell, persistence, owner/controller/coordinator 역할과 연결하지 않는다.

#### 17.59.2 테스트 범위

- 신규 테스트는 `test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart` source-level guardrail test로 제한한다.
- 테스트는 reader가 `_debugValidateHiddenVisualProbe(...)` 내부에만 존재하는지, 금지 import / 금지 참조가 없는지, DTO/model/public API로 승격하지 않는지, production entry와 shell mount로 노출되지 않는지를 문자열/범위 기반으로 확인한다.
- UI pump, route 실행, runtime integration test는 이번 단계의 검증 대상이 아니다.

#### 17.59.3 계속 금지되는 항목

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence 구현 변경: `not approved`
- owner migration 또는 persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`

### 17.60 Phase 10-E candidate representation reader termination audit

Phase 10-E는 구현 단계가 아니라 Phase 10-D에서 추가한 `candidate representation reader`가 Phase 10-A/B/C에서 정한 금지선과 최소 구현 조건을 지켰는지 확인하는 termination audit 단계다. 이 단계에서는 `lib/`, `test/`, production UI, shell, route, Provider / Repository / Navigator / persistence, DTO/model/public API를 수정하지 않는다.

#### 17.60.1 Phase 10-D 구현 결과 audit

Phase 10-D의 `candidate representation reader`는 `lib/ui/word_explorer_screen.dart`의 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local local function으로만 존재한다. `readCandidateRepresentation`은 선언과 호출 모두 helper 내부에만 있으며, helper 밖 public symbol이나 reusable contract로 승격되지 않았다.

`candidateSlots`, `candidateLabels`는 helper-local candidate structure로만 유지된다. 두 값은 helper 외부로 노출되지 않고, return value, field, getter, public contract, route argument, shell prop, persistence payload로 나가지 않는다.

확인 결과 다음 승격 또는 연결은 발생하지 않았다.

- public API / DTO / model / route contract / shell contract 승격 없음
- production UI diff 없음
- `ExplorerWorkspace` shell mount 없음
- route wiring / route registration 변경 없음
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 없음
- Provider / Repository / Navigator / persistence authority migration 없음
- projection result persistence/history/source-of-truth 사용 없음
- runtime/UI integration 또는 production visual consumer exposure 없음

#### 17.60.2 테스트 성격과 검증 결과

Phase 10-D 신규 테스트인 `test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart`는 UI pump나 runtime integration 검증이 아니라 source-level guardrail test다. 이 테스트는 reader가 `_debugValidateHiddenVisualProbe(...)` 내부에만 존재하는지, `candidateSlots` / `candidateLabels`가 helper-local candidate structure로만 유지되는지, 금지 import / 금지 참조가 없는지, DTO/model/public API 또는 production entry / shell mount로 노출되지 않는지를 문자열과 범위 기반으로 확인한다.

Phase 10-E audit 기준으로 기존 guardrail 테스트와 Phase 10-D 신규 테스트는 모두 통과했다.

- `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`: 통과
- `flutter test test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`: 통과
- `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`: 통과
- `flutter test test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart`: 통과

UI 기반 수동 테스트는 아직 대상이 아니다. Phase 10-E까지 production-visible UI, shell mount, route wiring, runtime integration이 없으므로 사용자가 화면에서 확인할 수 있는 새 동작을 만들지 않았고, UI 테스트 완료로 보고할 기준도 만들지 않았다.

#### 17.60.3 계속 금지되는 항목

아래 항목은 Phase 10-E 종료 audit 이후에도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration 변경: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- DTO/model/public API 추가: `not approved`
- projection result persistence/history/source-of-truth 사용: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`

#### 17.60.4 Phase 10 종료 가능 판단

Phase 10-A/B/C에서 정한 금지선과 Phase 10-D의 최소 구현 조건은 Phase 10-E audit 기준으로 유지되었다. 따라서 Phase 10은 종료 가능 상태로 판단할 수 있다.

이 판단은 Phase 11 production-visible 논의, production UI diff 승인, `ExplorerWorkspace` shell mount, route collapse, owner 또는 canonical authority migration 승인을 의미하지 않는다. Phase 11 또는 production-visible 검토는 별도 설계, 수정 범위, command 기반 검증 계획, 사용자 승인 대상으로 분리한다.

### 17.61 Phase 11-A production-visible readiness review

Phase 11의 목적은 Phase 10에서 확보한 `candidate representation reader` 기반 이후, `ExplorerWorkspace` 또는 관련 Level 2 consumer가 production-visible 전환을 검토할 수 있는 조건과 금지선을 분리해 확인하는 것이다.

Phase 11-A는 production-visible UX 구현 단계가 아니다. 이 단계는 readiness review 문서/audit 단계이며, production UI diff, route wiring, shell mount, runtime/UI integration, public API / DTO / model 추가, owner/controller/coordinator 이전을 수행하지 않는다.

사용자에게 보이는 UX 변화는 Phase 11-A 범위가 아니다. 실제 UX 변화는 readiness review와 shell mount precondition audit 이후, 별도 승인된 feature 단계에서만 가능하다.

#### 17.61.1 readiness review 판단 기준

Phase 11-A에서 production-visible 전환을 검토할 수 있다고 판단하려면 다음 조건을 먼저 확인해야 한다. 이 조건은 구현 승인 조건이 아니라 후속 승인 검토에 필요한 선행 audit 기준이다.

- production entry 구조가 유지되어야 한다. `main.dart -> HomeScreen`, `HomeScreen -> Navigator.push -> WordExplorerScreen` 흐름은 변경하지 않는다.
- `ExplorerWorkspace` shell이 production에 mount되지 않아야 한다.
- route registration 또는 route wiring 변경이 없어야 한다.
- Provider / Repository / Navigator / persistence authority migration이 없어야 한다.
- `WordExplorerScreen` production owner 상태가 유지되어야 한다.
- DTO/model/public API 추가가 없어야 한다.
- projection result를 persistence, history, source-of-truth로 사용하지 않아야 한다.
- Phase 10-D `candidate representation reader`는 helper-local read-only 구조로만 유지되어야 한다.
- 관련 source-level guardrail test가 통과해야 한다.
- production-visible UX 변경은 별도 feature 범위, 수정 파일 목록, command 기반 검증 계획, 사용자 승인을 다시 받아야 한다.

#### 17.61.2 shell mount precondition audit이 필요한 이유

`ExplorerWorkspace` shell mount는 단순한 문서 표현이나 helper-local reader 확장이 아니다. shell이 production tree에 mount되면 화면 노출, entry path, state ownership, route stack, history/persistence 해석, callback authority, rollback 범위가 함께 바뀔 수 있다.

따라서 shell mount를 검토하기 전에는 다음 precondition audit이 필요하다.

- 어떤 production entry에서 shell을 mount할지 확인해야 한다.
- 기존 `HomeScreen -> WordExplorerScreen` 진입 구조를 유지할지, 변경할지 별도 승인해야 한다.
- `WordExplorerScreen`이 소유한 graph center, selected word, detail target, history authority가 중복 소유되지 않는지 확인해야 한다.
- route registration, route alias, route collapse가 필요한지 별도 검토해야 한다.
- Provider / Repository / Navigator / persistence authority 이동이 필요한지 확인하고, 필요한 경우 Phase 11-A 범위 밖으로 분리해야 한다.
- 사용자-visible UI diff와 UI 테스트 기준을 별도 feature 단계에서 승인받아야 한다.

Phase 11-A에서는 위 precondition을 audit 대상으로만 기록한다. shell mount 자체는 계속 `not approved`다.

#### 17.61.3 Phase 10 결과의 승격 금지

Phase 10의 `candidate representation reader`는 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local 구조다. `readCandidateRepresentation`은 helper 내부 local function으로만 취급하며, public symbol이나 reusable contract가 아니다.

`candidateSlots`, `candidateLabels`는 helper-local candidate structure로만 유지된다. 두 값은 public API, DTO, model, route contract, shell contract, persistence payload, history payload, source-of-truth payload로 승격되지 않았다.

따라서 Phase 10 결과는 다음을 의미하지 않는다.

- public API 승격 아님
- DTO/model 추가 아님
- route contract 추가 아님
- shell contract 추가 아님
- production visual consumer exposure 아님
- runtime/UI integration 아님
- `ExplorerWorkspace` shell mount 승인 아님
- Level 3 production visible consumer 승인 아님

#### 17.61.4 Phase 11-A에서 계속 금지되는 항목

아래 항목은 Phase 11-A에서도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.61.5 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| production entry 구조 유지 확인 | `main.dart -> HomeScreen`, `HomeScreen -> Navigator.push -> WordExplorerScreen` 흐름이 유지되어야 함 | `home` 변경, route entry 변경, explorer 진입 구조 변경 | `rg` 기반 source 확인 | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell production mount 없음 확인 | production entry 또는 `WordExplorerScreen` production path에 shell mount가 없어야 함 | shell mount, visible widget tree 연결, shell prop 연결 | `rg` 기반 source 확인 | 작업 종료 보고에서 기록 |
| route registration / route wiring 변경 없음 확인 | route table, `Navigator` wiring, route alias 변경이 없어야 함 | route 등록 변경, push 대상 변경, route collapse 조짐 | `git diff`와 `rg` 기반 확인 | 작업 종료 보고에서 기록 |
| public API / DTO / model 추가 없음 확인 | `lib/` public contract 변경이 없어야 함 | 새 DTO/model/public export 추가 | `git diff --name-only -- lib` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | `lib/`, platform production path 변경이 없어야 함 | UI 구현 파일, route, shell, platform 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| Phase 7-F projection boundary guardrail test | source-level projection boundary가 유지되어야 함 | projection boundary 누출 또는 authority drift | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-C hidden visual probe guardrail test | hidden probe가 production-visible path로 연결되지 않아야 함 | runtime/UI integration 또는 visible exposure 조짐 | `flutter test test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-G hidden probe contract hardening test | candidate marker가 public surface, route, shell로 노출되지 않아야 함 | public API / DTO / model / route / shell 노출 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| Phase 10-D candidate representation reader test | reader가 helper-local boundary에 머물러야 함 | public contract 승격, shell/route 노출, 금지 import 참조 | `flutter test test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 이번 Phase 11-A 문서/audit 작업의 완료 기준이 아니다. Phase 11-A는 production-visible UX 변화를 만들지 않으므로 사용자가 화면에서 확인할 새 동작도 만들지 않는다.

### 17.62 Phase 11-B ExplorerWorkspace shell mount precondition audit

Phase 11-B의 목적은 `ExplorerWorkspace` shell mount를 구현하는 것이 아니라, shell mount 검토 전에 필요한 전제조건, 위험 요소, 금지선, 검증 기준을 문서로 분리해 확인하는 것이다.

Phase 11-B는 shell mount 구현 단계가 아니다. 이 단계에서는 production UI diff, route wiring, route registration, route collapse, owner/controller/coordinator 이전, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, runtime/UI integration을 수행하지 않는다.

`ExplorerWorkspace` shell mount는 계속 `not approved`다. shell mount precondition을 검토한다는 사실은 production-visible UX 승인, production owner migration, route collapse 승인, Level 3 production visible consumer 승인으로 이어지지 않는다. 사용자-visible UX 변화는 Phase 11-B 범위가 아니다.

현재 production entry 구조는 유지한다.

- `main.dart -> HomeScreen`
- `HomeScreen -> Navigator.push -> WordExplorerScreen`

`ExplorerWorkspace`는 아직 production owner, controller, coordinator가 아니다. 현재 production explorer owner는 계속 `WordExplorerScreen`이며, graph center, selected word, detail target, explorer history, route push 흐름의 소유권은 이전하지 않는다.

#### 17.62.1 shell mount 검토 전 최소 precondition

shell mount 검토 전에 다음 조건을 먼저 확인해야 한다. 아래 조건은 구현 승인 조건이 아니라 후속 feature 승인 여부를 판단하기 위한 audit 기준이다.

| precondition | 확인 기준 | Phase 11-B 판단 |
| --- | --- | --- |
| production entry 영향 범위 | `main.dart -> HomeScreen` 구조와 `HomeScreen -> Navigator.push -> WordExplorerScreen` 진입 경로를 유지한 채 검토 가능한지 확인한다. | entry 변경은 `not approved`다. |
| route 영향 범위 | route registration 없이 검토 가능한지, route collapse가 필요한지 확인한다. | route wiring / route registration / route collapse는 `not approved`다. |
| ownership 영향 범위 | `ExplorerWorkspace`가 owner/controller/coordinator가 되는 순간 어떤 책임이 이동하는지, 기존 owner와 충돌하는지 확인한다. | canonical owner migration은 `not approved`다. |
| persistence authority 영향 범위 | Provider / Repository / Navigator / persistence authority migration 없이 가능한지 확인한다. | authority migration은 `not approved`다. |
| projection result 의미 | projection 결과가 persistence, history, source-of-truth payload처럼 사용될 위험이 있는지 확인한다. | projection result persistence/history/source-of-truth usage는 `not approved`다. |
| UI diff 영향 범위 | shell mount가 production UI diff를 동반하는지, 사용자-visible 변화 없이 검토 가능한지 확인한다. | production UI diff와 runtime/UI integration은 `not approved`다. |
| public contract 영향 범위 | DTO/model/public API 추가 없이 가능한지 확인한다. | DTO/model/public API addition은 `not approved`다. |
| Phase 10 결과 해석 | Phase 10-D `candidate representation reader`가 helper-local 구조로만 유지되는지 확인한다. | public contract 승격은 `not approved`다. |
| 테스트 기준 | source-level guardrail test로 entry, route, shell, public contract, persistence authority 변경을 막을 수 있는지 확인한다. | Phase 11-B에서는 UI 테스트를 수행하지 않고 확인 방법만 정의한다. |

#### 17.62.2 shell mount 위험 요소

`ExplorerWorkspace` shell mount는 단순한 wrapper 추가로 취급할 수 없다. production tree에 shell이 mount되면 다음 위험이 함께 발생할 수 있다.

- production entry가 `HomeScreen` 중심 구조에서 다른 shell entry로 이동할 위험
- `HomeScreen -> WordExplorerScreen` Navigator 진입 경로가 변경되거나 축소될 위험
- route registration 또는 route wiring이 shell 중심으로 재배치될 위험
- route collapse가 shell mount의 부수 효과처럼 처리될 위험
- `ExplorerWorkspace`가 production owner/controller/coordinator처럼 해석될 위험
- `WordExplorerScreen`과 `ExplorerWorkspace`가 graph center, selected word, detail target, history authority를 중복 소유할 위험
- Provider / Repository / Navigator / persistence authority가 shell 쪽으로 이동할 위험
- projection result가 persistence, history, source-of-truth처럼 사용될 위험
- Phase 10-D helper-local `candidate representation reader`가 public API, DTO, model, route contract, shell contract로 오해될 위험
- production-visible UX 승인 없이 UI diff 또는 visible consumer exposure가 발생할 위험

위 위험 중 하나라도 실제 구현 변경을 필요로 하면 Phase 11-B 범위를 벗어난다. 해당 변경은 별도 feature 설계, 수정 파일 목록, command 기반 검증 계획, UI 확인 기준, 사용자 승인 대상으로 분리해야 한다.

#### 17.62.3 현재 유지되는 금지선

아래 항목은 Phase 11-B에서도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.62.4 shell mount 검토가 승인으로 이어지지 않는 기준

Phase 11-B에서 shell mount precondition을 문서화해도 다음 항목은 승인된 것으로 해석하지 않는다.

- `ExplorerWorkspace` shell을 production tree에 mount하는 것
- `ExplorerWorkspace`를 production owner, controller, coordinator로 승격하는 것
- `main.dart`, `HomeScreen`, `WordExplorerScreen`의 production entry 또는 Navigator 진입 흐름을 바꾸는 것
- route registration, route wiring, route alias, route collapse를 변경하는 것
- Provider / Repository / Navigator / persistence authority를 이전하는 것
- DTO/model/public API를 추가하는 것
- Phase 10-D `candidate representation reader`를 reusable contract 또는 public contract로 승격하는 것
- 사용자-visible UX 변화를 만드는 것

shell mount가 후속 단계에서 허용되더라도 그 자체로 production-visible UX 승인을 뜻하지 않는다. shell mount 구현, production UI diff, UI 기반 수동 확인, rollback 기준은 별도 feature 단계에서 다시 승인받아야 한다.

#### 17.62.5 테스트 기준

Phase 11-B의 command 기반 검증은 source-level guardrail 확인으로 제한한다. 목표는 이번 문서/audit 변경이 production entry, route, shell mount, public contract, persistence authority, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| production entry 구조 유지 확인 | `main.dart -> HomeScreen`, `HomeScreen -> Navigator.push -> WordExplorerScreen` 흐름이 유지되어야 함 | `home` 변경, route entry 변경, explorer 진입 구조 변경 | `rg` 기반 source 확인 | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell production mount 없음 확인 | production entry 또는 `WordExplorerScreen` production path에 shell mount가 없어야 함 | shell mount, visible widget tree 연결, shell prop 연결 | `rg` 기반 source 확인 | 작업 종료 보고에서 기록 |
| route registration / route wiring 변경 없음 확인 | route table, `Navigator` wiring, route alias 변경이 없어야 함 | route 등록 변경, push 대상 변경, route collapse 조짐 | `git diff`와 `rg` 기반 확인 | 작업 종료 보고에서 기록 |
| public API / DTO / model 추가 없음 확인 | `lib/` public contract 변경이 없어야 함 | 새 DTO/model/public export 추가 | `git diff --name-only -- lib` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | `lib/`, platform production path 변경이 없어야 함 | UI 구현 파일, route, shell, platform 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| Phase 7-F projection boundary guardrail test | source-level projection boundary가 유지되어야 함 | projection boundary 누출 또는 authority drift | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-C hidden visual probe guardrail test | hidden probe가 production-visible path로 연결되지 않아야 함 | runtime/UI integration 또는 visible exposure 조짐 | `flutter test test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-G hidden probe contract hardening test | candidate marker가 public surface, route, shell로 노출되지 않아야 함 | public API / DTO / model / route / shell 노출 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| Phase 10-D candidate representation reader test | reader가 helper-local boundary에 머물러야 함 | public contract 승격, shell/route 노출, 금지 import 참조 | `flutter test test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 Phase 11-B에서 수행하지 않는다. UI 기반 수동 테스트는 production-visible UX 변경, shell mount 구현, route 또는 visible consumer 노출이 별도 feature 단계에서 승인된 뒤 필요하다. 그 시점의 UI 확인 기준은 시작 화면, 조작 순서, 사람이 식별 가능한 테스트 데이터, 기대 화면 변화, 실패 증상, 완료 판단 기준을 포함해야 한다.

### 17.63 Phase 11-C production-visible candidate boundary review

Phase 11-C의 목적은 Phase 11-A readiness review와 Phase 11-B shell mount precondition audit을 바탕으로, 향후 production-visible 후보를 검토할 때 넘지 말아야 할 경계와 후보 조건을 문서화하는 것이다.

Phase 11-C는 production-visible feature 구현 단계가 아니다. 이 단계에서는 production UI diff, `ExplorerWorkspace` shell mount, route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator 이전, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, runtime/UI integration, Level 3 production-visible consumer 구현을 수행하지 않는다.

사용자-visible UX 변화는 Phase 11-C 범위가 아니다. 실제 UX 변화는 별도 승인된 feature 단계에서만 가능하며, 그 단계에서는 수정 파일 목록, command 기반 검증 계획, UI 기반 수동 테스트 기준, rollback 기준을 다시 승인받아야 한다.

#### 17.63.1 candidate 최소 조건

production-visible candidate로 검토하려면 먼저 아래 최소 조건을 만족해야 한다. 이 조건은 구현 승인 조건이 아니라 후속 feature 후보를 검토하기 위한 boundary review 기준이다.

| 검토 축 | 최소 조건 | Phase 11-C 판단 |
| --- | --- | --- |
| candidate 위치 | Phase 10 `candidate representation reader`처럼 helper-local 또는 hidden/probe-adjacent read-only 구조에 머무르는지 먼저 확인한다. shell contract, route contract, public contract처럼 해석될 수 있는 위치는 별도 feature 승인 전 candidate 검토 범위가 아니다. | helper-local boundary 유지가 기본 조건이다. |
| candidate 책임 | 단순 read/representation 책임인지 확인한다. UI rendering, navigation, persistence, ownership, coordination 책임을 가지면 Phase 11-C 범위를 벗어난다. | read-only representation 후보만 검토 가능하다. |
| Level 2 / Level 3 경계 | Level 2는 unmounted, non-route, non-owner, non-persistent, non-production-visible helper-local consumer로 제한한다. Level 3은 production tree mount, 사용자-visible surface, route/entry 영향, owner 또는 persistence authority 영향을 동반하는 순간으로 본다. | Level 3 production-visible consumer는 `not approved`다. |
| production-visible 전환 가능성 | production-visible 후보가 되려면 entry 영향 범위, route 영향 범위, shell mount 여부, owner/persistence authority 영향, UI diff, UI 테스트 기준, rollback 기준을 별도 feature 설계로 제시해야 한다. | Phase 11-C는 전환 가능성의 검토 조건만 기록한다. |
| shell mount 관계 | candidate 검토가 `ExplorerWorkspace` shell mount 승인으로 이어지지 않아야 한다. shell mount는 별도 feature 승인 전까지 금지한다. | `ExplorerWorkspace` shell mount는 `not approved`다. |
| route와 entry 구조 | `main.dart -> HomeScreen`, `HomeScreen -> Navigator.push -> WordExplorerScreen` 구조를 유지하고 route registration 없이 검토 가능한 후보만 Phase 11-C boundary 안에 둔다. | route wiring / route registration / entry 변경은 `not approved`다. |
| 테스트 기준 | source-level guardrail test로 entry, route, shell, public contract, persistence authority 변경 없음과 helper-local boundary 유지를 고정할 수 있어야 한다. | Phase 11-C에서는 UI 테스트를 수행하지 않고 확인 기준만 정의한다. |

#### 17.63.2 candidate가 넘으면 안 되는 금지선

아래 항목 중 하나라도 필요해지는 후보는 Phase 11-C candidate boundary를 넘는다. 해당 후보는 Phase 11-C 문서/audit 범위가 아니라 별도 feature 설계와 사용자 승인 대상으로 분리해야 한다.

- production UI diff
- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- Provider / Repository / Navigator / persistence authority migration
- DTO/model/public API addition
- projection result persistence/history/source-of-truth usage
- runtime/UI integration
- production visual consumer exposure
- route collapse
- canonical owner migration
- owner/controller/coordinator migration
- Level 3 production-visible consumer 구현

#### 17.63.3 Phase 10 / 11-A / 11-B 결과의 승격 금지

Phase 10-D의 `candidate representation reader`는 계속 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local 구조로만 해석한다. `readCandidateRepresentation`, `candidateSlots`, `candidateLabels`는 helper 내부 read-only candidate representation이며 public symbol, reusable contract, DTO, model, route argument, shell prop, persistence payload, history payload, source-of-truth payload가 아니다.

Phase 10, Phase 11-A, Phase 11-B의 결과는 다음을 의미하지 않는다.

- public API 승격 아님
- DTO/model 추가 아님
- route contract 추가 아님
- shell contract 추가 아님
- production visual consumer exposure 아님
- runtime/UI integration 아님
- `ExplorerWorkspace` shell mount 승인 아님
- route wiring / route registration 변경 승인 아님
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 승인 아님
- Provider / Repository / Navigator / persistence authority migration 승인 아님
- owner/controller/coordinator migration 승인 아님
- Level 3 production-visible consumer 승인 아님

#### 17.63.4 현재 유지되는 금지선

아래 항목은 Phase 11-C에서도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- owner/controller/coordinator migration: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.63.5 테스트 기준

Phase 11-C의 command 기반 검증은 source-level guardrail 확인과 path-level diff 확인으로 제한한다. 목표는 이번 문서/audit 변경이 production entry, route, shell mount, public contract, DTO/model, persistence authority, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| production entry 구조 유지 확인 | `main.dart -> HomeScreen` 구조가 유지되어야 함 | `home` 변경, route entry 변경 | `rg -n "home: const HomeScreen" lib/main.dart` | 작업 종료 보고에서 기록 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 유지 확인 | `Navigator.push`, `MaterialPageRoute`, `WordExplorerScreen` 흐름이 유지되어야 함 | push 대상 변경, explorer 진입 구조 변경, route collapse 조짐 | `rg -n "Navigator\.push|WordExplorerScreen|MaterialPageRoute" lib/ui/home_screen.dart` | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell production mount 없음 확인 | production entry 관련 경로인 `main.dart`, `home_screen.dart`, `word_explorer_screen.dart`에 `ExplorerWorkspace(` mount가 없어야 함 | production path shell mount, visible widget tree 연결 | `rg -n "ExplorerWorkspace\(" lib/main.dart lib/ui/home_screen.dart lib/ui/word_explorer_screen.dart` | 작업 종료 보고에서 기록 |
| public API / DTO / model 추가 없음 확인 | `lib/`, `test/`, platform, dependency 파일 변경이 문서 변경 범위를 벗어나지 않아야 함 | 새 DTO/model/public export, production 코드 변경, dependency 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | production UI 관련 경로 변경이 없어야 함 | `lib/`, platform production path 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Phase 7-F projection boundary guardrail test | source-level projection boundary가 유지되어야 함 | projection boundary 누출 또는 authority drift | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-C hidden visual probe guardrail test | hidden probe가 production-visible path로 연결되지 않아야 함 | runtime/UI integration 또는 visible exposure 조짐 | `flutter test test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-G hidden probe contract hardening test | candidate marker가 public surface, route, shell로 노출되지 않아야 함 | public API / DTO / model / route / shell 노출 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| Phase 10-D candidate representation reader test | reader가 helper-local boundary에 머물러야 함 | public contract 승격, shell/route 노출, 금지 import 참조 | `flutter test test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 Phase 11-C에서 수행하지 않는다. Phase 11-C는 사용자-visible UX 변화를 만들지 않으므로 화면에서 확인할 새 동작도 만들지 않는다. UI 기반 수동 테스트는 production-visible UX 변경, shell mount 구현, route 또는 visible consumer 노출이 별도 feature 단계에서 승인된 뒤 필요하다. 그 시점의 UI 확인 기준은 테스트 목적, 시작 화면, 조작 순서, 사람이 식별 가능한 테스트 데이터, 기대되는 화면 변화, 실패 시 확인할 증상, 테스트 완료 판단 기준을 포함해야 한다.

### 17.64 Phase 11-D Phase 11 termination audit

Phase 11-D의 목적은 Phase 11-A/B/C에서 정리한 내용을 기준으로 Phase 11 전체가 무엇을 확정했고 무엇을 여전히 승인하지 않았는지 문서화하며, Phase 11 종료 가능 여부를 판단하는 것이다.

Phase 11-D는 implementation 단계가 아니라 termination audit 단계다. 이 단계에서는 production-visible UX 구현, production UI diff, `ExplorerWorkspace` shell mount, route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, runtime/UI integration, Level 3 production-visible consumer 구현을 수행하지 않는다.

사용자-visible UX 변화는 Phase 11 범위에서 발생하지 않았다. 실제 UX 변화는 별도 승인된 후속 feature 단계에서만 가능하며, 해당 단계에서는 수정 파일 목록, command 기반 검증 계획, UI 기반 수동 테스트 기준, rollback 기준을 다시 승인받아야 한다.

#### 17.64.1 Phase 11-A/B/C 완료 내용 요약

| 단계 | 완료 내용 | Phase 11-D 해석 |
| --- | --- | --- |
| Phase 11-A | Phase 10 `candidate representation reader` 이후 production-visible 전환을 검토하기 위한 readiness 조건과 금지선을 문서화했다. | docs/audit 결과이며 production-visible 구현 승인이 아니다. |
| Phase 11-B | `ExplorerWorkspace` shell mount 검토 전 precondition, 위험 요소, 금지선, 검증 기준을 문서화했다. | docs/audit 결과이며 shell mount 승인이 아니다. |
| Phase 11-C | production-visible candidate를 검토할 때 넘지 말아야 할 boundary와 최소 후보 조건을 문서화했다. | docs/audit 결과이며 Level 3 production-visible consumer 승인이 아니다. |

#### 17.64.2 Phase 11 전체에서 확정된 것

Phase 11 전체에서 확정된 것은 구현 결과가 아니라 후속 feature 검토 전 기준이다.

- production-visible 전환 readiness 조건
- `ExplorerWorkspace` shell mount precondition
- production-visible candidate boundary
- Phase 10/11 결과의 승격 금지 기준
- 후속 feature 단계 전 유지해야 할 금지선
- command 기반 source-level guardrail 확인 기준

Phase 10-D의 `candidate representation reader`는 계속 `_debugValidateHiddenVisualProbe(...)` 내부 helper-local 구조로만 해석한다. `readCandidateRepresentation`, `candidateSlots`, `candidateLabels`는 helper 내부 read-only candidate representation이며 public symbol, reusable contract, DTO, model, route argument, shell prop, persistence payload, history payload, source-of-truth payload가 아니다.

Phase 10/11 결과는 다음을 의미하지 않는다.

- public API 승격 아님
- DTO/model 추가 아님
- route contract 추가 아님
- shell contract 추가 아님
- production visual consumer exposure 아님
- runtime/UI integration 아님
- `ExplorerWorkspace` shell mount 승인 아님
- route wiring / route registration 변경 승인 아님
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 승인 아님
- owner/controller/coordinator migration 승인 아님
- Provider / Repository / Navigator / persistence authority migration 승인 아님
- Level 3 production-visible consumer 승인 아님

#### 17.64.3 Phase 11 종료 audit 판단

| 질문 | Phase 11-D 판단 |
| --- | --- |
| Phase 11이 production-visible 구현을 승인했는가? | 아니오. Phase 11은 production-visible 전환 검토 조건만 확정했다. |
| Phase 11이 `ExplorerWorkspace` shell mount를 승인했는가? | 아니오. shell mount는 계속 `not approved`다. |
| Phase 11이 route 변경을 승인했는가? | 아니오. route wiring / route registration / route collapse는 계속 `not approved`다. |
| Phase 11이 public API / DTO / model 추가를 승인했는가? | 아니오. public contract 승격은 계속 `not approved`다. |
| Phase 11이 실제 사용자-visible UX 변경을 발생시켰는가? | 아니오. Phase 11은 화면에서 확인할 새 동작을 만들지 않았다. |
| Phase 11이 남긴 결과는 무엇인가? | production-visible 전환 readiness 조건, shell mount precondition, production-visible candidate boundary, 후속 feature 단계 전 금지선이다. |
| Phase 11 이후 가능한 다음 단계는 무엇인가? | 별도 승인된 docs/audit 또는 feature 단계다. 단, production UI diff / shell mount / route 변경은 여전히 별도 승인이 필요하다. |

#### 17.64.4 Phase 11 전체에서 여전히 승인되지 않은 것

아래 항목은 Phase 11-D 종료 audit 이후에도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- owner/controller/coordinator migration: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.64.5 Phase 11 종료 가능 조건

Phase 11은 아래 조건을 만족할 때 종료 가능 상태로 판단할 수 있다.

- Phase 11-A/B/C/D가 모두 docs/audit 결과로만 해석되어야 한다.
- Phase 11-D가 production-visible 구현, shell mount, route 변경, public contract 승인을 뜻하지 않아야 한다.
- production entry 구조가 `main.dart -> HomeScreen`, `HomeScreen -> Navigator.push -> WordExplorerScreen`로 유지되어야 한다.
- `ExplorerWorkspace` shell이 production path에 mount되지 않아야 한다.
- route wiring / route registration 변경이 없어야 한다.
- public API / DTO / model 추가가 없어야 한다.
- production UI diff가 없어야 한다.
- 기존 Phase 7-F / 8-C / 8-G / 10-D source-level guardrail test가 통과해야 한다.

#### 17.64.6 Phase 12 또는 후속 단계 검토 후보

Phase 11 이후에는 다음 후보만 별도 승인 대상으로 넘길 수 있다.

- Phase 11 결과를 기준으로 한 추가 docs/audit
- production-visible feature 진입 전 세부 precondition audit
- `ExplorerWorkspace` shell mount 가능성 검토 feature
- production UI diff를 포함하는 별도 feature
- route wiring / route registration 변경 검토 feature
- owner/controller/coordinator migration 검토 feature
- Provider / Repository / Navigator / persistence authority migration 검토 feature
- public API / DTO / model 추가 검토 feature
- Level 3 production-visible consumer 구현 검토 feature

위 후보는 모두 Phase 11-D에서 승인된 것이 아니다. production UI diff, shell mount, route 변경, owner migration, authority migration, public contract 승격은 각각 별도 설계, 수정 파일 목록, command 기반 검증 계획, UI 기반 수동 테스트 기준, 사용자 승인이 필요하다.

#### 17.64.7 명령어 기반 수동 테스트 체크리스트

Phase 11-D의 command 기반 검증은 source-level guardrail 확인과 path-level diff 확인으로 제한한다. 목표는 이번 문서/audit 변경이 production entry, route, shell mount, public contract, DTO/model, persistence authority, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| production entry 구조 유지 확인 | `main.dart -> HomeScreen` 구조가 유지되어야 함 | `home` 변경, route entry 변경 | `rg -n "home: const HomeScreen" lib/main.dart` | 작업 종료 보고에서 기록 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 유지 확인 | `Navigator.push`, `MaterialPageRoute`, `WordExplorerScreen` 흐름이 유지되어야 함 | push 대상 변경, explorer 진입 구조 변경, route collapse 조짐 | `rg -n "Navigator\.push|WordExplorerScreen|MaterialPageRoute" lib/ui/home_screen.dart` | 작업 종료 보고에서 기록 |
| `ExplorerWorkspace` shell production mount 없음 확인 | production entry 관련 경로인 `main.dart`, `home_screen.dart`, `word_explorer_screen.dart`에 `ExplorerWorkspace(` mount가 없어야 함 | production path shell mount, visible widget tree 연결 | `rg -n "ExplorerWorkspace\(" lib/main.dart lib/ui/home_screen.dart lib/ui/word_explorer_screen.dart` | 작업 종료 보고에서 기록 |
| route registration / route wiring 변경 없음 확인 | `lib/`, `test/`, platform, dependency 파일 변경이 문서 변경 범위를 벗어나지 않아야 함 | route 등록 변경, push 대상 변경, route collapse 조짐 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| public API / DTO / model 추가 없음 확인 | `lib/`, `test/`, platform, dependency 파일 변경이 문서 변경 범위를 벗어나지 않아야 함 | 새 DTO/model/public export, production 코드 변경, dependency 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | production UI 관련 경로 변경이 없어야 함 | `lib/`, platform production path 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Phase 7-F projection boundary guardrail test | source-level projection boundary가 유지되어야 함 | projection boundary 누출 또는 authority drift | `flutter test test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-C hidden visual probe guardrail test | hidden probe가 production-visible path로 연결되지 않아야 함 | runtime/UI integration 또는 visible exposure 조짐 | `flutter test test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` | 작업 종료 보고에서 기록 |
| Phase 8-G hidden probe contract hardening test | candidate marker가 public surface, route, shell로 노출되지 않아야 함 | public API / DTO / model / route / shell 노출 | `flutter test test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart` | 작업 종료 보고에서 기록 |
| Phase 10-D candidate representation reader test | reader가 helper-local boundary에 머물러야 함 | public contract 승격, shell/route 노출, 금지 import 참조 | `flutter test test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 Phase 11-D에서 수행하지 않는다. Phase 11-D는 사용자-visible UX 변화를 만들지 않으므로 화면에서 확인할 새 동작도 만들지 않는다. UI 기반 수동 테스트는 production-visible UX 변경, shell mount 구현, route 또는 visible consumer 노출이 별도 feature 단계에서 승인된 뒤 필요하다.

### 17.65 Phase 12-A minimum production-visible candidate selection audit

Phase 12-A는 구현 단계가 아니라 `minimum production-visible candidate selection audit` 단계다. 이번 단계의 목적은 ExplorerWorkspace를 곧바로 production-visible 구조로 전환하는 것이 아니라, Phase 12에서 가장 작은 production-visible 후보 범주가 무엇인지 문서/audit 기준으로 선정 가능한 상태를 만드는 것이다.

Phase 12-A는 production UI diff, `ExplorerWorkspace` shell mount, route wiring, route registration, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API addition, projection result persistence/history/source-of-truth usage, runtime/UI integration, production visual consumer exposure, route collapse, canonical owner migration, Level 3 production-visible consumer 구현을 수행하지 않는다.

#### 17.65.1 Phase 12-A 판단 질문

Phase 12-A에서 판단할 수 있는 것은 구현 가능성이 아니라 후보 범주의 문서상 적합성이다.

| 질문 | Phase 12-A 판단 |
| --- | --- |
| Phase 12의 목적을 production-visible 전환 실행이 아니라 minimum production-visible candidate selection으로 정의할 수 있는가? | 예. Phase 12-A는 전환 실행이 아니라 후보 범주 선정 audit이다. |
| full `ExplorerWorkspace` shell mount를 Phase 12-A 또는 Phase 12-B의 직접 구현 후보에서 제외해야 하는가? | 예. Phase 12-A 직접 후보에서 제외한다. Phase 12-B에서도 별도 승인 전 직접 구현 후보로 넘기지 않는다. |
| shell mount 없이 기존 `HomeScreen -> WordExplorerScreen` 경로 안에서 검토 가능한 최소 UX 후보가 있는가? | 예. 기존 `WordExplorerScreen` 경로 안의 제한적 read-only UX diff는 Phase 12-B의 후보 범주가 될 수 있다. 단, Phase 12-A는 해당 UX diff를 구현하거나 승인하지 않는다. |
| production UI diff는 검토 대상으로만 둘 것인가, Phase 12-B 이후 제한 구현 후보로 넘길 수 있는가? | production UI diff는 검토 대상이 될 수 있으나 구현 승인은 아직 아니다. Phase 12-B 이후 제한 후보로 넘기려면 별도 설계와 승인이 필요하다. |
| feature 브랜치로 넘어가기 위한 조건은 무엇인가? | candidate 범주, 진입 경로, 금지선, UI diff 범위, rollback 가능성, command 기반 검증, UI 기반 수동 테스트 기준이 문서화되어야 한다. |
| Phase 12-A 종료 시 어떤 판단이 가능해야 하는가? | shell mount를 직접 후보에서 제외하고, 기존 `WordExplorerScreen` 경로 안의 제한적 read-only UX diff를 Phase 12-B 후보 범주로 둘 수 있는지 판단할 수 있어야 한다. |

#### 17.65.2 `ExplorerWorkspace` shell mount 직접 후보 제외

`ExplorerWorkspace` shell mount는 Phase 12-A 직접 후보에서 제외한다. shell mount는 단일 UI 조정이 아니라 다음 변경 압력을 동시에 만들 수 있기 때문이다.

- route 변경 압력
- owner/controller/coordinator migration 압력
- production UI diff 압력
- Provider / Repository / Navigator / persistence authority migration 압력
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 압력
- route collapse 또는 production visual consumer exposure 압력

따라서 Phase 12-A는 shell mount를 구현하지 않고, shell mount를 Phase 12-B의 직접 구현 후보로도 자동 승격하지 않는다. shell mount가 필요해지는 후보는 별도 feature 설계, 수정 파일 목록, command 기반 검증 계획, UI 기반 수동 테스트 기준, rollback 기준, 사용자 승인을 다시 받아야 한다.

#### 17.65.3 production UI diff 상태 구분

Phase 12-A에서 production UI diff의 상태는 아래 세 단계로 분리한다.

| 구분 | 상태 | Phase 12-A 의미 |
| --- | --- | --- |
| 검토 대상 | 가능 | production-visible 후보 범주를 고르기 위한 문서상 비교 대상으로 둘 수 있다. |
| 구현 승인 | 아직 아님 | Phase 12-A는 production UI diff를 구현하거나 승인하지 않는다. |
| Phase 12-B 이후 제한 후보 | 가능 | 기존 `HomeScreen -> WordExplorerScreen` 진입 구조를 유지하고 shell mount 없이 작고 rollback 가능한 read-only UX diff로 제한될 때만 후보가 될 수 있다. |

이 구분은 production UI diff를 즉시 구현한다는 뜻이 아니다. Phase 12-B 이후에도 production UI diff가 실제 구현 후보가 되려면 수정 파일 목록, 변경 위치, command 기반 검증 계획, UI 기반 수동 테스트 기준, rollback 기준을 다시 제시하고 승인받아야 한다.

#### 17.65.4 기존 `WordExplorerScreen` 경로 안 최소 후보 가능성

기존 `HomeScreen -> WordExplorerScreen` 경로 안의 제한적 read-only UX diff는 Phase 12-B의 후보 범주가 될 수 있다. 단, Phase 12-A는 해당 UX diff를 구현하거나 승인하지 않는다.

Phase 12-B 후보로 검토 가능한 최소 범주는 다음 조건을 만족해야 한다.

- `HomeScreen -> WordExplorerScreen` 진입 구조를 유지한다.
- `ExplorerWorkspace` shell mount가 없다.
- route wiring 또는 route registration 변경이 없다.
- owner/controller/coordinator migration이 없다.
- Provider / Repository / Navigator / persistence authority migration이 없다.
- DTO/model/public API addition이 없다.
- projection result persistence/history/source-of-truth usage가 없다.
- runtime/UI integration 권한을 새로 만들지 않는다.
- production visual consumer exposure를 확대하지 않는다.
- UI diff가 작고 rollback 가능해야 한다.

이 후보 범주는 특정 UI 구현 승인으로 해석하지 않는다. Phase 12-A의 결론은 후보 범주 선정이며, production-visible UX 구현은 별도 승인된 후속 단계에서만 가능하다.

#### 17.65.5 Phase 12-B 또는 feature 브랜치 진입 조건

Phase 12-B 또는 feature 브랜치로 넘어가려면 아래 조건이 먼저 문서상 명확해야 한다.

- candidate 범주가 문서상 명확할 것
- 진입 경로가 기존 `HomeScreen -> WordExplorerScreen`을 유지할 것
- shell mount가 없을 것
- route 변경이 없을 것
- owner/controller/coordinator migration이 없을 것
- Provider / Repository / Navigator / persistence authority migration이 없을 것
- DTO/model/public API 추가가 없을 것
- projection result persistence/history/source-of-truth usage가 없을 것
- runtime/UI integration 권한이 새로 생기지 않을 것
- production visual consumer exposure가 확대되지 않을 것
- UI diff 범위가 작고 rollback 가능할 것
- 수동 테스트 기준이 문서화될 것
- command 기반 검증 계획과 UI 기반 수동 테스트 절차가 구분될 것
- 수정 파일 목록과 변경 위치가 사전 제시될 것
- 사용자가 별도 승인할 것

위 조건은 Phase 12-A 종료와 동시에 자동 충족되지 않는다. Phase 12-A는 다음 단계로 넘길 수 있는 후보 범주와 금지선만 정리한다.

#### 17.65.6 Phase 12-A에서 유지되는 금지선

아래 항목은 Phase 12-A 종료 이후에도 별도 승인 전까지 `not approved`로 유지한다.

- production UI diff 구현: `not approved`
- `ExplorerWorkspace` shell mount: `not approved`
- route wiring / route registration change: `not approved`
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경: `not approved`
- Provider / Repository / Navigator / persistence authority migration: `not approved`
- DTO/model/public API addition: `not approved`
- projection result persistence/history/source-of-truth usage: `not approved`
- runtime/UI integration: `not approved`
- production visual consumer exposure: `not approved`
- route collapse: `not approved`
- canonical owner migration: `not approved`
- owner/controller/coordinator migration: `not approved`
- Level 3 production visible consumer: `not approved`

#### 17.65.7 명령어 기반 수동 테스트 체크리스트

Phase 12-A의 command 기반 검증은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 문서/audit 변경이 production entry, route, shell mount, public contract, DTO/model, persistence authority, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-A 목적 정의 확인 | Phase 12-A가 `minimum production-visible candidate selection audit` 단계로 기록되어야 함 | production-visible 전환 실행 또는 구현 승인처럼 읽힘 | `rg -n "Phase 12-A|minimum production-visible candidate selection" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 금지선 유지 확인 | production UI diff, shell mount, route, Provider, Repository, Navigator, persistence, DTO, public API가 `not approved`로 유지되어야 함 | Phase 12-A가 production 연결 승인처럼 읽힘 | `rg -n "production UI diff|ExplorerWorkspace.*shell mount|route wiring|route registration|HomeScreen -> WordExplorerScreen|Provider|Repository|Navigator|persistence|DTO|public API|not approved" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| route / public API / DTO / model 변경 없음 확인 | `lib/`, `test/`, platform, dependency 파일 변경이 없어야 함 | route 등록 변경, 새 DTO/model/public export, dependency 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | production UI 관련 경로 변경이 없어야 함 | `lib/`, platform production path 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일이 Phase 12-A 문서 범위로 제한되어야 함 | `lib/` 코드 변경 또는 승인되지 않은 파일 변경 | `git status --short --branch` | 작업 종료 보고에서 기록 |

UI 기반 수동 테스트는 Phase 12-A에서 수행하지 않는다. Phase 12-A는 사용자-visible UX 변화를 만들지 않으므로 화면에서 확인할 새 동작도 만들지 않는다. UI 기반 수동 테스트는 production-visible UX 변경이 별도 feature 단계에서 승인된 뒤 필요하며, 그 시점에는 테스트 목적, 시작 화면, 조작 순서, 사람이 식별 가능한 테스트 데이터, 기대되는 화면 변화, 실패 시 확인할 증상, 테스트 완료 판단 기준을 포함해야 한다.

### 17.66 Phase 12-B WordExplorerScreen 최소 read-only context strip

Phase 12-B는 full `ExplorerWorkspace` shell mount가 아니라 기존 `HomeScreen -> WordExplorerScreen` production 진입 경로 안에서 수행하는 제한적 read-only UX diff 단계다. 이번 단계의 production-visible 변경은 `WordExplorerScreen` detail pane 상단에 작은 context strip을 추가하는 것으로 제한한다.

Context strip은 기존 `WordExplorerScreen` 내부 상태만 읽는다. 표시 내용은 `중심 단어: <centerWordId> · 선택: <selectedWordId>` 또는 선택 단어가 없을 때 `중심 단어: <centerWordId> · 선택 없음`이다. 이 strip은 보조 표시이며 클릭, 편집, 이동, route push, repository read/write, persistence 동작을 추가하지 않는다.

이번 구현에서 유지한 경계는 다음과 같다.

- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 없음
- route wiring / route registration 변경 없음
- `ExplorerWorkspace` shell mount 없음
- owner/controller/coordinator migration 없음
- Provider / Repository / Navigator / persistence authority migration 없음
- DTO/model/public API addition 없음
- `ExplorerWorkspaceState` projection visible UI 사용 없음
- projection result persistence/history/source-of-truth usage 없음
- route collapse 또는 canonical owner migration 없음

#### 17.66.1 명령어 기반 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 전체 Flutter 테스트 | 기존 테스트와 Phase 12-B guardrail 테스트가 통과해야 함 | context strip 구현이 기존 테스트 또는 source-level guardrail과 충돌 | `flutter test` | 작업 종료 보고에서 기록 |
| Phase 12-B 관련 source-level guardrail | context strip이 detail pane 내부에 있고 projection/route/shell/authority migration marker를 사용하지 않아야 함 | projection visible UI 사용, route 또는 repository hook 추가 | `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart` | 작업 종료 보고에서 기록 |
| diff 파일 범위 확인 | 변경 파일이 승인된 `lib/ui/word_explorer_screen.dart`, 관련 test/docs로 제한되어야 함 | route, shell, public API, dependency 파일 변경 | `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| projection visible UI 미사용 확인 | `_readOnlyWorkspaceProjection`, hidden probe, projection은 기존 assert-only 경계에 머물러야 함 | context strip이 projection을 visible UI 입력으로 사용 | `rg -n "ExplorerWorkspaceState|_debugValidateHiddenVisualProbe|explorerWorkspaceState|projection" lib/ui/word_explorer_screen.dart` | 작업 종료 보고에서 기록 |
| route 진입 경로 확인 | `HomeScreen -> WordExplorerScreen(initialWordId: normalizedWordId)`가 유지되어야 함 | route registration 또는 진입 구조 변경 | `rg -n "Navigator\\.push|MaterialPageRoute|HomeScreen" lib/ui/word_explorer_screen.dart lib/ui/home_screen.dart` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 커밋 전 변경 범위와 브랜치가 명확해야 함 | 승인되지 않은 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

#### 17.66.2 UI 기반 수동 테스트 체크리스트

UI 기반 수동 테스트는 클라이언트 확인 대상으로 남긴다. 구현자는 아래 절차를 수행했다고 보고하지 않는다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 기존 홈 진입 경로에서 context strip 확인 | `WordExplorerScreen` 우측 detail pane 상단에 `중심 단어: ... · 선택: ...` 또는 `선택 없음`이 표시됨 | strip 미표시, 문구 깨짐, detail pane 레이아웃 겹침 | 앱 실행 후 기존 HomeScreen에서 사람이 식별 가능한 단어를 선택해 탐색 화면 진입 |
| 그래프 노드 선택 반영 | 그래프에서 다른 노드를 선택하면 context strip의 선택 ID가 변경됨 | 선택 ID 미갱신, 기존 detail 내용 미표시 | `WordExplorerScreen`에서 그래프 노드를 클릭하고 우측 상단 strip과 detail 내용 확인 |
| 선택 해제 상태 확인 | 선택이 없으면 `선택 없음`이 표시됨 | 빈 문자열 표시 또는 이전 선택 잔존 | 선택 해제 동작이 가능한 상태에서 선택을 해제하고 strip 확인 |
| 기존 detail panel 유지 확인 | strip 아래 기존 detail 정보, loading, error, no-selection UI가 유지됨 | detail 내용이 사라지거나 스크롤 영역이 깨짐 | 탐색 진입 직후와 노드 선택 후 detail pane 확인 |
| 기존 탐색 흐름 유지 확인 | 뒤로 가기와 기존 HomeScreen 복귀 흐름이 유지됨 | route stack 변화, 뒤로 가기 실패 | `WordExplorerScreen`에서 뒤로 가기 실행 후 HomeScreen 복귀 확인 |

#### 17.66.3 baseline red 분리 판단

Phase 12-B 직접 관련 source-level guardrail은 통과했다.

```text
flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart
결과: 4 tests passed
```

클라이언트 UI 테스트도 성공으로 기록한다. 기존 `HomeScreen -> WordExplorerScreen` 진입 후 detail pane 상단 context strip 표시와 선택 ID 변경 흐름을 클라이언트가 확인했다.

전체 `flutter test`는 red 상태다.

```text
Phase 12-B 브랜치: +204 -6 실패
main baseline: +200 -6 실패
```

실패 계열은 main baseline과 동일 또는 동종이다. Phase 12-B 변경 파일인 `word_explorer_screen.dart` 또는 신규 Phase 12-B 테스트가 유발한 branch-only 실패는 확인되지 않았다.

따라서 전체 `flutter test` red는 Phase 12-B 신규 회귀가 아니라 기존 baseline red로 분리한다. Phase 12-B 병합 판단은 좁은 관련 테스트 통과, 클라이언트 UI 테스트 성공, 금지선 유지 여부를 기준으로 한다.

### 17.67 Phase 12-C 첫 production-visible UX diff 평가

Phase 12-C는 구현 단계가 아니라 docs/audit 단계다. 이번 단계의 목적은 Phase 12-B에서 처음 도입한 production-visible UX diff인 `WordExplorerScreen` detail pane 상단 context strip을 평가하고, 추가 UX 확장 또는 baseline 정리로 넘어가기 전 판단 기준을 문서화하는 것이다.

Phase 12-C는 코드 수정, UI 변경, 테스트 파일 수정, 플랫폼 파일 수정, dependency 변경을 수행하지 않는다. 또한 `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, projection result persistence/history/source-of-truth usage, `ExplorerWorkspaceState` projection visible UI 사용, route collapse, canonical owner migration, Level 3 production-visible consumer 승격을 승인하지 않는다.

#### 17.67.1 Phase 12-B context strip 평가

Phase 12-B context strip은 첫 production-visible UX diff로 성공한 것으로 평가한다. 성공 판단의 근거는 변경 범위가 작고 rollback 가능하며, 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지했고, `ExplorerWorkspace` shell mount와 route 변경 없이 기존 `WordExplorerScreen` 내부 상태만 read-only로 표시했다는 점이다.

다만 이 평가는 추가 UX 구현 승인으로 이어지지 않는다. Phase 12-C의 판단은 Phase 12-B 결과를 평가하는 docs/audit 기록이며, 추가 production-visible UX diff는 별도 범위 정의, 테스트 기준, 금지선 재확인, 사용자 승인을 거쳐야 한다.

Context strip의 장점은 다음과 같다.

- 작고 rollback 가능한 production-visible UX diff였다.
- 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지했다.
- `ExplorerWorkspace` shell mount가 없었다.
- route wiring / route registration 변경이 없었다.
- Provider / Repository / Navigator / persistence authority migration이 없었다.
- DTO/model/public API 추가가 없었다.
- `ExplorerWorkspaceState` projection visible UI 사용이 없었다.
- projection result persistence/history/source-of-truth usage가 없었다.

Context strip의 한계는 다음과 같다.

- raw ID 표시는 현재 최소 read-only UX diff로는 허용 가능하지만, 장기 사용자 UX로 유지하기에는 사용자 친화성이 낮을 수 있다.
- 장기 UX 표현으로는 lemma, spelling 또는 사람이 읽을 수 있는 대표 표시가 필요할 수 있다.
- 사람이 읽을 수 있는 표시로 조정하려면 추가 Repository 조회, 표시 정책, loading/error/no-selection 상태, 테스트 기준을 별도로 검토해야 한다.
- raw ID 표시를 조정하는 작업은 단순 문구 변경이 아니라 data read boundary와 표시 authority에 영향을 줄 수 있으므로 별도 승인 전 구현하지 않는다.

#### 17.67.2 context strip 유지/조정/제거 판단

Phase 12-C 기준으로 context strip은 유지한다. 제거할 직접 근거는 없으며, Phase 12-B 클라이언트 UI 테스트 성공은 참조 기록으로 남긴다.

다만 raw ID 표시는 장기 사용자 UX로 확정하지 않는다. 다음 UX 단계에서는 context strip을 그대로 유지할지, lemma/spelling 기반 표시로 조정할지, 또는 다른 detail pane context 표현으로 대체할지 먼저 판단해야 한다.

#### 17.67.3 다음 단계 선택지

| 선택지 | 내용 | 조건 |
| --- | --- | --- |
| A | context strip 유지 후 다음 제한 UX diff 검토 | baseline red 수용 정책 또는 정리 계획이 명확하고, 추가 UX diff 범위가 기존 진입 경로 안의 작은 read-only 변경으로 제한될 때 |
| B | context strip 표시 방식 조정 검토 | raw ID 대신 사람이 읽을 수 있는 표시가 필요하다고 판단하고, Repository 조회 또는 표시 정책 영향 범위를 별도로 정의할 때 |
| C | 추가 UX diff 전에 baseline `flutter test` red 정리 | 전체 테스트 red가 후속 production-visible UX 판단을 흐리므로 먼저 baseline 실패 원인과 수용 정책을 정리할 때 |

권장 판단은 다음과 같다.

```text
Phase 12-B는 성공으로 본다.
다만 추가 production-visible UX 확장 전,
baseline flutter test red 정리를 우선 검토한다.
```

#### 17.67.4 Phase 12-D 또는 다음 Phase 진입 조건

Phase 12-D 또는 다음 Phase로 진입하려면 아래 조건을 먼저 충족해야 한다.

- baseline `flutter test` red 정리 여부 또는 수용 정책을 명시해야 한다.
- context strip 유지/조정/제거 여부를 명시해야 한다.
- 추가 UX diff의 범위를 문서로 명시해야 한다.
- 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지해야 한다.
- `ExplorerWorkspace` shell mount가 없어야 한다.
- route wiring / route registration 변경이 없어야 한다.
- owner/controller/coordinator migration이 없어야 한다.
- Provider / Repository / Navigator / persistence authority migration이 없어야 한다.
- DTO/model/public API 추가가 없어야 한다.
- `ExplorerWorkspaceState` projection visible UI 사용이 없어야 한다.
- projection result persistence/history/source-of-truth usage가 없어야 한다.
- command 기반 테스트 기준과 UI 기반 수동 테스트 기준을 분리해 제시해야 한다.

위 조건이 충족되지 않으면 추가 UX 구현 브랜치로 넘어가지 않고 docs/audit를 계속해야 한다. 특히 baseline test red의 정리 여부 또는 수용 정책이 불명확하거나, context strip 표시 방식 조정이 Repository/Data Source 흐름을 요구하거나, shell mount / route 변경 / authority migration 압력이 생기는 경우에는 Phase 12-C 이후에도 docs/audit를 이어간다.

#### 17.67.5 production-visible UX diff 테스트 기준

production-visible UX diff를 계속 확장할 때는 아래 기준을 유지한다.

- 명령어 기반 테스트는 구현자가 수행하고 실제 실행 결과를 기록한다.
- UI 기반 수동 테스트는 클라이언트 확인 대상으로 남기며, 구현자는 수행하지 않은 UI 테스트를 수행했다고 보고하지 않는다.
- UI 기반 수동 테스트 안내에는 테스트 목적, 시작 화면, 조작 순서, 사람이 식별 가능한 테스트 데이터, 기대되는 화면 변화, 실패 시 확인할 증상, 테스트 완료 판단 기준을 포함한다.
- 전체 `flutter test`가 red인 경우 신규 회귀인지 baseline red인지 분리 판단해야 한다.
- baseline red를 수용하는 경우에는 수용 근거와 후속 정리 조건을 문서화해야 한다.

#### 17.67.6 Phase 12 전체 종료 전 해결 필요 항목

Phase 12 전체 종료 전에는 baseline `flutter test` red의 정리 또는 수용 정책, context strip의 장기 표시 방향, 추가 production-visible UX diff의 범위, shell mount / route 변경 / authority migration 금지선 유지 여부를 명확히 해야 한다.

Phase 12-C 자체는 UI 테스트를 수행하지 않는다. Phase 12-B에서 기존 `HomeScreen -> WordExplorerScreen` 진입 후 detail pane 상단 context strip 표시와 선택 ID 변경 흐름을 클라이언트가 확인했다는 점은 참조 기록으로만 사용한다.

#### 17.67.7 명령어 기반 확인 체크리스트

Phase 12-C의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-C 기록 확인 | Phase 12-C 목적, context strip 평가, baseline red 판단이 두 문서에 기록되어야 함 | Phase 12-C 항목 누락 또는 Phase 12-B 평가 누락 | `rg -n "Phase 12-B|context strip|baseline|flutter test|Phase 12-C" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 추가 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.68 Phase 12-D baseline test red inventory

Phase 12-D는 테스트 수정 단계가 아니라 docs/audit 단계다. 이번 단계의 목적은 main baseline의 `flutter test` red 상태를 inventory 형태로 정리하고, 각 실패가 ExplorerWorkspace Phase 12와 직접 관련 있는지, 기존 test debt인지, 오래된 API 또는 package/import 경로 문제인지, 즉시 작은 fix 브랜치로 정리할 수 있는지, 별도 test stabilization phase로 분리해야 하는지를 구분하는 것이다.

Phase 12-D에서는 코드 수정, 테스트 파일 수정, UI 변경, production route 변경, `ExplorerWorkspace` shell mount, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, baseline 실패를 고치기 위한 임의 수정을 수행하지 않는다.

#### 17.68.1 확인 기준과 실행 명령

확인 기준은 `main` 최신 상태에서 생성한 `docs/explorer-workspace-phase12d-baseline-test-red-inventory` 브랜치다. 기준 HEAD는 `b1fc6dd570b8f6f2a9fd8c1476e20e6ae289f523`이며, Phase 12-D 문서 수정 전 working tree는 clean 상태였다.

실행한 주요 명령은 다음과 같다.

- `git checkout main`
- `git pull --ff-only`
- `git checkout -b docs/explorer-workspace-phase12d-baseline-test-red-inventory`
- `flutter test --reporter expanded`
- `flutter test --reporter compact`
- `flutter test test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart --reporter expanded`
- `flutter test test/data/repositories/word_repository_read_source_policy_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart --reporter expanded`
- `flutter test test/ui/word_info_panel_test.dart --reporter expanded`
- `flutter test test/widget_test.dart --reporter expanded`
- `rg -n "WordInfoPanel\\(|wordMap|package:study|MyApp|Phase 5-A|guardrail|representative|read_source|Repository" test docs lib`
- `rg -n "class WordInfoPanel|WordInfoPanel\\(" lib test`
- `rg -n "class MyApp|package:study|package:reshet" lib test`

#### 17.68.2 전체 flutter test baseline red 요약

전체 `flutter test` 결과는 `+204 -6`으로 red 상태다. JSON reporter 기준으로 실패 event를 다시 추출했을 때도 실패 6건은 동일하게 확인되었다.

현재 inventory 기준으로 Phase 12-B/C 변경 파일 또는 신규 Phase 12-B 테스트가 직접 유발한 branch-only 실패는 확인되지 않았다. 확인된 실패는 기존 baseline test debt로 분류한다.

#### 17.68.3 실패 목록 inventory

| 실패 테스트 파일 | 실패 테스트명 또는 그룹명 | 실패 유형 | 원인 요약 | Phase 12-B/C 직접 관련 여부 | 즉시 fix 가능 여부 | 별도 test stabilization 필요 여부 | 권장 브랜치 성격 | 우선순위 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `test/data/repositories/word_repository_read_source_policy_test.dart` | loading 단계 | 컴파일 실패 / 오래된 API 참조 | 테스트가 `WordRepository.getWordMapByIdForSplitViewSingleWord`, `getWordDetailMapByIdForReadSourcePhase2Only`를 호출하지만 현재 `lib/data/repositories/word_repository.dart`에는 해당 public method가 없다. 현재 확인된 대응 API 후보는 `getWordDetailLikeDisplayItemByIdForSplitView`, `getWordMapByIdForExplorerSingleWord` 계열이다. | 직접 관련 없음 | 가능. 테스트를 현행 public contract에 맞추거나 compatibility API 복원 여부를 별도 판단해야 한다. | 필요. read source policy 테스트 범위가 넓어 단순 rename인지 contract 재정의인지 먼저 분리해야 한다. | `fix/` 또는 별도 test stabilization | 높음 |
| `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | `duplicate candidates use representative spelling for non-strong matches` | 기대값 불일치 | 기대값은 후보 1건이지만 실제 반환은 `DuplicateCandidateDisplayItem` 3건이다. non-strong duplicate query의 현행 검색 범위 또는 테스트 fixture 기대값이 어긋난 상태다. | 직접 관련 없음 | 제한적으로 가능. 원인이 테스트 기대값 노후화인지 repository query regression인지 먼저 좁은 검증이 필요하다. | 필요. 데이터 의미와 duplicate policy 영향이 있어 stabilization phase에서 다루는 편이 안전하다. | 별도 test stabilization 또는 `fix/` | 높음 |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | `production import tree does not reference preview composition` | 기대값 불일치 / source-level guardrail 불일치 | 테스트는 production import tree가 `explorer_workspace/`를 참조하지 않아야 한다고 기대하지만, 현재 `lib/ui/word_explorer_screen.dart`는 `explorer_workspace_contract.dart`, `word_explorer_workspace_projection_adapter.dart`를 import한다. 확인된 현재 소스 기준으로 기존 guardrail과 read-only projection boundary 흐름이 충돌한다. | Phase 12-B/C 직접 관련 없음. 다만 ExplorerWorkspace 장기 boundary와 관련 있는 기존 guardrail debt다. | 가능. guardrail 문구와 금지 범위를 현행 projection boundary에 맞게 재정의해야 한다. | 필요. preview composition 금지와 read-only projection helper 허용 범위를 분리해야 한다. | 별도 test stabilization 또는 `docs/` + test fix | 중간 |
| `test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart` | `documents record preview-only layout orchestration boundary` | 문서 guardrail 문구 불일치 | 테스트가 `docs/ux/explorer_workspace_unification.md`에서 `layout coordination만 수행한다` 문구를 찾지만 현재 문서의 Phase 5-A 섹션에는 해당 정확 문구가 없다. | 직접 관련 없음 | 가능. 문서 문구를 복원할지, 테스트 문구를 현행 문서 표현에 맞출지 선택하면 된다. | 제한적으로 필요. 문서 active authority와 historical guardrail test의 문구 고정 정책을 정해야 한다. | `docs/` 또는 별도 test stabilization | 중간 |
| `test/ui/word_info_panel_test.dart` | loading 단계 | 컴파일 실패 / 오래된 API 참조 | 테스트가 제거되었거나 이동된 `buildWordRepresentativeSpelling` helper와 과거 `WordInfoPanel(wordMap:)` 생성자를 참조한다. 현재 production 사용처는 `WordInfoPanel(displayItem: ...)` contract를 사용한다. | 직접 관련 없음 | 가능. 테스트를 `WordDetailLikeDisplayItem` 기반 contract로 갱신할 수 있다. | 필요. raw Map carrier 제거/전환 boundary와 UI panel contract를 함께 확인해야 한다. | `fix/` 또는 별도 test stabilization | 높음 |
| `test/widget_test.dart` | loading 단계 | import/package 경로 오류 | 테스트가 `package:study/main.dart`와 `MyApp`을 참조하지만 `pubspec.yaml`의 package name은 `reshet_app`이고 앱 class는 `ReshetApp`이다. | 직접 관련 없음 | 가능. import와 root widget class를 현행 이름으로 갱신하는 작은 fix 후보다. | 불필요할 수 있음. 단, 기본 widget smoke test의 기대 UI는 별도 확인이 필요하다. | `fix/` | 높음 |

#### 17.68.4 실패 유형별 분류

| 실패 유형 | 해당 파일 | 분류 |
| --- | --- | --- |
| 컴파일 실패 / 오래된 API 참조 | `word_repository_read_source_policy_test.dart`, `word_info_panel_test.dart` | 기존 테스트가 삭제되었거나 변경된 public contract를 참조한다. |
| import/package 경로 오류 | `widget_test.dart` | package name과 root widget class가 현행 프로젝트와 맞지 않는다. |
| 기대값 불일치 | `word_repository_phase8h1_representative_query_contract_test.dart` | duplicate candidate query의 기대값과 실제 반환 결과가 다르다. |
| source-level guardrail 불일치 | `explorer_workspace_phase4e_composition_boundary_test.dart` | 과거 preview composition guardrail과 이후 read-only projection boundary 흐름이 충돌한다. |
| 문서 guardrail 문구 불일치 | `explorer_workspace_phase5a_layout_orchestration_test.dart` | 테스트가 특정 문구를 고정해 확인하지만 현재 문서 문구와 일치하지 않는다. |

#### 17.68.5 즉시 fix 가능 항목과 stabilization 분리

즉시 작은 fix 브랜치로 우선 검토할 수 있는 항목은 다음과 같다.

- `test/widget_test.dart`: `package:study`와 `MyApp` 참조를 현행 `reshet_app` / `ReshetApp` 기준으로 맞추는 작은 import/root widget fix 후보
- `test/ui/word_info_panel_test.dart`: `WordInfoPanel(displayItem: ...)` contract에 맞춘 테스트 갱신 후보
- `test/data/repositories/word_repository_read_source_policy_test.dart`: 삭제/변경된 Repository API 참조를 현행 read boundary contract로 재정렬하는 후보
- `test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart`: 문서 문구 복원 또는 테스트 기대 문구 갱신 후보

별도 test stabilization phase로 분리하는 편이 안전한 항목은 다음과 같다.

- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`: duplicate candidate 의미와 query policy를 확인해야 하므로 단순 기대값 변경으로 처리하지 않는다.
- `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`: preview composition 금지와 read-only projection helper 허용 범위를 다시 나눠야 하므로 ExplorerWorkspace guardrail 재정의가 필요하다.
- `test/data/repositories/word_repository_read_source_policy_test.dart`: API 참조 fix 자체는 작을 수 있으나 read source policy test 전체가 넓어 별도 stabilization에서 다루는 편이 안전할 수 있다.

#### 17.68.6 다음 단계 선택지

| 선택지 | 내용 | 조건 |
| --- | --- | --- |
| A | 작은 fix 브랜치로 즉시 정리 | package/import 오류와 오래된 API 참조 계열부터 좁게 정리한다. production code 변경 없이 테스트 현행화로 끝나는 범위를 우선 선택한다. |
| B | 별도 test stabilization phase로 분리 | duplicate query 의미, ExplorerWorkspace source-level guardrail, read source policy처럼 contract 재해석이 필요한 항목을 묶어 안정화한다. |
| C | baseline red 수용 정책 문서화 후 UX 확장 제한 | 당장 red를 고치지 않는 대신, 추가 production-visible UX 확장은 baseline red 수용 근거와 좁은 관련 테스트 통과 조건이 명확할 때만 허용한다. |

권장 판단은 다음과 같다.

```text
추가 production-visible UX 확장 전,
package/import 오류와 오래된 API 참조 계열을 우선 정리하는 것이 바람직하다.
다만 실제 수정은 Phase 12-D가 아니라 별도 fix 또는 test stabilization 단계에서 수행한다.
```

#### 17.68.7 Phase 12-E 또는 다음 Phase 진입 조건

Phase 12-E 또는 다음 Phase로 진입하려면 아래 조건을 먼저 충족해야 한다.

- 어떤 실패를 먼저 고칠지 선택되어야 한다.
- fix 범위가 문서, 테스트, 코드 중 어디인지 구분되어야 한다.
- production code 변경 여부가 사전에 승인되어야 한다.
- ExplorerWorkspace UX 변경과 테스트 안정화 작업이 섞이지 않아야 한다.
- 수정 후 실행할 좁은 테스트와 전체 `flutter test` 기준이 정의되어야 한다.
- package/import 오류와 오래된 API 참조 계열을 작은 fix 브랜치에서 처리할지, 별도 test stabilization phase로 분리할지 결정되어야 한다.
- duplicate query 의미 변경 가능성이 있는 항목은 데이터 의미와 repository contract 검증 기준이 먼저 정의되어야 한다.
- source-level guardrail 항목은 active authority, reference/context, migration/history 문서 성격을 구분한 뒤 수정되어야 한다.

#### 17.68.8 Phase 12-D 명령어 기반 확인 체크리스트

Phase 12-D의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-D 기록 확인 | Phase 12-D, baseline test red, `flutter test`, test debt, inventory 기록이 두 문서에 있어야 함 | Phase 12-D 항목 누락 또는 inventory 누락 | `rg -n "Phase 12-D|baseline test red|flutter test|test debt|inventory" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 추가 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.69 Phase 12-E widget_test package/import baseline fix

Phase 12-E의 목적은 Phase 12-D baseline red inventory 6건 중 가장 작고 명확한 `test/widget_test.dart`의 package/import 오류 1건을 정리하는 것이다.

이번 단계는 UX 변경 단계가 아니다. production code는 수정하지 않으며, `ExplorerWorkspace` UX 확장, `WordExplorerScreen` context strip 조정, route/shell/authority/API 변경도 수행하지 않는다. 추가 UX diff는 계속 보류한다.

#### 17.69.1 수정 범위

- `test/widget_test.dart`의 `package:study/main.dart` import를 현행 package name인 `package:reshet_app/main.dart`로 교체했다.
- 존재하지 않는 `MyApp` 참조를 제거하고 실제 app root인 `ReshetApp` 기준의 최소 smoke test로 바꿨다.
- 기본 counter app 템플릿 assertion은 제거했다.
- 테스트 목적은 `ReshetApp` root widget이 첫 frame에서 예외 없이 빌드되는지 확인하는 수준으로 제한했다.
- `lib/` production code, ExplorerWorkspace UX, route/shell/authority/API, DTO/model/public API는 변경하지 않았다.

#### 17.69.2 명령어 기반 확인 결과

- `flutter test test/widget_test.dart --reporter expanded`는 `+1` 통과로 확인했다.
- `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`는 `+4` 통과로 유지됨을 확인했다.
- 전체 `flutter test --reporter compact`는 기존 Phase 12-D inventory 기준 `+204 -6`에서 현재 `+206 -4`로 바뀌었다.
- `widget_test.dart` 실패는 제거되었다.
- 이번 branch에서 새 실패는 확인되지 않았다.

#### 17.69.3 남은 baseline red 처리

Phase 12-E는 Phase 12-D inventory 중 `widget_test.dart` 1건만 의도적으로 정리한다. 나머지 baseline red 항목은 별도 phase 또는 test stabilization 단계로 유지한다.

현재 전체 테스트에서 남은 red 항목은 다음과 같다.

- `test/data/repositories/word_repository_read_source_policy_test.dart`
- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`
- `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`
- `test/ui/word_info_panel_test.dart`

`test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart`는 Phase 12-E 개별 확인에서 통과했다. 이 항목은 이번 단계의 의도적 수정 대상이 아니므로, Phase 12-D inventory의 나머지 test stabilization 후보와 별도로 재분류가 필요하다.

### 17.70 Phase 12-F remaining baseline red review

Phase 12-F는 수정 작업이 아니라 docs/audit 단계다. 이번 단계의 목적은 Phase 12-E 이후 `main` 기준으로 남은 baseline red를 다시 확인하고, 실제 남은 실패 목록을 갱신한 뒤 다음 fix 후보를 선정하는 것이다.

이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않는다. `lib/`, `test/`, production route, `WordExplorerScreen` context strip, `ExplorerWorkspace` shell mount, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가는 수행하지 않는다. 추가 production-visible UX diff는 계속 보류한다.

#### 17.70.1 확인 기준과 실행 명령

확인 기준은 Phase 12-E 이후 `main` 최신 상태에서 생성한 `docs/explorer-workspace-phase12f-remaining-baseline-red-review` 브랜치다. 기준 HEAD는 `3580e52fcb6970a5eb2a0a7c887974d7b33b5874`이며, 최신 커밋 메시지는 `fix: widget_test package import baseline 정리`다.

실행한 주요 명령은 다음과 같다.

- `git checkout main`
- `git pull --ff-only`
- `git checkout -b docs/explorer-workspace-phase12f-remaining-baseline-red-review`
- `flutter test --reporter compact`
- `flutter test --reporter expanded`
- `flutter test test/data/repositories/word_repository_read_source_policy_test.dart --reporter expanded`
- `flutter test test/ui/word_info_panel_test.dart --reporter expanded`
- `flutter test test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart --reporter expanded`
- `rg -n "Phase 12-D|Phase 12-E|Phase 12-F|baseline red|flutter test|widget_test|word_info_panel|read_source|representative|composition_boundary|layout_orchestration" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md test lib`
- `git status --short --branch`

#### 17.70.2 전체 flutter test 결과

Phase 12-E 이후 main 기준 전체 flutter test 결과: +206 -4

`flutter test --reporter compact`와 `flutter test --reporter expanded` 모두 `+206 -4`로 종료되었다. `widget_test.dart` 실패는 제거된 상태로 유지되었고, 현재 확인된 새 실패는 없다.

#### 17.70.3 Phase 12-D inventory 대비 비교

| 구분 | 항목 | Phase 12-F 확인 결과 |
| --- | --- | --- |
| 제거됨 | `test/widget_test.dart` | Phase 12-E에서 `package:study` / `MyApp` 참조를 현행 `reshet_app` / `ReshetApp` 기준으로 정리했고, Phase 12-F 전체 실행에서도 더 이상 실패하지 않는다. |
| 개별 실행 통과 | `test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart` | `flutter test test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart --reporter expanded` 결과 `+8: All tests passed!`로 확인했다. |
| 남음 | `test/data/repositories/word_repository_read_source_policy_test.dart` | 전체 실행과 개별 실행 모두 loading 단계 컴파일 실패로 재현된다. |
| 남음 | `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | 개별 실행에서 `duplicate candidates use representative spelling for non-strong matches` 기대값 불일치가 재현된다. |
| 남음 | `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | 개별 실행에서 `production import tree does not reference preview composition` source-level guardrail 불일치가 재현된다. |
| 남음 | `test/ui/word_info_panel_test.dart` | 전체 실행과 개별 실행 모두 loading 단계 컴파일 실패로 재현된다. |

개별 실행에서는 통과하지만 전체 실행에서 실패하는 항목은 현재 확인되지 않았다. 반대로 `explorer_workspace_phase5a_layout_orchestration_test.dart`는 Phase 12-D inventory에 포함되었으나 Phase 12-F 개별 실행 기준으로 통과했다.

#### 17.70.4 남은 baseline red 재분류

| 실패 테스트 파일 | 실패 테스트명 또는 그룹명 | 실패 유형 | 원인 요약 | Phase 12-B/C/E 직접 관련 여부 | 즉시 fix 가능 여부 | 별도 stabilization 필요 여부 | 권장 브랜치 성격 | 우선순위 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `test/data/repositories/word_repository_read_source_policy_test.dart` | loading 단계 / `WordRepository split view single-word path`, `WordRepository detail-only phase2 path`, `ReadSourceDebugCollector wrapper output` 부근 | 오래된 API 참조 | 테스트가 `getWordMapByIdForSplitViewSingleWord`, `getWordDetailMapByIdForReadSourcePhase2Only`를 호출하지만 현재 `WordRepository` public surface에는 없다. 현행 후보 API는 `getWordDetailLikeDisplayItemByIdForSplitView`, `getWordMapByIdForExplorerSingleWord` 계열이므로 단순 rename인지 read source policy contract 재정의인지 분리가 필요하다. | Phase 12-B/C/E 직접 관련 없음 | 제한적으로 가능 | 필요. read source policy 범위가 넓어 별도 안정화가 안전하다. | `fix/` 또는 `test-stabilization` | 높음 |
| `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | `duplicate candidates use representative spelling for non-strong matches` | 기대값 불일치 | 기대값은 후보 1건이지만 실제 반환은 `DuplicateCandidateDisplayItem` 3건이다. duplicate candidate query의 현재 검색 범위와 fixture 기대값 중 어느 쪽을 조정해야 하는지 데이터 의미 검증이 필요하다. | Phase 12-B/C/E 직접 관련 없음 | 제한적으로 가능 | 필요. duplicate policy 의미를 확인해야 한다. | `test-stabilization` 또는 `fix/` | 높음 |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | `production import tree does not reference preview composition` | source-level guardrail 불일치 | 테스트는 production import tree가 `explorer_workspace/`를 참조하지 않아야 한다고 기대하지만 현재 `word_explorer_screen.dart`는 read-only projection boundary용 `explorer_workspace_contract.dart`, `word_explorer_workspace_projection_adapter.dart`를 import한다. preview composition 금지와 read-only projection helper 허용 범위를 다시 구분해야 한다. | Phase 12-B/C/E 직접 관련 없음. 다만 ExplorerWorkspace 장기 boundary와 관련된 기존 guardrail debt다. | 가능 | 필요. guardrail 재정의가 필요하다. | `docs/` + test fix 또는 `test-stabilization` | 중간 |
| `test/ui/word_info_panel_test.dart` | loading 단계 / `buildWordRepresentativeSpelling`, `WordInfoPanel` 그룹 | 오래된 API 참조 | 테스트가 제거되었거나 이동된 `buildWordRepresentativeSpelling` helper와 과거 `WordInfoPanel(wordMap:)` 생성자를 참조한다. 현재 `WordInfoPanel`은 `WordDetailLikeDisplayItem` 기반 `displayItem` contract를 사용한다. | Phase 12-B/C/E 직접 관련 없음 | 가능 | 제한적으로 필요. raw Map carrier 전환 boundary를 확인해야 하지만 파일 범위가 작다. | `fix/` | 높음 |

#### 17.70.5 다음 fix 후보 1순위

다음 fix 후보 1순위는 `test/ui/word_info_panel_test.dart`다.

선정 이유는 다음과 같다.

- 실패가 loading 단계의 컴파일 실패로 명확하다.
- 원인이 오래된 `WordInfoPanel(wordMap:)` 생성자와 `buildWordRepresentativeSpelling` helper 참조로 좁혀져 있다.
- production-visible ExplorerWorkspace UX 변경과 섞이지 않는다.
- `WordDetailLikeDisplayItem` 기반 현행 contract에 맞춘 테스트 현행화 후보로 보이며, 좁은 파일 단독 실행으로 개선 여부를 확인할 수 있다.
- `word_repository_read_source_policy_test.dart`보다 read source policy 영향 범위가 작고, `phase8h1` duplicate query 의미 검증보다 데이터 정책 부담이 낮다.
- `phase4e` guardrail 재정의보다 ExplorerWorkspace 장기 boundary 판단 부담이 낮다.

다만 Phase 12-F는 다음 fix 후보를 선정하지만, Phase 12-G가 반드시 fix 단계로 확정된 것은 아니다.
현재 개발 속도와 구조 부담을 고려하여, 다음 단계는 `word_info_panel_test` fix 또는 incremental migration vs rebuild feasibility audit 중 하나로 별도 판단한다.

#### 17.70.6 Phase 12-G 진입 조건

Phase 12-G 또는 다음 단계로 진입하려면 아래 조건을 먼저 충족해야 한다.

- `test/ui/word_info_panel_test.dart`를 실제 fix 대상으로 선택할지, incremental migration vs rebuild feasibility audit로 전환할지 결정되어야 한다.
- fix를 선택하는 경우 production code 변경 여부와 테스트 현행화 범위를 사전에 구분해야 한다.
- rebuild feasibility audit로 전환하는 경우 기존 incremental migration 흐름과 재구축 가능성 비교 기준을 먼저 문서화해야 한다.
- ExplorerWorkspace UX 변경과 baseline red 정리 또는 audit 작업이 섞이지 않아야 한다.
- 추가 production-visible UX diff는 baseline red 정리 또는 별도 수용 정책이 더 명확해질 때까지 계속 보류한다.

#### 17.70.7 Phase 12-F 명령어 기반 확인 체크리스트

Phase 12-F의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-F 기록 확인 | Phase 12-F, remaining baseline red, `flutter test`, Phase 12-G, next fix, rebuild feasibility 기록이 두 문서에 있어야 함 | Phase 12-F 항목 누락 또는 다음 단계 판단 문구 누락 | `rg -n "Phase 12-F|remaining baseline red|flutter test|Phase 12-G|next fix|rebuild feasibility" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 추가 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.71 Phase 12-G word_info_panel_test baseline fix

Phase 12-G의 목적은 Phase 12-F remaining baseline red 중 다음 fix 후보 1순위로 선정한 `test/ui/word_info_panel_test.dart`를 현행 `WordInfoPanel` API와 구조에 맞춰 최소 수정하는 것이다. 이번 단계는 test baseline fix이며 UX 변경, ExplorerWorkspace 확장, production-visible UX diff가 아니다.

#### 17.71.1 범위와 전략 판단

이번 단계에서는 새로 개발과 병렬 개발을 계속 보류하고, 기존 방식의 점진 전환과 baseline 안정화를 유지한다. 추가 production-visible UX diff도 계속 보류한다.

변경 범위는 아래 파일로 제한한다.

- `test/ui/word_info_panel_test.dart`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`

`lib/` production code, `WordInfoPanel` production 구현, ExplorerWorkspace UX, `WordExplorerScreen`, context strip, route/shell/authority/API는 변경하지 않는다.

#### 17.71.2 테스트 현행화 내용

`test/ui/word_info_panel_test.dart`는 과거 `WordInfoPanel(wordMap:)` 생성자와 제거된 `buildWordRepresentativeSpelling` helper를 참조하고 있었다. 현행 production contract는 `WordDetailLikeDisplayItem` 기반 `WordInfoPanel(displayItem: ...)`이므로, 테스트 fixture를 `WordDetailLikeDisplayItem`로 구성하고 `displayItem:` 기반 호출로 전환한다.

제거된 helper 참조 테스트는 현행 `WordInfoPanel` 테스트 범위에서 제외한다. 이는 assertion 삭제만으로 통과시키는 조치가 아니라, 더 이상 production API에 존재하지 않는 helper/API 참조를 panel widget baseline 테스트에서 분리하는 것이다.

#### 17.71.3 Phase 12-F remaining red 반영

Phase 12-G에서 `word_info_panel_test.dart` 1건을 정리 대상으로 삼는다. 남은 baseline red는 아래 항목으로 별도 phase 또는 test stabilization 단계에서 유지한다.

- `word_repository_read_source_policy_test.dart`
- `word_repository_phase8h1_representative_query_contract_test.dart`
- `explorer_workspace_phase4e_composition_boundary_test.dart`

#### 17.71.4 Phase 12-G 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| `word_info_panel_test.dart` 단독 확인 | 현행 `WordInfoPanel(displayItem:)` 기준으로 컴파일되고 통과해야 함 | loading timeout, compile error, pump hang | `flutter test test/ui/word_info_panel_test.dart --reporter expanded` | 작업 종료 보고에서 기록 |
| 기존 root widget smoke 유지 | `widget_test.dart`가 통과해야 함 | Phase 12-E 정리 회귀 | `flutter test test/widget_test.dart --reporter expanded` | 작업 종료 보고에서 기록 |
| Phase 12-B context strip 좁은 테스트 유지 | 기존 context strip 테스트가 통과해야 함 | ExplorerWorkspace UX 주변 회귀 | `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart` | 작업 종료 보고에서 기록 |
| 전체 baseline 변화 확인 | 기존 `+206 -4` 대비 `word_info_panel_test.dart` 실패 제거 여부를 비교해야 함 | 새 branch-only 실패 또는 remaining red 불일치 | `flutter test --reporter compact` | 작업 종료 보고에서 기록 |
| 변경 파일 확인 | 승인된 3개 파일만 변경되어야 함 | 승인 범위 밖 파일 변경 | `git diff --name-only` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 잘못된 브랜치 또는 불필요한 변경 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.72 Phase 12-H remaining baseline red triage

Phase 12-H는 fix 단계가 아니라 docs/audit 단계다. 목적은 Phase 12-G 이후 남은 baseline red 3건을 실제 명령 결과 기준으로 다시 확인하고, 수정 난이도, 위험도, 정책 영향도, production code 영향 가능성을 비교하여 다음 fix 대상 1건만 선정하는 것이다.

이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않는다. `lib/`, `test/`, production route, `WordExplorerScreen` context strip, `ExplorerWorkspace` shell mount, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가는 수행하지 않는다. 추가 production-visible UX diff는 계속 보류한다.

새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화 전략을 유지한다. Phase 12-H는 남은 baseline red를 모두 고치는 단계가 아니며, 다음 Phase에서 가장 작고 정책 영향이 낮은 항목 1건만 fix 대상으로 선택하기 위한 triage 단계다.

#### 17.72.1 확인 기준과 실행 명령

확인 기준은 Phase 12-G 이후 main 최신 상태에서 생성한 `docs/explorer-workspace-phase12h-remaining-baseline-red-triage` 브랜치다. 기준 main HEAD는 `cdba5e894845ab78a6545d008c288df63fa2399e`이며, 최신 커밋 메시지는 `fix: word_info_panel_test baseline 현행화`다.

실행한 주요 명령은 다음과 같다.

- `git checkout main`
- `git pull --ff-only`
- `git checkout -b docs/explorer-workspace-phase12h-remaining-baseline-red-triage`
- `flutter test --reporter compact`
- `flutter test test/data/repositories/word_repository_read_source_policy_test.dart --reporter expanded`
- `flutter test test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded`
- `rg -n "read_source|readSource|source policy|source_policy|WordRepository|representative|duplicate candidate|composition boundary|ExplorerWorkspace|projection|import" test lib docs`
- `rg -n "word_repository_read_source_policy|word_repository_phase8h1|phase4e_composition" test docs`
- `git status --short --branch`

#### 17.72.2 전체 flutter test 결과

Phase 12-G 이후 main 기준 전체 flutter test 결과: +209 -3

`flutter test --reporter compact`는 남은 baseline red 3건을 포함해 `+209 -3`으로 종료되었다. Phase 12-G에서 `word_info_panel_test.dart` 실패가 제거된 상태로 유지되었고, 이번 단계에서 확인된 새 branch-only 실패는 없다.

#### 17.72.3 남은 baseline red 3건 재확인 결과

| 항목 | 개별 실행 결과 | 확인 내용 |
| --- | --- | --- |
| `test/data/repositories/word_repository_read_source_policy_test.dart` | loading 단계 컴파일 실패 | 테스트가 현재 `WordRepository` public surface에 없는 `getWordMapByIdForSplitViewSingleWord`, `getWordDetailMapByIdForReadSourcePhase2Only`를 호출한다. |
| `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | `duplicate candidates use representative spelling for non-strong matches` 실패 | `DuplicateCandidateDisplayItem` 기대값은 1건이지만 실제 반환은 3건이다. |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | `production import tree does not reference preview composition` 실패 | 테스트는 production import tree가 `explorer_workspace/`를 참조하지 않아야 한다고 기대하지만, 현재 `word_explorer_screen.dart`는 read-only projection boundary용 ExplorerWorkspace contract와 adapter를 import한다. |

#### 17.72.4 남은 baseline red 재분류

| 실패 테스트 파일 | 실패 테스트명 또는 그룹명 | 실패 유형 | 원인 요약 | Phase 12-B/G 직접 관련 여부 | production code 변경 필요 가능성 | test-only 수정 가능성 | docs-only 수정 가능성 | 정책 판단 필요 여부 | 수정 난이도 | 위험도 | 권장 브랜치 성격 | 우선순위 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `test/data/repositories/word_repository_read_source_policy_test.dart` | loading 단계 / `WordRepository split view single-word path`, `WordRepository detail-only phase2 path`, `ReadSourceDebugCollector wrapper output` 부근 | 오래된 Repository API 참조 | 테스트가 삭제되었거나 변경된 `WordRepository` API를 호출한다. 현재 대응 가능한 typed API 후보는 `getWordDetailLikeDisplayItemByIdForSplitView`, `getWordMapByIdForExplorerSingleWord`, detail screen display item read 계열이다. | 직접 관련 없음 | 낮음. 현행 API가 이미 있어 production 구현 변경 없이 테스트 현행화 가능성이 가장 높다. | 높음. 테스트를 현행 Repository API에 맞추는 방향이 우선이다. | 낮음. 문서만으로 red를 제거할 수 없다. | 낮음. API 대응 범위를 확인하되 정책 재정의 부담은 가장 작다. | 낮음 | 낮음 | `fix/` | 1순위 |
| `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | `duplicate candidates use representative spelling for non-strong matches` | 기대값 불일치 | 기대 1건 대비 실제 `DuplicateCandidateDisplayItem` 3건이 반환된다. seed DB / 정규화 / 대표 후보 정책 중 어느 쪽이 현행 기준인지 판단이 필요하다. | 직접 관련 없음 | 중간. query 정책을 바꾸면 production duplicate candidate 동작에 영향이 생긴다. | 중간. fixture 기대값이 낡은 것인지 실제 query regression인지 먼저 분리해야 한다. | 낮음. 문서만으로 red를 제거할 수 없다. | 높음. duplicate candidate 의미와 representative normalization 정책 판단이 필요하다. | 중간 | 높음 | `test-stabilization` 또는 `fix/` | 후순위 |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | `production import tree does not reference preview composition` | source-level guardrail 불일치 | production import tree의 `explorer_workspace/` 참조 금지 guardrail이 현재 read-only projection boundary 흐름과 충돌한다. ExplorerWorkspace preview composition 금지와 read-only projection helper 허용 범위를 다시 구분해야 한다. | 직접 관련 없음. 다만 ExplorerWorkspace 장기 boundary와 연결된 기존 guardrail debt다. | 중간. production import를 되돌리는 방식은 Phase 7 이후 projection boundary를 건드릴 수 있다. | 중간. 단순 테스트 수정으로 처리하지 말고 경계 정책 재정의가 먼저 필요하다. | 중간. guardrail 문서 정리는 가능하지만 red 제거에는 테스트 수정도 필요하다. | 높음. ExplorerWorkspace 경계 정책 재정의가 필요하다. | 중간 | 중간 | `docs/` + test fix 또는 `test-stabilization` | 후순위 |

#### 17.72.5 다음 fix 후보 1순위

다음 fix 후보 1순위는 `test/data/repositories/word_repository_read_source_policy_test.dart`다.

선정 이유는 다음과 같다.

- 컴파일 실패라 원인이 가장 명확하고, 현행 `WordRepository`에 대응 가능한 typed API가 이미 있어 production code 변경 없이 테스트 현행화 가능성이 가장 높기 때문이다.
- `word_repository_phase8h1_representative_query_contract_test.dart`는 seed DB / 정규화 / 대표 후보 정책 판단이 필요하므로 바로 fix보다 stabilization 또는 정책 검토가 먼저 필요하다.
- `explorer_workspace_phase4e_composition_boundary_test.dart`는 ExplorerWorkspace 경계 정책 재정의가 필요하므로 단순 테스트 수정으로 처리하지 않는다.
- ExplorerWorkspace UX 변경, `WordExplorerScreen` context strip 변경, route/shell/authority/API 변경과 섞이지 않는다.
- 개별 테스트와 전체 `flutter test` 결과를 비교해 개선 여부를 확인할 수 있다.

#### 17.72.6 Phase 12-I 진입 조건

Phase 12-I로 진입하려면 아래 조건을 충족해야 한다.

- Phase 12-I는 `test/data/repositories/word_repository_read_source_policy_test.dart` 단일 fix로 제한한다.
- production `WordRepository` 구현 변경은 원칙적으로 금지한다.
- 수정 방향은 테스트를 현행 Repository API에 맞추는 것으로 제한한다.
- `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`는 함께 수정하지 않는다.
- 개별 실행으로 `word_repository_read_source_policy_test.dart`의 컴파일 실패 제거 여부를 확인한다.
- 전체 `flutter test --reporter compact` 결과가 `+209 -3`에서 어떻게 변하는지 비교한다.
- 새 branch-only 실패가 없어야 한다.
- 추가 production-visible UX diff는 계속 보류한다.
- 새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화를 계속한다.

#### 17.72.7 Phase 12-H 명령어 기반 확인 체크리스트

Phase 12-H의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-H 기록 확인 | Phase 12-H, remaining baseline red, triage, Phase 12-I, next fix, `flutter test`, `read_source_policy` 기록이 두 문서에 있어야 함 | Phase 12-H 목적, 다음 fix 후보, Phase 12-I 조건 누락 | `rg -n "Phase 12-H|remaining baseline red|triage|Phase 12-I|next fix|flutter test|read_source_policy" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 추가 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.73 Phase 12-I read source policy test baseline fix

Phase 12-I의 목적은 Phase 12-H remaining red 중 1순위로 선정한 `test/data/repositories/word_repository_read_source_policy_test.dart` 1건을 현행 `WordRepository` API에 맞춰 정리하는 것이다. 이번 단계는 test baseline fix이며 UX 변경, ExplorerWorkspace 확장, production-visible UX diff가 아니다.

새로 개발과 병렬 개발은 계속 보류하고 기존 방식의 점진 안정화 전략을 유지한다. 추가 UX diff도 계속 보류한다.

#### 17.73.1 범위와 전략 판단

변경 범위는 아래 3개 파일로 제한한다.

- `test/data/repositories/word_repository_read_source_policy_test.dart`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`

production `lib/` 코드는 수정하지 않는다. `WordRepository` production 구현, ExplorerWorkspace UX, `WordExplorerScreen`, context strip, route/shell/authority/API도 변경하지 않는다. DTO/model/public API를 새로 추가하지 않는다.

Phase 12-I에서는 `word_repository_phase8h1_representative_query_contract_test.dart`, `explorer_workspace_phase4e_composition_boundary_test.dart`를 함께 수정하지 않는다. 두 항목은 별도 phase 또는 stabilization 단계로 유지한다.

#### 17.73.2 테스트 현행화 내용

`word_repository_read_source_policy_test.dart`의 loading 실패 원인은 현재 `WordRepository` public surface에 없는 오래된 API 호출이었다.

현행화한 API 대응은 다음과 같다.

| 오래된 테스트 API | 현행 Repository API | 비고 |
| --- | --- | --- |
| `getWordMapByIdForSplitViewSingleWord` | `getWordDetailLikeDisplayItemByIdForSplitView` | split view detail-like display typed contract 기준으로 교체 |
| `getWordDetailMapByIdForReadSourcePhase2Only` | `getWordDetailLikeDisplayItemByIdForDetailScreen` | detail screen display item typed contract 기준으로 교체 |
| raw `Map<String, dynamic>` detail display 비교 | `WordDetailLikeDisplayItem` 비교 지원 helper | 테스트 파일 내부 `_expectSameDetailDisplay(...)`만 조정 |

현행 `WordRepository`에서 `getWordMapById`와 `getWordMapByIdForExplorerSingleWord`는 `_phase8ARawSingleWordContexts`에 포함되어 `ReadSourcePolicy.normalizedWithFallback` 경로를 사용한다. 따라서 관련 assertion은 production code의 실제 policy 경로에 맞춰 최소 조정했다. 전역 기본값 `debugCurrentReadSourcePolicy == ReadSourcePolicy.legacy` 자체는 유지된다.

#### 17.73.3 명령어 기반 확인 결과

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| read source policy 단일 테스트 | 오래된 API loading 실패가 제거되고 전체 테스트가 통과해야 함 | 컴파일 실패, policy assertion 불일치, typed display 비교 실패 | `flutter test test/data/repositories/word_repository_read_source_policy_test.dart --reporter expanded` | `+17: All tests passed!` |
| root widget smoke 유지 | Phase 12-E 이후 root smoke가 계속 통과해야 함 | package/import 회귀 또는 root build 실패 | `flutter test test/widget_test.dart --reporter expanded` | `+1: All tests passed!` |
| WordInfoPanel baseline 유지 | Phase 12-G에서 정리한 panel 테스트가 계속 통과해야 함 | typed display item contract 회귀 | `flutter test test/ui/word_info_panel_test.dart --reporter expanded` | `+3: All tests passed!` |
| Phase 12-B context strip 좁은 테스트 유지 | ExplorerWorkspace UX/context strip 변경 없이 기존 guardrail이 통과해야 함 | context strip, route/shell/authority/API 관련 회귀 | `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart` | `+4: All tests passed!` |
| 전체 baseline 변화 확인 | 기존 `+209 -3`에서 read source policy 실패가 제거되어야 하며 새 branch-only 실패가 없어야 함 | 남은 실패가 Phase 12-H inventory와 불일치하거나 새 실패 발생 | `flutter test --reporter compact` | `+226 -2`로 종료. `word_repository_read_source_policy_test.dart` 실패는 제거되었고 새 실패는 없다. |

전체 `flutter test`의 남은 실패 2건은 Phase 12-H inventory의 나머지 항목과 일치한다.

- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`: `duplicate candidates use representative spelling for non-strong matches`에서 기대 1건 대비 실제 3건 반환
- `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`: `production import tree does not reference preview composition`에서 `explorer_workspace/` import guardrail 불일치

Phase 12-H remaining red 중 `word_repository_read_source_policy_test.dart` 1건은 정리되었다. 남은 baseline red 2건은 별도 phase로 유지한다.

### 17.74 Phase 12-J final red decision audit

Phase 12-J의 목적은 Phase 12-I 이후 남은 baseline red 2건을 고치는 것이 아니라, 각 실패가 단순 테스트 현행화인지, 정책 재정의 대상인지, 데이터/seed DB 기대값 재검토 대상인지, ExplorerWorkspace guardrail 재정의 대상인지 판단하고 다음 phase 방향을 결정하는 것이다.

이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않는다. `lib/`, `test/`, production route, `WordExplorerScreen` context strip, `ExplorerWorkspace` shell mount, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가는 수행하지 않는다. 추가 production-visible UX diff는 계속 보류한다.

새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화 전략을 유지한다.

#### 17.74.1 확인 기준과 실행 명령

확인 기준은 Phase 12-I 종료 후 main 최신 상태에서 생성한 `docs/explorer-workspace-phase12j-final-red-decision-audit` 브랜치다. 기준 main HEAD는 `86545f1742a31b7195826f1e29101ae5afc3db12`이며, 최신 커밋 메시지는 `fix: read source policy test baseline 현행화`다.

실행한 주요 명령은 다음과 같다.

- `git checkout main`
- `git pull --ff-only`
- `git checkout -b docs/explorer-workspace-phase12j-final-red-decision-audit`
- `flutter test --reporter compact`
- `flutter test test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded`
- `rg -n "DuplicateCandidateDisplayItem|representative|duplicate candidate|כפר|candidate|Phase 8-H|Phase 8H|representative query" test lib docs`
- `rg -n "composition boundary|Phase 4-E|production import|explorer_workspace/|ExplorerWorkspace|guardrail|projection" test lib docs`
- seed DB 확인용 읽기 전용 SQLite 조회
- `git status --short --branch`

#### 17.74.2 전체 flutter test 결과

Phase 12-I 이후 main 기준 전체 `flutter test --reporter compact` 결과는 `+226 -2`로 종료되었다.

남은 실패 2건은 Phase 12-I 종료 기록과 일치하며, 이번 Phase 12-J 브랜치에서 새 branch-only 실패는 확인되지 않았다.

#### 17.74.3 남은 baseline red 2건 개별 실행 결과

| 실패 테스트 파일 | 실패 테스트명 또는 그룹명 | 실제 실패 결과 |
| --- | --- | --- |
| `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | `Phase 8-H-1 representative query contract first slice duplicate candidates use representative spelling for non-strong matches` | 기대값은 후보 1건이지만 실제 `DuplicateCandidateDisplayItem` 3건이 반환되어 `Expected: an object with length of <1>`, `Actual: ... length of <3>`로 실패했다. 파일 전체는 `+5 -1`로 종료되었다. |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | `Phase 4-E ExplorerWorkspace preview-only composition boundary production import tree does not reference preview composition` | 테스트는 production import tree가 `explorer_workspace/`를 포함하지 않아야 한다고 기대하지만, 현재 `lib/ui/word_explorer_screen.dart`가 `explorer_workspace/explorer_workspace_contract.dart`, `explorer_workspace/word_explorer_workspace_projection_adapter.dart`를 import해 source-level guardrail 불일치로 실패했다. 파일 전체는 `+5 -1`로 종료되었다. |

#### 17.74.4 실패 성격 판단

| 실패 테스트 파일 | 실패 유형 | Phase 12-B~I 직접 관련 여부 | test-only 수정 가능성 | docs-only 수정 가능성 | production code 변경 필요 가능성 | 정책 판단 필요 여부 | Phase 12 안 해결 여부 | 별도 phase 이월 여부 | 위험도 | 권장 다음 조치 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart` | 기대값 불일치 / 데이터·seed DB 기대값 불일치 | 직접 관련 없음 | 높음 | 낮음. 문서만으로 red는 제거되지 않음 | 낮음. production query 변경은 duplicate 후보 정책 변경이 될 수 있어 우선하지 않음 | 낮음~중간. 현행 정책은 non-strong 대표 표기 비교이며 seed fixture 기대값 현행화 성격이 강함 | 가능. Phase 12-K 후보로 적합 | 이월 가능하지만 남은 red 축소 관점에서는 Phase 12-K가 더 작음 | 중간 | Phase 12-K에서 representative query expectation test 현행화를 진행한다. |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | source-level guardrail 불일치 / ExplorerWorkspace guardrail 정책 불일치 | 직접 관련 없음. 다만 Phase 7~12 projection/helper 흐름과 연결됨 | 중간. 단순 금지어 삭제가 아니라 guardrail 범위 재정의가 필요함 | 중간. 문서 정리는 가능하지만 red 제거에는 테스트 수정이 필요함 | 중간. production import를 되돌리면 Phase 7-D/F read-only projection chain과 Phase 8/10 guardrail 흐름을 건드릴 수 있음 | 높음. preview composition 금지와 read-only projection helper 허용 범위를 분리해야 함 | Phase 12에서 반드시 고치기보다 전환 정책으로 분리하는 편이 안전함 | Phase 13 또는 별도 ExplorerWorkspace guardrail 재정의 phase로 이월 권장 | 중간 | Phase 13 전환 정책에서 composition boundary guardrail 재정의를 진행한다. |

#### 17.74.5 representative query 실패 판단

`word_repository_phase8h1_representative_query_contract_test.dart`의 실패 케이스는 테스트 내부에서 히브리어 단어 `T9000_H1_DUPLICATE_NON_STRONG`을 추가하고 `spelling1: 'כפר'`로 non-strong duplicate 후보를 조회한다. 기대값은 테스트가 삽입한 1건만 반환되는 것이다.

실제 seed DB 기준으로는 테스트 삽입 전부터 `representative_spelling`에서 히브리어 모음을 제거한 값이 `כפר`인 히브리어 row가 2건 존재한다.

| seed word id | language | strong number | representative spelling | primary meaning |
| --- | --- | --- | --- | --- |
| `H3722_0000` | 히브리어 | `H3722` | `כָּפַר` | 덮다 |
| `H3723_0000` | 히브리어 | `H3723` | `כָּפָר` | 마을/촌락 |

따라서 실제 반환 3건은 seed DB 2건과 테스트가 삽입한 1건을 합친 결과로 설명된다. 현행 `findDuplicateCandidates`의 non-strong 경로는 같은 언어 row 전체를 representative projection으로 읽고, `_normalizeSpellingForDuplicateCheck`로 히브리어 표시 부호를 제거한 뒤 동일 spelling 후보를 `.take(20)`까지 반환한다. 이 동작은 Phase 8-H 기록의 "strong 우선 / normalized strong / non-strong representative spelling 비교 규칙"과 충돌한다고 확인되지 않는다.

현재 판단은 데이터 정책 변경이 아니라 테스트 fixture/expectation 현행화 대상이다. 테스트가 실제 seed DB에 존재하는 자연 후보를 포함하도록 기대값을 갱신하거나, 테스트 목적이 "삽입한 단일 row projection 확인"이면 seed DB와 충돌하지 않는 fixture spelling으로 바꾸는 방향이 가능하다. 어느 쪽이든 production code 변경 없이 진행 가능한 test-only 안정화 후보로 본다.

#### 17.74.6 composition boundary 실패 판단

`explorer_workspace_phase4e_composition_boundary_test.dart`의 과거 guardrail은 Phase 4-E 당시 preview-only composition이 production import tree로 유입되지 않도록 `explorer_workspace/` 참조 자체를 금지했다. 이 guardrail은 `ExplorerWorkspacePreviewScreen`, preview interaction host, preview input, repository/Navigator ownership, dummy id/display item 합성을 막는 목적이었다.

현재 production import tree에서 `explorer_workspace/` 참조가 발생하는 이유는 preview composition mount가 아니라 `WordExplorerScreen`의 read-only projection chain 때문이다. 현재 `WordExplorerScreen`은 `explorer_workspace_contract.dart`와 `word_explorer_workspace_projection_adapter.dart`를 import해 `_readOnlyWorkspaceProjection`을 만들고, assert-only hidden visual probe와 candidate representation reader guardrail에서 projection을 읽는다.

Phase 7-D/F 이후 `WordExplorerWorkspaceProjectionAdapter`와 `_readOnlyWorkspaceProjection`은 production owner 값을 `ExplorerWorkspaceState`로 투영하는 read-only boundary로 기록되었다. Phase 8-C/G는 이 projection을 assert-only hidden probe와 helper-local candidate marker로 제한했고, Phase 10-D는 candidate representation reader가 source-level, read-only, unmounted, non-route, non-owner, non-persistent boundary에 머무르는지 검증했다. Phase 12-B context strip guardrail도 visible UI input으로 projection을 쓰지 않는다는 경계를 확인한다.

따라서 현재 실패는 실제 `ExplorerWorkspace` shell mount, production route 변경, preview composition mount, repository/Navigator/persistence authority migration을 직접 가리키는 실패라기보다, Phase 4-E의 광범위한 `explorer_workspace/` 금지 문구가 Phase 7 이후 read-only projection helper 허용 범위를 반영하지 못하는 guardrail 노후화로 판단한다.

다만 이 항목은 단순 테스트 현행화로 처리하기에 정책 영향이 크다. 다음 단계에서는 preview composition 금지, `ExplorerWorkspace` shell mount 금지, read-only contract/adapter import 허용, visible UI input 금지, route/shell/owner/persistence migration 금지를 각각 분리한 새 guardrail로 재정의해야 한다. 이는 Phase 13 전환 정책 또는 별도 ExplorerWorkspace guardrail 재정의 phase로 넘기는 편이 안전하다.

#### 17.74.7 결론과 다음 phase 후보

Phase 12-J 결론은 선택지 D다.

```text
하나는 Phase 12-K에서 처리하고, 다른 하나는 Phase 13 전환 정책으로 이월한다.
```

Phase 12-K 후보는 `word_repository_phase8h1_representative_query_contract_test.dart`의 representative query expectation test 현행화다. 이 항목은 실제 seed DB 확인 결과를 기준으로 실패 원인이 설명되며, production code 변경 없이 test-only로 정리할 수 있는 가능성이 가장 높다.

`explorer_workspace_phase4e_composition_boundary_test.dart`는 Phase 12-K에서 함께 처리하지 않는다. 이 항목은 Phase 4-E preview-only composition guardrail과 Phase 7~12 read-only projection/helper guardrail 사이의 정책 재정의가 필요하므로, Phase 13 전환 정책 또는 별도 guardrail 재정의 단계로 이월한다.

Phase 12 종료 audit로 갈 수 있는 조건은 다음과 같다.

- Phase 12-K에서 representative query expectation test 현행화를 진행하고 전체 `flutter test` 결과 변화를 확인한다.
- 남은 실패가 `explorer_workspace_phase4e_composition_boundary_test.dart` 1건으로 축소되는지 확인한다.
- Phase 12 종료 audit에서 composition boundary guardrail을 Phase 13 전환 정책으로 이월한다는 판단을 명시한다.
- 추가 UX diff, 새로 개발, 병렬 개발, production route/shell/authority/API 변경이 계속 보류되어야 한다.

Phase 12 종료 audit에서 zero-red를 필수 조건으로 삼는다면 composition boundary guardrail 재정의까지 Phase 12 안에서 처리해야 한다. 그러나 현재 점진 안정화 전략 기준의 권장안은 Phase 12-K에서 데이터/fixture 기대값 현행화를 먼저 처리하고, ExplorerWorkspace guardrail 정책 재정의는 Phase 13로 분리하는 것이다.

#### 17.74.8 Phase 12-J 명령어 기반 확인 체크리스트

Phase 12-J의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-J 기록 확인 | Phase 12-J, final red decision, remaining baseline red, Phase 12-K, representative, composition boundary, `flutter test` 기록이 두 문서에 있어야 함 | Phase 12-J 목적, 실패 판단, 다음 phase 후보 누락 | `rg -n "Phase 12-J|final red decision|remaining baseline red|Phase 12-K|representative|composition boundary|flutter test" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.75 Phase 12-K representative query expectation baseline 현행화

Phase 12-K의 목적은 Phase 12-J에서 test-only fix 후보로 선정한 `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`의 representative query expectation을 현행 seed DB와 production duplicate candidate 정책에 맞춰 정리하는 것이다. 이번 단계는 baseline test red 정리이며 production 정책 변경, seed DB 변경, ExplorerWorkspace UX 변경이 아니다.

대상 테스트의 기존 기대값은 non-strong duplicate 후보 조회에서 테스트가 삽입한 `T9000_H1_DUPLICATE_NON_STRONG` 1건만 반환되는 것이었다. 그러나 seed DB에는 테스트 삽입 전부터 히브리어 대표 표기 정규화 기준 `כפר` 후보가 `H3722_0000`, `H3723_0000` 2건 존재한다.

| candidate id | language | strong number | representative spelling | normalized spelling | primary meaning |
| --- | --- | --- | --- | --- | --- |
| `H3722_0000` | 히브리어 | `H3722` | `כָּפַר` | `כפר` | 덮다 |
| `H3723_0000` | 히브리어 | `H3723` | `כָּפָר` | `כפר` | 마을/촌락 |
| `T9000_H1_DUPLICATE_NON_STRONG` | 히브리어 | 없음 | `כְּפַר` | `כפר` | non strong meaning |

현행 `findDuplicateCandidates`의 non-strong 경로는 같은 언어 row를 representative projection으로 읽고 히브리어 표시 부호를 제거한 representative spelling 기준으로 후보를 비교한다. 따라서 실제 반환 3건은 seed DB 기존 후보 2건과 테스트 삽입 1건이 함께 반환되는 자연스러운 결과다.

Phase 12-K에서는 이 동작을 production code 변경 없이 테스트 expectation으로 명시한다. 테스트는 단순 count 제거가 아니라 3건의 식별 가능한 값인 candidate id, language, strong number, representative spelling, primary meaning을 검증한다.

이번 단계에서는 `lib/` production code, `WordRepository` production 구현, seed DB, fixture DB, ExplorerWorkspace UX, `WordExplorerScreen`, context strip, route/shell/owner/controller/coordinator, Provider/Repository/Navigator/persistence authority, DTO/model/public API를 변경하지 않는다. 추가 production-visible UX diff는 계속 보류한다.

Phase 12-J remaining red 중 representative query 1건을 정리 대상으로 삼고, 남은 baseline red는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건으로 유지한다. 이 항목은 Phase 13 전환 정책 또는 별도 ExplorerWorkspace guardrail 재정의 단계로 이월한다.

새로 개발과 병렬 개발은 보류하고 기존 방식의 점진 안정화 전략을 계속한다.

명령어 기반 확인 결과, `word_repository_phase8h1_representative_query_contract_test.dart`는 `+6: All tests passed!`로 통과했다. 전체 `flutter test --reporter compact` 결과는 Phase 12-J 기준 `+226 -2`에서 `+227 -1`로 변했다. representative query 실패는 제거되었고 새 branch-only 실패는 확인되지 않았다. 남은 baseline red는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건이며 실패 내용은 기존 Phase 12-J inventory와 동일한 `explorer_workspace/` import guardrail 불일치다.

### 17.76 Phase 12-L termination and boundary carryover audit

Phase 12-L은 수정 단계가 아니라 `termination and boundary carryover audit` 단계다. 목적은 Phase 12 전체 종료 가능성을 검토하고, 마지막 남은 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` red를 Phase 12 안에서 직접 해결할지, Phase 13 전환 정책 또는 별도 guardrail 재정의 phase로 이월할지 판단하는 것이다.

이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않는다. `lib/`, `test/`, production route, `WordExplorerScreen` context strip, `ExplorerWorkspace` shell mount, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가는 수행하지 않는다.

#### 17.76.1 Phase 12 전체 성과

Phase 12는 첫 production-visible UX diff를 제한적으로 도입하고 baseline red를 대폭 축소했다.

- `WordExplorerScreen` detail pane 상단에 read-only context strip을 추가했다.
- 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지했다.
- `ExplorerWorkspace` shell mount는 하지 않았다.
- route 변경은 하지 않았다.
- owner/controller/coordinator migration은 하지 않았다.
- Provider / Repository / Navigator / persistence authority migration은 하지 않았다.
- DTO/model/public API 추가는 하지 않았다.
- `ExplorerWorkspaceState` projection을 visible UI input으로 사용하지 않았다.
- 전체 `flutter test --reporter compact` baseline red는 Phase 12-D 기준 `+204 -6`에서 Phase 12-K 이후 `+227 -1`로 개선되었다.

첫 production-visible UX diff인 context strip은 기존 production owner 내부의 `_centerWordId`, `_selectedWordId`만 읽는 read-only 표시로 제한되었다. 이 변경은 graph/detail split 구조, route entry, shell mount, authority ownership, projection visible UI 사용으로 확장되지 않았다.

#### 17.76.2 명령어 기반 확인 결과

현재 Phase 12-L 브랜치에서 전체 `flutter test --reporter compact`는 `+227 -1`로 종료되었다. 남은 실패는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` 1건이며, Phase 12-B부터 Phase 12-K까지의 변경으로 새 실패가 추가되었다고 확인되지 않았다.

남은 red 1건의 개별 실행 결과는 다음과 같다.

| 테스트 파일 | 개별 실행 결과 | 실패 지점 | 실패 요약 |
| --- | --- | --- | --- |
| `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` | `+5 -1` | `production import tree does not reference preview composition` | `lib/ui/word_explorer_screen.dart`가 `explorer_workspace/` contract/adapter를 import해 source-level guardrail과 불일치한다. |

실패 메시지는 `Production import tree must not reference preview composition: lib/ui/word_explorer_screen.dart -> explorer_workspace/.`로 확인되었다.

#### 17.76.3 composition boundary 실패 성격

이 실패는 production 기능 오류로 판단하지 않는다. 현재 실패는 `ExplorerWorkspace` shell mount, production route 변경, preview composition mount, repository ownership, Navigator ownership, persistence authority migration이 발생했다는 신호가 아니다.

현재 `word_explorer_screen.dart`의 `explorer_workspace/` import는 Phase 7 이후 도입된 read-only projection chain 때문이다. `WordExplorerScreen`은 `explorer_workspace_contract.dart`와 `word_explorer_workspace_projection_adapter.dart`를 import해 `_readOnlyWorkspaceProjection`을 만들고, assert-only hidden visual probe와 candidate representation reader guardrail에서 이를 읽는다. Phase 12-B context strip도 projection을 visible UI input으로 쓰지 않는다는 guardrail을 유지한다.

따라서 이 실패는 단순 오래된 API 참조나 기대값 현행화가 아니라, Phase 4-E production import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 범위가 충돌하는 문제다. Phase 4-E guardrail은 preview-only composition 유입을 막기 위해 `explorer_workspace/` 참조 자체를 광범위하게 금지했지만, Phase 7 이후에는 preview composition mount가 아닌 read-only contract/adapter import가 별도 boundary로 허용되는 흐름이 생겼다.

#### 17.76.4 Phase 12에서 직접 수정하지 않는 이유

`explorer_workspace_phase4e_composition_boundary_test.dart`를 Phase 12에서 직접 수정하지 않는다.

이 항목은 단순 test fix로 처리하기에 정책 영향이 크다. 금지어 목록에서 `explorer_workspace/`만 제거하면 preview composition 금지, shell mount 금지, read-only contract/adapter import 허용, visible UI input 금지, route/shell/owner/persistence migration 금지의 경계가 분리되지 않는다. 반대로 production import를 되돌리면 Phase 7-D/F read-only projection chain, Phase 8 hidden probe, Phase 10 candidate representation reader, Phase 12-B context strip guardrail 흐름을 흔들 수 있다.

따라서 Phase 12에서 임의로 테스트를 수정하지 않고, Phase 13 전환 정책 또는 별도 guardrail 재정의 phase로 이월한다. 후속 단계에서는 preview composition 금지와 read-only projection/adapter import 허용 범위를 별도 assertion으로 분리해야 한다.

#### 17.76.5 Phase 13 이월 조건

Phase 13 또는 별도 guardrail 재정의 phase로 이월할 때의 조건은 다음과 같다.

- `ExplorerWorkspacePreviewScreen`, preview interaction host, preview input, preview-only shell mount 금지는 계속 유지한다.
- production route, `HomeScreen -> WordExplorerScreen` entry, Navigator ownership, repository ownership, persistence/history authority migration 금지는 계속 유지한다.
- `ExplorerWorkspace` shell mount 또는 production replacement는 별도 승인 전까지 금지한다.
- read-only `ExplorerWorkspaceState` contract/adapter import 허용 여부를 preview composition import 금지와 분리해 정의한다.
- projection 결과를 visible UI input, persisted state, route state, canonical owner로 쓰지 않는다는 guardrail을 유지한다.
- Phase 4-E 문서와 테스트가 Phase 7 이후 projection/helper 흐름을 반영하도록 재정의한다.

#### 17.76.6 Phase 12 종료 판단

권장 판단은 다음과 같다.

```text
Phase 12는 첫 production-visible UX diff 도입과 baseline red 대폭 축소라는 핵심 목적을 달성했다.
남은 composition boundary red 1건은 Phase 13 guardrail 재정의 과제로 이월 가능하므로,
Phase 12-M 종료 audit로 진행할 수 있다.
```

다만 이 판단은 조건부다. Phase 12 종료 기준을 zero-red로 정의한다면 composition boundary guardrail 재정의까지 Phase 12 안에서 수행해야 한다. 현재 점진 안정화 전략에서는 이 red를 production 기능 오류가 아니라 guardrail 정의 불일치로 분류하고, Phase 13 전환 정책 또는 별도 guardrail phase로 이월하는 것이 안전하다.

Phase 12-M은 Phase 12 종료 audit로 필요하다. Phase 12-M에서는 Phase 12-A부터 Phase 12-L까지의 결과, 남은 carryover 1건, Phase 13 진입 조건, 추가 UX diff 보류 상태를 최종 확인해야 한다.

추가 production-visible UX diff는 계속 보류한다. 새로 개발과 병렬 개발도 보류하고 기존 방식의 점진 안정화 전략을 유지한다.

#### 17.76.7 Phase 12-L 명령어 기반 확인 체크리스트

Phase 12-L의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았음을 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 전체 baseline 확인 | 전체 `flutter test`가 `+227 -1`로 종료되고 남은 실패가 1건이어야 함 | 새 branch-only 실패 또는 실패 수 증가 | `flutter test --reporter compact` | `+227 -1` |
| 남은 red 개별 확인 | composition boundary 테스트가 `+5 -1`로 종료되어야 함 | 실패 성격이 기존 inventory와 달라짐 | `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` | `+5 -1` |
| Phase 12-L 기록 확인 | Phase 12-L, termination, carryover, composition boundary, Phase 13, `flutter test`, `+227 -1` 기록이 두 문서에 있어야 함 | Phase 12-L 목적, 이월 판단, 종료 audit 판단 누락 | `rg -n "Phase 12-L|termination|carryover|composition boundary|Phase 13|flutter test|\\+227 -1" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 작업 종료 보고에서 기록 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 작업 종료 보고에서 기록 |
| production UI diff 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 작업 종료 보고에서 기록 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 작업 종료 보고에서 기록 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | 작업 종료 보고에서 기록 |

### 17.77 Phase 12-M termination audit

Phase 12-M은 구현 단계가 아니라 Phase 12 종료 audit 단계다. 목적은 Phase 12-A부터 Phase 12-L까지의 결과를 종합해 Phase 12를 종료 가능한 상태로 볼 수 있는지 판단하고, Phase 13으로 이월할 항목과 Phase 13 시작 조건을 문서화하는 것이다.

이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않는다. 수정 범위는 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 문서로 제한한다.

#### 17.77.1 Phase 12 전체 성과 요약

| 단계 | 성과 요약 |
| --- | --- |
| Phase 12-A | `minimum production-visible candidate selection audit`로 Phase 12의 최소 production-visible 후보 범주를 선정했다. Full `ExplorerWorkspace` shell mount는 직접 후보에서 제외했고, 기존 `WordExplorerScreen` 경로 안의 작고 rollback 가능한 read-only UX diff만 후속 후보로 남겼다. |
| Phase 12-B | 기존 `HomeScreen -> WordExplorerScreen` 진입 경로를 유지한 상태에서 `WordExplorerScreen` detail pane 상단 read-only context strip을 추가했다. |
| Phase 12-C | Phase 12-B context strip을 첫 production-visible UX diff로 평가했고, 추가 UX 확장은 별도 범위 정의와 baseline red 판단 이후로 보류했다. |
| Phase 12-D | 전체 `flutter test` baseline red를 inventory로 정리했고, Phase 12-B/C 직접 회귀가 아니라 기존 baseline test debt로 분리했다. |
| Phase 12-E | `widget_test.dart` package/import baseline 문제를 현행화했다. |
| Phase 12-F | Phase 12-E 이후 남은 baseline red를 재검토하고 다음 작은 fix 후보를 분리했다. |
| Phase 12-G | `word_info_panel_test.dart` baseline을 현행 `WordInfoPanel` contract에 맞춰 정리했다. |
| Phase 12-H | 남은 baseline red를 triage하고 `read_source_policy` 계열을 다음 단일 fix 후보로 선정했다. |
| Phase 12-I | `word_repository_read_source_policy_test.dart` baseline을 현행 `WordRepository` API에 맞춰 정리했다. |
| Phase 12-J | 남은 red 2건을 final red decision audit로 분류했고, representative query는 Phase 12-K 후보로, composition boundary는 Phase 13 또는 별도 guardrail 재정의 후보로 분리했다. |
| Phase 12-K | `word_repository_phase8h1_representative_query_contract_test.dart`의 representative query expectation baseline을 현행 seed DB와 duplicate candidate 정책에 맞춰 정리했다. |
| Phase 12-L | 마지막 남은 composition boundary red 1건의 성격을 종료 전 boundary carryover로 판단하고 Phase 13 이월 가능성을 정리했다. |

Phase 12 전체의 핵심 성과는 첫 production-visible UX diff를 제한적으로 도입했고, baseline red를 대폭 축소했다는 점이다.

#### 17.77.2 Phase 12에서 실제 변경된 production-visible UX

Phase 12에서 실제로 발생한 production-visible UX 변경은 다음 하나로 한정한다.

```text
WordExplorerScreen detail pane 상단 read-only context strip 추가
```

이 변경은 기존 production owner 내부의 `_centerWordId`, `_selectedWordId`를 읽어 작은 context strip으로 표시하는 범위에 머물렀다. `ExplorerWorkspaceState` projection은 visible UI input으로 사용하지 않았다.

#### 17.77.3 Phase 12에서 변경하지 않은 것

Phase 12는 다음 항목을 변경하지 않았다.

- `ExplorerWorkspace` shell mount 없음
- route 변경 없음
- 기존 `HomeScreen -> WordExplorerScreen` 진입 경로 유지
- owner/controller/coordinator migration 없음
- Provider / Repository / Navigator / persistence authority migration 없음
- DTO/model/public API 추가 없음
- `ExplorerWorkspaceState` projection visible UI 사용 없음
- 새로 개발/병렬 개발 보류

따라서 Phase 12는 ExplorerWorkspace production replacement나 canonical owner migration 단계가 아니다.

#### 17.77.4 baseline red 개선 결과

Phase 12의 전체 `flutter test --reporter compact` baseline은 다음과 같이 개선되었다.

```text
+204 -6 -> +227 -1
```

Phase 12-D inventory 기준 6건의 red 중 package/import baseline, panel contract baseline, repository read source policy baseline, representative query expectation baseline을 단계적으로 정리했다. Phase 12-M 기준 남은 red는 다음 1건이다.

```text
test/ui/explorer_workspace_phase4e_composition_boundary_test.dart
```

#### 17.77.5 남은 red 1건의 성격과 이월 판단

남은 red는 production 기능 오류가 아니라, Phase 4-E production import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 범위의 정책 불일치다.

현재 실패는 `ExplorerWorkspace` shell mount, production route 변경, preview composition mount, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, persistence authority 이전이 발생했다는 의미가 아니다. `lib/ui/word_explorer_screen.dart`가 Phase 7 이후 read-only projection chain을 위해 `explorer_workspace/` contract/adapter를 import하는 흐름과, Phase 4-E의 광범위한 production import 금지 guardrail이 충돌한 것이다.

따라서 남은 red는 Phase 12-M에서 직접 수정하지 않는다. 이 항목은 Phase 13 guardrail 재정의 또는 별도 boundary policy phase로 이월한다.

#### 17.77.6 Phase 12 종료 가능 여부

권장 종료 판단은 다음과 같다.

```text
Phase 12는 첫 production-visible UX diff 도입과 baseline red 대폭 축소라는 핵심 목적을 달성했다.
남은 composition boundary red 1건은 Phase 13 guardrail 재정의 과제로 이월 가능하므로,
Phase 12는 종료 가능하다.
```

이 판단은 현재 점진 안정화 전략 기준이다. 남은 red는 production 동작 실패가 아니라 boundary policy와 source-level guardrail 정의의 불일치이므로, Phase 12 종료를 막는 production blocker로 보지 않는다.

#### 17.77.7 Phase 13 시작 조건

Phase 13은 Phase 12-M 종료 커밋 이후 별도 작업으로 시작한다. 시작 조건은 다음과 같다.

- Phase 13 첫 작업은 composition boundary guardrail 재정의 여부 판단으로 시작한다.
- Phase 4-E preview-only composition 금지와 Phase 7 이후 read-only projection/adapter import 허용 범위를 분리해 정의한다.
- 추가 production-visible UX diff는 composition boundary guardrail 정리 이후 재검토한다.
- `ExplorerWorkspace` shell mount, route 변경, owner/controller/coordinator migration은 별도 승인 전까지 금지한다.
- Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가도 별도 승인 전까지 금지한다.
- Phase 13은 새 ChatGPT 채팅에서 시작하는 것을 권장한다.

#### 17.77.8 Phase 13 우선 후보

Phase 13에서 우선 다룰 후보는 다음 두 가지로 분리한다.

| 후보 | 판단 |
| --- | --- |
| composition boundary guardrail 재정의 | 첫 작업 후보다. preview composition 금지, read-only contract/adapter import 허용, projection visible UI input 금지, route/shell/owner/persistence migration 금지를 분리해야 한다. |
| 이후 추가 production-visible UX diff 재검토 | guardrail 정리 이후에만 검토한다. 기존 `HomeScreen -> WordExplorerScreen` 진입 경로 유지, shell mount 없음, route 변경 없음, authority migration 없음 조건을 다시 확인해야 한다. |

#### 17.77.9 Phase 12-M 명령어 기반 확인 결과

Phase 12-M의 command 기반 확인은 문서 반영 확인, baseline red 확인, path-level diff 확인으로 제한했다. 목표는 이번 docs/audit 변경이 코드, 테스트, 플랫폼, dependency, production UI를 변경하지 않았고 Phase 12 종료 판단이 실제 baseline 상태와 일치하는지 확인하는 것이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 전체 baseline 확인 | 전체 `flutter test`가 `+227 -1`로 종료되고 남은 실패가 1건이어야 함 | 새 branch-only 실패 또는 실패 수 증가 | `flutter test --reporter compact` | `+227 -1` |
| 남은 red 개별 확인 | composition boundary 테스트가 `+5 -1`로 종료되어야 함 | 실패 성격이 기존 inventory와 달라짐 | `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` | `+5 -1` |
| Phase 12-M 기록 확인 | Phase 12-M, termination audit, Phase 13, carryover, composition boundary, `+227 -1`, production-visible UX diff 기록이 두 문서에 있어야 함 | Phase 12-M 목적, 이월 판단, 종료 판단 누락 | `rg -n "Phase 12-M|termination audit|Phase 13|carryover|composition boundary|\\+227 -1|production-visible UX diff" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 기록 확인됨 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| production UI diff 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 출력 없음 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | whitespace 오류 없음 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | `docs/explorer-workspace-phase12m-termination-audit`, 문서 2개 변경 |

### 17.78 Phase 13-A composition boundary guardrail 재정의 audit

Phase 13-A는 구현 단계가 아니라 docs/audit 단계다. 목적은 Phase 4-E production import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 흐름의 충돌을 문서 기준으로 재정의하는 것이다. 이번 단계에서는 코드, 테스트, UI, 플랫폼, dependency 파일을 수정하지 않는다.

Phase 4-E guardrail의 원래 목적은 preview-only composition이 production owner 또는 source of truth로 유입되는 것을 막는 것이었다. 당시의 광범위한 `explorer_workspace/` production import 금지는 `ExplorerWorkspace` shell mount, `ExplorerWorkspacePreviewScreen` route 연결, preview interaction host 연결, preview input의 production contract 소비, repository/Navigator/persistence authority 이전을 차단하기 위한 방어선이었다.

Phase 7 이후에는 별도 흐름이 생겼다. `WordExplorerScreen`의 read-only projection/adapter import는 shell mount, route 변경, owner migration이 아니다. 이 경계는 기존 `WordExplorerScreen` owner state를 `ExplorerWorkspaceState` snapshot으로 읽어 assert/probe에서 확인하는 one-way read-only projection이며, repository, Navigator, persistence, route authority를 이전하지 않는다.

따라서 현재 남은 red 1건은 production 기능 오류가 아니라 Phase 4-E blanket import guardrail과 Phase 7 이후 read-only projection/adapter import 허용 정책의 불일치로 기록한다. `explorer_workspace/` import를 전면 금지하는 기존 guardrail은 노후화되었으며, allowed import와 forbidden import를 분리한 새 composition boundary guardrail로 재정의해야 한다.

#### 17.78.1 allowed import 범위

Phase 13-A 기준 allowed 범위는 다음으로 제한한다.

- `WordExplorerScreen` 내부 read-only projection adapter import
- `ExplorerWorkspaceState` / `ExplorerWorkspaceLayoutPreset` / `ExplorerWorkspaceTransitionOrigin`의 read-only 참조
- 기존 `WordExplorerScreen` owner state를 projection으로 읽는 assert/probe 용도
- repository, Navigator, persistence, route authority를 이전하지 않는 참조

allowed import는 source of truth 이전이 아니다. projection 결과는 production history, persisted state, route state, visible UI source-of-truth, canonical owner state로 승격하지 않는다.

#### 17.78.2 forbidden import 및 변경 범위

Phase 13-A 기준 forbidden 범위는 다음과 같다.

- `ExplorerWorkspace` shell mount
- `ExplorerWorkspacePreviewScreen` production route 연결
- `ExplorerWorkspacePreviewInteractionHost` production 연결
- `ExplorerWorkspacePreviewInput`을 production route/input contract로 소비
- `ExplorerWorkspaceHistoryEntry`를 production history/source-of-truth로 사용
- `main.dart` route/default home 변경
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- DTO/model/public API 추가
- `ExplorerWorkspaceState` projection을 visible UI source-of-truth로 사용
- 추가 production-visible UX diff

이 forbidden 범위는 Phase 13-A에서 직접 수정하지 않는다. 후속 test fix가 필요하더라도 `explorer_workspace_phase4e_composition_boundary_test.dart`는 allowed/forbidden boundary가 문서로 고정된 뒤 별도 승인된 단계에서만 현행화한다.

#### 17.78.3 Phase 13-A에서 하지 않는 것

이번 단계에서는 다음을 하지 않는다.

- `explorer_workspace_phase4e_composition_boundary_test.dart` 수정
- `lib/` 수정
- `test/` 수정
- `ExplorerWorkspace` shell mount
- route wiring 변경
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- DTO/model/public API 추가
- 추가 production-visible UX diff

#### 17.78.4 Phase 13-A 판단

Phase 13-A의 판단은 다음과 같다.

```text
Phase 4-E의 blanket explorer_workspace/ import 금지는 preview-only composition 유입 방지 목적이었다.
Phase 7 이후 WordExplorerScreen의 read-only projection/adapter import는 production owner/source-of-truth 이전이 아니다.
따라서 남은 composition boundary red 1건은 production 기능 오류가 아니라 guardrail 정의 불일치다.
후속 단계에서는 allowed import와 forbidden import를 분리한 source-level guardrail로 재정의해야 한다.
```

#### 17.78.5 Phase 13-A 명령어 기반 확인 체크리스트

Phase 13-A의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 이번 단계는 docs/audit 변경만 수행하므로 전체 `flutter test` 실행은 필수로 보지 않는다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 문서 반영 확인 | Phase 13-A, composition boundary guardrail, read-only projection, adapter import, allowed, forbidden, Phase 4-E, Phase 7, production-visible UX diff 기록이 두 문서에 있어야 함 | Phase 13-A 목적, allowed/forbidden 범위, 남은 red 성격 누락 | `rg -n "Phase 13-A|composition boundary guardrail|read-only projection|adapter import|allowed|forbidden|Phase 4-E|Phase 7|production-visible UX diff" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 기록 확인됨 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | 문서 외 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| production UI diff 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | UI 또는 플랫폼 파일 변경 | `git diff --name-only -- lib android ios macos windows linux web` | 출력 없음 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | whitespace 오류 없음 |
| Git 상태 확인 | 변경 파일과 브랜치 상태가 명확해야 함 | 승인 범위 밖 파일 변경 또는 잘못된 브랜치 | `git status --short --branch` | `docs/explorer-workspace-phase13a-composition-boundary-guardrail-audit`, 문서 2개 변경 |
| 최신 커밋 확인 | 커밋 전에는 Phase 12-M 커밋, 커밋 후에는 Phase 13-A 커밋이 확인되어야 함 | 기준 커밋 또는 최종 커밋 불일치 | `git log -1 --oneline` | 커밋 전 `ca0b32e docs: ExplorerWorkspace Phase 12-M 종료 audit 정리` 확인 |

### 17.79 Phase 13-B composition boundary guardrail test 현행화

Phase 13-B는 Phase 13-A에서 문서화한 allowed / forbidden 기준을 `explorer_workspace_phase4e_composition_boundary_test.dart`에 반영하는 test guardrail fix 단계다. 이번 단계는 production code 변경이 아니라 오래된 Phase 4-E blanket import guardrail을 현재 read-only projection/adapter boundary에 맞게 현행화하는 작업이다.

이번 단계에서는 `lib/`, 플랫폼, dependency, DB, repository/provider/navigator/route production code를 수정하지 않는다. 추가 production-visible UX diff도 만들지 않는다. UI 기반 테스트는 수행 대상이 아니며 클라이언트 UI 확인 대상도 없다.

#### 17.79.1 테스트 guardrail 현행화 기준

기존 테스트의 `explorer_workspace/` 전체 production source 금지는 Phase 13-A 이후 노후화된 blanket ban으로 취급한다. Phase 13-B에서는 다음 allowed 범위를 production source에서 허용한다.

- `WordExplorerScreen` 내부 read-only projection adapter import
- `explorer_workspace_contract.dart`
- `word_explorer_workspace_projection_adapter.dart`
- `ExplorerWorkspaceState`
- `ExplorerWorkspaceLayoutPreset`
- `ExplorerWorkspaceTransitionOrigin`

동시에 다음 forbidden 범위는 계속 차단한다.

- `ExplorerWorkspace(` shell mount
- `ExplorerWorkspacePreviewScreen`
- `ExplorerWorkspacePreviewInteractionHost`
- `ExplorerWorkspacePreviewInput` production route/input contract 소비
- `ExplorerWorkspaceHistoryEntry` production history/source-of-truth 사용
- `explorer_workspace.dart` production import
- `explorer_workspace_preview_screen.dart`
- `explorer_workspace_preview_interaction_host.dart`
- `main.dart` default home 변경
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration

#### 17.79.2 테스트 변경 의도

`WordExplorerScreen`은 `explorer_workspace_contract.dart`와 `word_explorer_workspace_projection_adapter.dart`만 import할 수 있다. `explorer_workspace.dart`, preview screen, preview interaction host, preview input, history entry를 production route/input/history/source-of-truth로 소비하면 테스트가 실패해야 한다.

이 현행화는 `ExplorerWorkspace shell` 또는 preview composition을 production에 연결하는 승인이 아니다. read-only projection/adapter import만 allowed boundary로 유지하고, preview/shell/route/authority 유입은 forbidden boundary로 유지한다.

#### 17.79.3 Phase 13-B 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 개별 composition boundary test | Phase 13-B 기준으로 전체 통과해야 함 | allowed import가 과도하게 막히거나 forbidden marker가 누락됨 | `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` | `+6: All tests passed!` |
| 전체 baseline test | 기존 remaining red 1건이 해소되어 전체 green이어야 함 | 새 branch-only 실패 또는 기존 red 잔존 | `flutter test --reporter compact` | `+228: All tests passed!` |
| 문서 반영 확인 | Phase 13-B, composition boundary guardrail, read-only projection, adapter import, allowed, forbidden, ExplorerWorkspacePreviewScreen, ExplorerWorkspace shell, production-visible UX diff 기록이 두 문서에 있어야 함 | Phase 13-B 목적 또는 allowed/forbidden 기준 누락 | `rg -n "Phase 13-B|composition boundary guardrail|read-only projection|adapter import|allowed|forbidden|ExplorerWorkspacePreviewScreen|ExplorerWorkspace shell|production-visible UX diff" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 기록 확인됨 |
| 코드/플랫폼/dependency 변경 없음 확인 | `lib`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code 또는 dependency 변경 발생 | `git diff --name-only -- lib android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| 변경 파일 확인 | 테스트 파일과 문서 2개만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` | 테스트 파일 1개와 문서 2개 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 출력 없음 |
| Git 상태 확인 | Phase 13-B 브랜치에서 변경 범위가 명확해야 함 | 잘못된 브랜치 또는 예상 외 파일 변경 | `git status --short --branch` | `fix/explorer-workspace-phase13b-composition-boundary-guardrail-test`, 파일 3개 변경 |

### 17.80 Phase 13-C termination audit

Phase 13-C는 구현, test fix, UX 변경 단계가 아니라 Phase 13 전체 종료 가능 여부를 판단하는 termination audit 단계다. 이번 단계에서는 `lib/`, `test/`, 플랫폼, dependency, DB, repository/provider/navigator/route production code를 수정하지 않는다. 추가 production-visible UX diff도 수행하지 않는다.

#### 17.80.1 Phase 13-A 결과 요약

Phase 13-A는 composition boundary guardrail 정책을 재정의했다. Phase 4-E blanket `explorer_workspace/` import ban의 원래 목적은 preview-only composition이 production owner 또는 source of truth로 유입되는 것을 막는 것이었음을 재확인했다.

Phase 13-A는 이후 Phase 7~12에서 생긴 `WordExplorerScreen` 내부 read-only projection/adapter import를 별도 allowed boundary로 분리했다. allowed 범위는 `explorer_workspace_contract.dart`, `word_explorer_workspace_projection_adapter.dart`, `ExplorerWorkspaceState`, `ExplorerWorkspaceLayoutPreset`, `ExplorerWorkspaceTransitionOrigin`의 read-only 참조로 제한한다.

동시에 preview/shell/route/authority 유입은 forbidden boundary로 유지했다. `ExplorerWorkspace` shell mount, `ExplorerWorkspacePreviewScreen`, `ExplorerWorkspacePreviewInteractionHost`, `ExplorerWorkspacePreviewInput` production route/input contract 소비, `ExplorerWorkspaceHistoryEntry` production history/source-of-truth 사용, route wiring 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration은 계속 금지된다.

#### 17.80.2 Phase 13-B 결과 요약

Phase 13-B는 `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`를 Phase 13-A 기준에 맞게 현행화했다. 기존 `explorer_workspace/` 전체 production source blanket ban을 제거하고, `WordExplorerScreen`의 read-only projection/adapter import만 허용하도록 테스트를 재구성했다.

Preview/shell/route/history/authority 유입 차단은 유지했다. `ExplorerWorkspace(` shell mount, preview screen/interaction host/input/history marker, `explorer_workspace.dart` production import, route/default home 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration은 계속 실패 조건으로 남는다.

Phase 13-B 결과로 Phase 12-M 이후 남아 있던 remaining red 1건인 `explorer_workspace_phase4e_composition_boundary_test.dart` 실패가 해소되었다.

#### 17.80.3 Phase 13 종료 판단

Phase 13은 다음 조건을 충족했다.

- Phase 13-A에서 composition boundary guardrail 정책을 allowed / forbidden 기준으로 재정의했다.
- Phase 13-B에서 오래된 Phase 4-E source-level guardrail test를 현행 정책에 맞게 수정했다.
- 기존 remaining red 1건이 해소되었다.
- 전체 `flutter test --reporter compact` green 상태를 명령어 기반으로 확인했다.
- 이번 Phase 13-C에서는 production-visible UX diff를 수행하지 않는다.

명령어 기반 확인에서 위 조건이 유지되었으므로 Phase 13은 종료 가능하다.

#### 17.80.4 추가 production-visible UX diff 재개 조건

Phase 13-C 이후 추가 production-visible UX diff를 재개하려면 별도 Phase에서 다음 조건을 다시 확인해야 한다.

- `ExplorerWorkspace` shell mount 금지 유지 여부
- route wiring 변경 여부
- owner/controller/coordinator migration 여부
- Provider / Repository / Navigator / persistence authority migration 여부
- DTO/model/public API 추가 여부
- `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 여부
- rollback 가능한 최소 production-visible UX diff인지 여부

이 조건 확인은 Phase 13-C의 범위가 아니며, 추가 UX diff 구현 승인도 아니다.

#### 17.80.5 Phase 13-C 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 전체 test baseline 확인 | 전체 `flutter test`가 `+228: All tests passed!`로 종료되어야 함 | 새 branch-only 실패 또는 green baseline 붕괴 | `flutter test --reporter compact` | `+228: All tests passed!` |
| composition boundary test 개별 확인 | Phase 13-B 현행화 테스트가 `+6: All tests passed!`로 종료되어야 함 | allowed/forbidden guardrail 회귀 | `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` | `+6: All tests passed!` |
| 문서 반영 확인 | Phase 13-C, termination audit, Phase 13 종료, Phase 13-A/B, `+228`, production-visible UX diff 재개 조건이 두 문서에 있어야 함 | 종료 판단, 테스트 결과, 후속 UX diff 조건 누락 | `rg -n "Phase 13-C|termination audit|Phase 13 종료|composition boundary guardrail|Phase 13-A|Phase 13-B|flutter test|\\+228|production-visible UX diff|ExplorerWorkspace shell|route wiring|owner/controller/coordinator|Provider / Repository / Navigator / persistence" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 기록 확인됨 |
| 코드/테스트/플랫폼/dependency 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | docs/audit 범위 밖 파일 변경 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| production UI diff 없음 확인 | `lib`, 플랫폼 경로 변경이 없어야 함 | production-visible UI/플랫폼 변경 발생 | `git diff --name-only -- lib android ios macos windows linux web` | 출력 없음 |
| 변경 파일 확인 | 문서 2개만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` | `docs/logs/CHANGELOG.md`, `docs/ux/explorer_workspace_unification.md` |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 출력 없음 |
| Git 상태 확인 | Phase 13-C 브랜치에서 변경 범위가 명확해야 함 | 잘못된 브랜치 또는 예상 외 파일 변경 | `git status --short --branch` | `docs/explorer-workspace-phase13c-termination-audit`, 문서 2개 변경 |

### 17.81 Phase 14-A minimum production-visible UX diff candidate selection audit

Phase 14의 목적은 Phase 13에서 composition boundary guardrail green 상태를 확보한 뒤, 추가 production-visible UX diff를 재개해도 되는지 판단하는 것이다. Phase 14-A는 구현 단계가 아니라 minimum production-visible UX diff candidate selection audit 단계다. 이번 단계에서는 후보를 선정하고 금지선을 다시 고정할 뿐, production-visible UX diff를 만들지 않는다.

#### 17.81.1 유지 금지선

Phase 14-A와 Phase 14-B 후보 검토에서 유지해야 할 금지선은 다음과 같다.

- ExplorerWorkspace shell mount 금지
- route wiring / route registration 변경 금지
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 금지
- owner/controller/coordinator migration 금지
- Provider / Repository / Navigator / persistence authority migration 금지
- DTO/model/public API 추가 금지
- projection result persistence/history/source-of-truth 사용 금지
- `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 금지
- route collapse 금지
- canonical owner migration 금지
- Level 3 production-visible consumer 승격 금지

#### 17.81.2 Phase 14 최소 후보 선정 기준

Phase 14에서 검토할 최소 후보는 다음 기준을 모두 만족해야 한다.

- 기존 `WordExplorerScreen` 내부 변경이어야 한다.
- read-only UX diff여야 한다.
- rollback 가능한 최소 단위여야 한다.
- ExplorerWorkspace shell mount 없이 가능해야 한다.
- route 변경 없이 가능해야 한다.
- owner/controller/coordinator migration 없이 가능해야 한다.
- Provider / Repository / Navigator / persistence authority migration 없이 가능해야 한다.
- DTO/model/public API 추가 없이 가능해야 한다.
- `ExplorerWorkspaceState` projection을 visible UI source-of-truth로 사용하지 않아야 한다.
- 전체 `flutter test` green을 유지할 수 있어야 한다.
- UI 기반 확인 방법이 사람이 이해할 수 있는 형태여야 한다.

#### 17.81.3 1순위 후보 평가

1순위 후보는 `WordExplorerScreen` detail pane 상단 read-only context strip의 표시 가독성 개선이다. 이 후보는 Phase 12-B에서 도입한 context strip의 후속 최소 개선으로 다룬다.

Phase 14-A에서는 이 후보를 구현하지 않고 후보로만 기록한다. 후보 평가는 다음과 같다.

| 평가 항목 | 판단 |
| --- | --- |
| 기존 private/local state 사용 가능성 | 가능 후보다. Phase 12-B context strip은 기존 `WordExplorerScreen` 내부 `_centerWordId`, `_selectedWordId`를 읽는 read-only 표시로 제한되어 있었다. Phase 14-B 후보도 이 범위를 유지해야 한다. |
| projection visible source-of-truth 미사용 가능성 | 가능 후보다. `ExplorerWorkspaceState` projection을 visible UI source-of-truth로 쓰지 않고, 기존 `WordExplorerScreen` 내부 상태만 읽는 방식이어야 한다. |
| route 변경 없음 여부 | 가능 후보다. `HomeScreen -> WordExplorerScreen` 진입 구조, route wiring, route registration을 변경하지 않아야 한다. |
| owner/controller/coordinator 변경 없음 여부 | 가능 후보다. graph center, selected word, detail panel, explorer history ownership은 계속 `WordExplorerScreen`에 남아야 한다. |
| Provider / Repository / Navigator / persistence authority 변경 없음 여부 | 가능 후보다. 가독성 개선은 read-only display refinement로 제한해야 하며, authority migration이나 persistence/history 사용을 추가하지 않아야 한다. |
| DTO/model/public API 추가 없음 여부 | 가능 후보다. 표시 구조 조정은 기존 private/local 값과 기존 UI 구성 안에서 처리할 수 있어야 한다. |

따라서 Phase 14-A 기준의 우선 후보는 `WordExplorerScreen` detail pane 상단 read-only context strip 표시 가독성 개선 하나로 제한한다. 다른 production-visible UX diff 후보는 Phase 14-A 범위에 포함하지 않는다.

#### 17.81.4 Phase 14-B 진입 조건

Phase 14-B로 진입하려면 다음 조건이 충족되어야 한다.

- Phase 14-A 문서/audit에서 후보와 금지선이 명확히 정리되어야 한다.
- 구현 후보가 하나로 제한되어야 한다.
- 금지선 침범이 없어야 한다.
- 테스트 조건과 UI 확인 방법이 명확해야 한다.
- Phase 14-B는 별도 feature 브랜치에서 진행해야 한다.

#### 17.81.5 Phase 14-A 명령어 기반 확인 체크리스트

Phase 14-A의 command 기반 확인은 문서 반영 확인과 path-level diff 확인으로 제한한다. 이번 단계는 docs/audit only 변경이며 `lib/`, `test/`, production code 변경이 없으므로 전체 `flutter test` 실행은 필수로 보지 않는다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 현재 브랜치와 상태 확인 | Phase 14-A docs 브랜치에서 HEAD와 origin/main이 `8c01358bb90224082da0a388b0c9a5eefc132ff4`로 일치해야 함 | 기준 브랜치 또는 기준 커밋 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` | 브랜치 `docs/explorer-workspace-phase14a-minimum-ux-diff-candidate-audit`, HEAD `8c01358bb90224082da0a388b0c9a5eefc132ff4`, origin/main `8c01358bb90224082da0a388b0c9a5eefc132ff4`, 최신 커밋 `8c01358 docs: ExplorerWorkspace Phase 13-C 종료 audit 정리`, 변경 파일 문서 2개 확인 |
| 문서 반영 검색 | Phase 14-A, minimum production-visible UX diff, candidate selection audit, 금지선, `WordExplorerScreen`, context strip, Phase 14-B 기록이 두 문서에 있어야 함 | 목적, 후보, 금지선, 진입 조건 누락 | `rg -n "Phase 14-A|minimum production-visible UX diff|candidate selection audit|ExplorerWorkspace shell|route wiring|owner/controller/coordinator|Provider / Repository / Navigator / persistence|DTO/model/public API|ExplorerWorkspaceState|visible UI source-of-truth|WordExplorerScreen|context strip|Phase 14-B" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 요청한 `rg` 검색 정상 매칭 확인 |
| 변경 파일 확인 | 문서 2개만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` | `docs/logs/CHANGELOG.md`, `docs/ux/explorer_workspace_unification.md` 2개만 변경됨 |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, UI 구현, test, dependency 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | 출력 없음 |
| 전체 flutter test 판단 | 문서/audit only 변경이면 미실행 가능하며 사유를 보고해야 함 | 문서 외 변경이 있는데 test를 생략함 | `flutter test --reporter compact` 실행 여부 판단 | 문서/audit only 변경이며 `lib/`, `test`, production code 변경이 없으므로 전체 `flutter test --reporter compact` 미실행 |

### 17.82 Phase 14-B WordExplorerScreen context strip 표시 가독성 개선

Phase 14-B는 Phase 14-A에서 선정한 단일 후보를 구현하는 production-visible UX diff 단계다. 목적은 기존 `HomeScreen -> WordExplorerScreen` 진입 경로 안에서 `WordExplorerScreen` detail pane 상단 read-only context strip 표시를 raw word id 중심에서 사람이 읽기 쉬운 대표 표기 / Strong 번호 / transliteration 조합으로 개선하는 것이다.

이번 변경은 `WordExplorerScreen` 내부 표시 개선으로만 제한한다. `ExplorerWorkspace` shell mount, route wiring 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, 새 repository read, 새 DB query는 수행하지 않았다.

#### 17.82.1 실제 UX 변경 내용

기존 context strip은 `중심 단어: <centerWordId> · 선택: <selectedWordId>` 또는 `선택 없음`처럼 word id 중심으로 표시했다.

Phase 14-B 이후 context strip은 기존 `WordExplorerScreen` owner state 안에 이미 있는 표시값을 우선 사용한다.

- 중심 단어 표시는 `_centerDisplaySeed.representativeSpelling`, `_centerDisplaySeed.displayStrongNumber`, `_centerDisplaySeed.representativeTransliteration`을 조합한다.
- 선택 단어 표시는 `_selectedWordDisplayItem.representativeSpelling`, `_selectedWordDisplayItem.displayStrongNumber`, `_selectedWordDisplayItem.transliterations`의 첫 번째 비어 있지 않은 값을 조합한다.
- 대표 표기가 없으면 기존 word id fallback을 유지한다.
- Strong 번호가 없으면 생략한다.
- transliteration이 없으면 생략한다.
- 선택 단어가 없으면 기존과 같이 `선택 없음`을 유지한다.
- 빈 값 때문에 빈 괄호, 중복 구분자, 의미 없는 공백이 생기지 않도록 비어 있지 않은 segment만 ` · `로 연결한다.

예상 표시 형태는 다음과 같다.

```text
중심 단어: 대표표기 · Strong번호 · transliteration · 선택: 대표표기 · Strong번호 · transliteration
중심 단어: 대표표기 · Strong번호 · transliteration · 선택 없음
중심 단어: wordId · 선택: wordId
```

#### 17.82.2 유지 금지선 확인

| 항목 | Phase 14-B 결과 |
| --- | --- |
| `ExplorerWorkspace` shell mount | 없음 |
| route wiring / route registration 변경 | 없음 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 변경 | 없음 |
| owner/controller/coordinator migration | 없음 |
| Provider / Repository / Navigator / persistence authority migration | 없음 |
| DTO/model/public API 추가 | 없음 |
| projection result persistence/history/source-of-truth 사용 | 없음 |
| `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 | 없음 |
| route collapse | 없음 |
| canonical owner migration | 없음 |
| Level 3 production-visible consumer 승격 | 없음 |
| 새 repository read | 없음 |
| 새 DB query | 없음 |

#### 17.82.3 CodeX 수행: 명령어 기반 수동 테스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 12-B context strip guardrail 유지 | context strip이 detail pane 안에 read-only로 존재하고 기존 `WordExplorerScreen` 내부 상태 기반 표시 기준을 유지해야 함 | route/owner/authority marker 유입, projection visible UI 입력 사용, strip 위치 이탈 | `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart --reporter expanded` | `+4: All tests passed!` |
| Phase 14-B context strip 표시 가독성 검증 | 중심/선택 단어 표시가 가능한 경우 대표 표기 / Strong 번호 / transliteration 기반으로 구성되고, 선택 없음과 id fallback이 유지되어야 함 | 선택 없음 누락, id fallback 누락, 빈 segment 구분자 출력 가능성, 새 repository/route/authority marker 유입 | `flutter test test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart --reporter expanded` | `+5: All tests passed!` |
| composition boundary 유지 | production import tree가 read-only projection boundary만 허용하고 preview/shell/route/owner 유입을 차단해야 함 | `ExplorerWorkspace` preview composition mount, route/default home 변경, owner migration marker 유입 | `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` | `+6: All tests passed!` |
| 전체 테스트 | Phase 14-B 변경 후 전체 테스트가 통과해야 함 | 변경 범위 밖 회귀, source-level guardrail 실패, repository/data test 실패 | `flutter test --reporter compact` | `+233: All tests passed!` |
| 변경 범위 확인 | tracked 변경 파일은 허용 파일 안에 있어야 함 | 플랫폼, dependency, 허용 외 production 파일 변경 | `git diff --name-only` | `docs/logs/CHANGELOG.md`, `docs/ux/explorer_workspace_unification.md`, `lib/ui/word_explorer_screen.dart`, `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart` 출력. 문서 2개는 `LF will be replaced by CRLF` 줄바꿈 경고가 함께 출력됨 |
| 신규 테스트 파일 확인 | untracked 신규 테스트 파일도 허용 파일 안에 있어야 함 | 허용 외 신규 파일 생성 | `git status --short --branch`, `git ls-files --others --exclude-standard` | `test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart`가 untracked 신규 파일로 확인됨 |
| 금지 경로/위험 변경 확인 | 플랫폼 경로와 `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | dependency 변경 또는 플랫폼별 설정 변경 | `git diff --name-only -- android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| whitespace 확인 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | whitespace 오류 없음. 문서 2개는 `LF will be replaced by CRLF` 줄바꿈 경고가 출력됨 |

#### 17.82.4 클라이언트 수행: UI 기반 수동 테스트

CodeX는 UI 테스트를 수행하지 않는다. 아래 절차는 클라이언트가 production-visible UX diff를 확인하기 위한 기준이다.

| 테스트 목적 | 시작 화면 | 조작 순서 | 입력할 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 테스트 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- | --- |
| 중심 단어 context strip 가독성 확인 | `HomeScreen` | 앱을 실행하고 HomeScreen에서 사람이 식별 가능한 단어를 Explorer로 연 뒤 detail pane 상단 context strip을 확인한다. | Home 기본 목록 또는 검색 결과에서 대표 표기와 Strong 번호가 보이는 단어 | 중심 단어가 가능한 경우 word id만이 아니라 대표 표기 / Strong 번호 / transliteration 조합으로 표시된다. | 중심 단어가 raw id만 표시되거나 빈 괄호, 중복 구분자, 의미 없는 공백이 보임 | 중심 단어 context가 이전보다 읽기 쉬운 표시로 보이고 detail pane 레이아웃 겹침이 없음 |
| 선택 단어 context strip 갱신 확인 | `WordExplorerScreen` | 그래프에서 다른 노드를 선택하고 context strip의 선택 영역을 확인한다. | 그래프에 표시되는 사람이 식별 가능한 다른 단어 노드 | 선택 단어가 가능한 경우 대표 표기 / Strong 번호 / transliteration 조합으로 갱신된다. | 선택 영역이 갱신되지 않거나 raw id만 표시되거나 detail panel의 선택 단어와 어긋남 | 선택한 노드와 detail panel, context strip 선택 표시가 같은 단어를 가리킴 |
| 선택 없음 상태 유지 확인 | `WordExplorerScreen` | 선택이 없는 초기 상태 또는 선택 해제 가능한 흐름에서 context strip을 확인한다. | 별도 id 입력 없음 | 선택 단어 영역이 `선택 없음`으로 유지된다. | 선택 없음 상태에서 빈 문자열, 빈 구분자, 이전 선택 단어가 남음 | 선택 없음 상태가 명확히 표시되고 center 표시가 유지됨 |
| fallback 확인 | `WordExplorerScreen` | 대표 표기 또는 Strong 번호가 부족한 단어를 Explorer에서 확인한다. | 대표 표기 일부가 비어 있는 단어가 있을 경우 해당 단어 | 표시 가능한 값이 부족하면 기존 word id fallback이 유지되고 Strong 번호/transliteration은 비어 있으면 생략된다. | 빈 괄호, 중복 구분자, 공백만 있는 segment가 보임 | 표시 가능한 값만 보이고 부족한 값은 생략되며 word id fallback이 남음 |

### 17.83 Phase 14-C termination audit

Phase 14-C는 Phase 14 전체 종료 가능 여부를 판단하는 termination audit 단계다. 이번 단계는 구현, test fix, UX 변경 단계가 아니며 `docs/ux/explorer_workspace_unification.md`와 `docs/logs/CHANGELOG.md`에 Phase 14-A/B 결과와 종료 판단을 정리하는 docs/audit only 변경으로 제한한다.

#### 17.83.1 Phase 14-A 요약

Phase 14-A는 Phase 13 composition boundary guardrail green 이후 추가 production-visible UX diff를 재개할 수 있는지 판단하기 위한 minimum production-visible UX diff candidate selection audit였다.

Phase 14-A에서 후보는 `WordExplorerScreen` detail pane 상단 read-only context strip 표시 가독성 개선 하나로 제한되었다. 이 후보는 기존 `HomeScreen -> WordExplorerScreen` production 진입 경로 안에서 기존 `WordExplorerScreen` 내부 상태를 read-only로 표시하는 최소 UX diff로 평가되었다.

Phase 14-A에서 재확인한 금지선은 다음과 같다.

- `ExplorerWorkspace` shell mount 금지
- route wiring / route registration 변경 금지
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 금지
- owner/controller/coordinator migration 금지
- Provider / Repository / Navigator / persistence authority migration 금지
- DTO/model/public API 추가 금지
- projection result persistence/history/source-of-truth 사용 금지
- `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 금지
- route collapse 금지
- canonical owner migration 금지
- Level 3 production-visible consumer 승격 금지

#### 17.83.2 Phase 14-B 요약

Phase 14-B는 Phase 14-A에서 선정한 단일 후보를 구현했다. `WordExplorerScreen` detail pane 상단 read-only context strip 표시를 raw word id 중심에서 가능한 경우 대표 표기 / Strong 번호 / transliteration 기반으로 읽기 쉽게 개선했다.

Phase 14-B의 실제 변경은 다음과 같다.

- 중심 단어는 `_centerDisplaySeed`의 `representativeSpelling`, `displayStrongNumber`, `representativeTransliteration`을 우선 사용한다.
- 선택 단어는 `_selectedWordDisplayItem`의 `representativeSpelling`, `displayStrongNumber`, 첫 번째 비어 있지 않은 transliteration 값을 우선 사용한다.
- 표시값이 부족하면 기존 word id fallback을 유지한다.
- 선택이 없으면 `선택 없음` 상태를 유지한다.
- 빈 segment는 생략해 빈 괄호, 중복 구분자, 의미 없는 공백이 나오지 않도록 했다.

#### 17.83.3 Phase 14 금지선 유지 결과

| 항목 | Phase 14 결과 |
| --- | --- |
| `ExplorerWorkspace` shell mount | 없음 |
| route wiring / route registration 변경 | 없음 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 변경 | 없음 |
| owner/controller/coordinator migration | 없음 |
| Provider / Repository / Navigator / persistence authority migration | 없음 |
| DTO/model/public API 추가 | 없음 |
| projection result persistence/history/source-of-truth 사용 | 없음 |
| `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 | 없음 |
| 새 repository read | 없음 |
| 새 DB query | 없음 |
| route collapse | 없음 |
| canonical owner migration | 없음 |
| Level 3 production-visible consumer 승격 | 없음 |

#### 17.83.4 Phase 14 테스트와 UI 확인 결과

| 확인 항목 | 실제 결과 |
| --- | --- |
| Phase 12-B context strip 테스트 | `+4: All tests passed!` |
| Phase 14-B context strip readability 테스트 | `+5: All tests passed!` |
| composition boundary test | `+6: All tests passed!` |
| 전체 `flutter test --reporter compact` | `+233: All tests passed!` |
| 클라이언트 UI 기반 테스트 | 성공 확인됨 |

전체 flutter test는 Phase 14-C가 문서/audit only 변경이며 lib/test/production code 변경이 없으므로 미실행했다. Phase 14-B에서 전체 flutter test --reporter compact는 +233: All tests passed!로 이미 확인되었다.

#### 17.83.5 Phase 14 종료 판단

Phase 14는 후보 선정, 최소 UX diff 구현, 테스트/문서/UI 확인까지 완료했다. Phase 14-C 기준 remaining red는 없고, `main == origin/main`, working tree clean, local branch `main` only, 원격 Phase 14-B 브랜치 없음 상태에서 시작되었다.

따라서 Phase 14는 종료 가능하다.

다음 Phase에서는 별도 승인 전까지 `ExplorerWorkspace` shell mount, route wiring / route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경, owner/controller/coordinator migration, Provider / Repository / Navigator / persistence authority migration, DTO/model/public API 추가, `ExplorerWorkspaceState` projection visible UI source-of-truth 사용, 새 repository read, 새 DB query를 계속 금지한다.

#### 17.83.6 Phase 14-C 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| 기준 git 상태 확인 | Phase 14-C docs 브랜치에서 HEAD와 origin/main이 `0f9cbcc72494e65af01a9105a1b97fb0cc4da8bc`로 일치해야 함 | 기준 브랜치 또는 기준 커밋 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` | 브랜치 `docs/explorer-workspace-phase14c-termination-audit`, HEAD `0f9cbcc72494e65af01a9105a1b97fb0cc4da8bc`, origin/main `0f9cbcc72494e65af01a9105a1b97fb0cc4da8bc`, 최신 커밋 `0f9cbcc feat: ExplorerWorkspace Phase 14-B context strip 가독성 개선` 확인 |
| 문서 반영 검색 | Phase 14-C, termination audit, Phase 14 종료, Phase 14-A/B, context strip, test 결과, UI 기반 확인, 금지선 문구가 두 문서에서 검색되어야 함 | 종료 판단 또는 금지선 기록 누락 | `rg -n "Phase 14-C|termination audit|Phase 14 종료|Phase 14-A|Phase 14-B|context strip|flutter test|\\+233|UI 기반|ExplorerWorkspace shell|route wiring|owner/controller/coordinator|Provider / Repository / Navigator / persistence|DTO/model/public API|ExplorerWorkspaceState|visible UI source-of-truth|새 repository read|새 DB query" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` | 요청한 검색어가 두 문서에서 정상 매칭됨 |
| 변경 파일 확인 | 문서 2개만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` | `docs/logs/CHANGELOG.md`, `docs/ux/explorer_workspace_unification.md` 출력. 문서 2개는 `LF will be replaced by CRLF` 줄바꿈 경고가 함께 출력됨 |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, 테스트, UI 구현, dependency 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` | 출력 없음 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` | whitespace 오류 없음. 문서 2개는 `LF will be replaced by CRLF` 줄바꿈 경고가 출력됨 |
| 전체 flutter test 판단 | docs/audit only 변경이므로 전체 테스트 미실행 사유가 명확해야 함 | 문서 외 변경이 있는데 test를 생략함 | `flutter test --reporter compact` 실행 여부 판단 | 전체 flutter test는 Phase 14-C가 문서/audit only 변경이며 lib/test/production code 변경이 없으므로 미실행함. Phase 14-B에서 전체 flutter test --reporter compact는 +233: All tests passed!로 이미 확인됨 |

### 17.84 Phase 15-A minimum production-visible UX diff candidate selection audit

Phase 15-A는 구현 단계가 아니라 docs/audit only 단계다. 목적은 Phase 14-B에서 `WordExplorerScreen` detail pane 상단 read-only context strip 표시 가독성 개선을 완료한 뒤, Phase 15에서 추가 minimum production-visible UX diff를 재개할 수 있는지 문서상으로 판단하는 것이다.

이번 단계에서는 후보군을 비교하고 Phase 15-B로 넘길 단일 후보를 선정할 수 있는지만 기록한다. Phase 15-B 구현, production code 변경, test code 변경, dependency 변경, 플랫폼 파일 변경, UI 테스트 수행 보고는 하지 않는다.

#### 17.84.1 Phase 14-B 이후 추가 production-visible UX diff 재개 가능 여부

Phase 14-B의 context strip 가독성 개선은 기존 `HomeScreen -> WordExplorerScreen` production 진입 경로 안에서 완료되었고, Phase 14-C에서 종료 가능하다고 기록되었다. 따라서 추가 UX diff 후보 검토는 가능하다.

다만 Phase 15-A 기준으로 재개 가능한 범위는 기존 `WordExplorerScreen` 내부 표시 개선에 한정한다. shell mount, route wiring, owner/authority migration, 새 repository read, 새 DB query를 동반하는 후보는 minimum production-visible UX diff 범위를 초과하므로 Phase 15-B 후보에서 제외한다.

#### 17.84.2 유지 금지선

| 항목 | Phase 15-A 기준 |
| --- | --- |
| `ExplorerWorkspace` shell mount | 금지 |
| route wiring / route registration 변경 | 금지 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 변경 | 금지 |
| owner/controller/coordinator migration | 금지 |
| Provider / Repository / Navigator / persistence authority migration | 금지 |
| DTO/model/public API 추가 | 금지 |
| projection result persistence/history/source-of-truth 사용 | 금지 |
| `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 | 금지 |
| route collapse | 금지 |
| canonical owner migration | 금지 |
| Level 3 production-visible consumer 승격 | 금지 |
| 새 repository read | 금지 |
| 새 DB query | 금지 |
| production code 변경 | 금지 |
| test code 변경 | 금지 |
| dependency 변경 | 금지 |
| 플랫폼 파일 변경 | 금지 |

#### 17.84.3 후보군 비교

| 후보 | 내용 | 평가 | Phase 15-B 후보 여부 |
| --- | --- | --- | --- |
| 후보 A | `WordExplorerScreen` detail pane 선택 없음 empty state 안내 가독성 개선 | 기존 `_buildNoSelectionDetailPanel()` 범위의 표시 개선으로 제한 가능하고 route, shell, owner, repository, DTO, projection source-of-truth 변경 없이 진행 가능한 최소 UX diff 후보 | 선정 |
| 후보 B | context strip 추가 개선 | Phase 14-B에서 같은 영역의 가독성 개선을 막 완료했으므로 연속 수정 시 UX diff 목적이 흐려질 수 있음 | 보류 |
| 후보 C | graph/history/navigation 관련 표시 개선 | history tooltip, graph action, navigation affordance 개선은 navigation/history owner, availability probe, repository probe와 결합될 위험이 있음 | 제외 |
| 후보 D | `ExplorerWorkspace` shell mount 또는 route 전환 | 명시적 금지선에 해당하며 production shell mount 또는 route 전환을 포함함 | 제외 |

#### 17.84.4 Phase 15-B 단일 후보 선정 여부

Phase 15-B로 넘길 후보는 후보 A 하나로 제한한다.

선정 후보는 `WordExplorerScreen` detail pane 선택 없음 empty state 안내 가독성 개선이다. 이 후보는 선택된 그래프 노드가 없는 상태에서 detail pane에 표시되는 안내 문구와 시각적 안내를 더 명확하게 정리하는 범위로 제한한다.

#### 17.84.5 선정 이유

- 기존 production 진입 경로인 `HomeScreen -> WordExplorerScreen` 구조를 유지할 수 있다.
- 기존 `WordExplorerScreen` 내부 `_buildNoSelectionDetailPanel()` 수준의 표시 개선으로 제한할 수 있다.
- `ExplorerWorkspace` shell mount, route wiring, owner/controller/coordinator migration 없이 진행할 수 있다.
- Provider / Repository / Navigator / persistence authority migration 없이 진행할 수 있다.
- DTO/model/public API 추가 없이 진행할 수 있다.
- 새 repository read와 새 DB query 없이 진행할 수 있다.
- Phase 14-B 이후에도 사용자가 볼 수 있는 최소 UX diff로 분리할 수 있다.

#### 17.84.6 제외 후보와 제외 이유

| 제외 후보 | 제외 이유 |
| --- | --- |
| 후보 B: context strip 추가 개선 | Phase 14-B에서 context strip 표시 가독성 개선을 막 완료했으므로 같은 영역을 연속 수정하면 Phase 15의 UX diff 목적이 좁아질 수 있다. 추가 필요는 실제 UI 기반 확인에서 별도 문제가 확인될 때 재검토한다. |
| 후보 C: graph/history/navigation 관련 표시 개선 | navigation/history owner, availability probe, repository probe와 결합될 수 있어 minimum production-visible UX diff 범위를 초과할 위험이 있다. |
| 후보 D: `ExplorerWorkspace` shell mount 또는 route 전환 | `ExplorerWorkspace` shell mount와 route wiring / route registration 변경은 Phase 15-A 금지선에 직접 해당하므로 Phase 15 후보에서 제외한다. |

#### 17.84.7 Phase 15-B 진행 시 필요한 테스트 조건

Phase 15-B를 진행하려면 먼저 별도 승인을 받고 신규 source-level guardrail test를 추가해야 한다. 권장 파일은 `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart`이다.

해당 테스트는 다음을 확인해야 한다.

- empty state 개선이 `_buildNoSelectionDetailPanel()` 범위에 머무는지 확인한다.
- `Navigator`, `MaterialPageRoute`, `Provider`, `Repository`, `WordRepository`, `SharedPreferences`, `ExplorerWorkspaceState`, `WordExplorerWorkspaceProjectionAdapter`, `setState`, `async`, `await`, `Future<` marker를 empty state 영역에 추가하지 않는지 확인한다.
- route/shell/owner/authority migration이 없는지 확인한다.
- 기존 context strip guardrail을 깨지 않는지 확인한다.

Phase 15-B에서 실행해야 할 명령은 다음과 같다.

- `flutter test test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart --reporter expanded`
- `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart --reporter expanded`
- `flutter test test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart --reporter expanded`
- `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded`
- `flutter test --reporter compact`

Phase 15-B의 클라이언트 UI 기반 테스트 조건은 다음과 같다. CodeX는 UI 테스트를 수행했다고 보고하지 않고, 실제 UI 판단은 클라이언트가 수행한다.

| 테스트 목적 | 시작 화면 | 조작 순서 | 입력할 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 테스트 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- | --- |
| 선택 없음 empty state 안내 가독성 확인 | `HomeScreen` | 사람이 식별 가능한 단어를 Explorer로 열고 그래프 노드를 선택하지 않은 detail pane 상태를 확인한다. | Home 기본 목록 또는 검색 결과에서 대표 표기와 Strong 번호가 보이는 단어 | 선택 없음 안내가 현재 상태와 다음 가능한 행동을 혼동 없이 전달한다. | 안내 문구가 과하거나, 선택이 이미 된 것처럼 보이거나, 불필요한 동작을 유도함 | 선택 없음 상태가 명확하고 detail pane의 다른 정보와 충돌하지 않음 |
| context strip 유지 확인 | `WordExplorerScreen` | detail pane 상단 context strip을 확인한다. | 같은 단어 | Phase 14-B의 중심/선택 단어 context strip 표시가 유지된다. | context strip이 사라지거나 raw id 중심으로 퇴행함 | context strip 표시와 empty state 안내가 동시에 읽기 쉬움 |
| 선택 후 상세 패널 전환 확인 | `WordExplorerScreen` | 그래프에서 사람이 식별 가능한 다른 노드를 선택한다. | 그래프에 표시되는 다른 단어 노드 | 선택 없음 안내가 사라지고 선택 단어 상세 패널로 자연스럽게 전환된다. | 선택 후에도 empty state가 남거나 상세 정보와 겹침 | 선택된 노드와 상세 패널 내용이 일치함 |
| 레이아웃 겹침 확인 | `WordExplorerScreen` | 창 크기를 일반 데스크톱 사용 크기로 유지한 채 detail pane을 확인한다. | 별도 id 입력 없음 | 안내 문구, context strip, 상세 패널 영역이 겹치지 않는다. | 텍스트 잘림, 겹침, 빈 공간 과다 발생 | 안내와 상세 패널 전환이 안정적으로 보임 |

#### 17.84.8 Phase 15-A 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 변경 파일 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 파일만 변경되어야 함 | 허용 외 파일 변경 발생 | `git diff --name-only` |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, test code, dependency, 플랫폼 파일 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` |
| whitespace 검증 | whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |
| 문서 반영 검색 | Phase 15-A 목적, 후보 선정, 금지선, Phase 15-B 후보, 테스트 조건이 문서에서 확인되어야 함 | 후보 선정 또는 금지선 기록 누락 | `rg -n "Phase 15-A|minimum production-visible UX diff|candidate selection audit|empty state|선택 없음|ExplorerWorkspace shell|route wiring|owner/controller/coordinator|Provider / Repository / Navigator / persistence|DTO/model/public API|ExplorerWorkspaceState|visible UI source-of-truth|새 repository read|새 DB query|Phase 15-B" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| 전체 flutter test 판단 | docs/audit only이며 production code/test code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다 | 문서 외 변경이 있는데 전체 테스트를 생략함 | 변경 파일 범위 확인 후 실행 여부 판단 |

### 17.85 Phase 15-B WordExplorerScreen 선택 없음 empty state 안내 가독성 개선

Phase 15-B는 Phase 15-A에서 선정한 단일 후보를 구현하는 production-visible UX diff 단계다. 목적은 `WordExplorerScreen` detail pane에서 그래프 노드가 선택되지 않은 상태의 안내를 더 명확하고 읽기 쉽게 개선하는 것이다.

#### 17.85.1 실제 UX 변경 내용

`_buildNoSelectionDetailPanel()`의 empty state 안내 문구를 다음 사용자 기준 문구로 개선했다.

- `그래프에서 단어를 선택하세요`
- `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`
- `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`

기존 아이콘 기반 empty state 구조와 `Center`, `Padding`, `Column` 기반 레이아웃은 유지했다. 안내 문구 읽기 폭을 안정화하기 위해 `_buildNoSelectionDetailPanel()` 내부에 `ConstrainedBox(maxWidth: 360)`만 추가했다.

#### 17.85.2 변경 범위

| 항목 | Phase 15-B 결과 |
| --- | --- |
| production UI 변경 | `WordExplorerScreen` detail pane 선택 없음 empty state 문구 개선 |
| 구현 위치 | `lib/ui/word_explorer_screen.dart`의 `_buildNoSelectionDetailPanel()` 내부 |
| 신규 테스트 | `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart` |
| 문서 갱신 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` |
| `_buildDetailPaneContextStrip()` 변경 | 없음 |
| `_readOnlyWorkspaceProjection` 변경 | 없음 |
| `HomeScreen`, `WordGraphScreen`, `WordInfoPanel` 변경 | 없음 |

#### 17.85.3 유지 금지선

| 항목 | Phase 15-B 결과 |
| --- | --- |
| `ExplorerWorkspace` shell mount | 없음 |
| route wiring / route registration 변경 | 없음 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 변경 | 없음 |
| owner/controller/coordinator migration | 없음 |
| Provider / Repository / Navigator / persistence authority migration | 없음 |
| DTO/model/public API 추가 | 없음 |
| projection result persistence/history/source-of-truth 사용 | 없음 |
| `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 | 없음 |
| route collapse | 없음 |
| canonical owner migration | 없음 |
| Level 3 production-visible consumer 승격 | 없음 |
| 새 repository read | 없음 |
| 새 DB query | 없음 |
| dependency 변경 | 없음 |
| 플랫폼 파일 변경 | 없음 |

#### 17.85.4 신규 테스트 조건

`test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart`는 source-level guardrail 방식으로 다음을 확인한다.

- `_buildNoSelectionDetailPanel()`이 존재하고 기존 detail pane 내부에서 호출되는지 확인한다.
- empty state에 Phase 15-B 사용자 기준 문구가 포함되는지 확인한다.
- 앱 화면 문구에 개발자 용어인 `context strip`이 들어가지 않는지 확인한다.
- `_buildNoSelectionDetailPanel()` 내부가 `Center`, `Padding`, `ConstrainedBox`, `Column`, 기존 아이콘 기반 read-only 표시 개선에 머무는지 확인한다.
- `_buildNoSelectionDetailPanel()` 내부에 `Navigator`, `MaterialPageRoute`, `Provider`, `Repository`, `WordRepository`, `SharedPreferences`, `ExplorerWorkspaceState`, `WordExplorerWorkspaceProjectionAdapter`, `_readOnlyWorkspaceProjection`, `workspaceProjection`, `projection.`, `detailTargetWordId`, `layoutPreset`, `origin`, `setState`, `async`, `await`, `Future<`, `routes:`, `onGenerateRoute`, `ExplorerWorkspace(` marker가 없는지 확인한다.
- 기존 context strip helper와 `HomeScreen -> WordExplorerScreen` 진입 구조가 유지되는지 확인한다.

#### 17.85.5 명령어 기반 테스트 결과

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 | 실제 결과 |
| --- | --- | --- | --- | --- |
| Phase 15-B 신규 empty state guardrail | empty state 문구 개선과 `_buildNoSelectionDetailPanel()` 범위 제한이 확인되어야 함 | 사용자 기준 문구 누락, 개발자 용어 노출, route/shell/owner/repository marker 유입 | `flutter test test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart --reporter expanded` | `+4: All tests passed!` |
| Phase 12-B context strip guardrail 유지 | context strip이 detail pane 안에 read-only로 존재하고 기존 owner state 기준을 유지해야 함 | context strip 위치 이탈, projection visible UI 입력 사용, route/owner/authority marker 유입 | `flutter test test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart --reporter expanded` | `+4: All tests passed!` |
| Phase 14-B context strip 가독성 유지 | 중심/선택 단어 표시와 선택 없음 fallback이 유지되어야 함 | context strip 표시 퇴행, 선택 없음 누락, 빈 segment 출력 | `flutter test test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart --reporter expanded` | `+5: All tests passed!` |
| composition boundary 유지 | production import tree가 preview/shell/route/owner 유입을 차단해야 함 | `ExplorerWorkspace` shell mount, route/default home 변경, owner migration marker 유입 | `flutter test test/ui/explorer_workspace_phase4e_composition_boundary_test.dart --reporter expanded` | `+6: All tests passed!` |
| 전체 테스트 | 전체 테스트가 통과해야 함 | 변경 범위 밖 회귀, source-level guardrail 실패, repository/data test 실패 | `flutter test --reporter compact` | `+237: All tests passed!` |

#### 17.85.6 클라이언트 UI 기반 테스트 체크리스트

CodeX는 UI 테스트를 수행하지 않는다. 아래 절차는 클라이언트가 production-visible UX diff를 확인하기 위한 기준이다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 선택 없음 empty state 안내 확인 | detail pane에 `그래프에서 단어를 선택하세요`, `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`, `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`가 표시되어야 함 | 문구가 이전 상태로 남거나 개발자 용어가 보임 | HomeScreen에서 사람이 식별 가능한 단어를 Explorer로 열고 그래프 노드를 선택하지 않은 detail pane을 확인한다. |
| 상단 context strip 유지 확인 | Phase 14-B의 중심/선택 단어 context strip이 유지되어야 함 | context strip이 사라지거나 raw id 중심 표시로 퇴행함 | 같은 화면에서 detail pane 상단 표시줄과 선택 없음 안내를 함께 확인한다. |
| 그래프 노드 선택 후 전환 확인 | 그래프 노드를 선택하면 empty state 안내가 사라지고 선택 단어 상세 정보가 표시되어야 함 | 선택 후에도 empty state가 남거나 상세 패널과 겹침 | 그래프에서 사람이 식별 가능한 다른 단어 노드를 선택한다. |
| 레이아웃 겹침 확인 | 안내 문구, 상단 표시줄, 상세 패널 영역이 겹치지 않아야 함 | 텍스트 잘림, 겹침, 빈 공간 과다 발생 | 일반 Windows Desktop 창 크기에서 detail pane을 확인한다. |

클라이언트 UI 기반 테스트는 성공 확인됨으로 기록한다. 클라이언트가 직접 확인한 실제 UI 문구는 다음과 같다.

```text
그래프에서 단어를 선택하세요
선택한 단어의 상세 정보가 이 영역에 표시됩니다.
중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.
```

#### 17.85.7 Phase 15-B 종료 전 확인 조건

Phase 15-B는 명령어 기반 테스트 기준으로 remaining red 없이 green 상태다. 클라이언트 UI 기반 테스트도 성공 확인됨으로 기록한다. 최종 커밋 조건은 문서 갱신 후 전체 `flutter test --reporter compact` 재실행과 변경 범위 확인까지 통과하는 것이다.

### 17.86 Phase 15-C termination audit

Phase 15-C는 구현, test fix, UX 변경, 후보 선정 단계가 아니다. Phase 15-A와 Phase 15-B 결과를 문서상 정리하고 Phase 15 전체 종료 가능 여부를 판단하는 docs/audit only 단계다.

#### 17.86.1 Phase 15-A 요약

Phase 15-A는 minimum production-visible UX diff candidate selection audit로 진행되었다. Phase 14-B 이후 추가 production-visible UX diff를 재개할 수 있는지 후보군을 비교했고, Phase 15-B 후보를 `WordExplorerScreen` detail pane 선택 없음 empty state 안내 가독성 개선 하나로 제한했다.

Phase 15-A에서 보류 또는 제외한 후보는 다음과 같다.

- context strip 추가 개선은 Phase 14-B 직후 같은 영역을 연속 수정하는 것이므로 보류했다.
- graph/history/navigation 표시 개선은 navigation/history owner, availability probe, repository probe와 결합될 위험이 있으므로 제외했다.
- `ExplorerWorkspace` shell mount 또는 route 전환은 명시적 금지선에 해당하므로 제외했다.

#### 17.86.2 Phase 15-B 요약

Phase 15-B는 Phase 15-A에서 선정한 단일 후보를 구현한 production-visible UX diff 단계다. 구현 범위는 `lib/ui/word_explorer_screen.dart`의 `_buildNoSelectionDetailPanel()` 내부 표시 개선으로 제한했다.

실제 UI 문구는 다음과 같다.

- `그래프에서 단어를 선택하세요`
- `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`
- `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`

Phase 15-B에서는 기존 아이콘 기반 empty state 구조와 `Center`, `Padding`, `Column` 기반 레이아웃을 유지했고, 안내 문구 읽기 폭 제한을 위해 `_buildNoSelectionDetailPanel()` 내부에 `ConstrainedBox(maxWidth: 360)`만 추가했다. 신규 guardrail test는 `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart`로 추가했다.

#### 17.86.3 Phase 15 금지선 유지 결과

| 항목 | Phase 15 결과 |
| --- | --- |
| `ExplorerWorkspace` shell mount | 없음 |
| route wiring / route registration 변경 | 없음 |
| `HomeScreen -> WordExplorerScreen` 진입 구조 변경 | 없음 |
| owner/controller/coordinator migration | 없음 |
| Provider / Repository / Navigator / persistence authority migration | 없음 |
| DTO/model/public API 추가 | 없음 |
| projection result persistence/history/source-of-truth 사용 | 없음 |
| `ExplorerWorkspaceState` projection visible UI source-of-truth 사용 | 없음 |
| route collapse | 없음 |
| canonical owner migration | 없음 |
| Level 3 production-visible consumer 승격 | 없음 |
| 새 repository read | 없음 |
| 새 DB query | 없음 |
| dependency 변경 | 없음 |
| 플랫폼 파일 변경 | 없음 |

#### 17.86.4 Phase 15 테스트와 UI 확인 결과

| 확인 항목 | 실제 결과 |
| --- | --- |
| Phase 15-B 신규 empty state guardrail | `+4: All tests passed!` |
| Phase 12-B context strip guardrail | `+4: All tests passed!` |
| Phase 14-B context strip readability | `+5: All tests passed!` |
| composition boundary | `+6: All tests passed!` |
| 전체 `flutter test --reporter compact` | `+237: All tests passed!` |
| 클라이언트 UI 기반 테스트 | 성공 확인됨 |

클라이언트 UI 기반 테스트는 CodeX가 수행한 것이 아니라 클라이언트가 직접 확인한 결과다. 확인된 UI 문구는 `그래프에서 단어를 선택하세요`, `선택한 단어의 상세 정보가 이 영역에 표시됩니다.`, `중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.`이다.

#### 17.86.5 Phase 15 종료 판단

Phase 15-A는 후보 선정 audit를 완료했고, Phase 15-B는 선정된 단일 후보를 production-visible UX diff로 구현했다. Phase 15-B 명령어 기반 테스트는 전체 `flutter test --reporter compact` 기준 `+237: All tests passed!`로 통과했고, 클라이언트 UI 기반 테스트도 성공 확인됨으로 기록되었다.

Phase 15 전체에서 금지선 위반은 확인되지 않았고, 문서 최신화도 완료되었다. 따라서 Phase 15는 종료 가능하다.

#### 17.86.6 Phase 15-C 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 기준 git 상태 확인 | `main == origin/main`, HEAD `ff43a45042b8014371339f766aa224de38fa34d3`, working tree clean, local branch `main` only 상태에서 시작해야 함 | 기준 커밋 또는 브랜치 상태 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` |
| 문서 반영 검색 | Phase 15-C, termination audit, Phase 15 종료, Phase 15-A/B, empty state, 테스트 결과, 클라이언트 UI 기반 테스트 성공 확인, 금지선 문구가 두 문서에서 검색되어야 함 | 종료 판단, 테스트 결과, UI 확인, 금지선 기록 누락 | `rg -n "Phase 15-C|termination audit|Phase 15 종료|Phase 15-A|Phase 15-B|empty state|선택 없음|그래프에서 단어를 선택하세요|선택한 단어의 상세 정보|상단 표시줄|flutter test|\\+237|클라이언트 UI 기반 테스트|성공 확인|ExplorerWorkspace shell|route wiring|owner/controller/coordinator|Provider / Repository / Navigator / persistence|DTO/model/public API|ExplorerWorkspaceState|visible UI source-of-truth|새 repository read|새 DB query" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| 변경 파일 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 파일만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, test code, dependency, 플랫폼 파일 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |
| 전체 flutter test 판단 | Phase 15-C는 docs/audit only 변경이며 lib/test/production code 변경이 없으므로 전체 flutter test를 실행하지 않아야 함 | 문서 외 변경이 있는데 전체 테스트를 생략함 | 변경 파일 범위 확인 후 실행 여부 판단 |

Phase 15-C는 docs/audit only 변경이며 lib/test/production code 변경이 없으므로 전체 flutter test는 실행하지 않는다. Phase 15-B에서 전체 flutter test --reporter compact는 +237: All tests passed!로 이미 확인되었다.

### 17.87 Phase 16-A ExplorerWorkspace production transition readiness audit

Phase 16-A는 구현, test fix, UX 변경, shell mount 단계가 아니다. 이번 단계는 `ExplorerWorkspace` production transition readiness를 문서상 점검하는 docs/audit only 단계다.

Phase 14-B와 Phase 15-B에서 작은 production-visible UX diff는 성공했지만, 이는 `ExplorerWorkspace` shell mount, route 전환, owner migration 승인으로 해석하지 않는다. Phase 16-A의 결론은 전환 구현 승인이 아니라 전환 논의를 시작하기 위한 준비 조건, 차단 요소, owner 경계 확인으로 제한한다.

#### 17.87.1 현재 production canonical route

현재 production canonical route는 계속 다음 구조로 유지한다.

```text
main.dart -> HomeScreen -> WordExplorerScreen
```

Phase 16-A에서는 이 구조를 변경하지 않는다. `HomeScreen -> WordExplorerScreen` 진입 구조, route wiring, route registration은 모두 현행 상태를 유지한다.

#### 17.87.2 현재 ExplorerWorkspace 해석

현재 `ExplorerWorkspace`는 production owner가 아니라 다음 성격으로 해석한다.

```text
preview / read-only / projection boundary
```

`ExplorerWorkspaceState`도 production visible UI source-of-truth가 아니라 projection/contract boundary로 해석한다. `ExplorerWorkspaceState`를 persistence, history, selection, detail target의 canonical source-of-truth로 승격하지 않는다.

#### 17.87.3 production transition 전 owner 경계

production transition 논의 전에 아래 owner 경계를 먼저 정리해야 한다.

| owner 경계 | 정리 필요성 | 섞일 경우 위험 |
| --- | --- | --- |
| route owner | production entry와 화면 전환 책임이 어디에 있는지 고정해야 함 | `HomeScreen -> WordExplorerScreen` canonical route와 `ExplorerWorkspace` route가 동시에 owner처럼 해석될 수 있음 |
| repository/read owner | 단어/그래프 read 시점과 책임을 분리해야 함 | repository read 시점과 owner가 중복되어 새 repository read 또는 새 DB query가 암묵적으로 추가될 수 있음 |
| selection owner | 선택 단어의 canonical owner를 분리해야 함 | `WordExplorerScreen`과 `ExplorerWorkspaceState`가 동시에 selection/source-of-truth처럼 해석될 위험이 있음 |
| graph center owner | 중심 단어 변경과 그래프 중심 owner를 분리해야 함 | graph center가 route state, projection state, repository read state 사이에서 중복될 수 있음 |
| detail target owner | detail pane 대상 단어의 owner를 분리해야 함 | detail target이 projection 결과와 `WordExplorerScreen` 내부 state 사이에서 어긋날 수 있음 |
| navigation history owner | 화면 route history와 explorer internal history를 분리해야 함 | Navigator route history와 Explorer internal history가 섞일 위험이 있음 |
| persistence authority | 저장 대상과 저장 시점을 명확히 해야 함 | projection state가 persistence/source-of-truth처럼 오해될 위험이 있음 |
| projection/source-of-truth boundary | projection snapshot과 canonical state를 분리해야 함 | rollback이 어려워지고 preview/read-only 경계가 production owner로 오해될 수 있음 |

이 경계가 정리되지 않은 상태에서 shell mount나 route 전환을 진행하면 rollback 범위가 넓어지고, route owner, selection owner, repository/read owner, persistence authority가 한 번에 이동한 것처럼 보일 위험이 있다.

#### 17.87.4 Phase 16-A 판단 질문

Phase 16-A 종료 시 아래 질문에 답할 수 있어야 한다.

1. `ExplorerWorkspace` production transition 논의를 계속해도 되는가?
2. 현재 전환을 막는 owner/blocker는 무엇인가?
3. 유지해야 할 guardrail은 무엇인가?
4. 향후 재정의가 필요한 guardrail은 무엇인가?
5. `HomeScreen -> WordExplorerScreen` canonical route를 언제까지 유지해야 하는가?
6. `ExplorerWorkspaceState`를 projection boundary로 계속 둘 것인가, source-of-truth 후보로 검토할 것인가?
7. Phase 16-B는 구현 후보가 아니라 추가 audit로 가야 하는가?

#### 17.87.5 Phase 16-B 후보

Phase 16-B의 1차 후보는 `production transition blocker inventory`로 기록한다.

이 후보는 구현 단계가 아니라 추가 audit 단계다. Phase 16-B가 진행된다면 production transition을 막는 route owner, repository/read owner, selection owner, graph center owner, detail target owner, navigation history owner, persistence authority, projection/source-of-truth boundary의 blocker 목록을 먼저 정리해야 한다.

#### 17.87.6 Phase 16-A 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 기준 git 상태 확인 | `main == origin/main`, HEAD `f54a446ec6ccb581e5143ce5e44819181e47b080`, working tree clean, local branch `main` only 상태에서 시작해야 함 | 기준 커밋 또는 브랜치 상태 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` |
| 변경 파일 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 파일만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, test code, dependency, 플랫폼 파일 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` |
| 문서 반영 검색 | Phase 16-A, production transition readiness audit, canonical route, preview/read-only/projection boundary, owner 경계, Phase 16-B 후보가 두 문서에서 확인되어야 함 | readiness 목적, owner 경계, blocker inventory 기록 누락 | `rg -n "Phase 16-A|production transition readiness audit|transition readiness|HomeScreen -> WordExplorerScreen|canonical route|preview/read-only/projection boundary|ExplorerWorkspaceState|source-of-truth|route owner|repository/read owner|selection owner|graph center owner|detail target owner|navigation history owner|persistence authority|production transition blocker inventory|shell mount|route wiring|owner migration" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| production route marker 유지 확인 | `main.dart -> HomeScreen -> WordExplorerScreen` canonical route가 문서상 유지되어야 함 | canonical route 변경 또는 route transition 승인처럼 기록됨 | 문서 반영 검색 결과에서 canonical route 유지 문구 확인 |
| ExplorerWorkspace shell mount 없음 확인 | `ExplorerWorkspace` shell mount가 승인되지 않았다고 기록되어야 함 | shell mount 승인 또는 production owner 승격처럼 기록됨 | 문서 반영 검색 결과에서 shell mount 금지 문구 확인 |
| owner/repository/Navigator/persistence migration marker 없음 확인 | owner migration, repository/read owner 이동, Navigator history owner 이동, persistence authority migration이 승인되지 않아야 함 | owner 또는 authority migration이 승인된 것처럼 기록됨 | 문서 반영 검색 결과에서 각 owner 경계와 금지선 유지 문구 확인 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |
| 전체 flutter test 실행 여부 판단 | Phase 16-A는 docs/audit only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다 | 문서 외 변경이 있는데 전체 테스트를 생략함 | 변경 파일 범위 확인 후 실행 여부 판단 |

Phase 16-A는 docs/audit only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다. 변경 파일 범위가 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.88 Phase 16-B ExplorerWorkspace production transition blocker inventory

Phase 16-B는 구현, test fix, UX 변경, shell mount 단계가 아니다. 이번 단계는 Phase 16-A에서 제안한 `production transition blocker inventory`를 문서상 구체화하는 docs/audit only 단계다.

Phase 16-B의 목적은 `ExplorerWorkspace` production transition을 승인하는 것이 아니라, 전환을 막는 blocker를 owner 경계별로 분류하는 것이다. Phase 16-B 종료 후에도 바로 production transition 구현으로 가지 않는 것을 기본값으로 둔다.

현재 production canonical route는 계속 `main.dart -> HomeScreen -> WordExplorerScreen`로 유지한다. `ExplorerWorkspace`는 production owner가 아니라 preview/read-only/projection boundary로 유지하며, `ExplorerWorkspaceState`는 production visible UI source-of-truth로 승격하지 않는다.

#### 17.88.1 blocker inventory

| blocker | 현재 owner/상태 | 전환 시 충돌 가능성 | 해소 전 금지 작업 | 해소 후 가능한 다음 단계 | 확인 위치 |
| --- | --- | --- | --- | --- | --- |
| route owner blocker | production canonical route는 `main.dart -> HomeScreen -> WordExplorerScreen`이며, `HomeScreen`이 `Navigator.push`와 `MaterialPageRoute`로 `WordExplorerScreen` 진입을 소유한다. | `ExplorerWorkspace` route 또는 shell을 production에 붙이면 기존 route owner와 새 shell owner가 이중화될 수 있다. | shell mount, route wiring, route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경을 금지한다. | route owner를 문서상 단일화한 뒤 제한된 route transition 설계 audit을 진행할 수 있다. | `lib/main.dart`, `lib/ui/home_screen.dart`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`, Phase 16-A 기록 |
| repository/read owner blocker | `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen` 등 기존 화면이 각자의 repository read 책임을 보유한다. `ExplorerWorkspace` preview composition은 repository owner가 아니다. | `ExplorerWorkspace`가 repository/read owner로 해석되면 새 repository read 또는 새 DB query가 암묵적으로 추가될 위험이 있다. | repository/read owner 이동, 새 repository read, 새 DB query, Provider / Repository authority migration을 금지한다. | read owner별 책임과 호출 시점을 분리한 뒤 repository/read owner migration order design을 검토할 수 있다. | `lib/ui/home_screen.dart`, `lib/ui/word_explorer_screen.dart`, `lib/ui/word_graph_screen.dart`, `lib/ui/word_detail_screen.dart`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` |
| selection owner blocker | `WordExplorerScreen`이 `_selectedWordId`, `_selectedWordDisplayItem`을 보유하며 detail pane 선택 상태를 관리한다. | `ExplorerWorkspaceState`가 selection source-of-truth처럼 해석되면 selection owner가 `WordExplorerScreen`과 중복된다. | `ExplorerWorkspaceState`를 production visible UI source-of-truth로 사용하거나 selection owner를 이동하는 변경을 금지한다. | selection owner를 `WordExplorerScreen` 유지, projection 유지, 또는 별도 owner 이전 중 하나로 설계한 뒤 제한된 구현 후보를 낼 수 있다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`, `test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart` |
| graph center owner blocker | `WordExplorerScreen`은 `_centerWordId`와 `_centerDisplaySeed`를 보유하고, `WordGraphScreen`은 `centerWordId` seed와 graph internal center 상태를 보유한다. | center 변경 authority가 projection state, route state, graph internal state 사이에서 섞일 수 있다. | center owner migration, route state 기반 center 승격, projection 기반 center source-of-truth 사용을 금지한다. | graph center owner와 selection owner의 순서를 분리한 뒤 center transition path를 문서화할 수 있다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/word_graph_screen.dart`, `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart` |
| detail target owner blocker | detail pane target은 `WordExplorerScreen`의 selected display item 기준으로 동작하고, detail route는 별도 `WordDetailScreen`에서 reread한다. | `ExplorerWorkspaceState.detailTargetWordId`를 canonical detail target으로 승격하면 detail pane과 detail route의 read context가 섞일 수 있다. | detail target owner migration, `ExplorerWorkspaceState.detailTargetWordId` canonical 승격, detail route read context 변경을 금지한다. | detail pane target과 detail route reread 정책을 분리한 뒤 detail target owner 설계를 진행할 수 있다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/word_detail_screen.dart`, `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart` |
| navigation history owner blocker | `WordExplorerScreen`의 Explorer internal history와 Flutter `Navigator` route history는 별도다. | 두 history를 통합하거나 서로 대체하면 route history, explorer history, snapshot restore 의미가 한 번에 바뀔 수 있다. | navigation history owner 이동, Navigator history 대체, Explorer internal history를 route history로 승격하는 변경을 금지한다. | history owner별 책임과 rollback 단위를 정리한 뒤 제한된 navigation history audit을 진행할 수 있다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/word_navigation_history.dart`, `lib/ui/home_screen.dart`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` |
| persistence authority blocker | 현재 projection/history snapshot은 production persistence로 사용하지 않는다. `ExplorerWorkspaceState`는 projection/contract boundary다. | projection state를 저장 대상으로 해석하면 source-of-truth가 persistence 쪽으로 바뀔 수 있다. | projection persistence, history persistence, snapshot restore source-of-truth 사용, persistence authority migration을 금지한다. | persistence 대상과 restore authority를 별도 설계한 뒤 persistence guardrail 후보를 정리할 수 있다. | `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `lib/ui/word_explorer_screen.dart`, `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`, Phase 16-A 기록 |
| projection/source-of-truth blocker | `ExplorerWorkspaceState`는 `WordExplorerScreen` owner state를 읽은 projection/contract boundary이며 production visible UI source-of-truth가 아니다. | projection을 canonical owner로 승격하면 preview/read-only/projection boundary가 깨지고 selection, detail target, center source-of-truth가 중복될 수 있다. | projection을 canonical owner로 승격하거나 `ExplorerWorkspaceState`를 production visible UI source-of-truth로 사용하는 변경을 금지한다. | source-of-truth 후보와 projection 유지 범위를 문서상 확정한 뒤 guardrail 재정의 여부를 판단할 수 있다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` |
| guardrail redefinition blocker | 기존 composition boundary test는 `ExplorerWorkspace` preview-only/projection boundary를 보호한다. | production transition을 진행하려면 기존 guardrail 중 유지할 것과 재정의할 것을 먼저 정해야 하며, 이를 건너뛰면 구현이 테스트 의도와 충돌한다. | 기존 guardrail을 깨는 구현, 신규 test 추가 없는 guardrail 의미 변경, 기존 test 수정으로 금지선을 약화하는 변경을 금지한다. | 유지 guardrail과 재정의 guardrail을 분리한 뒤 필요한 source-level guardrail test 후보를 설계할 수 있다. | `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`, `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`, `test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart`, `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart` |
| rollback boundary blocker | route, repository, selection, history, persistence owner가 모두 분리되어 있으며 이번 단계에서는 어떤 owner도 이동하지 않는다. | 여러 owner를 한 번에 이동하면 rollback 범위가 커지고 어떤 변경이 문제를 만들었는지 분리하기 어렵다. | 다중 owner 동시 이동, route collapse, canonical owner migration, Level 3 production-visible consumer 승격을 금지한다. | owner migration 순서를 쪼갠 뒤 rollback 가능한 최소 단위의 transition path sequencing audit을 진행할 수 있다. | Phase 16-A 기록, `docs/logs/CHANGELOG.md`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` |

#### 17.88.2 blocker 우선순위

Phase 16-B의 blocker 우선순위는 아래 순서로 둔다.

1. route owner
2. projection/source-of-truth
3. selection owner
4. graph center owner
5. detail target owner
6. navigation history owner
7. repository/read owner
8. persistence authority
9. guardrail redefinition
10. rollback boundary

이 순서는 production entry와 source-of-truth 해석이 먼저 고정되어야 나머지 owner 이동 여부를 판단할 수 있기 때문이다. rollback boundary는 전체 전환 순서를 쪼개는 기준으로 유지하되, 앞선 owner blocker가 정리된 뒤 구체화한다.

#### 17.88.3 Phase 16-C 후보

Phase 16-C의 1차 후보는 `Phase 16-C transition path sequencing audit`로 제안한다. 보조 후보는 `Phase 16-C owner migration order design`이다.

Phase 16-C도 바로 구현 단계가 아니라 문서상 순서 설계 단계로 둔다. Phase 16-C에서는 route owner, projection/source-of-truth, selection owner를 어떤 순서로 해소할지 정리하고, shell mount 또는 route wiring을 실제로 변경하지 않는다.

#### 17.88.4 Phase 16-B 종료 판단 질문

Phase 16-B 종료 시 아래 질문에 답할 수 있어야 한다.

1. ExplorerWorkspace production transition을 막는 blocker는 무엇인가?
2. 어떤 blocker가 가장 먼저 해소되어야 하는가?
3. 어떤 blocker는 문서 정리만으로 해소 가능한가?
4. 어떤 blocker는 guardrail test가 필요한가?
5. 어떤 blocker는 실제 구현 전 별도 설계 phase가 필요한가?
6. Phase 16-C는 계속 audit이어야 하는가, 제한적 설계 문서화로 넘어가도 되는가?
7. 아직 production shell mount가 금지되어야 하는가?

#### 17.88.5 Phase 16-B 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 기준 git 상태 확인 | HEAD `04e795f95d22adae15eafd52fb677b8dfee4923d`, latest commit `docs: ExplorerWorkspace Phase 16-A 전환 준비 audit 정리`, `main == origin/main`, working tree clean, local branch `main` only 상태에서 시작해야 함 | 기준 커밋 또는 브랜치 상태 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` |
| 변경 파일 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 파일만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, test code, dependency, 플랫폼 파일 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` |
| blocker inventory 문서 반영 검색 | Phase 16-B와 필수 blocker 명칭이 두 문서에서 확인되어야 함 | blocker 누락 또는 docs/audit only 성격 누락 | `rg -n "Phase 16-B|production transition blocker inventory|route owner blocker|repository/read owner blocker|selection owner blocker|graph center owner blocker|detail target owner blocker|navigation history owner blocker|persistence authority blocker|projection/source-of-truth blocker|guardrail redefinition blocker|rollback boundary blocker" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| canonical route 유지 문구 확인 | `HomeScreen -> WordExplorerScreen` canonical route 유지가 명시되어야 함 | route 전환 승인처럼 해석되는 문구 | 문서 반영 검색 결과에서 `HomeScreen -> WordExplorerScreen`, `canonical route` 확인 |
| `ExplorerWorkspace` preview/read-only/projection boundary 유지 문구 확인 | `ExplorerWorkspace`가 preview/read-only/projection boundary로 유지된다고 기록되어야 함 | production owner 또는 shell로 승격된 것처럼 기록됨 | 문서 반영 검색 결과에서 `preview/read-only/projection boundary` 확인 |
| `ExplorerWorkspaceState` source-of-truth 미승격 문구 확인 | `ExplorerWorkspaceState`를 production visible UI source-of-truth로 승격하지 않는다고 기록되어야 함 | projection state를 canonical owner처럼 기록함 | 문서 반영 검색 결과에서 `ExplorerWorkspaceState`, `source-of-truth` 확인 |
| shell mount / route wiring / owner migration 금지 문구 확인 | shell mount, route wiring, owner migration 금지가 유지되어야 함 | 금지 항목 누락 또는 구현 허용처럼 기록됨 | 문서 반영 검색 결과에서 `shell mount`, `route wiring`, `owner migration` 확인 |
| Phase 16-C 후보 문구 확인 | `transition path sequencing audit` 또는 `owner migration order design` 계열 후보가 기록되어야 함 | Phase 16-C가 바로 구현 단계처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 16-C`, `transition path sequencing audit`, `owner migration order design` 확인 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |
| 전체 flutter test 실행 여부 판단 | Phase 16-B는 docs/audit only이며 `lib/`, `test`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다 | 문서 외 변경이 있는데 전체 테스트를 생략함 | 변경 파일 범위 확인 후 실행 여부 판단 |

Phase 16-B는 docs/audit only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다. 변경 파일 범위가 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.89 Phase 16-C ExplorerWorkspace transition path sequencing audit

Phase 16-C는 구현, test fix, UX 변경, shell mount 단계가 아니다. 이번 단계는 Phase 16-B에서 정리한 blocker inventory를 기반으로 production transition 경로의 처리 순서를 문서상 정리하는 docs/audit only 단계다.

Phase 16-C의 목적은 `ExplorerWorkspace` production transition을 승인하는 것이 아니라, 어떤 blocker를 어떤 순서로 다뤄야 하는지 sequencing하는 것이다. Phase 16-C 종료 후에도 바로 production transition 구현으로 가지 않는 것을 기본값으로 둔다.

현재 production canonical route는 계속 `main.dart -> HomeScreen -> WordExplorerScreen`로 유지한다. `ExplorerWorkspace`는 production shell이나 owner가 아니라 preview/read-only/projection boundary로 유지하며, `ExplorerWorkspaceState`는 production visible UI source-of-truth로 승격하지 않는다.

#### 17.89.1 transition sequencing

| 순서 | sequencing 항목 | 선행 조건 | 이 단계에서 판단할 것 | 아직 금지되는 작업 | 다음 단계 후보 | 확인 위치 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | route owner sequencing | 현재 production canonical route가 `main.dart -> HomeScreen -> WordExplorerScreen`이며 `HomeScreen`의 `Navigator.push`와 `MaterialPageRoute`가 `WordExplorerScreen` 진입을 소유한다는 사실을 유지한다. | `ExplorerWorkspace` shell 또는 route가 production entry owner로 해석되지 않도록 route owner boundary를 어디에 고정할지 판단한다. | shell mount, route wiring, route registration 변경, `HomeScreen -> WordExplorerScreen` 진입 구조 변경을 금지한다. | `Phase 16-D route owner boundary design`으로 route owner boundary를 문서상 고정한다. | `lib/main.dart`, `lib/ui/home_screen.dart`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`, Phase 16-B blocker inventory |
| 2 | projection/source-of-truth sequencing | route owner boundary가 먼저 문서상 고정되어야 한다. `ExplorerWorkspaceState`는 현재 projection/contract boundary이며 production visible UI source-of-truth가 아니다. | projection state를 canonical owner로 승격할지 여부를 판단하기 전까지 projection과 source-of-truth를 어떻게 분리할지 판단한다. | `ExplorerWorkspaceState`를 production visible UI source-of-truth로 사용하거나 projection state를 canonical owner로 사용하는 변경을 금지한다. | source-of-truth boundary design과 projection guardrail 재정의 후보를 분리한다. | `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart`, `lib/ui/word_explorer_screen.dart`, Phase 16-B blocker inventory |
| 3 | selection owner sequencing | projection/source-of-truth boundary가 먼저 분리되어야 한다. 현재 selection owner는 `WordExplorerScreen`의 `_selectedWordId`, `_selectedWordDisplayItem`과 연결되어 있다. | projection state가 selection owner처럼 해석되어 owner가 중복되지 않도록 selection owner boundary를 어디에 둘지 판단한다. | selection owner migration, projection 기반 selection source-of-truth 사용, `ExplorerWorkspaceState` selection owner 승격을 금지한다. | selection owner boundary design 또는 guardrail test 후보로 넘긴다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`, `test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart` |
| 4 | graph center owner sequencing | selection owner가 먼저 정리되어야 한다. graph center는 `WordExplorerScreen`의 `_centerWordId`와 `WordGraphScreen`의 internal center 상태 사이에 분산된 상태로 해석될 수 있다. | center 변경 authority를 projection, route, graph internal state 사이에서 어떻게 분리할지 판단한다. | center owner migration, route state 기반 center 승격, projection 기반 center source-of-truth 사용을 금지한다. | graph center owner boundary design과 center transition guardrail 후보를 검토한다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/word_graph_screen.dart`, `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart`, Phase 16-B blocker inventory |
| 5 | detail target owner sequencing | selection owner와 graph center owner의 해석이 먼저 분리되어야 한다. detail pane target은 `WordExplorerScreen`의 selected display item 기준으로 동작하고 detail route는 `WordDetailScreen`에서 별도 reread한다. | detail pane target과 detail route read context를 분리한 뒤 projection state 승격 여부를 판단한다. | detail target owner migration, `ExplorerWorkspaceState.detailTargetWordId` canonical 승격, detail route read context 변경을 금지한다. | detail target owner boundary design과 detail route reread 정책 검토로 넘긴다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/word_detail_screen.dart`, `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, Phase 16-B blocker inventory |
| 6 | navigation history owner sequencing | center/detail target owner가 먼저 정리되어야 한다. Explorer internal history와 Flutter `Navigator` route history는 별도다. | history owner를 통합할지, 대체할지, 계속 분리할지 판단하기 위한 boundary를 문서화한다. | navigation history owner migration, Navigator history 대체, Explorer internal history를 route history로 승격하는 변경을 금지한다. | navigation history owner boundary design과 rollback 단위 검토로 넘긴다. | `lib/ui/word_explorer_screen.dart`, `lib/ui/home_screen.dart`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`, Phase 16-B blocker inventory |
| 7 | repository/read owner sequencing | route, selection, center, detail, history boundary가 먼저 정리되어야 한다. 기존 화면들은 각자의 `WordRepository` read 책임을 보유한다. | repository/read owner 이동이 필요한지, 필요한 경우 read 시점과 owner를 어떤 phase로 분리할지 판단한다. | repository/read owner migration, 새 repository read, 새 DB query, Provider / Repository authority migration을 금지한다. | repository/read owner migration order design을 별도 implementation 전 design phase로 둔다. | `lib/ui/home_screen.dart`, `lib/ui/word_explorer_screen.dart`, `lib/ui/word_graph_screen.dart`, `lib/ui/word_detail_screen.dart`, Phase 16-B blocker inventory |
| 8 | persistence authority sequencing | route, source-of-truth, history boundary가 먼저 정리되어야 한다. 현재 projection/history snapshot은 production persistence source-of-truth가 아니다. | persistence 대상과 restore authority를 projection/history/source-of-truth 사이에서 어떻게 분리할지 판단한다. | projection result persistence, history snapshot source-of-truth 사용, persistence authority migration을 금지한다. | persistence authority design, persistence guardrail test 후보, 제한된 implementation phase 후보를 분리한다. | `lib/ui/explorer_workspace/explorer_workspace_contract.dart`, `lib/ui/word_explorer_screen.dart`, Phase 16-A/16-B 기록 |
| 9 | guardrail redefinition sequencing | 앞선 owner boundary별로 유지할 금지선과 바뀔 가능성이 있는 금지선을 먼저 구분해야 한다. 기존 guardrail은 preview-only/projection boundary를 보호한다. | 기존 guardrail 중 유지, 재정의, 신규 추가 대상이 무엇인지 목록화한다. | 신규 test 파일 추가, 기존 test 수정, guardrail 의미를 약화하는 production 구현을 금지한다. | guardrail redefinition design과 source-level guardrail test 후보를 별도 phase로 넘긴다. | `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`, `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`, `test/ui/word_explorer_screen_phase14b_context_strip_readability_test.dart`, `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart` |
| 10 | rollback boundary sequencing | 모든 sequencing 항목에서 다중 owner를 한 번에 이동하지 않는 원칙이 유지되어야 한다. | 각 후속 phase가 rollback 가능한 최소 단위인지, 어떤 owner boundary를 건드리는지 판단한다. | 다중 owner 동시 이동, route collapse, canonical owner migration, Level 3 production-visible consumer 승격을 금지한다. | owner migration order design 또는 rollback boundary design을 후속 문서 단계로 둔다. | Phase 16-A 기록, Phase 16-B blocker inventory, `docs/logs/CHANGELOG.md`, `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart` |

이 순서는 route owner를 먼저 고정한 뒤 projection/source-of-truth 해석을 분리하고, selection, graph center, detail target, navigation history를 순차적으로 정리한 다음 repository/read와 persistence authority를 다루는 구조다. repository/read owner를 먼저 옮기면 새 repository read 또는 새 DB query가 암묵적으로 추가될 위험이 있으므로 후순위로 둔다. rollback boundary는 마지막 항목이지만 모든 후속 phase의 최소 변경 단위 판단 기준으로 유지한다.

#### 17.89.2 단계 유형 분류

| sequencing 항목 | 단계 유형 | 판단 |
| --- | --- | --- |
| route owner sequencing | design documentation required | production canonical route를 유지한 채 route owner boundary를 문서상 고정해야 하므로 구현보다 설계 문서화가 먼저다. |
| projection/source-of-truth sequencing | design documentation required + guardrail test required | `ExplorerWorkspaceState`의 projection/contract boundary와 production visible UI source-of-truth 미승격을 문서화하고, 후속 phase에서 guardrail 재정의 필요성을 판단해야 한다. |
| selection owner sequencing | design documentation required + guardrail test required | `_selectedWordId`, `_selectedWordDisplayItem` owner와 projection state 해석이 중복되지 않도록 boundary design과 guardrail 후보가 필요하다. |
| graph center owner sequencing | design documentation required + guardrail test required + implementation phase required | center authority가 `WordExplorerScreen`, `WordGraphScreen`, projection 사이에 걸쳐 있어 설계와 guardrail 후 별도 구현 phase가 필요하다. |
| detail target owner sequencing | design documentation required + guardrail test required + implementation phase required | detail pane target과 `WordDetailScreen` reread context가 분리되어야 하므로 설계와 guardrail 후 제한된 구현 phase가 필요하다. |
| navigation history owner sequencing | design documentation required + guardrail test required + implementation phase required | Explorer internal history와 Navigator route history가 별도이므로 history owner design, guardrail, 구현 phase를 분리해야 한다. |
| repository/read owner sequencing | design documentation required + implementation phase required | repository/read owner 이동은 새 repository read 또는 새 DB query 위험이 있어 구현 전 별도 design phase가 필요하다. |
| persistence authority sequencing | design documentation required + guardrail test required + implementation phase required | projection/history snapshot을 persistence source-of-truth처럼 쓰지 않도록 설계, guardrail, 구현 phase를 분리해야 한다. |
| guardrail redefinition sequencing | audit only + design documentation required + guardrail test required | Phase 16-C에서는 목록화까지만 수행하고, 실제 test 수정은 후속 guardrail phase에서 다룬다. |
| rollback boundary sequencing | audit only + design documentation required | 다중 owner를 한 번에 이동하지 않는 원칙을 audit 기준으로 고정하고, 후속 설계 문서에서 최소 rollback 단위를 판단한다. |

#### 17.89.3 Phase 16-D 후보

Phase 16-D의 1차 후보는 `Phase 16-D route owner boundary design`으로 둔다. 이 후보는 production shell mount나 route wiring 변경이 아니라, 현재 `main.dart -> HomeScreen -> WordExplorerScreen` canonical route를 유지한 상태에서 route owner boundary를 문서상 고정하는 design 단계다.

대안 후보는 `Phase 16-D owner migration order design`이다. 이 대안도 바로 구현 단계가 아니라 route owner, projection/source-of-truth, selection owner, graph center owner, detail target owner, navigation history owner, repository/read owner, persistence authority의 이동 순서를 문서상 설계하는 단계로 제한한다.

#### 17.89.4 Phase 16-C 종료 판단 질문

Phase 16-C 종료 시 아래 질문에 답할 수 있어야 한다.

1. production transition blocker들은 어떤 순서로 다뤄야 하는가?
2. 가장 먼저 다뤄야 할 owner boundary는 무엇인가?
3. 어떤 항목은 audit only로 충분한가?
4. 어떤 항목은 design documentation이 필요한가?
5. 어떤 항목은 guardrail test가 필요한가?
6. 어떤 항목은 실제 implementation phase가 필요한가?
7. Phase 16-D는 어떤 주제로 시작해야 하는가?
8. 아직 production shell mount가 금지되어야 하는가?

#### 17.89.5 Phase 16-C 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 기준 git 상태 확인 | HEAD `f050ed346a2bb01587c5e8dc57f7bf0d199fc285`, latest commit `docs: ExplorerWorkspace Phase 16-B 전환 blocker inventory 정리`, `main == origin/main`, working tree clean, local branch `main` only 상태에서 시작해야 함 | 기준 커밋, 브랜치, working tree 상태 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` |
| 변경 파일 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 파일만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, test code, dependency, 플랫폼 파일 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` |
| transition sequencing 문서 반영 검색 | Phase 16-C, transition path sequencing audit, sequencing 항목, 금지선이 두 문서에서 확인되어야 함 | sequencing 항목 누락 또는 docs/audit only 성격 누락 | `rg -n "Phase 16-C|transition path sequencing audit|route owner sequencing|projection/source-of-truth sequencing|selection owner sequencing|graph center owner sequencing|detail target owner sequencing|navigation history owner sequencing|repository/read owner sequencing|persistence authority sequencing|guardrail redefinition sequencing|rollback boundary sequencing" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| sequencing 항목 10개 반영 확인 | route owner부터 rollback boundary까지 10개 항목이 모두 기록되어야 함 | 항목 누락, 순서 변경, blocker 의미 축소 | transition sequencing 표에서 10개 항목 확인 |
| 단계 유형 분류 반영 확인 | `audit only`, `design documentation required`, `guardrail test required`, `implementation phase required`가 기록되어야 함 | 유형 누락 또는 구현 승인처럼 해석되는 문구 | 문서 반영 검색 결과와 단계 유형 분류 표 확인 |
| canonical route 유지 문구 확인 | `HomeScreen -> WordExplorerScreen` canonical route 유지가 명시되어야 함 | route 전환 승인처럼 해석되는 문구 | 문서 반영 검색 결과에서 `HomeScreen -> WordExplorerScreen`, `canonical route` 확인 |
| `ExplorerWorkspace` preview/read-only/projection boundary 유지 문구 확인 | `ExplorerWorkspace`가 preview/read-only/projection boundary로 유지된다고 기록되어야 함 | production owner 또는 shell로 승격된 것처럼 기록됨 | 문서 반영 검색 결과에서 `preview/read-only/projection boundary` 확인 |
| `ExplorerWorkspaceState` source-of-truth 미승격 문구 확인 | `ExplorerWorkspaceState`를 production visible UI source-of-truth로 승격하지 않는다고 기록되어야 함 | projection state를 canonical owner처럼 기록함 | 문서 반영 검색 결과에서 `ExplorerWorkspaceState`, `source-of-truth` 확인 |
| shell mount / route wiring / owner migration 금지 문구 확인 | shell mount, route wiring, owner migration 금지가 유지되어야 함 | 금지 항목 누락 또는 구현 허용처럼 기록됨 | 문서 반영 검색 결과에서 `shell mount`, `route wiring`, `owner migration` 확인 |
| Phase 16-D 후보 문구 확인 | `Phase 16-D route owner boundary design`과 `Phase 16-D owner migration order design` 후보가 기록되어야 함 | Phase 16-D가 바로 구현 단계처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 16-D`, `route owner boundary design`, `owner migration order design` 확인 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |
| 전체 flutter test 실행 여부 판단 | Phase 16-C는 docs/audit only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다 | 문서 외 변경이 있는데 전체 테스트를 생략함 | 변경 파일 범위 확인 후 실행 여부 판단 |

Phase 16-C는 docs/audit only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다. 변경 파일 범위가 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.90 Phase 16-D ExplorerWorkspace route owner boundary design

Phase 16-D는 현재 production canonical route인 `main.dart -> HomeScreen -> WordExplorerScreen`를 유지한 상태에서, 이후 ExplorerWorkspace transition을 논의하기 위한 route owner boundary를 문서상 정의하는 docs/design only 단계다.

이번 Phase는 route wiring 구현 단계가 아니다. ExplorerWorkspace shell mount 단계가 아니며, `HomeScreen -> WordExplorerScreen` 진입 구조 변경 단계도 아니다. owner/controller/coordinator migration을 수행하지 않고, `ExplorerWorkspaceState`를 route state source-of-truth로 승격하지 않는다.

#### 17.90.1 route owner boundary

| 경계 | Phase 16-D 해석 | 유지 기준 |
| --- | --- | --- |
| `MaterialApp` / `main.dart` | 앱 최상위 entry configuration이다. 현재 `home`은 `HomeScreen`이다. | Phase 16-D에서는 변경하지 않는다. |
| `HomeScreen` | 현재 production route entry owner에 가장 가까운 위치다. Explorer 진입 여부와 `WordExplorerScreen` push를 결정하는 위치다. | 현재 route owner boundary로 문서상 해석하되, 구현 변경은 하지 않는다. |
| `Navigator` / `MaterialPageRoute` | 현재 route transition mechanism이다. | mechanism 변경과 Navigator authority migration은 수행하지 않는다. |
| `WordExplorerScreen` | 현재 Explorer production route target이다. `initialWordId`를 받아 Explorer split view를 구성하는 현재 production 대상이다. | 현재 `WordRepository`, center, selection, detail target, navigation history를 직접 보유하는 production visible owner로 유지한다. |
| `ExplorerWorkspace` | 현재 route owner가 아니며 production shell도 아니다. | preview / read-only / projection boundary로만 유지한다. |
| `ExplorerWorkspaceState` | route state source-of-truth가 아니며 production visible UI source-of-truth도 아니다. | projection / contract state로만 해석한다. |

이 boundary는 현재 production entry와 ExplorerWorkspace preview boundary를 동시에 보존하기 위한 문서상 guardrail이다. `ExplorerWorkspace`가 production shell 또는 route owner로 승격되었다는 의미가 아니며, `ExplorerWorkspaceState`를 source-of-truth로 사용하는 승인도 아니다.

#### 17.90.2 유지 금지선

Phase 16-D에서는 아래 작업을 금지선으로 유지한다.

- ExplorerWorkspace shell mount 금지
- route wiring / route registration 변경 금지
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경 금지
- route collapse 금지
- canonical owner migration 금지
- Navigator authority migration 금지
- Provider / Repository / persistence authority migration 금지
- `ExplorerWorkspaceState` source-of-truth 승격 금지
- projection result persistence/history/source-of-truth usage 금지
- 신규 repository read 금지
- 신규 DB query 금지
- 신규 DTO/model/public API 추가 금지
- `lib/` 변경 금지
- `test/` 변경 금지
- dependency 변경 금지

#### 17.90.3 Phase 16-D 결론

Phase 16-D는 route owner boundary를 문서상 고정하는 단계로 종료할 수 있다.
이 단계만으로 ExplorerWorkspace transition 구현은 승인되지 않는다.
후속 phase에서는 projection/source-of-truth boundary 또는 route owner guardrail을 별도로 다룬 뒤에만 구현 가능성을 논의할 수 있다.

#### 17.90.4 Phase 16-E 후보

Phase 16-E의 1차 후보는 `Phase 16-E projection/source-of-truth boundary design`이다.

대안 후보는 `Phase 16-E route owner guardrail design`이다.

Phase 16-D 직후에는 `ExplorerWorkspaceState`가 route state source-of-truth로 오해되는 위험을 먼저 줄이는 것이 중요하므로 Phase 16-E의 1차 후보는 projection/source-of-truth boundary design이 자연스럽다.

#### 17.90.5 Phase 16-D 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 기준 git 상태 확인 | HEAD `d1e7230fc50efedf47ce3e2e3ca44a59cff558f3`, latest commit `docs: ExplorerWorkspace Phase 16-C 전환 순서 audit 정리`, `main == origin/main`, working tree clean, local branch `main` only 상태에서 시작해야 함 | 기준 커밋, 브랜치, working tree 상태 불일치 | `git status --short --branch`, `git branch --list`, `git rev-parse HEAD`, `git rev-parse origin/main`, `git log -1 --oneline` |
| 변경 파일 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 두 파일만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-only` |
| 금지 경로 변경 없음 확인 | `lib`, `test`, 플랫폼 경로, `pubspec.yaml`, `pubspec.lock` 변경이 없어야 함 | production code, test code, dependency, 플랫폼 파일 변경 발생 | `git diff --name-only -- lib test android ios macos windows linux web pubspec.yaml pubspec.lock` |
| route owner boundary 문서 반영 검색 | Phase 16-D, route owner boundary, route target, 금지선이 두 문서에서 확인되어야 함 | boundary 누락 또는 docs/design only 성격 누락 | `rg -n "Phase 16-D|route owner boundary|HomeScreen -> WordExplorerScreen|production route entry owner|Explorer production route target|preview / read-only / projection boundary|preview/read-only/projection boundary|ExplorerWorkspaceState|source-of-truth|shell mount|route wiring|owner migration" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| canonical route 유지 문구 확인 | `HomeScreen -> WordExplorerScreen` canonical route 유지가 명시되어야 함 | route 전환 승인처럼 해석되는 문구 | 문서 반영 검색 결과에서 `HomeScreen -> WordExplorerScreen`, `canonical route` 확인 |
| `ExplorerWorkspace` preview/read-only/projection boundary 유지 문구 확인 | `ExplorerWorkspace`가 preview/read-only/projection boundary로 유지된다고 기록되어야 함 | production owner 또는 shell로 승격된 것처럼 기록됨 | 문서 반영 검색 결과에서 `preview / read-only / projection boundary` 또는 `preview/read-only/projection boundary` 확인 |
| `ExplorerWorkspaceState` source-of-truth 미승격 문구 확인 | `ExplorerWorkspaceState`를 route state source-of-truth 또는 production visible UI source-of-truth로 승격하지 않는다고 기록되어야 함 | projection state를 canonical owner처럼 기록함 | 문서 반영 검색 결과에서 `ExplorerWorkspaceState`, `source-of-truth` 확인 |
| shell mount / route wiring / owner migration 금지 문구 확인 | shell mount, route wiring, owner migration 금지가 유지되어야 함 | 금지 항목 누락 또는 구현 허용처럼 기록됨 | 문서 반영 검색 결과에서 `shell mount`, `route wiring`, `owner migration` 확인 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |
| 전체 flutter test 실행 여부 판단 | Phase 16-D는 docs/design only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다 | 문서 외 변경이 있는데 전체 테스트를 생략함 | 변경 파일 범위 확인 후 실행 여부 판단 |

Phase 16-D는 docs/design only이며 `lib/`, `test/`, production code 변경이 없으면 전체 `flutter test --reporter compact`는 실행하지 않는다. 변경 파일 범위가 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.91 Phase 16-E ExplorerWorkspace projection/source-of-truth boundary design

Phase 16-E는 `projection/source-of-truth boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 state owner migration이 아니다. owner/controller/coordinator migration을 수행하지 않고, route wiring이나 ExplorerWorkspace shell mount를 변경하지 않는다. Phase 16-E만으로 ExplorerWorkspace production transition 구현은 승인되지 않는다.

#### 17.91.1 Phase 16-E 성격

| 항목 | Phase 16-E 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| state owner migration | 아님 |
| production transition 구현 승인 | 아님 |
| `ExplorerWorkspaceState` production source-of-truth 승격 | 아님 |
| route state source-of-truth 변경 | 없음 |
| persistence/history/source-of-truth usage 승인 | 없음 |

Phase 16-E의 목적은 `ExplorerWorkspaceState`를 production visible UI source-of-truth로 승격하는 것이 아니라, 현재 production visible UI source-of-truth가 무엇인지와 projection / contract representation이 어디까지인지 문서상 분리하는 것이다.

#### 17.91.2 현재 production visible UI source-of-truth

현재 production 구조에서 `WordExplorerScreen` 내부 상태는 Explorer production visible UI source-of-truth로 해석한다. Phase 16-E에서는 이 소유권을 `ExplorerWorkspaceState`로 이전하지 않는다.

현재 production 구조 기준으로 source-of-truth로 해석하는 항목은 다음과 같다.

| 항목 | 현재 production 해석 | Phase 16-E 유지 기준 |
| --- | --- | --- |
| `_centerWordId` | 현재 Explorer graph center의 production visible UI source-of-truth다. | `ExplorerWorkspaceState`로 이전하지 않는다. |
| `_selectedWordId` | 현재 선택 단어 id의 production visible UI source-of-truth다. | projection 기반 selection source-of-truth로 승격하지 않는다. |
| `_selectedWordDisplayItem` | 현재 detail pane 선택 표시 대상의 production visible UI source-of-truth다. | detail target owner를 이전하지 않는다. |
| `_history` | 현재 Explorer 내부 navigation history 표시와 이동 판단의 production visible UI source-of-truth다. | route history 또는 projection history로 승격하지 않는다. |
| detail loading state | 현재 detail pane loading 표시 판단의 production visible UI source-of-truth다. | projection state로 이전하지 않는다. |
| detail error state | 현재 detail pane error 표시 판단의 production visible UI source-of-truth다. | projection state로 이전하지 않는다. |
| detail unavailable state | 현재 detail pane unavailable 표시 판단의 production visible UI source-of-truth다. | projection state로 이전하지 않는다. |
| `WordRepository` read result | 현재 production read 결과이며 detail/graph 표시 판단의 입력 source-of-truth로 해석한다. | 신규 repository read 또는 repository/read owner migration을 수행하지 않는다. |

이 목록은 현재 production 구조 기준의 해석이다. 장기 최종 구조 확정이나 owner migration 승인으로 해석하지 않는다.

#### 17.91.3 `_readOnlyWorkspaceProjection` boundary

`_readOnlyWorkspaceProjection`은 production source-of-truth가 아니다.

`_readOnlyWorkspaceProjection`은 `WordExplorerScreen` 내부 production 상태를 `ExplorerWorkspaceState` 형태로 읽기 위해 사용하는 read-only projection entry다. 이 entry는 `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, `_history`, detail 상태, repository read 결과의 소유권을 갖지 않는다.

`_readOnlyWorkspaceProjection` 결과를 persistence, navigation history, rollback, route state, selection owner, graph center owner, detail target owner의 source-of-truth로 사용하지 않는다.

#### 17.91.4 `WordExplorerWorkspaceProjectionAdapter.project(...)` boundary

`WordExplorerWorkspaceProjectionAdapter.project(...)`는 source-of-truth adapter가 아니다.

`WordExplorerWorkspaceProjectionAdapter.project(...)`는 production 상태를 `ExplorerWorkspaceState` 형태로 변환하는 projection adapter다. adapter는 production 상태를 결정하거나 소유하지 않는다. adapter 결과는 production visible UI state, route state, persistence state, navigation history state를 대체하지 않는다.

Phase 16-E에서는 adapter를 owner, controller, coordinator, repository/read authority, persistence authority로 승격하지 않는다.

#### 17.91.5 `ExplorerWorkspaceState` boundary

`ExplorerWorkspaceState`는 projection / contract representation이다.

`ExplorerWorkspaceState`는 다음 항목이 아니다.

- production visible UI source-of-truth
- route state source-of-truth
- persistence source-of-truth
- navigation history source-of-truth
- selection owner
- graph center owner
- detail target owner
- navigation history owner
- repository/read owner
- persistence authority
- rollback authority

따라서 `ExplorerWorkspaceState`의 `centerWordId`, `selectedWordId`, `detailTargetWordId`, `history` 계열 값은 현재 production owner state를 읽은 projection representation으로만 해석한다. 이 값들을 기준으로 route, repository read, persistence restore, rollback, history mutation을 결정하는 사용은 Phase 16-E에서 승인되지 않는다.

#### 17.91.6 Phase 16-E 이후에도 승인되지 않은 항목

Phase 16-E 이후에도 아래 항목은 승인되지 않은 상태로 유지한다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- projection result persistence/history/source-of-truth usage
- Level 3 production-visible consumer 승격
- 신규 repository read
- 신규 DB query
- 신규 DTO/model/public API 추가
- `lib/` 변경
- `test/` 변경
- DB 변경
- dependency 변경
- platform 파일 변경

#### 17.91.7 Phase 16-F 후보

Phase 16-F의 1차 후보는 `Phase 16-F selection owner boundary design`이다.

대안 후보는 `Phase 16-F projection guardrail design`이다.

Phase 16-E 문서 정리 결과 projection/source-of-truth boundary가 충분히 명확하면 Phase 16-F는 `selection owner boundary design`으로 진행할 수 있다.

반대로 `ExplorerWorkspaceState`가 source-of-truth처럼 오해될 여지가 남아 있으면 Phase 16-F는 `projection guardrail design`을 우선한다.

#### 17.91.8 Phase 16-E 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-E 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git status --short --branch`, `git diff -- docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| projection/source-of-truth boundary 문서 반영 검색 | `ExplorerWorkspaceState`가 projection / contract representation이며 production source-of-truth가 아니라고 확인되어야 함 | `ExplorerWorkspaceState`를 source-of-truth처럼 읽을 수 있는 표현 잔존 | `rg -n "ExplorerWorkspaceState|source-of-truth|source of truth|projection|read-only|contract representation|WordExplorerScreen|_readOnlyWorkspaceProjection|WordExplorerWorkspaceProjectionAdapter" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| 현재 production visible UI source-of-truth 확인 | `WordExplorerScreen` 내부 상태와 `WordRepository` read result가 현재 production 구조 기준 source-of-truth로 문서화되어야 함 | production owner를 projection state로 이전한 것처럼 기록됨 | 문서 반영 검색 결과에서 `WordExplorerScreen`, `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, `_history`, `WordRepository` 확인 |
| projection entry와 adapter 역할 확인 | `_readOnlyWorkspaceProjection`과 `WordExplorerWorkspaceProjectionAdapter.project(...)`가 projection boundary로 기록되어야 함 | entry 또는 adapter가 상태를 소유하는 것처럼 기록됨 | 문서 반영 검색 결과에서 `_readOnlyWorkspaceProjection`, `WordExplorerWorkspaceProjectionAdapter.project(...)` 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, persistence/history/source-of-truth usage가 미승인으로 남아야 함 | 금지 항목 누락 또는 승인처럼 읽히는 문구 | 문서 반영 검색 결과에서 `승인되지 않은 상태`, `shell mount`, `route wiring`, `owner/controller/coordinator migration`, `projection result persistence/history/source-of-truth usage` 확인 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |

Phase 16-E는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.92 Phase 16-F ExplorerWorkspace selection owner boundary design

Phase 16-F는 `selection owner boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 selection owner migration이 아니다. selection owner 이전, controller 도입, production 동작 변경을 수행하지 않는다. Phase 16-F만으로 `ExplorerWorkspaceState` 또는 `ExplorerWorkspace`가 selection owner로 승격되는 것은 승인되지 않는다.

#### 17.92.1 Phase 16-F 성격

| 항목 | Phase 16-F 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| selection owner migration | 아님 |
| selection controller 도입 | 아님 |
| production 동작 변경 승인 | 없음 |
| `ExplorerWorkspaceState` selection source-of-truth 승격 | 아님 |
| `ExplorerWorkspace` selection controller화 | 아님 |

Phase 16-F의 목적은 현재 production에서 선택된 단어를 실제로 결정하는 주체와 projection representation의 경계를 분리하는 것이다. 이 단계는 Phase 16-E의 projection/source-of-truth boundary를 유지한 상태에서 selection owner boundary만 문서상 정리한다.

#### 17.92.2 현재 production selection owner

현재 production selection owner는 `WordExplorerScreen` 내부 상태로 해석한다.

| 항목 | 현재 production 해석 | Phase 16-F 유지 기준 |
| --- | --- | --- |
| `_selectedWordId` | 현재 선택 단어 id의 production visible UI source-of-truth다. | `ExplorerWorkspaceState.selectedWordId`로 소유권을 이전하지 않는다. |
| `_selectedWordDisplayItem` | 현재 detail pane 표시 대상의 production visible UI source-of-truth다. | `ExplorerWorkspaceState.detailTargetWordId`로 소유권을 이전하지 않는다. |

`_selectedWordId`와 `_selectedWordDisplayItem`은 관련되어 있지만 동일 개념으로 병합하지 않는다. `_selectedWordId`는 선택 단어 id를 나타내고, `_selectedWordDisplayItem`은 detail pane이 표시할 수 있는 선택 단어 표시 payload를 나타낸다.

Phase 16-F는 이 소유권을 `ExplorerWorkspaceState` 또는 `ExplorerWorkspace`로 이전하지 않는다. `WordGraphScreen`의 selection callback이 `WordExplorerScreen`의 `_selectWord(...)` 흐름으로 연결될 수 있지만, 현재 production selection 결정과 상태 보유 위치는 `WordExplorerScreen` 내부 상태로 유지한다.

#### 17.92.3 `ExplorerWorkspaceState` selection boundary

`ExplorerWorkspaceState.selectedWordId` 계열 값은 selection owner state가 아니라 projection representation이다.

`ExplorerWorkspaceState.detailTargetWordId` 계열 값은 detail target owner state가 아니라 projection representation이다.

`ExplorerWorkspaceState`는 selection event를 발생시키는 controller가 아니다. 또한 selection mutation, history mutation, detail target 결정, graph center 변경을 소유하지 않는다.

따라서 `ExplorerWorkspaceState.selectedWordId` 또는 `ExplorerWorkspaceState.detailTargetWordId`를 기준으로 production selection, detail target, graph center, navigation history를 변경하는 사용은 Phase 16-F에서 승인되지 않는다.

#### 17.92.4 selection owner와 다른 owner boundary 구분

Phase 16-F에서는 다음 owner/authority를 selection owner와 혼동하지 않는다.

| 경계 | Phase 16-F 해석 |
| --- | --- |
| selection owner | 현재 선택 단어 id와 선택 표시 payload를 보유하는 `WordExplorerScreen` 내부 상태다. |
| detail target owner | detail pane 표시 대상 결정과 연결되지만 selection owner와 동일시하지 않는다. |
| graph center owner | center 변경과 연결될 수 있지만 selection owner와 동일시하지 않는다. |
| navigation history owner | selection 변경 기록과 연결될 수 있지만 selection owner와 동일시하지 않는다. |
| repository/read owner | 선택 표시 payload를 읽는 흐름과 연결되지만 selection owner와 동일시하지 않는다. |
| persistence authority | projection 또는 history snapshot을 저장/복원하는 authority로 승격하지 않는다. |
| route state owner | route state 결정 주체로 selection owner를 승격하지 않는다. |

selection 변경이 detail target 표시와 연결될 수 있지만, selection owner와 detail target owner를 동일시하지 않는다.

selection 변경이 graph center 변경으로 이어질 수 있지만, selection owner와 graph center owner를 동일시하지 않는다.

selection 변경이 history mutation과 연결될 수 있지만, selection owner와 navigation history owner를 동일시하지 않는다.

projection state를 기준으로 selection, detail, center, history mutation을 결정하는 사용은 승인되지 않는다.

#### 17.92.5 Phase 16-F 이후에도 승인되지 않은 항목

Phase 16-F 이후에도 아래 항목은 승인되지 않은 상태로 유지한다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- selection owner migration
- detail target owner migration
- graph center owner migration
- navigation history owner migration
- repository/read owner migration
- persistence authority migration
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- projection result 기반 selection/history/detail/center mutation
- 신규 repository read
- 신규 DB query
- 신규 DTO/model/public API 추가
- `lib/` 변경
- `test/` 변경
- DB 변경
- dependency 변경
- platform 파일 변경

#### 17.92.6 Phase 16-G 후보

Phase 16-G의 1차 후보는 `Phase 16-G graph center owner boundary design`이다.

대안 후보는 `Phase 16-G detail target owner boundary design`이다.

또 다른 대안 후보는 `Phase 16-G selection guardrail design`이다.

Phase 16-F에서 selection owner boundary가 충분히 명확해지면 Phase 16-G는 `graph center owner boundary design`으로 진행할 수 있다.

반대로 selection과 detail target, graph center, history mutation 구분이 충분히 명확하지 않으면 Phase 16-G는 `selection guardrail design`을 우선한다.

#### 17.92.7 Phase 16-F 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-F 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff -- docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md`, `git status --short --branch` |
| selection owner boundary 문서 반영 확인 | `WordExplorerScreen` 내부 상태가 현재 production selection owner로 문서화되어야 함 | owner가 `ExplorerWorkspaceState` 또는 `ExplorerWorkspace`로 이전된 것처럼 기록됨 | 문서 반영 검색 결과에서 `WordExplorerScreen`, `selection owner`, `_selectedWordId`, `_selectedWordDisplayItem` 확인 |
| `_selectedWordId`와 `_selectedWordDisplayItem` 역할 구분 확인 | `_selectedWordId`는 선택 단어 id, `_selectedWordDisplayItem`은 detail pane 표시 대상 payload로 구분되어야 함 | 두 항목이 동일 개념처럼 병합됨 | 문서 반영 검색 결과에서 두 항목의 정의 확인 |
| `ExplorerWorkspaceState` selection boundary 확인 | `ExplorerWorkspaceState`는 selection owner가 아니라 projection representation으로 문서화되어야 함 | `ExplorerWorkspaceState`를 selection source-of-truth처럼 읽을 수 있는 표현 잔존 | `rg -n "selection|selectedWord|_selectedWordId|_selectedWordDisplayItem|detailTargetWordId|ExplorerWorkspaceState|source-of-truth|projection|owner" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| owner boundary 분리 확인 | selection owner, detail target owner, graph center owner, navigation history owner가 혼동되지 않아야 함 | selection과 detail/center/history owner를 동일시하는 표현 | 문서 반영 검색 결과에서 `detail target owner`, `graph center owner`, `navigation history owner` 확인 |
| Phase 16-E boundary 충돌 확인 | Phase 16-E projection/source-of-truth boundary와 충돌하는 표현이 없어야 함 | projection state 기반 mutation 또는 source-of-truth usage 승인처럼 기록됨 | 문서 반영 검색 결과에서 `projection`, `source-of-truth`, `승인되지 않는다` 확인 |
| whitespace 검증 | diff에 whitespace 오류가 없어야 함 | trailing whitespace 또는 patch formatting 오류 | `git diff --check` |

Phase 16-F는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.93 Phase 16-G ExplorerWorkspace graph center owner boundary design

Phase 16-G는 `graph center owner boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 graph center owner migration이 아니다. `_centerWordId` 소유권을 이전하지 않고, `ExplorerWorkspaceState.centerWordId`를 production source-of-truth로 승격하지 않으며, `ExplorerWorkspace`를 graph center controller 또는 production shell로 만들지 않는다.

#### 17.93.1 Phase 16-G 성격

| 항목 | Phase 16-G 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| graph center owner migration | 아님 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| source-of-truth migration 승인 | 없음 |

Phase 16-G의 목적은 현재 production에서 graph center를 실제로 결정하는 주체와 projection representation의 경계를 분리하는 것이다. 이 단계는 Phase 16-E의 projection/source-of-truth boundary와 Phase 16-F의 selection owner boundary를 유지한 상태에서 graph center owner boundary만 문서상 정리한다.

#### 17.93.2 현재 production graph center owner

현재 production 기준 graph center owner는 `WordExplorerScreen` 내부 상태로 해석한다.

| 항목 | 현재 production 해석 | Phase 16-G 유지 기준 |
| --- | --- | --- |
| `_centerWordId` | 현재 Explorer graph center의 production visible UI source-of-truth다. | `ExplorerWorkspaceState.centerWordId`로 소유권을 이전하지 않는다. |
| `WordExplorerScreen` 내부 center 상태 갱신 흐름 | 현재 Explorer graph center 표시와 graph child 입력을 결정하는 production 흐름이다. | `ExplorerWorkspace` graph center controller화로 해석하지 않는다. |

이 문서의 graph center owner 판단은 현재 production 기준으로만 제한한다. 이는 미래 최종 구조의 확정 owner 선언이 아니며, canonical owner migration 승인도 아니다.

`ExplorerWorkspace`는 graph center controller가 아니다.

`ExplorerWorkspace`는 production shell이 아니다.

Phase 16-G는 owner migration이 아니라 owner boundary design이다.

#### 17.93.3 `ExplorerWorkspaceState.centerWordId` boundary

`ExplorerWorkspaceState.centerWordId`는 graph center owner state가 아니다.

`ExplorerWorkspaceState.centerWordId`는 production visible UI source-of-truth가 아니다.

`ExplorerWorkspaceState.centerWordId`는 route state source-of-truth가 아니다.

`ExplorerWorkspaceState.centerWordId`는 projection representation이다.

따라서 `ExplorerWorkspaceState.centerWordId`를 기준으로 production graph center, route state, navigation history, persistence, rollback, selection, detail target을 결정하는 사용은 Phase 16-G에서 승인되지 않는다.

#### 17.93.4 graph center owner와 다른 owner boundary 구분

Phase 16-G에서는 다음 owner/authority를 graph center owner와 병합하지 않는다.

| 경계 | Phase 16-G 해석 |
| --- | --- |
| graph center owner | 현재 production 기준 Explorer graph center를 보유하는 `WordExplorerScreen` 내부 상태다. |
| selection owner | 선택 단어 id와 선택 표시 payload를 보유하는 경계이며 graph center owner와 동일시하지 않는다. |
| detail target owner | detail pane 표시 대상 결정과 연결될 수 있지만 graph center owner와 동일시하지 않는다. |
| navigation history owner | center 변경 기록과 연결될 수 있지만 graph center owner와 동일시하지 않는다. |
| repository/read owner | graph/detail 표시 데이터 read 흐름과 연결되지만 graph center owner와 동일시하지 않는다. |
| route state owner | route state 결정 주체로 graph center owner를 승격하지 않는다. |
| persistence authority | projection 또는 history snapshot을 저장/복원하는 authority로 graph center owner를 승격하지 않는다. |
| rollback authority | 복원 판단과 연결될 수 있지만 graph center owner와 동일시하지 않는다. |

selection 변경이 center 변경으로 이어질 수 있지만, selection owner와 graph center owner는 동일하지 않다.

center 변경이 history mutation과 연결될 수 있지만, graph center owner와 navigation history owner는 동일하지 않다.

detail target 갱신이 selection 또는 center 흐름과 함께 발생할 수 있지만, detail target owner와 graph center owner는 동일하지 않다.

projection result를 기준으로 selection, detail, center, history mutation을 결정하는 사용은 승인되지 않는다.

#### 17.93.5 현재 production 흐름 설명

현재 production 흐름에서 `WordGraphScreen.onSelectWordId`는 `WordExplorerScreen`의 `_selectWord(...)`로 연결된다.

`_selectWord(...)`는 selection/detail 상태를 갱신하고, 필요 시 center/history 상태 갱신을 동반할 수 있다.

하지만 하나의 흐름에서 여러 상태가 갱신된다는 사실은 owner 개념을 병합한다는 뜻이 아니다. Phase 16-G는 이 흐름을 graph center owner migration, selection owner migration, navigation history owner migration, detail target owner migration의 근거로 사용하지 않는다.

#### 17.93.6 Phase 16-G 이후에도 승인되지 않은 항목

Phase 16-G 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history mutation
- Level 3 production-visible consumer 승격
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- dependency 변경
- platform 파일 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.93.7 Phase 16-G 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-G 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| graph center owner boundary 문서 반영 확인 | 현재 production 기준 graph center owner가 `WordExplorerScreen` 내부 상태로 문서화되어야 함 | owner가 `ExplorerWorkspaceState` 또는 `ExplorerWorkspace`로 이전된 것처럼 기록됨 | 문서 반영 검색 결과에서 `graph center owner`, `WordExplorerScreen`, `_centerWordId` 확인 |
| `ExplorerWorkspaceState.centerWordId` boundary 확인 | `ExplorerWorkspaceState.centerWordId`는 graph center owner state가 아니라 projection representation으로 문서화되어야 함 | source-of-truth 승격 또는 route state owner처럼 기록됨 | `rg -n "Phase 16-G|graph center owner|_centerWordId|ExplorerWorkspaceState\\.centerWordId|projection representation|not approved" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| owner boundary 분리 확인 | graph center owner, selection owner, detail target owner, navigation history owner가 혼동되지 않아야 함 | center/selection/detail/history owner를 동일시하는 표현 | 문서 반영 검색 결과에서 각 owner 구분 문구 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, projection result 기반 mutation, `lib/`, `test/`, DB, dependency, platform 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-G는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.94 Phase 16-H ExplorerWorkspace detail target owner boundary design

Phase 16-H는 `detail target owner boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 detail target owner migration이 아니다. `_selectedWordDisplayItem` 소유권을 이전하지 않고, `ExplorerWorkspaceState.detailTargetWordId` 계열 값을 production source-of-truth로 승격하지 않으며, `ExplorerWorkspace`를 detail target controller 또는 production shell로 만들지 않는다.

#### 17.94.1 Phase 16-H 성격

| 항목 | Phase 16-H 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| detail target owner migration | 아님 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| source-of-truth migration 승인 | 없음 |

Phase 16-H의 목적은 현재 production에서 detail pane 표시 대상을 실제로 결정하는 주체와 projection representation의 경계를 분리하는 것이다. 이 단계는 Phase 16-D의 route owner boundary와 route wiring 금지선, Phase 16-E의 projection/source-of-truth boundary, Phase 16-F의 selection owner boundary, Phase 16-G의 graph center owner boundary를 유지한 상태에서 detail target owner boundary만 문서상 정리한다.

#### 17.94.2 현재 production detail target owner

현재 production detail target owner는 `WordExplorerScreen` 내부 상태로 해석한다.

| 항목 | 현재 production 해석 | Phase 16-H 유지 기준 |
| --- | --- | --- |
| `_selectedWordDisplayItem` | 현재 detail pane 표시 대상의 production visible UI source-of-truth다. | `ExplorerWorkspaceState.detailTargetWordId`로 소유권을 이전하지 않는다. |
| `_selectedWordId` | 현재 선택 단어 id의 production visible UI source-of-truth다. | `_selectedWordDisplayItem`과 동일 개념으로 병합하지 않는다. |
| `WordExplorerScreen` 내부 detail 상태 갱신 흐름 | 현재 Explorer detail pane 표시 대상을 결정하는 production 흐름이다. | `ExplorerWorkspace` detail target controller화로 해석하지 않는다. |

`_selectedWordId`와 `_selectedWordDisplayItem`은 관련되어 있지만 동일 개념으로 병합하지 않는다. `_selectedWordId`는 어떤 단어가 선택되었는지를 나타내는 selection state이고, `_selectedWordDisplayItem`은 detail pane이 현재 보여줄 표시 항목을 나타내는 detail target state다.

이 문서의 detail target owner 판단은 현재 production 기준으로만 제한한다. 이는 미래 최종 구조의 확정 owner 선언이 아니며, canonical owner migration 승인도 아니다.

`ExplorerWorkspace`는 detail target controller가 아니다.

`ExplorerWorkspace`는 production shell이 아니다.

Phase 16-H는 owner migration이 아니라 detail target owner boundary design이다.

#### 17.94.3 `ExplorerWorkspaceState.detailTargetWordId` boundary

`ExplorerWorkspaceState.detailTargetWordId` 계열 값은 detail target owner state가 아니다.

`ExplorerWorkspaceState.detailTargetWordId` 계열 값은 production visible UI source-of-truth가 아니다.

`ExplorerWorkspaceState.detailTargetWordId` 계열 값은 route state source-of-truth가 아니다.

`ExplorerWorkspaceState.detailTargetWordId` 계열 값은 projection representation이다.

따라서 `ExplorerWorkspaceState.detailTargetWordId` 계열 값을 기준으로 production detail target, selection, graph center, navigation history, repository/read, persistence, rollback을 결정하는 사용은 Phase 16-H에서 승인되지 않는다.

#### 17.94.4 detail target owner와 다른 owner boundary 구분

Phase 16-H에서는 다음 owner/authority를 detail target owner와 병합하지 않는다.

| 경계 | Phase 16-H 해석 |
| --- | --- |
| selection owner | 어떤 단어가 선택되었는지를 결정하는 경계이며 detail target owner와 동일시하지 않는다. |
| detail target owner | 현재 production 기준 detail pane 표시 대상을 보유하는 `WordExplorerScreen` 내부 상태다. |
| graph center owner | graph center를 어떤 단어로 둘지를 결정하는 경계이며 detail target owner와 동일시하지 않는다. |
| navigation history owner | 이동 기록과 back/forward 판단을 결정하는 경계이며 detail target owner와 동일시하지 않는다. |
| repository/read owner | detail 표시를 위한 read 결과와 loading/error/unavailable 상태를 다루는 경계이며 detail target owner와 동일시하지 않는다. |
| route state owner | route state 결정 주체로 detail target owner를 승격하지 않는다. |
| persistence authority | projection 또는 history snapshot을 저장/복원하는 authority로 detail target owner를 승격하지 않는다. |
| rollback authority | 복원 판단과 연결될 수 있지만 detail target owner와 동일시하지 않는다. |

selection 변경이 detail target 갱신으로 이어질 수 있지만, selection owner와 detail target owner는 동일하지 않다.

detail target 갱신이 repository/read 결과와 연결될 수 있지만, detail target owner와 repository/read owner는 동일하지 않다.

detail target 갱신이 graph center 변경 또는 history mutation과 같은 흐름에서 발생할 수 있지만, detail target owner와 graph center owner, navigation history owner는 동일하지 않다.

projection result를 기준으로 selection, detail, center, history mutation을 결정하는 사용은 승인되지 않는다.

#### 17.94.5 현재 production 흐름 설명

현재 production 흐름에서 `WordGraphScreen.onSelectWordId`는 `WordExplorerScreen`의 `_selectWord(...)`로 연결될 수 있다.

`_selectWord(...)` 흐름 안에서 selection, detail target, graph center, navigation history 상태 갱신이 함께 일어날 수 있다.

하지만 하나의 `_selectWord(...)` 흐름 안에서 selection/detail/center/history 상태 갱신이 함께 일어날 수 있어도 owner 개념을 병합해서는 안 된다. Phase 16-H는 이 흐름을 detail target owner migration, selection owner migration, graph center owner migration, navigation history owner migration, repository/read owner migration의 근거로 사용하지 않는다.

#### 17.94.6 Phase 16-D/E/F/G와의 연결

Phase 16-H는 기존 Phase 16-D/E/F/G의 금지선과 boundary를 다음 방식으로 유지한다.

| 이전 Phase | Phase 16-H 연결 방식 |
| --- | --- |
| Phase 16-D | route owner boundary와 route wiring 금지선을 유지한다. |
| Phase 16-E | projection/source-of-truth boundary를 유지한다. |
| Phase 16-F | selection owner boundary와 detail target owner를 분리한다. |
| Phase 16-G | graph center owner boundary와 detail target owner를 분리한다. |

#### 17.94.7 Phase 16-H 이후에도 승인되지 않은 항목

Phase 16-H 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history mutation
- Level 3 production-visible consumer 승격
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.94.8 Phase 16-H 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-H 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| detail target owner boundary 문서 반영 확인 | 현재 production 기준 detail target owner가 `WordExplorerScreen` 내부 상태로 문서화되어야 함 | owner가 `ExplorerWorkspaceState` 또는 `ExplorerWorkspace`로 이전된 것처럼 기록됨 | 문서 반영 검색 결과에서 `detail target owner`, `WordExplorerScreen`, `_selectedWordDisplayItem` 확인 |
| `_selectedWordId`와 `_selectedWordDisplayItem` 역할 구분 확인 | `_selectedWordId`는 selection state, `_selectedWordDisplayItem`은 detail target state로 구분되어야 함 | 두 항목이 동일 개념처럼 병합됨 | 문서 반영 검색 결과에서 두 항목의 정의 확인 |
| `ExplorerWorkspaceState.detailTargetWordId` boundary 확인 | `ExplorerWorkspaceState.detailTargetWordId` 계열 값은 detail target owner state가 아니라 projection representation으로 문서화되어야 함 | source-of-truth 승격 또는 route state owner처럼 기록됨 | `rg -n "Phase 16-H|detail target owner|_selectedWordDisplayItem|_selectedWordId|ExplorerWorkspaceState\\.detailTargetWordId|projection representation" docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md` |
| owner boundary 분리 확인 | selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner가 혼동되지 않아야 함 | selection/detail/center/history/read owner를 동일시하는 표현 | 문서 반영 검색 결과에서 각 owner 구분 문구 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, projection result 기반 mutation, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-H는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.95 Phase 16-I ExplorerWorkspace navigation history owner boundary design

Phase 16-I는 `navigation history owner boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 navigation history owner migration이 아니다. `_history` 소유권을 이전하지 않고, `ExplorerWorkspaceState.history` 계열 값을 production source-of-truth로 승격하지 않으며, `ExplorerWorkspace`를 navigation history controller, rollback authority, production shell로 만들지 않는다.

#### 17.95.1 Phase 16-I 성격

| 항목 | Phase 16-I 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| navigation history owner migration | 아님 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| source-of-truth migration 승인 | 없음 |
| rollback authority migration 승인 | 없음 |

Phase 16-I의 목적은 현재 production에서 navigation history를 실제로 결정하는 주체와 projection representation의 경계를 분리하는 것이다. 이 단계는 Phase 16-D의 route owner boundary와 route wiring 금지선, Phase 16-E의 projection/source-of-truth boundary, Phase 16-F의 selection owner boundary, Phase 16-G의 graph center owner boundary, Phase 16-H의 detail target owner boundary를 유지한 상태에서 navigation history owner boundary만 문서상 정리한다.

#### 17.95.2 현재 production navigation history owner

현재 production navigation history owner는 `WordExplorerScreen` 내부 상태로 해석한다.

| 항목 | 현재 production 해석 | Phase 16-I 유지 기준 |
| --- | --- | --- |
| `_history` | 현재 Explorer 내부 navigation history 표시와 back/forward 이동 판단의 production visible UI source-of-truth다. | `ExplorerWorkspaceState.history`로 소유권을 이전하지 않는다. |
| `WordExplorerScreen` 내부 history 갱신 흐름 | 현재 Explorer 내부 이동 기록과 back/forward 판단을 결정하는 production 흐름이다. | `ExplorerWorkspace` navigation history controller화로 해석하지 않는다. |

이 문서의 navigation history owner 판단은 현재 production 기준으로만 제한한다. 이는 미래 최종 구조의 확정 owner 선언이 아니며, canonical owner migration 승인도 아니다.

`ExplorerWorkspace`는 navigation history controller가 아니다.

`ExplorerWorkspace`는 rollback authority가 아니다.

`ExplorerWorkspace`는 production shell이 아니다.

Phase 16-I는 owner migration이 아니라 navigation history owner boundary design이다.

#### 17.95.3 `ExplorerWorkspaceState.history` boundary

`ExplorerWorkspaceState.history` 계열 값은 navigation history owner state가 아니다.

`ExplorerWorkspaceState.history` 계열 값은 production visible UI source-of-truth가 아니다.

`ExplorerWorkspaceState.history` 계열 값은 route state source-of-truth가 아니다.

`ExplorerWorkspaceState.history` 계열 값은 projection representation이다.

따라서 `ExplorerWorkspaceState.history` 계열 값이나 projection result를 근거로 production history를 mutate, persist, rollback하는 것은 Phase 16-I에서 승인되지 않는다.

#### 17.95.4 navigation history owner와 다른 owner boundary 구분

Phase 16-I에서는 다음 owner/authority를 navigation history owner와 병합하지 않는다.

| 경계 | Phase 16-I 해석 |
| --- | --- |
| selection owner | 어떤 단어가 선택되었는지를 결정하는 책임이며 navigation history owner와 동일시하지 않는다. |
| detail target owner | detail pane이 어떤 단어/표시 항목을 보여줄지를 결정하는 책임이며 navigation history owner와 동일시하지 않는다. |
| graph center owner | graph center를 어떤 단어로 둘지를 결정하는 책임이며 navigation history owner와 동일시하지 않는다. |
| navigation history owner | 현재 production 기준 Explorer 내부 이동 기록과 back/forward 판단을 보유하는 `WordExplorerScreen` 내부 상태다. |
| repository/read owner | detail 표시를 위한 read 결과와 loading/error/unavailable 상태를 다루는 책임이며 navigation history owner와 동일시하지 않는다. |
| route state owner | Explorer route 진입과 route transition을 다루는 책임이며 navigation history owner와 동일시하지 않는다. |
| persistence authority | 상태를 저장/복원하는 권한이며 navigation history owner로 승격하지 않는다. |
| rollback authority | projection 결과나 history 표현을 근거로 production 상태를 되돌리는 권한이며 navigation history owner와 동일시하지 않는다. |

selection 변경이 history mutation으로 이어질 수 있지만, selection owner와 navigation history owner는 동일하지 않다.

detail target 갱신이 history mutation과 같은 흐름에서 발생할 수 있지만, detail target owner와 navigation history owner는 동일하지 않다.

graph center 변경이 history mutation과 연결될 수 있지만, graph center owner와 navigation history owner는 동일하지 않다.

repository/read 결과가 detail 표시 흐름에 영향을 줄 수 있지만, repository/read owner와 navigation history owner는 동일하지 않다.

projection result를 기준으로 production history mutation, persistence, rollback을 결정하는 사용은 승인되지 않는다.

#### 17.95.5 현재 production 흐름 설명

현재 production 흐름에서 `WordGraphScreen.onSelectWordId`는 `WordExplorerScreen`의 `_selectWord(...)`로 연결될 수 있다.

`_selectWord(...)` 흐름 안에서 selection, detail target, graph center, navigation history 상태 갱신이 함께 일어날 수 있다.

하지만 하나의 `_selectWord(...)` 흐름 안에서 selection/detail/center/history 상태 갱신이 함께 일어날 수 있어도 owner 개념을 병합해서는 안 된다. Phase 16-I는 이 흐름을 navigation history owner migration, selection owner migration, detail target owner migration, graph center owner migration, repository/read owner migration의 근거로 사용하지 않는다.

#### 17.95.6 Phase 16-D/E/F/G/H와의 연결

Phase 16-I는 기존 Phase 16-D/E/F/G/H의 금지선과 boundary를 다음 방식으로 유지한다.

| 이전 Phase | Phase 16-I 연결 방식 |
| --- | --- |
| Phase 16-D | route owner boundary와 route wiring 금지선을 유지한다. |
| Phase 16-E | projection/source-of-truth boundary를 유지한다. |
| Phase 16-F | selection owner boundary와 navigation history owner를 분리한다. |
| Phase 16-G | graph center owner boundary와 navigation history owner를 분리한다. |
| Phase 16-H | detail target owner boundary와 navigation history owner를 분리한다. |

#### 17.95.7 Phase 16-I 이후에도 승인되지 않은 항목

Phase 16-I 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- `ExplorerWorkspaceState.history` navigation history source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history mutation
- projection result 기반 rollback 승인
- Level 3 production-visible consumer 승격
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.95.8 Phase 16-I 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-I 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| navigation history owner boundary 문서 반영 확인 | 현재 production 기준 navigation history owner가 `WordExplorerScreen` 내부 상태로 문서화되어야 함 | owner가 `ExplorerWorkspaceState` 또는 `ExplorerWorkspace`로 이전된 것처럼 기록됨 | 문서 반영 검색 결과에서 `navigation history owner`, `WordExplorerScreen`, `_history` 확인 |
| `_history`와 `ExplorerWorkspaceState.history` 역할 구분 확인 | `_history`는 production visible UI source-of-truth, `ExplorerWorkspaceState.history` 계열 값은 projection representation으로 구분되어야 함 | 두 항목이 동일 owner state처럼 병합됨 | 문서 반영 검색 결과에서 두 항목의 정의 확인 |
| owner boundary 분리 확인 | selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner, route state owner가 혼동되지 않아야 함 | selection/detail/center/history/read/route owner를 동일시하는 표현 | 문서 반영 검색 결과에서 각 owner 구분 문구 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, projection result 기반 mutation/rollback, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-I는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.96 Phase 16-J ExplorerWorkspace repository/read owner boundary design

Phase 16-J는 `repository/read owner boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 repository/read owner migration이 아니다. `WordRepository` owner migration을 시작하지 않고, 새 repository read나 새 DB query를 추가하지 않으며, `ExplorerWorkspace`를 repository/read controller, read result source-of-truth, loading/error/unavailable state owner로 승격하지 않는다.

#### 17.96.1 Phase 16-J 성격

| 항목 | Phase 16-J 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| repository/read owner migration | 아님 |
| `WordRepository` owner migration | 아님 |
| 새 repository read / 새 DB query 승인 | 없음 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| source-of-truth migration 승인 | 없음 |
| rollback authority migration 승인 | 없음 |

Phase 16-J의 목적은 현재 production에서 detail 표시를 위한 repository/read를 실제로 수행하는 주체와 projection representation의 경계를 분리하는 것이다. 이 단계는 Phase 16-D의 route owner boundary와 route wiring 금지선, Phase 16-E의 projection/source-of-truth boundary, Phase 16-F의 selection owner boundary, Phase 16-G의 graph center owner boundary, Phase 16-H의 detail target owner boundary, Phase 16-I의 navigation history owner boundary를 유지한 상태에서 repository/read owner boundary만 문서상 정리한다.

#### 17.96.2 현재 production repository/read owner

현재 production repository/read owner는 `WordExplorerScreen` 내부 흐름으로 해석한다.

| 항목 | 현재 production 해석 | Phase 16-J 유지 기준 |
| --- | --- | --- |
| `WordRepository` | 현재 `WordExplorerScreen` 내부에서 직접 보유된다. | `ExplorerWorkspace`, `ExplorerWorkspaceState`, Provider, 별도 controller로 소유권을 이전하지 않는다. |
| `_repository` | `WordExplorerScreen` 내부 private repository instance다. | repository/read owner migration의 근거로 사용하지 않는다. |
| `_loadSplitViewDisplayItem(...)` | 현재 split view detail read 흐름에 속한다. | `ExplorerWorkspace` read API나 projection 기반 read 흐름으로 이전하지 않는다. |
| `_selectWord(...)` | selection, optional graph center 변경, split view detail read 결과, detail loading/error/unavailable 상태, history 갱신이 함께 발생할 수 있는 현재 production 흐름이다. | 하나의 흐름 안에서 여러 상태가 갱신되어도 owner 개념을 병합하지 않는다. |
| `_initializeExplorerBootstrap()` | 초기 Explorer 진입에서 graph center 표시 seed와 split view detail read를 수행하는 현재 production 흐름이다. | route owner 또는 `ExplorerWorkspaceState` source-of-truth migration으로 해석하지 않는다. |
| `_refreshSelectedWord(...)` | edit/detail route 복귀 뒤 선택 단어의 split view detail read를 다시 수행하고 detail 상태를 갱신하는 현재 production 흐름이다. | 새 repository read 추가나 read controller 승격으로 해석하지 않는다. |
| `_isDetailLoading` | 현재 detail loading 표시의 `WordExplorerScreen` 내부 상태다. | `ExplorerWorkspaceState`로 이전하지 않는다. |
| `_detailError` | 현재 detail error 표시의 `WordExplorerScreen` 내부 상태다. | `ExplorerWorkspaceState`로 이전하지 않는다. |
| `_detailUnavailableMessage` | 현재 detail unavailable 표시의 `WordExplorerScreen` 내부 상태다. | `ExplorerWorkspaceState`로 이전하지 않는다. |

이 문서의 repository/read owner 판단은 현재 production 기준으로만 제한한다. 이는 미래 최종 구조의 확정 owner 선언이 아니며, canonical owner migration 승인도 아니다.

`ExplorerWorkspace`는 repository/read controller가 아니다.

`ExplorerWorkspace`는 read result source-of-truth가 아니다.

`ExplorerWorkspace`는 loading/error/unavailable state owner가 아니다.

Phase 16-J는 owner migration이 아니라 repository/read owner boundary design이다.

#### 17.96.3 `ExplorerWorkspaceState` repository/read boundary

`ExplorerWorkspaceState`는 repository/read result owner state가 아니다.

`ExplorerWorkspaceState`는 detail loading/error/unavailable source-of-truth가 아니다.

`ExplorerWorkspaceState`는 production visible UI source-of-truth가 아니다.

`ExplorerWorkspaceState`는 projection representation이다.

따라서 `ExplorerWorkspaceState` 또는 projection result를 근거로 새 repository read, 새 DB query, read result persistence, read rollback을 수행하는 것은 Phase 16-J에서 승인되지 않는다.

#### 17.96.4 repository/read owner와 다른 owner boundary 구분

Phase 16-J에서는 다음 owner/authority를 repository/read owner와 병합하지 않는다.

| 경계 | Phase 16-J 해석 |
| --- | --- |
| selection owner | 어떤 단어가 선택되었는지를 결정하는 책임이며 repository/read owner와 동일시하지 않는다. |
| detail target owner | detail pane이 어떤 단어/표시 항목을 보여줄지를 결정하는 책임이며 repository/read owner와 동일시하지 않는다. |
| graph center owner | graph center를 어떤 단어로 둘지를 결정하는 책임이며 repository/read owner와 동일시하지 않는다. |
| navigation history owner | 이동 기록과 back/forward 판단을 결정하는 책임이며 repository/read owner와 동일시하지 않는다. |
| repository/read owner | detail 표시를 위한 read 요청, read 결과, loading/error/unavailable 상태 흐름을 다루는 현재 `WordExplorerScreen` 내부 책임이다. |
| route state owner | Explorer route 진입과 route transition을 다루는 책임이며 repository/read owner와 동일시하지 않는다. |
| persistence authority | 상태를 저장/복원하는 권한이며 repository/read owner로 승격하지 않는다. |
| rollback authority | projection 결과나 history 표현을 근거로 production 상태를 되돌리는 권한이며 repository/read owner와 동일시하지 않는다. |

selection 변경이 repository/read 요청으로 이어질 수 있지만, selection owner와 repository/read owner는 동일하지 않다.

detail target 갱신이 repository/read 결과와 연결될 수 있지만, detail target owner와 repository/read owner는 동일하지 않다.

graph center 변경이 repository/read 흐름과 같은 `_selectWord(...)` 흐름에서 발생할 수 있지만, graph center owner와 repository/read owner는 동일하지 않다.

navigation history mutation이 repository/read 결과 처리와 같은 흐름에서 발생할 수 있지만, navigation history owner와 repository/read owner는 동일하지 않다.

detail loading/error/unavailable 상태는 현재 production 기준 `WordExplorerScreen` 내부 상태이며 `ExplorerWorkspaceState`로 이전하지 않는다.

하나의 `_selectWord(...)` 흐름 안에서 selection/detail/center/history/read 상태 갱신이 함께 일어날 수 있어도 owner 개념을 병합해서는 안 된다.

#### 17.96.5 현재 production 흐름 설명

현재 production 흐름에서 `WordGraphScreen.onSelectWordId`와 `WordGraphScreen.onChangeCenterWordId`는 `WordExplorerScreen`의 `_selectWord(...)`로 연결될 수 있다.

`_selectWord(...)`는 `_isDetailLoading`을 true로 전환하고 `_detailError`, `_detailUnavailableMessage`를 초기화한 뒤 `_loadSplitViewDisplayItem(...)`을 통해 split view detail display item을 읽는다. read 결과가 있으면 `_selectedWordId`, `_selectedWordDisplayItem`, `_isDetailLoading`, `_detailUnavailableMessage`와 필요 시 `_centerWordId`, `_centerDisplaySeed`, `_history`를 갱신한다. read 실패는 `_detailError`, `_isDetailLoading`, `_detailUnavailableMessage` 상태로 처리한다.

`_initializeExplorerBootstrap()`은 초기 진입 word id를 기준으로 graph center 표시 seed read와 split view detail read를 수행하고, 결과를 `_centerWordId`, `_centerDisplaySeed`, `_selectedWordId`, `_selectedWordDisplayItem`, `_isDetailLoading`, `_detailError`, `_detailUnavailableMessage`, `_history` 흐름에 반영한다.

`_refreshSelectedWord(...)`는 edit/detail route 복귀 뒤 `_loadSplitViewDisplayItem(...)`으로 현재 선택 단어의 split view detail display item을 다시 읽고, `_selectedWordId`, `_selectedWordDisplayItem`, `_detailUnavailableMessage`, `_isDetailLoading`, 필요 시 `_centerWordId`, `_centerDisplaySeed`, `_graphRevision`, `_history`를 갱신한다.

이 흐름들은 현재 production repository/read owner가 `WordExplorerScreen` 내부 흐름임을 확인하기 위한 reference다. Phase 16-J는 이 흐름을 `ExplorerWorkspace` repository/read controller 승격, `ExplorerWorkspaceState` read result source-of-truth 승격, `WordRepository` owner migration의 근거로 사용하지 않는다.

#### 17.96.6 Phase 16-D/E/F/G/H/I와의 연결

Phase 16-J는 기존 Phase 16-D/E/F/G/H/I의 금지선과 boundary를 다음 방식으로 유지한다.

| 이전 Phase | Phase 16-J 연결 방식 |
| --- | --- |
| Phase 16-D | route owner boundary와 route wiring 금지선을 유지한다. |
| Phase 16-E | projection/source-of-truth boundary를 유지한다. |
| Phase 16-F | selection owner boundary와 repository/read owner를 분리한다. |
| Phase 16-G | graph center owner boundary와 repository/read owner를 분리한다. |
| Phase 16-H | detail target owner boundary와 repository/read owner를 분리한다. |
| Phase 16-I | navigation history owner boundary와 repository/read owner를 분리한다. |

#### 17.96.7 Phase 16-J 이후에도 승인되지 않은 항목

Phase 16-J 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `WordRepository` owner migration
- repository/read owner migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- `ExplorerWorkspaceState.history` navigation history source-of-truth usage
- `ExplorerWorkspaceState` repository/read result source-of-truth usage
- `ExplorerWorkspaceState` loading/error/unavailable source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history/read mutation
- projection result 기반 repository read
- projection result 기반 DB query
- projection result 기반 rollback 승인
- Level 3 production-visible consumer 승격
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.96.8 Phase 16-J 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-J 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| repository/read owner boundary 문서 반영 확인 | 현재 production 기준 repository/read owner가 `WordExplorerScreen` 내부 흐름으로 문서화되어야 함 | owner가 `ExplorerWorkspaceState`, `ExplorerWorkspace`, Provider, 별도 controller로 이전된 것처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 16-J`, `repository/read owner`, `WordExplorerScreen`, `WordRepository`, `_repository` 확인 |
| split view detail read 흐름 확인 | `_loadSplitViewDisplayItem(...)`, `_selectWord(...)`, `_initializeExplorerBootstrap()`, `_refreshSelectedWord(...)`가 현재 production read 흐름 reference로 기록되어야 함 | 새 repository read 또는 새 DB query 승인처럼 읽힘 | 문서 반영 검색 결과에서 각 메서드명 확인 |
| detail loading/error/unavailable owner 확인 | `_isDetailLoading`, `_detailError`, `_detailUnavailableMessage`는 `WordExplorerScreen` 내부 상태로 문서화되어야 함 | `ExplorerWorkspaceState` loading/error/unavailable source-of-truth 승격처럼 기록됨 | 문서 반영 검색 결과에서 각 상태명과 `ExplorerWorkspaceState` boundary 확인 |
| owner boundary 분리 확인 | selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner, route state owner, rollback authority가 혼동되지 않아야 함 | selection/detail/center/history/read/route owner를 동일시하는 표현 | 문서 반영 검색 결과에서 각 owner 구분 문구 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, projection result 기반 read/query/mutation/rollback, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-J는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.97 Phase 16-K ExplorerWorkspace persistence authority boundary design

Phase 16-K는 `persistence authority boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 persistence authority migration이 아니다. 새 persistence 기능이나 새 restore 기능을 추가하지 않고, rollback authority migration을 시작하지 않으며, `ExplorerWorkspace` shell mount, route wiring, owner/controller/coordinator migration, source-of-truth migration을 승인하지 않는다.

#### 17.97.1 Phase 16-K 성격

| 항목 | Phase 16-K 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| persistence authority migration | 아님 |
| rollback authority migration | 아님 |
| 새 persistence 기능 / 새 restore 기능 승인 | 없음 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| source-of-truth migration 승인 | 없음 |
| production state persist/restore 승인 | 없음 |

Phase 16-K의 목적은 현재 production에서 Explorer 상태를 저장/복원하는 persistence authority가 존재하는지와 `ExplorerWorkspaceState`, projection result, `_history`, history snapshot 계열 값을 persistence source-of-truth 또는 restore authority로 사용할 수 있는지 여부를 문서상 분리하는 것이다. 이 단계는 Phase 16-D의 route owner boundary와 route wiring 금지선, Phase 16-E의 projection/source-of-truth boundary, Phase 16-F의 selection owner boundary, Phase 16-G의 graph center owner boundary, Phase 16-H의 detail target owner boundary, Phase 16-I의 navigation history owner boundary, Phase 16-J의 repository/read owner boundary를 유지한 상태에서 persistence authority boundary만 문서상 정리한다.

#### 17.97.2 현재 production persistence authority 판단

현재 production persistence authority는 `ExplorerWorkspace`에 없다.

| 항목 | 현재 production 해석 | Phase 16-K 유지 기준 |
| --- | --- | --- |
| `ExplorerWorkspace` | preview/read-only/projection boundary로 유지되는 workspace 표현이다. | persistence controller, restore controller, production shell로 승격하지 않는다. |
| `ExplorerWorkspaceState` | selected/center/detail/layout/origin 값을 담는 projection representation이다. | persistence source-of-truth로 사용하지 않는다. |
| projection result | 현재 owner state를 읽어 만든 read-only projection 결과다. | production state persist/restore 근거로 사용하지 않는다. |
| `_history` | navigation history owner state일 수 있고 back/forward 판단에 사용된다. | persistence authority로 승격하지 않는다. |
| history snapshot 계열 값 | history 표시와 navigation 판단을 위한 표현이다. | production state restore authority로 사용하지 않는다. |
| `ExplorerWorkspaceHistoryEntry` 계열 표현 | `ExplorerWorkspaceState` snapshot을 감싸는 표현이다. | persistence API나 restore controller로 해석하지 않는다. |
| `WordNavigationHistoryController` | in-memory back/forward controller다. | persistence authority로 해석하지 않는다. |

`ExplorerWorkspace`는 persistence controller가 아니다.

`ExplorerWorkspace`는 restore controller가 아니다.

`ExplorerWorkspace`는 production shell이 아니다.

Phase 16-K는 persistence authority migration이 아니라 persistence authority boundary design이다.

#### 17.97.3 `ExplorerWorkspaceState` persistence boundary

`ExplorerWorkspaceState`는 persistence source-of-truth가 아니다.

`ExplorerWorkspaceState`는 production visible UI source-of-truth가 아니다.

`ExplorerWorkspaceState`는 projection representation이다.

projection result는 persistence source-of-truth가 아니다.

따라서 `ExplorerWorkspaceState` 또는 projection result를 근거로 production selection/detail/center/history/read state를 저장/복원하는 것은 Phase 16-K에서 승인되지 않는다.

`ExplorerWorkspaceState.history` 계열 값 또는 history snapshot 표현을 근거로 production state를 persist/restore하는 것도 승인되지 않는다.

#### 17.97.4 persistence authority와 다른 owner boundary 구분

Phase 16-K에서는 다음 owner/authority를 persistence authority와 병합하지 않는다.

| 경계 | Phase 16-K 해석 |
| --- | --- |
| route state owner | Explorer route 진입과 route transition을 다루는 책임이며 persistence authority와 동일시하지 않는다. |
| selection owner | 어떤 단어가 선택되었는지를 결정하는 책임이며 persistence authority와 동일시하지 않는다. |
| detail target owner | detail pane이 어떤 단어/표시 항목을 보여줄지를 결정하는 책임이며 persistence authority와 동일시하지 않는다. |
| graph center owner | graph center를 어떤 단어로 둘지를 결정하는 책임이며 persistence authority와 동일시하지 않는다. |
| navigation history owner | 이동 기록과 back/forward 판단을 결정하는 책임이며 persistence authority와 동일시하지 않는다. |
| repository/read owner | detail 표시를 위한 read 요청, read 결과, loading/error/unavailable 상태 흐름을 다루는 책임이며 persistence authority와 동일시하지 않는다. |
| persistence authority | production state를 저장/복원할 권한이며 현재 `ExplorerWorkspace`에 존재하지 않는다. |
| rollback authority | projection 결과나 history 표현을 근거로 production 상태를 되돌리는 권한이며 persistence authority와 동일시하지 않는다. |

navigation history owner와 persistence authority는 동일하지 않다.

`_history`가 back/forward 판단에 사용될 수 있어도 persistence authority로 승격하지 않는다.

history snapshot 또는 `ExplorerWorkspaceHistoryEntry` 계열 표현을 근거로 production state를 persist/restore하는 것은 승인되지 않는다.

persistence authority가 없다는 사실은 route owner, selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner의 현재 production 책임을 변경하지 않는다.

하나의 navigation/history/read 흐름 안에서 여러 상태가 함께 갱신될 수 있어도 persistence authority가 승인된 것으로 해석하지 않는다.

#### 17.97.5 현재 production 흐름 설명

현재 production 흐름에서 `WordExplorerScreen`은 `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, detail loading/error/unavailable 상태, `_history`, `_repository`를 내부 상태와 private instance로 보유한다.

`_readOnlyWorkspaceProjection`은 현재 owner state를 `ExplorerWorkspaceState`로 읽어내는 projection 흐름이다. 이 projection은 state 저장, state 복원, repository read, DB query, rollback 판단을 수행하지 않는다.

`_selectWord(...)`, `_initializeExplorerBootstrap()`, `_refreshSelectedWord(...)` 흐름에서는 selection/detail/center/history/read 상태 갱신이 함께 일어날 수 있다. 하지만 하나의 흐름 안에서 여러 상태가 함께 갱신되어도 persistence authority가 승인된 것으로 해석하지 않는다.

`_applyHistoryEntry(...)`, `_pushHistoryEntry(...)`, `_replaceCurrentHistoryEntry(...)`, `_createHistoryEntry(...)`는 현재 navigation history owner 흐름을 설명하는 reference다. 이 흐름은 history 표시와 back/forward 판단을 위한 것이며 production state persistence 또는 restore authority 승인을 뜻하지 않는다.

#### 17.97.6 Phase 16-D/E/F/G/H/I/J와의 연결

Phase 16-K는 기존 Phase 16-D/E/F/G/H/I/J의 금지선과 boundary를 다음 방식으로 유지한다.

| 이전 Phase | Phase 16-K 연결 방식 |
| --- | --- |
| Phase 16-D | route owner boundary와 route wiring 금지선을 유지한다. |
| Phase 16-E | projection/source-of-truth boundary를 유지한다. |
| Phase 16-F | selection owner boundary와 persistence authority를 분리한다. |
| Phase 16-G | graph center owner boundary와 persistence authority를 분리한다. |
| Phase 16-H | detail target owner boundary와 persistence authority를 분리한다. |
| Phase 16-I | navigation history owner boundary와 persistence authority를 분리한다. |
| Phase 16-J | repository/read owner boundary와 persistence authority를 분리한다. |

#### 17.97.7 Phase 16-K 이후에도 승인되지 않은 항목

Phase 16-K 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `WordRepository` owner migration
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- `ExplorerWorkspaceState.history` navigation history source-of-truth usage
- `ExplorerWorkspaceState` repository/read result source-of-truth usage
- `ExplorerWorkspaceState` loading/error/unavailable source-of-truth usage
- `ExplorerWorkspaceState` persistence source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history/read mutation
- projection result 기반 repository read
- projection result 기반 DB query
- projection result 기반 persistence
- projection result 기반 restore
- projection result 기반 rollback 승인
- history snapshot 기반 persistence
- history snapshot 기반 restore
- Level 3 production-visible consumer 승격
- 새 persistence 기능 추가
- 새 restore 기능 추가
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.97.8 Phase 16-K 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-K 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| persistence authority boundary 문서 반영 확인 | 현재 production persistence authority가 `ExplorerWorkspace`에 없다고 문서화되어야 함 | `ExplorerWorkspace`가 persistence controller 또는 restore controller처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 16-K`, `persistence authority`, `ExplorerWorkspace` 확인 |
| projection/source-of-truth 분리 확인 | `ExplorerWorkspaceState`와 projection result가 persistence source-of-truth가 아니라고 기록되어야 함 | projection result 기반 persistence/restore 승인처럼 읽힘 | 문서 반영 검색 결과에서 `ExplorerWorkspaceState`, `projection representation`, `projection result`, `persistence source-of-truth` 확인 |
| history 계열 boundary 확인 | `_history`, history snapshot, `ExplorerWorkspaceHistoryEntry`, `WordNavigationHistoryController`가 persistence authority 또는 restore authority가 아니라고 기록되어야 함 | history 표현을 production state restore authority처럼 기록 | 문서 반영 검색 결과에서 `_history`, `history snapshot`, `ExplorerWorkspaceHistoryEntry`, `WordNavigationHistoryController` 확인 |
| owner boundary 분리 확인 | route state owner, selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner, persistence authority, rollback authority가 혼동되지 않아야 함 | history/read 흐름의 동시 갱신을 persistence authority 승인처럼 해석 | 문서 반영 검색 결과에서 각 owner/authority 구분 문구 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, persistence authority migration, rollback authority migration, projection result 기반 persistence/restore, history snapshot 기반 persistence/restore, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-K는 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.98 Phase 16-L ExplorerWorkspace rollback authority boundary design

Phase 16-L은 `rollback authority boundary design`을 문서상 고정하는 docs/design only 단계다.

이번 Phase는 rollback authority migration이 아니다. 새 rollback 기능, 새 restore 기능, 새 persistence 기능을 추가하지 않고, `ExplorerWorkspace` shell mount, route wiring, owner/controller/coordinator migration, source-of-truth migration을 승인하지 않는다.

#### 17.98.1 Phase 16-L 성격

| 항목 | Phase 16-L 판단 |
| --- | --- |
| 단계 성격 | docs/design only |
| 구현 범위 | 구현 없음 |
| rollback authority migration | 아님 |
| 새 rollback 기능 / 새 restore 기능 승인 | 없음 |
| 새 persistence 기능 승인 | 없음 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| source-of-truth migration 승인 | 없음 |
| production state rollback/restore 승인 | 없음 |

Phase 16-L의 목적은 현재 production에서 Explorer 상태를 이전 상태로 되돌리거나 projection/history 표현을 근거로 복원하는 rollback authority가 존재하는지와 `ExplorerWorkspaceState`, projection result, `_history`, history snapshot 계열 값을 rollback source-of-truth 또는 restore/rollback authority로 사용할 수 있는지 여부를 문서상 분리하는 것이다. 이 단계는 Phase 16-D의 route owner boundary와 route wiring 금지선, Phase 16-E의 projection/source-of-truth boundary, Phase 16-F의 selection owner boundary, Phase 16-G의 graph center owner boundary, Phase 16-H의 detail target owner boundary, Phase 16-I의 navigation history owner boundary, Phase 16-J의 repository/read owner boundary, Phase 16-K의 persistence authority boundary를 유지한 상태에서 rollback authority boundary만 문서상 정리한다.

#### 17.98.2 현재 production rollback authority 판단

현재 production rollback authority는 `ExplorerWorkspace`에 없다.

| 항목 | 현재 production 해석 | Phase 16-L 유지 기준 |
| --- | --- | --- |
| `ExplorerWorkspace` | preview/read-only/projection boundary로 유지되는 workspace 표현이다. | rollback controller, restore controller, production shell로 승격하지 않는다. |
| `ExplorerWorkspaceState` | selected/center/detail/layout/origin 값을 담는 projection representation이다. | rollback source-of-truth로 사용하지 않는다. |
| projection result | 현재 owner state를 읽어 만든 read-only projection 결과다. | production state rollback/restore 근거로 사용하지 않는다. |
| `_history` | navigation history owner state일 수 있고 back/forward 판단에 사용된다. | rollback authority로 승격하지 않는다. |
| history snapshot 계열 값 | history 표시와 navigation 판단을 위한 표현이다. | production state rollback authority로 사용하지 않는다. |
| `ExplorerWorkspaceHistoryEntry` 계열 표현 | `ExplorerWorkspaceState` snapshot을 감싸는 표현이다. | restore/rollback controller로 해석하지 않는다. |
| `WordNavigationHistoryController` | in-memory back/forward controller다. | rollback authority로 해석하지 않는다. |

`ExplorerWorkspace`는 rollback controller가 아니다.

`ExplorerWorkspace`는 restore controller가 아니다.

`ExplorerWorkspace`는 production shell이 아니다.

back/forward navigation은 rollback authority가 아니다.

Phase 16-L은 rollback authority migration이 아니라 rollback boundary design이다.

#### 17.98.3 `ExplorerWorkspaceState` rollback boundary

`ExplorerWorkspaceState`는 rollback source-of-truth가 아니다.

`ExplorerWorkspaceState`는 production visible UI source-of-truth가 아니다.

`ExplorerWorkspaceState`는 projection representation이다.

projection result는 rollback source-of-truth가 아니다.

따라서 `ExplorerWorkspaceState` 또는 projection result를 근거로 production selection/detail/center/history/read state를 되돌리는 것은 Phase 16-L에서 승인되지 않는다.

`ExplorerWorkspaceState.history` 계열 값, history snapshot 표현, `ExplorerWorkspaceHistoryEntry` 계열 표현을 근거로 production state를 rollback/restore하는 것도 승인되지 않는다.

#### 17.98.4 rollback authority와 다른 owner boundary 구분

Phase 16-L에서는 다음 owner/authority를 rollback authority와 병합하지 않는다.

| 경계 | Phase 16-L 해석 |
| --- | --- |
| route state owner | Explorer route 진입과 route transition을 다루는 책임이며 rollback authority와 동일시하지 않는다. |
| selection owner | 어떤 단어가 선택되었는지를 결정하는 책임이며 rollback authority와 동일시하지 않는다. |
| detail target owner | detail pane이 어떤 단어/표시 항목을 보여줄지를 결정하는 책임이며 rollback authority와 동일시하지 않는다. |
| graph center owner | graph center를 어떤 단어로 둘지를 결정하는 책임이며 rollback authority와 동일시하지 않는다. |
| navigation history owner | 이동 기록과 back/forward 판단을 결정하는 책임이며 rollback authority와 동일시하지 않는다. |
| repository/read owner | detail 표시를 위한 read 요청, read 결과, loading/error/unavailable 상태 흐름을 다루는 책임이며 rollback authority와 동일시하지 않는다. |
| persistence authority | production state를 저장/복원할 권한이며 rollback authority와 동일시하지 않는다. |
| rollback authority | production state를 이전 상태로 되돌리거나 projection/history 표현을 근거로 복원할 권한이며 현재 `ExplorerWorkspace`에 존재하지 않는다. |

navigation history owner와 rollback authority는 동일하지 않다.

persistence authority와 rollback authority는 동일하지 않다.

`_history`가 back/forward 판단에 사용될 수 있어도 rollback authority로 승격하지 않는다.

back/forward navigation은 rollback authority가 아니다.

history snapshot 또는 `ExplorerWorkspaceHistoryEntry` 계열 표현을 근거로 production state를 rollback/restore하는 것은 승인되지 않는다.

rollback authority가 없다는 사실은 route owner, selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner, persistence authority의 현재 production 책임을 변경하지 않는다.

하나의 navigation/history/read 흐름 안에서 여러 상태가 함께 갱신될 수 있어도 rollback authority가 승인된 것으로 해석하지 않는다.

#### 17.98.5 현재 production 흐름 설명

현재 production 흐름에서 `WordExplorerScreen`은 `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, detail loading/error/unavailable 상태, `_history`, `_repository`를 내부 상태와 private instance로 보유한다.

`_readOnlyWorkspaceProjection`은 현재 owner state를 `ExplorerWorkspaceState`로 읽어내는 projection 흐름이다. 이 projection은 state 저장, state 복원, repository read, DB query, rollback 판단을 수행하지 않는다.

`_selectWord(...)`, `_initializeExplorerBootstrap()`, `_refreshSelectedWord(...)` 흐름에서는 selection/detail/center/history/read 상태 갱신이 함께 일어날 수 있다. 하지만 하나의 흐름 안에서 여러 상태가 함께 갱신되어도 rollback authority가 승인된 것으로 해석하지 않는다.

`_applyHistoryEntry(...)`, `_pushHistoryEntry(...)`, `_replaceCurrentHistoryEntry(...)`, `_createHistoryEntry(...)`는 현재 navigation history owner 흐름을 설명하는 reference다. 이 흐름은 history 표시와 back/forward 판단을 위한 것이며 production state rollback 또는 restore authority 승인을 뜻하지 않는다.

#### 17.98.6 Phase 16-D/E/F/G/H/I/J/K와의 연결

Phase 16-L은 기존 Phase 16-D/E/F/G/H/I/J/K의 금지선과 boundary를 다음 방식으로 유지한다.

| 이전 Phase | Phase 16-L 연결 방식 |
| --- | --- |
| Phase 16-D | route owner boundary와 route wiring 금지선을 유지한다. |
| Phase 16-E | projection/source-of-truth boundary를 유지한다. |
| Phase 16-F | selection owner boundary와 rollback authority를 분리한다. |
| Phase 16-G | graph center owner boundary와 rollback authority를 분리한다. |
| Phase 16-H | detail target owner boundary와 rollback authority를 분리한다. |
| Phase 16-I | navigation history owner boundary와 rollback authority를 분리한다. |
| Phase 16-J | repository/read owner boundary와 rollback authority를 분리한다. |
| Phase 16-K | persistence authority boundary와 rollback authority를 분리한다. |

#### 17.98.7 Phase 16-L 이후에도 승인되지 않은 항목

Phase 16-L 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `WordRepository` owner migration
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- `ExplorerWorkspaceState.history` navigation history source-of-truth usage
- `ExplorerWorkspaceState` repository/read result source-of-truth usage
- `ExplorerWorkspaceState` loading/error/unavailable source-of-truth usage
- `ExplorerWorkspaceState` persistence source-of-truth usage
- `ExplorerWorkspaceState` rollback source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history/read mutation
- projection result 기반 repository read
- projection result 기반 DB query
- projection result 기반 persistence
- projection result 기반 restore
- projection result 기반 rollback 승인
- history snapshot 기반 persistence
- history snapshot 기반 restore
- history snapshot 기반 rollback
- `ExplorerWorkspaceHistoryEntry` 기반 restore/rollback
- `WordNavigationHistoryController` rollback authority 승격
- Level 3 production-visible consumer 승격
- 새 rollback 기능 추가
- 새 restore 기능 추가
- 새 persistence 기능 추가
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.98.8 Phase 16-L 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-L 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| rollback authority boundary 문서 반영 확인 | 현재 production rollback authority가 `ExplorerWorkspace`에 없다고 문서화되어야 함 | `ExplorerWorkspace`가 rollback controller 또는 restore controller처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 16-L`, `rollback authority`, `ExplorerWorkspace` 확인 |
| projection/source-of-truth 분리 확인 | `ExplorerWorkspaceState`와 projection result가 rollback source-of-truth가 아니라고 기록되어야 함 | projection result 기반 rollback/restore 승인처럼 읽힘 | 문서 반영 검색 결과에서 `ExplorerWorkspaceState`, `projection representation`, `projection result`, `rollback source-of-truth` 확인 |
| history 계열 boundary 확인 | `_history`, history snapshot, `ExplorerWorkspaceHistoryEntry`, `WordNavigationHistoryController`가 rollback authority 또는 restore authority가 아니라고 기록되어야 함 | history 표현을 production state rollback/restore authority처럼 기록 | 문서 반영 검색 결과에서 `_history`, `history snapshot`, `ExplorerWorkspaceHistoryEntry`, `WordNavigationHistoryController` 확인 |
| owner boundary 분리 확인 | route state owner, selection owner, detail target owner, graph center owner, navigation history owner, repository/read owner, persistence authority, rollback authority가 혼동되지 않아야 함 | history/read 흐름의 동시 갱신을 rollback authority 승인처럼 해석 | 문서 반영 검색 결과에서 각 owner/authority 구분 문구 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, persistence authority migration, rollback authority migration, projection result 기반 rollback/restore, history snapshot 기반 rollback/restore, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-L은 docs/design only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.99 Phase 16-M ExplorerWorkspace implementation entry / guardrail redefinition audit

Phase 16-M은 `ExplorerWorkspace implementation entry / guardrail redefinition audit` docs/audit only 단계다.

이번 Phase는 implementation 단계가 아니다. `ExplorerWorkspace` production shell mount, route wiring, owner/controller/coordinator migration, `ExplorerWorkspaceState` source-of-truth 승격, 신규 test 추가, 기존 test 수정, `lib/` 변경을 승인하지 않는다.

구현 진입 가능성 검토와 구현 승인은 동일하지 않다.

guardrail redefinition 필요성 검토와 test 추가 승인은 동일하지 않다.

Phase 17-A 후보 선정 준비와 Phase 17 구현 착수는 동일하지 않다.

#### 17.99.1 Phase 16-M 성격

| 항목 | Phase 16-M 판단 |
| --- | --- |
| 단계 성격 | docs/audit only |
| 구현 범위 | 구현 없음 |
| implementation approval | 없음 |
| guardrail test 추가 승인 | 없음 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| `ExplorerWorkspaceState` source-of-truth 승격 | 없음 |
| 신규 test 추가 / 기존 test 수정 | 없음 |
| `lib/` 변경 | 없음 |

Phase 16-M의 목적은 Phase 16-D부터 Phase 16-L까지 문서상 고정한 owner/authority boundary를 기준으로 구현 진입 가능 여부와 guardrail redefinition 필요성을 audit하는 것이다. 이 audit은 Phase 17-A 후보 선정 준비를 위한 문서 판단이며, Phase 17 구현 착수 또는 구현 승인으로 해석하지 않는다.

`ExplorerWorkspaceState`는 계속 projection representation으로 유지된다.

`ExplorerWorkspace`는 아직 production shell이 아니다.

`ExplorerWorkspace`는 route owner, selection owner, graph center owner, detail target owner, navigation history owner, repository/read owner, persistence authority, rollback authority가 아니다.

#### 17.99.2 Phase 16-D/E/F/G/H/I/J/K/L boundary 종합

Phase 16-M은 기존 Phase 16-D/E/F/G/H/I/J/K/L의 결론을 다음 방식으로 종합한다.

| 이전 Phase | Phase 16-M 종합 |
| --- | --- |
| Phase 16-D | route owner boundary 유지 |
| Phase 16-E | projection/source-of-truth boundary 유지 |
| Phase 16-F | selection owner boundary 유지 |
| Phase 16-G | graph center owner boundary 유지 |
| Phase 16-H | detail target owner boundary 유지 |
| Phase 16-I | navigation history owner boundary 유지 |
| Phase 16-J | repository/read owner boundary 유지 |
| Phase 16-K | persistence authority boundary 유지 |
| Phase 16-L | rollback authority boundary 유지 |

이 종합은 기존 boundary를 구현 승인으로 승격하지 않는다. Phase 16-D/E/F/G/H/I/J/K/L에서 고정한 owner/authority boundary는 구현 진입 판단의 기준으로 사용할 수 있지만, 각 boundary의 owner migration 또는 authority migration을 자동 승인하지 않는다.

#### 17.99.3 구현 진입 가능성 분류

Phase 16-M에서 구현 진입 가능성은 다음처럼 분류한다.

바로 승인하지 않는 구현:

- `ExplorerWorkspace` production shell mount
- `HomeScreen -> ExplorerWorkspace` route wiring
- `WordExplorerScreen` owner migration
- `ExplorerWorkspaceState` production source-of-truth 승격
- projection result 기반 selection/detail/center/history/read mutation
- projection result 기반 persistence/restore/rollback
- 새 repository read
- 새 DB query
- persistence/rollback 기능 추가
- Level 3 production-visible consumer 승격

Phase 17-A 후보로 검토 가능한 항목:

- implementation candidate selection audit
- guardrail redefinition audit
- preview/projection boundary 보호 test 후보 선정
- `ExplorerWorkspaceState` projection contract 보강 후보 검토
- production-visible UX diff 후보 audit
- shell mount 전 선행 guardrail/test 설계
- hidden probe / preview-only boundary 보호 강화

Phase 17-A 후보는 구현 자체가 아니라 구현 후보 선정 audit으로 제한한다. Phase 17-B 이후에만 별도 승인 하에 guardrail test 또는 preview/projection boundary 보호 구현을 검토할 수 있다.

`ExplorerWorkspace` production shell mount는 Phase 17-A의 직접 구현 후보로 올리지 않는다.

route wiring 변경은 Phase 17-A의 직접 구현 후보로 올리지 않는다.

owner migration은 Phase 17-A의 직접 구현 후보로 올리지 않는다.

#### 17.99.4 guardrail redefinition audit 판단

기존 preview/projection guardrail은 Phase 17 진입 전 재정의 필요성을 audit할 수 있다. 다만 guardrail redefinition 필요성 검토는 test 추가 승인과 동일하지 않다.

현재 guardrail 판단 기준은 다음과 같이 유지한다.

- `ExplorerWorkspaceState`는 selected/center/detail/layout/origin 값을 담는 projection representation이다.
- `WordExplorerWorkspaceProjectionAdapter.project(...)`는 source-of-truth adapter가 아니라 read-only projection adapter다.
- `_readOnlyWorkspaceProjection`은 현재 owner state를 읽어 projection snapshot을 만드는 흐름이며 mutation/read/persistence/rollback을 수행하지 않는다.
- hidden probe와 preview-only boundary는 production route, production shell, repository/read owner, Navigator owner, persistence authority, rollback authority로 확장하지 않는다.
- Level 3 production-visible consumer 승격은 아직 승인하지 않는다.

Phase 17-A에서는 guardrail/test 구현이 아니라 guardrail/test 후보를 선정하는 audit만 수행할 수 있다.

#### 17.99.5 Phase 16-M 이후에도 승인되지 않은 항목

Phase 16-M 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `WordRepository` owner migration
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- `ExplorerWorkspaceState.history` navigation history source-of-truth usage
- `ExplorerWorkspaceState` repository/read result source-of-truth usage
- `ExplorerWorkspaceState` loading/error/unavailable source-of-truth usage
- `ExplorerWorkspaceState` persistence source-of-truth usage
- `ExplorerWorkspaceState` rollback source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history/read mutation
- projection result 기반 repository read
- projection result 기반 DB query
- projection result 기반 persistence
- projection result 기반 restore
- projection result 기반 rollback 승인
- history snapshot 기반 persistence
- history snapshot 기반 restore
- history snapshot 기반 rollback
- `ExplorerWorkspaceHistoryEntry` 기반 restore/rollback
- `WordNavigationHistoryController` rollback authority 승격
- Level 3 production-visible consumer 승격
- 새 rollback 기능 추가
- 새 restore 기능 추가
- 새 persistence 기능 추가
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.99.6 Phase 16-M 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-M 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| docs/audit only 성격 확인 | Phase 16-M이 implementation 단계가 아니며 구현 승인과 분리되어야 함 | shell mount, route wiring, owner migration 승인처럼 읽힘 | 문서 반영 검색 결과에서 `Phase 16-M`, `docs/audit only`, `implementation entry`, `guardrail redefinition` 확인 |
| 기존 boundary 종합 확인 | Phase 16-D/E/F/G/H/I/J/K/L owner/authority boundary가 유지되어야 함 | 이전 Phase 결론이 owner/authority migration 승인처럼 기록됨 | 문서 반영 검색 결과에서 Phase 16-D부터 Phase 16-L까지의 연결 확인 |
| Phase 17-A 후보 제한 확인 | Phase 17-A 후보가 implementation candidate selection audit 또는 guardrail/test 후보 선정으로 제한되어야 함 | Phase 17-A가 shell mount, route wiring, owner migration 직접 구현 후보처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 17-A`, `candidate selection`, `guardrail/test` 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, source-of-truth 승격, projection result 기반 mutation/read/persistence/rollback, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-M은 docs/audit only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.100 Phase 16-N ExplorerWorkspace Phase 16 termination audit

Phase 16-N은 `ExplorerWorkspace Phase 16 termination audit` docs/audit only 단계다.

이번 Phase는 Phase 16 전체 종료 가능 여부를 판단하고, Phase 16에서 고정한 owner/authority boundary와 아직 승인되지 않은 금지선을 최종 정리하는 termination audit이다.

Phase 16-N은 구현 단계가 아니다.

Phase 16-N은 Phase 17-A 구현 착수 단계가 아니다.

Phase 16-N은 `ExplorerWorkspace` shell mount 승인 단계가 아니다.

Phase 16-N은 route wiring 승인 단계가 아니다.

Phase 16-N은 owner/controller/coordinator migration 승인 단계가 아니다.

Phase 16-N은 `ExplorerWorkspaceState` source-of-truth 승격 단계가 아니다.

Phase 16-N은 projection result 기반 mutation/read/persistence/rollback 승인 단계가 아니다.

#### 17.100.1 Phase 16-N 성격

| 항목 | Phase 16-N 판단 |
| --- | --- |
| 단계 성격 | docs/audit only |
| audit 범위 | Phase 16 전체 종료 가능 여부 |
| 구현 범위 | 구현 없음 |
| Phase 17-A 구현 착수 | 없음 |
| `ExplorerWorkspace` shell mount 승인 | 없음 |
| route wiring 승인 | 없음 |
| owner/controller/coordinator migration 승인 | 없음 |
| `ExplorerWorkspaceState` source-of-truth 승격 | 없음 |
| projection result 기반 mutation/read/persistence/rollback 승인 | 없음 |
| 신규 test 추가 / 기존 test 수정 | 없음 |
| `lib/`, `test/`, DB, dependency, platform, pubspec 변경 | 없음 |

Phase 16-N의 목적은 Phase 16-A부터 Phase 16-M까지의 audit/boundary 흐름을 종합해 Phase 16을 종료 가능한 boundary/audit phase로 볼 수 있는지 판단하는 것이다. 이 판단은 production transition 구현 승인이나 Phase 17-A 구현 착수 승인으로 해석하지 않는다.

#### 17.100.2 Phase 16-A부터 Phase 16-N까지의 흐름 종합

| Phase | Phase 16-N 종합 |
| --- | --- |
| Phase 16-A | production transition readiness audit |
| Phase 16-B | production transition blocker inventory |
| Phase 16-C | transition path sequencing audit |
| Phase 16-D | route owner boundary |
| Phase 16-E | projection/source-of-truth boundary |
| Phase 16-F | selection owner boundary |
| Phase 16-G | graph center owner boundary |
| Phase 16-H | detail target owner boundary |
| Phase 16-I | navigation history owner boundary |
| Phase 16-J | repository/read owner boundary |
| Phase 16-K | persistence authority boundary |
| Phase 16-L | rollback authority boundary |
| Phase 16-M | implementation entry / guardrail redefinition audit |
| Phase 16-N | Phase 16 termination audit |

Phase 16-A/B/C는 production transition 논의를 구현으로 옮기기 전에 readiness, blocker, sequencing을 문서상 정리했다.

Phase 16-D/E/F/G/H/I/J/K/L은 route, projection/source-of-truth, selection, graph center, detail target, navigation history, repository/read, persistence, rollback owner/authority boundary를 각각 분리해 고정했다.

Phase 16-M은 이 boundary를 기준으로 implementation entry와 guardrail redefinition 필요성을 audit했지만, 구현 승인 또는 guardrail test 추가 승인으로 승격하지 않았다.

Phase 16-N은 위 흐름을 Phase 16 전체 종료 audit으로 종합한다. Phase 16-N은 새 owner를 추가하지 않고, 기존 boundary를 production owner migration으로 승격하지 않는다.

#### 17.100.3 Phase 16 종료 판단

Phase 16은 `ExplorerWorkspace` production transition을 위한 boundary/audit phase로 종료 가능하다.

Phase 16은 구현 phase가 아니었다.

`ExplorerWorkspace` shell mount는 Phase 16에서 승인되지 않았다.

route wiring / route registration change는 Phase 16에서 승인되지 않았다.

`HomeScreen -> WordExplorerScreen` 진입 구조 변경은 Phase 16에서 승인되지 않았다.

owner/controller/coordinator migration은 Phase 16에서 승인되지 않았다.

`ExplorerWorkspaceState` production source-of-truth 승격은 Phase 16에서 승인되지 않았다.

projection result 기반 production mutation/read/persistence/restore/rollback은 Phase 16에서 승인되지 않았다.

새 repository read, 새 DB query, 신규 DTO/model/public API 추가는 Phase 16에서 승인되지 않았다.

신규 test 추가, 기존 test 수정, `lib/`, `test/`, DB, dependency, platform, `pubspec.yaml`, `pubspec.lock` 변경은 Phase 16-N에서 수행하지 않는다.

#### 17.100.4 Phase 17-A 후보 제한

Phase 17-A는 implementation candidate selection audit으로 시작한다.

Phase 17-A는 구현 착수 단계가 아니다.

Phase 17-A는 `ExplorerWorkspace` production shell mount 단계가 아니다.

Phase 17-A는 `HomeScreen -> ExplorerWorkspace` route wiring 단계가 아니다.

Phase 17-A는 owner migration 단계가 아니다.

Phase 17-A에서는 구현 후보를 선정하되, 직접 구현은 별도 Phase 17-B 이후 별도 승인으로 분리한다.

Phase 17-A 후보군은 아래 범위로 제한한다.

- implementation candidate selection audit
- guardrail/test 후보 선정
- preview/projection boundary 보호 후보 선정
- production-visible UX diff 후보 재검토
- shell mount 전 선행 조건 audit
- hidden probe / preview-only boundary 보호 강화 후보 검토
- `ExplorerWorkspaceState` projection contract 보강 후보 검토

Phase 17-A의 직접 구현 후보에서 제외할 항목은 다음과 같다.

- `ExplorerWorkspace` production shell mount
- `HomeScreen -> ExplorerWorkspace` route wiring
- `WordExplorerScreen` owner migration
- `ExplorerWorkspaceState` production source-of-truth 승격
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- projection result 기반 production mutation
- 새 repository read
- 새 DB query

#### 17.100.5 Phase 16-N 이후에도 승인되지 않은 항목

Phase 16-N 이후에도 아래 항목은 승인되지 않은 상태로 유지한다. 아래 금지선은 not approved 상태다.

- `ExplorerWorkspace` shell mount
- route wiring / route registration change
- `HomeScreen -> WordExplorerScreen` 진입 구조 변경
- route collapse
- canonical owner migration
- Navigator authority migration
- owner/controller/coordinator migration
- Provider / Repository / Navigator / persistence authority migration
- `WordRepository` owner migration
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- `ExplorerWorkspaceState` production source-of-truth usage
- `ExplorerWorkspaceState` route state source-of-truth usage
- `ExplorerWorkspaceState` selection source-of-truth usage
- `ExplorerWorkspaceState` detail target source-of-truth usage
- `ExplorerWorkspaceState.centerWordId` graph center source-of-truth usage
- `ExplorerWorkspaceState.history` navigation history source-of-truth usage
- `ExplorerWorkspaceState` repository/read result source-of-truth usage
- `ExplorerWorkspaceState` loading/error/unavailable source-of-truth usage
- `ExplorerWorkspaceState` persistence source-of-truth usage
- `ExplorerWorkspaceState` rollback source-of-truth usage
- projection result persistence/history/source-of-truth usage
- projection result 기반 selection/detail/center/history/read mutation
- projection result 기반 repository read
- projection result 기반 DB query
- projection result 기반 persistence
- projection result 기반 restore
- projection result 기반 rollback 승인
- history snapshot 기반 persistence
- history snapshot 기반 restore
- history snapshot 기반 rollback
- `ExplorerWorkspaceHistoryEntry` 기반 restore/rollback
- `WordNavigationHistoryController` rollback authority 승격
- Level 3 production-visible consumer 승격
- 새 rollback 기능 추가
- 새 restore 기능 추가
- 새 persistence 기능 추가
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API 추가
- 신규 test 추가
- 기존 test 수정
- `lib/` 변경
- `test/` 변경
- DB 변경
- 플랫폼 파일 변경
- dependency 변경
- `pubspec.yaml` 변경
- `pubspec.lock` 변경

#### 17.100.6 Phase 16-N 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 16-N 문서 변경 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | 허용 범위 밖 파일 변경 | `git diff --name-status`, `git diff --name-only` |
| docs/audit only 성격 확인 | Phase 16-N이 implementation 단계가 아니며 Phase 17-A 구현 착수와 분리되어야 함 | shell mount, route wiring, owner migration, source-of-truth 승격 승인처럼 읽힘 | 문서 반영 검색 결과에서 `Phase 16-N`, `termination audit`, `docs/audit only` 확인 |
| Phase 16-A부터 Phase 16-M까지의 흐름 종합 확인 | Phase 16 전체가 readiness, blocker, sequencing, owner/authority boundary, implementation entry audit 흐름으로 정리되어야 함 | Phase 16 일부 흐름 누락 또는 구현 승인처럼 기록됨 | 문서 반영 검색 결과에서 Phase 16-A부터 Phase 16-M까지의 연결 확인 |
| Phase 17-A 후보 제한 확인 | Phase 17-A가 implementation candidate selection audit으로 제한되어야 함 | Phase 17-A가 production shell mount, route wiring, owner migration 직접 구현 후보처럼 기록됨 | 문서 반영 검색 결과에서 `Phase 17-A`, `implementation candidate selection audit` 확인 |
| 금지선 유지 확인 | shell mount, route wiring, owner migration, source-of-truth 승격, projection result 기반 mutation/read/persistence/rollback, `lib/`, `test/`, DB, dependency, platform, pubspec 변경이 승인되지 않은 상태로 남아야 함 | 구현 승인처럼 읽히는 문구 또는 금지 영역 변경 | 문서 반영 검색과 `git diff --name-only` 확인 |

Phase 16-N은 docs/audit only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.101 Phase 17-A ExplorerWorkspace implementation candidate selection audit

Phase 17-A는 `ExplorerWorkspace implementation candidate selection audit` docs/audit only 단계다.

Phase 17-A는 구현 착수 단계가 아니다.

Phase 17-A는 `ExplorerWorkspace` shell mount 단계가 아니다.

Phase 17-A는 route wiring 단계가 아니다.

Phase 17-A는 owner migration 단계가 아니다.

Phase 17-A의 목적은 Phase 16 boundary를 기준으로 Phase 17-B 이후 실행 가능한 최소 구현 후보를 분류하는 것이다.

이번 audit은 구현 후보군을 분류하지만, 그 자체가 구현 승인 또는 production transition 승인으로 해석되지 않는다.

#### 17.101.1 Phase 17-A 성격

| 항목 | Phase 17-A 판단 |
| --- | --- |
| 단계 성격 | docs/audit only |
| 목적 | Phase 16 boundary 기준 최소 구현 후보 분류 |
| 구현 착수 | 없음 |
| shell mount | 없음 |
| route wiring | 없음 |
| owner migration | 없음 |
| `ExplorerWorkspaceState` source-of-truth 승격 | 없음 |
| projection result 기반 production mutation/read/persistence/restore/rollback | 없음 |
| `lib/`, `test/`, DB, dependency, platform, pubspec 변경 | 없음 |

#### 17.101.2 구현 후보군 분류

| 후보군 | Phase 16 boundary 충돌 여부 | production route 변경 여부 | `WordExplorerScreen` owner 이동 여부 | `ExplorerWorkspaceState` source-of-truth 오해 가능성 | projection result production mutation/read/persistence/rollback 사용 여부 | Phase 17-B 후보 가능성 |
| --- | --- | --- | --- | --- | --- | --- |
| A. guardrail/test 후보 | boundary 보호 목적이면 충돌 없음 | 없음 | 없음 | source-of-truth 금지선을 테스트 대상으로 명시하면 낮음 | 사용 금지를 검증 대상으로 삼음 | 가능 |
| B. preview/projection boundary 보호 후보 | preview/read-only boundary 보호 목적이면 충돌 없음 | 없음 | 없음 | projection representation을 명시하면 낮음 | read-only projection 외 사용 금지 | 가능 |
| C. production-visible UX diff 후보 | 작고 rollback 가능한 `WordExplorerScreen` 내부 UX diff로 제한할 때만 충돌 없음 | 없음 | 없음 | `ExplorerWorkspaceState`를 visible source-of-truth로 쓰면 충돌 | projection result를 UX 상태 결정에 쓰면 충돌 | 제한적 가능 |
| D. shell mount 전 선행 조건 audit 후보 | audit only이면 충돌 없음 | 없음 | 없음 | source-of-truth 승격 전제처럼 쓰면 충돌 | production read/write 전제처럼 쓰면 충돌 | 가능 |
| E. hidden probe / preview-only boundary 보호 후보 | hidden probe가 preview-only boundary에 남으면 충돌 없음 | 없음 | 없음 | probe 결과를 production UI source로 쓰면 충돌 | probe 결과를 mutation/read/persistence/rollback에 쓰면 충돌 | 가능 |
| F. `ExplorerWorkspaceState` projection contract 보강 후보 | projection contract 보강이면 충돌 없음 | 없음 | 없음 | source-of-truth가 아님을 contract로 고정해야 함 | production mutation/read/persistence/rollback 입력 금지 | 가능 |

#### 17.101.3 후보군별 판단

A. guardrail/test 후보는 Phase 16 boundary를 보호하는 방향으로만 Phase 17-B 후보가 될 수 있다. 이 후보는 production route를 변경하지 않고, `WordExplorerScreen` owner를 이동시키지 않으며, `ExplorerWorkspaceState`를 source-of-truth로 승격하지 않는 조건을 검증 대상으로 삼아야 한다.

B. preview/projection boundary 보호 후보는 `ExplorerWorkspace`와 projection adapter가 read-only boundary로 남는지 확인하는 범위로 제한할 때 Phase 17-B 후보가 될 수 있다. projection result는 production mutation/read/persistence/rollback에 사용하지 않는다.

C. production-visible UX diff 후보는 Phase 17-A에서 직접 구현하지 않는다. 이후 후보로 검토하더라도 production route 비변경, `WordExplorerScreen` owner 유지, `ExplorerWorkspaceState` 비-source-of-truth, projection result 비사용 조건을 동시에 만족해야 한다.

D. shell mount 전 선행 조건 audit 후보는 shell mount 자체가 아니다. 이 후보는 shell mount 전에 필요한 guardrail, route owner boundary, repository/read owner boundary, source-of-truth boundary가 문서와 테스트로 보호되는지 확인하는 audit 후보로만 유지한다.

E. hidden probe / preview-only boundary 보호 후보는 hidden probe와 preview-only host가 production route, production shell, repository/read owner, Navigator owner, persistence authority, rollback authority로 확장되지 않도록 보호하는 후보다. probe 결과는 production UI state나 production read/write 입력이 아니다.

F. `ExplorerWorkspaceState` projection contract 보강 후보는 `ExplorerWorkspaceState`가 selected/center/detail/layout/origin/history 계열 값을 담는 projection representation이라는 점을 더 명확히 고정하는 후보다. 이 contract는 source-of-truth contract가 아니며, production mutation/read/persistence/restore/rollback contract가 아니다.

#### 17.101.4 Phase 17-A 직접 구현 후보 제외 항목

Phase 17-A의 직접 구현 후보에서 아래 항목은 제외한다.

- `ExplorerWorkspace` production shell mount
- `HomeScreen -> ExplorerWorkspace` route wiring
- `WordExplorerScreen` owner migration
- `ExplorerWorkspaceState` production source-of-truth 승격
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- projection result 기반 production mutation/read/persistence/restore/rollback
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API
- `lib/`, `test/`, DB, dependency, platform, pubspec 변경

#### 17.101.5 Phase 17-B 이후 최소 후보

Phase 17-B 최소 후보는 shell mount나 route wiring이 아니라, production route 비변경, `ExplorerWorkspaceState` 비-source-of-truth, projection read-only boundary를 고정하는 guardrail/test 후보 중 하나로 제한하는 것이 가장 안전하다.

이 문장은 확정 구현 승인이 아니다. Phase 17-B 이후 실제 구현은 별도 승인과 별도 변경 범위 확인 이후에만 검토한다.

#### 17.101.6 Phase sequencing 금지선

Phase 17-A에서는 shell mount, route wiring, owner migration을 금지한다.

Phase 17-B는 guardrail/test 후보 구현 전용으로 제한하는 경우에 한해 검토 가능하다.

Phase 17-C 이후에는 guardrail 결과를 바탕으로 shell mount 선행 조건을 재검토할 수 있다.

owner migration은 shell mount와 route wiring보다 더 늦은 별도 phase에서만 검토 가능하다.

#### 17.101.7 Phase 17-A 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| 현재 브랜치와 변경 상태 확인 | Phase 17-A docs 브랜치에서 허용 파일만 변경되어야 함 | 다른 브랜치에서 작업하거나 허용 범위 밖 변경 발생 | `git status --short --branch` |
| 변경 파일 범위 확인 | `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`만 변경되어야 함 | `lib/`, `test/`, DB, dependency, platform, pubspec 변경 포함 | `git diff --name-only` |
| UX audit 문서 변경 확인 | Phase 17-A 섹션이 추가되어야 함 | Phase 17-A가 구현 승인처럼 기록됨 | `docs/ux/explorer_workspace_unification.md` 변경 확인 |
| changelog 변경 확인 | Phase 17-A changelog 항목이 추가되어야 함 | 실제 구현 또는 금지선 변경처럼 기록됨 | `docs/logs/CHANGELOG.md` 변경 확인 |
| `lib/` 변경 없음 확인 | `lib/` 하위 변경이 없어야 함 | shell mount, route wiring, owner migration 구현 포함 | `git diff --name-only` |
| `test/` 변경 없음 확인 | 신규 test 추가 또는 기존 test 수정이 없어야 함 | Phase 17-A가 guardrail 구현 단계로 변질 | `git diff --name-only` |
| DB 변경 없음 확인 | DB schema, migration, SQL 변경이 없어야 함 | 새 DB query 또는 data boundary 변경 포함 | `git diff --name-only` |
| pubspec/dependency/platform 변경 없음 확인 | `pubspec.yaml`, `pubspec.lock`, dependency, platform 파일 변경이 없어야 함 | dependency 또는 platform 설정 변경 포함 | `git diff --name-only` |

Phase 17-A는 docs/audit only이며 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없으면 `flutter test`는 실행하지 않는다. 변경 파일 범위가 허용된 두 문서 밖으로 벗어나면 작업을 중단하고 보고한다.

### 17.102 Phase 17-B ExplorerWorkspace transition guardrail minimum slice

Phase 17-B는 `ExplorerWorkspace transition guardrail/test minimum slice selection` 이후의 test-only guardrail minimum slice 단계다.

이번 Phase는 production shell mount 단계가 아니다.

이번 Phase는 route wiring 단계가 아니다.

이번 Phase는 owner migration 단계가 아니다.

이번 Phase는 production-visible UX diff 단계가 아니다.

이번 Phase의 목적은 production route transition 금지선을 테스트로 고정하는 것이다.

#### 17.102.1 Phase 17-B 성격

| 항목 | Phase 17-B 판단 |
| --- | --- |
| 단계 성격 | test-only guardrail minimum slice |
| 신규 테스트 | `test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart` |
| production route 변경 | 없음 |
| shell mount | 없음 |
| route wiring | 없음 |
| owner migration | 없음 |
| `ExplorerWorkspaceState` source-of-truth 승격 | 없음 |
| production-visible UX diff | 없음 |
| 신규 public API / DTO / model / repository read / DB query | 없음 |

#### 17.102.2 고정한 production boundary

Phase 17-B guardrail은 아래 boundary를 고정한다.

- production route는 `main.dart -> HomeScreen -> WordExplorerScreen` 흐름을 유지한다.
- `lib/main.dart`는 production home으로 `HomeScreen`을 유지한다.
- `lib/ui/home_screen.dart`는 `WordExplorerScreen`을 import하는 production explorer entry를 유지한다.
- `HomeScreen` 기본 explorer 진입은 `WordExplorerScreen(initialWordId: normalizedWordId)` 생성 흐름을 유지한다.
- `ExplorerWorkspace`는 production shell 또는 route target이 아니다.
- preview entrypoint, preview screen, preview host는 production 경로에 연결되지 않는다.
- `ExplorerWorkspace` named route wiring은 production 경로에 추가되지 않는다.

#### 17.102.3 false positive 방지 기준

Phase 17-B guardrail은 production entry files와 `HomeScreen` route wiring에 한정한다.

`WordExplorerScreen`이 `explorer_workspace_contract.dart` 또는 `word_explorer_workspace_projection_adapter.dart`를 import하는 것은 Phase 7 이후 허용된 read-only projection boundary로 유지한다.

preview-only 파일이 별도 entrypoint로 존재하는 것 자체는 실패 조건으로 삼지 않는다.

#### 17.102.4 유지 금지선

Phase 17-B에서는 아래 항목을 수행하지 않았다.

- `ExplorerWorkspace` production shell mount
- `HomeScreen -> ExplorerWorkspace` route wiring
- `WordExplorerScreen` owner migration
- `ExplorerWorkspaceState` production source-of-truth 승격
- repository/read owner migration
- persistence authority migration
- rollback authority migration
- projection result 기반 production mutation/read/persistence/restore/rollback
- 새 repository read
- 새 DB query
- 신규 DTO/model/public API
- production-visible UX diff
- `lib/` 변경
- production 코드 변경

#### 17.102.5 명령어 기반 확인 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| Phase 17-B 신규 guardrail 테스트 확인 | 신규 테스트가 통과해야 함 | production route, shell mount, preview 연결, named route wiring guardrail 실패 | `flutter test test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart` |
| production route 비변경 확인 | `main.dart -> HomeScreen -> WordExplorerScreen` 흐름이 유지되어야 함 | `HomeScreen` home 변경 또는 `WordExplorerScreen` 진입 변경 | 신규 guardrail 테스트와 source diff 확인 |
| production shell mount 없음 확인 | `ExplorerWorkspace`가 production shell 또는 route target으로 mount되지 않아야 함 | `ExplorerWorkspace(` 또는 shell import가 production entry에 유입 | 신규 guardrail 테스트와 `git diff --name-only` |
| preview 연결 없음 확인 | preview entrypoint, preview screen, preview host가 production 경로에 연결되지 않아야 함 | preview-only surface가 `main.dart` 또는 `HomeScreen`에 유입 | 신규 guardrail 테스트 |
| 금지선 유지 확인 | owner/source-of-truth/repository/persistence/rollback/DB/API/UX diff가 없어야 함 | `lib/` 변경, 신규 read/query/API, production-visible UX diff 포함 | `git diff --name-only`, `git diff --check`, 테스트 결과 확인 |

Phase 17-B는 test-only guardrail 단계이므로 production-visible UI 확인은 사용자가 수행하는 UI 테스트 대상이 아니다. 이번 Phase의 완료 여부는 명령어 기반 테스트와 변경 파일 범위 확인으로 판단한다.

### 17.103 Phase 18-A HomeScreen large-screen split shell responsive follow-up

Phase 18-A는 PC/태블릿 large width에서 `HomeScreen`을 유지한 채 우측에 `WordExplorerScreen` 기반 Explorer pane을 함께 표시하는 첫 production-visible 전환 slice다.

이번 Phase에서 해제한 범위는 large-screen `HomeScreen` layout 안에서 Graph/Detail Area를 함께 mount하는 데 한정한다. `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` source-of-truth 승격, `WordExplorerScreen` owner migration, repository/read owner migration은 수행하지 않는다.

small width에서는 이번 Phase의 범위를 확장하지 않고 기존 detail/route 진입 흐름을 유지한다. 따라서 small-screen에서 단어 선택 시 split pane이 아니라 기존 상세 화면으로 이동하는 동작은 Phase 18-A의 실패 조건이 아니다.

다만 장기 UX 목표에서는 graph와 detail을 완전히 분리된 별도 화면으로 다루지 않는다. 후속 responsive workspace 정책에서는 graph/detail을 하나의 workspace 안에서 표시 영역이 조정되는 surface로 재정리해야 한다.

Phase 18-A의 small width guardrail은 아래 두 가지를 함께 고정한다.

- small width에서는 embedded Explorer pane이 `HomeScreen` body에 mount되지 않는다.
- 기존 route/detail 진입 흐름은 후속 responsive workspace 정책 전까지 유지한다.

### 17.104 Phase 18-B HomeScreen left control pane narrowing

Phase 18-B는 Strong Rail 완성이 아니다. 이번 단계는 Phase 18-A에서 도입한 large-screen `HomeScreen` split shell을 장기 PC/태블릿 UX 방향에 맞게 한 단계 조정하는 left control pane narrowing minimum slice다.

large width에서 좌측 Home search/list pane은 `flex: 3`에서 `flex: 2`로 줄이고, 우측 `WordExplorerScreen` Graph/Detail Area는 `flex: 5`에서 `flex: 6`으로 넓힌다. 검색/list 구조, small-screen route/detail 흐름, `WordExplorerScreen` owner state는 유지한다.

이번 단계에서는 초협폭 rail UI, Strong 번호 전용 rail, 좌측 단어 추가 버튼, create flow public API, `WordGraphScreen` 내부 create flow 이동을 구현하지 않는다.

`ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, repository/read owner migration, 새 repository read, 새 DB query, DTO/model/public API 추가는 수행하지 않는다. large-screen 임시 default target은 `H0001_0000`으로 유지한다.

### 17.105 Phase 18-C HomeScreen left control surface boundary

Phase 18-C의 목적은 Phase 18-B 이후 좁아진 large-screen 좌측 pane을 단순 Home list 축소로 둘지, 장기 left control surface 후보로 다룰 수 있는지 실제 코드 기준으로 확인하는 것이다. 이번 단계는 full Strong Rail 구현이나 ownership migration 단계가 아니다.

현재 좌측 pane의 production 책임은 `HomeScreen` 내부에 있다. `TextField`, 검색/초기화 `IconButton`, 기본 Strong 목록, 검색 결과 목록, large-screen 목록 선택 시 `_largeScreenExplorerWordId` 갱신을 같은 owner가 처리한다. 이 책임은 `WordExplorerScreen`, `ExplorerWorkspaceState`, repository owner로 이동하지 않는다.

left control surface의 장기 책임 후보는 persistent search entry, Strong anchor 접근, workspace orientation, 단어 생성 진입점 후보를 포함할 수 있다. 다만 Phase 18-C에서 안전하게 구현 가능한 범위는 기존 search/list state와 read 흐름을 유지한 채 large-screen 상단 검색 control area를 시각적으로 분리하는 것에 한정한다.

persistent search/control area는 새 DB query, 새 repository read, 신규 DTO/model/public API 없이 구현 가능하다고 판단했다. 이에 large-screen에서 검색 입력 영역을 `homeSearchControlArea`로 분리하고 배경과 하단 경계를 부여해 좌측 pane의 상단 control surface로 보이게 했다. small-screen에서는 기존 `homePane` 흐름을 유지한다.

단어 추가 접근점은 Phase 18-C에서 구현하지 않는다. 현재 단어 추가 버튼은 `WordGraphScreen` graph app bar의 `Icons.note_add`이며, 실제 흐름은 private `_showCreateWordFlow()` 내부에서 duplicate check, create write, edit seed read, `WordEditScreen.fromSeed`, relation option, graph refresh를 처리한다. 이 흐름을 좌측 pane에서 직접 호출하려면 public/route-level entry 또는 owner 경계 재정의가 필요하므로 현재 금지선 안에서는 추천하지 않는다.

Strong Rail 실제 구현은 보류한다. Strong 번호 중심 초협폭 rail은 source-of-truth, selected/center authority, scroll/jump state, search/list와 graph/detail 사이의 continuity rule이 필요하다. 현재 Phase 18-C에서는 이 authority를 새로 만들거나 `ExplorerWorkspaceState`로 승격하지 않는다. 다음 단계에서는 Strong Rail behavior, selection rule, jump behavior, keyboard access, navigation continuity를 별도 후보로 먼저 정의해야 한다.

유지한 금지선은 `ExplorerWorkspace` production shell mount 금지, `ExplorerWorkspaceState` production source-of-truth 승격 금지, `WordExplorerScreen` owner state migration 금지, repository/read owner migration 금지, 새 DB query 금지, 새 repository read 금지, 신규 DTO/model/public API 금지, projection result 기반 production mutation/read/persistence/restore/rollback 금지다.

### 17.106 Phase 18-D HomeScreen left target feedback boundary

Phase 18-D는 large-screen 좌측 control surface에서 현재 우측 `WordExplorerScreen` target을 current target feedback으로 표시하는 production-visible UX minimum slice다.

이번 단계는 selection owner 이전이 아니다. 좌측 list/search 결과는 target owner나 selection source가 아니며, 기존 `HomeScreen` private state인 `_largeScreenExplorerWordId`와 각 item의 `wordId` 비교 결과를 시각적으로 보여주는 범위에 머문다.

적용 범위는 default Strong list와 search result list 모두다. 두 목록 모두 large-screen에서만 current target feedback을 표시하고, small-screen에서는 기존 `return homePane;` 및 list → detail route 흐름을 유지한다.

이 feedback은 Strong Rail 구현 이전의 안전한 중간 단계다. Strong Rail, 좌측 단어 추가 버튼, scroll/jump behavior, keyboard access, navigation continuity rule은 이번 단계에서 구현하지 않는다.

`ListTile.selected`와 `selectedTileColor`는 Flutter의 기존 list feedback 속성을 사용한 구현 수단이다. 이를 selection owner 이전, left selection source 도입, `WordExplorerScreen` owner migration으로 해석하지 않는다.

유지한 금지선은 `ExplorerWorkspace` production shell mount 금지, `ExplorerWorkspaceState` production source-of-truth 승격 금지, `WordExplorerScreen` owner state migration 금지, repository/read owner migration 금지, 새 DB query 금지, 새 repository read 금지, 신규 DTO/model/public API 금지, projection result 기반 production mutation/read/persistence/restore/rollback 금지다.

### 17.107 Phase 18-E HomeScreen left control action boundary audit

Phase 18-E는 `left control surface action boundary audit`를 수행하는 docs/audit-only 단계다. 이번 단계는 production code 변경, `lib/` 변경, `test/` 변경, DB 변경, dependency 변경, Strong Rail 구현, 좌측 단어 추가 버튼 구현, scroll/jump behavior 구현, keyboard access 구현, search/list continuity 구현을 승인하지 않는다.

#### Phase 18-A~D 기준 현재 책임

Phase 18-A~D까지 large-screen 좌측 control surface가 맡은 production 책임은 `HomeScreen` private 범위 안의 search/list/target feedback 책임으로 제한된다.

현재 책임은 아래와 같다.

- 검색 입력과 검색 실행/초기화 control
- 기본 Strong 목록 표시
- 검색 결과 목록 표시
- large-screen 목록 item tap을 우측 `WordExplorerScreen` target 변경 요청으로 변환
- `_largeScreenExplorerWordId` 기준 current target feedback 표시
- small-screen에서는 기존 `return homePane;` 및 list → detail route 흐름 유지

이 책임은 selection owner, graph center owner, detail target owner, navigation history owner, repository/read owner, persistence authority, rollback authority가 아니다.

#### 허용 가능한 action 후보

Phase 18-E 기준으로 좌측 control surface가 안전하게 맡을 수 있는 action 후보는 기존 `HomeScreen` private state와 기존 read 흐름 안에서 끝나는 항목으로 제한한다.

허용 가능한 후보는 아래와 같다.

- current target feedback 표시의 시각적 정리
- large-screen에서 기존 list item tap을 `_showWordInLargeScreenExplorerPane(...)`로 보내는 retarget request surface 유지
- 검색 입력, 검색 실행, 검색 초기화의 control surface 표현 정리
- default Strong list와 search result list가 같은 current target feedback 기준을 공유한다는 guardrail/docs 보강
- small-screen route/detail 흐름을 보존하는 source guard 보강

이 후보들은 새 DB query, 새 repository read, 신규 DTO/model/public API 없이 가능해야 한다.

#### 아직 금지해야 할 action 후보

아래 action은 Phase 18-E 기준에서 좌측 control surface로 옮기면 안 된다.

- Strong Rail 실제 구현
- 좌측 단어 추가 버튼 구현
- `WordGraphScreen._showCreateWordFlow()`를 좌측 pane에서 직접 호출하는 흐름
- graph center, selected word, detail target, history를 좌측 list가 소유하는 흐름
- scroll/jump behavior 구현
- keyboard access 구현
- search/list continuity rule 구현
- repository/read owner migration
- `ExplorerWorkspaceState`를 production source-of-truth로 사용하는 흐름
- projection result 기반 production mutation/read/persistence/restore/rollback

#### Strong Rail 선결 조건

Strong Rail을 실제 구현하려면 먼저 아래 owner/source-of-truth/action boundary를 정의해야 한다.

- Strong Rail이 표시 source인지, target request surface인지, selection surface인지 구분
- Strong 번호 anchor source와 list item source의 관계
- 현재 우측 target과 rail highlight의 관계
- rail tap이 search/list scroll만 수행하는지, Explorer target 변경까지 수행하는지에 대한 action boundary
- small-screen route/detail 흐름과 large-screen retarget 흐름의 분기 규칙
- `ExplorerWorkspaceState`나 `WordExplorerScreen` owner state를 우회하지 않는 guardrail

이 정의 전에는 Strong Rail을 production UI로 구현하지 않는다.

#### 좌측 add action 선결 조건

현재 단어 추가 action은 `WordGraphScreen` graph app bar의 `Icons.note_add`에서 `WordGraphScreen._showCreateWordFlow()`로 진입한다. 이 흐름은 duplicate check, create write, edit seed read, `WordEditScreen.fromSeed`, relation option, graph refresh를 포함하며 `WordGraphScreen` owner와 repository/write 흐름에 묶여 있다.

좌측 add action을 구현하려면 아래 선결 조건이 필요하다.

- 좌측 pane에서 호출 가능한 public entry 또는 route-level entry 정의
- 생성된 단어가 어느 graph center와 relation option을 갖는지 결정하는 owner boundary
- create write, edit seed read, post-save payload read, relation create의 repository/write owner 유지 규칙
- 취소/rollback 성격의 discard 흐름을 어느 owner가 처리하는지에 대한 boundary
- `WordGraphScreen._showCreateWordFlow()` private 흐름을 직접 이동하지 않는 대체 contract

이 선결 조건 없이는 좌측 단어 추가 버튼을 구현하지 않는다.

#### Strong anchor/jump behavior 선결 조건

현재 `HomeScreen`에는 기본 Strong 목록에서만 동작하는 strong jump 관련 private 상태와 메서드가 있다. `_strongJumpDebounceTimer`, `_currentDefaultStrongItems`, `_isShowingDefaultStrongList`, `_jumpToStrongInDefaultList(...)`, `_scrollToDefaultStrongIndex(...)`는 기본 Strong 목록 scroll helper 성격이다.

Strong anchor/jump behavior를 확장하려면 아래 조건을 먼저 정의해야 한다.

- scroll state owner가 `HomeScreen` private list controller인지 별도 rail state인지
- jump action이 scroll-only인지 Explorer target retarget까지 포함하는지
- 검색 결과 목록과 기본 Strong 목록 사이에서 jump action이 어떤 continuity rule을 따르는지
- search mode일 때 Strong anchor 입력이 검색 결과를 유지하는지 기본 Strong 목록으로 복귀하는지
- current target feedback과 jump focus/highlight가 같은 의미인지 다른 의미인지
- small-screen route/detail 흐름에 jump behavior가 영향을 주지 않는 guardrail

이 정의 전에는 scroll/jump behavior, keyboard access, search/list continuity를 구현하지 않는다.

#### default Strong list와 search result list의 공통 책임 범위

default Strong list와 search result list는 아래 범위에서는 같은 control surface 책임으로 묶을 수 있다.

- item의 `wordId`를 기준으로 large-screen Explorer target 변경 요청을 보낸다.
- `_largeScreenExplorerWordId`와 item `wordId` 비교로 current target feedback을 표시한다.
- 기존 repository/read 흐름을 유지한 채 display item을 렌더링한다.

다만 두 목록은 selection source, detail source-of-truth, graph center owner, repository/read owner로 묶이지 않는다. search result list의 ranking/read 흐름과 default Strong list의 strong order/read 흐름은 기존 repository boundary를 유지한다.

#### HomeScreen private state 범위

`HomeScreen` private state 범위에서 가능한 action은 `_largeScreenExplorerWordId` 갱신, current target feedback, search input state, 기본 Strong 목록 scroll helper, 기존 list tap 분기 정도다.

불가능한 action은 `WordExplorerScreen` 내부 `_centerWordId`, `_selectedWordId`, `_selectedWordDisplayItem`, `_history`, detail loading/error/unavailable state, repository/read result를 직접 소유하거나 이동하는 것이다. 이 값들은 현재 `WordExplorerScreen` owner boundary 안에 있다.

#### Phase 18-F 후보와 추천 순서

| 추천 순서 | 후보 | 위험도 | 이유 |
| --- | --- | --- | --- |
| 1 | Phase 18-F guardrail/docs 보강 | 낮음 | `lib/` 변경 없이 Phase 18-A~E boundary를 source guard 또는 문서 기준으로 고정할 수 있다. |
| 2 | Phase 18-F HomeScreen private feedback polish | 중간 | current target feedback의 시각적 명확성 개선은 가능하지만 production UI diff이므로 small-screen guard와 owner boundary 검증이 필요하다. |
| 3 | Phase 18-F Strong anchor/jump design audit | 중간~높음 | Strong Rail 구현 전 선결 조건을 더 구체화할 수 있으나 scroll state, target state, continuity rule을 잘못 섞으면 owner 혼동 위험이 크다. |

추천 순서는 guardrail/docs 보강을 먼저 수행한 뒤, 필요한 경우 HomeScreen private feedback polish를 검토하고, Strong anchor/jump는 별도 design audit로 분리하는 것이다.

#### 유지 금지선

Phase 18-E는 `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, `WordExplorerScreen` owner migration, repository/read owner migration, 새 repository read, 새 DB query, 신규 DTO/model/public API 추가, persistence/restore/rollback authority migration, projection result 기반 production mutation/read/persistence/restore/rollback을 승인하지 않는다.

### 17.108 Phase 18-F ExplorerWorkspace left control boundary guardrail/docs 보강

Phase 18-F는 Phase 18-A~E에서 정리한 large-screen `HomeScreen` 좌측 control surface boundary를 source guard와 문서 기준으로 고정하는 guardrail/docs 단계다. 이번 단계는 새 UX 구현, production UI polish, Strong Rail 구현, scroll/jump behavior 구현, keyboard access 구현, search/list continuity 구현 단계가 아니다.

#### source guard 고정 기준

Phase 18-F source guard는 아래 경계를 확인한다.

- large-screen 좌측 control surface는 `_largeScreenExplorerWordId` 기반 current target feedback과 retarget request surface 범위만 가진다.
- `HomeScreen`은 `WordExplorerScreen` 내부 owner state인 center, selected, detail, history 상태를 직접 소유하지 않는다.
- `ExplorerWorkspaceState`는 `HomeScreen` production source-of-truth로 사용되지 않는다.
- small-screen에서는 기존 `return homePane;` 및 list → detail route 흐름을 유지한다.
- default Strong list와 search result list는 current target feedback 기준을 공유할 수 있지만 selection owner, graph/detail owner, repository/read owner로 확장되지 않는다.
- 좌측 control surface와 large-screen split shell 경로는 `WordGraphScreen._showCreateWordFlow()`, `WordEditScreen.fromSeed`, `Icons.note_add` 기반 create/edit/write entry를 직접 열지 않는다.
- 기존 strong jump helper는 기본 Strong 목록 scroll helper 범위를 넘지 않으며 Explorer retarget, repository read, Navigator route, `ExplorerWorkspaceState` source-of-truth 흐름으로 확장되지 않는다.
- Strong Rail, keyboard access, search/list continuity 관련 production 구현은 `HomeScreen` 또는 `ExplorerWorkspace` production-adjacent surface에 추가하지 않는다.

#### 유지 범위와 금지선

이번 단계에서 허용한 변경은 `test/` source guard 추가와 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md` 기록 보강에 한정한다. `lib/` production code, DB, dependency, repository/read contract, DTO/model/public API는 변경하지 않는다.

Phase 18-F는 `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, `WordExplorerScreen` owner migration, repository/read owner migration, persistence/restore/rollback authority migration, projection result 기반 production mutation/read/persistence/restore/rollback을 승인하지 않는다.

### 17.109 Phase 18-G Strong Rail Level 1 retarget-only minimum slice

Phase 18-G는 large-screen `HomeScreen` 좌측 control surface 내부에 얇은 Strong Rail을 도입하는 Level 1 retarget-only minimum slice다. 이번 단계의 Strong Rail은 새 navigation owner, selection owner, graph/detail owner, repository/read owner가 아니다. 기존 default Strong list 데이터를 재사용해 compact Strong 번호 item을 표시하고, item tap은 기존 large-screen Explorer target retarget request만 수행한다.

#### 구현 범위

- Strong Rail은 large-screen `HomeScreen` branch의 좌측 control surface 내부에만 mount한다.
- small-screen에서는 기존 `return homePane;` 및 list → detail route 흐름을 유지한다.
- rail data는 기존 default Strong list future를 재사용한다. search mode의 기존 검색 결과 list surface는 default Strong list로 전환하지 않는다.
- rail item은 Strong 번호 중심 compact item으로 표시한다.
- rail item의 current feedback은 `item.wordId == _largeScreenExplorerWordId` 비교만 사용한다.
- rail item tap action boundary는 `_showWordInLargeScreenExplorerPane(item.wordId)` 호출로 제한한다.
- Phase 18-F source guard는 Strong Rail production 부재 전제만 Phase 18-G 기준으로 보정하고, owner/source-of-truth 금지선은 유지한다.
- Phase 18-G 전용 source guard는 rail future 재사용, large-screen mount, small-screen route 흐름, retarget-only tap, search mode list 유지, read/query/API 금지선을 확인한다.

#### 금지선

Phase 18-G는 keyboard access, search/list continuity, rail tap 기반 list scroll/jump, search result list 초기화, default/search list 전환, 좌측 단어 추가 버튼, `WordGraphScreen._showCreateWordFlow()` 좌측 호출을 승인하지 않는다.

Phase 18-G는 `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, `WordExplorerScreen` owner migration, `HomeScreen`의 `WordExplorerScreen` center/selected/detail/history owner state 소유, repository/read owner migration, 새 repository read, 새 DB query, 신규 DTO/model/public API 추가, dependency 변경, persistence/restore/rollback authority migration, projection result 기반 production mutation/read/persistence/restore/rollback을 승인하지 않는다.

### 17.110 Phase 18-I Strong Rail local jump minimum slice

Phase 18-I는 large-screen `HomeScreen` 좌측 control surface에 이미 mount된 Strong Rail의 local jump를 최소 범위로 추가하는 단계다. 검색창에 Strong 번호 형식의 입력이 들어오면 large-screen에서는 기존 default Strong list scroll helper가 아니라 Strong Rail 내부 scroll 위치만 이동한다. 이 단계는 graph selection sync가 아니며, 그래프에서 단어를 선택했을 때 Rail이 이동하거나 highlight되는 동작은 포함하지 않는다.

#### 구현 범위

- Strong Rail local jump는 `HomeScreen` private state 안의 rail 전용 scroll mechanism으로만 처리한다.
- rail scroll은 `_strongRailScrollController`와 rail item extent 기준 offset helper를 사용한다.
- rail index lookup은 기존 default Strong list future로부터 rail builder가 받은 item 목록을 `_currentStrongRailItems`에 보관해 수행한다.
- `_currentStrongRailItems`는 rail-local jump index lookup cache일 뿐이며 default list/search result list의 source-of-truth가 아니다.
- `_normalizeStrongInput`, `_findStrongIndex`, `_formatDisplayStrong` 같은 순수 helper는 재사용할 수 있다.
- 기존 `_jumpToStrongInDefaultList(...)`와 `_scrollToDefaultStrongIndex(...)`는 default Strong list helper로 유지하고, rail local jump는 별도 helper로 분리한다.
- rail item tap의 current/target feedback은 Phase 18-G 기준인 `item.wordId == _largeScreenExplorerWordId` 비교를 유지한다.

#### 금지선

Phase 18-I의 검색 입력 기반 rail local jump는 `_largeScreenExplorerWordId`를 변경하지 않고, `_showWordInLargeScreenExplorerPane(...)`을 호출하지 않으며, `WordExplorerScreen` remount를 발생시키지 않는다. 또한 `_setVisibleWordListFuture(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`를 변경하지 않으므로 search result list를 초기화하거나 default Strong list로 전환하지 않는다.

Phase 18-I는 graph selection 연동, `WordExplorerScreen` constructor callback 추가, `WordGraphScreen` callback 변경, 새 DB query, 새 repository read, 신규 DTO/model/public API 추가, dependency 변경, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, `WordExplorerScreen` owner migration, `HomeScreen`의 graph/detail owner 승격, 좌측 단어 추가 버튼, keyboard access, search/list continuity 구현을 승인하지 않는다.

### 17.111 Phase 18-J stale HomeScreen source guard cleanup

Phase 18-J는 Phase 18-C/18-D 시점의 과거 HomeScreen source guard를 Phase 18-G/I 이후 production reality에 맞게 보정하는 cleanup 단계다. 이번 단계는 새 UX 구현 단계가 아니며, production `lib/` code를 변경하지 않는다.

#### guard 보정 기준

- Strong Rail은 Phase 18-G 이후 large-screen `HomeScreen` 좌측 control surface 내부에 허용된 production surface다.
- Phase 18-C/18-D의 "Strong Rail production 존재 자체 금지" guard는 stale 기준이므로 제거한다.
- Strong Rail source guard는 존재 금지가 아니라 owner/source/read/query/API 확장 금지 기준으로 해석한다.
- rail source는 기존 default Strong list future를 재사용하는 retarget/local jump surface 범위를 넘지 않는다.
- rail tap은 Phase 18-G 기준인 `_showWordInLargeScreenExplorerPane(item.wordId)` retarget request로만 유지한다.
- rail local jump는 Phase 18-I 기준인 rail-local scroll/index cache 동작으로만 유지하며 Explorer target을 변경하지 않는다.

#### 유지 금지선

Phase 18-J는 `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, `WordExplorerScreen` owner migration, `HomeScreen`의 graph/detail/selected/history owner 승격, repository/read owner migration, 새 repository read, 새 DB query, 신규 DTO/model/public API 추가, dependency 변경, graph selection sync, keyboard access, search/list continuity, 좌측 create/edit/write entry, `WordGraphScreen._showCreateWordFlow()` 좌측 호출, Strong Rail tap 이외 retarget 확장을 승인하지 않는다.

이번 단계는 source guard와 문서 기록만 정리하므로 production UX 변경과 클라이언트 UI 재테스트 대상이 아니다.

### 17.112 Phase 18-K graph selection Strong Rail passive sync minimum slice

Phase 18-K는 large-screen `HomeScreen` 우측 `WordExplorerScreen` 내부 graph selection을 좌측 Strong Rail에 passive하게 반영하는 minimum slice다. 이번 단계의 sync는 rail-local jump 또는 passive selected feedback에 한정하며, 우측 Explorer target retarget이나 `WordExplorerScreen` remount가 아니다.

#### 구현 범위

- `WordExplorerScreen`은 optional `onSelectedStrongWordChanged` callback으로 확정된 selected word의 `wordId`와 display Strong 번호를 알릴 수 있다.
- callback은 route usage와 standalone usage를 깨지 않는 optional contract이며, 신규 DTO/model을 추가하지 않는다.
- `HomeScreen`은 callback을 받아 rail-local passive selected state만 갱신한다.
- display Strong 번호가 비어 있으면 `HomeScreen`은 passive selected state를 clear한다. 이 처리는 retarget이 아니며 `_largeScreenExplorerWordId`를 변경하지 않는다.
- display Strong 번호가 있으면 `HomeScreen`은 기존 Strong Rail 목록 cache에서 해당 Strong 위치로 rail-local jump를 시도하고, 찾을 수 없는 경우 사용자 feedback 없이 passive state만 유지한다.

#### feedback 기준

- target feedback은 계속 `_largeScreenExplorerWordId`와 rail item `wordId` 비교를 기준으로 한다.
- passive selected feedback은 graph selected word에서 전달된 display Strong 번호와 rail item display Strong 번호 비교를 기준으로 한다.
- 같은 rail item이 target이면서 passive selected일 수 있다.
- target feedback은 primary container/border 기준으로 유지하고, passive selected feedback은 secondary 계열 보조 표시로만 취급한다. passive selected feedback은 target feedback을 대체하지 않는다.

#### stale guard

`WordExplorerScreen._selectWord(...)`는 selection request token을 사용해 async detail load 이후 현재 요청이 아닌 결과를 버린다. 이 guard는 빠른 graph node 선택에서 과거 selection callback이 늦게 도착해 Strong Rail을 과거 위치로 되돌리는 상황을 막기 위한 최소 범위다.

selection clear도 token을 무효화하고 빈 Strong callback으로 passive selected feedback을 clear한다. 이 처리는 selection owner, center owner, detail owner, history owner를 `HomeScreen`으로 옮기지 않으며, history/center ownership migration으로 확장하지 않는다.

#### 유지 금지선

Phase 18-K는 graph selection이 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하는 흐름을 승인하지 않는다. graph selection은 `WordExplorerScreen` key 또는 `initialWordId`를 변경하지 않으며 remount를 유발하지 않는다.

이번 단계는 `HomeScreen`의 graph/detail/selected/history owner 승격, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, 새 DB query, 새 repository read, 신규 DTO/model 추가, dependency 변경, persistence/restore/rollback authority migration, projection result 기반 production mutation/read/persistence/restore/rollback, 좌측 create/edit/write entry, keyboard access, search/list continuity 구현을 승인하지 않는다.

### 17.113 Phase 18-L Search / Strong Jump role separation audit

Phase 18-L은 `Search / Strong Jump role separation audit`를 수행한 read-only audit 단계다. 이번 단계에서는 production code, test code, DB, dependency, 문서 외 파일을 변경하지 않고, Phase 18-K 이후 `HomeScreen`의 일반 검색 입력과 Strong Rail local jump 입력 역할을 실제 코드 기준으로 확인했다.

#### 확인한 현재 결합 상태

- 현재 일반 검색과 Strong jump는 같은 `_searchController`, 같은 `TextField`, 같은 입력 surface를 공유한다.
- 같은 입력 surface는 large-screen 상단 control surface의 `TextField`이며, `labelText`는 현재 `검색 (표기/의미/스트롱 번호)`다.
- Strong 번호 형식 입력의 `onChanged` 경로는 `_handleSearchChanged(...)`에서 시작해 `_isStrongJumpInput(...)`, debounce, `_normalizeStrongInput(...)`, `_canRunAutoStrongRailJump(...)`, `_jumpToStrongInRail(...)`로 이어진다.
- 일반 검색 실행 경로는 `_runSearch(...)`, `_setVisibleWordListFuture(...)`, `_createSearchWordsFuture(...)`를 통해 기존 `_repository.searchStrongExactMap(...)` 또는 `_repository.searchWordsMap(...)`를 사용한다.
- 일반 검색 후보 item tap은 large-screen에서 `_showWordInLargeScreenExplorerPane(wordId)`를 호출해 `_largeScreenExplorerWordId`를 갱신하고, `WordExplorerScreen(key: ValueKey(_largeScreenExplorerWordId), initialWordId: _largeScreenExplorerWordId)` remount로 우측 Explorer retarget을 수행한다.

#### rail-local jump 경계 확인

Strong-like 입력의 `onChanged` 기반 rail-local jump 경로는 일반 검색 실행/retarget 경로와 분리되어 있다.

- `_jumpToStrongInRail(...)`은 `_currentStrongRailItems`에서 display Strong 번호 index를 찾고 `_scrollToStrongRailIndex(...)`만 호출한다.
- `_scrollToStrongRailIndex(...)`는 `_strongRailScrollController`와 `_strongRailListItemExtent` 기반으로 Strong Rail scroll 위치만 이동한다.
- 이 경로는 `_largeScreenExplorerWordId`를 변경하지 않는다.
- 이 경로는 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- 이 경로는 `_searchWordsFuture`, `_setVisibleWordListFuture(...)`, `_isShowingDefaultStrongList`를 변경하지 않는다.
- 이 경로는 검색 결과 목록 초기화, default/search list 전환, `WordExplorerScreen` key 변경, Explorer pane remount를 유발하지 않는다.

#### 위험 지점

현재 위험 지점은 역할이 다른 두 입력 의미가 같은 입력란을 공유한다는 점이다. Strong-like query를 입력하는 동안 `onChanged` 경로는 rail-local jump로 분리되어 있지만, 같은 입력란에서 submit 또는 검색 button을 실행하면 `_runSearch(...)` 경로로 들어갈 수 있다. 이 경우 Strong 번호 입력이 일반 검색 실행으로 해석되어 검색 결과 목록 전환을 유발할 수 있다.

따라서 Phase 18-L audit 결론은 "rail-local jump helper 자체는 retarget/list 전환과 분리되어 있으나, 입력 surface/controller 공유가 UX 역할 혼동을 만들 수 있다"로 정리한다.

#### Phase 18-M 당시 최소 구현 후보

아래 항목은 Phase 18-L audit 시점에 기록한 역사적 후보 범위다. 이후 Phase 18-M에서 일반 검색 field와 `Strong/스트롱` compact field 분리를 완료했으며, 현재 구현 기준은 `17.114 Phase 18-M Search / Strong Jump role separation implementation`과 `17.115 Phase 18-N Phase 18 종료 전 guardrail hardening`을 따른다.

포함 후보:

- large-screen `HomeScreen` control surface 한정으로 일반 검색 field와 Strong/스트롱 compact field를 분리한다.
- Strong/스트롱 field label 후보는 `Strong/스트롱`으로 둔다.
- Strong/스트롱 field placeholder 기본 후보는 `H1 또는 G26`으로 둔다.
- 폭 부족 시 placeholder 축약 후보는 `H1, G26`으로 둔다.
- Strong/스트롱 field 입력은 rail-local jump만 수행한다.
- 일반 검색 field는 기존 검색 후보 목록 표시와 검색 후보 item tap의 Explorer retarget 흐름을 유지한다.

제외 후보:

- small-screen 흐름 변경
- 새 DB query
- 새 repository read/API
- 신규 DTO/model
- dependency 변경
- keyboard access
- search ranking 개선
- recent search / persistence
- 좌측 create/edit/write entry 추가
- graph/detail/history owner migration
- `ExplorerWorkspace` production shell mount
- `ExplorerWorkspaceState` production source-of-truth 승격

#### Phase 18-M 당시 guardrail/test 후보

아래 guardrail 후보는 Phase 18-L audit 시점의 역사적 기록이며, Phase 18-M 구현과 Phase 18-N runtime guardrail에서 실제 검증 기준으로 반영했다.

- Strong/스트롱 field handler source에 `_showWordInLargeScreenExplorerPane(...)`, `_largeScreenExplorerWordId =`, `_searchWordsFuture`, `_setVisibleWordListFuture(...)`, `_isShowingDefaultStrongList =`, `WordExplorerScreen(`, `Navigator.push`, `_repository.`가 포함되지 않아야 한다.
- 일반 검색 field는 기존 `_runSearch(...)`, `_clearSearch(...)`, `_createSearchWordsFuture(...)`, 검색 결과 list surface, 검색 후보 item tap retarget 경로를 유지해야 한다.
- small-screen branch는 기존 `return homePane;` 흐름과 기존 검색 field 흐름을 유지해야 한다.
- 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경이 없어야 한다.

### 17.114 Phase 18-M Search / Strong Jump role separation implementation

Phase 18-M은 large-screen `HomeScreen` control surface에서 일반 검색 입력과 `Strong/스트롱` rail-local jump 입력을 분리한 최소 구현 단계다. 이 단계는 Phase 18-L에서 확인한 입력 surface/controller 공유 위험을 해소하되, graph/detail/selected/history authority와 data read boundary는 변경하지 않는다.

#### 구현 범위

- `HomeScreen`에 `_searchController`와 분리된 `_strongJumpController`를 추가했다.
- large-screen control surface에서는 일반 검색 field와 `Strong/스트롱` compact field를 분리했다.
- 일반 검색 field는 기존 `_runSearch(...)`, `_clearSearch(...)`, 검색 후보 목록, 검색 후보 item tap의 Explorer retarget 흐름을 유지한다.
- `Strong/스트롱` field label은 `Strong/스트롱`으로 두고 placeholder는 `H1 또는 G26`으로 둔다.
- `Strong/스트롱` field 입력은 `_handleStrongRailJumpChanged(...)`, `_handleStrongRailJumpSubmitted(...)`, `_runStrongRailJump(...)`를 거쳐 기존 `_jumpToStrongInRail(...)` rail-local helper만 호출한다.
- large-screen 일반 검색 field의 `onChanged`는 pending Strong jump timer 취소만 수행하고, Strong Rail local jump를 수행하지 않는다.
- small-screen branch는 기존 `homePane` 반환 흐름과 기존 `_handleSearchChanged(...)` 기반 검색 field 흐름을 유지한다.

#### 유지한 금지선

- `Strong/스트롱` 입력은 `_largeScreenExplorerWordId`를 변경하지 않는다.
- `Strong/스트롱` 입력은 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- `Strong/스트롱` 입력은 `_runSearch(...)`, `_setVisibleWordListFuture(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` 변경과 결합하지 않는다.
- `Strong/스트롱` 입력은 `WordExplorerScreen` remount, `Navigator.push`, repository read/API 호출을 유발하지 않는다.
- 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경은 없다.
- `HomeScreen` graph/detail/selected/history owner 승격, `WordExplorerScreen` owner migration, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` source-of-truth 승격은 수행하지 않았다.

#### 명령어 기반 검증 결과

- `flutter test test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart --reporter expanded`: 통과, `+6`.
- `flutter test test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart test/ui/home_screen_phase18g_strong_rail_retarget_boundary_test.dart test/ui/home_screen_phase18i_strong_rail_local_jump_boundary_test.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart --reporter expanded`: 통과, `+31`.
- `flutter analyze --no-fatal-infos --no-fatal-warnings lib/ui/home_screen.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart`: exit code 0. 기존 `_dbMessage` unused warning 1건과 기존 `print` info 4건을 보고했다.
- `git diff -- pubspec.yaml pubspec.lock`: 변경 없음.

#### UI 수동 테스트 기준

UI 수동 테스트는 클라이언트가 Windows Desktop 앱에서 수행한다. 창 너비를 900px 이상으로 둔 뒤 일반 검색창에 `H1`을 입력하고 검색 버튼을 눌렀을 때 좌측 목록이 검색 후보 목록으로 전환되어야 하며, 후보 item을 누르기 전까지 우측 Explorer는 retarget되지 않아야 한다. 검색 후보 item을 클릭하면 우측 Explorer가 해당 후보로 retarget되어야 한다. `Strong/스트롱` 입력란에 `G26`을 입력하면 Strong Rail 위치/feedback만 변하고, 우측 Explorer retarget, 검색 결과/default list 전환, 우측 Explorer remount가 발생하지 않아야 한다. 창 너비를 900px 미만으로 줄인 뒤 기존 검색 입력에서 `H1`을 입력하면 기존 small-screen 흐름이 유지되어야 한다.

### 17.115 Phase 18-N Phase 18 종료 전 guardrail hardening

Phase 18-N은 Phase 19로 이동하기 전 Phase 18 종료 조건을 보강하는 guardrail/docs 단계다. production 기능과 동작은 변경하지 않으며, Phase 18-G~M에서 확정한 Search, Strong Jump, Strong Rail, graph passive sync 역할 경계를 기존 source guard와 runtime widget guard로 함께 확인한다.

#### 최종 역할 경계

- 일반 검색 field는 `_searchController`, `_runSearch(...)`, 기존 검색 후보 목록, 검색 후보 item tap의 우측 Explorer retarget 흐름을 담당한다.
- `Strong/스트롱` field는 Strong Rail 내부 local jump만 담당하며, 검색 결과/default list 전환과 우측 Explorer retarget/remount를 수행하지 않는다.
- Strong Rail item tap은 `_showWordInLargeScreenExplorerPane(item.wordId)` retarget request만 수행한다.
- graph selection passive sync는 Strong Rail passive selected feedback과 rail-local jump만 수행하며, `_largeScreenExplorerWordId`를 변경하거나 Explorer를 retarget/remount하지 않는다.
- Strong 번호가 없는 selected word는 passive selected state clear로 처리한다.
- small-screen은 기존 검색 결과 item tap의 detail route 흐름을 유지한다.

#### runtime guardrail 범위와 한계

`test/ui/home_screen_phase18n_runtime_guardrail_test.dart`는 production `HomeScreen`을 격리 복사 DB에서 mount해 일반 검색 submit, Strong Rail local jump, 검색 목록 유지, Explorer element/key/initial target 유지, passive callback 이후 Explorer 비-retarget, small-screen detail route 흐름을 확인한다.

graph node는 `WordGraphScreen` 내부 `CustomPaint`와 계산된 좌표 기반 `GestureDetector`로 렌더되므로 production key를 추가하지 않고 안정적인 특정 node 직접 탭을 수행하는 것은 이번 Phase 범위를 넘는다. Phase 18-N runtime guard는 mounted `WordExplorerScreen`의 production `onSelectedStrongWordChanged` callback을 실제 호출해 `HomeScreen` passive sync 경계를 확인하고, graph selection callback 연결과 async stale guard는 기존 Phase 18-K source guard로 유지한다.

#### 유지 금지선

Phase 18-N은 `lib/` production code, DB, repository read/API, DTO/model, dependency를 변경하지 않는다. Strong Rail/Search/graph selection/passive sync 동작 변경, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, keyboard access, search ranking, recent search/persistence 구현을 수행하지 않는다.

#### 명령어 기반 검증 결과

- `flutter test test/ui/home_screen_phase18n_runtime_guardrail_test.dart --reporter expanded`: 통과, `+3`.
- Phase 17-B/C, Phase 18-A/B/C/D/F/G/I/K/M, Phase 18-N guardrail 묶음: 통과, `+74`.
- `flutter test --reporter compact`: 전체 통과, `+311`.
- `flutter analyze --no-fatal-infos --no-fatal-warnings test/ui/home_screen_phase18n_runtime_guardrail_test.dart`: 통과, `No issues found!`.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`.

#### UI 수동 테스트 체크리스트

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| large-screen 일반 검색 `H1` | 좌측 목록이 `H1` 검색 후보 목록으로 전환되고, 후보 tap 전까지 우측 Explorer target은 유지된다. | 목록이 기본 Strong 목록으로 남거나 입력만으로 Explorer가 바뀌는지 확인한다. | Windows Desktop 창을 900px 이상으로 두고 일반 검색 field에 `H1`을 입력한 뒤 Enter 또는 검색 버튼을 누른다. |
| 일반 검색 후보 item tap | 선택한 후보로 우측 Explorer가 retarget된다. | 우측 Explorer가 유지되거나 detail route가 별도로 열리는지 확인한다. | `H1 / אָב / 아브 / 아버지` 후보 item 본문을 클릭하고 우측 Explorer 중심/상세가 해당 단어로 바뀌는지 확인한다. |
| `Strong/스트롱` 입력 `G26` | Strong Rail 위치만 `G26`으로 이동하며 검색 결과/default list와 우측 Explorer target/remount는 유지된다. | 좌측 목록 전환, 우측 Explorer 초기화/retarget, 검색 실행이 발생하는지 확인한다. | large-screen `Strong/스트롱` field에 `G26`을 입력하고 Enter를 누른 뒤 Rail 위치와 기존 화면 상태를 비교한다. |
| graph selection → Strong Rail passive selected/jump | 선택 단어의 Strong 번호 위치로 Rail이 이동하고 secondary passive selected feedback만 표시된다. 우측 Explorer target은 유지된다. | primary target feedback이 바뀌거나 Explorer가 remount/retarget되는지 확인한다. | `H1 / אָב / 아브 / 아버지` Explorer graph에서 `H2 / אַב / 아브 / 아버지` 또는 `H85 / אַבְרָהָם / 아브라함/아베라함` node를 선택한다. |
| Strong 번호 없는 graph node 선택 | 기존 passive selected feedback이 clear되고 우측 Explorer target은 유지된다. | 이전 passive 표시가 남거나 Explorer target이 바뀌는지 확인한다. | graph에서 `אַבָּא / 아빠 / 아버지` node를 선택하고 Rail의 secondary passive 표시가 사라지는지 확인한다. |
| small-screen 검색/detail route | embedded Explorer와 `Strong/스트롱` field 없이 기존 검색 후보 목록이 표시되고 후보 tap이 detail route를 연다. | embedded Explorer가 나타나거나 후보 tap이 large-screen retarget처럼 동작하는지 확인한다. | 창을 900px 미만으로 줄이고 일반 검색 field에 `H1`을 검색한 뒤 후보 item 본문을 클릭한다. |

### 17.116 Phase 19-A 상단 검색/명령 surface read-only audit active boundary

Phase 19-A는 상단 검색/명령 surface와 좌측 control surface의 장기 역할을 재정의하기 위한 read-only UX/architecture audit 단계다. 상세 source 근거와 감사 결과는 `docs/ux/explorer_workspace_phase19a_top_search_command_surface_audit.md`에 reference/context 기록으로 남긴다. 이번 단계는 production code, test code, DB, repository read/API, DTO/model, dependency를 변경하지 않으며 상단 surface 구현을 승인하지 않는다.

현재 일반 검색 입력은 `HomeScreen`의 `Scaffold.body > LayoutBuilder > homeSearchControlArea > homePane` 경로에 mount된다. large-screen에서 `homePane`은 좌측 `Expanded(flex: 2)`에 위치하므로 현재 일반 검색 입력은 좌측 control surface 상단에 있으며, 좌우 전체 workspace를 가로지르는 상단 surface는 아니다.

일반 검색 query, `_runSearch(...)`, `_clearSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`, default/search 목록 전환은 계속 `HomeScreen` private state가 소유한다. 검색 결과/default 목록은 좌측 surface에 유지한다. 상단 검색/명령 surface 후보는 이 기존 state와 handler를 시각적으로 노출하는 owner-preserving presentation candidate로만 평가할 수 있다.

상단 search submit은 검색 결과 목록 전환까지만 수행해야 하며, submit 자체가 `_showWordInLargeScreenExplorerPane(...)`를 호출하거나 `_largeScreenExplorerWordId`를 변경해서는 안 된다. 우측 Explorer retarget request는 기존과 같이 명시적 검색 후보 item tap 또는 Strong Rail item tap에서만 발생한다.

`Strong/스트롱` 입력은 좌측 Strong Rail local jump 전용으로 유지한다. `_runSearch(...)`, 검색 결과/default 목록 전환, Explorer retarget/remount, repository read/API와 결합하지 않는다. graph selection passive sync도 Strong Rail passive selected feedback과 rail-local jump로만 유지하며 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

일반 검색 입력을 large-screen 상단 surface 후보로 시각 재배치하는 것은 `HomeScreen` 내부 build composition 변경 후보로 평가할 수 있으며, `WordExplorerScreen` owner state migration 없이 가능하다. 그러나 Phase 19-A는 이를 구현하지 않으며, 구현이 필요하면 Phase 19-B 이후 별도 설계·승인 대상으로 분리한다.

좌측 control surface의 유지 역할은 Strong Rail 및 Strong anchor orientation, `Strong/스트롱` rail-local jump, default Strong 목록, 일반 검색 실행 후 검색 후보 목록, explicit 후보 item 선택, current target feedback, graph selection 기반 passive selected Strong feedback이다. 좌측 surface는 graph/detail/selected/history owner, repository owner, create/edit/write owner가 아니다.

Phase 19-A의 “명령 surface” 표현은 장기 UX 개념으로만 사용한다. keyboard command, command palette, recent search, persistence, search ranking 개선을 승인하지 않는다. AppBar의 DB 초기화/실행 취소 같은 write action과 상단 검색/명령 surface 역할을 결합하지 않으며, 좌측 또는 상단 surface에 create/edit/write entry를 추가하지 않는다.

Phase 19-A는 `WordExplorerScreen` production owner state migration, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, graph selection 기반 Explorer retarget, 새 DB query, 새 repository read/API, 신규 DTO/model, dependency 변경을 승인하지 않는다.

### 17.117 Phase 19-B 상단 검색 surface presentation 최소 구현

Phase 19-B는 large-screen `HomeScreen`에서 일반 검색 입력을 좌측 control surface 내부가 아니라 좌우 split 전체 위의 workspace 상단 surface로 시각 재배치한 owner-preserving presentation 단계다.

large-screen production mount 구조는 다음과 같다.

```text
HomeScreen
└─ Scaffold.body
   └─ LayoutBuilder
      └─ large-screen outer Row
         └─ Expanded
            └─ Column
               ├─ homeWorkspaceSearchSurface
               │  └─ homeSearchControlArea
               │     └─ _searchController 기반 일반 검색 입력
               └─ Expanded
                  └─ Row
                     ├─ homePane
                     │  ├─ homeStrongControlArea
                     │  │  └─ _strongJumpController 기반 Strong/스트롱 입력
                     │  └─ Strong Rail + default/search 목록
                     └─ WordExplorerScreen
```

이번 변경은 `HomeScreen.build()` 내부 widget composition만 조정했다. 일반 검색 state와 handler는 계속 `HomeScreen` private state가 소유하며 `_searchController`, `_runSearch(...)`, `_clearSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` 책임은 이동하지 않았다.

좌측 control surface에는 다음 역할을 유지한다.

- `Strong/스트롱` rail-local jump 입력
- Strong Rail 및 Strong anchor orientation
- default Strong 목록 또는 일반 검색 실행 후 검색 후보 목록
- 명시적 후보 item 선택과 기존 large-screen Explorer retarget request
- current Explorer target feedback
- graph selection 기반 passive selected Strong feedback

상단 search submit은 기존 `_runSearch(...)`만 호출하고 검색 후보/default 목록 전환까지만 수행한다. submit 자체는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. 검색 후보 item tap과 Strong Rail item tap의 기존 명시적 Explorer retarget 경로는 유지한다.

`Strong/스트롱` 입력은 기존 `_handleStrongRailJumpChanged(...)`, `_handleStrongRailJumpSubmitted(...)`, `_jumpToStrongInRail(...)` 경로를 유지하며 일반 검색 실행, 목록 전환, Explorer retarget/remount와 결합하지 않는다. graph selection passive sync도 기존 rail-local passive feedback 및 jump 경로만 유지한다.

small-screen은 기존 `homePane` 안의 일반 검색 입력과 검색 후보 item tap의 detail route 흐름을 유지한다. 별도 `Strong/스트롱` 입력, Strong Rail, embedded `WordExplorerScreen`을 추가하지 않았다.

Phase 19-B는 DB, repository read/API, DTO/model, dependency, `WordExplorerScreen` owner state, `ExplorerWorkspace` production mount, `ExplorerWorkspaceState` source-of-truth를 변경하지 않는다. 좌측 또는 상단 create/edit/write entry, keyboard access, command palette, search ranking, recent search, persistence도 추가하지 않았다.

명령어 기반 검증 결과:

- Phase 19-B 신규 guardrail 단독 실행: 통과, `+7`, `All tests passed!`.
- 기존 Phase 18-N runtime widget guardrail 단독 실행: 통과, `+3`, `All tests passed!`.
- Phase 17-B/C 및 Phase 18-A/B/C/D/F/G/I/K/M/N, Phase 19-B guardrail 묶음: 통과, `+82`, `All tests passed!`.
- Phase 19-B 신규 guardrail은 large-screen 상단 검색 mount, 좌측 Strong/Rail/list 유지, search submit 비-retarget, 명시적 후보 item retarget, Strong/passive sync 경계, small-screen 흐름, owner 금지선을 확인한다.
- Phase 19-B 변경 파일 대상 analyze: exit code `0`. 기존 `HomeScreen` warning/info 5건만 확인했고 신규 오류는 없다.
- 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`. 이번 범위에서 수정하지 않았다.

### 17.118 Phase 19-C 상단 검색 surface guardrail hardening 및 종료 audit

Phase 19-C는 Phase 19-B 이후 large-screen 상단 검색 surface, 좌측 control surface, Strong Rail, 우측 Explorer owner 경계가 다시 섞이지 않도록 source guard를 보강하고 Phase 19 종료 가능 여부를 판단한 guardrail/docs 단계다. production code, DB, repository read/API, DTO/model, dependency, UX 기능은 변경하지 않았다.

#### 최종 active boundary

- large-screen 일반 검색 입력은 좌우 split 전체 위의 `homeWorkspaceSearchSurface`에 mount된다.
- large-screen 좌측 `homePane`에는 일반 검색 입력이 남지 않으며 `Strong/스트롱` 입력, Strong Rail, default/search 목록, current target feedback, passive selected Strong feedback을 유지한다.
- small-screen 일반 검색 입력은 기존 `homePane` 흐름을 유지하고 검색 후보 item tap은 detail route를 연다.
- 일반 검색 submit은 검색 목록 상태만 변경하며 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- `Strong/스트롱` changed/submitted/run handler는 `_jumpToStrongInRail(...)` rail-local 경로로 제한하며 `_runSearch(...)`, 검색 결과/default 목록 전환, Explorer retarget/remount와 결합하지 않는다.
- graph selection passive sync는 rail-local passive feedback 및 jump로 제한하며 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- `WordExplorerScreen`은 graph center, selected word, detail target, history의 production owner로 유지된다.
- `ExplorerWorkspace` production shell mount와 `ExplorerWorkspaceState` production source-of-truth 승격은 금지 상태를 유지한다.

#### guardrail 보강

- `test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart`의 Phase 19-B 이전 넓은 source slice를 `homeSearchControlArea`, `homeStrongControlArea`, `homeWorkspaceSearchSurface`, `homePane`별 검사로 교체했다.
- 같은 guard에서 Strong changed/submitted/run handler를 각각 분리해 검색 실행, 목록 전환, Explorer retarget, repository read와 결합되지 않는 경계를 고정했다.
- `test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart`를 추가해 Phase 19 최종 active boundary와 production mount 금지선을 전용 source guard로 고정했다.

#### 명령어 기반 검증 결과

- Phase 19-B 신규 guardrail 단독 실행: 통과, `+7`, `All tests passed!`.
- Phase 18-C/M 및 Phase 19-B source guard 묶음: 통과, `+21`, `All tests passed!`.
- Phase 18-N runtime widget guardrail 단독 실행: 통과, `+3`, `All tests passed!`.
- Phase 17-B/C 및 Phase 18-A/B/C/D/F/G/I/K/M/N, Phase 19-B guardrail 묶음: 통과, `+82`, `All tests passed!`.
- Phase 19-C 신규 guardrail 단독 실행: 통과, `+7`, `All tests passed!`.
- 보정한 Phase 18-M 및 신규 Phase 19-C guardrail 묶음: 통과, `+13`, `All tests passed!`.
- 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치 error 13건과 기존 warning/info를 포함해 `47 issues found`, exit code `1`. Phase 19-C 신규 문제는 확인되지 않았으며 기존 기술 부채로 분리한다.

#### Phase 19 종료 판단

Phase 19의 목표였던 large-screen 일반 검색 입력의 owner-preserving 상단 surface 재배치와 상단 검색/좌측 control/Strong Rail/Explorer owner 경계 고정은 완료되었다. Phase 19-B UI 수동 테스트는 클라이언트 기준으로 통과했고 Phase 19-C는 production UI를 변경하지 않았다. 따라서 현재 승인 범위와 검증 기준에서는 Phase 19를 종료할 수 있다.

keyboard access, command palette, search ranking, recent search, persistence, AppBar write action 결합, `ExplorerWorkspace` production mount, `ExplorerWorkspaceState` source-of-truth 승격은 Phase 19 종료 범위에 포함하지 않으며 별도 설계와 승인 없이는 진행하지 않는다.

### 17.119 Phase 20-A Surface & Navigation Role Audit active boundary

Phase 20-A는 Phase 19 이후 large-screen workspace의 상단 검색 surface, 좌측 control surface, graph/detail standalone route와 small-screen flow의 장기 역할을 실제 production source 기준으로 확인한 read-only docs/audit 단계다. 상세 source 근거와 판단은 `docs/ux/explorer_workspace_phase20a_surface_navigation_role_audit.md`에 reference/context 기록으로 남긴다.

현재 large-screen 일반 검색 입력은 좌우 split 전체 위의 `homeWorkspaceSearchSurface`에 있고, 좌측 `homePane`에는 `Strong/스트롱` rail-local jump 입력, Strong Rail, default/search 목록, current Explorer target feedback, graph selection passive feedback이 있다. 상단 검색 입력과 좌측 Strong 입력의 역할은 분리되어 있지만, query-specific 검색 결과와 default Strong 전체 목록이 좌측에 계속 표시되어 좌측 surface가 persistent navigation/orientation 보조와 global discovery/result 표시를 함께 담당하는 역할 충돌이 있다.

large-screen 일반 검색 결과를 상단 검색에 딸린 transient result surface로 표현하는 방향은 후속 구현 후보로 검토할 수 있다. 이 후보는 query와 결과의 interaction context를 가깝게 하고 좌측 control surface를 Strong 기반 navigation 보조 역할로 좁힐 수 있다. 다만 Phase 20-A에서는 result surface 이동, exact presentation, state owner 이동, submit 기반 Explorer retarget을 구현하거나 확정하지 않는다. 검색 결과/default 목록은 현재 좌측 surface에 유지한다.

default Strong 전체 목록은 Strong Rail과 같은 persistent navigation으로 보기보다 browse/discovery 성격이 강하다. large-screen에서 계속 필요하다면 명시적 browse/discovery surface로 재정의하는 장기 전환 후보가 적절하다. Phase 20-A에서는 default Strong 목록의 제거, 이동, 축소를 확정하지 않으며 small-screen 기존 home flow에서는 즉시 유지한다.

large-screen `HomeScreen`의 default/search 목록 상세·그래프 아이콘은 embedded `WordExplorerScreen`이 존재하는 상태에서도 `WordDetailScreen` 또는 `WordGraphScreen` standalone route를 연다. `WordExplorerScreen` 내부 full detail route, `WordDetailScreen`의 graph route, callback 없는 `WordGraphScreen`의 자체 graph route 탐색과 create 후 replacement도 존재한다. large-screen standalone route를 줄이는 방향은 pane 중심 continuity를 위한 장기 전환 후보지만, small-screen/mobile flow와 full detail/standalone graph 역할 때문에 전역 제거는 아직 부적절하다.

후속 후보 순서는 form factor/action intent별 route inventory 고정, large-screen pane action 설계, `HomeScreen` large-screen standalone entry부터 workspace-aware redirect 후보 검토, `WordExplorerScreen` full detail 역할 분리, detail/graph standalone 내부 의존성 감사, small-screen 유지 상태의 large-screen 전용 전환 검토, route/internal history와 repository refresh 경계 설계 이후 제거 가능성 재검토 순으로 둔다. 각 항목은 별도 설계와 승인이 필요하며 이동 또는 제거 확정이 아니다.

small-screen `homePane → detail route`는 즉시 유지한다. small-screen에는 embedded Explorer와 Strong Rail이 없고 현재 detail route가 primary reading surface 역할을 하므로 large-screen pane 방향을 그대로 적용하지 않는다. 장기적으로 search, detail, graph, return path의 semantic continuity를 보존하는 `mobile Explorer presentation`으로 재정의할 수 있는지는 별도 audit 대상으로 남긴다.

Phase 20-A는 production code, test/guardrail, DB/data/sql, dependency, `pubspec.yaml`, `pubspec.lock`, route redirect, standalone route 제거, UI를 변경하지 않는다. large-screen 상단 검색, 좌측 일반 검색 입력 부재, small-screen 기존 home flow, search submit 비-retarget, `Strong/스트롱` rail-local jump, graph selection passive sync, `WordExplorerScreen` graph/detail/selected/history owner 유지, `ExplorerWorkspace` production shell mount 금지, `ExplorerWorkspaceState` source-of-truth 승격 금지의 Phase 19 경계를 유지한다.

Phase 20-A는 docs/audit-only이므로 Flutter test와 전체 analyze를 재실행하지 않는다. 기존 전체 analyze의 `47 issues found`, exit code `1`은 선행 기술 부채이며 Phase 20-A에서 새로 발생한 문제가 아니다.

### 17.120 Phase 20-B Search Result Surface Contract Audit active boundary

Phase 20-B는 Phase 20-A에서 확인한 large-screen 검색 결과/default Strong 목록의 좌측 surface 역할 충돌을 검색 결과 surface 계약 관점에서 구체화한 read-only docs/audit 단계다. 상세 source 근거와 판단은 `docs/ux/explorer_workspace_phase20b_search_result_surface_contract_audit.md`에 reference/context 기록으로 남긴다.

현재 일반 검색 query, `_runSearch(...)`, `_clearSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`는 계속 `HomeScreen` private state가 소유한다. large-screen 일반 검색 입력은 workspace 상단 `homeWorkspaceSearchSurface`에 있고, 검색 결과와 default Strong 목록은 같은 좌측 `homeWordListSurface`를 공유한다. small-screen은 기존 `homePane` 안에서 일반 검색 입력과 default/search 목록을 함께 유지한다.

현재 공유 구조에는 역할 충돌이 있다. 검색 결과는 특정 query에 종속된 semantic candidate/result entry지만 default Strong 목록은 empty-query browse/discovery 후보이다. 두 목록이 같은 좌측 surface를 공유하면서 좌측 `homePane`은 Strong Rail 기반 persistent navigation/orientation 보조와 global search result/default browse 표시를 함께 담당한다.

large-screen 검색 결과 surface는 `query-bound transient result surface` 후보로 정의한다. 검색 submit은 result surface 갱신 또는 표시까지만 허용하며 submit만으로 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. 명시적 검색 후보 item 본문 tap은 기존 `_showWordInLargeScreenExplorerPane(wordId)` Explorer retarget 경로를 유지해야 한다. exact presentation, open/close lifecycle, dismiss, focus 복귀, search state owner 이동은 Phase 20-B에서 확정하거나 구현하지 않는다.

default Strong 목록은 search result가 아니라 `browse/discovery surface` 후보로 정의한다. Strong Rail은 persistent navigation/orientation 보조이고 default Strong 목록은 empty-query browse/discovery 후보이므로 같은 Strong data를 사용해도 역할은 같지 않다. Phase 20-B에서는 default Strong 목록의 삭제, 축소, 이동 또는 대체를 결론 내리지 않으며 small-screen 기존 home browse/default 목록 역할을 유지한다.

`Strong/스트롱` 입력은 좌측 rail-local jump 전용으로 유지하고 `_runSearch(...)`, 검색 결과/default 목록 전환, Explorer retarget/remount와 결합하지 않는다. graph selection passive sync도 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. `WordExplorerScreen`은 graph center, selected word, detail target, history의 production owner로 유지한다.

Phase 20-B는 production code, test code, DB/data/sql, dependency, `pubspec.yaml`, `pubspec.lock`, UI와 route를 변경하지 않는다. large-screen transient search result surface 구현, `ExplorerWorkspace` production shell mount, `ExplorerWorkspaceState` production source-of-truth 승격, small-screen `homePane → detail route` 변경을 수행하지 않는다. 검색 결과/default 목록은 현재 좌측 control surface에 유지한다.

Phase 20-C 이후 후보는 large-screen query-bound transient result surface 최소 presentation, large-screen 검색 결과 presentation과 현재 공유 목록 surface의 responsive 분리, query/loading/no-result/clear/dismiss lifecycle 설계, 명시적 후보 tap retarget과 focus 복귀 계약, 관련 guardrail 보강, default Strong browse/discovery surface 별도 설계다. 각 후보는 별도 설계와 승인 없이 구현하지 않는다.

Phase 20-B는 UI를 변경하지 않으므로 Codex는 UI 수동 테스트를 수행하지 않는다. 후속 구현 phase에서는 large-screen submit 비-retarget, 명시적 후보 item tap retarget, default browse/search result 역할 분리, Strong rail-local jump, graph passive sync, small-screen 기존 detail route를 클라이언트 UI 체크리스트로 확인해야 한다.

### 17.121 Phase 20-C large-screen transient search result surface 최소 구현 active boundary

Phase 20-C는 large-screen 상단 일반 검색 입력 아래에 query-bound transient search result surface를 같은 widget tree 안의 inline attached panel로 최소 구현한 단계다. 상세 구현, 검증 결과, 클라이언트 UI 체크리스트는 `docs/ux/explorer_workspace_phase20c_transient_search_result_surface_minimum_slice.md`에 reference/context 기록으로 남긴다.

검색 state owner는 계속 `_HomeScreenState` private state다. `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`의 책임과 기존 검색 repository/API 의미는 이동하거나 변경하지 않는다. 새 `_isLargeScreenTransientSearchResultVisible` state는 panel presentation 표시 여부만 소유하며 query, result data, Explorer target의 source-of-truth가 아니다.

non-empty query submit은 기존 search list 전환과 future 갱신을 수행하면서 large-screen transient panel을 열거나 갱신할 수 있다. 검색 submit만으로 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. transient panel의 명시적 검색 후보 item 본문 tap만 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로로 Explorer를 retarget하고, 이후 panel presentation을 닫는다.

`검색 결과 닫기`는 transient panel presentation만 닫고 Explorer target, query, search future, 좌측 검색 결과 목록을 유지한다. 기존 `초기화`는 `_clearSearch()` 흐름과 일관되게 default Strong 목록 상태로 복귀하고 panel을 닫지만 Explorer target은 변경하지 않는다.

Phase 20-C는 기존 좌측 `homeWordListSurface`의 검색 결과/default Strong 목록을 삭제, 축소, 이동하지 않는다. large-screen 상단 transient panel과 좌측 검색 결과 중복 표시는 점진 전환 상태로 허용한다. default Strong 목록과 Strong Rail은 좌측에 유지하며 좌측 surface의 최종 browse/discovery 재정의와 중복 제거 여부는 후속 설계 대상으로 남긴다.

`Strong/스트롱` 입력은 rail-local jump 전용으로 유지하며 `_runSearch(...)`, transient panel lifecycle, 검색 결과/default 목록 전환, Explorer retarget/remount와 결합하지 않는다. graph selection passive sync도 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

small-screen에는 transient panel을 mount하지 않으며 기존 `homePane → detail route` 흐름을 유지한다. `WordExplorerScreen`은 graph center, selected word, detail target, history의 production owner로 유지한다. production `ExplorerWorkspace` mount와 `ExplorerWorkspaceState` source-of-truth 승격은 금지 상태를 유지한다.

Phase 20-C는 DB, repository read/API, DTO/model, dependency, `pubspec.yaml`, `pubspec.lock`을 변경하지 않았다. 신규 source guardrail `+9`, 신규 실제 DB 기반 runtime widget guardrail `+3`, 기존 Phase 19-B/19-C guardrail `+14`, 기존 Phase 18-N runtime guardrail `+3`, 기존 Phase 17-B/C 및 Phase 18-K/M owner·passive sync·Strong 분리 guardrail `+26`이 통과했다. 변경 파일 대상 analyze는 기존 `HomeScreen` warning/info 5건만 보고하고 exit code `0`이며 Phase 20-C 신규 오류는 없다. 전체 analyze도 실제 실행했으며 기존 기준과 동일한 `47 issues found`, exit code `1`이다. error 13건은 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치이므로 이번 범위와 분리한다.

Codex는 UI 기반 수동 테스트를 수행했다고 보고하지 않는다. 클라이언트는 large-screen `H2` submit 비-retarget, 후보 tap retarget 후 panel 닫힘, dismiss/초기화 비-retarget, `G26` Strong rail-local jump, 좌측 중복 목록과 default Strong 유지, small-screen `H2` detail route를 확인해야 한다. 클라이언트 UI 확인 전에는 Phase 20-C의 최종 UX 승인 또는 후속 중복 제거를 선언하지 않는다.

### 17.122 Phase 20-D 좌측 control surface browse/discovery 역할 분리 audit active boundary

Phase 20-D는 Phase 20-C 이후 large-screen 좌측 control surface에 함께 남아 있는 query-bound 검색 결과 목록, default Strong 목록, Strong Rail의 역할을 실제 production source와 guardrail 기준으로 분리한 docs/audit-only 단계다. 상세 source 근거와 판단은 `docs/ux/explorer_workspace_phase20d_left_control_browse_discovery_role_audit.md`에 `reference/context` 기록으로 남긴다.

large-screen query-bound search result는 상단 일반 검색 입력 아래의 transient result surface에 귀속한다. 좌측 `homeWordListSurface`에 남은 query-bound search result list는 Phase 20-C 최소 구현 이후 유지된 transition/legacy duplicate presentation으로 분류한다. Phase 20-D에서는 이를 제거하지 않지만, 최종 large-screen 검색 결과 surface로 취급하지 않는다.

default Strong 목록은 search result 또는 검색 결과 없음 fallback이 아니라 empty-query browse/discovery surface 후보로 분류한다. Strong Rail은 Strong 번호 중심 compact navigation/orientation surface이고, default Strong 목록은 전체 목록형 정보와 상세/그래프 action을 제공하는 browse/discovery 후보이므로 같은 `_defaultStrongListFuture`를 사용해도 역할은 같지 않다. Phase 20-D에서 default Strong 목록의 삭제, 축소, 이동, 대체 또는 Strong Rail과의 장기 병합을 확정하지 않는다.

large-screen 좌측 목록과 small-screen 목록은 현재 같은 `homeWordListSurface` builder/composition을 공유한다. 그러나 large-screen query-bound 결과는 상단 transient surface에 귀속되고 small-screen 검색 결과 목록은 `homePane → detail route`의 primary surface이므로 UX 의미는 다를 수 있다. small-screen 기존 흐름은 유지한다.

Phase 20-E 최소 구현 후보는 `homeLeftControlListSurface` responsive composition에서 large-screen query-bound 목록 presentation만 분리하거나 제거하는 범위로 제한한다. Phase 20-E에서도 `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` owner와 의미, default Strong 목록, Strong Rail, small-screen `homePane → detail route`, 검색 submit 비-retarget, graph passive sync 비-retarget을 우선 변경하지 않는 방향이 안전하다.

Phase 20-C source/runtime guardrail은 좌측 duplicate 검색 결과 유지 상태를 명시적으로 고정하고 있다. Phase 20-E 구현 시에는 해당 duplicate 유지 assertion만 새 active boundary에 맞게 재정의하고, default Strong 목록과 small-screen detail route 유지 assertion은 계속 방어해야 한다.

Phase 20-D는 production code, test code, DB/data/sql, repository read/API, DTO/model, dependency, `pubspec.yaml`, `pubspec.lock`, route, UI를 변경하지 않는다. Phase 20-C 중복 상태·small-screen source guardrail `+9`와 검색/Strong/passive sync/workspace owner source guardrail `+33`이 통과했다. production `ExplorerWorkspace` mount와 `ExplorerWorkspaceState` production source-of-truth 승격 금지 상태를 유지한다. docs/audit-only 단계이므로 Codex는 UI 테스트를 수행했다고 보고하지 않으며, 전체 analyze는 기존 `47 issues found`, exit code `1` 기술 부채와 섞지 않기 위해 실행하지 않는다.

### 17.123 Phase 20-E large-screen 좌측 검색 결과 중복 표시 제거 active boundary

Phase 20-E는 Phase 20-D에서 확정한 역할 분리에 따라 large-screen 좌측 control surface의 query-bound search result duplicate presentation만 제거한 최소 구현 단계다.

large-screen `homeLeftControlListSurface`는 Strong Rail을 항상 유지한다. `_isShowingDefaultStrongList`가 `true`인 default mode에서만 divider와 `homeWordListSurface`를 Strong Rail 옆에 mount하므로 default Strong browse/discovery 목록은 유지된다. query-bound mode에서는 좌측 `homeWordListSurface`를 mount하지 않으며 검색 결과는 상단 transient result surface에만 표시한다.

small-screen branch는 계속 `homeLeftControlListSurface = homeWordListSurface`와 `return homePane` 흐름을 사용한다. 따라서 small-screen 검색 결과 목록과 item tap의 `WordDetailScreen` detail route 흐름은 유지된다.

검색 state owner와 실행 의미는 변경하지 않는다. `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`는 계속 `_HomeScreenState` private state에 있고, `_runSearch(...)`는 검색 future와 presentation state만 갱신하며 Explorer를 retarget하지 않는다. large-screen transient 후보 item의 명시적 tap만 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로로 Explorer를 retarget한 뒤 panel을 닫는다.

`Strong/스트롱` 입력은 rail-local jump 전용이고 Strong Rail item tap은 기존 Explorer retarget 경로를 유지한다. graph passive sync는 rail-local passive feedback과 jump만 수행하며 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. production `ExplorerWorkspace` mount와 `ExplorerWorkspaceState` production source-of-truth 승격 금지 상태도 유지한다.

Phase 20-E source guardrail은 shared `homeWordListSurface`와 small-screen detail route를 유지하면서 large-screen 목록 mount가 default Strong mode 조건부임을 확인한다. 실제 DB 기반 runtime guardrail은 large-screen query submit 후 transient panel과 Strong Rail은 유지되고 좌측 query-bound 후보는 없으며, clear 후 default Strong browse/discovery 목록이 복귀하고, transient 후보 tap은 Explorer를 retarget하며, small-screen detail route가 유지됨을 확인한다.

명령어 기반 검증 결과는 Phase 20-C 조정 source guardrail `+9`, 실제 DB 기반 runtime guardrail 최종 `+3`, Phase 19-C·18-M/K·17-B/C source guardrail 묶음 `+33`, Phase 18-N runtime guardrail `+3`으로 모두 통과했고 최종 관련 source/runtime 묶음도 `+48`, `All tests passed!`로 통과했다. 변경 파일 대상 analyze는 exit code `0`이며 기존 `HomeScreen` warning/info 5건만 확인했다. 전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`는 기존 `47 issues found`, exit code `1` 기술 부채와 섞지 않기 위해 실행하지 않는다.

Phase 20-E는 repository read/query, DB/data/sql, DTO/model, dependency, `pubspec.yaml`, `pubspec.lock`, route-level overlay, `OverlayEntry`를 변경하거나 추가하지 않는다.

#### 클라이언트 UI 기반 수동 테스트 체크리스트

Codex는 UI 기반 수동 테스트를 수행했다고 보고하지 않는다. 클라이언트는 Windows Desktop 앱에서 아래 항목을 확인한다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| large-screen 일반 검색 submit | 상단 transient panel에 결과가 표시되고 좌측 control surface에는 query-bound 검색 결과가 중복 표시되지 않으며 Explorer target은 유지된다. | 좌측 검색 후보 목록 표시, transient panel 미표시, submit 즉시 Explorer retarget | 창 너비를 900px 이상으로 두고 상단 검색 입력에 `H2`를 입력한 뒤 Enter 또는 검색 버튼을 사용한다. |
| large-screen transient 후보 클릭 | 선택 후보로 Explorer pane이 retarget되고 transient panel이 닫힌다. | Explorer target 유지, submit 시점 조기 retarget, 후보 선택 후 panel 잔류 | `H2` transient 결과의 후보 본문을 클릭하고 우측 Explorer와 panel 상태를 확인한다. |
| large-screen 검색 결과 닫기 | Explorer target과 Strong Rail은 유지되고 transient panel만 닫히며 좌측 query-bound 결과는 나타나지 않는다. | Explorer target 변경, 좌측 검색 결과 재표시, Strong Rail 소실 | `H2` 검색 후 `검색 결과 닫기`를 누르고 우측 Explorer와 좌측 rail을 확인한다. |
| large-screen clear | transient panel이 닫히고 default Strong browse/discovery 목록이 Strong Rail 옆에 복귀하며 Explorer target은 유지된다. | default Strong 목록 미복귀, Explorer target 변경, Strong Rail 소실 | `H2` 검색 후 `초기화`를 누르고 좌측 default Strong 목록과 우측 Explorer를 확인한다. |
| small-screen 검색과 후보 tap | 기존 `homePane` 검색 결과 목록이 표시되고 후보 tap이 detail route를 연다. | 검색 결과 목록 미표시, transient panel 또는 embedded Explorer 표시, detail route 미진입 | 창 너비를 900px 미만으로 줄이고 `H2`를 검색한 뒤 후보 본문을 클릭한다. |
| `Strong/스트롱` 입력 | Strong Rail 위치/feedback만 변하며 일반 검색 결과와 transient panel lifecycle에는 영향을 주지 않는다. | 일반 검색 실행, transient panel open/close, Explorer retarget | large-screen `Strong/스트롱` 입력에 `G26`을 입력하고 panel, rail, Explorer 상태를 비교한다. |
| Strong Rail item tap | 기존 `_showWordInLargeScreenExplorerPane(...)` 경로로 Explorer가 retarget된다. | Explorer target 유지 또는 standalone route 이동 | large-screen Strong Rail의 식별 가능한 Strong 번호 item을 클릭하고 우측 Explorer target 변화를 확인한다. |

### 17.124 Phase 20-F large-screen 좌측 Strong Rail compact surface active boundary

Phase 20-F는 Phase 20-E 이후 large-screen 좌측 control surface에 남아 있던 default Strong browse/discovery 목록도 미표시로 전환하고, 좌측 surface를 Strong 입력과 Strong Rail 중심의 compact navigation surface로 좁힌 구현 단계다.

large-screen `homeLeftControlListSurface`는 default/query-bound mode와 관계없이 Strong Rail만 mount한다. large-screen에서는 shared `homeWordListSurface`를 mount하지 않으므로 query-bound 검색 결과 목록과 default Strong browse/discovery 목록 모두 좌측에 표시하지 않는다. query-bound 검색 결과는 계속 상단 일반 검색 입력 아래의 transient result surface에 귀속한다.

large-screen 좌측 surface 폭은 클라이언트 UI 확인 결과를 반영해 `_largeScreenStrongControlSurfaceWidth = 160.0`으로 고정한다. Strong 입력과 Rail item은 `_largeScreenStrongControlHorizontalPadding = 12.0`을 공유한다. Strong 입력은 별도 고정 폭 wrapper를 사용하지 않고 160px surface의 좌우 padding을 제외한 136px content 폭을 사용한다. `Strong/스트롱` label은 compact 폭에서 잘리지 않도록 항상 floating 표시한다. 이 계약은 `H1 또는 G26` hint, `G26`, `H7225` 같은 입력값과 Strong Rail 번호를 안정적으로 표시하면서 불필요한 목록 영역을 줄이는 조정 기준이다.

small-screen branch는 계속 `homeLeftControlListSurface = homeWordListSurface`와 `return homePane` 흐름을 사용한다. 따라서 small-screen default Strong 목록, 검색 결과 목록, item tap의 `WordDetailScreen` detail route 흐름은 유지된다. Phase 20-E의 default Strong 목록 유지 계약은 Phase 20-F 이후 앱 전체 목록 삭제 금지와 small-screen browse/default 흐름 유지 계약으로 해석하며, large-screen 표시 유지 계약으로 해석하지 않는다.

검색 state owner와 실행 의미는 변경하지 않는다. `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`는 계속 `_HomeScreenState` private state에 있고, 검색 submit만으로 Explorer를 retarget하지 않는다. transient 후보 item의 명시적 tap만 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로로 Explorer를 retarget한다.

`Strong/스트롱` 입력은 rail-local jump 전용이며 일반 검색이나 transient panel lifecycle과 결합하지 않는다. Strong Rail item tap은 기존 Explorer retarget 경로를 유지한다. graph passive sync는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다. production `ExplorerWorkspace` mount와 `ExplorerWorkspaceState` production source-of-truth 승격 금지 상태도 유지한다.

Phase 20-F source guardrail은 large-screen Rail-only compact surface, 160px 고정 폭, Strong 입력 always-floating label, shared small-screen 목록, 검색/Strong/passive sync/workspace owner 경계를 확인한다. 실제 DB 기반 runtime guardrail은 large-screen Strong 입력 136px content 폭과 always-floating label, Strong Rail 160px 폭, `H7225` 입력 보존, 초기/default/query/clear 상태에서 좌측 default/search 목록 미표시, transient 후보 tap retarget과 small-screen default/search/detail 흐름 유지를 확인한다.

명령어 기반 검증에서 수정된 Phase 18-B/C/G/I, Phase 19-B/C, Phase 20-C source guardrail과 Phase 18-F/K/M, Phase 17-B/C 경계 guardrail 묶음은 `+82`, 실제 DB 기반 Phase 20-C/18-N runtime guardrail 묶음은 `+6`으로 모두 통과했다. 최종 관련 source/runtime guardrail 묶음도 `+88`, `All tests passed!`로 통과했다. 변경 파일 대상 `dart analyze`는 신규 error 없이 기존 `home_screen.dart` warning/info 5건만 확인했으며 exit code는 `1`이다. 전체 analyze는 기존 `47 issues found`, exit code `1` 기술 부채와 섞지 않기 위해 실행하지 않는다.

Phase 20-F는 dependency, `pubspec.yaml`, `pubspec.lock`, DB/data/sql, repository/data source, DTO/model, route를 변경하지 않는다.

#### 클라이언트 UI 기반 수동 테스트 체크리스트

Codex는 UI 기반 수동 테스트를 수행했다고 보고하지 않는다. 클라이언트는 Windows Desktop 앱에서 아래 항목을 확인한다.

| 테스트 시나리오 | 기대 결과 | 실패 시 관찰 포인트 | 실제 확인 방법 |
| --- | --- | --- | --- |
| large-screen 앱 진입 | 좌측에 default Strong browse/discovery 목록이 없고 Strong 입력과 Strong Rail만 160px compact surface 안에 표시된다. `Strong/스트롱` label은 항상 floating 표시되고, `H1 또는 G26`, `G26`, `H7225`와 Rail 번호가 잘리지 않는다. | default Strong 목록 표시, 넓은 빈 목록 영역, 입력 label/hint/value 또는 Rail 번호 잘림 | 창 너비를 900px 이상으로 두고 앱에 진입한 뒤 좌측 surface 폭과 Strong 입력/Rail 표시를 확인하고 `G26`, `H7225`를 입력해 본다. |
| large-screen 일반 검색 submit | 상단 transient panel에 `H2` 결과가 표시되고 좌측에는 query-bound 검색 결과 목록이 나타나지 않으며 Explorer target은 유지된다. | 좌측 검색 결과 목록 표시, transient panel 미표시, submit 즉시 Explorer retarget | 상단 일반 검색 입력에 `H2`를 입력하고 Enter 또는 검색 버튼을 사용한 뒤 상단 panel, 좌측 surface, 우측 Explorer를 비교한다. |
| large-screen clear | transient panel이 닫히고 좌측 default Strong 목록은 나타나지 않으며 Strong Rail과 Explorer target은 유지된다. | default Strong 목록 복귀, Strong Rail 소실, Explorer target 변경 | `H2` 검색 후 `초기화`를 누르고 상단 panel, 좌측 Rail, 우측 Explorer를 확인한다. |
| large-screen `Strong/스트롱` 입력 | `G26` 입력이 Strong Rail 위치/feedback에만 영향을 주고 일반 검색 결과나 transient panel을 열거나 닫지 않으며 Explorer를 retarget하지 않는다. | 일반 검색 실행, transient panel open/close, Explorer retarget | transient panel이 닫힌 상태와 열린 상태에서 각각 `G26`을 입력하고 panel, Rail, Explorer 상태를 비교한다. |
| large-screen Strong Rail item tap | 식별 가능한 Strong 번호 item tap이 기존 경로로 우측 Explorer를 retarget한다. | Explorer target 유지, standalone route 이동, 일반 검색/transient panel lifecycle 변경 | Strong Rail의 식별 가능한 번호 item을 클릭하고 우측 Explorer target 변화를 확인한다. |
| small-screen 앱 진입 | 기존 default Strong browse/discovery 목록이 표시되고 large-screen Strong Rail 또는 embedded Explorer가 나타나지 않는다. | default Strong 목록 미표시, Strong Rail 또는 embedded Explorer 표시 | 창 너비를 900px 미만으로 줄여 앱에 진입하고 기존 목록을 확인한다. |
| small-screen 검색과 후보 tap | `H2` 검색 결과 목록이 기존 `homePane`에 표시되고 후보 tap이 detail route를 연다. | 검색 결과 목록 미표시, transient panel 또는 embedded Explorer 표시, detail route 미진입 | small-screen에서 `H2`를 검색한 뒤 식별 가능한 후보 본문을 클릭하고 detail 화면 이동을 확인한다. |

### 17.125 Phase 20-G large-screen 검색 결과 floating panel active boundary

Phase 20-G는 Phase 20-F 이후 large-screen transient 검색 결과 panel이 기존 UI를 아래로 밀어내던 layout 참여 문제를 수정한 구현 단계다.

large-screen workspace composition은 `homeWorkspaceSearchSurface + Expanded(Stack(...))` 계열 구조를 사용한다. `Stack`의 base child는 기존 좌측 Strong Rail compact surface와 우측 `WordExplorerScreen` graph/detail 영역을 포함하는 `Row`이며, 이 base `Row`는 `Positioned.fill(...)`로 항상 같은 크기와 위치를 유지한다.

transient 검색 결과 panel은 같은 `HomeScreen` large-screen widget tree 내부에서 `Positioned(top: 0, left: 0, right: 0)`로 base layout 위에 배치한다. 따라서 panel open/close 여부는 좌측 Strong Rail compact surface와 우측 Explorer graph/detail 영역의 layout height, position, size 계산에 참여하지 않는다. `OverlayEntry`, route-level overlay, portal 구조는 사용하지 않는다.

panel은 상단 일반 검색 입력 아래의 workspace body 최상단에 붙어 나타난다. 기존 Phase 20-C~F의 surface color와 max height는 유지하되, `Material` elevation, shadow, 하단 radius를 적용해 floating surface로 읽히게 한다. panel 내부 loading, error, no-result, candidate list는 기존 `_searchWordsFuture`를 그대로 사용한다.

검색 state owner와 실행 의미는 변경하지 않는다. `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList`는 계속 `_HomeScreenState` private state에 있고, `_runSearch(...)`는 검색 future와 panel presentation state만 갱신한다. 검색 submit만으로 `_largeScreenExplorerWordId`를 바꾸거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

transient 후보 item tap만 사용자의 명시적 Explorer retarget request로 해석한다. 후보 tap은 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로를 호출한 뒤 panel을 닫는다. `Strong/스트롱` 입력은 rail-local jump 전용으로 유지하며 일반 검색, transient panel lifecycle, Explorer retarget/remount와 결합하지 않는다. Strong Rail item tap은 기존 Explorer retarget 경로를 유지하고, graph passive sync는 `_largeScreenExplorerWordId`를 변경하거나 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.

small-screen branch는 계속 `return homePane` 흐름을 사용한다. small-screen default Strong 목록, 검색 결과 목록, item tap의 `WordDetailScreen` detail route 흐름은 Phase 20-G에서 변경하지 않는다.

Phase 20-G는 dependency, `pubspec.yaml`, `pubspec.lock`, DB/data/sql, repository/data source, DTO/model/public API, route를 변경하지 않는다. `docs/logs/FEATURE_STATUS.md`는 최신 Phase 20 active boundary를 기록하는 핵심 문서가 아니므로 변경하지 않는다.

Phase 20-G source guardrail은 base `Row`가 transient panel 조건 밖에 있고 panel이 local `Stack`/`Positioned` floating surface로만 mount되는지, submit 비-retarget과 후보 tap retarget 경로, small-screen `homePane` 흐름을 확인한다. 실제 DB 기반 runtime guardrail은 large-screen panel open/close 전후 Strong Rail `Rect`와 Explorer `Rect`가 유지되고, submit 비-retarget, 후보 tap retarget, small-screen detail route가 유지됨을 확인한다.

명령어 기반 검증에서 Phase 20-G 신규 source guardrail은 `+4`, 관련 Phase 20-G/20-C/19/18/17 source guardrail 묶음은 `+99`, Phase 20-C 및 Phase 18-N 실제 DB 기반 runtime guardrail 묶음은 `+6`으로 모두 통과했다. 변경 파일 대상 `dart analyze`는 신규 error 없이 기존 `home_screen.dart` warning/info 5건만 확인했으며 exit code는 `1`이다.

#### 클라이언트 UI 기반 수동 테스트 체크리스트

Codex는 UI 기반 수동 테스트를 수행했다고 보고하지 않는다. 클라이언트는 Windows Desktop 앱에서 아래 항목을 확인한다.

| 테스트 시나리오 | 테스트 목적 | 시작 화면 | 조작 순서와 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- | --- |
| large-screen 검색 panel open | floating panel open 시 base layout 안정성 확인 | 창 너비 900px 이상 large-screen `HomeScreen` | 상단 일반 검색창에 `H2`를 입력하고 Enter 또는 검색 버튼을 사용한다. | 검색 결과 panel이 검색창 아래에 붙어 나타나며 좌측 Strong Rail 위치와 폭이 변하지 않고 우측 Explorer graph/detail 영역이 아래로 밀리지 않으며 크기도 변하지 않는다. | panel 표시 순간 Explorer 영역이 아래로 이동함, 좌측 Strong Rail 높이/위치가 흔들림, 검색창 아래에 layout 여백이 새로 생김 | panel이 열린 상태에서도 Strong Rail과 Explorer graph/detail의 위치와 크기가 검색 전과 같음 |
| large-screen 검색 panel close | floating panel close 시 base layout 안정성 확인 | `H2` 검색 결과 panel이 열린 large-screen `HomeScreen` | 검색어를 지우거나 `검색 결과 닫기` 또는 기존 닫힘 조건을 수행한다. | panel이 사라져도 좌측 Strong Rail과 우측 Explorer graph/detail layout이 움직이지 않는다. | panel이 닫힐 때 Explorer 영역이 위로 튐, 좌측 Rail 위치가 변함 | panel open 전, open 중, close 후의 Strong Rail과 Explorer layout이 같은 위치와 크기로 보임 |
| 검색 submit 비-retarget 유지 | submit과 Explorer retarget 분리 확인 | large-screen `HomeScreen`에서 우측 Explorer가 기존 단어를 표시 중인 상태 | 상단 일반 검색창에 `H2`를 입력한 뒤 Enter 또는 검색 버튼만 수행한다. | 검색 결과 panel만 열리고 우측 Explorer graph/detail target은 바뀌지 않는다. | submit 순간 우측 Explorer가 첫 검색 결과로 이동함 | 후보 item을 클릭하기 전까지 우측 Explorer target이 유지됨 |
| 검색 후보 item tap retarget 유지 | 명시적 후보 선택의 기존 retarget 경로 확인 | `H2` 검색 결과 panel이 열린 large-screen `HomeScreen` | panel의 식별 가능한 후보 item 본문을 클릭한다. | 클릭한 후보 단어가 우측 Explorer graph/detail에 표시되고 panel은 닫힌다. | panel은 열리지만 item 클릭이 무시됨, 다른 단어로 이동함, graph/detail이 passive sync처럼 자동 변경됨 | 클릭한 후보와 우측 Explorer target이 일치하고 submit만으로는 이동하지 않음 |
| small-screen 회귀 확인 | large-screen floating panel 변경이 small-screen 흐름에 영향이 없는지 확인 | 창 너비 900px 미만 small-screen `HomeScreen` | 기존 homePane에서 `H2`를 검색하고 검색 결과 목록의 후보 item을 클릭한다. | small-screen에는 large-screen floating panel과 embedded Explorer가 나타나지 않고 기존 검색 결과 목록에서 `WordDetailScreen` detail route로 진입한다. | small-screen 검색 결과 목록이 사라짐, detail route 진입이 깨짐, large-screen 전용 floating panel이 small-screen에 나타남 | small-screen default/search 목록과 후보 tap detail route 흐름이 Phase 20-F 이전과 동일하게 동작함 |

### 17.126 Phase 20-H large-screen floating 검색 panel polish active boundary

Phase 20-H는 Phase 20-G의 local `Stack` / `Positioned` floating 검색 결과 panel 구조를 유지하면서 닫힘 조건, keyboard dismiss, empty query, 표시 범위 안정성을 보강한 구현 단계다.

panel이 열린 동안 base `Positioned.fill(child: Row(...))` 위와 panel 아래에 투명 dismiss layer를 mount한다. Explorer 또는 Strong Rail 영역의 첫 외부 클릭은 dismiss layer에서 panel close로 소비되며, 같은 클릭으로 Explorer target 변경이나 Strong Rail 이동을 수행하지 않는다. panel open/close 여부는 계속 base Row의 위치와 크기 계산에 참여하지 않는다.

large-screen workspace의 local `Focus.onKeyEvent` 경계는 descendant primary focus에서 bubbling되는 ESC key down만 감지한다. 초기 구현은 `Focus(canRequestFocus: false)` 조상 경계만 두어 Enter submit 후 primary focus가 검색 field descendant 경로를 벗어나면 ESC를 받을 수 없었다. 이를 보정하기 위해 large-screen 검색 field가 소유하는 `_largeScreenSearchFocusNode`를 추가하고, Enter submit 또는 검색 버튼으로 panel을 연 직후 `_runLargeScreenSearch()` presentation wrapper가 검색 focus를 post-frame 복귀시킨다. `_runSearch(...)` 의미는 변경하지 않는다.

focus 복귀는 non-empty large-screen 검색 submit으로 panel이 열린 직후에만 수행한다. `autofocus`와 불필요한 `unfocus`는 사용하지 않으며 입력 중 focus를 임의로 이동시키지 않는다. panel 내부 result list scroll 후에도 검색 focus 경로를 유지하므로 검색창을 다시 클릭하지 않고 ESC를 사용할 수 있다. ESC handler 자체는 panel presentation만 닫으며 검색어 삭제, 검색 결과 future 초기화, Explorer retarget, Strong Rail 이동, small-screen 흐름 변경을 수행하지 않는다.

large-screen 일반 검색 입력이 empty가 되면 stale 검색 결과 panel이 남지 않도록 panel presentation을 닫는다. 이 동작은 `_runSearch(...)` 의미나 검색 owner를 변경하지 않는다. `_searchController`, `_searchWordsFuture`, `_isShowingDefaultStrongList`는 계속 `_HomeScreenState` private state가 소유하며 검색 submit은 Explorer를 retarget하지 않는다.

panel 표시 범위는 기존 `ConstrainedBox(maxHeight: 320)`을 유지한다. 결과 목록은 기존 `Flexible` 내부 `ListView.builder`로 scroll하며 숫자, surface color, elevation, radius 등 Phase 20-G 디자인 계약을 과도하게 변경하지 않는다.

transient 후보 item tap만 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로로 Explorer를 retarget한 뒤 panel을 닫는다. small-screen은 계속 `return homePane`과 기존 검색 결과 목록의 `WordDetailScreen` detail route 흐름을 사용한다.

Phase 20-H는 `OverlayEntry`, route-level overlay, portal 구조, 신규 dependency, DB/API/repository, DTO/model/public API, Explorer graph/detail owner state, Strong Rail 구조를 변경하지 않는다.

명령어 기반 검증에서 Phase 20-H 신규 source guard는 `+7`, Phase 20-H ESC 보정 직접 관련 source/runtime 묶음은 `+46`, 전체 `flutter test`는 `+352`로 모두 통과했다. 전체 `dart analyze`는 이번 변경 범위 밖의 기존 `tool/verify_graph_*` error를 포함해 총 47건과 exit code `1`을 보고했다. 변경 Dart 파일 대상 analyze는 Phase 20-G 기준과 동일한 기존 `home_screen.dart` warning 1건과 info 4건만 확인했으며 Phase 20-H 신규 진단은 없다.

#### 클라이언트 UI 기반 수동 테스트 체크리스트

Codex는 UI 기반 수동 테스트를 수행했다고 보고하지 않는다. 클라이언트는 Windows Desktop 앱에서 아래 항목을 확인한다.

| 테스트 시나리오 | 테스트 목적 | 시작 화면 | 조작 순서와 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- | --- |
| large-screen 검색 panel 표시 | non-empty 검색 submit의 panel 표시 확인 | 창 너비 900px 이상 large-screen `HomeScreen` | 상단 일반 검색창에 `H2`를 입력하고 Enter 또는 검색 버튼을 사용한다. | floating 검색 결과 panel이 검색창 아래에 표시되고 Explorer target은 유지된다. | panel 미표시, submit 순간 Explorer target 변경 | panel은 열리지만 후보 item을 클릭하기 전까지 Explorer target이 유지됨 |
| Explorer 영역 외부 클릭 dismiss | 첫 외부 클릭 소비와 Explorer target 유지 확인 | `H2` 검색 결과 panel이 열린 large-screen 화면 | panel 아래 우측 Explorer graph/detail 영역을 한 번 클릭한다. | panel만 닫히고 Explorer target은 바뀌지 않는다. | panel 유지, 같은 클릭으로 graph/detail target 또는 selection 변경 | 첫 클릭으로 panel만 닫히고 Explorer 내용이 유지됨 |
| Strong Rail 영역 외부 클릭 dismiss | 첫 외부 클릭 소비와 Rail 이동 방지 확인 | `H2` 검색 결과 panel이 열린 large-screen 화면 | panel 아래 좌측 Strong Rail 영역을 한 번 클릭한다. | panel만 닫히고 Strong Rail 위치와 Explorer target이 유지된다. | Rail 이동 또는 Explorer retarget이 panel close와 동시에 발생 | 첫 클릭으로 panel만 닫히고 Rail과 Explorer가 유지됨 |
| Enter submit 직후 ESC dismiss | 검색창 재클릭 없이 ESC가 panel close만 수행하는지 확인 | large-screen `HomeScreen` | 검색창에 `H2`를 입력하고 Enter로 panel을 연 뒤 다른 곳을 클릭하지 않고 ESC를 누른다. | panel만 닫히고 검색어 `H2`, Explorer target, Strong Rail 위치가 유지된다. | ESC 무반응, 검색창 재클릭 필요, 검색어 삭제, Explorer retarget | Enter submit 직후 ESC 한 번으로 panel만 닫힘 |
| 검색 버튼·panel scroll 후 ESC dismiss | 검색 버튼과 panel interaction 후에도 ESC 경로가 유지되는지 확인 | large-screen `HomeScreen` | 검색창에 `H`를 입력하고 검색 버튼으로 panel을 연 뒤 결과 목록을 scroll하고 검색창 재클릭 없이 ESC를 누른다. | panel만 닫히고 검색어 `H`, Explorer target, Strong Rail 위치가 유지된다. | 검색 버튼 또는 scroll 후 ESC 무반응, 검색어 삭제, Explorer retarget | 검색 버튼과 panel scroll 후에도 ESC 한 번으로 panel만 닫힘 |
| 검색어 empty dismiss | stale panel 방지 확인 | 검색 결과 panel이 열린 large-screen 화면 | 검색창의 검색어를 전체 삭제한다. | floating panel이 즉시 닫힌다. | 이전 검색 결과가 stale panel로 남음 | 검색창이 empty가 되는 즉시 panel이 사라짐 |
| 많은 검색 결과 bounds/scroll | 기존 320px 상한과 내부 scroll 확인 | large-screen `HomeScreen` | 검색창에 `H`를 입력하고 검색한 뒤 panel 내부를 scroll한다. | panel이 Explorer graph/detail을 과도하게 덮지 않고 결과 목록 내부만 scroll된다. | panel이 320px 상한을 넘어 확장되거나 내부 scroll 불가 | panel 높이가 제한되고 내부 결과를 scroll할 수 있음 |
| 반복 open/close layout 안정성 | base Row 위치와 크기 유지 확인 | large-screen `HomeScreen` | 검색 submit, 외부 클릭, ESC, empty 입력을 반복한다. | Strong Rail과 Explorer graph/detail 위치와 크기가 흔들리지 않는다. | open/close 때 Rail 또는 Explorer가 이동하거나 크기 변경 | 반복 전후 base layout이 같은 위치와 크기로 보임 |
| 검색 후보 item tap retarget | 기존 명시적 retarget 경로 유지 확인 | `H2` 검색 결과 panel이 열린 large-screen 화면 | 식별 가능한 후보 item 본문을 클릭한다. | 해당 후보로 Explorer가 retarget되고 panel이 닫힌다. | submit만으로 retarget, item tap 무시, standalone route 이동 | item tap만 Explorer를 retarget함 |
| small-screen 회귀 확인 | 기존 homePane과 detail route 유지 확인 | 창 너비 900px 미만 small-screen `HomeScreen` | `H2`를 검색하고 식별 가능한 후보 item 본문을 클릭한다. | 기존 검색 결과 목록에서 `WordDetailScreen` detail route로 진입한다. | floating panel 또는 embedded Explorer 표시, detail route 미진입 | small-screen 기존 흐름이 유지됨 |

### 17.127 Phase 20-I Explorer standalone 역할 감사 active boundary

Phase 20-I는 standalone graph/detail route와 embedded workspace pane의 현재 역할을 실제 로컬 production source 기준으로 분리한 docs/audit-only 단계다. 상세 감사 기록은 `docs/ux/explorer_workspace_phase20i_standalone_role_audit.md`에 남긴다.

현재 production에서 `WordExplorerScreen` standalone route를 직접 생성하는 코드는 `HomeScreen._openDefaultStrongWordExplorer(...)` 하나지만, 이 helper는 호출자가 없는 dormant compatibility/guardrail 경로다. large-screen primary flow는 `HomeScreen` 내부 embedded `WordExplorerScreen`이며, Strong Rail item tap과 transient 검색 후보 본문 tap은 `_showWordInLargeScreenExplorerPane(...)`를 통해 해당 pane을 retarget한다.

large-screen에서는 shared default/search 목록을 mount하지 않으므로 목록 builder 안의 detail/graph 아이콘 route helper는 현재 large-screen 실제 진입점이 아니다. large-screen에서 실제로 열리는 standalone 경로는 embedded Explorer detail pane의 full-detail action이 여는 `WordDetailScreen`과, 해당 detail route의 graph action이 여는 `WordGraphScreen`이다.

small-screen은 계속 `return homePane` 흐름을 사용하며 default/search 목록 본문 tap의 `WordDetailScreen` route, 목록 graph 아이콘의 `WordGraphScreen` route, detail route의 graph action을 보존한다. small-screen에는 embedded Explorer가 없으므로 이 route 흐름은 즉시 제거하거나 large-screen workspace 전환과 함께 변경하지 않는다.

`WordExplorerScreen`은 standalone과 embedded 사용 모두에서 graph center, selected word, detail target, internal history의 production owner다. large-screen embedded retarget은 `ValueKey(_largeScreenExplorerWordId)` 변경으로 새 Explorer instance를 생성하므로 기존 selection과 internal history가 초기화되는 현재 동작을 가진다. dormant standalone helper 정리와 embedded owner/history continuity 변경은 같은 작업으로 취급하지 않는다.

Phase 20-J 우선 최소 구현 후보는 호출자가 없는 `_openDefaultStrongWordExplorer(...)` helper와 해당 source 문자열 존재만 고정하는 stale guard를 정리하는 단일 slice다. Phase 20-I에서는 helper, route, test guard를 변경하지 않는다. embedded Explorer full-detail route, `WordDetailScreen` 역할 이동, detail → graph redirect, standalone graph 내부 navigation, small-screen route, embedded retarget owner/history 변경은 판단 보류 또는 후속 별도 설계 대상으로 유지한다.

Phase 20-I는 production Dart 코드, route, test guard, DB/API/repository, DTO/model/public API, dependency, large-screen/small-screen behavior를 변경하지 않는다. 클라이언트 UI 테스트는 수행하지 않으며 현재 역할 분류 확인 절차만 상세 감사 문서에 기록한다.

### 17.128 Phase 20-J dormant standalone helper cleanup active boundary

Phase 20-J는 Phase 20-I 감사에서 확인한 호출자 없는 `HomeScreen._openDefaultStrongWordExplorer(...)` helper와 해당 helper의 source 문자열 존재만 고정하던 stale guard를 정리한 최소 구현 단계다. helper 본체, 전용 compatibility/guardrail 주석, `ignore: unused_element`를 제거했으며 production에서 호출 가능한 Explorer route를 제거하지 않았다.

large-screen primary flow는 계속 `HomeScreen` 내부 embedded `WordExplorerScreen`이다. Strong Rail과 transient 검색 후보 tap은 `_showWordInLargeScreenExplorerPane(...)`를 통해 `_largeScreenExplorerWordId`를 갱신하고, `ValueKey(_largeScreenExplorerWordId)` 변경으로 Explorer owner instance를 재생성한다.

small-screen default/search 목록 본문 tap의 `WordDetailScreen` route, 목록 graph 아이콘의 `WordGraphScreen` route, embedded Explorer full-detail route, detail → graph route, standalone `WordGraphScreen` 내부 navigation은 유지한다. `WordExplorerScreen`의 graph center, selected word, detail target, internal history owner 정책도 변경하지 않는다.

Phase 20-J에서는 route 통합, standalone 전체 제거, embedded retarget 구조 변경, owner/history continuity 변경, DB/API/repository, DTO/model/public API, dependency 변경을 수행하지 않는다. 상세 정리 기록은 `docs/ux/explorer_workspace_phase20j_dormant_standalone_helper_cleanup.md`에 남긴다.

### 17.129 Phase 20-K embedded full-detail 역할 감사 active boundary

Phase 20-K는 embedded Explorer detail pane의 `상세 화면에서 열기` action과 `WordDetailScreen` route의 현재 책임 차이를 실제 로컬 production source 기준으로 분해한 docs/audit-only 단계다. 상세 감사 기록은 `docs/ux/explorer_workspace_phase20k_embedded_full_detail_role_audit.md`에 남긴다.

embedded full-detail action은 dormant 경로가 아니라 large-screen embedded Explorer에서 실제 호출 가능한 active route다. `WordExplorerScreen._openSelectedWordDetail()`은 현재 선택 단어의 `wordId`와 split-view `WordDetailLikeDisplayItem`을 `WordDetailScreen`에 전달하고, delete 성공 `true` result를 분기하거나 일반 복귀 후 선택 단어를 다시 읽어 필요 시 center 표시와 graph를 갱신한다.

embedded detail pane은 split-view 표시, Explorer 전용 edit, full-detail 진입을 제공한다. `WordDetailScreen`은 initial display를 먼저 표시한 뒤 detail 전용 context로 reread하며, detail 전용 edit, delete, standalone graph 진입, delete 성공 route result 반환을 추가로 소유한다. 비중심 선택 삭제 후에는 Explorer가 center를 유지하고 selection을 해제하며, center 삭제 후에는 유효한 이전 history, 다음 history 순서로 복구하고 양쪽 모두 없으면 host에 delete result를 전달한다.

small-screen `HomeScreen` detail route와 large-screen embedded full-detail route는 같은 `WordDetailScreen`을 공유하지만 caller의 초기 read와 복귀 후 refresh 책임은 다르다. `WordDetailScreen`이 여는 callback 없는 standalone `WordGraphScreen`도 Explorer callback이 연결된 embedded graph와 다른 내부 navigation 책임을 유지한다.

full-detail action 제거 또는 route 통합 전에는 embedded pane의 delete/graph 대체 action, delete 결과 contract, center/selection/history 복구, edit와 graph refresh owner, small-screen detail route 보존, large-screen detail → graph 정책, standalone graph 내부 navigation을 먼저 설계하고 승인해야 한다.

Phase 20-K에서는 embedded full-detail route, `WordDetailScreen` 역할, delete/graph/detail route 흐름, Explorer refresh, `ValueKey(_largeScreenExplorerWordId)` retarget, history/selection/center 정책, production Dart 코드, test guard, DB/API/repository, DTO/model/public API를 변경하지 않는다. 전체 `flutter test`와 `flutter analyze`는 필수 완료 조건으로 삼지 않으며 기존 `tool/verify_graph_*` analyzer 오류는 범위 밖 기술부채로 구분한다.

### 17.130 Phase 20-L 반응형 ExplorerWorkspace 목표 구조 감사 active boundary

Phase 20-L은 ChatGPT가 제안한 Responsive ExplorerWorkspace 목표 구조 초안을 실제 로컬 production source와 기존 UX authority 문서 기준으로 교차검증한 docs/audit-only 단계다. 상세 감사 기록은 `docs/ux/explorer_workspace_phase20l_responsive_target_architecture_audit.md`에 남긴다.

Reshet의 장기 UX를 큰 화면의 병렬형 workspace와 작은 화면의 단계형 viewer/flow로 표현되는 하나의 responsive semantic workspace로 보는 방향은 `workspace_ux_architecture.md`와 `responsive_layout_policy.md`의 authority에 부합한다. 다만 production에서 실제 mount되는 것은 `ExplorerWorkspace` class가 아니라 `HomeScreen` large-screen branch 내부의 embedded `WordExplorerScreen`이다. `ExplorerWorkspace` class와 `ExplorerWorkspaceState`는 현재 preview-only composition/projection 경계이며 production canonical owner가 아니다.

현재 large-screen은 상단 검색, Strong Rail, embedded `WordExplorerScreen`의 graph/detail 병렬 구성을 제공한다. 현재 small-screen은 계속 `return homePane`과 `HomeScreen → WordDetailScreen → WordGraphScreen` route 흐름을 사용한다. 큰 화면과 작은 화면이 같은 semantic workspace 기능을 form factor에 맞게 표현해야 한다는 것은 목표 원칙이지만, 현재 구현에서는 embedded detail pane에 delete/graph action이 없고 small-screen에는 embedded Explorer와 Strong Rail이 없는 등 action과 surface 노출 차이가 있다.

`WordDetailScreen`은 현재 small-screen과 large-screen이 공유하는 active 안정 route다. detail 전용 reread/edit, delete, standalone graph 진입, delete 성공 route result 반환을 소유하므로 현재 과도기적 fallback으로 확정하지 않는다. 장기적으로 responsive workspace 내부 detail/action surface에 일부 책임을 흡수하는 후보는 검토할 수 있지만, 대체 UX와 state/result 계약을 먼저 설계하고 승인해야 한다.

responsive workspace 공통 상태 후보는 현재 단일 owner에 모여 있지 않다. search state와 large-screen target은 `HomeScreen`, center/selection/detail target/internal history는 주로 `WordExplorerScreen`, graph data와 viewport 및 graph local state는 `WordGraphScreen`과 cache, detail route 표시와 delete result는 `WordDetailScreen`, route history와 result 전달은 Navigator 및 caller별 계약에 분산되어 있다. refresh도 단일 상태가 아니라 Home/Explorer/Detail/Graph의 owner별 reread, graph reload, cache invalidation 동작이다.

detail 표시와 embedded edit 진입은 비교적 낮거나 낮음~중간 위험의 후속 후보이고, edit 후 refresh 계약과 graph action의 단순 진입 정책 변경은 중간 위험이다. standalone graph 내부 navigation과 create 후 replacement 흡수, delete 책임 이동, small-screen mobile ExplorerWorkspace는 높은 위험이며, `WordDetailScreen` 제거는 매우 높은 위험으로 분류한다.

Phase 20-L에서는 production `ExplorerWorkspace` mount, production Dart 코드, route, test guard, DB/API/repository, DTO/model/public API, dependency, embedded refresh, delete/graph/detail 흐름, center/selection/history 정책, `FEATURE_STATUS.md`를 변경하지 않는다. 전체 `flutter test`와 `flutter analyze`는 docs/audit-only 완료 조건으로 삼지 않는다.

### 17.131 Phase 20-M embedded detail action clarity active boundary

Phase 20-M은 large-screen embedded Explorer detail pane의 full-detail action 의미를 명확히 한 production UX copy/tooltip 최소 개선 단계다. 기존 `상세 화면에서 열기` 문구를 `상세 작업 화면 열기`로 변경하고, `삭제·그래프 보기 등 전체 작업용 상세 화면을 엽니다.` tooltip을 추가했다.

embedded full-detail action은 단순히 동일한 상세 정보를 다시 보는 중복 진입이 아니다. active `WordDetailScreen` route는 detail 전용 reread와 edit, delete, standalone graph 진입, delete 성공 route result 반환을 제공한다. embedded detail pane은 계속 split-view 표시와 Explorer 전용 edit 및 full-detail 진입만 제공하며, delete와 graph action을 직접 추가하지 않는다.

`WordExplorerScreen._openSelectedWordDetail()`의 `Navigator.push<bool?>` 및 `WordDetailScreen` route, delete result 분기, 일반 복귀 후 `_refreshSelectedWord(...)`, center/selection/history 복구 계약은 변경하지 않았다. `WordDetailScreen`의 edit/delete/graph action, large-screen과 small-screen의 detail/graph route 동작도 변경하지 않았다.

Phase 20-M에서는 `ExplorerWorkspace` class production 변경, owner state 이동, refresh/delete/graph/detail route behavior 변경, route result contract 변경, DB/API/repository, DTO/model/public API, dependency, large-scale responsive/mobile ExplorerWorkspace 구현을 수행하지 않는다. `WordInfoPanel` widget test와 source guard는 새 action 문구·tooltip 및 embedded/full-detail 경계를 고정한다.

### 17.132 Phase 20-N WordDetailScreen typed route result active boundary

Phase 20-N은 `WordDetailScreen` delete 성공 route result contract를 암묵적 `bool?` 신호에서 명시적 `WordDetailRouteResult` typed contract로 전환한 내부 refactor 단계다. `WordDetailDeletedResult`는 삭제된 `wordId`를 포함하며, 향후 caller별 refresh/result 정책을 명확히 구분하기 위한 기반이다.

`WordExplorerScreen._openSelectedWordDetail()`은 `WordDetailDeletedResult`를 받은 경우에만 기존 `_handleDeletedSelectedWord(...)` 경로를 수행한다. `null` 또는 delete result가 아닌 일반 복귀에서는 기존 `_refreshSelectedWord(...)` 경로를 유지한다. `HomeScreen` detail caller는 typed push를 사용하지만 result를 별도로 해석하지 않고 기존 `_refreshWords()` 동작을 유지한다.

`WordDetailScreen`의 delete 실행 위치와 확인 dialog의 bool 계약, edit/delete/graph action, standalone `WordGraphScreen` push, small-screen detail route는 변경하지 않는다. embedded detail pane에는 delete 또는 graph action을 추가하지 않으며, Explorer host의 별도 bool result와 center/selection/history 정책도 변경하지 않는다.

Phase 20-N에서는 DB/API/repository/DTO/domain model/dependency를 변경하지 않는다. Phase 20-M guardrail은 typed result 현행 계약에 맞춰 갱신하고, Phase 20-N guardrail은 typed delete result와 기존 delete/refresh/graph/small-screen 경계를 고정한다.

### 17.133 Phase 20-O large-screen full-detail graph request result active boundary

Phase 20-O는 Phase 20-N의 typed detail route result 기반 위에서 caller별 graph action 정책을 분리한 최소 route/caller contract 변경 단계다. `WordDetailGraphRequestedResult`는 graph 이동을 요청한 단어의 `wordId`를 포함한다.

large-screen embedded Explorer가 여는 full-detail `WordDetailScreen` route만 `returnToCaller` graph action mode를 사용한다. 이 route에서 `그래프 보기`를 실행하면 새 standalone graph route를 push하지 않고 `WordDetailGraphRequestedResult`를 caller에 반환한다. `WordExplorerScreen`은 해당 result를 받아 기존 `_selectWord(..., changeCenterWord: true)` 경로로 요청 단어를 embedded graph center와 selection에 반영하며, 기존 center 변경 history 정책을 그대로 사용한다.

`WordDetailScreen`의 기본 graph action mode는 `standaloneRoute`다. 따라서 small-screen과 일반 detail caller의 `그래프 보기`는 기존처럼 `WordGraphScreen(centerWordId: _wordId)`를 push한다. graph action은 mode 분기 전에 기존 단어 존재 확인을 수행하며, 단어를 찾을 수 없는 경우 기존 unavailable snackbar 정책을 유지한다.

Phase 20-O는 delete/edit route와 result, delete 처리, 일반/null 복귀 refresh, embedded pane action 노출, standalone graph 내부 navigation, graph create 후 replacement, DB/API/repository/DTO/domain model/dependency, `HomeScreen`, `WordGraphScreen` production source를 변경하지 않는다. `ExplorerWorkspace` class production 전환, small-screen mobile ExplorerWorkspace 구현, center/selection/history 정책 재설계도 수행하지 않는다.

### 17.134 Phase 20-P detail route responsibility audit active boundary

Phase 20-P는 Phase 20-N/O 이후 `WordDetailScreen`에 남은 책임과 large-screen embedded Explorer가 이미 흡수한 책임을 실제 production source 기준으로 교차검증한 docs/audit-only 단계다. 상세 근거와 후보 matrix는 `docs/ux/explorer_workspace_phase20p_detail_route_responsibility_audit.md`에 `reference/context` 기록으로 남긴다.

`WordDetailScreen`은 현재 detail 전용 reread, detail edit와 local refresh, delete 관계 수 확인·confirm·write·graph cache clear·typed result 반환, 기본 standalone graph route, local snackbar와 unavailable handling을 소유한다. Small-screen과 일반 detail caller가 이 active route에 의존하므로 현재 제거 또는 축소 구현 대상으로 보지 않는다.

Embedded Explorer는 direct edit, `WordDetailDeletedResult`와 `WordDetailGraphRequestedResult` 해석, embedded graph center retarget, delete 후 center/selection/history 복구를 이미 소유한다. Edit는 delete보다 작은 단위의 후속 감사 후보지만, detail/Explorer read context와 edit 후 refresh 계약을 Phase 20-Q에서 먼저 감사해야 한다. 이는 구현 승인이 아니며 Phase 20-P에서는 edit 책임을 이동하지 않는다.

Delete 이동은 DB write, relation count, confirm dialog, graph cache clear, typed route result, center/selection/history 복구, caller refresh, small-screen route 보존이 연결된 높은 위험 후보다. Phase 20-R은 delete 이동 전 precondition audit 후보일 뿐이며 Phase 20-P에서는 delete를 구현 대상으로 다루지 않는다.

Phase 20-P는 production Dart 코드, test, route, action 노출, edit/delete/graph 구현, DB/API/repository/domain/dependency, `pubspec.yaml`, `pubspec.lock`, center/selection/history 정책을 변경하지 않는다. UI 테스트, 전체 `flutter test`, 전체 `flutter analyze`는 docs/audit-only 완료 조건으로 삼지 않는다.

### 17.135 Phase 20-Q detail edit caller result active boundary

Phase 20-Q는 large-screen embedded Explorer가 연 full-detail route의 edit action 책임만 caller로 분기하는 최소 route/caller contract 변경 단계다. `WordDetailEditRequestedResult`는 edit를 요청한 단어의 `wordId`를 포함한다.

`WordDetailScreen`의 기본 edit action mode는 `localRoute`다. 따라서 small-screen과 `HomeScreen` 기본 detail route는 기존처럼 detail 전용 edit seed를 읽고 `WordEditScreen.fromSeed(...)`를 열며, 저장 성공 후 detail local reread와 local snackbar를 수행한다.

large-screen embedded Explorer가 여는 full-detail `WordDetailScreen` route만 `returnToCaller` edit action mode를 사용한다. 해당 route에서 `편집`을 실행하면 `WordDetailScreen`은 detail edit seed를 읽거나 edit route를 직접 열지 않고 `WordDetailEditRequestedResult`를 반환한다.

`WordExplorerScreen._openSelectedWordDetail()`은 edit result를 받으면 기존 `_openEditSelectedWord()`를 재사용하고 즉시 반환한다. 따라서 Explorer 전용 edit seed, selected detail refresh, center word와 동일한 경우 center display seed 동기화, 변경 시 graph revision 증가, history snapshot replace와 Explorer context snackbar 정책을 유지하며 일반/null 복귀용 `_refreshSelectedWord(...)`를 추가 실행하지 않는다.

Delete와 graph action 정책은 변경하지 않는다. `WordDetailDeletedResult`, `_confirmDelete()`, `WordDetailGraphRequestedResult`, embedded graph center retarget, 일반/null 복귀 refresh, embedded pane action 노출, `WordInfoPanel`, `WordEditScreen`, DB schema/API/repository/domain/dependency는 기존 계약을 유지한다.

Phase 20-Q UI 테스트는 기존 실데이터를 수정하거나 삭제하지 않는다. Codex가 백업 후 생성한 `PHASE20Q_EDIT_TARGET`, `PHASE20Q_DELETE_TARGET`, `PHASE20Q_GRAPH_TARGET` 테스트 전용 데이터만 사용하며, 클라이언트 UI 테스트 완료 후 테스트 데이터 정리 또는 백업 복구와 DB clean 확인을 마쳐야 커밋할 수 있다. 상세 구현·검증·UI 체크리스트는 `docs/ux/explorer_workspace_phase20q_detail_edit_caller_result.md`에 기록한다.

### 17.136 Phase 20-R delete 이동 전 선행 조건 감사 active boundary

Phase 20-R은 `WordDetailScreen`의 delete 실행 책임을 large-screen embedded Explorer로 이동할 수 있는지 실제 production source 기준으로 교차검증한 docs/audit-only 단계다. 상세 감사 기록은 `docs/ux/explorer_workspace_phase20r_delete_precondition_audit.md`에 `reference/context` 기록으로 남긴다.

현재 delete 실행 owner는 `WordDetailScreen`으로 유지한다. `_confirmDelete()`는 `countRelationsForWord(_wordId)` relation count 조회, confirm dialog, `_isDeleting` 진행 상태, `DeleteWordCommand(wordId: _wordId)`와 `WordWriteService.execute(...)`, `WordGraphDataCache.clear()`, route local 성공/실패 snackbar와 `WordDetailDeletedResult(wordId: _wordId)` 반환을 한 흐름으로 소유한다.

Embedded Explorer는 delete 실행 owner가 아니라 delete 후 복구 owner다. `WordExplorerScreen._openSelectedWordDetail()`은 `WordDetailDeletedResult`를 해석하고, non-center 선택 단어 삭제 시 center를 유지한 채 selection/detail을 비우며, center 단어 삭제 시 유효한 이전 history와 다음 history 순서로 복구한다. 유효한 history가 없으면 Explorer host에 `true`를 반환한다. 일반/null 복귀는 `_refreshSelectedWord(...)`, edit result는 `_openEditSelectedWord()`, graph result는 `_selectWord(..., changeCenterWord: true)` 경로를 유지한다.

`WordDetailDeletedResult`는 현행 유지한다. 다만 Explorer caller가 result의 `wordId`를 검증하지 않는 점과 center 삭제 후 유효한 history가 없을 때 typed result가 아닌 `true`를 host로 반환하는 계약은 delete 이동 전 후속 재검토 항목이다.

`HomeScreen._openDefaultStrongWordDetail(...)`과 small-screen은 기본 `WordDetailScreen` route를 계속 사용한다. Home caller는 typed delete result를 별도로 해석하지 않고 route 복귀 후 `_refreshWords()`를 수행한다. Small-screen에는 embedded Explorer delete 대체 경로가 없으므로 기본 detail route delete를 유지한다.

Phase 20-R에서는 embedded detail pane delete 버튼 추가, delete 실행 owner 이동, `_confirmDelete()`, `DeleteWordCommand`, `WordDetailDeletedResult`, delete/edit/graph action, full-detail route, small-screen/Home detail route, center/selection/history 정책, production Dart 코드, test, DB, repository/domain/database/dependency와 `pubspec.yaml`, `pubspec.lock`을 변경하지 않는다. Relation count, confirm, write/cache invalidation, feedback, center/non-center 복구 검증, Home/small-screen 보존, result contract와 테스트 데이터 백업·생성·복구 정책을 모두 확정하고 별도 구현 승인을 받은 이후에만 delete 이동을 검토한다.

### 17.137 Phase 20-S delete result wordId contract guardrail active boundary

Phase 20-S는 delete 실행 owner 이동 단계가 아니다. `WordExplorerScreen._openSelectedWordDetail()`의 `WordDetailDeletedResult` 처리 branch에 result contract guard만 추가한다. 상세 구현과 검증 기록은 `docs/ux/explorer_workspace_phase20s_delete_result_contract_guardrail.md`에 `migration/history` 및 `changelog/status` 기록으로 남긴다.

Explorer caller는 `detailResult.wordId.trim()`과 route를 열 당시 캡처한 `selectedWordId.trim()`를 비교한다. 두 값이 일치할 때만 기존 `_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)`를 실행한다. Mismatch이면 delete 복구를 실행하지 않고 route를 열 당시 선택 단어를 `_refreshSelectedWord(...)`로 안전하게 refresh한 뒤 즉시 반환한다.

Delete 실행 owner는 계속 `WordDetailScreen._confirmDelete()`다. `DeleteWordCommand` 호출 위치, `WordGraphDataCache.clear()` owner, embedded detail pane action, full-detail route, `HomeScreen`과 small-screen 기본 detail route는 변경하지 않는다. Center 삭제 후 유효한 history가 없을 때 Explorer host에 `Navigator.pop(context, true)`를 실행하는 계약도 제거하지 않고 후속 재검토 항목으로 유지한다.

Phase 20-O/Q 기존 source guard는 새 mismatch refresh가 아니라 분기 마지막의 일반/null 복귀 refresh를 계속 검사하도록 현행화한다. Phase 20-S에서는 실제 DB delete UI 테스트와 실데이터 수정·삭제를 수행하지 않는다. Repository/domain/database/dependency, `pubspec.yaml`, `pubspec.lock`도 변경하지 않는다.

### 17.138 Phase 20-T center delete 후 Explorer host `true` 반환 계약 감사 active boundary

Phase 20-T는 center 단어 삭제 후 Explorer 내부에서 복구할 유효한 previous/next history가 없을 때 실행되는 `Navigator.pop(context, true)`의 실제 host와 수신·해석 경로를 production source 기준으로 확인하는 docs/audit-only 단계다. 상세 감사 기록은 `docs/ux/explorer_workspace_phase20t_center_delete_host_true_contract_audit.md`에 `reference/context` 및 docs/audit 기록으로 남긴다.

현재 production에서 `WordExplorerScreen`을 생성하는 위치는 `HomeScreen` large-screen branch의 embedded child 한 곳이며, `Navigator.push`로 Explorer를 여는 production caller는 없다. `WordExplorerScreen`의 host callback은 passive Strong Rail feedback용 `onSelectedStrongWordChanged`뿐이고, `HomeScreen`에는 embedded Explorer의 bool `true` 결과를 수신하거나 refresh trigger로 해석하는 경로가 없다.

따라서 center delete history 부재 시의 `Navigator.pop(context, true)`는 유지 가능한 안정 계약으로 확정하지 않는다. 현재 embedded host 구조에서 수신·해석 경로가 없고 nearest/enclosing Navigator route를 pop할 가능성이 있는 legacy fallback 위험으로 분류한다. `WordDetailDeletedResult` typed result는 삭제된 `wordId`를 포함하고 Explorer caller가 해석하지만, 이 bool fallback은 삭제 context가 없고 현재 host가 해석하지 않는 별도 경계다.

Phase 20-T 1차 작업에서는 source guard를 추가하지 않는다. 위험한 legacy fallback 위치와 host 해석 부재를 감시할 guard는 후속 기대 계약이 승인된 뒤 재검토한다. `Navigator.pop(context, true)` 제거, typed result 통합, delete 실행 owner 이동, `WordDetailDeletedResult`, `_confirmDelete()`, `DeleteWordCommand`, `WordGraphDataCache.clear()`, production Dart, test, DB, dependency, `pubspec.yaml`, `pubspec.lock`은 변경하지 않는다. UI 기반 수동 테스트와 실제 DB delete 테스트도 수행하지 않는다.

### 17.139 Phase 20-U center delete bool fallback 최소 방어 active boundary

Phase 20-U는 Phase 20-T에서 확인한 embedded Explorer의 center delete bool fallback 위험을 최소 방어로 처리한다. Center 단어 삭제 후 유효한 previous/next history가 모두 없을 때 `Navigator.pop(context, true)`로 enclosing Navigator route를 닫지 않고, 기존 selection/detail 정리 경로인 `_clearSelectedWordPanel(refreshGraph: true)`를 실행한다.

`WordDetailDeletedResult`, route/result 계약, delete 실행 owner인 `WordDetailScreen._confirmDelete()`, `DeleteWordCommand` 호출 위치와 `WordGraphDataCache.clear()` owner는 변경하지 않는다. Production `WordExplorerScreen`은 계속 `HomeScreen` large-screen branch의 embedded child 한 곳에서만 생성한다.

삭제된 center/history를 별도 empty-state로 재설계하는 작업은 Phase 20-U 범위가 아니다. 필요성이 확인되면 후속 Phase로 분리한다. UI 기반 수동 테스트, 실제 DB delete 테스트와 실데이터 수정·삭제는 수행하지 않는다.

### 17.140 Phase 20-V detail delete caller-result 감사 active boundary

Phase 20-V는 Explorer가 여는 full-detail `WordDetailScreen` route의 delete action을 edit/graph처럼 caller-request result로 분기할 수 있는지 감사하고, production 최소 구현을 진행하지 않는 source guard/docs-only 단계다. 상세 감사와 검증 기록은 `docs/ux/explorer_workspace_phase20v_detail_delete_caller_result_audit.md`에 `reference/context`, `migration/history`, `changelog/status` 기록으로 남긴다.

Delete는 아직 caller-request mode로 분기하지 않는다. `WordDetailDeleteActionMode`, `deleteActionMode`, `WordDetailDeleteRequestedResult`는 도입하지 않는다. Delete 실행 owner는 계속 `WordDetailScreen._confirmDelete()`이며, relation count 조회, confirm dialog, 진행 상태, `DeleteWordCommand`, `WordGraphDataCache.clear()`, 성공·실패 feedback과 completed `WordDetailDeletedResult` 반환을 소유한다.

Explorer full-detail route는 edit와 graph action mode만 caller-result로 전달한다. Explorer는 completed `WordDetailDeletedResult`의 `wordId`를 검증하고 delete 후 center/non-center 복구를 수행하는 결과 해석자이며 delete executor가 아니다. Explorer에 `DeleteWordCommand` 실행 경로, `WordWriteService` 또는 `WordGraphDataCache.clear()` owner를 추가하지 않는다.

Phase 20-V에서는 production Dart 동작, Home/small-screen 기본 detail route, full-detail route, embedded detail pane action, Phase 20-U center empty-state/history, DB/repository/domain/dependency, `pubspec.yaml`, `pubspec.lock`을 변경하지 않는다. Delete owner 이동 또는 공통 delete executor 도입은 실행 surface, relation count와 confirm, 진행 상태, write/cache invalidation, feedback, completed result와 복구, Home/small-screen 보존, 테스트 데이터 정책을 설계하고 별도 승인받은 후속 Phase로 분리한다. UI 테스트, 실제 DB delete 테스트와 실데이터 수정·삭제는 수행하지 않는다.

### 17.141 Phase 20-W full-detail route 역할 감사 active boundary

Phase 20-W는 Phase 20-N/O/Q/V 이후 Explorer full-detail route의 잔여 역할과 action ownership을 감사한 docs-only 단계다. 상세 감사 기록은 `docs/ux/explorer_workspace_phase20w_full_detail_route_role_audit.md`에 `reference/context`, `migration/history`, `changelog/status` 기록으로 남긴다.

Explorer embedded detail pane은 split-view 안에서 선택 단어의 상세 요약과 제한된 action을 제공하는 lightweight detail/action surface다. Embedded detail pane은 `편집`과 `상세 작업 화면 열기`를 직접 제공하지만, `삭제`와 `그래프 보기`는 직접 제공하지 않는다.

Explorer full-detail route는 “상세 작업 화면”으로 유지한다. `WordExplorerScreen._openSelectedWordDetail()`은 `Navigator.push<WordDetailRouteResult>`로 `WordDetailScreen(...)`을 열고, 이 route는 `편집`, `그래프 보기`, `삭제` action을 제공한다.

Explorer route에서 edit와 graph는 caller-result 경로를 사용한다. Edit는 `WordDetailEditRequestedResult`를 통해 Explorer의 `_openEditSelectedWord()`로 연결되고, graph는 `WordDetailGraphRequestedResult`를 통해 `_selectWord(..., changeCenterWord: true)`로 연결된다. Home 기본 route는 계속 `WordDetailScreen`의 local edit와 standalone graph route를 유지한다.

Delete 실행 owner는 계속 `WordDetailScreen._confirmDelete()`다. Explorer는 completed `WordDetailDeletedResult`를 해석하고 center/non-center 복구를 수행하는 result 해석자이며 delete executor가 아니다. Explorer에 delete command 실행, common delete executor, `WordGraphDataCache.clear()` owner를 추가하지 않는다.

현재 버튼 문구 `상세 작업 화면 열기`와 tooltip `삭제·그래프 보기 등 전체 작업용 상세 화면을 엽니다.`는 full-detail route의 역할 설명으로 충분하므로 production UX 변경을 하지 않는다. 기존 Phase 20-M/O/Q/V guard가 embedded action 제한, edit/graph caller mode, delete owner 유지, Explorer delete executor 부재, Home 기본 detail route 유지를 이미 보호하므로 Phase 20-W source guard 추가도 불필요하다.

Delete owner 이동, full-detail route 제거, embedded delete 버튼 추가, common delete executor 설계, center delete empty-state/history 정리, production UX 문구 변경과 실제 DB delete 테스트는 Phase 20-W 범위가 아니며 후속 Phase로 분리한다. Phase 20-W에서는 production Dart, test, DB/repository/domain/dependency, `pubspec.yaml`, `pubspec.lock`을 변경하지 않으며 UI 테스트, DB/SQL 검증, 실데이터 수정·삭제를 수행하지 않는다.
