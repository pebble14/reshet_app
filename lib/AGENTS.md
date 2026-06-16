# AGENTS.md

## 1. 적용 범위

이 문서는 `lib/` 이하 Flutter/Dart 코드 작업에 적용한다.
승인, 작업 유형, Git, 문서, 검증 주체, 비용 효율 원칙은 루트 `AGENTS.md`를 따른다.
이 문서는 `lib/` 전용 구조와 구현 경계만 추가한다.

## 2. 변경 전 확인

Flutter 코드 변경 전에는 실제 source와 관련 문서를 확인한다.
다만 확인 범위는 작업의 핵심 질문과 변경 파일에 필요한 수준으로 제한한다.

특히 다음을 추측하지 않는다.

* 위젯 유형과 생성자 파라미터
* import 경로와 public API
* 모델 필드, raw map key, repository 메서드
* `BuildContext`와 상태 ownership
* DB 컬럼, 관계 방향, 상태·분류 코드
* 현재 route, graph, detail, search 흐름

수정 제안에는 파일 경로, 클래스·메서드 이름, 삽입·교체·삭제 여부,
앞뒤 문맥, 영향 범위, 검증 방법을 포함한다.

작업 중 다음이 확인되면 범위를 자동 확장하지 말고 먼저 보고한다.

* 지시 범위 밖 source 변경 필요
* route / state ownership 변경 가능성
* repository / DB / dependency 영향 가능성
* 기존 문서와 source 불일치
* 시간 비용 증가 대비 새 의사결정 가치 낮음

## 3. 계층과 구조

현재 주요 구조는 다음과 같다.

* `lib/main.dart`: 앱 시작점
* `lib/database/`: DB 연결과 Data Source
* `lib/data/models/`: 데이터 모델
* `lib/data/repositories/`: repository와 조회 경계
* `lib/ui/`: 화면 UI

기본 흐름은 `UI → State/Controller → Repository → Data Source`다.

* `lib/ui/`에서 SQL 또는 Data Source를 직접 사용하지 않는다.
* UI는 Repository를 우회하지 않는다.
* Repository와 모델은 실제 SQLite 구조와 일치해야 한다.
* 새 public boundary는 가능한 한 typed contract를 사용한다.
* raw `Map<String, dynamic>` carrier는 legacy compatibility 또는 transition boundary로 제한한다.
* 대규모 구조 변경은 별도 승인 없이 진행하지 않는다.

## 4. Flutter 코드 원칙

* 기존 프로젝트 패턴과 상태 ownership을 우선한다.
* 복잡한 widget tree는 의미 있는 메서드로 분리하고 중첩을 줄인다.
* `const`는 실제로 가능한 경우에만 사용한다.
* 주석은 역할이나 의도가 코드만으로 명확하지 않은 핵심 로직에만 추가한다.
* 임시 `print()` 디버깅은 확인 후 제거한다.
* 데이터 의미가 드러나는 모델과 이름을 우선한다.
* 작은 production slice로 해결 가능한 문제를 불필요한 감사 / 문서 / guard로 우회하지 않는다.
* 단, 변경한 영역의 명령어 기반 검증과 문서 영향 평가는 생략하지 않는다.

## 5. 그래프 / Explorer 작업 원칙

* 그래프와 Explorer 작업은 현재 production path와 최신 UX authority를 먼저 확인한다.
* 그래프 관계 데이터는 `WORD_RELATION`을 기준으로 한다.
* `WORD_TABLE`의 legacy 관계 컬럼을 그래프 주 데이터 소스로 사용하지 않는다.
* 중심 단어, 선택 단어, 상세 대상, 연결 단어의 의미와 ownership을 구분한다.
* graph engine, relation formatter, cache, repository 경계를 우회하지 않는다.
* 초기 그래프 단계와 Split View 목표는 historical/context 또는 점검 체크포인트로만 사용한다.
* 현재 UX 판단은 루트 `AGENTS.md`가 지정한 최신 `/docs/ux` authority를 우선한다.
* route, graph, detail, search 흐름 감사는 핵심 질문에 필요한 진입 경로와 owner 확인으로 제한한다.
* standalone route, embedded pane, full-detail route, delete owner 같은 boundary는 실제 source와 최신 active boundary를 대조한 뒤 판단한다.
* delete owner 이동, route 제거, workspace state 재설계처럼 ownership을 바꾸는 작업은 별도 승인 없이 진행하지 않는다.

## 6. 문서 영향

`lib/` 변경 전후에는 관련 `/docs` 문서를 검토한다.
문서는 영향이 있을 때 갱신하며, 영향이 없으면 그 사유를 보고한다.
문서 갱신이 불필요하면 그 사유도 보고한다.

특히 다음 변경은 문서 영향을 확인한다.

* public contract와 계층 구조
* 기능 또는 UX 동작
* repository read/write path
* DB 구조 또는 데이터 해석
* graph, search, detail, edit 흐름
* route/result/action ownership 경계

문서화는 후속 재사용 가치가 있을 때 수행한다.
이미 문서화된 결론을 반복하거나 단순 대화 요약 수준의 문서를 만들지 않는다.

## 7. 검증 기준

검증은 루트 `AGENTS.md`의 작업 유형과 주체 구분을 따른다.

* production code 변경: 관련 analyze/test 등 명령어 기반 검증 필수
* UI 영향이 있는 기능 변경: 클라이언트 UI 테스트 체크리스트 필요
* UI 영향 없는 test-only / cleanup: UI 테스트 N/A 가능
* DB read/write 영향 없음: SQL 검증 N/A 가능
* repository read/write, schema, migration, fallback 영향: 실제 DB 기준 SQL 검증 필수

코드만 변경되었다는 이유로 문서 영향 평가를 생략하지 않는다.
반대로 UI 또는 DB 영향이 없는 작업에 불필요한 UI·SQL 검증을 강제하지 않는다.

명령어 기반 검증은 변경 범위에 맞게 최소 충분하게 수행한다.
불필요한 전체 테스트나 광범위한 analyze를 자동으로 강제하지 않는다.
다만 변경한 영역의 검증은 생략하지 않는다.

## 8. 현재 구현 주의점

* `WordGraphScreen`과 관련 graph 구성요소의 실제 역할을 먼저 확인한다.
* 중심 단어, 선택 단어, 상세 대상의 현재 계약을 임의로 합치지 않는다.
* Word 모델 필드명과 DB 컬럼명 매핑을 혼동하지 않는다.
* 실제 데이터와 더미 데이터를 섞을 때 현재 단계와 사용 경계를 명확히 한다.
* normalized-only 완료, fallback 제거 등 transition 완료 상태는 실제 검증 없이 선언하지 않는다.
* Explorer embedded detail pane, full-detail route, standalone graph/detail route의 역할을 임의로 합치지 않는다.
* Explorer가 delete executor인지 result 해석자인지 같은 action ownership은 최신 active boundary와 source를 기준으로 판단한다.
