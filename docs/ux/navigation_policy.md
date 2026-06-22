# Navigation Policy

## 1. 목적

이 문서는 Reshet의 semantic navigation behavior authority를 정의한다.

이 문서는 `workspace_ux_architecture.md` 아래에 위치하며, 사용자가 단어, search entry, pane, exploration surface 사이를 이동하는 동안 semantic context를 보존하기 위한 navigation 원칙을 정의한다.

이 문서는 전체 workspace 철학을 다시 정의하지 않는다. 이 문서는 그 철학 안에서 navigation이 continuity를 어떻게 보존해야 하는지 정의한다.

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- semantic navigation continuity
- current focus와 current context 개념
- selection persistence 철학
- semantic context 정합성 유지 원칙
- Strong Rail navigation 철학
- navigation 안에서의 global search entry 역할
- navigation 중 pane coherence
- navigation event의 UX-level 의미

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- search ranking, scoring, weighting, debounce timing
- hover timing, scroll timing, animation curve, gesture timing
- graph traversal rule, expansion algorithm, edge semantics, relation interpretation
- exact responsive breakpoint, mobile layout tree, rendering layout detail
- Flutter widget hierarchy, controller structure, state management implementation
- repository API, DTO, schema, normalization rule

세부 behavior specification과 implementation contract는 각자의 authority 문서에서 정의해야 한다.

## 3. Workspace UX Architecture와의 관계

`workspace_ux_architecture.md`는 Reshet의 persistent semantic workspace에 대한 parent UX authority이다.

이 문서는 그 하위 authority이다. 이 문서는 workspace architecture 결정, pane 책임 경계, graph의 contextual workspace 역할을 대체하지 않는다.

Navigation policy는 사용자가 workspace 안을 이동하는 동안 workspace가 semantically coherent하게 유지되도록 하는 continuity rule을 정의한다.

## 4. Semantic Navigation 철학

Navigation은 semantic continuity를 보존하기 위해 존재한다.

사용자가 단어, result, pane, exploration state 사이를 이동할 때 workspace는 사용자가 다음을 이해할 수 있을 만큼의 context를 보존해야 한다.

- 어떤 semantic object가 focus에 있는가
- 어떤 context가 현재 맥락으로 이어졌는가
- 현재 맥락이 인접한 navigation surface와 어떻게 관련되는가
- 방향을 잃지 않고 exploration을 어떻게 이어갈 수 있는가

Navigation은 graph surface에 종속되지 않는다. Graph, detail, search, exploration surface는 모두 navigation에 참여할 수 있지만, 그중 어떤 하나도 전체 navigation model을 단독으로 정의하지 않는다.

Navigation은 workspace fragmentation을 줄여야 한다. 각 surface 전환이 분리된 재시작처럼 느껴지게 해서는 안 된다.

## 5. Core Navigation 개념

### Current Focus

Current focus는 workspace가 사용자의 즉시 의미 관심 대상으로 취급하는 semantic object이다.

Current focus는 UX 개념이다. Storage, state management, widget ownership을 정의하지 않는다.

### Current Semantic Context

Current semantic context는 current focus를 둘러싼 더 넓은 의미 환경이다.

여기에는 search entry context, graph context, exploration history, selected object, pane-specific reading context가 포함될 수 있다. 이 문서의 관심은 continuity이지 data structure가 아니다.

### Selected Semantic Object

Selected semantic object는 사용자가 현재 context 안에서 확인하거나 다루는 대상이다.

Selection은 orientation을 지원해야 한다. Selection 때문에 workspace가 하나의 pane 또는 하나의 surface로 축소되어서는 안 된다.

### Context Persistence

Context persistence는 semantic entry point 사이를 이동할 때 navigation이 orientation의 불필요한 손실을 피해야 한다는 뜻이다.

Persistence는 모든 navigation surface가 항상 시각적으로 노출되어야 한다는 뜻이 아니다. Persistence는 navigation model이 이동 과정에서 의미적으로 coherent한 맥락을 보존해야 한다는 뜻이다.

## 6. Strong Rail 역할

Strong Rail은 persistent semantic navigation spine이다.

Strong Rail의 navigation 역할은 Strong 기반 semantic anchor에 대한 안정적인 접근을 제공하고 workspace 안에서 orientation을 지원하는 것이다.

Strong Rail은 다음을 표현할 수 있다.

- navigation level에서의 current semantic position
- semantic jump를 위한 entry point
- search, graph, detail, exploration context 사이의 continuity
- graph가 global navigation 책임을 떠안지 않도록 하면서 알려진 semantic anchor에 접근하는 경로

Strong Rail은 다음이 아니다.

- detail renderer
- control panel
- explorer replacement
- graph configuration surface
- search ranking surface
- temporary migration 또는 debug surface

Strong Rail은 navigation-oriented하게 유지되어야 한다. Strong Rail이 persistently visible하다는 이유만으로 관련 없는 workspace responsibility를 축적해서는 안 된다.

## 7. Global Search Entry 역할

Search는 navigation과 독립적인 global entry point이다.

Search result는 semantic context로 들어가는 entry를 제공한다. Search result는 graph, detail, exploration surface의 대체물이 아니라 semantic focus에 진입하거나 semantic focus를 이동하는 방법으로 이해되어야 한다.

Search는 다음으로의 이동을 시작할 수 있다.

- detail reading
- graph context
- exploration context
- 다른 semantic workspace state

이 문서는 ranking, scoring, fuzzy matching, result grouping, debounce behavior, result rendering algorithm을 정의하지 않는다.

### Mobile Focused Search Navigation 계약

Mobile Graph 또는 Detail에서 연 focused search는 검색 결과 target을 직접 push하지 않는다. Search route는 `wordId`와 destination(`detail` 또는 `graph`) 의미를 가진 typed selection만 origin route에 반환하고 즉시 stack에서 제거된다.

Navigation 순서는 다음과 같다.

1. origin Graph 또는 Detail이 focused search를 child route로 push한다.
2. Search route는 결과 선택 시 typed selection을 반환하며 pop한다.
3. origin route가 selection을 해석해 기존 Detail 또는 Graph target route를 child로 push한다.
4. target에서 back 하면 Search 목록이 아니라 origin Graph 또는 Detail로 복귀한다.

일반 읽기·탐색 흐름에서 이 구조는 origin Graph의 camera, zoom/LOD, selection, relation·expansion state와 origin Detail의 route·scroll 위치를 보존해야 한다. Search 진입·dismiss·selection은 origin의 graph reload, center 교체, selection clear를 일으키지 않는다.

Mobile Search target과 그 child route에서 성공한 write는 해당 탐색 체인에 한정된 typed mutation impact로 누적해 origin에 반영할 수 있다. mutation이 없는 일반 탐색과 back은 origin reload를 일으키지 않는다.

origin은 현재 Detail의 단어 또는 Graph의 active node·edge 범위와 mutation 영향 범위가 겹칠 때만 최소 반영한다. Graph 반영은 최신 데이터 정합성과 기존 camera, zoom/LOD, 유효한 selection, relation·expansion/reveal 상태, seed node position 보존을 함께 만족해야 한다. 삭제되어 더 이상 유효하지 않은 route나 selection은 보존 대상이 아니다.

이 계약은 Mobile Search 탐색 체인의 route-local 전달 경계이며, 독립적인 global cross-route mutation protocol을 새로 정의하지 않는다.

## 8. Focus와 Context Continuity

Navigation은 focus, selected object, 더 넓은 semantic context 사이의 관계를 보존해야 한다.

Focus가 바뀌더라도 workspace는 사용자에게 설명 가능한 상태로 남아야 한다. 사용자는 무엇이 바뀌었고, 무엇이 의미 있게 유지되며, 어떻게 이어갈 수 있는지 이해할 수 있어야 한다.

Selection persistence는 UX continuity 원칙이다. Selection persistence는 의미가 유지되는 곳에서 selection이 semantic orientation을 지원해야 한다는 뜻이다. 모든 navigation path에서 이전 selection을 항상 복원해야 한다는 뜻은 아니다.

Context continuity는 우발적인 UI state를 보존하는 것보다 중요하다.

## 9. Navigation 중 Pane Coherence

Workspace pane들은 서로 다른 책임을 가진 독립 surface이다. 그러나 navigation은 이들이 semantically coherent하게 유지되도록 해야 한다.

Graph, detail, exploration pane은 같은 semantic context의 서로 다른 측면을 나타낼 수 있다. Navigation은 pane 사이에 모순되거나 단절된 맥락이 생기는 것을 줄여야 한다.

Pane coherence는 모든 pane이 같은 action을 하거나 같은 object를 표시해야 한다는 뜻이 아니다. Pane coherence는 각 pane의 맥락이 하나의 workspace context 일부로 이해될 수 있어야 한다는 뜻이다.

Semantic continuity는 pane ownership convenience보다 중요하다.

Implementation synchronization detail은 이 문서의 범위 밖이다.

## 10. Navigation Boundary Rules

다음 규칙은 이 policy의 boundary를 정의한다.

1. Navigation policy는 interaction timing specification이 아니다.
2. Navigation policy는 animation specification이 아니다.
3. Navigation policy는 graph traversal authority가 아니다.
4. Navigation policy는 graph expansion authority가 아니다.
5. Navigation policy는 relation interpretation authority가 아니다.
6. Navigation policy는 search ranking authority가 아니다.
7. Navigation policy는 responsive layout authority가 아니다.
8. Navigation policy는 Flutter state management authority가 아니다.
9. Navigation policy는 repository 또는 database boundary 문서가 아니다.
10. Current implementation snapshot은 semantic navigation authority를 override하지 않는다.

## 11. 다른 문서와의 관계

### Workspace UX Architecture

`workspace_ux_architecture.md`는 Reshet이 왜 persistent semantic workspace를 사용하는지 정의한다.

이 문서는 그 workspace 안에서 navigation이 semantic continuity를 어떻게 보존해야 하는지 정의한다.

### Responsive Policy 문서

Responsive policy 문서는 navigation surface가 desktop, tablet, mobile form factor에서 어떻게 표현되는지 정의해야 한다.

이 문서는 navigation continuity expectation을 정의할 뿐, layout implementation이나 breakpoint rule을 정의하지 않는다.

### Search Authority 문서

Search authority 문서는 query behavior, ranking, result grouping, scoring, search-specific interaction contract를 정의해야 한다.

이 문서는 search를 navigation을 위한 global semantic entry point로만 정의한다.

### Graph Authority 문서

Graph authority 문서는 graph traversal, expansion, direction interpretation, edge semantics, graph-specific behavior를 정의해야 한다.

이 문서는 graph surface가 navigation continuity에 어떻게 참여하는지만 정의하며, graph semantics를 정의하지 않는다.

### Repository and Data Boundary 문서

Repository and data boundary 문서는 API, contract, normalization, schema authority를 정의해야 한다.

이 문서는 UX 수준에서 semantic context를 언급할 수는 있지만, data structure 또는 repository behavior를 정의하지 않는다.

### Migration and Historical 문서

Migration and historical 문서는 navigation behavior가 어떻게 변화해 왔는지 설명할 수 있다.

이 문서들은 evidence와 transition context를 제공하지만, 이 navigation policy를 override하지 않는다.

## 12. 비목표

이 문서는 다음을 정의하지 않는다.

- exact rail interaction
- exact jump algorithm
- scroll behavior
- hover behavior
- animation curve
- keyboard shortcut map
- search ranking 또는 scoring
- graph traversal 또는 expansion rule
- relation direction behavior
- responsive breakpoint value
- mobile layout tree
- Flutter widget structure
- controller hierarchy
- repository API
- DTO
- database schema

이 결정들은 별도 authority 문서 또는 implementation-level specification에서 다루어야 한다.

## 13. 요약

Reshet navigation은 사용자가 workspace 안을 이동하는 동안 semantic continuity를 보존해야 한다.

Strong Rail은 persistent semantic navigation을 제공한다. Search는 global semantic entry를 제공한다. Graph, detail, exploration pane은 하나의 surface로 합쳐지지 않으면서 조율되어야 한다.

이 policy는 navigation change가 Reshet workspace 안의 semantic context continuity를 강화하는지 약화하는지 판단할 때 사용해야 한다.
