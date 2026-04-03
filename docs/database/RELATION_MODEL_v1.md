# RELATION_MODEL_v1

## 목적

Reshet의 관계 모델은 단어 사이의 연결을 단순 나열하는 것이 아니라,
의미 형성, 어휘 대응, 형태 변화, 어원적 연결을 일관된 체계로 다루기 위해 존재한다.

이번 기준 문서는 다음을 명확히 맞춘다.

- 관계 구조는 `category (1) : relation type (N)` 이다.
- `code`는 내부 식별용이며 변경하지 않는다.
- UI는 `label`을 표시용으로 사용한다.
- `relation type`은 방향성을 포함하지 않는다.
- 방향 해석은 `direction_code`로 처리한다.
- 레거시 호환 코드는 유지하되 label과 description은 현재 용어 체계에 맞춘다.

---

## 핵심 원칙

1. 관계 분류는 `category_code`와 `relation_type`으로 구성한다.
2. `category_code`는 상위 분류이고, 직접 의미 구분은 `relation_type`이 담당한다.
3. `relation_type` 자체에는 방향성을 넣지 않는다.
4. 관계의 방향은 `direction_code`로만 해석한다.
5. `label`과 `description`은 문서, DB, UI에서 같은 의미로 유지한다.
6. 기존 `code` 값과 DB schema는 변경하지 않는다.

---

## direction_code

| code | 의미 | UI 해석 기준 |
| --- | --- | --- |
| `w1_to_w2` | `word_id_1`에서 `word_id_2`로 향하는 방향 | 중심 단어가 `word_id_1`이면 outgoing, `word_id_2`이면 incoming |
| `w2_to_w1` | `word_id_2`에서 `word_id_1`로 향하는 방향 | 중심 단어가 `word_id_2`이면 outgoing, `word_id_1`이면 incoming |
| `undirected` | 본질적으로 무방향인 관계 | 양방향 또는 무방향 관계로 해석 |
| `unknown` | 방향을 아직 확정하지 않은 관계 | 방향 미확정 상태로 해석 |

정리:

- type은 방향을 가지지 않는다.
- 같은 type이라도 `direction_code`에 따라 incoming / outgoing / undirected / unknown으로 달라진다.
- UI는 type label과 direction 해석을 결합해 관계를 표시한다.

---

## 관계 구성 요소

| 필드 | 역할 |
| --- | --- |
| `category_code` | 관계의 상위 분류 |
| `relation_type` | 관계의 직접 의미를 구분하는 코드 |
| `direction_code` | 관계 방향 해석 |
| `description` | 개별 관계 행에 대한 보충 설명 |
| `status_code` | 관계 상태 |
| `relation_group_id` | 동일 조합 사건 또는 관련 관계 묶음 식별용 |

참고:

- lookup 테이블의 `description`은 type 정의 설명이다.
- `WORD_RELATION.description`은 실제 관계 행에 대한 개별 설명이다.

---

## RELATION_CATEGORY

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

## RELATION_TYPE

### 개념 관계

| code | label | description |
| --- | --- | --- |
| `similar` | 의미 유사 | 의미가 비슷하게 대응되는 관계 |
| `contrast` | 의미 대조 | 의미가 서로 대조되는 관계 |
| `broader` | 상위 개념 | 더 넓은 범주의 의미를 가리키는 관계 |
| `narrower` | 하위 개념 | 더 좁은 범주의 의미를 가리키는 관계 |

### 어휘 관계

| code | label | description |
| --- | --- | --- |
| `synonym` | 동의어 | 서로 바꾸어 쓸 수 있을 정도로 뜻이 가까운 관계 |
| `antonym` | 반의어 | 뜻이 서로 반대되는 관계 |
| `hypernym` | 상위어 | 더 넓은 어휘 범주에 속하는 관계 |
| `hyponym` | 하위어 | 더 구체적인 어휘 범주에 속하는 관계 |

### 형태 관계

| code | label | description |
| --- | --- | --- |
| `derived` | 파생어 | 파생에 의해 연결되는 단어 형성 관계 |
| `inflected` | 굴절형 | 활용이나 굴절에 의해 연결되는 형태 관계 |
| `variant` | 형태 변이 | 철자나 형태가 달라진 이형 관계 |
| `compound` | 합성 | 둘 이상의 어휘 요소가 결합해 이루어진 단어 형성 관계 |

### 어원 관계

| code | label | description | 비고 |
| --- | --- | --- | --- |
| `root_shared` | 공통 어근 | 공통된 어근을 공유하는 관계 | - |
| `borrowed_from` | 차용어 관계 | 언어 간 차용으로 연결되는 관계 | - |
| `loan_translation` | 번역 차용 | 표현 요소를 번역해 받아들인 차용 관계 | - |
| `root-related` | 어근 관련 | 레거시 데이터 호환을 위해 유지하는 어근 관련 관계 | legacy |

### 음운 관계

| code | label | description |
| --- | --- | --- |
| `sound_similar` | 발음 유사 | 발음이 서로 유사하게 들리는 관계 |
| `sound_shift` | 음운 변화 | 음운 변동으로 이어지는 관계 |

### 음역 관계

| code | label | description |
| --- | --- | --- |
| `direct_transliteration` | 직접 음역 | 원어의 음을 직접 대응해 옮긴 관계 |
| `approx_transliteration` | 근사 음역 | 음운 차이를 반영해 가깝게 옮긴 관계 |
| `conventional_transliteration` | 관용 음역 | 관용적으로 굳어진 음역 관계 |

### 번역 관계

| code | label | description |
| --- | --- | --- |
| `literal_translation` | 직역 | 표현을 가능한 한 문자 그대로 옮긴 번역 관계 |
| `semantic_translation` | 의역 | 의미 대응을 중심으로 옮긴 번역 관계 |
| `interpretive_translation` | 풀이 번역 | 의미 풀이를 보완해 옮긴 번역 관계 |

### 미분류 관계

| code | label | description | 비고 |
| --- | --- | --- | --- |
| `related` | 일반 관련 | 레거시 데이터 호환을 위해 유지하는 일반 관련 관계 | legacy |

---

## 레거시 호환

다음 항목은 기존 데이터를 보존하기 위해 유지한다.

| code | 유지 이유 |
| --- | --- |
| `unspecified` | category 정보가 정교하게 분류되지 않은 기존 관계를 수용하기 위함 |
| `related` | 기존 다수의 관계 데이터가 이 type을 사용하고 있기 때문 |
| `root-related` | 기존 어원 관계 데이터와의 호환을 유지하기 위함 |

레거시 항목도 현재 UI에서는 새 label과 description으로 표시한다.

---

## UI 해석 원칙

1. 드롭다운과 상세 화면은 `label`을 보여 준다.
2. 저장과 비교는 `code`로 처리한다.
3. type label에는 방향 표현을 넣지 않는다.
4. 방향 안내는 `direction_code` 해석 결과를 별도로 보여 준다.
5. `description`은 짧고 명확하게 유지한다.

---

## 그래프 정책

`graph_expand_mode`는 중심 단어 기준으로 어떤 관계를 그래프에 포함할지 정하는 정책이다.

- `default`
- `incoming_only`
- `outgoing_limited`
- `full`

이 정책은 표시 범위를 정하는 용도이며,
관계 type 정의 자체와 혼합하지 않는다.

---

## WORD_RELATION UNIQUE 기준

1차 v2 구현의 UNIQUE 기준은 다음 조합을 사용한다.

- `word_id_1`
- `word_id_2`
- `relation_type`
- `direction_code`

정리:

- `category_code`는 상위 분류이므로 UNIQUE 기준에 포함하지 않는다.
- `relation_group_id`는 메타데이터로 취급하며 UNIQUE 기준에 포함하지 않는다.
- `unknown`과 `undirected`는 반드시 구분한다.
