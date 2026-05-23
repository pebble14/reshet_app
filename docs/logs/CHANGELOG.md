# CHANGELOG

## 2026-05-23 Phase 8-D hidden visual probe stabilization audit

- Phase 8-D는 구현 단계가 아니라 Phase 8-C hidden visual probe가 Level 1 boundary 안에 머무는지 확인하는 stabilization audit 단계로 기록했다.
- `lib/ui/word_explorer_screen.dart`의 `_debugValidateHiddenVisualProbe(...)`가 `WordExplorerScreen.build(...)` 내부 assert-only 경계에서 호출되며 read-only projection snapshot만 소비한다고 정리했다.
- hidden visual probe는 owner/controller/coordinator authority를 이전하지 않고, Provider / Repository / Navigator / DB / persistence authority migration을 수행하지 않는다고 기록했다.
- production route 노출, `ExplorerWorkspace` shell mount, `main.dart` / `HomeScreen` / Navigator route 변경, production visible UI diff가 없다고 기록했다.
- projection result persistence/history/source-of-truth usage가 없고, source-level boundary test가 존재한다고 기록했다.
- 관련 테스트 `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`, `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart` 결과를 `+11: All tests passed!`로 기록했다.
- `flutter analyze`는 기존 저장소 이슈로 실패하며, 이번 변경 파일인 `docs/ux/explorer_workspace_unification.md`, `docs/logs/CHANGELOG.md`는 analyzer 오류 목록에 포함되지 않는 상태로 구분했다.
- Phase 8-E는 Level 2 승격이 아니라 hidden visual probe output contract planning, source-level hardening, visual candidate structure audit 후보로만 기록했다.

## 2026-05-23 Phase 8-C hidden visual probe 구현

- `lib/ui/word_explorer_screen.dart`의 기존 build-local read-only projection read 및 assert-only consumer 경계 안에 `_debugValidateHiddenVisualProbe(...)` helper를 추가했다.
- hidden visual probe는 `ExplorerWorkspaceState` projection snapshot을 입력으로 받아 graph/detail visual candidate slot과 read-only label 구성 가능성만 검증하며, side effect 없이 assert-only 범위에서만 동작한다.
- `ExplorerWorkspace` shell mount, production route 노출, `HomeScreen` / `main.dart` / Navigator route 변경, production visible UI diff는 추가하지 않았다.
- Provider / Repository / Navigator / DB / persistence authority migration은 수행하지 않았고, projection result를 field, cache, history payload, source of truth로 저장하지 않았다.
- `test/ui/word_explorer_screen_phase8c_hidden_visual_probe_test.dart`를 추가해 hidden visual probe가 read-only / non-owner / non-route / non-shell-mount 경계를 유지하는지 source-level로 검증하도록 했다.
- `docs/ux/explorer_workspace_unification.md`에 `17.44 Phase 8-C hidden visual probe implementation` 섹션을 추가해 Level 1 boundary 유지, 미승인 항목 유지, Phase 8-D 후보 조건을 기록했다.

## 2026-05-23 Phase 8-B visual consumer candidate selection 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.43 Phase 8-B visual consumer candidate selection` 섹션을 추가해 Phase 8-A visual consumer entry boundary 이후 첫 visual consumer 후보군을 문서상으로 비교했다.
- Candidate A `Level 1 hidden visual probe`를 Phase 8-C 첫 구현 후보로 선정하되, Phase 8-B에서는 실제 hidden visual probe를 구현하지 않는다고 기록했다.
- Candidate B `Level 2 production-adjacent visual consumer`는 production 인접성에 따른 runtime/UI diff와 owner boundary 오해 가능성 때문에 보류로 기록했다.
- Candidate C `Level 3 production visible consumer`는 production route 노출과 production UI diff를 동반하므로 Phase 8-B에서 `not approved`로 유지했다.
- runtime/UI integration, `ExplorerWorkspace` shell mount, route collapse, canonical owner migration, Provider / Repository / Navigator / persistence authority migration은 계속 `not approved` 상태로 유지했다.
- `ExplorerWorkspace`가 owner, controller, coordinator가 아니며 owner boundary는 이전되지 않았다고 다시 고정했다.
- 이번 변경은 문서 변경만 포함하며 production UI diff는 없다.

## 2026-05-23 Phase 8-A visual consumer entry boundary 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.42 Phase 8-A visual consumer entry boundary` 섹션을 추가해 Phase 7 read-only projection chain 이후 visual consumer가 projection snapshot을 읽기 전에 필요한 entry boundary를 문서화했다.
- Phase 8은 `ExplorerWorkspace` shell을 production에 mount하는 단계가 아니며, runtime/UI integration과 visual consumer production exposure는 계속 `not approved` 상태라고 명시했다.
- `ExplorerWorkspace` shell mount, route collapse, canonical owner migration, Provider / Repository / Navigator / persistence authority migration은 승인되지 않았고 owner boundary 미이전 상태를 유지한다고 기록했다.
- projection result persistence, projection result history usage, projection result source-of-truth usage는 모두 `not approved`로 고정했다.
- 이번 변경은 문서 변경만 포함하며 production UI diff는 없다.

## 2026-05-23 Phase 7-H projection chain stabilization audit 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.41 Phase 7-H projection chain stabilization audit` 섹션을 추가해 Phase 7-A~7-G projection chain의 closure / stabilization audit 결과를 문서화했다.
- audit 결과 Phase 7 문서 흐름, read-only projection adapter, `WordExplorerScreen` private projection getter, build-local read + debug assert-only consumer, production entry / explorer route 유지, owner boundary 비침범, runtime/UI diff 없음이 서로 일치한다고 기록했다.
- Phase 7은 현재 기준 `closable`로 판단했지만, 이는 runtime/UI 구현 승인, visual consumer 승인, `ExplorerWorkspace` shell mount 승인, feature 브랜치 생성 승인이 아니라고 명시했다.
- visual consumer status와 shell mount status는 계속 `not approved`로 유지하며, 두 결정은 다음 phase unresolved 항목으로 이관했다.
- 대상 전체 `dart analyze`의 기존 `home_screen.dart` warning/info 5건과 sandbox 내부 Flutter test timeout / telemetry 접근 문제는 Phase 7-H 직접 경계와 분리된 검증 환경 이슈로 기록했다.

## 2026-05-23 Phase 7-G projection consumer boundary planning 문서화

- `docs/ux/explorer_workspace_unification.md`에 `17.40 Phase 7-G projection consumer boundary planning 기준`을 추가해, Phase 7-F read-only projection result의 현재 소비 상태와 안전한 consumer 경계 후보 A/B/C/D 비교를 문서화했다.
- 현재 projection boundary는 `WordExplorerScreen` 내부 private getter `_readOnlyWorkspaceProjection`과 build-local read + debug assert에만 머무르며, field/history/source of truth, UI prop, widget tree, route, `Navigator`, repository, persistence로 연결되지 않는다는 점을 기준으로 고정했다.
- 추천 consumer 경계는 후보 B `debug/assert-only consumer`로 기록했지만, 이는 implementation approval이 아니고 feature 브랜치 생성 승인도 아니며 visual consumer 구현 승인이나 `ExplorerWorkspace` shell mount 승인도 아니다.
- 후보 C visual consumer 연결은 production widget tree 변경, runtime/UI diff, preview host의 `_state` / `setState`로 인한 shadow owner 위험 때문에 현 단계에서는 비추천으로 기록했다.
- 후속 feature 브랜치 전환 전에는 visual consumer 필요성에 대한 별도 승인, production mount를 UI diff가 있는 기능 변경으로 취급하는 기준, `ExplorerWorkspace` non-owner 문구와 테스트 설계, route / `Navigator` / Repository / DB / Provider 영향 검토, 명령어 기반 검증 시나리오와 클라이언트 UI 확인 절차 확정, Flutter 테스트 실행 환경 정상화가 선행되어야 한다고 명시했다.

## 2026-05-23 Phase 7-F WordExplorer read-only projection boundary implementation

- `lib/ui/word_explorer_screen.dart`에 private read-only projection boundary `_readOnlyWorkspaceProjection`을 추가하고, current owner state를 `WordExplorerWorkspaceProjectionAdapter.project(...)` 호출로 파생 `ExplorerWorkspaceState` snapshot에만 투영하도록 정리했다.
- projection 입력은 `graphCenterWordId <- _centerWordId`, `selectedWordId <- _selectedWordId`, `detailTargetWordId <- (_selectedWordDisplayItem != null ? normalizedSelectedWordId : null)` 기준으로 유지하되, center/selected/detail 후보가 blank string이면 adapter로 전달하지 않도록 caller-local 방어를 추가했다.
- `layoutPreset`은 `ExplorerWorkspaceLayoutPreset.balanced`, `origin`은 `ExplorerWorkspaceTransitionOrigin.routeAlias`로 projection 호출 인자에만 고정했고, field/history/source of truth/runtime policy state로 확장하지 않았다.
- projection 결과는 `build()` 시작부 local final과 debug assert에서만 참조하며, UI prop, widget tree, route, Navigator, persistence, repository 호출에는 연결하지 않았다.
- `test/ui/word_explorer_screen_phase7f_projection_boundary_test.dart`를 추가해 private projection getter 존재, blank guard, detail payload gating, field/history 비저장, 비시각 경계 유지 여부를 source-level로 검증했다.
- `docs/ux/explorer_workspace_unification.md`에 Phase 7-F 구현 기록을 추가해 current owner 유지, derived snapshot 경계, 금지 확장 미적용 상태를 문서화했다.

## 2026-05-22 Phase 7-E projection adapter integration boundary planning

- Phase 7-E를 adapter 연결 전 경계 조사와 proposal 문서화 단계로 기록했다. 이번 단계는 구현 단계가 아니며 `WordExplorerScreen` 수정 승인, feature 브랜치 생성 승인, runtime/UI 구현 승인으로 간주하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 `17.38 Phase 7-E projection adapter integration boundary planning` 섹션을 추가해 current owner state 조사 결과, build/callback/setState 경계, adapter 연결 후보 A/B/C 비교, 추천 후보 B, forbidden expansion, unresolved / precondition, feature 전환 전 조건을 정리했다.
- current code 기준 projection 입력 출처를 `graphCenterWordId <- _centerWordId`, `selectedWordId <- _selectedWordId`, `detailTargetWordId <- (_selectedWordDisplayItem != null ? _selectedWordId : null)`로 기록했지만, 이는 후속 feature 구현 전 검토 기준이지 구현 승인 사항은 아니다.
- 추천 후보는 `private getter or private method read-only projection`으로 기록했지만, projection result를 field/history/source of truth로 저장하지 않는 derived snapshot 경계로만 취급해야 하며 implementation approval은 아니다.
- implementation status는 `not approved`, feature branch status는 `not approved`로 유지하며, 제안된 후속 feature 브랜치명 `feature/explorer-workspace-phase7f-wordexplorer-projection-boundary` 역시 생성 승인 없이 제안으로만 남긴다.

## 2026-05-22 Phase 7-D read-only projection adapter implementation

- `lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart`를 추가해 `WordExplorerScreen`이 이미 소유한 projection candidate 값을 `ExplorerWorkspaceState`로 변환하는 read-only adapter를 구현했다.
- adapter는 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`을 모두 명시적 입력으로 받으며, 내부에서 mutation, navigation, persistence, fetch, refresh, synchronization을 수행하지 않는다.
- `detailTargetWordId`는 current owner가 제공한 detail target 의미 값을 read-only projection하는 범위로만 다루며, helper 내부에서 `selectedWordId`로 자동 추론하지 않는다.
- source of truth는 계속 `WordExplorerScreen`에 남아 있고, `ExplorerWorkspace`는 runtime owner가 아니라 projection consumer로 유지한다.
- production mount, route collapse, Navigator rewiring, Repository/DB/Provider authority 변경은 수행하지 않았고 runtime/UI diff가 없도록 범위를 제한했다.
- `test/ui/explorer_workspace_phase7d_readonly_projection_adapter_test.dart`를 추가해 explicit projection, non-inference boundary, 금지 import/호출 부재를 source-level로 검증했다.

## 2026-05-22 Phase 7-C Candidate A feature implementation entry plan

- Phase 7-C를 ExplorerWorkspace 후보 A의 feature 구현 진입 계획을 문서로 고정하는 단계로 기록했다. 이번 단계는 implementation이 아니며, feature 브랜치 생성이나 runtime/UI 구현을 승인하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 `17.36 Phase 7-C Candidate A feature implementation entry plan` 섹션을 추가해 후보 A의 목적, 허용 책임, 금지 책임, current contract 기준 projection 범위, forbidden expansion, feature 브랜치 전환 전 조건, 명령어 기반 검증 계획, UI 확인 기준을 정리했다.
- source of truth는 계속 `WordExplorerScreen`에 남아 있어야 하며, `ExplorerWorkspace`는 projection consumer일 뿐 runtime owner가 아니라고 다시 고정했다.
- implementation status는 `not approved`, feature branch status는 `not approved`로 유지했고, recommended next feature branch는 제안으로만 기록했다.

## 2026-05-21 Phase 7-B first implementation unit candidate selection

- Phase 7-B를 ExplorerWorkspace Phase 7의 첫 구현 단위 후보를 실제 코드 기준으로 조사하고 비교하는 문서 단계로 기록했다. 이번 단계는 implementation이 아니며, feature 브랜치 생성이나 runtime/UI 구현을 승인하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 Phase 7-B 조사 기준, current owner / authority 조사 결과, 후보 A/B/C 비교, 추천 후보, forbidden expansion, feature 브랜치 전환 전 조건을 추가했다.
- 추천 첫 구현 후보는 `WordExplorer -> ExplorerWorkspaceState` 읽기 전용 projection adapter로 기록했지만, 이는 implementation approval이 아니며 source of truth는 계속 `WordExplorerScreen`에 남아 있어야 한다고 명시했다.
- implementation status는 `not approved`, feature branch status는 `not approved`로 유지했다.

## 2026-05-21 Phase 7-A implementation entry boundary planning

- Phase 7-A를 ExplorerWorkspace Phase 6 runtime coordination planning 이후 implementation 진입 전에 허용 범위와 금지선을 고정하는 문서 단계로 기록한다. 이번 단계는 implementation이 아니라 implementation entry boundary planning이며, 후속 feature 브랜치 생성이나 runtime/UI 구현을 자동 승인하지 않는다.
- `docs/ux/explorer_workspace_unification.md`에 Phase 7에서 허용 가능한 첫 구현 단위의 조건, 아직 금지해야 할 구현 유형, docs 브랜치에서 feature 브랜치로 전환 가능한 기준, implementation entry checklist를 추가한다.
- runtime/UI 구현 금지, route collapse 금지, canonical owner migration 금지, Provider/Repository/Navigator/persistence authority 이전 금지, coordination candidate의 implementation permission 해석 금지를 Phase 7-A 경계로 다시 고정한다.
- Codex 명령어 기반 검증 항목을 문서에 명시하고, UI 기반 확인은 이번 단계의 수행 대상이 아니며 후속 feature 브랜치에서 UI 동작 변경이 생길 때만 클라이언트 기준으로 분리해 작성한다고 기록한다.

## 2026-05-21 Phase 6-D authority-preserving coordination guardrail policy

- Phase 6-D를 ExplorerWorkspace Phase 6-B coordination candidate inventory와 Phase 6-C authority-crossing risk classification을 owner-preserving guardrail policy로 고정하는 문서 단계로 기록한다. 이번 단계는 implementation planning이 아니며, guardrail policy도 runtime/UI implementation permission이 아니다.
- `allowed wording`, `caution wording`, `forbidden wording`, `allowed planning action`, `review-required planning action`, `blocked planning action`, `authority drift detection criteria`, `escalation criteria`, `implementation status: not approved`를 문서에 추가해 boundary violation 해석을 방지한다.
- `caution wording`은 자유 사용 표현이 아니며 반드시 `reference`, `candidate`, `non-owner`, `caller-local`, `not approved`, `current owner 유지` 같은 제한 문구와 함께 써야 한다. 제한 문구 없이 사용되면 authority drift 위험 표현으로 간주한다.
- review-required planning action은 current owner / authority, forbidden expansion, `implementation status: not approved`를 함께 적어야 하며, 별도 승인 없이 implementation planning으로 넘어갈 수 없다고 고정한다.
- blocked planning action은 구현 단계뿐 아니라 문서상 계획 단계에서도 금지되는 확장으로 정의한다.
- `ExplorerWorkspace`를 runtime coordinator/controller/owner로 승격하지 않으며, Provider/Repository/Navigator/persistence authority와 existing production route 기본값은 그대로 유지한다. route collapse 승인, canonical owner migration, implementation roadmap처럼 읽히는 표현은 금지한다.

## 2026-05-20 Phase 6-C authority-crossing risk classification

- Phase 6-C를 ExplorerWorkspace Phase 6-B candidate의 authority-crossing risk classification 단계로 기록한다. 이번 단계는 implementation planning도 implementation prioritization도 아니며, runtime planning 확장 승인이나 authority migration 승인을 뜻하지 않는다.
- risk level은 `medium`, `high`, `blocked`만 사용하고 `low` 후보는 이번 단계에서 식별하지 않았다. `medium`도 implementation-ready가 아니며 boundary 문서화가 상대적으로 쉬운 후보라는 뜻으로만 제한한다.
- `high`는 owner/controller/coordinator drift, runtime synchronization, route collapse, canonical owner migration 위험이 높은 후보로 정의한다.
- `blocked`는 candidate 자체 폐기를 뜻하지 않으며, reference candidate로 유지할 수 있다. 다만 reference vocabulary / inventory 수준을 넘는 runtime planning 확장, implementation planning, authority migration, route collapse 정당화는 현재 금지된다는 뜻으로 제한한다.
- `ExplorerWorkspace`를 runtime coordinator/controller/owner로 승격하지 않으며, Provider/Repository/Navigator/persistence authority와 existing production route 기본값은 그대로 유지한다. runtime/UI 코드는 변경하지 않는다.

## 2026-05-20 Phase 6-B owner-preserving runtime coordination candidate inventory

- Phase 6-B를 ExplorerWorkspace Phase 6-A 경계를 유지한 owner-preserving runtime coordination candidate inventory 단계로 기록한다. 이번 단계는 implementation 단계가 아니며 runtime execution model, runtime synchronization architecture, route collapse, canonical owner migration을 승인하지 않는다.
- inventory 분류는 `passive coordination candidate`와 `explicit request coordination candidate`로만 제한한다. 여기서 explicit request coordination candidate는 runtime action/execution 의미가 아니라 명시적 요청 후보를 약하게 기록하는 reference vocabulary다.
- 모든 candidate에 current owner / authority 유지, candidate별 forbidden expansion, `implementation status: not approved`를 함께 기록한다.
- `ExplorerWorkspace`를 coordinator, controller, owner로 승격하지 않으며, Provider/Repository/Navigator/persistence authority, existing production route 기본값, `WordExplorerScreen` production authority는 그대로 유지한다. runtime/UI 코드는 변경하지 않는다.

## 2026-05-20 Phase 6-A runtime coordination boundary audit

- Phase 6-A를 ExplorerWorkspace Phase 6 진입 전 문서 경계 audit 단계로 기록한다. 이 단계는 runtime/UI 구현 단계가 아니며, runtime execution model 승인 문서도 아니다.
- `docs/ux/explorer_workspace_unification.md`에서 `workspace action`, `restore action`, `semantic transition`, route alias/collapse, staged roadmap 표현을 preview/reference interaction vocabulary와 historical/reference roadmap 기록으로 다시 고정했다.
- `runtime coordination planning`은 planning input과 reference candidate 정리만 뜻하며, runtime orchestration implementation readiness, runtime synchronization architecture 승인, eventual runtime structure 확정을 의미하지 않음을 명시했다.
- `ExplorerWorkspace`를 권한 주체나 실행 주체처럼 읽게 만드는 표현을 약화하고, coordination vocabulary가 canonical owner migration, route collapse 승인, Provider/Repository/Navigator/persistence authority 재배치의 근거로 해석되지 않도록 경계를 보강했다.
- Provider/Repository/Navigator/persistence authority, existing production route 기본값, `WordExplorerScreen` production authority는 유지하며 runtime/UI 코드는 변경하지 않았다.

## 2026-05-20 Phase 5-I ExplorerWorkspace terminology hardening

- Phase 5-I를 ExplorerWorkspace Phase 5 종료 안정화를 위한 terminology hardening 단계로 기록한다. 이 단계는 새 설계 추가가 아니라 기존 문서 표현을 preview-only orchestration semantics boundary에 맞춰 약화하는 작업이다.
- `owner`, `canonical path`, `수렴`, `semantic navigation spine`, `global/universal entry point`처럼 runtime ownership, production commitment, canonical authority로 오해될 수 있는 표현을 candidate, reference direction, future evaluation target, non-owner semantics로 정리했다.
- Phase 5 종료는 preview-only orchestration semantics의 boundary stabilization만 뜻하며, production migration, runtime coordination implementation, route collapse, canonical owner migration, repository/Navigator/persistence authority 이전을 의미하지 않음을 명시했다.
- 다음 단계는 implementation이 아니라 runtime coordination planning 단계로만 해석해야 하며, 기존 Phase 5-F/G/H boundary 의미는 변경하지 않는다.

## 2026-05-20 Phase 5-H ExplorerWorkspace semantic transition boundary

- Phase 5-H를 workspace 내부의 focus/context/surface 전환을 semantic transition boundary로 정리하는 문서 단계로 기록한다. 이 단계는 production migration이나 route collapse 단계가 아니다.
- semantic context transition은 workspace-local orchestration semantics로만 정리하고, route navigation이나 canonical selection 변경으로 확장하지 않는다.
- focus transition boundary와 foreground surface transition은 authority 이동이 아니라 foreground/emphasis 전환으로만 정리한다.
- temporary focus carry-over는 temporary orchestration continuity로만 제한하고, persistence, repository authority, Navigator authority로 확장하지 않는다.
- graph/detail/context transition 관계와 fixed entry surface transition request를 owner migration 없이 workspace-local coordination 관점에서만 정리했다.
- transition semantics와 canonical selection boundary를 분리하고, runtime/UI 코드 무변경, repository/Navigator/persistence authority 비이전 경계를 유지한다.

## 2026-05-20 Phase 5-G ExplorerWorkspace workspace composition boundary

- Phase 5-G를 `ExplorerWorkspace` 내부 surface들의 workspace composition boundary를 문서로 정리하는 단계로 기록한다. 이 단계는 production migration이나 route collapse 단계가 아니다.
- workspace composition boundary는 ownership boundary가 아니라 surface coordination contract로만 정리한다. 여러 surface의 공존을 canonical owner 병합으로 해석하지 않는다.
- orchestration layer composition은 UI-level coordination으로만 두고 authority layer로 확장하지 않는다.
- surface registration은 문서상 semantics로만 두고 runtime plugin 구조, dynamic registration API, detachable runtime module로 확장하지 않는다.
- workspace-local lifecycle coordination은 canonical lifecycle이 아니라 local coordination lifecycle로만 정리한다.
- detachable surface는 실제 분리 구현이 아니라 해석 후보로만 제한하고, composition contract와 authority boundary를 계속 분리한다.

## 2026-05-20 Phase 5-F ExplorerWorkspace graph/detail hierarchy and temporary focus lifecycle

- Phase 5-F를 `GraphPanel` / `DetailPane` hierarchy와 temporary focus lifecycle을 문서로 정리하는 단계로 기록한다. 이 단계는 production migration이나 route collapse 단계가 아니다.
- Graph / Detail hierarchy는 ownership hierarchy가 아니라 orchestration/foreground hierarchy 후보로만 정리한다. Graph와 Detail 사이에 canonical owner 관계를 부여하지 않는다.
- contextual foreground semantics는 authority semantics가 아니라 현재 context에서 어느 surface가 전경에 놓이는지 설명하는 비권위 표현으로만 정리한다.
- temporary focus lifecycle은 `focus acquisition`, `focus decay`, `focus disposal`의 UI-level temporary lifecycle로만 정리하고, canonical selection, repository authority, Navigator authority, persistence authority로 확장하지 않는다.
- graph/detail synchronization boundary, semantic context transition, temporary expansion vs canonical selection boundary를 owner migration 없이 workspace coordination 관점에서만 정리했다.
- `WordExplorerScreen` production authority 유지, runtime/UI 코드 무변경, repository/Navigator/persistence authority 비이전 경계를 유지한다.

## 2026-05-19 Phase 5-E ExplorerWorkspace global creation entry surface candidate

- Phase 5-E를 `AddWordFixedAction`을 global creation entry surface candidate로 정리하는 문서/경계 단계로 기록한다. 이 단계는 preview-only boundary 안에 머무르며 production replacement가 아니다.
- Add Word는 creation entry / explicit creation request surface 후보로만 정의한다. canonical insertion authority, repository owner, persistence owner, route owner로 확대하지 않는다.
- Add Word action은 semantic creation request 후보일 뿐이며, repository write, persistence 저장, route push, center 변경, selection 확정, detail target 확정을 직접 소유하지 않는다.
- Rail/Search/Graph/Detail과의 관계는 workspace composition 안에서의 후보 관계로만 정리하고, owner 이전 또는 production path 재배선의 근거로 해석하지 않는다.
- `WordExplorerScreen` production authority, route collapse 금지, repository/Navigator/persistence authority 비이전, runtime/UI 코드 무변경 경계를 유지한다.

## 2026-05-19 Phase 5-D ExplorerWorkspace fixed search anchor / semantic entry point candidate

- Phase 5-D를 `GlobalSearch`를 fixed search anchor / semantic entry point candidate로 정리하는 문서/경계 단계로 기록한다. 이 단계는 preview-only boundary 안에 머무르며 production replacement가 아니다.
- Search는 corpus entry, workspace orientation, explicit retarget request surface 후보로만 정의한다. canonical selection owner, graph/detail owner, route owner, persistence owner로 확대하지 않는다.
- Search result 선택은 semantic retarget request 후보일 뿐이며, graph center 확정, detail target 확정, canonical selection 확정, route push, history restore를 직접 소유하지 않는다.
- `temporary focus initiation`과의 관계는 후보 관계로만 정리하고, focus owner 이전, persistent focus policy, persisted layout 결정 주체로 해석하지 않는다.
- `WordExplorerScreen` production authority, route collapse 금지, repository/Navigator/persistence authority 비이전, runtime/UI 코드 무변경 경계를 유지한다.

## 2026-05-19 Phase 5-C ExplorerWorkspace fixed navigation rail candidate

- Phase 5-C를 `StrongRail`의 semantic 역할을 fixed navigation rail candidate로 정리하는 문서/경계 단계로 기록한다. 이 단계는 preview-only boundary 안에 머무르며 production replacement가 아니다.
- `StrongRail`은 strong anchor 접근과 workspace orientation을 위한 stable navigation spine 후보로만 정의한다. graph/detail data owner, repository owner, Navigator owner, persistence/history authority로 확대하지 않는다.
- `persistent narrow rail`은 rail이 좁은 폭으로 계속 남는 시각적 fixed rail 후보라는 뜻으로만 사용한다. persisted layout 저장, route restore, Navigator history 결합, repository-backed preference 의미는 포함하지 않는다.
- rail과 graph/detail orchestration의 관계를 보조적 navigation axis 후보로 제한하고, `WordExplorerScreen` production authority, route collapse 금지, repository/Navigator/persistence authority 비이전 경계를 유지한다.
- `active`/`focused`/`preview` 표현은 새 canonical state가 아니라 기존 workspace state와 preview-only 표현에서 파생되는 비권위 표시로만 정리했다.

## 2026-05-19 Phase 5-B ExplorerWorkspace layout state policy / preset UX refinement

- Phase 5-B를 preview-only layout state policy와 preset UX semantics를 더 명확히 고정하는 단계로 기록한다. 이 단계는 production replacement가 아니다.
- `ExplorerWorkspacePreviewInteractionHost`의 preview-local visibility state를 `graph + detail`, `graph only`, `detail only` 세 상태로 고정하고 `graph hidden + detail hidden` empty workspace 상태를 금지했다.
- preset은 recommended orchestration snapshot, visibility는 current local workspace state로 분리했다. preset 전환이 local visibility state를 강제로 초기화하거나 authority를 이전하지 않도록 유지했다.
- `balanced`를 preview 기본 preset으로 유지하고, `graphFocused`와 `detailFocused`는 canonical/persistence authority가 아닌 preview orchestration semantics로만 설명하도록 UI와 문서를 정리했다.
- `ExplorerWorkspace`에 최소 하나의 semantic panel visible assert를 추가하고, 마지막 visible panel 숨기기 방어를 preview-only UX에서 더 명확히 드러냈다.
- `WordExplorerScreen` production owner, production route 기본값, repository ownership, Navigator ownership, canonical authority, persistence/history authority는 변경하지 않았다.
- Phase 5-B widget/source regression test와 UX/architecture/changelog 문서를 현행화했다.

## 2026-05-19 Phase 5-A preview-only layout orchestration

- Phase 5-A를 preview-only layout orchestration 검증 단계로 기록한다. 이 단계는 production replacement가 아니다.
- `ExplorerWorkspacePreviewInteractionHost`에 preview host 내부 local orchestration state를 추가해 `balanced`, `graphFocused`, `detailFocused` preset 전환과 graph/detail panel visibility 조율을 preview 내부에서만 검증한다.
- preset 전환은 semantic id와 canonical item은 유지한 채 layout만 조율하도록 제한한다. panel visibility와 split ratio는 preview host local state에서만 관리한다.
- `WordExplorerScreen` production owner, production route 기본값, repository ownership, Navigator ownership, canonical authority, persistence/history authority는 유지한다.
- dummy/fallback display item, fake canonical item, production route 교체, route collapse는 이번 단계에서도 추가하지 않는다.
- Phase 5-A widget test와 source-level regression test를 추가하고, 관련 UX/architecture 문서를 현행화했다.
## 2026-05-19 Phase 5-A-1 route 미연결 preview access boundary

- Phase 5-A-1을 route 미연결 preview access boundary 단계로 기록한다. 이 단계는 production route 변경 없이 preview UI 직접 확인용 최소 실행 진입점을 여는 작업이다.
- `lib/main_explorer_workspace_preview.dart` 엔트리 포인트를 추가하고 `flutter run -t lib/main_explorer_workspace_preview.dart` 실행으로 preview-only host를 별도 app 루트에서 띄울 수 있게 했다.
- preview access는 production route, `HomeScreen`, `WordExplorerScreen`, production Navigator tree에 연결하지 않는다.
- preview access는 기존 preview-only input만 사용하며 repository ownership, persistence/history access, display item projection, dummy/fallback display item 추가를 수행하지 않는다.
- Phase 5-A-1 widget/source boundary test와 관련 UX/architecture 문서를 추가했다.

## 2026-05-16 Phase 4-E ExplorerWorkspace preview-only composition boundary

- Phase 4-E를 production replacement가 아니라 ExplorerWorkspace preview-only composition boundary를 고정하는 문서 및 source-level regression test 단계로 기록했다.
- `ExplorerWorkspacePreviewScreen`은 production owner 또는 source of truth가 아니며, workspace-local orchestration은 ownership 이전이 아님을 명시했다.
- Projection lifecycle은 UI-level lifecycle로 제한하고 repository/data lifecycle, Navigator history, route restore, canonical selection ownership과 분리했다.
- production route 기본값, `HomeScreen` production entry, `WordExplorerScreen` production owner, repository/read owner, Navigator owner는 변경하지 않았다.
- preview composition/orchestration boundary가 production import tree, repository ownership, route collapse, dummy id/display item fallback으로 확장되지 않도록 regression test를 추가했다.

## 2026-05-16 Phase 4-D ExplorerWorkspace preview-local interaction boundary

- Phase 4-D를 ExplorerWorkspace preview 내부에서만 동작하는 preview-local interaction boundary 검증 단계로 기록했다.
- `ExplorerWorkspacePreviewInteractionHost`를 추가해 `ExplorerWorkspacePreviewInput`에 이미 들어온 non-empty id만 사용한 graph/detail target 전환을 preview 내부 ephemeral state로 제한했다.
- 기존 `ExplorerWorkspacePreviewScreen`은 read-only projection wrapper로 유지했고, production route 기본값과 `HomeScreen` production entry는 변경하지 않았다.
- DB 조회, repository/read owner 이전, Navigator 호출, route alias 기반 interaction, `WordGraphScreen`/`WordDetailScreen`/`WordExplorerScreen` 직접 embed, dummy id/display item 생성은 수행하지 않았다.
- Phase 4-D boundary regression test를 추가해 preview-local interaction이 production owner, read boundary, route boundary로 확장되지 않는지 검증하도록 했다.

## 2026-05-16 Phase 4-C ExplorerWorkspace passive synchronization boundary

- Phase 4-C를 passive synchronization 허용 범위 검증 단계로 기록하고, production replacement 또는 owner migration 단계가 아님을 명시했다.
- `ExplorerWorkspacePreviewInput` 기반 real projection에서 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`가 동시에 들어와도 병합, 추론, 동기화 ownership으로 확장되지 않는지 boundary regression test를 추가했다.
- projection 관계가 callback/state mutation API, Navigator/history owner, repository/read source owner, search result/display item/explorer history source 연결로 확장되지 않도록 source-level 검증을 보강했다.
- production `lib/` 코드는 변경하지 않았고, production route 기본값과 `WordExplorerScreen` production owner 구조를 유지했다.

## 2026-05-16 Phase 4-B ExplorerWorkspace real projection input

- `ExplorerWorkspacePreviewInput`을 추가해 hidden preview wrapper가 production-compatible real id projection shape를 받을 수 있는 경계를 분리했다.
- projection input은 `selectedWordId`, `graphCenterWordId`, `detailTargetWordId`, `layoutPreset`, `origin`만 보유하며 callback, repository, Navigator, display item, history source를 보유하지 않는다.
- `ExplorerWorkspacePreviewScreen`은 input을 소비해 `ExplorerWorkspace`에 read-only projection으로 전달하는 역할만 유지한다.
- `WordExplorerScreen` production owner, production route 기본값, production import tree isolation, Navigator history / workspace history 분리는 변경하지 않았다.
- DB existence check, state owner migration, repository/read owner migration, route collapse, `WordGraphScreen`/`WordDetailScreen` 직접 embed, dummy id/display item 생성은 수행하지 않았다.

## 2026-05-16 Phase 4-A ExplorerWorkspace production-hidden preview wrapper

- `ExplorerWorkspacePreviewScreen`을 추가해 production route에 연결하지 않는 숨겨진 preview host boundary를 만들었다.
- wrapper는 `ExplorerWorkspaceState.forExplorerEntry`, `forGraphRouteAlias`, `forDetailRouteAlias` 기반 semantic input만 조립하고 `ExplorerWorkspace`에 전달한다.
- `main.dart`와 `HomeScreen` production entry는 변경하지 않았고, `WordExplorerScreen` production owner 구조를 유지했다.
- state owner migration, repository/read owner 이전, `WordGraphScreen`/`WordDetailScreen` 직접 embed, dummy id/display item 생성은 수행하지 않았다.
- source-level boundary test로 preview wrapper가 production entry에 연결되지 않고 route ownership을 갖지 않는지 검증하도록 보강했다.

## 2026-05-13 Phase 8-3A

- GraphBuilder legacy/public helper inventory 결과를 first slice로 반영해 `GraphBuilder.buildFromRepository`, `GraphBuilder.buildFromVisibleGraphData`, `getWordByIdForGraphSingleWord`에 dormant compatibility `@Deprecated` 표시를 추가했다.
- active graph production path는 `WordGraphScreen` → `getVisibleGraphDataForGraph` → `WordGraphDataCache` → `GraphBuilder.buildMergedVisibleGraphData` 구조로 계속 유지한다.
- API 삭제, method signature 변경, graph screen center bootstrap 변경, stale test 정리, DB schema/UI 구조 변경은 수행하지 않았다.

## 2026-05-12 Phase 8-2

- **Explorer bootstrap graph center read 한정**으로 raw center map 의존을 줄였다.
- `WordExplorerScreen` 초기 bootstrap을 `getWordMapByIdForGraphCenterSingleWord` raw row 해석에서 `getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord` typed contract 소비로 전환했다.
- bootstrap center seed는 `wordId`, representative spelling, strong display, representative transliteration의 기존 표시 의미를 유지하며, selected detail display fallback 순서는 기존 제어 흐름을 보존했다.
- `test/ui/word_explorer_screen_phase8h16_bootstrap_center_display_contract_test.dart`를 추가해 typed center display 우선순위와 split-view/id-only fallback 의미가 기존 bootstrap seed와 일치하는지 검증했다.
- 클라이언트 UI 확인 결과, Explorer 초기 bootstrap coherence와 fallback 체감 확인이 모두 성공했다.
- `GraphBuilder`, graph screen 자체 center bootstrap, `WordEditScreen(word: Map)`, `getWordMapByIdForGraphCenterSingleWord`, public legacy API, DB schema, UI 구조는 변경하지 않았다.

## 2026-05-10 Phase 8-1

- **Home/Detail graph navigation existence check 한정**으로 raw map read 의존을 줄였다.
- `HomeScreen`과 `WordDetailScreen`의 graph 진입 전 확인을 `getWordMapByIdForGraphCenterSingleWord` raw row null-check에서 `wordExistsForGraphNavigation(String id)` boolean probe로 전환했다.
- `wordExistsForGraphNavigation`은 `WORD_TABLE.id` 존재 여부만 확인하며, 표시 필드와 expression row를 요구하지 않는다.
- Explorer bootstrap, `GraphBuilder`, `WordEditScreen(word: Map)`, `getWordMapByIdForGraphCenterSingleWord`, public legacy API, DB schema, UI 구조는 변경하지 않았다.

## 2026-05-10 edit input/output typed boundary

- Production edit input boundary를 typed `WordEditSeed` contract 기준으로 완료했다.
- Edit save output/result를 raw `Map<String, dynamic>` route result에서 typed
  `WordEditSaveResult` contract로 전환했다.
- Graph create post-save payload read를 `GraphCreatePostSavePayload`와
  repository-owned post-save payload API로 분리했다.
- `WordGraphScreen`은 graph create post-save relation payload를 만들 때 더 이상
  raw `editedWordMap` / `postSaveWordMap` carrier에 의존하지 않는다.
- DB table/column/index storage는 변경하지 않았다.
- Active UX authority와 active repository/data authority 문서는 재정의하지 않았다.
- Legacy compatibility는 유지한다. `WordEditScreen(word: Map)`과 raw read API는
  compatibility 및 후속 cleanup 판단 대상으로 남겨둔다.

## 2026-04-25 Phase 8-H 완료

- Phase 8-H 완료 기준과 다음 Phase 이관 항목을 문서화했다.
- 완료 범위는 graph seed / public seed의 `centerWordId` 축소, graph/explorer `_centerWordId` authority 정리, visible node / builder-cache carrier 최소 typed contract 정리, selection / center change callback id 중심 정리다.
- 완료 범위에는 explorer tooltip/history display baseline의 `_ExplorerCenterDisplaySeed` / tooltip display contract 분리, pending side-car 제거, explorer bootstrap / graph visible data projection / graph create-relation post-save 경계의 `Word.fromMap` 우회 제거가 포함된다.
- UX 정책 변경 없음.
- 비대상/이관 항목으로 history selected state 정책 판단, global / generic `Word.fromMap` 정리, analyzer/test baseline 정리를 남겼다.
- global Word.fromMap 제거는 다음 Phase 대상이다.
- history selected state는 UX 정책 판단 대상이다.

## 2026-04-25 Phase 8-H-42

- graph create/relation post-save Word.fromMap residual cleanup first slice를 적용했다.
- `WordGraphScreen`의 create/relation post-save 경계에서 `Word.fromMap(currentWordMap)` 우회와 `getWordByIdForGraphSingleWord(newId)` 기반 full `Word` carrier 생성을 제거했다.
- 후속 관계 생성과 새 graph 전환은 local payload의 `wordId`, `representativeSpelling`만 사용하도록 정리했다.
- relation dialog 대표 표기 fallback, graph refresh, cache invalidation 흐름은 유지했다.
- global `Word.fromMap`, repository public API, graph center payload 전체, UX, history selected state 정책은 변경하지 않았다.

## 2026-04-25 Phase 8-H-40

- graph visible data Word.fromMap residual cleanup first slice를 적용했다.
- repository 내부 graph visible data projection에서 `Word.fromMap(row)` 우회를 제거하고, row의 `id`, `표기1`, `스트롱넘버`, `음역1` 값을 직접 trim해 `GraphVisibleWord`를 생성하도록 정리했다.
- `VisibleWordGraphData.connectedWords` 반환 contract와 기존 order 보장 방식은 유지했다.
- global `Word.fromMap`, repository public API, graph builder/cache, SQL read policy, DB schema, UX는 변경하지 않았다.

## 2026-04-25 Phase 8-H-38

- explorer bootstrap word carrier cleanup first slice를 적용했다.
- `WordExplorerScreen` bootstrap center display seed 생성에서 `Word.fromMap(centerWordMap)` 사용 1곳을 제거했다.
- `_ExplorerCenterDisplaySeed`는 `centerWordMap`의 `id`, `스트롱넘버`, `표기1`, `음역1` 최소 필드만 직접 읽어 생성한다.
- history selected state 정책, global `Word.fromMap`, graph 내부 `Word.fromMap`, repository/DB, graph callback contract, tooltip UX는 변경하지 않았다.

## 2026-04-25 Phase 8-H-37

- `pending display seed side-car final cleanup first slice`를 적용했다.
- `WordExplorerScreen`에서 legacy `onChangeCenterWord(Word)` handler 전달을 중단하고, center change 주경로를 `onChangeCenterWordId`로 유지했다.
- `_pendingCenterDisplaySeedFallback` 필드와 소비 helper를 제거했다.
- center display seed는 `_loadSplitViewDisplayItem(centerWordId)` 결과의 detail-like display item으로 확정하고, split-view read가 `null`인 예외 경로에서만 id-only fallback을 허용한다.
- tooltip UX, history selected state 정책, `Word.fromMap` 일반 경계, `onChangeCenterWord(Word)` public API, repository/DB는 변경하지 않았다.

## 2026-04-25 Phase 8-H-36

- pending center fallback side-car cleanup first slice를 적용했다.
- `WordExplorerScreen`의 pending center fallback carrier를 `Word?`에서 `_ExplorerCenterDisplaySeed?`로 축소했다.
- `centerWordId` callback을 authoritative path로 유지하고, legacy `onChangeCenterWord(Word)`는 explorer에서 display seed 보정값으로 즉시 축소 저장하도록 제한했다.
- pending display seed fallback은 id 일치 시에만 소비하고, mismatch 시 폐기한다.
- tooltip UX, history selected state 정책, history payload schema, `onChangeCenterWord(Word)` public API, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-25 Phase 8-H-34

- explorer center state contract first slice를 적용했다.
- `WordExplorerScreen` center authoritative state를 `_centerWordId`로 줄이고, tooltip/history baseline 값은 private `_ExplorerCenterDisplaySeed`로 분리했다.
- graph seed 전달은 기존 `centerWordId` 기준을 유지했고, `_pendingCenterWordChangeFallback`은 id 일치 시 display seed 보정용 compatibility side-car로 유지했다.
- history selected state 복원 정책, tooltip UX, history payload schema, graph callback/public API, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-25 Phase 8-H-33

- graph center change callback contract first slice를 적용했다.
- `WordGraphScreen`에 `onChangeCenterWordId`를 추가하고, same-node center change dispatch의 주 payload를 `centerWordId`로 축소했다.
- 기존 `onChangeCenterWord(Word)`는 compatibility/local fallback side-car로 유지했다.
- `WordExplorerScreen`은 center change를 id callback으로 소비하고, fallback `Word`는 id 일치 시에만 임시 보조 carrier로 사용하도록 제한했다.
- explorer `_centerWord`, history payload, tooltip contract, selection callback, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계, graph/explorer UX 정책은 변경하지 않았다.

## 2026-04-24 Phase 8-H-32

- graph center state contract first slice를 적용했다.
- `WordGraphScreen` 내부 center authoritative state를 `_centerWordId`로 전환하고, cache key / stale guard / reload 기준 / pending center focus 기준을 `_centerWordId`로 통일했다.
- `_centerWord`는 compatibility/local fallback carrier로 유지하고, center display는 기존 `GraphCenterWordDisplayItem` 경로를 유지했다.
- `onChangeCenterWord`, selection callback, explorer/history, graph builder public signature, repository/DB, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-23 Phase 8-H-30

- graph selection callback contract first slice를 적용했다.
- `WordGraphScreen`에 `onSelectWordId`를 selection callback 주경로로 추가하고, 기존 `onSelectWord`는 compatibility fallback으로 유지했다.
- `WordExplorerScreen._selectWord`의 주 입력을 `selectedWordId`로 전환하고, detail panel 갱신은 기존 split-view id reread 경로를 유지했다.
- `onChangeCenterWord`, `_centerWord`, graph builder/cache, repository/DB, `Word.fromMap` 일반 경계, graph/history/tooltip UX 정책은 변경하지 않았다.

## 2026-04-23 Phase 8-H-28

- graph UI state visible node contract first slice를 적용했다.
- `GraphVisibleNode`를 추가해 `WordGraphScreen` 내부 `_graphWordsById` 저장 carrier를 full `Word`에서 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration` 최소 필드로 줄였다.
- `GraphWordLabelDisplayItem` 주 label 경로, `_centerWord`, `ValueChanged<Word>` callback, explorer callback, `WordGraphScreen` public API는 유지했다.
- repository/DB, `Word.fromMap` 일반 경계, graph builder/cache carrier는 변경하지 않았다.

## 2026-04-22 Phase 8-H-26

- graph builder/cache carrier contract first slice를 적용했다.
- `GraphVisibleWord`를 추가해 graph builder/cache 경계의 connected carrier를 `wordId`, `fallbackSpelling`, `fallbackStrongNumber`, `fallbackTransliteration` 최소 필드로 줄였다.
- `VisibleWordGraphData.connectedWords`, `WordGraphDataCache`, `GraphBuilder`의 base/expansion 입력 carrier를 full `Word` 대신 graph visible carrier로 연결했다.
- `GraphWordLabelDisplayItem` 주경로, `WordGraphScreen` public API / `_centerWord` / `_graphWordsById` / callback 시그니처, repository/DB read policy, `Word.fromMap` 일반 경계는 변경하지 않았다.

## 2026-04-22 Phase 8-H-24

- graph seed public API contract first slice를 적용했다.
- `WordGraphScreen`의 주 seed contract를 `centerWordId`로 전환하고, 기존 `centerWord: Word`는 compatibility entrypoint로 남겨 id-only seed로 축소했다.
- home/detail/explorer/graph 내부 graph 진입 caller는 full `Word` 대신 `centerWordId`를 전달하도록 최소 변경했다.
- center display reread, graph label reread, graph data build, `graph_builder`, `word_graph_cache`, repository/DB, `Word.fromMap` 일반 경계, explorer/history payload, graph UX 정책은 변경하지 않았다.

## 2026-04-22 Phase 8-H-22

- graph seed id contract first slice를 적용했다.
- `WordGraphScreen(centerWord: Word)` public API는 유지하면서, graph 내부 seed 소비 경계가 caller `Word`의 표시 필드 대신 `centerWord.id.trim()`만 bootstrap 기준으로 신뢰하도록 정리했다.
- 초기 load와 center update 비교/적용 경계에서 trim된 center id를 사용하고, center display / graph label / graph data는 기존 graph 내부 reread 결과 경로를 유지했다.
- `graph_builder`, `word_graph_cache`, repository, DB, `Word.fromMap` 일반 경계, explorer/history payload, graph UX 정책은 변경하지 않았다.

## 2026-04-21 Phase 8-H-20

- explorer history payload ID contract first slice를 적용했다.
- `_ExplorerHistorySnapshot`의 중심 payload를 `Word` 전체에서 `centerWordId`로 줄이고, payload는 `centerWordId`, `selectedWordId`만 보유하도록 정리했다.
- `_applyHistoryEntry`는 `Word(id: centerWordId)`로 기존 graph center reread 흐름에 연결하고, `_isSameHistoryLocation`은 `centerWordId`, `selectedWordId`만 비교한다.
- tooltip display contract, availability probe contract, `WordGraphScreen(centerWord: Word)`, graph seed public API, `Word.fromMap` 일반 경계, repository/DB는 변경하지 않았다.
- history back/forward UX, selected history 복원 정책, 삭제된 entry fallback 정책은 변경하지 않았다.

## 2026-04-21 Phase 8-H-18

- explorer history tooltip display contract first slice를 적용했다.
- `WordNavigationHistoryTooltipDisplay`를 추가해 tooltip 표시가 `wordId`, 대표 표기, display Strong, 대표 음역 최소 필드를 사용하도록 분리했다.
- `_buildHistoryTooltip`은 더 이상 `entry.payload.centerWord.transliteration1`을 직접 읽지 않고, tooltip display contract의 표시 줄만 소비한다.
- `_ExplorerHistorySnapshot`, back/forward navigation 의미, graph seed, `WordGraphScreen(centerWord: Word)`, `Word.fromMap` 일반 경계, repository/DB는 변경하지 않았다.

## 2026-04-21 Phase 8-H-16

- explorer history availability probe contract first slice를 적용했다.
- `WordExplorerScreen._isHistoryEntryAvailable`의 back/forward 직전 availability 재검증을 `getWordMapByIdForExplorerSingleWord` full map 조회에서 `probeExistingWordIdsForExplorerHistory` id existence probe로 전환했다.
- `_ExplorerHistorySnapshot`, history tooltip/display, graph seed, `Word.fromMap` 일반 경계, explorer UX 정책은 변경하지 않았다.

## 2026-04-20 Phase 8-H-15

- duplicate candidate projection alias contract first slice를 적용했다.
- `findDuplicateCandidates`의 strong exact / normalized strong / non-strong projection row alias를 `word_id`, `language`, `strong_number`, `representative_spelling`, `primary_meaning` canonical 집합으로 맞췄다.
- `_buildDuplicateCandidateDisplayItem`는 canonical alias만 소비하도록 줄였고, `DuplicateCandidateDisplayItem` public field 구조와 duplicate warning UI는 유지했다.
- strong exact / normalized strong / non-strong duplicate 비교 규칙과 create/edit/graph 흐름은 변경하지 않았다.

## 2026-04-19 Phase 8-H-12

- home search ranking candidate contract first slice를 적용했다.
- `HomeSearchRankingCandidate`를 추가해 `searchWordsMap` 내부 ranking helper 입력을 raw row 전체에서 `wordId`, `strongNumber`, indexed spellings / transliterations / meanings 최소 필드로 축소했다.
- `searchWordsMap`의 public 반환형 `List<HomeSearchResultDisplayItem>`과 display projection `_resolveHomeSearchDisplayItemsForPhase32(...)` 흐름은 유지했다.
- strong exact / prefix / partial, spelling exact / prefix / partial, transliteration exact / prefix / partial, meaning partial ranking priority와 id tie-break 정렬 의미는 유지했다.
- `searchStrongExactMap`, `getStrongWordsMap`, `home_screen.dart`, graph / explorer / detail / edit / duplicate / relation add search 경로는 변경하지 않았다.

## 2026-04-18 Phase 8-H-11

- graph center full display contract first slice를 적용했다.
- `GraphCenterWordDisplayItem`을 추가해 center node full display에 필요한 `wordId`, `language`, `displayStrongNumber`, `representativeSpelling`, `representativeTransliteration`, `representativePronunciation`, `primaryMeaning` 최소 필드를 분리했다.
- `WordGraphScreen._buildCenterNode`는 center display contract를 소비하도록 전환했고, `centerWord: Word`, `connectedWords`, graph navigation / selection / expansion / cache key / callback payload는 기존 흐름을 유지했다.
- peripheral node label, secondary label, relation display name은 Phase 8-H-9 결과를 유지했고, `Word.fromMap` 일반 경계 제거는 이번 단계 범위에 포함하지 않았다.
- `test/data/repositories/word_repository_phase8h11_graph_center_display_contract_test.dart`, `test/ui/word_graph_screen_phase8h11_center_display_contract_test.dart`를 추가해 center display projection과 helper widget 표시 경계를 검증했다.

## 2026-04-18 Phase 8-H-9

- graph word label display contract first slice를 적용했다.
- `GraphWordLabelDisplayItem`을 추가해 graph peripheral title, secondary label, relation display name, graph builder label에 필요한 `wordId`, `representativeSpelling`, `representativeTransliteration`, `displayStrongNumber` 최소 필드를 분리했다.
- `VisibleWordGraphData`는 기존 `connectedWords` 흐름을 유지하면서 label 전용 `wordLabels`를 병행 공급하도록 확장했다.
- `GraphBuilder`, `WordGraphScreen`, `WordGraphDataCache`는 label contract 보존과 소비에 필요한 범위만 최소 수정했고, center node full display와 `Word.fromMap` 일반 경계는 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h9_graph_label_display_contract_test.dart`, `test/domain/graph/graph_builder_phase8h9_graph_label_contract_test.dart`를 추가해 representative label projection과 graph builder label fallback을 검증했다.

## 2026-04-18 Phase 8-H-7

- edit 초기 seed 전용 typed contract `WordEditSeed`를 추가했다.
- `WordEditScreen`은 언어, 스트롱넘버, 비고, 의미, expression read result, hidden-slot issue를 seed contract를 통해 초기화하도록 정리했다.
- expression controller group 생성은 `CanonicalExpressionReadResult` 기반 helper를 추가해 연결하고, 기존 legacy row helper는 compatibility 용도로 유지했다.
- hidden-slot issue의 write exclusion 의미와 edit 저장 / validation / submit 정책은 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h7_edit_seed_contract_test.dart`를 추가하고, `word_edit_screen_test.dart`를 보강해 seed 동일성을 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 edit seed typed contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-14 Phase 8-H-5

- `getStrongWordsMap()` 경로에 home default strong list display contract first slice를 적용했다.
- `HomeDefaultStrongListItem`은 기본 strong 목록 consumer에 실제 필요한 `wordId`, `displayStrongNumber`, `representativeSpelling` 최소 필드만 남기도록 정리했다.
- repository strong-list branch는 representative spelling 표시를 기본 strong 목록 전용 typed contract로 projection하고, strong-list mismatch 보호는 최소 contract 기준으로만 제한했다.
- `HomeScreen` 기본 strong 목록 consumer는 새 필드명만 읽도록 최소 수정했고, home search 결과 / 상세 진입 / 기타 흐름은 변경하지 않았다.
- `test/data/repositories/word_repository_phase8h5_home_strong_display_contract_test.dart`를 추가해 representative projection과 legacy fallback baseline을 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 home default strong list display contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-13 Phase 8-H-4

- `searchWords()`의 검색 semantics는 유지한 채 graph relation add search 전용 typed contract first slice를 적용했다.
- graph relation add search 반환 경계는 raw `Word` 대신 `wordId`, `representativeSpelling`, `primaryMeaning`, `displayStrongNumber` 최소 필드만 노출하도록 축소했다.
- `WordGraphScreen` 관계 추가 대상 선택 다이얼로그는 raw slot field 대신 동일 typed contract만 소비하도록 정리했다.
- create-after-save 이후 관계 추가 흐름은 유지하면서 `_showCreateRelationDialog` 입력도 관계 생성에 필요한 최소 인자로 축소했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 graph relation add search contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-13 Phase 8-H-3

- `findDuplicateCandidates`의 query semantics와 strong / non-strong duplicate 판정 규칙은 유지한 채 duplicate warning 전용 typed display contract first slice를 적용했다.
- duplicate candidate 반환 경계는 raw `Map<String, dynamic>` 대신 `wordId`, `language`, `strongNumber`, `representativeSpelling`, `primaryMeaning` 최소 필드만 노출하도록 축소했다.
- `WordEditScreen`, `WordGraphScreen` duplicate warning dialog는 동일한 typed contract만 소비하도록 정리했다.
- duplicate display contract 회귀를 확인하도록 기존 representative query contract test의 duplicate candidate 검증을 보강했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 display contract first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-H-1

- `findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups`를 representative spelling / transliteration 기준 query first slice로 전환했다.
- `findDuplicateCandidates`는 strong 우선 규칙을 유지한 채 non-strong duplicate 비교축을 representative spelling 기준으로 전환했다.
- representative row가 존재하는데 transliteration이 blank인 경우 legacy `음역1`로 복귀하지 않도록 제한했다.
- duplicate warning dialog는 기존 contract를 유지하면서 안내 문구를 representative 표기 기준으로만 최소 조정했다.
- `test/data/repositories/word_repository_phase8h1_representative_query_contract_test.dart`를 추가해 collision / duplicate representative query first slice를 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 Phase 8-H-1 first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-B

- `createWord`, `updateWord`의 expression write 흐름을 canonical expression set -> normalized `word_expression_set` row 저장 -> `WORD_TABLE` 6-slot projection 생성 순서로 재정렬했다.
- `WORD_TABLE` expression slot은 write authority가 아니라 projection/compatibility 출력물로 낮췄고, 이번 단계에서는 6-slot 범위를 유지했다.
- `deleteWord`, `undoLastChange` history는 기존 `WORD_TABLE` compatibility snapshot을 유지하면서 normalized snapshot을 함께 저장하도록 보강했다.
- `undoLastChange`는 신규 history row에서 normalized restore를 우선 사용하고, 기존 history row는 legacy fallback을 유지한다.
- Phase 8-B repository 테스트를 보강해 create/update/delete/undo, save/undo reread, normalized-restore 우선 / legacy-fallback 규칙을 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에는 write authority first switch와 projection/compatibility 유지 사실만 보수적으로 반영했다.

## 2026-04-12 Phase 8-A

- `getWordMapById`, `getWordMapByIdForExplorerSingleWord` 두 raw single-word public read를 Phase 8-A first slice로 `NORMALIZED_WITH_FALLBACK` 경로에 편입했다.
- 두 경로는 새 fallback/resolver를 만들지 않고 기존 detail-like single-word materialization helper를 재사용한다.
- 반환 contract는 계속 raw `Map<String, dynamic>`로 유지하고, visible mismatch가 생기면 기존 legacy fallback을 그대로 사용한다.
- `getWordsByIds`, `getWordsMap`, 기타 generic batch/list read는 이번 단계에서 바꾸지 않았다.
- Phase 8-A 전용 repository 테스트를 추가해 경로 전환과 expression projection 보존을 최소 범위로 검증했다.
- `docs/database/read_source_migration.md`, `docs/logs/FEATURE_STATUS.md`에 raw single-word 2경로 first slice 적용 사실만 보수적으로 반영했다.

## 2026-04-11 Phase 7-11

- detail-like display shared contract `WordDetailLikeDisplayItem`를 추가했다.
- `getWordDetailLikeDisplayItemByIdForDetailScreen`, `getWordDetailLikeDisplayItemByIdForSplitView`의 public 반환형을 raw `Map<String, dynamic>`에서 shared contract로 전환했다.
- repository 내부에 `raw row -> fallback 반영 -> detail-like display contract` 경계를 추가하고, graph/safe-zone raw single-word read는 기존 raw 경계를 유지했다.
- `WordInfoPanel`이 raw map 기반 helper와 직접 key 해석을 제거하고 typed display renderer로 전환됐다.
- `WordDetailScreen`과 `WordExplorerScreen`이 공통 detail-like contract를 panel에 전달하도록 정리됐고, 편집/이동 같은 화면별 동작은 on-demand raw reread로 분리했다.
- `HomeScreen` detail navigation은 새 detail contract를 전달하는 최소 caller 적응만 반영했다.
- `docs/database/read_source_migration.md`에 Phase 7-11 detail-like shared contract 적용 범위와 구조 결과를 반영했다.

## 2026-04-11 Phase 7-7

- home search result display 전용 controlled contract `HomeSearchResultDisplayItem`을 추가했다.
- `searchStrongExactMap`, `searchWordsMap`의 public 반환형을 raw `Map<String, dynamic>` 목록에서 contract 목록으로 전환했다.
- repository 내부에서 `raw row -> fallback 반영 -> display contract 생성` 경계를 고정했다.
- `HomeScreen` search branch가 raw row, `Word.fromMap`, `buildHomeWordDisplaySummary`, raw subtitle 추출 없이 contract만 소비하도록 정리했다.
- `searchWordsMap('')`는 더 이상 `getWordsMap(limit: limit)` browse path로 내려가지 않고 빈 결과를 반환한다.
- `docs/database/read_source_migration.md`에 Phase 7-7 contract 적용 범위와 구조 결과를 반영했다.

## 2026-04-11 Phase 7-4

- Home search branch가 detail / explorer / graph navigation에 search row 전체를 직접 넘기지 않도록 `wordId` 기준 helper로 정리했다.
- search result navigation은 detail `getWordDetailLikeDisplayItemByIdForDetailScreen`, graph `getWordMapByIdForGraphCenterSingleWord`, explorer `initialWordId` bootstrap 구조로 분리했다.
- `WordExplorerScreen` route payload를 `initialWordId`로 줄이고 init bootstrap에서 graph center read + split-view read를 사용하도록 바꿨다.
- explorer history snapshot은 full selected row 대신 selected word id만 보관하도록 정리했다.

## 2026-04-11

### 변경
- controlled zone 판정 기준을 `docs/database/read_source_migration.md` 에 정책 문장으로 문서화했다.
- graph display / history probe / legacy generic read context의 3계층 구조 구분을 확정했다.
- read 승격 절차를 `generic -> owner-specific 분리 -> 반환 계약 고정 -> 관측/검증 가능성 확보 -> controlled 판정` 기준으로 고정했다.
- explorer history existence probe 전용 API `probeExistingWordIdsForExplorerHistory` 를 추가했다.
- explorer history availability 판단은 더 이상 generic `getWordsByIds` full row read를 사용하지 않고 `Set<String>` probe 결과를 직접 사용한다.
- history probe 구현은 `SELECT id FROM WORD_TABLE WHERE id IN (...)` 로 최소화했고 `getWordsByIds` 자체는 그대로 유지했다.
- probe는 display/read-source 해석 대상이 아니므로 기존 `ReadSourceDebugCollector` 를 재사용하지 않고 query 실행부 근처에 전용 collector TODO 만 남겼다.
- history probe 전용 repository 테스트를 추가하고 구조 검증 명령으로 explorer caller의 generic batch 의존 제거를 확인했다.

## 2026-04-10

### 변경
- `readForGraphSingleWord` 를 legacy single read 에서 controlled `normalizedWithFallback` 경로로 승격했다.
- `getWordMapByIdForGraphSingleWord` 는 public API contract 와 기존 `readForGraphSingleWord` context 를 유지한 채 graph single-word 전용 controlled read 로 전환했다.
- graph single-word stable / display-mismatch fallback 을 닫는 repository 테스트와 `tool/verify_graph_single_word_context.dart` 검증 스크립트를 추가했다.
- `getWordsByIds` 는 generic legacy zone 으로 그대로 유지했고 split/detail/save/undo safe zone 은 변경하지 않았다.
- `docs/database/read_source_migration.md` 에 Phase 5 범위와 검증 결과를 반영했다.

## 2026-04-09

### 변경
- graph batch read 를 `readForGraphBatch` 단일 policy zone 으로 승격했다.
- `getWordsByIdsForGraphBatch` 에 graph batch 전용 adapter 를 도입하고 detail/split safe zone 의 detail-like display guard 를 재사용했다.
- generic `getWordsByIds` 는 그대로 `LEGACY` 로 유지하고 collector context 분리를 보존했다.
- repository 테스트에 graph batch normalized success / display-mismatch fallback 검증을 추가했다.
- `tool/verify_graph_batch_context.dart` 를 Phase 4-E 기준 command 검증 스크립트로 갱신했다.
- `docs/database/read_source_migration.md` 에 Phase 4-E 범위와 검증 결과를 반영했다.

## 2026-04-08

### 변경
- split view 표시 read를 detail-like `normalizedWithFallback` 경로로 상향했다.
- `readForSplitViewSingleWord` context를 `NORMALIZED_WITH_FALLBACK` 대상에 편입했다.
- split view wrapper와 explorer history probe wrapper를 분리 유지했다.
- repository 정책 테스트에 split view normalized success / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 Phase 4-B 기준 상태를 반영했다.

## 2026-04-04

### 변경
- 문서 구조를 `/docs` 기준으로 정리했다.
- read source 전환 1차 기반을 repository 내부에 도입했다.
- 기본 read source policy는 아직 `LEGACY`로 유지한다.
- normalized read adapter와 fallback 판정/관측 모델을 연결했다.
- 실제 normalized read 활성 전환은 아직 수행하지 않았다.
- `WordDetailScreen` 전용 제한 경로 `getWordDetailLikeDisplayItemByIdForDetailScreen`를 추가했다.
- 상세 화면은 `widget.word` 초기 표시를 유지한 채 백그라운드에서만 phase 2 read를 시도한다.
- fallback reason에 `user_visible_display_mismatch`를 추가하고 in-memory observation 항목을 확장했다.
- repository 테스트에 detail-only success / empty fallback / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 phase 2 제한 적용 범위, rollback, 관측 기준을 반영했다.
