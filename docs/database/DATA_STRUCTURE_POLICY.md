# Data Structure Policy

## 1. 문서 목적

이 문서는 Reshet 프로젝트의 데이터 구조 개선 범위, 현재 상태, 목표 상태, 완료 조건을 정의한다.

이 문서는 구현 지시서가 아니라 구조 정책 문서다.

## 2. 문서 범위

- word core / expression / relation 저장 구조
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
- 동시에 expression slot(`표기1~6`, `음역1~6`, `발음1~6`)과 relation slot(`관련1~7`)도 함께 보유하고 있다.
- 현재 앱의 일부 read 경로는 아직 legacy expression slot에 의존한다.
- expression write 경로에서는 `WORD_TABLE` expression slot을 canonical authority가 아니라 compatibility projection으로 갱신한다.
- meaning slot(`의미1~7`)은 현재 meaning read 및 history restore authority로 남아 있다.

#### 5.1.1 meaning slot / word_meaning_set migration boundary

- 현재 meaning read 및 history restore authority는 legacy `WORD_TABLE.의미1~7`이다.
- `word_meaning_set`은 정상 runtime에서 `DatabaseService.openDatabaseFile()`의 DB open 직후 ensure/backfill되는 병행 저장/동기화 구조다.
- 따라서 source DB 파일에 `word_meaning_set` table이 없는 상태 자체는 migration 누락으로 단정하지 않는다.
- ensure/backfill에서는 raw 값이 존재하는 `의미N`을 문자열 수정 없이 `word_meaning_set.seq=N`으로 보존한다. `ROW_NUMBER()` 재번호 부여, hole 재압축, 순서 변경, trim, 중복 제거, 문자열 수정, 의미 병합/분할, 중요도 재판단은 하지 않는다. 예를 들어 `G2367_0000`의 `의미1`과 `의미7`은 `seq=1`, `seq=7`로 보존하며 `seq=2`로 당기지 않는다.
- expression set의 `seq`는 표기/음역/발음 묶음의 안정적 대응 순서이고 대표성은 `is_representative`로 판단한다. meaning set의 `seq`는 기존 `의미1~7`의 우선순위와 표시 순서를 보존하므로 expression migration의 compact/reindex 전략을 재사용하지 않는다.
- 현재 `word_meaning_set`은 final canonical read/history authority가 아니라 병행 저장/동기화 target이다. final canonical read/history authority로의 승격은 후속 phase다.
- 현재 전환 경계는 runtime ensure/backfill, legacy `의미1~7` to `seq=N` 보존, normalized row와 legacy projection의 동기화 검증으로 제한한다. detail/home search/graph read 전환, legacy read 기본값 제거, legacy column 삭제, meaning data repair, 검색 ranking 재설계는 제외한다.
- legacy projection을 유지하는 이유는 detail/search/graph와 history restore가 현재 legacy `의미1~7` projection을 읽고 있어 read/history path 전환 없이 독립 구현할 수 있기 때문이다.
- 초기 migration은 기존 DB raw slot을 보존한다. 현재 UI edit/write는 의미 입력을 list로 다루며 trim/빈 값 제거 후 저장할 수 있으므로, 사용자가 edit 후 저장하면 기존 hole이 compact될 수 있다. slot-aware 편집 UX나 hole 보존 편집 의미론은 현재 전환 경계의 목표가 아니며 별도 UX/쓰기 정책 phase에서 다룬다.
- Phase 31-B 시점 실제 DB에는 공백 전용 meaning이 0건이었지만, 향후 발견되는 공백 전용 raw value를 initial migration에서 임의 trim/삭제하지 않는다. 일반 UI write는 기존 입력 의미론에 따라 trim/빈 값 제거를 유지할 수 있다. schema 제약 검토에서는 trim 기반 CHECK(`TRIM(meaning) <> ''`)가 raw 보존 원칙과 충돌할 수 있으므로 피하고, 최소 제약은 `TEXT NOT NULL`과 필요 시 `meaning <> ''` 수준으로 검토한다.
- 현재 history/undo는 legacy `WORD_TABLE.의미1~7` snapshot 기반이다. undo/restore가 normalized rows와 legacy projection을 함께 동기화하더라도, normalized-only history format 전환은 별도 phase다.

### 5.2 word_expression_set

- `word_expression_set`는 expression을 정규화된 row 구조로 저장하는 테이블이다.
- 현재 상태에서 `word_expression_set`는 이미 존재하는 persisted normalized table이다.
- 현재 expression write authority는 repository 내부 canonical expression set과 `word_expression_set` write path를 우선한다.
- 현재 write는 canonical expression set을 normalized row로 저장한 뒤 `WORD_TABLE` expression slot을 compatibility projection으로 갱신하는 dual-write 구조다.
- 현재 read source는 전역 단일 전환 상태가 아니라 `LEGACY` 기본 위에 일부 context만 `NORMALIZED_WITH_FALLBACK`으로 승격된 hybrid 상태다.
- 따라서 현재 `word_expression_set`는 expression write 기준 canonical target이지만, expression read authority 완료 상태 또는 normalized-only 완료 상태로 선언하지 않는다.

### 5.3 WORD_RELATION / lookup

- `WORD_RELATION`은 현재 relation edge의 runtime storage다.
- `RELATION_CATEGORY`, `RELATION_TYPE`는 runtime lookup으로 사용된다.
- `RELATION_STATUS` lookup table도 존재한다.
- 그러나 현재 실제 데이터의 `WORD_RELATION.status_code` 값과 `RELATION_STATUS` lookup membership가 일치하지 않는다.
- 이 불일치가 남아 있는 동안 `RELATION_STATUS`는 canonical lookup 완료 상태로 선언할 수 없다.

## 6. 목표 상태

### 6.1 canonical normalized target

- word core: `WORD_TABLE`
- expression: `word_expression_set`
- meaning: `word_meaning_set`
- relation edge: `WORD_RELATION`
- relation lookup: `RELATION_CATEGORY`, `RELATION_TYPE`, `RELATION_STATUS`

### 6.2 authority target

- expression authority는 `WORD_TABLE` expression slot에서 `word_expression_set`로 이동한다.
- meaning authority는 legacy `WORD_TABLE.의미1~7`에서 `word_meaning_set`로 이동한다.
- relation 해석은 `WORD_RELATION + aligned lookup` 조합으로 일관되게 가능해야 한다.
- UI는 저장 구조가 아니라 repository materialization 결과를 소비한다.

### 6.3 정규화 authority 전환 원칙

- 정규화의 목적은 단순한 테이블 분리가 아니라 `...1~7`처럼 번호로 고정된 slot column이 데이터 개수의 상한이 되지 않게 하는 것이다.
- 반복 데이터는 성격에 맞는 구조로 관리한다.
- 향후 8개 이상의 표현, 의미, 관련 관계가 생겨도 데이터가 절단, 은닉, 임의 누락되지 않아야 한다.
- 표기, 음역, 발음은 서로 대응하는 한 묶음이므로 `word_expression_set` 한 행으로 함께 다룬다.
- 의미는 서로 독립된 목록이므로 `word_meaning_set`의 개별 행으로 다룬다.
- 관련은 단어와 단어 사이의 관계이므로 `WORD_RELATION`이 최종 authority다.
- legacy 번호 slot은 장기 canonical authority가 아니라 전환 기간의 compatibility projection이다.
- 이 원칙은 legacy column 즉시 삭제, read path 변경, history authority 변경을 뜻하지 않는다.
- legacy column 제거 또는 projection 중단은 상세, 편집, 검색, graph, history, undo, data migration이 모두 해당 normalized authority로 안전하게 전환된 뒤 별도 production phase에서 결정한다.
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
- `WORD_TABLE` meaning slot
- `WORD_TABLE` relation slot
- `CHANGE_HISTORY`
- `RMAC_TABLE`
- `RMAC_TABLE_KR`

## 8. WORD_TABLE 장기 역할 정책

### 8.1 word core

- `WORD_TABLE`은 장기적으로 word core 1:1 저장소 역할에 집중한다.

### 8.2 expression slot

- 현재 expression slot은 canonical write authority가 아니라 compatibility projection이다.
- expression slot은 legacy read 경로와 호환을 위해 유지되지만, 장기 canonical authority로 유지하지 않는다.
- 이후 expression slot은 compatibility projection으로만 남기거나 제거 대상으로 검토한다.

### 8.3 relation slot

- `관련1~7`은 현재 runtime relation authority로 사용하지 않는다.
- 현재 relation runtime authority는 `WORD_RELATION`이다.
- 따라서 relation slot은 장기적으로 canonical relation storage로 유지하지 않는다.
- 필요 시 legacy / compatibility projection으로만 남기거나 제거 대상으로 검토한다.

### 8.4 meaning slot

- `의미1~7`은 현재 meaning read 및 history restore authority다.
- 장기적으로는 `word_meaning_set`이 meaning canonical authority가 되어야 한다.
- 현재 `word_meaning_set`은 병행 저장/동기화 구조이며, normalized-only read/history authority 완료 상태로 선언하지 않는다.
- meaning slot 제거 또는 projection 중단은 read, history restore, undo, data migration 전환이 완료된 뒤 별도 production phase에서 검토한다.

## 9. word_expression_set 정책

### 9.1 현재 상태

- 현재 `word_expression_set`는 persisted normalized expression table이다.
- 현재 expression write authority는 repository 내부 canonical expression set / `word_expression_set` write path를 우선한다.
- 현재 `WORD_TABLE` expression slot은 legacy compatibility projection으로 유지된다.
- 현재 read는 legacy 기본 + controlled normalized fallback 구조다.

### 9.2 목표 상태

- write 기준에서 `word_expression_set`는 현재 expression canonical write target이다.
- read 기준에서는 아직 context별 hybrid 상태이며, normalized-only 완료 상태가 아니다.
- 목표 상태에서 expression read authority도 `word_expression_set` 기준으로 확정된다.
- legacy slot은 authority에서 내려온 compatibility projection이며, 이후 제거 후보가 된다.

## 10. relation 정합성 정책

### 10.1 현재 상태

- 실제 relation data의 `status_code`와 `RELATION_STATUS` lookup membership가 일치하지 않는다.
- 이는 relation lookup 정합성이 아직 완료되지 않았음을 의미한다.

### 10.2 구조적 의미

- relation 구조는 아직 canonical lookup 완료 상태가 아니다.
- relation 구조 정합화 phase가 별도로 필요하다.
- 완료 선언 전에는 lookup code set, 실제 data code set, repository/runtime 해석이 서로 일치해야 한다.

### 10.3 현재 작업 경계

- `WORD_RELATION`이 relation의 최종 authority라는 지향점은 유지한다.
- 이 문서는 relation schema, metadata, `관련1~7` projection, read/write/history 전환을 감사하거나 구현하지 않는다.
- 현재 relation의 세부 전환 상태는 기존에 검증된 사실만 유지하며 추측으로 보강하지 않는다.

## 11. import/export 원칙

- import/export는 DB 계층 책임이 아니다.
- import는 외부 형식을 canonical payload로 변환하는 adapter/boundary 책임이다.
- export는 canonical stored entity를 외부 형식으로 투영하는 adapter/boundary 책임이다.
- DB 내부에는 canonical normalized storage만 authority로 남아야 한다.

### 11.1 DB 계층이 책임지지 않아야 하는 이유

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
- meaning read/history authority transition
- relation lookup/data/contract 정합화
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
