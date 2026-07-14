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
- 동시에 expression slot(`표기1~6`, `음역1~6`, `발음1~6`)과 relation slot(`관련1~7`)도 함께 보유하고 있다.
- 현재 앱의 일부 read 경로는 아직 legacy expression slot에 의존한다.
- expression write 경로에서는 `WORD_TABLE` expression slot을 canonical authority가 아니라 compatibility projection으로 갱신한다.
- meaning slot(`의미1~7`)은 현재 canonical authority가 아니라 compatibility projection이다.

#### 5.1.1 meaning slot / word_meaning_set migration boundary

- 현재 normal runtime의 meaning read 및 history authority는 `word_meaning_set`이다.
- Phase 43-A 기준 private seed baseline은 `word_meaning_set` table과 `ux_word_meaning_set_word_seq` index를 물리적으로 포함한다.
- `word_meaning_set`은 정상 runtime에서 `DatabaseService.openDatabaseFile()`의 DB open 직후 ensure/backfill되며, canonical meaning row 저장소로 사용한다.
- 따라서 과거 work DB나 legacy source DB 파일에 `word_meaning_set` table이 없는 상태 자체는 migration 누락으로 단정하지 않고 runtime 안전망으로 보강한다.
- ensure/backfill에서는 raw 값이 존재하는 `의미N`을 문자열 수정 없이 `word_meaning_set.seq=N`으로 보존한다. `ROW_NUMBER()` 재번호 부여, hole 재압축, 순서 변경, trim, 중복 제거, 문자열 수정, 의미 병합/분할, 중요도 재판단은 하지 않는다. 예를 들어 `G2367_0000`의 `의미1`과 `의미7`은 `seq=1`, `seq=7`로 보존하며 `seq=2`로 당기지 않는다.
- expression set의 `seq`는 표기/음역/발음 묶음의 안정적 대응 순서이고 대표성은 `is_representative`로 판단한다. meaning set의 `seq`는 기존 `의미1~7`의 우선순위와 표시 순서를 보존하므로 expression migration의 compact/reindex 전략을 재사용하지 않는다.
- `word_meaning_set.seq`는 `seq >= 1`을 유지하며 `seq <= 7` 상한을 두지 않는다. `seq>7` canonical meaning은 허용되며 legacy slot에 맞추기 위해 절단하지 않는다.
- legacy `의미1~7`은 compatibility projection으로 유지한다. canonical row의 `seq=1~7`만 `의미1~7`에 대응하며 `seq>7`은 legacy column에 기록하지 않는다.
- detail, edit 재진입, home search, graph primary label, graph relation-add search, 새 history/undo는 `word_meaning_set`을 meaning authority로 사용한다.
- legacy-only 구형 history snapshot처럼 normalized meaning payload가 없는 경우에는 `의미1~7` fallback을 유지한다.
- legacy column 삭제, projection 중단, `의미8` 등 legacy slot 확장, 전체 검색 ranking 재설계는 이번 전환 범위 밖이며 별도 phase에서 판단한다.
- 초기 migration은 기존 DB raw slot을 보존한다. 현재 UI edit/write는 의미 입력을 list로 다루며 trim/빈 값 제거 후 저장할 수 있으므로, 사용자가 edit 후 저장하면 기존 hole이 compact될 수 있다. slot-aware 편집 UX나 hole 보존 편집 의미론은 현재 전환 경계의 목표가 아니며 별도 UX/쓰기 정책 phase에서 다룬다.
- Phase 31-B 시점 실제 DB에는 공백 전용 meaning이 0건이었지만, 향후 발견되는 공백 전용 raw value를 initial migration에서 임의 trim/삭제하지 않는다. 일반 UI write는 기존 입력 의미론에 따라 trim/빈 값 제거를 유지할 수 있다. schema 제약 검토에서는 trim 기반 CHECK(`TRIM(meaning) <> ''`)가 raw 보존 원칙과 충돌할 수 있으므로 피하고, 최소 제약은 `TEXT NOT NULL`과 필요 시 `meaning <> ''` 수준으로 검토한다.
- 새 history snapshot은 canonical normalized meaning rows를 포함한다. 구형 legacy-only snapshot fallback은 호환 목적으로만 유지한다.

### 5.2 word_expression_set

- `word_expression_set`는 expression을 정규화된 row 구조로 저장하는 테이블이다.
- 현재 상태에서 `word_expression_set`는 이미 존재하는 persisted normalized table이다.
- 현재 normal runtime의 expression read/history authority는 `word_expression_set`이다.
- 현재 write는 canonical expression set을 normalized row로 저장한 뒤 `WORD_TABLE` expression slot을 compatibility projection으로 갱신하는 dual-write 구조다.
- legacy `표기1~6`·`음역1~6`·`발음1~6`은 compatibility projection이며 canonical authority가 아니다.
- `seq>6` canonical expression set은 `word_expression_set`에 저장·조회되며 legacy slot에 맞추어 잘리지 않는다.
- primary expression은 `is_representative=1` row를 우선하고, representative row가 없으면 가장 낮은 `seq` row를 fallback으로 사용한다.
- normalized expression payload가 없는 구형 legacy-only history snapshot fallback은 호환 목적으로 유지한다.
- legacy expression column 삭제, projection 중단, `표기7` 등 legacy slot 확장은 이번 범위 밖이며 별도 phase에서 판단한다.

### 5.3 WORD_RELATION / lookup

- `WORD_RELATION`은 현재 relation edge의 runtime storage다.
- `RELATION_CATEGORY`, `RELATION_TYPE`는 runtime lookup으로 사용된다.
- `RELATION_STATUS` lookup table도 존재한다.
- `RELATION_STATUS.inferred`는 seed baseline에 포함되며, runtime lookup 보정 경로에서도 기존/과거 DB 안전망으로 보장된다.
- `inferred`의 사용자 표시 label은 `기존 데이터 기반`이다.
- `inferred`는 기존 데이터와 기존 처리 경로에서 보존된 관계 상태이며, 관계 유형·방향·근거가 현재 기준에서 독립적으로 확정·검증되었음을 뜻하지 않는다.
- 이 보정은 relation 데이터 재작성이나 `WORD_RELATION.status_code` FK 추가를 포함하지 않는다.

### 5.4 Phase 41-B canonical boundary 기록

이 section은 Phase 41-A 감사에서 이미 확인된 현재 경계만 기록한다. 새 설계, migration 계획, legacy 제거 일정, relation status 해결안은 포함하지 않는다.

#### 5.4.1 현재 canonical read/write authority

| 영역 | 현재 canonical read/write authority | compatibility projection 및 fallback 경계 |
| --- | --- | --- |
| expression | `word_expression_set` 중심의 normalized-with-fallback 경계 | `WORD_TABLE` expression slot은 compatibility projection이며, legacy fallback 축소는 이번 범위 밖이다. |
| meaning | `word_meaning_set` | `WORD_TABLE.의미1~7`은 compatibility projection과 제한적 fallback 역할을 유지한다. |
| relation | `WORD_RELATION` | `RELATION_STATUS.inferred` lookup은 seed baseline과 runtime 보정 안전망에 포함되며, relation 데이터 재작성과 FK 추가는 별도 판단 대상이다. |

#### 5.4.2 meaning materialization 경계

- meaning 표시 목록은 `word_meaning_set` row를 `seq ASC, id ASC` 순서로 materialize한다.
- 표시 materialization에서는 trim 후 빈 값이 되는 meaning을 제외한다.
- 대표 meaning은 materialized 표시 목록의 첫 번째 값이다.
- legacy `WORD_TABLE.의미1~7`은 canonical authority가 아니며, compatibility projection과 제한적 fallback 경계로만 유지한다.
- work DB의 `word_meaning_set` 18,149건은 legacy meaning의 non-empty 값과 missing/extra 0으로 일치한다.

#### 5.4.3 seed/work DB와 runtime ensure 경계

- Phase 43-A 기준에서 seed DB와 work DB 모두 `word_meaning_set` canonical baseline을 포함한다.
- 앱은 work DB가 있으면 work DB를 열고, 없을 때만 seed를 복사한다.
- 이후 runtime ensure 경로는 기존 work DB나 과거 seed 상태를 열 때 meaning table을 생성하거나 보강하는 안전망으로 유지한다.
- 이 기록은 legacy projection/fallback 제거, normalized-only 완료 선언, seed Git 추적 전환을 의미하지 않는다.

#### 5.4.4 history와 relation status 경계

- `CHANGE_HISTORY`는 현재 데이터 조회 authority가 아니라 undo/restore용 snapshot 저장소다.
- `status_code='inferred'` relation 데이터는 `RELATION_STATUS.inferred` lookup 보정과 함께 해석할 수 있다.
- 이 보정은 relation 데이터 snapshot 재작성, history restore 정책 변경, relation provenance 모델 도입을 뜻하지 않는다.
- 현재 relation의 canonical authority가 `WORD_RELATION`이라는 경계는 유지한다.

#### 5.4.5 이번 기록이 확정하지 않는 사항

- 현재 상태는 normalized-only 완료나 legacy column 물리적 제거 가능 확정을 의미하지 않는다.
- legacy meaning column 삭제, projection 중단, fallback 제거는 이번 범위 밖이다.
- expression fallback 축소, relation 데이터 재작성, graph dynamics, node level, dark mode는 이번 범위에 포함하지 않는다.

#### 5.4.6 canonical read/write closure guard 경계

- 사용자 기능용 detail, home/search, graph single/center/batch, explorer/split view, edit seed, save 후 재조회, undo 후 재조회는 expression `word_expression_set`, meaning `word_meaning_set` 기준의 canonical read contract를 사용한다.
- generic/raw helper의 legacy 기본 정책은 raw compatibility 경계로 유지할 수 있다. 이 경계는 사용자 기능용 canonical display/read의 근거가 아니다.
- 신규 expression/meaning write는 normalized table을 먼저 갱신하고, `WORD_TABLE` expression/meaning slot은 compatibility projection으로 동기화한다.
- 새 `CHANGE_HISTORY` word snapshot은 normalized expression/meaning row를 포함하며, restore는 해당 normalized payload를 우선한다.
- normalized payload가 없는 과거 history snapshot은 legacy slot fallback을 compatibility 목적으로만 사용한다.
- 이 closure guard의 완료 기준은 legacy slot 물리 삭제, projection 중단, 과거 history 재작성, fallback 전면 제거가 아니다. 해당 작업은 별도 production/data phase에서 판단한다.

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
- 이 원칙은 legacy column 즉시 삭제나 projection 중단을 뜻하지 않는다.
- legacy column 제거 또는 projection 중단은 호환 필요성과 data migration 상태를 확인한 뒤 별도 production phase에서 결정한다.
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

- `word_meaning_set`은 normal runtime의 meaning read 및 history authority다.
- `의미1~7`은 compatibility projection이며 canonical authority가 아니다.
- `seq>7` canonical meaning은 `word_meaning_set`에 저장·조회되며 legacy slot에 맞추어 잘리지 않는다.
- meaning slot 제거 또는 projection 중단은 이번 범위 밖이며 별도 production phase에서 검토한다.

## 9. word_expression_set 정책

### 9.1 현재 상태

- 현재 `word_expression_set`는 persisted normalized expression table이다.
- 현재 normal runtime의 expression read/history authority는 `word_expression_set`이다.
- 현재 `WORD_TABLE` expression slot은 legacy compatibility projection으로 유지된다.
- legacy-only 구형 history snapshot처럼 normalized expression payload가 없는 경우에는 `표기1~6`·`음역1~6`·`발음1~6` fallback을 유지한다.

### 9.2 목표 상태

- `word_expression_set`는 normal runtime의 expression canonical write/read/history target이다.
- expression set의 순서는 `seq ASC`이며, 표기·음역·발음은 동일 `seq`의 대응 묶음으로 보존한다.
- `seq>6` canonical row는 보존하며 legacy slot projection을 위해 절단하지 않는다.
- legacy slot은 authority에서 내려온 compatibility projection이며, 삭제 또는 projection 중단은 별도 phase에서 판단한다.

## 10. relation 정합성 정책

### 10.1 현재 상태

- relation runtime authority는 `WORD_RELATION`이다.
- `RELATION_CATEGORY`, `RELATION_TYPE`, `RELATION_STATUS` lookup code set과 실제 relation data code set은 정합하다.
- `WORD_RELATION.word_id_1`, `word_id_2`의 dangling endpoint는 0건이다.
- repository의 relation read/write/delete/undo/restore 경계는 `WORD_RELATION`과 동일한 relation contract를 사용한다.
- `WORD_TABLE.관련1~7`은 정상 runtime relation authority가 아니다.
- `RELATION_STATUS.inferred`는 seed baseline에 포함되며, runtime lookup 보정 경로에서도 기존/과거 DB 안전망으로 보장된다.
- 실제 relation data의 `status_code` 값은 보존되며, 이 문서는 relation data 재작성 완료나 FK 추가 완료를 선언하지 않는다.

### 10.2 구조적 의미

- 현재 runtime relation authority와 lookup/data code, endpoint, repository/history 경계의 정합성은 확인됐다.
- 이 확인은 legacy `관련1~7` column의 물리 삭제, relation provenance 재설계, FK 추가, `unknown` direction 데이터 전수 판정, 과거 history 재작성을 완료했다는 뜻이 아니다.
- 위 장기 물리 정리 후보는 실제 호환 필요성과 데이터 보존 영향을 확인한 뒤 별도 production/data phase에서 판단한다.

### 10.3 현재 작업 경계

- `WORD_RELATION`은 현재 relation의 runtime authority다.
- 이 문서는 relation schema 변경, relation data 재작성, `관련1~7` 물리 삭제, provenance/FK 정책 결정을 수행하지 않는다.
- 현재 runtime 정합성과 장기적 물리 정리 가능성을 구분하며, 미검증 미래 선택을 완료 상태로 선언하지 않는다.

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
- meaning legacy projection 축소 또는 제거 정책 확정
- relation legacy slot·provenance·FK 물리 정리 필요성 판단
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
