# 라틴어 원어·발음·음역 정비 결정

- 기록 성격: 사용자 승인 결정과 작업 DB 적용 결과
- 결정일: 2026-10-10
- 최종 판단자: 사용자
- 전량 검수: 라틴어 159단어·166개 표현 세트
- 실제 적용: 158단어·165개 표현 세트
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md) 6-2절
- 개별 승인값·근거: [변경값 JSON](latin_expression_approved_changes.json)
- 출처 안내: [자료 출처 안내](../legal/data_attributions.md)

## 승인 범위와 결과

사용자는 제3자의 상업 이용·수정·재배포가 가능한 출처로 재검토한 라틴어 제안을 승인했다. 42개 표현의 원어·발음·음역 본문과 165개 표현의 발음 표기체계 정보를 정비했다. 두 수는 겹치며, 123개는 표기체계 정보만 바뀌었다. Rachel 1개는 모든 값을 유지했다. 의미·관계·어휘 분리 결정은 승인 범위가 아니다.

| 필드·범위 | 실제 변경 표현 수 |
| --- | ---: |
| 원어 철자 | 1 |
| 기존 발음 수정 | 13 |
| 발음 공란 보완 | 20 |
| 발음 문자열 전체 | 33 |
| 한글 음역 | 12 |
| 원어·발음·음역 중 하나 이상 | 42 |
| pronunciation_notation | 165 |
| pronunciation_notation_name | 1 |

필드별 수는 겹친다. 적용 후 체계는 넓은 IPA `ipa_phonemic` 159개, 상세 IPA `ipa_phonetic` 5개, 라틴 문자 안내 `other` 1개, 발음 공란·체계 NULL 1개다. 단일 장모음은 한글을 두 음절로 늘리지 않고 IPA의 ː로 나타낸다. 실제 별도 모음의 연속과 중복 자음은 구분한다. 한글 받침을 포함한 원어 자음 대응을 우선하며 고전 라틴어 교재식 읽기의 범위와 한계는 정책에 기록했다.

## 본문 판단 유보 5개

| 대상 | 유지 원어 | 미해결 사항 |
| --- | --- | --- |
| L0000_0030 / 1 | Lýsĭas | y 모음의 장단: 기존값과 허용 출처 간 근거 차이 |
| L0000_0046 / 1 | Rachel | 발음 공란 |
| L0000_0052 / 1 | Sýrĭa | y 모음의 장단: 기존값과 허용 출처 간 근거 차이 |
| L0000_0109 / 2 | mile | 단일/중복 l 독음 |
| L0000_0119 / 1 | pópŭlus | 의미가 다른 두 어휘의 구분 |

위 5개는 원어·발음·한글 음역 본문을 보존했다. Rachel 외 4개는 기존 IPA의 표기체계 정보만 정비했다. 이 유보는 DB의 semantic hold 설정이나 의미 승인에 가산하지 않는다. Lysias·Syria는 기존 IPA와 허용 출처의 장단 표시가 달라 현재값이 확정적으로 옳다는 뜻도 아니다.

## 출처·라이선스와 근거의 한계

외부 자료는 Reshet 자체의 비영리 여부와 별개로 제3자의 상업 이용·수정·재배포를 허용해야 한다. 현재 근거는 다음 범위로 한정한다.

| 자료 | 채택 범위·조건 |
| --- | --- |
| [Perseus Lewis & Short XML](https://github.com/PerseusDL/lexica/blob/edd73d89ce159e72a285829f849fb32ac250a4ea/CTS_XML_TEI/perseus/pdllex/lat/ls/lat.ls.perseus-eng2.xml) | 개별 어형·장단·본문 속 이름 대조. CC BY-SA 4.0의 출처·변경 안내·해당 재사용 자료의 동일조건 공유를 보존 |
| [DCC Allen & Greenough](https://dcc.dickinson.edu/about-dcc) | 음가·음절·강세·어말 장단·접미사 규칙. CC BY-SA 4.0 조건 보존 |
| [Bennett, The Latin Language (1907)](https://archive.org/details/latinlanguagehis00bennuoft) | 퍼블릭 도메인 원저작물 제3장 §§36–53. 현대 재게시본의 추가 주석 제외 |
| [FIPAT Terminologia Anatomica 2판](https://cdn.dal.ca/content/dam/dalhousie/pdf/library/FIPAT/TA2/FIPAT-TA2-Front-Matter.pdf) | 퍼블릭 도메인인 cranium·larynx 개별 용어의 철자만. CC BY-ND 4.0 PDF의 편집·설명·번역 제외 |

Perseus XML은 commit `edd73d89ce159e72a285829f849fb32ac250a4ea`, SHA-256 `a21c3799f42d33931b463c19a036b0e5c4a6504ccbd81ee55a262421a9e1836c`로 고정했다. 원자료 XML 자체를 수정하지 않았다. Bennett 원본 OCR SHA-256은 `b7f0bb0f6c4d14a016260b8b5e914b0a38252fc8a7df9b3921655ae4f91a00dd`이며 장단 기호의 OCR 오류를 고려했다. 자료별 이용 범위와 출처 의무는 변경값 JSON과 출처 안내에 함께 보존한다.

초기 보충 대조에 사용했던 Gaffiot 2016(CC BY-NC-ND), Vatican 웹 본문, 허가가 명확하지 않은 Alatius 현대 추가 주석은 현재 채택 근거에서 제외했다. 초기 비교 이력·캐시는 비공개 외부 조사 폴더에 보존하며 저장소·앱·공개 배포 묶음에 넣지 않는다. 사전 정의·설명문·배열이나 현대 웹 IPA를 전재하지 않았다. 새 IPA·한글 표기는 허용 자료의 어형·장단·규칙을 바탕으로 구성한 교재식 제안이며 사전의 공식 IPA나 기록 당대의 실제 발음으로 표시하지 않는다.

제한 자료로만 보충했던 Drusilla·Gallio·Iulia·Julia·Quirinius·Rachel 6개 표현은 허용된 L&S의 표제 또는 본문 용례로 독립 재확인했다. Gallio 어말 장음과 Quirinius의 일부 장단은 문법 규칙·관련 형태에 따른 추론이며 해당 용례에 길이가 직접 표시된 것은 아니다. 유지한 기존값의 과거 수집 출처나 기존 DB 전체의 재배포 허락을 이번 대조로 소급 확정하지 않는다. 코드·DB 전체의 최종 라이선스 결정도 별도다.

## 적용 경로와 보존 범위

이 절은 최초 표현 정비 시점의 적용 결과다. 이후 별도로 승인된 ID 정리 결과는 다음 절에 기록한다.

원본 byte 백업과 승인 계획을 만든 뒤 격리 사본에 먼저 적용·검증하고 실제 작업 DB에 반영했다. 기존 `WordRepository.updateWord`의 전체 단어 저장은 L0000_0030의 meaning 끝 공백을 제거하고 L0000_0003의 ID 끝 TAB도 잘라 승인 범위 밖 변경 또는 외래 키 실패를 일으킬 수 있었다. 이를 적용 전 대조에서 확인했다.

따라서 이번 적용은 저장소 밖 일회성 스크립트로 승인 expression 필드만 제자리 UPDATE하는 오프라인 데이터 교정으로 수행했다. 단일 SQLite 트랜잭션에서 변경 전 상태를 확인하고 기존 normalized 형식의 단어 수정 이력 158개를 추가했다. 앱 코드·Repository 실행 경로·schema·의존성을 바꾸거나 상설 검수·쓰기 도구를 추가하지 않았다. 앱의 undo 동작을 실행·검증했다는 뜻은 아니다.

- 전체 13개 테이블과 schema 전후 대조: 승인 expression 필드·새 수정 이력 및 관련 sqlite_sequence 외 동일.
- 모든 단어 ID, expression·meaning 내부 id, seq·대표 여부 보존. 내부 id 변경 0건.
- 의미·비고·언어·Strong 번호·관계·lookup·원자료 보관 값·기존 이력 보존. L0000_0030 meaning 끝 공백도 그대로 유지.
- 166개 최종 제안값 전량 일치, 본문 판단 유보 5개 보존.
- CHANGE_HISTORY 5,671 → 5,829행. 새 158개 group_id는 기존 및 서로 간 중복 없음. before/after 차이는 승인 필드에 한정.
- WORD_TABLE 15,029행, word_expression_set 15,257행, word_meaning_set 18,188행, WORD_RELATION 7,587행 유지.
- `integrity_check=ok`, 외래 키 위반 0건, 발음 metadata 위반 0건, work DB sidecar 없음.
- seed DB 미변경. UI·앱 undo 테스트 미수행 — 앱 동작·UX 변경 범위가 아니며 실제 SQL과 전 테이블 비교로 콘텐츠 적용을 검증.

실행 SQL의 핵심 형태와 조회 목적:

```sql
BEGIN IMMEDIATE;
SELECT * FROM WORD_TABLE WHERE id = ?;
SELECT * FROM word_expression_set WHERE word_id = ? ORDER BY seq;
SELECT * FROM word_meaning_set WHERE word_id = ? ORDER BY seq;
-- 승인 계획에서 바뀐 필드만 SET에 포함; 아래는 발음 변경 행의 형태.
UPDATE word_expression_set SET pronunciation = ? WHERE id = ? AND word_id = ? AND seq = ?;
INSERT INTO CHANGE_HISTORY
  (group_id, action_type, entity_type, entity_id, before_json, after_json, created_at, undone_at)
  VALUES (?, 'update', 'word', ?, ?, ?, ?, NULL);
PRAGMA integrity_check;
PRAGMA foreign_key_check;
COMMIT;
```

변경 전 단어·표현·의미 전체 상태를 확인한 다음 승인한 필드만 수정하고 전후 이력을 기록했다. 검증기는 전체 테이블·schema를 백업과 읽기 전용으로 대조했다. SQL 결과와 항목별 대조는 `live_validation.json`에 기록했다.

## ID 말미 TAB — 후속 승인으로 정리 완료

사용자는 ID 끝의 탭 입력이 의도한 바가 아니라고 설명했고, 변경할 단어·표현·뜻·관계·수정 이력을 사전 설명한 뒤 정리를 승인했다. 2026-10-10 작업 DB의 `L0000_0003\t`(U+0009)을 `L0000_0003`으로 교정했다. 새 ID는 사전에 존재하지 않아 충돌이 없었다.

| 실제 수정 대상 | 변경 |
| --- | --- |
| WORD_TABLE 1행 | id의 끝 탭 제거 |
| word_expression_set 내부 id 7133 | word_id 교정 |
| word_meaning_set 내부 id 203 | word_id 교정 |
| WORD_RELATION 내부 id 152 | word_id_2 교정; G0000_0008과의 연결 유지 |
| CHANGE_HISTORY 내부 id 5681 | entity_id 및 before_json·after_json 안의 단어·표현·뜻 ID 각 3곳 교정 |

합계 5개 행·11개 ID 참조를 교정했다. 기존 이력 1건에서는 대상 ID와 두 snapshot 안의 ID를 합쳐 7곳이 바뀌었다. 표현·뜻·비고·관계 종류·방향·출처, 모든 내부 행 번호, 이력의 시각·그룹·본문은 보존했다. CHANGE_HISTORY 행수는 5,829로 동일하며 새 앱 undo 이력을 만들지 않았다. 옛 ID와 원래 이력은 byte 백업 및 별도 적용 receipt로 추적한다.

원본 byte 백업 후 파일 사본에 선적용했고, 실제 작업 DB에도 같은 단일 트랜잭션으로 적용했다. 외래 키는 ON으로 유지하고 `defer_foreign_keys`로 검사만 트랜잭션 종료까지 유예했다. 승인된 참조를 모두 교정한 뒤 외래 키 검사와 무결성 검사를 통과하고 commit했다.

```sql
PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;
PRAGMA defer_foreign_keys = ON;
UPDATE WORD_TABLE SET id = :new_id WHERE id = :old_id;
UPDATE word_expression_set SET word_id = :new_id WHERE word_id = :old_id;
UPDATE word_meaning_set SET word_id = :new_id WHERE word_id = :old_id;
UPDATE WORD_RELATION SET word_id_2 = :new_id WHERE word_id_2 = :old_id;
UPDATE CHANGE_HISTORY SET entity_id = :new_id,
  before_json = :corrected_before_json, after_json = :corrected_after_json
  WHERE id = 5681;
PRAGMA foreign_key_check;
PRAGMA integrity_check;
COMMIT;
```

변경 전후 13개 테이블·schema 전량 대조에서 위 ID 필드 외 차이 0건, 작업 DB 전체 TEXT 열의 옛 ID 참조 0건, 외래 키 위반 0건, `integrity_check=ok`였다. 관계 ID 정렬 제약도 유지했다. 사본과 실제 DB의 적용 후 byte 해시는 일치했다. 앱 코드·schema·의존성·UI는 변경하지 않았으며 앱 UI·runtime undo는 실행하지 않았다.

배포용 seed DB와 `tool/data_provenance/manifests/seed_pronunciation_holds.json`은 byte 그대로 보존했다. 기존 seed에는 옛 ID가 남아 있으며 향후 seed 갱신 때 새 ID와 승인된 표현값을 별도로 맞춰야 한다. 과거 배포 문서·최초 제안·기존 백업은 당시 ID를 보존한다. 현재 상태 JSON은 새 ID를 사용하며 승인 변경값 기록에는 이전 ID와 현재 ID의 대응을 추가했다.

실행·백업 근거는 `data/backups/approved_content_batch/20261010_latin_id_tab_cleanup/`의 `snapshot.db`, `approved_plan.json`, `rehearsal_validation.json`, `live_receipt.json`, `live_validation.json`, `semantic_progress_validation.json`이다. 외부의 일회성 실행기를 사용했으며 프로젝트에 상설 도구를 추가하지 않았다.

## 표준 진행 보고서와 기록 위치

공식 `tool/data_provenance/semantic_progress_report.py`로 형제 폴더 `reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 재생성했다. 이 보고서는 canonical H/G Strong 14,298건을 대상으로 하며 라틴어 행은 포함하지 않는다. 따라서 canonical 행 전량·semantic_status·summary·anomaly·외부 출처 지문은 동일하고 CSV byte도 동일하다. JSON·Markdown의 작업 DB 지문과 snapshot identity는 적용 후 상태로 갱신됐다. CSV 상태는 JSON과 일치한다.

explicit_approved 198건, semantic hold 5건, unapproved 14,095건, anomaly 113건은 유지했다. 라틴어 표현 승인을 의미·관계 승인으로 가산하거나 공식 보고서의 대상을 임의 확장하지 않았다. 라틴어 전량의 최신값은 외부 `approved_application_final_state.json` 166행으로 별도 보관한다.

Git 제외 실행 기록: `data/backups/approved_content_batch/20261010_latin_expression_approved/`의 `snapshot.db`, `approved_plan.json`, `rehearsal_validation.json`, `live_receipt.json`, `live_validation.json`, `semantic_progress_validation.json`. 저장소 밖 기존 `latin_expression_audit_20261010`에는 최초 제안·출처 검토 이력과 `latin_expression_application_result.md`, `approved_application_final_state.json`을 보관한다. 최초 제안 JSON은 미승인 시점 이력 그대로 보존하고 자동 적용 원장으로 재사용하지 않는다.

| 파일 | 적용 완료 SHA-256 |
| --- | --- |
| 적용 전 work / snapshot.db | d61cb4c0eb37816b1e9d7eef8ff2cce04a5d5f66861cd667fb70e08283fb5933 |
| 표현 정비 후 work — ID 정리 전 | 05b0d5e680c0f1a8d5f2e9a6f028314ea0d00559ce83d979ab431214bbf3a6fd |
| ID 정리 후 현재 work | 07f7ab79ace2af4c384f12b1a663240a2dff1d7c9b4cbeb6c0467ecdbc8f86a8 |
| seed | e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb |
| 표준 semantic_progress.json | 7f17d9529bff6159852c50123e8e0ed0dbe193f66760fca2e445a66e2dd5295a |
| 표준 semantic_progress.csv | 162deadba4f41402ee22d9a07790dd50ebeb984fdc89684966e180108f39958d |
| 표준 semantic_progress.md | 13ec94673cb8d2c8c7ddcfcde9ec924f9de6fed398bbbf9a575e6d5a74320cd8 |

저장소 변경 범위는 이 결정·개별 변경값 JSON·표기 정책·결정 색인·provenance 및 출처 안내 문서다. 사용자는 DB 적용·검증 후 Git 커밋·main fast-forward 병합·push를 포함한 마무리를 승인했다. 기존에 보존하기로 한 5개 작업 브랜치는 유지하고 이번 `codex/latin-expression-reviewed` 브랜치만 통합·게시 확인 후 정리한다. DB·백업·검증 실행기·원자료 캐시는 Git 추적 대상에 추가하지 않는다. 최종 Git 결과와 DB 해시 보존 확인은 `data/backups/approved_content_batch/20261010_latin_id_tab_cleanup/git_closeout.json`에 기록한다.

이번 완료는 라틴어 전량을 대조하고 승인한 표현 정비와 후속 탭 ID 정리를 적용했다는 뜻이다. 본문 판단 유보 5개 해결, 모든 기존값의 과거 provenance 확정 또는 기록 당대의 실제 발음 복원을 뜻하지 않는다.
