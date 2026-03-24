# DATABASE_SCHEMA_v2

## 목적

기존 WORD_RELATION 구조를 확장하여
의미 형성과 영향 흐름을 표현한다.

---

## WORD_RELATION 확장

- direction_code TEXT (기본값: 'unknown')
- description TEXT
- relation_group_id TEXT (optional)

---

## direction_code

- w1_to_w2
- w2_to_w1
- undirected
- unknown

---

## relation_type 확장

- component_of_meaning
- derived_from
- compound_component
- prefix_component
- suffix_component
- semantic_association
- name_change

---

## WORD_TABLE 확장

추가 컬럼:

- graph_expand_mode TEXT
graph_expand_mode의 기본값은 'default'로 둔다.

---

## 그래프 정책

- default
- incoming_only
- outgoing_limited
- full

---

## graph_expand_mode 정의

graph_expand_mode는 중심 단어가 그래프의 기준이 될 때,
어떤 관계를 표시 대상으로 포함할지 결정하는 정책이다.

값은 다음과 같이 정의한다.

- default
  incoming, outgoing, undirected, unknown 관계를 모두 표시 대상으로 포함한다.

- incoming_only
  incoming, undirected, unknown 관계를 표시 대상으로 포함하고,
  outgoing 관계는 표시 대상에서 제외한다.

- outgoing_limited
  incoming, undirected, unknown 관계는 모두 포함한다.
  outgoing 관계는 제한적으로만 포함한다.

- full
  incoming, outgoing, undirected, unknown 관계를 모두 제한 없이 표시 대상으로 포함한다.

---

## outgoing_limited의 제한 방식

outgoing_limited의 "limited"는 1차 구현에서는 개수 제한을 의미한다.

즉, outgoing 관계는 정해진 최대 개수까지만 표시한다.

초기 구현에서는 outgoing 관계의 표시 상한을 고정 개수로 적용한다.
구체적인 상한값은 앱 구현 단계에서 상수로 관리할 수 있다.

향후 필요 시 다음 방식으로 확장할 수 있다.

- relation_type 우선순위 기반 제한
- 중요도 기반 제한
- 깊이 기반 제한

---

## direction_code 기본값

기존 데이터에는 방향 정보가 없으므로,
v2 이행 시 direction_code의 기본값은 undirected가 아니라 unknown으로 둔다.

의미는 다음과 같다.

- unknown: 방향이 있을 수 있으나 아직 결정되지 않음
- undirected: 본질적으로 무방향 관계

이 둘은 반드시 구분한다.

---

## word_id_1 / word_id_2 저장 원칙

word_id_1 / word_id_2는 정렬 저장을 조건부로 유지할 수 있다.

조건은 다음과 같다.

- 저장 시 단어 순서를 정렬했다면,
  direction_code도 정렬된 저장 순서 기준으로 함께 보정해야 한다.
- 입력 순서와 저장 순서가 달라져
  word_id_1 / word_id_2가 뒤바뀌는 경우,
  direction_code는 w1_to_w2 와 w2_to_w1 사이에서 함께 변환되어야 한다.
- undirected 와 unknown은 방향 보정 없이 그대로 유지한다.

---

## WORD_RELATION UNIQUE 기준

1차 v2 구현에서 WORD_RELATION의 UNIQUE 기준은
다음 조합을 사용한다.

- word_id_1
- word_id_2
- relation_type
- direction_code

초기 단계에서는 category_code를 UNIQUE 기준에 포함하지 않는다.
category_code는 상위 분류이며,
실제 관계 의미의 직접 구분은 relation_type 중심으로 처리한다.

relation_group_id는 1차 UNIQUE 기준에 포함하지 않는다.
relation_group_id는 초기 단계에서는 메타데이터로 취급한다.

SQLite 인덱스 구현에서는 NULL 비교 문제를 피하기 위해
다음과 같은 정규화 기준을 사용할 수 있다.

- word_id_1
- word_id_2
- COALESCE(relation_type, '')
- COALESCE(direction_code, 'unknown')

즉, 문서상 UNIQUE 기준은 relation_type / direction_code 기준이지만,
실제 SQLite 인덱스 구현에서는 COALESCE를 사용할 수 있다.

---

## 기존 필드의 역할

- category_code: 관계의 상위 분류를 나타낸다.
- relation_type: 관계의 직접 의미를 나타낸다.
- status_code: 관계의 확정도 또는 편집 상태를 나타낸다.

v2에서도 이 세 필드는 유지되며,
direction_code / description / relation_group_id는 이를 보완하는 확장 필드로 본다.

---

## 핵심 규칙

- 관계와 그래프 정책 분리
- unknown 과 undirected 구분
- 기존 데이터 보존
