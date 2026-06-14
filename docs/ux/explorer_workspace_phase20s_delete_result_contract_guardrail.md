# ExplorerWorkspace Phase 20-S delete result wordId contract guardrail

## 문서 역할

이 문서는 Phase 20-S 구현과 검증을 기록하는 `migration/history` 및 `changelog/status` 문서다. 현재 active authority는 `docs/ux/explorer_workspace_unification.md`의 Phase 20-S active boundary다.

## 목적

Phase 20-S는 delete 실행 owner 이동 단계가 아니다. `WordExplorerScreen._openSelectedWordDetail()`이 `WordDetailDeletedResult`를 받을 때 result의 `wordId`가 route를 열 당시 선택 단어와 일치하는지 확인하는 최소 result contract guard만 추가한다.

```dart
final deletedWordId = detailResult.wordId.trim();
final expectedDeletedWordId = selectedWordId.trim();
```

두 값이 일치할 때만 기존 `_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)`를 실행한다.

## 변경 후 동작

- `WordDetailDeletedResult.wordId`와 route를 열 당시 캡처한 `selectedWordId`를 각각 `trim()`한 뒤 비교한다.
- 두 값이 일치하면 기존 center/non-center delete 복구 경로를 실행한다.
- mismatch이면 Explorer delete 복구를 실행하지 않는다.
- mismatch fallback은 route를 열 당시 선택 단어를 `_refreshSelectedWord(...)`로 안전하게 다시 읽는 범위로 제한한다.
- mismatch refresh 후 즉시 반환하므로 `_handleDeletedSelectedWord(...)`를 실행하지 않는다.

## 유지되는 책임과 계약

- Delete 실행 owner는 계속 `WordDetailScreen._confirmDelete()`다.
- `DeleteWordCommand` 호출 위치와 `WordGraphDataCache.clear()` owner는 변경하지 않는다.
- `WordDetailDeletedResult` typed result 정의와 `WordDetailScreen`의 반환 위치는 유지한다.
- Embedded detail pane에 delete 버튼을 추가하지 않는다.
- Full-detail route를 축소하거나 제거하지 않는다.
- `HomeScreen`과 small-screen 기본 `WordDetailScreen` route를 유지한다.
- Center 삭제 후 유효한 history가 없을 때 Explorer host에 `Navigator.pop(context, true)`를 실행하는 계약은 제거하지 않고 후속 재검토 항목으로 유지한다.
- Repository, domain, database, dependency, `pubspec.yaml`, `pubspec.lock`은 변경하지 않는다.

## Source guard test

신규 source guard:

```text
test/ui/word_explorer_phase20s_delete_result_contract_guardrail_test.dart
```

검증 항목:

- deleted result branch가 `detailResult.wordId.trim()`을 사용한다.
- route를 열 당시의 `selectedWordId.trim()`와 비교한다.
- mismatch branch가 안전 refresh 후 `_handleDeletedSelectedWord(...)` 호출 전에 반환한다.
- match 경로에서만 기존 `_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)` 호출을 유지한다.
- `WordDetailScreen._confirmDelete()`의 `DeleteWordCommand`, `WordGraphDataCache.clear()`, typed delete result 반환을 유지한다.
- `HomeScreen` 기본 detail route와 Explorer host `true` 반환 계약을 유지한다.
- Phase 20-O/Q 기존 source guard는 새 mismatch refresh가 아니라 분기 마지막의 일반/null 복귀 refresh를 계속 검사하도록 `lastIndexOf(...)` 기준으로 현행화한다.

## 명령어 기반 검증

```text
flutter test test/ui/word_explorer_phase20s_delete_result_contract_guardrail_test.dart
```

실제 결과:

- exit code `0`
- `+5`
- `All tests passed!`

```text
flutter analyze
git diff --check
git status --short --branch
```

실제 결과:

- 전체 `flutter analyze`: exit code `1`, 기존 기준과 같은 `47 issues found`
- 전체 analyze error 13건: 기존 `tool/verify_graph_batch_context.dart`, `tool/verify_graph_center_context.dart`
- Phase 20-S 변경 Dart/test 4개 대상 `flutter analyze`: exit code `0`, `No issues found!`
- Phase 20-S와 Phase 20-N/O/Q 관련 source guard 4개: `+26`, `All tests passed!`
- `git diff --check`: exit code `0`, whitespace 오류 없음

추가 source 검색:

```text
rg -n "WordDetailDeletedResult|detailResult\.wordId|_handleDeletedSelectedWord|Navigator\.pop\(context, true\)|_confirmDelete|DeleteWordCommand|WordGraphDataCache.clear" lib/ui/word_explorer_screen.dart lib/ui/word_detail_screen.dart lib/ui/home_screen.dart
```

## UI 기반 수동 테스트 원칙

Phase 20-S에서는 실제 DB delete UI 테스트와 실데이터 수정·삭제를 수행하지 않는다. Codex는 UI 테스트를 수행했다고 보고하지 않는다.

클라이언트가 선택적으로 수행할 수 있는 delete 없는 smoke 확인:

- 테스트 목적: mismatch guard 추가가 일반 full-detail 복귀와 Explorer 표시를 방해하지 않는지 확인
- 시작 화면: Windows Desktop large-screen `HomeScreen`의 embedded Explorer
- 조작 순서:
  1. 사람이 식별 가능한 기존 단어를 Explorer에 연다.
  2. 오른쪽 detail pane에서 `상세 작업 화면 열기`를 클릭한다.
  3. 편집, 삭제, 그래프 보기를 실행하지 않고 뒤로 이동한다.
- 입력할 테스트 데이터: 없음
- 기대되는 화면 변화: 기존 선택 단어와 center가 유지되고 detail이 정상 표시됨
- 실패 시 확인할 증상: 선택 단어 해제, center 변경, detail 오류, graph 불필요 변경
- 테스트 완료 판단 기준: delete 없이 full-detail route를 열고 닫은 뒤 기존 Explorer 상태가 유지됨

## 현재 상태

Phase 20-S는 `WordDetailDeletedResult.wordId` mismatch가 잘못된 Explorer delete 복구를 실행하지 않도록 최소 guard를 추가했다. 관련 Phase 20-O/Q source guard도 새 mismatch refresh와 기존 일반/null 복귀 refresh를 구분하도록 현행화했다. Delete owner 이동, 실제 DB delete UI 테스트, 실데이터 수정·삭제는 수행하지 않았다.
