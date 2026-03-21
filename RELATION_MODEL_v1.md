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

## 핵심 규칙

- 관계와 표시 정책을 혼합하지 않는다
- unknown 과 undirected 는 구분한다
- 관계는 설명 가능해야 한다