# Reshet 문서 안내

이 문서는 Reshet 문서의 중앙 index다. 현재 구현을 판단할 때는 현행 authority와 계약을 먼저 읽고, 차기 설계·참고 문서와 과거 기록은 해당 역할에 맞게 구분해서 사용한다.

## 처음 읽을 문서

- [프로젝트 README](../README.md) — 프로젝트 목적, 주요 기능, 실행 조건과 private DB 경계를 안내한다.
- [Project Context](architecture/PROJECT_CONTEXT.md) — Reshet의 개념과 high-level 맥락을 설명하는 입문 참고 문서다.
- [Project Structure](architecture/PROJECT_STRUCTURE.md) — 현재 주요 디렉터리와 코드 책임을 안내한다.

## 현행 architecture

- [Repository Data Boundary Policy](architecture/repository_data_boundary_policy.md) — repository와 data boundary의 현재 active authority다.
- [Project Structure](architecture/PROJECT_STRUCTURE.md) — 외부 개발자를 위한 현재 코드 구조 reference다.
- [Development Workflow](architecture/DEVELOPMENT_WORKFLOW.md) — 작업 유형별 개발·검증·Git 흐름의 active authority다.
- [Graph Semantic Authority](architecture/graph_semantic_authority.md) — graph의 의미와 relation 방향·탐색 경계를 정의한다.
- [ExplorerWorkspace Constitution](architecture/explorer_workspace_constitution.md) — ExplorerWorkspace composition과 ownership 경계를 정의한다.

## 현행 database 계약

- [SCHEMA](database/SCHEMA.md) — 현재 `data/reshet_work.db` 전체 schema의 authority다.
- [Data Structure Policy](database/DATA_STRUCTURE_POLICY.md) — canonical storage, compatibility projection, repository/UI 경계를 정의한다.

## UX와 navigation 계약

- [Workspace UX Architecture](ux/workspace_ux_architecture.md) — workspace UX의 최상위 방향을 정의한다.
- [Navigation Policy](ux/navigation_policy.md) — semantic navigation과 context 연속성의 authority다.
- [Responsive Layout Policy](ux/responsive_layout_policy.md) — form factor별 workspace 유지·변형 기준을 정의한다.
- [Search Policy](ux/search_policy.md) — global search entry와 결과 의미를 정의한다.
- [Interaction Policy](ux/interaction_policy.md) — activation, focus, selection, transient continuity를 정의한다.
- [Graph Layout / Viewport 계약](ux/graph_layout_viewport_contract.md) — graph layout 좌표와 viewport/camera 책임을 정의한다.

## 차기 설계·참고 문서

- [Architecture Overview](architecture/ARCHITECTURE.md) — high-level architecture와 historical/current 맥락을 함께 설명하는 reference다.
- [DATABASE_SCHEMA_v2](database/SCHEMA_v2.md) — relation v2 모델과 lookup metadata의 참고 기준이며 전체 DB schema authority는 아니다.
- [Relation Model v1](database/RELATION_MODEL_v1.md) — relation category/type/direction 모델의 설계 참고 문서다.
- [Explorer 단일 Workspace 통합](ux/explorer_workspace_unification.md) — 현재 구현 조사와 단계별 통합 검토를 보존한 reference/context 문서다.

## 과거 기록·상태 로그

- [FEATURE STATUS](logs/FEATURE_STATUS.md) — 과거 개발 단계의 상태를 보존한 historical log이며 최신 authority가 아니다.
- [CHANGELOG](logs/CHANGELOG.md) — 완료된 변경과 검증 기록을 시간순으로 보존한다.

## SQL·migration 자료

- [Word Expression Set Migration](database/WORD_EXPRESSION_SET_MIGRATION.md) — `word_expression_set` migration 절차와 검증 기준이다.
- [Read Source Migration](database/read_source_migration.md) — read source 전환 과정의 과거 단계 기록이다.
- [`001` create](../sql/word_expression_set/001_create_word_expression_set.sql) — `word_expression_set` 생성 SQL이다.
- [`002` precheck](../sql/word_expression_set/002_precheck_word_expression_set_empty.sql) — backfill 전 상태 확인 SQL이다.
- [`003` backfill](../sql/word_expression_set/003_backfill_word_expression_set.sql) — legacy expression을 normalized row로 옮기는 SQL이다.
- [`004` verify](../sql/word_expression_set/004_verify_word_expression_set.sql) — migration 결과 검증 SQL이다.
- [`005` exceptions](../sql/word_expression_set/005_export_word_expression_set_exceptions.sql) — 예외 후보 추출 SQL이다.
- [`006` rollback](../sql/word_expression_set/006_rollback_word_expression_set.sql) — migration rollback SQL이다.
