# Workspace UX Architecture

## 1. 목적

이 문서는 Reshet의 workspace 방향에 대한 UX architecture authority를 정의한다.

Reshet는 graph viewer로만 정의되지 않는다. Reshet는 단어, 관계, 의미 맥락을 지속적으로 탐색하기 위한 persistent semantic workspace이다.

이 문서는 사용자 경험이 왜 workspace, persistent navigation, semantic continuity, 조율된 pane 구조를 중심으로 구성되어야 하는지 설명한다. 이 문서는 낮은 수준의 구현 세부사항을 정의하지 않는다.

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- UX 철학
- workspace 개념
- pane 관계
- persistent semantic workspace 방향
- workspace 안에서의 graph 역할
- navigation continuity 개념
- persistent UX 방향
- responsive 철학 방향
- UX authority boundary

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- graph traversal semantics
- edge direction algorithm
- graph expansion rule
- search ranking 또는 scoring
- debounce behavior
- repository interaction detail
- database schema
- Flutter widget structure
- exact responsive breakpoint value
- rendering optimization
- visual styling system
- typography 또는 color system
- exact navigation behavior specification

세부 구현 규칙은 각 영역의 별도 문서 또는 code-level contract에서 정의해야 한다.

## 3. 핵심 철학

Reshet UX의 핵심 목표는 사용자가 관련 단어 사이를 이동하는 동안 의미적 방향을 잃지 않도록 돕는 것이다.

사용자는 graph, detail view, search result, exploration state를 서로 분리된 화면으로 경험하지 않아야 한다. 이 surface들은 하나의 persistent workspace 안에서 조율된 view로 느껴져야 한다.

Reshet UX는 다음을 우선한다.

- 분리된 page transition보다 semantic continuity
- 일회성 이동보다 persistent access
- 정적인 조회보다 contextual exploration
- 임시 workflow 편의보다 workspace 안정성

Graph exploration은 여전히 중요하다. 그러나 graph는 application shell이 아니다. graph는 여러 workspace surface 중 하나의 contextual workspace surface이다.

## 4. Persistent Semantic Workspace

Persistent semantic workspace는 사용자가 탐색을 계속하는 동안 현재 의미 맥락을 유지할 수 있게 하는 workspace이다.

Workspace는 다음 항목을 가로질러 사용자의 방향성을 보존해야 한다.

- 선택된 단어
- 중심 또는 현재 초점 단어
- 관련 단어
- detail context
- exploration history
- search entry point
- 생성 또는 수정 흐름

Persistence는 모든 panel이 모든 기기에서 항상 시각적으로 노출되어야 한다는 뜻이 아니다. 이는 사용자가 관련 작업 사이를 이동할 때 semantic context의 불필요한 손실을 피해야 한다는 뜻이다.

Workspace model은 사용자의 의미적 연속 질문을 지원하기 위해 존재한다. 사용자는 “나는 의미 네트워크의 어디에 있는가, 무엇을 보고 있는가, 다음에 무엇을 할 수 있는가”를 이해할 수 있어야 한다.

## 5. MainWorkspace 개념

목표 workspace 개념은 다음과 같다.

```text
MainWorkspace
 ├─ GraphPane
 ├─ DetailPane
 └─ ExplorePane
```

이들은 하나의 semantic workspace 안에 있는 개념적 pane 또는 view이다. 이들은 서로 분리된 application identity가 아니다.

### GraphPane

GraphPane은 관계 맥락을 표현한다. GraphPane의 역할은 현재 단어가 다른 단어와 어떻게 연결되는지 사용자가 이해하도록 돕는 것이다.

GraphPane은 contextual하게 유지되어야 한다. GraphPane은 전체 application의 유일한 organizing shell이 되어서는 안 된다.

### DetailPane

DetailPane은 선택된 단어의 읽을 수 있는 의미 정보를 표현한다.

DetailPane은 사용자의 현재 초점을 명확하게 해야 하지만 navigation authority를 가져가서는 안 된다.

### ExplorePane

ExplorePane은 더 넓은 exploration continuity를 지원한다. 여기에는 history, 인접 맥락, semantic movement, workspace-level coordination이 포함된다.

ExplorePane은 단순한 graph replacement가 아니다. ExplorePane은 사용자의 ongoing exploration state를 나타낸다.

### Pane 조율

Pane들은 platform과 layout 필요에 따라 시각적으로 결합되거나 분리될 수 있다. 그러나 각 pane의 책임은 구분되어야 한다.

Workspace는 semantic context의 정합성 유지를 지원해야 한다. Focus, selection, exploration context의 변화는 pane의 책임을 하나의 과부하된 view로 합치지 않으면서 pane 간 semantic coherence를 보존해야 한다.

## 6. Graph 역할

Graph는 contextual semantic surface이다.

Graph의 역할은 현재 context 주변의 관계 구조를 드러내는 것이다. Graph는 사용자가 연결을 보고, 관계 의미를 확인하고, 의미 네트워크를 따라 이동할 수 있도록 돕는다.

Graph는 다음이 아니다.

- application shell
- global navigation system
- 유일한 workspace authority
- detail reading의 대체물
- search의 대체물
- persistent semantic navigation의 대체물

Graph traversal semantics, relation direction interpretation, expansion limit, edge rendering, layout algorithm 같은 graph-specific rule은 graph authority 문서가 담당한다. 이 UX architecture 문서는 이를 정의하지 않는다.

## 7. Persistent Navigation 개념

Persistent navigation은 사용자가 탐색하는 동안 semantic access를 유지하기 위해 존재한다.

Strong Rail은 semantic navigation spine candidate다. Strong Rail은 graph 영역이 global navigation 책임을 떠안지 않도록 하면서 Strong 기반 semantic anchor에 대한 persistent access와 workspace orientation을 제공할 수 있는 candidate surface다. 이는 canonical navigation owner를 뜻하지 않는다.

Strong Rail은 다음을 지원해야 한다.

- platform이 허용하는 범위의 persistent visibility
- 안정적인 semantic access
- 알려진 anchor로 빠르게 돌아갈 수 있는 가능성
- search, graph, detail, exploration context 사이의 continuity
- graph workspace에 대한 최소 침범

Strong Rail은 다음이 아니다.

- detail renderer
- explorer replacement
- heavy interaction panel
- temporary debug surface
- graph layout control surface

Exact navigation behavior, jump mechanic, scrolling behavior, selection restoration, keyboard interaction은 navigation policy 문서에서 정의해야 한다.

## 8. Search 철학

Search는 semantic workspace로 들어가는 semantic entry surface candidate다.

Search는 사용자가 detail content를 읽고 있거나, graph를 확인하고 있거나, exploration path를 이어가는 중이더라도 개념적으로 전역 접근 가능해야 한다.

Search는 사용자가 현재 semantic context를 불필요하게 버리지 않고 corpus에 지속적으로 접근할 수 있게 해야 한다. 이 표현은 canonical selection owner나 production entry authority를 뜻하지 않는다.

이 문서는 ranking, scoring, normalization, debounce, result rendering algorithm을 정의하지 않는다. 해당 사항은 search-specific implementation 또는 policy 문서가 담당한다.

## 9. Persistent Action 개념

생성 및 수정 action은 exploration continuity의 일부이다.

Add action은 UX architecture에서 부차적이거나 숨겨진 action이 아니다. Add action은 다음과 같은 자연스러운 흐름을 지원한다.

```text
explore
-> discover a missing word or relation
-> add or correct it
-> continue exploring
```

Workspace는 이 흐름을 개념적으로 가능하게 해야 한다. 단, 전체 workspace를 editing surface로 바꾸어서는 안 된다.

Exact creation dialog, validation behavior, repository write, rollback behavior는 implementation 또는 data boundary 문서가 담당한다.

## 10. Responsive 철학

Responsive UX는 platform 제약을 존중하면서 workspace 철학을 보존해야 한다.

### Desktop과 Tablet

Desktop과 tablet 경험은 persistent workspace UX를 우선해야 한다.

이 form factor들은 persistent semantic navigation, graph context, detail reading 같은 여러 workspace surface를 동시에 지원할 수 있다.

### Mobile

Mobile은 viewer 또는 flow UX를 사용해야 한다.

Mobile은 desktop workspace의 축소판이 아니다. Mobile은 모든 desktop pane을 작은 layout 안에 강제로 넣는 대신, flow, state, return path를 통해 semantic continuity를 보존해야 한다.

Exact breakpoint, platform layout decision, Flutter implementation detail은 responsive layout policy 문서가 담당한다.

## 11. UX Boundary Rules

다음 규칙은 UX 책임 경계를 정의한다.

1. Graph는 application shell이 아니다.
2. Strong Rail은 detail renderer가 아니다.
3. Strong Rail은 explorer replacement가 아니다.
4. Search는 graph surface에 종속되지 않는다.
5. Detail reading은 navigation spine이 아니다.
6. Temporary workflow UI를 architecture authority로 승격하지 않는다.
7. Migration, debug, verification UI를 permanent UX policy로 삼지 않는다.
8. Implementation convenience는 UX authority를 정의하지 않는다.
9. Pane이 시각적 공간을 공유할 수는 있지만, 책임 경계는 명확해야 한다.
10. Current implementation snapshot은 target UX architecture를 override하지 않는다.

## 12. 다른 문서와의 관계

이 문서는 UX architecture 방향만 정의한다. 관련 문서는 각자의 세부 authority를 가져야 한다.

### Graph Authority 문서

Graph authority 문서는 graph semantics, relation traversal, direction interpretation, expansion policy, edge behavior, graph-specific rendering rule을 정의한다.

Graph layout coordinate와 viewport/camera 책임 경계는 `graph_layout_viewport_contract.md`가 정의한다.

이 문서는 workspace 안에서 graph의 UX 역할을 정의할 뿐, graph engine behavior를 정의하지 않는다.

### Responsive Policy 문서

향후 responsive layout policy 문서는 platform별 layout rule, breakpoint strategy, pane presentation rule을 정의해야 한다.

이 문서는 responsive 철학만 정의한다. Desktop과 tablet은 persistent workspace UX를 우선하고, mobile은 viewer 또는 flow UX를 사용한다.

### Navigation Policy 문서

향후 navigation policy 문서는 Strong Rail behavior, selection rule, jump behavior, keyboard access, navigation continuity detail을 정의해야 한다.

이 문서는 persistent semantic navigation이 왜 존재하고 workspace 안에서 어떤 역할을 갖는지만 정의한다.

### Migration and Historical 문서

Migration and historical 문서는 evidence, transition context, implementation history를 제공한다. 이 문서의 UX architecture authority를 override하지 않는다.

### Repository and Data Boundary 문서

Repository, read boundary, normalization, database 문서는 data authority와 interaction boundary를 정의한다.

이 문서는 UI surface가 안정적인 semantic contract를 소비한다고 전제할 수는 있다. 그러나 repository API, read policy, normalization rule, schema detail은 정의하지 않는다.

## 13. 비목표

이 문서는 다음을 정의하지 않는다.

- exact screen layout
- Flutter widget tree
- database structure
- search scoring
- graph traversal rule
- relation direction algorithm
- graph layout algorithm
- responsive breakpoint
- visual design token
- typography
- exact color system
- performance optimization

이 결정들은 별도 authority 문서 또는 implementation-level specification에서 다루어야 한다.

## 14. 런타임 테마와 그래프 surface 계약

애플리케이션의 기본 테마 모드는 시스템 설정 사용이며 운영체제의 light/dark 테마를 따른다. 사용자가 라이트 또는 다크를 선택하면 운영체제 설정보다 사용자 선택을 우선하며, 시스템 설정 사용을 다시 선택하면 운영체제 테마 추종으로 돌아간다. 이 선택은 앱을 재실행한 뒤에도 유지한다. 그래프 canvas도 현재 테마의 surface를 사용하되, node·edge chip·방향 상태 badge 같은 그래프 콘텐츠 객체는 어두운 canvas에서도 밝은 객체 성격과 의미 계층을 유지한다. 그래프 dialog는 그래프 객체가 아니라 일반 애플리케이션 UI로서 현재 테마를 따른다.

## 15. 요약

Reshet의 UX 방향은 persistent semantic workspace이다.

Workspace는 graph, detail, exploration, search, navigation, creation flow를 조율하되, 어떤 단일 surface도 전체 application의 책임을 독점하지 않게 한다.

Graph는 의미 이해에 여전히 중요하지만 shell-level이 아니라 contextual하다. Persistent navigation과 search는 access와 orientation을 보존한다. Responsive UX는 하나의 desktop layout을 모든 form factor에 축소 적용하지 않고, 각 form factor에 맞게 workspace 철학을 적용한다.

이 문서는 future UX change가 Reshet의 persistent semantic workspace 방향을 강화하는지 약화하는지 판단할 때 UX architecture authority로 사용해야 한다.
