# DATABASE_SCHEMA.md

## 데이터베이스 개요

Reshet 프로젝트는 SQLite 데이터베이스를 사용한다.

현재 앱 기준 주요 파일은 다음과 같다.

| 경로 | 역할 |
| --- | --- |
| `data/reshet_seed.db` | 기준 seed DB |
| `data/reshet_work.db` | 앱이 실제로 읽고 쓰는 작업 DB |
| `data/bbwdb_20260106.db` | `reshet_seed.db`가 없을 때 사용하는 legacy fallback |

핵심 테이블:

- `WORD_TABLE`
- `WORD_RELATION`
- `RELATION_CATEGORY`
- `RELATION_TYPE`

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

## 주요 컬럼

| 컬럼 | 설명 |
| --- | --- |
| `id` | 단어 ID |
| `언어` | 언어 |
| `스트롱넘버` | Strong Number |
| `표기1` | 원어 표기 |
| `음역1` | 음역 |
| `발음1` | 발음 |
| `의미1` | 기본 의미 |
| `의미2` | 추가 의미 |
| `의미3~7` | 확장 의미 |
| `비고` | 기타 정보 |

---

# WORD_RELATION

단어 간 관계 테이블.

각 레코드는 두 단어 사이의 관계 1건을 의미한다.

## 주요 컬럼

| 컬럼 | 설명 |
| --- | --- |
| `id` | 관계 ID |
| `word_id_1` | 정렬 저장 기준 첫 번째 단어 |
| `word_id_2` | 정렬 저장 기준 두 번째 단어 |
| `category_code` | 관계 상위 분류 |
| `relation_type` | 관계 타입 코드 |
| `status_code` | 상태 |
| `direction_code` | 방향 해석 코드 |
| `description` | 개별 관계 설명 |
| `relation_group_id` | 관련 관계 묶음 식별자 |
| `note` | 메모 |
| `source` | 출처 |
| `created_at` | 생성 시간 |
| `updated_at` | 수정 시간 |

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

| 컬럼 | 설명 |
| --- | --- |
| `code` | 내부 식별용 코드 |
| `label` | UI 표시용 카테고리명 |
| `description` | 카테고리 설명 |
| `sort_order` | 정렬 순서 |

현재 카테고리:

| code | label |
| --- | --- |
| `semantic` | 개념 관계 |
| `lexical` | 어휘 관계 |
| `morphological` | 형태 관계 |
| `etymological` | 어원 관계 |
| `phonological` | 음운 관계 |
| `transliteration` | 음역 관계 |
| `translation` | 번역 관계 |
| `unspecified` | 미분류 관계 |

---

# RELATION_TYPE

관계 타입 lookup 테이블.

| 컬럼 | 설명 |
| --- | --- |
| `code` | 내부 식별용 코드 |
| `category_code` | 소속 카테고리 코드 |
| `label` | UI 표시용 타입명 |
| `description` | 타입 설명 |
| `sort_order` | 정렬 순서 |

대표 타입:

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

전체 카탈로그와 description은 [RELATION_MODEL_v1.md](/c:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_app/RELATION_MODEL_v1.md) 및 [DATABASE_SCHEMA_v2.md](/c:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_app/DATABASE_SCHEMA_v2.md) 기준을 따른다.

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
