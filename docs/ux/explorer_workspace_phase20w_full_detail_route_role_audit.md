# ExplorerWorkspace Phase 20-W full-detail route 역할 감사

## 문서 역할

이 문서는 Phase 20-W의 Explorer full-detail route 잔여 역할 및 action ownership 감사 판단을 기록하는 `reference/context`, `migration/history`, `changelog/status` 문서다.

현재 active authority는 `docs/ux/explorer_workspace_unification.md`의 Phase 20-W active boundary다.

## 감사 목적

Phase 20-W는 Phase 20-N/O/Q/V 이후 large-screen embedded Explorer가 여는 full-detail `WordDetailScreen` route의 잔여 역할과 action ownership을 정리하는 docs-only 감사 단계다.

이번 감사는 production 구현, source guard 추가, UX 문구 변경, DB 또는 repository 변경을 수행하지 않고 현재 경계를 공식 문서로 고정한다.

## embedded detail pane 역할

Explorer embedded detail pane은 split-view 안에서 선택 단어의 상세 요약과 제한된 action을 제공하는 lightweight detail/action surface다.

제공 action:

- `편집`
- `상세 작업 화면 열기`

제공하지 않는 action:

- `삭제`
- `그래프 보기`

따라서 embedded detail pane은 모든 상세 작업을 직접 소유하는 화면이 아니다. 삭제와 graph action을 직접 노출하지 않고, 필요한 전체 작업은 full-detail route로 넘긴다.

## full-detail route 역할

진입 경로:

```text
WordExplorerScreen._openSelectedWordDetail()
→ Navigator.push<WordDetailRouteResult>
→ WordDetailScreen(...)
```

Explorer full-detail `WordDetailScreen` route가 제공하는 action:

- `편집`
- `그래프 보기`
- `삭제`

현재 full-detail route의 역할은 단순히 같은 상세 정보를 다시 보여주는 “상세 보기”가 아니라 **상세 작업 화면**이다. Embedded detail pane에 없는 delete action을 제공하고, edit와 graph는 Explorer caller-result 경로로 연결한다.

## action ownership

```text
Action | 현재 실행 owner | Explorer 역할 | 비고
edit   | Explorer _openEditSelectedWord() | full-detail route의 edit request result 해석자 | Home 기본 route는 WordDetailScreen local edit 유지
graph  | Explorer _selectWord(..., changeCenterWord: true) | full-detail route의 graph request result 해석자 | Home 기본 route는 WordDetailScreen standalone graph 유지
delete | WordDetailScreen._confirmDelete() | completed WordDetailDeletedResult 해석 및 복구 owner | Explorer는 delete executor가 아님
```

Edit와 graph는 Explorer가 여는 full-detail route에서 caller-result로 반환된다. Explorer는 해당 result를 해석해 기존 Explorer-owned edit flow와 embedded graph center retarget flow를 수행한다.

Delete는 caller-request mode로 분기하지 않는다. Delete 실행 owner는 계속 `WordDetailScreen._confirmDelete()`이며, Explorer는 completed `WordDetailDeletedResult`를 해석하고 center/non-center 복구를 수행하는 result 해석자다.

## UI 문구와 tooltip 판단

현재 embedded detail pane의 full-detail action 문구는 다음과 같다.

```text
상세 작업 화면 열기
```

Tooltip은 다음과 같다.

```text
삭제·그래프 보기 등 전체 작업용 상세 화면을 엽니다.
```

이 문구와 tooltip은 full-detail route가 단순 상세 보기 중복 진입이 아니라 전체 작업용 상세 화면이라는 역할을 충분히 설명한다. 따라서 Phase 20-W에서는 production UX 문구 개선을 진행하지 않는다.

## source guard 판단

Phase 20-W에서는 source guard 추가가 불필요하다.

사유:

- Phase 20-M guard는 embedded detail pane action이 `편집`과 full-detail 진입으로 제한되는 경계를 보호한다.
- Phase 20-O guard는 Explorer full-detail route의 graph caller-result mode와 Home 기본 route의 standalone graph 유지를 보호한다.
- Phase 20-Q guard는 Explorer full-detail route의 edit caller-result mode와 Home 기본 route의 local edit 유지를 보호한다.
- Phase 20-V guard는 delete owner가 `WordDetailScreen._confirmDelete()`에 남고 Explorer가 delete executor가 아니며 Home 기본 detail route가 유지되는 경계를 보호한다.

이번 감사에서 새 production 위험이나 기존 guard가 보호하지 못하는 미보호 경계는 확인되지 않았다.

## 후속 Phase로 미룰 항목

다음 항목은 Phase 20-W에서 구현하거나 확정하지 않는다.

- full-detail route 제거
- delete owner 이동
- common delete executor 설계
- embedded detail pane delete 버튼 추가
- center delete empty-state/history 정리
- production UX 문구 변경
- 실제 DB delete 테스트

위 항목은 현재 action ownership과 route/result 경계를 바꾸거나 실데이터 delete 검증 정책을 요구하므로 별도 Phase와 승인된 작업 유형으로 분리해야 한다.

## 검증/N/A

- UI 테스트: N/A — docs-only 작업이며 UI 클릭 또는 수동 판단을 수행하지 않는다.
- DB/SQL 검증: N/A — DB schema, repository, read/write path 변경이 없다.
- 명령어 기반 앱 테스트: N/A — production/test code 변경이 없다.
- Production/test/dependency 변경: 없음.
- `pubspec.yaml`, `pubspec.lock` 변경: 없음.
- 실데이터 수정/삭제: 없음.
