# DATABASE_SCHEMA.md

## 데이터베이스 개요

Reshet 프로젝트는 SQLite 데이터베이스를 사용한다.

주요 데이터베이스 파일:

```text
data/bbwdb_20260106.db
```


핵심 테이블:

- WORD_TABLE
- WORD_RELATION


---

# WORD_TABLE

단어 기본 정보 테이블.

Primary Key:

```text
id TEXT
```


예:

```text
H0001_0000
```

---

## 주요 컬럼

| 컬럼 | 설명 |
| --- | --- |
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
| --- | --- |
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

```sql
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
```


이 쿼리는 **양방향 관계**를 처리한다.
