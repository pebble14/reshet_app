# ExplorerWorkspace Phase 20-K embedded full-detail 역할 감사

> 문서 분류: `reference/context` 및 docs/audit 기록
>
> 기준 HEAD: `9e463fcba74e694aefdee824edbe63205247e868`
>
> 한국어 작업명: embedded Explorer full-detail action 역할 감사
>
> Phase 20-K는 docs/audit-only 단계다. production Dart 코드, route, test guard, DB/API/repository, DTO/model/public API, large-screen 또는 small-screen 동작을 변경하지 않는다.

## 1. 감사 목적과 결론

Phase 20-K는 `WordExplorerScreen._openSelectedWordDetail()`의 실제 역할과 embedded Explorer detail pane, `WordDetailScreen` route 사이의 책임 차이를 로컬 production source 기준으로 분해한다.

embedded Explorer detail pane의 `상세 화면에서 열기` action은 dormant 경로가 아니다. 현재 large-screen embedded Explorer에서 실제로 호출 가능한 active route이며, `WordDetailScreen`이 가진 delete, standalone graph 진입, route result 반환 역할을 연결한다.

Phase 20-K의 결론은 다음과 같다.

- embedded detail pane과 `WordDetailScreen`은 `WordInfoPanel` 표시 contract를 공유하지만 action과 refresh 책임은 동일하지 않다.
- embedded detail pane은 split-view 표시, Explorer 전용 edit, full-detail route 진입을 제공한다.
- `WordDetailScreen`은 detail 전용 reread, detail 전용 edit, delete, standalone graph 진입, delete 성공 route result 반환을 제공한다.
- full-detail route 복귀 후 `WordExplorerScreen`은 delete 결과를 분기하고, delete가 아니면 split-view 표시와 필요 시 center 표시 및 graph를 다시 동기화한다.
- small-screen detail route와 large-screen embedded full-detail route는 같은 `WordDetailScreen`을 공유하지만 caller의 초기 read context와 route 복귀 후 refresh 책임은 다르다.
- 현재 full-detail route를 제거하거나 통합하려면 대체 action, delete 결과 반환, center/selection/history 복구, refresh owner, form factor별 graph 진입 정책을 먼저 설계하고 승인해야 한다.

## 2. 감사 대상과 active 진입 경계

확인한 핵심 production 파일은 다음과 같다.

- `lib/ui/word_explorer_screen.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/ui/word_info_panel.dart`
- `lib/ui/word_graph_screen.dart`
- `lib/ui/home_screen.dart`
- `lib/data/repositories/word_repository.dart`

현재 active 진입 경계는 다음과 같다.

| form factor | 시작 위치 | active 경로 | route 복귀 owner |
| --- | --- | --- | --- |
| large-screen | embedded `WordExplorerScreen` detail pane | `_openSelectedWordDetail()` → `WordDetailScreen` | `WordExplorerScreen` |
| small-screen | `HomeScreen` default/search 목록 본문 또는 상세 action | `_openDefaultStrongWordDetail(...)` → `WordDetailScreen` | `HomeScreen` |
| 모든 `WordDetailScreen` route | `그래프 보기` action | `_openGraph()` → standalone `WordGraphScreen` | `WordDetailScreen` 아래 Navigator stack |

large-screen shared default/search 목록은 현재 mount되지 않는다. 따라서 large-screen에서 실제 full-detail route 진입점은 embedded Explorer detail pane의 active action이다.

## 3. `_openSelectedWordDetail()` 정확한 역할

`WordExplorerScreen._openSelectedWordDetail()`은 현재 선택 상태가 완성되어 있을 때만 route를 연다.

### 3.1 진입 조건과 payload

- `_selectedWordId`가 null이면 진입하지 않는다.
- `_selectedWordDisplayItem`이 null이면 진입하지 않는다.
- route push 전에 선택 단어가 현재 center인지 `wasCenterWord`로 저장한다.
- `Navigator.push<bool?>`와 `MaterialPageRoute`를 사용한다.
- `WordDetailScreen`에 다음 payload를 전달한다.
  - `wordId: selectedWordId`
  - `initialDisplayItem: selectedDisplayItem`

`selectedDisplayItem`은 Explorer가 `getWordDetailLikeDisplayItemByIdForSplitView(wordId)`로 읽어 보유한 split-view 표시 contract다. 이 payload는 route 첫 표시를 위한 초기값이며 `WordDetailScreen`의 최종 read authority를 대체하지 않는다.

### 3.2 route result와 복귀 처리

`WordDetailScreen`의 route result는 `bool?`이며, 현재 명시적 의미는 delete 성공 여부다.

| route result | Explorer 처리 |
| --- | --- |
| `true` | `_handleDeletedSelectedWord(wasCenterWord: ...)` 실행 |
| `null` 또는 `false` | `_refreshSelectedWord(...)` 실행 |

delete가 아닌 복귀에서는 다음 인자로 선택 단어를 다시 읽는다.

- `wordId: selectedWordId`
- `syncCenterWord: wasCenterWord`
- `refreshGraphIfChanged: true`

따라서 route 안에서 edit가 발생했는지 별도 result로 구분하지 않아도, 일반 복귀 시 split-view 표시를 다시 읽고 실제 변경이 확인되면 graph revision을 증가시킨다. 선택 단어가 center였으면 center 표시 seed도 갱신한다. 현재 history에는 새 위치를 push하지 않고 갱신된 center/selection snapshot을 replace한다.

## 4. embedded detail pane과 `WordDetailScreen` 책임 차이

두 surface는 같은 `WordDetailLikeDisplayItem` 기반 `WordInfoPanel`을 사용한다. 그러나 전달하는 action callback과 read/refresh owner가 다르다.

| 역할 | embedded Explorer detail pane | `WordDetailScreen` route |
| --- | --- | --- |
| 표시 | split-view read 결과 표시 | initial payload를 먼저 표시한 뒤 detail 전용 reread 결과 표시 |
| read context | `getWordDetailLikeDisplayItemByIdForSplitView` | `getWordDetailLikeDisplayItemByIdForDetailScreen` |
| edit | 있음, `getWordEditSeedForExplorerEdit` 사용 | 있음, `getWordEditSeedForDetailEdit` 사용 |
| edit 후 refresh | Explorer가 `_refreshSelectedWord(...)` 실행 | route 내부 `_refreshDetailScreenDisplayItem()` 실행 |
| full-detail 열기 | 있음, `_openSelectedWordDetail()` | 해당 없음 |
| delete | 없음 | 있음, 관계 수 확인 후 `DeleteWordCommand` 실행 |
| graph 진입 | 없음 | 있음, 존재 확인 후 standalone `WordGraphScreen` route push |
| route result 반환 | 없음 | delete 성공 시 caller에 `true` 반환 |
| center/selection/history 복구 | Explorer가 소유 | 직접 소유하지 않고 delete result를 caller에 전달 |

embedded pane에서 `WordInfoPanel`에 전달하는 action은 `onEdit`와 `onOpenDetail`이다. `onDelete`와 `onShowGraph`는 전달하지 않는다.

`WordDetailScreen`에서 `WordInfoPanel`에 전달하는 action은 `onEdit`, `onShowGraph`, `onDelete`다. full-detail route 자체이므로 `onOpenDetail`은 전달하지 않는다.

## 5. `WordDetailScreen` 역할 감사

### 5.1 initial payload와 detail 전용 reread

`WordDetailScreen`은 생성자에서 `wordId`와 `initialDisplayItem`을 필수로 받는다.

`initState()`에서 다음 순서로 초기화한다.

1. `wordId`를 trim해 `_wordId`에 저장한다.
2. `initialDisplayItem`을 `_displayItem`에 저장해 즉시 표시 가능한 상태를 만든다.
3. `_refreshDetailScreenDisplayItem()`을 비동기로 실행한다.

`_refreshDetailScreenDisplayItem()`은 `getWordDetailLikeDisplayItemByIdForDetailScreen(_wordId)` detail 전용 read context를 사용한다. reread 실패 또는 null 결과는 초기 표시를 유지하도록 조용히 무시한다. reload token으로 오래된 비동기 응답이 최신 표시를 덮지 않게 한다.

### 5.2 edit

`_openEdit()`은 `getWordEditSeedForDetailEdit(_wordId)`를 사용해 `WordEditScreen.fromSeed(...)`를 연다.

edit route가 `WordEditSaveResult`를 반환하면 `WordDetailScreen` 내부에서 `_refreshDetailScreenDisplayItem()`을 다시 실행한다. 이 refresh는 현재 detail route의 표시를 갱신한다. 이후 full-detail route가 닫히면 Explorer caller는 별도로 split-view refresh를 수행한다.

### 5.3 delete

`_confirmDelete()`는 다음 책임을 가진다.

1. `countRelationsForWord(_wordId)`로 연결 관계 수를 확인한다.
2. 관계 수를 포함한 삭제 확인 dialog를 표시한다.
3. 승인 시 `DeleteWordCommand(wordId: _wordId)`를 `WordWriteService`로 실행한다.
4. `WordGraphDataCache.clear()`를 실행한다.
5. delete 성공을 `Navigator.pop(context, true)`로 caller에 반환한다.

caller가 받는 delete 정보는 현재 `true` 한 가지다. 삭제된 word id, 이전 center 여부, 대체 center 같은 추가 정보는 route result에 포함되지 않는다. Explorer는 route 진입 전에 저장한 `selectedWordId`와 `wasCenterWord`를 사용해 복구를 판단한다.

### 5.4 graph 진입

`_openGraph()`은 `wordExistsForGraphNavigation(_wordId)`로 center 단어 존재 여부를 확인한 뒤 `WordGraphScreen(centerWordId: _wordId)` route를 push한다.

이 route에는 Explorer selection/center callback이 전달되지 않는다. 따라서 detail route에서 연 graph는 embedded graph가 아니라 standalone graph 책임을 가진다.

## 6. delete 후 Explorer 영향

### 6.1 선택 단어가 center가 아닌 경우

`_handleDeletedSelectedWord(wasCenterWord: false)`는 `_clearSelectedWordPanel(refreshGraph: true)`를 실행한다.

- center word id와 center 표시 seed는 유지한다.
- selection과 selected display item을 비운다.
- detail loading/error/unavailable 상태를 초기화한다.
- graph revision을 증가시켜 graph를 갱신한다.
- 현재 history entry를 같은 center와 `selectedWordId: null`로 replace한다.
- large-screen Home passive Strong callback에는 빈 selection을 알린다.

### 6.2 선택 단어가 center인 경우

`_handleDeletedSelectedWord(wasCenterWord: true)`는 현재 Explorer가 삭제된 center를 계속 소유하지 않도록 다음 순서로 복구한다.

1. 이전 history entry가 실제로 사용 가능한지 확인한다.
2. 사용 가능하면 history back 후 해당 entry를 적용한다.
3. 이전 entry가 없으면 다음 history entry의 사용 가능 여부를 확인한다.
4. 사용 가능하면 history forward 후 해당 entry를 적용한다.
5. 양쪽 모두 사용할 수 없으면 `Navigator.pop(context, true)`로 Explorer host에 delete 결과를 전달한다.

history entry 적용 시 center는 snapshot의 center로 바뀌고 selection은 비워진다. 이 동작은 기존 Explorer history와 center navigation 정책이며 Phase 20-K에서 변경하지 않는다.

## 7. `WordGraphScreen` standalone과 embedded 책임 차이

embedded Explorer는 child `WordGraphScreen`에 다음 연결을 전달한다.

- `selectedWordId`
- Explorer history action
- `onSelectWordId`
- `onClearSelection`
- `onChangeCenterWordId`

따라서 embedded graph의 node interaction은 Explorer가 소유하는 selection과 center/history 흐름으로 전달된다.

`WordDetailScreen._openGraph()`이 여는 `WordGraphScreen`에는 위 callback이 없다. callback 없는 standalone graph는 다음 자체 route 책임을 유지한다.

- 이미 선택된 연결 node 재탭 시 새 `WordGraphScreen` route push
- 단어 생성 후 관계를 만들지 않은 경우 새 center의 `WordGraphScreen`으로 push replacement

detail → graph route를 large-screen workspace redirect로 바꾸려면 small-screen standalone graph 흐름과 callback 없는 standalone graph 내부 navigation을 별도로 보존하거나 대체해야 한다.

## 8. small-screen과 large-screen 공유 및 차이

small-screen detail route와 large-screen embedded full-detail route는 같은 `WordDetailScreen` class와 동일한 detail 내부 read/edit/delete/graph 구현을 공유한다.

| 구분 | small-screen `HomeScreen` detail route | large-screen embedded Explorer full-detail route |
| --- | --- | --- |
| caller | `HomeScreen` | `WordExplorerScreen` |
| route 진입 전 표시 read | detail screen context로 initial item read | 현재 split-view display item 사용 |
| route 화면 | 같은 `WordDetailScreen` | 같은 `WordDetailScreen` |
| delete result 소비 | result 의미를 직접 분기하지 않고 route 복귀 후 `_refreshWords()` | `true`를 분기해 center/selection/history 복구 |
| 일반 복귀 refresh | Home 목록 future refresh | 선택 단어 split-view reread, 필요 시 center/graph/history 갱신 |
| embedded pane 존재 | 없음 | route 아래에 Explorer graph/detail pane 유지 |

small-screen에는 detail을 대체할 embedded pane이 없다. large-screen full-detail route만 제거하는 경우에도 같은 `WordDetailScreen`이 제공하던 delete와 graph 역할의 대체 위치, route result와 Explorer refresh 연결을 먼저 정의해야 한다.

## 9. full-detail route 유지 이유

현재 full-detail action과 route를 유지해야 하는 이유는 다음과 같다.

1. embedded pane에는 delete action이 없다.
2. embedded pane에는 graph route 진입 action이 없다.
3. `WordDetailScreen`은 detail 전용 reread와 edit refresh를 소유한다.
4. delete 성공 `true` result가 Explorer의 center/selection/history 복구를 시작한다.
5. 일반 route 복귀가 Explorer의 split-view와 graph refresh 기회로 사용된다.
6. small-screen과 large-screen이 같은 detail route 구현을 공유한다.
7. detail에서 여는 standalone graph는 embedded graph와 다른 navigation 책임을 가진다.

따라서 action 하나만 제거하면 기능 표시가 단순해지는 것이 아니라 delete, graph, result, refresh, 복구 경계가 끊어진다.

## 10. 제거 또는 통합 전 선행 설계 조건

full-detail action 제거 또는 detail route 통합을 검토하려면 최소한 다음 조건을 먼저 설계하고 승인해야 한다.

1. embedded pane에서 edit/delete/graph 중 어떤 action을 제공할지 정의한다.
2. delete 확인, relation count 안내, write 실행, cache invalidation owner를 정의한다.
3. `bool?` delete result를 대체할 typed 상태 반환 또는 owner callback contract를 정의한다.
4. center 삭제 시 이전/다음 history 복구와 host pop을 대체하는 UX를 정의한다.
5. 비중심 삭제 시 selection 해제, graph refresh, 현재 history entry 교체를 보존한다.
6. edit 후 detail display, center display seed, graph refresh owner를 정의한다.
7. small-screen `HomeScreen → WordDetailScreen` route를 유지할지 form factor별로 분리한다.
8. large-screen detail → graph를 workspace center 이동으로 바꿀지 standalone graph route로 유지할지 정의한다.
9. standalone graph의 callback 없는 내부 navigation과 create 후 replacement 정책을 보존하거나 대체한다.
10. `ValueKey(_largeScreenExplorerWordId)` retarget과 Explorer owner/history continuity 변경 여부를 별도 설계한다.
11. production behavior guard와 UI 검증 시나리오를 변경 설계에 맞게 승인받는다.

## 11. Phase 20-K 금지 및 유지 범위

Phase 20-K에서는 다음을 수행하지 않는다.

- embedded Explorer full-detail route 제거
- `WordDetailScreen` 역할 이동
- delete 흐름 변경
- detail → `WordGraphScreen` route 변경
- embedded Explorer refresh 구조 변경
- small-screen detail 또는 graph route 변경
- `WordExplorerScreen` 변경
- `ValueKey(_largeScreenExplorerWordId)` retarget 구조 변경
- history, selection, center navigation 정책 변경
- DB/API/repository 변경
- DTO/model/public API 추가 또는 변경
- production Dart 코드 변경
- test guard 변경
- route 통합 또는 standalone/active route 제거
- `docs/logs/FEATURE_STATUS.md` 변경

## 12. 명령어 기반 검증 기준

Phase 20-K 문서 반영 후 다음 명령으로 docs/audit-only 범위를 확인한다.

```text
git status --short --branch
git branch --show-current
git rev-parse main
git rev-parse origin/main
git log -1 --oneline
git diff --stat
git diff --check
git diff --name-only
rg "_openSelectedWordDetail|WordDetailScreen|WordGraphScreen|ValueKey\(_largeScreenExplorerWordId\)" lib test docs
```

완료 조건은 변경 파일이 승인된 문서 3개에 한정되고 production Dart 코드, route, test guard, DB/API/repository, DTO/model/public API 변경이 없는 것이다.

전체 `flutter test`와 `flutter analyze`는 docs/audit-only인 Phase 20-K의 필수 완료 조건으로 삼지 않는다. `flutter analyze`를 실행할 경우 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart` 오류는 이번 Phase 범위 밖 기술부채로 구분한다.

## 13. 클라이언트 UI 확인 체크리스트

Phase 20-K는 UI를 변경하지 않는 docs/audit-only 단계이므로 Codex는 UI 테스트를 수행하지 않는다. 아래 절차는 클라이언트가 필요 시 현재 역할 분류를 확인하기 위한 체크리스트다.

| 테스트 목적 | 시작 화면 | 조작 순서와 테스트 데이터 | 기대되는 화면 변화 | 실패 시 확인할 증상 | 완료 판단 기준 |
| --- | --- | --- | --- | --- | --- |
| active full-detail route 확인 | Windows Desktop `HomeScreen`, 창 너비 900px 이상, embedded Explorer에서 `H2` 단어 선택 | 우측 detail pane에서 `상세 화면에서 열기`를 클릭한다. | 같은 단어의 `WordDetailScreen` route가 열리고 편집, 그래프 보기, 삭제 action이 표시된다. | route 미진입, delete 또는 graph action 부재 | embedded full-detail action이 active route임을 확인함 |
| full-detail edit 복귀 refresh 확인 | large-screen `H2` full-detail route | 식별 가능한 비고를 `Phase20K 편집 확인`으로 수정하고 Explorer로 복귀한다. | Explorer detail pane에 수정 내용이 반영되고 선택 상태가 유지된다. | 이전 표시 유지, selection 소실, 다른 단어 표시 | route 복귀 후 split-view refresh 역할을 확인함 |
| 비중심 선택 삭제 복귀 확인 | large-screen Explorer에서 center와 다른 식별 가능한 연결 단어 선택 | full-detail route에서 선택 단어를 삭제하고 확인한다. | 기존 center는 유지되고 selection/detail pane은 비워지며 graph가 갱신된다. | 삭제된 선택 유지, center 변경, graph에 삭제 단어 잔존 | 비중심 delete 복구 역할을 확인함 |
| center 삭제 복귀 확인 | 테스트용으로 삭제 가능한 단어를 center로 둔 large-screen Explorer | full-detail route에서 center 단어를 삭제한다. | 유효한 이전 또는 다음 history가 있으면 해당 center로 이동하고 selection은 비워진다. 양쪽 모두 없으면 Explorer host가 닫힌다. | 삭제된 center 유지, 사용할 수 없는 history로 이동 | center delete history 복구 역할을 확인함 |
| detail → standalone graph 확인 | large-screen 또는 small-screen `WordDetailScreen`에서 `H2` 표시 | `그래프 보기`를 클릭한다. | `H2` 중심의 standalone `WordGraphScreen` route가 열린다. | embedded Explorer center만 변경, graph route 미진입 | detail route의 standalone graph 역할을 확인함 |
| small-screen 공유 detail 확인 | 창 너비 900px 미만 `HomeScreen` | `H2`를 검색하고 식별 가능한 후보 본문을 클릭한다. | embedded Explorer 없이 같은 `WordDetailScreen` route가 열리고 편집, 그래프 보기, 삭제 action이 표시된다. | embedded Explorer 표시, detail route 미진입 | small-screen과 large-screen full-detail이 같은 detail 구현을 공유함 |
