# Project Structure

> 문서 분류: 현재 코드 구조 reference
>
> 이 문서는 외부 개발자가 주요 디렉터리와 책임을 찾기 위한 안내다. 세부 repository/data authority는 [Repository Data Boundary Policy](repository_data_boundary_policy.md), UX authority는 [Workspace UX Architecture](../ux/workspace_ux_architecture.md), 현재 DB schema는 [SCHEMA](../database/SCHEMA.md)를 따른다.

## 프로젝트 개요

Reshet은 Flutter와 SQLite를 사용하는 단어 관계 탐색 도구다. 앱의 기본 데이터 흐름은 UI에서 domain/repository 경계를 거쳐 SQLite에 접근하며, UI가 SQL을 직접 실행하지 않는다.

## 저장소 최상위 구조

```text
lib/       Flutter production code
test/      UI, domain, repository, database test
docs/      현행 계약, 설계 참고, migration, 과거 기록
sql/       명시적으로 실행하는 migration·검증 SQL
data/      로컬 private SQLite DB와 backup 위치
windows/   Windows runner
android/   Android runner
```

`data/`의 `*.db`, `*.sqlite`, `*.sqlite3` 파일은 `.gitignore`로 제외한다. clean clone에는 실행용 DB가 없으며, DB 경계는 [루트 README](../../README.md)와 [SCHEMA](../database/SCHEMA.md)를 함께 확인한다.

## `lib/` 주요 책임

```text
lib/
├── main.dart
├── database/
├── data/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── expression/
│   ├── graph/
│   ├── relation/
│   └── word/
└── ui/
    └── explorer_workspace/
```

### `lib/main.dart`

Flutter 앱 시작점이다. 앱 초기화, 테마 설정, `HomeScreen` 진입을 연결한다.

### `lib/database/`

SQLite 파일 lifecycle과 전체 DB 백업·복원을 담당한다.

- `database_service.dart` — seed/work DB 선택, open, runtime schema·lookup 보정 경계
- `database_snapshot_service.dart` — 전체 SQLite snapshot 생성
- `database_backup_service.dart` — 플랫폼별 백업 저장 흐름
- `database_restore_service.dart` — 복원 후보 검증, staging, 교체와 rollback 흐름

### `lib/data/`

- `models/` — word, relation, relation lookup의 data model
- `repositories/word_repository.dart` — 단어·표현·의미·관계의 조회와 저장, history/undo를 제공하는 repository 경계

단어·관계 데이터 read/write UI는 SQL을 직접 사용하지 않고 repository/domain 계약을 소비한다. DB 초기화·백업·복원 같은 SQLite lifecycle 작업은 별도 database service 경계를 통해 앱 UI에서 조율한다.

### `lib/domain/`

저장 row와 화면 사이에서 사용하는 typed contract와 도메인 로직을 둔다.

- `expression/` — expression read model과 read source 정책
- `graph/` — graph node/edge/view contract와 layout 전략
- `relation/` — relation 표시·해석 규칙
- `word/` — word edit seed/result, write command와 write service

### `lib/ui/`

검색, 상세·편집, Explorer, graph 화면과 responsive presentation을 담당한다.

- `home_screen.dart` — 검색과 large/small 화면 shell의 진입점
- `word_detail_screen.dart` — 단어 상세 route
- `word_edit_screen.dart` — 단어 편집 흐름
- `word_explorer_screen.dart` — graph/detail 탐색의 production owner
- `word_graph_screen.dart` — graph 표시와 단어·관계 action surface
- `explorer_workspace/` — Explorer composition contract와 preview/reference 구성

Explorer의 장기 UX 방향과 현재 owner 경계는 [문서 index](../README.md)의 UX·architecture authority를 따른다.

## `test/`, `docs/`, `sql/`

- `test/ui/` — 화면 contract와 widget behavior 검증
- `test/domain/` — graph, relation, expression, word domain 검증
- `test/data/` — repository read/write 경계 검증
- `test/database/` — backup/restore와 DB lifecycle 검증
- `docs/` — 코드와 함께 유지하는 authority, reference/context, migration/history 기록
- `sql/word_expression_set/` — expression normalization을 위한 단계별 SQL 자료

이 문서는 모든 파일의 inventory가 아니다. 새 진입점을 찾을 때는 위 책임 경계에서 시작하고, 세부 정책은 [문서 중앙 index](../README.md)에서 현재 역할을 확인한다.
