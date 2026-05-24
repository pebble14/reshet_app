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
