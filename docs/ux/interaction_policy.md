# Interaction Policy

## 1. 목적

이 문서는 Reshet의 interaction을 semantic activation / focus / selection / transient continuity policy로 정의한다.

Interaction은 gesture handler, widget event, controller implementation이 아니다. Interaction은 사용자가 semantic workspace 안에서 어떤 대상을 활성화하고, 무엇에 초점을 두며, 어떤 semantic object를 선택하고, transient surface를 통해 현재 context를 어떻게 유지하는지에 관한 UX-level 원칙이다.

이 문서는 interaction이 semantic context를 시작하거나 전환하거나 보존하는 방식을 정의한다.

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- semantic activation의 UX-level 의미
- focus transition의 semantic meaning
- selection state semantics
- active semantic context indication
- transient surface continuity
- modal / dialog continuity의 UX-level 원칙
- keyboard interaction의 철학적 의미
- hover / focus / selection affordance의 의미 수준

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- pointer event handling
- gesture implementation
- exact hover timing
- animation duration
- Flutter widget 또는 controller structure
- focus node implementation
- exact shortcut key binding
- dialog widget structure
- button behavior flow
- rendering 또는 layout structure
- graph traversal 또는 expansion logic
- repository 또는 data mutation
- debounce 또는 timer implementation

## 3. Workspace UX Authority와의 관계

`workspace_ux_architecture.md`는 Reshet이 persistent semantic workspace를 지향한다는 parent UX authority다.

이 문서는 그 전제 아래에서 사용자의 activation, focus, selection, transient surface interaction이 semantic workspace의 continuity를 어떻게 보존해야 하는지 정의한다.

Interaction은 workspace를 조작하는 implementation event가 아니라, workspace 안에서 사용자의 semantic intent가 표현되는 UX-level behavior다.

이 문서는 workspace 철학 전체를 다시 정의하지 않는다. 이 문서는 interaction이 semantic context를 훼손하지 않고 사용자의 attention과 action을 어떻게 지원해야 하는지만 정의한다.

## 4. Semantic Activation 철학

Activation은 semantic context를 시작하거나 전환하는 UX-level 행위다.

Activation은 다음을 의미할 수 있다.

- semantic object를 현재 attention의 대상으로 삼는 것
- detail, graph, search, exploration surface 중 하나로 진입하는 것
- transient surface에서 제한된 작업을 시작하는 것
- 현재 context를 유지한 채 다음 semantic action을 준비하는 것

Activation은 단순한 click event가 아니다. Activation은 사용자가 어떤 semantic object 또는 semantic context를 의도적으로 다루기 시작했다는 의미를 가져야 한다.

Activation은 사용자를 방향 없는 UI state로 밀어 넣어서는 안 된다. Activation 이후 사용자는 자신이 어떤 semantic context 안에 있는지 이해할 수 있어야 한다.

## 5. Focus / Selection Semantics

Focus는 현재 workspace에서 사용자의 attention이 향하는 semantic target이다.

Selection은 현재 workspace에서 사용자가 다루거나 확인하는 semantic object를 나타낸다.

Focus와 selection은 다음 기준을 따라야 한다.

- Focus는 사용자가 현재 무엇을 보고 있는지 이해하도록 도와야 한다.
- Selection은 현재 어떤 semantic object가 작업 또는 탐색의 대상인지 드러내야 한다.
- Focus transition은 semantic context를 불필요하게 끊지 않아야 한다.
- Selection state는 pane ownership보다 semantic coherence를 우선해야 한다.
- Focus와 selection은 graph, detail, search, exploration surface 사이에서 서로 충돌하지 않아야 한다.

Focus와 selection은 implementation state object가 아니다. 이 문서는 focus node, controller, widget state, selected index implementation을 정의하지 않는다.

## 6. Active Context Indication

Active context indication은 사용자가 현재 semantic workspace 안에서 어디에 있고 무엇을 다루고 있는지 이해하게 하는 UX-level 기준이다.

Active context indication은 다음을 지원해야 한다.

- current semantic focus의 인식
- selected semantic object의 인식
- transient surface가 열려 있을 때 원래 context와의 관계 인식
- action 이후 돌아갈 수 있는 semantic context의 인식
- 여러 surface가 동시에 있거나 전환될 때 context 혼선 감소

Active context indication은 visual styling system이 아니다. 이 문서는 color, typography, icon style, highlight rendering, animation style을 정의하지 않는다.

## 7. Transient Surface Interaction

Transient surface는 사용자가 제한된 작업, 확인, 선택, 생성, 수정, 보조 탐색을 수행하기 위해 일시적으로 만나는 surface다.

Transient surface interaction의 원칙은 다음과 같다.

- Transient surface는 현재 semantic context를 단절하지 않아야 한다.
- Transient surface는 사용자가 어디에서 왔고 어디로 돌아가는지 이해할 수 있게 해야 한다.
- Transient surface는 temporary workflow convenience를 permanent UX authority로 승격하지 않아야 한다.
- Transient surface 안의 action은 원래 workspace context와 의미적으로 연결되어야 한다.
- Transient surface는 graph, detail, search, exploration의 본래 authority를 대체하지 않아야 한다.

이 문서는 transient surface의 exact layout, route structure, overlay implementation, animation timing, dismissal gesture를 정의하지 않는다.

## 8. Modal / Dialog Continuity

Modal 또는 dialog는 현재 context를 단절하지 않고 제한된 작업을 지원해야 한다.

Modal / dialog continuity의 원칙은 다음과 같다.

- Modal은 현재 semantic context 위에서 제한된 decision 또는 action을 지원해야 한다.
- Modal은 workspace 전체를 새로운 독립 화면처럼 대체해서는 안 된다.
- Modal 안의 선택 또는 확인은 원래 semantic object와의 관계를 잃지 않아야 한다.
- Modal 취소 또는 완료 이후 사용자는 이전 semantic context를 이해할 수 있어야 한다.
- Modal은 migration, debug, verification convenience를 permanent UX rule로 만들지 않아야 한다.

이 문서는 dialog widget tree, button order, confirmation flow, validation detail, route implementation, focus trap implementation을 정의하지 않는다.

## 9. Keyboard Interaction Philosophy

Keyboard interaction은 semantic access와 efficient workspace movement를 보조할 수 있다.

Keyboard interaction의 UX-level 원칙은 다음과 같다.

- Keyboard interaction은 known semantic entry로 빠르게 접근하는 것을 도울 수 있다.
- Keyboard interaction은 focus와 selection의 semantic meaning을 흐리게 해서는 안 된다.
- Keyboard interaction은 pointer interaction의 숨겨진 대체 경로가 아니라 semantic access를 보조하는 경로여야 한다.
- Keyboard interaction은 workspace orientation을 깨뜨리지 않아야 한다.

이 문서는 exact shortcut key binding, key event handling, focus node traversal, platform-specific keyboard mapping을 정의하지 않는다.

## 10. Interaction과 Navigation Continuity Boundary

Interaction은 activation, focus, selection, transient surface의 semantic meaning을 정의한다.

Navigation continuity는 `navigation_policy.md`가 정의한다.

Interaction policy의 관심은 다음과 같다.

- 사용자가 무엇을 활성화했는가
- 현재 attention이 어디에 있는가
- 어떤 semantic object가 선택되었는가
- transient surface가 현재 context와 어떻게 연결되는가
- activation 이후 사용자가 context를 잃지 않는가

Navigation policy의 관심은 다음과 같다.

- semantic context 사이를 어떻게 이동하는가
- entry 이후 current focus가 어떻게 유지되는가
- pane 간 coherence가 어떻게 보존되는가
- 이동 후 orientation이 어떻게 유지되는가

Interaction은 navigation을 시작할 수 있지만, navigation model 전체를 정의하지 않는다.

## 11. 다른 Authority와의 관계

### Workspace UX Architecture

`workspace_ux_architecture.md`는 persistent semantic workspace와 pane 관계의 parent 철학을 정의한다.

이 문서는 그 철학 아래에서 interaction이 semantic context를 보존하는 방식을 정의한다.

### Navigation Policy

`navigation_policy.md`는 semantic navigation continuity를 정의한다.

이 문서는 activation, focus, selection, transient continuity의 interaction-level 의미를 정의하고, navigation continuity 자체를 재정의하지 않는다.

### Search Policy

`search_policy.md`는 Search를 semantic search entry + result behavior policy로 정의한다.

Search result selection은 interaction을 포함할 수 있지만, search result meaning과 ordering policy는 search policy가 담당한다.

### Responsive Layout Policy

`responsive_layout_policy.md`는 form factor adaptation과 surface presentation을 정의한다.

이 문서는 transient surface가 context를 보존해야 한다는 interaction principle만 정의하며, responsive placement나 mobile layout tree를 정의하지 않는다.

### Graph Semantic Authority

`graph_semantic_authority.md`는 graph-specific semantic surface, traversal, expansion, relation semantics를 정의한다.

Graph node activation 또는 selection은 interaction 의미를 가질 수 있지만, graph traversal과 expansion semantics는 graph authority가 담당한다.

### Repository / Data Boundary

Repository and data boundary 문서는 API, schema, normalization, read/write boundary, data mutation을 정의해야 한다.

이 문서는 repository call, write transaction, rollback, validation, persistence behavior를 정의하지 않는다.

## 12. Interaction Boundary Rules

1. Interaction policy는 gesture implementation specification이 아니다.
2. Interaction policy는 pointer event handling guide가 아니다.
3. Interaction policy는 animation timing specification이 아니다.
4. Interaction policy는 Flutter widget 또는 controller authority가 아니다.
5. Interaction policy는 focus node implementation guide가 아니다.
6. Interaction policy는 shortcut key map이 아니다.
7. Interaction policy는 dialog widget specification이 아니다.
8. Interaction policy는 rendering 또는 visual styling guide가 아니다.
9. Interaction policy는 responsive layout authority가 아니다.
10. Interaction policy는 graph traversal 또는 expansion authority가 아니다.
11. Interaction policy는 repository 또는 data mutation authority가 아니다.
12. Interaction policy는 navigation continuity를 재정의하지 않는다.
13. Current implementation snapshot은 Interaction authority를 override하지 않는다.

## 13. 비목표

이 문서는 다음을 정의하지 않는다.

- GestureDetector 사용 방식
- pointer event handling
- click handler
- hover timing
- animation duration
- FocusNode 사용 방식
- controller hierarchy
- exact shortcut key binding
- dialog widget tree
- button order
- validation flow
- route structure
- overlay implementation
- rendering layout
- graph traversal rule
- graph expansion rule
- repository API
- SQL
- data mutation
- debounce 또는 timer implementation

## 14. 요약

Interaction policy는 Reshet의 interaction을 semantic activation, focus, selection, transient continuity의 UX-level 기준으로 정의한다.

Activation은 semantic context를 시작하거나 전환하는 행위다. Focus는 사용자의 attention이 향하는 semantic target이고, selection은 사용자가 현재 다루는 semantic object다. Transient surface와 modal은 현재 context를 단절하지 않고 제한된 작업을 지원해야 한다.

이 문서는 gesture, widget, controller, animation, shortcut, dialog implementation, graph traversal, responsive layout, repository mutation을 정의하지 않는다. Interaction은 implementation event가 아니라 semantic workspace 안에서 사용자의 intent를 안정적으로 표현하고 보존하는 UX-level behavior다.
