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
- 현재 앱의 일부 read/write 경로는 아직 이 legacy slot에 의존한다.

### 5.2 word_expression_set

- `word_expression_set`는 expression을 정규화된 row 구조로 저장하는 테이블이다.
- 현재 상태에서 `word_expression_set`는 이미 존재하는 persisted normalized table이다.
- 그러나 현재 write authority는 `word_expression_set`가 아니라 `WORD_TABLE` expression slot이다.
- 현재 write는 `WORD_TABLE`에 먼저 반영한 뒤 `word_expression_set`를 sync하는 dual-sync 구조다.
- 현재 read source는 전역 단일 전환 상태가 아니라 `LEGACY` 기본 위에 일부 context만 `NORMALIZED_WITH_FALLBACK`으로 승격된 hybrid 상태다.
- 따라서 현재 `word_expression_set`를 expression canonical authority 완료 상태로 선언하지 않는다.

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
- relation edge: `WORD_RELATION`
- relation lookup: `RELATION_CATEGORY`, `RELATION_TYPE`, `RELATION_STATUS`

### 6.2 authority target

- expression authority는 `WORD_TABLE` expression slot에서 `word_expression_set`로 이동한다.
- relation 해석은 `WORD_RELATION + aligned lookup` 조합으로 일관되게 가능해야 한다.
- UI는 저장 구조가 아니라 repository materialization 결과를 소비한다.

## 7. canonical / non-canonical 분류

### 7.1 현재 canonical storage

- `WORD_TABLE`의 word core field
- `WORD_RELATION`
- `RELATION_CATEGORY`
- `RELATION_TYPE`

### 7.2 canonical target

- `word_expression_set`
- 정합성이 확보된 `RELATION_STATUS`

### 7.3 보조 / 파생 / 호환 구조

- `WORD_TABLE` expression slot
- `WORD_TABLE` relation slot
- `CHANGE_HISTORY`
- `RMAC_TABLE`
- `RMAC_TABLE_KR`

## 8. WORD_TABLE 장기 역할 정책

### 8.1 word core

- `WORD_TABLE`은 장기적으로 word core 1:1 저장소 역할에 집중한다.

### 8.2 expression slot

- 현재 expression slot은 write authority다.
- 목표 상태에서 expression slot은 authority에서 제외한다.
- 이후 expression slot은 legacy / compatibility projection으로만 남기거나 제거 대상으로 검토한다.
- expression slot을 장기 canonical authority로 유지하지 않는다.

### 8.3 relation slot

- `관련1~7`은 현재 runtime relation authority로 사용하지 않는다.
- 현재 relation runtime authority는 `WORD_RELATION`이다.
- 따라서 relation slot은 장기적으로 canonical relation storage로 유지하지 않는다.
- 필요 시 legacy / compatibility projection으로만 남기거나 제거 대상으로 검토한다.

## 9. word_expression_set 정책

### 9.1 현재 상태

- 현재 `word_expression_set`는 persisted normalized sync table이다.
- 현재 write authority는 `WORD_TABLE` expression slot이다.
- 현재 read는 legacy 기본 + controlled normalized fallback 구조다.

### 9.2 목표 상태

- `word_expression_set`는 expression canonical storage가 된다.
- expression read/write authority는 repository 내부에서 `word_expression_set` 기준으로 확정된다.
- legacy slot은 authority에서 내려오고 projection 또는 제거 후보가 된다.

## 10. relation 정합성 정책

### 10.1 현재 상태

- 실제 relation data의 `status_code`와 `RELATION_STATUS` lookup membership가 일치하지 않는다.
- 이는 relation lookup 정합성이 아직 완료되지 않았음을 의미한다.

### 10.2 구조적 의미

- relation 구조는 아직 canonical lookup 완료 상태가 아니다.
- relation 구조 정합화 phase가 별도로 필요하다.
- 완료 선언 전에는 lookup code set, 실제 data code set, repository/runtime 해석이 서로 일치해야 한다.

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
- legacy expression slot이 authority에서 제외됨
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
