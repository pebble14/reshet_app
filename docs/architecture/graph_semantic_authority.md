# Graph Semantic Authority

## 1. 목적

이 문서는 Reshet의 graph-specific semantic authority를 정의한다.

Graph는 application shell이 아니다. Graph는 Reshet workspace 안에서 관계 의미를 드러내는 contextual semantic surface이다.

이 문서는 graph가 어떤 의미 구조를 표현하고, relation direction과 traversal이 어떤 semantic meaning을 가지며, expansion이 어떤 철학을 따라야 하는지 정의한다.

이 문서는 graph를 어떻게 렌더링할지, 어떤 layout algorithm을 사용할지, 어떤 interaction timing을 적용할지 정의하지 않는다.

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- graph semantic surface 역할
- core graph concept
- Center Word와 Connected Words의 의미
- Ego Network의 semantic role
- relation semantics
- relation direction semantics
- graph traversal semantics
- graph expansion philosophy
- multi-edge semantics
- graph exploration continuity
- graph boundary rules

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- application shell responsibility
- global navigation continuity
- responsive layout adaptation
- Flutter widget 또는 layout
- rendering optimization
- exact layout algorithm
- animation timing
- gesture 또는 click timing
- dialog 또는 control behavior
- search ranking 또는 result grouping
- repository API
- database schema
- normalization rule
- exact count value
- visual styling token

Graph authority는 graph-specific semantic rule을 정의한다. Graph authority는 graph engine implementation specification이 아니다.

## 3. Workspace UX Authority와의 관계

`workspace_ux_architecture.md`는 Reshet의 parent UX authority이다.

이 문서는 그 하위의 sibling authority이다. 이 문서는 navigation authority나 responsive authority의 하위 문서가 아니다.

권장 hierarchy는 다음과 같다.

```text
workspace authority
    ├─ navigation authority
    ├─ responsive authority
    └─ graph authority
```

Workspace authority는 graph가 왜 application shell이 아니며 contextual semantic surface인지 정의한다. 이 문서는 그 전제 위에서 graph 내부의 relation, traversal, expansion, multi-edge semantics를 정의한다.

Graph authority는 workspace authority를 대체하지 않는다. Graph authority는 graph surface가 workspace 안에서 어떤 semantic rule을 가져야 하는지 정의한다.

## 4. Graph Semantic Surface 철학

Graph는 현재 semantic context 주변의 관계 구조를 드러내는 surface이다.

Graph는 사용자가 다음을 이해하도록 돕는다.

- 현재 Center Word가 어떤 semantic relation 안에 있는가
- 연결된 단어들이 어떤 의미적 맥락을 만드는가
- relation direction이 의미 흐름을 어떻게 드러내는가
- graph traversal이 어떤 semantic movement를 만드는가
- expansion이 어떤 의미 범위를 열거나 제한하는가

Graph는 다음이 아니다.

- application shell
- global navigation system
- detail renderer
- search replacement
- repository boundary
- responsive layout authority
- visual design authority

Graph는 semantic surface이다. Graph의 가치는 시각적 복잡도나 표시량이 아니라 relation meaning을 잃지 않고 드러내는 데 있다.

## 5. Core Graph Concepts

Graph authority는 다음 vocabulary를 기본 개념으로 사용한다.

- Center Word
- Connected Words
- Word Relation
- Node
- Edge
- Relation Direction
- Graph Expansion
- Multi-Edge

이 vocabulary는 `GRAPH_ENGINE_RULES.md`의 v1 vocabulary를 제한적으로 계승한다. 다만 이 문서는 v1의 layout, rendering, state management, split view 계획을 계승하지 않는다.

이 vocabulary는 graph-specific semantic reasoning을 위한 개념이다. 이 문서는 각 개념의 storage structure나 widget ownership을 정의하지 않는다.

## 6. Center Word와 Ego Network

Center Word는 graph semantic context의 anchor이다.

Ego Network는 Center Word를 기준으로 relation context를 해석하는 graph structure이다. Ego Network의 목적은 모든 corpus relation을 한 번에 드러내는 것이 아니라, 현재 semantic focus 주변의 관계 의미를 이해 가능하게 만드는 것이다.

Connected Words는 Center Word와 relation을 가지는 semantic neighbor이다. Connected Words는 단순한 주변 표시 대상이 아니라 Center Word의 의미 형성에 참여하는 relation participant이다.

Ego Network는 graph가 workspace 전체를 대체한다는 뜻이 아니다. Ego Network는 graph surface 안에서 현재 focus 주변 relation을 해석하기 위한 semantic frame이다.

## 7. Relation Semantics

Word Relation은 두 단어 사이에 존재하는 의미 관계이다.

Relation은 graph에서 단순한 연결선이 아니다. Relation은 단어가 서로 어떤 의미적 영향을 주고받는지, 어떤 맥락에서 함께 이해되어야 하는지를 드러내는 semantic unit이다.

Graph authority는 relation을 다음 기준으로 해석한다.

- relation은 의미 형성의 단서이다.
- relation은 traversal의 근거가 될 수 있다.
- relation은 expansion의 포함 또는 제한 기준이 될 수 있다.
- relation은 하나의 visual edge로 축소되어 의미를 잃어서는 안 된다.

이 문서는 relation storage, relation query, relation editing flow를 정의하지 않는다.

## 8. Relation Direction Semantics

Relation Direction은 relation의 의미 흐름을 해석하기 위한 semantic concept이다.

Center Word 기준에서 direction은 다음과 같이 해석될 수 있다.

- incoming은 Center Word의 의미 형성에 영향을 주는 relation을 나타낸다.
- outgoing은 Center Word가 다른 단어의 의미 형성에 영향을 주는 relation을 나타낸다.
- undirected는 방향 의미가 명시되지 않은 relation을 나타낸다.
- unknown은 direction 의미가 아직 안정적으로 확인되지 않은 relation을 나타낸다.

Relation direction은 relation meaning이다. Relation direction은 display policy가 아니다.

Graph authority는 relation direction의 semantic meaning을 정의한다. 이 문서는 direction을 어떤 symbol, label, color, shape로 표현해야 하는지 정의하지 않는다.

## 9. Graph Traversal Semantics

Graph traversal은 graph surface 안에서 relation을 따라 semantic context를 이동하는 것이다.

Traversal은 단순한 screen transition이 아니다. Traversal은 사용자가 한 semantic object에서 다른 semantic object로 이동하면서 relation meaning을 이어가는 semantic movement이다.

Graph traversal은 다음을 보존해야 한다.

- 이동의 기준이 된 Center Word
- 이동을 가능하게 한 relation
- 이동 전후 semantic context의 연결성
- exploration continuity

Graph traversal은 global navigation authority가 아니다. Graph traversal은 graph surface 안에서 발생하는 semantic movement이며, workspace-level navigation continuity는 `navigation_policy.md`가 정의한다.

이 문서는 exact interaction trigger, click behavior, gesture timing, scroll behavior를 정의하지 않는다.

## 10. Graph Expansion Philosophy

Graph expansion은 현재 Center Word 주변의 semantic context를 어느 범위까지 열 것인지 결정하는 graph-specific philosophy이다.

Expansion은 더 많은 relation을 보여주는 작업만이 아니다. Expansion은 semantic context를 확장하면서도 사용자가 relation meaning을 이해할 수 있도록 범위를 조절하는 작업이다.

Graph expansion은 다음 원칙을 따라야 한다.

- incoming, outgoing, undirected, unknown relation은 각각 semantic meaning을 가진다.
- expansion은 relation direction 의미를 무시하지 않아야 한다.
- expansion은 허브 relation이 semantic context를 압도하지 않도록 제한될 수 있다.
- expansion 제한은 의미 손실을 최소화해야 한다.
- expansion mode는 relation meaning을 선택적으로 보존하거나 제한하는 semantic policy로 이해되어야 한다.

`GRAPH_ENGINE_RULES_v2.md`의 `graph_expand_mode` 개념은 expansion philosophy의 source로 계승한다. 다만 이 문서는 exact option value, exact count limit, configuration key contract를 정의하지 않는다.

## 11. Multi-Edge Semantics

Multi-Edge는 같은 Center Word와 같은 Connected Word 사이에 여러 Word Relation이 존재할 수 있다는 의미를 보존하기 위한 concept이다.

같은 pair의 relation이 여러 건 존재할 때, graph authority는 다음 원칙을 따른다.

- 여러 relation은 단일 relation으로 덮어써져서는 안 된다.
- 여러 relation은 의미적으로 구분 가능한 relation set으로 보존되어야 한다.
- graph surface는 relation plurality가 존재한다는 사실을 잃지 않아야 한다.
- representative edge가 필요하더라도 underlying relation meaning은 손실되어서는 안 된다.

이 문서는 multi-edge를 어떻게 표시하거나 어떤 UI로 확인해야 하는지 정의하지 않는다.

## 12. Graph Exploration Continuity

Graph exploration continuity는 사용자가 graph surface 안에서 relation meaning을 따라가면서 semantic orientation을 잃지 않는 것이다.

Graph exploration은 다음 continuity를 지원해야 한다.

- Center Word 중심의 현재 relation context
- traversal이 만든 semantic path
- expansion이 열어 둔 relation scope
- multi-edge가 나타내는 relation plurality
- workspace 안의 detail, search, exploration surface와의 의미적 연결성

Graph exploration continuity는 global navigation continuity와 다르다. Graph exploration continuity는 graph surface 내부의 semantic continuity이며, workspace-level navigation continuity는 `navigation_policy.md`가 정의한다.

## 13. Graph Boundary Rules

다음 규칙은 graph authority의 boundary를 정의한다.

1. Graph authority는 application shell authority가 아니다.
2. Graph authority는 global navigation authority가 아니다.
3. Graph authority는 responsive layout authority가 아니다.
4. Graph authority는 search ranking authority가 아니다.
5. Graph authority는 repository 또는 database authority가 아니다.
6. Graph authority는 Flutter widget authority가 아니다.
7. Graph authority는 rendering optimization guide가 아니다.
8. Graph authority는 animation timing specification이 아니다.
9. Graph authority는 exact gesture 또는 click behavior specification이 아니다.
10. Graph authority는 exact layout algorithm specification이 아니다.
11. Graph authority는 exact count value policy가 아니다.
12. Current implementation snapshot은 graph semantic authority를 override하지 않는다.

## 14. 다른 Authority와의 관계

### Workspace UX Authority

`workspace_ux_architecture.md`는 graph가 contextual semantic surface이며 application shell이 아니라는 parent UX 기준을 정의한다.

이 문서는 그 기준 아래에서 graph-specific semantics를 정의한다.

### Navigation Authority

`navigation_policy.md`는 workspace-level semantic navigation continuity를 정의한다.

이 문서는 graph traversal의 semantic meaning을 정의할 수 있다. 그러나 global navigation model, rail behavior, exact jump behavior, selection restoration은 정의하지 않는다.

### Responsive Authority

`responsive_layout_policy.md`는 GraphPane이 desktop, tablet, mobile form factor에서 어떤 surface로 표현될 수 있는지 정의한다.

이 문서는 responsive adaptation, breakpoint, mobile layout tree, pane presentation rule을 정의하지 않는다.

### Search Authority

Search authority 문서는 search query behavior, ranking, result grouping, scoring, search-specific interaction contract를 정의해야 한다.

이 문서는 search result가 graph에 어떻게 진입하는지 또는 search result를 어떻게 정렬하는지 정의하지 않는다.

### Repository and Data Boundary

Repository and data boundary 문서는 API, schema, normalization, read boundary를 정의해야 한다.

이 문서는 graph가 안정적인 relation data를 소비한다고 전제할 수는 있다. 그러나 repository API, database schema, normalization rule은 정의하지 않는다.

### Legacy Graph Documents

`GRAPH_ENGINE_RULES.md`는 vocabulary와 historical v1 source로 참고할 수 있다.

`GRAPH_ENGINE_RULES_v2.md`는 relation direction, expansion, multi-edge semantics의 primary semantic source로 참고할 수 있다.

이 문서는 두 legacy 문서의 rendering, layout, exact count value, current implementation detail을 active authority로 승격하지 않는다.

## 15. 비목표

이 문서는 다음을 정의하지 않는다.

- graph rendering pipeline
- rendering optimization
- exact layout algorithm
- node position calculation
- visual edge style
- visual direction marker
- animation timing
- gesture timing
- click behavior
- dialog behavior
- Flutter widget structure
- controller hierarchy
- state management implementation
- responsive layout adaptation
- breakpoint rule
- search ranking
- search result grouping
- repository API
- DTO
- database schema
- normalization rule
- exact expansion count
- exact configuration key contract

이 결정들은 별도 authority 문서 또는 implementation-level specification에서 다루어야 한다.

## 16. 요약

Graph Semantic Authority는 graph-specific semantics를 정의한다.

Graph는 application shell이 아니라 contextual semantic surface이다. Graph는 Center Word 주변의 relation meaning을 드러내고, relation direction을 해석하며, traversal과 expansion을 통해 semantic exploration을 지원한다.

이 문서는 graph를 어떻게 그릴지 정의하지 않는다. 이 문서는 graph가 무엇을 의미해야 하는지, relation과 traversal과 expansion이 어떤 semantic rule을 따라야 하는지 정의한다.

Future graph change는 relation meaning, traversal semantics, expansion philosophy, multi-edge semantics, graph exploration continuity를 강화하는지 약화하는지 기준으로 판단해야 한다.
