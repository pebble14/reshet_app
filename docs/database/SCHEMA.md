# SCHEMA

이 문서는 `data/reshet_work.db`를 기준으로 현재 데이터베이스 스키마를 설명한다.  
`SCHEMA_v2.md`는 차기 구조 설계 문서이며, 현행 스키마 기준 문서는 이 문서다.

## 데이터베이스 개요

Reshet 프로젝트는 SQLite 데이터베이스를 사용한다.

현재 앱 기준 주요 파일은 다음과 같다.

| 경로 | 역할 |
| --- | --- |
| `data/reshet_seed.db` | 기준 seed DB |
| `data/reshet_work.db` | 앱이 실제로 읽고 쓰는 작업 DB |
| `data/bbwdb_20260106.db` | `reshet_seed.db`가 없을 때 사용하는 legacy fallback |

검증 기준:

- 주 기준 DB는 `data/reshet_work.db`
- `data/reshet_seed.db`는 구조 차이 여부 확인용 참고 DB
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
- 현재 앱 read source는 아직 legacy `WORD_TABLE` 표현 컬럼이다.
- `word_expression_set.id`는 surrogate key이다.
- 의미 비교와 정합성 검증은 `(word_id, seq)`를 natural identity로 본다.

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

제약:

- `FOREIGN KEY(word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE`
- `CHECK(seq >= 1)`
- `CHECK(is_representative IN (0, 1))`
- `CHECK(LENGTH(TRIM(spelling)) > 0)`
- `CHECK(transliteration IS NULL OR LENGTH(TRIM(transliteration)) > 0)`
- `CHECK(pronunciation IS NULL OR LENGTH(TRIM(pronunciation)) > 0)`

인덱스:

- `ux_word_expression_set_word_seq`
  - `UNIQUE(word_id, seq)`
- `ux_word_expression_set_one_representative`
  - `UNIQUE(word_id) WHERE is_representative = 1`

정합성 원칙:

- 대표 세트는 항상 `seq = 1`
- `spelling`이 있는 slot만 row로 승격한다.
- `spelling` 없이 `transliteration` 또는 `pronunciation`만 있는 slot은 row로 저장하지 않고 migration exception으로 분리한다.
- semantic compare에서는 `id`를 제외하고
  `word_id, seq, is_representative, spelling, transliteration, pronunciation`
  집합만 비교한다.

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

메모:

- `WORD_RELATION.status_code`의 스키마 기본값은 `asserted`다.
- 현재 `reshet_work.db`의 `WORD_RELATION` 데이터에는 `inferred` 값도 존재하므로, lookup 행과 실제 데이터 값의 정합성은 별도 검토 대상이다.

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
2. `database_service.dart`가 `RELATION_CATEGORY.code`, `RELATION_TYPE.code` 기준으로 upsert를 수행한다.
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
