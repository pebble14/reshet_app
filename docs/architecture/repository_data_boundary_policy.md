# Repository Data Boundary Policy

> Status: Active repository/data authority
>
> 이 문서는 Reshet의 repository/data boundary에 대한 현재 active authority다.
>
> 이 문서는 UX semantic authority, migration/history log, schema reference,
> implementation helper specification이 아니다.

## 1. 목적

이 문서는 Reshet에서 repository가 UI/semantic surface와 database storage 사이에서 어떤 책임을 가지는지 정의한다.

Reshet의 현재 expression 구조는 다음 상태다.

```text
write authority = canonicalized
read authority = hybrid transition
```

즉 expression write 기준은 repository 내부 canonical expression set과 `word_expression_set` write path를 우선한다. 그러나 read 기준은 아직 normalized-only 완료 상태가 아니다. `LEGACY`와 `NORMALIZED_WITH_FALLBACK` context가 공존하며, fallback governance와 compatibility projection이 유지된다.

이 문서의 목적은 다음 경계를 active authority로 고정하는 것이다.

- repository responsibility
- repository public contract
- normalized read/write boundary
- read context governance
- controlled zone governance
- legacy compatibility projection
- fallback / collector governance
- search read boundary
- graph read boundary
- snapshot / history persistence boundary
- repository verification / comparison 기준

## 2. Authority 범위

이 문서가 authority를 가지는 범위는 다음과 같다.

- UI와 database 사이의 repository 책임 경계
- repository public contract의 의미
- read source policy의 active 해석
- normalized read boundary와 fallback boundary
- normalized write / mutation boundary
- controlled zone 정의와 승격 기준
- owner-specific read context governance
- search read boundary
- graph read boundary
- semantic read boundary
- legacy compatibility projection의 역할
- fallback reason과 collector 관측 원칙
- snapshot / history persistence boundary
- repository 결과 비교와 verification 기준

이 문서가 authority를 가지지 않는 범위는 다음과 같다.

- Flutter widget 또는 controller 구조
- screen flow
- semantic UX philosophy
- graph traversal semantics
- responsive layout
- dialog 또는 interaction behavior
- SQL optimization detail
- exact schema migration sequence
- temporary migration workaround
- implementation-only helper detail
- phase-by-phase migration log

## 3. UX / Semantic Authority와의 관계

UX authority는 사용자가 어떤 semantic workspace를 경험해야 하는지 정의한다. Repository/data boundary는 그 semantic surface가 소비할 stable data contract를 repository가 어떻게 공급하는지 정의한다.

따라서 UX authority는 다음을 전제할 수 있다.

- UI surface는 repository가 확정한 semantic object 또는 display contract를 소비한다.
- Search result, graph node, detail display는 stable semantic identity를 가져야 한다.
- UI는 source selection, fallback reason, schema detail을 직접 해석하지 않는다.

그러나 UX authority는 다음을 정의하지 않는다.

- repository API signature
- SQL query
- schema structure
- normalization algorithm
- read source policy
- write transaction
- fallback / rollback behavior

Graph, search, navigation, interaction authority가 repository/data boundary를 언급할 때는 이 문서를 기준으로 한다.

## 4. Repository Responsibility

Repository는 UI/State/Controller와 DatabaseService/SQLite 사이의 data boundary다.

Repository의 책임은 다음과 같다.

- DB row와 public contract 사이의 materialization
- read source 선택
- normalized read adapter 호출
- fallback 판정
- lookup 해석
- owner-specific display contract 생성
- data mutation transaction 관리
- history snapshot 생성과 복원
- relation write/read boundary 관리
- verification 가능한 debug/collector observation 제공

UI의 책임은 다음으로 제한된다.

- repository public contract 소비
- semantic activation 또는 display 흐름 처리
- 사용자의 visible state 표현

UI는 다음을 직접 수행하지 않는다.

- SQL 작성
- DB row의 canonical 의미 해석
- `word_expression_set`와 `WORD_TABLE` 사이의 source selection
- fallback reason 판정
- normalized / legacy source 차이 보정
- history snapshot 구조 해석

## 5. Repository Public Contract

Repository public contract는 UI와 domain layer가 소비할 수 있는 stable boundary다.

Public contract는 다음을 우선한다.

- stable semantic identity
- typed display item
- owner-specific minimal contract
- source 차이를 숨긴 final materialized result
- fallback 이후 확정된 최종 반환 구조

Raw `Map<String, dynamic>` 반환은 legacy compatibility 또는 transition boundary로 해석한다. Raw map 반환이 존재한다고 해서 UI가 storage structure를 직접 해석해도 된다는 뜻은 아니다.

새 read surface는 가능하면 다음 형태를 우선해야 한다.

- typed display contract
- id 중심 contract
- owner-specific projection
- probe 전용 minimal result

Repository method name이나 현재 반환 타입은 UX authority가 아니다. Public contract 변경은 repository/data boundary 변경으로 다루어야 하며, UX philosophy 문서에서 직접 정의하지 않는다.

## 6. Normalized Read Boundary

현재 expression read authority는 hybrid transition 상태다.

Read source policy는 다음 세 상태를 기준으로 해석한다.

| Policy | 의미 |
| --- | --- |
| `LEGACY` | legacy `WORD_TABLE` expression slot을 read source로 사용한다. |
| `NORMALIZED_WITH_FALLBACK` | `word_expression_set`를 우선 조회하고, 정의된 비정상 조건에서만 legacy result로 fallback 한다. |
| `NORMALIZED_ONLY` | `word_expression_set`만 read source로 사용한다. 현재 전면 완료 상태로 선언하지 않는다. |

현재 active 상태는 다음과 같다.

- global read는 normalized-only 완료 상태가 아니다.
- legacy 기본 context와 `NORMALIZED_WITH_FALLBACK` context가 공존한다.
- controlled 또는 owner-specific context만 단계적으로 normalized read 후보가 될 수 있다.
- fallback governance와 collector observation은 read transition의 일부다.

Normalized read는 source-specific raw row를 public contract로 직접 노출하지 않는다. Repository는 normalized read adapter가 만든 canonical expression result를 기준으로 final materialized result를 만든다.

Read source가 달라도 public contract는 source 차이를 직접 드러내지 않아야 한다. 다만 fallback, collector, debug observation은 repository boundary 내부에서 검증 가능해야 한다.

## 7. Normalized Write / Mutation Boundary

현재 expression write authority는 repository 내부 canonical expression set과 `word_expression_set` write path를 우선한다.

Expression write 흐름은 다음 기준을 따른다.

```text
input / draft
-> canonical expression set
-> normalized rows in word_expression_set
-> WORD_TABLE expression slot compatibility projection
```

`WORD_TABLE` expression slot은 expression write 기준 authoritative source가 아니다. 이 slot은 current read compatibility와 기존 surface 호환을 위한 projection이다.

단, 이 문장은 다음을 의미하지 않는다.

- `WORD_TABLE`이 제거되었다.
- read source가 normalized-only로 완료되었다.
- legacy fallback이 제거되었다.
- 전체 DB authority가 normalized structure로 완전히 전환되었다.

`WORD_TABLE`은 여전히 다음 역할을 가진다.

- word core 1:1 row storage
- Strong number, language, meaning, note 등 core/compatibility field storage
- legacy read compatibility
- expression compatibility projection

Data mutation은 repository transaction boundary 안에서 처리한다. UI는 mutation 이후 repository가 확정한 result 또는 reread boundary를 통해 상태를 갱신한다.

## 8. Read Context Governance

Read context는 repository가 어떤 owner, contract, fallback rule, collector context로 read를 수행하는지 구분하기 위한 boundary다.

Read context governance의 기본 원칙은 다음과 같다.

- generic read는 controlled read로 자동 승격되지 않는다.
- owner-specific read라도 display contract가 고정되지 않으면 controlled read가 아니다.
- probe context는 display read와 분리한다.
- context는 fallback observation과 collector summary를 해석할 수 있어야 한다.
- context-specific read boundary는 source transition의 blast radius를 제한해야 한다.

Read context는 다음 tier로 분류할 수 있다.

| Tier | 의미 |
| --- | --- |
| Controlled zone | owner-specific display read이며 fallback/collector 해석이 가능한 context |
| Owner-specific but not controlled | owner는 있으나 display read가 아니거나 controlled 조건을 충족하지 않는 context |
| Legacy generic | owner가 없고 full row helper 성격이 강한 context |

Generic helper를 재사용해 source policy를 확장하면 context별 사용자 영향과 fallback 원인을 분리하기 어렵다. 따라서 normalized read 확대는 generic helper 직접 확장이 아니라 owner-specific boundary 분리 이후 검토해야 한다.

## 9. Controlled Zone Governance

Controlled zone은 repository/data authority 안의 read context governance 개념이다.

Controlled zone은 다음 조건을 모두 만족하는 context다.

- 단일 owner가 존재한다.
- probe나 internal helper가 아니라 display read다.
- 반환 의미가 특정 owner display contract에 대해 고정되어 있다.
- fallback 결과를 구조적으로 해석할 수 있다.
- collector 결과를 구조적으로 해석할 수 있다.
- UI display와 직접 연결된다.
- generic 재사용에서 분리되어 있다.

Controlled zone이 필요한 이유는 다음과 같다.

- normalized read 확대 범위를 작게 유지한다.
- fallback reason을 context별로 해석 가능하게 한다.
- UI-visible mismatch를 source transition 중에 관측할 수 있게 한다.
- generic helper가 여러 surface에 영향을 주는 것을 막는다.
- read source migration과 active repository contract를 분리한다.

Controlled zone 승격 절차는 다음 순서를 따른다.

```text
generic
-> owner-specific 분리
-> 반환 계약 고정
-> fallback / collector 관측 가능성 확보
-> controlled 판정
-> normalized read policy 승격 검토
```

Owner-specific이라는 사실만으로 controlled zone이 되지 않는다. Probe context는 display read가 아니므로 별도 기준이 마련되기 전까지 controlled zone 밖에 둔다.

## 10. Legacy Compatibility Projection

Compatibility projection은 canonical storage 또는 active write authority가 아닌 legacy compatibility layer다.

현재 `WORD_TABLE` expression slot은 compatibility projection이다. 이 projection은 다음 목적을 가진다.

- legacy read path 유지
- 기존 surface와 tool/script 호환
- transition 중 rollback 가능성 유지
- user-visible display mismatch 비교 기준 유지

Compatibility projection은 다음을 의미하지 않는다.

- `WORD_TABLE` expression slot이 expression write authority다.
- normalized write가 완료되지 않았다.
- normalized read가 항상 무시된다.

Compatibility projection은 transition architecture의 일부이며, projection 제거 여부는 별도 phase와 verification 이후 판단한다.

## 11. Fallback / Collector Governance

Fallback은 source 차이를 숨기는 일반 보정 장치가 아니다. Fallback은 normalized read가 안정적인 final result를 만들 수 없는 비정상 상태에서만 허용되는 recovery boundary다.

Fallback governance의 원칙은 다음과 같다.

- fallback reason은 구조적으로 분류되어야 한다.
- fallback 발생 context와 `word_id`는 관측 가능해야 한다.
- fallback은 normalized 안정화 여부를 판단하는 signal이다.
- fallback이 조용히 발생하는 상태를 안정 상태로 보지 않는다.
- collector 누락 또는 중복 때문에 observation을 신뢰할 수 없으면 controlled 승격을 보류한다.

Repository collector는 다음을 관측할 수 있어야 한다.

- word id
- read context
- requested policy
- final result source
- fallback 여부
- fallback reason
- legacy result availability
- normalized result availability
- final result set count

Collector는 UI policy가 아니다. Collector는 repository/data transition을 검증하기 위한 debug/verification boundary다.

## 12. Search Read Boundary

Search policy는 search result가 semantic entry라는 UX-level 의미를 정의한다. Search read boundary는 repository가 그 entry를 어떤 source와 contract로 공급하는지 정의한다.

Search read boundary의 원칙은 다음과 같다.

- search result는 stable semantic identity를 가져야 한다.
- search result는 raw DB row가 아니라 public display contract로 소비되어야 한다.
- search ranking과 SQL implementation은 search UX authority가 아니라 repository/data 또는 implementation boundary다.
- search result display는 fallback 이후 확정된 final materialized result를 사용해야 한다.
- Strong exact search와 general search는 repository public contract 기준으로 결과를 반환해야 한다.

Search read boundary는 graph traversal, navigation continuity, responsive placement를 정의하지 않는다.

## 13. Graph Read Boundary

Graph authority는 graph traversal semantics, relation direction semantics, expansion philosophy를 정의한다. Graph read boundary는 repository가 graph surface에 필요한 relation data와 word display data를 어떻게 공급하는지 정의한다.

Graph read boundary의 원칙은 다음과 같다.

- graph는 repository가 확정한 relation edge와 word display contract를 소비한다.
- graph surface는 `WORD_RELATION` storage를 직접 해석하지 않는다.
- relation lookup materialization은 repository responsibility다.
- graph label, center display, visible word data는 가능한 한 owner-specific contract로 공급한다.
- graph batch와 graph center read는 generic read와 분리된 context로 검토해야 한다.

Graph read boundary는 다음을 정의하지 않는다.

- graph traversal semantic meaning
- expansion philosophy
- layout algorithm
- node rendering
- click behavior

## 14. Snapshot / History Persistence Boundary

History persistence는 repository mutation boundary 안에서 관리한다.

Current expression history 원칙은 다음과 같다.

- word history snapshot은 compatibility word snapshot과 normalized expression rows를 함께 보존할 수 있다.
- new history row는 normalized snapshot restore를 우선한다.
- older history row는 legacy compatibility fallback restore를 유지할 수 있다.
- history snapshot은 UI state persistence가 아니라 data mutation rollback/persistence boundary다.

History는 다음을 직접 정의하지 않는다.

- navigation history UX
- selected state restoration policy
- tooltip display behavior
- screen flow

Snapshot / history persistence는 write authority, compatibility projection, rollback 가능성을 함께 보존해야 한다.

## 15. Verification / Comparison 기준

Repository/data verification은 raw DB row 차이가 아니라 final public contract와 canonical read result 기준으로 판단한다.

Verification 원칙은 다음과 같다.

- source별 raw row 차이는 최종 판정 기준이 아니다.
- repository final result의 user-visible equivalence를 확인한다.
- fallback 발생 여부와 fallback reason을 기록한다.
- context별 collector observation을 확인한다.
- create/update/delete/undo 이후 expression dual-write와 compatibility projection이 정합한지 확인한다.
- `word_expression_set` verification은 semantic diff 기준으로 수행한다.

Repository result comparison은 다음을 구분해야 한다.

- legacy raw row
- normalized raw row
- canonical read result
- materialized public contract
- fallback final result

단계 승격은 verification 결과와 fallback observation을 함께 보고 판단한다.

## 16. Migration / History 문서와의 관계

Migration/history 문서는 evidence, transition context, phase record를 제공한다. Migration/history 문서는 이 active repository/data authority를 override하지 않는다.

`docs/database/read_source_migration.md`는 다음 역할을 가진다.

- phase별 변경 이력
- migration decision history
- 이전 검증 기록
- controlled zone 정의의 source history
- read source transition 과정 기록

다만 active 판단은 이 문서를 따른다.

Migration/history 문서에서 active authority로 승격할 수 있는 내용은 이 문서에 옮겨 관리한다. Phase별 세부 로그, temporary workaround, 특정 command 결과는 migration/history 문서에 남긴다.

## 17. 다른 문서와의 관계

### Workspace UX Architecture

`docs/ux/workspace_ux_architecture.md`는 persistent semantic workspace의 UX 철학을 정의한다. 이 문서는 workspace surface가 소비하는 repository/data contract를 정의한다.

### Search Policy

`docs/ux/search_policy.md`는 Search의 semantic entry role을 정의한다. Search query implementation, normalized read rule, repository method contract는 이 문서의 boundary에 속한다.

### Interaction Policy

`docs/ux/interaction_policy.md`는 activation, focus, selection, transient continuity를 정의한다. Data mutation, rollback, persistence behavior는 이 문서의 boundary에 속한다.

### Graph Semantic Authority

`docs/architecture/graph_semantic_authority.md`는 graph-specific semantics를 정의한다. Graph read data, relation lookup materialization, graph display contract는 이 문서의 boundary에 속한다.

### Data Structure Policy

`docs/database/DATA_STRUCTURE_POLICY.md`는 data structure의 현재 상태와 목표 상태를 정리한다. 이 문서는 repository public contract와 read/write boundary authority를 정의한다.

### Schema Reference

`docs/database/SCHEMA.md`는 actual schema reference다. Schema reference는 table/column/constraint 사실을 설명하되, repository context governance를 정의하지 않는다.

## 18. Boundary Rules

다음 규칙은 repository/data boundary를 고정한다.

1. UI는 data source selection을 직접 해석하지 않는다.
2. Repository는 read source 선택, fallback 판정, materialization을 담당한다.
3. Expression write authority는 canonical expression set / `word_expression_set` write path를 우선한다.
4. `WORD_TABLE` expression slot은 compatibility projection이다.
5. Read authority는 아직 hybrid transition 상태다.
6. Normalized-only read 완료를 선언하지 않는다.
7. Legacy fallback 제거를 선언하지 않는다.
8. Controlled zone은 owner-specific display read와 collector/fallback 해석 가능성을 모두 요구한다.
9. Generic helper는 controlled zone으로 자동 승격되지 않는다.
10. Search/graph/detail read는 각 owner-specific contract로 분리될 수 있어야 한다.
11. History snapshot은 mutation persistence boundary이며 UX navigation history policy가 아니다.
12. Migration/history 문서는 active authority를 override하지 않는다.
13. Schema reference는 repository public contract를 정의하지 않는다.
14. Current implementation convenience는 repository/data authority를 정의하지 않는다.

## 19. 비목표

이 문서는 다음을 정의하지 않는다.

- Flutter widget tree
- controller hierarchy
- screen route flow
- interaction timing
- dialog behavior
- responsive layout
- graph traversal semantics
- graph layout algorithm
- search UX philosophy
- exact SQL optimization
- exact migration execution sequence
- implementation-only helper detail
- temporary workaround
- phase-by-phase migration record
- visual rendering detail

## 20. 요약

Repository Data Boundary Policy는 Reshet의 active repository/data authority다.

현재 expression write authority는 repository 내부 canonical expression set과 `word_expression_set` write path를 우선한다. `WORD_TABLE` expression slot은 compatibility projection이다.

Read authority는 아직 hybrid transition 상태다. `LEGACY`와 `NORMALIZED_WITH_FALLBACK` context가 공존하며, normalized-only 완료나 fallback 제거는 선언하지 않는다.

Controlled zone은 normalized read 확대를 owner-specific display contract, fallback observation, collector 해석 가능성 안에서 제한하기 위한 governance다.

Future repository/data change는 source selection, public contract, compatibility projection, fallback observation, history persistence, verification 기준이 이 문서의 boundary를 강화하는지 약화하는지 기준으로 판단해야 한다.
