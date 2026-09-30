# License Baseline

## 1. 목적

이 문서는 현재 repository 상태의 third-party dependency, SDK resource, icon, font, asset license baseline을 기록한다.

이 문서는 Reshet 자체의 배포 license를 선언하지 않는다.
release, commercial distribution, public distribution, open-source 전환 전에는 별도 compliance review가 필요하다.

## 2. 문서 Status와 Scope

Status: Baseline reference

이 문서는 다음 범위를 다룬다.

- `pubspec.yaml`과 `pubspec.lock` 기준 dependency license baseline
- Flutter / Dart SDK 및 bundled resource baseline
- Material Icons, Cupertino Icons, platform template asset provenance
- SQLite / `sqlite3` / `sqflite_common_ffi` license 성격 구분
- dependency 또는 asset 추가 시 license audit workflow

이 문서는 다음을 선언하지 않는다.

- Reshet project-level license
- release readiness
- commercial distribution readiness
- public distribution readiness
- legal approval

## 3. Baseline과 Final Compliance의 구분

Baseline은 현재 repository와 lockfile을 기준으로 확인된 license 상태를 기록한다.
Baseline은 dependency 추가, asset 추가, SDK 변경, release target 변경이 발생하면 다시 갱신되어야 한다.

Final compliance는 배포 방식, 대상 플랫폼, 포함되는 binary/resource, project-level license, notice 제공 방식까지 포함해 별도로 검토해야 한다.
따라서 이 문서는 final compliance verdict가 아니라 current-state reference이다.

## 4. 현재 Dependency Baseline

작성 기준: 2026-05-08 repository 상태

`pubspec.lock` 기준 dependency 개요:

| 구분 | 수량 / 항목 |
|---|---|
| 전체 package | 57 |
| hosted package | 53 |
| SDK package | 4 |
| direct main dependency | `cupertino_icons`, `flutter`, `path`, `shared_preferences`, `sqflite_common_ffi` |
| direct dev dependency | `flutter_lints`, `flutter_test` |
| transitive dependency | 50 |

로컬 Pub cache의 package `LICENSE` 파일 기준 hosted package license 분포:

| License 계열 | 수량 |
|---|---:|
| BSD-style | 46 |
| MIT | 4 |
| Apache-2.0 | 3 |

현재 baseline에서 GPL / AGPL / LGPL 후보는 확인되지 않았다.
이 판단은 `pubspec.lock`의 현재 version과 로컬 cache의 license file을 기준으로 한다.

직접 hosted dependency baseline:

| Package | Version | Dependency | Baseline License | Status |
|---|---:|---|---|---|
| `cupertino_icons` | `1.0.8` | direct main | MIT | Allowed |
| `path` | `1.9.1` | direct main | BSD-style | Allowed |
| `shared_preferences` | `2.5.4` | direct main | BSD-style | Allowed |
| `sqflite_common_ffi` | `2.4.0+2` | direct main | BSD-2-Clause | Allowed |
| `flutter_lints` | `6.0.0` | direct dev | BSD-style | Allowed |

## 5. SDK / Flutter / Dart Baseline

Flutter SDK와 Dart SDK는 repository dependency가 아니라 SDK baseline으로 별도 관리한다.

| Component | 확인 기준 | Baseline License | Status |
|---|---|---|---|
| Flutter SDK | local `C:\flutter\LICENSE` 및 공식 repository | BSD-style / BSD-3-Clause 계열 | Allowed |
| Dart SDK | local `C:\flutter\bin\cache\dart-sdk\LICENSE` 및 공식 repository | BSD-style / BSD-3-Clause 계열 | Allowed |
| Flutter SDK bundled artifacts | local `C:\flutter\bin\cache\artifacts` | bundled notice 확인 필요 | Review Required |

SDK 자체는 permissive 계열로 보이지만, SDK가 함께 제공하는 fonts, engine artifact, platform artifact는 release target별 notice 필요 여부를 별도로 확인해야 한다.

## 6. Icon / Font / Asset Provenance

`pubspec.yaml` 기준 custom `assets:` 섹션은 Android seed DB 복사를 위해 `data/reshet_seed.db`만 선언한다.
custom `fonts:` 섹션은 현재 활성화되어 있지 않다.
`assets/branding/`은 앱 아이콘 SVG 원본과 Linux 배포 준비 자산이며 Flutter runtime asset으로 등록하지 않는다. 별도 custom font는 사용하지 않는다.

앱 아이콘은 사용자 제공 승인 이미지 `reshet_icon_design.png`를 기준으로 재구성한 프로젝트 브랜딩 자산이다. 이 밖의 SDK resource와 iOS launch asset은 기존 baseline을 유지한다.

| Resource | Path / Source | Baseline | Status | Notes |
|---|---|---|---|---|
| Material Icons | `uses-material-design: true`, Flutter SDK bundled material font | CC BY 4.0 계열 license file 확인 | Review Required | attribution / notice 관리 필요 가능성 |
| Roboto fonts | Flutter SDK bundled material fonts | Apache-2.0 | Allowed | SDK bundled resource로 관리 |
| Cupertino Icons | `cupertino_icons` package | MIT | Allowed | package `LICENSE` 확인 |
| Seed DB asset | `data/reshet_seed.db` | Project data | Allowed | `data/reshet_work.db` 기준 개발 baseline snapshot이며 앱 최초 설치/reset 기준 DB. 앱 공개 전까지 Git 미추적 로컬 private build asset으로 유지 |
| 공통 아이콘 원본 / Linux 준비 자산 | `assets/branding/` | 사용자 제공 승인 디자인의 수작업 SVG 재구성 및 생성 PNG | Project asset | 외부 font·bitmap 참조 없음. 원본 제공 경위를 기록하며 별도 배포 권리 승인을 선언하지 않음 |
| Web icons / favicon | `web/icons/*`, `web/favicon.png` | 공통 SVG에서 생성 | Project asset | 일반·maskable·작은 크기 변형 |
| Android launcher icons | `android/app/src/main/res/mipmap-*`, `drawable*/reshet_icon_*` | 공통 SVG에서 생성 | Project asset | legacy·adaptive·monochrome |
| iOS app icons | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | 공통 SVG에서 생성 | Project asset | 기존 Asset Catalog 크기·파일명 유지 |
| iOS launch assets | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | Flutter template-derived 가능성 | Review Required | 이번 앱 아이콘 교체 범위 밖 |
| macOS app icons | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` | 공통 SVG에서 생성 | Project asset | 기존 Asset Catalog 크기·파일명 유지 |
| Windows app icon | `windows/runner/resources/app_icon.ico` | 공통 SVG에서 생성 | Project asset | 크기별 독립 렌더링 frame |

앱 아이콘 원본은 `assets/branding/reshet_icon_master.svg`다. 작은 크기·단색 SVG 및 플랫폼 자산은
`tool/generate_app_icons.cjs`로 생성한다. 기존 개발환경의 `sharp`를 `NODE_PATH`로 지정하여
`node tool/generate_app_icons.cjs`를 실행한다. 앱 dependency와 runtime bundle에는 renderer를 추가하지 않는다.
생성기는 검토용 PNG와 자산 목록을 Git 제외 경로 `build/icon-review/`에 저장한다.
마스터는 전체 정사각형 배경을 유지하고 플랫폼 모서리와 Android/Web 안전영역은 생성 단계에서 처리한다.

`.metadata`의 Flutter create revision은 기존 platform scaffold의 이력이다.
이번 교체 대상 앱 아이콘의 현재 출처를 Flutter template로 간주하지 않는다.

## 7. SQLite / sqlite3 License 구분

SQLite 관련 dependency는 Dart wrapper와 native SQLite를 분리해서 관리한다.

| Component | 성격 | Baseline License | Status |
|---|---|---|---|
| `sqflite_common_ffi` | Dart/Flutter FFI wrapper | BSD-2-Clause | Allowed |
| `sqflite_common` | transitive Dart wrapper | BSD-2-Clause | Allowed |
| `sqlite3` Dart package | Dart FFI binding / code assets | MIT | Allowed |
| native SQLite | embedded database engine | public domain | Allowed |

`sqlite3` package와 native SQLite는 같은 license unit으로 취급하지 않는다.
`sqlite3` Dart package는 MIT baseline이고, native SQLite는 public domain baseline으로 기록한다.
Release artifact에 native SQLite binary가 포함되는 경우, 해당 target의 bundled binary와 notice 필요 여부를 다시 확인한다.

## 8. Root Project License 상태

현재 repository root에는 project-level `LICENSE`, `NOTICE`, `COPYING` 파일이 없다.

따라서 이 문서는 Reshet 자체의 배포 license를 선언하지 않는다.
현재 문서는 third-party dependency와 bundled resource의 baseline만 기록한다.

Project-level license를 정하기 전까지는 다음을 구분한다.

- Reshet source code의 license: undecided
- Third-party dependency baseline: 이 문서에서 current-state 기준으로 기록
- Release / distribution notice: future review 대상

## 9. Allowed / Review Required / Prohibited License Policy

### Allowed

다음 license 계열은 현재 project policy상 기본 허용 후보로 본다.

- MIT
- BSD-2-Clause
- BSD-3-Clause
- Apache-2.0
- Flutter / Dart BSD-style license
- SQLite public domain

### Review Required

다음 항목은 사용 전 별도 검토가 필요하다.

- LGPL
- MPL
- CC-BY
- OFL
- native binary를 포함하는 package
- attribution required asset
- font 또는 icon resource
- SDK bundled artifact
- platform-specific binary 또는 generated artifact

### Prohibited

다음 성격의 license 또는 resource는 기본적으로 사용하지 않는다.

- GPL
- AGPL
- commercial-use restricted license
- strong source disclosure obligation이 있는 license
- usage-restricted license
- redistribution 제한이 명확한 asset 또는 font

## 10. Dependency 추가 시 Audit Workflow

Dependency를 추가하거나 version을 변경할 때는 다음 절차를 따른다.

1. `pubspec.yaml` 변경 내용을 확인한다.
2. `pubspec.lock` 변경 내용을 확인한다.
3. 새로 추가되거나 version이 바뀐 package 목록을 추출한다.
4. direct dependency와 transitive dependency를 구분한다.
5. 각 package의 `LICENSE`, `NOTICE`, `COPYING` 파일을 확인한다.
6. package license를 Allowed / Review Required / Prohibited 중 하나로 분류한다.
7. native binary, code assets, generated artifacts 포함 여부를 확인한다.
8. Review Required 또는 Prohibited 후보가 있으면 변경을 중단하고 별도 검토한다.
9. baseline 문서를 갱신한다.

권장 확인 명령:

```powershell
git status --short --branch
Get-Content pubspec.yaml
Get-Content pubspec.lock
flutter pub deps --style=list
rg -n "GPL|AGPL|LGPL|MIT|BSD|Apache|license|LICENSE|라이선스" .
```

## 11. Asset / Font / Icon 추가 시 Provenance Workflow

Asset, font, icon, image를 추가할 때는 다음 정보를 기록한다.

| Field | 설명 |
|---|---|
| Path | repository 내 resource 경로 |
| Source | 원 출처 또는 생성 도구 |
| License | license 또는 사용 조건 |
| Attribution Required | attribution 필요 여부 |
| Modification | 원본 수정 여부 |
| Distribution Notes | release artifact 포함 여부와 notice 필요 여부 |
| Status | Allowed / Review Required / Prohibited |

Asset provenance가 불명확한 resource는 release 대상에 포함하기 전에 출처와 license를 확정해야 한다.

## 12. Known Open Items

현재 baseline에서 남아 있는 open item은 다음과 같다.

- Material Icons bundled resource의 attribution / notice 제공 방식 확인
- Flutter SDK bundled artifact의 release target별 notice 필요 여부 확인
- platform template asset이 Flutter template 원본에서 유래했는지 최종 provenance 확인
- Windows / macOS app icon의 current SDK template hash 불일치 원인 확인
- root project-level `LICENSE` 결정
- public distribution 또는 open-source 전환 시 `NOTICE` / `THIRD_PARTY_NOTICES` 필요 여부 확인
- release artifact에 포함되는 native SQLite binary 확인

## 13. Future Release / Commercial Compliance Checklist

Release 또는 public distribution을 검토할 때는 최소한 다음을 확인한다.

- project-level license 결정 여부
- third-party dependency license table 최신화 여부
- Flutter / Dart SDK license notice 포함 필요 여부
- Material Icons / fonts attribution 필요 여부
- platform template asset provenance 확정 여부
- native binary 포함 여부
- target platform별 generated artifact 확인
- `NOTICE` 또는 `THIRD_PARTY_NOTICES` 문서 필요 여부
- dependency 추가 이후 license audit 재실행 여부

## 14. References

- Flutter SDK local license: `C:\flutter\LICENSE`
- Dart SDK local license: `C:\flutter\bin\cache\dart-sdk\LICENSE`
- Flutter official license: https://github.com/flutter/flutter/blob/master/LICENSE
- Dart SDK official license: https://github.com/dart-lang/sdk/blob/main/LICENSE
- Material Design Icons license: https://github.com/google/material-design-icons/blob/master/LICENSE
- Cupertino Icons package license: https://pub.dev/packages/cupertino_icons/license
- sqflite_common_ffi package license: https://pub.dev/packages/sqflite_common_ffi/license
- sqlite3 package: https://pub.dev/packages/sqlite3
- SQLite copyright: https://www.sqlite.org/copyright.html

## 15. 요약

현재 dependency baseline은 MIT / BSD-style / Apache-2.0 중심이다.
현재 확인 범위에서 GPL / AGPL / LGPL 후보는 발견되지 않았다.

그러나 이 문서는 current-state baseline이며 project-level license 또는 release readiness를 선언하지 않는다.
Dependency, asset, SDK, release target이 바뀌면 이 baseline은 다시 검토되어야 한다.


## Android 비공개 테스트 준비 점검 (2026-09-30)

현재 `.dart_tool/package_config.json`의 hosted package 65개에 대해 실제 cache LICENSE/NOTICE 파일을 읽어 확인했다. 파일 누락은 없었으며 MPL/GPL/AGPL/LGPL 본문 표지는 발견하지 못했다. 이 결과는 기존 2026-05-08 표의 패키지 수를 현행 수로 단정하는 근거가 아니며, 검증 기록은 `build/play_release/source_audit.json`에 보관한다.

출시 AAB에는 Flutter의 `NOTICES.Z`가 포함되어 Flutter·Dart·SQLite wrapper 및 파일 선택·설정 패키지의 안내를 포함한다. 프로그램 정보에서 Flutter 표준 라이선스 화면으로 접근한다. 자료 출처는 `data_attributions.md`, 개인정보 안내는 `privacy_policy.md`로 별도 제공한다.

Strong 원자료는 pinned manifest의 CC0/CC BY 4.0 근거와 가공 안내를 제공한다. 초기 보존 DB의 한국어 뜻풀이·RMAC 등 전체 자료의 재배포 근거는 아직 확인 중이며, 기술적으로 빌드됐다는 사실을 DB 전체 배포권 검토 완료로 해석하지 않는다. Reshet 자체의 공개 소스 라이선스는 이번 작업으로 정하지 않는다.
