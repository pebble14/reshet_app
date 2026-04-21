# CHANGELOG

## 2026-04-21 Phase 8-H-18

- explorer history tooltip display contract first slice를 적용했다.
- `WordNavigationHistoryTooltipDisplay`를 추가해 tooltip 표시가 `wordId`, 대표 표기, display Strong, 대표 음역 최소 필드를 사용하도록 분리했다.
- `_buildHistoryTooltip`은 더 이상 `entry.payload.centerWord.transliteration1`을 직접 읽지 않고, tooltip display contract의 표시 줄만 소비한다.
- `_ExplorerHistorySnapshot`, back/forward navigation 의미, graph seed, `WordGraphScreen(centerWord: Word)`, `Word.fromMap` 일반 경계, repository/DB는 변경하지 않았다.

## 2026-04-21 Phase 8-H-16

- explorer history availability probe contract first slice를 적용했다.
- `WordExplorerScreen._isHistoryEntryAvailable`의 back/forward 직전 availability 재검증을 `getWordMapByIdForExplorerSingleWord` full map 조회에서 `probeExistingWordIdsForExplorerHistory` id existence probe로 전환했다.
- `_ExplorerHistorySnapshot`, history tooltip/display, graph seed, `Word.fromMap` 일반 경계, explorer UX 정책은 변경하지 않았다.

## 2026-04-20 Phase 8-H-15

- duplicate candidate projection alias contract first slice를 적용했다.
- `findDuplicateCandidates`의 strong exact / normalized strong / non-strong projection row alias를 `word_id`, `language`, `strong_number`, `representative_spelling`, `primary_meaning` canonical 집합으로 맞췄다.
- `_buildDuplicateCandidateDisplayItem`는 canonical alias만 소비하도록 줄였고, `DuplicateCandidateDisplayItem` public field 구조와 duplicate warning UI는 유지했다.
- strong exact / normalized strong / non-strong duplicate 비교 규칙과 create/edit/graph 흐름은 변경하지 않았다.

## 2026-04-19 Phase 8-H-12

- home search ranking candidate contract first slice를 적용했다.
- `HomeSearchRankingCandidate`를 추가해 `searchWordsMap` 내부 ranking helper 입력을 raw row 전체에서 `wordId`, `strongNumber`, indexed spellings / transliterations / meanings 최소 필드로 축소했다.
- `searchWordsMap`의 public 반환형 `List<HomeSearchResultDisplayItem>`과 display projection `_resolveHomeSearchDisplayItemsForPhase32(...)` 흐름은 유지했다.
- strong exact / prefix / partial, spelling exact / prefix / partial, transliteration exact / prefix / partial, meaning partial ranking priority와 id tie-break 정렬 의미는 유지했다.
- `searchStrongExactMap`, `getStrongWordsMap`, `home_screen.dart`, graph / explorer / detail / edit / duplicate / relation add search 경로는 변경하지 않았다.

## 2026-04-18 Phase 8-H-11

- graph center full display contract first slice를 적용했다.
- `GraphCenterWordDisplayItem`을 추가해 center node full display에 필요한 `wordId`, `language`, `displayStrongNumber`, `representativeSpelling`, `representativeTransliteration`, `representativePronunciation`, `primaryMeaning` 최소 필드를 분리했다.
- `WordGraphScreen._buildCenterNode`는 center display contract를 소비하도록 전환했고, `centerWord: Word`, `connectedWords`, graph navigation / selection / expansion / cache key / callback payload는 기존 흐름을 유지했다.
- peripheral node label, secondary label, relation display name은 Phase 8-H-9 결과를 유지했고, `Word.fromMap` 일반 경계 제거는 이번 단계 범위에 포함하지 않았다.
- `test/data/repositories/word_repository_phase8h11_graph_center_display_contract_test.dart`, `test/ui/word_graph_screen_phase8h11_center_display_contract_test.dart`를 추가해 center display projection과 helper widget 표시 경계를 검증했다.

## 2026-04-18 Phase 8-H-9

- graph word label display contract first slice를 적용했다.
- `GraphWordLabelDisplayItem`을 추가해 graph peripheral title, secondary label, relation display name, graph builder label에 필요한 `wordId`, `representativeSpelling`, `representativeTransliteration`, `displayStrongNumber` 최소 필드를 분리했다.
- `VisibleWordGraphData`는 기존 `connectedWords` 흐름을 유지하면서 label 전용 `wordLabels`를 병행 공급하도록 확장했다.
- `GraphBuilder`, `WordGraphScreen`, `WordGraphDataCache`는 label contract 보존과 소비에 필요한 범위만 최소 수정했고, center node full display와 `Word.fromMap` 일반 경계는 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h9_graph_label_display_contract_test.dart`, `test/domain/graph/graph_builder_phase8h9_graph_label_contract_test.dart`를 추가해 representative label projection과 graph builder label fallback을 검증했다.

## 2026-04-18 Phase 8-H-7

- edit 초기 seed 전용 typed contract `WordEditSeed`를 추가했다.
- `WordEditScreen`은 언어, 스트롱넘버, 비고, 의미, expression read result, hidden-slot issue를 seed contract를 통해 초기화하도록 정리했다.
- expression controller group 생성은 `CanonicalExpressionReadResult` 기반 helper를 추가해 연결하고, 기존 legacy row helper는 compatibility 용도로 유지했다.
- hidden-slot issue의 write exclusion 의미와 edit 저장 / validation / submit 정책은 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h7_edit_seed_contract_test.dart`를 추가하고, `word_edit_screen_test.dart`를 보강해 seed 동일성을 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 edit seed typed contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-14 Phase 8-H-5

- `getStrongWordsMap()` 경로에 home default strong list display contract first slice를 적용했다.
- `HomeDefaultStrongListItem`은 기본 strong 목록 consumer에 실제 필요한 `wordId`, `displayStrongNumber`, `representativeSpelling` 최소 필드만 남기도록 정리했다.
- repository strong-list branch는 representative spelling 표시를 기본 strong 목록 전용 typed contract로 projection하고, strong-list mismatch 보호는 최소 contract 기준으로만 제한했다.
- `HomeScreen` 기본 strong 목록 consumer는 새 필드명만 읽도록 최소 수정했고, home search 결과 / 상세 진입 / 기타 흐름은 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h5_home_strong_display_contract_test.dart`를 추가해 representative projection과 legacy fallback baseline을 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 home default strong list display contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-13 Phase 8-H-4

- `searchWords()`의 검색 semantics는 유지한 채 graph relation add search 전용 typed contract first slice를 적용했다.
- graph relation add search 반환 경계는 raw `Word` 대신 `wordId`, `representativeSpelling`, `primaryMeaning`, `displayStrongNumber` 최소 필드만 노출하도록 축소했다.
- `WordGraphScreen` 관계 추가 대상 선택 다이얼로그는 raw slot field 대신 동일 typed contract만 소비하도록 정리했다.
- create-after-save 이후 관계 추가 흐름은 유지하면서 `_showCreateRelationDialog` 입력도 관계 생성에 필요한 최소 인자로 축소했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 graph relation add search contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-13 Phase 8-H-3

- `findDuplicateCandidates`의 query semantics와 strong / non-strong duplicate 판정 규칙은 유지한 채 duplicate warning 전용 typed display contract first slice를 적용했다.
- duplicate candidate 반환 경계는 raw `Map<String, dynamic>` 대신 `wordId`, `language`, `strongNumber`, `representativeSpelling`, `primaryMeaning` 최소 필드만 노출하도록 축소했다.
- `WordEditScreen`, `WordGraphScreen` duplicate warning dialog는 동일한 typed contract만 소비하도록 정리했다.
- duplicate display contract 회귀를 확인하도록 기존 representative query contract test의 duplicate candidate 검증을 보강했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 display contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-H-1

- `findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups`를 representative spelling / transliteration 기준 query first slice로 전환했다.
- `findDuplicateCandidates`는 strong 우선 규칙을 유지한 채 non-strong duplicate 비교축을 representative spelling 기준으로 전환했다.
- representative row가 존재하는데 transliteration이 blank인 경우 legacy `음역1`로 복귀하지 않도록 제한했다.
- duplicate warning dialog는 기존 contract를 유지하면서 안내 문구를 representative 표기 기준으로만 최소 조정했다.
- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`를 추가해 collision / duplicate representative query first slice를 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 Phase 8-H-1 first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-B

- `createWord`, `updateWord`의 expression write 흐름을 canonical expression set -> normalized `word_expression_set` row 저장 -> `WORD_TABLE` 6-slot projection 생성 순서로 재정렬했다.
- `WORD_TABLE` expression slot은 write authority가 아니라 projection/compatibility 출력물로 낮췄고, 이번 단계에서는 6-slot 범위를 유지했다.
- `deleteWord`, `undoLastChange` history는 기존 `WORD_TABLE` compatibility snapshot을 유지하면서 normalized snapshot을 함께 저장하도록 보강했다.
- `undoLastChange`는 신규 history row에서 normalized restore를 우선 사용하고, 기존 history row는 legacy fallback을 유지한다.
- Phase 8-B repository 테스트를 보강해 create/update/delete/undo, save/undo reread, normalized-restore 우선 / legacy-fallback 규칙을 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 write authority first switch와 projection/compatibility 유지 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-A

- `getWordMapById`, `getWordMapByIdForExplorerSingleWord` 두 raw single-word public read를 Phase 8-A first slice로 `NORMALIZED_WITH_FALLBACK` 경로에 편입했다.
- 두 경로는 새 fallback/resolver를 만들지 않고 기존 detail-like single-word materialization helper를 재사용한다.
- 반환 contract는 계속 raw `Map<String, dynamic>`로 유지하고, visible mismatch가 생기면 기존 legacy fallback을 그대로 사용한다.
- `getWordsByIds`, `getWordsMap`, 기타 generic batch/list read는 이번 단계에서 바꾸지 않았다.
- Phase 8-A 전용 repository 테스트를 추가해 경로 전환과 expression projection 보존을 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에 raw single-word 2경로 first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-11 Phase 7-11

- detail-like display shared contract `WordDetailLikeDisplayItem`를 추가했다.
- `getWordDetailLikeDisplayItemByIdForDetailScreen`, `getWordDetailLikeDisplayItemByIdForSplitView`의 public 반환형을 raw `Map<String, dynamic>`에서 shared contract로 전환했다.
- repository 내부에 `raw row -> fallback 반영 -> detail-like display contract` 경계를 추가하고, graph/safe-zone raw single-word read는 기존 raw 경계를 유지했다.
- `WordInfoPanel`이 raw map 기반 helper와 직접 key 해석을 제거하고 typed display renderer로 전환됐다.
- `WordDetailScreen`과 `WordExplorerScreen`이 공통 detail-like contract를 panel에 전달하도록 정리됐고, 편집/이동 같은 화면별 동작은 on-demand raw reread로 분리했다.
- `HomeScreen` detail navigation은 새 detail contract를 전달하는 최소 caller 적응만 반영했다.
- `docs/database/read_source_migration.md`에 Phase 7-11 detail-like shared contract 적용 범위와 구조 결과를 반영했다.

## 2026-04-11 Phase 7-7

- home search result display 전용 controlled contract `HomeSearchResultDisplayItem`을 추가했다.
- `searchStrongExactMap`, `searchWordsMap`의 public 반환형을 raw `Map<String, dynamic>` 목록에서 contract 목록으로 전환했다.
- repository 내부에서 `raw row -> fallback 반영 -> display contract 생성` 경계를 고정했다.
- `HomeScreen` search branch가 raw row, `Word.fromMap`, `buildHomeWordDisplaySummary`, raw subtitle 추출 없이 contract만 소비하도록 정리했다.
- `searchWordsMap('')`는 더 이상 `getWordsMap(limit: limit)` browse path로 내려가지 않고 빈 결과를 반환한다.
- `docs/database/read_source_migration.md`에 Phase 7-7 contract 적용 범위와 구조 결과를 반영했다.

## 2026-04-11 Phase 7-4

- Home search branch가 detail / explorer / graph navigation에 search row 전체를 직접 넘기지 않도록 `wordId` 기준 helper로 정리했다.
- search result navigation은 detail `getWordDetailLikeDisplayItemByIdForDetailScreen`, graph `getWordMapByIdForGraphCenterSingleWord`, explorer `initialWordId` bootstrap 구조로 분리했다.
- `WordExplorerScreen` route payload를 `initialWordId`로 줄이고 init bootstrap에서 graph center read + split-view read를 사용하도록 바꿨다.
- explorer history snapshot은 full selected row 대신 selected word id만 보관하도록 정리했다.

## 2026-04-11

### 변경
- controlled zone 판정 기준을 `docs/database/read_source_migration.md` 에 정책 문장으로 문서화했다.
- graph display / history probe / legacy generic read context의 3계층 구조 구분을 확정했다.
- read 승격 절차를 `generic -> owner-specific 분리 -> 반환 계약 고정 -> 관측/검증 가능성 확보 -> controlled 판정` 기준으로 고정했다.
- explorer history existence probe 전용 API `probeExistingWordIdsForExplorerHistory` 를 추가했다.
- explorer history availability 판단은 더 이상 generic `getWordsByIds` full row read를 사용하지 않고 `Set<String>` probe 결과를 직접 사용한다.
- history probe 구현은 `SELECT id FROM WORD_TABLE WHERE id IN (...)` 로 최소화했고 `getWordsByIds` 자체는 그대로 유지했다.
- probe는 display/read-source 해석 대상이 아니므로 기존 `ReadSourceDebugCollector` 를 재사용하지 않고 query 실행부 근처에 전용 collector TODO 만 남겼다.
- history probe 전용 repository 테스트를 추가하고 구조 검증 명령으로 explorer caller의 generic batch 의존 제거를 확인했다.

## 2026-04-10

### 변경
- `readForGraphSingleWord` 를 legacy single read 에서 controlled `normalizedWithFallback` 경로로 승격했다.
- `getWordMapByIdForGraphSingleWord` 는 public API contract 와 기존 `readForGraphSingleWord` context 를 유지한 채 graph single-word 전용 controlled read 로 전환했다.
- graph single-word stable / display-mismatch fallback 을 닫는 repository 테스트와 `tool/verify_graph_single_word_context.dart` 검증 스크립트를 추가했다.
- `getWordsByIds` 는 generic legacy zone 으로 그대로 유지했고 split/detail/save/undo safe zone 은 변경하지 않았다.
- `docs/database/read_source_migration.md` 에 Phase 5 범위와 검증 결과를 반영했다.

## 2026-04-09

### 변경
- graph batch read 를 `readForGraphBatch` 단일 policy zone 으로 승격했다.
- `getWordsByIdsForGraphBatch` 에 graph batch 전용 adapter 를 도입하고 detail/split safe zone 의 detail-like display guard 를 재사용했다.
- generic `getWordsByIds` 는 그대로 `LEGACY` 로 유지하고 collector context 분리를 보존했다.
- repository 테스트에 graph batch normalized success / display-mismatch fallback 검증을 추가했다.
- `tool/verify_graph_batch_context.dart` 를 Phase 4-E 기준 command 검증 스크립트로 갱신했다.
- `docs/database/read_source_migration.md` 에 Phase 4-E 범위와 검증 결과를 반영했다.

## 2026-04-08

### 변경
- split view 표시 read를 detail-like `normalizedWithFallback` 경로로 상향했다.
- `readForSplitViewSingleWord` context를 `NORMALIZED_WITH_FALLBACK` 대상에 편입했다.
- split view wrapper와 explorer history probe wrapper를 분리 유지했다.
- repository 정책 테스트에 split view normalized success / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 Phase 4-B 기준 상태를 반영했다.

## 2026-04-04

### 변경
- 문서 구조를 `/docs` 기준으로 정리했다.
- read source 전환 1차 기반을 repository 내부에 도입했다.
- 기본 read source policy는 아직 `LEGACY`로 유지한다.
- normalized read adapter와 fallback 판정/관측 모델을 연결했다.
- 실제 normalized read 활성 전환은 아직 수행하지 않았다.
- `WordDetailScreen` 전용 제한 경로 `getWordDetailLikeDisplayItemByIdForDetailScreen`를 추가했다.
- 상세 화면은 `widget.word` 초기 표시를 유지한 채 백그라운드에서만 phase 2 read를 시도한다.
- fallback reason에 `user_visible_display_mismatch`를 추가하고 in-memory observation 항목을 확장했다.
- repository 테스트에 detail-only success / empty fallback / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 phase 2 제한 적용 범위, rollback, 관측 기준을 반영했다.
