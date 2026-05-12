# Read Source Migration

## 2026-05-13 Phase 8-3A GraphBuilder dormant compatibility 표시

### 요약

- 이번 단계는 **GraphBuilder legacy/public helper 판단 결과를 deprecated marking으로만 반영한 first slice**다.
- active graph production path는 `WordGraphScreen` → `getVisibleGraphDataForGraph` → `GraphVisibleWord` / `GraphWordLabelDisplayItem` / `WordRelationEdgeInfo` → `WordGraphDataCache` → `GraphBuilder.buildMergedVisibleGraphData`로 유지한다.
- dormant builder repository path는 `GraphBuilder.buildFromRepository`와 `GraphBuilder.buildFromVisibleGraphData`로 분리해 해석한다.
- full `Word` 변환 helper인 `getWordByIdForGraphSingleWord`도 production active path가 아닌 dormant compatibility helper로 명시한다.

### 표시 대상

- `GraphBuilder.buildFromRepository`
- `GraphBuilder.buildFromVisibleGraphData`
- `WordRepository.getWordByIdForGraphSingleWord`

### 유지 범위

- API 삭제, signature 변경, graph screen center bootstrap 변경은 수행하지 않았다.
- `GraphBuilder.buildMergedVisibleGraphData`, `getWordMapByIdForGraphSingleWord`, `getWordMapByIdForGraphCenterSingleWord`, `getWordsByIdsForGraphBatch`, `getVisibleGraphDataForGraph`는 변경하지 않았다.
- stale test 정리와 public legacy API cleanup은 이번 단계 범위에 포함하지 않았다.

## 2026-05-12 Phase 8-2 Explorer bootstrap graph center typed 전환

### 요약

- 이번 단계는 **Explorer bootstrap graph center read 한정** raw carrier 축소다.
- `WordExplorerScreen` 초기 bootstrap은 `getWordMapByIdForGraphCenterSingleWord` raw row 대신 `getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord` typed display contract를 사용한다.
- bootstrap center seed는 `GraphCenterWordDisplayItem.wordId`, `representativeSpelling`, `displayStrongNumber`, `representativeTransliteration`만 소비한다.
- `representative spelling`, strong display, representative transliteration, center word id의 사용자 표시 의미는 기존 bootstrap seed 흐름과 같은 우선순위로 유지한다.

### 유지 범위

- `GraphBuilder`와 graph screen 자체 center bootstrap은 변경하지 않았다.
- `WordEditScreen(word: Map)` legacy constructor와 public legacy raw read API는 변경하지 않았다.
- `getWordMapByIdForGraphCenterSingleWord`는 삭제하지 않았다.
- DB schema와 UI 구조는 변경하지 않았다.

### 검증 기준

- repository graph center display contract 회귀 테스트를 유지한다.
- Explorer bootstrap 표시 contract 테스트는 typed center display 우선순위, split-view fallback, id-only fallback이 기존 bootstrap seed 의미를 유지하는지 확인한다.
- fallback 제어 흐름은 center typed item 우선, 없으면 selected detail display item 여부에 따른 기존 `idOnly` / split-view display fallback 순서를 유지한다.

### 클라이언트 UI 확인 결과

- Explorer 초기 bootstrap coherence 확인: 성공
- Explorer 초기 bootstrap fallback 체감 확인: 성공

## 2026-05-10 Phase 8-1 Home/Detail graph navigation existence check

### 요약

- 이번 단계는 **Home/Detail graph navigation existence check 한정** 정리다.
- `HomeScreen`과 `WordDetailScreen`의 graph 진입 전 존재 확인에서 raw `Map<String, dynamic>` word row read 의존을 제거했다.
- repository에 `wordExistsForGraphNavigation(String id)`를 추가해 `WORD_TABLE.id` 존재 여부만 확인하도록 분리했다.
- Home/Detail caller는 graph route 진입 전 더 이상 반환 row 필드를 사용하지 않는다.

### 유지 범위

- Explorer bootstrap은 변경하지 않았다.
- `GraphBuilder` 구조와 `buildFromRepository` 경로는 변경하지 않았다.
- `WordEditScreen(word: Map)` legacy constructor는 변경하거나 삭제하지 않았다.
- `getWordMapByIdForGraphCenterSingleWord`를 삭제하지 않았다.
- DB schema와 UI 구조는 변경하지 않았다.

### 검증 기준

- `wordExistsForGraphNavigation`은 `WORD_TABLE.id` 존재 확인만 수행한다.
- 표시 필드, expression row, graph center display projection은 이 존재 확인의 입력 조건이 아니다.
- Home/Detail graph navigation 실패 안내 동작은 기존과 동일하게 유지한다.

## 2026-05-10 edit seed / save result typed boundary history note

### 요약

- Edit seed read controlled zone 범위를 detail, explorer, graph create follow-up
  edit의 owner-specific edit read path로 확장했다.
- Graph create post-save payload에는 `readForGraphCreatePostSavePayload`
  controlled read context를 추가했다.
- `readForGraphCreatePostSavePayload`는 `NORMALIZED_WITH_FALLBACK`에 연결되며,
  기존 resolver / collector / fallback observation 흐름을 재사용한다.
- Edit route output은 raw `Map<String, dynamic>` result에서 최소 typed
  `WordEditSaveResult(wordId)`로 전환했다.
- Graph post-save relation payload data는 typed `GraphCreatePostSavePayload`
  repository boundary를 통해 읽는다.
- Graph create flow는 post-save relation payload를 만들 때 더 이상 raw
  `editedWordMap` / `postSaveWordMap` carrier에 의존하지 않는다.

### Boundary notes

- 이번 변경은 typed boundary 확대와 controlled-zone 후속 단계다.
- Read authority는 hybrid transition 상태로 유지된다.
- `LEGACY`와 `NORMALIZED_WITH_FALLBACK` context는 계속 공존한다.
- Fallback governance는 유지된다.
- `WORD_TABLE` compatibility projection은 유지된다.
- DB table/column/index storage는 변경하지 않았다.
- Raw read API와 legacy edit constructor는 후속 cleanup 판단을 위한
  compatibility surface로 유지한다.

## 2026-04-25 Phase 8-H 완료 기준 및 다음 Phase 이관

### 완료 범위

- Phase 8-H 완료 범위는 graph / explorer의 seed, display, callback, carrier 경계를 id 또는 최소 typed contract 중심으로 줄인 문서화 가능한 절편이다.
- graph seed / public seed는 `centerWordId` 중심으로 축소되었고, graph center state는 `_centerWordId` authority로 정리되었다.
- graph visible node / builder-cache carrier는 `GraphVisibleNode`, `GraphVisibleWord` 최소 typed contract로 축소되었다.
- graph selection callback과 center change callback은 id 중심 경로로 정리되었다.
- explorer center state는 `_centerWordId` 중심으로 정리되었고, explorer tooltip/history display baseline은 `_ExplorerCenterDisplaySeed` / tooltip display contract로 분리되었다.
- pending side-car, explorer bootstrap `Word.fromMap` 잔여 carrier, graph visible data projection의 `Word.fromMap` 우회, graph create/relation post-save의 `Word.fromMap` 우회는 제거되었다.

### 완료 선언 기준

- UX 정책 변경 없음.
- graph / explorer 주요 baseline은 유지한다.
- read/display/seed/callback 경계가 id 또는 typed contract 중심으로 정리되었다.
- 남은 항목은 별도 Phase 또는 UX 정책 판단 대상으로 분리할 수 있다.
- global Word.fromMap 제거는 다음 Phase 대상이다.

### 비대상/이관 항목

- history selected state는 UX 정책 판단 대상이다. `_ExplorerHistorySnapshot.selectedWordId`는 저장/비교되지만 apply 시 복원되지 않는다. 다음 Phase에서 history back/forward 시 선택 상태 복원 여부를 결정한다.
- global Word.fromMap 제거는 다음 Phase 대상이다. repository public API 반환형, generic `getWordById`, `getConnectedWords`, graph center legacy compatibility payload, `GraphBuilder.buildFromRepository`, tool/script 경로는 전역 영향이 있으므로 별도 Phase로 분리한다.
- analyzer/test baseline 정리는 별도 chore/fix 후보다. 오래된 테스트/API 참조와 tool script의 legacy carrier 가정은 이번 Phase 완료와 분리한다.

### 해석 제한

- Phase 8-H 완료는 사용자-visible UX 정책, DB schema, read source policy 변경을 포함하지 않는다.
- Phase 8-H 완료는 남은 generic repository API 또는 tool/script carrier 정리를 완료했다는 의미가 아니다.
- history selected state는 현재 정책 판단 대상으로 남기며, 결함으로 단정하지 않는다.

## 2026-04-25 Phase 8-H-42 graph create/relation post-save Word.fromMap residual cleanup first slice

### 이번 단계 요약

- 이번 단계는 graph create/relation post-save Word.fromMap residual cleanup first slice다.
- `WordGraphScreen`의 create/relation post-save 경계에서 `Word.fromMap(currentWordMap)` carrier 우회를 제거했다.
- 저장 완료 후속 흐름은 full `Word` 대신 local payload의 `wordId`, `representativeSpelling`만 사용한다.
- relation dialog의 대표 표기 fallback과 graph refresh/cache invalidation 흐름은 유지했다.

### 유지 범위

- global `Word.fromMap` 제거 아님
- repository public API 변경 아님
- graph center payload 전체 개편 아님
- UX 변경 아님
- history selected state 정책 변경 아님

## 2026-04-25 Phase 8-H-40 graph visible data Word.fromMap residual cleanup first slice

### 이번 단계 요약

- 이번 단계는 graph visible data Word.fromMap residual cleanup first slice다.
- repository 내부 graph visible data projection에서 `rows -> Word.fromMap(row) -> GraphVisibleWord` 우회 경로를 제거했다.
- `GraphVisibleWord`는 row의 `id`, `표기1`, `스트롱넘버`, `음역1` 값을 직접 trim해서 생성한다.
- `VisibleWordGraphData.connectedWords`의 반환 contract와 기존 relation edge order 기반 재정렬 흐름은 유지했다.

### 유지 범위

- global `Word.fromMap` 제거 아님
- repository public API 변경 아님
- graph builder/cache 변경 아님
- graph center payload 변경 아님
- SQL read policy / DB schema 변경 아님
- UX 변경 아님

## 2026-04-25 Phase 8-H-38 explorer bootstrap word carrier cleanup first slice

### 이번 단계 요약

- 이번 단계는 explorer bootstrap word carrier cleanup first slice다.
- `WordExplorerScreen` bootstrap center display seed 생성 경계에서 `Word.fromMap(centerWordMap)` 잔여 carrier를 제거했다.
- center display seed는 `centerWordMap`의 `id`, `스트롱넘버`, `표기1`, `음역1` 최소 필드만 직접 읽어 만든다.
- 대표 표기가 비면 `centerWordId`를 사용하고, Strong 표시는 기존 `formatWordDisplayStrong(...)` 기준을 유지한다.

### 유지 범위

- history selected state 정책 변경 아님
- global `Word.fromMap` 제거 아님
- graph 내부 `Word.fromMap` 변경 아님
- repository/DB 변경 아님
- graph callback contract 변경 아님
- tooltip UX 변경 아님

## 2026-04-25 Phase 8-H-37 pending display seed side-car final cleanup first slice

### 이번 단계 요약

- 이번 단계는 `pending display seed side-car final cleanup first slice`다.
- `WordExplorerScreen` center change 경로는 explorer에서 legacy `onChangeCenterWord(Word)` handler를 더 이상 전달하지 않고 `onChangeCenterWordId`만 주경로로 소비한다.
- `_pendingCenterDisplaySeedFallback` side-car와 소비 helper를 제거했다.
- center display seed는 center id 기준 `_loadSplitViewDisplayItem(centerWordId)` 결과로 `_ExplorerCenterDisplaySeed.fromDisplayItem`을 만들어 확정한다.
- split-view read가 `null`인 예외 경로에서는 id-only fallback을 허용하지만, 정상 center change 경로는 detail-like display item 기반 seed를 사용한다.

### 유지 범위

- tooltip UX 변경 아님
- history selected state 정책 변경 아님
- `Word.fromMap` 제거 아님
- `onChangeCenterWord(Word)` public API, repository/DB, graph callback contract 재수정 없음

## 2026-04-25 Phase 8-H-36 pending center fallback side-car cleanup first slice

### 이번 단계 요약

- 이번 단계는 explorer pending center fallback side-car cleanup first slice다.
- `WordExplorerScreen` center change 경로에서 pending fallback carrier를 `Word?`에서 `_ExplorerCenterDisplaySeed?`로 축소했다.
- `centerWordId` callback은 center change authoritative path로 유지하고, legacy `onChangeCenterWord(Word)`는 display seed 보정값 생성에만 사용한다.
- pending display seed fallback은 id callback의 `centerWordId`와 일치할 때만 소비하고, mismatch 시 폐기한다.

### 적용 범위

- `WordExplorerScreen` pending center fallback side-car 타입 축소
- center change callback 소비부의 id-first 경로 유지
- `_ExplorerCenterDisplaySeed` 기반 history tooltip/display baseline 유지

### 제외 범위

- `onChangeCenterWord(Word)` public API 제거
- history selected state 정책 / history payload schema
- tooltip UX
- repository/DB, `Word.fromMap` 일반 경계
- graph/explorer UX 정책

## 2026-04-25 Phase 8-H-34 explorer center state contract first slice

### 이번 단계 요약

- 이번 단계는 explorer center state contract first slice다.
- `WordExplorerScreen` 내부 authoritative center state를 full `_centerWord` carrier에서 `_centerWordId`로 줄였다.
- history tooltip/display baseline에 필요한 값은 private `_ExplorerCenterDisplaySeed` 최소 contract로 분리했다.
- `_pendingCenterWordChangeFallback`은 제거하지 않고, id 일치 시 display seed 보정용 compatibility side-car로 유지한다.

### 적용 범위

- `WordExplorerScreen` center id authority
- history entry 생성 시 center display seed 소비
- graph child `centerWordId` seed 전달 유지
- center change fallback display seed 보정 경계

### 제외 범위

- history selected state 복원 정책
- tooltip UX / history payload schema
- graph public API / graph callback contract
- repository/DB, `Word.fromMap` 일반 경계

## 2026-04-25 Phase 8-H-33 graph center change callback contract first slice

### 이번 단계 요약

- 이번 단계는 graph center change callback contract first slice다.
- `WordGraphScreen.onChangeCenterWordId`를 추가해 graph → explorer center change callback의 주 payload를 `centerWordId`로 줄였다.
- `WordExplorerScreen`은 id callback으로 center change를 소비하고, fallback `Word`는 history/tooltip baseline 유지를 위한 임시 보조 carrier로만 사용한다.
- fallback stash는 id가 일치할 때만 사용하고, mismatch면 폐기한다.

### 적용 범위

- `WordGraphScreen.onChangeCenterWordId`
- same-node 재탭 center change dispatch helper
- `WordExplorerScreen` center change callback 소비 경계

### 제외 범위

- explorer `_centerWord` 구조
- history payload / tooltip contract
- selection callback, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계
- graph/explorer UX 정책

## 2026-04-24 Phase 8-H-32 graph center state contract first slice

### 이번 단계 요약

- 이번 단계는 graph center state contract first slice다.
- `WordGraphScreen` 내부 center authoritative state를 `_centerWord`가 아니라 `_centerWordId`로 분리했다.
- cache key, stale guard, reload 기준, pending center focus 기준은 `_centerWordId`를 authoritative source로 사용한다.
- `_centerWord`는 local compatibility fallback carrier로만 유지하고, center display는 계속 `GraphCenterWordDisplayItem` reread 경로를 사용한다.

### 적용 범위

- `WordGraphScreen` 내부 center id authority
- base graph reload / cache key / stale guard / pending center focus
- builder input local adapter와 center tap compatibility fallback

### 제외 범위

- `onChangeCenterWord(Word)`, selection callback, explorer `_centerWord`, history payload/tooltip은 변경하지 않는다.
- graph builder public signature, repository/DB, `Word.fromMap` 일반 경계, graph UX 정책은 변경하지 않는다.

## 2026-04-23 Phase 8-H-30 graph selection callback contract first slice

### 이번 단계 요약

- 이번 단계는 graph selection callback contract first slice다.
- `WordGraphScreen.onSelectWordId`를 selection callback 주경로로 추가했다.
- `WordExplorerScreen._selectWord`는 full `Word` 대신 `selectedWordId`를 주 입력으로 받고, detail panel은 기존 split-view id reread 경로를 유지한다.
- 기존 `onSelectWord`는 compatibility fallback으로 유지한다.

### 유지 범위

- `onChangeCenterWord` 시그니처와 동작은 변경하지 않는다.
- `_centerWord`, `WordGraphScreen` public seed API, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않는다.
- explorer history payload/tooltip, graph selection UX, detail panel UX, navigation 정책은 변경하지 않는다.
- 이번 단계는 selection callback boundary 축소이며 graph interaction 전면 개편으로 해석하지 않는다.

## 2026-04-23 Phase 8-H-28 graph UI state visible node contract first slice

### 이번 단계 요약

- 이번 단계는 graph UI state visible node contract first slice다.
- `WordGraphScreen` 내부 `_graphWordsById` 저장 carrier를 full `Word`에서 `GraphVisibleNode`로 줄였다.
- `GraphVisibleNode`는 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration`만 보유한다.
- `GraphWordLabelDisplayItem` 주 label 경로는 유지하고, label contract가 없을 때만 `_graphWordsById`의 visible node fallback 값을 참조한다.

### 적용 범위

- `GraphVisibleNode`
- `WordGraphScreen._graphWordsById`
- visible node lookup / fallback display 경계

### 유지 범위

- `_centerWord`는 변경하지 않는다.
- `ValueChanged<Word>` callback, explorer callback, `WordGraphScreen` public API는 변경하지 않는다.
- repository/DB read policy, `Word.fromMap` 일반 경계, graph builder/cache carrier는 변경하지 않는다.
- relation add/search, detail panel, graph selection, explorer history, home/edit seed UX 정책은 변경하지 않는다.

## 2026-04-22 Phase 8-H-26 graph builder/cache carrier contract first slice

### 이번 단계 요약

- 이번 단계는 graph builder/cache carrier contract first slice다.
- `VisibleWordGraphData.connectedWords`에서 cache와 `GraphBuilder`로 전달되는 graph 내부 조립 carrier를 full `Word`에서 `GraphVisibleWord`로 줄였다.
- `GraphVisibleWord`는 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration`만 보유한다.
- `GraphWordLabelDisplayItem` 주경로는 유지하고, label contract가 없을 때만 `GraphVisibleWord` fallback 값을 사용한다.

### 적용 범위

- `GraphVisibleWord`
- `VisibleWordGraphData.connectedWords`
- `WordGraphDataCache` base/expansion payload
- `GraphBuilder` base/expansion input, node 생성, fallback label, 정렬, expansion / `+N more` 계산

### 유지 범위

- `WordGraphScreen` public API, `_centerWord`, `_graphWordsById`, callback 시그니처는 변경하지 않는다.
- repository/DB read policy와 `Word.fromMap` 일반 경계는 변경하지 않는다.
- graph seed public boundary, graph UX/interaction 정책, relation add/search, duplicate, home, edit seed 경계는 변경하지 않는다.
- 이번 단계는 graph internal state 전면 개편이나 `Word.fromMap` 제거 시작으로 해석하지 않는다.

## 2026-04-22 Phase 8-H-24 graph seed public API contract first slice

### 이번 단계 요약

- 이번 단계는 graph seed public API contract first slice다.
- `WordGraphScreen`의 주 seed contract를 `centerWordId`로 전환했다.
- 기존 `centerWord: Word`는 compatibility entrypoint로 유지하되, 실제 graph seed는 `centerWord.id.trim()`만 사용한다.
- graph 진입 caller는 full `Word` carrier 대신 `centerWordId`를 전달하도록 한 단계 축소했다.

### 적용 범위

- `WordGraphScreen` public seed boundary
- home/detail/explorer graph 진입 seed 전달부
- graph 내부에서 자기 자신을 다시 여는 seed 전달부

### 유지 범위

- center display / graph label / graph data는 기존 graph 내부 reread 결과 경로를 유지한다.
- `graph_builder`, `word_graph_cache`, repository, DB 구조는 변경하지 않는다.
- `Word.fromMap` 일반 경계와 explorer/history payload, graph selection / expansion / navigation UX 정책은 변경하지 않는다.

## 2026-04-22 Phase 8-H-22 graph seed id contract first slice

### 이번 단계 요약

- 이번 단계는 graph seed id contract first slice다.
- `WordGraphScreen(centerWord: Word)` public API는 유지한다.
- graph 내부 seed 소비 경계는 caller `Word` 전체가 아니라 `centerWord.id.trim()`만 bootstrap 기준으로 신뢰한다.
- center display / graph label / graph data는 기존 graph 내부 reread 결과 경로를 유지한다.

### 적용 범위

- `WordGraphScreen` 초기 center seed 설정
- `WordGraphScreen.didUpdateWidget` center seed 비교와 적용 경계
- `_loadConnectedWords` 요청 center id 고정 경계

### 유지 범위

- `graph_builder`, `word_graph_cache`, repository, DB 구조는 변경하지 않았다.
- `Word.fromMap` 일반 경계는 변경하지 않았다.
- explorer/history payload, graph selection / expansion / navigation UX 정책은 변경하지 않았다.

## 2026-04-21 Phase 8-H-20 explorer history payload ID contract first slice

### 이번 단계 요약

- 이번 단계는 explorer history payload ID contract first slice다.
- `_ExplorerHistorySnapshot`의 중심 payload를 `Word` 전체에서 `centerWordId`로 줄였다.
- history payload는 `centerWordId`, `selectedWordId` 최소 필드만 가진다.
- `_applyHistoryEntry`는 `centerWordId`로 `Word(id: ...)`를 만들어 기존 graph center reread 흐름에 연결한다.

### 적용 범위

- `WordExplorerScreen._ExplorerHistorySnapshot`
- `WordExplorerScreen._createHistoryEntry`
- `WordExplorerScreen._applyHistoryEntry`
- `WordExplorerScreen._isSameHistoryLocation`

### 유지 범위

- tooltip display contract는 Phase 8-H-18 결과를 유지한다.
- availability probe contract는 Phase 8-H-16 결과를 유지한다.
- `WordGraphScreen(centerWord: Word)`, graph seed public API, `Word.fromMap` 일반 경계, repository/DB 구조는 변경하지 않았다.
- back/forward history UX, selected history 복원 정책, 삭제된 entry fallback 정책은 변경하지 않았다.

## 2026-04-21 Phase 8-H-18 explorer history tooltip display contract first slice

### 이번 단계 요약

- 이번 단계는 explorer history tooltip display contract first slice다.
- history tooltip 표시가 navigation payload의 `Word` 전체 대신 `WordNavigationHistoryTooltipDisplay`의 최소 display 필드를 사용하도록 분리했다.
- `_ExplorerHistorySnapshot`, back/forward navigation 의미, graph seed, `Word.fromMap` 일반 경계, repository/DB 구조는 변경하지 않았다.

### 적용 범위

- `WordNavigationHistoryTooltipDisplay`
- `WordNavigationHistoryEntry` tooltip display 보유 경계
- `WordExplorerScreen._createHistoryEntry`
- `WordExplorerScreen._buildHistoryTooltip`
- history tooltip display contract 단위 테스트

### 구조 결과

- tooltip display 경로는 `wordId`, `representativeSpelling`, `displayStrongNumber`, `representativeTransliteration` 최소 필드만 소비한다.
- history availability와 기존 호출부 영향은 `WordNavigationHistoryEntry.wordId`, `representativeSpelling`, `strongNumber` getter를 유지해 제한했다.
- 이번 단계는 explorer/history UX 정책 변경, history payload 제거, graph seed 변경, `Word.fromMap` 일반 경계 제거 단계가 아니다.

## 2026-04-21 Phase 8-H-16 explorer history availability probe contract first slice

### 이번 단계 요약

- 이번 단계는 explorer history availability probe contract first slice다.
- `_isHistoryEntryAvailable`의 back/forward 직전 availability 재검증 경계를 full map read에서 id existence probe로 줄인다.
- explorer/history UI, tooltip/display, history payload, graph seed, `Word.fromMap` 일반 경계는 유지한다.

### 적용 범위

- `WordExplorerScreen._isHistoryEntryAvailable`
- `WordRepository.probeExistingWordIdsForExplorerHistory`

### 구조 결과

- history entry availability 재검증은 `wordId`만 사용한다.
- 재검증은 `probeExistingWordIdsForExplorerHistory`의 `Set<String>` 결과에 해당 id가 포함되는지 확인한다.
- back/forward availability UX와 삭제된 entry fallback 정책은 변경하지 않는다.

## 2026-04-20 Phase 8-H-15 duplicate candidate projection alias contract first slice

### 이번 단계 요약

- 이번 단계는 duplicate candidate projection alias contract first slice다.
- `DuplicateCandidateDisplayItem` public field 구조와 duplicate warning UI는 유지한다.
- strong exact / normalized strong / non-strong duplicate 비교 규칙은 유지하고, repository 내부 projection row alias만 canonical 집합으로 맞춘다.

### 적용 범위

- `WordRepository.findDuplicateCandidates`
- `WordRepository._findDuplicateCandidatesByNormalizedStrong`
- `WordRepository._buildDuplicateCandidateDisplayItem`

### 구현 방식

- duplicate candidate projection row는 `word_id`, `language`, `strong_number`, `representative_spelling`, `primary_meaning`만 helper에 공급한다.
- `_buildDuplicateCandidateDisplayItem`는 위 canonical alias만 읽어 `DuplicateCandidateDisplayItem`을 생성한다.
- normalized strong 경로도 같은 helper를 사용하게 해 duplicate candidate projection 입력 경계를 동일하게 유지한다.

### 구조 결과

- duplicate candidate query projection과 helper 입력 사이의 한글 slot alias 직접 의존이 한 단계 줄었다.
- 이번 단계는 duplicate UX 정책 변경, duplicate warning UI 변경, graph / explorer / history / edit seed / home search 경계 변경, `Word.fromMap` 일반 경계 제거 단계가 아니다.

## 2026-04-19 Phase 8-H-12 home search ranking candidate contract first slice

### 이번 단계 요약

- 이번 단계는 home search ranking candidate contract first slice다.
- `searchWordsMap`의 public 반환형과 `HomeSearchResultDisplayItem` display contract는 유지한다.
- `searchWordsMap` 내부 ranking helper가 raw row 전체 대신 ranking 입력 전용 `HomeSearchRankingCandidate`를 소비하도록 경계를 줄였다.
- `searchStrongExactMap`, `getStrongWordsMap`, Home UI, graph / explorer / detail / edit / duplicate / relation add search 경로는 이번 단계 범위에 포함하지 않는다.

### 적용 범위

- `HomeSearchRankingCandidate`
- `WordRepository.searchWordsMap` 내부 ranking loop
- `WordRepository._rankHomeSearchCandidate`

### 구현 방식

- SQL 후보 수집은 기존 `WORD_TABLE` row 수집 흐름을 유지한다.
- 후보 row에서 ranking에 필요한 `wordId`, `strongNumber`, indexed spellings / transliterations / meanings만 candidate로 변환한다.
- strong exact / prefix / partial, spelling exact / prefix / partial, transliteration exact / prefix / partial, meaning partial ranking priority는 기존 값을 유지한다.
- display projection은 기존 `_resolveHomeSearchDisplayItemsForPhase32(...)` 흐름을 유지한다.

### 구조 결과

- home search ranking 경로의 raw row 직접 소비가 ranking 전용 typed candidate로 한 단계 줄었다.
- 이번 단계는 home search public display contract 변경, search semantics 재설계, `Word.fromMap` 일반 경계 제거 단계가 아니다.

## 2026-04-18 Phase 8-H-11 graph center full display contract first slice

### 이번 단계 요약

- 이번 단계는 graph center full display contract first slice다.
- `_buildCenterNode`의 언어, strong, 대표 표기, 대표 음역, 대표 발음, 의미 표시만 `GraphCenterWordDisplayItem`으로 분리했다.
- `centerWord: Word`, `connectedWords`, graph navigation / selection / expansion / cache key / callback payload는 기존 흐름을 유지한다.
- peripheral node label, secondary label, relation display name은 Phase 8-H-9 결과를 유지한다.

### 적용 범위

- `GraphCenterWordDisplayItem`
- `WordRepository.getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord`
- `WordGraphScreen._buildCenterNode`

### 구현 방식

- repository는 center display 공급 전용 helper에서 center 표시 필드만 projection한다.
- representative spelling / transliteration / pronunciation은 representative row를 우선하고, representative row가 없을 때만 seq 우선 normalized row, 마지막으로 legacy slot을 사용한다.
- `displayStrongNumber`는 기존 center 표시와 동일하게 strong 표시 정규화를 유지한다.
- `primaryMeaning`은 기존 center node의 `meaning1` 표시 기준만 유지한다.

### 구조 결과

- center node full display 경로의 raw `Word` 직접 표시 의존을 줄였다.
- 이번 단계는 graph 전면 개편, `Word.fromMap` 일반 경계 제거, `connectedWords` 구조 변경 단계가 아니다.

## 2026-04-18 Phase 8-H-9 graph word label display contract first slice

### 이번 단계 요약

- 이번 단계는 graph word label display contract first slice다.
- graph peripheral title, secondary label, relation display name, graph builder label에 필요한 최소 typed contract를 도입했다.
- center node full display, `Word.fromMap` 일반 경계, graph navigation / selection / expansion 흐름은 이번 단계 범위에 포함하지 않는다.

### 적용 범위

- `GraphWordLabelDisplayItem`
- `WordRepository.getWordLabelDisplayItemsByIdsForGraphBatch`
- `VisibleWordGraphData.wordLabels`
- `GraphBuilder` node label 경계
- `WordGraphScreen` peripheral title / secondary label / relation display name 경계
- `WordGraphDataCache` label contract 보존

### 구현 방식

- repository는 기존 `connectedWords` 반환을 유지하면서 `wordLabels`를 병행 공급한다.
- label contract는 `wordId`, `representativeSpelling`, `representativeTransliteration`, `displayStrongNumber`만 포함한다.
- representative spelling / transliteration은 representative query projection 기준으로 공급하고, representative row가 없을 때만 기존 projection fallback을 사용한다.
- graph cache는 cache hit 이후에도 label contract가 유지되도록 payload 필드만 확장했다.

### 구조 결과

- graph label 관련 consumer가 `Word.spelling1`, `Word.transliteration1`, `Word.strongNumber` 직접 소비에 덜 의존하게 됐다.
- center node full display와 detail-like full row display는 기존 구조를 유지한다.
- 이번 단계는 graph label 전용 contract 검증 절편이며, legacy slot / `Word.fromMap` 제거 완료로 해석하지 않는다.

## 2026-04-18 Phase 8-H-7 edit seed typed contract first slice

### 이번 단계 요약

- 이번 단계는 edit seed typed contract first slice다.
- edit 화면 초기값에 필요한 최소 seed를 `WordEditSeed`로 묶고, `WordEditScreen`의 raw `Map<String, dynamic>` / legacy slot 직접 해석을 한 단계 줄인다.
- graph / home / search / `Word.fromMap` 일반 경계, history/undo/fallback, duplicate / relation add search는 이번 단계 범위에 포함하지 않는다.

### 적용 범위

- `WordEditSeed`
- `WordRepository.buildWordEditSeedFromWordRow`
- `WordEditScreen` 초기 seed 소비 경로
- `word_expression_set.dart` expression controller group 생성 경계

### 구현 방식

- edit seed contract는 `wordId`, `language`, `strongNumber`, `note`, `meanings`, `expressionReadResult`, `hiddenSlotIssues`만 포함한다.
- `language`, `strongNumber`, `note`, `wordId`, `meanings`의 해석 규칙은 기존 edit 초기화 동작과 동일하게 유지한다.
- expression seed는 `CanonicalExpressionReadResult`를 재사용하고, hidden-slot issue는 기존 write exclusion 의미를 유지한다.

### 구조 결과

- edit 초기 seed 경로가 일반 word row 전체 shape 대신 edit 전용 typed seed를 소비하도록 좁아졌다.
- `readLegacyWordExpressionRow()` compatibility helper는 유지하되, `WordEditScreen`의 직접 slot read 의존은 줄였다.
- 이번 단계는 edit 전면 개편이나 slot contract 제거 완료가 아니며, 저장 정책과 validation 흐름은 유지한다.

## 2026-04-14 Phase 8-H-5 home default strong list display contract first slice

### 이번 단계 요약

- 이번 단계는 `getStrongWordsMap()` 경로의 home default strong list display contract first slice다.
- `searchWordsMap`, `searchStrongExactMap`, home search ranking helper는 이번 단계 범위에 포함하지 않는다.
- Home 기본 strong 목록은 `wordId`, `displayStrongNumber`, `representativeSpelling` 최소 typed contract만 소비하도록 한 단계 더 축소한다.

### 적용 범위

- `getStrongWordsMap()`
- `HomeDefaultStrongListItem`
- `HomeScreen` 기본 strong 목록 consumer

### 구현 방식

- repository strong-list branch는 home default strong list 전용 typed contract를 직접 projection한다.
- representative spelling은 기본 strong 목록 contract에서 의미가 드러나는 이름으로 고정하고, strong-list mismatch 보호는 최소 contract 기준으로만 제한한다.
- home search 결과 contract, ranking semantics, graph / edit / `Word.fromMap` 일반 경계는 이번 단계에서 변경하지 않는다.

### 구조 결과

- Home 기본 strong 목록 경로가 generic `title` / `subtitle` shape 대신 의미가 드러나는 minimal display contract를 사용한다.
- 기본 strong 목록 consumer는 raw slot display shape를 직접 해석하지 않는다.
- home search, graph, edit, duplicate, graph relation add search 경로는 그대로 유지한다.

## 2026-04-13 Phase 8-H-4 graph relation add search contract first slice

### 이번 단계 요약

- 이번 단계는 graph relation add search consumer contract 축소 first slice다.
- `searchWords()`의 검색 semantics는 기존 `표기1`, `의미1`, `스트롱넘버` 부분일치 범위를 그대로 유지한다.
- graph relation add dialog는 raw `Word` 대신 graph relation add search 전용 최소 typed contract만 소비한다.

### 적용 범위

- `searchWords()`
- `WordGraphScreen` 관계 추가 대상 선택 다이얼로그

### 구현 방식

- repository query의 `WHERE 표기1 LIKE ? OR 의미1 LIKE ? OR 스트롱넘버 LIKE ?` 조건은 유지한다.
- query result는 representative query projection을 재사용해 `representativeSpelling` 표시값만 보수적으로 projection한다.
- typed contract 필드는 `wordId`, `representativeSpelling`, `primaryMeaning`, `displayStrongNumber`으로 제한한다.

### 구조 결과

- graph relation add dialog가 raw `Word`와 slot field를 직접 읽지 않게 됐다.
- search semantics 전면 변경 없이 graph relation add search 경로의 display contract만 한 단계 더 축소했다.
- home search, graph label / secondary label, 일반 `Word.fromMap` 경계, edit seed, history/undo/fallback 구조는 이번 단계 범위에 포함하지 않는다.

## 2026-04-13 Phase 8-H-3 duplicate display contract first slice

### 이번 단계 요약

- 이번 단계는 duplicate candidate query semantics 재설계가 아니라 duplicate warning display contract 축소 first slice다.
- `findDuplicateCandidates`의 strong 우선 규칙과 non-strong representative spelling 비교축은 그대로 유지한다.
- duplicate warning consumer는 raw `Map<String, dynamic>` 대신 duplicate warning 전용 최소 typed display contract만 소비한다.

### 적용 범위

- `findDuplicateCandidates`
- `WordEditScreen` duplicate warning dialog
- `WordGraphScreen` duplicate warning dialog

### 구현 방식

- repository query는 기존 SELECT / filter / exclude 흐름을 유지하고, 결과를 duplicate warning 표시용 typed contract로 projection한다.
- typed contract 필드는 `wordId`, `language`, `strongNumber`, `representativeSpelling`, `primaryMeaning`으로 제한한다.
- `primaryMeaning`는 이번 단계에서 기존 표시값 유지 목적만 담당하며 의미 구조 자체는 변경하지 않는다.

### 구조 결과

- duplicate warning 두 consumer가 raw slot display shape와 DB column key를 직접 읽지 않게 됐다.
- duplicate warning 경로에서 representative query + 좁은 display contract 패턴을 한 단계 더 고정했다.
- query semantics, duplicate policy, 다른 read/write 경로는 이번 단계 범위에 포함하지 않는다.

## 2026-04-12 Phase 8-H-1 representative query contract first slice

### 이번 단계 요약

- 이번 단계는 production slot contract 전체 제거가 아니라 collision / duplicate 조회 2경로의 representative query first slice다.
- `WORD_TABLE` slot direct-read를 representative-first query helper로 일부 전환하되, strong 우선 규칙과 기존 UI contract는 유지한다.
- search pipeline 전체, `Word.fromMap`, edit seed, history/undo/fallback 구조, graph 전체 label contract는 이번 단계 대상이 아니다.

### 적용 범위

- `findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups`
- `findDuplicateCandidates`
- duplicate warning dialog wording 최소 정리

### 구현 방식

- collision 조회는 `(언어, representative spelling, representative transliteration)` 축으로 충돌군을 판정한다.
- duplicate 조회는 strong case에서는 기존 strong 우선 규칙을 그대로 유지하고, non-strong case에서만 representative spelling 기준 비교로 전환한다.
- representative row가 있으면 해당 row를 그대로 사용한다.
- representative row가 없을 때만 seq 우선 normalized row, 마지막으로 legacy slot fallback을 검토한다.
- representative row가 존재하는데 transliteration이 blank인 경우 legacy `음역1`로 되돌아가지 않는다.

### 구조 결과

- collision / duplicate 두 production query에서 slot direct-read 의존이 한 단계 줄었다.
- representative query helper 패턴을 작은 범위에서 먼저 고정했고, 다음 slot contract 제거 절편의 기준을 마련했다.
- production slot contract 제거 완료를 의미하지는 않으며, 나머지 consumer와 owner-specific read는 후속 단계로 남겨 둔다.

## 2026-04-12 Phase 8-B expression write authority first switch

### 이번 단계 요약

- 이번 단계는 expression read completion 확대가 아니라 repository 내부 expression write authority의 first switch다.
- canonical write authority는 `word_expression_set` 기준으로 먼저 전환했다.
- `WORD_TABLE` expression slot은 제거하지 않고 계속 6-slot compatibility projection으로 유지한다.
- `getWordsByIds`, `getWordsMap`, 기타 legacy/dormant read 범위는 이번 단계에서 바꾸지 않았다.

### 구현 방식

- `createWord`, `updateWord`는 canonical expression set -> normalized row 저장 -> `WORD_TABLE` 6-slot projection 생성 순서를 따른다.
- `deleteWord`, `undoLastChange` history는 기존 `WORD_TABLE` compatibility snapshot을 유지한 채 normalized snapshot을 함께 저장한다.
- `undoLastChange`는 신규 history row에서 normalized restore를 우선 사용하고, 기존 history row는 legacy compatibility fallback을 유지한다.
- `>6 expression` 확장, dual-sync 제거, relation / import-export 변경은 이번 단계에 포함하지 않는다.

### 구조 결과

- repository 내부에서 canonical write authority 위치가 `word_expression_set` 기준으로 더 명확해졌다.
- `WORD_TABLE` slot은 projection/compatibility 역할로 낮아졌지만 아직 제거하지 않는다.
- dual-sync 종료 판단과 read completion 확대는 다음 단계 조건으로 남겨 둔다.

## 2026-04-12 Phase 8-A raw single-word first slice

### 이번 단계 요약

- 이번 단계는 expression read completion 전체를 끝내는 단계가 아니다.
- `WordRepository.getWordMapById`, `WordRepository.getWordMapByIdForExplorerSingleWord` 두 raw single-word public read만 first slice로 전환했다.
- fallback/source 선택은 새 정책이나 새 resolver를 만들지 않고, 기존 `_getResolvedWordRowForDetailLikeSingleWordRead`, `_resolveWordRowForDetailLikeDisplay` 재사용 범위로만 제한했다.
- `getWordsByIds`, `getWordsMap`, 기타 generic batch/list read는 이번 단계 대상이 아니며 기존 legacy read 경계를 유지한다.

### 적용 범위

- `WordRepository.getWordMapById`
- `WordRepository.getWordMapByIdForExplorerSingleWord`
- `test/data/repositories/word_repository_phase8a_expression_read_slice_test.dart`

### 구현 방식

- 두 public API의 반환 contract는 계속 raw `Map<String, dynamic>`로 유지한다.
- read source policy는 `getWordMapById`, `readForExplorerSingleWord` context에 한해 `NORMALIZED_WITH_FALLBACK`를 적용한다.
- 실제 row materialization은 기존 detail-like single-word helper를 그대로 재사용한다.
- visible display mismatch가 생기면 기존과 동일하게 legacy fallback을 유지한다.
- `>6 expression` 확장은 하지 않는다. 이번 단계 raw single-word read는 기존 compatibility projection 범위를 넘지 않는다.

### 구조 결과

- read completion이 single-word public raw read부터 실제로 시작되었음을 코드와 테스트로 고정했다.
- generic batch/list read는 아직 authority transition 이전의 compatibility-only legacy zone으로 남겨 두었다.
- 다음 단계에서 나머지 read 경로를 다룰 때도 동일한 원칙으로 owner-specific/public 경계를 좁혀서 확장할 수 있다.

## 2026-04-11 Phase 7-11 detail-like display shared contract 적용

### 이번 단계 요약

- 이번 단계의 목표는 WordDetailScreen 본문과 Explorer split-view 우측 패널이 공유하는 detail-like display boundary를 raw row에서 typed shared contract로 고정하는 것이다.
- `WordRepository.getWordDetailLikeDisplayItemByIdForDetailScreen`, `WordRepository.getWordDetailLikeDisplayItemByIdForSplitView`의 public 반환형은 이제 `WordDetailLikeDisplayItem`이다.
- fallback/source 선택 책임은 기존처럼 repository 내부 `_resolveWordRowForDetailLikeDisplay`에 두고, contract 생성은 detail-like single-word read 경계에서 수행한다.
- `WordInfoPanel`은 더 이상 raw `Map<String, dynamic>`를 해석하지 않고 `WordDetailLikeDisplayItem`만 렌더링하는 typed display renderer가 된다.
- `WordDetailScreen`, `WordExplorerScreen`은 같은 본문 contract를 공유하고, 화면별 액션/로딩/empty/error 책임만 유지한다.

### 적용 범위

- `lib/domain/word/word_detail_like_display_item.dart`
- `WordRepository._getWordDetailLikeDisplayItemByIdWithContext`
- `WordRepository.getWordDetailLikeDisplayItemByIdForDetailScreen`
- `WordRepository.getWordDetailLikeDisplayItemByIdForSplitView`
- `WordInfoPanel`
- `WordDetailScreen`
- `WordExplorerScreen`

### 구현 방식

- repository는 기존 `_buildWordDetailDisplaySignature`를 seed로 사용해 `WordDetailLikeDisplayItem`를 만드는 private builder를 추가한다.
- detail-like display fallback은 기존처럼 `_resolveWordRowForDetailLikeDisplay`에서 normalized/legacy visible mismatch를 판정한다.
- display contract 생성은 fallback이 끝난 row를 기준으로 repository 내부에서만 수행한다.
- `WordInfoPanel`은 contract의 `representativeSpelling`, `displayStrongNumber`, `language`, `spellings`, `transliterations`, `pronunciations`, `meanings`, `note`만으로 본문 섹션을 구성한다.
- Detail/Explorer의 edit/open-detail/open-graph 같은 화면 동작은 필요 시 on-demand raw reread를 사용하되, 그 raw 값이 다시 panel display boundary로 올라오지는 않게 한다.

### 구조 결과

- detail-like display는 이제 owner-shared display contract를 public boundary로 가진다.
- UI 본문 display에서 raw map 해석 책임이 제거되고 repository/contract 경계로 내려간다.
- `WordInfoPanel`은 shared typed display renderer가 되고, Detail과 Explorer의 차이는 본문이 아니라 외곽 상태와 액션에만 남는다.

## 2026-04-11 Phase 7-7 home search result display controlled contract 적용

### 이번 단계 요약

- 이번 단계의 목표는 home search result display의 public boundary를 raw row에서 controlled display contract로 고정하는 것이다.
- `WordRepository.searchStrongExactMap`, `WordRepository.searchWordsMap`의 public 반환형은 이제 `HomeSearchResultDisplayItem` 목록이다.
- raw `WORD_TABLE` row, normalized fallback 판단, display field 확정 책임은 repository 내부에만 남긴다.
- `HomeScreen` search branch는 더 이상 `Map<String, dynamic>`를 직접 해석하지 않고 contract만 소비한다.
- `searchWordsMap('')`는 더 이상 generic `getWordsMap(limit: limit)` browse path로 내려가지 않고 빈 결과를 반환한다.

### 적용 범위

- `lib/domain/home/home_search_result_display_item.dart`
- `WordRepository.searchStrongExactMap`
- `WordRepository.searchWordsMap`
- `WordRepository._resolveHomeDisplayRowsForPhase32` 이후 home search display contract 변환 경계
- `HomeScreen` search result branch

### 구현 방식

- repository는 기존 Phase 3.2 fallback / display signature 비교 구조를 유지한다.
- `searchStrongExactMap`, `searchWordsMap`는 legacy row를 모은 뒤 `_resolveHomeDisplayRowsForPhase32`로 fallback이 반영된 display row를 먼저 확정한다.
- 확정된 display row는 repository 내부 helper에서 `HomeSearchResultDisplayItem`으로 변환한다.
- contract field는 `wordId`, `displayStrongNumber`, `representativeSpelling`, `representativeTransliteration`, `representativePronunciation`, `subtitleMeaning`으로 고정한다.
- empty string display value는 contract에서 nullable로 흡수한다.

### 구조 결과

- home search result display는 owner-specific display contract를 public boundary에 가진다.
- UI는 title / subtitle / navigation action을 contract 값만으로 구성한다.
- search branch의 raw row convenience 의존은 제거된다.
- empty keyword browse path는 search contract 밖으로 밀어냈고, 이번 단계에서는 빈 결과 반환으로 고정했다.

## 2026-04-11 Phase 7-4 home search navigation owner reread 적용

### 이번 단계 요약

- 이번 단계는 search ranking이나 search display 계산을 바꾸는 단계가 아니다.
- 목적은 Home search 결과가 navigation payload 책임에서 빠지고 display surface 쪽으로 더 순수해지게 만드는 것이다.
- search branch는 detail / explorer / graph 진입 모두 `wordId` 기준으로 정규화했다.
- detail / graph는 HomeScreen에서 owner-specific reread 후 navigate 하도록 맞췄다.
- explorer는 route full row를 제거하고 screen 내부 bootstrap에서 owner reread로 초기 상태를 만든다.

### 적용 범위

- `HomeScreen._openWordDetail`
- `HomeScreen._openWordExplorer`
- `HomeScreen._openWordGraph`
- `WordExplorerScreen` initial bootstrap / history seed

### 구현 방식

- search branch는 더 이상 `searchWordsMap` / `searchStrongExactMap` 결과 row 전체를 navigation payload로 직접 넘기지 않는다.
- Home search -> detail:
  - payload = `wordId`
  - owner read = `getWordDetailLikeDisplayItemByIdForDetailScreen`
- Home search -> graph:
  - payload = `wordId`
  - owner read = `getWordMapByIdForGraphCenterSingleWord`
- Home search -> explorer:
  - payload = `wordId`
  - center bootstrap = `getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord`
  - selected panel bootstrap = `getWordDetailLikeDisplayItemByIdForSplitView`

### explorer 초기 구조 정리

- 기존에는 `initialWordMap` 한 개가 center seed, selected panel 초기값, history seed를 동시에 맡았다.
- 이번 단계에서는 route payload를 `initialWordId`로 줄였다.
- explorer는 init bootstrap에서 graph center read와 split-view read를 각각 호출해 초기 상태를 구성한다.
- history snapshot은 full selected row 대신 selected word id만 보관한다.
- history availability probe는 기존처럼 `readForExplorerSingleWord` / `probeExistingWordIdsForExplorerHistory` 경로를 유지한다.

### 구조 결과

- search result row는 여전히 display materialization row이지만 Home navigation payload로는 직접 사용되지 않는다.
- Home search display contract와 navigation contract 경계가 이전보다 선명해졌다.
- explorer는 여전히 controlled zone은 아니지만 route full row convenience 의존은 제거됐다.

## Phase 6-A controlled zone 판정 기준

### 목적

- 이 섹션은 read context 분류 기준을 구조 정책으로 정의한다.
- 이 섹션의 문장은 이후 read 설계와 승격 판단에 재사용하는 기준 문장으로 사용한다.

### read context 3계층 구조

- `controlled zone`
- `readForGraphBatch`
- `readForGraphCenterSingleWord`
- `readForGraphSingleWord`
- `owner-specific but not controlled`
- `probeExistingWordIdsForExplorerHistory`
- `legacy generic`
- `getWordsByIds`

### controlled zone 정의

- controlled zone은 단순 owner-specific zone으로 정의하지 않는다.
- controlled zone은 아래 조건을 모두 만족하는 context만 포함한다.
- owner-specific display read여야 한다.
- 반환 의미가 특정 owner display contract에 대해 고정되어야 한다.
- fallback 결과를 구조적으로 해석할 수 있어야 한다.
- collector 결과를 구조적으로 해석할 수 있어야 한다.
- UI display와 직접 연결되어야 한다.
- 위 조건 중 하나라도 만족하지 못하면 controlled zone으로 분류하지 않는다.

### probe 계층 정의

- owner-specific이라고 해서 자동으로 controlled가 되지 않는다.
- probe와 display는 구조적으로 분리한다.
- `probeExistingWordIdsForExplorerHistory`는 흐름 판정용 probe context로 정의한다.
- `probeExistingWordIdsForExplorerHistory`는 display read가 아니다.
- `probeExistingWordIdsForExplorerHistory`는 controlled zone에 포함하지 않는다.
- availability 또는 흐름 판정으로 계약이 제한된 probe context는 owner-specific이어도 controlled가 아니다.

### generic 계층 정의

- generic read는 controlled 후보가 아니다.
- owner가 없는 context는 controlled로 분류할 수 없다.
- `getWordsByIds`는 legacy generic context로 정의한다.
- generic context는 장기 축소 대상이다.
- controlled 검토는 generic 재사용에서 분리된 이후에만 수행한다.

### 계층 비교

| Tier | Contexts | Owner | Primary purpose | Return contract | Controlled eligibility |
| --- | --- | --- | --- | --- | --- |
| Controlled zone | `readForGraphBatch`, `readForGraphCenterSingleWord`, `readForGraphSingleWord` | `graph` | display | graph display contract | eligible and fixed |
| Owner-specific but not controlled | `probeExistingWordIdsForExplorerHistory` | `explorer history` | probe | existence / flow judgement | not controlled |
| Legacy generic | `getWordsByIds` | none | generic batch helper | generic full row batch | not eligible |

### controlled 판정 checklist

- 단일 owner가 존재하는가.
- probe나 internal helper가 아니라 display read인가.
- 반환 의미가 하나의 owner display contract에 대해 고정되는가.
- fallback 결과를 구조적으로 해석할 수 있는가.
- collector 결과를 구조적으로 해석할 수 있는가.
- UI display와 직접 연결되는가.
- generic 재사용에서 이미 분리되었는가.

### controlled 승격 절차

- read 승격은 아래 순서를 기준으로 판단한다.

```text
generic
-> owner-specific 분리
-> 반환 계약 고정
-> 관측/검증 가능성 확보
-> controlled 판정
```

- controlled 판정은 generic 분리 이전에 수행하지 않는다.
- owner-specific 분리만으로 controlled를 인정하지 않는다.
- probe context는 별도 고정 계약과 재검토 기준이 마련되기 전까지 controlled zone 밖에 둔다.

## 2026-04-11 Phase 5 explorer history probe context 분리

### 이번 단계 요약

- 이번 단계는 controlled 승격이 아니라 explorer history existence probe 분리 단계다.
- history navigation availability 판단은 더 이상 generic `getWordsByIds` full row read를 사용하지 않는다.
- explorer history owner 전용 probe API를 추가하고 반환값을 `Set<String>` 으로 최소화한다.
- `getWordsByIds` 는 그대로 generic legacy helper로 유지한다.
- 기존 controlled zone, safe zone, write 경로는 변경하지 않는다.

### 적용 범위

- `WordRepository.probeExistingWordIdsForExplorerHistory`
- `WordExplorerScreen._loadExistingHistoryWordIds`
- history probe 전용 repository test

### 구현 방식

- probe API 는 `SELECT id FROM WORD_TABLE WHERE id IN (...)` 만 수행한다.
- probe API 는 내부적으로 `getWordsByIds` 를 호출하지 않는다.
- full row 반환, display 해석, read source collector 연결을 모두 피한다.
- query 실행부 근처에 probe 전용 collector TODO 만 남기고 이번 단계에서는 실제 collector event 를 추가하지 않는다.

### 구조적 의미

- explorer history caller는 존재 여부 판단만 필요하므로 full row overfetch 가 제거된다.
- generic batch read 는 남아 있지만 history probe owner 는 별도 API 와 반환 계약으로 분리된다.
- 이번 단계의 목적은 generic helper 제거가 아니라 owner-specific probe context 분리다.

## 2026-04-10 Phase 5 graph single-word controlled zone 적용

### 이번 단계 요약

- 이번 단계의 단일 승격 대상은 `readForGraphSingleWord` 하나뿐이다.
- graph-owned single follow-up read를 `LEGACY` 에서 `NORMALIZED_WITH_FALLBACK` controlled zone으로 올린다.
- `getWordsByIds` 는 generic batch contract를 유지하기 위해 그대로 legacy zone에 둔다.
- split/detail/save/undo safe zone과 기존 graph batch / graph center controlled zone은 변경하지 않는다.

### 적용 범위

- `WordRepository.getWordMapByIdForGraphSingleWord`
- `readForGraphSingleWord` collector context
- graph single-word 전용 repository test / command verify

### 제외 범위

- `readForGraphBatch`
- `readForGraphCenterSingleWord`
- generic `getWordsByIds`
- split/detail/save/undo safe zone
- create/update/delete/write 경로

### 구현 방식

- `readForGraphSingleWord` context 자체는 그대로 유지한다.
- graph single-word read는 detail-like single-word resolver를 재사용하되 collector context는 `readForGraphSingleWord` 로 고정한다.
- stable case는 `final=normalized` 로 남기고, user-visible display mismatch는 `final=legacyFallback` 으로 되돌린다.
- fallback reason과 collector summary 구조는 기존 controlled/safe zone과 같은 체계를 재사용한다.

### collector 기대 상태

- stable case: `context=readForGraphSingleWord`, `policy=normalizedWithFallback`, `final=normalized`
- mismatch case: `context=readForGraphSingleWord`, `policy=normalizedWithFallback`, `final=legacyFallback`, `reason=userVisibleDisplayMismatch`
- summary contexts 는 `readForGraphSingleWord` 하나만 남아 graph batch / graph center / safe zone 과 섞이지 않아야 한다.

### command 검증

- `flutter test --no-pub test/data/repositories/word_repository_read_source_policy_test.dart`
  - 결과: graph single-word path 포함 전체 테스트 통과
- `dart run tool/verify_graph_single_word_context.dart`
  - 결과: stable normalized / mismatch fallback / isolated collector context 확인
- `dart run tool/verify_graph_batch_context.dart`
  - 결과: 기존 graph batch controlled zone 회귀 없음
- `dart run tool/verify_graph_center_context.dart`
  - 결과: 기존 graph center controlled zone 회귀 없음

## 2026-04-09 Phase 4-E graph batch policy zone 적용

### 이번 단계 핵심

- 이번 단계 대상은 graph 전체가 아니라 `readForGraphBatch` 하나뿐이다.
- center node, `readForGraphSingleWord`, graph↔split 연결은 이번 단계에서 수정하지 않는다.
- graph batch는 독립된 policy zone 으로 유지하고, shared safe zone 은 wrapper 를 통해서만 재사용한다.

### 적용 범위

- `WordRepository.getWordsByIdsForGraphBatch`
- `readForGraphBatch` collector context
- graph batch 전용 command 검증 / repository 테스트

### 제외 범위

- center node external input boundary
- `readForGraphSingleWord`
- generic `getWordsByIds`
- graph↔split 연결 재설계

### 구현 방식

- `readForGraphBatch` context 만 `NORMALIZED_WITH_FALLBACK` 대상으로 승격한다.
- graph batch 전용 adapter 가 batch 입력 정리, collector context 유지, shared resolver 호출 통제를 담당한다.
- adapter 내부에서는 detail/split safe zone 이 이미 사용 중인 detail-like display guard 를 재사용한다.
- 반환 데이터는 기존 graph UI 계약을 유지하는 legacy-shaped row 이고, source policy 만 승격한다.
- fallback 규칙은 detail/split safe zone 보다 넓히지 않는다.

### collector 기대 상태

- graph batch normalized success 는 `context=readForGraphBatch`, `final=normalized` 로 남는다.
- graph batch display mismatch 는 `context=readForGraphBatch`, `final=legacyFallback` 로 남는다.
- 같은 word 를 generic batch 로 다시 읽으면 summary contexts 에 `getWordsByIds|readForGraphBatch` 가 함께 남아 문맥 분리가 가능해야 한다.

### command 검증

- `flutter test --no-pub test/data/repositories/word_repository_read_source_policy_test.dart --plain-name "WordRepository graph batch path"`
  - 결과: 2개 테스트 통과
- `dart run tool/verify_graph_batch_context.dart`
  - 결과: graph batch normalized success / display-mismatch fallback / generic batch legacy / summary contexts 분리 확인
  - 주의: 로컬 sqlite native hook 실행 권한이 필요할 수 있다.

## 2026-04-08 Phase 4-B split view normalized path 적용

### 현재 기준

- split view 우측 패널 표시 read는 더 이상 direct DB read가 아니다.
- UI 경로는 `WordExplorerScreen._loadSplitViewDisplayItem -> WordRepository.getWordDetailLikeDisplayItemByIdForSplitView` 이다.
- `readForSplitViewSingleWord` context 는 `NORMALIZED_WITH_FALLBACK` 대상이다.
- split view wrapper 는 detail-like single-word resolver 를 재사용하고, 반환값은 기존 `WordInfoPanel` 계약을 유지하는 `WordDetailLikeDisplayItem` 이다.
- collector 에서는 context=`readForSplitViewSingleWord` 기준으로 success=`normalized`, fallback=`legacy_fallback` 을 해석한다.
- history availability probe 는 Phase 8-H-16 기준으로 back/forward 직전 재검증까지 `probeExistingWordIdsForExplorerHistory` id existence probe 를 사용한다.
- 이 섹션은 문서 안의 예전 “split view direct DB read 위험 경로” 메모보다 최신 상태를 우선한다.

## 2026-04-04 Phase 3.3 undo path 적용

### 이번 단계 성격

- 이번 단계는 Phase 3.3 전체 완료가 아니다.
- 이번 단계는 `undo` 직후 single-word reread를 Home owner 기준으로 safe zone에 편입하는 작업이다.
- 적용 context는 `readAfterUndoSingleWord` 하나뿐이다.

### 이번 단계 적용 범위

- `HomeScreen._undoLastChange`
- `WordRepository.undoLastChange`
- `WordRepository.getWordMapByIdForReadAfterUndoSingleWord`
- 관련 collector / fallback / command 검증 기록

### 이번 단계 제외 범위

- split view direct DB read 수정
- graph single-word read policy 변경
- explorer single-word read policy 변경
- generic `getWordMapById` 정책 변경
- detail phase 2 context 정책 변경
- `normalizedOnly` 전환

### primaryWordId 산정 규칙

- undo group 안의 `entity_type == 'word'` 기준 unique word id가 정확히 1개일 때만 후보를 만든다.
- 후보 word id가 undo 완료 후 `WORD_TABLE`에 실제로 존재할 때만 `primaryWordId`로 확정한다.
- `primaryWordId != null`일 때만 Home이 `readAfterUndoSingleWord` single-word reread를 정확히 1회 수행한다.
- 이후 기존 `_createWordsFuture()` multi-read refresh는 그대로 유지한다.

### 구현 방식

- `readAfterUndoSingleWord` context만 `NORMALIZED_WITH_FALLBACK` 적용 대상으로 추가한다.
- undo single-word reread는 save path와 같은 detail-like display guard를 재사용한다.
- mismatch 또는 adapter/query 문제는 기존 fallback reason 체계를 그대로 사용한다.

## 2026-04-04 Phase 3.3 save path 적용

### 이번 단계 성격

- 이번 단계는 Phase 3.3 전체 완료가 아니다.
- 이번 단계는 edit 저장 직후 single-word reread save path만 safe zone으로 확장한다.
- 적용 context는 `readAfterSaveSingleWord` 하나뿐이다.

### 이번 단계 적용 범위

- `WordEditScreen._save` 저장 직후 reread
- `WordRepository.getWordMapByIdForReadAfterSaveSingleWord`
- 관련 collector / fallback / command 검증 기록

### 이번 단계 제외 범위

- undo single-word reread 구현
- split view direct DB read 수정
- graph single-word read policy 변경
- explorer single-word read policy 변경
- generic `getWordMapById` 전체 정책 변경
- detail phase 2 context 정책 변경
- `normalizedOnly` 전환

### 구현 방식

- `readAfterSaveSingleWord` context만 `NORMALIZED_WITH_FALLBACK` 적용 대상으로 추가한다.
- save reread는 normalized read를 시도한 뒤 legacy-shaped row로 materialize한다.
- 사용자 가시 필드가 detail display 기준으로 일치하면 normalized 결과를 사용한다.
- mismatch 또는 adapter/query 문제는 기존 fallback reason 체계를 그대로 사용한다.

### display guard 기준

save path reread는 detail 화면이 최초로 받는 row이므로 detail display 기준을 재사용한다.

- representative spelling
- spelling list
- transliteration list
- pronunciation list
- meaning list
- language
- strong number
- note

### 실제 command 테스트 대상

선정 SQL:

```sql
SELECT id,
       TRIM("스트롱넘버") AS strong_number,
       TRIM("표기1") AS spelling,
       TRIM("발음1") AS pronunciation
FROM WORD_TABLE
WHERE "스트롱넘버" IS NOT NULL
  AND TRIM("스트롱넘버") <> ''
  AND "표기1" IS NOT NULL
  AND TRIM("표기1") <> ''
ORDER BY
  CASE UPPER(SUBSTR(TRIM("스트롱넘버"), 1, 1))
    WHEN 'H' THEN 0
    WHEN 'G' THEN 1
    ELSE 2
  END,
  CAST(SUBSTR(TRIM("스트롱넘버"), 2) AS INTEGER),
  id
LIMIT 1;
```

실제 대상:

- `id = H0001_0000`
- strong number = `H0001`
- original spelling = `אָב`
- original pronunciation = `awb`
- test spelling = `אָב__SAVE33`

### command 테스트 결과

save 직후 immediate reread:

- context = `readAfterSaveSingleWord`
- policy = `NORMALIZED_WITH_FALLBACK`
- final result source = `normalized`
- fallback = `false`
- DB value = `אָב__SAVE33`
- reread value = `אָב__SAVE33`

교차 read:

- detail reread = `אָב__SAVE33`
- strong exact search = `אָב__SAVE33`
- strong list = `אָב__SAVE33`
- cross read consistent = `true`

context 확인:

- full contexts = `getStrongWordsMap`, `getWordDetailLikeDisplayItemByIdForDetailScreen`, `readAfterSaveSingleWord`, `searchStrongExactMap`
- unexpected context = 없음
- fallback reason summary = 없음

원복 확인:

- restore context = `readAfterSaveSingleWord`
- restore final result source = `normalized`
- restore fallback = `false`
- restore DB value = `אָב`
- restore reread value = `אָב`
- restore cross read consistent = `true`

### UI 확인 방법

UI 시나리오 1:

- 특정 단어 편집 화면 진입
- spelling 또는 pronunciation 수정
- 저장
- 저장 직후 상세 화면 값 확인

기대 결과:

- 방금 저장한 값이 즉시 보인다.
- 잠시 후 값이 다시 바뀌지 않는다.

실패 관찰 포인트:

- 처음에는 예전 값이 보였다가 잠시 후 새 값으로 바뀌는지
- 일부 필드만 늦게 갱신되는지

UI 시나리오 2:

- 저장 직후 뒤로 이동
- 홈에서 strong exact 또는 strong list로 같은 단어 재조회
- 다시 상세 진입

기대 결과:

- 상세 / 검색 / 목록 값이 동일하다.

실패 관찰 포인트:

- 화면마다 값이 다르게 보이는지
- 상세만 다르거나 목록만 다른지

### 남은 범위

- undo single-word reread는 아직 설계 후보 단계다.
- split view direct DB read는 여전히 별도 위험 경로다.
- graph / explorer single-word read는 context 분리만 완료했고 정책은 그대로 유지한다.

## 2026-04-04 Phase 3.3 진입 조건 확보 작업

### 이번 단계 성격

- 이번 단계는 Phase 3.3 완료 단계가 아니다.
- 이번 단계 목적은 single-word read를 의도 단위로 관측 가능하게 만드는 것이다.
- read policy 변경, normalized 확장, undo single-word reread 구현, split view direct DB read 수정은 포함하지 않는다.

### context 분리 결과

기존 method:

- `WordRepository.getWordMapById`

추가 context:

- `readAfterSaveSingleWord`
- `readForGraphSingleWord`
- `readForExplorerSingleWord`

구현 방식:

- `getWordMapById`는 그대로 유지한다.
- repository 내부에 context 전달용 공용 helper를 두고 wrapper만 추가한다.
- wrapper에서만 collector context를 다르게 전달한다.

연결된 UI 경로:

- `readAfterSaveSingleWord`
  - `WordEditScreen._save`
- `readForGraphSingleWord`
  - `WordGraphScreen` 신규 단어 생성 후 단건 reread
  - `GraphBuilder.buildFromRepository` center word 단건 read
- `readForExplorerSingleWord`
  - `WordExplorerScreen._isHistoryEntryAvailable`

이번 단계 제외:

- `WordExplorerScreen._loadWordMap`
- `WordExplorerScreen._refreshSelectedWord`
- 그 외 기존 `getWordMapById` generic 호출

### undo single-word reread 설계 후보

후보 1:

- UI 위치: detail 화면이 열린 상태에서 global undo 수행 직후
- 호출 method: `getWordMapByIdForReadAfterUndoSingleWord` 또는 detail 전용 wrapper
- 장점: 사용자가 undo 결과를 가장 직접적으로 확인할 수 있다.
- 리스크: 현재 undo 진입점이 home 화면이라 active detail surface와 상태 연결 방식이 추가로 필요하다.

후보 2:

- UI 위치: explorer에서 현재 선택된 단어가 있을 때 undo 직후
- 호출 method: explorer 전용 single-word wrapper + selected word id 기준 reread
- 장점: split view 우측 패널과 실제 복원 결과를 바로 비교할 수 있다.
- 리스크: 현재 explorer detail panel은 direct DB read라 repository 경유 설계 정리가 먼저 필요하다.

후보 3:

- UI 위치: 마지막 변경 word id를 undo 결과로 반환한 뒤 home/detail/explorer가 공통 후처리
- 호출 method: `readAfterUndoSingleWord` 전용 wrapper
- 장점: UI surface와 collector context를 같은 의미 단위로 맞출 수 있다.
- 리스크: undo API 반환 구조가 바뀌므로 이번 단계 범위를 넘는다.

### direct DB read 경로

- 경로: `WordExplorerScreen._loadWordMap`
  - 사용 위치: split view 선택 단어 detail panel 로드
  - read 데이터 종류: `WORD_TABLE` 단건 row
  - repository 전환 필요성: 높음

- 경로: `WordExplorerScreen._refreshSelectedWord`
  - 사용 위치: detail 화면 복귀 후 selected word refresh
  - read 데이터 종류: `_loadWordMap`을 통한 `WORD_TABLE` 단건 row
  - repository 전환 필요성: 높음

현재 Phase 3.3 범위에서 추가로 확인된 UI single-word direct DB read는 위 2개다.

### command 테스트 결과

테스트 대상 SQL:

```sql
SELECT id,
       TRIM("스트롱넘버") AS strong_number,
       TRIM("표기1") AS spelling
FROM WORD_TABLE
WHERE "스트롱넘버" IS NOT NULL
  AND TRIM("스트롱넘버") <> ''
  AND "표기1" IS NOT NULL
  AND TRIM("표기1") <> ''
ORDER BY
  CASE UPPER(SUBSTR(TRIM("스트롱넘버"), 1, 1))
    WHEN 'H' THEN 0
    WHEN 'G' THEN 1
    ELSE 2
  END,
  CAST(SUBSTR(TRIM("스트롱넘버"), 2) AS INTEGER),
  id
LIMIT 1;
```

실제 테스트 대상:

- `id = H0001_0000`
- original spelling = `אָב`

context 테스트 결과:

- save reread
  - last context: `readAfterSaveSingleWord`
  - summary contexts: `readAfterSaveSingleWord`
  - fallback: 0
- graph read
  - last context: `readForGraphSingleWord`
  - summary contexts: `readForGraphSingleWord`
  - fallback: 0
- explorer read
  - last context: `readForExplorerSingleWord`
  - summary contexts: `readForExplorerSingleWord`
  - fallback: 0

보조 확인:

- 테스트 중 save/undo 원복은 정상 동작했고 최종 spelling은 원래 값으로 복원되었다.
- command 기준으로 context가 generic `getWordMapById`에 남지 않고 분리된 wrapper context로 기록되었다.

### 이번 단계 판단

- `readAfterSaveSingleWord` 분리: 완료
- `readForGraphSingleWord` 분리: 완료
- `readForExplorerSingleWord` 분리: 완료
- direct DB read 경로 식별: 완료
- undo single-word reread 구현: 미포함
- Phase 3.3 진입 가능 여부: 조건부 가능

조건부 가능으로 보는 이유:

- save 기준 single-word reread는 이제 독립 context로 관측된다.
- direct DB blind spot은 식별되었지만 아직 수정되지 않았다.
- undo single-word reread는 설계 후보만 있고 실제 경로는 아직 없다.

## 2026-04-04 Phase 3.2 홈 목록/검색 결과 표시 read 확장

### 이번 단계 적용 범위

- `WordRepository.getStrongWordsMap`
- `WordRepository.searchStrongExactMap`
- `WordRepository.searchWordsMap`

대상 surface:

- 홈 기본 Strong 목록 결과 표시
- 홈 Strong exact 검색 결과 표시
- 홈 일반 검색 결과 표시
- 상세 복귀 후 동일 home surface 재조회
- undo 후 동일 home surface 재조회

이번 단계 비대상:

- 검색 후보 산출 로직 자체
- split view direct DB read
- graph 관련 read
- edit 전용 single-word reread

### 구현 방식

- 대상 context 3개만 `NORMALIZED_WITH_FALLBACK`으로 승격한다.
- fallback reason, collector 구조, direct DB read 구조는 변경하지 않는다.
- normalized read가 성공하면 legacy-shaped row를 다시 materialize해서 홈 표시용 row로 반환한다.
- 표시용 signature가 legacy row와 다르면 `user_visible_display_mismatch`로 기존 fallback을 유지한다.

helper 정리:

- 기존 detail 전용 이름이던 materialize helper를 공용 display materialize helper로 일반화했다.
- detail 비교는 기존 Phase 2 전용 비교 규칙을 유지한다.
- home 목록/검색 결과 표시는 Phase 3.2 전용 resolver에서 별도 signature 비교를 수행한다.

### 홈 표시용 비교 기준

`getStrongWordsMap`

- strong number
- representative spelling

`searchStrongExactMap`, `searchWordsMap`

- strong number
- representative spelling
- representative transliteration
- representative pronunciation
- subtitle meaning(`의미1` 우선, 없으면 `의미`)

canonical semantic equality만으로 통과시키지 않고, 실제 홈 화면 표시 필드가 같을 때만 normalized 결과를 통과시킨다.

### 실제 keyword 고정

선정 SQL:

```sql
SELECT TRIM("스트롱넘버") AS keyword
FROM WORD_TABLE
WHERE "스트롱넘버" IS NOT NULL
  AND TRIM("스트롱넘버") <> ''
  AND UPPER(SUBSTR(TRIM("스트롱넘버"), 1, 1)) IN ('H', 'G')
ORDER BY
  CASE UPPER(SUBSTR(TRIM("스트롱넘버"), 1, 1))
    WHEN 'H' THEN 0
    WHEN 'G' THEN 1
    ELSE 2
  END,
  CAST(SUBSTR(TRIM("스트롱넘버"), 2) AS INTEGER),
  id
LIMIT 1;
```

```sql
SELECT id, TRIM("표기1") AS spelling
FROM WORD_TABLE
WHERE "표기1" IS NOT NULL
  AND TRIM("표기1") <> ''
ORDER BY id
LIMIT 1;
```

고정값:

- exact keyword: `H0001`
- general keyword: `-fer`

route 확인:

- `H0001`
  - strong jump regex 일치
  - `searchStrongExactMap` 결과 1건
  - UI에서는 exact search path로 진입 가능
- `-fer`
  - strong jump regex 불일치
  - `searchStrongExactMap` 결과 0건
  - `searchWordsMap` 결과 2건
  - UI에서는 general search path로만 진입

### command 세션 결과

세션 규칙:

- app/process fresh start
- collector reset 1회
- `getStrongWordsMap` 1회
- `searchStrongExactMap('H0001')` 1회
- `searchWordsMap('-fer')` 1회

실측 결과:

- observed contexts: `getStrongWordsMap`, `searchStrongExactMap`, `searchWordsMap`
- target context 3개 모두 observed
- unexpected context: 0
- fallback reason summary: 0건
- recent event 기준 final result source: 전부 `normalized`

건수:

- `getStrongWordsMap`: 6231건
- `searchStrongExactMap('H0001')`: 1건
- `searchWordsMap('-fer')`: 2건

### coverage 판정

command coverage:

- target context completeness: pass
- unexpected context absence: pass
- direct DB blind spot absence: pass
  - Phase 3.2 대상 surface는 home screen에서 repository context 3개로만 진입함을 코드 기준으로 재확인했다.

UI coverage:

- 상세 복귀 후 동일 context 재관측: client manual session 필요
- undo 후 동일 context 재관측: client manual session 필요

현재 판정:

- Phase 3.2 command 세션 기준 진입 조건 충족
- 최종 UI coverage pass 여부는 클라이언트 수동 확인 전까지 보류

### 한계 범위

- split view direct DB read는 이번 단계에 포함하지 않는다.
- graph cache hit / graph search 경로는 이번 단계에 포함하지 않는다.
- edit 저장 직후 single-word reread는 이번 단계에 포함하지 않는다.
- `getWordsMap`은 현재 홈 UI target surface가 아니라서 이번 단계에 포함하지 않는다.

## 2026-04-04 Phase 2 제한 적용

### 이번 단계 적용 범위

- 기본 global policy는 계속 `LEGACY`다.
- 실제 `NORMALIZED_WITH_FALLBACK` 적용 범위는 `WordRepository.getWordDetailLikeDisplayItemByIdForDetailScreen` 한 곳으로 제한한다.
- 이 경로는 `WordDetailScreen`에서만 호출한다.
- `widget.word`는 상세 화면의 초기 표시값으로 그대로 유지한다.
- 상세 화면은 백그라운드 재조회만 수행하고, 로딩 indicator나 별도 fallback UI는 추가하지 않는다.

### 전체 적용을 하지 않은 이유

- 목록 조회, 검색, 그래프, edit/undo 이후 refresh 경로는 다수 단어 조합 read 또는 후속 write 흐름과 강하게 연결되어 있다.
- 이번 단계 목표는 전면 전환이 아니라 제한된 실제 사용자 read 경로에서만 normalized path를 검증하는 것이다.
- 상세 화면 단일 재조회는 단일 `word_id` 기반 read-only 경로라서 rollback과 관측 범위를 가장 작게 유지할 수 있다.

### fallback 처리 흐름

1. legacy `WORD_TABLE` row를 먼저 조회한다.
2. 상세 전용 제한 경로에서만 `NORMALIZED_WITH_FALLBACK` policy로 normalized read를 시도한다.
3. normalized adapter가 성공하면 상세 화면 사용자 표시 기준으로 materialized row를 만든다.
4. materialized row와 legacy row의 사용자 표시 기준이 같으면 normalized 결과를 최종 반환한다.
5. adapter 실패, normalized row 없음, query 실패, 사용자 표시 기준 mismatch가 있으면 legacy row로 fallback 한다.
6. fallback이면 해당 호출의 최종 반환값은 legacy 단일 기준이다.

### 사용자 표시 기준 비교 항목

- 대표 표기
- 표기 리스트
- 음역 리스트
- 발음 리스트
- 의미 리스트
- 언어
- 스트롱 번호
- 비고

canonical semantic 동일성만으로 통과시키지 않는다. 현재 상세 화면에서 실제로 보이는 기준이 같을 때만 normalized 결과를 통과시킨다.

### 관측 항목

상세 전용 제한 경로와 기존 snapshot 관측 모델에서 다음 항목을 in-memory로 유지한다.

- `word_id`
- `context`
- `requestedPolicy`
- `fallbackObservation` 여부와 reason
- `legacyResultAvailable`
- `normalizedResultAvailable`
- `finalResultSource`
- `legacyReadResult`
- `normalizedReadResult`

`fallbackObservation.reason`에는 기존 reason 외에 `user_visible_display_mismatch`를 추가해 상세 화면 표시 차이 가능성을 별도로 관측한다.

### rollback 방식

- 상세 전용 제한 경로를 호출하지 않으면 사용자 read는 즉시 기존 `LEGACY` 경로만 사용한다.
- 문제가 발생하면 `WordDetailScreen`에서 이 API 호출을 제거하거나 debug override로 `LEGACY`를 강제해 바로 복구할 수 있다.
- DB schema 변경은 없으므로 rollback은 코드 경로 차단만으로 가능하다.

### 다음 단계 진입 조건

- 상세 전용 제한 경로에서 `user_visible_display_mismatch` fallback이 반복되지 않을 것
- empty/query failure fallback 대상이 정리될 것
- 수동 테스트에서 상세 화면 표시 차이, edit 후 재조회 이상, 기존 기능 회귀가 없을 것
- 관측 결과를 바탕으로 다음 적용 후보 API를 별도 설계 후 승인받을 것

## 2026-04-04 Phase 2.5 fallback 관측/분석 강화

### 목적

- 이번 단계 목적은 fallback을 줄이거나 제거하는 것이 아니라, fallback을 신뢰 가능하게 관측하고 해석할 수 있도록 만드는 것이다.
- read policy, 적용 범위, UI, DB schema는 유지한다.
- 사용자 기능으로 보이는 화면이나 영속 로그는 추가하지 않는다.

### collector 도입 이유

- 기존 관측은 `WordRepository` 인스턴스 내부 snapshot 기록 중심이라서 앱 세션 전체 fallback 경향을 집계하기에 한계가 있다.
- Phase 2.5에서는 debug 전용 shared in-memory collector를 도입해 동일 앱 프로세스 안에서 fallback/raw event/summary를 함께 본다.
- 공식 외부 접근 경로는 `WordRepository.debugReadSourceCollector` wrapper로 제한한다.

### collector 구조

- collector 파일 위치: `lib/domain/expression/read_source_debug_collector.dart`
- 생명주기: lazy init + app process in-memory
- reset: debug API로 수동 초기화 가능
- 앱 재시작 시 collector 데이터는 모두 초기화된다.
- raw event는 최근 200개만 유지한다.
- aggregate summary는 reset 전까지 누적 유지한다.

### 관측 범위

- 현재 관측 대상은 read source phase 2 상세 전용 경로와 repository debug inspection 경로다.
- 기본 관측 단위는 event 1건이며, 집계 단위는 `word_id`와 `reason` 두 축을 사용한다.
- summary는 반드시 `event count`와 `unique word count`를 분리해서 해석한다.

### collector 제공 데이터

1. summary by word
2. summary by reason
3. recent raw events

summary by word 기본 항목:

- `wordId`
- `totalEvents`
- `fallbackEvents`
- `normalizedSuccessEvents`
- `legacyOnlyEvents`
- `legacyFallbackEvents`
- `normalizedFailureEvents`
- `reasonCounts`
- `contexts`
- `firstSeenAt`
- `lastSeenAt`
- `lastFallbackDetail`

summary by reason 기본 항목:

- `reason`
- `eventCount`
- `uniqueWordCount`
- `contexts`
- `firstSeenAt`
- `lastSeenAt`
- `sampleWordIds`

recent raw event 기본 항목:

- `sequence`
- `observedAt`
- `wordId`
- `context`
- `requestedPolicy`
- `resolvedSource`
- `finalResultSource`
- `didFallback`
- `fallbackReason`
- `fallbackDetail`
- `legacyResultAvailable`
- `normalizedResultAvailable`
- `legacySetCount`
- `normalizedSetCount`
- `finalSetCount`

### fallback reason 분류 유지

Phase 2.5에서는 fallback reason 자체를 변경하지 않는다.

- `query_failed`
- `empty_result`
- `mapping_invalid`
- `minimum_expression_not_met`
- `user_visible_display_mismatch`

해석 기준:

- `query_failed`: normalized query 자체 실패. 1건이라도 위험 신호로 본다.
- `empty_result`: normalized usable row 부재. sparse data 여부를 함께 해석한다.
- `mapping_invalid`: row 구조 해석 불가. 즉시 위험 신호로 본다.
- `minimum_expression_not_met`: 최소 spelling 조건 미충족. 데이터 품질 또는 migration 이상 후보로 본다.
- `user_visible_display_mismatch`: 상세 화면 표시 차이. Phase 3 진입 차단 신호로 본다.

### 해석 기준

- `event fallback rate`와 `unique word fallback rate`를 함께 본다.
- 동일 단어 반복 조회만으로 통계가 왜곡되지 않도록 unique word 기준을 반드시 같이 확인한다.
- UI가 조용히 유지되더라도 collector에 fallback이 누적되면 안정 상태로 보지 않는다.
- fallback reason이 관측되지 않으면 안정성 판단도 불가능하다고 본다.

### Phase 3 진입 판단 기준

즉시 Phase 3 가능:

- real DB unique word 20개 이상 관측
- `query_failed = 0`
- `mapping_invalid = 0`
- `user_visible_display_mismatch = 0`
- 일반 단어군에서 설명 불가능한 `empty_result` / `minimum_expression_not_met`가 없음

추가 관측 필요:

- 샘플 수가 부족하거나
- `empty_result`, `minimum_expression_not_met`가 sparse cohort에 한해 제한적으로 관측되지만 원인 설명이 가능한 경우

진입 금지:

- 위험 reason이 1건이라도 재현되거나
- unique fallback이 일반 단어군으로 확산되거나
- collector 누락/중복 때문에 관측 신뢰도를 설명할 수 없는 경우

## 1. 개요

이 문서는 현재 legacy `WORD_TABLE` 기반인 read source를 normalized `word_expression_set` 기준으로 안전하게 전환하기 위한 정책을 정의한다.

현재 상태 요약:

- canonical read/write 완료
- `word_expression_set` migration 완료
- dual-sync write 적용
- normalized table은 write 기준으로 최신 상태 유지
- read source는 아직 legacy `WORD_TABLE`
- verify SQL 존재

문제 정의:

- read/write source 불일치 상태가 유지되고 있다.
- 동일한 표현 데이터를 legacy와 normalized 기준으로 각각 해석해야 하므로 유지보수 복잡도가 증가한다.
- 정규화 구조를 write에는 사용하지만 read에는 사용하지 않아 구조 활용이 불완전하다.
- 장기적으로 read/write 분리 상태는 정책 누락, 회귀, 검증 누락을 유발하는 유지보수 리스크가 된다.

목표:

- read source를 normalized 기준으로 전환한다.
- 기존 기능 영향 없이 안정적으로 전환한다.
- rollback 가능성을 확보한다.

이번 문서 범위:

- read source 전환 정책 정의
- verify 기준 정의
- fallback 기준 정의

이번 문서 범위에 포함하지 않을 것:

- public API 변경안
- DB schema 변경안
- UI 계약 변경안
- 구현 절차 상세
- 코드 예시

## 2. 전환 전략

### 2.1 기본 전략

전환 기본 정책:

- read source 전환은 단계적 방식으로 수행한다.
- read source policy는 repository 내부에서 관리한다.
- UI 및 상위 레이어는 read source 변경을 인지하지 않는다.
- 단계 승급은 verify 결과와 fallback 관측 결과를 기준으로 판단한다.

책임 분리:

- Read Adapter의 책임: source별 row를 canonical expression result 하나로 통일한다.
- repository의 책임: source 선택과 fallback 판정을 수행한다.
- UI 및 상위 레이어의 책임: source 변경을 알 필요가 없으며, 기존과 동일한 최종 반환 구조만 사용한다.

### 2.2 Read Source 정책 정의

| 정책 | 설명 | 허용 상태 |
| --- | --- | --- |
| `LEGACY` | legacy `WORD_TABLE` 표현 컬럼만 read source로 사용한다. | 초기 기준 상태 |
| `NORMALIZED_WITH_FALLBACK` | normalized `word_expression_set`를 우선 조회하고, 정의된 비정상 조건에서만 legacy read로 fallback 한다. | 1차 전환 상태 |
| `NORMALIZED_ONLY` | normalized `word_expression_set`만 read source로 사용한다. legacy read는 비상 복구 경로로도 사용하지 않는다. | 2차 전환 상태 |

### 2.3 단계별 전환 흐름

고정 전환 순서:

`LEGACY -> NORMALIZED_WITH_FALLBACK -> NORMALIZED_ONLY -> legacy read 제거`

단계 해석:

- 초기 상태는 `LEGACY`다.
- 1차 전환은 `NORMALIZED_WITH_FALLBACK`이다.
- 2차 전환은 `NORMALIZED_ONLY`다.
- 최종 단계에서 legacy read 코드를 제거한다.

## 3. Read Adapter 설계

### 3.1 목적

- legacy / normalized 결과를 동일한 canonical read 결과로 정규화한다.
- normalized read는 canonical read 결과를 기준으로 한다.
- read source가 달라도 최종 반환 구조는 동일해야 한다.
- 최종 반환 구조의 안정성은 source 차이보다 우선한다.

### 3.2 출력 계약 정의

출력 계약:

- 대표값은 `is_representative = 1`을 1차 기준으로 사용한다.
- `seq = 1`은 대표 정의가 아니라, 대표 플래그가 없거나 결과가 비정상일 때만 제한적으로 사용하는 복구 fallback 기준이다.
- 정렬은 `seq` 기준으로 수행한다.
- 정렬은 항상 deterministic해야 하며 동일 입력에 대해 동일 순서를 보장해야 한다.
- `spelling`, `transliteration`, `pronunciation`은 source와 무관하게 동일한 의미의 필드로 매핑한다.
- `null`과 empty string은 canonical 결과에서 동일하게 취급하지 않는다.
- empty string은 trim 후 제거하거나 `null`로 정규화한다.
- `spelling`이 비어 있는 표현은 유효한 canonical 표현으로 승격하지 않는다.
- 중복 제거는 최종 canonical 표현 단위로 판단한다.
- 중복 제거 기준은 `spelling`, `transliteration`, `pronunciation`, `seq`, `is_representative`가 모두 동일한 결과를 중복으로 본다.

비정상 row 처리:

- 비정상 normalized row 때문에 canonical 결과를 안정적으로 만들 수 없으면 임의 보정하지 않는다.
- 이 경우 결과를 `mapping invalid`로 판정한다.
- `mapping invalid`는 fallback 대상으로 넘긴다.

### 3.3 핵심 원칙

- read source가 달라도 최종 반환 구조는 동일해야 한다.
- canonical read 결과는 source별 raw row보다 우선한다.
- source 차이를 숨기기 위한 임의 보정은 허용하지 않는다.

## 4. Fallback 전략

### 4.1 Fallback 허용 조건

다음 경우에만 fallback을 허용한다.

- 쿼리 실패
- 결과 row 없음
- mapping 결과가 유효하지 않음
- 최소 표현 조건 미충족

### 4.2 Fallback 금지 조건

다음 사유로는 fallback을 허용하지 않는다.

- 정렬 차이
- 대표값 차이
- 일부 필드 값 차이
- 표현 개수 차이

### 4.3 정책 문장

fallback은 결과 차이를 숨기기 위한 것이 아니라, 비정상 상태 복구용으로만 사용한다

### 4.4 Fallback 관측 가능성

fallback 발생 시 해당 `word_id`와 원인은 반드시 관측 가능해야 한다.

fallback은 반드시 디버깅 가능한 형태로 기록 가능해야 한다.

최소 관측 항목:

- `word_id`
- 현재 policy
- fallback 원인
- 발생 시점 또는 검증 맥락

운영 원칙:

- fallback 기록은 문제를 숨기기 위한 로그가 아니라, normalized 안정화 여부를 판단하기 위한 검증 신호로 사용한다.
- fallback이 관측되지 않으면 안정성 판정도 할 수 없다고 본다.

## 5. Dual-Sync 유지 정책

### 5.1 유지 원칙

- read 전환 이후에도 write는 계속 dual-sync를 유지한다.
- read source 전환은 write authoritative 상태 변경을 의미하지 않는다.

### 5.2 단계별 정책

| 단계 | read | write |
| --- | --- | --- |
| 초기 | legacy | dual-sync |
| 전환1 | normalized + fallback | dual-sync |
| 전환2 | normalized only | dual-sync |

### 5.3 종료 조건

다음 3개 조건을 모두 만족할 때 dual-sync 종료 검토를 시작한다.

- fallback 발생 없음
- verify 통과
- 주요 기능 정상 동작

## 6. Verify 기준

### 6.1 핵심 원칙

verify는 raw DB row가 아니라 최종 read 결과 동치성 기준으로 판단한다

### 6.2 Verify 레벨 정의

| 레벨 | 검증 대상 | 기준 |
| --- | --- | --- |
| Level 1 | DB 정합성 | 표현 개수, 대표값, 필드 매핑, 순서 |
| Level 2 | Repository 결과 비교 | 동일 `word_id` 기준 legacy vs normalized 최종 결과 비교 |
| Level 3 | UI 동작 검증 | 상세화면, 목록, 검색, 그래프, split view |
| Level 4 | Fallback 발생 여부 검증 | fallback 건수, 대상 `word_id`, 원인, 검증 맥락 |

Level 1:

- `word_expression_set` row 구조가 canonical 결과를 만들 수 있는지 확인한다.
- 표현 개수, 대표값, 필드 매핑, 순서를 확인한다.

Level 2:

- 동일 `word_id`에 대해 legacy read 결과와 normalized read 결과의 최종 canonical 결과를 비교한다.
- raw row 차이가 아니라 사용자 출력에 영향을 주는 최종 결과 동치성만 비교한다.

Level 3:

- 상세화면
- 목록
- 검색
- 그래프
- split view

Level 4:

- fallback이 발생하지 않는 것이 정상 상태다.
- fallback 발생 건수와 대상 `word_id`를 검증 결과에 포함한다.
- fallback 발생 자체가 즉시 실패를 의미하지는 않지만, 단계 승급 차단 조건으로 본다.

verify 기록 원칙:

- verify 기록에는 fallback 발생 여부를 반드시 포함한다.
- verify 기록에는 fallback 관찰 로그 확인 여부를 반드시 포함한다.

## 7. Legacy Read 제거 기준

### 7.1 제거 조건

다음 조건을 모두 만족해야 legacy read 제거를 시작한다.

- `NORMALIZED_ONLY` 안정성 확보
- fallback 0건
- verify 통과
- 주요 기능 영향 없음

### 7.2 제거 순서

제거는 반드시 다음 두 단계로 분리한다.

1. fallback 제거
2. legacy read 코드 제거

## 8. 테스트 전략

### 8.1 기본 원칙

- 수동 테스트 기준으로 수행한다.
- 실제 DB 데이터 기반으로 수행한다.
- 테스트 대상 레코드를 명시한다.
- verify 및 수동 테스트 기록에는 fallback 발생 여부와 관찰 로그 확인 항목을 포함한다.

### 8.2 테스트 유형

다음 5개 유형을 모두 수행한다.

1. 단일 단어 조회 비교
2. 다중 표현 비교
3. 편집 후 재조회
4. 삭제 + undo
5. UI 회귀 테스트

### 8.3 DB 기반 테스트 방식

기준 SQL 예시:

```sql
SELECT id, lemma FROM WORD_TABLE WHERE id = ?;
SELECT * FROM word_expression_set WHERE word_id = ?;
```

비교 기준:

- 동일 `word_id` 기준 legacy read 결과와 normalized read 결과를 각각 확인한다.
- DB 조회 결과는 raw row 확인용으로만 사용하고, 최종 판정은 canonical read 결과 동치성으로 수행한다.

### 8.4 테스트 문서 요구사항

각 테스트는 반드시 다음 항목을 포함한다.

- 테스트 대상 ID
- 테스트 목적
- 기대 결과
- 실패 시 관찰 포인트

테스트 대상 샘플 ID:

- `E0000_0001`
- `E0000_0010`
- `E0000_0056`
- `E0000_0076`
- `G0185_0000`
- `H0000_0024`
- `H0896_0000`
- `G4572_0000`

기록 원칙:

- 각 테스트는 fallback 발생 여부를 기록한다.
- fallback이 발생하면 `word_id`, policy, 원인, 검증 맥락을 함께 기록한다.
- UI 회귀 테스트는 목록, 상세, 검색, 그래프, split view 결과를 모두 포함한다.

## 9. 리스크 및 대응 전략

### 9.1 Read 결과 불일치

리스크:

- legacy와 normalized의 최종 결과가 다르면 사용자 출력이 달라질 수 있다.

대응:

- 정책 승급을 중단한다.
- fallback 기록을 확인한다.
- repository 결과 비교 verify를 재실행한다.
- 필요 시 이전 policy로 rollback 한다.

### 9.2 Fallback 과다 발생

리스크:

- normalized read가 nominal path로 동작하지 못하고 예외 복구 경로에 의존하게 된다.

대응:

- fallback 관측 기록을 집계한다.
- 동일 원인의 반복 발생 여부를 확인한다.
- 정책 승급을 중단한다.
- 필요 시 이전 policy로 rollback 한다.

### 9.3 UI 표시 차이

리스크:

- 대표값, 정렬, 표현 개수 차이가 목록과 상세 표시 차이로 이어질 수 있다.

대응:

- UI 동작 verify를 재실행한다.
- fallback 기록과 repository 비교 결과를 함께 확인한다.
- 사용자 출력 차이가 확인되면 단계 승급을 중단한다.

### 9.4 Undo / Edit 영향

리스크:

- edit, delete, undo 이후 normalized read 결과가 legacy 기준과 달라질 수 있다.

대응:

- 편집 후 재조회와 삭제 + undo 테스트를 반복 수행한다.
- dual-sync 유지 상태에서 verify를 재실행한다.
- 필요 시 이전 policy로 rollback 한다.

## 10. 최종 정책 요약

read source는 단계적으로 전환한다

repository 내부 policy로 관리한다

fallback은 예외 복구용으로만 사용한다

dual-sync는 안정화 전까지 유지한다

verify는 사용자 출력 기준으로 판단한다

legacy 제거는 별도 단계로 수행한다
