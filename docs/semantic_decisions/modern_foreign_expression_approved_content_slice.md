# 영어·현대 외국어 표현 정비 승인 기록

상태: active — 2026-10-10 사용자 위임 승인에 따라 작업 DB 적용·검증 완료. 표현 교정 기록이며 의미·관계 승인이나 semantic hold 결정이 아니다.

## 범위와 최종값

영어 155개 단어·166개 표현은 음역이 이미 모두 `NULL`이므로 삭제할 값은 0건이었다. 영어 원어·발음·의미는 보존하며 영어 음역을 다시 채우지 않는 정책을 승인했다. 기타 현대 외국어는 읽기 안내를 유지한다.

사용자는 아래 네 단어의 적절한 음역·발음 선택과 공란 보완, 작업 DB 수정 및 Git 완료를 위임했다. 근거가 부족하면 강제로 채우지 않는 조건으로 검토했으며 이번 대상의 미해결 항목은 0건이다. 정확한 전후 값·고정 출처·byte 지문은 [변경값 JSON](modern_foreign_expression_approved_changes.json)을 따른다.

| 식별자 / seq | 원어 | 최종 한글 음역 | 발음 표시 | 발음 체계 | 처리 |
|---|---|---|---|---|---|
| U0000_0002 / 1 | Zither | 치타 | [ˈt͡sɪtɐ] | ipa_phonetic | 초기 소문자 교정, 후속 음역·발음 본문 유지 및 체계 명시 |
| U0000_0003 / 1 | царь | 짜르 | [t͡sarʲ] | ipa_phonetic | 차리/짜리 교환, 발음 본문 유지 및 체계 명시 |
| U0000_0005 / 1 | timpani | 팀파니 | /ˈtim.pa.ni/ | ipa_phonemic | 발음 공란·체계 보완 |
| U0000_0006 / 1 | tìmpano | 팀파노 | /ˈtim.pa.no/ | ipa_phonemic | 발음 공란·체계 보완 |

DB의 `pronunciation`에는 바깥 대괄호·빗금 없이 본문만 저장한다. 네 단어 모두 `transliteration`·`pronunciation`이 채워져 있고 `pronunciation_notation_name`은 별도 명칭이 불필요하므로 `NULL`이다. 내부 id 7298·7299·7301·7302, seq·대표 여부·원어는 후속 적용에서 보존했다.

## 선택 근거와 한계

- **독일어:** 치타는 [ˈt͡sɪtɐ]를 옮기는 기존 한글 근사로 유지했다. 의미란의 관용명 치터에 음역을 자동 통일하지 않는다. 한글이 독일어 모음·파찰음을 정확히 재현한다는 뜻은 아니다. 명사 대문자 표기는 Duden과도 대조했다.
- **러시아어:** `rʲ`는 연음화된 자음이며 별도의 /i/ 모음이 아니다. 비기식 [t͡s]를 ㅉ으로 근사하여 짜르 하나로 정리했다. 르에도 보조 모음이 있으므로 실제 한 음절 발음과 같다고 설명하지 않는다. 한글에서 빠지는 연음화는 IPA에 보존했다.
- **이탈리아어:** 단수형의 /ˈtim.pa.no/는 고정 원문의 이탈리아어 절에서 확인했다. 복수형 /ˈtim.pa.ni/는 단수형 IPA와 복수형의 `tìm | pa | ni` 강세·음절 자료를 조합한 전사다. 복수형 IPA를 사전에서 직접 복사한 것으로 표시하지 않는다. 영어 timpani의 /ˈtɪmpəni/나 에스페란토 발음은 사용하지 않았다. 기존 한글값과 사전식 강세 철자 `tìmpano`는 유지했다.

필수 표기 검토 결과, 이번 변경은 표현의 발음 체계와 한글 근사에 한정한다. meaning·비고의 배치, 한자 병기·가운데점·합성 경계에는 변경이 없다. 다른 언어·기존 승인값의 일괄 변경 규칙으로 확대하지 않는다.

## 출처와 재사용 조건

확인일은 2026-10-10이다. 자료 제공자는 Wiktionary 기여자들이며 고정 문서와 그 이력으로 기여자에게 연결한다.

| 자료 | 고정 판본 | 가져오거나 대조한 사실 |
|---|---|---|
| [독일어판 Zither](https://de.wiktionary.org/w/index.php?title=Zither&oldid=10670429) | 10670429 | [ˈt͡sɪtɐ] |
| [영어판 царь의 러시아어 절](https://en.wiktionary.org/w/index.php?title=%D1%86%D0%B0%D1%80%D1%8C&oldid=92935751) | 92935751 | [t͡sarʲ] |
| [영어판 timpano의 이탈리아어 절](https://en.wiktionary.org/w/index.php?title=timpano&oldid=90623067) | 90623067 | /ˈtim.pa.no/와 복수형 timpani |
| [이탈리아어판 timpani](https://it.wiktionary.org/w/index.php?title=timpani&oldid=4038010) | 4038010 | 복수형, 강세·음절 `tìm | pa | ni` |

네 판본의 라이선스 표시를 확인하고 원문 HTML byte 지문을 보관했다. [Wikimedia 이용 약관 7절](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use#7._Licensing_of_Content)과 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)에 따라 상업적 이용·수정·재배포가 가능하다. 보호되는 재사용 자료와 가공물에는 출처·라이선스·변경 표시와 동일조건 공유 의무를 보존한다. [앱 자료 출처 안내](../legal/data_attributions.md)에 이를 반영했다.

새 IPA를 입력한 이탈리아어와 기존 IPA를 대조한 독일어·러시아어를 구분한다. 기존값의 과거 수집 출처를 소급 증명하거나 기존 DB 전체·앱 코드의 라이선스를 확정하지 않는다. 한글 음역 판단은 별도로 작성한 근사다. Duden·Treccani는 표기 비교에만 사용했으며 그 정의문·설명문·IPA 데이터를 전재하지 않았다. Wiktionary 원문 HTML·정의문·음원·이미지도 저장소·앱 배포에 편입하지 않았다.

## 실제 적용과 검증

초기 적용은 독일어 `zither → Zither` 1필드와 수정 이력 1개(id 5837)였다. 당시 러시아어 음역·이탈리아어 발음은 유보했으며 후속 사용자 지시로 이번에 해소했다.

후속 적용은 4표현의 7필드와 normalized 단어 수정 이력 4개(id 5838–5841), 관련 `sqlite_sequence`다. 두 단계를 합산하면 4표현의 8필드와 이력 5개다. 의미·비고·관계·식별자·schema·seed는 보존했다.

| 검증 | 실제 결과 |
|---|---|
| 원본 byte 백업·격리 사본 적용 후 실제 적용 | 완료, 사본·실제 적용 후 SHA-256 일치 |
| 13개 테이블·schema 전후 대조 | 승인 필드·이력·sequence 외 차이 0건 |
| `PRAGMA integrity_check` / `foreign_key_check` | ok / 위반 0건 |
| 대상 네 표현의 음역·발음 공란 | 각각 0건 |
| 영어 표현 음역 | 155단어·166표현 모두 NULL 유지 |
| 단어 / 표현 / 의미 / 관계 행 수 | 15,029 / 15,257 / 18,188 / 7,587 유지 |
| 후속 CHANGE_HISTORY 행 수 | 5,830 → 5,834 |
| seed SHA-256 | e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb 유지 |

작업 DB의 후속 적용 전 SHA-256은 `f95871ecdd8f7aee9f102369c954de401ed374e0189ace9dd002b685c814679f`, 적용 후는 `25be68d0887105b1b42413431bf71b8c528deaf810b22751c5db5facd2057c86`다. 앱 코드·상설 도구·테스트 파일을 변경하지 않았다. UI·runtime undo는 실행하지 않았으며 데이터 교정의 명령어 검증과 구분한다.

조회 목적은 지정 네 단어의 최종 표현·체계·공란을 확인하는 것이다. 다음 SQL의 매개변수는 네 대상 id이며 결과는 위 최종값 표의 4행, 음역·발음 공란 각각 0건이다. 전체 전후 비교·실제 UPDATE와 이력 검증은 로컬 적용 계획 및 receipt에 보관한다.

```sql
SELECT word_id, seq, spelling, transliteration, pronunciation,
       pronunciation_notation, pronunciation_notation_name
FROM word_expression_set
WHERE word_id IN (?, ?, ?, ?) ORDER BY word_id, seq;
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

표준 외부 `reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 공식 CLI로 갱신했다. JSON·Markdown은 현재 작업 DB 지문을 반영한다. canonical H/G 14,298행·summary·외부 출처 지문·CSV byte는 그대로다. explicit_approved 198·hold 5·unapproved 14,095·anomaly 113을 유지한다. U/E 표현 교정을 semantic 승인으로 가산하지 않는다.

DB·seed·백업·원자료는 Git 제외 상태를 유지한다. 초기 증거는 `data/backups/approved_content_batch/20261010_modern_foreign_expression_review/`, 후속 백업·계획·격리/실제 receipt·검증·진행 보고서 검증·Git closeout은 `data/backups/approved_content_batch/20261010_modern_foreign_expression_completion/`에서 확인한다. Git에는 정책·출처·정확한 변경값·이 결정 기록을 남기며, 기존 작업 브랜치 5개는 정리 대상에서 제외한다.
