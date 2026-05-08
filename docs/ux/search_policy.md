# Search Policy

## 1. 목적

이 문서는 Reshet의 Search를 semantic search entry + result behavior policy로 정의한다.

Search는 단순한 text lookup, UI widget, repository query가 아니다. Search는 사용자가 semantic workspace 안에서 알려진 대상, 예상되는 대상, 또는 탐색 중 발견한 의미 후보로 진입하기 위한 global semantic entry point다.

이 문서는 Search가 어떤 UX-level 의미를 가져야 하는지, search result가 어떤 방식으로 semantic context entry가 되어야 하는지, result behavior가 어떤 경계를 지켜야 하는지를 정의한다.

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- Search의 global semantic entry role
- search result가 semantic object entry로 해석되는 원칙
- Strong exact match의 UX-level 의미
- general search result의 match priority 철학
- result ordering의 UX-level 기준
- result grouping의 boundary
- empty query / no result behavior의 UX-level 기준
- search result와 navigation continuity의 책임 경계

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- SQL 또는 query implementation
- repository API signature
- DTO, schema, normalization detail
- exact ranking score formula
- hardcoded priority constant
- exact debounce timing
- Flutter widget, controller, state implementation
- result rendering detail
- responsive placement detail
- graph traversal 또는 expansion rule

## 3. Workspace UX Authority와의 관계

`workspace_ux_architecture.md`는 Reshet이 persistent semantic workspace를 지향한다는 parent UX authority다.

이 문서는 그 하위에서 Search가 semantic workspace로 진입하는 global entry point로 어떻게 작동해야 하는지를 정의한다.

Search는 graph, detail, exploration, navigation surface 중 하나에 종속되지 않는다. Search는 사용자가 현재 어떤 surface에 있더라도 semantic object 또는 semantic context로 진입할 수 있게 해야 한다.

이 문서는 workspace 철학 전체를 다시 정의하지 않는다. 이 문서는 Search의 semantic entry와 result behavior만 정의한다.

## 4. Search Semantic Entry 철학

Search는 semantic workspace로 들어가는 global semantic entry point다.

Search의 목적은 사용자를 단순 문자열 결과 목록에 멈추게 하는 것이 아니라, 의미 있는 대상 또는 의미 후보로 진입하게 하는 것이다.

Search는 다음을 지원해야 한다.

- 알려진 Strong anchor로 빠르게 진입
- 단어 표기, 음역, 의미 단서로 semantic object 발견
- 현재 workspace context를 불필요하게 버리지 않는 corpus access
- graph, detail, exploration surface 중 적절한 semantic entry로 이어질 수 있는 결과 선택

Search는 graph replacement가 아니다. Search는 detail renderer도 아니다. Search는 semantic entry를 제공하고, 그 이후 context continuity는 navigation authority와 workspace structure 안에서 처리되어야 한다.

## 5. Search Context와 Result Entry

Search context는 사용자가 입력한 query와 그 query가 가리키는 semantic intent의 관계다.

Search result는 semantic object 또는 semantic object 후보로 해석되어야 한다. Search result는 단순 row, raw data, rendering item이 아니라 사용자가 workspace 안에서 확인하거나 이동할 수 있는 semantic entry다.

Search result는 가능하면 stable semantic identity를 가져야 한다. UX-level 기준에서 result entry는 표시 문자열보다 semantic object identity를 우선해야 한다.

Result entry는 다음으로 이어질 수 있다.

- detail reading
- graph context
- exploration context
- workspace 안의 다른 semantic surface

어떤 surface로 진입하더라도 Search result 자체가 navigation continuity를 재정의하지는 않는다. Result는 entry를 제공하고, entry 이후 continuity는 navigation policy가 담당한다.

## 6. Strong Exact Search 원칙

Strong exact match는 known semantic anchor로 우선 해석된다.

Strong number는 사용자가 이미 알고 있는 external reference 또는 canonical anchor일 수 있다. 따라서 Strong exact match는 일반 keyword discovery보다 더 직접적인 semantic intent로 해석될 수 있다.

Strong exact search의 UX-level 원칙은 다음과 같다.

- 사용자가 정확한 Strong anchor를 입력하면 해당 anchor로 빠르게 진입할 수 있어야 한다.
- Strong exact match는 일반 discovery result보다 더 직접적인 semantic entry로 취급될 수 있다.
- Strong exact match가 존재하지 않는 경우에도 Search는 일반 discovery path를 통해 semantic 후보를 제공할 수 있다.
- Strong anchor는 display convenience가 아니라 semantic entry anchor로 해석되어야 한다.

이 문서는 Strong normalization algorithm, exact parsing rule, repository query, numeric comparison, priority constant를 정의하지 않는다.

## 7. General Search Result Philosophy

General Search는 사용자가 정확한 anchor를 모르는 상태에서 semantic object를 발견하도록 돕는다.

General result behavior는 사용자의 query intent와 semantic target 사이의 거리를 줄여야 한다.

다음 match 성격은 UX-level에서 구분될 수 있다.

- exact match: query가 semantic target을 직접 가리키는 경우
- prefix match: query가 target의 시작 단서로 작동하는 경우
- partial match: query가 target 내부의 단서로 작동하는 경우
- meaning match: query가 surface form보다 의미 설명을 통해 target을 가리키는 경우

이 구분은 search result behavior를 설명하기 위한 철학적 기준이다. 이 문서는 exact matching implementation, field-specific algorithm, scoring formula를 정의하지 않는다.

## 8. Result Ordering Philosophy

Result ordering은 사용자가 의도한 semantic target에 빠르게 도달하도록 도와야 한다.

Ordering의 UX-level 기준은 다음과 같다.

- 더 직접적인 semantic match는 덜 직접적인 match보다 우선될 수 있다.
- known anchor match는 discovery-oriented match보다 우선될 수 있다.
- surface form의 직접 match는 indirect clue보다 우선될 수 있다.
- 같은 수준의 match에서는 사용자가 결과를 예측 가능하게 비교할 수 있어야 한다.

Ordering은 semantic usefulness를 높이기 위한 정책이다. Ordering은 exact numerical score, priority constant, SQL order, widget ordering implementation을 의미하지 않는다.

## 9. Result Grouping Boundary

Result grouping은 필요할 수 있지만, grouping은 visual rendering specification이 아니다.

Search result grouping은 다음 목적을 가질 수 있다.

- known anchor result와 discovery result의 의미 차이를 드러내기
- exact, prefix, partial, meaning-based result의 성격을 구분하기
- duplicate 또는 near-duplicate result를 사용자가 이해할 수 있게 하기
- empty 또는 no result 상태와 normal result 상태를 명확히 구분하기

그러나 grouping은 다음을 정의하지 않는다.

- visual section layout
- list rendering structure
- card 또는 tile structure
- color, typography, spacing
- responsive placement

Grouping은 search result behavior의 의미적 구분으로만 다룬다.

## 10. Empty Query / No Result Behavior

Empty query와 no result는 같은 상태가 아니다.

Empty query는 사용자가 아직 semantic intent를 제공하지 않은 상태다. Empty query를 Search result가 없다는 의미로만 처리하면 Search와 browse/default list의 책임이 섞일 수 있다.

No result는 사용자가 semantic intent를 제공했지만 현재 corpus에서 대응되는 entry를 찾지 못한 상태다.

UX-level 기준은 다음과 같다.

- Empty query는 browse, default list, recent entry, known anchor access와 혼동되지 않아야 한다.
- No result는 corpus에 해당 semantic candidate가 없거나 query가 충분히 구체적이지 않다는 상태로 해석될 수 있어야 한다.
- No result는 사용자를 dead end에 가두지 않아야 한다.
- No result 이후에도 수정된 query, 생성 action, 다른 semantic entry로 이어질 수 있어야 한다.

이 문서는 empty query의 exact UI behavior, default list implementation, no result rendering text, create flow trigger 조건을 정의하지 않는다.

## 11. Search Result Navigation Boundary

Search result는 semantic entry를 제공한다.

Search result 선택 이후의 navigation continuity는 `navigation_policy.md`가 담당한다.

Search policy의 관심은 다음과 같다.

- 어떤 result가 semantic object entry로 해석되는가
- result entry가 stable semantic identity를 가지는가
- result 선택이 detail, graph, exploration 등으로 이어질 수 있는 entry를 제공하는가

Navigation policy의 관심은 다음과 같다.

- entry 이후 current focus가 어떻게 유지되는가
- semantic context continuity가 어떻게 보존되는가
- pane 간 coherence가 어떻게 유지되는가
- 사용자가 이동 후 orientation을 잃지 않는가

Search는 navigation을 시작할 수 있지만, navigation model 전체를 정의하지 않는다.

## 12. 다른 Authority와의 관계

### Workspace UX Architecture

`workspace_ux_architecture.md`는 Search가 persistent semantic workspace의 universal entry point라는 parent 철학을 정의한다.

이 문서는 그 철학 아래에서 Search result behavior와 search-specific boundary를 정의한다.

### Navigation Policy

`navigation_policy.md`는 semantic navigation continuity를 정의한다.

이 문서는 Search가 semantic entry를 제공한다는 점을 정의하고, entry 이후 continuity는 navigation policy에 맡긴다.

### Responsive Layout Policy

`responsive_layout_policy.md`는 form factor 변화 속에서도 Search가 global entry point 역할을 유지해야 한다는 layout-level 원칙을 정의한다.

이 문서는 Search의 responsive placement, breakpoint, mobile layout tree를 정의하지 않는다.

### Graph Semantic Authority

`graph_semantic_authority.md`는 graph-specific semantic surface, traversal, expansion, relation semantics를 정의한다.

Search result는 graph context로 진입할 수 있지만, graph traversal 또는 expansion rule은 graph authority가 담당한다.

### Repository / Data Boundary

Repository and data boundary 문서는 query implementation, API, schema, normalization, read boundary를 정의해야 한다.

이 문서는 SQL, DTO, repository method, database schema, normalized read rule을 정의하지 않는다.

## 13. Search Boundary Rules

1. Search policy는 repository query specification이 아니다.
2. Search policy는 SQL 또는 schema authority가 아니다.
3. Search policy는 exact scoring formula authority가 아니다.
4. Search policy는 hardcoded priority constant를 정의하지 않는다.
5. Search policy는 debounce timing specification이 아니다.
6. Search policy는 Flutter widget 또는 controller authority가 아니다.
7. Search policy는 result rendering guide가 아니다.
8. Search policy는 responsive placement authority가 아니다.
9. Search policy는 graph traversal 또는 expansion authority가 아니다.
10. Search policy는 navigation continuity를 재정의하지 않는다.
11. Current implementation snapshot은 Search authority를 override하지 않는다.

## 14. 비목표

이 문서는 다음을 정의하지 않는다.

- search repository method name
- SQL query
- LIKE matching rule
- exact normalization algorithm
- score formula
- priority number
- debounce interval
- keyboard shortcut
- result list widget
- empty state text
- no result text
- responsive placement
- graph traversal
- graph expansion
- database schema
- DTO 또는 raw row contract

## 15. 요약

Search는 Reshet semantic workspace로 들어가는 global semantic entry point다.

Search result는 semantic object 또는 semantic object 후보로 진입할 수 있어야 한다. Strong exact match는 known semantic anchor로 우선 해석될 수 있고, general search result는 사용자가 의도한 semantic target에 빠르게 도달하도록 정렬되거나 구분될 수 있다.

이 문서는 Search의 UX-level semantic entry와 result behavior를 정의한다. Query implementation, scoring formula, debounce timing, widget rendering, responsive placement, graph traversal, repository boundary는 다른 authority가 담당한다.
