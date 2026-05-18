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
