# ARCHITECTURE.md

## 전체 구조

Reshet 프로젝트는 다음 구조를 따른다.

```text
UI Layer
↓
Repository Layer
↓
Database Layer
```


---

# UI Layer

Flutter 화면.

파일 위치:

```text
lib/ui/
```


주요 화면:

- HomeScreen
- WordDetailScreen
- WordGraphScreen


---

# Repository Layer

데이터 조회 로직.

파일 위치:

```text
lib/data/repositories
```


역할:

- UI와 DB 사이의 중간 계층
- SQL을 직접 UI에서 사용하지 않도록 한다.


---

# Model Layer

데이터 구조 정의.

파일 위치:

```text
lib/data/models
```


예:

- Word
- WordRelation


---

# Database Layer

SQLite 연결 및 관리.

파일 위치:

```text
lib/database
```


DatabaseService가 DB 연결을 담당한다.


---

# 그래프 구조

그래프는 다음 순서로 구현된다.

1. 중심 단어 선택
2. WORD_RELATION 조회
3. 연결된 단어 목록 조회
4. 원형 노드 배치
5. 중심 노드와 연결선 렌더링
6. 노드 클릭 시 새로운 중심 단어로 탐색


---

# UI 목표

그래프는 단어 관계 탐색의 핵심 기능이다.

장기 목표:

- 좌측: 단어 관계 그래프
- 우측: 단어 상세 정보


Split View 구조를 고려한다.
