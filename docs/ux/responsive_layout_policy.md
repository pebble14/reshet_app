# Responsive Layout Policy

## 1. 목적

이 문서는 Reshet의 responsive layout authority를 정의한다.

이 문서의 핵심 질문은 다음과 같다.

```text
semantic workspace를 desktop, tablet, mobile form factor에서
어떻게 유지하거나 변형할 것인가?
```

이 문서는 breakpoint 목록이 아니다. 이 문서는 `workspace_ux_architecture.md` 아래에서 form factor별 workspace 유지와 변형 기준을 정의하는 authority다.

`workspace_ux_architecture.md`는 Reshet가 왜 persistent semantic workspace를 지향하는지 정의한다. 이 문서는 그 철학을 반복하지 않고, 각 form factor에서 어떤 surface를 persistent하게 유지하고 어떤 surface를 transient하게 전환해야 하는지 정의한다.

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- desktop, tablet, mobile form factor별 layout philosophy
- persistent surface와 transient surface의 구분 원칙
- form factor별 MainWorkspace 해석
- form factor별 GraphPane, DetailPane, ExplorePane presentation 원칙
- form factor별 Strong Rail 역할
- form factor별 Search 접근성 원칙
- responsive layout과 navigation continuity의 관계
- workspace fragmentation 방지 원칙
- mobile viewer/flow UX 원칙
- responsive authority boundary

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- exact breakpoint value
- Flutter widget tree
- controller hierarchy
- rendering optimization
- pixel-level visual design
- animation 또는 gesture timing
- graph traversal rule
- graph layout algorithm
- edge 또는 relation semantics
- search ranking, scoring, result grouping
- repository API
- database schema
- normalization rule

이 문서는 layout이 semantic workspace를 어떻게 보존해야 하는지 정의한다. layout이 정확히 어떤 코드 구조로 구현되어야 하는지는 정의하지 않는다.

## 3. Workspace UX Architecture와의 관계

`workspace_ux_architecture.md`는 parent UX authority다. 이 문서는 그 하위에서 form factor adaptation 기준을 정의한다.

이 문서는 Reshet가 persistent semantic workspace라는 점을 다시 증명하지 않는다. 대신 각 form factor가 그 workspace를 어떤 방식으로 유지하거나 변형해야 하는지 판단 기준을 제공한다.

Responsive layout은 workspace 철학의 적용 방식이다. Form factor가 달라져도 다음 기준은 유지되어야 한다.

- 사용자는 현재 semantic context를 잃지 않아야 한다.
- graph, detail, exploration은 독립된 앱 화면처럼 분리되지 않아야 한다.
- surface가 줄어들어도 workspace의 의미 관계는 끊기지 않아야 한다.
- 접근 가능한 surface 수보다 semantic continuity가 우선되어야 한다.

## 4. Form Factor Adaptation 철학

Responsive layout은 desktop layout을 모든 화면에 축소 적용하는 작업이 아니다.

Form factor adaptation은 사용 가능한 공간, 입력 방식, 화면 전환 비용에 따라 workspace surface의 노출 방식을 조정하는 것이다.

각 form factor는 다음 질문에 답해야 한다.

- 어떤 semantic surface를 동시에 노출할 수 있는가?
- 어떤 surface는 필요할 때 transient하게 열려야 하는가?
- 사용자가 현재 semantic context를 어떻게 확인할 수 있는가?
- navigation continuity가 layout 전환 중에도 어떻게 유지되는가?
- workspace fragmentation을 줄이기 위해 어떤 surface가 우선되어야 하는가?

Desktop, tablet, mobile은 같은 workspace 철학을 공유하지만 같은 layout을 공유하지 않는다.

## 5. Desktop 원칙

Desktop은 persistent workspace UX를 가장 강하게 지원할 수 있는 form factor다.

Desktop layout은 가능한 경우 여러 semantic surface를 동시에 노출해야 한다.

- GraphPane은 contextual workspace surface로 유지될 수 있다.
- DetailPane은 현재 focus에 대한 reading surface로 유지될 수 있다.
- ExplorePane은 exploration continuity를 보조하는 surface로 유지될 수 있다.
- Strong Rail은 navigation spine candidate로 persistent하게 유지될 수 있다.
- Search는 semantic entry surface candidate로 빠르게 접근 가능해야 한다.

Desktop에서 중요한 기준은 surface의 동시 노출 자체가 아니라, 동시 노출된 surface들이 하나의 MainWorkspace로 읽히는 것이다.

Desktop layout은 graph를 application shell로 만들지 않아야 한다. GraphPane이 넓은 공간을 차지할 수는 있지만, workspace 전체의 navigation authority나 shell responsibility를 가져서는 안 된다.

## 6. Tablet 원칙

Tablet은 persistent workspace UX와 transient flow UX가 섞이는 form factor다.

Tablet layout은 desktop과 mobile 사이의 단순 중간값이 아니다. Tablet은 사용 방향, 사용 거리, 입력 방식에 따라 surface persistence를 선택적으로 유지해야 한다.

Tablet에서 권장되는 기준은 다음과 같다.

- 핵심 semantic context는 persistent하게 확인 가능해야 한다.
- 모든 pane을 동시에 고정 노출하려고 해서는 안 된다.
- GraphPane, DetailPane, ExplorePane은 필요에 따라 paired surface 또는 transient surface로 전환될 수 있다.
- Strong Rail은 가능한 경우 navigation spine candidate로 유지하되, workspace surface를 과도하게 침범하지 않아야 한다.
- Search는 화면 구성이 변해도 semantic entry surface candidate 역할을 잃지 않아야 한다.

Tablet adaptation의 목적은 desktop layout을 압축하는 것이 아니라, workspace coherence를 유지하면서 surface 부담을 줄이는 것이다.

## 7. Mobile Viewer/Flow UX 원칙

Mobile은 desktop workspace의 축소판이 아니다.

Mobile은 viewer/flow UX로 정의되어야 한다. Mobile에서는 제한된 화면 안에 모든 pane을 동시에 넣는 것보다, 사용자가 현재 focus를 확인하고 다음 semantic surface로 자연스럽게 이동할 수 있어야 한다.

Mobile에서 중요한 기준은 다음과 같다.

- 한 번에 하나의 primary semantic surface를 명확하게 제공한다.
- surface 전환은 현재 semantic context를 잃지 않도록 구성한다.
- GraphPane, DetailPane, ExplorePane은 동시에 고정 노출되는 pane보다 flow 안의 semantic surface로 해석될 수 있다.
- Strong Rail은 desktop과 같은 폭의 persistent rail일 필요는 없지만, navigation spine candidate의 역할을 잃어서는 안 된다.
- Search는 mobile에서도 semantic entry surface candidate로 접근 가능해야 한다.
- 사용자는 현재 어디에 있고 무엇을 보고 있으며 어디로 돌아갈 수 있는지 이해할 수 있어야 한다.

Mobile layout은 workspace를 단순히 축소하지 않는다. Mobile layout은 workspace를 flow로 변형한다.

## 8. Persistent Surface와 Transient Surface

Responsive layout은 모든 surface를 항상 보이게 만드는 정책이 아니다.

Persistent surface는 사용자의 orientation과 semantic continuity를 유지하는 데 필요한 surface다. Transient surface는 특정 form factor에서 필요할 때 열리고 닫히는 surface다.

Form factor별 판단 기준은 다음과 같다.

- Desktop에서는 여러 surface가 persistent하게 유지될 수 있다.
- Tablet에서는 핵심 orientation surface는 persistent하게 유지하고 보조 surface는 transient하게 전환할 수 있다.
- Mobile에서는 primary semantic surface 중심의 flow를 우선하고, 보조 surface는 필요할 때 접근 가능하게 둘 수 있다.

Surface가 transient하더라도 semantic context가 transient해져서는 안 된다. 화면에서 사라진 surface도 workspace의 의미 관계 안에서는 끊기지 않아야 한다.

## 9. MainWorkspace와 Pane의 Form Factor별 해석

MainWorkspace는 특정 화면 배치가 아니라 semantic workspace structure다.

Form factor가 바뀌어도 다음 관계는 유지되어야 한다.

```text
MainWorkspace
├─ GraphPane
├─ DetailPane
└─ ExplorePane
```

이 구조는 구현 layout을 고정하지 않는다. 이 구조는 각 pane이 어떤 responsibility를 가지는지 정의한다.

### GraphPane

GraphPane은 form factor와 관계없이 contextual workspace surface다.

Desktop에서는 GraphPane이 넓고 persistent한 surface가 될 수 있다. Tablet에서는 다른 surface와 paired 또는 transient하게 표현될 수 있다. Mobile에서는 graph가 flow 안의 하나의 semantic surface가 될 수 있다.

GraphPane은 어떤 form factor에서도 application shell이 아니다.

### DetailPane

DetailPane은 selected semantic object의 의미를 읽는 surface다.

Desktop에서는 persistent reading surface로 유지될 수 있다. Tablet에서는 focus 유지와 함께 전환 가능한 surface가 될 수 있다. Mobile에서는 viewer/flow UX의 primary surface가 될 수 있다.

DetailPane은 navigation spine이나 graph replacement가 아니다.

### ExplorePane

ExplorePane은 exploration continuity를 보조하는 surface다.

Desktop에서는 GraphPane, DetailPane과 함께 workspace를 구성할 수 있다. Tablet과 mobile에서는 보조 surface 또는 flow step으로 표현될 수 있다.

ExplorePane은 모든 form factor에서 독립 앱 화면으로 분리되어서는 안 된다.

## 10. Strong Rail의 Form Factor별 역할

Strong Rail은 semantic navigation spine candidate다.

Responsive layout policy는 Strong Rail의 exact interaction을 정의하지 않는다. 이 문서는 form factor별로 Strong Rail이 workspace layout 안에서 어떤 역할 후보를 유지해야 하는지만 정의한다. 여기서 candidate라는 표현은 canonical authority를 뜻하지 않는다.

Desktop에서는 Strong Rail이 persistent navigation spine candidate로 유지될 수 있다.

Tablet에서는 Strong Rail이 persistent하거나 compact한 navigation spine candidate로 표현될 수 있다. 어떤 표현이든 Strong Rail은 detail renderer, control panel, explorer replacement가 되어서는 안 된다.

Mobile에서는 Strong Rail이 desktop과 같은 시각적 형태를 유지하지 않을 수 있다. 그러나 navigation spine candidate로서의 orientation 역할은 유지되어야 한다. Mobile에서 rail의 형태가 바뀌더라도 사용자는 현재 semantic position과 주요 semantic entry에 접근할 수 있어야 한다.

## 11. Search의 Form Factor별 역할

Search는 semantic entry surface candidate다.

Responsive layout policy는 search ranking, scoring, result grouping을 정의하지 않는다. 이 문서는 Search가 form factor 변화 속에서도 semantic workspace로 진입하는 entry/orientation surface candidate 역할을 유지해야 한다는 점만 정의한다. 이 표현은 canonical selection owner나 production entry authority를 뜻하지 않는다.

Desktop에서는 Search가 persistent access 또는 즉시 접근 가능한 entry로 유지될 수 있다.

Tablet에서는 Search가 workspace surface를 과도하게 차지하지 않으면서도 entry surface candidate 역할을 유지해야 한다.

Mobile에서는 Search가 flow 안에서 사라지는 보조 기능이 되어서는 안 된다. Search는 graph, detail, exploration 어느 surface에서도 semantic context로 진입할 수 있는 접근 경로로 유지되어야 한다.

## 12. Navigation Continuity와 Responsive Layout

Navigation continuity의 의미는 `navigation_policy.md`가 정의한다. 이 문서는 그 continuity가 form factor별 layout 변화 속에서 끊기지 않도록 하는 layout-level 원칙만 정의한다.

Responsive layout은 다음을 보장해야 한다.

- layout 전환이 semantic context를 불필요하게 끊지 않는다.
- surface가 숨겨지거나 transient해져도 current focus의 의미가 유지된다.
- mobile flow에서도 사용자는 현재 semantic position을 이해할 수 있다.
- tablet adaptation은 surface 압축 때문에 workspace fragmentation을 만들지 않는다.
- desktop persistence는 graph 중심 shell로 오해되지 않아야 한다.

이 문서는 direct jump algorithm, scroll behavior, keyboard interaction, selection restoration rule을 정의하지 않는다.

## 13. Workspace Fragmentation 방지 원칙

Workspace fragmentation은 graph, detail, exploration, search가 서로 다른 앱 화면처럼 경험되는 상태다.

Responsive layout은 form factor 제약 때문에 surface를 나누더라도 workspace fragmentation을 줄여야 한다.

다음은 방지해야 할 상태다.

- mobile에서 graph, detail, exploration이 서로 관계없는 화면처럼 분리되는 상태
- tablet에서 surface 전환이 semantic context를 잃게 만드는 상태
- desktop에서 GraphPane이 전체 application shell처럼 작동하는 상태
- Search가 특정 surface에 종속되어 semantic entry surface candidate 역할을 잃는 상태
- Strong Rail이 navigation spine을 넘어 heavy interaction panel로 확장되는 상태

Responsive layout은 한 화면에 많은 것을 보여주는 것보다 semantic coherence를 유지하는 것을 우선해야 한다.

## 14. Responsive Boundary Rules

다음 규칙은 이 policy의 boundary를 정의한다.

1. Responsive layout policy는 breakpoint specification이 아니다.
2. Responsive layout policy는 Flutter widget tree specification이 아니다.
3. Responsive layout policy는 rendering optimization guide가 아니다.
4. Responsive layout policy는 animation 또는 gesture timing specification이 아니다.
5. Responsive layout policy는 graph traversal authority가 아니다.
6. Responsive layout policy는 graph layout algorithm authority가 아니다.
7. Responsive layout policy는 search ranking authority가 아니다.
8. Responsive layout policy는 repository 또는 database boundary 문서가 아니다.
9. Responsive layout policy는 visual design system authority가 아니다.
10. Current implementation snapshot은 responsive authority를 override하지 않는다.

## 15. 다른 문서와의 관계

### Workspace UX Architecture

`workspace_ux_architecture.md`는 parent UX authority다. 이 문서는 그 철학을 form factor별 layout decision 기준으로 적용한다.

### Navigation Policy

`navigation_policy.md`는 semantic navigation continuity를 정의한다. 이 문서는 navigation continuity가 layout 변화 속에서 끊기지 않도록 하는 form factor-level 기준만 정의한다.

### Search Authority 문서

Search authority 문서는 query behavior, ranking, result grouping, scoring, search-specific interaction contract를 정의해야 한다.

이 문서는 Search가 form factor별로 semantic entry surface candidate 역할을 유지해야 한다는 responsive 기준만 정의한다.

### Graph Authority 문서

Graph authority 문서는 graph traversal, relation interpretation, expansion rule, graph layout algorithm, graph-specific behavior를 정의해야 한다.

이 문서는 GraphPane이 form factor별로 어떤 workspace surface로 표현될 수 있는지만 정의한다.

### Repository and Data Boundary 문서

Repository and data boundary 문서는 API, schema, normalization, read boundary를 정의해야 한다.

이 문서는 semantic surface가 data authority와 어떻게 연결되는지 정의하지 않는다.

### Migration and Historical 문서

Migration and historical 문서는 transition context와 implementation history를 제공할 수 있다. 그러나 responsive layout authority를 override하지 않는다.

## 16. 비목표

이 문서는 다음을 정의하지 않는다.

- exact breakpoint value
- device width table
- Flutter widget tree
- controller hierarchy
- state management implementation
- rendering optimization
- animation curve
- gesture timing
- graph traversal rule
- graph expansion rule
- relation direction behavior
- graph layout algorithm
- search ranking
- search scoring
- result grouping
- repository API
- DTO
- database schema
- normalization rule
- visual design token
- typography
- color system

이 결정들은 별도 authority 문서 또는 implementation-level specification에서 다루어야 한다.

## 17. 요약

Responsive layout policy는 Reshet의 semantic workspace를 form factor별로 유지하거나 변형하는 기준이다.

Desktop은 persistent workspace UX를 가장 강하게 지원한다. Tablet은 persistent surface와 transient surface를 조합한다. Mobile은 desktop workspace의 축소판이 아니라 viewer/flow UX로 workspace를 변형한다.

MainWorkspace, GraphPane, DetailPane, ExplorePane, Strong Rail, Search는 form factor에 따라 표현 방식이 달라질 수 있다. 그러나 semantic context, semantic continuity, semantic coherence는 유지되어야 한다.

이 문서는 responsive change가 workspace fragmentation을 줄이는지, navigation continuity를 보존하는지, mobile을 desktop 축소판으로 만들지 않는지 판단하는 authority로 사용해야 한다.
