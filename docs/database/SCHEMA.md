# SCHEMA

> 문서 분류: 현재 전체 DB schema authority
>
> 이 문서는 `data/reshet_work.db`를 기준으로 현재 데이터베이스 전체 스키마를 설명한다. relation v2 모델과 lookup metadata의 설계·참고 기준은 [SCHEMA_v2](SCHEMA_v2.md)에 있으며, 전체 DB의 현행 schema authority는 이 문서다.

## 데이터베이스 개요

Reshet 프로젝트는 SQLite 데이터베이스를 사용한다.

현재 앱 기준 주요 파일은 다음과 같다.

| 경로 | 역할 |
| --- | --- |
| `data/reshet_seed.db` | 앱 최초 설치 상태와 reset 기준으로 사용하는 개발 기준 snapshot DB |
| `data/reshet_work.db` | 개발자가 데이터를 입력/수정하며 관리하는 권위 있는 작업 DB |
| `data/bbwdb_20260106.db` | `reshet_seed.db`가 없을 때 사용하는 legacy fallback |

Windows 개발/테스트 경로는 repository root의 `data/` 디렉터리를 기준으로 유지한다.
Android 앱은 `pubspec.yaml`에 선언된 `data/reshet_seed.db` asset을 앱 내부 `files/data/` 디렉터리로 복사하고, 같은 디렉터리의 `reshet_work.db`를 작업 DB로 사용한다.
`data/reshet_seed.db`는 앱 설치/reset baseline 역할의 snapshot이며, Phase 43-A 기준으로 `word_meaning_set` canonical baseline과 `RELATION_STATUS.inferred` lookup을 물리적으로 포함한다. 앱 공개 전까지 seed DB는 Git 미추적 로컬 private build asset으로 유지한다. 단, 완성 배포 DB를 뜻하지 않고 Hebrew Strong coverage 같은 콘텐츠 완성도는 별도 DB 완성도 phase에서 다룬다.
`data/reshet_work.db`는 mutable local work DB이므로 Git 미추적 상태로 유지한다.
clean clone에는 DB 파일이 포함되지 않으므로, Android full build와 fresh install smoke는 별도 private DB 준비 후 수행한다.

## 데이터 백업·복원 경계

- 데이터 백업은 정상 runtime ensure가 완료된 현재 열린 `reshet_work.db` 전체를 `VACUUM INTO`로 생성한 단일 SQLite snapshot이다.
- snapshot에는 table, index, view, trigger가 그대로 포함되며 `RMAC_TABLE`, `RMAC_TABLE_KR`도 제외하지 않는다.
- SharedPreferences의 화면·session 상태는 SQLite snapshot에 포함되지 않는다.
- 백업 파일은 암호화되지 않으므로 신뢰할 수 있는 위치에 보관해야 한다.
- 현재 Reshet 복원 호환성 계약을 충족하는 전체 SQLite DB를 `reshet_work.db` 교체 대상으로 지원한다. 실제 백업 메뉴에서 생성됐는지 여부는 별도 marker가 없어 판별하지 않는다.
- 복원 원본은 read-only connection에서 integrity, 필수 table·column·PK·unique index, 대표 read를 검증하며 원본에는 runtime ensure나 migration을 실행하지 않는다.
- 현재 전체 백업 보존 계약에는 `RMAC_TABLE`, `RMAC_TABLE_KR`이 포함되며 복원 후보에도 두 table의 존재를 요구한다.
- 검증된 외부 원본은 work DB와 같은 filesystem의 앱 소유 staging 파일로 stream copy하고, runtime ensure는 staging copy에만 적용한다.
- live DB 교체 전 현재 열린 work DB에서 `VACUUM INTO` rollback snapshot을 생성·검증한다. 교체 또는 새 DB 검증 실패 시 previous work를 우선 복구하고, 불가능하면 rollback snapshot을 사용한다.
- 새 work DB open, runtime ensure, integrity/schema, 대표 read가 성공한 뒤 DB 복원 성공으로 확정한다. 이후 화면 상태 갱신이나 임시 파일 cleanup 실패는 검증된 DB를 rollback하는 조건이 아니다.
- SharedPreferences, 검색·탐색 session, graph session은 복원하지 않으며 복원 후 관련 화면 상태와 cache를 다시 초기화한다.
- 현재 백업·복원 입력/저장 경계의 검증 플랫폼은 Windows와 Android다.
- adapter 경계는 Windows에서 `file_selector`, Android에서 `flutter_file_dialog`을 사용한다. Android 복원 입력은 SAF 원본을 앱 cache path로 복사한 뒤 사용하고 best-effort 정리한다.
- Linux 백업·복원 지원은 이번 범위에 포함하지 않으며, 후속 Production phase에서 `file_selector` 경로와 Linux runtime을 별도로 검증한 뒤 완료를 판단한다.
- 배포 대상 플랫폼에서는 MPL 등 소스 제공 의무가 발생할 수 있는 dependency를 사용하지 않는다.

검증 기준:

- 주 기준 DB는 `data/reshet_work.db`
- `data/reshet_seed.db`는 앱 설치/reset baseline 재현성 확인용 snapshot DB
- 아래 컬럼 메타데이터는 `PRAGMA table_info(...)` 기준으로 정리한다.

실제 테이블:

핵심 테이블:

- `WORD_TABLE`
- `WORD_RELATION`
- `CHANGE_HISTORY`

보조/참조 테이블:

- `RELATION_CATEGORY`
- `RELATION_TYPE`
- `RELATION_STATUS`
- `RMAC_TABLE`
- `RMAC_TABLE_KR`

---

# WORD_TABLE

단어 기본 정보 테이블.

Primary Key:

```text
id TEXT
```

예:

```text
H0001_0000
```

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `id` | `TEXT` | Y | N | - | 단어 ID |
| `언어` | `TEXT` | N | N | - | 언어 |
| `스트롱넘버` | `TEXT` | N | N | - | Strong Number |
| `표기1` | `TEXT` | N | N | - | 원어 표기 1 |
| `표기2` | `TEXT` | N | N | - | 원어 표기 2 |
| `표기3` | `TEXT` | N | N | - | 원어 표기 3 |
| `표기4` | `TEXT` | N | N | - | 원어 표기 4 |
| `표기5` | `TEXT` | N | N | - | 원어 표기 5 |
| `표기6` | `TEXT` | N | N | - | 원어 표기 6 |
| `음역1` | `TEXT` | N | N | - | 음역 1 |
| `음역2` | `TEXT` | N | N | - | 음역 2 |
| `음역3` | `TEXT` | N | N | - | 음역 3 |
| `음역4` | `TEXT` | N | N | - | 음역 4 |
| `음역5` | `TEXT` | N | N | - | 음역 5 |
| `음역6` | `TEXT` | N | N | - | 음역 6 |
| `발음1` | `TEXT` | N | N | - | 발음 1 |
| `발음2` | `TEXT` | N | N | - | 발음 2 |
| `발음3` | `TEXT` | N | N | - | 발음 3 |
| `발음4` | `TEXT` | N | N | - | 발음 4 |
| `발음5` | `TEXT` | N | N | - | 발음 5 |
| `발음6` | `TEXT` | N | N | - | 발음 6 |
| `관련1` | `TEXT` | N | N | - | 관련 정보 1 |
| `관련2` | `TEXT` | N | N | - | 관련 정보 2 |
| `관련3` | `TEXT` | N | N | - | 관련 정보 3 |
| `관련4` | `TEXT` | N | N | - | 관련 정보 4 |
| `관련5` | `TEXT` | N | N | - | 관련 정보 5 |
| `관련6` | `TEXT` | N | N | - | 관련 정보 6 |
| `관련7` | `TEXT` | N | N | - | 관련 정보 7 |
| `의미1` | `TEXT` | N | N | - | 기본 의미 |
| `의미2` | `TEXT` | N | N | - | 추가 의미 2 |
| `의미3` | `TEXT` | N | N | - | 추가 의미 3 |
| `의미4` | `TEXT` | N | N | - | 추가 의미 4 |
| `의미5` | `TEXT` | N | N | - | 추가 의미 5 |
| `의미6` | `TEXT` | N | N | - | 추가 의미 6 |
| `의미7` | `TEXT` | N | N | - | 추가 의미 7 |
| `비고` | `TEXT` | N | N | - | 기타 정보 |
| `graph_expand_mode` | `TEXT` | N | Y | `'default'` | 그래프 확장 표시 정책 |

메모:

- 실제 DB에 `graph_expand_mode` 컬럼이 존재한다.
- 현재 `reshet_work.db` 레코드에서 `default`, `full`, `outgoing_limited` 값이 확인된다.

---

# word_expression_set

표현 세트 정규화 테이블.

현재 상태:

- `reshet_work.db`에 migration으로 생성한다.
- 현재 로컬 private `reshet_seed.db`는 `reshet_work.db` 기준 snapshot이므로 이 테이블을 포함한다.
- 이전 Android 설치 DB나 legacy fallback처럼 이 테이블이 없거나 비어 있는 DB를 work DB로 열 때는
  `DatabaseService.openDatabaseFile()`이 `word_expression_set` 테이블과 인덱스를
  보장하고, 테이블이 비어 있을 때만 legacy expression slot에서 최소 backfill한다.
- runtime ensure는 기존 테이블에 nullable `pronunciation_notation`, `pronunciation_notation_name` 열이 없으면 안전한 `ALTER TABLE ... ADD COLUMN`으로 추가한다. 기존 pronunciation 본문은 변경하지 않고, 본문이 있는 미분류 행만 `unknown`으로 멱등 보강한다.
- 현재 앱 read source는 아직 전면 normalized-only가 아니며, legacy `WORD_TABLE` 표현 컬럼과 일부 `NORMALIZED_WITH_FALLBACK` context가 공존한다.
- 현재 앱 expression write path는 `word_expression_set`를 우선 갱신하고 `WORD_TABLE` expression slot을 compatibility projection으로 함께 유지하는 dual-write 구조를 사용한다.
- `word_expression_set.id`는 surrogate key이다.
- 의미 비교와 정합성 검증은 `(word_id, seq)`를 natural identity로 본다.

운영 원칙:

- expression write authority는 repository 내부 canonical expression set과 `word_expression_set` write path를 우선한다.
- create/update 시 repository transaction 안에서 canonical expression set을 normalized row로 저장한 뒤, 같은 expression set을 기준으로 `WORD_TABLE` expression slot compatibility projection을 생성 또는 갱신한다.
- legacy `WORD_TABLE` expression slot은 read compatibility와 기존 surface 호환을 위해 유지되지만, expression write 기준 authoritative source로 보지 않는다.
- expression dual-write / compatibility projection 구현 검증은 create/update/delete/undo 수동 시나리오를 모두 수행한 뒤 마지막에 `sql/word_expression_set/004_verify_word_expression_set.sql`을 다시 실행해 semantic diff 0건인지 확인한다.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `id` | `INTEGER` | Y | N | - | surrogate key |
| `word_id` | `TEXT` | N | Y | - | `WORD_TABLE.id` 참조 |
| `seq` | `INTEGER` | N | Y | - | canonical compacting 순서 |
| `is_representative` | `INTEGER` | N | Y | - | 대표 세트 여부 (`0/1`) |
| `spelling` | `TEXT` | N | Y | - | 표기 |
| `transliteration` | `TEXT` | N | N | - | 음역 |
| `pronunciation` | `TEXT` | N | N | - | 발음 |
| `pronunciation_notation` | `TEXT` | N | N | - | 발음 표기 방식 코드 |
| `pronunciation_notation_name` | `TEXT` | N | N | - | `other` 표기 체계명(선택) |

제약:

- `FOREIGN KEY(word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE`
- `CHECK(seq >= 1)`
- `CHECK(is_representative IN (0, 1))`
- `CHECK(LENGTH(TRIM(spelling)) > 0)`
- `CHECK(transliteration IS NULL OR LENGTH(TRIM(transliteration)) > 0)`
- `CHECK(pronunciation IS NULL OR LENGTH(TRIM(pronunciation)) > 0)`
- `CHECK(pronunciation_notation IS NULL OR pronunciation_notation IN ('strong_dictionary', 'ipa_phonemic', 'ipa_phonetic', 'other', 'unknown'))`
- `CHECK(pronunciation_notation_name IS NULL OR LENGTH(TRIM(pronunciation_notation_name)) > 0)`

기존 테이블 전체 재작성이나 trigger는 사용하지 않는다. pronunciation과 두 metadata 열의 교차 필드 규칙은 repository·normalized write·history restore 공통 write 경계에서 검증한다.

인덱스:

- `ux_word_expression_set_word_seq`
  - `UNIQUE(word_id, seq)`
- `ux_word_expression_set_one_representative`
  - `UNIQUE(word_id) WHERE is_representative = 1`

정합성 원칙:

- 대표 세트는 항상 `seq = 1`
- `pronunciation`이 `NULL`이면 두 notation 열도 `NULL`이다. 본문이 있으면 `pronunciation_notation`은 허용 코드 중 하나이며, `other`가 아닐 때 체계명은 `NULL`이다.
- `other`의 체계명은 선택 사항이지만 값이 있으면 trim 후 비어 있지 않아야 한다.
- `ipa_phonemic`과 `ipa_phonetic`은 DB에 바깥 delimiter를 제외한 본문만 저장한다. 화면·검색 결과·복사는 공통 formatter가 각각 `/본문/`, `[본문]`으로 표시한다.
- legacy `WORD_TABLE.발음1~6`에는 notation slot을 추가하지 않는다. legacy 본문을 읽을 때 값이 있으면 `unknown`, 없으면 notation도 `NULL`로 해석한다.
- `spelling`이 있는 slot만 row로 승격한다.
- `spelling` 없이 `transliteration` 또는 `pronunciation`만 있는 slot은 row로 저장하지 않고 migration exception으로 분리한다.
- semantic compare에서는 `id`를 제외하고
  `word_id, seq, is_representative, spelling, transliteration, pronunciation, pronunciation_notation, pronunciation_notation_name`
  집합만 비교한다.

---

# word_meaning_set

의미 slot 정규화 테이블.

현재 상태:

- Phase 43-A 기준에서 `data/reshet_seed.db`와 `data/reshet_work.db`는 모두 `word_meaning_set` 테이블과 `ux_word_meaning_set_word_seq` 인덱스를 포함한다.
- 앱은 work DB가 있으면 work DB를 열고, 없을 때만 seed를 복사한다.
- `DatabaseService.openDatabaseFile()`과 `resetToSeed()`의 runtime ensure 경로는 기존 work DB, 과거 seed-only 최초 시작, reset 후 재오픈처럼 baseline이 오래된 경우를 위한 안전망으로 유지한다.
- seed-only 최초 시작, 기존 work DB 시작, `resetToSeed()` 이후 재오픈은 모두 같은 runtime ensure/backfill 계약으로 `word_meaning_set` canonical 상태를 준비한다.
- 테이블이 비어 있을 때만 legacy `WORD_TABLE.의미1~7`에서 one-time backfill한다.
- backfill은 raw 의미 문자열을 수정하지 않고 기존 slot 번호를 `seq`로 보존한다.
- 현재 meaning read/write authority는 `word_meaning_set`이다.
- 현재 앱 meaning write path는 `word_meaning_set`를 우선 갱신하고 `WORD_TABLE.의미1~7` projection을 같은 transaction에서 함께 유지한다.
- legacy `WORD_TABLE.의미1~7`은 compatibility projection과 제한적 fallback 역할을 유지한다.
- meaning 표시 목록은 `seq ASC, id ASC` 순서로 materialize하며, trim 후 빈 값은 제외한다.
- 대표 meaning은 materialized 표시 목록의 첫 번째 값이다.
- `word_meaning_set.id`는 surrogate key이다.
- 의미 비교와 정합성 검증은 `(word_id, seq)`를 natural identity로 본다.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `id` | `INTEGER` | Y | N | - | surrogate key |
| `word_id` | `TEXT` | N | Y | - | `WORD_TABLE.id` 참조 |
| `seq` | `INTEGER` | N | Y | - | legacy `의미N` slot 번호 |
| `meaning` | `TEXT` | N | Y | - | 의미 raw 문자열 |

제약:

- `FOREIGN KEY(word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE`
- `CHECK(seq >= 1)`
- `CHECK(meaning <> '')`

인덱스:

- `ux_word_meaning_set_word_seq`
  - `UNIQUE(word_id, seq)`

정합성 원칙:

- initial backfill은 `ROW_NUMBER()` 재번호 부여, hole 재압축, 순서 변경, trim, 중복 제거, 문자열 수정을 하지 않는다.
- `NULL`과 빈 문자열은 normalized row로 저장하지 않는다.
- 공백 전용 문자열은 trim 기준으로 제거하지 않는다.
- semantic compare에서는 `id`를 제외하고 `word_id, seq, meaning` 집합만 비교한다.

---

# WORD_RELATION

단어 간 관계 테이블.

각 레코드는 두 단어 사이의 관계 1건을 의미한다.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `id` | `INTEGER` | Y | N | - | 관계 ID |
| `word_id_1` | `TEXT` | N | Y | - | 정렬 저장 기준 첫 번째 단어 |
| `word_id_2` | `TEXT` | N | Y | - | 정렬 저장 기준 두 번째 단어 |
| `category_code` | `TEXT` | N | N | - | 관계 상위 분류 |
| `relation_type` | `TEXT` | N | N | - | 관계 타입 코드 |
| `status_code` | `TEXT` | N | N | `'asserted'` | 관계 상태 코드 |
| `note` | `TEXT` | N | N | - | 메모 |
| `source` | `TEXT` | N | N | - | 출처 |
| `created_at` | `TEXT` | N | N | `CURRENT_TIMESTAMP` | 생성 시간 |
| `updated_at` | `TEXT` | N | N | `CURRENT_TIMESTAMP` | 수정 시간 |
| `direction_code` | `TEXT` | N | Y | `'unknown'` | 방향 해석 코드 |
| `description` | `TEXT` | N | N | - | 개별 관계 설명 |
| `relation_group_id` | `TEXT` | N | N | - | 관련 관계 묶음 식별자 |

메모:

- 실제 스키마에는 `CHECK(word_id_1 < word_id_2)` 제약이 있어 두 단어 ID는 정렬 저장을 전제로 한다.
- `relation_type`은 방향성을 포함하지 않으며, 방향 해석은 `direction_code`가 담당한다.
- `status_code`의 스키마 기본값은 `asserted`다.
- runtime schema 보정은 `idx_word_relation_signature_lookup`과 `idx_word_relation_pair_type_direction_unique`의 `sqlite_master.sql`을 기대 정의와 비교한다. 인덱스가 없거나 정의가 다를 때만 생성·교체하며, 공백·대소문자 차이만 있는 동일 정의에는 DDL을 실행하지 않는다.
- signature 충돌 조회는 계속 수행하며, `idx_word_relation_pair_type_direction_unique`는 충돌이 없을 때만 보장한다.

## direction_code

| 값 | 의미 |
| --- | --- |
| `w1_to_w2` | `word_id_1`에서 `word_id_2`로 향하는 관계 |
| `w2_to_w1` | `word_id_2`에서 `word_id_1`로 향하는 관계 |
| `undirected` | 무방향 관계 |
| `unknown` | 방향 미확정 관계 |

원칙:

- `relation_type`은 방향성을 포함하지 않는다.
- 방향 해석은 `direction_code`가 담당한다.

---

# RELATION_CATEGORY

관계 카테고리 lookup 테이블.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `code` | `TEXT` | Y | N | - | 내부 식별용 코드 |
| `label` | `TEXT` | N | Y | - | UI 표시용 카테고리명 |
| `description` | `TEXT` | N | N | - | 카테고리 설명 |
| `sort_order` | `INTEGER` | N | N | `0` | 정렬 순서 |

현재 카테고리:

| code | label | sort_order |
| --- | --- | --- |
| `semantic` | 개념 관계 | `1` |
| `lexical` | 어휘 관계 | `2` |
| `morphological` | 형태 관계 | `3` |
| `etymological` | 어원 관계 | `4` |
| `phonological` | 음운 관계 | `5` |
| `transliteration` | 음역 관계 | `6` |
| `translation` | 번역 관계 | `7` |
| `unspecified` | 미분류 관계 | `999` |

---

# RELATION_TYPE

관계 타입 lookup 테이블.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `code` | `TEXT` | Y | N | - | 내부 식별용 코드 |
| `category_code` | `TEXT` | N | Y | - | 소속 카테고리 코드 |
| `label` | `TEXT` | N | Y | - | UI 표시용 타입명 |
| `description` | `TEXT` | N | N | - | 타입 설명 |
| `sort_order` | `INTEGER` | N | N | `0` | 정렬 순서 |

현재 `reshet_work.db`의 `RELATION_TYPE` 행 수는 25건이다. 아래 표는 대표 타입만 적는다.

| category_code | code | label |
| --- | --- | --- |
| `semantic` | `similar` | 의미 유사 |
| `semantic` | `contrast` | 의미 대조 |
| `semantic` | `broader` | 상위 개념 |
| `semantic` | `narrower` | 하위 개념 |
| `lexical` | `synonym` | 동의어 |
| `lexical` | `antonym` | 반의어 |
| `lexical` | `hypernym` | 상위어 |
| `lexical` | `hyponym` | 하위어 |
| `morphological` | `derived` | 파생어 |
| `morphological` | `inflected` | 굴절형 |
| `morphological` | `variant` | 형태 변이 |
| `morphological` | `compound` | 합성 |
| `unspecified` | `related` | 일반 관련 |

현행 relation 분류 해석과 용어 설명은 [RELATION_MODEL_v1.md](./RELATION_MODEL_v1.md)를 참고한다.  
[SCHEMA_v2.md](./SCHEMA_v2.md)는 차기 구조 설계 문서다.

---

# RELATION_STATUS

관계 상태 lookup 테이블.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `code` | `TEXT` | Y | N | - | 내부 식별용 상태 코드 |
| `label` | `TEXT` | N | Y | - | UI 표시용 상태명 |
| `description` | `TEXT` | N | N | - | 상태 설명 |
| `sort_order` | `INTEGER` | N | N | `0` | 정렬 순서 |

현재 상태 코드:

| code | label | sort_order |
| --- | --- | --- |
| `asserted` | 확정 | `1` |
| `hypothesized` | 가설 | `2` |
| `disputed` | 이견 | `3` |
| `uncertain` | 불확실 | `4` |
| `rejected` | 부정됨 | `5` |
| `unknown` | 미정 | `6` |
| `inferred` | 기존 데이터 기반 | `7` |

메모:

- `WORD_RELATION.status_code`의 스키마 기본값은 `asserted`다.
- `inferred`는 seed baseline에 물리적으로 포함되며, runtime lookup 보정 경로도 기존/과거 DB 안전망으로 유지된다.
- `inferred`는 기존 데이터와 기존 처리 경로에서 보존된 관계 상태를 뜻하며, 관계 유형·방향·근거가 현재 기준에서 독립적으로 확정·검증되었음을 뜻하지 않는다.
- 이 보정은 relation 데이터 재작성이나 `WORD_RELATION.status_code` FK 추가를 포함하지 않는다.

---

# CHANGE_HISTORY

변경 이력 기록 테이블.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `id` | `INTEGER` | Y | N | - | 변경 이력 ID |
| `group_id` | `TEXT` | N | Y | - | 변경 묶음 식별자 |
| `action_type` | `TEXT` | N | Y | - | 동작 유형 |
| `entity_type` | `TEXT` | N | Y | - | 대상 엔터티 유형 |
| `entity_id` | `TEXT` | N | Y | - | 대상 엔터티 ID |
| `before_json` | `TEXT` | N | N | - | 변경 전 스냅샷 JSON |
| `after_json` | `TEXT` | N | N | - | 변경 후 스냅샷 JSON |
| `created_at` | `TEXT` | N | Y | - | 생성 시간 |
| `undone_at` | `TEXT` | N | N | - | 되돌림 처리 시간 |

---

# RMAC_TABLE / RMAC_TABLE_KR

형태 분석 참조용 보조 테이블. 두 테이블은 동일한 컬럼 구조를 가진다.

## 실제 컬럼 구조

| 컬럼 | 타입 | PK | NOT NULL | 기본값 | 설명 |
| --- | --- | --- | --- | --- | --- |
| `RMAC` | `TEXT` | Y | N | - | RMAC 코드 |
| `Part_of_Speech` | `TEXT` | N | N | - | 품사 |
| `Tense` | `TEXT` | N | N | - | 시제 |
| `Voice` | `TEXT` | N | N | - | 태 |
| `Mood` | `TEXT` | N | N | - | 법 |
| `Person` | `TEXT` | N | N | - | 인칭 |
| `Case` | `TEXT` | N | N | - | 격 |
| `Number` | `TEXT` | N | N | - | 수 |
| `Gender` | `TEXT` | N | N | - | 성 |
| `Degree` | `TEXT` | N | N | - | 등급 |
| `Form` | `TEXT` | N | N | - | 형식 |

적용 대상:

- `RMAC_TABLE`
- `RMAC_TABLE_KR`

---

# lookup 정합화

앱은 DB를 열 때 다음 흐름으로 relation metadata를 맞춘다.

1. seed DB를 work DB로 복사한다.
2. `database_service.dart`가 `RELATION_CATEGORY.code`, `RELATION_TYPE.code`, `RELATION_STATUS.code` 기준으로 upsert를 수행한다.
3. 기존 work DB와 reset 후 work DB 모두 같은 label, description, sort_order를 갖게 된다.

이 방식은 DB 파일을 직접 수정하지 않고도 lookup 정합화를 유지하기 위한 것이다.

---

# 관계 조회 규칙

특정 단어와 연결된 단어는 다음 로직으로 조회한다.

```sql
SELECT * FROM WORD_TABLE
WHERE id IN (
  SELECT CASE
    WHEN word_id_1 = ?
      THEN word_id_2
    ELSE word_id_1
  END
  FROM WORD_RELATION
  WHERE word_id_1 = ?
     OR word_id_2 = ?
)
```

이 쿼리는 양쪽 컬럼을 모두 확인하므로 양방향 조회가 가능하다.
