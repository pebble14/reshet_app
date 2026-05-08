# ARCHITECTURE.md

> Status: High-level architecture reference
>
> 이 문서는 active UX, navigation, responsive, graph semantic authority가 아니다.
>
> UX identity는 `docs/ux/workspace_ux_architecture.md`를 따른다.
> Navigation semantics는 `docs/ux/navigation_policy.md`를 따른다.
> Responsive layout 기준은 `docs/ux/responsive_layout_policy.md`를 따른다.
> Graph semantics는 `docs/architecture/graph_semantic_authority.md`를 따른다.
>
> 이 문서는 high-level architecture overview, implementation architecture reference,
> 그리고 historical/current architecture context를 설명하기 위한 reference로 유지된다.

## 전체 구조

현재 high-level architecture는 다음 layer 구조로 설명된다.

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

current implementation snapshot에서 graph flow는 다음 순서로 설명된다.

1. 중심 단어 선택
2. WORD_RELATION 조회
3. 연결된 단어 목록 조회
4. 원형 노드 배치
5. 중심 노드와 연결선 렌더링
6. 노드 클릭 시 새로운 중심 단어로 탐색


---

# UI 목표

graph surface는 단어 관계 탐색에서 중요한 surface이다.

historical/current implementation context에서 기록된 layout 목표:

- 좌측: 단어 관계 그래프
- 우측: 단어 상세 정보


Split View 구조는 historical/current implementation context의 layout 후보로 기록한다.
