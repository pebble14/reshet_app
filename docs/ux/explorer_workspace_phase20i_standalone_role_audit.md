# ExplorerWorkspace Phase 20-I Explorer standalone 역할 감사

> 문서 분류: `reference/context` 및 docs/audit 기록
>
> 기준 HEAD: `99dcbf2c8c7decf63dcec7147d57599383ef1b36`
>
> 한국어 작업명: Explorer 단독 화면 역할 감사 및 workspace 통합 경계 정리
>
> 이 문서는 production Dart 코드, route, test guard, DB/API/repository, DTO/model/public API, large-screen 또는 small-screen 동작을 변경하지 않는다.
>
> 후속 상태: Phase 20-J에서 이 감사가 식별한 호출자 없는 `_openDefaultStrongWordExplorer(...)` helper와 직접 관련 stale source guard를 정리했다. 이 문서의 helper 존재 설명과 Phase 20-J 후보 문장은 Phase 20-I 당시의 감사 결과 및 후속 작업 근거로 유지한다.

## 감사 목적과 판정 기준

Phase 20-I는 실제 로컬 production source를 기준으로 standalone graph/detail route와 embedded workspace pane의 현재 역할을 분리하고, Phase 20-J에서 구현 가능한 최소 작업 단위를 문서화하는 docs/audit-only 단계다.

이번 감사에서는 소스에 함수나 widget 생성 코드가 존재하는 것과 현재 production UI에서 실제로 mount되거나 호출되는 것을 구분한다. 특히 `HomeScreen`의 shared default/search 목록 builder에는 detail/graph 아이콘과 route helper가 남아 있지만, 현재 large-screen composition은 해당 목록을 mount하지 않고 Strong Rail과 transient 검색 panel만 사용한다.

확인한 핵심 production 파일은 다음과 같다.

- `lib/main.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/ui/word_graph_screen.dart`
- `lib/ui/word_info_panel.dart`

production 시작점은 `MaterialApp(home: const HomeScreen())`이며, large-screen 기준은 `HomeScreen._largeScreenSplitBreakpoint = 900.0`이다.

## 1. 현재 standalone 진입 경로 목록

### 1.1 standalone `WordExplorerScreen`

| 시작 위치 | 실제 경로 | 현재 production 상태 | form factor |
| --- | --- | --- | --- |
| `HomeScreen._openDefaultStrongWordExplorer(...)` | `Navigator.push` → `WordExplorerScreen(initialWordId: normalizedWordId)` | 함수는 존재하지만 `unused_element`로 표시되어 있고 호출자가 없는 dormant compatibility/guardrail 경로 | 현재 실제 진입 없음 |

`WordExplorerScreen` standalone route를 직접 생성하는 production source는 위 helper 하나다. 현재 `HomeScreen`의 default/search 목록, Strong Rail, transient 검색 panel은 이 helper를 호출하지 않는다.

### 1.2 standalone `WordDetailScreen`

| 시작 위치 | 실제 경로 | 현재 production 상태 | form factor |
| --- | --- | --- | --- |
| `HomeScreen` default Strong 목록 본문 tap | `_openDefaultStrongWordDetail(...)` → `WordDetailScreen` | active | small-screen |
| `HomeScreen` 검색 결과 목록 본문 tap | `_openWordDetail(...)` → `_openDefaultStrongWordDetail(...)` → `WordDetailScreen` | active | small-screen |
| `HomeScreen` default Strong 목록 상세 아이콘 | `_openDefaultStrongWordDetail(...)` → `WordDetailScreen` | active인 shared 목록 action | 현재 목록이 mount되는 small-screen |
| `HomeScreen` 검색 결과 목록 상세 아이콘 | `_openWordDetail(...)` → `WordDetailScreen` | active인 shared 목록 action | 현재 목록이 mount되는 small-screen |
| `WordExplorerScreen` detail pane의 상세 화면 열기 | `_openSelectedWordDetail()` → `WordDetailScreen` | active | large-screen embedded Explorer 및 dormant standalone Explorer 내부 |

`WordDetailScreen`은 진입 시 전달받은 `initialDisplayItem`을 표시한 뒤 detail 전용 repository read context로 다시 읽는다. 또한 edit, delete, graph 진입을 소유한다. embedded Explorer detail pane은 edit와 full-detail 열기를 제공하지만 delete와 graph 진입을 직접 제공하지 않는다.

### 1.3 standalone `WordGraphScreen`

| 시작 위치 | 실제 경로 | 현재 production 상태 | form factor |
| --- | --- | --- | --- |
| `HomeScreen` default Strong 목록 graph 아이콘 | `_openDefaultStrongWordGraph(...)` → `WordGraphScreen` | active인 shared 목록 action | 현재 목록이 mount되는 small-screen |
| `HomeScreen` 검색 결과 목록 graph 아이콘 | `_openWordGraph(...)` → `_openDefaultStrongWordGraph(...)` → `WordGraphScreen` | active인 shared 목록 action | 현재 목록이 mount되는 small-screen |
| `WordDetailScreen` graph 보기 | `_openGraph()` → `WordGraphScreen` | active | detail route가 열린 모든 form factor |
| standalone `WordGraphScreen` 연결 node 재탭 | callback이 없을 때 `Navigator.push` → 새 `WordGraphScreen` | active standalone graph 내부 탐색 | standalone graph route 내부 |
| standalone `WordGraphScreen` 단어 생성 후 relation 미생성 | callback이 없을 때 `pushReplacement` → 새 `WordGraphScreen` | active standalone graph create 후속 흐름 | standalone graph route 내부 |

`WordExplorerScreen`이 child로 mount하는 `WordGraphScreen`에는 selection과 center change callback이 항상 전달된다. 따라서 해당 embedded graph에서 node 재탭은 새 graph route를 열지 않고 Explorer owner의 center/selection 흐름으로 전달된다.

## 2. 현재 embedded workspace pane 경로 목록

현재 production embedded workspace 경로는 `HomeScreen` large-screen branch 안의 `WordExplorerScreen`이다.

```text
HomeScreen
└─ LayoutBuilder
   └─ width >= 900
      └─ Stack base Row
         ├─ Strong Rail compact surface
         └─ WordExplorerScreen
            ├─ WordGraphScreen
            └─ detail pane / WordInfoPanel
```

embedded Explorer retarget 경로는 다음과 같다.

| 시작 위치 | retarget 경로 | route 이동 여부 |
| --- | --- | --- |
| large-screen Strong Rail item tap | `_showWordInLargeScreenExplorerPane(wordId)` | 없음 |
| large-screen transient 검색 후보 본문 tap | `_showWordInLargeScreenExplorerPane(wordId)` 후 panel dismiss | 없음 |

`_showWordInLargeScreenExplorerPane(...)`는 `_largeScreenExplorerWordId`를 변경한다. `HomeScreen`은 `WordExplorerScreen`에 `ValueKey(_largeScreenExplorerWordId)`를 부여하므로 target 변경 시 기존 Explorer instance를 갱신하는 것이 아니라 새 owner instance를 생성한다.

## 3. large-screen 역할

현재 large-screen의 primary semantic flow는 standalone Explorer route가 아니라 `HomeScreen` 내부 embedded `WordExplorerScreen`이다.

- 상단 일반 검색 submit은 Explorer를 retarget하지 않는다.
- transient 검색 후보의 명시적 본문 tap은 embedded Explorer를 retarget한다.
- Strong Rail item tap은 embedded Explorer를 retarget한다.
- graph selection passive sync는 Explorer를 retarget하지 않는다.
- shared default/search 목록은 large-screen에서 mount되지 않는다.
- 따라서 shared 목록 안에 남아 있는 detail/graph 아이콘 route helper는 현재 large-screen 실제 진입점이 아니다.

large-screen에서 현재 실제로 열릴 수 있는 standalone route는 embedded Explorer detail pane의 full-detail action으로 여는 `WordDetailScreen`과, 그 detail route의 graph action으로 여는 `WordGraphScreen`이다.

## 4. small-screen 역할

small-screen에서는 `return homePane` 흐름을 사용하고 embedded `WordExplorerScreen`, Strong Rail, large-screen transient 검색 panel을 mount하지 않는다.

- default Strong 목록 본문 tap은 `WordDetailScreen` route를 연다.
- 검색 결과 목록 본문 tap은 `WordDetailScreen` route를 연다.
- 목록의 상세 아이콘은 `WordDetailScreen` route를 연다.
- 목록의 graph 아이콘은 `WordGraphScreen` route를 연다.
- `WordDetailScreen`의 graph action은 `WordGraphScreen` route를 연다.
- Navigator 뒤로가기는 목록과 검색 state가 남아 있는 `HomeScreen`으로 복귀하는 현재 mobile-style 흐름을 제공한다.

small-screen에는 detail을 대체할 embedded pane이 없으므로 `homePane → WordDetailScreen` 경로는 즉시 보존해야 한다.

## 5. 보존해야 할 경로

Phase 20-J의 최소 구현 후보를 검토할 때 다음 경로는 우선 보존한다.

1. small-screen default/search 목록 본문 tap → `WordDetailScreen`
2. small-screen 목록 상세 아이콘 → `WordDetailScreen`
3. small-screen 목록 graph 아이콘 → `WordGraphScreen`
4. `WordDetailScreen`의 edit/delete/graph 및 뒤로가기 흐름
5. standalone `WordGraphScreen` 내부 node 재탭 recenter와 create 후 `pushReplacement` 흐름
6. large-screen Strong Rail과 transient 검색 후보의 embedded Explorer retarget
7. `WordExplorerScreen`의 graph center, selection, detail target, internal history owner 역할

위 경로를 변경하려면 form factor별 대체 presentation, route return result, refresh, delete 후 복귀, graph create 후 center 이동을 별도로 설계하고 승인해야 한다.

## 6. 폐지 후보 경로

현재 가장 작은 폐지 후보는 호출자가 없는 `HomeScreen._openDefaultStrongWordExplorer(...)` dormant helper다.

- production UI에서 호출되지 않는다.
- standalone `WordExplorerScreen` route 생성 코드를 보존하기 위한 compatibility/guardrail source 역할만 남아 있다.
- 다수의 source guard가 `WordExplorerScreen(initialWordId: normalizedWordId)` 문자열 존재를 고정한다.

따라서 이 helper와 관련 stale source guard 정리는 Phase 20-J 최소 구현 후보로 넘긴다. Phase 20-I에서는 helper, test guard, route를 제거하거나 변경하지 않는다.

## 7. 판단 보류 경로

### 7.1 embedded Explorer → full detail route

`WordExplorerScreen._openSelectedWordDetail()`은 large-screen에서도 active다. 이 route를 제거하거나 embedded pane action으로 대체하려면 다음 차이를 먼저 해소해야 한다.

- embedded detail pane: split-view read, edit, full-detail 열기
- `WordDetailScreen`: detail 전용 reread, edit, delete, graph 진입, route result 반환
- 삭제 성공 시 Explorer center/selection/history 복구 처리
- route 복귀 후 `_refreshSelectedWord(...)`와 graph refresh 처리

### 7.2 detail route → graph route

`WordDetailScreen._openGraph()`은 small-screen의 명시적 graph 진입이면서 large-screen full-detail route에서도 사용된다. large-screen 전용 workspace redirect 후보와 small-screen standalone graph 유지 경계를 분리하기 전에는 변경하지 않는다.

### 7.3 standalone graph 내부 route 탐색

callback 없는 `WordGraphScreen`은 node 재탭 시 새 graph route를 push하고 create 후 relation을 만들지 않으면 graph route를 replace한다. embedded graph callback 흐름과 의미가 다르므로 별도 감사와 설계 없이 비활성화하지 않는다.

### 7.4 history, selection, center navigation, owner state 영향

`WordExplorerScreen`은 standalone과 embedded 사용 모두에서 graph center, selected word, selected display item, detail target, internal history를 직접 소유한다. 차이는 host와 외부 연결이다.

| 구분 | standalone `WordExplorerScreen` | large-screen embedded `WordExplorerScreen` |
| --- | --- | --- |
| host | Navigator route 위의 top-level screen | `HomeScreen` large-screen child |
| initial target | dormant helper가 전달하는 `initialWordId` | `_largeScreenExplorerWordId` |
| Home passive Strong callback | 없음 | `onSelectedStrongWordChanged` 연결 |
| retarget 방식 | 현재 외부 active retarget 없음 | `ValueKey` 변경으로 새 Explorer instance 생성 |
| internal history 수명 | standalone route instance 수명 | target retarget 전까지의 embedded instance 수명 |
| Navigator history | Explorer route 자체가 한 entry | Home route 안에 머무름 |

standalone Explorer helper 제거 자체는 현재 production behavior를 바꾸지 않는 후보지만, embedded retarget을 같은 정리로 취급해서는 안 된다. embedded retarget은 새 owner instance를 생성해 selection과 internal history를 초기화하는 현재 동작이므로, 향후 workspace continuity 개선은 별도 설계 대상이다.

## 8. 테스트 영향

### 8.1 standalone Explorer helper를 직접 고정하는 source guard

다음 테스트는 `WordExplorerScreen(initialWordId: normalizedWordId)` source 존재를 직접 확인한다.

- `test/ui/explorer_workspace_phase17b_transition_guardrail_minimum_slice_test.dart`
- `test/ui/explorer_workspace_phase4a_hidden_preview_wrapper_test.dart`
- `test/ui/explorer_workspace_phase4b_real_projection_contract_test.dart`
- `test/ui/explorer_workspace_phase4c_passive_sync_boundary_test.dart`
- `test/ui/explorer_workspace_phase4d_preview_interaction_boundary_test.dart`
- `test/ui/home_screen_phase18a_large_split_shell_test.dart`
- `test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart`
- `test/ui/home_screen_phase18k_graph_selection_rail_passive_sync_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`
- `test/ui/word_explorer_screen_phase10d_candidate_representation_reader_test.dart`
- `test/ui/word_explorer_screen_phase12b_readonly_context_strip_test.dart`
- `test/ui/word_explorer_screen_phase15b_empty_state_readability_test.dart`

Phase 20-J에서 dormant helper를 정리하려면 위 guard 중 compatibility route source 존재만 고정하는 assertion과 실제 owner/embedded boundary를 보호하는 assertion을 구분해야 한다.

### 8.2 detail route를 고정하는 주요 guard와 runtime test

- `test/ui/home_screen_phase18a_large_split_shell_test.dart`
- `test/ui/home_screen_phase18d_left_target_feedback_boundary_test.dart`
- `test/ui/home_screen_phase18f_left_control_boundary_guardrail_test.dart`
- `test/ui/home_screen_phase18n_runtime_guardrail_test.dart`
- `test/ui/home_screen_phase19b_top_search_surface_presentation_test.dart`
- `test/ui/home_screen_phase19c_top_search_surface_guardrail_hardening_test.dart`
- `test/ui/home_screen_phase20c_transient_search_result_surface_guardrail_test.dart`
- `test/ui/home_screen_phase20c_transient_search_result_surface_runtime_test.dart`
- `test/ui/home_screen_phase20g_floating_transient_search_result_panel_guardrail_test.dart`
- `test/ui/home_screen_phase20h_floating_search_panel_polish_guardrail_test.dart`
- `test/ui/explorer_workspace_phase4b_real_projection_contract_test.dart`
- `test/ui/explorer_workspace_phase4c_passive_sync_boundary_test.dart`
- `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`
- `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`

특히 Phase 18-N과 Phase 20-C runtime test는 small-screen 검색 결과 tap이 실제 `WordDetailScreen` route를 여는 동작을 검증한다.

### 8.3 graph standalone/embedded 차이를 고정하는 주요 guard

- `test/ui/explorer_workspace_phase3b_coexistence_boundary_test.dart`
- `test/ui/explorer_workspace_phase4a_hidden_preview_wrapper_test.dart`
- `test/ui/explorer_workspace_phase4b_real_projection_contract_test.dart`
- `test/ui/explorer_workspace_phase4c_passive_sync_boundary_test.dart`
- `test/ui/explorer_workspace_phase4d_preview_interaction_boundary_test.dart`
- `test/ui/explorer_workspace_phase4e_composition_boundary_test.dart`
- `test/ui/explorer_workspace_phase5a_layout_orchestration_test.dart`
- `test/ui/explorer_workspace_phase5a1_preview_access_boundary_test.dart`
- `test/ui/explorer_workspace_phase7d_readonly_projection_adapter_test.dart`
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`
- `test/ui/word_explorer_screen_phase8g_hidden_probe_contract_hardening_test.dart`
- `test/ui/word_graph_screen_phase8h30_selection_callback_contract_test.dart`
- `test/ui/word_graph_screen_phase8h33_center_change_callback_contract_test.dart`

Phase 20-I에서는 test code와 guard를 변경하지 않는다.

## 9. 문서 영향

현재 standalone/embedded 경계를 전제하거나 설명하는 주요 문서는 다음과 같다.

- active boundary 및 누적 기록
  - `docs/ux/explorer_workspace_unification.md`
  - `docs/logs/CHANGELOG.md`
- 직접 관련 reference/context audit
  - `docs/ux/explorer_workspace_phase20a_surface_navigation_role_audit.md`
  - `docs/ux/explorer_workspace_phase19a_top_search_command_surface_audit.md`
  - `docs/ux/explorer_workspace_phase20b_search_result_surface_contract_audit.md`
  - `docs/ux/explorer_workspace_phase20c_transient_search_result_surface_minimum_slice.md`
  - `docs/ux/explorer_workspace_phase20d_left_control_browse_discovery_role_audit.md`
- architecture/reference boundary
  - `docs/architecture/explorer_workspace_constitution.md`
  - `docs/ux/workspace_ux_architecture.md`
  - `docs/ux/navigation_policy.md`
  - `docs/ux/responsive_layout_policy.md`

`docs/ux/explorer_workspace_unification.md`의 초기 route inventory는 historical/reference snapshot으로 유지한다. Phase 20-I active boundary에는 현재 large-screen 목록 미mount와 dormant standalone Explorer helper를 별도로 기록해 초기 snapshot을 현재 production 상태로 오해하지 않게 한다.

`docs/logs/FEATURE_STATUS.md`는 최신 Phase 20 active boundary 기록 문서가 아니므로 Phase 20-I에서 변경하지 않는다.

## 10. Phase 20-J 최소 구현 후보

### 우선 최소 후보

`HomeScreen._openDefaultStrongWordExplorer(...)` dormant helper와 해당 helper의 source 문자열 존재만 고정하는 stale guard를 정리하는 단일 slice를 검토한다.

Phase 20-J 승인 전 확인 조건은 다음과 같다.

1. production caller가 여전히 없는지 재검색한다.
2. helper 제거가 production route behavior를 변경하지 않는지 확인한다.
3. stale source guard와 실제 owner/embedded boundary guard를 분리한다.
4. small-screen detail/graph route guard는 유지한다.
5. `WordExplorerScreen` owner fields와 embedded mount/retarget guard는 유지한다.
6. production Dart 코드와 test 변경 범위를 helper 및 직접 관련 stale assertion으로 제한한다.

### 후속 별도 후보

다음 항목은 Phase 20-J 우선 최소 후보에 포함하지 않는다.

- embedded Explorer full-detail route 제거 또는 대체
- `WordDetailScreen` delete/graph/read 역할 이동
- detail → graph의 large-screen workspace-aware redirect
- standalone graph 내부 node 재탭 push 또는 create 후 pushReplacement 변경
- small-screen route 흐름 변경
- embedded Explorer retarget 시 owner/history continuity 변경
- `ExplorerWorkspace` production mount 또는 source-of-truth 승격

## 명령어 기반 검증 기준

Phase 20-I 문서 변경 후 다음을 실행해 docs/audit-only 범위를 확인한다.

```text
git diff --stat
git diff --name-only
git diff --check
rg "Phase 20-I|standalone|WordExplorerScreen|WordDetailScreen" docs
git status --short
```

완료 조건은 변경 파일이 승인된 문서 3개에 한정되고 production Dart 코드, route, test guard 변경이 없는 것이다.

## 클라이언트 UI 테스트 체크리스트

Phase 20-I는 docs/audit-only 단계이므로 Codex는 UI 테스트를 수행하지 않는다. 아래 절차는 현재 역할 분류를 클라이언트가 필요 시 확인하기 위한 체크리스트다.

| 테스트 목적 | 시작 화면 | 조작 순서와 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- |
| large-screen embedded Explorer 확인 | Windows Desktop `HomeScreen`, 창 너비 900px 이상 | 상단 검색창에 `H2`를 입력하고 검색한 뒤 식별 가능한 후보 본문을 클릭한다. | 새 route 없이 우측 Explorer graph/detail target이 후보 단어로 바뀌고 panel이 닫힌다. | standalone Explorer route가 열림, submit만으로 retarget됨 | 후보 본문 tap만 embedded Explorer를 retarget함 |
| large-screen full-detail standalone 역할 확인 | large-screen embedded Explorer에서 식별 가능한 단어가 선택된 상태 | 우측 detail pane의 `상세 화면에서 열기` action을 사용한다. | `WordDetailScreen` route가 열리고 edit/delete/graph action을 제공한다. | detail route 미진입, delete 또는 graph action 부재 | full-detail route의 별도 역할을 확인함 |
| small-screen detail route 보존 확인 | 창 너비 900px 미만 `HomeScreen` | `H2`를 검색한 뒤 식별 가능한 후보 본문을 클릭한다. | embedded Explorer 없이 `WordDetailScreen` route가 열린다. | large-screen Explorer 표시, detail route 미진입 | 기존 `homePane → detail route`가 유지됨 |
| small-screen graph route 보존 확인 | 창 너비 900px 미만 default/search 목록 | 식별 가능한 단어의 graph 아이콘을 클릭한다. | standalone `WordGraphScreen` route가 열린다. | graph route 미진입 또는 embedded Explorer 표시 | small-screen graph 직접 진입이 유지됨 |
| detail → graph 경로 확인 | `WordDetailScreen`에서 식별 가능한 단어 표시 | graph 보기 action을 사용한다. | 해당 단어 중심의 standalone `WordGraphScreen` route가 열린다. | 다른 center 표시, graph route 미진입 | detail route의 graph 진입 역할을 확인함 |
