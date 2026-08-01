# Data Structure Policy

> 문서 분류: 현행 data structure policy
>
> 이 문서는 canonical storage, compatibility projection, repository/UI contract의 현재 정책 경계를 정의한다. 전체 DB의 실제 schema authority는 [SCHEMA](SCHEMA.md)다.
>
> 외부 원천, 저작권·라이선스 경계와 provenance 정책은 [데이터 출처와 재배포 경계](DATA_PROVENANCE.md)를 따른다.

## 1. 문서 목적

이 문서는 Reshet 프로젝트의 데이터 구조 개선 범위, 현재 상태, 목표 상태, 완료 조건을 정의한다.

이 문서는 구현 지시서가 아니라 구조 정책 문서다.

## 2. 문서 범위

- word core / expression / meaning / relation 저장 구조
- repository read boundary
- UI contract boundary
- import/export 책임 경계
- 데이터 구조 개선 완료 기준

## 3. 문서 비범위

- DB 구조 변경안
- 코드 수정안
- 새로운 기능 구현
- import/export 기능 추가
- relation 구조 변경안
- 새로운 public contract 추가

## 4. 구조 계층 구분

### 4.1 DB storage

- DB storage는 canonical persisted data를 저장하는 계층이다.
- 이 계층은 외부 입출력 포맷이 아니라 내부 canonical structure를 기준으로 유지한다.

### 4.2 Repository read model

- repository는 read source 선택, fallback 판정, lookup 해석, row materialization을 담당한다.
- UI는 repository가 확정한 결과만 사용한다.

### 4.3 UI contract

- UI contract는 표시와 탐색에 필요한 typed/public boundary다.
- UI는 DB row나 fallback 정책을 직접 해석하지 않는다.

## 5. 현재 상태

### 5.1 WORD_TABLE

- `WORD_TABLE`은 현재 word core 1:1 row 저장소다.
- expression slot(`표기1~6`, `음역1~6`, `발음1~6`)은 legacy 호환 컬럼으로 물리 schema에 남아 있다.
- meaning slot(`의미1~7`)은 2026-07-29 production migration에서 `WORD_TABLE`의 live 물리 schema에서 제거됐다.
- relation slot(`관련1~7`)은 2026-07-29 production migration에서 물리 제거됐다.
- generic/default legacy read 경계는 아직 legacy expression slot에 의존하지만, active owner-specific `NORMALIZED_ONLY` read는 SQL로 해당 컬럼을 조회하지 않는다.
- expression create/update는 `word_expression_set`만 갱신한다. create는 물리 expression slot을 채우지 않고 update는 기존 값을 변경하거나 비우지 않는다.
- live `WORD_TABLE`에는 meaning slot이 없으며 meaning read/write와 새 history의 유일한 authority는 `word_meaning_set`이다.

#### 5.1.1 legacy meaning / word_meaning_set migration boundary

- 현재 normal runtime의 meaning read/write 및 새 history authority는 `word_meaning_set`이다.
- 2026-07-29 기준 work·seed DB는 `word_meaning_set` table과 `ux_word_meaning_set_word_seq` index를 포함하며 `WORD_TABLE.의미1~7`은 물리적으로 제거된 상태다.
- runtime ensure는 canonical table/index를 먼저 보장한 뒤 legacy meaning 컬럼 7개가 모두 있으면 한 transaction에서 canonical 보존을 검증하고 컬럼을 제거한다. 컬럼이 모두 없는 현행 schema는 no-op한다.
- full legacy DB에서 canonical table이 없거나 비어 있으면 raw 값이 존재하는 `의미N`을 문자열 수정 없이 `word_meaning_set.seq=N`으로 materialize한다. `ROW_NUMBER()` 재번호 부여, hole 재압축, 순서 변경, trim, 중복 제거, 문자열 수정, 의미 병합/분할, 중요도 재판단은 하지 않는다. 예를 들어 `G2367_0000`의 `의미1`과 `의미7`은 `seq=1`, `seq=7`로 보존하며 `seq=2`로 당기지 않는다.
- expression set의 `seq`는 표기/음역/발음 묶음의 안정적 대응 순서이고 대표성은 `is_representative`로 판단한다. meaning set의 `seq`는 기존 `의미1~7`의 우선순위와 표시 순서를 보존하므로 expression migration의 compact/reindex 전략을 재사용하지 않는다.
- `word_meaning_set.seq`는 `seq >= 1`을 유지하며 `seq <= 7` 상한을 두지 않는다. `seq>7` canonical meaning은 허용되며 legacy slot에 맞추기 위해 절단하지 않는다.
- full legacy DB에 canonical row가 이미 있으면 모든 non-empty legacy 셀이 같은 `(word_id, seq, meaning)` canonical row로 보존돼야 한다. canonical 전용 row와 `seq>7` row는 그대로 보존하며, 일부 legacy 컬럼만 있는 schema나 legacy/canonical 충돌은 fail-closed한다.
- detail, edit 재진입, home search, graph primary label, graph relation-add search, 새 history/undo는 `word_meaning_set`을 meaning authority로 사용한다.
- normalized meaning payload가 없는 legacy-only 구형 history snapshot은 `의미1~7`을 canonical `word_meaning_set` 복원 입력으로만 해석한다. 해당 key는 `WORD_TABLE` undo insert/update payload에서 항상 제외한다.
- live meaning fallback, dual-write, legacy slot 확장은 다시 도입하지 않는다. 전체 검색 ranking 재설계는 이번 전환 범위 밖이다.
- 초기 migration은 기존 DB raw slot을 보존한다. 현재 UI edit/write는 의미 입력을 list로 다루며 trim/빈 값 제거 후 저장할 수 있으므로, 사용자가 edit 후 저장하면 기존 hole이 compact될 수 있다. slot-aware 편집 UX나 hole 보존 편집 의미론은 현재 전환 경계의 목표가 아니며 별도 UX/쓰기 정책 phase에서 다룬다.
- Phase 31-B 시점 실제 DB에는 공백 전용 meaning이 0건이었지만, 향후 발견되는 공백 전용 raw value를 initial migration에서 임의 trim/삭제하지 않는다. 일반 UI write는 기존 입력 의미론에 따라 trim/빈 값 제거를 유지할 수 있다. schema 제약 검토에서는 trim 기반 CHECK(`TRIM(meaning) <> ''`)가 raw 보존 원칙과 충돌할 수 있으므로 피하고, 최소 제약은 `TEXT NOT NULL`과 필요 시 `meaning <> ''` 수준으로 검토한다.
- 새 history snapshot은 canonical normalized meaning rows를 포함한다. 구형 legacy-only snapshot fallback은 호환 목적으로만 유지한다.

### 5.2 word_expression_set

- `word_expression_set`는 expression을 정규화된 row 구조로 저장하는 테이블이다.
- 현재 상태에서 `word_expression_set`는 이미 존재하는 persisted normalized table이다.
- 현재 normal runtime의 expression read/history authority는 `word_expression_set`이다.
- 현재 write는 canonical expression set을 normalized row로만 저장하며 `WORD_TABLE` expression slot로 dual-write하지 않는다.
- 신규 word history는 normalized expression rows를 저장하고 18개 legacy expression key를 포함하지 않는다.
- legacy `표기1~6`·`음역1~6`·`발음1~6`은 물리 schema와 generic/startup·backup·restore 호환 경계에 남아 있지만 canonical authority가 아니다.
- `seq>6` canonical expression set은 `word_expression_set`에 저장·조회되며 legacy slot에 맞추어 잘리지 않는다.
- primary expression은 `is_representative=1` row를 우선하고, representative row가 없으면 가장 낮은 `seq` row를 fallback으로 사용한다.
- normalized expression payload가 없는 구형 legacy-only history snapshot의 18개 key decoder는 canonical 복원 입력으로 유지한다. 해당 key는 undo의 `WORD_TABLE` core DML에는 전달하지 않는다.
- normal runtime projection 중단은 완료됐지만 legacy expression 컬럼의 물리 삭제와 startup·backup·restore 전환, `표기7` 등 legacy slot 확장은 이번 범위 밖이다.

### 5.3 WORD_RELATION / lookup

- `WORD_RELATION`은 현재 relation edge의 runtime storage다.
- `RELATION_CATEGORY`, `RELATION_TYPE`는 runtime lookup으로 사용된다.
- `RELATION_STATUS` lookup table도 존재한다.
- `RELATION_STATUS.inferred`는 seed baseline에 포함되며, runtime lookup 보정 경로에서도 기존/과거 DB 안전망으로 보장된다.
- `inferred`의 사용자 표시 label은 `기존 데이터 기반`이다.
- `inferred`는 기존 데이터와 기존 처리 경로에서 보존된 관계 상태이며, 관계 유형·방향·근거가 현재 기준에서 독립적으로 확정·검증되었음을 뜻하지 않는다.
- 이 보정은 relation 데이터 재작성이나 `WORD_RELATION.status_code` FK 추가를 포함하지 않는다.
- `WORD_LEGACY_RELATED_VALUE`는 기존 `WORD_RELATION`에 대응되지 않은 legacy raw 값만 보관하는 비권위적 격리소다. runtime repository/model/API와 history/undo는 이 테이블을 소비하지 않는다.

### 5.4 Phase 41-B canonical boundary 기록

이 section은 Phase 41-A 감사에서 이미 확인된 현재 경계만 기록한다. 새 설계, migration 계획, legacy 제거 일정, relation status 해결안은 포함하지 않는다.

#### 5.4.1 현재 canonical read/write authority

| 영역 | 현재 canonical read/write authority | compatibility projection 및 fallback 경계 |
| --- | --- | --- |
| expression | active owner-specific read/write/history의 `word_expression_set` | generic/default legacy read와 debug fallback, 구형 history decoder는 호환 경계로 유지하며 18개 물리 컬럼 제거는 후속이다. |
| meaning | `word_meaning_set` | live `WORD_TABLE.의미1~7`은 제거됐다. full legacy startup·restore 입력과 구형 history payload decode만 호환 경계로 유지한다. |
| relation | `WORD_RELATION` | `RELATION_STATUS.inferred` lookup은 seed baseline과 runtime 보정 안전망에 포함되며, relation 데이터 재작성과 FK 추가는 별도 판단 대상이다. |

#### 5.4.2 meaning materialization 경계

- meaning 표시 목록은 `word_meaning_set` row를 `seq ASC, id ASC` 순서로 materialize한다.
- 표시 materialization에서는 trim 후 빈 값이 되는 meaning을 제외한다.
- 대표 meaning은 materialized 표시 목록의 첫 번째 값이다.
- live `WORD_TABLE.의미1~7`은 물리 제거됐고 canonical authority나 live fallback으로 사용하지 않는다. full legacy startup·restore 입력과 legacy history decode만 compatibility 경계로 해석한다.
- 2026-07-29 제거 전 검증에서 work DB의 legacy non-empty meaning과 `word_meaning_set`은 각각 18,193건, seed DB는 각각 18,188건이며 양쪽 모두 missing/extra 0으로 일치했다. 제거 후 canonical row 수와 내용은 불변이다.
- work DB에 유입됐던 앞선 확인 fixture 단어 4행과 직접 종속 `word_expression_set` 5행은 제거됐다. 2026-08-01 추가로 확정한 expression 테스트 fixture parent 2행과 직접 종속 `word_expression_set` 1행·`word_meaning_set` 1행도 제거했으며 seed DB는 변경하지 않았다.

#### 5.4.3 seed/work DB와 runtime ensure 경계

- 2026-07-29 기준 seed DB와 work DB 모두 meaning 물리 컬럼 없이 `word_meaning_set` canonical baseline을 포함한다.
- 앱은 work DB가 있으면 work DB를 열고, 없을 때만 seed를 복사한다.
- runtime ensure 경로는 기존 work DB나 과거 seed 상태가 full legacy이면 canonical을 생성·검증한 뒤 meaning 컬럼을 제거하고, 현행 schema이면 no-op하는 안전망으로 유지한다.
- 2026-07-29 meaning 전환은 meaning 물리 컬럼 제거와 startup·restore 호환 전환을 포함한다. expression의 active runtime 분리 이후에도 generic legacy read, 구형 history decoder, expression 물리 컬럼과 startup·backup·restore 호환은 남아 있다.

#### 5.4.4 history와 relation status 경계

- `CHANGE_HISTORY`는 현재 데이터 조회 authority가 아니라 undo/restore용 snapshot 저장소다.
- `status_code='inferred'` relation 데이터는 `RELATION_STATUS.inferred` lookup 보정과 함께 해석할 수 있다.
- 이 보정은 relation 데이터 snapshot 재작성, history restore 정책 변경, relation provenance 모델 도입을 뜻하지 않는다.
- 현재 relation의 canonical authority가 `WORD_RELATION`이라는 경계는 유지한다.

#### 5.4.5 이번 기록이 확정하지 않는 사항

- 현재 상태는 active owner-specific expression runtime의 물리 컬럼 분리를 의미하지만 repository 전체 normalized-only 완료나 남은 expression legacy column의 물리적 제거 가능 확정을 의미하지 않는다.
- meaning 물리 컬럼은 제거됐지만 full legacy startup·restore staging migration과 구형 history decode 호환 경계는 유지한다.
- expression fallback 축소, relation 데이터 재작성, graph dynamics, node level, dark mode는 이번 범위에 포함하지 않는다.

#### 5.4.6 canonical read/write closure guard 경계

- 사용자 기능용 detail, home/search, graph single/center/batch, explorer/split view, edit seed, save 후 재조회, undo 후 재조회는 expression `word_expression_set`, meaning `word_meaning_set` 기준의 canonical read contract를 사용한다.
- generic/raw helper의 legacy 기본 정책은 raw compatibility 경계로 유지할 수 있다. 이 경계는 사용자 기능용 canonical display/read의 근거가 아니다.
- 신규 expression write는 `word_expression_set`만 갱신하며 `WORD_TABLE` expression slot을 생성·갱신·비움 처리하지 않는다.
- 신규 meaning write는 `word_meaning_set`만 갱신한다. live `WORD_TABLE`에는 `의미1~7`이 없으며 해당 key는 create/update payload와 새 history snapshot 및 undo의 `WORD_TABLE` DML payload에서 제외한다.
- 새 `CHANGE_HISTORY` word snapshot은 normalized expression/meaning row를 포함하고 legacy expression/meaning key를 포함하지 않으며, restore는 해당 normalized payload를 우선한다.
- normalized expression payload가 없는 과거 history snapshot은 legacy expression key를 canonical 복원 입력으로만 사용하고 `WORD_TABLE` core DML에서는 제외한다.
- normalized meaning payload가 없는 과거 history snapshot은 legacy meaning slot을 canonical meaning 복원 입력으로만 사용한다.
- Phase 41-B closure guard의 당시 완료 기준은 legacy slot 물리 삭제가 아니었다. meaning slot은 2026-07-29 후속 production/data 전환에서 제거됐고, expression normal runtime projection은 중단됐지만 물리 삭제와 startup·backup·restore 전환 및 과거 history 재작성은 별도 판단 대상으로 남는다.

## 6. 목표 상태

### 6.1 canonical normalized target

- word core: `WORD_TABLE`
- expression: `word_expression_set`
- meaning: `word_meaning_set`
- relation edge: `WORD_RELATION`
- relation lookup: `RELATION_CATEGORY`, `RELATION_TYPE`, `RELATION_STATUS`

### 6.2 authority target

- expression authority는 `WORD_TABLE` expression slot에서 `word_expression_set`로 이동한다.
- meaning authority는 legacy `WORD_TABLE.의미1~7`에서 `word_meaning_set`로 전환 완료됐다.
- relation 해석은 `WORD_RELATION + aligned lookup` 조합으로 일관되게 가능해야 한다.
- UI는 저장 구조가 아니라 repository materialization 결과를 소비한다.

### 6.3 정규화 authority 전환 원칙

- 정규화의 목적은 단순한 테이블 분리가 아니라 `...1~7`처럼 번호로 고정된 slot column이 데이터 개수의 상한이 되지 않게 하는 것이다.
- 반복 데이터는 성격에 맞는 구조로 관리한다.
- 향후 8개 이상의 표현, 의미, 관련 관계가 생겨도 데이터가 절단, 은닉, 임의 누락되지 않아야 한다.
- 표기, 음역, 발음은 서로 대응하는 한 묶음이므로 `word_expression_set` 한 행으로 함께 다룬다.
- 의미는 서로 독립된 목록이므로 `word_meaning_set`의 개별 행으로 다룬다.
- 관련은 단어와 단어 사이의 관계이므로 `WORD_RELATION`이 최종 authority다.
- 남아 있는 expression legacy 번호 slot은 장기 canonical authority나 active runtime projection이 아니라 전환 기간의 호환 컬럼이다.
- meaning legacy 번호 slot은 live schema에서 제거됐으며 full legacy startup·restore 입력과 legacy history decode에서만 해석한다.
- 남은 expression legacy column 제거와 startup·backup·restore 호환 전환 또는 meaning legacy 입력 지원 종료 여부는 별도 production phase에서 결정한다.
- 새 기능은 legacy 번호 slot의 개수를 늘려 문제를 해결하지 않는다.

## 7. canonical / non-canonical 분류

### 7.1 현재 canonical storage

- `WORD_TABLE`의 word core field
- `WORD_RELATION`
- `RELATION_CATEGORY`
- `RELATION_TYPE`

### 7.2 canonical target

- `word_expression_set`
- `word_meaning_set`
- 정합성이 확보된 `RELATION_STATUS`

### 7.3 보조 / 파생 / 호환 구조

- `WORD_TABLE` expression slot
- 구형 startup·restore 입력과 history payload의 meaning key decoder
- `WORD_LEGACY_RELATED_VALUE`
- `CHANGE_HISTORY`
- `RMAC_TABLE`
- `RMAC_TABLE_KR`

## 8. WORD_TABLE 장기 역할 정책

### 8.1 word core

- `WORD_TABLE`은 장기적으로 word core 1:1 저장소 역할에 집중한다.

### 8.2 expression slot

- 현재 expression slot은 canonical write authority나 active runtime projection이 아닌 legacy 호환 컬럼이다.
- expression slot은 generic legacy read와 startup·backup·restore 호환을 위해 물리적으로 유지되지만, 장기 canonical authority로 유지하지 않는다.
- 이후 expression slot의 물리 제거와 호환 계약 전환은 별도 production 단계에서 검토한다.

### 8.3 relation slot

- `관련1~7`은 `WORD_TABLE`에서 물리 제거됐다.
- 현재 relation runtime authority는 `WORD_RELATION`이다.
- 승인된 정확한 5개 셀과 기존 `WORD_RELATION`에 양방향 endpoint pair로 대응되는 값은 archive하지 않는다.
- 나머지 미대응 non-null raw 값만 `WORD_LEGACY_RELATED_VALUE`에 source ID·원본 slot·target 원문 그대로 보존한다.
- archive는 relation metadata나 semantic direction을 추론하지 않는 비권위적 격리소이며 runtime에서 소비하지 않는다.

### 8.4 meaning slot

- `word_meaning_set`은 normal runtime의 meaning read/write 및 새 history authority다.
- live `WORD_TABLE.의미1~7`은 2026-07-29 work·seed DB에서 물리 제거됐다.
- runtime ensure는 full legacy 7개 컬럼을 canonical로 materialize 또는 대조한 뒤 제거하고, 현행 schema에서는 no-op한다. partial schema와 canonical 충돌은 fail-closed한다.
- restore 원본은 read-only로 사전검증하고, full legacy migration은 앱 소유 staging copy에서만 수행한다.
- normalized meaning payload가 없는 구형 history는 legacy meaning key를 `word_meaning_set` 복원 입력으로만 해석한다.
- `seq>7` canonical meaning은 `word_meaning_set`에 저장·조회되며 legacy slot에 맞추어 잘리지 않는다.

## 9. word_expression_set 정책

### 9.1 현재 상태

- 현재 `word_expression_set`는 persisted normalized expression table이다.
- 현재 normal runtime의 expression read/history authority는 `word_expression_set`이다.
- 현재 `WORD_TABLE` expression slot은 active runtime에서 조회·갱신하지 않는 legacy 호환 컬럼으로 물리 유지된다.
- legacy-only 구형 history snapshot처럼 normalized expression payload가 없는 경우에는 `표기1~6`·`음역1~6`·`발음1~6`을 canonical 복원 입력으로만 해석한다.

### 9.2 목표 상태

- `word_expression_set`는 normal runtime의 expression canonical write/read/history target이다.
- expression set의 순서는 `seq ASC`이며, 표기·음역·발음은 동일 `seq`의 대응 묶음으로 보존한다.
- `seq>6` canonical row는 보존하며 legacy slot 수에 맞추기 위해 절단하지 않는다.
- normal runtime projection은 중단됐고 legacy slot의 물리 삭제 및 startup·backup·restore 호환 전환은 별도 phase에서 판단한다.

## 10. relation 정합성 정책

### 10.1 현재 상태

- relation runtime authority는 `WORD_RELATION`이다.
- `RELATION_CATEGORY`, `RELATION_TYPE`, `RELATION_STATUS` lookup code set과 실제 relation data code set은 정합하다.
- `WORD_RELATION.word_id_1`, `word_id_2`의 dangling endpoint는 0건이다.
- repository의 relation read/write/delete/undo/restore 경계는 `WORD_RELATION`과 동일한 relation contract를 사용한다.
- `WORD_TABLE.관련1~7`은 물리 제거됐고 `WORD_LEGACY_RELATED_VALUE`도 runtime relation authority가 아니다.
- `RELATION_STATUS.inferred`는 seed baseline에 포함되며, runtime lookup 보정 경로에서도 기존/과거 DB 안전망으로 보장된다.
- 실제 relation data의 `status_code` 값은 보존되며, 이 문서는 relation data 재작성 완료나 FK 추가 완료를 선언하지 않는다.

### 10.2 구조적 의미

- 현재 runtime relation authority와 lookup/data code, endpoint, repository/history 경계의 정합성은 확인됐다.
- legacy `관련1~7`의 물리 제거와 미대응 raw 값 격리는 완료됐다.
- 이는 relation provenance 재설계, FK 추가, `unknown` direction 데이터 전수 판정, 과거 history 재작성 완료를 뜻하지 않는다.

### 10.3 현재 작업 경계

- `WORD_RELATION`은 현재 relation의 runtime authority다.
- `WORD_LEGACY_RELATED_VALUE`는 미대응 legacy 원문만 보관하며 relation schema·data와 연결하지 않는다.
- relation data 재작성과 provenance/FK 정책 결정은 완료된 legacy slot 제거와 별개다.

## 11. import/export 원칙

- import/export는 DB 계층 책임이 아니다.
- import는 외부 형식을 canonical payload로 변환하는 adapter/boundary 책임이다.
- export는 canonical stored entity를 외부 형식으로 투영하는 adapter/boundary 책임이다.
- DB 내부에는 canonical normalized storage만 authority로 남아야 한다.

### 11.1 backup/restore 경계

- import/export는 canonical payload와 외부 교환 형식 사이를 변환하는 adapter 책임이다.
- backup/restore는 현재 work DB 전체를 단일 SQLite snapshot으로 보존하거나 교체하는 별도 계약이다.
- 두 기능은 데이터 단위, 검증 기준, 사용자 위험이 다르므로 같은 책임으로 합치지 않는다.
- 현재 backup은 열린 work DB에서 `VACUUM INTO`로 생성한 전체 SQLite snapshot이며, restore는 현재 Reshet 복원 호환성 계약을 충족하는 전체 SQLite DB로 work DB를 교체한다.
- 복원 원본은 read-only로만 검증한다. runtime ensure와 schema 보정은 앱 data directory에 stream copy한 staging 파일에만 적용하며 외부 원본을 수정하지 않는다.
- full legacy `관련1~7` backup은 staging migration 후 허용하고, legacy 컬럼 없이 유효한 archive가 있는 backup은 현행 상태로 허용한다. partial, neither, archive 손상·원본 충돌은 fail-closed한다.
- meaning은 `의미1~7`이 모두 있는 full legacy backup과 컬럼 없이 유효한 `word_meaning_set`이 있는 현행 backup을 허용한다. full legacy에서 canonical table이 없거나 비어 있으면 staging에서 raw slot을 정확한 `seq`로 materialize하고, canonical row가 이미 있으면 모든 non-empty legacy 셀의 정확한 보존을 요구한다.
- meaning legacy 컬럼이 일부만 있거나 legacy/canonical이 충돌하거나 legacy 컬럼과 canonical table이 모두 없으면 교체 전에 fail-closed한다.
- 복원 호환성은 SQLite integrity와 현재 필수 table·column·PK·unique index 및 대표 read로 판단한다. 실제 백업 메뉴 생성 여부나 사용자의 수동 변경 여부를 증명하는 계약은 아니다.
- `RMAC_TABLE`, `RMAC_TABLE_KR`은 runtime canonical authority는 아니지만 전체 백업 보존 대상이므로 복원 후보에 존재해야 하며 그대로 교체·보존한다.
- live DB 교체 전 `VACUUM INTO` rollback snapshot을 만들고, 교체 후 검증 실패 시 previous work 또는 rollback snapshot으로 기존 DB를 복구한다.
- 새 DB open·runtime ensure·integrity/schema·대표 read 이후 cleanup 또는 화면 갱신 실패는 DB 성공을 뒤집지 않는다.
- Windows와 Android를 현재 지원하며 Linux runtime은 후속 Production phase에서 별도로 검증한다.
- SharedPreferences와 검색·탐색·graph session state는 SQLite backup/restore 대상이 아니다.

### 11.2 DB 계층이 책임지지 않아야 하는 이유

- 외부 포맷 변화가 DB authority를 흔들면 안 된다.
- 비정규화 포맷을 DB authority로 두면 source of truth가 둘 이상 생긴다.
- import/export는 호환과 전달의 문제이며 저장 authority 문제와 분리되어야 한다.

## 12. 데이터 구조 개선 완료 조건

다음 조건을 모두 만족할 때 데이터 구조 개선 완료를 선언한다.

- `WORD_TABLE`의 장기 역할이 word core 중심으로 확정됨
- expression authority가 `word_expression_set` 기준으로 전환됨
- meaning authority가 `word_meaning_set` 기준으로 전환됨
- legacy expression slot이 authority에서 제외됨
- legacy meaning slot이 authority에서 제외됨
- relation lookup과 실제 data code set이 정합함
- relation read boundary가 raw/internal과 typed/public으로 명확히 분리됨
- import/export 경계가 DB 밖의 adapter/boundary 책임으로 고정됨
- verify 기록과 수동 검증으로 안정성이 확인됨

## 13. phase 구조

### 13.1 선행 phase

- expression normalization 검토
- migration SQL
- semantic compare 기준
- dual-sync write
- read source policy
- normalized read adapter
- fallback 관측
- controlled read boundary
- typed public boundary
- detail-like contract 안정화

### 13.2 후속 phase

- `WORD_TABLE` 역할 확정
- expression authority transition
- meaning full-legacy startup/restore 입력 지원 종료 여부
- legacy slot 축소 또는 제거 정책 확정

### 13.3 병렬 가능성

- import/export boundary 정책 정리와 relation 설계 검토는 병렬 검토 가능하다.
- expression authority transition 완료 선언은 `WORD_TABLE` 역할 확정 이후에 판단한다.

## 14. 절대 금지 사항

- DB 구조 변경
- 코드 수정
- 새로운 기능 구현
- import/export 기능 추가
- relation 구조 변경
- contract 추가

## 15. 검증 방식

CodeX 수행 기준:

- 코드 grep / 호출 경로 확인
- DB schema 조회
- 실제 data 확인
- 문서 대조
- analyzer 가능 여부 확인

검증 기록에는 반드시 다음을 포함한다.

- 확인한 코드 위치
- 실행한 명령어 또는 SQL
- 결과 요약
- 확인된 사실 vs 해석/판단 분리
