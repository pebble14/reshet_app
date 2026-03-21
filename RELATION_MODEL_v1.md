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

- relation_type
- direction_code
- description
- status_code

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

## 핵심 규칙

- 관계와 표시 정책을 혼합하지 않는다
- unknown 과 undirected 는 구분한다
- 관계는 설명 가능해야 한다