# ExplorerWorkspace Phase 20-L 반응형 목표 구조 감사

> 문서 분류: `reference/context` 및 docs/audit 기록
>
> 기준 main HEAD: `8ec02f0788a918e576307a3d8ccf3175e546e265`
>
> 한국어 작업명: 반응형 ExplorerWorkspace 목표 구조 감사
>
> Phase 20-L은 docs/audit-only 단계다. production Dart 코드, route, test guard, DB/API/repository, DTO/model/public API, dependency, large-screen 또는 small-screen 동작을 변경하지 않는다.

## 1. 감사 목적과 결론

Phase 20-L은 ChatGPT가 제안한 Responsive ExplorerWorkspace 목표 구조 초안을 로컬 production source와 기존 UX authority 문서 기준으로 교차검증한다.

교차검증 결과, Reshet의 장기 UX를 큰 화면의 병렬형 workspace와 작은 화면의 단계형 viewer/flow로 표현되는 하나의 responsive semantic workspace로 보는 방향은 기존 UX authority와 충돌하지 않는다.

다만 이 목표를 현재 production 구현 또는 현재 owner 구조로 오해해서는 안 된다.

- production에서 실제 mount되는 것은 `ExplorerWorkspace` class가 아니라 `HomeScreen` large-screen branch 내부의 embedded `WordExplorerScreen`이다.
- `ExplorerWorkspace` class는 현재 preview-only composition coordinator이며 production canonical owner가 아니다.
- `WordDetailScreen`은 현재 small-screen과 large-screen이 공유하는 active 안정 route다. 장기 흡수 후보로 검토할 수 있지만, 현재 과도기적 fallback으로 확정하지 않는다.
- 큰 화면과 작은 화면이 같은 semantic workspace 기능을 제공해야 한다는 것은 목표 원칙이다. 현재 구현에서는 surface와 action 노출이 다르다.
- 공통 상태 후보와 책임은 현재 하나의 owner에 모여 있지 않고 `HomeScreen`, `WordExplorerScreen`, `WordGraphScreen`, `WordDetailScreen`, Navigator result contract에 분산되어 있다.

Phase 20-L은 위 목표와 현재 경계를 문서화할 뿐, 새로운 production architecture나 migration commitment를 승인하지 않는다.

## 2. 감사 기준

### 2.1 확인한 production source

- `lib/ui/home_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/ui/word_graph_screen.dart`
- `lib/ui/word_info_panel.dart`
- `lib/ui/explorer_workspace/explorer_workspace.dart`
- `lib/ui/explorer_workspace/explorer_workspace_contract.dart`
- `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart`

### 2.2 확인한 주요 문서

- `docs/ux/workspace_ux_architecture.md`
- `docs/ux/responsive_layout_policy.md`
- `docs/architecture/explorer_workspace_constitution.md`
- `docs/ux/explorer_workspace_unification.md`
- `docs/ux/explorer_workspace_phase20a_surface_navigation_role_audit.md`
- `docs/ux/explorer_workspace_phase20i_standalone_role_audit.md`
- `docs/ux/explorer_workspace_phase20k_embedded_full_detail_role_audit.md`

`workspace_ux_architecture.md`와 `responsive_layout_policy.md`는 persistent semantic workspace, desktop의 병렬 surface, mobile viewer/flow 원칙을 이미 authority로 정의한다. `explorer_workspace_constitution.md`는 현재 `ExplorerWorkspace` class가 preview-only coordinator이며 production owner가 아님을 고정한다.

## 3. Responsive ExplorerWorkspace 목표 정의

이 문서에서 Responsive ExplorerWorkspace는 특정 Flutter class 또는 신규 production owner를 뜻하지 않는다.

Responsive ExplorerWorkspace는 다음 목표를 설명하는 UX architecture vocabulary다.

- Reshet의 search, navigation, graph, detail/action, exploration history가 서로 관계없는 화면 묶음이 아니라 하나의 semantic workspace로 경험되어야 한다.
- 큰 화면은 여러 semantic surface를 병렬로 노출할 수 있다.
- 작은 화면은 같은 semantic 관계를 한 번에 하나의 primary surface 또는 단계형 flow로 표현할 수 있다.
- form factor가 달라도 center, selection, detail context, return path와 같은 semantic continuity가 불필요하게 끊기지 않아야 한다.

이 목표 정의는 production `ExplorerWorkspace` mount, `ExplorerWorkspaceState` source-of-truth 승격, controller 도입, route 제거를 뜻하지 않는다.

## 4. 현재 production 구조

### 4.1 큰 화면

현재 large-screen primary flow는 `HomeScreen` 내부의 embedded `WordExplorerScreen`이다.

- `HomeScreen`은 상단 일반 검색, Strong Rail, `_largeScreenExplorerWordId`를 소유한다.
- Strong Rail 또는 transient 검색 후보의 명시적 선택은 `_showWordInLargeScreenExplorerPane(...)`를 통해 Explorer target을 바꾼다.
- `ValueKey(_largeScreenExplorerWordId)`가 바뀌면 새 `WordExplorerScreen` owner instance가 생성되므로 기존 selection과 internal history는 초기화된다.
- embedded `WordExplorerScreen`은 `WordGraphScreen`과 detail pane을 병렬로 mount한다.
- embedded detail pane의 full-detail action은 active `WordDetailScreen` route를 연다.

따라서 현재 large-screen은 목표 병렬형 workspace 방향의 production 기반을 갖고 있다. 그러나 production `ExplorerWorkspace` class가 mount된 상태는 아니다.

### 4.2 작은 화면

현재 small-screen은 `HomeScreen`의 `return homePane` 흐름을 사용한다.

- default/search 목록 본문 tap과 상세 action은 `WordDetailScreen` route를 연다.
- 목록 graph action은 `WordGraphScreen` route를 연다.
- `WordDetailScreen`의 graph action도 standalone `WordGraphScreen` route를 연다.
- small-screen에는 embedded `WordExplorerScreen`, Strong Rail, large-screen transient 검색 panel이 없다.

현재 route 흐름은 한 번에 하나의 primary semantic surface를 제공하는 mobile viewer/flow와 호환된다. 다만 route 사이의 상태와 result 계약을 mobile ExplorerWorkspace로 재정의한 상태는 아니다.

### 4.3 preview-only `ExplorerWorkspace`

`ExplorerWorkspace` class와 `ExplorerWorkspaceState`는 현재 preview-only composition 및 projection 경계다.

- production repository owner가 아니다.
- Navigator 또는 route stack owner가 아니다.
- canonical selection/center/detail authority가 아니다.
- persistence/history/restore authority가 아니다.
- `WordExplorerScreen._readOnlyWorkspaceProjection`은 현재 owner state를 read-only projection으로만 변환한다.

따라서 목표 architecture 문서에서 `ExplorerWorkspace`라는 용어를 사용할 때 production class 또는 현재 공통 owner를 지칭한다고 해석하지 않는다.

## 5. 큰 화면 목표 UX

큰 화면의 목표는 search, persistent navigation, graph, detail/action을 하나의 semantic workspace 안에서 병렬로 경험하게 하는 것이다.

- Search는 semantic entry surface로 접근 가능해야 한다.
- Strong navigation은 orientation과 명시적 retarget을 지원해야 한다.
- Graph surface는 관계 맥락을 제공해야 한다.
- Detail/action surface는 현재 선택 또는 detail target의 읽기와 승인된 action을 제공해야 한다.
- edit 또는 full-detail route 복귀 후에도 center, selection, detail context가 불필요하게 손실되지 않아야 한다.

현재 embedded `WordExplorerScreen`은 graph/detail 병렬 구성과 center/selection/history coordination을 제공한다. 그러나 full-detail route, standalone graph route, `ValueKey` retarget 초기화, 분산 refresh 책임은 active 상태로 유지된다.

Phase 20-L에서는 이 active 경계를 제거하거나 변경하지 않는다.

## 6. 작은 화면 목표 UX

작은 화면의 목표는 큰 화면의 좌우 분할을 축소하는 것이 아니다.

장기적으로는 search 또는 explore view, graph view, detail/action view가 같은 semantic workspace의 단계형 presentation으로 이어지는 mobile ExplorerWorkspace 가능성을 검토할 수 있다.

이 목표를 검토할 때는 다음 계약이 먼저 필요하다.

- 현재 semantic position과 return path 표시
- 단계 전환과 Navigator 뒤로가기 의미
- detail 또는 graph 진입 후 원래 search/explore context 복귀
- edit/delete/graph route result 소비 위치
- center/selection/detail target 유지 또는 초기화 기준
- small-screen에서 필요한 action의 접근 위치

현재 `HomeScreen → WordDetailScreen → WordGraphScreen` route 흐름은 active 안정 경로이며, 장기 mobile presentation 후보를 이유로 즉시 제거하거나 변경하지 않는다.

## 7. 목표 원칙과 현재 기능 노출 차이

큰 화면과 작은 화면은 장기적으로 같은 semantic workspace 기능을 form factor에 맞는 표현 방식으로 제공해야 한다. 그러나 이는 현재 구현의 action 노출이 동일하다는 뜻이 아니다.

| 역할 또는 action | 현재 large-screen embedded 흐름 | 현재 small-screen 흐름 |
| --- | --- | --- |
| search | 상단 검색과 transient 결과 panel | `homePane` 검색과 목록 |
| Strong navigation | persistent Strong Rail | desktop 형태의 Strong Rail 없음 |
| graph와 detail 동시 표시 | embedded `WordExplorerScreen`에서 제공 | 제공하지 않음 |
| embedded detail edit | 제공 | embedded pane 없음 |
| delete | embedded pane에는 없음, full-detail route에서 제공 | `WordDetailScreen` route에서 제공 |
| graph action | embedded pane에는 없음, full-detail route에서 standalone graph 진입 | 목록 또는 detail route에서 standalone graph 진입 |
| center/selection/history | `WordExplorerScreen` 내부 coordination | 공통 mobile workspace owner 없음 |

따라서 목표 원칙은 semantic capability와 continuity의 방향을 설명한다. 현재 surface/action 차이를 숨기거나 이미 통합되었다고 선언하는 근거로 사용하지 않는다.

## 8. `WordDetailScreen`의 현재 역할과 장기 위치

`WordDetailScreen`은 현재 small-screen과 large-screen이 공유하는 active 안정 route다.

현재 역할은 다음과 같다.

- 전달받은 initial display를 먼저 표시하고 detail 전용 context로 다시 읽기
- detail 전용 edit 진입과 저장 후 자체 refresh
- 관계 수 안내를 포함한 delete 확인과 write 실행
- graph cache clear
- callback 없는 standalone `WordGraphScreen` 진입
- delete 성공을 `true` route result로 caller에 반환

large-screen embedded detail pane은 split-view 표시, Explorer 전용 edit, full-detail route 진입을 제공하지만 delete와 graph action은 직접 제공하지 않는다.

장기적으로 detail reading과 일부 action을 responsive workspace 내부 detail/action surface로 흡수하는 후보는 검토할 수 있다. 그러나 `WordDetailScreen`을 현재 과도기적 fallback으로 확정하지 않는다. 대체 UX와 state/result 계약이 설계되고 승인되기 전까지 active 안정 route로 유지한다.

## 9. 공통 상태 후보와 현재 owner 분포

다음 항목은 장기 responsive workspace에서 공통 semantic state 또는 coordination contract 후보로 검토할 수 있다. 현재 단일 `ExplorerWorkspace` owner state라는 뜻은 아니다.

| 후보 상태 또는 책임 | 현재 주요 owner | 현재 경계 |
| --- | --- | --- |
| center word | `WordExplorerScreen`, `WordGraphScreen` | Explorer와 Graph가 각각 center id를 보유하며 callback으로 연결되는 경계가 있음 |
| selected word | `WordExplorerScreen`, `WordGraphScreen` | embedded mode에서 callback으로 동기화하지만 local state가 분산됨 |
| detail target | `WordExplorerScreen`, `WordDetailScreen` | embedded selected display와 detail route `_wordId`/display가 분리됨 |
| graph data와 viewport | `WordGraphScreen`, `WordGraphDataCache` | graph local state와 cache 책임 |
| search state | `HomeScreen` | query, result future, default/search mode, transient panel 표시 소유 |
| internal exploration history | `WordExplorerScreen` | center/selected snapshot과 availability 검증 소유 |
| route history와 result | Navigator 및 각 caller | `bool?` delete result, edit result, caller별 복귀 처리 |
| refresh | `HomeScreen`, `WordExplorerScreen`, `WordDetailScreen`, `WordGraphScreen` | 하나의 상태가 아니라 owner별 reread, graph reload, cache invalidation 동작으로 분산 |

현재 owner 분포는 목표 architecture 후보와 충돌하지 않지만, owner 이동 또는 통합을 이미 승인하지도 않는다. 공통 계약 없이 상태나 책임을 이동하면 안 된다.

## 10. 책임별 흡수 가능성과 위험

### 10.1 흡수 후보로 검토 가능한 책임

- detail 표시: embedded pane에서 이미 수행 중이므로 비교적 낮은 위험의 presentation 후보
- edit 진입: embedded pane에 이미 Explorer 전용 edit 경로가 있어 낮음에서 중간 위험의 후보
- edit 후 detail reread: 현재 owner별 경로가 존재하므로 명시적 refresh 계약을 전제로 검토 가능
- graph node selection과 center request: embedded graph callback 경계가 이미 있어 workspace coordination 후보로 검토 가능

### 10.2 아직 이동하면 위험한 책임

- delete 실행과 결과 소비
- center 삭제 후 이전/다음 history 복구 또는 host pop
- 비중심 삭제 후 selection 해제, graph refresh, history replace
- route result와 caller별 복귀 refresh
- standalone graph 내부 same-node 재탭 navigation
- graph create 후 callback 없는 `pushReplacement`
- `ValueKey(_largeScreenExplorerWordId)` retarget과 owner/history continuity
- small-screen 단계 전환과 뒤로가기 의미

## 11. 위험도별 구현 후보 분류

| 후보 | 위험도 | 감사 판단 |
| --- | --- | --- |
| embedded detail 표시 유지 또는 presentation 정리 | 낮음 | 이미 active pane에서 수행 중 |
| embedded edit 진입 정리 | 낮음~중간 | 이미 active 경로가 있으나 refresh 계약 확인 필요 |
| edit 후 responsive workspace refresh 계약 | 중간 | detail, center display seed, graph revision, history replace 기준 필요 |
| graph action의 단순 진입 정책 변경 | 중간 | large-screen standalone route 유지 또는 workspace center 이동 정책 필요 |
| standalone graph 내부 navigation과 create 후 replacement 흡수 | 높음 | callback 없는 navigation과 route replacement 대체 계약 필요 |
| delete 책임 이동 | 높음 | center/selection/history/cache/host pop 영향이 큼 |
| small-screen mobile ExplorerWorkspace | 높음 | 단계 전환, 뒤로가기, route result 의미 재설계 필요 |
| `WordDetailScreen` 제거 | 매우 높음 | 대체 detail/action UX와 상태/result 계약 안정화 이후에만 검토 |

graph action은 범위를 분리해 평가한다. 단순 진입 위치 또는 large-screen redirect 정책은 중간 위험이지만, standalone graph가 가진 내부 navigation과 create 후 replacement까지 workspace로 흡수하는 작업은 높은 위험이다.

## 12. ChatGPT 초안 대비 보정 반영

1. production mount 주체를 `ExplorerWorkspace`가 아니라 embedded `WordExplorerScreen`으로 기록했다.
2. `ExplorerWorkspace` class는 현재 preview-only coordinator임을 명시했다.
3. `WordDetailScreen`을 과도기적 fallback으로 확정하지 않고 active 안정 route이자 장기 흡수 후보로 기록했다.
4. 큰 화면과 작은 화면의 기능 동일성은 목표 원칙으로 한정하고 현재 action 노출 차이를 별도 표로 기록했다.
5. 공통 상태 후보를 현재 단일 owner 상태로 표현하지 않고 owner별 분산 상태와 동작으로 기록했다.
6. `refresh state`를 단일 상태가 아니라 owner별 reread, graph reload, cache invalidation 책임으로 보정했다.
7. graph action의 단순 진입 정책 변경과 standalone 내부 navigation/create replacement 흡수를 각각 중간 위험과 높은 위험으로 분리했다.

## 13. Phase 20-L 금지 및 유지 범위

Phase 20-L에서는 다음을 수행하지 않는다.

- production `ExplorerWorkspace` mount
- `ExplorerWorkspaceState` production source-of-truth 승격
- production Dart 코드 변경
- test guard 변경
- route 제거 또는 동작 변경
- `WordDetailScreen` 제거 또는 역할 이동
- small-screen route 변경
- large-screen full-detail route 변경
- embedded Explorer refresh 구조 변경
- delete 흐름 변경
- graph route 또는 standalone graph navigation 변경
- center/selection/history 정책 변경
- DB/API/repository 변경
- DTO/model/public API 추가 또는 변경
- dependency 변경
- `docs/logs/FEATURE_STATUS.md` 변경

## 14. 이후 Phase 후보

다음 항목은 별도 설계와 사용자 승인이 필요한 후속 후보다. Phase 20-L에서 구현하지 않는다.

1. responsive workspace semantic state와 현재 분산 owner 사이의 coordination contract 감사
2. large-screen graph action의 workspace-aware 진입 정책 감사
3. edit 후 detail/center/graph/history refresh 계약 감사
4. delete 책임 및 typed result contract 감사
5. standalone graph 내부 navigation과 create 후 replacement 역할 감사
6. mobile ExplorerWorkspace 단계 전환, 뒤로가기, route result 정책 감사
7. 대체 detail/action surface가 안정된 이후의 `WordDetailScreen` 장기 역할 재감사

## 15. 검증 기준

Phase 20-L 문서 반영 후 다음 명령으로 docs/audit-only 범위를 확인한다.

```text
git status --short --branch
git branch --show-current
git rev-parse main
git rev-parse origin/main
git log -1 --oneline
git diff --stat
git diff --check
git diff --name-only
rg "WordDetailScreen|WordExplorerScreen|WordGraphScreen|ValueKey\(_largeScreenExplorerWordId\)|_openSelectedWordDetail|Navigator.push|Navigator.pop|center|selection|history|return homePane" lib docs test
```

완료 조건은 변경 파일이 승인된 문서 3개에 한정되고 production Dart 코드, test guard, DB/API/repository, DTO/model/public API, dependency 변경이 없는 것이다.

Phase 20-L은 UI와 production behavior를 변경하지 않으므로 Codex UI 테스트, 전체 `flutter test`, 전체 `flutter analyze`를 필수 완료 조건으로 삼지 않는다.
