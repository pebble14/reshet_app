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
runtime read/write/history authority = canonical-only
retained compatibility = input/history/debug boundary
```

즉 active production expression read/write/history authority는 `word_expression_set`이다. 모든 active production owner-specific read context는 `NORMALIZED_ONLY`를 사용하며 `WORD_TABLE`의 legacy 표현 컬럼을 SQL projection하거나 legacy adapter를 실행하지 않는다. 현행 `WORD_TABLE`에는 18개 표현 컬럼이 없다. `_defaultReadSourcePolicy`의 `LEGACY`, 공용 resolver와 debug policy override는 generic/debug 호환·검증을 위해 남은 구현 경계이며 active production legacy fallback이 아니다.

이 문서의 목적은 다음 경계를 active authority로 고정하는 것이다.

- repository responsibility
- repository public contract
- normalized read/write boundary
- read context governance
- controlled zone governance
- retained compatibility boundary
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
- retained compatibility boundary의 역할
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
- resolver/materialization 이후 확정된 최종 반환 구조

Raw `Map<String, dynamic>` 반환은 legacy-shaped 메모리 projection 또는 internal compatibility boundary로 해석한다. Raw map 반환이나 `Word.fromMap` parsing contract가 존재한다고 해서 물리 legacy DB 컬럼을 조회하거나 UI가 storage structure를 직접 해석해도 된다는 뜻은 아니다.

새 read surface는 가능하면 다음 형태를 우선해야 한다.

- typed display contract
- id 중심 contract
- owner-specific projection
- probe 전용 minimal result

Repository method name이나 현재 반환 타입은 UX authority가 아니다. Public contract 변경은 repository/data boundary 변경으로 다루어야 하며, UX philosophy 문서에서 직접 정의하지 않는다.

## 6. Normalized Read Boundary

현재 production expression read authority는 canonical-only 상태다. 과거 hybrid transition에서 사용한 policy enum과 resolver 분기는 retained compatibility와 debug/verification 경계로 남아 있지만 active production source authority를 구성하지 않는다.

Read source policy 구현은 다음 세 mode를 구분한다.

| Policy | 의미 |
| --- | --- |
| `LEGACY` | legacy-shaped row를 해석하는 generic/debug 호환 mode다. 현행 schema의 물리 expression slot은 active runtime read source가 아니다. |
| `NORMALIZED_WITH_FALLBACK` | `word_expression_set`를 우선 조회하고 retained resolver 안에서만 compatibility result를 비교·선택할 수 있는 debug/verification mode다. active production context는 없다. |
| `NORMALIZED_ONLY` | `word_expression_set`만 read source로 사용한다. 모든 active production owner-specific context의 현재 mode다. |

현재 active 상태는 다음과 같다.

- active production owner-specific context는 모두 `NORMALIZED_ONLY`이며 expression을 `word_expression_set`에서 읽는다.
- 현행 `WORD_TABLE`에는 legacy expression slot이 없으므로 live legacy expression SQL read나 production fallback source가 존재하지 않는다.
- `_defaultReadSourcePolicy`의 `LEGACY`와 `NORMALIZED_WITH_FALLBACK` 처리 분기는 generic/debug 호환·비교 능력으로 유지하며 production runtime fallback과 동일시하지 않는다.
- fallback governance와 collector observation은 retained debug/verification 경계를 검증하기 위한 능력이다.

Detail·Explorer·graph-create edit-seed 경계의 active policy는 다음과 같다.

- debug policy override가 없을 때 `readForDetailEditSeed`,
  `readForExplorerEditSeed`, `readForGraphCreateEditSeed`는
  `NORMALIZED_ONLY`를 요청한다.
- 세 context의 실제 요청 정책이 `NORMALIZED_ONLY`이고 최종 결과가
  `normalizedFailure`이면, repository는 snapshot과 failure observation을
  기록한 뒤 nullable `WordEditSeed` contract에서 `null`을 반환한다. 이때
  legacy expression result로 edit seed를 재구성하지 않는다.
- normalized row가 없는 canonical empty는 normalized 성공 결과이므로 non-null edit seed와 빈 expression set을 반환한다.

Normalized read는 source-specific raw row를 public contract로 직접 노출하지 않는다. Repository는 normalized read adapter가 만든 canonical expression result를 기준으로 final materialized result를 만든다.

Generic/debug resolver에서 source를 비교하더라도 public contract는 source 차이를 직접 드러내지 않아야 한다. Retained fallback, collector, debug observation은 repository boundary 내부에서만 검증 가능해야 한다.

## 7. Normalized Write / Mutation Boundary

현재 expression write authority는 repository 내부 canonical expression set과 `word_expression_set` write path다.

Expression write 흐름은 다음 기준을 따른다.

```text
input / draft
-> canonical expression set
-> normalized rows in word_expression_set
```

현행 `WORD_TABLE`에는 expression slot이 없다. create/update는 repository transaction 안에서 canonical expression set을 `word_expression_set` row로만 저장한다.

단, 이 문장은 다음을 의미하지 않는다.

- `WORD_TABLE`이 제거되었다.
- full-legacy startup·restore 입력 지원이 제거되었다.
- 구형 history payload decoder가 제거되었다.
- generic/debug resolver와 policy override가 제거되었다.
- 전체 DB authority가 normalized structure로 완전히 전환되었다.

`WORD_TABLE`은 여전히 다음 역할을 가진다.

- word core 1:1 row storage
- Strong number, language, note, graph expand mode 등 core field storage

Full-legacy startup·restore 입력의 `WORD_TABLE` expression slot은 staging compatibility 입력으로만 해석한다. Runtime ensure는 canonical 대응과 archive를 검증한 뒤 해당 컬럼을 제거하므로 live `WORD_TABLE` 역할이나 read/write authority가 아니다.

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

## 10. Retained Compatibility Boundary

Retained compatibility boundary는 canonical storage 또는 active production read/write authority가 아닌 과거 데이터·debug/verification 호환 layer다.

`WORD_TABLE.표기1~6`·`음역1~6`·`발음1~6`은 현행 schema에서 물리 제거됐다. 다음 호환 경계만 유지한다.

- full-legacy startup·restore 입력을 staging에서 canonical row로 검증·전환하는 경계
- normalized expression payload가 없는 구형 history snapshot의 legacy key decoder
- generic/debug resolver, policy override, collector와 legacy-shaped 메모리 projection
- canonical 발음과 ASCII 끝 공백만 달랐던 exact raw를 보존하는 `WORD_LEGACY_EXPRESSION_VALUE`

이 retained compatibility는 다음을 의미하지 않는다.

- `WORD_TABLE` expression slot이 expression write authority다.
- live legacy expression SQL read나 production fallback이 존재한다.
- `WORD_LEGACY_EXPRESSION_VALUE`가 runtime read source 또는 fallback이다.
- 구형 입력이 migration 이후에도 물리 expression slot으로 남는다.

Active `NORMALIZED_ONLY` read가 legacy-shaped raw map을 반환해야 할 때는 canonical row에서 메모리 호환 형상을 materialize한다. `Word.fromMap` 또는 legacy-shaped key를 소비하는 in-memory contract는 물리 legacy DB read가 아니다. `WORD_LEGACY_EXPRESSION_VALUE`도 원시값 보존용 비권위 archive이며 repository read/write, 검색·그래프·상세·편집, history/undo에서 소비하지 않는다.

## 11. Fallback / Collector Governance

Fallback branch와 collector는 generic/debug resolver의 비교·검증 능력으로 유지한다. Active production owner-specific context에는 legacy fallback source가 없다. 아래 원칙은 retained resolver를 사용하는 debug/verification 경계에 적용한다.

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

Collector는 UI policy가 아니다. Collector는 retained repository/data resolver를 검증하기 위한 debug/verification boundary다.

## 12. Search Read Boundary

Search policy는 search result가 semantic entry라는 UX-level 의미를 정의한다. Search read boundary는 repository가 그 entry를 어떤 source와 contract로 공급하는지 정의한다.

Search read boundary의 원칙은 다음과 같다.

- search result는 stable semantic identity를 가져야 한다.
- search result는 raw DB row가 아니라 public display contract로 소비되어야 한다.
- search ranking과 SQL implementation은 search UX authority가 아니라 repository/data 또는 implementation boundary다.
- search result display는 repository가 확정한 final materialized result를 사용해야 한다.
- Strong exact search와 general search는 repository public contract 기준으로 결과를 반환해야 한다.

Search read boundary는 graph traversal, navigation continuity, responsive placement를 정의하지 않는다.

## 13. Graph Read Boundary

Graph authority는 graph traversal semantics, relation direction semantics, expansion philosophy를 정의한다. Graph read boundary는 repository가 graph surface에 필요한 relation data와 word display data를 어떻게 공급하는지 정의한다.

Graph read boundary의 원칙은 다음과 같다.

- graph는 repository가 확정한 relation edge와 word display contract를 소비한다.
- graph surface는 `WORD_RELATION` storage를 직접 해석하지 않는다.
- relation lookup materialization은 repository responsibility다.
- relation status read는 원시 `status_code`를 보존하면서 `RELATION_STATUS`의 label과 description을 repository에서 materialize한다.
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

- 신규 word history snapshot은 word core와 normalized expression rows를 보존하며 18개 legacy expression key를 포함하지 않는다.
- 신규 history row는 normalized snapshot으로 복원한다.
- normalized expression payload가 없는 older history row는 legacy key를 canonical expression 복원 입력으로 해석한다.
- 신규·구형 history의 legacy expression key는 `WORD_TABLE` core insert/update DML에서 제외한다.
- history snapshot은 UI state persistence가 아니라 data mutation rollback/persistence boundary다.

Word/relation history 경계는 다음과 같다.

- word history snapshot은 `WORD_TABLE.관련1~7`을 저장하지 않는다.
- 과거 word snapshot에 `관련1~7` key가 있어도 `WORD_TABLE` update/insert undo payload에서는 무시한다.
- 현재 relation 저장·조회와 relation history/undo authority는 `WORD_RELATION`이다.
- relation create/update는 같은 transaction에서 비어 있지 않은 `RELATION_STATUS.code`를 검증하고 `status_code`를 명시적으로 저장한다.
- relation history의 before/after snapshot은 `status_code`를 정확히 보존하며, status-only update도 일반 relation update와 같은 undo 대상으로 복원한다.
- `관련1~7` 물리 컬럼은 제거됐으며, 미대응 raw 값만 `WORD_LEGACY_RELATED_VALUE`에 비권위적으로 격리한다.
- repository와 history/undo는 `WORD_LEGACY_RELATED_VALUE`를 읽거나 관계 authority로 사용하지 않는다.

History는 다음을 직접 정의하지 않는다.

- navigation history UX
- selected state restoration policy
- tooltip display behavior
- screen flow

Snapshot / history persistence는 canonical write authority, 구형 payload decode 호환, rollback 가능성을 함께 보존해야 한다.

## 15. Verification / Comparison 기준

Repository/data verification은 raw DB row 차이가 아니라 final public contract와 canonical read result 기준으로 판단한다.

Verification 원칙은 다음과 같다.

- source별 raw row 차이는 최종 판정 기준이 아니다.
- repository final result의 user-visible equivalence를 확인한다.
- retained debug/verification context에서는 fallback 발생 여부와 fallback reason을 기록한다.
- 해당 context의 collector observation을 확인한다.
- create/update 이후 canonical expression만 갱신되고 `WORD_TABLE`에 18개 expression slot이 다시 생기지 않는지 확인한다.
- 신규 history에 normalized expression rows가 있고 legacy key가 없는지, 구형 history는 canonical 복원되면서 legacy key가 core DML에 전달되지 않는지 확인한다.
- 18개 표현 컬럼 없는 현행 canonical-only schema에서 active read와 create/update/delete/undo가 동작하는지 확인한다.
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
4. 현행 `WORD_TABLE`에는 expression slot이 없다.
5. Active production expression read authority는 `word_expression_set`의 `NORMALIZED_ONLY` 경계다.
6. Production canonical-only 상태를 generic/debug resolver와 policy override 제거 완료로 확대 해석하지 않는다.
7. Full-legacy startup·restore 입력과 구형 history decode는 retained compatibility이며 live legacy read/write 또는 production fallback이 아니다.
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

현재 expression read/write/history authority는 active production runtime에서 `word_expression_set`이다. `WORD_TABLE`의 18개 expression slot은 물리 제거됐다.

현재 active production owner-specific read context는 모두 `NORMALIZED_ONLY`이며, legacy expression SQL projection과 eager legacy adapter 실행을 하지 않는다. `_defaultReadSourcePolicy`의 `LEGACY`, `NORMALIZED_WITH_FALLBACK` 처리 분기와 `legacyReadResult` 구성은 generic/debug 호환·비교·검증 능력을 위해 유지되지만 활성 production legacy read/fallback context는 아니다. Full-legacy startup·restore 입력과 구형 history decode도 retained compatibility 경계로만 남는다.

Controlled zone은 normalized read 확대를 owner-specific display contract, fallback observation, collector 해석 가능성 안에서 제한하기 위한 governance다.

Future repository/data change는 source selection, public contract, retained compatibility boundary, fallback observation, history persistence, verification 기준이 이 문서의 boundary를 강화하는지 약화하는지 기준으로 판단해야 한다.
