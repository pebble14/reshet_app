# Read Source Migration

## 2026-04-04 Phase 2 제한 적용

### 이번 단계 적용 범위

- 기본 global policy는 계속 `LEGACY`다.
- 실제 `NORMALIZED_WITH_FALLBACK` 적용 범위는 `WordRepository.getWordDetailMapByIdForReadSourcePhase2Only` 한 곳으로 제한한다.
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
