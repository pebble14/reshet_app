# Reshet

Reshet은 성경 원어 단어를 Strong 번호, 표기, 음역, 발음, 의미와 관계망으로 검색하고 탐색하는 Flutter 기반 도구다. 단어 상세·편집과 관계 그래프를 하나의 Explorer 흐름에서 연결하며, 데이터는 로컬 SQLite에 저장한다.

이 도구가 성경을 더 깊이 읽고 복음을 접하는 작은 계기가 되기를 바라는 마음으로 개발한다. 소스코드는 누구나 자유롭게 활용하고 발전시킬 수 있도록 MIT 라이선스로 제공한다.

프로젝트 소개는 [Reshet 안내 페이지](https://github.com/pebble14/reshet-info/blob/main/README.md)에서 확인할 수 있다.

## 주요 기능

- Strong 번호와 표기·음역·발음·의미 기반 단어 검색
- 단어 상세 정보 확인과 편집
- 관계 그래프와 Explorer workspace를 통한 관계 탐색
- 단어 관계 추가·수정·삭제와 마지막 변경 undo
- SQLite 전체 DB 백업·복원
- 시스템 설정, 밝은 테마, 어두운 테마 선택

## 검증된 플랫폼

- Windows
- Android

Linux 플랫폼 디렉터리는 저장소에 있으나 실제 검증 환경이 없어 현재 지원 완료를 선언하지 않는다.

## 저장소 구조

| 경로 | 역할 |
| --- | --- |
| `lib/` | Flutter 앱, 도메인 계약, repository, SQLite lifecycle |
| `test/` | UI·도메인·repository·database 검증 |
| `docs/` | 현행 authority, 설계 참고, migration, 과거 기록 |
| `sql/` | 명시적으로 실행하는 migration·검증 SQL |
| `data/` | 로컬 SQLite DB 위치. DB 파일은 Git 추적 대상이 아님 |
| `windows/`, `android/` | 검증된 플랫폼 runner |

세부 책임은 [프로젝트 구조](docs/architecture/PROJECT_STRUCTURE.md)에서 확인할 수 있다.

## 핵심 코드 진입점

| 흐름 | 경로 |
| --- | --- |
| 앱 시작 | `lib/main.dart` |
| 주요 UI | `lib/ui/` |
| 도메인 쓰기 경계 | `lib/domain/word/` |
| 데이터 조회·저장 | `lib/data/repositories/word_repository.dart` |
| SQLite lifecycle | `lib/database/database_service.dart` |
| DB 백업 | `lib/database/database_backup_service.dart` |
| DB 복원 | `lib/database/database_restore_service.dart` |
| DB snapshot | `lib/database/database_snapshot_service.dart` |

Repository와 데이터 경계의 세부 계약은 [Repository Data Boundary Policy](docs/architecture/repository_data_boundary_policy.md)를 따른다.

## SQLite DB와 Git 미추적 asset 경계

`data/reshet_seed.db`와 `data/reshet_work.db`는 의도적으로 Git에 포함하지 않는다. 따라서 clean clone에는 실행용 DB가 없다.

- 소스와 문서 열람, 의존성 설치는 DB 없이 가능하다.
- 전체 앱 실행과 일부 integration/runtime 테스트에는 별도로 준비된 seed/work DB가 필요하다.
- Windows·Android build에는 `pubspec.yaml`에 asset으로 선언된 `data/reshet_seed.db`가 필요하다.
- 공식 DB 배포 파일은 게시가 완료되면 [프로젝트 소개](https://github.com/pebble14/reshet-info/blob/main/README.md)에서 안내한다. 입수한 공식 seed는 `data/reshet_seed.db`로 준비한다. 기존 DB가 있으면 먼저 백업하고, 개인 작업 DB를 배포 DB로 임의 덮어쓰지 않는다.

현재 DB 계약은 [SCHEMA](docs/database/SCHEMA.md)에서 확인한다.

## 코드 라이선스와 출처 안내

Reshet 자체의 소스코드는 [MIT 라이선스](LICENSE)를 따른다. 수정·재배포·상업적 이용을 허용하며, 수정판의 소스코드 공개를 요구하지 않는다. 코드 또는 그 상당 부분을 재배포할 때는 원저작권 표시와 MIT 라이선스 전문을 유지해야 한다.

MIT 적용 범위에는 DB와 어휘 연구 데이터(문서·manifest에 포함된 데이터 포함), 외부 원자료, 제3자 코드·자산을 일괄 포함하지 않는다. 해당 자료에는 별도로 명시한 이용 조건을 적용한다.

Reshet를 활용한 프로그램이나 문서에서 아래 출처 문구를 사용하면 프로젝트를 알리는 데 도움이 된다. 프로젝트명·소개 링크·저장소 링크의 안내는 권장 사항이며 MIT에 추가되는 의무 조건은 아니다. 이 문구는 원저작권 표시와 라이선스 전문을 대신하지 않는다.

```text
Reshet의 소스코드를 활용했습니다.
프로젝트 소개: https://github.com/pebble14/reshet-info/blob/main/README.md
소스코드: https://github.com/pebble14/reshet_app
코드 라이선스: MIT
```

## 데이터와 라이선스

Reshet가 권리를 가진 데이터 기여분은 [CC BY 4.0](docs/legal/data_license.md)으로 제공한다. 수정·재배포·상업적 이용을 허용하며 수정판의 동일조건배포나 DB·소스 공개를 요구하지 않는다. 출처·라이선스와 변경 사실을 안내해야 한다. 외부 원자료의 조건은 유지하며 DB 전체를 단일 CC BY 자료로 안내하지 않는다.

현재 데이터 provenance 정리와 공개 Strong 원천을 통한 선택적 재검증이 진행 중이며, e-Sword 모듈 파일은 저장소와 배포물에 포함하지 않는다. DB 파일은 계속 Git에서 제외하며 실제 다운로드 경로는 배포가 완료되면 안내한다.

확인된 출처, 재배포 경계와 향후 데이터 입력 기준은 [데이터 출처와 재배포 경계](docs/database/DATA_PROVENANCE.md)를 따른다.

## 개발 환경 준비

1. Flutter stable과 대상 플랫폼 toolchain을 준비한다.
2. `pubspec.yaml`의 Dart SDK 조건인 `^3.11.0`을 만족하는지 확인한다.
3. 의존성을 설치한다.

```powershell
flutter pub get
```

`flutter pub get`은 DB 없이 실행할 수 있다. 전체 앱을 실행하려면 먼저 앞의 DB 경계에 맞는 DB를 준비해야 한다.

```powershell
flutter run -d windows
flutter devices
flutter run -d <Android-device-id>
```

## 분석과 테스트

정적 분석은 runtime DB를 읽지 않는다.

```powershell
flutter analyze
```

DB를 직접 열지 않는 단위 테스트는 개별 실행할 수 있다. 다음은 relation formatter 단위 테스트의 예다.

```powershell
flutter test test/domain/relation/relation_formatter_test.dart
```

이 안내는 모든 analyze/test의 현재 통과를 선언하지 않는다. DB·asset·runtime 경로를 여는 테스트는 clean clone에서 바로 실행되지 않으므로 각 테스트의 fixture와 private DB 의존성을 먼저 확인해야 한다.

## 문서 안내

- [문서 중앙 index](docs/README.md)
- [프로젝트 구조](docs/architecture/PROJECT_STRUCTURE.md)
- [Repository/Data 경계](docs/architecture/repository_data_boundary_policy.md)
- [현재 DB schema](docs/database/SCHEMA.md)
- [데이터 이용 조건](docs/legal/data_license.md)
- [Windows 베타 배포 절차](docs/release/windows_beta.md)
- [Workspace UX Architecture](docs/ux/workspace_ux_architecture.md)
- [Navigation Policy](docs/ux/navigation_policy.md)

## 현재 제한사항

- clean clone만으로는 전체 앱과 DB 의존 테스트를 실행할 수 없다.
- Linux는 실제 검증 환경이 없어 지원 완료 상태가 아니다.
- DB 전체에 단일한 라이선스를 적용하지 않으며 Reshet 기여분과 외부 원자료의 조건을 구분한다.
