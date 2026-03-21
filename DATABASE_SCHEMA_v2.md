# DATABASE_SCHEMA_v2

## 목적

기존 WORD_RELATION 구조를 확장하여
의미 형성과 영향 흐름을 표현한다.

---

## WORD_RELATION 확장

추가 컬럼:

- direction_code TEXT
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

---

## 그래프 정책

- default
- incoming_only
- outgoing_limited
- full

---

## 핵심 규칙

- 관계와 그래프 정책 분리
- unknown 과 undirected 구분
- 기존 데이터 보존