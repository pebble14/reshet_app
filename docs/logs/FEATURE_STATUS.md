# FEATURE_STATUS

## 2026-04-24 Phase 8-H-32 진행 상태

- 진행 범위: graph center state contract first slice, `WordGraphScreen` 내부 center id authority / reload / stale guard / pending center focus 경계
- 현재 상태: graph center authoritative source가 `_centerWordId`로 전환되었고 `_centerWord`는 compatibility/local fallback carrier로만 유지
- 구조 기준: cache key, stale guard, reload 기준, pending center focus 기준은 `_centerWordId`를 사용하고, center display는 `GraphCenterWordDisplayItem` reread 경로를 유지
- 유지 범위: `onChangeCenterWord`, selection callback, explorer `_centerWord`, history payload/tooltip, graph builder public signature, repository/DB, `Word.fromMap` 일반 경계, graph UX 정책
- 주의: 이번 단계는 graph center state contract first slice이며, graph center UX 변경이나 callback contract 변경 단계가 아니다
- 보류 범위: center change callback contract 후속 절편, `Word.fromMap` 일반 경계 정리 후속 절편

## 2026-04-23 Phase 8-H-30 진행 상태

- 진행 범위: graph selection callback contract first slice, `WordGraphScreen.onSelectWordId` → `WordExplorerScreen._selectWord` selection callback 경계
- 현재 상태: selection callback 주경로가 full `Word` carrier 대신 `selectedWordId`를 전달하도록 적용
- 구조 기준: `onSelectWordId`는 selection callback의 id 중심 주경로이고, 기존 `onSelectWord`는 compatibility fallback으로만 유지한다
- 유지 범위: `onChangeCenterWord`, `_centerWord`, `WordGraphScreen` public seed API, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계, history/tooltip/graph UX 정책
- 주의: 이번 단계는 selection callback boundary first slice이며, graph interaction 전면 개편이나 center carrier 축소 단계가 아니다
- 보류 범위: `onChangeCenterWord` contract, `_centerWord` 축소, `Word.fromMap` 일반 경계 후속 절편

## 2026-04-23 Phase 8-H-28 진행 상태

- 진행 범위: graph UI state visible node contract first slice, `WordGraphScreen` 내부 `_graphWordsById` visible node carrier 경계
- 현재 상태: `_graphWordsById`가 full `Word` 대신 `GraphVisibleNode` 최소 carrier를 저장하도록 적용
- 구조 기준: `GraphVisibleNode`는 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration`만 보유하는 graph UI state visible node용 carrier다
- 유지 범위: `GraphWordLabelDisplayItem` 주 label 경로, `_centerWord`, `ValueChanged<Word>` callback, explorer callback, `WordGraphScreen` public API, repository/DB, `Word.fromMap` 일반 경계, graph builder/cache carrier, graph UX 정책
- 주의: 이번 단계는 `_graphWordsById` state 저장 축소 first slice이며, center/callback/public API나 builder/cache 재정리 단계가 아니다
- 보류 범위: callback contract 축소, `_centerWord` 축소, `Word.fromMap` 일반 경계 후속 절편

## 2026-04-22 Phase 8-H-26 진행 상태

- 진행 범위: graph builder/cache carrier contract first slice, `VisibleWordGraphData.connectedWords` → `WordGraphDataCache` → `GraphBuilder` 내부 조립 carrier
- 현재 상태: graph builder/cache carrier contract first slice 적용
- 구조 기준: `GraphVisibleWord`는 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration`만 보유하는 graph builder/cache용 최소 carrier다
- 유지 범위: `GraphWordLabelDisplayItem` 주 label 경로, `WordGraphScreen` public API / `_centerWord` / `_graphWordsById` / callback 시그니처, repository/DB read policy, `Word.fromMap` 일반 경계, graph seed public boundary, graph UX 정책
- 주의: 이번 단계는 graph 내부 조립 carrier first slice이며, graph internal state 전면 개편이나 `Word.fromMap` 제거 시작 단계가 아니다
- 보류 범위: graph UI state contract 후속 절편, repository 반환형 추가 정리, `Word.fromMap` 일반 경계 후속 절편

## 2026-04-22 Phase 8-H-24 진행 상태

- 진행 범위: graph seed public API contract first slice, `WordGraphScreen` public seed boundary, graph 진입 caller seed 전달부
- 현재 상태: graph seed public API contract first slice 적용
- 구조 기준: `WordGraphScreen`의 주 seed contract는 `centerWordId`이며, 기존 `centerWord: Word`는 compatibility entrypoint로 남기되 내부 seed는 id만 사용한다
- 유지 범위: center display reread, graph label reread, graph data build 흐름, `graph_builder`, `word_graph_cache`, repository/DB 구조, `Word.fromMap` 일반 경계, explorer/history payload, graph UX 정책
- 주의: 이번 단계는 graph public seed 입력 boundary 축소이며, graph public API 전면 개편이나 `Word.fromMap` 제거 시작 단계가 아니다
- 보류 범위: graph builder/cache carrier contract, repository 반환형 정리, `Word.fromMap` 일반 경계 후속 절편

## 2026-04-22 Phase 8-H-22 진행 상태

- 진행 범위: graph seed id contract first slice, `WordGraphScreen` 내부 seed 소비 경계, 초기 load / center update 비교와 적용 경계
- 현재 상태: graph seed id contract first slice 적용
- 구조 기준: `WordGraphScreen(centerWord: Word)` public API는 유지하고, graph 내부 bootstrap seed carrier는 caller `Word` 전체 대신 `centerWord.id.trim()`만 신뢰한다
- 유지 범위: center display reread, graph label reread, graph data build 흐름, `graph_builder`, `word_graph_cache`, repository/DB 구조, explorer/history payload, `Word.fromMap` 일반 경계, graph UX 정책
- 주의: 이번 단계는 graph 내부 seed consumer 축소이며, graph seed public API 변경이나 `Word.fromMap` 제거 시작 단계가 아니다
- 보류 범위: graph seed public API 축소, graph builder carrier 정리, `Word.fromMap` 일반 경계 후속 절편

## 2026-04-21 Phase 8-H-20 진행 상태

- 진행 범위: explorer history payload ID contract, `_ExplorerHistorySnapshot`, `_createHistoryEntry`, `_applyHistoryEntry`, `_isSameHistoryLocation`
- 현재 상태: explorer history payload ID contract first slice 적용
- 구조 기준: history payload는 `centerWordId`, `selectedWordId` 최소 필드만 보유하고, history apply는 `centerWordId`로 `Word(id: ...)`를 만들어 기존 graph center reread 흐름에 연결한다
- 유지 범위: tooltip display contract, availability probe contract, `WordGraphScreen(centerWord: Word)`, graph seed public API, `Word.fromMap` 일반 경계, repository/DB 구조, explorer/history UX 정책
- 주의: 이번 단계는 history payload carrier 축소이며, explorer/history 재구성이나 graph seed public API 변경 단계가 아니다
- 보류 범위: graph seed contract, `Word.fromMap` 일반 경계, explorer/history 후속 절편

## 2026-04-21 Phase 8-H-18 진행 상태

- 진행 범위: explorer history tooltip display contract, `_createHistoryEntry`의 tooltip 표시값 생성 경계, `_buildHistoryTooltip`의 tooltip 표시 소비 경계
- 현재 상태: explorer history tooltip display contract first slice 적용
- 구조 기준: tooltip display는 `WordNavigationHistoryTooltipDisplay`의 `wordId`, `representativeSpelling`, `displayStrongNumber`, `representativeTransliteration` 최소 필드만 기준으로 표시한다
- 유지 범위: `_ExplorerHistorySnapshot`, history payload, back/forward navigation 의미, graph seed, `WordGraphScreen(centerWord: Word)`, `Word.fromMap` 일반 경계, repository/DB 구조, explorer/history UX 정책
- 주의: 이번 단계는 tooltip 표시 consumer 축소이며, explorer/history 재구성이나 navigation payload 대체 단계가 아니다
- 보류 범위: history payload contract, graph seed contract, `Word.fromMap` 일반 경계, explorer/history 후속 절편

## 2026-04-21 Phase 8-H-16 진행 상태

- 진행 범위: explorer history availability probe contract, `_isHistoryEntryAvailable` back/forward 직전 재검증 경계
- 현재 상태: explorer history availability probe contract first slice 적용
- 구조 기준: `_isHistoryEntryAvailable`는 history entry의 `wordId`만 사용해 `probeExistingWordIdsForExplorerHistory` 결과에 포함되는지 확인한다
- 유지 범위: `_ExplorerHistorySnapshot`, tooltip/display, history payload, graph seed, `Word.fromMap` 일반 경계, explorer/history UX 정책
- 주의: 이번 단계는 history availability 재검증 boundary 축소이며, explorer/history UI나 navigation payload 변경 단계가 아니다
- 보류 범위: tooltip display contract, graph seed contract, `Word.fromMap` 일반 경계, explorer/history 후속 절편

## 2026-04-20 Phase 8-H-15 진행 상태

- 진행 범위: duplicate candidate query projection alias, `_buildDuplicateCandidateDisplayItem` helper 입력 경계, H-1 duplicate regression assertion
- 현재 상태: duplicate candidate projection alias contract first slice 적용
- 구조 기준: strong exact / normalized strong / non-strong duplicate projection row는 `word_id`, `language`, `strong_number`, `representative_spelling`, `primary_meaning` canonical alias 집합을 helper에 공급한다
- 유지 범위: `DuplicateCandidateDisplayItem` public field 구조, duplicate warning UI, strong 우선 / normalized strong / non-strong representative spelling 비교 규칙, graph / explorer / history / edit seed / home search
- 주의: 이번 단계는 duplicate projection alias boundary 정리이며, duplicate UX 정책 변경이나 `Word.fromMap` 일반 경계 제거 단계가 아니다
- 보류 범위: explorer/history/graph seed 잔여 boundary, duplicate warning UI 정책, 나머지 slot consumer 후속 절편

## 2026-04-19 Phase 8-H-12 진행 상태

- 진행 범위: home search ranking candidate contract, `searchWordsMap` 내부 ranking 입력 경계, ranking candidate repository 테스트
- 현재 상태: home search ranking candidate contract first slice 적용
- 구조 기준: `searchWordsMap` ranking helper는 raw row 전체 대신 `HomeSearchRankingCandidate`의 `wordId`, `strongNumber`, indexed spellings / transliterations / meanings 최소 필드를 기준으로 rank를 계산한다
- 유지 범위: `searchWordsMap` public 반환형 `List<HomeSearchResultDisplayItem>`, `HomeSearchResultDisplayItem`, `_resolveHomeSearchDisplayItemsForPhase32(...)` display projection, `searchStrongExactMap`, `getStrongWordsMap`, Home UI, graph / explorer / detail / edit / duplicate / relation add search
- 주의: 이번 단계는 ranking 입력 boundary 축소이며, home search 전면 개편이나 `Word.fromMap` 일반 경계 제거 완료 단계가 아니다
- 보류 범위: `searchStrongExactMap`, `getStrongWordsMap`, explorer/history 후속 절편, `Word.fromMap` 일반 경계, 나머지 slot consumer 후속 절편

## 2026-04-18 Phase 8-H-11 진행 상태

- 진행 범위: graph center full display contract, `_buildCenterNode` center 표시 경계, center display repository helper
- 현재 상태: graph center full display contract first slice 적용
- 구조 기준: center node full display는 `GraphCenterWordDisplayItem`의 `wordId`, `language`, `displayStrongNumber`, `representativeSpelling`, `representativeTransliteration`, `representativePronunciation`, `primaryMeaning` 최소 필드를 공급받아 표시한다
- 유지 범위: `centerWord: Word`, `connectedWords`, graph navigation / selection / expansion / cache key / callback payload, peripheral label / secondary label / relation display name, relation add search, duplicate warning, home, edit seed
- 주의: 이번 단계는 center node 표시 consumer 축소이며, graph 전면 개편이나 `Word.fromMap` 일반 경계 제거 완료 단계가 아니다
- 보류 범위: `Word.fromMap` 일반 경계, history/undo/fallback, explorer 경계, 나머지 slot consumer 후속 절편

## 2026-04-18 Phase 8-H-9 진행 상태

- 진행 범위: graph word label display contract, graph peripheral title / secondary label, relation display name, graph builder label, label contract repository 공급 경계
- 현재 상태: graph word label display contract first slice 적용
- 구조 기준: graph label 경로는 `GraphWordLabelDisplayItem`의 `wordId`, `representativeSpelling`, `representativeTransliteration`, `displayStrongNumber` 최소 필드를 병행 공급받아 표시한다
- 유지 범위: center node full display, `connectedWords` 흐름, `Word.fromMap` 일반 경계, graph navigation / selection / expansion, relation add search, duplicate warning, home 경로
- 주의: 이번 단계는 graph label 관련 display 소비 축소이며, graph 전면 개편이나 `Word.fromMap` 제거 완료 단계가 아님
- 보류 범위: center node full display contract, `Word.fromMap` 일반 경계, history/undo/fallback, 나머지 slot consumer 후속 절편

## 2026-04-18 Phase 8-H-7 진행 상태

- 진행 범위: edit seed typed contract, `WordEditScreen` 초기 seed 소비 경로, `word_expression_set.dart` expression controller group 생성 경계, edit seed contract 테스트 보강
- 현재 상태: edit seed typed contract first slice 적용
- 구조 기준: edit 초기값은 `WordEditSeed`의 `wordId`, `language`, `strongNumber`, `note`, `meanings`, `expressionReadResult`, `hiddenSlotIssues` 최소 필드만 기준으로 공급한다
- 유지 범위: edit 저장 정책, validation, submit 흐름, graph / home / search 전반, `Word.fromMap` 일반 경계, history/undo/fallback, duplicate / relation add search
- 주의: 이번 단계는 edit 초기 seed 경로의 raw map / slot 의존 축소 단계이며, edit 전면 개편이나 slot contract 제거 완료 단계가 아님
- 보류 범위: graph label / secondary label, home search / ranking, `Word.fromMap` 일반 경계, history/undo/fallback, 나머지 slot consumer 후속 절편

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
