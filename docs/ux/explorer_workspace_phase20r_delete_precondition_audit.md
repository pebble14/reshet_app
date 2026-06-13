# ExplorerWorkspace Phase 20-R delete 이동 전 선행 조건 감사

> 문서 분류: `reference/context` 및 docs/audit 기록
>
> 기준 main HEAD: `fca3fbec6f9f98a771d76d5c3baacb4c102dcec1`
>
> 한국어 작업명: delete 이동 전 선행 조건 감사
>
> Phase 20-R은 docs/audit-only 단계다. production Dart 코드, test, DB, route, delete flow, action 노출, repository/domain/database/dependency를 변경하지 않는다. 이 문서의 선행 조건과 후속 재검토 항목은 delete 책임 이동 구현 승인이 아니다.

## 1. 문서 성격과 감사 결론

Phase 20-R은 Phase 20-Q 종료 상태에서 `WordDetailScreen`이 소유한 delete 실행 책임을 large-screen embedded Explorer로 이동할 수 있는지 실제 로컬 production source 기준으로 감사한다.

감사 결론은 다음과 같다.

- Phase 20-R에서는 delete 실행 owner를 이동하지 않는다.
- 현재 delete 실행 owner는 `WordDetailScreen`으로 유지한다.
- 현재 Explorer는 delete 실행 owner가 아니라 delete 후 복구 owner다.
- `HomeScreen`과 small-screen에는 embedded Explorer 기반 대체 delete 경로가 없으므로 기본 `WordDetailScreen` route의 delete를 유지한다.
- embedded detail pane에 delete 버튼을 직접 추가하는 것은 아직 이르며 Phase 20-R 범위가 아니다.
- `WordDetailDeletedResult`는 현행 유지한다. 다만 delete 이동 전 `wordId` 검증 부재와 Explorer host의 별도 `true` 반환 계약을 후속 재검토해야 한다.
- full-detail route 축소 또는 제거는 delete/edit/graph 대체 action과 caller별 복구 정책이 안정된 후에만 재감사할 수 있다.

## 2. 기준 상태와 확인 대상

### 2.1 기준 상태

- Phase 20-Q 공식 종료 상태를 기준으로 한다.
- 기준 main HEAD는 `fca3fbec6f9f98a771d76d5c3baacb4c102dcec1`이다.
- 기준 최신 커밋 메시지는 `feat: Phase 20-Q detail edit action caller result 분기`다.
- Phase 20-Q 이후 embedded full-detail edit action은 caller result로 분기되지만 delete action은 계속 `WordDetailScreen` 내부에서 실행된다.
- Phase 20-R은 현재 transition/hybrid 책임 경계를 감사하며 normalized-only 또는 route 통합 완료 상태를 선언하지 않는다.

### 2.2 확인한 파일

- `lib/ui/word_detail_route_result.dart`
- `lib/ui/word_detail_screen.dart`
- `lib/ui/word_explorer_screen.dart`
- `lib/ui/home_screen.dart`
- `lib/ui/word_info_panel.dart`
- `lib/ui/word_graph_cache.dart`
- `lib/domain/word/word_write_models.dart`
- `lib/domain/word/word_write_service.dart`
- `docs/ux/explorer_workspace_phase20p_detail_route_responsibility_audit.md`
- `docs/ux/explorer_workspace_phase20q_detail_edit_caller_result.md`
- `docs/ux/explorer_workspace_unification.md`
- `docs/logs/CHANGELOG.md`

## 3. 현재 delete 실행 책임

### 3.1 `WordDetailScreen` 실행 흐름

`WordDetailScreen._confirmDelete()`은 현재 delete 실행을 조정하는 owner다.

1. `_repository.countRelationsForWord(_wordId)`로 삭제 대상의 relation count를 조회한다.
2. relation count를 포함한 delete confirm dialog를 표시한다.
3. 사용자가 승인하면 `_isDeleting`을 `true`로 바꾸어 진행 상태를 표시하고 delete 버튼 재실행을 막는다.
4. `DeleteWordCommand(wordId: _wordId)`를 `WordWriteService.execute(...)`에 전달한다.
5. write 성공 후 `WordGraphDataCache.clear()`로 graph cache 전체를 비운다.
6. route local context에서 delete 성공 snackbar를 표시한다.
7. `WordDetailDeletedResult(wordId: _wordId)`를 caller에 반환하며 detail route를 닫는다.
8. write 실패 시 `_isDeleting`을 `false`로 복구하고 route local context에서 delete 실패 snackbar를 표시한다.

따라서 현재 delete 실행 책임은 relation count, confirm dialog, 진행 상태, write 호출, cache invalidation, 성공/실패 feedback과 typed result 반환이 한 route-local 흐름으로 묶여 있다.

### 3.2 Domain/write 경계

`DeleteWordCommand`는 삭제 대상 `wordId`를 포함하는 typed command다. `WordWriteService.execute(...)`는 command를 `DeleteWordCommand`로 해석해 repository의 `deleteWord(...)`를 실행하고 `WordWriteAction.delete` 결과를 반환한다.

Phase 20-R은 이 domain/write 경계나 repository/database 구현을 변경하지 않는다. 후속 owner 이동을 검토하더라도 UI가 repository를 우회하거나 data source에 직접 접근해서는 안 된다.

### 3.3 `WordInfoPanel` action 노출 경계

`WordInfoPanel`은 `onDelete`가 제공될 때만 delete 버튼을 표시한다. `isDeleting`이 `true`이면 delete 버튼을 비활성화하고 진행 표시를 사용한다.

- `WordDetailScreen`은 `onDelete: _confirmDelete`와 `isDeleting: _isDeleting`을 제공한다.
- embedded Explorer detail pane은 `onEdit`와 `onOpenDetail`만 제공한다.
- embedded Explorer detail pane은 현재 `onDelete`를 직접 제공하지 않는다.

Delete 버튼 노출만 추가하면 relation count, confirm, write, cache, feedback, result와 복구 계약이 함께 해결되지 않는다. 따라서 embedded pane delete 버튼 추가는 보류한다.

## 4. 현재 delete 이후 caller 책임

### 4.1 Embedded Explorer full-detail caller

`WordExplorerScreen._openSelectedWordDetail()`은 full-detail `WordDetailScreen` route를 열고 result 타입별로 처리한다.

- `WordDetailDeletedResult`: `_handleDeletedSelectedWord(...)`로 delete 후 복구
- `WordDetailEditRequestedResult`: 기존 `_openEditSelectedWord()` 재사용
- `WordDetailGraphRequestedResult`: `_selectWord(..., changeCenterWord: true)`로 embedded graph center 변경
- 일반/null 복귀: `_refreshSelectedWord(...)`로 selected detail과 필요 시 center/graph 갱신

Delete result는 edit, graph, 일반/null 결과보다 먼저 분기된다.

### 4.2 Non-center 선택 단어 삭제

삭제 대상이 center가 아니면 `_clearSelectedWordPanel(refreshGraph: true)`를 실행한다.

- center는 유지한다.
- selection과 detail을 비운다.
- graph revision을 증가시킨다.
- 현재 history entry의 selected word를 비운 상태로 교체한다.

현재 흐름은 non-center 선택 삭제 후 복구를 결정적으로 수행한다. 다만 delete owner 이동 전에는 이 정책을 source guard 및 재현 가능한 테스트로 고정해야 한다.

### 4.3 Center 단어 삭제

삭제 대상이 center이면 Explorer는 다음 순서로 복구한다.

1. 유효한 이전 history가 있으면 이전 history로 복구한다.
2. 이전 history가 없고 유효한 다음 history가 있으면 다음 history로 복구한다.
3. 유효한 이전/다음 history가 모두 없으면 `Navigator.pop(context, true)`로 Explorer host에 delete 결과를 전달한다.

현재 순서는 명확하지만 delete owner 이동 전 안정성이 충분히 검증되었다고 선언할 수 없다. 이전/다음 history의 삭제 대상 또는 unavailable entry 제외, selection/detail/graph 동기화, host 복귀 계약을 재현 가능한 테스트로 검증해야 한다.

### 4.4 Home 및 small-screen caller

`HomeScreen._openDefaultStrongWordDetail(...)`은 기본 mode의 `WordDetailScreen` route를 연다. 기본 `WordDetailScreen`은 delete 실행 owner를 유지한다.

Home caller는 `Navigator.push<WordDetailRouteResult>`를 사용하지만 `WordDetailDeletedResult`를 별도로 해석하지 않는다. route 복귀 후 결과 종류와 관계없이 `_refreshWords()`를 실행한다.

Small-screen은 embedded Explorer가 없고 기본 detail route가 delete 제공 surface다. 따라서 대체 delete surface와 복구 계약이 승인되기 전에는 small-screen/Home detail route delete를 유지해야 한다.

## 5. `WordDetailDeletedResult` 현행 유지와 후속 재검토

Phase 20-R에서는 `WordDetailDeletedResult`를 변경하거나 대체하지 않고 현행 유지한다.

다만 다음 두 계약은 delete owner 이동 전 반드시 후속 재검토한다.

### 5.1 Delete result의 `wordId` 검증 부재

`WordDetailDeletedResult`는 삭제된 `wordId`를 포함하지만, 현재 `WordExplorerScreen._openSelectedWordDetail()`은 result가 `WordDetailDeletedResult` 타입인지 확인할 뿐 `detailResult.wordId`가 route를 열 때의 `selectedWordId`와 일치하는지 검증하지 않는다.

현재 단일 route 흐름에서는 detail route가 자신의 `_wordId`를 반환하므로 정상 동작한다. 그러나 delete 실행 owner나 result 발생 위치를 이동하면 stale result, 다른 선택 상태 또는 비동기 순서와 결합될 수 있다. 후속 구현 전에는 `wordId`를 검증할지, result에 복구에 필요한 추가 context를 포함할지, result contract를 대체할지 결정해야 한다.

### 5.2 Center 삭제 후 host `true` 반환 계약

Explorer가 center 삭제 후 유효한 이전/다음 history를 찾지 못하면 `WordDetailDeletedResult`를 전달하지 않고 `Navigator.pop(context, true)`로 host에 별도 bool 결과를 반환한다.

이 bool 계약은 detail route의 typed result 계약과 다른 경계다. 후속 구현 전에는 host가 이 값을 어떻게 해석하는지, 삭제된 `wordId`가 필요한지, typed result로 통합할지, form factor별로 다른 결과 계약을 유지할지 결정해야 한다.

두 항목은 Phase 20-R에서 해결하거나 구현하지 않는다. 현행 contract를 유지하면서 후속 재검토 필요성을 기록한다.

## 6. 감사 질문별 판단

### 6.1 Delete 실행 owner를 계속 `WordDetailScreen`으로 둘 것인가

현재는 유지한다. `WordDetailScreen`은 small-screen/Home 기본 detail route의 active delete surface이며, relation count부터 typed result 반환까지 이어지는 실행 흐름을 이미 소유한다. 대체 surface와 caller별 계약이 확정되지 않은 상태에서 owner를 이동하면 large-screen과 small-screen 동작이 갈라질 수 있다.

### 6.2 Explorer가 delete 실행까지 소유하기 위한 선행 조건

다음 조건을 모두 충족하고 별도 구현 승인을 받아야 한다.

- delete action을 노출할 large-screen surface 확정
- relation count 조회와 confirm dialog owner 확정
- `_isDeleting`에 해당하는 중복 실행 방지와 진행 상태 owner 확정
- `DeleteWordCommand` 및 `WordWriteService.execute(...)` 호출 owner 확정
- `WordGraphDataCache.clear()` 실행 owner와 범위 확정
- 성공/실패 snackbar context와 표시 시점 확정
- non-center 및 center 삭제 후 복구 정책의 재현 가능한 검증
- Home/small-screen delete 보존 또는 대체 정책 확정
- `WordDetailDeletedResult` 유지/확장/대체 결정
- 테스트 전용 데이터 생성, 백업, 복구와 clean 확인 정책 확정

현재는 이 조건이 모두 충족되지 않았다.

### 6.3 Relation count와 confirm dialog owner

현재 owner는 `WordDetailScreen`이다. 후속 이동 시에는 delete action을 시작하는 surface와 실행 coordinator 중 어디가 relation count와 confirm dialog를 소유할지 먼저 확정해야 한다. Relation count를 사용자에게 보여 주는 confirm UX와 실제 write 호출이 서로 다른 stale context를 사용하지 않도록 하나의 명시적 실행 경계로 설계해야 한다.

### 6.4 Delete 성공/실패 snackbar owner

현재 성공/실패 snackbar는 `WordDetailScreen` route local context가 소유한다. 후속 이동 시 large-screen Explorer context, small-screen detail route context, Home context 중 어느 위치가 성공과 실패를 표시할지 확정해야 한다.

성공 feedback과 실패 feedback은 동일하게 다룰 수 없다. 실패 시 실행 surface가 유지되어 재시도할 수 있어야 하고, 성공 시 삭제된 detail surface와 복구된 Explorer/Home surface 중 사용자에게 의미 있는 context에서 표시되어야 한다. Phase 20-R은 owner를 확정하지 않고 결정 필요 항목으로 보류한다.

### 6.5 Center와 non-center 복구 정책의 안정성

현재 정책은 source 기준으로 결정적이다. Non-center 삭제는 center 유지와 selection/detail 비우기, center 삭제는 이전 history 우선 후 다음 history, history 부재 시 host 복귀 순서를 사용한다.

그러나 delete 이동을 허용할 만큼 충분히 검증되었다고 선언하지 않는다. `WordDetailDeletedResult.wordId` 검증 부재, unavailable history 제외, host `true` 반환 계약과 복구 후 graph/detail/history 동기화를 후속 guard 및 테스트로 고정해야 한다.

### 6.6 Small-screen/Home detail route delete 유지 여부

유지해야 한다. Small-screen에는 embedded Explorer delete 대체 경로가 없고 Home caller는 typed delete result를 별도 해석하지 않은 채 route 복귀 후 목록을 refresh한다. 대체 UX와 result/refresh 계약 없이 기본 detail route delete를 제거하거나 변경해서는 안 된다.

### 6.7 Embedded detail pane delete 버튼 직접 노출 여부

아직 이르다. 버튼 노출은 delete 실행 owner 이동이나 복구 계약 완료를 의미하지 않는다. Embedded pane delete 버튼 추가는 별도 구현 Phase에서 선행 조건 충족과 승인 후 검토한다.

### 6.8 `WordDetailDeletedResult` 유지 또는 대체 여부

Phase 20-R에서는 현행 유지한다. 후속 구현 전에는 `wordId` 검증, Explorer host bool result, Home의 result 미해석 정책을 함께 검토한 뒤 유지, 확장 또는 대체를 결정해야 한다.

### 6.9 Delete 테스트 데이터 생성, 백업과 복구 정책

Phase 20-R에서는 DB 테스트 데이터를 생성하지 않는다. 후속 delete 구현 Phase의 UI 테스트가 필요하면 다음 정책을 먼저 확정해야 한다.

- 기존 실데이터를 delete 테스트 대상으로 사용하지 않는다.
- 사람이 식별 가능한 Phase 전용 테스트 단어를 기존 write path로 생성한다.
- non-center 삭제, center 삭제와 이전 history 복구, 다음 history 복구, history 부재를 각각 검증할 테스트 구성을 정의한다.
- 관계가 있는 delete 대상이 필요하면 기존 repository/write 경계를 통해 관계를 구성하고 실제 schema를 먼저 확인한다.
- 테스트 전 작업 DB를 repo 외부에 백업하고 원본과 백업의 해시를 기록한다.
- 테스트 완료 후 테스트 데이터 정리 또는 백업 복구를 수행한다.
- Phase 전용 데이터 조회 0건, `PRAGMA integrity_check = ok`, 필요 시 백업과 복원 DB 해시 일치를 확인한다.
- DB 파일과 백업 파일이 git 변경에 노출되지 않았음을 확인한 후에만 커밋을 검토한다.

### 6.10 Full-detail route 축소 또는 제거 순서

Full-detail route 축소 또는 제거는 delete 책임 이동과 동시에 처리하지 않는다. 후속 검토 순서는 다음과 같다.

1. Large-screen embedded action별 owner와 caller result 정책을 확정한다.
2. Delete 실행, feedback, cache invalidation과 복구 계약을 검증한다.
3. Small-screen/Home 기본 detail route의 delete/edit/graph 및 reread 대체 여부를 별도로 확정한다.
4. Form factor별 back navigation과 caller refresh를 검증한다.
5. Full-detail route에 남은 책임이 없거나 승인된 대체 경로가 있음을 확인한 뒤 축소 또는 제거를 재감사한다.

## 7. Delete 이동 전 선행 조건 상태

| 선행 조건 | 현재 상태 | Phase 20-R 판단 |
| --- | --- | --- |
| relation count owner | `WordDetailScreen` | 이동 owner 미확정 |
| confirm dialog owner | `WordDetailScreen` route local | 이동 owner 미확정 |
| 진행 상태와 중복 실행 방지 | `_isDeleting` in `WordDetailScreen` | 대체 상태 owner 미확정 |
| write owner | `WordDetailScreen`이 `WordWriteService` 호출 | 이동 보류 |
| cache invalidation owner | delete 성공 후 `WordDetailScreen` | 이동 owner와 invalidation 범위 미확정 |
| 성공/실패 snackbar owner | `WordDetailScreen` route local | form factor별 feedback owner 미확정 |
| non-center 복구 | Explorer가 selection/detail 비우기 | source 기준 확인, 재현 가능한 검증 필요 |
| center 복구 | 이전 history, 다음 history, host 순서 | source 기준 확인, 재현 가능한 검증 필요 |
| Home/small-screen 보존 | 기본 `WordDetailScreen` route | 반드시 유지 |
| `WordDetailDeletedResult` | 현행 typed result 유지 | `wordId` 검증 부재 후속 재검토 |
| Explorer host 결과 | history 부재 시 `true` | typed contract 여부 후속 재검토 |
| delete 테스트 데이터 정책 | Phase 20-R에서 생성하지 않음 | 후속 구현 전 백업/생성/복구 정책 확정 필요 |

모든 선행 조건이 충족되고 별도 구현 승인이 있기 전에는 delete 실행 owner를 이동하지 않는다.

## 8. Phase 20-R 금지 및 유지 범위

Phase 20-R에서는 다음을 수행하지 않는다.

- production Dart 코드 변경
- `test/` 변경
- DB 파일 또는 테스트 데이터 생성·수정·삭제
- route 또는 delete flow 변경
- `_confirmDelete()` 변경
- `DeleteWordCommand` 사용 위치 변경
- `WordDetailDeletedResult` 변경 또는 대체
- embedded detail pane delete 버튼 추가
- `WordDetailScreen` 제거 또는 축소
- full-detail route 제거
- small-screen/Home detail route 변경
- graph action 또는 Phase 20-Q edit action 동작 변경
- repository/domain/database/dependency 변경
- `pubspec.yaml`, `pubspec.lock` 변경
- UI 테스트 수행 완료 보고

## 9. 명령어 기반 검증 기준

Phase 20-R 문서 반영 후 다음 명령으로 docs/audit-only 범위를 확인한다.

```text
git diff --name-only
git diff --check
git status --short --branch
```

다음 검색으로 필수 감사 항목 반영 여부를 확인한다.

```text
rg -n "Phase 20-R|delete 이동 전|WordDetailScreen|WordDetailDeletedResult|_confirmDelete|DeleteWordCommand|WordGraphDataCache.clear|countRelationsForWord|embedded Explorer|center 단어 삭제|non-center|small-screen|Home detail route" docs/ux/explorer_workspace_phase20r_delete_precondition_audit.md docs/ux/explorer_workspace_unification.md docs/logs/CHANGELOG.md
```

완료 조건은 변경 파일이 승인된 문서 3개에 한정되고 `lib/`, `test/`, `data/`, DB 파일, dependency 파일 변경이 없는 것이다.

## 10. 테스트 원칙과 현재 상태

Phase 20-R은 UI와 production behavior를 변경하지 않는 docs/audit-only 단계다.

- Codex는 UI 테스트를 수행하지 않는다.
- 클라이언트 UI 테스트도 Phase 20-R 완료 조건이 아니다.
- `lib/`, `test/` 변경이 없으므로 `flutter test`와 `flutter analyze`를 실행하지 않는다.
- DB 테스트 데이터를 생성하지 않고 DB 검증 또는 변경을 수행하지 않는다.
- 명령어 기반 문서 범위, 필수 문구와 whitespace 검증만 수행한다.

현재 delete 실행 owner는 `WordDetailScreen`, delete 후 복구 owner는 Explorer로 유지한다. Delete 책임 이동은 모든 선행 조건 충족과 별도 구현 승인 이후에만 검토한다.
