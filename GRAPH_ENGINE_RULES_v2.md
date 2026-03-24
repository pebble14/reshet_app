# GRAPH_ENGINE_RULES_v2

## 목적

그래프는 단어의 의미 형성 구조를 탐색하기 위한 도구이다.

---

## 핵심 변화

```text
v1: 무방향 그래프
v2: 방향 + 의미 흐름 그래프
```

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

---

## graph_expand_mode 동작 규칙

- default
  incoming, outgoing, undirected, unknown 관계를 모두 표시 대상으로 포함한다.
  다만 일반적인 그래프 표시 규칙은 적용될 수 있다.

- incoming_only
  incoming, undirected, unknown 관계를 표시 대상으로 포함하고,
  outgoing 관계는 표시 대상에서 제외한다.

- outgoing_limited
  incoming, undirected, unknown 관계는 모두 포함한다.
  outgoing 관계는 제한된 개수만 포함한다.

- full
  incoming, outgoing, undirected, unknown 관계를 모두 포함하며,
  허브 단어에 대한 일반 제한도 적용하지 않는 예외 모드로 본다.

---

## outgoing_limited의 제한 방식

1차 구현에서 outgoing_limited의 제한은 "고정 개수 제한"으로 정의한다.

- outgoing 표시 상한: 12

이 값은 향후 설정값 또는 정책값으로 확장할 수 있으나,
현재 구현 기준 문서에서는 12를 기본값으로 사용한다.

---

## 다건 관계 보존 규칙

같은 중심 단어와 같은 상대 단어 사이에 관계가 여러 건 존재할 수 있다.

그래프 엔진은 다음 원칙을 따른다.

- 내부 데이터 구조에서는 관계를 단건으로 덮어쓰지 않고 목록으로 보존한다.
- 화면 표시용 대표 edge는 별도로 선택할 수 있다.
- 사용자는 edge detail dialog 등에서 동일 pair의 여러 관계를 개별적으로 확인하고 수정할 수 있어야 한다.

---

## direction 표시 규칙

그래프는 중심 단어 기준 방향 해석 결과를 노출할 수 있어야 한다.

- incoming / outgoing 관계는 화살표 또는 동등한 방향 표시를 사용한다.
- undirected / unknown 관계는 화살표 없이 표시할 수 있다.
- edge label에는 필요 시 IN / OUT / UNDIR / UNK / MIX 요약을 사용할 수 있다.
