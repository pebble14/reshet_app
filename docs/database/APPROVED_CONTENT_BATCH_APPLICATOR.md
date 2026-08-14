# 승인 콘텐츠 batch applicator v1/v2/v3

> 문서 분류: 내부 DB 운영 도구의 현행 계약
>
> 이 문서는 승인 완료된 meaning·word note·relation payload를 `reshet_work.db`에 원자적으로 반영하는 CLI의 입력·검증·복구 경계를 정의한다. 콘텐츠의 의미·어원·관계를 판단하거나 사용자 UI 확인을 대신하는 문서가 아니다.

## 1. 목적과 범위

`tool/approved_content_batch.dart`는 사람이 별도로 승인한 콘텐츠를 JSON manifest로 전달받아 다음 operation만 지원한다.

- 단어별 `word_meaning_set` 전체 projection 교체
- v2 단어별 `WORD_TABLE.비고` exact before/after 교체
- v3 Strong 단위 승인 supersession metadata 검증과 보고
- `WORD_RELATION` 신규 생성
- 여러 operation을 한 SQLite transaction과 한 `CHANGE_HISTORY.group_id`로 기록
- 적용 가능성 dry-run과 실제 `WordRepository.undoLastChange()` 1회 복원 검증
- live apply 전 `VACUUM INTO` snapshot 및 적용 결과 보고서 생성

v1 manifest는 기존 meaning·relation 계약을 그대로 유지하며 `word_note_replacements`를 받지 않는다. v2는 v1의 operation에 word note 교체를 추가한다. v3는 v2의 DB operation을 그대로 유지하면서 completion authority용 Strong 단위 `supersedes` metadata를 추가한다. 다음 operation은 세 version 모두 지원하지 않는다.

- meaning 일부 행 patch
- 관계 수정·삭제
- `비고` 이외 단어 core와 expression 변경
- schema·migration 변경
- seed DB 반영 또는 work→seed 승격
- 번역·어원·관계의 자동 추론
- 앱 UI 변경이나 사용자 UI 테스트 자동화

## 2. 실행 명령

저장소 root의 Windows PowerShell에서 실행한다.

```text
dart run tool/approved_content_batch.dart --manifest <manifest.json>
dart run tool/approved_content_batch.dart --manifest <manifest.json> --apply
```

`--apply`가 없으면 항상 dry-run이다. 다른 read-only 검증 대상을 사용할 때만 다음처럼 `--database`를 지정할 수 있다.

```text
dart run tool/approved_content_batch.dart --manifest <manifest.json> --database <database.db>
```

`--apply`와 `--database`는 함께 사용할 수 없다. live apply는 저장소의 canonical `data/reshet_work.db`만 허용하며 seed DB와 다른 경로는 resolved path 검증에서 거부한다. 대화형 확인은 사용하지 않고 명시적 `--apply`와 manifest의 exact work DB SHA를 승인 경계로 사용한다.

성공은 exit code `0`, manifest·DB precondition 같은 검증 실패는 `2`, 임시 적용·undo·snapshot·transaction·post-commit 검증 같은 실행 실패는 `1`을 반환한다. stderr의 `검증 실패`와 `실행 실패` 접두어로 두 범주를 구분한다.

## 3. Manifest v1/v2/v3

입력은 UTF-8 JSON이며 YAML dependency를 사용하지 않는다.

```json
{
  "format_version": 1,
  "batch_id": "RESHET-EC-P2-...",
  "provenance": {
    "document_id": "승인 문서 식별자",
    "document_sha256": "64자리 소문자 SHA-256"
  },
  "target": {
    "expected_work_sha256": "64자리 소문자 SHA-256",
    "expected_user_version": 0
  },
  "meaning_replacements": [
    {
      "word_id": "H0000_0000",
      "before": [{"seq": 1, "meaning": "기존 값"}],
      "after": [{"seq": 1, "meaning": "승인 값"}]
    }
  ],
  "relation_creates": [
    {
      "word_id_1": "H0000_0000",
      "word_id_2": "H0001_0000",
      "category_code": "etymological",
      "relation_type": "root_shared",
      "status_code": "asserted",
      "direction_code": "undirected",
      "description": null,
      "relation_group_id": null,
      "note": null,
      "source": "승인된-source"
    }
  ]
}
```

검증 계약은 다음과 같다.

- `format_version: 1`은 위 exact top-level 계약을 유지한다. 기존 Git tracked v1 manifest를 자동 변환하거나 수정하지 않으며 `word_note_replacements`를 추가하면 unknown field로 거부한다.
- `format_version: 2`는 v1 필드 전체에 필수 top-level 배열 `word_note_replacements`를 추가한다.
- 알 수 없는 필드나 operation 종류, 묵시적 타입 변환을 허용하지 않는다.
- 문자열은 trim·정규화·번역하지 않는다.
- operation은 최소 1개여야 한다.
- 같은 word의 meaning replacement, 같은 word의 note replacement, 같은 unordered relation pair의 중복을 각각 거부한다. 같은 word가 meaning과 note 배열 양쪽에 한 번씩 있는 것은 허용한다.
- meaning `before`는 DB의 `(seq, meaning)` ordered projection과 exact 일치해야 한다.
- meaning `before`와 `after`가 같으면 no-op으로 거부한다. 각 projection의 `seq`는 양수이고 엄격한 오름차순이어야 하며 문자열은 빈 값일 수 없다.
- 관계의 두 word와 category/type/status lookup은 실제 DB에 존재해야 한다. type의 category도 manifest와 일치해야 한다.
- 관계 pair는 현행 `WORD_RELATION` CHECK에 맞게 `word_id_1 < word_id_2` canonical 순서로 명시해야 한다. 도구가 pair나 방향을 조용히 재정렬하지 않는다.
- 같은 unordered pair가 DB에 어떤 관계로든 존재하면 batch 전체를 거부한다.
- 관계 `source`는 manifest의 명시값만 저장하고 provenance에서 추론하지 않는다.
- manifest 원문 SHA-256을 계산해 dry-run 출력과 apply 보고서에 기록한다.

v2 word note operation은 다음 형식이다.

```json
{
  "format_version": 2,
  "batch_id": "RESHET-EC-P2-...",
  "provenance": {
    "document_id": "승인 문서 식별자",
    "document_sha256": "64자리 소문자 SHA-256"
  },
  "target": {
    "expected_work_sha256": "64자리 소문자 SHA-256",
    "expected_user_version": 0
  },
  "meaning_replacements": [],
  "word_note_replacements": [
    {
      "word_id": "H0000_0000",
      "before": null,
      "after": "승인된 비고"
    }
  ],
  "relation_creates": []
}
```

- note 값의 canonical 형식은 비고 없음인 `null` 또는 실제 값인 non-empty string이다.
- 빈 문자열과 whitespace-only 문자열은 거부한다. 입력을 trim해 다른 값으로 바꾸지 않으며 삭제는 `after: null`로 명시한다.
- `before`는 현재 `WORD_TABLE.비고`와 null/string을 포함해 exact 일치해야 한다. 대상 word 부재, before 불일치, before/after가 같은 no-op은 전체 batch를 거부한다.
- note-only v2 manifest도 기술적으로 허용하며 dry-run·history·undo 계약을 동일하게 적용한다.

v3 supersession metadata 계약은 다음과 같다.

- v3는 v2의 exact top-level 필드 전체와 필수 배열 `supersedes`를 가진다.
- 각 row는 `strong_number`와 `batch_id`만 가지며, `strong_number`는 `H5229` 같은 canonical Strong 형식이고 `batch_id`는 `-APPROVED-CONTENT-SLICE`로 끝나는 이전 승인 batch identity다.
- 동일 Strong·batch reference 중복과 self-supersession을 거부하며, supersession을 선언한 현재 manifest의 `meaning_replacements`에도 해당 Strong이 있어야 한다.
- applicator는 metadata를 manifest 보고서에 보존하지만 DB operation, history payload, undo 범위에는 사용하지 않는다. reference batch의 존재·해당 Strong 포함, tracked set의 batch ID 고유성, cycle과 active approval 결정은 completion gate가 전체 manifest set을 기준으로 fail-closed 검증한다.
- filename 순서나 Git timestamp는 승인 우선순위가 아니며 과거 manifest는 수정·삭제하지 않는다.

## 4. Dry-run 계약

dry-run은 원본 DB의 SHA와 sidecar 상태를 실행 전후 확인하고 원본을 수정하지 않는다.

1. manifest 구조와 대상 DB SHA·`user_version`을 검증한다.
2. SQLite sidecar(`-wal`, `-shm`, `-journal`)가 있으면 안전한 복제를 위해 거부한다.
3. read-only connection에서 runtime schema, `integrity_check`, `foreign_key_check`, word·lookup·meaning/note before·relation pair precondition을 확인한다.
4. 원본을 시스템 임시 디렉터리의 `reshet_work.db`로 exact 복제하고 SHA를 확인한다.
5. 임시 DB에서 모든 operation과 history를 exclusive SQLite transaction 하나로 적용한다.
6. meaning·승인 note·relation·history payload, 동일 history group, 승인 note 이외 word core와 대상 밖 semantic projection, integrity/FK를 검증한다.
7. 실제 `WordRepository.undoLastChange()`를 정확히 한 번 호출한다.
8. meaning/note before 복원, 생성 관계 제거, 해당 history 전체 inactive, 대상 밖 semantic projection, integrity/FK를 다시 검증한다.
9. 임시 디렉터리를 ownership 확인 후 정리하고 원본 DB SHA가 exact 불변인지 확인한다.

dry-run 성공은 단순 SQL 문법 검사가 아니라 현재 manifest가 대상 DB에 원자적으로 적용되고 현행 실제 undo로 한 번에 복원됨을 뜻한다.

## 5. Live apply 계약

live apply는 같은 manifest의 전체 dry-run이 먼저 성공해야 한다. 이후에도 work DB precondition을 다시 확인한다.

1. canonical work·seed DB와 sidecar 상태를 확인하고 seed 크기·SHA를 기록한다.
2. `DatabaseSnapshotService`의 검증된 `VACUUM INTO` 경계로 pre-write snapshot을 만든다.
3. snapshot의 runtime schema, integrity/FK, lookup과 meaning/note target before projection을 검증한다.
4. snapshot, manifest exact copy와 manifest SHA를 같은 backup 디렉터리에 보존한다.
5. source와 `VACUUM INTO` snapshot의 `schema_version`이 달라질 수 있음을 결과에 함께 기록한다.
6. 적용 직전 work SHA와 sidecar를 다시 확인하고 exclusive transaction 안에서 모든 DB precondition을 재검증한다.
7. meaning replacement와 note replacement마다 기존 canonical word update history 1행, relation create마다 기존 relation create history 1행을 같은 새 `group_id`로 기록한다. 같은 word에 meaning과 note가 함께 있으면 두 완전한 word history 행을 meaning→note 순서로 기록하며 한 번의 group undo로 모두 복원한다.
8. relation `updated_at`은 적용 시 생성하고 실제 ID·`created_at`·최종 row를 결과 보고서에 기록한다.
9. commit 뒤 exact projection, history, 대상 밖 값, integrity/FK와 seed 크기·SHA 불변을 확인한다.

backup 경로는 다음과 같다.

```text
data/backups/approved_content_batch/<UTC timestamp>/
  snapshot.db
  manifest.json
  manifest.sha256
  result.json
  summary.txt
```

`result.json`은 machine-readable 결과이고 `summary.txt`는 사람용 요약이다. transaction 내부 실패는 전체 rollback된다. commit 이후 검증이 실패하면 snapshot 경로, work·seed SHA와 실패 보고서를 보존하고 중단한다. 도구는 임의 후속 수정이나 snapshot 자동 복원을 수행하지 않는다.

## 6. 운영 책임 경계

- manifest 생성 전 콘텐츠 판단과 provenance 승인은 사람이 수행한다.
- 도구 성공은 콘텐츠가 언어학적으로 옳다는 판정이 아니다.
- semantic completion gate의 `explicit_approved` 근거는 계속 `meaning_replacements[].after` exact projection뿐이다. v2 note-only manifest는 승인 Strong을 만들지 않으며, meaning+note manifest의 note 불일치도 semantic completion state를 낮추지 않는다. note 적용 무결성은 이 applicator의 before/after·history·undo 검증에서 별도로 보호한다.
- 사용자 UI 확인은 자동화 대상이 아니며 필요한 콘텐츠 batch별로 별도 수행한다.
- seed DB 반영과 work→seed 승격은 별도 승인·검증 작업이다.
- `test/fixtures/approved_content_batch/p1_rehearsal_manifest.json`은 P1 절차 재현용 테스트 fixture이며 영구 콘텐츠 정책이나 재적용 지시가 아니다.
