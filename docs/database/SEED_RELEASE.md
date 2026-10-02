# 배포용 seed 준비와 교체

이 문서는 개발자가 작업 DB에서 배포용 seed를 만드는 관리 절차다. 사용자 앱의 자동 콘텐츠 업데이트 기능은 아니다.

## 데이터 정책

- 원본은 프로젝트 `data/reshet_work.db`, 교체 대상은 `data/reshet_seed.db`다.
- 작업 DB의 표·행·구조를 보존한 후보에서 `CHANGE_HISTORY` 행을 제거한다. 사용자 승인으로 고정한 발음 보류 목록이 있는 경우에만 아래 예외를 적용한다. 원본 편집 이력과 작업 DB는 그대로 둔다. 후보의 삭제 흔적은 `secure_delete`와 `VACUUM`으로 정리한다.
- 비고, 어휘·의미·관계, lookup, 원자료 보존용 archive는 유지한다. RMAC 영문·코드·구조는 유지하고 한글 설명만 아래 승인 번역 예외를 적용한다. 콘텐츠 정당성이나 테스트/비공개 데이터 여부를 자동 판정하거나 자동 삭제하지 않는다.
- 앱 전체 백업과 다르다. 사용자 백업에서는 편집 이력도 보존하며 이 도구의 이력 제거 정책을 적용하지 않는다.
- 기존 seed와의 비교는 행 수뿐 아니라 실제 행 값을 비교한다. 사본은 SQLite 저장 배치가 달라질 수 있으므로 원본과 파일 SHA가 같아야 한다고 요구하지 않는다.

### 승인 발음 보류 예외

`tool/data_provenance/manifests/seed_pronunciation_holds.json`은 사용자 승인한 배포용 발음 보류 목록이다. 2026-10-02 승인 범위는 출처·발음 체계를 확정하지 못한 11개 expression의 발음 보류다. 단어 삭제나 의미 변경이 아니며 작업 DB와 기존 사용자 설치 DB는 보존한다.

`prepare`는 이 파일이 있으면 자동 적용한다. 목록은 format 1이며 각 행에 정확한 `word_id`, `seq`, `spelling`, `pronunciation`, `pronunciation_notation`, `pronunciation_notation_name` 원래 값을 기록한다. 중복 식별자, 대상 부재 또는 원래 값의 변경은 실패한다. 다른 어형을 추정해 적용하거나 이미 비운 값을 새로운 원래 값으로 받아들이지 않는다. 목록 수정·제거는 새로운 배포 정책 결정이므로 사용자 승인 후 수행한다. 보류 자료를 확인한 뒤 복원하려면 해당 항목을 별도 승인으로 목록에서 해제하고 후보를 다시 생성한다.

후보에서만 해당 expression의 발음 및 두 metadata를 NULL로 비운다. 발음 없이 metadata가 남으면 runtime 읽기 계약에 어긋나므로 세 값을 함께 비운다. 발음 보류 자체는 철자·음역·의미·비고·관계·ID·seq를 포함한 다른 모든 필드와 표를 유지한다. 아래 RMAC 번역 예외는 별도로 적용한다. 전체 projection 비교는 이 승인된 seed 변환과 이력 제거 이외의 차이를 거부한다.

발음 보류 도입 시 보고서 format 2에 목록의 원래 값과 파일 SHA256을 기록했다. 현재 format 3에도 이 정보를 유지한다. `content_preserved_except_history`는 보류가 있으면 false이며, 대신 `content_preserved_except_approved_holds_and_history`로 보존 검증을 명시한다. 승격 시 현재 목록과 보고서의 값·SHA가 같아야 하고, 보류가 있는 후보는 작업 DB SHA와 전체 내용을 다시 대조한다. 두 예외 목록이 없는 기존 프로젝트/격리 테스트는 기존 이력만 제거하는 동작을 유지한다. 활성 목록이 있는 상태에서 목록 없는 옛 후보를 승격할 수 없다.

### 승인 RMAC 한글 재작성 예외

2026-10-02 사용자 승인으로 `tool/data_provenance/manifests/seed_rmac_translations.json`을 배포 후보에 자동 적용한다. 현재 영문 설명 97종류를 MLV Teams의 공개 RMAC 페이지 55개와 대조했다. 페이지별 RMAC 전용 Public Domain 고지를 확인했고 설명의 URL과 HTML SHA256을 목록에 고정했다. 대소문자·마침표·따옴표·HTML 공백 및 기존 `towar d` 공백 차이는 대조에서만 정규화하며 DB 영문을 바꾸지 않는다. 공개 원천을 기준으로 한글 설명 94종류를 새로 작성한다. 과거 수집 사이트나 기존 번역 저작자 복구를 주장하지 않는다.

`tool/data_provenance/prepare_seed_rmac.py`는 DB를 읽기 전용으로 열고 정확한 영문 값과 번역의 대응을 검증한다. 원문 HTML 사본은 Git 제외 `build/play_release/rmac_sources/`에 보존하며 앱에 포함하지 않는다. 영문 값 집합이 달라지거나 공개 원천 대조·전용 공개 조건 확인이 실패하면 목록 생성을 거부한다. 목록을 다시 생성하거나 내용을 변경하는 작업은 승인 범위에서만 수행한다.

`SeedRmacPolicy`는 영문·한글 표의 RMAC 식별자가 정확히 같아야 적용한다. 후보의 `RMAC_TABLE_KR` 설명 열 10개만 영문 원천에 대응하는 새 번역으로 갱신한다. 영문 NULL은 한글도 NULL로 유지하며 원천 목록에 없는 영문 설명·중복 번역·잘못된 목록은 거부한다. 코드·행 수·schema·영문 표·어휘·관계·작업 DB·기존 사용자 DB는 보존한다.

보고서 format 3은 `rmac_translations_sha256`과 전체 전후 차이를 기록한다. `content_preserved_except_approved_seed_changes_and_history`는 발음 보류·한글 RMAC 재작성·편집 이력 제거 이외의 전체 내용과 구조 보존을 나타낸다. RMAC 예외가 있으면 기존 `content_preserved_except_history`와 `content_preserved_except_approved_holds_and_history`는 false다. 승격 때 현재 번역 목록 SHA와 작업 DB SHA를 재확인하고 전체 내용을 다시 대조한다. 활성 목록이 있으면 번역 예외가 없는 이전 후보의 승격은 거부한다. 목록이 없는 격리 프로젝트는 기존 동작을 유지한다.

## 사용 순서

앱과 DB 편집기를 종료한 뒤 저장소 루트에서 실행한다. 각 단계의 DB가 바뀌거나 SQLite sidecar가 남아 있으면 중단하며 자동 삭제하지 않는다. 도구 동시 실행은 공통 파일 잠금으로 차단한다.

```powershell
dart run tool/seed_release.dart prepare
```

이 명령은 work와 기존 seed를 읽고 기존 `DatabaseSnapshotService`의 `VACUUM INTO`로 사본을 만든다. 앱의 기존 검증기와 별도 외래키 검사, 승인 발음 보류·RMAC 한글 재작성·이력 제거 이외의 내용·구조 보존 검사, 별도 사본의 실제 runtime ensure를 수행한다. 원본 work에는 runtime ensure를 실행하지 않는다.
결과는 Git에서 제외된 `data/backups/seed_release/candidate_*/`에 보관한다.

- `candidate.db`: 편집 이력 없는 배포 후보
- `summary.txt`: 사람이 읽는 검사 결과와 테이블별 변경 수, 주요 변경 예시
- `report.json`: 기준 work/seed SHA, 후보 SHA, UTC 생성 시각, 전체 추가·삭제·수정 값

`report.json`이 없는 폴더는 실패한 준비 결과이므로 승격하지 않는다. 실패한 파일은 조사용으로 보존한다. 보고서에는 기존 seed의 내용도 포함되므로 공개 배포 파일에 함께 넣지 않는다.
작업본의 의미 항목 수가 줄어도 오류라고 단정하지 않는다. 비교 보고서로 의도한 삭제·통합인지 검토한다. 이 검토는 자동 테스트가 대신하지 않는다.

검사한 후보와 보고서를 승인한 뒤에만 다음 명령을 실행한다.

```powershell
dart run tool/seed_release.dart promote <report.json의_경로> <prepare가_출력한_보고서_SHA256>
```

승격은 이 프로젝트의 보고서만 받으며 보고서 SHA, 후보 SHA, 기존 seed SHA, 후보의 구조·무결성·외래키·이력 비움 상태를 재확인한다. 후보 생성 이후 work의 추가 연구는 승격 후보에 자동 포함되지 않는다. 최신 작업본을 원하면 prepare를 다시 실행한다.
이전 seed를 같은 후보 폴더의 `previous_seed.db`로 옮겨 보관하고, 검증한 후보의 임시 사본을 seed로 배치한다. 교체 또는 사후검증 실패 시 백업에서 원래 seed를 복구한다. 백업은 성공/실패 뒤에도 보관한다. 자동 복구까지 실패하면 오류에 표시된 백업으로 복구해야 하며 재실행으로 덮어쓰지 않는다.
도구 실행 중 프로세스 강제 종료·전원 차단 뒤의 자동 복구는 지원하지 않는다. seed가 없고 `previous_seed.db`가 남아 있으면 해당 파일을 보존하고 수동 복구한다.

## 배포와 검증 범위

seed 교체는 앱 빌드/배포나 기존 사용자의 work 교체를 수행하지 않는다. 새 seed로 빌드한 뒤 신규 초기화는 별도로 확인한다.
자료 버전의 앱 화면 표시, 사용자 선택 DB 교체, 콘텐츠 병합은 이 도구의 범위가 아니다. RMAC 설명 재작성은 기존 앱의 UI나 Repository 읽기 경로를 바꾸지 않는다. 현재 생성 기록은 날짜와 SHA로 식별한다.

자동 검증은 임시 DB에서 준비·승격 성공, 후보/보고서/seed 변경 거부, sidecar/잘못된 구조 거부, 교체 중 실패 및 사후검증 실패 복구를 확인한다. 실제 seed 승격과 Git 커밋·병합·push는 별도 승인 범위다.
