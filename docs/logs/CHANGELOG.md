# CHANGELOG

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
- `WordDetailScreen` 전용 제한 경로 `getWordDetailMapByIdForReadSourcePhase2Only`를 추가했다.
- 상세 화면은 `widget.word` 초기 표시를 유지한 채 백그라운드에서만 phase 2 read를 시도한다.
- fallback reason에 `user_visible_display_mismatch`를 추가하고 in-memory observation 항목을 확장했다.
- repository 테스트에 detail-only success / empty fallback / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 phase 2 제한 적용 범위, rollback, 관측 기준을 반영했다.
