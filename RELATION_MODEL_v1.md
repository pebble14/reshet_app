# RELATION_MODEL_v1

## 목적

Reshet의 관계 모델은 다음 질문에 답하기 위해 존재한다.

- 이 단어는 왜 이런 의미를 갖게 되었는가
- 이 단어는 다른 단어의 의미 형성에 어떤 영향을 주었는가

관계는 단순 연결이 아니라
**의미 형성의 원인과 영향 흐름**을 표현해야 한다.

---

## 핵심 원칙

1. 관계는 방향성을 가질 수 있다
2. 그래프는 incoming / outgoing을 모두 다룬다
3. 표시 정책은 단어 기준으로 제어한다
4. 관계는 설명과 근거를 가질 수 있다

---

## 방향성 정의

direction_code:

- w1_to_w2
- w2_to_w1
- undirected
- unknown

---

## 관계 구성 요소

- category_code
- relation_type
- direction_code
- description
- status_code
- relation_group_id (동일 조합 사건 또는 관련 관계 묶음 식별용)

---

## 그래프 정책

graph_expand_mode:

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
  다만 그래프 엔진의 일반 표시 규칙(예: 화면 가독성 보조 규칙, 대표 edge 선택 등)은 적용될 수 있다.

- incoming_only
  incoming, undirected, unknown 관계를 표시 대상으로 포함하고,
  outgoing 관계는 표시 대상에서 제외한다.

- outgoing_limited
  incoming, undirected, unknown 관계는 모두 포함한다.
  outgoing 관계는 제한된 개수만 포함한다.

- full
  incoming, outgoing, undirected, unknown 관계를 모두 포함하며,
  허브 단어에 대한 일반적인 제한 정책도 적용하지 않는 예외 모드로 본다.

unknown 관계는 방향이 아직 결정되지 않은 관계이므로,
초기 구현에서는 보수적으로 표시 대상에 포함한다.

즉, unknown은 정보 부족 때문에 숨기지 않고,
사용자 검토 대상이 되도록 기본적으로 노출하는 방향을 우선한다.

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

---

## 핵심 규칙

- 관계와 표시 정책을 혼합하지 않는다
- unknown 과 undirected 는 구분한다
- 관계는 설명 가능해야 한다
