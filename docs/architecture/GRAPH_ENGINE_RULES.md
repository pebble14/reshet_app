# GRAPH_ENGINE_RULES.md

> Status: Legacy v1 graph reference
>
> 이 문서는 현재 active graph authority가 아니다.
> 현재 graph-specific semantic authority는 `docs/architecture/graph_semantic_authority.md`이다.
>
> 이 문서는 초기 graph 구현의 vocabulary, historical rule, implementation snapshot을 보존하기 위한 reference로 유지된다.
> 이 문서의 layout, rendering, click flow, state management, Split View 계획은 현재 UX authority를 override하지 않는다.

## 목적

이 문서는 Reshet 프로젝트의 초기 **단어 관계 그래프 엔진 v1 reference**를 기록한다.

그래프 구조는 프로젝트의 핵심 기능이지만, 현재 active graph semantic authority는 `docs/architecture/graph_semantic_authority.md`이다.
AI 도구(Codex 등) 또는 개발자는 이 문서를 legacy reference와 historical implementation snapshot으로 참고한다.

그래프 구조를 변경하려면 현재 active authority와 사용자 승인을 함께 확인한 뒤 진행해야 한다.

---

# 1. 그래프의 핵심 개념

Reshet 그래프는 다음 개념으로 구성된다.

- **중심 단어 (Center Word)**
- **연결 단어 (Connected Words)**
- **단어 관계 (Word Relation)**
- **노드 (Node)**
- **엣지 (Edge)**

그래프는 항상 **하나의 중심 단어를 기준으로 탐색된다.**

즉, Reshet 그래프는 **Ego Network 형태**이다.

```text
center word
│
├── connected word
├── connected word
└── connected word
```


---

# 2. 중심 노드 규칙

그래프에는 항상 **하나의 중심 노드**가 존재한다.

중심 노드는 다음 특징을 가진다.

- 그래프의 기준 단어
- 화면 중앙에 위치
- 다른 노드보다 시각적으로 강조됨

예:

- 더 큰 노드
- 강조 색상
- 강조 테두리

중심 노드는 다음 데이터를 포함한다.

- 언어
- Strong Number (있다면)
- spelling1
- 발음
- 의미

---

# 3. 연결 노드 규칙

연결 노드는 중심 단어와 관계가 있는 단어이다.

연결 노드는 다음 특징을 가진다.

- 중심 노드 주변에 배치
- 중심 노드보다 작음
- 동일 스타일 유지

노드에는 최소한 다음 정보가 표시된다.

- spelling1
- 발음 (가능한 경우)
- 의미 일부

텍스트가 길 경우 줄임표(...) 처리 가능하다.

---

# 4. 데이터 소스 규칙

그래프의 관계 데이터는 **WORD_RELATION 테이블을 기반으로 한다.**

다음 컬럼을 사용한다.

```text
WORD_RELATION

id
word_id_1
word_id_2
category_code
relation_type
status_code
note
source
created_at
updated_at
```


그래프 연결은 다음 규칙으로 계산한다.

```text
if word_id_1 == centerWord
connectedWord = word_id_2
else
connectedWord = word_id_1
```


즉, 관계는 **양방향 관계**로 처리한다.

---

# 5. WORD_TABLE 사용 규칙

연결 단어의 실제 데이터는 **WORD_TABLE**에서 조회한다.

그래프는 다음 흐름으로 데이터를 가져온다.

```text
centerWordId
↓
WORD_RELATION 조회
↓
connected word ids 수집
↓
WORD_TABLE 조회
↓
노드 렌더링
```


주의:

WORD_TABLE의 다음 컬럼은 **그래프 관계 계산에 사용하지 않는다.**

```text
관련1
관련2
관련3
관련4
관련5
관련6
관련7
```


v1 reference에서 그래프 관계는 **WORD_RELATION** 기반으로 기록되어 있다.

---

# 6. 노드 배치 규칙

v1 implementation snapshot에서 그래프 배치는 **원형 레이아웃 (Circular Layout)** 을 사용한다.

```text
    node
      │

node ─ center ─ node
│
node
```


배치 규칙:

- 중심 노드는 화면 중앙
- 연결 노드는 중심 기준 원형 배치
- 노드 간 각도 균등 분배

예:

```text
angle = 360 / nodeCount
```


---

# 7. 노드 위치 계산

연결 노드 위치는 다음 방식으로 계산한다.

```text
x = centerX + radius * cos(angle)
y = centerY + radius * sin(angle)
```


radius는 그래프 크기에 따라 조정할 수 있다.

---

# 8. 엣지(Edge) 규칙

엣지는 다음 특징을 가진다.

- 중심 노드와 연결 노드 사이에 존재
- 노드 중심점 기준 연결
- 방향성 표시 없음

즉, 관계는 **무방향 그래프**로 표시한다.

---

# 9. 노드 클릭 탐색 규칙

그래프 탐색은 다음 방식으로 이루어진다.

```text
노드 클릭
↓
선택 노드가 새로운 중심 노드
↓
그래프 재조회
↓
새로운 관계 렌더링
```


즉, 그래프는 **탐색 가능한 네트워크**이다.

---

# 10. 상태 관리 규칙

그래프 상태는 다음 두 가지가 핵심이다.

```text
currentCenterWord
connectedWords
```


v1 implementation snapshot에서 그래프 렌더링은 이 두 상태를 기반으로 기록되어 있다.

---

# 11. 그래프 확장 규칙

향후 그래프는 다음 기능으로 확장될 수 있다.

가능한 확장:

- 관계 유형별 색상
- 노드 확대 / 축소
- 그래프 드래그 이동
- 그래프 애니메이션
- 그래프 레벨 확장

다음 항목은 v1 implementation snapshot에서 유지 대상으로 기록되었다.

- 중심 노드 기반 구조 유지
- WORD_RELATION 기반 데이터 유지
- 원형 레이아웃 기본 구조 유지

---

# 12. Split View 확장 계획

v1 reference에서는 향후 UI 확장 계획으로 다음 구조가 기록되어 있다.

```text
┌──────────────┬──────────────┐
│ │ │
│ Graph │ Word Info │
│ │ │
│ │ │
└──────────────┴──────────────┘
```


- 왼쪽: 그래프
- 오른쪽: 단어 상세 정보

그래프 탐색 시 오른쪽 정보가 업데이트된다.

---

# 13. AI 작업 제한

AI 도구(Codex)는 다음 작업을 수행하기 전에 사용자 승인을 받아야 한다.

- 그래프 레이아웃 변경
- 관계 계산 로직 변경
- WORD_RELATION 사용 방식 변경
- 중심 노드 구조 변경

이 항목은 legacy v1 graph reference에서 구조 안정성을 위해 기록된 작업 제한이다.

---

# 14. 핵심 원칙

Reshet 그래프의 핵심 철학은 다음과 같다.


단어는 관계 속에서 이해된다.


그래프는 단어의 의미를 **네트워크 구조로 탐색할 수 있도록** 설계된다.
