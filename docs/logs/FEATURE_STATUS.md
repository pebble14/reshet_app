# FEATURE_STATUS

## 2026-04-14 Phase 8-H-5 진행 상태

- 진행 범위: `getStrongWordsMap()`, home default strong list display contract, `HomeScreen` 기본 strong 목록 consumer, strong-list contract 테스트 보강
- 현재 상태: home default strong list display contract first slice 적용
- 구조 기준: 기본 strong 목록 경로는 `wordId`, `displayStrongNumber`, `representativeSpelling` 최소 typed contract를 기준으로 유지하고, `searchWordsMap`, `searchStrongExactMap`, home search ranking helper는 그대로 둔다
- 유지 범위: home search 결과 contract, `Word.fromMap` 일반 경계, graph label / secondary label, edit seed, duplicate / relation add search, history/undo/fallback 구조
- 주의: 이번 단계는 Home 전체 재구성이 아니라 기본 strong 목록 경로의 raw slot/display 의존 축소 단계이며, home search 전면 개편이나 slot contract 제거 완료 단계가 아님
- 보류 범위: home search ranking, `Word.fromMap` 일반 경계, graph label / secondary label, edit seed, 나머지 slot consumer 후속 절편

## 2026-04-13 Phase 8-H-4 진행 상태

- 진행 범위: `searchWords()`, graph relation add search dialog, graph relation add search contract 테스트 보강
- 현재 상태: graph relation add search contract first slice 적용
- 구조 기준: `searchWords()`의 기존 `표기1` / `의미1` / `스트롱넘버` 검색 semantics는 유지하고, graph relation add consumer contract만 최소 typed search result contract로 축소
- 유지 범위: home search, `Word.fromMap` 일반 경계, graph label / secondary label, edit seed, history/undo/fallback 구조
- 주의: graph relation add search 경로의 raw/slot display 의존 축소 단계이며, search 전면 개편이나 slot contract 제거 완료 단계가 아님
- 보류 범위: home search, graph label / secondary label, `Word.fromMap` 일반 경계, edit seed, 나머지 slot consumer 후속 절편

## 2026-04-13 Phase 8-H-3 진행 상태

- 진행 범위: `findDuplicateCandidates`, edit/graph duplicate warning dialog, duplicate display contract 테스트 보강
- 현재 상태: duplicate display contract first slice 적용
- 구조 기준: query semantics와 strong 우선 / non-strong representative spelling 비교 규칙은 유지하고, consumer contract만 최소 typed display contract로 축소
- 유지 범위: `primaryMeaning`의 기존 표시값, search pipeline, `Word.fromMap`, edit seed, history/undo/fallback 구조
- 주의: duplicate warning 경로의 raw map 의존 축소 단계이며, slot contract 제거 완료 단계가 아님
- 보류 범위: graph relation add search, home search, 나머지 slot consumer 후속 절편

## 2026-04-12 Phase 8-H-1 진행 상태

- 진행 범위: `findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups`, `findDuplicateCandidates`, duplicate warning dialog 최소 정리
- 현재 상태: representative query contract first slice 적용
- 구조 기준: collision / duplicate 조회는 representative-first query helper 기준으로 전환, strong 우선 규칙과 기존 UI contract는 유지
- 유지 범위: search pipeline, `Word.fromMap`, edit seed, history/undo/fallback 구조, graph 전체 label contract
- 주의: production slot contract 제거 시작 단계이며, 제거 완료 단계가 아님
- 보류 범위: 나머지 slot consumer, search 전반, owner-specific 후속 절편

## 2026-04-12 Phase 8-B 진행 상태

- 진행 범위: `createWord`, `updateWord`, `deleteWord`, `undoLastChange`
- 현재 상태: repository 내부 expression write authority first switch 적용
- 구조 기준: canonical write는 `word_expression_set` normalized-first, `WORD_TABLE` slot은 6-slot projection/compatibility 유지
- 유지 범위: 기존 raw/UI contract, dual-sync, legacy read 경계
- 보류 범위: read source completion 확대, `>6 expression`, dual-sync 종료

## 2026-04-12 Phase 8-A 진행 상태

- 진행 범위: `getWordMapById`, `getWordMapByIdForExplorerSingleWord`
- 현재 상태: raw single-word 2경로 first slice 전환 적용
- 보류 범위: `getWordsByIds`, `getWordsMap`, 기타 generic batch/list read
- 주의: expression read completion 전체 완료가 아니라 read 선행 정리의 첫 절편만 반영됨

## 프로젝트 목표

Reshet은 단어 사이의 관계를 탐색하기 위한 도구이다.

핵심 기능:

1. 단어 데이터 조회
2. 단어 상세 정보 확인
3. 단어 관계 그래프 탐색


---

# 현재 구현 상태

- 기준 완료 단계: Phase 7-12

## 데이터베이스 연결

- [x] SQLite 데이터베이스 연결
- [x] 기존 DB 파일 사용
- [x] WORD_TABLE 조회
- [x] WORD_RELATION 조회


---

## 단어 목록

- [x] HomeScreen에서 단어 목록 표시
- [x] WORD_TABLE 주요 컬럼 표시
- [x] 단어 검색
- [x] Strong Number 검색


---

## 단어 상세 화면

- [x] WordDetailScreen 구현
- [x] 공통 상세 표시 계약 기반 정보 표시


---

## Explorer / Split View

- [x] Explorer 화면 구현
- [x] 좌측 그래프 / 우측 상세 패널 split view 적용
- [x] 상세 화면과 탐색 화면 우측 패널의 공통 표시 계약 적용


---

## 그래프 화면

### 기본 구조

- [x] WordGraphScreen 생성
- [x] 중심 노드 표시
- [x] 더미 노드 생성
- [x] 원형 배치 구현
- [x] 연결선 렌더링


### 데이터 연결

- [x] WORD_RELATION 기반 연결 단어 조회
- [x] Repository 계층 도입
- [x] 실제 연결 단어 그래프 표시


### 그래프 탐색

- [x] 노드 클릭 탐색
- [x] 선택 노드를 중심 단어로 재탐색


---

# 다음 단계

## 그래프 UI 개선

- [ ] 관계 타입별 선 색상
- [ ] 노드 정보 표시 개선
- [ ] 노드 라벨 레이아웃 개선
- [ ] 노드 크기 자동 조절


---

## 그래프 탐색 기능 확장

- [ ] 노드 클릭 시 애니메이션 이동
- [ ] 그래프 확대 / 축소
- [ ] 그래프 드래그 이동


---

## 관계 정보 표시

- [ ] relation_type 표시
- [ ] category_code 표시
- [ ] 관계 설명 툴팁


---

## 검색 기능 고도화

- [ ] 언어별 필터


---

## 데이터 구조 개선 (장기)

- 데이터 구조 정책 문서: `docs/database/DATA_STRUCTURE_POLICY.md`

- [ ] WORD_TABLE 구조 검토
- [x] 표현 세트 정규화 가능성 검토
- [x] word_expression_set migration SQL 작성
- [x] word_expression_set semantic compare 기준 확정
- [x] word_expression_set dual-sync write path 구현
- [x] word_expression_set read source policy 기반 도입
- [x] word_expression_set normalized read adapter 연결
- [x] word_expression_set fallback 판정/관측 구조 도입
- [x] word_expression_set detail-only phase 2 read path 적용
- [x] expression write authority first switch
- [x] WORD_TABLE expression slot projection / compatibility 유지 구조 반영
- [x] history / undo용 normalized snapshot 병행 저장
- [x] controlled read boundary 정리
- [x] 공개 읽기 경계의 typed contract 적용
- [x] detail-like 공통 표시 계약 적용
- [x] detail-like 공개 API naming 안정화
- [ ] word_expression_set read source 전환
- [ ] 확장 가능한 관계 구조 설계


---

# 장기 목표

Reshet은 단순한 단어 사전이 아니라

**단어 관계 탐색 도구**가 되는 것을 목표로 한다.

장기 목표:

- 대규모 관계 그래프 탐색
- 관계 유형 시각화
- 성경 단어 네트워크 분석
- 연구용 도구로 확장


---

# Codex 작업 규칙

Codex는 FEATURE_STATUS.md를 참고하여 다음을 수행한다.

1. 이미 완료된 작업을 반복하지 않는다
2. 다음 단계 작업을 우선 제안한다
3. 기능 단위를 작은 단계로 나눈다
4. 사용자 승인 후에만 수정 제안한다
