# DATABASE_SCHEMA.md

## 데이터베이스 개요

Reshet 프로젝트는 SQLite 데이터베이스를 사용한다.

주요 데이터베이스 파일:


data/bbwdb_20260106.db


핵심 테이블:

- WORD_TABLE
- WORD_RELATION


---

# WORD_TABLE

단어 기본 정보 테이블.

Primary Key:


id TEXT


예:


H0001_0000



---

## 주요 컬럼

| 컬럼 | 설명 |
|-----|-----|
| id | 단어 ID |
| 언어 | 언어 |
| 스트롱넘버 | Strong Number |
| 표기1 | 원어 스펠링 |
| 음역1 | 한글 음역 |
| 발음1 | 발음 |
| 의미1 | 의미 |
| 의미2 | 추가 의미 |
| 의미3~7 | 확장 의미 |
| 비고 | 기타 정보 |


---

# WORD_RELATION

단어 간 관계 테이블.

각 레코드는 **두 단어 사이의 관계**를 의미한다.


---

## 컬럼

| 컬럼 | 설명 |
|-----|-----|
| id | 관계 ID |
| word_id_1 | 첫 번째 단어 |
| word_id_2 | 두 번째 단어 |
| category_code | 관계 카테고리 |
| relation_type | 관계 유형 |
| status_code | 상태 |
| note | 메모 |
| source | 출처 |
| created_at | 생성 시간 |
| updated_at | 수정 시간 |


---

# 관계 조회 규칙

특정 단어와 연결된 단어는 다음 로직으로 조회한다.


SELECT * FROM WORD_TABLE
WHERE id IN (
SELECT CASE
WHEN word_id_1 = ?
THEN word_id_2
ELSE word_id_1
END
FROM WORD_RELATION
WHERE word_id_1 = ?
OR word_id_2 = ?
)


이 쿼리는 **양방향 관계**를 처리한다.


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

Reshet v2에서 그래프는 incoming / outgoing / undirected / unknown 관계를 구분하여 다룬다.
기본 모드(default)는 전체 관계를 최대한 보존하는 방향으로 동작하며,
일부 허브 단어에 대해서만 graph_expand_mode를 사용해 outgoing 표시를 제한한다.
기존 데이터의 direction_code 기본값은 unknown으로 두며,
WORD_RELATION의 1차 UNIQUE 기준은 word_id_1, word_id_2, relation_type, direction_code를 사용한다.