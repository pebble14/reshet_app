# DATABASE_SCHEMA_v2

> 문서 분류: relation v2 설계·모델 reference
>
> 이 문서는 현재 구현된 relation v2 contract와 lookup metadata를 이해하기 위한 해당 영역의 참고 기준이다. 전체 DB의 현행 schema authority는 [SCHEMA](SCHEMA.md)이며, 이 문서는 이를 대체하지 않는다. 문서 안의 설계 원칙과 현재 구현 설명은 각 section의 범위에 맞게 해석한다.

## 목적

`WORD_RELATION` v2 구조와 관계 lookup metadata의 모델·참고 기준을 정리한다.

이번 기준의 핵심은 다음과 같다.

- `direction_code`, `description`, `relation_group_id`를 포함한 관계 구조를 사용한다.
- 관계 분류는 `RELATION_CATEGORY` 와 `RELATION_TYPE` lookup으로 관리한다.
- 앱은 `seed DB -> work DB 복사 -> lookup metadata upsert` 순서로 정합화를 수행한다.
- 기존 `code` 값과 DB schema는 유지한다.

---

## 데이터베이스 파일

| 경로 | 역할 |
| --- | --- |
| `data/reshet_seed.db` | 기준 seed DB |
| `data/reshet_work.db` | 앱이 실제로 읽고 쓰는 작업 DB |
| `data/bbwdb_20260106.db` | `reshet_seed.db`가 없을 때 사용하는 legacy seed fallback |

정리:

1. 앱이 처음 실행되면 seed DB를 work DB로 복사한다.
2. work DB를 연 뒤 relation lookup metadata를 code 기준으로 upsert 한다.
3. reset 후에도 같은 upsert가 다시 적용된다.

---

## WORD_RELATION v2

| 컬럼 | 설명 |
| --- | --- |
| `id` | 관계 ID |
| `word_id_1` | 정렬 저장 기준 첫 번째 단어 |
| `word_id_2` | 정렬 저장 기준 두 번째 단어 |
| `category_code` | 관계의 상위 분류 |
| `relation_type` | 관계의 직접 의미를 나타내는 코드 |
| `status_code` | 관계 상태 |
| `direction_code` | 방향 해석 코드 |
| `description` | 개별 관계 설명 |
| `relation_group_id` | 관련 관계 묶음 식별자 |
| `note` | 메모 |
| `source` | 출처 |
| `created_at` | 생성 시각 |
| `updated_at` | 수정 시각 |

---

## direction_code

| code | 의미 |
| --- | --- |
| `w1_to_w2` | `word_id_1`에서 `word_id_2`로 향함 |
| `w2_to_w1` | `word_id_2`에서 `word_id_1`로 향함 |
| `undirected` | 무방향 관계 |
| `unknown` | 방향 미확정 관계 |

원칙:

- type은 방향성을 가지지 않는다.
- 방향 해석은 `direction_code`로만 처리한다.
- `unknown`과 `undirected`는 반드시 구분한다.

---

## lookup 테이블

### RELATION_CATEGORY

```sql
CREATE TABLE RELATION_CATEGORY (
  code TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0
)
```

### RELATION_TYPE

```sql
CREATE TABLE RELATION_TYPE (
  code TEXT PRIMARY KEY,
  category_code TEXT NOT NULL,
  label TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  FOREIGN KEY (category_code) REFERENCES RELATION_CATEGORY(code)
)
```

---

## 현재 RELATION_CATEGORY 카탈로그

| code | label | description |
| --- | --- | --- |
| `semantic` | 개념 관계 | 의미상의 유사, 대조, 포함 관계를 나타내는 상위 분류 |
| `lexical` | 어휘 관계 | 단어 간 어휘 대응 관계를 나타내는 상위 분류 |
| `morphological` | 형태 관계 | 형태 변화와 단어 형성 관계를 나타내는 상위 분류 |
| `etymological` | 어원 관계 | 기원, 어근, 차용 관계를 나타내는 상위 분류 |
| `phonological` | 음운 관계 | 발음과 음운 변동 관계를 나타내는 상위 분류 |
| `transliteration` | 음역 관계 | 문자 체계 사이의 음역 관계를 나타내는 상위 분류 |
| `translation` | 번역 관계 | 의미 전달을 위한 번역 관계를 나타내는 상위 분류 |
| `unspecified` | 미분류 관계 | 기존 데이터 호환을 위해 유지하는 분류되지 않은 관계 |

---

## 현재 RELATION_TYPE 카탈로그

| category_code | code | label | description | 비고 |
| --- | --- | --- | --- | --- |
| `semantic` | `similar` | 의미 유사 | 의미가 비슷하게 대응되는 관계 | - |
| `semantic` | `contrast` | 의미 대조 | 의미가 서로 대조되는 관계 | - |
| `semantic` | `broader` | 상위 개념 | 더 넓은 범주의 의미를 가리키는 관계 | - |
| `semantic` | `narrower` | 하위 개념 | 더 좁은 범주의 의미를 가리키는 관계 | - |
| `lexical` | `synonym` | 동의어 | 서로 바꾸어 쓸 수 있을 정도로 뜻이 가까운 관계 | - |
| `lexical` | `antonym` | 반의어 | 뜻이 서로 반대되는 관계 | - |
| `lexical` | `hypernym` | 상위어 | 더 넓은 어휘 범주에 속하는 관계 | - |
| `lexical` | `hyponym` | 하위어 | 더 구체적인 어휘 범주에 속하는 관계 | - |
| `morphological` | `derived` | 파생어 | 파생에 의해 연결되는 단어 형성 관계 | - |
| `morphological` | `inflected` | 굴절형 | 활용이나 굴절에 의해 연결되는 형태 관계 | - |
| `morphological` | `variant` | 형태 변이 | 철자나 형태가 달라진 이형 관계 | - |
| `morphological` | `compound` | 합성 | 둘 이상의 어휘 요소가 결합해 이루어진 단어 형성 관계 | 신규 |
| `etymological` | `root_shared` | 공통 어근 | 공통된 어근을 공유하는 관계 | - |
| `etymological` | `borrowed_from` | 차용어 관계 | 언어 간 차용으로 연결되는 관계 | - |
| `etymological` | `loan_translation` | 번역 차용 | 표현 요소를 번역해 받아들인 차용 관계 | - |
| `etymological` | `root-related` | 어근 관련 | 레거시 데이터 호환을 위해 유지하는 어근 관련 관계 | legacy |
| `phonological` | `sound_similar` | 발음 유사 | 발음이 서로 유사하게 들리는 관계 | - |
| `phonological` | `sound_shift` | 음운 변화 | 음운 변동으로 이어지는 관계 | - |
| `transliteration` | `direct_transliteration` | 직접 음역 | 원어의 음을 직접 대응해 옮긴 관계 | - |
| `transliteration` | `approx_transliteration` | 근사 음역 | 음운 차이를 반영해 가깝게 옮긴 관계 | - |
| `transliteration` | `conventional_transliteration` | 관용 음역 | 관용적으로 굳어진 음역 관계 | - |
| `translation` | `literal_translation` | 직역 | 표현을 가능한 한 문자 그대로 옮긴 번역 관계 | - |
| `translation` | `semantic_translation` | 의역 | 의미 대응을 중심으로 옮긴 번역 관계 | - |
| `translation` | `interpretive_translation` | 풀이 번역 | 의미 풀이를 보완해 옮긴 번역 관계 | - |
| `unspecified` | `related` | 일반 관련 | 레거시 데이터 호환을 위해 유지하는 일반 관련 관계 | legacy |

---

## lookup 정합화 방식

앱은 `database_service.dart`에서 다음 원칙으로 lookup을 맞춘다.

1. `RELATION_CATEGORY.code` 기준으로 label, description, sort_order를 upsert 한다.
2. `RELATION_TYPE.code` 기준으로 category_code, label, description, sort_order를 upsert 한다.
3. seed DB 파일을 직접 수정하지 않아도 기존 work DB와 reset 후 work DB가 같은 metadata를 갖게 된다.
4. 레거시 코드 `unspecified`, `related`, `root-related`도 함께 정비한다.

---

## UNIQUE 기준

v2의 관계 중복 판정 기준은 다음 조합을 사용한다.

- `word_id_1`
- `word_id_2`
- `relation_type`
- `direction_code`

SQLite 인덱스 구현에서는 `NULL` 비교를 안정화하기 위해 다음 형태를 사용한다.

- `COALESCE(relation_type, '')`
- `COALESCE(direction_code, 'unknown')`
