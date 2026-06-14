# ExplorerWorkspace Phase 20-T center delete 후 Explorer host `true` 반환 계약 감사

> 문서 분류: `reference/context` 및 docs/audit 기록
>
> 기준 main HEAD: `6568e562ca1224fa45d52a059a31a296884c5356`
>
> 기준 최신 커밋: `fix: Phase 20-S delete result wordId guard 추가`
>
> Phase 20-T는 docs/audit-only 단계다. production Dart 코드, test, DB, dependency, `pubspec.yaml`, `pubspec.lock`을 변경하지 않는다.

## 1. 감사 목적과 결론

Phase 20-T는 center 단어 삭제 후 Explorer 내부에서 복구할 유효한 history가 없을 때 실행되는 `Navigator.pop(context, true)`의 실제 host와 수신·해석 경로를 로컬 source 기준으로 감사한다.

감사 결론은 다음과 같다.

- `WordExplorerScreen._handleDeletedSelectedWord(...)`의 center delete 복구 순서는 이전 history, 다음 history, bool pop fallback 순서가 맞다.
- 현재 production에서 `WordExplorerScreen`을 생성하는 위치는 `HomeScreen` large-screen branch의 embedded child 한 곳이다.
- 현재 production source에는 `WordExplorerScreen`을 `Navigator.push`로 여는 caller가 없다.
- `WordExplorerScreen`이 host에 전달할 수 있는 callback은 `onSelectedStrongWordChanged`뿐이며, delete 결과 또는 `true` 결과를 전달하는 callback은 없다.
- `HomeScreen`에는 embedded Explorer의 `true` 결과를 수신하거나 refresh trigger로 해석하는 경로가 없다.
- 따라서 `Navigator.pop(context, true)`는 현재 embedded host 구조에서 수신·해석 경로가 없는 legacy fallback 위험이다. Explorer pane만 닫는 명시적 계약이 아니며, nearest/enclosing Navigator route를 pop할 가능성이 있다.
- 이 위험은 center 삭제 후 유효한 이전/다음 history가 모두 없는 제한된 조건에서 발생하지만, 발생 시 enclosing route navigation에 영향을 줄 수 있으므로 source 기준 위험도를 중간~높음으로 판단한다.
- Phase 20-T에서는 bool pop을 제거하거나 typed result로 통합하지 않는다. 현재 구조와 위험을 기록하고 후속 설계·구현 판단으로 분리한다.

## 2. 확인한 파일

다음 파일을 실제 로컬 source 기준으로 확인했다.

- `lib/ui/word_explorer_screen.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_detail_route_result.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/ui/word_info_panel.dart`
- `docs/ux/explorer_workspace_phase20r_delete_precondition_audit.md`
- `docs/ux/explorer_workspace_phase20s_delete_result_contract_guardrail.md`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`
- `test/ui/word_explorer_phase20s_delete_result_contract_guardrail_test.dart`

추가로 repository 전체 production source의 `Navigator.pop(context, true)` 위치와 `WordExplorerScreen` 생성·push 위치를 검색했다.

## 3. Center delete 후 실제 복구 순서

`WordExplorerScreen._openSelectedWordDetail()`은 `WordDetailDeletedResult`를 받으면 result의 `wordId`와 route를 열 당시의 `selectedWordId`를 검증한다. 두 값이 일치할 때만 `_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)`를 실행한다.

`_handleDeletedSelectedWord(...)`의 실제 순서는 다음과 같다.

1. 삭제 대상이 center가 아니면 `_clearSelectedWordPanel(refreshGraph: true)`를 실행하고 반환한다.
2. 삭제 대상이 center이면 `_history.previousEntry`를 확인한다.
3. previous entry가 유효하면 `_history.goBack()`을 실행하고 반환된 entry를 `_applyHistoryEntry(...)`로 적용한 뒤 반환한다.
4. previous 복구가 완료되지 않으면 `_history.nextEntry`를 확인한다.
5. next entry가 유효하면 `_history.goForward()`를 실행하고 반환된 entry를 `_applyHistoryEntry(...)`로 적용한 뒤 반환한다.
6. 이전/다음 history 복구가 모두 완료되지 않고 widget이 mounted 상태이면 `Navigator.pop(context, true)`를 실행한다.

따라서 bool pop은 previous/next history fallback 이후 마지막 위치에 존재한다.

## 4. `Navigator.pop(context, true)` 실제 위치와 의미 구분

Production `lib` source에는 `Navigator.pop(context, true)`가 7곳 존재한다.

| 파일과 위치 | 의미 |
| --- | --- |
| `lib/ui/word_explorer_screen.dart:746` | center delete 후 유효한 이전/다음 history가 없을 때 실행되는 Explorer fallback |
| `lib/ui/word_detail_screen.dart:154` | 단어 삭제 confirm dialog의 승인 결과 |
| `lib/ui/home_screen.dart:524` | DB 초기화 confirm dialog의 승인 결과 |
| `lib/ui/word_graph_screen.dart:4594` | 관계 삭제 confirm dialog의 승인 결과 |
| `lib/ui/word_graph_screen.dart:4928` | 관계 추가 흐름의 계속 추가 dialog 결과 |
| `lib/ui/word_edit_screen.dart:493` | 편집 흐름의 계속 저장 dialog 결과 |
| `lib/ui/word_expression_set.dart:420` | 표현 세트의 제외하고 저장 dialog 결과 |

Explorer fallback 한 곳을 제외한 나머지 6곳은 `showDialog<bool>` 등 dialog caller가 즉시 bool 결과를 받는 local confirm/choice 계약이다. Explorer fallback은 dialog 결과가 아니며, 현재 production host가 결과를 받는 명시적 caller 계약이 확인되지 않는다는 점에서 의미가 다르다.

문서와 test에도 해당 source 문자열을 참조하는 기록이 있다. Phase 20-S source guard는 Explorer fallback의 존재를 검사하고, Phase 20-N guard는 detail confirm dialog 내부 bool 결과 수를 검사한다.

## 5. Explorer host와 현재 embedded 구조

Production source에서 `WordExplorerScreen(` 생성 위치는 `HomeScreen` large-screen branch 한 곳이다.

```dart
WordExplorerScreen(
  key: ValueKey(_largeScreenExplorerWordId),
  initialWordId: _largeScreenExplorerWordId,
  onSelectedStrongWordChanged: _handleExplorerSelectedStrongWordChanged,
)
```

현재 production source에는 `Navigator.push`로 `WordExplorerScreen`을 여는 경로가 없다. Phase 20-J에서 호출자 없는 dormant standalone Explorer helper가 제거되었고, large-screen primary flow는 embedded child mount로 유지된다.

`onSelectedStrongWordChanged`는 선택 단어와 표시 Strong 번호를 `HomeScreen`에 전달해 passive Strong Rail feedback과 rail-local jump를 갱신한다. 이 callback은 delete 결과 callback이 아니며 bool `true`를 전달하거나 해석하지 않는다.

`HomeScreen`에는 다음 경로가 없다.

- embedded Explorer delete 결과 callback
- Explorer host result callback
- `true`를 refresh trigger로 해석하는 caller
- embedded `WordExplorerScreen`의 pop 결과를 await하는 route caller

따라서 현재 source 기준 Explorer host는 `true` 결과를 명시적으로 받는 구조가 아니다. Embedded child의 context에서 호출한 `Navigator.pop(context, true)`는 Explorer pane 자체를 닫는 API가 아니며 nearest/enclosing Navigator route를 pop할 가능성이 있다.

이 문서는 해당 bool pop을 유지 가능한 안정 계약 또는 정상적인 embedded host result 계약으로 단정하지 않는다. 현재 embedded host 구조와 충돌 가능성이 있는 legacy fallback 위험으로 분류한다.

## 6. Typed detail result와 bool Explorer fallback 차이

`WordDetailRouteResult`는 detail route와 caller 사이의 typed contract다.

- `WordDetailDeletedResult`는 삭제된 `wordId`를 포함한다.
- `WordDetailEditRequestedResult`는 편집 요청 대상 `wordId`를 포함한다.
- `WordDetailGraphRequestedResult`는 graph 요청 대상 `wordId`를 포함한다.

`WordExplorerScreen._openSelectedWordDetail()`은 `Navigator.push<WordDetailRouteResult>` 결과를 타입별로 분기한다. 특히 `WordDetailDeletedResult.wordId`는 Phase 20-S guard에 따라 route를 열 당시 선택 단어와 일치할 때만 delete 복구를 실행한다.

반면 center delete history 부재 시의 `Navigator.pop(context, true)`는 다음 차이가 있다.

- typed result가 아니라 bool이다.
- 삭제된 `wordId`를 포함하지 않는다.
- 현재 production embedded host에 결과를 await하거나 해석하는 caller가 없다.
- detail route result 경계가 아니라 Explorer widget context에서 enclosing Navigator에 전달된다.

따라서 두 결과는 현재 동일한 result contract가 아니다. Typed result 전환 또는 통합은 후속 Phase 후보이며 Phase 20-T 구현 범위가 아니다.

## 7. `HomeScreen._openDefaultStrongWordDetail(...)` 결과 처리

`HomeScreen._openDefaultStrongWordDetail(...)`은 `Navigator.push<WordDetailRouteResult>`로 기본 `WordDetailScreen` route를 연다. 그러나 반환값을 변수에 저장하거나 타입별로 분기하지 않는다.

Route가 복귀하고 `HomeScreen`이 mounted 상태이면 결과 종류와 관계없이 `_refreshWords()`를 실행한다. 따라서 이 경로는 typed push를 사용하지만 `WordDetailDeletedResult`를 별도로 해석하지 않는다.

이 Home detail route 경계는 embedded Explorer bool pop의 host 경계와 별개다.

## 8. Phase 20-S source guard 범위와 한계

`test/ui/word_explorer_phase20s_delete_result_contract_guardrail_test.dart`는 다음을 검사한다.

- deleted result `wordId`와 route 선택 단어 `wordId` 비교
- mismatch refresh 후 delete 복구 전 반환
- match 경로에서만 `_handleDeletedSelectedWord(...)` 실행
- detail delete owner와 typed deleted result 유지
- Home 기본 detail route 유지
- `_handleDeletedSelectedWord(...)` source 내부 `Navigator.pop(context, true)` 존재 유지

현재 guard는 다음을 검사하지 않는다.

- bool pop이 previous/next history fallback 이후 마지막에만 존재하는지
- production `WordExplorerScreen`이 embedded child로만 mount되는지
- `HomeScreen`에 bool 결과 수신·해석 경로가 있는지
- bool pop이 enclosing Navigator route에 미치는 영향

Phase 20-T 1차 작업에서는 새 source guard를 추가하지 않는다. 기존 Phase 20-S guard가 bool pop 존재를 이미 고정하고 있는 상태에서 현재 host 해석 부재까지 추가로 고정하면 알려진 위험 구조를 장기 계약처럼 중복 고착할 수 있다.

후속 설계에서 기대 계약이 승인된 뒤에는 다음을 감시하는 source guard 필요성을 재검토할 수 있다.

- 위험한 legacy fallback 위치와 host 해석 부재가 의도치 않게 확대되지 않는지
- 승인된 대체 계약이 있으면 embedded host와 result 처리 경계가 일치하는지
- delete owner, `WordDetailDeletedResult`, `_confirmDelete()`, `DeleteWordCommand`, `WordGraphDataCache.clear()`가 별도 승인 없이 함께 이동하지 않는지

## 9. 현재 위험도 판단

Source 기준 위험도는 중간~높음이다.

- 발생 조건은 center 단어 삭제 후 유효한 previous/next history가 모두 없는 경우로 제한된다.
- 실제 실행되면 embedded Explorer 자체가 아니라 nearest/enclosing Navigator route가 pop될 가능성이 있다.
- `HomeScreen`에는 `true` 결과를 받아 refresh하거나 Explorer target을 복구하는 경로가 없다.
- bool 결과에는 삭제된 `wordId`와 복구 context가 없다.
- 실제 DB delete UI 테스트를 수행하지 않았으므로 runtime 결과를 검증 완료로 선언하지 않는다.

현재 transition/hybrid 상태를 유지하며, normalized-only 또는 typed result 통합 완료 상태로 선언하지 않는다.

## 10. Phase 20-T에서 구현하지 않는 항목

Phase 20-T에서는 다음을 수행하지 않는다.

- `Navigator.pop(context, true)` 제거
- `WordDetailDeletedResult` 구조 변경
- typed route result 통합 구현
- delete 실행 owner 이동
- `WordDetailScreen._confirmDelete()` 변경
- `DeleteWordCommand` 호출 위치 변경
- `WordGraphDataCache.clear()` owner 변경
- embedded detail pane delete 버튼 추가
- full-detail route 축소 또는 제거
- Home/small-screen 기본 detail route 변경
- production Dart 및 test 변경
- 실제 DB delete UI 테스트와 실데이터 수정·삭제
- repository/domain/database/dependency 변경
- `pubspec.yaml`, `pubspec.lock` 변경

## 11. 후속 Phase 후보

후속 작업은 delete owner 이동과 분리해 다음 순서로 검토할 수 있다.

1. Embedded Explorer의 center delete history 부재 시 기대 UX와 host 책임을 별도 설계한다.
2. bool pop 유지, host callback 추가, typed result 전환 또는 local 복구 중 어떤 계약을 사용할지 승인받는다.
3. 승인된 계약을 기준으로 source guard와 재현 가능한 비파괴 검증 전략을 정의한다.
4. Delete owner 이동은 result/host 계약과 분리된 별도 Phase에서 선행 조건을 다시 확인한다.

위 항목은 후속 후보이며 구현 승인 또는 정책 확정이 아니다.

## 12. 명령어 기반 검증

감사에 사용한 필수 검색:

```text
rg -n "Navigator\.pop\(context, true\)|_handleDeletedSelectedWord|WordExplorerScreen\(|Navigator\.push.*WordExplorerScreen|WordDetailDeletedResult|Navigator\.push<WordDetailRouteResult>|_openDefaultStrongWordDetail|_largeScreenExplorerWordId" lib test docs
```

핵심 결과:

- `_handleDeletedSelectedWord(...)`와 Explorer bool pop은 `lib/ui/word_explorer_screen.dart`에서 확인했다.
- Production `WordExplorerScreen(` 생성은 `lib/ui/home_screen.dart` large-screen embedded branch 한 곳에서 확인했다.
- Production source에서 `Navigator.push.*WordExplorerScreen` 결과는 없었다.
- `WordDetailDeletedResult` typed 정의와 detail/Explorer caller 처리를 확인했다.
- `HomeScreen._openDefaultStrongWordDetail(...)`은 typed push 후 결과 분기 없이 `_refreshWords()`를 실행함을 확인했다.

추가 검색:

```text
rg -n "Navigator\.pop\(context, true\)" lib test docs
rg -n "Navigator\.push<.*WordExplorer|Navigator\.push.*WordExplorer|WordExplorerScreen\(" lib
rg -n "onSelectedStrongWordChanged|on.*Result|on.*Deleted|on.*Delete" lib/ui/word_explorer_screen.dart lib/ui/home_screen.dart
```

문서 편집 전 기준 상태 확인:

```text
git status --short --branch
git diff --check
```

문서 편집 전 실제 결과:

- 현재 브랜치: `docs/explorer-workspace-phase20t-center-delete-host-true-contract-audit`
- 기준 HEAD: `6568e562ca1224fa45d52a059a31a296884c5356`
- 문서 편집 전 working tree clean
- 문서 편집 전 `git diff --check`: exit code `0`

문서 편집 후 검증 명령:

```text
git diff --check
git diff -- docs/ux/explorer_workspace_phase20t_center_delete_host_true_contract_audit.md docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md
git diff --no-index --check -- NUL docs/ux/explorer_workspace_phase20t_center_delete_host_true_contract_audit.md
git status --short --branch
```

문서 편집 후 실제 결과:

- `git diff --check`: exit code `0`, tracked 문서 whitespace 오류 없음
- 신규 untracked 감사 문서는 `git diff --no-index --check -- NUL ...`로 별도 검사했다. 빈 `NUL`과 신규 파일의 차이를 감지해 exit code `1`을 반환했지만 whitespace 오류 진단은 없었고 line ending 변환 경고만 출력되었다.
- 일반 문서 diff에서 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`의 Phase 20-T 추가만 확인했다.
- `git status --short --branch`에서 승인된 문서 3개만 변경 상태로 확인했다.
- Production Dart, test, DB, dependency, `pubspec.yaml`, `pubspec.lock` 변경은 없다.

환경 응답 없음 기록:

```text
flutter test test/ui/word_explorer_phase20s_delete_result_contract_guardrail_test.dart
flutter --version
```

- 기존 Phase 20-S source guard 실행은 120초와 300초 제한에서 출력 없이 timeout되었다.
- `flutter --version`도 30초 제한에서 출력 없이 timeout되었다.
- 위 timeout은 테스트 성공 또는 실패로 해석하지 않는다. 현재 환경에서 Flutter 명령이 응답하지 않은 상태로 기록한다.
- Phase 20-T docs-only 작업의 필수 완료 판단은 `rg`, `git diff --check`, 문서 diff, `git status --short --branch` 결과를 기준으로 한다.

## 13. UI 및 DB 테스트

Phase 20-T에서는 UI 기반 수동 테스트를 수행하지 않았다. 실제 DB delete UI 테스트와 실데이터 수정·삭제도 수행하지 않았다.

Source 감사만으로 runtime delete 동작을 검증 완료했다고 선언하지 않는다.
