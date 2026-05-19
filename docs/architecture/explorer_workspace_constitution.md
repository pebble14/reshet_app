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
## 7. Phase 5-A-1 route 미연결 preview access boundary 보강

Phase 5-A-1은 route 미연결 preview access boundary 보강 단계다. 이 단계는 별도 실행 엔트리 포인트를 통해 preview를 확인할 수 있게 하지만 production route와 결합하지 않는다.

허용 범위는 별도 실행 엔트리 포인트 추가와 preview-only input 연결까지다. `flutter run -t lib/main_explorer_workspace_preview.dart` 실행은 preview app 루트에서만 동작해야 하며 production `main.dart` 경로를 대체하지 않는다.

이 보강은 production Navigator tree, `HomeScreen`, `WordExplorerScreen`, repository owner, canonical authority, persistence/history authority를 침범하지 않는다. preview access는 production shell 내부 hidden entry나 route push로 구현하지 않는다.

즉 Phase 5-A-1은 preview UI 접근 boundary를 여는 단계일 뿐이며, ownership boundary를 이동시키는 단계가 아니다.
## 8. Phase 5-B layout state policy / preset UX refinement 보강

Phase 5-B에서도 ExplorerWorkspace는 preview-only orchestration coordinator다. layout state policy 보강은 authority 이전이 아니라 preview state semantics를 더 명확히 고정하는 단계다.

이 단계에서 `layoutPreset`은 recommended orchestration snapshot이고, panel visibility state는 current local workspace state다. 두 상태는 같은 의미로 결합하지 않으며, preset 변경만으로 local visibility state를 강제로 재설정하지 않는다.

허용 visibility state는 `graph + detail`, `graph only`, `detail only` 세 가지뿐이다. `graph hidden + detail hidden`은 금지 상태이며, preview host와 layout widget은 최소 하나의 semantic panel visible invariant를 유지해야 한다.

`balanced`는 preview 기본 진입 preset으로 유지한다. 이는 graph와 detail을 함께 읽는 split-view 기본 상태를 가장 보수적으로 표현하기 위한 것이며, `graphFocused` 또는 `detailFocused`를 canonical default처럼 오해하지 않게 하기 위한 보호 장치다.

이번 보강도 production owner를 침범하지 않는다. `WordExplorerScreen`, production route, repository, Navigator, canonical authority, persistence/history authority는 계속 기존 production 경로에 남는다.
