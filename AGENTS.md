# AGENTS.md

## 1. 문서 역할과 프로젝트 범위

이 문서는 Reshet 저장소 전체에 적용하는 project-local 에이전트 지침이다.
하위 디렉터리에 별도 `AGENTS.md`가 있으면 이 문서와 함께 적용한다.

Reshet는 Flutter와 SQLite를 사용하는 단어 관계 탐색 도구다.

- 현재 우선 플랫폼: Windows Desktop
- 핵심 기능: 단어 상세 정보 확인, 단어 관계 그래프 탐색
- 주요 데이터 테이블: `WORD_TABLE`, `WORD_RELATION`
- 그래프 관계 데이터 기준: `WORD_RELATION`

모든 보고, 커밋 메시지, 새 공식 문서 기록은 한국어를 기본으로 한다.
코드 식별자와 기존 파일명은 프로젝트 관례를 따른다.

## 2. 승인과 실제 근거

- 사용자는 최종 승인자다.
- 코드, 문서, 설정, DB 파일은 사용자 승인 후에만 수정한다.
- 커밋, 병합, push도 각각 사용자 승인 후에만 진행한다.
- read-only audit은 파일 변경 없이 바로 수행할 수 있다.
- 설계, 정책, 스키마, UX 흐름, 구현 상태는 실제 파일·DB·Git 상태를 확인한 내용만 보고한다.
- 승인 범위를 넘어서는 충돌이나 추가 변경 필요가 발견되면 먼저 보고하고 승인을 받는다.

수정 제안에는 가능한 한 다음을 포함한다.

- 작업 유형과 목표
- 수정할 파일과 정확한 위치
- 삽입 / 교체 / 삭제 여부와 앞뒤 문맥
- 변경 범위와 금지 범위
- 검증 방법과 UI 테스트 초안
- 문서 영향 예상

## 3. 작업 유형

작업 시작 시 다음 유형 중 하나로 분류한다.

### Read-only audit

- 파일 변경 없음
- `main`에서 수행 가능
- 구현, 커밋, 병합, push N/A
- 변경이 필요해지면 그 시점에 적절한 작업 브랜치를 만든다.

### Docs-only

- 문서만 변경
- `docs/...` 브랜치 사용
- 앱 UI 테스트와 기능 동작 테스트 N/A
- 문서 위치, authority 성격, 기존 문서 충돌을 확인한다.

### Test-only / guard

- production code 변경 없이 테스트 또는 guard만 변경
- `test/...` 브랜치 사용
- 추가·수정한 테스트 실행 필수
- UI 영향이 없으면 UI 테스트 N/A

### Cleanup / chore

- 기능 변화 없이 내부 구조만 정리
- `chore/...` 브랜치 사용
- 명령어 기반 검증 필수
- UI 영향이 없으면 UI 테스트 N/A

### Production 기능 변경

- 앱 동작, UX, DB, repository, graph, 검색, 상세·편집 흐름에 영향
- `feature/...` 또는 `fix/...` 브랜치 사용
- 명령어 기반 검증 필수
- UX 판단이 필요하면 클라이언트 UI 테스트 필요
- 기능·UX·정책·데이터 흐름 변경 시 관련 문서를 갱신한다.

## 4. 기본 작업 흐름

기본 흐름은 다음과 같다.

설계 → 수정 제안 → 사용자 승인 → 구현 → 검증 → 검토 → 커밋 → 병합

작업 유형상 해당하지 않는 단계는 `N/A`와 사유로 대체한다.
작업은 하나의 목적을 검증 가능한 작은 단위로 나눈다.

검토 단계에서는 다음을 확인한다.

- 승인 범위 준수
- 기존 기능 영향
- 데이터 의미 보존
- 문서와 구현의 일치
- 의도하지 않은 파일 변경

## 5. 아키텍처와 코드 원칙

- 기본 계층은 `UI → State/Controller → Repository → Data Source`다.
- UI에서 SQL이나 Data Source를 직접 사용하지 않는다.
- Repository를 우회하지 않는다.
- 새 public boundary는 가능한 한 typed contract를 사용한다.
- `Map<String, dynamic>`은 legacy compatibility 또는 transition boundary에서만 최소화해 사용한다.
- 대규모 구조 변경은 별도 승인 없이 진행하지 않는다.
- 핵심 기능은 외부 네트워크 의존성 없이 동작해야 한다.

`lib/` 아래 Flutter/Dart 작업의 세부 규칙은 `lib/AGENTS.md`를 따른다.

## 6. 데이터와 SQL 검증

- SQLite 구조는 실제 프로젝트 DB를 기준으로 확인한다.
- 기준 문서는 `docs/database/SCHEMA.md`이며, 실제 DB와 불일치하면 즉시 보고한다.
- 데이터 구조, 관계 방향, 상태 코드, fallback 상태를 추측하지 않는다.
- DB 구조 변경과 데이터 의미 변경은 별도 사전 승인이 필요하다.
- transition / hybrid 상태를 실제 검증 없이 완료 상태로 선언하지 않는다.

다음 변경은 SQL 검증이 필수다.

- DB schema 또는 migration 변경
- repository read/write path 변경
- normalized table 또는 legacy fallback 변경
- seed/work DB에 영향을 줄 수 있는 변경
- 실제 데이터가 기능 동작에 영향을 주는 변경

DB와 무관한 docs-only, test-only, cleanup, UI/graph rendering 변경은 SQL 검증을 `N/A`로 처리할 수 있다.
SQL 결과 보고에는 조회 목적, 실행 SQL, 결과, 해석을 포함한다.

## 7. 검증 주체

핵심 원칙은 다음과 같다.

- 재현 가능한 명령어 기반 검증은 Codex가 수행하고 실제 결과를 보고한다.
- 사용자 경험 판단이 필요한 UI 기반 테스트는 클라이언트가 수행한다.
- Codex는 수행하지 않은 UI 테스트를 완료로 보고하지 않는다.
- 클라이언트에게 SQL 조회나 코드 검증 같은 명령어 기반 검증을 요구하지 않는다.

UI 테스트 안내에는 테스트 목적, 시작 화면, 조작 순서, 사람이 식별 가능한 테스트 데이터,
기대 화면 변화, 실패 증상, 완료 판단 기준을 포함한다.

## 8. 문서 관리

- 일반 Markdown 문서는 `/docs` 하위에 둔다.
- 예외는 `README.md`, `AGENTS.md` 계열이다.
- 기능, 구조, UX, 정책, 데이터 흐름 변경 시 문서 영향을 평가한다.
- 문서 영향이 없으면 사유를 보고한다.
- 새 문서나 새 section은 한국어로 작성한다.
- active authority 문서를 implementation log처럼 사용하지 않는다.

문서 성격을 구분한다.

- active authority
- reference/context
- migration/history
- changelog/status

## 9. UX와 그래프 방향

그래프는 단어 관계 탐색의 핵심 surface지만 application shell 또는 유일한 workspace authority가 아니다.
고정된 “좌측 그래프 / 우측 상세” 구조와 초기 그래프 구현 단계는 historical/context 또는 점검 체크포인트로만 취급한다.

현재 UX 판단은 최신 active authority 문서를 우선한다.

- `docs/ux/workspace_ux_architecture.md`
- `docs/ux/navigation_policy.md`
- `docs/ux/responsive_layout_policy.md`
- `docs/ux/search_policy.md`
- `docs/ux/interaction_policy.md`

Phase 또는 audit 문서는 해당 문서에 명시된 authority 성격과 최신 구현 상태를 확인한 뒤 사용한다.

## 10. 의존성과 라이선스

새 패키지를 추가하기 전에 패키지명, 목적, 라이선스, 선택 이유, 대체 가능성,
기존 코드로 해결할 수 없는 이유를 보고하고 승인을 받는다.

- 기본 허용: MIT, BSD, Apache 2.0
- 금지: GPL, AGPL, LGPL 등 공개 의무가 발생할 수 있는 라이선스, 비상업·사용 범위 제한 라이선스

의존성 변경 후에는 `pubspec.yaml`, `pubspec.lock` 기준으로 변경 패키지와 라이선스를 검증한다.

## 11. Git 규칙

- 파일 변경이 있는 작업은 목적에 맞는 작업 브랜치에서 진행한다.
- 서로 다른 목적의 기능, 수정, 정리를 한 브랜치에 섞지 않는다.
- 커밋은 하나의 의미 단위로 구성하고 메시지는 한국어로 작성한다.
- fast-forward 병합을 우선한다.

커밋 전에는 현재 브랜치, 변경 파일, 의도하지 않은 변경 여부, 실행한 검증 결과,
문서 영향, 필요한 UI 테스트 체크리스트를 보고한다.

병합 후에는 다음을 보고한다.

- `main` 이동 여부와 병합 방식
- merge commit 생성 여부
- push 결과
- 삭제한 로컬 브랜치와 남은 로컬 브랜치
- `git status --short --branch`
- local `main` / `origin/main` HEAD 일치 여부
- 최신 커밋 해시와 메시지

## 12. 완료 기준

완료 보고는 실제 검증 결과에 근거한다.

- Read-only audit: 변경 파일 없음, 확인 결과와 후속 후보 정리
- Docs-only: 승인된 문서만 변경, 문서 충돌과 위치 확인, 명령어 기반 문서 검증
- Test-only: 테스트 목적과 보호 대상 명확화, 변경 테스트 실행
- Cleanup: 기능 변화 없음 확인, 명령어 기반 검증
- Production 기능 변경: 구현, 명령어 기반 검증, 필요한 UI 체크리스트, 문서 영향 평가

승인 없는 수정·커밋·병합·push, 추측 기반 구현, 검증 없는 완료 보고,
수행하지 않은 UI 테스트 완료 보고는 금지한다.
