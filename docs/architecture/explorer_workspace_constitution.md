# ExplorerWorkspace Constitution

> Status: Active ExplorerWorkspace composition authority
>
> 이 문서는 ExplorerWorkspace의 현재 boundary를 짧게 고정하는 constitution이다.
>
> 이 문서는 repository/data authority, Navigator/route authority, canonical selection authority, persistence/history authority 문서가 아니다.
>
> 현재 production owner 유지 원칙과 preview-only exploration 구조를 전제로 한다.

## 1. 목적

ExplorerWorkspace는 preview-only workspace composition coordinator다.

현재 단계에서 ExplorerWorkspace가 할 수 있는 일은 panel composition, layout orchestration, panel visibility, split ratio, preview interaction을 UI composition 관점에서 조율하는 것까지다.

현재 단계에서 ExplorerWorkspace가 하지 않는 일은 repository ownership, Navigator ownership, canonical authority, persistence authority를 가져가는 것이다.

## 2. Ownership Matrix

| 항목 | ExplorerWorkspace 역할 | ownership |
| --- | --- | --- |
| repository access | 직접 소유하지 않음 | repository read/write, data source access authority 없음 |
| canonical selection | 직접 소유하지 않음 | canonical selected/center/detail authority 없음 |
| route stack | 직접 소유하지 않음 | Navigator, route stack, route restore authority 없음 |
| layout orchestration | 조율 가능 | panel 배치와 emphasis composition 조율 |
| panel visibility | 조율 가능 | panel visibility composition 조율 |
| split ratio | 조율 가능 | graph/detail 비율과 preset composition 조율 |
| preview interaction | 제한적 조율 가능 | preview-local ephemeral interaction만 허용, authority 이전 금지 |

## 3. 금지사항

- ExplorerWorkspace는 repository owner가 아니다.
- ExplorerWorkspace는 Navigator 또는 route stack owner가 아니다.
- ExplorerWorkspace는 canonical selection authority가 아니다.
- ExplorerWorkspace는 persistence, history, restore authority가 아니다.

## 4. Coordination 원칙

coordination은 authority가 아니다.

ExplorerWorkspace가 layout, visibility, split ratio, preview-local event를 조율해도 production owner는 기존 production 경로에 남는다. 현재 단계에서 `WordExplorerScreen` production owner 유지 원칙은 변경되지 않는다.

## 5. Projection Lifecycle 원칙

projection lifecycle은 UI composition lifecycle이다.

ExplorerWorkspace가 받는 projection 값은 화면 조합, 표시, preview-local interaction에 필요한 수명만 가진다. 이 lifecycle은 repository/data lifecycle, DB existence validation, canonical persistence, route restore lifecycle이 아니다.
## 6. Phase 5-A preview-only layout orchestration 보강

Phase 5-A에서도 ExplorerWorkspace는 preview-only layout coordinator다. preview-only layout orchestration 보강은 layout coordinator 역할을 더 명확히 검증하는 단계이며 production replacement가 아니다.

이번 보강에서 허용하는 조율 범위는 layout preset 전환, panel visibility orchestration, split ratio orchestration, preview composition layout 조정이다. 이 조율은 preview host 내부 local orchestration state에서만 관리한다.

Phase 5-A의 layout coordination은 semantic id와 canonical item을 바꾸지 않는다. `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`는 명시적 semantic action이 없는 한 유지되며, preset 전환만으로 canonical authority가 이동하지 않는다.

ownership boundary 유지가 전제다. ExplorerWorkspace는 여전히 repository owner가 아니고, Navigator owner가 아니고, canonical authority가 아니고, persistence/history authority가 아니다.

따라서 Phase 5-A의 panel visibility와 split ratio 조율은 production route 교체, `WordExplorerScreen` 제거, route collapse, repository authority 이전, Navigator authority 이전, canonical authority 이전, persistence/history authority 이전의 근거가 될 수 없다.
