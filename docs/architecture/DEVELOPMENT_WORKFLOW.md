# DEVELOPMENT_WORKFLOW.md

## 1. 문서 성격과 목적

- 문서 분류: `active authority`
- 목적: Reshet의 작업 유형별 개발, 검증, 검토, Git 흐름을 정의한다.

루트 `AGENTS.md`는 저장소 작업 규칙을 정의하고, 이 문서는 실제 개발 흐름을 구체화한다.
UX 목표와 정책은 최신 `/docs/ux` active authority를 우선한다.

## 2. 공통 원칙

- 사용자는 최종 승인자다.
- 실제 코드, 문서, DB, Git 상태를 확인한 근거로 작업한다.
- 작업은 하나의 목적을 가진 작은 단위로 나눈다.
- 데이터 의미와 기존 기능을 보존한다.
- 항상 같은 검증을 강제하지 않고 작업 유형과 영향 범위에 맞게 검증한다.
- 해당하지 않는 단계는 `N/A`와 사유로 대체한다.

## 3. 작업 유형과 브랜치

| 작업 유형 | 변경 범위 | 브랜치 | 핵심 검증 |
| --- | --- | --- | --- |
| read-only audit | 파일 변경 없음 | `main` 가능 | 실제 상태 확인, 후속 후보 정리 |
| docs-only | 문서만 변경 | `docs/...` | diff, 문서 충돌, 문서 위치 |
| test-only / guard | 테스트·guard만 변경 | `test/...` | 변경 테스트 실행 |
| cleanup / chore | 기능 변화 없는 정리 | `chore/...` | 기능 변화 없음, 관련 명령어 검증 |
| production 기능 변경 | 앱 동작·UX·DB·흐름 변경 | `feature/...` 또는 `fix/...` | 관련 명령어 검증, 필요 시 UI 테스트 |

파일 변경 없는 audit 중 변경 필요가 확인되면 그 시점에 적절한 작업 브랜치를 만든다.
서로 다른 목적의 변경은 한 브랜치에 섞지 않는다.

## 4. 기본 흐름

기본 흐름은 다음과 같다.

설계 → 수정 제안 → 사용자 승인 → 구현 → 검증 → 검토 → 커밋 → 병합

### 설계와 수정 제안

다음을 확인하고 보고한다.

- 작업 유형과 목표
- 현재 branch와 working tree
- 수정할 파일과 정확한 위치
- 변경 범위와 금지 범위
- 검증 계획과 UI 테스트 초안
- 문서 영향 예상

승인 범위를 넘어서는 추가 변경이나 정책 판단이 필요하면 구현 전에 보고한다.

### 구현

- 승인된 파일과 범위만 수정한다.
- production code, 문서, DB, 설정을 임의로 함께 변경하지 않는다.
- 현재 architecture와 public contract를 우회하지 않는다.

### 검증

검증은 명령어 기반 검증과 UI 기반 테스트로 구분한다.

| 검증 유형 | 수행 주체 | 예시 |
| --- | --- | --- |
| 명령어 기반 검증 | Codex | `flutter test`, 특정 테스트 파일, `flutter analyze`, SQL 조회, Git/diff 확인 |
| UI 기반 테스트 | 클라이언트 | 실제 화면 조작, UX 판단, 시각적 변화 확인 |
| 문서·정책 검토 | 상위 설계자 또는 ChatGPT 검토, 필요 시 Codex 근거 보고 | authority 충돌, 정책 정합성 확인 |

`flutter run -d windows`는 UI 확인이 필요한 경우의 실행 수단이지 모든 작업의 고정 검증 명령이 아니다.
Codex는 수행하지 않은 UI 테스트를 완료로 보고하지 않는다.

### 검토

검토 단계에서는 다음을 확인한다.

- 승인 범위와 작업 유형 준수
- 기존 기능 영향
- 데이터 의미 보존
- 문서 갱신 또는 영향 없음 사유
- 의도하지 않은 변경
- 검증 결과와 남은 위험

## 5. 검증 N/A 기준

다음은 영향이 없을 때 `N/A`로 처리할 수 있다.

- docs-only: Flutter UI 테스트, 앱 실행 테스트, SQL 검증
- UI 영향 없는 test-only / cleanup: UI 테스트
- DB read/write 영향 없는 test-only / cleanup / UI 변경: SQL 검증
- 의존성 변경 없는 작업: 라이선스 검증
- DB schema 변경 없는 작업: migration 검증

`N/A`는 절차 누락이 아니라 해당 작업에 필요하지 않다는 판단이며 사유를 함께 기록한다.

## 6. SQL 검증 기준

다음 변경에는 실제 프로젝트 DB 기준 SQL 검증이 필요하다.

- DB schema 또는 migration
- repository read/write path
- normalized table 또는 legacy fallback
- seed/work DB에 영향 가능한 변경
- 실제 데이터가 기능 동작에 영향을 주는 변경

SQL 결과 보고에는 조회 목적, 실행 SQL, 결과, 해석을 포함한다.
DB 구조나 데이터 의미 변경은 별도 사전 승인 후 진행한다.

## 7. 문서 영향 평가

기능, 구조, UX, 정책, 데이터 흐름 변경 시 관련 문서를 검토한다.
문서 갱신은 영향이 있을 때 수행하며, 영향이 없으면 사유를 보고한다.

문서의 성격을 구분한다.

- active authority
- reference/context
- migration/history
- changelog/status

현재 구현 snapshot이나 historical 문서는 최신 authority를 대체하지 않는다.

## 8. 커밋 전 보고와 승인

커밋은 사용자의 승인 후에만 진행한다.
커밋 전에는 다음을 보고한다.

- 작업 유형과 현재 브랜치
- 변경 파일과 파일별 요약
- 의도하지 않은 변경 여부
- 실행한 검증 명령과 실제 결과
- N/A 항목과 사유
- 문서 영향 평가
- 필요한 UI 테스트 체크리스트
- 제안 커밋 메시지

커밋 메시지는 한국어로 작성하고 하나의 의미 단위를 표현한다.

## 9. 병합과 push

병합과 push는 각각 사용자 승인 후에만 진행한다.
병합은 가능한 경우 fast-forward를 우선한다.

병합 전에는 작업 유형별 완료 기준, 테스트 결과, 문서 영향, Git 상태를 보고한다.
병합 후에는 다음을 보고한다.

- `main` 이동 여부
- 병합 방식과 fast-forward 여부
- merge commit 생성 여부
- push 결과
- 삭제한 로컬 브랜치와 남은 로컬 브랜치
- `git status --short --branch`
- local `main` / `origin/main` HEAD 일치 여부
- 최신 커밋 해시와 메시지

## 10. 완료 판단

완료는 실제 검증 결과가 있을 때만 선언한다.

- read-only audit: 변경 파일 없음, 확인 결과와 후속 후보 정리
- docs-only: 문서 수정, 위치·authority·충돌 확인, diff 검증
- test-only / guard: 보호 대상 명확화, 변경 테스트 실행
- cleanup / chore: 기능 변화 없음, 관련 명령어 검증
- production 기능 변경: 구현, 관련 명령어 검증, 필요한 UI 체크리스트, 문서 영향 평가

승인 없는 커밋·병합·push, 검증 없는 완료 보고, 수행하지 않은 UI 테스트 완료 보고는 금지한다.
