# 고대 페르시아어·아카드어·우가릿어 정비 승인 기록

상태: active — 2026-10-10 전량 검토와 후속 피드백을 거쳐 사용자 승인대로 작업 DB 적용·검증 완료. 기존에 정비하지 않은 세 언어의 각 1단어가 대상이다. 정확한 전후 값·출처 판본·byte 지문·내부 id는 [변경값 JSON](other_ancient_languages_approved_changes.json)을 따른다.

## 최종 표현과 의미

| 단어 / seq | 원어 표기 | 한글 음역 | 발음란 | 발음 체계명 |
|---|---|---|---|---|
| U0000_0001 / 1 | 𐎶𐎦𐎢𐏁 | 마구쉬 | maguš | 고대 페르시아어 학술 읽기 전사 |
| U0000_0004 / 1 | 𒀸𒋩𒆠 | 앗슈르 | Aššur | 아카드어 학술 읽기 전사 |
| U0000_0004 / 2 (추가) | 𒀭𒀸𒋩 | 앗슈르 | Aššur | 아카드어 학술 읽기 전사 |
| U0000_0007 / 1 | 𐎍𐎛𐎋 | 라이카 | laʾika | 우가릿어 학술 재구 읽기 전사 |

네 표현 모두 `pronunciation_notation=other`와 위 체계명을 기록했다. 실제 음성을 확정한 IPA로 표시하지 않는다. 기존 원어·표현 id·대표 여부는 보존하고 아카드어 표현 2만 비대표로 추가했다.

| 단어 | 최종 meaning, seq 순서 | 처리 |
|---|---|---|
| U0000_0001 | 제사장(祭司長)[고대 이란 문화권의 마기] | 기존 의미 교정 |
| U0000_0004 | ① 아슈르[아시리아의 최고신(最高神)] ② 아시리아 ③ 아슈르 (지) | 신명 표기 교정, 나라명 보존, 도시 의미 추가 |
| U0000_0007 | 보내다 | 기존 의미 유지 |

세 단어의 비고에는 읽기·문자 전사·의미 범위와 불확실성을 기록했다. 전체 비고 원문은 변경값 JSON의 `words[].after.비고`에 보존한다. 별도 단어·Strong 번호·관계·표현과 의미 사이의 새로운 연결 구조를 만들지 않았다.

## 선택 이유와 남은 불확실성

**고대 페르시아어:** `maguš`를 마구쉬로 근사하고 현행 철자를 유지했다. 마즈다 한 신의 전속 종교 담당자로 제한하던 뜻은 마기 집단의 구성원을 가리키도록 조정했다. 사용자는 사제의 현대 가톨릭 연상을 피하기 위해 제사장을 선택했고, 미디아·페르시아 등을 포괄하도록 최종 설명을 고대 이란 문화권으로 확정했다. 여기서 이란은 현대 국가명으로 범위를 제한하는 말이 아니며 제사장이 최고 직급을 뜻하는 것도 아니다. 언어명은 고대 페르시아어로 유지한다. 집단의 정확한 사회적 범위·직무와 강세·모음 길이는 확정하지 않는다.

**아카드어:** 기존 지명 한정기호 `𒆠(ki)` 표기를 보존하고, 신명 한정기호 `𒀭(d)`를 가진 표현을 같은 단어의 seq 2에 추가했다. 두 한정기호는 읽지 않는다. 기존 나라명 아시리아는 유지하고 도시 아슈르만 seq 3 의미로 추가했다. 한정기호 없는 용례도 있으므로 기호 유무로 모든 용례를 자동 분류하지 않는다. 의미란 아슈르는 식별용 이름, 음역란 앗슈르는 `šš` 중복을 드러낸 한글 근사다. Wiktionary의 `Aššūr`·장모음 IPA와 ORACC의 `Aššur`는 표기 관습이 다르다. ORACC 정규화 읽기를 채택하되 길이 미표기를 단모음의 증거로 해석하지 않는다.

**우가릿어:** 문자 전사 `lỉk`와 모음을 보완한 읽기 `laʾika`를 구분했다. `ỉ`는 단순한 모음 i가 아니다. 라이카는 라·이·카의 근사이며 한글에서 드러나지 않는 성문폐쇄 `ʾ`는 발음란에 보존했다. 특정 완료형의 재구 읽기를 모든 활용형의 실제 발음으로 일반화하지 않는다. 완료형이라는 분석은 David Marcus의 원논문 57쪽 주 118과 독립 대조했으며, 비고의 통상 3인칭 남성 단수 설명은 형태 분석임을 구분한다. 의미는 사전형 보내다로 유지했다.

필수 표기 검토 결과, 의미에는 간결한 뜻과 식별용 이름을 두고 읽기·형태·한계를 비고에 배치했다. 제사장·최고신의 한자는 확인했으며 고유명사에 한자를 만들지 않았다. 새 합성 경계·가운데점 병기·semantic hold는 추가하지 않는다. 이 개별 승인으로 다른 언어의 기존 승인값을 자동 변경하지 않는다.

## 출처와 배포 조건

확인일은 2026-10-10이다. [앱 자료 출처 안내](../legal/data_attributions.md)에 제공자·판본·라이선스·가공 내용을 반영했다. 아래 고정 판본과 원문 HTML 지문은 변경값 JSON에 보존한다.

| 채택·대조 자료 | 사용 범위와 조건 |
|---|---|
| Wiktionary 기여자: 고대 페르시아어 판본 88090315·92163561, Aššūr 92525695, 우가릿어 75513432 | 철자·읽기·재구 읽기·뜻 대조. [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| University of Pennsylvania RINAP 4: 고유명사 사전, Q003230; Erle Leichty, lemmatization Jamie Novotny | Aššur 정규화와 신명·도시명·나라명 용례. 해당 프로젝트 본문 및 판본에 표시된 [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/) |
| Eleanor Robson, Oracc Nimrud Project: Aššur | 신명·도시·나라의 관계 대조. 해당 글의 CC BY-SA 3.0; 이미지 제외 |

상업적 이용·수정·재배포가 가능한 원천을 채택하고, 보호되는 자료와 가공물에는 출처·라이선스·변경 표시·동일조건 공유 의무를 보존한다. ORACC 전체나 출판사 PDF에 같은 허가가 있다고 확대하지 않는다. 한국어 설명과 한글 근사는 별도로 작성했다.

Tolman의 1908년 원저작물 OCR은 사실 대조용이며 설명문을 전재하지 않았다. Marcus 논문은 무료 열람과 재사용 허락을 구분하여 사실 확인에만 사용했다. Iranica의 마기 설명과 국립국어원의 한자 표기도 참고 사실 대조용이며 정의문을 옮기지 않았다. 허가가 확인되지 않은 현대 사전·교재 본문, NC·ND 자료, 원자료 HTML·PDF·판면·음원·이미지는 앱이나 저장소에 편입하지 않는다. 이번 출처 기록은 기존 DB 전체의 과거 provenance나 앱 코드 전체의 라이선스를 소급 확정하지 않는다.

## 적용과 검증

기존 일괄 적용 도구는 표현 교정을 지원하지 않으므로, 앞선 표현 정비와 같이 백업·사본 적용 후 일회성 SQL transaction으로 교정했다. 프로젝트의 상설 도구·앱 코드·테스트 파일은 변경하지 않았다. 기존 normalized 단어 이력 계약에 맞춰 단어마다 표현·의미·비고의 전후 값을 함께 기록했다.

| 검증 항목 | 실제 결과 |
|---|---|
| 변경 범위 | 기존 표현 3행의 12필드, 새 표현 1행, 의미 교정 2행·추가 1행, 비고 3개 |
| 변경 이력 | 단어별 update 3개, id 5842–5844; 기존 이력 전량 보존 |
| 새 행 | 아카드어 표현 id 19876 / seq 2, 의미 id 22787 / seq 3 |
| 13테이블·DDL·schema version 전후 대조 | 승인 범위·신규 이력·관련 sequence 외 차이 0건 |
| `PRAGMA integrity_check` / `foreign_key_check` | ok / 위반 0건 |
| 격리 사본 / 실제 적용 후 SHA-256 | 일치, sidecar 없음 |
| 전체 단어 / 표현 / 의미 / 관계 수 | 15,029 / 15,258 / 18,189 / 7,587 |
| CHANGE_HISTORY 행 수 | 5,834 → 5,837 |
| seed | SHA-256 불변 |

작업 DB SHA-256은 `25be68d0887105b1b42413431bf71b8c528deaf810b22751c5db5facd2057c86`에서 `780a78d9204a86b229f575c28d9d63a78d4435b102090dd16c605cc359cf6259`로 바뀌었다. seed는 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`를 유지했다. 기존 단어·표현·의미 id와 다른 언어·관계·언어명·Strong·그래프 설정·schema는 보존했다. UI·앱 runtime undo는 실행하지 않았으며 명령어 검증과 구분한다. UX·앱 코드 변경이 없어 별도 UI 테스트는 N/A다.

조회 목적은 승인한 최종 표현·의미·비고와 DB 정합성을 확인하는 것이다. 다음 SQL의 매개변수는 세 대상 id이며 표현 4행·의미 5행·비고 3개가 위 최종값과 일치했다.

```sql
SELECT word_id, seq, is_representative, spelling, transliteration,
       pronunciation, pronunciation_notation, pronunciation_notation_name
FROM word_expression_set WHERE word_id IN (?, ?, ?) ORDER BY word_id, seq;
SELECT word_id, seq, meaning
FROM word_meaning_set WHERE word_id IN (?, ?, ?) ORDER BY word_id, seq;
SELECT id, 비고 FROM WORD_TABLE WHERE id IN (?, ?, ?) ORDER BY id;
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

표준 외부 `reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 공식 CLI로 갱신했다. canonical H/G 14,298행·summary·외부 원천 지문·CSV byte는 동일하며 JSON·Markdown의 DB 지문과 snapshot identity를 현재 상태로 갱신했다. explicit_approved 198·hold 5·unapproved 14,095·anomaly 113을 유지한다. 세 U 단어는 Strong 집계 대상 밖이므로 이번 의미 교정을 canonical Strong 승인 수에 가산하지 않는다.

백업·승인 계획·일회성 적용 스크립트·사본/실제 receipt·진행 보고서 검증·Git closeout은 Git 제외 폴더 `data/backups/approved_content_batch/20261010_other_ancient_languages/`에 보관한다. 기존 외부 조사 보고서도 최종 승인·적용 상태를 반영한다. DB·seed·백업·원자료는 Git 제외를 유지하고, Git에는 정확한 변경값·결정·정책·출처 기록만 남긴다. 기존 작업 브랜치 다섯 개는 정리 대상에서 제외한다.
