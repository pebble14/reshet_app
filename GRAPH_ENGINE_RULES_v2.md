# GRAPH_ENGINE_RULES_v2

## 목적

그래프는 단어의 의미 형성 구조를 탐색하기 위한 도구이다.

---

## 핵심 변화

v1: 무방향 그래프  
v2: 방향 + 의미 흐름 그래프

---

## 핵심 개념

- Center Word
- Connected Words
- Relation Direction
- Graph Expansion Policy

---

## 방향성 규칙

direction_code:

- w1_to_w2
- w2_to_w1
- undirected
- unknown

---

## 관계 해석

중심 단어 기준:

- incoming = 의미 형성 원인
- outgoing = 의미 형성 영향

---

## 그래프 정책

graph_expand_mode:

- default
- incoming_only
- outgoing_limited
- full

---

## 핵심 규칙

1. 관계는 방향을 가질 수 있다
2. 그래프는 incoming/outgoing 모두 고려한다
3. 일부 단어는 확장 제한 가능
4. Ego Network 구조는 유지한다

---

## 금지 규칙

- 관계 방향과 표시 정책을 혼합하지 않는다
- 모든 관계를 동일하게 표시하지 않는다