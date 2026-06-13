# ExplorerWorkspace Phase 20-P detail route 책임 경계 감사

> 문서 분류: `reference/context` 및 docs/audit 기록
>
> 기준 main HEAD: `c0b7a909b2742c06709abb83c62d4de499a92123`
>
> 한국어 작업명: detail route 책임 경계 감사
>
> Phase 20-P는 docs/audit-only 단계다. production Dart 코드, route, test, DB/API/repository/domain/dependency, large-screen 또는 small-screen 동작을 변경하지 않는다. 이 문서의 흡수 가능성은 후속 감사 및 설계 후보를 뜻하며 구현 승인이 아니다.

## 1. 문서 성격과 감사 결론

Phase 20-P는 Phase 20-N과 Phase 20-O 이후 `WordDetailScreen`에 남은 책임을 실제 로컬 production source 기준으로 교차검증하고, large-screen embedded Explorer로 흡수 가능한 후보와 독립 route에 남겨야 할 책임을 분리한다.

이번 Phase에서는 구현 후보를 제안만 하며 적용하지 않는다. `WordDetailScreen` 제거 또는 축소, route 변경, action 노출 변경, edit/delete/graph 구현 이동은 수행하지 않는다.

감사 결론은 다음과 같다.

- `WordDetailScreen`은 아직 small-screen과 일반 detail caller가 사용하는 active 안정 route다.
- `WordDetailScreen`은 detail 전용 reread, detail edit와 local refresh, delete 전체 실행 흐름, 기본 standalone graph 진입, typed route result, local snackbar를 소유한다.
- embedded Explorer는 direct edit와 typed delete/graph result 해석, embedded graph center retarget, delete 후 center/selection/history 복구를 이미 소유한다.
- edit는 Explorer direct path가 이미 존재하므로 delete보다 작은 단위의 후속 감사 후보로 다룰 수 있다. 다만 detail용/Explorer용 read context와 edit 후 refresh 계약 감사가 Phase 20-Q에서 선행되어야 하며, Phase 20-P에서는 구현하지 않는다.
- delete 이동은 DB write, 관계 수 확인, 확인 dialog, graph cache clear, typed result, caller별 복구와 refresh, small-screen route 보존이 연결된 높은 위험 후보다. Phase 20-P에서는 구현 대상으로 다루지 않는다.
- full-detail route 자체의 제거 또는 축소는 대체 action과 form factor별 route 책임이 안정된 이후에만 재감사할 수 있는 후보다.

## 2. 기준 상태와 확인 대상

### 2.1 기준 상태

- Phase 20-N은 delete 성공 결과를 `WordDetailDeletedResult` typed contract로 명시했다.
- Phase 20-O는 large-screen embedded Explorer full-detail route의 graph action을 `WordDetailGraphRequestedResult`로 caller에 반환하고 embedded graph center를 retarget하도록 분기했다.
- 기준 main HEAD는 `c0b7a909b2742c06709abb83c62d4de499a92123`이다.
- 기준 최신 커밋 메시지는 `feat: Phase 20-O detail graph action caller result 분기`다.

### 2.2 확인한 파일

- `lib/ui/word_detail_screen.dart`
- `lib/ui/word_detail_route_result.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_info_panel.dart`
- `lib/ui/word_graph_screen.dart`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`

## 3. `WordDetailScreen` 현재 책임

### 3.1 Detail reread와 표시

`WordDetailScreen`은 `wordId`와 `initialDisplayItem`을 입력으로 받는다. `initState()`에서 initial display를 즉시 사용한 뒤 `_refreshDetailScreenDisplayItem()`을 비동기로 실행한다.

Detail reread는 `getWordDetailLikeDisplayItemByIdForDetailScreen(_wordId)` 전용 read context를 사용한다. reread가 null 또는 오류이면 initial display를 유지하며, 오래된 비동기 응답이 최신 표시를 덮지 않도록 reload token을 사용한다.

### 3.2 Edit route와 local refresh

`_openEdit()`은 `getWordEditSeedForDetailEdit(_wordId)`로 detail edit seed를 읽고 `WordEditScreen.fromSeed(...)` route를 연다. `WordEditSaveResult`가 반환되면 detail route 내부 표시를 다시 읽고 local snackbar를 표시한다.

이 책임은 Explorer direct edit와 유사하지만 동일하지 않다. Explorer는 `getWordEditSeedForExplorerEdit(...)`를 사용하고, 저장 후 `_refreshSelectedWord(...)`로 selected detail, 필요 시 center display seed, graph revision과 history snapshot을 갱신한다.

### 3.3 Delete flow

`_confirmDelete()`은 다음 책임을 한 흐름으로 소유한다.

1. `countRelationsForWord(_wordId)`로 연결 관계 수를 확인한다.
2. 관계 수를 포함한 delete confirm dialog를 표시한다.
3. 승인 후 `DeleteWordCommand(wordId: _wordId)`를 `WordWriteService`로 실행한다.
4. `WordGraphDataCache.clear()`를 실행한다.
5. 성공 또는 실패 snackbar를 표시한다.
6. 성공 시 `WordDetailDeletedResult(wordId: _wordId)`를 caller에 반환한다.

Delete 실행과 delete 이후 workspace 복구는 같은 owner가 아니다. `WordDetailScreen`은 write와 typed result 반환을 소유하고, Explorer caller는 result를 해석해 center/selection/history를 복구한다. Home caller는 result 타입을 해석하지 않고 route 복귀 후 목록을 refresh한다.

### 3.4 Graph action

`_openGraph()`은 `wordExistsForGraphNavigation(_wordId)`로 단어 존재를 확인하고 unavailable이면 local snackbar를 표시한다.

- 기본 `standaloneRoute` mode에서는 `WordGraphScreen(centerWordId: _wordId)` route를 push한다.
- embedded Explorer full-detail caller가 지정한 `returnToCaller` mode에서는 `WordDetailGraphRequestedResult(wordId: _wordId)`를 반환한다.

기본 standalone graph route는 callback 없는 `WordGraphScreen`이다. 이 graph는 같은 연결 노드 재탭 시 새 graph route를 push하고, create 이후 조건에 따라 `pushReplacement`를 수행하는 독립 navigation 책임을 유지한다.

### 3.5 Route result

`WordDetailRouteResult`는 현재 다음 두 typed result를 제공한다.

| result | 발생 위치 | caller 책임 |
| --- | --- | --- |
| `WordDetailDeletedResult` | delete 성공 후 `WordDetailScreen` | Explorer는 delete 복구, Home은 일반 목록 refresh |
| `WordDetailGraphRequestedResult` | `returnToCaller` graph action | Explorer는 embedded graph center retarget |

일반 뒤로가기는 null result다. Explorer는 null 또는 별도 처리 대상이 아닌 일반 복귀에서 `_refreshSelectedWord(...)`를 실행하고, Home은 route 복귀 후 `_refreshWords()`를 실행한다.

### 3.6 Snackbar와 unavailable handling

`WordDetailScreen`은 edit 성공, delete 성공, delete 실패, graph/edit seed unavailable을 route local snackbar로 표시한다. 이 snackbar 책임은 현재 route context와 묶여 있다.

### 3.7 Caller refresh와의 관계

`WordDetailScreen` 내부 refresh와 caller refresh는 서로 다른 책임이다.

- Detail route 내부 edit 후에는 `_refreshDetailScreenDisplayItem()`으로 route 표시를 갱신한다.
- Explorer 일반 복귀 후에는 `_refreshSelectedWord(...)`로 split-view detail과 필요 시 center/graph/history를 갱신한다.
- Home detail route 복귀 후에는 `_refreshWords()`로 현재 목록 future를 갱신한다.
- Delete와 graph typed result는 Explorer에서 일반 복귀 refresh보다 먼저 분기된다.

## 4. Phase 20-N/O 이후 embedded Explorer가 이미 흡수한 책임

### 4.1 Typed result 해석

`WordExplorerScreen._openSelectedWordDetail()`은 `Navigator.push<WordDetailRouteResult>`로 full-detail route를 열고 다음 결과를 구분한다.

- `WordDetailDeletedResult`: `_handleDeletedSelectedWord(...)` 실행
- `WordDetailGraphRequestedResult`: `_selectWord(..., changeCenterWord: true)` 실행
- 일반/null 복귀: `_refreshSelectedWord(...)` 실행

### 4.2 Embedded graph center retarget

Phase 20-O 이후 full-detail route의 graph action은 large-screen embedded Explorer caller에서 standalone graph route를 열지 않는다. `WordDetailGraphRequestedResult`를 받은 Explorer가 기존 center 변경 경로를 사용해 center, selection과 history entry를 갱신한다.

### 4.3 Delete 이후 Explorer 복구

Explorer는 delete 실행 자체를 소유하지 않지만 typed delete result 이후 복구를 소유한다.

- 비중심 선택 단어 삭제: center를 유지하고 selection/detail을 비우며 graph와 현재 history entry를 갱신한다.
- center 단어 삭제: 사용 가능한 이전 history, 다음 history 순서로 복구한다.
- 유효한 history가 없으면 Explorer host에 별도 delete 결과를 전달한다.

### 4.4 Embedded pane direct edit

Embedded detail pane은 `onEdit: _openEditSelectedWord`를 직접 제공한다. Explorer direct edit는 Explorer 전용 edit seed를 읽고, 저장 후 selected detail, 필요 시 center display, graph revision과 history snapshot을 갱신한다.

Embedded pane은 계속 `onDelete`와 `onShowGraph`를 직접 제공하지 않는다. Phase 20-P는 이 action 노출을 변경하지 않는다.

## 5. 아직 `WordDetailScreen`에 남겨야 하는 책임

다음 책임은 현재 active contract 때문에 `WordDetailScreen`에 남겨야 한다. 장기 재검토 후보가 될 수 있어도 Phase 20-P에서 이동 또는 제거하지 않는다.

- small-screen `HomeScreen → WordDetailScreen` route
- 일반 detail caller와 기본 `standaloneRoute` graph action
- callback 없는 standalone `WordGraphScreen` 진입
- detail 전용 reread와 initial display fallback
- detail 전용 edit seed와 route local edit refresh
- delete 관계 수 확인, confirm dialog, write 실행, cache clear, 성공/실패 표시
- `WordDetailDeletedResult`와 `WordDetailGraphRequestedResult` 반환
- route local snackbar와 unavailable handling
- caller별 refresh를 시작할 수 있는 안정적인 route 복귀 경계

## 6. Explorer 흡수 후보 matrix

아래의 “흡수 가능성”은 구현 승인이나 확정 계획이 아니다. 후속 Phase에서 감사 또는 설계할 후보를 분류한 것이다.

| 후보 | 현재 owner | 흡수 가능성 | 위험도 | 선행 조건 | Phase 20-Q/R 후보 여부 |
| --- | --- | --- | --- | --- | --- |
| edit | Explorer direct edit와 `WordDetailScreen` detail edit에 분산 | large-screen embedded 경로의 책임 정리 후보. 이번 Phase에서는 구현하지 않음 | 낮음~중간 | detail/Explorer edit seed read context 차이, 저장 후 detail/center/graph/history refresh 계약, snackbar owner 감사 | Phase 20-Q 우선 감사 후보 |
| graph action | 기본 standalone graph는 `WordDetailScreen`, embedded retarget은 Explorer | large-screen full-detail graph action은 Phase 20-O에서 일부 흡수됨. 추가 흡수는 별도 감사 대상 | 중간 | small-screen 기본 standalone 유지, unavailable 처리, standalone graph 내부 navigation/create replacement 분리 | Phase 20-Q 이후 별도 후보 |
| delete | 실행은 `WordDetailScreen`, 복구는 Explorer, 목록 refresh는 Home | 높은 위험의 장기 후보. Phase 20-P에서는 구현 대상으로 다루지 않음 | 높음 | 관계 수, confirm UX, write/cache/snackbar owner, typed result, center/selection/history 복구, Home refresh, small-screen 보존 계약 | Phase 20-R precondition audit 후보 |
| full-detail route 자체 | `WordDetailScreen`과 caller별 Navigator 계약 | 대체 action과 route 책임이 안정된 이후 재감사 후보. 이번 Phase에서는 제거·축소하지 않음 | 매우 높음 | edit/graph/delete 대체 경계, detail reread owner, local feedback, small-screen route와 back navigation, caller refresh 안정화 | Q/R 이후 장기 재감사 후보 |

## 7. Edit 우선 판단

Edit는 delete보다 작은 단위의 후속 감사 후보로 분류한다.

- Explorer embedded pane에 이미 direct edit path가 존재한다.
- Explorer direct edit는 selected word context와 저장 후 refresh 경로를 이미 소유한다.
- DB delete, 관계 수 확인, graph cache 전체 clear, center 삭제 복구 같은 delete 전용 위험이 없다.

그러나 edit 책임을 즉시 이동하거나 full-detail edit를 제거할 수 있다는 뜻은 아니다.

- Detail route와 Explorer는 서로 다른 edit seed read context를 사용한다.
- Detail route는 local reread와 snackbar를 소유한다.
- Explorer는 selected detail, center display, graph revision과 history replace를 함께 고려한다.
- Small-screen은 embedded Explorer direct edit 대체 경로가 없다.

따라서 Phase 20-Q는 구현 Phase가 아니라 edit 책임 경계와 refresh/read-context 계약 감사 또는 최소 guardrail 후보로 시작해야 한다. Phase 20-P에서는 edit 구현을 이동하지 않는다.

## 8. Delete 보류 판단

Delete는 높은 위험 후보이며 Phase 20-P에서 구현 대상으로 다루지 않는다.

Delete 이동이 높은 위험인 이유는 다음 책임이 함께 연결되어 있기 때문이다.

- DB write: `DeleteWordCommand` 실행과 오류 처리
- relation count: 삭제 전 관계 수 조회와 사용자 안내
- confirm dialog: 취소/승인 UI 및 삭제 진행 상태
- graph cache clear: 성공 후 `WordGraphDataCache.clear()`
- route pop result: `WordDetailDeletedResult` 반환
- center/selection/history 복구: Explorer가 삭제 대상의 center 여부와 history 가용성을 기준으로 복구
- caller refresh: Explorer와 Home의 복귀 후 처리 방식이 다름
- small-screen route 보존: embedded Explorer가 없는 small-screen에서도 delete가 제공되어야 함
- local snackbar: 성공과 실패 피드백을 표시할 owner가 필요함

Delete action을 embedded pane에 추가하는 것만으로는 위 계약을 흡수할 수 없다. Phase 20-R은 delete 이동 전 precondition audit 후보이며, write owner, feedback owner, typed result 대체 여부, 복구와 small-screen 계약을 먼저 감사해야 한다.

## 9. Phase 20-Q/R 후보

### 9.1 Phase 20-Q 후보

Phase 20-Q는 edit 책임 경계 감사 또는 최소 guardrail 후보다.

- detail edit와 Explorer direct edit의 seed read context 차이
- edit 저장 후 detail/center/graph/history refresh 계약
- local snackbar와 unavailable feedback owner
- small-screen detail edit 유지 경계
- full-detail route edit를 유지하거나 축소하기 위한 선행 조건

Phase 20-Q에서도 별도 승인 없이 구현 이동을 수행하지 않는다.

### 9.2 Phase 20-R 후보

Phase 20-R은 delete 이동 전 precondition audit 후보다.

- relation count와 confirm UX owner
- `WordWriteService`와 cache invalidation owner
- `WordDetailDeletedResult` 유지 또는 대체 contract
- 비중심/center 삭제 후 Explorer 복구
- Home 목록 refresh와 small-screen route 보존
- 성공/실패 snackbar 및 삭제 진행 상태 owner

Phase 20-R은 delete 구현 이동 승인이 아니며, 높은 위험 경계를 먼저 감사하는 단계 후보로만 기록한다.

## 10. Phase 20-P 금지 및 유지 범위

Phase 20-P에서는 다음을 수행하지 않는다.

- `lib/` production code 변경
- `test/` 변경
- DB 파일, DB/API/repository/domain/dependency 변경
- `pubspec.yaml`, `pubspec.lock` 변경
- route 구조 변경
- `WordDetailScreen` 제거 또는 축소 구현
- `WordInfoPanel` action 변경
- embedded detail pane에 delete/graph action 추가
- small-screen detail route 변경
- standalone `WordGraphScreen` route 변경
- center/selection/history 정책 변경
- delete 또는 edit 구현 이동
- production behavior guard 변경

## 11. 명령어 기반 검증 기준

Phase 20-P 문서 반영 후 다음 명령으로 docs/audit-only 범위를 확인한다.

```text
git diff --name-only
git diff --check
rg -n "Phase 20-P|WordDetailScreen|WordDetailRouteResult|WordDetailGraphRequestedResult|WordDetailDeletedResult|delete|edit|graph action" docs/ux/explorer_workspace_phase20p_detail_route_responsibility_audit.md docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md
git status --short --branch
```

완료 조건은 변경 파일이 승인된 문서 3개에 한정되고 `lib/`, `test/`, DB, dependency, platform 파일 변경이 없는 것이다.

## 12. 수동 테스트 체크리스트

Phase 20-P는 UI와 production behavior를 변경하지 않는 docs/audit-only 단계다.

- Codex는 UI 테스트를 수행하지 않는다.
- 클라이언트 UI 수동 테스트도 Phase 20-P 완료 조건이 아니다.
- command 기반 문서 범위와 문구 확인만 수행한다.
- `lib/`, `test/` 변경이 없으면 `flutter test`와 `flutter analyze`를 실행하지 않으며, 실행하지 않은 사유를 결과 보고에 명시한다.
