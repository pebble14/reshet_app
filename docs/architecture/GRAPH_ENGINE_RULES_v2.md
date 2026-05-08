# GRAPH_ENGINE_RULES_v2

> Status: Legacy v2 semantic source
>
> 현재 active graph semantic authority는 `docs/architecture/graph_semantic_authority.md`이다.
>
> 이 문서는 relation direction, graph_expand_mode, multi-edge semantics의 semantic source/reference 역할을 가진다.
>
> exact display, count, dialog, rendering behavior는 current/historical implementation snapshot이며 active authority가 아니다.

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

## v2 semantic source notes

1. 관계는 방향을 가질 수 있다
2. 그래프는 incoming/outgoing 모두 고려한다
3. 일부 단어는 확장 제한 가능
4. Ego Network 구조는 유지한다

---

## direction/display 분리 source notes

- 관계 방향과 표시 정책을 혼합하지 않는다
- 모든 관계를 동일하게 표시하지 않는다

---

## graph_expand_mode source notes

- default
  incoming, outgoing, undirected, unknown 관계를 모두 고려하는 source mode로 기록되어 있다.
  다만 일반적인 그래프 display rule은 별도 implementation/policy에서 정할 수 있다.

- incoming_only
  incoming, undirected, unknown 관계를 고려하고,
  outgoing 관계는 expansion scope에서 제외하는 source mode로 기록되어 있다.

- outgoing_limited
  incoming, undirected, unknown 관계는 모두 고려한다.
  outgoing 관계는 제한된 범위만 고려하는 source mode로 기록되어 있다.

- full
  incoming, outgoing, undirected, unknown 관계를 모두 고려하며,
  허브 단어에 대한 일반 제한도 적용하지 않는 예외 source mode로 기록되어 있다.

---

## outgoing_limited historical count note

1차 구현 snapshot에서 outgoing_limited의 제한은 "고정 개수 제한"으로 기록되어 있다.

- outgoing 표시 상한: 12

이 값은 향후 설정값 또는 정책값으로 확장할 수 있으나,
현재 active graph semantic authority의 exact count policy가 아니다.

---

## Multi-Edge semantic source notes

같은 중심 단어와 같은 상대 단어 사이에 관계가 여러 건 존재할 수 있다.

v2 source는 다음 semantic source note를 남긴다.

- relation은 단건으로 축소되어 의미를 잃지 않아야 한다.
- 화면 표시용 대표 edge 선택은 historical display snapshot으로 남긴다.
- edge detail dialog는 historical implementation snapshot이며 active authority가 아니다.

---

## historical display notes

v2 source는 중심 단어 기준 방향 해석 결과를 display할 수 있다는 historical note를 남긴다.

- incoming / outgoing 관계의 화살표 또는 동등한 방향 표시는 historical display snapshot이다.
- undirected / unknown 관계를 화살표 없이 표시할 수 있다는 내용도 historical display snapshot이다.
- edge label의 IN / OUT / UNDIR / UNK / MIX 요약은 display note이며 active graph semantic authority가 아니다.
