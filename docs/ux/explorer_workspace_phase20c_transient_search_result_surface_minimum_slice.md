# ExplorerWorkspace Phase 20-C large-screen transient search result surface 최소 구현

> 문서 성격: reference/context 및 구현·검증 기록
>
> 구현 브랜치: `feature/explorer-workspace-phase20c-transient-search-result-surface`
>
> 기준 HEAD: `c796dc6af8a7974654390f15805d5f6b03f37de5`
>
> active boundary 요약은 `docs/ux/explorer_workspace_unification.md`의 Phase 20-C 항목을 따른다.

## 1. 목적

Phase 20-C는 large-screen 상단 일반 검색 입력 아래에 query-bound transient search result surface를 최소 구현하는 단계다.

이번 단계는 검색 state 또는 Explorer owner를 재설계하지 않는다. 기존 검색 실행과 좌측 목록 흐름을 유지하면서, large-screen에서 검색 query와 결과 후보를 가까운 위치에서 확인하고 명시적으로 선택할 수 있는 inline attached panel을 추가한다.

클라이언트 UI 확인 전이므로 Phase 20-C의 최종 UX 승인을 선언하지 않는다. 명령어 기반 구현 검증은 완료했으며 UI 기반 수동 확인은 클라이언트가 수행한다.

## 2. 구현 범위

### 2.1 추가한 presentation

`HomeScreen` large-screen workspace의 상단 검색 입력 바로 아래에 같은 widget tree 안의 inline attached panel을 추가했다.

```text
HomeScreen large-screen workspace
├─ homeWorkspaceSearchSurface
├─ large-screen transient search result surface
└─ split row
   ├─ homePane
   │  ├─ Strong/스트롱 rail-local jump
   │  ├─ Strong Rail
   │  └─ 기존 default/search 목록
   └─ WordExplorerScreen
```

panel은 `OverlayEntry`, route-level overlay, global focus manager를 사용하지 않는다. 최대 높이를 제한한 inline panel이며 다음 상태를 표시한다.

- 검색 결과 loading
- 검색 오류
- 검색 결과 없음
- 검색 후보 목록
- 검색 결과 닫기

### 2.2 presentation state

새 private state `_isLargeScreenTransientSearchResultVisible`은 transient panel의 표시 여부만 소유한다.

기존 검색 state와 실행 책임은 계속 `_HomeScreenState`에 유지된다.

| 책임 | 유지 owner/source |
| --- | --- |
| 일반 검색 입력 | `_searchController` |
| 검색 실행 | `_runSearch()` |
| 검색 결과 future | `_searchWordsFuture` |
| default/search 목록 전환 | `_isShowingDefaultStrongList` |
| transient panel 표시 여부 | `_isLargeScreenTransientSearchResultVisible` |
| large-screen Explorer target | `_largeScreenExplorerWordId` |

`_isLargeScreenTransientSearchResultVisible`은 검색 query, 검색 결과 데이터, Explorer target의 source-of-truth가 아니다.

## 3. interaction lifecycle

### 3.1 검색 submit

non-empty query submit은 기존 `_runSearch()` 경로에서 `_isShowingDefaultStrongList`를 search 상태로 전환하고 `_setVisibleWordListFuture()`를 호출한다. large-screen에서는 같은 submit 시점에 transient panel presentation을 열거나 갱신한다.

검색 submit은 다음 동작을 수행하지 않는다.

- `_largeScreenExplorerWordId` 변경
- `_showWordInLargeScreenExplorerPane(...)` 호출
- `WordExplorerScreen` 직접 생성 또는 owner 변경
- route push

empty query submit은 기존 default Strong 목록 전환 흐름을 유지하며 transient panel을 닫는다.

### 3.2 검색 후보 item tap

large-screen transient panel의 검색 후보 item 본문 tap만 사용자의 명시적 선택으로 해석한다.

```text
검색 후보 item tap
→ _showWordInLargeScreenExplorerPane(wordId)
→ transient result surface dismiss
```

Explorer retarget은 기존 `_showWordInLargeScreenExplorerPane(wordId)` 경로를 그대로 사용한다. 후보 선택 후 panel presentation만 닫는다.

### 3.3 dismiss와 clear

`검색 결과 닫기`는 transient panel presentation만 닫는다.

- Explorer target 유지
- 검색 query 유지
- `_searchWordsFuture` 유지
- 좌측 검색 결과 목록 유지

`초기화`는 기존 `_clearSearch()` 흐름을 유지한다.

- `_searchController.clear()`
- default Strong 목록 상태 복귀
- 기존 visible list future 갱신
- transient panel 닫기
- Explorer target 유지

## 4. 점진 전환 상태

Phase 20-C에서는 large-screen transient panel과 좌측 검색 결과 목록의 중복 표시를 허용한다.

기존 좌측 `homeWordListSurface`는 변경하지 않았다.

- 검색 결과 목록 삭제 없음
- 검색 결과 목록 축소 없음
- 검색 결과 목록 이동 없음
- default Strong 목록 삭제·축소·이동 없음
- Strong Rail 유지

좌측 surface의 최종 browse/discovery 역할 재정의와 중복 제거 여부는 후속 설계 대상으로 남긴다.

## 5. 유지한 금지선

- 검색 state owner는 `_HomeScreenState` private state로 유지한다.
- `_searchController`, `_runSearch(...)`, `_searchWordsFuture`, `_isShowingDefaultStrongList` 책임을 이동하지 않는다.
- 검색 실행의 repository/API 의미를 변경하지 않는다.
- 검색 submit만으로 Explorer를 retarget하지 않는다.
- `Strong/스트롱` 입력은 rail-local jump 전용으로 유지한다.
- `Strong/스트롱` 입력은 transient result surface를 열거나 닫지 않는다.
- graph selection passive sync는 `_largeScreenExplorerWordId`를 변경하지 않는다.
- graph selection passive sync는 `_showWordInLargeScreenExplorerPane(...)`를 호출하지 않는다.
- `WordExplorerScreen`은 graph/detail/selected/history owner로 유지한다.
- production `ExplorerWorkspace`를 mount하지 않는다.
- `ExplorerWorkspaceState`를 production source-of-truth로 승격하지 않는다.
- small-screen `homePane → detail route` 흐름을 변경하지 않는다.
- DB, repository read/API, DTO/model, dependency, `pubspec.yaml`, `pubspec.lock`을 변경하지 않는다.

## 6. 명령어 기반 테스트

### 6.1 신규 source guardrail

```text
flutter test test/ui/home_screen_phase20c_transient_search_result_surface_guardrail_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+9`
- `All tests passed!`

검증 항목:

- inline attached panel mount와 `OverlayEntry` 금지
- `_HomeScreenState` 검색 owner 유지
- loading/no-result surface 구성
- submit 비-retarget
- 후보 tap 기존 retarget 경로 및 dismiss 순서
- dismiss/clear 비-retarget
- Strong/passive sync 비결합
- 좌측 중복 목록과 small-screen detail route 유지
- `WordExplorerScreen`, `ExplorerWorkspace`, `ExplorerWorkspaceState` 금지선 유지

### 6.2 신규 runtime widget guardrail

```text
flutter test test/ui/home_screen_phase20c_transient_search_result_surface_runtime_test.dart --reporter expanded
```

실제 결과:

- 격리 복사 DB 기반 통과
- `+3`
- `All tests passed!`

검증 시나리오:

- 사람이 식별 가능한 `H2` 검색 submit 후 panel 표시 및 Explorer target 유지
- dismiss 후 Explorer target 유지
- 같은 `H2` query 재실행 후 panel 갱신
- panel이 닫힌 상태의 `G26` Strong 입력이 panel을 열지 않고 Explorer target을 변경하지 않음
- panel이 열린 상태의 `H85` Strong 입력이 panel lifecycle과 Explorer target을 변경하지 않음
- 기존 초기화 동작 후 panel 닫힘과 Explorer target 유지
- `H2` 후보 item tap 후 기존 Explorer retarget 및 panel 닫힘
- `PHASE20C_RESULT_NOT_FOUND_20260606` query의 no-result 상태 표시
- small-screen `H2` 후보 item tap의 기존 detail route 유지

### 6.3 기존 guardrail 회귀

```text
flutter test test/ui/home_screen_phase19b_top_search_surface_presentation_test.dart test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+14`
- `All tests passed!`

```text
flutter test test/ui/home_screen_phase18n_runtime_guardrail_test.dart --reporter expanded
```

실제 결과:

- 격리 복사 DB 기반 통과
- `+3`
- `All tests passed!`

```text
flutter test test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart test/ui/explorer_workspace_phase17c_state_source_guardrail_test.dart test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart test/ui/home_screen_phase18m_search_strong_jump_role_separation_test.dart --reporter expanded
```

실제 결과:

- 통과
- `+26`
- `All tests passed!`
- production `ExplorerWorkspace` mount 금지, `ExplorerWorkspaceState` source-of-truth 승격 금지, graph passive sync 비-retarget, Strong/search 역할 분리를 추가 확인

### 6.4 변경 파일 대상 analyze

```text
flutter analyze --no-fatal-infos --no-fatal-warnings lib/ui/home_screen.dart test/ui/home_screen_phase20c_transient_search_result_surface_guardrail_test.dart test/ui/home_screen_phase20c_transient_search_result_surface_runtime_test.dart
```

실제 결과:

- exit code `0`
- 기존 `HomeScreen`의 `_dbMessage` unused warning 1건
- 기존 `print` 사용 info 4건
- Phase 20-C 신규 오류 없음

전체 `flutter analyze --no-fatal-infos --no-fatal-warnings`도 실제 실행했다. 결과는 기존 기준과 동일한 `47 issues found`, exit code `1`이며, error 13건은 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` API 불일치다. Phase 20-C 변경 파일 대상 analyze는 exit code `0`이므로 전체 analyze 기술 부채와 신규 변경을 분리한다. 기존 기술 부채는 이번 범위에서 수정하지 않는다.

## 7. 클라이언트 UI 기반 수동 테스트 체크리스트

Codex는 UI 기반 수동 테스트를 수행했다고 보고하지 않는다. 클라이언트는 Windows Desktop 앱에서 다음 항목을 확인한다.

### 7.1 large-screen submit 비-retarget

- 테스트 목적: 검색 submit과 Explorer retarget 분리 확인
- 시작 화면: Windows Desktop `HomeScreen`, 창 너비 900px 이상
- 조작 순서: 현재 Explorer 단어를 확인하고 상단 검색 입력에 `H2`를 입력한 뒤 Enter 또는 검색 버튼 사용
- 입력 데이터: `H2`
- 기대 화면 변화: 상단 검색 입력 아래 transient 검색 결과 panel이 열리고 좌측 검색 결과도 유지되며, 후보 선택 전 우측 Explorer target은 유지됨
- 실패 시 증상: panel이 보이지 않음, submit 즉시 Explorer가 변경됨, 좌측 목록 또는 default Strong 목록 구조가 사라짐
- 완료 판단 기준: panel 표시와 Explorer target 유지가 동시에 확인됨

### 7.2 명시적 후보 선택

- 테스트 목적: 후보 item tap의 기존 Explorer retarget 및 panel dismiss 확인
- 시작 화면: `H2` transient 검색 결과 panel이 열린 large-screen 화면
- 조작 순서: panel에서 `H2`로 표시되는 후보 본문 tap
- 입력 데이터: `H2` 검색 후보
- 기대 화면 변화: 우측 Explorer가 선택 후보로 retarget되고 transient panel은 닫힘
- 실패 시 증상: Explorer가 바뀌지 않음, submit 시점에 이미 바뀜, 후보 tap 후 panel이 남음
- 완료 판단 기준: 명시적 후보 tap 후에만 Explorer target 변경과 panel 닫힘이 발생함

### 7.3 dismiss와 초기화

- 테스트 목적: presentation dismiss와 기존 clear 흐름의 비-retarget 확인
- 시작 화면: `H2` transient 검색 결과 panel이 열린 large-screen 화면
- 조작 순서: `검색 결과 닫기`를 누른 뒤 Explorer를 확인하고, 다시 `H2` 검색 후 `초기화` 사용
- 입력 데이터: `H2`
- 기대 화면 변화: 닫기는 panel만 닫고 좌측 검색 결과와 Explorer target을 유지함. 초기화는 panel을 닫고 기존 default Strong 목록으로 복귀하며 Explorer target을 유지함
- 실패 시 증상: 닫기 또는 초기화가 Explorer를 변경함, 닫기만으로 좌측 결과가 사라짐, 초기화 후 default Strong 목록이 복귀하지 않음
- 완료 판단 기준: 두 동작 모두 Explorer target을 유지하며 각 presentation/list 역할에 맞게 동작함

### 7.4 Strong rail-local jump

- 테스트 목적: Strong 입력과 transient 검색 surface lifecycle 분리 확인
- 시작 화면: `H2` transient 검색 결과 panel이 열린 large-screen 화면
- 조작 순서: 좌측 `Strong/스트롱` 입력에 `G26` 입력 후 Enter
- 입력 데이터: `G26`
- 기대 화면 변화: Strong Rail 위치/feedback만 변하고 transient panel, 좌측 검색 결과, 우측 Explorer target은 유지됨
- 실패 시 증상: transient panel이 새로 열리거나 닫힘, 일반 검색 실행, 좌측 목록 전환, Explorer retarget
- 완료 판단 기준: rail-local 변화만 발생함

### 7.5 small-screen 기존 흐름

- 테스트 목적: transient panel 미적용과 기존 detail route 유지 확인
- 시작 화면: Windows Desktop `HomeScreen`, 창 너비 900px 미만
- 조작 순서: 일반 검색 입력에 `H2` 입력 후 검색하고 검색 후보 본문 tap
- 입력 데이터: `H2`
- 기대 화면 변화: large-screen transient panel과 embedded Explorer 없이 기존 검색 결과 목록에서 `WordDetailScreen` route로 이동
- 실패 시 증상: transient panel 표시, embedded Explorer 표시, 후보 tap 후 detail route 미진입
- 완료 판단 기준: 기존 `homePane → detail route` 흐름이 유지됨

### 7.6 loading과 검색 결과 없음

- 테스트 목적: transient panel 내부 상태 표시 확인
- 시작 화면: Windows Desktop `HomeScreen`, 창 너비 900px 이상
- 조작 순서: 상단 검색 입력에 `PHASE20C_RESULT_NOT_FOUND_20260606`을 입력하고 검색 실행
- 입력 데이터: `PHASE20C_RESULT_NOT_FOUND_20260606`
- 기대 화면 변화: 검색 처리 중 loading이 표시되는 경우 transient panel 내부에 표시되고, 완료 후 같은 panel 내부에 `검색 결과 없음`이 표시됨
- 실패 시 증상: no-result panel이 열리지 않음, 결과 없음 상태가 좌측 목록에만 보임, Explorer target 변경
- 완료 판단 기준: no-result 상태가 transient panel 내부에 보이고 Explorer target이 유지됨

## 8. 현재 상태

Phase 20-C 최소 구현과 명령어 기반 테스트는 적용되었다. large-screen transient surface와 좌측 검색 결과의 중복 표시는 의도한 점진 전환 상태다. 클라이언트 UI 기반 수동 테스트 결과가 확인되기 전에는 최종 UX 승인 또는 후속 중복 제거를 선언하지 않는다.
