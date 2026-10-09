# 헬라어 원어·발음·음역 정비 결정

- 기록 성격: 사용자 승인 결정과 작업 DB 적용 결과
- 결정일: 2026-10-10
- 최종 판단자: 사용자
- 조사 범위: 헬라어 6,005단어·6,106개 표현 세트
- 적용 범위: 1,271단어·1,290개 표현 세트
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md) 6-1절
- 개별 승인값: [변경값 JSON](greek_expression_approved_changes.json)

## 최종 결정

사용자는 최종 제안 중 「실제 활용형을 표제로 선택하는 추천 2건」을 제외한 나머지를 승인했다. 두 건의 기존 원어·발음·음역·발음 유형은 모두 유지한다. 실제 활용형의 존재만으로 사전이 채택한 표제의 문법적 성격을 바꾸지 않는다. 최초 제안 1,292개에서 두 건을 제외한 **1,290개**가 최종 적용 범위다. 기존 보류 7개도 변경하지 않았다.

| 대상 | 보존 원어 | 보존 발음 | 보존 음역 | 철회한 교체안 |
| --- | --- | --- | --- | --- |
| G2467_0000 / 1 | ἴσημι | is'-ay-mee | 이세미 | ἴσασιν / ísasin / 이사신 |
| G4483_0000 / 1 | ῥέω | hreh'-o | 레오 | ἐρῶ / erō̂ / 에로 |

Strong은 G2467의 ἴσημι를 일부가 가정한 기반형으로 기록한다. 행 26:4의 ἴσασιν은 실제 활용형이지만 이를 대체 표제로 삼으면 기존 기록의 성격이 달라진다. G4483도 Strong의 ῥέω 표제와 λέγω 활용군의 미래형 ἐρῶ를 구분한다. G4482의 동철자 ῥέω와 의미·관계를 합치지 않는다. 활용형을 비고나 별도 표현으로 추가하는 일은 이번 승인에 포함하지 않았다.

근거: [고정 Strong XML](https://github.com/morphgnt/strongs-dictionary-xml/blob/dd6758b82f46b620804a8ea677d715844679eea1/strongsgreek.xml), [고정 TAGNT](https://github.com/STEPBible/STEPBible-Data/tree/b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39/Translators%20Amalgamated%20OT%2BNT), [Mounce λέγω](https://www.billmounce.com/greek-dictionary/lego).

## 승인된 적용과 표기 기준

| 필드 | 실제 변경 표현 수 |
| --- | ---: |
| 원어 표기 | 258 |
| 발음 문자열 | 659 |
| 발음 문자열 또는 유형·체계명 | 666 |
| 한글 음역 | 621 |

필드별 수는 겹친다. 발음 유형 코드 666건·체계명 665건을 정비했고, 새 교재식 로마자 읽기 전사 662건을 `other / 교재식 그리스어 읽기 전사`로 기록했다. 발음 공란 124개 중 121개, 한글 음역 공란 4개 중 3개를 보완했다. 나머지 공란은 보류 항목에 속한다.

한글 음역은 원어 형태를 보존하는 교재식 읽기다. ευ·ηυ는 에우, 단독 υ는 위 계열, σσ는 ㅆ, 다른 중복 자음은 적절한 받침+초성 등을 사용한다. 실제 별도 모음의 연속은 아아·오오·이이 등으로 보존하고 단일 장모음을 두 모음으로 늘리지 않는다. 원어와 맞는 Strong 안내는 유지하며 새 전사를 특정 시대의 실제 발음·IPA나 원본 Strong 안내라고 표시하지 않는다. 공통 기준과 한계는 표기 정책에 기록한다.

## 적용 보류 7개

| 대상 | 보류 이유 |
| --- | --- |
| G3753_0000 / 2, / 3, / 4 | ὅτε의 정상적인 성별 변화인지, 별도 구문·오입력인지 정체 확인 필요 |
| G2458_0000 / 1 | Ἰουνία·Ἰουνιᾶς 선택에 인명 해석 개입 |
| G0000_0114 / 1 | επαίσχυντος의 고대 원전 근거 미확인 |
| G0000_0208 / 1 | μέθῠστος의 독립 표제 근거·어휘 정체 미확인 |
| G0000_0337 / 1 | τράγω의 도리스식 현재형이라는 설명의 독립 근거 미확인 |

보류는 현재값을 보존한다는 뜻이다. 사용자 결정으로 표제를 유지한 위 2건은 이 미확인 7건과 구분한다. 개별 현재값·근거와 승인한 변경 전후 값은 변경값 JSON에 기록했다.

## 적용 및 검증

전체 6,106개 표현의 변경 전 값과 expression id를 실제 DB와 대조하고 원본 byte 백업을 만들었다. 격리 사본에 기존 `WordRepository.updateWord`로 적용·검증한 뒤 실제 작업 DB에도 같은 경로로 반영했다. 저장 경로는 단어별 트랜잭션과 기존 수정 이력을 사용한다. 최초 제안의 ID 보존은 단어 ID·자연 키 `(word_id, seq)` 보존으로 구체화하며, 기존 Repository가 재생성하는 expression·meaning 내부 id와 구분한다. 별도 SQL 쓰기 경로나 상설 검수 도구를 추가하지 않았다.

- 전체 13개 테이블과 schema 비교: 승인 범위 밖 표현 내용, meaning·비고·언어·Strong 번호·관계·lookup·원자료 보관 값·기존 이력 보존.
- 단어 ID·seq·대표 여부 유지. 내부 id 재생성: expression 1,311행, meaning 1,822행. 논리적 의미 내용은 동일하다.
- 사용자 유지 2건과 보류 7건: 모든 값과 내부 id 동일. 승인 변경값과 실제 DB의 전량 대조 일치.
- CHANGE_HISTORY: 4,400 → 5,671행. 새 1,271건의 group_id는 서로 구분되고 기존 그룹과도 겹치지 않는다. before/after payload 차이는 승인 필드에 한정된다.
- WORD_TABLE 15,029행, word_expression_set 15,257행, word_meaning_set 18,188행, WORD_RELATION 7,587행 유지.
- `integrity_check=ok`, 외래 키 위반 0건, 발음 metadata 위반 0건, work DB sidecar 없음.
- seed DB·source cache·canonical profile·앱 코드·의존성·schema 변경 없음. UI 테스트 N/A — 표현 내용 변경이며 UX 흐름 변경 없음.

실행한 핵심 SQL과 해석:

```sql
SELECT * FROM word_expression_set WHERE word_id = ? AND seq = ?;
SELECT * FROM word_expression_set ORDER BY word_id, seq;
SELECT * FROM word_meaning_set ORDER BY word_id, seq;
SELECT * FROM CHANGE_HISTORY ORDER BY id;
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

첫 조회는 승인값·유지값 대조, 전체 조회는 표현의 승인 밖 필드와 의미·기존 이력 보존, PRAGMA는 DB 무결성 확인에 사용했다. 다른 테이블도 전후 전체 행을 비교했다. 표현·의미의 내부 id 변화는 수정 단어에만 허용했다.

## 표준 진행 보고서와 기록 위치

공식 `tool/data_provenance/semantic_progress_report.py`로 형제 폴더 `reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 갱신했다. current_expression·current_expressions가 달라진 canonical Strong 행은 244개다. 전체 semantic_status·summary·anomaly·외부 출처 지문을 보존했으며 작업 DB 지문은 적용 후 해시로 갱신했다. CSV 상태도 JSON과 일치한다. canonical Strong 14,298건, explicit_approved 198건, semantic hold 5건, unapproved 14,095건, anomaly 113건은 동일하다. 표현 정비 승인을 의미·관계 승인으로 가산하지 않았다.

로컬 실행 기록은 Git 제외 경로 `data/backups/approved_content_batch/20261010_greek_expression_approved/`에 보관한다. `snapshot.db`, `approved_plan.json`, `rehearsal_validation.json`, `live_receipt.json`, `live_validation.json`, `semantic_progress_validation.json`이 근거다. 상세 조사와 최신 전량 적용 상태는 저장소 밖 기존 `greek_expression_audit_20261009` 폴더의 `12_DB적용결과.md`, `approved_application_final_state.json`에 있다. 원래 제안 파일은 이력으로 보존하며 자동 적용 원장으로 다시 사용하지 않는다.

| 파일 | 적용 완료 SHA-256 |
| --- | --- |
| 적용 전 work / snapshot.db | 30be8a70e74e1aeff2ed7e5bc83409ccd3f9283ed5e5d04475573252f0464476 |
| 적용 후 work | d61cb4c0eb37816b1e9d7eef8ff2cce04a5d5f66861cd667fb70e08283fb5933 |
| seed | e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb |
| 표준 semantic_progress.json | 5746571dbe9ce36c8314e4a2bc10c7d0aaaff2c7758e666ac73a076389946a55 |
| 표준 semantic_progress.csv | 162deadba4f41402ee22d9a07790dd50ebeb984fdc89684966e180108f39958d |
| 표준 semantic_progress.md | 18f461290c2b5af04adf531281196c1d4413959108e63b73567e30fadb624ace |

이 문서와 정책·개별 변경값 JSON이 이번 저장소 변경 범위다. 사용자는 DB 적용 후 Git 커밋·main 병합·push를 포함한 마무리를 승인했다. DB 파일과 로컬 검증·백업 자료는 Git 추적 대상에서 제외한다. 최종 Git 결과와 DB 해시 보존 확인은 같은 로컬 실행 기록 폴더의 `git_closeout.json`에 보관한다. 기존에 보존하기로 한 5개 작업 브랜치는 유지하며 이번 헬라어 작업 브랜치만 게시 후 정리한다. 검수·적용에 사용한 일회성 파일은 저장소 밖에 보관하고 저장소 안 임시 적용기는 실행 지문을 남긴 뒤 제거했다.

이번 완료는 전량 대조 후 승인한 표현 정비의 적용 완료다. 보류 7건 해결, 모든 단어의 특정 시대 실제 발음 재구 또는 녹음 검증을 뜻하지 않는다. 새 근거나 실제 문제가 생기면 해당 항목에서 재검토한다.
