# Reshet 데이터 출처와 재배포 경계

> 문서 분류: 현행 data provenance policy
>
> 이 문서는 Reshet 데이터의 확인된 출처, 재배포 판단 경계와 향후 외부 데이터 입력 정책을 정의한다. 법률적 안전성을 단정하거나 코드·DB 전체의 라이선스를 확정하는 문서가 아니다.

## 1. 문서 목적

이 문서의 목적은 다음과 같다.

- 데이터가 어디에서 왔는지 확인 가능한 범위에서 기록한다.
- 재배포 가능한 데이터와 출처·라이선스가 아직 확정되지 않은 데이터를 구분한다.
- 외부 원천을 사용할 때 필요한 검증 경계를 정의한다.
- 향후 기여자가 출처를 기록하지 않은 외부 데이터를 추가하지 않도록 기준을 제공한다.

## 2. 적용 범위

이 문서는 앱 소스코드와 DB schema, Strong 번호·철자·발음, 한글 음역, 한국어 의미·설명, 단어 관계·메모 및 과거 참고 자료의 provenance 경계를 다룬다.

Phase 50-A 기준 데이터 규모는 다음과 같다.

- `WORD_TABLE`: 15,009행
- `word_expression_set`: 15,237행
- G Strong 단어: 5,523행
- H Strong 단어: 8,642행

이 문서는 현행 DB 전체의 폐기나 교체, 코드·DB 라이선스 확정, 외부 데이터 편입 또는 DB 값 변경을 지시하지 않는다.

## 3. 데이터 범주

| 데이터 범주 | 현재 성격 | 공개·재배포 상태 | 후속 |
| --- | --- | --- | --- |
| 앱 소스코드 | Reshet 작성 | 코드 라이선스 별도 확정 예정 | 라이선스 phase |
| DB schema | Reshet 프로젝트 구조 | 코드·문서 정책과 함께 관리 | 현행 유지 |
| Strong 번호 | 사실·식별자 | 공개 원천으로 재검증 가능 | provenance 확정 |
| 원어 철자 | 외부 참고 후 입력 | 공개 Strong 원천과 대조 | 선택적 재검증 |
| 발음(`pronunciation`) | Strong식 표기·IPA형·기타 형식이 혼재하고 항목별 출처 미기록 | legacy 값으로 보존하되 최종 active pronunciation으로 인정하지 않음 | profile·출처 확정 후 migration 분류 |
| 한글 음역 | 항목별 출처 미기록 | 현행 유지, 독점 권리 단정 금지 | 별도 정책 |
| 한국어 의미·설명 | 사용자 직접 작성 | Reshet 작성 데이터 | 라이선스 추후 확정 |
| 단어 관계·메모 | 사용자 작성·편집 | Reshet 작성 데이터 | 현행 유지 |
| e-Sword 모듈 | 제3자 전자 파생물 | 포함·재배포하지 않음 | 과거 참고로만 기록 |
| Wiktionary 자료 | 과거 참고 가능성 | 항목별 직접 provenance 없음 | 향후 사용 시 별도 기록 |

현재 유지 가능한 범위에는 단어 ID, 사용자가 직접 작성한 한국어 의미·설명, 사용자가 구성한 단어 관계·메모, Strong 번호와 공개 Strong 원천으로 재검증 가능한 대표 철자가 포함된다. 현행 `pronunciation` 값은 파괴적 변경을 피하기 위해 migration 전까지 보존하지만, 아래의 profile·출처 조건을 충족하기 전에는 최종 active pronunciation으로 인정하지 않는다.

`pronunciation` 전체는 migration 분류 대상이지만 모든 행을 일괄 변환하지 않는다. 다음 형식과 항목은 분류 과정의 우선 확인 대상이다.

- 히브리어 pronunciation 전반
- 발음 대신 음역이 저장된 값과 혼합 발음값
- 명시적인 IPA형 Strong expression
- 숫자·설명문 등 비정상 pronunciation
- 일부 secondary expression과 철자 variant
- 출처가 항목별로 기록되지 않은 한글 transliteration

## 4. 과거 입력 과정

사용자는 데이터 입력 과정에서 e-Sword의 Strong 사전 모듈과 Wiktionary의 철자·발음 정보를 참고했다. 그러나 현행 DB에는 항목별 원천 URL, 조회 날짜 또는 원천별 provenance가 기록돼 있지 않다.

따라서 특정 현재 값이 e-Sword 또는 Wiktionary에서 왔다고 단정하지 않는다. 현행 한글 음역 전체가 사용자 독자 저작물이라거나 현행 발음 전체가 Public Domain이라고도 단정하지 않는다. 이 자료들은 과거 참고 자료로 기록하고, 공개 원천과의 독립 대조를 통해 공식 provenance를 재정립한다.

## 5. Strong 데이터의 공식 기준

James Strong의 1890년 원판과 CrossWire SWORD Project의 Public Domain Strong 모듈은 Strong 데이터의 역사적·독립 대조 근거로 유지한다. Phase 50-Q부터 재현 가능한 전자 재구축 입력은 다음 두 원천의 고정 commit으로 한정한다.

| 언어 | 공식 전자 재구축 원천 | 고정 파일 | SHA-256 | 라이선스·표시 |
| --- | --- | --- | --- | --- |
| Greek | `morphgnt/strongs-dictionary-xml` commit `dd6758b82f46b620804a8ea677d715844679eea1`, version 1.9 | `strongsgreek.xml` | `91474213b208a4e487d35f85c10e5c90737acc69082dad15dec5431406003545` | CC0 1.0 |
| Hebrew | `openscriptures/HebrewLexicon` commit `21c9add13bc727d3a951361778e97e3ff7afd1ce` | `HebrewStrong.xml` | `a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4` | CC BY 4.0, `Open Scriptures Hebrew Bible Project` attribution 필요 |

Greek 원천은 `entry@strongs`, 머리부 `greek@unicode`, `greek@translit`과 해당 `greek` 뒤의 `pronunciation@strongs`만 사용한다. 설명 영역 이후 descendant `greek`·`pronunciation`, definition, derivation, KJV definition과 참조용 중첩 요소는 사용하지 않는다.

Hebrew 원천은 `entry@id`와 `entry`의 직접 자식 `w` 본문, `w@xlit`, `w@pron`만 사용한다. `BrownDriverBriggs.xml`, `LexicalIndex.xml`, `StrongHebrewG.xml`, 중첩 참조 `w`, BDB·TWOT·definition·설명문과 Strong 외 lexical index 콘텐츠는 사용하지 않는다.

원천 XML 자체는 변형하지 않고 ignored local cache에 둔다. Reshet 도구가 수행하는 Strong ID 정규화, NFC 비교, headword 필드 추출과 dry-run plan 생성은 원천과 구분되는 가공이다. Hebrew 가공물에는 CC BY 4.0과 위 attribution을 유지하고 변경·정규화 사실을 표시한다.

공식 전자 재구축 원천은 canonical source candidate의 근거다. DB의 `is_representative`는 기존 expression 내부 표시 정책이며 source candidate 선택 기준이 아니다. 원천 채택은 실제 DB migration 완료, 기존 모든 DB 값의 최초 provenance 입증, representative expression 변경 승인 또는 IPA profile 승인을 뜻하지 않는다.

Strong 원판·모듈과 고정 XML을 이용한 문자열 대조는 Strong식 철자·발음 표기의 재구축 근거일 뿐, 언어별 IPA profile이나 expression별 IPA provenance를 입증하지 않는다.

## 6. e-Sword 모듈 경계

Phase 50-A에서 확인한 `strong.lexx` 메타데이터는 다음과 같다.

- 제목: Strong's Hebrew and Greek Dictionaries
- 원자료 설명: James Strong의 *Strong's Exhaustive Concordance*에서 가져온 히브리어·그리스어 사전 자료
- 원자료 발행: 1890년
- 원자료 상태: Public Domain
- 전자 모듈 메타데이터: `Derivative Work`, `Copyright © 2002-2019 Rick Meyers`, `All rights reserved`

`strong.lexx`는 표준 SQLite 컨테이너지만 실제 `Definition`은 독자적인 BLOB 형식으로 저장돼 있다. Reshet는 다음 운영 경계를 적용한다.

- `strong.lexx` 파일 자체를 저장소나 배포물에 포함하지 않는다.
- e-Sword `Definition` BLOB을 추출·변환·재배포하지 않는다.
- e-Sword 모듈을 Reshet 공개 데이터의 공식 재배포 원천으로 사용하지 않는다.
- e-Sword는 과거 참고 자료로만 기록한다.

이 경계는 확인된 메타데이터와 Reshet의 운영 선택을 구분한다. e-Sword 제작자의 권리 범위를 추가로 추론하거나 모든 e-Sword 데이터의 법적 상태를 일반화하지 않는다.

## 7. Wiktionary·Wikidata 경계

Wiktionary는 과거 철자·발음 참고 자료였으나 항목별 provenance가 남아 있지 않다. 현행 DB의 특정 값이 Wiktionary에서 왔다고 단정하지 않는다. 향후 Wiktionary 자료를 직접 재사용한다면 사용 시점의 라이선스, 항목 URL, 확인 날짜와 가져온 필드를 별도로 기록한다.

Wikidata는 이번 감사에서 실제 원천으로 사용하지 않았으며 Reshet 현행 데이터의 출처로 선언하지 않는다. Wikidata의 라이선스 안내 링크는 향후 원천 검토를 위한 기준 정보일 뿐, 현재 데이터 사용 사실을 뜻하지 않는다.

### 기존 입력 범위와 배포 대조의 구분

사용자는 2026-10-01에 e-Sword Strong 모듈과 영어판·그리스어판 Wiktionary에서 복사한 범위가 철자와 발음 표기이며, 의미·비고는 자료를 참고해 직접 작성했다고 설명했다. 이는 입력 과정에 대한 사용자 진술이며 모든 개별 값의 원천 URL을 입증하는 것은 아니다. 한국어 의미·비고를 외부 사전 설명의 일괄 복사로 분류하지 않는다. 원문 설명의 직접 번역·각색이 확인되는 항목은 별도로 검토한다.

공개 Strong 원천과 현재 문자열의 일치, 원천 기반의 실제 교체 기록, 발음 표기 방식 분류는 서로 구분한다. Unicode 정규화·대소문자·아포스트로피 차이만 제거한 비교는 후보 분류에만 사용하며, DB 저장값 변경이나 역사적 출처 확정에 사용하지 않는다. 공식 발음이 아닌 음역과의 일치를 발음 정확성 검증으로 안내하지 않는다.

Wiktionary 원문 페이지는 현재 값의 대조 근거로 기록할 수 있지만 현재 철자로 만든 링크만으로 과거 복사 출처가 확인됐다고 기록하지 않는다. 재사용하는 보호 대상 자료는 해당 페이지의 조건을 확인하고 출처·라이선스·수정 안내 및 필요한 동일조건배포 범위를 갖춘다. 이 작업은 앱 코드 또는 DB 전체의 공개 라이선스를 임의로 정하지 않는다. 음역·IPA·Strong식 발음이나 서로 다른 시대·체계의 발음을 단순 문자열 차이 때문에 일괄 교체하지 않는다.

## 8. Reshet 작성 데이터

사용자가 직접 작성한 한국어 의미·설명과 사용자가 구성·편집한 단어 관계·메모는 Reshet 작성 데이터로 구분한다. 단어 ID와 Strong 번호는 식별자·사실 범주로 구분한다.

이 분류는 Reshet 작성 데이터의 최종 공개 라이선스나 현행 DB 전체에 대한 독점 권리를 확정하지 않는다. 특히 항목별 출처가 기록되지 않은 한글 음역과 외부 참고 후 입력한 철자·발음은 Reshet 작성 데이터와 같은 범주로 일괄 취급하지 않는다.

## 9. 현행 DB 공개 상태

- 현행 DB가 불법이거나 폐기 대상이라고 판단한 것은 아니다.
- 공개 원천과의 선택적 재검증이 완료되기 전에는 전체 DB에 단일한 자유 라이선스가 확정됐다고 선언하지 않는다.
- 코드 라이선스와 데이터 라이선스는 분리하여 결정한다.
- official data package의 공개 여부와 조건은 후속 phase에서 확정한다.

따라서 현재 저장소 상태를 이미 상업적 재배포가 가능한 최종 공개 상태로 안내하지 않는다.

## 10. 향후 데이터 변경 절차

2026-10-11 후속 승인에서는 Strong 원자료를 분명한 근거 없이 다른 표제로 바꾸지 않는 원칙을 재확인했다. G2458은 CC0 원자료의 악센트와 맞추고 인물 해석은 확정하지 않았다. 비Strong 라틴어는 기존 L&S(CC BY-SA 4.0) 근거에 따라 모음 길이·명시적인 교재식 독법·populus 어휘 구분을 정비했다. 역사적 독음의 미확정 사항과 사용자 입력 세 그리스어 어형의 근거 미확인은 비고에 보존한다. 정확한 범위·현재값은 [헬라어 결정](../semantic_decisions/greek_expression_approved_content_slice.md)과 [라틴어 결정](../semantic_decisions/latin_expression_approved_content_slice.md)의 후속 승인 및 개별 JSON을 따른다.

2026-10-10 사용자 지시에 따라 외부 자료 선정은 Reshet 자체의 비영리 여부와 별개로 **제3자의 상업 이용·수정·재배포가 가능한가**를 기준으로 한다. 비상업(NC)·변경물 배포 금지(ND) 조건이 붙은 보호 자료는 채택하지 않는다. 개별 용어·사실에 별도로 명시된 퍼블릭 도메인 범위는 제한된 편집물 전체와 구분한다. CC BY-SA 자료는 상업적 수정·재배포를 허용하므로 해당 재사용 자료의 출처·변경 표시·동일조건 의무를 보존하는 조건으로 사용할 수 있다. 이는 코드·DB 전체의 최종 라이선스를 정하는 선언이 아니다.

라틴어 표현 정비에서는 고정 Perseus L&S XML·DCC A&G(CC BY-SA 4.0), Bennett 1907 원저작물 및 FIPAT의 퍼블릭 도메인 개별 용어만 현재 근거로 채택했다. Gaffiot 2016·Vatican 웹 본문·허가 불명확한 현대 추가 주석의 보호되는 본문은 가져오지 않았다. 새 IPA·한글 표기는 어형·장단·문법 규칙을 대조해 구성했으며 기존값의 과거 수집 출처를 소급 확정하지 않는다. 자료별 범위·고정 버전·출처 조건과 실제 적용은 [라틴어 표현 정비 결정](../semantic_decisions/latin_expression_approved_content_slice.md)과 [자료 출처 안내](../legal/data_attributions.md)에 기록한다.

2026-10-10 초기 적용에서는 사용자 승인으로 영어·기타 현대 외국어의 음역 정책을 정리했다. 작업 DB의 영어 155개 단어·166개 표현은 이미 음역이 모두 `NULL`이므로 삭제 0건이며 이 상태를 유지한다. 독일어·러시아어·이탈리아어의 4개 표현은 한글 음역을 보존했다. 실제 교정은 `U0000_0002 / 1`, expression 내부 id 7298의 `spelling`을 `zither`에서 `Zither`로 바꾼 1필드다. 이 초기 적용에서는 러시아어 `U0000_0003 / 1`의 `차리/짜리`는 연음화 근사의 검토 대상으로 남겼으며 새 한글값을 확정하지 않았다. 이탈리아어 2건의 발음 공란도 유지했다. 의미·비고·관계·대표 여부·발음 metadata·다른 언어의 기존 표현은 변경하지 않았다. 아래 후속 적용 기록에서 러시아어 음역과 이탈리아어 발음의 유보를 해소한다.

독일어 명사의 대문자 표기는 [Duden의 Zither 항목](https://www.duden.de/rechtschreibung/Zither), 러시아어 어말 연음화의 성격은 [Gramota의 ь 설명](https://gramota.ru/biblioteka/spravochniki/pravila-russkoy-orfografii-i-punktuatsii/bukva-kak-znak-myagkosti-soglasnogo)과 대조했다. 이탈리아어 표기 검토에는 [Treccani의 tìmpano 항목](https://www.treccani.it/vocabolario/timpano/)을 참고했다. 이 자료는 언어적 사실의 비교 검토에 사용했으며 정의·설명문·사전 IPA 데이터나 원자료 파일을 새로 전재하지 않았다. 이번 적용은 기존 철자의 첫 글자 대소문자만 교정하며 기존 데이터 전체의 과거 provenance·배포 허락을 소급 확정하지 않는다.

원본 byte 백업 후 격리 사본과 실제 작업 DB에 같은 단일 트랜잭션을 적용했다. 표현 필드 1개와 기존 normalized 형식의 단어 수정 이력 1개(id 5837), 관련 `sqlite_sequence` 외 차이 0건이었다. 13개 테이블·schema 전후 대조, `integrity_check=ok`, 외래 키 위반 0건을 확인했고 사본·실제 DB의 적용 후 byte 해시는 일치했다. CHANGE_HISTORY는 5,829→5,830행이며 단어·표현·의미·관계 행 수는 동일하다. 작업 DB SHA-256은 `07f7ab79ace2af4c384f12b1a663240a2dff1d7c9b4cbeb6c0467ecdbc8f86a8`에서 `f95871ecdd8f7aee9f102369c954de401ed374e0189ace9dd002b685c814679f`로 바뀌었고 seed DB는 byte 그대로 보존했다. 앱 코드·schema·상설 도구를 추가·변경하지 않았으며 앱 UI·runtime undo는 실행하지 않았다.

조회·교정 SQL의 핵심 형태는 다음과 같다. 영어 조회 매개변수는 `영어`, UPDATE 매개변수는 `('Zither', 7298, 'U0000_0002', 1, 'zither')`다. 조회 결과는 단어 155개·표현 166개·음역 값 0개, UPDATE 결과는 1행이다.

```sql
SELECT COUNT(DISTINCT w.id), COUNT(e.id), COUNT(e.transliteration)
FROM WORD_TABLE w JOIN word_expression_set e ON e.word_id = w.id
WHERE w."언어" = ?;
UPDATE word_expression_set SET spelling = ?
WHERE id = ? AND word_id = ? AND seq = ? AND spelling = ?;
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

승인 정책은 [한국어 표기 정책 6-3절](../semantic_research/korean_lexical_notation_policy.md#6-3-영어기타-현대-외국어의-음역-승인-기준--2026-10-10)을 따른다. Git 제외 백업·승인 계획·사본/실제 적용 receipt·전후 검증은 `data/backups/approved_content_batch/20261010_modern_foreign_expression_review/`에 보관한다. 영어·기타 현대 외국어는 canonical H/G Strong 진행 보고서의 대상이 아니므로 이 정비를 의미·관계 승인이나 semantic hold 변경에 가산하지 않는다.

형제 폴더 `reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 공식 CLI로 재생성했다. JSON·Markdown의 작업 DB 지문과 snapshot identity는 적용 후 상태와 일치한다. canonical Strong 14,298행 전량과 summary·외부 출처 지문은 동일하고 CSV byte도 동일하다. explicit_approved 198건·hold 5건·unapproved 14,095건·anomaly 113건은 유지했다. 검증 결과는 같은 백업 폴더의 `semantic_progress_validation.json`에 기록한다.

같은 날 후속 사용자 지시에 따라 네 단어의 음역·발음 선택과 공란 보완을 위임받아 적용했다. `U0000_0002`의 치타·기존 IPA는 유지하고 체계를 명시했다. `U0000_0003`의 음역은 짜르로 교환하고 기존 IPA의 체계를 명시했다. `U0000_0005`·`U0000_0006`의 발음은 각각 `ˈtim.pa.ni`·`ˈtim.pa.no`로 채우고 `ipa_phonemic`으로 기록했다. 네 단어 모두 음역·발음 공란이 없으며 근거 부족으로 남긴 항목은 0건이다. 새 출처는 상업적 수정·재배포를 허용하는 CC BY-SA 4.0 Wiktionary 고정 판본 4개다. 독일어·러시아어 기존 IPA의 현재 대조 근거와 이탈리아어 새 발음의 근거를 구분하고, 복수형 IPA는 단수형 IPA와 복수형의 강세·음절 자료를 조합한 가공물로 표시한다. 출처·판본·HTML byte 지문·가공·라이선스 의무는 [현대 외국어 표현 정비 결정](../semantic_decisions/modern_foreign_expression_approved_content_slice.md), [정확한 변경값](../semantic_decisions/modern_foreign_expression_approved_changes.json), [자료 출처 안내](../legal/data_attributions.md)에 보존한다. 원문 HTML·음원·정의문은 저장소나 앱에 편입하지 않았다.

후속 적용은 4개 표현의 7필드와 normalized 수정 이력 4개(id 5838–5841), 관련 `sqlite_sequence`로 한정했다. 13개 테이블·schema 전후 대조에서 예상 밖 차이 0건, `integrity_check=ok`, 외래 키 위반 0건, 격리 사본·실제 적용 후 byte 해시 일치를 확인했다. 의미·비고·관계·식별자·대표 여부·seed는 그대로다. 작업 DB SHA-256은 `f95871ecdd8f7aee9f102369c954de401ed374e0189ace9dd002b685c814679f`에서 `25be68d0887105b1b42413431bf71b8c528deaf810b22751c5db5facd2057c86`로 바뀌었으며, CHANGE_HISTORY는 5,830→5,834행이다. 초기 적용까지 합산하면 표현 4행·8필드와 이력 5개다. 백업·적용 계획·receipt·전후 검증은 Git 제외 폴더 `data/backups/approved_content_batch/20261010_modern_foreign_expression_completion/`에 보관한다.

표준 외부 진행 보고서도 후속 DB 지문으로 공식 CLI를 통해 갱신했다. canonical H/G 행·summary·외부 출처 지문·CSV byte는 그대로이며 JSON의 작업 DB 지문·snapshot identity와 Markdown의 DB 지문만 현재 상태로 바뀌었다. 검증은 후속 백업 폴더의 `semantic_progress_validation.json`을 따른다. 이 표현 정비를 의미·관계 승인이나 semantic hold 변경에 가산하지 않는다. 앱 코드·상설 도구·schema 변경은 없으며 UI·runtime undo 검증은 실행하지 않았다.

고대 페르시아어·아카드어·우가릿어 전량 3단어도 2026-10-10 후속 피드백과 최종 승인대로 정비했다. `U0000_0001`은 마구쉬 / maguš와 `제사장(祭司長)[고대 이란 문화권의 마기]`, `U0000_0004`는 앗슈르 / Aššur와 신명 표기 `𒀭𒀸𒋩`·도시 의미 `아슈르 (지)` 추가, `U0000_0007`은 라이카 / laʾika와 의미 보내다 유지다. 세 단어에 읽기와 의미 범위·불확실성 비고를 추가하고 발음 metadata는 `other` 및 언어별 학술 읽기·재구 읽기 체계명으로 명시했다. 원어 기존 표기·언어명·Strong·관계·기존 id·schema·seed는 보존했다. [결정 기록](../semantic_decisions/other_ancient_languages_approved_content_slice.md)과 [정확한 변경값 JSON](../semantic_decisions/other_ancient_languages_approved_changes.json)에 최종값·원천 판본·가공 내용·라이선스·참고 전용 자료를 기록했다. [앱 자료 출처 안내](../legal/data_attributions.md)도 갱신했다.

이번 적용은 표현을 지원하지 않는 기존 일괄 도구와 구분한 일회성 오프라인 교정이다. 기존 표현 3행의 12필드·새 표현 1행·의미 교정 2행·추가 1행·비고 3개 및 normalized 이력 3개(id 5842–5844)로 한정했다. 전체 13테이블·DDL 비교에서 승인 범위·이력·관련 sequence 외 차이 0건, integrity ok·FK 0·sidecar 없음, 사본/실제 적용 후 byte 해시 일치를 확인했다. 작업 DB SHA-256은 `25be68d0887105b1b42413431bf71b8c528deaf810b22751c5db5facd2057c86` → `780a78d9204a86b229f575c28d9d63a78d4435b102090dd16c605cc359cf6259`, seed는 기존 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`를 유지했다. 전체 단어 15,029·표현 15,258·의미 18,189·관계 7,587·이력 5,837행이다. 백업·승인 계획·사본/실제 receipt·진행 보고서 검증·Git closeout은 `data/backups/approved_content_batch/20261010_other_ancient_languages/`에 보존한다. 원자료 HTML·논문 PDF·이미지는 앱이나 저장소에 편입하지 않았다.

공식 CLI로 표준 외부 진행 보고서 세 형식을 현재 DB 지문으로 갱신했다. canonical H/G 14,298행·summary·외부 원천 지문·CSV byte는 동일하고 승인 198·hold 5·미승인 14,095·anomaly 113을 유지한다. U 단어는 Strong 집계 밖이므로 이번 의미 교정을 canonical Strong 승인 수에 가산하지 않는다. 별도 외부 기타 언어 조사 보고서에는 승인·적용 결과를 반영했다. 앱 코드·상설 도구·테스트 파일 변경은 없으며 UI·앱 runtime undo는 실행하지 않았다.

외부 데이터를 새로 입력할 때 다음 항목을 기록한다.

- 원천 이름
- 원천 URL 또는 식별자
- 원천 판본·버전
- 확인 날짜
- 원천 라이선스
- 가져온 필드
- 수정·정규화 내용
- attribution 필요 여부

다음 작업은 허용하지 않는다.

- 라이선스가 불명확한 전자 사전의 대량 복사
- 잠긴 모듈의 추출·변환 결과를 공개 데이터에 편입
- 출처를 기록하지 않은 정의문·발음·음역의 대량 추가
- Public Domain 원전과 현대 파생 편집물을 같은 자료로 취급

외부 원천을 실제로 채택할 때는 원천별 조건, attribution과 변경 이력을 먼저 검토하고 기록한다. 이 절차는 데이터 구조·값 변경 승인을 대체하지 않는다.

## 11. Strong 원천 검증과 결정적 mapping 도구

`tool/data_provenance/manifests/strong_sources.json`은 두 공식 원천의 repository·commit·file·SHA-256·라이선스·attribution·필드 경계를 고정한다. `tool/data_provenance/strong_source_mapping.py`의 `fetch`는 이 manifest에서 재구성되는 정확한 raw GitHub URL만 허용한다. 임의 URL, branch 최신 파일과 mirror fallback을 받지 않으며, SHA-256이 다르면 XML parsing 전에 실패한다. 공식 XML은 `.gitignore`의 `tool/data_provenance/.source_cache/`에 두고 저장소에는 commit하지 않는다.

source와 DB expression의 migration 준비 mapping은 Strong ID로 식별되는 word 전체를 단위로 한다. 아직 매핑되지 않은 candidate와 expression에 `raw spelling + exact pronunciation`, `NFC spelling + exact pronunciation`, `raw spelling`, `NFC spelling` 순서로만 적용하고, 각 단계에서 서로 degree 1인 pair만 확정한다. pronunciation trim·case 변환·유사도, pronunciation-only 일치, source ordinal, DB `seq`, `is_representative`와 임의 첫 결과는 선택 기준으로 사용하지 않는다. 모든 candidate와 expression이 완전한 일대일 대응을 이루고 expression 구조 변경이 필요 없을 때만 word를 `auto`로 분류한다.

primary disposition은 `auto`, `exception`, `hold`로 상호 배타적으로 기록한다. cardinality 불일치, 모호한 bijection, 중복 source candidate, 잔여 candidate·expression, representative 무결성 이상과 expression 구조 변경 필요는 `exception`이다. 유효하지 않은 Strong ID, source 또는 DB target 부재, placeholder, 사용할 수 없는 headword와 지원하지 않는 source 구조는 `hold`다. source pronunciation이 없다는 사실만으로 word를 `hold`로 만들지 않으며, 이 경우 확정된 spelling 외 pronunciation·notation 변경 후보는 만들지 않는다.

source pronunciation이 있고 word 전체 mapping이 확정된 expression만 예상 `pronunciation_notation = strong_dictionary`, `pronunciation_notation_name = NULL`을 생성한다. notation은 표기 형식 metadata이며 provenance나 라이선스 자체가 아니다. 이 phase의 plan은 DB write path와 연결하지 않는다.

실행 예시는 다음과 같다.

```powershell
python tool/data_provenance/strong_source_mapping.py fetch
python tool/data_provenance/strong_source_mapping.py validate
python tool/data_provenance/strong_source_mapping.py dry-run `
  --db data/reshet_work.db `
  --output-dir "<GENERATED_PATH>\work"
python tool/data_provenance/strong_source_mapping.py parity `
  --left-db data/reshet_work.db `
  --right-db data/reshet_seed.db
```

`dry-run`은 `manifest.json`, `summary.json`, `mapping_plan.jsonl`, `exception_manifest.json`을 생성한다. 대형 mapping plan과 exception manifest는 generated output로 관리하고 기본적으로 commit하지 않는다. 도구는 SQLite URI `mode=ro`, `PRAGMA query_only = ON`, `integrity_check`와 실행 전후 SHA-256 불변을 확인한다. `parity`는 surrogate row ID를 제외한 Strong word·expression 의미 projection을 비교한다.

기존 `tool/data_provenance/strong_source_diff.py`는 사용자가 전달한 XML의 expression별 비교 결과를 확인하는 보조 도구로 유지한다. 해당 도구의 pronunciation-only·trimmed pronunciation을 포함한 독립 후보 선택은 migration 준비 mapping 계약으로 사용하지 않는다. 어느 도구의 일치 결과도 현행 값의 최초 출처, 승인된 IPA profile 또는 최종 IPA 원천 적합성을 입증하지 않는다.

### 11.1 Strong parser·mapping v2 현행 계약

`strong_sources.json`의 `parser_contract`는 historical replay를 위한 v1 기본값 `greek_headword_v1`·`hebrew_direct_w_v1`로 유지한다. v2는 `parser_contracts`의 `greek_forms_v2`·`hebrew_forms_v2`와 `meaning_projection_contract`의 `greek_meanings_v2`·`hebrew_meanings_v2`를 명시적으로 선택할 때만 사용한다. 기존 caller의 기본 dispatch를 v2로 바꾸지 않는다.

Greek v2 form tuple은 `source_key`, `source_document_order`, `form_role`, `spelling`, `transliteration`, nullable `pronunciation`, `source_language`, `xml_context`로 구성한다. 각 entry의 첫 direct `strongs_derivation`·`strongs_def`·`kjv_def` 이전 direct `greek`만 source form이며, 바로 다음 direct element가 `pronunciation`일 때만 짝을 이룬다. 첫 form은 `primary`, 이후 form은 `alternate`다. 고정 source의 form 분포는 0개 101 entry, 1개 5,453 entry, 2개 51 entry, 3개 17 entry, 4개 2 entry로 총 5,614 form이다. form-bearing entry는 5,523, multi-form entry는 70, 최대 form은 4다. 101 placeholder는 `forms=[]`, `source_not_used`로 제외하며 빈 candidate를 합성하지 않는다. G1520은 `εἷς / heîs / hice`와 `ἕν / hén / NULL`의 두 form으로 보존한다.

Hebrew·Aramaic v2 form tuple은 `source_key`, `source_document_order`, `form_role`, `spelling`, `transliteration`, `pronunciation`, `source_language_code`, `part_of_speech`, `xml_context`로 구성한다. 각 entry의 direct child `w` 정확히 하나만 `primary` form으로 사용하고 `source`·`note` 등에 포함된 nested `w`는 form이나 별도 expression으로 승격하지 않는다. 고정 source 8,674 entry의 언어 코드는 `heb` 5,393, `arc` 653, `x-pn` 2,628이다. `heb`는 `히브리어`, `arc`는 `아람어`로 매핑하며 `x-pn`은 derivation이나 기존 DB 언어로 추론하지 않고 `unresolved`로 유지한다. H0859 등의 nested variant import는 별도 phase 경계다.

meaning v2는 신규 source-only word의 read-only import projection에만 사용한다. Greek은 nonblank direct `strongs_def`, nonblank direct `kjv_def`, 하나 이상의 definition이 있을 때 마지막 definition 뒤 nonblank entry-level postscript 순서다. Hebrew·Aramaic은 nonblank direct `meaning`, nonblank direct `usage` 순서이며 선택한 `meaning` 내부 inline `note`는 같은 행에 보존한다. 빈 결과는 행으로 만들지 않고 남은 행의 `seq`를 1부터 연속 부여한다. 기존 DB의 normalized·legacy meaning은 이 계약으로 갱신하지 않는다.

plain-text renderer는 source order와 Unicode code point를 보존하고 Unicode normalization을 수행하지 않는다. XML whitespace `[ \t\r\n]+`만 ASCII space 하나로 축약하며, Strong 참조는 `G####`·`H####`, inline form은 spelling과 존재하는 `xlit`·`pron` marker, note는 `[note: …]`로 렌더링한다. 빈 attribute marker를 만들지 않고 source punctuation·case·기호와 중복 meaning을 보존한다. 승인되지 않은 inline tag는 누락하지 않고 fail-closed한다. 원천 XML은 수정하지 않으며 이 whitespace 축약·Strong ID 정규화·marker 렌더링은 Reshet 가공임을 attribution과 함께 표시한다.

mapping v2는 form 값을 정렬 기준으로 사용하지 않고 source document order를 expected expression `seq`로 사용한다. source spelling·pronunciation은 canonical이고, 기존 DB transliteration이 nonblank이면 유지하며 blank 또는 `NULL`일 때만 source transliteration을 사용한다. source pronunciation이 있으면 notation은 `strong_dictionary`, notation name은 `NULL`이다. 첫 form만 representative다. G1520 alternate는 read-only `insert_expression_candidate`로만 표시하고 DB에 적용하지 않는다. source `arc`·DB `히브리어` 불일치 518건은 적용 전 mapping에서 `source_db_language_mismatch_deferred`로 hold했으며, 11.3의 별도 언어 정합화 뒤에는 source `arc` 653건이 모두 DB `아람어`와 일치한다. mapping 자체는 계속 language update action을 생성하지 않는다.

source-only word는 `G####_0000`·`H####_0000` ID, source order expression·meaning, current schema의 `graph_expand_mode` 기본값, nullable `비고`, normalized·legacy projection과 relation 0건으로 계획한다. read-only projection은 `source_key ASC`, UTF-8, BOM 없음, `ensure_ascii=false`, key 정렬, compact JSONL object와 final LF로 직렬화한다. clear-language Hebrew source-only 20건 H1564, H1618, H1653, H1655, H1656, H1674, H1833, H2020, H2251, H2491, H2646, H3958, H4200, H4461, H5005, H5229, H5807, H6306, H6378, H6772는 Phase 50-W에서 repository work·seed DB에 적용했으며 H1655만 `아람어`, 나머지는 `히브리어`다. source-only `x-pn` 12건 H1649, H1721, H2044, H2647, H2650, H3160, H3184, H3265, H3959, H5011, H7288, H8206은 `source_language_x_pn_unresolved`로 계속 hold한다.

Hebrew 원천과 모든 Hebrew 가공에는 CC BY 4.0과 `Open Scriptures Hebrew Bible Project` attribution을 유지한다. Phase 50-W의 20건 import와 source `arc` 518건 language reconciliation은 각각 승인된 별도 production slice로 repository work·seed DB에 적용했다. 과거 표기 59건은 정확한 cohort·비교 provenance가 보존되지 않은 집계라 쓰기 기준으로 재사용하지 않았고, 2026-07-22 고정 source와 기존 mapping으로 재현한 source `arc` 12건만 11.4에서 별도 적용했다. 발음 불일치 505건, nested variant, 기존 meaning reconciliation과 그 밖의 active DB write는 계속 별도 승인 phase다. 이 v2 계약은 DB schema와 canonical storage structure를 바꾸지 않는다.

### 11.2 Phase 50-W HebrewStrong 20건 production manifest·active 적용 경계

`tool/data_provenance/manifests/phase50w_hebrew20_source_import.json`은 Open Scriptures `HebrewStrong.xml`의 고정 commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`와 SHA-256 `a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4`에서 source-only clear-language 20건의 전체 production payload를 고정한다. 현행 선택형 parser 식별자 `hebrew_forms_v2`와 meaning 계약 `hebrew_meanings_v2`를 사용하며, source order·Unicode code point를 보존한 plain-text projection과 Reshet의 whitespace·Strong 참조·inline marker 가공 고지를 함께 기록한다. 라이선스는 CC BY 4.0이고 attribution은 `Open Scriptures Hebrew Bible Project`다.

manifest 대상은 히브리어 19건과 아람어 1건(H1655)이며, DB 하나당 `WORD_TABLE` 20건, `word_expression_set` 20건, `word_meaning_set` 39건을 insert했다. update·delete와 relation·`CHANGE_HISTORY` 생성은 0건이다. `x-pn` source-only 12건은 `source_language_x_pn_unresolved` 사유로 제외하고 payload에 포함하지 않았다. manifest는 UTF-8·BOM 없음·LF·final LF·결정적 key/order 계약을 사용하며 source manifest, parser·mapping source, parser v2 projection과 전체·개별 payload SHA를 검증한다.

`tool/data_provenance/phase50w_hebrew20_source_import.py`는 active work·seed가 모두 `pre_apply`이고 전체·Strong 집계가 기대값과 일치함을 확인한 뒤 verified backup을 생성하고 두 DB에 manifest payload를 적용했다. work SHA-256은 `e5fff68a1538fe56826455133d1b4dd7fbdf23fd9d94ac7f08a6dcfa59585510`에서 `9545e8b49038f453cd969581a169ea8debfe441b7cea0745dd9bcd7bec8c36c5`, seed SHA-256은 `7ca9da527bae12aedc2883c8886580070e5b2a82a1974cf3c1240a5792d0ee3e`에서 `27c2f5d20fbb03e7aac1a822d0e48700626bf37a6a53b20001ab995654f72e0a`로 변경됐다. postflight에서 전체 15,029/15,257/18,188/7,416과 Strong 14,185/14,385/16,766 집계, protected projection, normalized·legacy exact, work·seed semantic parity, integrity check `ok`, foreign key 위반과 SQLite sidecar 0을 확인했다.

현재 상태는 **repository work·seed DB 적용 완료**다. verified backup은 `data/backups/phase50w/20260720T153431_661359Z`에 보존하며 원본과 backup SHA·크기, integrity·foreign key를 확인했다. 성공 result artifact는 `tool/data_provenance/migrations/phase50w_hebrew20_source_import_result.json`, SHA-256 `c6f116a3cc125584f4f0285fceb35f01b027334195f7f5a3907bea434aadd5d9`이며 `status=applied`, work·seed sidecar 0, active rollback 미발생을 명시한다. apply 또는 postflight 실패 시 양쪽 verified backup을 함께 복원하는 경계는 임시 DB fault injection으로 검증했고 active second-run은 DB·result·backup을 바꾸지 않은 `이미 적용됨 — 변경 0` no-op이다. 사용자가 `גֹּלֶם`, `גֶּשֶׁם`의 Hebrew·Aramaic 별도 항목, `גֹּשֶׁם`, `צָמָא` 검색·상세와 저장 없는 편집 화면 종료를 검증해 UI 테스트를 통과했다. result의 DB SHA는 결정적인 migration 직후 canonical repository DB SHA를 기준으로 하며, 앱 시작 시 인덱스 재생성으로 발생하는 물리 SHA 변경 방지는 별도 production 후속 작업이다. G1520 alternate expression, nested variant와 Android runtime migration은 Phase 50-W import와 분리되어 계속 미적용·보류한다. 당시 보류한 518건 Hebrew·Aramaic language reconciliation은 아래 11.3에서 별도 적용을 완료했다. 이번 적용은 DB schema, repository와 runtime 구조를 바꾸지 않는다.

### 11.3 HebrewStrong source `arc` 518건 언어 정합화

`tool/data_provenance/manifests/hebrewstrong_arc_language_reconciliation.json`은 `openscriptures/HebrewLexicon` commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`의 `HebrewStrong.xml`, SHA-256 `a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4`에서 `xml:lang=arc`이고 적용 전 DB 언어가 `히브리어`였던 Strong 518개와 각 word ID를 고정한다. source manifest SHA-256은 `29ef7dc4a7281c77c28bdb1fd6337b25d1e363f200e4ff93fe84bee6f8464fc5`, target Strong projection SHA-256은 `052e64a957ead92cfde964d1ee265c2a2b384866eaf7b76a0e9ff813554710c1`, target 전체 projection SHA-256은 `55600973f002563e998b8338ad7999380330d8046c096d871dc9b5ceaee41870`, manifest SHA-256은 `4e013f0c6c000ee9ec870c0564f4cae873baa7af03380a6e668fd240158d5bcb`다.

`tool/data_provenance/hebrewstrong_arc_language_reconciliation.py`는 work DB에 seed DB를 `ATTACH`한 단일 transaction에서 manifest의 518개 word만 `WORD_TABLE.언어 = 히브리어 → 아람어`로 변경한다. verified byte backup과 양쪽 복원 경계를 두며, target의 언어 외 전체 값, non-target word 전체와 언어, 전체 expression과 notation provenance, meaning, relation, `CHANGE_HISTORY`, schema projection을 전후 SHA로 보호한다. 임시 DB fault injection은 work update 직후 실패 시 work·seed가 모두 적용 전 SHA로 복원됨을 확인했고, 잘못된 사전 조건은 추가 write 없이 실패했다.

2026-07-21 repository work·seed DB에 각각 정확히 518행을 적용했다. source `arc` 전체 653건의 DB 언어는 적용 전 `히브리어` 518·`아람어` 135에서 적용 후 `아람어` 653·`히브리어` 0으로 바뀌었다. work SHA-256은 `9545e8b49038f453cd969581a169ea8debfe441b7cea0745dd9bcd7bec8c36c5`에서 `28c9a0ccdc5c951120eb95ed17465d9e161f869ea71eb951838042b489130168`, seed SHA-256은 `27c2f5d20fbb03e7aac1a822d0e48700626bf37a6a53b20001ab995654f72e0a`에서 `1a5ee7f23f812ff936137800f60346a1c84275f0a31e365c44b0f7eb32947a7b`로 변경됐다. 두 DB 모두 `integrity_check=ok`, foreign key 위반 0, target expression 추가·누락 0이며 두 번째 active apply는 backup·transaction·result 변경 없는 `이미 적용됨 — 변경 0`이다. 결과 artifact는 `tool/data_provenance/migrations/hebrewstrong_arc_language_reconciliation_result.json`, SHA-256 `714ba4a28a4beb6ae721167018948c7cf4e1bddf1eeb4331a153cb6bd7ec50df`다.

이번 slice 당시 표기는 정확한 cohort와 비교 provenance가 보존되지 않은 집계만 있어 변경하지 않았고, 그 집계를 후속 쓰기 기준으로 재사용하지 않았다. 2026-07-22에는 11.4의 재현 가능한 12건만 별도 적용했다. 발음 불일치 505건, source-only `x-pn` 누락 12건과 nested lexical form은 계속 변경하지 않았으며, x-pn 누락 projection은 work·seed 모두 12건, SHA-256 `b9748b7a07a48a8c4f922c90e28659a8af0d653f01a266ad462af1686d02731b`로 유지된다. Windows Debug는 repository `data/reshet_work.db`를 직접 사용하고 신규 설치·초기화는 `data/reshet_seed.db`에서 work DB를 생성하므로 이 repository DB slice가 반영된다. 기존 Android 설치는 app-private work DB를 유지해 packaged seed 갱신을 자동 병합하지 않으므로, 최종 DB 확정 뒤 조건부·idempotent runtime data migration과 release 검증을 수행하는 기존 배포 blocker 경계를 유지한다. 이번 slice에서는 Dart/runtime code를 변경하지 않았다.

### 11.4 HebrewStrong source `arc` 12건 표기 정합화

`tool/data_provenance/manifests/hebrewstrong_arc_spelling_sync.json`은 Open Scriptures `HebrewStrong.xml` 고정 commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`, XML SHA-256 `a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4`, source manifest SHA-256 `29ef7dc4a7281c77c28bdb1fd6337b25d1e363f200e4ff93fe84bee6f8464fc5`를 기준으로 한다. `hebrew_forms_v2`가 direct child `w`와 `source_language_code=arc`를 고정하고, historical replay parser `hebrew_direct_w_v1`과 기존 `strong_mapping_v2`의 degree-1 대응을 교차한다. Unicode normalization을 저장값에 적용하지 않고 source code point를 보존하되, 대상 연결에는 기존 `nfc_spelling_exact_pronunciation` 비교를 사용한다. 라이선스는 CC BY 4.0이며 attribution은 `Open Scriptures Hebrew Bible Project`다.

source `arc` 653 entry는 현재 DB의 653단어·654 expression과 연결되고 모두 DB 언어 `아람어`다. 기존 mapping은 574 expression을 `auto`, 79단어·80 expression을 `exception`으로 분류한다. v2 raw code-point 표기 차이는 90건이지만 이를 새 후보 규칙으로 사용하지 않았고, 기존 mapping에서 `auto`·`nfc_spelling_exact_pronunciation`·`nfc_only_match`·spelling-only를 모두 만족하는 H1123, H1247, H3479, H4887, H6606, H7593, H7595, H7598, H7662, H7972, H8086, H8122의 seq 1만 확정했다. 과거 ignored full-run 산출물과 현재 work·seed 재생성 결과의 12건 identity/value projection은 SHA-256 `0dbaa9ead5f2f4901c8cd05be181f24abdf1ec0bd06d30e03bc9800982d8c316`으로 일치했다. 과거 provenance 없는 59건 집계는 사용하지 않았다.

`tool/data_provenance/hebrewstrong_arc_spelling_sync.py`는 기존 `strong_source_migration.py`의 exact current/expected precondition, normalized/legacy parity, transaction rollback, verified backup·양 DB 복원과 비대상 projection 보호를 재사용한다. active 적용 전 임시 work·seed 복사본에서 동일 적용, 최종 parity와 두 번째 실행 변경 0을 확인했다. 2026-07-22 repository work·seed 각각 `word_expression_set.spelling` 12행과 대응 `WORD_TABLE.표기1` 12행만 source code point로 변경했다. 발음·notation·언어·Strong·음역·seq·대표 상태·표현 개수의 semantic 변경은 0건이다.

work SHA-256은 `28c9a0ccdc5c951120eb95ed17465d9e161f869ea71eb951838042b489130168`에서 `386fa3766ea0e8163376cc759c7357d37aed87632bd7bab302e1659696d4eec0`으로, seed SHA-256은 `1a5ee7f23f812ff936137800f60346a1c84275f0a31e365c44b0f7eb32947a7b`에서 `1d431b7e379dfe7cb1ab40ac01dc2a7a7174146371b5248a21d0a41a63c584d8`로 변경됐다. manifest SHA-256은 `9333431060a82a793d7d37b79747a46b90c96adf537ef5f96adce5879b7954dd`이고 verified backup은 `data/backups/hebrewstrong_arc_spelling_sync/20260722T141244_507564Z`에 보존한다. backup 대비 target 외 word/expression과 그 밖의 모든 table·schema·row count는 동일하고, work·seed target final projection과 전체 Strong projection도 동일하다. 두 DB 모두 `integrity_check=ok`, foreign key 위반 0이며 active 두 번째 apply는 backup·transaction 없이 `이미 적용됨 — 변경 0`이었다. manifest와 결과 artifact는 Git checkout 환경과 무관하게 같은 바이트 identity를 유지하도록 LF를 고정한다. 결과 artifact는 `tool/data_provenance/migrations/hebrewstrong_arc_spelling_sync_result.json`, SHA-256 `b05d690489a899c2745a1519347d7cca839bb75f99c3f75f88a10e4abc6e1059`다.

이번 slice는 앱 코드, read-source/repository, schema와 Android runtime migration을 변경하지 않았다. 기존 Android 설치의 app-private work DB 전파는 최종 DB 확정 뒤 통합 migration·release 검증 대상으로 계속 보류한다. data-only이며 전체 cohort를 SQL·targeted test·backup/current projection으로 검증했으므로 클라이언트 UI 수동 테스트는 N/A다.

### 11.5 P2 승인 한국어 meaning·직접 파생 관계 work DB slice

`tool/data_provenance/manifests/p2_approved_content_slice.json`은 승인 문서 SHA-256 `72f5c08c614348fc686f0446c1ed5657c94d5f04bdb482c6db3c47c2e2eaff3d`를 provenance로 고정하고, work DB SHA-256 `0f69929202c88b8560f6dd0b7b07b1ad29617ea9dd5226738a3466f731748fb9`의 source-only 영어 meaning projection을 exact precondition으로 사용한다. manifest SHA-256은 `21f0128d761e1bc5e0b9917b0a875ab55133d9763e283552799f1b3f98fd14cd`다. `H2020_0000 → 구원`, `H5005_0000 → 간음`, `H6306_0000 → 속량`, `H6772_0000 → 갈증`으로 active `word_meaning_set` 전체 projection을 각각 1행으로 교체했으며, Phase 50-W 원천 영어 meaning은 source manifest와 provenance에 계속 보존한다.

같은 transaction에서 `H5337 → H2020`, `H5003 → H5005`, `H6299 → H6306`, `H6770 → H6772`의 직접 파생 관계 4건을 생성했다. 네 관계는 모두 `category_code=morphological`, `relation_type=derived`, `status_code=asserted`이고, canonical pair 정렬 뒤 기반 Strong에서 파생어로 향하도록 각각 `w2_to_w1`, `w1_to_w2`, `w1_to_w2`, `w1_to_w2`를 저장했다. source는 P1 승인 관계 convention을 이어 `RESHET-EC-P2-H2020-H5337`, `RESHET-EC-P2-H5005-H5003`, `RESHET-EC-P2-H6306-H6299`, `RESHET-EC-P2-H6772-H6770`으로 기록했으며 선택 metadata는 `NULL`이다.

적용은 기존 승인 콘텐츠 batch applicator로 `data/reshet_work.db`에만 수행했다. work SHA-256은 `0f69929202c88b8560f6dd0b7b07b1ad29617ea9dd5226738a3466f731748fb9`에서 `8e269644a233ada5c4fb4a93cd6b018ae743d8a28a4972c8398edd928f085e2b`로 변경됐고, seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1786333230068470`에 word update 4행과 relation create 4행을 기록했다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260810T034029356000Z/snapshot.db`에 보존하며 크기 8,241,152바이트, SHA-256 `4d9aca0edb66e753a64cd897033e485b39b0495127256754c717055a077cadf0`, quick check `ok`, foreign key 위반 0이다.

dry-run의 임시 적용·실제 undo와 live apply의 exact projection·대상 밖 semantic digest·integrity/FK 검증이 통과했고 SQLite sidecar는 없다. 동일 manifest 재실행은 적용 전 work SHA 불일치로 write 전에 거부된다. `H6306_0000`의 대표 expression `פִּדְיוֹם`과 전체 expression table은 변경하지 않았으며 추가 형태는 별도 후속 후보로 유지한다. production Dart·테스트 코드와 UI/UX 동작은 변경하지 않았고, 콘텐츠 SQL 검증으로 범위를 닫았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.6 성경 어휘 Evidence Packet MVP 1

`tool/data_provenance/biblical_research_evidence_packet.py`는 Strong 번호 하나를 입력받아 기본 어휘 정보, 현재 Reshet meaning·nullable word note, ±10 번호창, Strong XML의 직접 참조, canonical 성경 occurrence와 로컬 번역·원전분해 참고자료를 결정적인 UTF-8 JSON으로 stdout에 출력하는 개발·연구 CLI다. 기존 Strong parser와 mapping 계약을 재사용하며 work DB와 모든 로컬 SQLite 자료는 read-only·query-only로 열고 실행 전후 SHA-256 불변을 확인한다.

Evidence Packet의 single-Strong·target 직접 참조 계약은 유지한다. 별도 `tool/data_provenance/lexical_relation_discovery.py`는 같은 고정 `strong_sources.json`과 fingerprint 검증을 재사용하고, relation research 전용 선택형 extraction으로 Greek의 `strongs_derivation`·`strongs_def`·`kjv_def`·entry-level `strongsref`와 Hebrew의 `source`·`usage`·`meaning`에 구조적으로 표시된 Strong reference를 포함한다. 각 source-target occurrence는 source language·container·결정적 순서, 기존 compact wording과 target 표시가 있는 reference-local context를 함께 보존하며, 동일 graph edge의 connectivity 중복을 억제해도 복수 source evidence는 버리지 않는다.

relation discovery의 기존 CLI는 outgoing·incoming reverse index를 기본 2-hop, 허용 1~3-hop으로 양방향 탐색하는 bounded 계약을 그대로 유지한다. `tool/data_provenance/semantic_research_batch.py`는 같은 index를 cluster 실행당 한 번 만들고 하나 이상의 출발 Strong에서 새 node가 없을 때까지 양방향 closure를 수행한다. semantic depth cutoff는 없으며 `--max-nodes`는 이번 실행의 node 확장·준비만 제한하고 미완료 frontier를 보존하는 실행 안전값이다. deterministic node·primary path·additional discovery reason과 incident edge의 복수 reference evidence를 유지하면서 cycle과 중복 준비를 억제한다. ±10 번호창은 target에서 한 번만 만드는 숫자 이웃이며 traversal seed나 semantic relation이 아니다.

batch는 cluster discovery를 먼저 끝낸 뒤 node를 `explicit_approved`·`hold`·미승인으로 분류한다. 승인 node는 현재 meaning·note와 completion authority를, hold node는 disposition 사유·근거·reopen 조건을 재사용해 full preparation을 생략하지만 두 경우 모두 해당 node를 통과한 relation traversal은 계속한다. 미승인 node는 관련 node를 포함해 각각 Evidence Packet, node 중심 lexical relation JSON과 Review를 같은 flat output 디렉터리에 준비한다. `00_research_state.json`은 source fingerprint·실행 option·seed identity·visited/frontier·node별 artifact hash와 오류를 검증하는 resume 자료이고, `00_review_queue.md`는 사람이 볼 순서를 정리한 derivative다. 두 파일 모두 semantic authority가 아니며 research discovery evidence를 relation assertion이나 approval로 승격하지 않는다. 최종 meaning·relation 판단과 승인은 계속 사람이 수행하고, 이 workflow는 DB를 읽기만 하며 schema·data를 쓰지 않는다.

canonical Hebrew·Aramaic occurrence는 `openscriptures/morphhb` commit `3d15126fb1ef74867fc1434be1942e837932691f`의 `wlc/` OSHB corpus를 사용한다. WLC 본문은 Public Domain, lemma·morphology는 CC BY 4.0이며 `Open Scriptures Hebrew Bible Project` attribution을 유지한다. augmented lemma 원문은 보존하고 숫자 slash component처럼 문법적으로 결정적인 경우에만 standard Strong으로 연결하며, 모호한 확장은 warning으로 남긴다. occurrence identity는 source-native OSIS verse로 유지하고 verse direct child의 `KJV:` note는 typed alternate 목록으로 별도 보존한다. 같은 kind의 서로 다른 복수 alternate와 `!b`처럼 현재 계약으로 확정할 수 없는 suffix는 임의 해석하지 않는다.

canonical Greek NT occurrence는 `STEPBible/STEPBible-Data` commit `b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39`의 TAGNT Mat–Jhn·Act–Rev 파일을 사용한다. `editions` 필드에 NA27 또는 NA28 membership이 명시된 token만 기본 canonical profile에 포함하고 다른 판본에만 존재하는 variant token은 occurrence count에서 제외한다. TAGNT base reference를 occurrence identity로 유지하며 `[KJV]`, `(NA)`, `{other}` alternate는 kind와 원문 표기를 보존한 별도 후보로 전달한다. `(NA)`가 있다는 이유로 occurrence identity나 모든 local target의 lookup key를 NA reference로 교체하지 않는다. 자료는 CC BY 4.0이며 `STEP Bible` attribution을 유지한다. 개별 corpus 파일의 실제 SHA-256, repository·commit·path, parser 계약과 canonical profile은 `tool/data_provenance/manifests/biblical_occurrence_sources.json`에 고정한다. raw corpus cache는 ignored `tool/data_provenance/.source_cache/biblical_occurrences/`에 두고 추적하지 않는다.

`HebGrkKo.dct`, `KJV_S.sdb`, `개역개정S.sdb`, `개역한글S.sdb`, `새번역.bdb`, `원전분해.sdb`는 reference-only 자료다. 파일명·승인된 SHA-256·역할·reference profile·경계는 `tool/data_provenance/manifests/local_research_reference_sources.json`에 기록하며 절대경로와 원본 파일은 기록하지 않는다. 현재 verse target 중 `kjv`만 KJV profile로 검증됐고 개역개정·개역한글·새번역·원전분해는 `unverified`다. source에 reference conflict가 없으면 기존 source-native same-key 조회를 `same_key_no_source_conflict` 근거로 유지한다. 명시적 alternate가 검증된 target profile과 하나로 대응할 때만 해당 alternate를 사용하고, explicit conflict와 `unverified` target의 조합이나 복수·특수 형식 ambiguity는 SQLite 조회 없이 `manual_review_required`로 닫는다. 선택한 alternate 조회가 실패해도 source-native나 다른 후보로 fallback하지 않는다. CLI는 fingerprint와 schema 불일치를 fail-closed한다. 로컬 row ID와 marker count는 cross-source key나 canonical occurrence count로 사용하지 않으며, 비표준 marker를 standard Strong으로 병합하지 않는다.

실행 예시는 다음과 같다.

```powershell
python tool/data_provenance/biblical_research_evidence_packet.py G32 `
  --local-sources ..\reshet_research_sources
```

Evidence Packet JSON은 전체 machine-readable evidence의 source of truth다. occurrence에는 source-native/base reference와 source-provided typed alternate를 보존하고, 각 local target 결과에는 target profile, 실제 lookup reference, reference 선택 근거, join 상태, lookup 수행 여부와 manual review 여부를 기록한다. `tool/data_provenance/biblical_research_evidence_review.py`는 이 JSON을 target 요약, 현재 Reshet meaning·note, canonical source meaning·usage, reference-only lexical 자료, Strong ±10, raw 번역 표현 빈도, occurrence 비교표와 접힌 상세로 재배열하는 local human-readable derivative다. batch가 선택형 node 중심 relation context를 전달하면 방향·source container·compact wording·reference-local context·복수 occurrence와 관련 Strong 상태도 함께 표시한다. renderer는 성경 source나 DB를 직접 읽지 않고 source 문구를 semantic relation assertion으로 바꾸지 않는다. Review는 정상 자동 join의 lookup reference와 선택 근거, 일반 `unmatched`, 의도적으로 lookup을 생략한 `manual_review_required`를 서로 구분하고 manual 사례에는 source-native reference와 alternate 후보를 함께 표시한다.

```powershell
python tool/data_provenance/biblical_research_evidence_review.py `
  ..\reshet_research_output\G32_evidence_packet.json `
  --output ..\reshet_research_output\G32_review.md
```

`--output`은 PowerShell의 native stdout 재인코딩을 거치지 않고 renderer의 결정적 UTF-8 바이트를 직접 기록한다. 생략하면 기존 stdout 출력을 유지한다. 생성된 Review Markdown은 저장소 밖 연구 output에만 두고 Git tracked artifact로 관리하지 않는다. 전체 source hash와 상세 provenance는 Review에 복제하지 않고 원 Evidence Packet JSON을 참조한다.

completion gate는 새 저장소를 만들지 않고 Git tracked `*_approved_content_slice.json` 및 기존 비표준 파일명 `approved_meaning_notation_policy_correction.json` manifest를 approved-content format·batch ID 계약으로 검증한 뒤 결정적 파일명 순서로 집계하되, 그 순서를 승인 우선순위로 사용하지 않는다. 기존 format v1 exact 계약을 유지하고 format v2에서는 필수 `word_note_replacements` 계약을 검증하며, format v3는 v2 필드에 필수 `supersedes` 배열을 추가한다. format v4는 v3 필드에 필수 `relation_replacements` 배열을 추가하며 `supersedes` 의미는 v3와 같다. format v5는 v4 필드에 필수 `meaning_approvals` 배열을 추가해 DB 쓰기 없이 승인된 현행 meaning 전체 projection을 기록한다. 각 supersession은 canonical `strong_number`와 이전 승인 manifest의 고유 `batch_id`를 exact 필드로 기록한다. tracked manifest set의 `batch_id`는 고유해야 하고, supersession source와 target batch 모두 해당 Strong의 meaning replacement after 또는 current meaning approval을 포함해야 한다. 존재하지 않는 target, self-supersession, cycle은 fail-closed다.

supersession은 manifest 전체가 아니라 Strong 단위다. 과거 manifest와 승인 이력은 그대로 보존하되 명시적으로 superseded된 batch의 해당 Strong projection만 current authority에서 제외한다. 남은 active approval들의 projection이 같으면 기존처럼 근거 파일을 모두 기록하고, 서로 다르면 fail-closed로 오류를 낸다. `explicit_approved`는 `meaning_replacements[].after` 또는 v5 `meaning_approvals[].meanings`에서 온 active approval projection 하나가 현재 work DB meaning projection과 exact 일치할 때만 부여하며, 현재 DB가 superseded projection과 일치해도 부여하지 않는다. v5 approval-only manifest는 applicator read-only dry-run에서 exact DB SHA·`user_version`·현재 meaning projection과 DB 불변을 검증하고 `--apply`, history, snapshot, undo를 만들지 않는다. superseded history가 있으면 completion 결과의 `active_approval_evidence`와 `superseded_approval_evidence`로 두 근거를 구분한다. filename이나 Git timestamp로 최신 승인을 추론하거나 현재 DB와 우연히 일치하는 과거 승인을 선택하지 않는다. `word_note_replacements`, `relation_creates`, `relation_replacements` endpoint는 승인 Strong 집계에 사용하지 않으므로 note-only 또는 relation-only manifest는 `explicit_approved` 근거가 아니며, note·relation 적용 무결성은 approved-content applicator의 before/after·history·undo 계약에서 별도로 검증한다. Packet provenance에는 실제 참조한 approved-content manifest 전체를 같은 결정적 순서로 기록한다.

기존 괄호 한자 marker와 source-only import projection을 함께 사용해 `legacy_hanja_candidate`, `source_only`, `unclassified`를 실행 시 계산한다. `legacy_hanja_candidate`는 최종 승인 상태가 아니며 한자가 없다는 이유만으로 미완료로 분류하지 않는다. `tool/data_provenance/manifests/p1_historical_approval_approved_content_slice.json`은 tracked P1 rehearsal fixture와 그 fixture를 추가한 commit `985830cd6f1dd6d759ae2f8fefc68a035ddb19b8`, SHA-256 `cbc4d60b13b4489f3677122bda486aecafaecc47166a71d1a2cb4c901392599d`의 pre-write snapshot, active history group `1786202221443735`, 현재 work DB projection의 exact 일치를 근거로 H1653·H1655·H1656의 기존 human-approved meaning을 현행 completion 계약에 연결한다. 이 manifest는 historical tracking backfill이며 live apply나 DB write를 수행하지 않는다. completion gate는 세 `meaning_replacements`만 `explicit_approved` 근거로 사용하고 같은 historical batch의 `relation_creates` endpoint는 의미 승인으로 간주하지 않는다. MVP 1에서 LXX alignment, Hebrew↔Greek 분석, 의미 후보·semantic relation 자동 판정, Approval Ledger, Dashboard/UI, DB write와 runtime schema 변경은 N/A다. LXX Human Reference의 explicit lookup·manual review 경계는 아래 11.7의 별도 계약을 유지하며 자동 Evidence Packet join에 참여하지 않는다.

#### 전체 Strong semantic 진행 현황 derivative

`tool/data_provenance/semantic_progress_report.py`는 `strong_sources.json`의 정규화·중복 검증된 Greek 및 Hebrew/Aramaic 전체 entry를 분모로 삼아 현재 semantic 작업 상태를 JSON·CSV·Markdown으로 재구성하는 read-only 개발 도구다. 이 출력은 approval input이나 새 semantic authority가 아니다. tracked approved-content manifest 전체와 현재 `reshet_work.db` meaning projection의 exact 일치를 확인하는 현행 completion gate, `semantic_research_dispositions.json`의 hold, 고정 Strong source가 계속 authority다. relation-only manifest endpoint는 meaning approval에 포함하지 않고, superseded approval과 현재 projection 불일치도 현행 completion 계약대로 `explicit_approved`에서 제외한다. active `explicit_approved`와 hold가 겹치면 report 생성 전에 fail-closed한다.

기본 출력은 저장소 밖 `../reshet_research_output/semantic_progress/`의 `semantic_progress.json`, `semantic_progress.csv`, `semantic_progress.md`이며 기존 세 파일은 완성된 UTF-8 바이트를 임시 파일에 쓴 뒤 atomic replace한다. JSON과 CSV가 전체 canonical Strong row의 machine-readable·정렬 가능한 snapshot이고 Markdown은 summary, 전체 hold, 전체 anomaly와 CSV 필터 안내만 제공한다. 행의 `language`는 고정 source `language_mapping`의 해석값이고 `source_language_code`는 원시 코드, `language_group`은 canonical 상위 언어군이다. `work_db_language`는 현재 work DB에 해당 Strong 행이 정확히 하나 있을 때 그 행의 `WORD_TABLE.언어`를 보존하며 행이 없거나 여러 개이면 비워 둔다. 따라서 `x-pn`의 `language=unresolved`와 현재 DB의 `work_db_language=히브리어`는 서로 다른 층위의 사실로 함께 기록하며 어느 한쪽으로 자동 보정하지 않는다. 동일 input에서는 벽시계 시각을 넣지 않으며 tool version, work DB SHA-256과 source fingerprint로 snapshot identity를 계산한다.

```powershell
python -B tool/data_provenance/semantic_progress_report.py `
  --output-dir ..\reshet_research_output\semantic_progress
```

`semantic_status`는 `explicit_approved`, `hold`, `unapproved` 세 값만 사용한다. `progress_detail`의 `approved`, `hold`, `unapproved_with_meaning`, `unapproved_without_meaning`, `anomaly`는 사람이 진행표를 필터하기 위한 derivative 분류다. anomaly row도 authority 상태는 세 값 중 하나를 유지하므로 DB meaning 존재나 source/DB 불일치를 승인으로 승격하지 않는다. `semantic_approval_ratio`는 `explicit_approved / total_canonical_strongs`, `decision_disposition_ratio`는 `(explicit_approved + hold) / total_canonical_strongs`이며 hold는 승인이나 semantic 완료가 아니다.

`canonical_occurrence_count`는 `biblical_occurrence_sources.json`이 고정한 OSHB/TAGNT canonical profile을 source별 한 번 읽어 Strong별로 집계하며 translation DB marker 수를 사용하지 않는다. `lexical_out_degree`, `lexical_in_degree`, `lexical_direct_degree`는 고정 Strong XML relation index에서 distinct direct node 수를 계산한 다음 대상·cluster 규모 참고값일 뿐 semantic approval, relation assertion 또는 hub 확정 근거가 아니다. recursive closure size 계산, research artifact 존재 여부, 자동 다음 Strong scoring은 이 v1 계약의 범위 밖이다.

### 11.7 LXXStp.bdb Human Reference 단건 verse 조회 경계

`LXXStp.bdb`는 사용자가 Bethlehem Bible에서 확보했다고 확인한 로컬 Human Reference 자료다. `tool/data_provenance/manifests/lxx_human_reference_source.json`은 파일명, 크기와 SHA-256 `eb0cc4445d47dd85cdb9977210b39b3d459a4b075663dfecb039510fd3e671ad`로 exact file identity를 고정하지만, 이는 upstream provenance나 license가 검증됐음을 뜻하지 않는다. 이 자료는 canonical Research/Build Source나 canonical occurrence 근거가 아니며 원본 corpus와 절대경로를 Git에 추적하거나 배포하지 않는다.

`tool/data_provenance/lxx_human_reference_lookup.py`는 사람이 명시한 book/chapter/verse만 SQLite read-only·immutable·query-only 연결과 parameterized SELECT로 조회한다. unmatched 절을 다른 절로 자동 mapping하거나 offset·본문 검색 fallback으로 추정하지 않으며 lemma, morphology, Strong, Hebrew↔Greek alignment와 의미·관계 후보를 생성하지 않는다. 출력은 `human_reference`, `provenance_unverified`, `not_canonical_evidence`, `manual_review_required` 경계를 명시하며 기존 Evidence Packet JSON, canonical occurrence count, OSHB·TAGNT source 계약, Review renderer와 LXX alignment N/A 계약을 변경하지 않는다.

실행 예시는 다음과 같다.

```powershell
python tool/data_provenance/lxx_human_reference_lookup.py "Joshua 22:24" `
  --local-sources ..\reshet_research_sources
```

이 도구는 정식 LXX source가 없는 동안 사람이 선택한 절을 별도 output으로 대조하기 위한 임시 연구 경계다. 향후 provenance와 license가 검증된 LXX source를 확보하면 기존 canonical Evidence Packet 경계를 자동 확장하지 않고 별도 승인 작업에서 교체할 수 있다.

### 11.8 H1672·H1674 승인 meaning·직접 파생 관계 work DB slice

`tool/data_provenance/manifests/h1672_h1674_approved_content_slice.json`은 승인 작업 지시 SHA-256 `1f0de468f4f23b194c24236b28bcd9561b53205d941308e6ae0d6bf57ac586fe`를 provenance로 고정하고, work DB SHA-256 `8e269644a233ada5c4fb4a93cd6b018ae743d8a28a4972c8398edd928f085e2b`의 meaning projection과 관계 부재를 exact precondition으로 사용한다. manifest SHA-256은 `62bba3f11e0f9dd1bd2c2a0404e848f6553415d03fa649320abbd494507f55a0`다. active `word_meaning_set` 전체 projection은 `H1672_0000 → 걱정하다`, `H1674_0000 → 걱정`으로 각각 1행이 됐다.

같은 transaction에서 `H1672 → H1674` 직접 파생 관계 id `7624`를 생성했다. 저장값은 `category_code=morphological`, `relation_type=derived`, `status_code=asserted`, `direction_code=w1_to_w2`, `source=RESHET-EC-P2-H1674-H1672`이고 선택 metadata는 `NULL`이다. history group `1786547348104946`에는 word update 2행과 relation create 1행을 기록했다.

적용은 기존 승인 콘텐츠 batch applicator로 `data/reshet_work.db`에만 수행했다. work SHA-256은 `8e269644a233ada5c4fb4a93cd6b018ae743d8a28a4972c8398edd928f085e2b`에서 `06e3ca5dc408f1360eae0687a3a61b9a64515dd911319e40fa2da3783936597b`로 변경됐고, seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260812T150907367789Z/snapshot.db`에 보존하며 크기 8,245,248바이트, SHA-256 `eb9b0024839146ca9cd537daa4997d7a7b504641ae0a34dc5434f1b93cfd1d19`다.

dry-run의 임시 적용·실제 undo와 live apply의 exact projection·대상 밖 semantic projection·integrity/FK 검증이 통과했고 SQLite sidecar는 없다. production Dart·테스트 코드, schema, seed와 UI/UX 동작은 변경하지 않았으며 SQL과 기존 applicator로 검증을 닫았으므로 사용자 UI 수동 테스트는 N/A다. H1672 연구에서 확인한 Psalms versification join 문제는 이 approved-content slice에는 포함하지 않았으며, 현재 Evidence Packet에서는 위 11.6의 reference-join 계약에 따라 처리한다.

### 11.9 첫 5-Strong 승인 meaning·직접 파생 관계 work DB slice

`tool/data_provenance/manifests/first_semantic_batch_approved_content_slice.json`은 승인 작업 지시 SHA-256 `85d96f81e00288196b441a840128472ba0bff9764f5efc97035b20b6ba01abbb`를 provenance로 고정하고, work DB SHA-256 `06e3ca5dc408f1360eae0687a3a61b9a64515dd911319e40fa2da3783936597b`의 meaning projection과 관계 부재를 exact precondition으로 사용한다. manifest SHA-256은 `9c0e5a72b09d3d8d901372c7ab2f4178cb095020d3490f50b1ca6196538e761d`다. active `word_meaning_set` 전체 projection은 `H1618_0000 → 딱지가 생기는 피부병`, `H4200_0000 → 곳간(저장고)`, `H4461_0000 → 치수`, `H5807_0000 → 힘`, `H6378_0000 → 병`으로 각각 1행이 됐다.

같은 transaction에서 직접 파생 관계 3건을 생성했다. semantic 방향 `H4058 → H4461`은 canonical pair `H4058_0000 / H4461_0000`, `direction_code=w1_to_w2`, relation id `7625`로 저장했고, `H5810 → H5807`은 canonical pair `H5807_0000 / H5810_0000`, `direction_code=w2_to_w1`, relation id `7626`으로 저장했다. `H6379 → H6378`은 canonical pair `H6378_0000 / H6379_0000`, `direction_code=w2_to_w1`, relation id `7627`로 저장했다. 세 관계는 모두 `category_code=morphological`, `relation_type=derived`, `status_code=asserted`이며 source는 각각 `RESHET-EC-FIRST-5-STRONG-H4461-H4058`, `RESHET-EC-FIRST-5-STRONG-H5807-H5810`, `RESHET-EC-FIRST-5-STRONG-H6378-H6379`이고 선택 metadata는 `NULL`이다.

적용은 기존 승인 콘텐츠 batch applicator로 `data/reshet_work.db`에만 수행했다. work SHA-256은 `06e3ca5dc408f1360eae0687a3a61b9a64515dd911319e40fa2da3783936597b`에서 `1f8fde72bdedc4a10885023846c4a7b5efaee09cac5b220935311cc1af74635d`로 변경됐고, seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1786596587315763`에는 active word update 5행과 relation create 3행을 기록했다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260813T044946592388Z/snapshot.db`에 보존하며 크기 8,249,344바이트, SHA-256 `9d4eb017bc89ad7ca98a23911ad22316e84f85bafd7e1bb114ec10c1a7b67a42`, integrity check `ok`, foreign key 위반 0이다. `VACUUM INTO`로 생성한 snapshot의 schema version은 `1369`이며 source와 적용 후 work DB의 schema version `1368`과 다른 것은 기존 applicator 계약상 예상된 schema cookie 차이다.

dry-run의 임시 적용·실제 undo와 live apply의 exact projection·대상 밖 semantic projection·integrity/FK 검증이 통과했다. 적용 후 work DB는 `user_version=0`, `schema_version=1368`, integrity check `ok`, foreign key 위반 0이고 SQLite sidecar는 없다. production Dart·테스트 코드, schema, seed와 UI/UX 동작은 변경하지 않았으며 SQL과 기존 applicator로 검증을 닫았으므로 사용자 UI 수동 테스트와 새 guard/test는 N/A다.

### 11.10 두 번째 semantic batch 승인 meaning·word note work DB slice

`tool/data_provenance/manifests/second_semantic_batch_approved_content_slice.json`은 batch ID `RESHET-EC-SECOND-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE`와 승인 작업 지시 SHA-256 `be89bda743322dd96065cf60a84c8afe7b6dce469c17e18fdc794295b8c89d7f`를 provenance로 고정하고, work DB SHA-256 `1f8fde72bdedc4a10885023846c4a7b5efaee09cac5b220935311cc1af74635d`의 meaning·word note projection을 exact precondition으로 사용한다. manifest SHA-256은 `8b6742b6cdc1e666710e367b67cdb78a5b50a019e529822ec45d18fe8eb86a5d`다. active `word_meaning_set` 전체 projection은 `H1564_0000 → 형체가 갖추어지지 않은 것`, `H2251_0000 → 떨다·털다`, `H3958_0000 → 보석의 한 종류`, `H5229_0000 → 올곧음`으로 각각 1행이 됐다. `H2251_0000`과 `H3958_0000`에는 승인 word note를 함께 적용했으며, `H1833`은 manifest와 write 대상에서 제외해 `source_only` hold를 유지하고 relation은 생성하지 않았다.

적용은 기존 승인 콘텐츠 batch applicator v2로 `data/reshet_work.db`에만 수행했다. work SHA-256은 `1f8fde72bdedc4a10885023846c4a7b5efaee09cac5b220935311cc1af74635d`에서 `e204715a3c7d8f32a92094df94f05532e39ff974cbcf4c6488ce6cc5dd9b66d6`로 변경됐고, seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1786634753173702`에는 active word update 6행(meaning 4행, note 2행)을 기록했고 relation history는 0행이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260813T152552451541Z/snapshot.db`에 보존하며 크기 8,253,440바이트, SHA-256 `b871b3287edb8c689f33914d5f00917424d740cd4d80bcfd96c31262b7247439`다. snapshot integrity check는 `ok`, foreign key 위반은 0이며 schema version `1369`와 source·적용 후 work DB `1368`의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. 자동 restore는 실행되지 않았다.

독립 read-only SQL로 네 meaning·두 note의 승인 after, history payload, H1833 meaning·note·relation 불변, 두 보류 relation pair 0행과 대상 밖 meaning·word projection·전체 relation 불변을 확인했다. 적용 후 work DB는 integrity check `ok`, foreign key 위반 0이고 SQLite sidecar는 없으며 seed 크기·수정시각도 불변이다. tracked manifest 기준 completion gate에서 네 대상은 `explicit_approved`, H1833은 `source_only`다. production Dart·테스트 코드, schema, seed와 UI/UX 동작은 변경하지 않았으므로 사용자 UI 수동 테스트와 새 guard/test는 N/A다.

### 11.11 두 번째 semantic batch 승인 파생·굴절 관계 work DB slice

`tool/data_provenance/manifests/second_semantic_batch_relations_approved_content_slice.json`은 batch ID `RESHET-EC-SECOND-SEMANTIC-BATCH-RELATIONS-APPROVED-CONTENT-SLICE`, 승인 작업 지시 SHA-256 `7a46c3c66ee40ec39167729007ec4c59601d615c10284c2c44a63f1c12947632`, manifest SHA-256 `f3c3a15f587c609de83874b652b940ad72e1d61e60a904d1a6b96c21e26e4054`를 provenance로 고정한다. work DB SHA-256 `e204715a3c7d8f32a92094df94f05532e39ff974cbcf4c6488ce6cc5dd9b66d6`와 두 unordered pair의 부재를 exact precondition으로 사용했으며 meaning·word note operation은 0건이다.

같은 exclusive transaction에서 semantic 방향 `H1563 → H1564`를 canonical pair `H1563_0000 / H1564_0000`, `category_code=morphological`, `relation_type=derived`, `status_code=asserted`, `direction_code=w1_to_w2`, relation id `7628`로 저장했다. `H5228 → H5229`는 canonical pair `H5228_0000 / H5229_0000`, `category_code=morphological`, `relation_type=inflected`, `status_code=asserted`, `direction_code=w1_to_w2`, relation id `7629`로 저장했다. source는 각각 `RESHET-EC-SECOND-SEMANTIC-BATCH-H1564-H1563`, `RESHET-EC-SECOND-SEMANTIC-BATCH-H5229-H5228`이고 description·relation group·note는 `NULL`이다.

적용 후 work DB SHA-256은 `9ed988d697e27ff0ce947a8b4164abff988bc6e34340f950cf1327e6ebcae040`이며 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1786638420819517`에는 active relation create 2행만 기록했고 word update는 0행이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260813T162700109576Z/snapshot.db`에 보존하며 크기 8,257,536바이트, SHA-256 `6b26c79f9f9bbd72df4ea4f6c66f64e062a997b32bd83157da223a1110d3cd5c`, integrity check `ok`, foreign key 위반 0이다. snapshot schema version `1369`와 source·적용 후 work DB `1368`의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이며 자동 restore는 실행되지 않았다. 독립 read-only SQL에서 두 관계의 exact row·중복 0, 대상 밖 `WORD_RELATION` 불변, 기존 meaning·word note와 H1833 불변, work DB integrity/FK와 SQLite sidecar 0을 확인했다. completion gate는 H1564·H2251·H3958·H5229 `explicit_approved`, H1833 `source_only`를 유지한다.

### 11.12 의미 연구의 인간 보류 기록

Semantic 승인 완료와 사람이 검토 후 의도적으로 보류한 상태는 별도 authority로 관리한다. `explicit_approved`의 authority는 기존 Git tracked `*_approved_content_slice.json`과 현재 work DB meaning projection의 exact 일치이며, human hold의 authority는 `tool/data_provenance/manifests/semantic_research_dispositions.json`이다. 이 ledger는 승인 상태를 중복 기록하지 않고 현재 `hold` status만 지원하며, 각 hold에는 사유·안정적인 evidence 참조·새 전문 근거 확보를 전제로 한 재검토 조건을 기록한다.

현재 첫 entry는 H1833이다. lexical source의 damask 직물 의미와 Damascus 지명 의미 및 Amos 3:12 관련 현재 evidence만으로 일반 semantic meaning 하나를 확정하기 어려워 hold하며, completion state는 `source_only` 그대로다. hold 집합을 production batch 자동 제외 selector에는 아직 연결하지 않으며, H2646 pilot에서도 hold authority와 approved-content authority를 분리해 유지했다.

### 11.13 H2646 승인 meaning·word note work DB slice

`tool/data_provenance/manifests/h2646_approved_content_slice.json`은 batch ID `RESHET-EC-H2646-APPROVED-CONTENT-SLICE`와 승인 작업 지시 SHA-256 `cfc46d51c3b84398f7f3ef1c4369770194958e733a1b5eac3bf6b95c64c98326`를 provenance로 고정하고, work DB SHA-256 `9ed988d697e27ff0ce947a8b4164abff988bc6e34340f950cf1327e6ebcae040`의 meaning·word note projection을 exact precondition으로 사용한다. manifest SHA-256은 `6001aa8241101459283fd5923764fcdd6bc75e5a961022cea265a6d93a0c923c`다. 기존 연구 artifact `H2646_evidence_packet.json`과 `H2646_review.md`의 SHA-256은 각각 `ec44ffc87ae67c3eecda61a573bf94b14d02bb5dabbe45fcd8000946f5781309`, `76abe3e589803b9dec5754dd19868ceb017a05a46c508c7bf5761d944a40df81`로 재확인했다. 과거 conflict/manual-review 표시는 semantic conflict가 아니라 OSHB/WLC `Psalms.19.6`과 typed KJV alternate `Psalms.19.5`의 versification 차이였다.

active `word_meaning_set` 전체 projection은 서로 다른 두 sense인 `H2646_0000 → 덮개`, `H2646_0000 → 방`을 seq 1·2의 별도 행으로 저장했다. H2645 `덮다`에서 파생된 명사라는 점과 덮는 구조물·둘러싸인 공간 및 혼례 문맥의 `신방`·`골방` 번역 용례는 `WORD_TABLE.비고`에 기록했으며, `신방`은 별도 canonical meaning으로 저장하지 않았다. 서로 다른 semantic sense는 별도 meaning으로 저장하고, `·` 병기는 동일하거나 사실상 같은 의미의 한국어 표현을 함께 표시할 때 사용하며, sense 사이의 어근적·개념적 연결이나 문맥별 구체 번역은 필요한 경우 word note에서 설명한다.

기존 승인 콘텐츠 batch applicator v2로 `data/reshet_work.db`에만 적용했으며 work SHA-256은 `9ed988d697e27ff0ce947a8b4164abff988bc6e34340f950cf1327e6ebcae040`에서 `7fe497b8fc568a588eeb950efc72776dc67b510f2ebf33f657ca56cb138d7b1a`로 변경됐다. seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1786694528148594`에는 meaning과 word note의 active word update 2행을 기록했고 relation은 생성하지 않았다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260814T080207454890Z/snapshot.db`에 보존하며 크기 8,257,536바이트, SHA-256 `446c4f843066f745cf7356cf800dc6b414d66b73e7bbe8dcb3a078e59c28b2ca`다. snapshot integrity check는 `ok`, foreign key 위반은 0이며 schema version `1369`와 source·적용 후 work DB `1368`의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 H2646의 meaning 2행·word note·relation 0건, H1833과 다른 승인 Strong의 meaning projection 불변, work DB integrity check `ok`, foreign key 위반 0과 SQLite sidecar 0을 확인했다. tracked manifest 기준 completion gate에서 H2646은 `explicit_approved`이고 semantic hold에는 포함되지 않는다. H1833은 `source_only`와 hold를 유지하며 approved와 hold의 교집합은 비어 있다. production Dart·테스트 코드, schema, seed와 UI/UX 동작은 변경하지 않았으므로 사용자 UI 수동 테스트와 새 guard/test는 N/A다.

### 11.14 세 번째 semantic batch 승인 meaning supersession work DB slice

`tool/data_provenance/manifests/third_semantic_batch_approved_content_slice.json`은 format v3 batch ID `RESHET-EC-THIRD-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE`와 승인 작업 지시 SHA-256 `011908d1a2af6932d691e337a963e5351af1cd9879023b3d6cf49197140a8d5e`를 provenance로 고정하고, work DB SHA-256 `7fe497b8fc568a588eeb950efc72776dc67b510f2ebf33f657ca56cb138d7b1a`의 실제 meaning projection을 exact precondition으로 사용한다. manifest SHA-256은 `5bedcee7be4ceea7d2566b0f3f20241c3ecf26ffa62ea9c6587a9f216ac95602`다. active `word_meaning_set` 전체 projection은 `H1563_0000 → 말다`, `H1652_0000 → 비를 내리다`, `H5228_0000 → 올바른`, `H5229_0000 → 올바름`, `H6770_0000 → 목마르다`, `H6772_0000 → 목마름`, `H2645_0000 → 덮다`의 seq 1 한 행씩이다. 이번 batch에서는 승인된 품사 구분을 보존해 H5228의 형용사 표현 `올바른`과 H5229의 명사 표현 `올바름`을 서로 다른 exact projection으로 저장했다.

H5229는 batch `RESHET-EC-SECOND-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE`의 `올곧음`을, H6772는 batch `RESHET-EC-P2-APPROVED-CONTENT-SLICE`의 `갈증`을 Strong 단위로 supersede한다. 기존 두 manifest는 승인 history로 유지하고 새 manifest만 active authority가 된다. `word_note_replacements`와 `relation_creates`는 모두 빈 배열이며 word note와 `WORD_RELATION`을 변경하지 않았다. dry-run은 exit code 0으로 임시 exact copy에 meaning 7건을 적용한 뒤 실제 undo를 수행해 `did_undo=true`, history 7행, 원본 work SHA 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 `7fe497b8fc568a588eeb950efc72776dc67b510f2ebf33f657ca56cb138d7b1a`에서 `acb1ae39a48c11a2c78989620276894714b633f4e0fd6c0c32cd9603edbd5431`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1786714311422193`에는 `word/update` active 7행만 있고 relation create·note update·예상 밖 action은 0행이다.

적용 전 snapshot은 `data/backups/approved_content_batch/20260814T133150706819Z/snapshot.db`에 보존하며 크기 8,261,632바이트, SHA-256 `da9145cf3d441af3dc0717ab25044aa80e3036a7ad8412a5b892bd928d906e18`, integrity check `ok`, foreign key 위반 0이다. snapshot schema version `1369`와 source·적용 후 work DB `1368`의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이며 자동 restore는 실행되지 않았다. 독립 read-only SQL에서 7개 exact projection과 H5229 `올곧음`·H6772 `갈증` 0행, 대상 밖 meaning·WORD_TABLE·expression digest 불변, `WORD_RELATION` 7,429행과 digest 불변, work·seed integrity check `ok`, foreign key 위반 0, SQLite sidecar 0을 확인했다. tracked manifest completion gate는 7개 Strong을 모두 `explicit_approved`로 판정하고 H5229·H6772의 active evidence와 superseded evidence를 구분한다. 다른 승인 Strong의 회귀는 없고 H1833은 `source_only`와 hold를 유지하며 approved와 hold의 교집합은 비어 있다. production Dart·schema·seed·UI/UX 동작은 변경하지 않았으므로 Flutter 전체 suite와 사용자 UI 수동 테스트는 N/A다.

### 11.15 세 번째 semantic batch 승인 관계 work DB slice

`tool/data_provenance/manifests/third_semantic_batch_relations_approved_content_slice.json`은 format v4 batch ID `RESHET-EC-THIRD-SEMANTIC-BATCH-RELATIONS-APPROVED-CONTENT-SLICE`, 승인 작업 지시 SHA-256 `d7001ad21dd48d861f6f75da2d3a86f48f1ba146da350045dde8620bec682b87`, manifest SHA-256 `09dc8eb4a140ffa82b50a3063d46c7f22cfe0f3e6d02d76750f7e276ffda35da`를 provenance로 고정한다. relation source는 기존 승인 batch의 `RESHET-EC-THIRD-SEMANTIC-BATCH-H대상-H근원` 관례를 따르며, upstream evidence인 `HebrewStrong.xml` SHA-256 `a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4`를 human approval provenance 대신 사용하지 않았다. `meaning_replacements`, `word_note_replacements`, `supersedes`는 빈 배열이고 tracked manifest completion gate에서 기존 승인 Strong 24개가 모두 `explicit_approved`를 유지했으며 새 승인 Strong은 생기지 않았다.

신규 관계는 4건이다. semantic 방향 `H1563 → H1545`는 canonical pair `H1545_0000 / H1563_0000`, `direction_code=w2_to_w1`, relation id `7630`으로 생성했다. `H6770 → H6771`은 pair `H6770_0000 / H6771_0000`, id `7631`, `H2645 → H2646`은 pair `H2645_0000 / H2646_0000`, id `7632`이며 둘 다 `direction_code=w1_to_w2`다. variant `H2644 → H2645`는 pair `H2644_0000 / H2645_0000`, `direction_code=w1_to_w2`, relation id `7633`으로 생성했다. 앞의 세 관계는 `morphological / derived / asserted`, variant는 `morphological / variant / asserted`이고 description·relation group·note는 모두 `NULL`이다.

기존 relation id `7617`의 `H1652_0000 / H1653_0000`과 id `7618`의 `H1652_0000 / H1656_0000`은 pair와 `created_at`을 보존한 채 `etymological / root_shared / asserted / undirected`에서 `morphological / derived / asserted / w1_to_w2`로 in-place 교체했다. source는 각각 `RESHET-EC-THIRD-SEMANTIC-BATCH-H1653-H1652`, `RESHET-EC-THIRD-SEMANTIC-BATCH-H1656-H1652`로 갱신했고 `updated_at`은 적용 시각으로 변경됐다. 독립 SQL에서 두 unordered pair가 각각 1행이며 기존 `root_shared` 중복 잔존이 없음을 확인했다.

dry-run은 create 4건·replacement 2건을 임시 적용한 뒤 `undoLastChange()` 1회로 신규 row 제거, replacement full before와 original `updated_at` 복원, history 비활성화 및 원본 work SHA 불변을 확인했다. live apply 후 work SHA-256은 `acb1ae39a48c11a2c78989620276894714b633f4e0fd6c0c32cd9603edbd5431`에서 `ab8ec1aaeef9c4bad0d7bbda2576b50b1236fbb06ee62a0396cde7509730a026`으로 변경됐고, seed 크기 10,162,176바이트와 SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1787231738818521`에는 active relation create 4행과 relation update 2행만 기록했다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260820T131537785106Z/snapshot.db`에 보존하며 크기 8,269,824바이트, SHA-256 `4a2e1010631fd748a43a6aa7f9da31679d8d144d5d3ff912902f83aa24ac9a1f`, integrity check `ok`, foreign key 위반 0이다. snapshot schema version `1369`와 source·적용 후 work DB `1368`의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. applicator와 독립 SQL 검증에서 meaning·word note 불변, work·seed integrity check `ok`, foreign key 위반 0, SQLite sidecar 0을 확인했다. H5228/H5226 same-source, H1656/H1653 equivalent, H1565 probable, compare 및 depth-2-only 관계는 manifest와 DB write에서 제외한 보류 상태를 유지한다. production tooling·schema·seed·UI/UX 동작은 변경하지 않았으므로 Dart unit test와 사용자 UI 수동 테스트는 N/A다.

### 11.16 H1 클러스터 사용자 결정과 G5 word note work DB slice

`tool/data_provenance/manifests/g5_word_note_approved_content_slice.json`은 format v2 batch ID `RESHET-EC-G5-WORD-NOTE-APPROVED-CONTENT-SLICE`, 사용자 결정 기록 SHA-256 `a7bd8c2b7c0ead62d4235070d881baf9d6c29da51124f9bb1797748816307785`, manifest SHA-256 `d56cf36be5281a0939382dd180bf96cd21eac80a33df5b7dc304561e05c54dc9`를 provenance로 고정한다. 사용자는 H1·H2의 현행 meaning과 한자 병기를 유지하고 G5의 현행 meaning `아빠/아버지`도 유지하기로 결정했다. 따라서 meaning과 relation operation은 만들지 않았고, G5의 기존 비고에서 canonical occurrence가 뒷받침하지 않는 `조상(祖上)` 설명을 제거하는 word note replacement 1건만 포함했다. 적용 후 비고는 `아람어 אַבָּא를 헬라어로 음역한 호격이다. 신약의 세 용례 모두 ‘아바, 아버지’ 문맥이며, ‘아빠’는 같은 의미를 친근하게 나타낸 한국어 표현이다.`이다.

dry-run은 word note 1건을 임시 적용하고 실제 undo해 `did_undo=true`, history 1행, 원본 work SHA 전후 exact 동일을 확인했다. live apply 후 work SHA-256은 `ab8ec1aaeef9c4bad0d7bbda2576b50b1236fbb06ee62a0396cde7509730a026`에서 `479fd8660cbc19aa18f9f6640cc097656b63f5f65084ee923f718edf6f791fb2`로 변경됐고, seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. history group `1787366556119746`에는 `G0005_0000`의 active `word/update` 1행만 기록했다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260822T024235120136Z/snapshot.db`에 보존하며 크기 8,269,824바이트, SHA-256 `b38471559b5a50bbdf4672227d468597d63b754b18d64457b03e621d60c26d4e`다. snapshot schema version `1369`와 source·적용 후 work DB `1368`의 차이는 기존 applicator 계약상 예상된 schema cookie 차이다.

독립 read-only SQL에서 G5의 meaning `아빠/아버지`, H1·H2의 두 현행 meaning, G5의 새 비고와 history exact 1행을 확인했다. work DB integrity check는 `ok`, foreign key 위반과 SQLite sidecar는 0이다. 당시 semantic progress는 전체 14,298건, `explicit_approved=24`, `hold=1`, `unapproved=14,273`, anomaly 113건을 유지했다. note-only manifest는 meaning 승인 근거가 아니며 applicator는 동일한 meaning before/after의 no-op을 금지하므로, H1·H2는 `legacy_hanja_candidate`, G5는 `unclassified`인 `unapproved`로 남았다. 실제 과거 projection을 꾸미거나 no-op 계약을 우회하지 않고 현행값 승인을 표현하는 후속 authority 계약은 아래 11.17에서 해결했다. production Dart·schema·seed·UI/UX 동작은 변경하지 않았으므로 Flutter 테스트와 사용자 UI 수동 테스트는 N/A다.

### 11.17 H1·H2·G5 현행 meaning 승인 authority

`tool/data_provenance/manifests/h1_h2_g5_meaning_approval_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H1-H2-G5-MEANING-APPROVAL-APPROVED-CONTENT-SLICE`, 11.16과 같은 사용자 결정 기록 SHA-256 `a7bd8c2b7c0ead62d4235070d881baf9d6c29da51124f9bb1797748816307785`, manifest SHA-256 `447cb183eaac48db4c8f6e05575c1fcc8e0b964b6b1a34608a6523d3672f9eeb`를 provenance로 고정한다. `meaning_approvals`는 `H0001_0000 → 아버지; 조상(祖上)/선조(先祖)/시조(始祖)`, `H0002_0000 → 아버지; 조상(祖上)/선조(先祖)/시조(始祖)`, `G0005_0000 → 아빠/아버지`의 현행 ordered projection을 기록한다. `meaning_replacements`, `word_note_replacements`, `relation_creates`, `relation_replacements`, `supersedes`는 모두 빈 배열이다.

Applicator v5 dry-run은 canonical work SHA-256 `479fd8660cbc19aa18f9f6640cc097656b63f5f65084ee923f718edf6f791fb2`, `user_version=0`, 세 word의 존재와 current meaning exact projection, integrity/FK와 sidecar 부재를 read-only로 검증했다. 결과는 `write_executed=false`, `history_group_id=null`, history 0행, `did_undo=false`, meaning approval 3건이며 work DB SHA는 전후 exact 동일하다. approval-only manifest에는 적용할 DB 변화가 없으므로 `--apply`, snapshot, history와 undo를 의도적으로 만들지 않는다. seed DB SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`도 불변이다.

새 manifest를 기존 tracked 승인 manifest 10개와 함께 명시적으로 포함한 full-data precommit reconstruction에서 전체 canonical Strong 14,298건, `explicit_approved=27`, `hold=1`, `unapproved=14,270`, anomaly 113건으로 집계됐다. H1·H2·G5는 모두 이 manifest를 `approval_authority`로 하는 `explicit_approved / approved`이며 기존 승인 24건, H1833 hold와 anomaly 집합에는 회귀가 없다. Git tracked discovery에 참여하는 시점은 이 manifest와 v5 completion gate 구현이 같은 commit에 포함된 뒤다. DB·schema·seed·앱 UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.18 H3 cluster 승인 의미·비고·관계 work DB slice

`tool/data_provenance/manifests/h3_cluster_approved_content_slice.json`은 format v4 batch ID `RESHET-EC-H3-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자 승인 및 DB·Git 실행 지시 SHA-256 `37c591cf6285a1d93b374e348ecd24b8d76cf18872308d0f55f71f291162bde4`, manifest SHA-256 `4a0f138124d541b3a47ddb1b43cf8479376918a8922adba8f3c9882b83b0913c`를 provenance로 고정한다. meaning replacement는 `H0003_0000 → 푸른 초목(草木)`, `H0004_0000 → 열매`, `H0024_0000 → 곡식(穀食)의 풋이삭; 아빕월(月)`의 ordered projection 3건이다. H3 비고는 `욥 8:12에서는 식물이 아직 푸른 상태를, 아가 6:11에서는 골짜기의 푸른 초목(草木)·새순을 가리킨다.`, H24 비고는 `아빕월(月)은 곡식(穀食)의 풋이삭이 나는 시기에서 이름을 얻은 달이며, 후대에는 니산월(月)로 불렸다.`로 교체했다. 신규 관계는 `H0003 ↔ H0004`, `H0003 ↔ H0024`의 `etymological / root_shared / asserted / undirected` 2건과 `H0024 → H8512`, `H8510 → H8512`의 `morphological / compound / asserted / w1_to_w2` 2건이며 description·relation group·note는 모두 `NULL`이다. relation replacement, supersede와 hold operation은 없다.

dry-run은 exit code 0으로 임시 exact copy에 9개 operation을 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787381373485968`의 9행과 원본 work SHA-256 `479fd8660cbc19aa18f9f6640cc097656b63f5f65084ee923f718edf6f791fb2` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 `479fd8660cbc19aa18f9f6640cc097656b63f5f65084ee923f718edf6f791fb2`에서 `572104fb3787b88f9f6ce60f817918ea6eb7330c4bc997f5e949ac2463aa01a5`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260822T065000295765Z/snapshot.db`, 크기 8,273,920바이트, SHA-256 `ad93e6888d7998fe15d9287aad587efaff62b5f302aefe9204ab928e3665b50f`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787381401330453`에는 active word update 5행과 relation create 4행만 있고 relation id는 7634~7637, `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 승인 meaning·비고와 네 relation의 exact row·unordered pair 중복 0을 확인했다. H8510·H8512의 meaning·비고는 불변이고, snapshot 대조에서 대상 밖 `WORD_TABLE`, 대상 밖 meaning, 전체 expression, 기존 relation, 기존 history projection diff는 모두 0이다. `WORD_RELATION`은 7,433행에서 7,437행, `CHANGE_HISTORY`는 1,474행에서 1,483행으로 승인 수만큼 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work/seed SQLite sidecar는 0이다. full-data semantic progress snapshot identity는 `fba14a48ea0b679174fb6d85d93443a406a81f40420cc3a3415b255f41bcea21`이며 전체 14,298건에서 `explicit_approved=30`, `hold=1`, `unapproved=14,267`, anomaly 113건이다. H3·H4·H24는 새 manifest를 authority로 하는 `explicit_approved / approved`, H8510·H8512는 기존 `unapproved_with_meaning`을 유지한다. JSON·CSV는 각각 14,298행이고 artifact SHA-256은 JSON `0d43dba6077171f257810f4b1fdfb5db132bdc1e08296d9fbdb20eb81b446040`, CSV `0402130d63ec2f4c6ffe199c0852b4d773406492e24a3aadbbd00248020ee64b`, Markdown `d13c15f6d15000404d16673f18e04e2f8f7481233e563c0fe2ff33ed3865bfb2`다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 Flutter 테스트와 사용자 UI 수동 테스트는 N/A다.

### 11.19 H5 인명 의미·비고 승인 work DB slice

`tool/data_provenance/manifests/h5_name_approved_content_slice.json`은 format v4 batch ID `RESHET-EC-H5-NAME-APPROVED-CONTENT-SLICE`, 사용자 확정 기록 SHA-256 `d780fc918dd2d68e62f9494a318c163dd45a9165a29035e34798735f7faee0b8`, manifest SHA-256 `ecd8647fd7d0a290ff111ea6b96f4e6d1c0ab85a22d6f76414f38677db231491`를 provenance로 고정한다. meaning replacement는 `H0005_0000`의 `아박다 (인)`을 `아박다·아바그타 (인)`으로 교체한다. word note는 `아박다는 한국어 성경의 관용 표기이고, 아바그타는 히브리어 본문 표기에 따른 한국어 음역이다. 아케메네스 제국권에서 사용된 실제 원형은 확인되지 않는다.`로 설정한다. `word_expression_set`의 `אֲבַגְתָא`·`아바그타`·기존 발음 정보는 변경하지 않았고, G0912와의 relation create, relation replacement, supersede와 hold operation은 없다.

dry-run은 exit code 0으로 의미 1건과 비고 1건을 임시 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787629824103488`의 2행과 원본 work SHA-256 `572104fb3787b88f9f6ce60f817918ea6eb7330c4bc997f5e949ac2463aa01a5` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 `572104fb3787b88f9f6ce60f817918ea6eb7330c4bc997f5e949ac2463aa01a5`에서 `84ee4fbc8e2288b6c01b793593b696720100c5e2b3c0d374becd40c0291b7b21`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260825T035040243113Z/snapshot.db`, 크기 8,286,208바이트, SHA-256 `fbddbf3ab1906272300ddaf1ca174da23e244fccc6e801ade4a505cc09ba5eed`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787629841314971`에는 active word update 2행만 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 새 meaning·비고와 H5–G0912 관계 0건을 확인했다. snapshot 대조에서 대상 밖 `WORD_TABLE`, 대상 밖 meaning, 전체 expression, 전체 relation, 기존 history projection과 schema diff는 모두 0이다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행, `WORD_RELATION` 7,437행은 불변이고 `CHANGE_HISTORY`만 1,483행에서 1,485행으로 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work/seed SQLite sidecar는 0이다. 새 manifest를 기존 tracked 승인 manifest와 함께 명시적으로 포함한 full-data precommit reconstruction은 전체 canonical Strong 14,298건, `explicit_approved=31`, `hold=1`, `unapproved=14,266`, anomaly 113건이며 H5는 새 manifest를 authority로 하는 `explicit_approved / approved`다. snapshot identity는 `4999b4e50837449624d294e097c49fa88af248e968050c3604af0222156d8b9b`, 결정적 render SHA-256은 JSON `287314197da91519bf76dee313a7c44d1613cdeaee5b1c075a7d10c92e53433c`, CSV `015fa556f9c782704652936ac84a66d353e463e0f2f5da755c24e7019bc947ed`, Markdown `16cd44904d390a800ff832b1960b0318af6aece2f0cd5c76ed637d3c8b8621ce`다. Git tracked discovery에는 manifest가 commit에 포함된 뒤 참여한다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 Flutter 테스트와 사용자 UI 수동 테스트는 N/A다.

### 11.20 H6 cluster 승인 의미·비고·관계 work DB slice

`tool/data_provenance/manifests/h6_cluster_approved_content_slice.json`은 format v4 batch ID `RESHET-EC-H6-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자 확정 및 `H0006–H0010` 관계 삭제 제외·DB 반영 지시 SHA-256 `7c5c7e84b2d367848b83dc3893b2a4b79afc1a4faf6765e5b65b375c23e47610`, manifest SHA-256 `1d7694a641db5d4cea0dd0aa943c8dee71d6044c480e8c91f3571bb1ed019f6f`를 provenance로 고정한다. meaning replacement는 `H0006_0000 → 멸망하다(滅亡-)/죽다; 멸망시키다(滅亡-)/파괴하다(破壞-); 없어지다/없애다; 잃다/길을 잃다`, `H0007_0000 → 멸망하다(滅亡-)/없어지다; 멸망시키다(滅亡-)/없애다`, `H0008_0000 → 멸망(滅亡)`, `H0009_0000 → 잃어버린 것`, `H0010_0000·H0011_0000·H0012_0000·H0013_0000 → 멸망(滅亡)`, `G0003_0000 → 아바돈·아밧돈`의 ordered projection 9건이다. word note는 H6의 형태별 의미 분포, H10의 잠 27:20 기록형·독음형 경계, H11의 장소 용례, G3의 관용 표기·한국어식 음역·H11 기원·G623 대응을 기록하고 H9의 중복 비고를 `NULL`로 교체했다. `word_expression_set`은 전체 불변이며 G3의 `Ἀβαδδών`, `transliteration=아받돈`, 기존 발음 정보도 변경하지 않았다.

신규 관계는 `H0009–H0010`의 `morphological / variant / uncertain / undirected`와 `H0011→H0010`의 `morphological / variant / asserted / w2_to_w1` 2건이며 relation id는 7638·7639다. 기존 relation id 472, 473, 474, 5, 476, 477은 각각 H6와 H7·H8·H9·H11·H12·H13 사이의 `root_shared` 또는 `derived` 관계로, id 4는 `H0011→G0003`의 `transliteration / direct_transliteration / asserted / w2_to_w1`로, id 5368은 `G0003→G0623`의 `translation / semantic_translation / asserted / w1_to_w2`로 identity와 `created_at`을 보존한 채 교체했다. 사용자의 최종 범위에 따라 relation id 475 `H0006–H0010 / unspecified / related / inferred / unknown / WORD_TABLE.관련1`은 삭제하지 않고 exact 불변으로 남겼다. relation delete, supersede와 hold operation은 manifest에 없다.

dry-run은 exit code 0으로 24개 operation을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787642443098668`의 24행과 원본 work SHA-256 `84ee4fbc8e2288b6c01b793593b696720100c5e2b3c0d374becd40c0291b7b21` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 위 값에서 `6ec49bfeccb981693183e6d01bf4f50c43f1fee587240909045507a935f23e79`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260825T072107673444Z/snapshot.db`, 크기 8,290,304바이트, SHA-256 `074ea69364e34b2a60d7c3b66f34a65b661968dcfc3cf0875013390424fbcbaf`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787642468690007`에는 active word update 14행, relation create 2행, relation update 8행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 승인 meaning·비고·관계와 id 475 불변을 확인했다. snapshot 양방향 `EXCEPT` 대조에서 대상 밖 `WORD_TABLE`, 대상 밖 meaning, 전체 expression, 대상 밖 relation, 기존 history projection diff는 모두 0이다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행은 불변이고 `WORD_RELATION`은 7,437행에서 7,439행, `CHANGE_HISTORY`는 1,485행에서 1,509행으로 승인 operation 수만큼 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work/seed SQLite sidecar는 0이다. 새 manifest를 stage해 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=40`, `hold=1`, `unapproved=14,257`, anomaly 113건이며 H6·H7·H8·H9·H10·H11·H12·H13·G3는 모두 새 manifest를 authority로 하는 `explicit_approved / approved`다. snapshot identity는 `6580d79d6ebb4430aee5a5d758ed2325af756b1bfb613e4d588f41bcfed02eae`, artifact SHA-256은 JSON `071a3e8f7a4e46f94106cb025f8ddce39a1078cd8734f472e0684513ab27f9c1`, CSV `9a1961593c0e49be0fdb212eabfa40913f706530e5972af54429110e149d5b06`, Markdown `49fe15a14d09615cd7eb397aadc7b6d112defe3e4ba97ed98db7ae67408329fb`다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 Flutter 테스트와 사용자 UI 수동 테스트는 N/A다.

### 11.21 H14 cluster 승인 의미·비고·관계 work DB slice

`tool/data_provenance/manifests/h14_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H14-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자 최종 확정 및 DB 반영 지시 SHA-256 `45b2c8f694d5300e9d666ed0d7ec64cc0886826358d4ec85321386e50a376bb3`, manifest SHA-256 `112b71a54aefb1e9207db3fc9371772687d24c4ec2c2c3ff931927970405e627`를 provenance로 고정한다. meaning replacement 12건은 `H0014_0000 → 원하다(願하다)`, `H0015_0000 → 원(願)·소원(所願)`, `H0016_0000 → 파피루스`, `H0017_0000 → 근심(憂)`, `H0034_0000 → 궁핍한(窮乏한)`, `H0035_0000 → 케이퍼 열매`, `H8375_0000 → 갈망(渴望)`, `H8374_0000 → 혐오하다(嫌惡하다)`, `H8373_0000 → 갈망하다(渴望하다)`, `H0340_0000 → 원수(怨讐)로 대하다`, `H0341_0000 → 원수(怨讐)`, `H0342_0000 → 원한(怨恨)`의 ordered projection이다. 이미 `욥`인 `H0347_0000`과 `G2492_0000`은 동일 before/after 교체로 꾸미지 않고 `meaning_approvals` 2건으로 현행 projection을 승인했다.

word note 11건은 H14의 문맥별 의지·수락 범위, H15의 욥 34:36 용법과 어원 대안, H16의 파피루스 배, H17의 감탄사 계통, H35의 후대 히브리어 식물명과 전 12:5의 욕망 번역, H8373·H8374·H8375의 동형어·어원 불확실성, H340·H341·H342의 동사·분사·추상명사 관계를 기록한다. 신규 관계는 `morphological / derived / hypothesized / w1_to_w2`인 H14→H15·H16·H17·H34·H35, H8374→H8375, H340→H347의 7건과 `morphological / derived / asserted / w1_to_w2`인 H340→H341·H342의 2건이며 relation id는 7640~7648이다. 기존 relation id 2131 `G2492–H0347`은 identity와 `created_at`을 보존한 채 `transliteration / direct_transliteration / asserted / w2_to_w1`로 교체했다. 비교 근거만 있는 H15–H8375, H8374–H340, H8373–H8374는 관계로 생성하지 않았고 supersede와 hold operation도 없다.

dry-run은 exit code 0으로 33개 write operation과 현행 meaning approval 2건을 검증하고 임시 exact copy의 write operation을 실제 undo해 `did_undo=true`, 임시 history group `1787655156827890`의 33행과 원본 work SHA-256 `6ec49bfeccb981693183e6d01bf4f50c43f1fee587240909045507a935f23e79` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 위 값에서 `67ad253b471c8e64d1970c3cc3d565828155581c6ce86b8c1c245f6d9a87adeb`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260825T105257707035Z/snapshot.db`, 크기 8,318,976바이트, SHA-256 `33ebe4043dddff6b4aaf95b8f779b7cca07562cdf22c5e8dffa794c385b55617`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787655179042010`에는 active word update 23행, relation create 9행, relation update 1행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 승인 meaning·비고 14개 projection과 관계 10건을 exact 확인했다. snapshot 양방향 `EXCEPT` 전수 대조에서 차이는 `WORD_TABLE` 11행, `word_meaning_set` 12행, `WORD_RELATION` 기존 1행 교체와 신규 9행, `CHANGE_HISTORY` 신규 33행뿐이며 다른 모든 사용자 테이블은 동일하다. `WORD_TABLE` 15,029행과 `word_meaning_set` 18,175행은 행 수가 불변이고 `WORD_RELATION`은 7,439행에서 7,448행, `CHANGE_HISTORY`는 1,509행에서 1,542행으로 승인 operation 수만큼 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work SQLite sidecar는 0이다. 새 manifest를 명시적으로 포함한 full-data precommit reconstruction은 canonical Strong 14,298건, `explicit_approved=54`, `hold=1`, `unapproved=14,243`, anomaly 113건이며 H14 cluster 14개 Strong은 모두 새 manifest를 authority로 하는 `explicit_approved / approved`다. snapshot identity는 `de0e7b339e2ec53ec4ef7654bbbf78acc4b8f41de81b62191ac52847d5aabf89`, artifact SHA-256은 JSON `10ebbdf9a76549b6dbcc2062013958ab18840ac6f81c3add2ce410c2065b5c33`, CSV `2d76c6fc5c6f742bc7f7cc9cb0e346435e9933c50aef070609390e113edfd781`, Markdown `77745c33ca2668a45aa39317cbc25e5b09e2ce0a6ee0a30842a19c46985945c3`다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 Flutter 테스트와 사용자 UI 수동 테스트는 N/A다.

### 11.22 H18 cluster 승인 의미·비고·관계 work DB slice

`tool/data_provenance/manifests/h18_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H18-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자 최종 확정 및 DB·Git 완료 지시 SHA-256 `29697305d80719706c6bfe5fe47ed76acad5384a302dcdbe1549f4d717aecfb6`, 적용 manifest SHA-256 `5d5adb888d77ce82410281d5860e9342701984b56a0db4cdeed7e8c21b7fa8ec`를 provenance로 고정한다. meaning replacement 3건은 `H0018_0000 → 구유`, `H0075_0000 → 살찌우다`, `H3965_0000 → 곡물 창고(穀物倉庫)`의 ordered projection이다. H18 비고는 가축의 먹이통이라는 핵심 의미와 욥 39:9의 문맥상 `외양간` 번역을 구분하고, H75 비고는 먹이를 주어 살찌게 하는 뜻과 두 canonical 용례의 칼 수동분사 형태를 기록한다. H3965 비고는 `NULL`을 유지한다.

신규 관계는 `H0075→H0018`과 `H0075→H3965`의 `morphological / derived / asserted` 2건이며 relation id는 7649·7650이다. 정렬된 저장 pair는 각각 `H0018–H0075 / w2_to_w1`, `H0075–H3965 / w1_to_w2`이고 source는 `RESHET-EC-H18-CLUSTER-H0075-H0018`, `RESHET-EC-H18-CLUSTER-H0075-H3965`다. H0018–H3965 직접 관계, relation replacement, supersede와 hold operation은 없다.

dry-run은 exit code 0으로 7개 write operation을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787795245512092`의 7행과 원본 work SHA-256 `67ad253b471c8e64d1970c3cc3d565828155581c6ce86b8c1c245f6d9a87adeb` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 위 값에서 `f8e1366cb3b4e0fc585e48fe6104c2668c2e9b0be38cd7fe25c359ac31e44db6`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260827T014816727006Z/snapshot.db`, 크기 8,355,840바이트, SHA-256 `16d1f82b8d722629b39b2475600499861350ac67461873cbd34a8c5d3b8a8c70`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787795297559755`에는 active word update 5행과 relation create 2행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 승인 meaning·비고와 관계 2건을 exact 확인했다. snapshot 전수 대조에서 차이는 `WORD_TABLE` 2행 교체, `word_meaning_set` 3행 교체, `WORD_RELATION` 신규 2행, `CHANGE_HISTORY` 신규 7행뿐이며 다른 모든 사용자 테이블은 동일하다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행은 불변이고 `WORD_RELATION`은 7,448행에서 7,450행, `CHANGE_HISTORY`는 1,542행에서 1,549행으로 승인 operation 수만큼 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다. 새 manifest를 stage해 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=57`, `hold=1`, `unapproved=14,240`, anomaly 113건이며 H18·H75·H3965는 모두 새 manifest를 authority로 하는 `explicit_approved / approved`다. snapshot identity는 `c591dfbaee4b07e2c43d7778d56651e80c88c771ee7ed38ce4e9b84e9249ef09`, artifact SHA-256은 JSON `0d0571bdf429bab574c0a22ec10f58b33147000b36ecafad18b44a403d76b852`, CSV `a8a99696fb88203d8850eb0e02a42b72395a6e36ac7f5ecb006743cb39bbe22f`, Markdown `0b6057ffac360a971366dcbe690b7c3c8a67019973fe7ae1f8cd39116b763d26`다. 대상 applicator service 테스트 29건은 모두 통과했다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.23 H19 단일어 승인 의미·비고 work DB slice

`tool/data_provenance/manifests/h19_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H19-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자 최종 확정 및 DB·Git 완료 지시 SHA-256 `48486118447c331a4248594e6e3a3221db2525ef9e8d0109ee73fe148d8a756e`, 적용 manifest SHA-256 `3255e7275211eceebb4b27f0e1d6d2654073b01724ded74d12b1da6da2c06c03`를 provenance로 고정한다. `H0019_0000`의 active meaning 전체 projection은 기존 `칼을 휘두름` 1행에서 `칼의 번뜩임` 1행으로 교체했다. `칼을 휘두름`은 두 번째 meaning으로 남기지 않고, hapax legomenon의 해석 불확실성과 함께 word note에 보존했다. 비고는 Strong·일부 주석의 휘두름·회전 해석, 전통 주석의 번뜩임·공포·칼에 죽은 자들의 외침 해석, 칠십인역·타르굼과 BDB·게제니우스의 `טִבְחַת` 계열 본문에 따른 살육 해석을 서로 구분한다. relation create·replacement, supersede와 meaning approval operation은 없다.

dry-run은 exit code 0으로 2개 write operation을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787822310057010`의 2행과 원본 work SHA-256 `f8e1366cb3b4e0fc585e48fe6104c2668c2e9b0be38cd7fe25c359ac31e44db6` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 위 값에서 `d20c0f44f569fe0dbbf04e69ab7928500c8305558b3089fea540174b920c76d4`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260827T091847309849Z/snapshot.db`, 크기 8,368,128바이트, SHA-256 `600ac8366023c92f1e7b47b607c43fe3f23f444cdd1194a4bfd152aac8828b82`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787822328102295`에는 active word update 2행만 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 `H0019_0000`의 meaning·word note와 관계 0건을 exact 확인했다. snapshot 양방향 `EXCEPT` 대조에서 차이는 `WORD_TABLE`의 H0019 1행 교체, `word_meaning_set`의 H0019 1행 교체, `CHANGE_HISTORY` 신규 2행뿐이며 다른 모든 사용자 테이블, 대상 밖 word·meaning과 전체 expression·relation은 동일하다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행, `WORD_RELATION` 7,450행은 불변이고 `CHANGE_HISTORY`는 1,549행에서 1,551행으로 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다. 새 manifest를 stage해 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=58`, `hold=1`, `unapproved=14,239`, anomaly 113건이며 H19는 새 manifest를 authority로 하는 `explicit_approved / approved`다. snapshot identity는 `a642ea1de3864ea50f384ddb8964cd99351086d67b564f89c220f975b8ac9670`, artifact SHA-256은 JSON `db542743220b23e550b661c4a3e76076764d556c377b5a287cff8b56230e8314`, CSV `c9f608f2a911ee4cb139c6f00c0fbd562447ebf993d973d689d1805763de9e20`, Markdown `be22dc6c11a0a21dd92b56e49375bdb3d512690d79382918a4df452dbdfbe290`다. 대상 applicator service 테스트 29건은 모두 통과했다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.24 H20 단일어 승인 의미·비고 work DB slice

`tool/data_provenance/manifests/h20_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H20-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자 최종 확정 및 DB·Git 완료 지시 SHA-256 `5b7a6f6af9045a2b9ee5aa0864aa2d25841fd1b8d39c96ad307a53d8a44b7fb3`, 적용 manifest SHA-256 `24e05048a5a93c4bea601ffde1fd18417c39c01d95d2f51e8f2cdbc51e95d9d7`를 provenance로 고정한다. `H0020_0000`의 active meaning 전체 projection은 기존 `참외, 수박` 1행에서 `수박` 1행으로 교체했다. word note는 이 단어가 민수기 11:5에 복수형으로 한 번만 나타나며, Strong의 넓은 `melon`, 한국어 번역의 참외·수박 차이, BDB와 식물사 연구의 수박 식별을 구분해 기록한다. relation create·replacement, supersede와 meaning approval operation은 없다.

dry-run은 exit code 0으로 2개 write operation을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787879384043822`의 2행과 원본 work SHA-256 `d20c0f44f569fe0dbbf04e69ab7928500c8305558b3089fea540174b920c76d4` 전후 exact 동일을 확인했다. live apply도 exit code 0이며 work SHA-256은 위 값에서 `708b04a8756ce1e1b5b82c344c44b8ccff114b4169ff585633434847af90267a`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260828T011013390607Z/snapshot.db`, 크기 8,368,128바이트, SHA-256 `4c0c0b2b031677b11d99b64e835393ce4383265b52102a4e0a6f8266c2518ca2`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. live history group `1787879414222763`에는 active word update 2행만 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 `H0020_0000`의 meaning·word note와 관계 0건을 exact 확인했다. snapshot의 12개 사용자 테이블을 양방향 대조한 결과 차이는 `WORD_TABLE`의 H0020 1행 교체, `word_meaning_set`의 H0020 1행 교체, `CHANGE_HISTORY` 신규 2행뿐이며 다른 모든 사용자 테이블은 동일하다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행, `WORD_RELATION` 7,450행은 불변이고 `CHANGE_HISTORY`는 1,551행에서 1,553행으로 증가했다. work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다. 새 manifest를 stage해 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=59`, `hold=1`, `unapproved=14,238`, anomaly 113건이며 H20은 새 manifest를 authority로 하는 `explicit_approved / approved`다. snapshot identity는 `35742a9b6fa9d134b062e675af3a9200f3c1df4ce9d4be2535c9462d326dd194`, artifact SHA-256은 JSON `4732cd8732567979ecb9715a2464b0ad7d60de148945bade4efe69e883254f1e`, CSV `a10e79e305e522b30e6a7266dcd63639db711d7e366a1c7ca44f925838b40a3b`, Markdown `09f96f061b31504b8c3e5dd24d76ada4f26e3227283c81b5702e5dd165834f0a`다. 대상 applicator service 테스트 29건은 모두 통과했다. production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.25 H21 현행 의미 승인·비고·파생 관계 work DB slice

`tool/data_provenance/manifests/h21_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H21-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자의 H21 meaning·비고·관계·hold 최종 승인 SHA-256 `92419da4cd06390136c005b8329ad39b3f7c9059b27abe1ebd5d40fb9c8f08a8`, 적용 manifest SHA-256 `f93e90f8ad5dbdd8beeff1acb7ca3e5853f4033cf78d3cd541d8c94cf9332089`를 provenance로 고정한다. `H0021_0000`의 현행 meaning projection `아비 (인)` 1행은 `meaning_approvals`로 exact 승인했으며 meaning write는 수행하지 않았다. word note에는 히스기야의 어머니이자 스가랴의 딸이라는 인물 정보와 왕하 18:2의 아비(H0021), 병행되는 대하 29:1의 아비야(H0029)가 같은 인물이라는 점을 기록했다.

신규 relation id 7651은 `H0001_0000→H0021_0000`의 `morphological / derived / asserted / w1_to_w2`이며 source는 `RESHET-EC-H21-CLUSTER-H0001-H0021`, 선택 metadata는 `NULL`이다. Canonical source-reference H0021→H0001과 semantic derivation H0001→H0021의 방향을 구분했다. 동일 인물이라는 문맥만으로 직접 lexical relation을 만들지 않기 위해 H0021–H0029 relation은 생성하지 않았고 hold operation도 없다.

Dry-run은 exit code 0으로 word note 1건과 relation create 1건을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787924278720761`의 2행과 원본 work SHA-256 `708b04a8756ce1e1b5b82c344c44b8ccff114b4169ff585633434847af90267a` 전후 exact 동일을 확인했다. Live apply도 exit code 0이며 work SHA-256은 위 값에서 `550155e13dd8db5d55880126a03ab5bba66fec903af7a69e59d9074be7c9532c`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260828T133835427394Z/snapshot.db`, 크기 8,372,224바이트, SHA-256 `a257deeaff36763ee5a683166e80f0288f0b9116b98d547441bc69e17434f1d0`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. Live history group `1787924316328349`에는 active word update 1행과 relation create 1행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 H0021 meaning `아비 (인)`, 승인 word note, relation id 7651을 exact 확인했고 H0021–H0029 relation은 0건, 승인 relation 이외 H0021 incident relation도 0건이다. Snapshot의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 차이는 `WORD_TABLE`의 H0021 1행 교체, `WORD_RELATION` 신규 1행, `CHANGE_HISTORY` 신규 2행뿐이다. 다른 9개 사용자 테이블은 동일하며 `word_expression_set` 15,257행과 `word_meaning_set` 18,175행도 불변이다. `WORD_RELATION`은 7,450행에서 7,451행, `CHANGE_HISTORY`는 1,553행에서 1,555행으로 승인 operation 수만큼 증가했다. Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다.

새 manifest를 stage해 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=60`, `hold=1`, `unapproved=14,237`, anomaly 113건이며 H21은 새 manifest를 authority로 하는 `explicit_approved / approved`다. Snapshot identity는 `a32fbba2a4e234150c2e3cd893f843bd9a1263a073e6f376221ba76b5f84e2ae`, artifact SHA-256은 JSON `488607340b7d21f7cf130b2785d24581ba35c6d20c7e9e49de3844edae5fbcdf`, CSV `28620cba657e70c0569239eddb0b317c7a871527688f7de148c81c263133ade9`, Markdown `e79b3062634a92e1b547764f49fe9fc4c0064e3e8e6eb5c8f5ce0b53cae6a50f`다. 대상 applicator service 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.26 H22 현행 의미 승인·비고·합성 관계 work DB slice

`tool/data_provenance/manifests/h22_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H22-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자의 추천안 전체 승인 및 DB·Git 완료 지시 SHA-256 `9909e3308356c03f85f04547ca2f3e1f98c5da91d3b09640e6e6dd956eafbe8b`, 적용 manifest SHA-256 `0cd3c085798360b6ed0eec369d7512f911ea80e394d77c21d9ab1d1f03fa2be7`를 provenance로 고정한다. `core.autocrlf=true`의 최종 `main` checkout에서는 working-copy manifest가 CRLF SHA-256 `572bf307e9b4dccb5510562a4d67d08e3536d6c237efe250c6d4bbd5d95c051b`로 재구성되지만, committed Git blob과 applicator backup manifest는 적용 SHA-256과 exact 일치하며 JSON payload도 동일하다. `H0022_0000`의 현행 meaning projection `아비엘 (인)` 1행은 `meaning_approvals`로 exact 승인했으며 meaning write는 수행하지 않았다. Word note에는 canonical 세 용례가 가리키는 두 이스라엘 사람, H0001·H0410 구성에 따른 일반적 이름 풀이, 대상 11:32와 삼하 23:31의 아비엘·아비알본(H0045) 평행을 기록했다. H0001의 기존 승인은 유지하며 H0410·H0045의 독립 meaning은 이번 manifest로 승인하지 않는다.

신규 relation id 7652는 `H0001_0000→H0022_0000`의 `morphological / compound / asserted / w1_to_w2`, id 7653은 semantic 방향 `H0410_0000→H0022_0000`의 같은 관계다. 후자는 canonical pair 정렬에 따라 `H0022_0000, H0410_0000 / w2_to_w1`로 저장했다. Source는 각각 `RESHET-EC-H22-CLUSTER-H0001-H0022`, `RESHET-EC-H22-CLUSTER-H0410-H0022`이며 선택 metadata는 `NULL`이다. 평행 명단의 인물 대응과 직접 lexical edge를 구분하기 위해 H0022–H0045 relation은 생성하지 않았고 hold operation도 없다.

Dry-run은 exit code 0으로 word note 1건과 relation create 2건을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1787969375217773`의 3행과 원본 work SHA-256 `550155e13dd8db5d55880126a03ab5bba66fec903af7a69e59d9074be7c9532c` 전후 exact 동일을 확인했다. Live apply도 exit code 0이며 work SHA-256은 위 값에서 `c1d3f36bce54c049fc4315f15fc4e0fa8c0357cd27fecf2415574a9aa25a14e6`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260829T021017712611Z/snapshot.db`, 크기 8,372,224바이트, SHA-256 `859cfdd996c803d0cc650bce23ab01241912a7a02fd53a665ce66971921a0a13`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. Live history group `1787969418635585`에는 active word update 1행과 relation create 2행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 H0022 meaning `아비엘 (인)`, 승인 word note, relation id 7652·7653을 exact 확인했고 H0022–H0045 relation은 0건이다. Snapshot의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 차이는 `WORD_TABLE`의 H0022 1행 교체, `WORD_RELATION` 신규 2행, `CHANGE_HISTORY` 신규 3행뿐이다. 다른 9개 사용자 테이블은 동일하며 `word_expression_set` 15,257행과 `word_meaning_set` 18,175행도 불변이다. `WORD_RELATION`은 7,451행에서 7,453행, `CHANGE_HISTORY`는 1,555행에서 1,558행으로 승인 operation 수만큼 증가했다. Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다.

최종 `main` checkout에서 새 manifest를 tracked discovery에 포함해 재생성한 full-data progress는 canonical Strong 14,298건, `explicit_approved=61`, `hold=1`, `unapproved=14,236`, anomaly 113건이며 H22는 새 manifest를 authority로 하는 `explicit_approved / approved`다. Snapshot identity는 `b379d8939692fb1606640d5664029f5161cca83772d248f605f4f2cd97941349`, artifact SHA-256은 JSON `bb9932990d2b3adf781e97f8b349d95a780409a96c95dacbbd03475ff591afa8`, CSV `5efa826d51580b1ce9ae681a1fb70ee6f9a445bcff708827450e53624607ef8a`, Markdown `53c7775bc94b6b191314e030d684f9a5f148351c09d408c8c565c13d78d9364f`이며 같은 최종 checkout 입력의 반복 재생성에서도 세 SHA가 유지됐다. 대상 applicator service 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.27 H23 인명 meaning 병기와 합성·축약 관계 work DB slice

`tool/data_provenance/manifests/h23_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H23-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자의 relation 추천안 수용과 meaning 확정·적용 지시 SHA-256 `23fc7e46225fabef7a86534d8f4daa50dd9f5310d2dfb64e61ca0bb74d8da563`, 적용 manifest SHA-256 `883518fe2098761225e342b6dba040aa6e14832b61c8d2153b6f82fbf1158e52`를 provenance로 고정한다. Meaning replacement는 `H0023_0000`의 `아비아삽 (인)`을 `아비아삽·아비-아사프 (인)`으로, `H0043_0000`의 `에비아삽 (인)`을 `에비아삽·에브야사프 (인)`으로 각각 한 행 안에서 교체한다. 동일 인명의 관용 표기와 원문 기반 표기를 별도 sense로 만들지 않고 가운데점으로 병기했으며, H0023의 하이픈은 H0001·H0622 합성 경계를 보이는 분석 기호다. Word note와 `word_expression_set`은 변경하지 않았고 H0001의 기존 승인은 유지하며 H0622의 독립 meaning은 이번 manifest로 승인하지 않는다.

신규 relation id 7654는 `H0001_0000→H0023_0000`의 `morphological / compound / asserted / w1_to_w2`, id 7655는 semantic 방향 `H0622_0000→H0023_0000`의 같은 관계다. 후자는 canonical pair 정렬에 따라 `H0023_0000, H0622_0000 / w2_to_w1`로 저장했다. Id 7656은 H0023 원형에서 H0043 축약형으로 향하는 `morphological / variant / asserted / w1_to_w2`다. Source는 각각 `RESHET-EC-H23-CLUSTER-H0001-H0023`, `RESHET-EC-H23-CLUSTER-H0622-H0023`, `RESHET-EC-H23-CLUSTER-H0023-H0043`이며 선택 metadata는 `NULL`이다. Relation replacement, supersession과 hold operation은 없다.

Dry-run은 exit code 0으로 meaning replacement 2건과 relation create 3건을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1788054127451976`의 5행과 원본 work SHA-256 `c1d3f36bce54c049fc4315f15fc4e0fa8c0357cd27fecf2415574a9aa25a14e6` 전후 exact 동일을 확인했다. Live apply도 exit code 0이며 work SHA-256은 위 값에서 `0a093606123195a372ca7693307464e20830eabd38ce88cab27de96bd75ddb9f`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260830T014221079828Z/snapshot.db`, 크기 8,380,416바이트, SHA-256 `fad0f67660c2610d698eea4819dc7af567b2e7ee0e2316807a9e79236162d9d8`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. Live history group `1788054141913107`에는 active word update 2행과 relation create 3행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 두 승인 meaning과 relation id 7654~7656을 exact 확인했다. Snapshot의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 `WORD_TABLE`, 전체 `word_expression_set`, 비대상 `word_meaning_set`과 다른 7개 비이력 테이블은 동일하다. 전체 meaning projection 차이는 승인된 두 old row와 두 new row뿐이고, `WORD_RELATION` current-only 3행과 `CHANGE_HISTORY` current-only 5행 외 pre-only 차이는 없다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행은 불변이고 `WORD_RELATION`은 7,453행에서 7,456행, `CHANGE_HISTORY`는 1,558행에서 1,563행으로 승인 operation 수만큼 증가했다. Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다.

최종 `main` checkout에서 새 manifest를 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=63`, `hold=1`, `unapproved=14,234`, anomaly 113건이며 H23·H43은 새 manifest를 authority로 하는 `explicit_approved / approved`다. `core.autocrlf=true` 때문에 working-copy manifest는 CRLF SHA-256 `e87c0dec5192b9f4b4337498c004e42daba220933c9458b86e62174fbd34467a`로 재구성되지만, committed Git blob과 applicator backup manifest는 적용 SHA-256 `883518fe2098761225e342b6dba040aa6e14832b61c8d2153b6f82fbf1158e52`와 exact 일치하며 JSON payload도 동일하다. 이 최종 checkout의 snapshot identity는 `cd2fea199f869716dadefb12ff9019960e6fd8896ba55e2323fd4fb4859e5bee`, artifact SHA-256은 JSON `e0a4b6caffceefec53ae7c4d462754bb2e140c1905886a097d0d5f259bfac077`, CSV `dcf153201a03b37104f375353693ac9e3f828d0b992aff872a39d0c98e222745`, Markdown `ef15fa6c44f1072e2953cc59c62dd7aa2828582da154c90e7a7845779f93b416`이며 반복 재생성에서도 세 SHA가 유지됐다. 공식 Flutter wrapper는 SDK 환경에서 무출력 정체되어 중단했고, 검증된 Flutter tools snapshot runner를 좁은 SDK 쓰기 권한으로 실행한 대상 applicator service 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.28 H25 관계 호칭 meaning과 H1·H1391 구성 관계 work DB slice

`tool/data_provenance/manifests/h25_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H25-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자의 최종 결정 수용과 적용·Git 완료 지시 SHA-256 `42a70e0b483b553d3c2912aabd72753f309b2060643a4fc47daa0790bedc586e`, 적용 manifest SHA-256 `aca53c53dd2127435f76b465892b9911a435f398eed0110df41fdf1c78b1eb29`를 provenance로 고정한다. Meaning replacement는 `H0025_0000`의 `아비 기브온 (인)` 한 행을 `기브온의 아버지` 한 행으로 교체한다. Word note는 이 표현이 H0001 연계형과 H1391 지명이 이룬 관계 호칭임을 밝히고 대상 8:29·9:35의 본문 차이와 선조·시조·성읍 지도자 해석 가능성을 미확정 상태로 보존한다. `word_expression_set`은 변경하지 않았고 H0001의 기존 승인은 유지하며 H1391·H1387·H1393의 독립 meaning은 이번 manifest로 승인하지 않는다.

신규 relation id 7657은 `H0001_0000→H0025_0000`의 `morphological / compound / asserted / w1_to_w2`, id 7658은 semantic 방향 `H1391_0000→H0025_0000`의 같은 관계다. 후자는 canonical pair 정렬에 따라 `H0025_0000, H1391_0000 / w2_to_w1`로 저장했다. Source는 각각 `RESHET-EC-H25-CLUSTER-H0001-H0025`, `RESHET-EC-H25-CLUSTER-H1391-H0025`이며 선택 metadata는 `NULL`이다. Relation replacement, supersession과 hold operation은 없다.

공식 Dart runner는 applicator 시작 전에 telemetry 세션 파일의 `PathAccessException`으로 중단됐고 DB write는 발생하지 않았다. 같은 SDK의 검증된 direct runner로 재실행한 dry-run은 exit code 0으로 meaning replacement 1건, word note replacement 1건과 relation create 2건을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1788060282379000`의 4행과 원본 work SHA-256 `0a093606123195a372ca7693307464e20830eabd38ce88cab27de96bd75ddb9f` 전후 exact 동일을 확인했다. Live apply도 exit code 0이며 work SHA-256은 위 값에서 `14b773bb85d7cb55e5b51807bbf213c1c03c1de70d66892f760541975df1d1f3`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260830T032458166750Z/snapshot.db`, 크기 8,380,416바이트, SHA-256 `bc4a250327f8be0a778114797bd3bb017b4b26f6d2df86f1ab528ec47326f709`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. Live history group `1788060298949613`에는 active word update 2행과 relation create 2행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

독립 read-only SQL에서 승인 meaning·note와 relation id 7657·7658을 exact 확인했다. Snapshot의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 `word_expression_set`을 포함한 8개 비대상 테이블은 동일하다. `WORD_TABLE`과 `word_meaning_set`의 current-only·pre-only 각 1행은 승인된 note와 meaning 교체뿐이고, `WORD_RELATION` current-only 2행과 `CHANGE_HISTORY` current-only 4행 외 차이는 없다. `WORD_TABLE` 15,029행, `word_expression_set` 15,257행, `word_meaning_set` 18,175행은 불변이고 `WORD_RELATION`은 7,456행에서 7,458행, `CHANGE_HISTORY`는 1,563행에서 1,567행으로 승인 operation 수만큼 증가했다. Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다.

새 manifest를 stage해 tracked discovery에 포함한 full-data progress는 canonical Strong 14,298건, `explicit_approved=64`, `hold=1`, `unapproved=14,233`, anomaly 113건이며 H25는 새 manifest를 authority로 하는 `explicit_approved / approved`다. Snapshot artifact SHA-256은 JSON `91eee59cbc118835177dc85ed0b5bae705fec89659eb0153a1f9b8b61dbba26e`, CSV `5f86b895de63a5a6b6b0a6e7cc6ea47dc16909c45b5adec5c915d5a5e0f6cd54`, Markdown `1facd759bd3487025dec17189cef3ca0dff10e326015e74f2648a3fe94911454`이며 반복 재생성에서도 세 SHA가 유지됐다. 검증된 Flutter tools snapshot runner로 실행한 대상 applicator service 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.29 기존 승인 meaning 한국어 표기 정책 정비 work DB slice

`tool/data_provenance/manifests/approved_meaning_notation_policy_correction.json`은 format v5 batch ID `RESHET-EC-APPROVED-MEANING-NOTATION-POLICY-CORRECTION-APPROVED-CONTENT-SLICE`와 사용자 승인 문서 SHA-256 `ea2a93c22f32668df050ab40f0667eed03dbea275513a63488440bf1601e5c8f`를 provenance로 고정한다. 대상은 G0005, H0001, H0002, H0006, H0007, H0017, H0340, H1564, H1618, H1655, H2020, H2646, H3958, H4200, H4461, H5005, H6306, H6378이며, meaning replacement 18건만 포함한다. Word note, relation, hold, schema와 seed DB는 변경하지 않는다. 각 Strong의 현재 ordered projection은 [승인 meaning 한국어 표기 정책 정비 결정](../semantic_decisions/approved_meaning_notation_policy_correction.md)에 기록한다.

Dry-run은 18개 operation을 임시 DB에 적용하고 실제 undo해 원본 work SHA-256 `fc77559add7ccdd64af1360db1673287cd40dadae0eed5adc16f102f418ae0d7`을 전후 동일하게 유지했다. Live apply 뒤 work SHA-256은 `eb89e99f116fa9f8f49a715d0cbc2ed6398b9a18ca763b00ee45c81d05199f3a`이며 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260912T075022811114Z/snapshot.db`, SHA-256 `b0c506fa640744c33f893827f8a9ef8bb88533e5371554e6417990f15b049f2b`이고 live history group `1789199423626046`에는 active word update 18행이 있다.

Snapshot과 현재 DB의 12개 사용자 테이블을 양방향 대조한 결과 승인 대상 `word_meaning_set` projection과 `CHANGE_HISTORY` 18행 외 차이는 없다. `word_meaning_set`은 H1655의 동일 sense 두 행을 한 행으로 합치면서 18,178행에서 18,177행이 됐다. Work·snapshot integrity check는 `ok`, foreign key 위반은 0이고 work·seed SQLite sidecar는 없다. Applicator 대상 Flutter 테스트 29건은 모두 통과했다.

적용 backup manifest SHA-256은 `ea03e105a759c76c27abe2a5531d7f158275eb59268eaadc407f18228e962721`이다. 적용 후 progress authority 검증에서 첫 5-Strong 배치 ID 4건의 명칭 오기를 발견해 최종 manifest의 supersession 대상만 실제 ID `RESHET-EC-FIRST-5-STRONG-APPROVED-CONTENT-SLICE`로 바로잡았다. 최종 manifest SHA-256은 `7d8b32d45b83e07b7cdc4b309eb3fa453374532b7dab3f694e9582606af69665`이고, backup manifest와의 차이는 이 metadata 문자열 4건뿐이며 meaning operation payload는 동일하다.

새 manifest를 명시적으로 포함한 semantic progress는 canonical Strong 14,298건, `explicit_approved=94`, `hold=2`, `unapproved=14,202`, anomaly 113건이다. 18개 대상은 모두 새 manifest를 유일한 active authority로 가지며 현재 DB projection과 exact 일치한다. 산출물 SHA-256은 JSON `d617bb2101d39a44b5b88990d63193ce48f3d04057bf4ece2dc97167fe4ce83e`, CSV `059d52bd92dbb29a7dc070ec6e24a94b93eea7e7b685195477bbce821576a29c`, Markdown `d11567eb619f39229075df21d54151910f5e973090c7912e2b8976bdaf2dbba9`이며 반복 생성에서도 세 값이 동일했다. 같은 세 산출물을 `../reshet_research_output/semantic_progress`에 재생성하고, 출력 루트의 현재값 색인과 관련 Markdown 19개의 갱신 안내를 추가했다. JSON Evidence Packet·research state·database audit은 연구 당시 immutable 스냅샷으로 보존했다. Pre-commit 상태에서 tracked discovery는 새 파일을 자동 발견하지 않으므로 검증 호출에 새 manifest를 명시적으로 전달했으며, 커밋·병합·push는 별도 승인 전까지 수행하지 않는다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.

### 11.30 H0026 분석적 합성 표기 work DB slice

`tool/data_provenance/manifests/h0026_analytic_name_notation_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H0026-ANALYTIC-NAME-NOTATION-APPROVED-CONTENT-SLICE`와 사용자가 승인한 `아비가일·아비갈·아비-가일·아비-갈 (인)`을 provenance로 고정한다. H0026의 ordered meaning 한 행만 교체하며, word note·expression/transliteration·relation·hold·schema와 seed DB는 변경하지 않는다. H0026에 한해 기존 `RESHET-EC-H26-CLUSTER-APPROVED-CONTENT-SLICE`의 meaning authority를 supersede한다.

Dry-run은 meaning replacement 한 건을 임시 DB에 적용한 뒤 실제 undo하여 원본 work SHA-256 `eb89e99f116fa9f8f49a715d0cbc2ed6398b9a18ca763b00ee45c81d05199f3a`을 전후 동일하게 유지했다. Live apply 뒤 work SHA-256은 `71b348a889c5de2a2ddbeae5e235bdf38d28a7349de458a0d7f1cd0413fbc21f`이며 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260912T090312352183Z/snapshot.db`, SHA-256 `a3830c0ca2ce12e623a8e38a2dd43ea8fbe76fcfa2a006cb933351299c93566f`이고 live history group `1789203793160663`에는 active word update 한 행이 있다.

Snapshot과 현재 DB의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 `word_meaning_set`의 승인된 교체 전후 각 한 행과 `CHANGE_HISTORY` current-only 한 행 외 차이는 없다. Work·snapshot integrity check는 `ok`, foreign key 위반은 0이고 work·seed SQLite sidecar는 없다. Manifest SHA-256은 `bcb26ac94a4bda215db1074ca9768038029a0a1c5dc4388dcfe5b43320e2c29c`이다.

기존 18개 표기정비 manifest와 새 H0026 manifest를 명시한 semantic progress는 canonical Strong 14,298건, `explicit_approved=94`, `hold=2`, `unapproved=14,202`, anomaly 113건이다. H0026은 새 manifest를 유일한 active authority로 하는 `explicit_approved / approved`이며 현재 DB projection과 exact 일치한다. 산출물 SHA-256은 JSON `cf1ea41fecfddf6926c99c36caa82745d8adf94cb6ed8de514bd647aab1721ea`, CSV `d348ca2b4aa5280a9abd7d080ec46311e682b6340e79d1df081a351460e75716`, Markdown `72300696f2da89cd83fc1559a8ce6bd8e879a01158040400293dce64776cc7be`이다. 자동 discovery는 suffix 규칙 때문에 `approved_meaning_notation_policy_correction.json`을 포함하지 않으므로, 현재 전수 보고는 이 기존 manifest와 새 H0026 manifest를 모두 명시적으로 전달해 생성했다. 외부 현재값 색인과 H26 summary·review 안내도 같은 meaning으로 갱신했고 연구 당시 JSON 증거는 변경하지 않았다.

Production Dart·schema·seed·UI/UX는 변경하지 않았다. Applicator 구현은 직전 표기정비 slice에서 통과한 대상 테스트 29건과 동일하며, 이번에는 exact manifest dry-run·live apply·snapshot diff로 변경 한 건을 검증했으므로 테스트를 반복 실행하지 않았다. 사용자 UI 수동 테스트는 N/A다. 커밋·병합·push는 별도 승인 전까지 수행하지 않는다.

### 11.31 H0022·H1841·G1158 분석적 합성 표기 work DB slice

`tool/data_provenance/manifests/h0022_h1841_g1158_analytic_name_notation_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H0022-H1841-G1158-ANALYTIC-NAME-NOTATION-APPROVED-CONTENT-SLICE`와 사용자 승인 문서 SHA-256 `06be207a2a89781baeef68bdba881c99921f6ebaa1a9823902a5cabc8a7aa1ae`를 provenance로 고정한다. H0022는 `아비엘 (인)`에서 `아비엘·아비-엘 (인)`, H1841과 G1158은 각각 `다니엘 (인)`에서 `다니엘·다니-엘 (인)`으로 ordered meaning 한 행만 교체한다. Word note·expression/transliteration·relation·hold·schema와 seed DB는 변경하지 않는다. H0022에 한해 기존 H22 manifest, H1841·G1158에 한해 기존 H27 manifest의 meaning authority를 supersede한다.

Dry-run은 meaning replacement 3건을 임시 DB에 적용한 뒤 실제 undo하여 원본 work SHA-256 `71b348a889c5de2a2ddbeae5e235bdf38d28a7349de458a0d7f1cd0413fbc21f`을 전후 동일하게 유지했다. Live apply 뒤 work SHA-256은 `75a44ef1098742cca6cfd91194931cd1fc063c040f7219e82ed635855d711171`이며 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260913T020444075006Z/snapshot.db`, SHA-256 `64d2fbe6b3782db9a4b7248bd84deeaa5c3d10651a21dfb4356ae0221a2347b3`이고 live history group `1789265084936111`에는 active word update 3행이 있다.

Snapshot과 현재 DB의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 `word_meaning_set`의 승인된 교체 전후 각 3행과 `CHANGE_HISTORY` current-only 3행 외 차이는 없다. Work·snapshot integrity check는 `ok`, foreign key 위반은 0이고 work·seed SQLite sidecar는 없다. 적용 manifest와 backup manifest SHA-256은 모두 `e42778640c9252d46ff3ada57d2a6fa295196eb6b4874daeb66f73d48b91d7da`이다.

기존 자동 discovery 대상이 아닌 `approved_meaning_notation_policy_correction.json`을 명시적으로 포함해 재생성한 semantic progress는 canonical Strong 14,298건, `explicit_approved=94`, `hold=2`, `unapproved=14,202`, anomaly 113건이다. 세 대상은 새 manifest를 유일한 active approval authority로 가지며 현재 DB projection과 exact 일치한다. 외부 산출물 SHA-256은 JSON `4979ff2a92f69064a3425aa689747c6fbb571bb7d7c79547b0c52248a1960e97`, CSV `3e108a63f15cbe72cbe86cc91941c2ec73144bbf12fd962e7031a5effbda4173`, Markdown `2f351916049c66c93fb4308ed7fbb57e5b5d0d3dc81dc06c344f927d97a6af55`이다. 외부 현재값 색인과 H22·H27 summary·review 안내도 같은 meaning으로 갱신하고, Evidence Packet·research state·database audit JSON은 연구 당시 immutable 스냅샷으로 보존한다.

Production Dart·schema·seed·UI/UX는 변경하지 않았다. Applicator 구현과 테스트는 직전 승인 slice 이후 변경되지 않았고 이번 exact manifest dry-run·live apply·snapshot diff로 변경 3건을 검증했으므로 applicator 테스트를 반복 실행하지 않았다. 사용자 UI 수동 테스트는 N/A다. 커밋·병합·push는 별도 승인 전까지 수행하지 않는다.

### 11.32 H28 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h28_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H28-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자의 추천안 전체 승인 및 DB·Git 완료 지시 SHA-256 `b7c5554744fcbd9ef747eef62b062362fc08711a955b2803e551381550a4a8c3`, 적용 manifest SHA-256 `5c0e0d6f1bfbf356b44ed93dd617ce94e6dadef0125df0213aa2a6a1fc1ec84e`를 provenance로 고정한다. `H0028_0000`의 active meaning 한 행을 `아비다 (인)`에서 `아비다·아비-다 (인)`으로 교체한다. Word note는 창 25:4와 대상 1:33의 동일 인물 계보, 한국어 성경의 관용 표기와 H0001·H3045 분석 경계, 하이픈의 비마케프 성격, Strong과 reference-only HebGrkKo의 어원 풀이 차이를 기록한다. Expression·transliteration·pronunciation, H0001·H3045의 독립 meaning, hold·schema와 seed DB는 변경하지 않는다.

신규 relation id 7683은 `H0001_0000→H0028_0000`의 `morphological / compound / asserted / w1_to_w2`, id 7684는 semantic 방향 `H3045_0000→H0028_0000`의 같은 관계다. 후자는 canonical pair 정렬에 따라 `H0028_0000, H3045_0000 / w2_to_w1`로 저장했다. Source는 각각 `RESHET-EC-H28-CLUSTER-H0001-H0028`, `RESHET-EC-H28-CLUSTER-H3045-H0028`이며 선택 metadata는 `NULL`이다. Relation replacement, supersession과 hold operation은 없다.

Dry-run은 exit code 0으로 meaning replacement 1건, word note replacement 1건과 relation create 2건을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1789302772814742`의 4행과 원본 work SHA-256 `75a44ef1098742cca6cfd91194931cd1fc063c040f7219e82ed635855d711171` 전후 exact 동일을 확인했다. Live apply도 exit code 0이며 work SHA-256은 위 값에서 `db8d6a6d28801b2aff9b6bf5a6b76a0d29d58bd2b57761cea8571d9561158c69`으로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260913T123315662676Z/snapshot.db`, SHA-256 `5113501b7a8cb822ab846c8de695c3e24fc28891461b1dc60cf26b5bd3391857`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. Live history group `1789302796475698`에는 active word update 2행과 relation create 2행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

Snapshot과 현재 DB의 12개 사용자 테이블을 양방향 대조한 결과 `word_expression_set`을 포함한 8개 비대상 테이블은 동일하다. `WORD_TABLE`과 `word_meaning_set`의 current-only·pre-only 각 1행은 승인된 note와 meaning 교체뿐이고, `WORD_RELATION` current-only 2행과 `CHANGE_HISTORY` current-only 4행 외 차이는 없다. `WORD_RELATION`은 7,482행에서 7,484행, `CHANGE_HISTORY`는 1,669행에서 1,673행으로 승인 operation 수만큼 증가했다. Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 work·seed SQLite sidecar는 0이다.

새 H28 manifest와 자동 discovery 대상이 아닌 `approved_meaning_notation_policy_correction.json`을 명시적으로 포함해 생성한 semantic progress는 canonical Strong 14,298건, `explicit_approved=95`, `hold=2`, `unapproved=14,201`, anomaly 113건이다. H0028은 새 manifest를 유일한 active authority로 하는 `explicit_approved / approved`이며 현재 meaning과 exact 일치한다. Snapshot identity는 `8449969a4be2b256487e69fca1b2fa612b8a073299c5f06e0506527a401d65e3`이고 외부 산출물 SHA-256은 JSON `f834b0767924dc0f72277de686454f81e08de9d62e5dd91803ba35db26a1e8df`, CSV `e5347497cd5828be673155cc043cfbb6d908554818ad90cc4ccb06caa201a0f1`, Markdown `0614aedc91256f544b83356338156ea10bf5c721d6b3ff0ba964cb8945e253b8`이다.

Targeted approved-content applicator 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다. Semantic 결정은 `docs/semantic_decisions/h28_cluster_approved_content_slice.md`에 기록하고 README 색인에 추가했다.

### 11.33 H29 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h29_cluster_approved_content_slice.json`은 format v5 batch ID `RESHET-EC-H29-CLUSTER-APPROVED-CONTENT-SLICE`, 사용자의 semantic 안 승인 및 DB 반영·Git 완료 지시 SHA-256 `3410501498af209b657327a54cd6b16f1c613a1ecdf95cdeee195a2d69e85871`, 적용 manifest SHA-256 `75b5ca53a20d2ef557a4f2ebd9e40d0f3c2e5ca79bea0c48ba05a358d0502ab4`를 provenance로 고정한다. `H0029_0000`과 `G0007_0000`의 active meaning 한 행을 각각 `아비야/아비-야`에서 `아비야·아비-야 (인)`으로 교체한다. 두 word note는 canonical 전 용례의 인명·제사장 반열 문맥, 한국어 관용 표기와 H0001·H3050 분석 경계, 어원 자료 차이와 원천 히브리어 구조의 성격을 기록한다. Expression·transliteration·pronunciation, H0001·H3050의 독립 meaning, hold·schema와 seed DB는 변경하지 않는다.

Relation id 13은 semantic 방향 H0029→G0007의 `transliteration / direct_transliteration / asserted / w2_to_w1`, id 14는 H0001→H0029의 `morphological / compound / asserted / w1_to_w2`, id 5370은 H3050→H0029의 `morphological / compound / asserted / w2_to_w1`로 교체했다. Canonical pair와 relation id는 유지하고 `status_code`를 `inferred`에서 `asserted`로, source를 각각 `RESHET-EC-H29-CLUSTER-H0029-G0007`, `RESHET-EC-H29-CLUSTER-H0001-H0029`, `RESHET-EC-H29-CLUSTER-H3050-H0029`로 변경했으며 선택 metadata는 `NULL`이다. Relation create·supersession·hold operation은 없고 H0021–H0029 relation도 생성하지 않았다.

Dry-run은 exit code 0으로 meaning replacement 2건, word note replacement 2건과 relation replacement 3건을 임시 exact copy에 적용하고 실제 undo해 `did_undo=true`, 임시 history group `1789343822019123`의 7행과 원본 work SHA-256 `db8d6a6d28801b2aff9b6bf5a6b76a0d29d58bd2b57761cea8571d9561158c69` 전후 exact 동일을 확인했다. Live apply도 exit code 0이며 work SHA-256은 위 값에서 `d2aa4704444a529429174fbe36609b1ac490954cd8a33690f20c03e731f7bc5f`로 변경됐고 seed SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 적용 전 snapshot은 `data/backups/approved_content_batch/20260913T235718895850Z/snapshot.db`, SHA-256 `6d9fe59da9acefec8783fc4e022dc4166071eb0346dbc69fd5820a3b30e3695b`이며 source schema version 1368과 snapshot 1369의 차이는 기존 `VACUUM INTO` 계약상 예상된 schema cookie 차이다. Live history group `1789343839802287`에는 active word update 4행과 relation update 3행이 있고 `undone_at`은 모두 `NULL`이며 자동 restore는 실행되지 않았다.

Snapshot과 현재 DB의 12개 사용자 테이블을 양방향 대조한 결과 `word_expression_set`을 포함한 8개 비대상 테이블은 동일하다. `WORD_TABLE`과 `word_meaning_set`의 current-only·pre-only 각 2행은 승인된 note와 meaning 교체뿐이고, `WORD_RELATION` current-only·pre-only 각 3행과 `CHANGE_HISTORY` current-only 7행 외 차이는 없다. `WORD_RELATION`은 7,484행으로 row 수가 유지됐고 `CHANGE_HISTORY`는 1,673행에서 1,680행으로 승인 operation 수만큼 증가했다. Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 SQLite sidecar는 0이다.

새 H29 manifest를 Git-tracked discovery에 포함해 생성한 semantic progress는 canonical Strong 14,298건, `explicit_approved=79`, `hold=2`, `unapproved=14,217`, anomaly 113건이다. H0029과 G0007은 새 manifest를 유일한 active authority로 하는 `explicit_approved / approved`이며 현재 meaning·note와 exact 일치한다. Snapshot identity는 `403330652d5496e1986927968bc28b36b51f1c4a8750c53467302357f9128a38`이고 외부 산출물 SHA-256은 JSON `3599af1ed555c5da487806f2af4bd5e6c07a9c36c8359f19724c226ad9ffe230`, CSV `1303d10451252ac374af4d39d58ea930aab7ee4d3e0bb105a0997c7bfec9b5d7`, Markdown `cc3a55e7cbf084f8cc265c11570e902d03e587911663c644effa47fba41fbca6`이다.

Targeted approved-content applicator 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다. Semantic 결정은 `docs/semantic_decisions/h29_cluster_approved_content_slice.md`에 기록하고 README 색인에 추가했다.

### 11.34 H30 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h30_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H30-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자가 승인한 외부 `00_cluster_summary.md`의 SHA-256 `9c582950de51e87ff8740d8d1f6f885842c4f44d588e8c724cd2458611b18640`를 provenance로 고정하며 적용 manifest SHA-256은 `1f7c038367c708fb11a1c9be0a3367cd5c234ce0088ca5116f27061535d1d078`이다.

H0030 meaning을 `아비후 (인)`에서 `아비후·아비-후 (인)` 한 행으로 교체하고, NULL 비고에 인물 식별·관용/분석 표기 구분·BDB와 Strong의 어원 풀이 차이를 기록했다. H0001→H0030(id 7685, w1_to_w2)과 H1931→H0030(id 7686, w2_to_w1)을 각각 `morphological / compound / asserted`로 생성했다. H1·H1931 의미, expression, hold, schema, seed는 변경하지 않았다.

공식 dry-run은 승인 4작업과 undo에 성공하고 원본 work DB를 보존했다. Live history group은 `1789821998340133`, snapshot은 `data/backups/approved_content_batch/20260919T124637535784Z/snapshot.db`이다. work SHA는 `d2aa4704444a529429174fbe36609b1ac490954cd8a33690f20c03e731f7bc5f`에서 `3d62213308ee031c769236aa9c58d56e6baba2a4ec649fbc2d364cb5e78f1ced`로 변경됐고 seed SHA `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. 독립 전체 테이블/schema 비교에서 승인 변경과 history 4행 외 차이가 없으며 work·seed·snapshot integrity ok, FK 오류·sidecar 0이다.

Progress는 H0030 explicit_approved, 전체 승인 80·hold 2·미승인 14,216·anomaly 113이다. Snapshot identity는 `3f5996c84de9a46a14a87923358803e61736c403f1c1d5f4b214f6a9d85caa97`, JSON SHA-256은 `7d1335354dc9134b998bb85fbccbf5331571eab51fcc8a9eb875ec5ae2d13dfc`다. 이는 적용 시점의 derivative snapshot이다. Targeted applicator 테스트 29건 통과, UI 테스트 N/A. [H30 결정 기록](../semantic_decisions/h30_cluster_approved_content_slice.md)에 최종값·판단 근거·대안·재검토 조건을 기록했다.


### 11.35 H31 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h31_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H31-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자가 외부 연구 추천안을 승인하고 G0010은 간결형을 선택했다. 연구 summary의 UTF-8 LF 정규화 텍스트 SHA-256은 `b7f69726abe78557f59d86585a5f39de19287d1a2e5d9ead7224b496cdaa0d01`, 실제 적용 manifest SHA-256은 `dc1345dd8318d847d07294c5335f29d3d980dfcdae56569258b39761886d9479`다.

H0031·G0010 meaning을 각각 `아비훗·아비-후드 (인)` 한 행으로 교체하고 비고에 어원 풀이 차이, H31의 본문 분석 대안, G10의 헬라어형·원천 이름 분석 표기와 인물 구별을 보존했다. 관계 id 22(H1→H31), 5376(H1935→H31), 21(H31→G10)의 기존 pair/type/direction을 유지하고 inferred→asserted 및 source를 갱신했다. 빈 note와 NULL metadata는 보존했다. H1·H1935 독립 의미, expression·schema·hold·seed는 변경하지 않았다.

공식 dry-run·undo 및 live apply 성공. History group `1789867056755925`, word update 4·relation update 3의 총 7행이며 undone_at NULL이다. Work SHA는 `3d62213308ee031c769236aa9c58d56e6baba2a4ec649fbc2d364cb5e78f1ced`에서 `be51c0c430804b5827f1771383633961192b822c14dbb9bfdabfa15e68f02388`로 변경됐다. Seed SHA `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 동일하다. Snapshot `data/backups/approved_content_batch/20260920T011735914468Z/snapshot.db`와 전체 사용자 테이블·schema를 독립 비교하여 승인 범위 외 변경 없음, work·seed·snapshot integrity ok·FK 오류 0·sidecar 없음 확인.

H0031·G0010 explicit_approved, 전체 승인 82·hold 2·미승인 14,214·anomaly 113이다. Progress snapshot identity `3e460ab553e06e085d78d5ce5c716c709a627e210ceddbee5ea3c9e90ebfa220`, JSON SHA `92c2207f86a124257d457165385ca3b9f0c87be38f4d2577644943d2187d08cd`는 적용 시점의 derivative 기록이다. Targeted applicator 테스트 29건 통과, UI 테스트 N/A. [H31 결정 기록](../semantic_decisions/h31_cluster_approved_content_slice.md)에 최종 결정과 대안·불확실성을 기록했다.


### 11.36 H32 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h32_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H32-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 H32 연구 추천 내용과 DB·문서 반영을 승인했다. 연구 summary raw-byte SHA-256은 `01277f617e21a0a6a2a6b156a21291c4205e5b003c3204dc132745061f46b41b`, 적용 manifest SHA-256은 `aaced8b0bffda2dfd716eca9e4cf7de5ee60e04811d847fe67cca52fcb1fc284`다.

H0032 meaning을 `아비하일·아비-하일 (인)` 한 행으로 교체하고 이름 구성·ח/ה 철자 차이·다섯 인물·어원 및 LXX/대하 본문 해석 한계를 비고에 보존했다. H1→H32(id 7687, w1_to_w2), H2428→H32(id 7688, w2_to_w1)를 morphological/compound/asserted로 신규 생성했다. H1·H2428 독립 의미, expression·schema·hold·seed는 변경하지 않았다.

공식 dry-run·undo 및 live apply 성공. History group `1789884646270777`, word update 2·relation create 2의 4행이다. Work SHA는 `be51c0c430804b5827f1771383633961192b822c14dbb9bfdabfa15e68f02388`에서 `5adbfabff24214f2238d6c106cb9c89e644622be19339647d63769e5db3efae8`로 변경되었다. Snapshot은 `data/backups/approved_content_batch/20260920T061045447061Z/snapshot.db`이며 seed SHA는 기존 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`과 동일하다. 전체 사용자 테이블 독립 비교에서 승인된 변경과 history 외 차이 없음, integrity ok·FK 0·sidecar 없음.

H0032 explicit_approved, 전체 승인 101·hold 2·미승인 14,195·anomaly 113이다. Targeted applicator 테스트 29건 통과, UI 테스트 N/A. [H32 결정 기록](../semantic_decisions/h32_cluster_approved_content_slice.md)에 최종값·대안·불확실성과 검증을 기록했다.

### 11.37 H33 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h33_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H33-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자 최종 검토로 H0033·H0373에 ‘가문 사람’과 기반 인명 병기를 채택하고 H0044·H0372 및 관계 추천을 승인했다. 승인 근거 `08_approved_scope.md` SHA는 `886460e5f5213942c2f76ff4216e472a33669d621180c48af299120ba6813725`, manifest SHA는 `cd7e973c95890e445141dcd42a404685034b620fd6f658d633f8d0e9420d276e`다.

Meaning4·note4·관계6을 반영했다. 관계 id7689–7694는 소속형 파생2·합성2 asserted와 무방향 variant2 hypothesized다. H5829→H0044는 비생성, H0336/H5828→H0372 어원 관계는 보류, 새 word hold는 없다. 정확한 값·채택 이유·한계는 [H33 결정 기록](../semantic_decisions/h33_cluster_approved_content_slice.md)에 보존했다.

공식 dry-run/undo·live apply 성공, history group `1789909426985605` 14행. Work SHA `5adbfabff24214f2238d6c106cb9c89e644622be19339647d63769e5db3efae8` → `62cad49bbca797c9ed22ba0cebb50a94ec5ac9184f144e38d18b2174364a19ea`, seed SHA `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67` 불변. Snapshot `data/backups/approved_content_batch/20260920T130346190802Z/snapshot.db`. 전체 사용자 테이블 독립 비교에서 승인된 행과 history 외 차이 없음; integrity ok·FK0·sidecar0.

CORE4개 explicit_approved, 전체 승인105·hold2·미승인14,191·anomaly113. Applicator 테스트29건 통과, UI 테스트 N/A. Expression·발음·schema·기존 관계·hold ledger·seed는 변경하지 않았다.

Git 정규화 LF manifest blob SHA는 `3fb0ffed97b293921cc26f74cacd1b2869aeacd8bb404743492806876bcbe745`이며 적용 snapshot의 CRLF manifest와 JSON 내용은 동일하다.


### 11.38 H36 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h36_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H36-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-22 연구 제안 전체와 DB/Git 작업을 승인했다. 연구 summary raw-byte SHA는 `d5e868b50ac3e082a931dc61c33a40696191ab339969ffe57548fe72659c2ed6`, 적용 manifest SHA는 `72f8894185b904bb67a7ebe1e6bc77ee7c56f6f1d51e56457a44651c2f4d6c7e`다.

H0036 meaning `아비둡·아비-투브 (인)`과 승인 비고를 반영하고 H1→H36(id 7695, w1_to_w2), H2898→H36(id 7696, w2_to_w1)를 morphological/compound/asserted로 생성했다. 다른 Strong 의미·expression·schema·hold·seed는 변경하지 않았다.

공식 dry-run undo 및 live apply 성공, history group `1790004038806277`. Work SHA `62cad49bbca797c9ed22ba0cebb50a94ec5ac9184f144e38d18b2174364a19ea` → `e55c30fa055e3981ba1d0a9642fe0f5a3888516b89854262be59728af08866f4`. Snapshot은 `data/backups/approved_content_batch/20260921T152037973494Z/snapshot.db`다. 독립 전체 테이블 비교로 승인한 meaning1·note1·relation2 및 history4 외 delta 없음, integrity ok/FK0을 확인했다.

H0036 explicit_approved, 전체 승인 106·hold 2·미승인 14,190·anomaly 113. Targeted applicator 테스트 29건 통과. [H36 결정 기록](../semantic_decisions/h36_cluster_approved_content_slice.md)에 정확한 최종값·대안·불확실성을 기록했다. UI 테스트 N/A.

### 11.39 H37 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h37_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H37-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-22 제안 내용과 DB/Git 실행을 승인했다. 연구 summary raw-byte SHA는 `e456deae31285f261199e8179ece2b5783d4af0ceca626f4a96e139c69a4be39`, 적용 manifest SHA는 `99d42e7c2d9f6031a6e02ec40b5a404939578abac945064c8ef8933b997de7cb`다.

H0037 meaning `아비달·아비-탈 (인)`과 승인 비고를 반영하고 H1→H37(id 7697, w1_to_w2), H2919→H37(id 7698, w2_to_w1)를 morphological/compound/asserted로 생성했다. 다른 Strong 의미·expression·언어·schema·hold·seed는 변경하지 않았다.

공식 dry-run undo 및 live apply 성공, history group `1790032500613835`. Work SHA `e55c30fa055e3981ba1d0a9642fe0f5a3888516b89854262be59728af08866f4` → `838d80faa317b5c286ad5394c685041f02deb8fe07fd5eb00fd171b8360bafc8`. Snapshot은 `data/backups/approved_content_batch/20260921T231459786415Z/snapshot.db`다. 독립 schema/전체 사용자 테이블 비교로 승인한 meaning1·note1·relation2 및 history4 외 delta 없음, integrity ok/FK0/sidecar 없음을 확인했다.

H0037 explicit_approved, 전체 승인 107·hold 2·미승인 14,189·anomaly 113. Targeted applicator 테스트 29건 통과. [H37 결정 기록](../semantic_decisions/h37_cluster_approved_content_slice.md)에 최종값·채택 근거·대안·불확실성을 기록했다. UI 테스트 N/A.

### 11.40 H38 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h38_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H38-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-23 추천 5가지 모두와 DB/Git 실행을 승인했다. 연구 summary raw-byte SHA는 `278e4e76856f5f85dc60fa7df02511931647dcf342215eaabace4d034a1a47a2`, 적용 manifest SHA는 `21549254515b0be1d913edf4200a0a99421f16443f4e44f333942e770cf97d23`다.

H0038 meaning `아비얌·아비-얌 (인)`과 승인 비고를 반영하고 H1→H38(id 7699, w1_to_w2), H3220→H38(id 7700, w2_to_w1)를 morphological/compound/asserted로 생성했다. H29–H38·H8043–H38 관계는 생성하지 않고 H38 hold 없음, H1·H29 기존 승인을 유지했다. 다른 Strong 의미·expression·언어·schema·hold ledger·seed는 변경하지 않았다.

공식 dry-run undo 및 live apply 성공, history group `1790119496601845`. Work SHA `838d80faa317b5c286ad5394c685041f02deb8fe07fd5eb00fd171b8360bafc8` → `47a6f2a858734def654245708a35e87bba2ae622cfd935f80319a24afd148b25`. Snapshot은 `data/backups/approved_content_batch/20260922T232455767799Z/snapshot.db`다. 독립 schema/전체 사용자 테이블 대조로 meaning1·note1·relation2 및 history4 외 delta 없음, integrity ok/FK0/sidecar 없음을 확인했다.

H0038 explicit_approved, 전체 승인 108·hold 2·미승인 14,188·anomaly 113. Targeted applicator 테스트는 DB 쓰기와 분리한 재실행에서 29건 통과했다. [H38 결정 기록](../semantic_decisions/h38_cluster_approved_content_slice.md)에 최종값·채택 근거·대안·불확실성을 기록했다. UI 테스트 N/A.

### 11.41 H39 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h39_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H39-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-24 추천 내용과 DB/Git 완료를 승인했다. 연구 summary raw-byte SHA는 `85e88e329620392b3ceb8453208725840143836e03e7468ec8242faab6786fb5`, 적용 manifest SHA는 `e53246f9d5b3eec6232af1d7acd63dd12d55eea998d17f66dc63743d285363af`다.

H0039 meaning `아비마엘·아비-마엘 (인)`과 승인 비고를 반영하고 H1→H39(id 7701, w1_to_w2)를 morphological/compound/asserted로 생성했다. H410·미확인 마엘 요소의 관계는 생성하지 않고 H39 hold 없음, H1 기존 승인을 유지했다. 다른 Strong·expression·언어·schema·hold ledger·seed는 변경하지 않았다.

공식 dry-run/undo 및 live apply 성공. History group `1790203611119728`, history 3행, snapshot `data/backups/approved_content_batch/20260923T224650308417Z/snapshot.db`. Work SHA는 `47a6f2a858734def654245708a35e87bba2ae622cfd935f80319a24afd148b25`에서 `5c915348421d589674dc35243d4b3c7cb3c7fe6b5b97b7464c369d8a65a6f571`로 변경됐다. 전체 사용자 테이블 독립 대조에서 승인된 변경 외 차이 없음, integrity ok·FK 0·sidecar 없음, seed SHA 불변을 확인했다.

H0039 explicit_approved, 전체 승인 109·hold 2·미승인 14,187·anomaly 113. Targeted applicator 테스트 29건 통과. [H39 결정 기록](../semantic_decisions/h39_cluster_approved_content_slice.md)에 최종값·채택 근거·대안·불확실성을 기록했다. UI 테스트 N/A.

### 11.42 H40·H1125 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h40_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H40-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-27 H1125 다층 분석 표기 조정안을 포함한 의미·비고·관계 및 DB/Git 완료를 승인했다. 승인 내용 raw-byte SHA는 `c1588f2369bbc5963369da0bc03a2228200e70905bc22d2ccab12c291ec3e82b`, manifest SHA는 `3cbab33b012913e5d9e6d5132d96c29b9de5ab6694370b59ddf24ead488e0b27`이다.

H0040 `아비멜렉·아비-멜레크 (인)`, H1125 `벤아비나답·벤-아비-나다브 (인)`과 승인 비고를 적용했다. H1→H40(id 7702, w1_to_w2), H4428→H40(id 7703, w2_to_w1), H1121→H1125(id 7704, w1_to_w2)를 morphological/compound/asserted로 생성했다. H40–H1125는 비생성, H41→H1125는 생성 보류이며 word-level hold·source·seed·schema 변경은 없다.

공식 dry-run/undo 및 live apply가 성공했다. 독립 snapshot 대조는 WORD_TABLE 2행·word_meaning_set 2행 교체, WORD_RELATION 3행·CHANGE_HISTORY 7행 추가만 확인했다. History group `1790466814169456`, snapshot `data/backups/approved_content_batch/20260926T235333388907Z/snapshot.db`. Work SHA는 `5c915348421d589674dc35243d4b3c7cb3c7fe6b5b97b7464c369d8a65a6f571`에서 `d1710e4e0cb10de5c3cb363b7a3521290d97e6308abb1cb3bd462e89f9c7ccc4`로 변경됐고 seed SHA `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다. Integrity ok, FK 0, sidecar 없음.

두 단어 explicit_approved, 전체 승인 111·hold 2·미승인 14,185·anomaly 113. [H40·H1125 결정 기록](../semantic_decisions/h40_cluster_approved_content_slice.md)에 최종값·표기 선택 이유·관계 보류를 기록했다. UI 테스트 N/A.

### 11.43 H41 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h41_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H41-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-27 추천 meaning·비고·합성 관계와 DB/Git 완료를 승인했다. 승인 내용 SHA는 `c9cf8669172b1b2e9c75cd30e27539d644293617f315037affe2eee6cbcf3c4b`, 적용 manifest SHA는 `81dc2b11a2db4e9e817703bcb14b775d591dca2ca02331d722097c503ac47e32`다.

H0041 `아비나답·아비-나다브 (인)`과 승인 비고를 적용하고 H1→H41(id 7705, w1_to_w2), H5068→H41(id 7706, w2_to_w1)를 morphological/compound/asserted로 생성했다. H41→H1125 생성 보류와 H41–H3440·추정 Greek 관계 비생성을 유지했다. 다른 단어 의미·expression·언어·hold ledger·source·schema·seed는 변경하지 않았다.

Work SHA `d1710e4e0cb10de5c3cb363b7a3521290d97e6308abb1cb3bd462e89f9c7ccc4` → `5acab4442be19539a36199842bf09ca5f7b051d2d4328d7a10aca2e88d3dab4f`. Seed SHA `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67` 불변. History group `1790506379385621`, active 4행. Snapshot 및 독립 검증은 `data/backups/approved_content_batch/20260927T105258568895Z/`에 보존했다. 전체 테이블 대조에서 승인된 word·meaning 1행씩 교체, relation 2행·history 4행 추가만 확인했다. Integrity ok, FK 0, sidecar 없음.

H41 explicit_approved, 전체 승인 112·hold 2·미승인 14,184·anomaly 113. Targeted applicator 테스트 29건 통과. [H41 결정 기록](../semantic_decisions/h41_cluster_approved_content_slice.md)에 최종값·채택 근거·대안·불확실성을 기록했다. UI 테스트 N/A.

### 11.44 H42 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h42_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H42-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-09-28 추천 의미·비고·관계 및 DB/Git 완료를 승인했다. 승인 내용 SHA는 `c3a6f77d574acac5271d011434b85ccd281c102ffe9f6a1cf0fd8855408c736c`, 적용 manifest SHA는 `574aaaccf32f3649ccabeeb6154fe9ccb05d0b47943fbd57e20c2b1bcb383208`이다.

H0042 `아비노암·아비-노암 (인)`과 승인 비고를 적용하고 H1→H42(id 7707, w1_to_w2), H5278→H42(id 7708, w2_to_w1)를 morphological/compound/asserted로 생성했다. H42 hold 없음, 간접 파생·공통 구성 요소에 근거한 직접 관계 및 추정 Greek 관계는 비생성이다. 다른 단어 의미·expression·언어·hold ledger·source·schema·seed는 변경하지 않았다.

Work SHA `5acab4442be19539a36199842bf09ca5f7b051d2d4328d7a10aca2e88d3dab4f` → `112f7c58b1a5ff753c4f577551a503542db63c31e97a0122c2e8453c870f8246`. Seed SHA `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67` 불변. History group `1790553731644648`, active 4행. Snapshot 및 독립 검증은 `data/backups/approved_content_batch/20260928T000210845097Z/`에 보존했다. 전체 사용자 테이블 비교에서 승인 word·meaning 1행씩 교체, relation 2행·history 4행 추가만 확인했다. Integrity ok, FK 0, sidecar 없음.

H42 explicit_approved, 전체 승인 113·hold 2·미승인 14,183·anomaly 113. [H42 결정 기록](../semantic_decisions/h42_cluster_approved_content_slice.md)에 최종값·채택 근거·대안·불확실성을 기록했다. UI 테스트 N/A.

## 12. pronunciation profile·migration 현행 경계

### 12.1 active pronunciation 계약

Reshet의 active pronunciation은 언어별로 승인된 profile에 맞는 IPA만 사용한다. 기본 정밀도는 broad phonemic transcription이며, 다음 공통 원칙을 적용한다.

- 하나의 active pronunciation에는 승인된 profile의 대표 IPA 하나만 저장한다. 대체 발음은 active 값에 함께 넣지 않는다.
- 승인된 profile과 다른 시대·지역 체계를 fallback으로 사용하지 않는다.
- 검증 가능한 profile 일치 자료가 없으면 추측하거나 음역을 IPA처럼 취급하지 않고 `NULL`을 유지한다.
- `ipa_phonemic`과 `ipa_phonetic` 값은 slash·bracket을 붙이지 않은 본문만 저장하고 notation metadata로 해석을 구분한다. Strong식 표기·기타 형식·미분류 legacy 값은 각각 `strong_dictionary`, `other`, `unknown`으로 구분할 수 있다.
- UI·검색 결과·복사는 공통 formatter를 사용해 `ipa_phonemic`은 `/본문/`, `ipa_phonetic`은 `[본문]`, 나머지는 본문으로 표시한다.
- notation metadata는 표기 형식을 나타낼 뿐 profile 승인, 원천 또는 라이선스를 입증하지 않는다. `unknown` backfill도 기존 값의 출처를 새로 확정하지 않는다.

승인된 언어별 profile은 다음과 같다.

| DB 언어 값 | 승인된 pronunciation profile |
| --- | --- |
| `히브리어` | 재구성 티베리아 성서 히브리어(Reconstructed Tiberian Biblical Hebrew) |
| `헬라어` | 서기 1세기 코이네 그리스어 재구성(Reconstructed 1st-century CE Koine Greek) |
| `라틴어` | 재구성 고전 라틴어(Reconstructed Classical Latin) |
| `영어` | 일반 미국 영어(General American English) |

DB의 `헬라어` label은 정책상 Greek에 해당한다. 위 네 profile은 pronunciation 목표를 승인한 것이며, 실제 원천·판본·라이선스·stable key를 승인한 것은 아니다.

### 12.2 현행 구현과 데이터 신뢰 경계

확인된 현행 구현에서 `pronunciation`은 schema·model·repository 전 구간에서 nullable이고, `pronunciation_notation`, `pronunciation_notation_name`은 표기 방식 metadata로 함께 이동한다. 빈 pronunciation write는 세 필드를 모두 `NULL`로 정규화하며, 본문이 있는 기존·legacy 행은 notation을 `unknown`으로 해석한다. normalized write, history·undo와 backup·restore는 같은 typed validation을 사용하고, 상세 화면·검색 결과·개별 복사·전체 상세 복사는 같은 formatter를 사용한다. pronunciation은 검색 대상, 정렬·filter 기준 또는 identity로 사용되지 않으며 graph에도 표시하지 않는다. notation은 provenance가 아니므로 별도의 source column은 추가하지 않았다.

Phase 50-R 이후 직접 재확인한 현행 규모와 기존 pronunciation 신뢰 상태는 다음과 같다.

| 항목 | 확인된 수 |
| --- | ---: |
| 전체 expression | 15,237 |
| `pronunciation IS NOT NULL` | 15,038 |
| `pronunciation IS NULL` | 199 |
| `pronunciation_notation = unknown` | 9,649 |
| `pronunciation_notation = strong_dictionary` | 5,389 |
| pronunciation·notation 무효 조합 | 0 |
| 형식상 IPA 후보(Phase 50-O 기준 참고치) | 576 |
| 승인 profile과 항목별 provenance가 함께 검증된 IPA | 0 |

Phase 50-O에서 형식만으로 분류한 IPA 후보 576건을 모두 잘못된 값으로 단정하지 않는다. 이 수치는 Phase 50-R 뒤 IPA cohort를 재분류한 현행 집계가 아니라 기존 신뢰 경계의 참고치다. IPA처럼 보인다는 사실만으로는 승인 profile과 provenance가 확인되지 않으므로 cohort D로 분류한다. Phase 50-R의 `strong_dictionary` 값은 IPA 승인이나 profile 검증을 뜻하지 않으며, 승인 profile과 항목별 provenance가 함께 검증된 IPA는 여전히 0건이다.

### 12.3 언어 경계

- `히브리어`, `헬라어`, `라틴어`, `영어`는 승인 profile이 있으므로 언어별 read-only 원천 조사 후보가 된다. 원천명, 판본, 라이선스와 stable key는 아직 승인되지 않았다.
- `아람어`는 실제 데이터가 존재하지만 별도의 profile·원천 조사가 필요하다. 히브리어 profile을 자동 적용하지 않으며, profile 결정 뒤 별도 migration 대상으로 다룬다.
- `히브리어/아람어`는 독립된 pronunciation 언어가 아니라 expression 언어가 아직 확정되지 않은 임시 label이다. 해당 19단어·19 expression은 전체 migration에서 제외하지 않고 `F-language`로 포함한다. 각 expression의 언어를 먼저 판정한 뒤 히브리어이면 승인된 히브리어 profile, 아람어이면 향후 승인될 아람어 profile을 적용한다. 판정 근거나 검증 가능한 원천이 부족하면 `NULL`로 둔다.
- `H1551_0000`의 canonical 언어 판정은 완료됐다. CrossWire StrongsHebrew 1.2 RawLD의 H1551 항목에서 Galiylah를 H1551의 prolonged form으로 설명하므로 `WORD_TABLE.언어`는 `히브리어/아람어`에서 `히브리어`로 정규화했다. 따라서 H1551은 더 이상 `F-language` 미판정 대상에 포함하지 않는다.
- `H0000_0016`의 canonical 언어 판정은 완료됐다. CrossWire StrongsHebrew 1.2 RawLD의 H2053 항목에서 vav를 히브리어 여섯째 글자의 이름으로 설명하므로 `WORD_TABLE.언어`는 `히브리어/아람어`에서 `히브리어`로 정규화했다. H2053은 언어 판정 근거로만 사용했으며 H0000_0016의 Strong 번호 배정이나 `H2053_0000`과의 병합을 의미하지 않는다. 따라서 H0000_0016은 더 이상 `F-language` 미판정 대상에 포함하지 않는다.
- 고대 페르시아어, 독일어, 러시아어, 아카드어, 우가릿어, 이탈리아어에는 승인된 profile이 없다. profile을 임의로 만들거나 자동 IPA migration을 적용하지 않으며, 검증 가능한 자료가 없으면 `NULL`로 둔다. DB 집계·migration selector에서는 활성 DB의 canonical 언어 값 `아카드어`, `우가릿어`를 사용한다.

### 12.4 migration DB와 backup 경계

pronunciation migration의 active 대상은 `data/reshet_work.db`와 `data/reshet_seed.db`의 canonical `word_expression_set`이다. `WORD_TABLE.발음1~6`은 2026-08-01 물리 제거됐으므로 이후 본문 migration은 legacy projection에 dual-write하지 않는다. 아래 Phase별 legacy projection 설명은 각 적용 시점의 historical 기록으로 유지한다.

Phase 50-O는 두 active DB의 normalized table에 notation 열을 추가하고 기존 non-NULL pronunciation 15,036건을 `unknown`으로 보강했다. pronunciation 본문과 legacy projection은 변경하지 않았고 legacy slot도 추가하지 않았다. 기존 값을 `strong_dictionary`로 자동 전환하지 않았으며 notation은 형식 metadata이므로 원천을 뜻하는 source column도 추가하지 않았다.

Phase 50-Q는 위 Greek·Hebrew 고정 XML을 공식 전자 재구축 원천으로 채택하고 source manifest, 결정적 mapping과 read-only dry-run 경계를 추가했다. 당시에는 active work·seed DB의 spelling·pronunciation·notation, expression 구조, representative와 legacy projection에 반영하지 않았고, 실제 DB migration을 Greek와 Hebrew로 분리한 후속 production phase의 별도 승인·검증 대상으로 남겼다.

Phase 50-R은 Phase 50-Q plan 중 Greek `auto` 5,326단어·5,389 expression만 `data/reshet_work.db`와 `data/reshet_seed.db`에 반영했다. 적용 전 `G0153_0000 / seq 1`의 normalized pronunciation과 legacy `WORD_TABLE.발음1` 사이에 선행 공백 한 글자 차이가 확인되어, normalized 값을 canonical로 유지하고 두 DB의 `발음1`만 길이 21에서 20으로 exact 보정했다. 이 선행 보정은 normalized expression, 다른 legacy field, `CHANGE_HISTORY`와 schema를 변경하지 않았다.

Greek auto migration은 spelling 5,238건, pronunciation 316건, notation 5,389건을 변경했다. spelling 변경 5,238건은 모두 NFC-equivalent였고, notation-only 변경은 136건이다. legacy `표기N`은 5,238건, `발음N`은 316건을 normalized 값과 함께 갱신했다. Greek exception 197단어, Greek source-only hold 101단어, Hebrew 전체, transliteration·Strong ID·language·word_id·seq·representative, expression 생성·삭제와 `CHANGE_HISTORY`는 변경하지 않았다. migration 후 work·seed의 14,365행 Strong 의미 projection은 동일하고, 임시 DB 복사본의 두 번째 실행은 실제 변경 0건·no-op 5,389건이었다.

재현 도구는 `tool/data_provenance/strong_source_migration.py`, targeted fixture는 `tool/data_provenance/test_strong_source_migration.py`, compact 결과는 `tool/data_provenance/migrations/phase50r_greek_auto.json`에 둔다. migration plan SHA-256은 `38136c17976ce5b0565bfcfef7b8d40e4b8b08d60a531fd6bed4c5aee4cdd0a5`다. Phase 시작 work·seed SHA-256은 각각 `fc0b7839d307c5543cbec70e54df91d2767ae6bcc430aa03cfb00eb4ebe2707e`, `120d68883b32354cf1ab48f83b90453ee02b3601803a7c2e6de6e47df6c424f7`이고, G0153 보정 후에는 `3efb41d8fc94a3db68fc7025f0a2f36f41e009fc01e2fc1d3a35231a23b68d53`, `82f1daad9f7e714ed3872ed1ac1df96627c42a5bb151c23930d1576055c4d7b2`, 최종 migration 후에는 `63f5ab90df5c813449b91098847e159bcd5411fc9fcf0827fc790e5ef3a6f847`, `284d4ca1ff4eb55fbf23de1ea5da1eeee3451f6ceb6c66e274e5a60d679f5c33`이다. 대형 plan·source XML과 pre-repair 및 post-repair/pre-migration backup은 ignored local artifact로 유지한다.

Phase 50-T는 Phase 50-S에서 확정한 Greek E0 183단어·190 expression의 pronunciation 본문과 legacy `발음N`을 그대로 유지하고 `pronunciation_notation`만 `unknown`에서 `strong_dictionary`로 변경했다. 기준 원천은 MorphGNT `strongs-dictionary-xml`의 commit `dd6758b82f46b620804a8ea677d715844679eea1`, `strongsgreek.xml`, SHA-256 `91474213b208a4e487d35f85c10e5c90737acc69082dad15dec5431406003545`다. E4 11건과 E5 23건, Hebrew·Aramaic은 보류 상태를 유지했고, spelling·transliteration·meaning·language·Strong identity·word_id·seq·representative, `WORD_TABLE`의 `표기N`·`음역N`·`발음N`, schema와 `CHANGE_HISTORY`는 변경하지 않았다.

적용 전후 notation 집계는 work·seed 각각 `NULL` 199건 유지, `strong_dictionary` 5,389건에서 5,579건, `unknown` 9,649건에서 9,459건이다. work SHA-256은 `4de82abc3a1476b8cc34820e6ac4b6903ddf3728c29d3a880c089ccc1b8a0866`에서 `947bb5f9f0526cb5d8b4679509611fa8e513abb5c8165674cd52c7fa75188e0b`, seed SHA-256은 `284d4ca1ff4eb55fbf23de1ea5da1eeee3451f6ceb6c66e274e5a60d679f5c33`에서 `e785d0fdf6e200c57c51b1f634819e86363426ace06bffc5cb0a897298083767`로 변경됐다. 두 DB의 전체 파일 SHA는 서로 다른 독립 경계이며, 적용 후 14,365행 Strong 의미 projection은 SHA-256 `25be4ab4aebf7c42e09595cc3f4bf57c0a9832d7df03c2bead97c2918bbf7252`로 exact parity를 유지했다. 양쪽 `integrity_check`는 `ok`, foreign key 위반은 0이고, active DB 두 번째 실행은 transaction·backup·DB write 없이 `이미 적용됨 — 변경 0`과 DB·result SHA 불변을 확인했다.

입력 manifest는 `tool/data_provenance/manifests/phase50t_greek_legacy_strong_notation.json`이며 파일 SHA-256은 `3b69360633c18d38ebb4c221bfaaefe7d64c8b9de0f815c84983167b9d0e2775`, candidate projection SHA-256은 `0e20117dc7a7319172574bf395a7130f5ee235b5de73958a76c72715f1abecbf`다. 전용 도구와 targeted test는 각각 `tool/data_provenance/phase50t_greek_legacy_strong_notation.py`, `tool/data_provenance/test_phase50t_greek_legacy_strong_notation.py`이고, 결과 manifest는 `tool/data_provenance/migrations/phase50t_greek_legacy_strong_notation_result.json`, 파일 SHA-256은 `9c7a84f83cd6e5a353a1778aa4c95aed30171442dbe6d4704d5698f802fb91ea`다. 적용 전 verified byte backup은 ignored 경로 `data/backups/phase50t/20260718T154557_729817Z`에 유지한다.

Phase 50-V 전체 작업 유형은 repository work·seed DB metadata 변경, migration tooling, manifest, result artifact, targeted test와 provenance 문서를 함께 포함하는 **Metadata-only Small Production DB Slice**다. 현재 마지막 하위 단계는 문서 경계 반영·마감 검증이다.

Phase 50-V 1차 preflight는 Hebrew·Aramaic의 기존 pronunciation 본문과 legacy `발음N`이 Open Scriptures `HebrewLexicon` XML primary와 exact인 738단어·771 expression을 metadata-only 후보로 고정했다. 기준 원천은 commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`의 `HebrewStrong.xml`, SHA-256 `a628f4f89f8bdaf2483fd3faf1abc8653cc6717758dfc9f24beb7571d9bdd0c4`, CC BY 4.0이며 `Open Scriptures Hebrew Bible Project` attribution을 유지한다. parser contract `hebrew_direct_w_v1`은 `entry`의 직접 자식 `w@pron`만 사용하고 중첩 참조 `w`는 제외한다. `openscriptures/strongs` raw DAT와 generated JS는 Phase 50-S의 756 expression 경계를 설명하는 historical audit source일 뿐 Phase 50-V의 canonical source나 migration dependency가 아니다.

Phase 50-S 756 expression은 Phase 50-V XML exact 771 expression에 완전히 포함된다. XML 전용 15 expression은 raw DAT language marker 차이 13건과 XML·DAT pronunciation 값 차이 2건이며, manifest의 `historical_phase50s_member`, `xml_only_reason`, `historical_source_difference`로만 설명한다. 변경 selector는 이 historical 원천에 의존하지 않는다. Hebrew는 698단어·730 expression, Aramaic은 40단어·41 expression이고 work·seed identity·semantic projection, normalized·legacy pronunciation과 source primary가 exact parity다.

입력 manifest는 `tool/data_provenance/manifests/phase50v_hebrew_aramaic_strong_notation.json`이며 파일 SHA-256은 `6b0c0c3c18c1f4142ca6dacbdc9a5742ed8d20e7bea61a0167227406ea0aa9d7`, candidate projection SHA-256은 `ffed5f3c430597b42f5f318b023fe23ac5b09792e4e7a58e04f14266a23b03c8`다. projection은 manifest에 명시된 22개 필드 순서의 JSONL ordered arrays이며 언어 순서 `히브리어`·`아람어`, `word_id ASC`, `seq ASC`로 정렬한다. UTF-8, BOM 없음, `ensure_ascii=false`, compact separators와 final LF를 사용한다. 전용 도구와 targeted test는 각각 `tool/data_provenance/phase50v_hebrew_aramaic_strong_notation.py`, `tool/data_provenance/test_phase50v_hebrew_aramaic_strong_notation.py`다.

2026-07-19 Phase 50-V 적용은 `data/reshet_work.db`와 `data/reshet_seed.db`에서 위 manifest의 771 expression(Hebrew 730, Aramaic 41)에 대해 `word_expression_set.pronunciation_notation`만 `unknown`에서 `strong_dictionary`로 변경했다. work SHA-256은 `313a4770be2df025bbb8685d59a072233e64aaa4d54011f38e341887b7b0cf22`에서 적용 직후 보고 SHA `aa3d3441cb28c1dfa6ea9bb18927538a5352793c527d5bac1a7e53075f780f93`로, seed SHA-256은 `e785d0fdf6e200c57c51b1f634819e86363426ace06bffc5cb0a897298083767`에서 `c25cf32acdc8c1351ef84fed45bc304d7a72924660fbf135ae6c1e3bf5660697`로 변경됐다. 적용 후 target 771건은 모두 `strong_dictionary`, `pronunciation_notation_name = NULL`, normalized·legacy·source primary exact이며 work·seed target immutable projection SHA-256 `b235d9f54bea50c2cebff3cf78b414e6b48406bbbc58fb3fb3b4fbf3ea4cdfb3`로 parity를 유지한다.

적용 전후 target immutable fields, non-target expression, 전체 expression의 notation 외 필드, `WORD_TABLE`, `CHANGE_HISTORY`와 schema projection은 각 DB 안에서 동일하고 integrity check는 `ok`, foreign key 위반은 0이다. 동일 도구의 두 번째 실행은 backup·transaction·result rewrite 없이 `이미 적용됨 — 변경 0`을 확인했다. 결과 artifact는 `tool/data_provenance/migrations/phase50v_hebrew_aramaic_strong_notation_result.json`, 파일 SHA-256은 `9b96be917075c46ab6f4a616999a1d7ce090f416e7c82b708ad37109861d91b5`이며, 적용 전 verified backup은 ignored 경로 `data/backups/phase50v/20260719T111222_492354Z`에 유지한다.

현재 마감 시점의 work DB 물리 SHA-256은 `9aa81325dc20e48c3fe59236a8d95f5d3602700bd3912d9bbdfaa92cc3cbeef4`, seed DB 물리 SHA-256은 `c25cf32acdc8c1351ef84fed45bc304d7a72924660fbf135ae6c1e3bf5660697`이다. work DB 물리 SHA는 적용 직후 보고값과 현재 마감 시점이 다르지만 이번 마감 감사 시작·종료 사이에는 불변이었다. 물리 SHA 차이의 원인은 이 Phase에서 다시 조사하지 않는다. 마감 postflight에서도 manifest 771건은 모두 `strong_dictionary`, `unknown` 0건이고 work·seed target semantic diff는 0, target immutable SHA-256은 `b235d9f54bea50c2cebff3cf78b414e6b48406bbbc58fb3fb3b4fbf3ea4cdfb3`, 양쪽 integrity check는 `ok`, foreign key 위반은 0, SQLite sidecar는 0이다.

Phase 50-V의 repository work·seed DB와 Android packaged seed에는 위 771건이 적용되어 있다. Windows UI 테스트는 repository work DB를 사용한 H0001·H0002·H1325·H0217 사례에서 `Strong 사전식` 표시로 통과했다. Android 기존 설치 UI 테스트도 수행했으나 `표기 체계 미상` 표시로 실패를 확인했다. 확정 원인은 기존 설치가 app-private `reshet_work.db`를 유지하고 packaged seed 업데이트를 자동 병합하지 않아 Phase 50-V 771건이 전달되지 않은 것이다. 현재 해결 상태는 미해결·의도적 보류이며, 추가 Android UI 재검증은 최종 DB 확정 후 배포 전 runtime migration 구현 뒤 수행하므로 현재 단계에서는 N/A다. 이는 해결 완료 상태가 아니라 최종 배포 DB 확정 뒤 통합 검증으로 이관한 active boundary다.

기존 Android work DB에는 사용자 편집 데이터가 존재하므로 앱 데이터 삭제나 DB 전체 교체를 해결책으로 사용하지 않는다. 기존 설치 DB용 조건부·idempotent data migration은 최종 데이터베이스 확정 후 배포 전 단계에서 구현·검증하며, Android release 검증 전까지 이 propagation 경계를 배포 blocker로 취급한다. **배포 전 필수 후속: Android 기존 설치 runtime DB migration 및 release 검증.** 이 시점에는 migration 세부 설계나 771 identity payload 형식을 확정하지 않는다.

G0185 legacy pronunciation parity repair는 MorphGNT `strongs-dictionary-xml` 고정 commit `dd6758b82f46b620804a8ea677d715844679eea1`의 `strongsgreek.xml`, SHA-256 `91474213b208a4e487d35f85c10e5c90737acc69082dad15dec5431406003545`를 다시 확인했다. G0185의 source-owned 머리부는 `ἀκέραιος`와 pronunciation `ak-er'-ah-yos` 한 건이며, `G2767`은 `strongs_derivation` 내부 Strong 참조다. normalized expression은 원래 seq 1 한 행으로 정확했으므로 변경하지 않고, active work·seed DB의 `G0185_0000`에서 legacy `WORD_TABLE.발음2='G2767'` 두 셀만 `NULL`로 수선했다.

work SHA-256은 `9aa81325dc20e48c3fe59236a8d95f5d3602700bd3912d9bbdfaa92cc3cbeef4`에서 `e5fff68a1538fe56826455133d1b4dd7fbdf23fd9d94ac7f08a6dcfa59585510`, seed SHA-256은 `c25cf32acdc8c1351ef84fed45bc304d7a72924660fbf135ae6c1e3bf5660697`에서 `7ca9da527bae12aedc2883c8886580070e5b2a82a1974cf3c1240a5792d0ee3e`로 변경됐다. schema, normalized expression·meaning, `WORD_RELATION`, `CHANGE_HISTORY`, G0185의 다른 legacy 컬럼과 다른 모든 단어는 전후 projection이 동일하다. 양쪽 `integrity_check`는 `ok`, foreign key 위반과 SQLite sidecar는 0이며, 동일 apply의 두 번째 실행은 backup·transaction·DB write·result rewrite 없이 `이미 적용됨 — 변경 0`을 확인했다.

입력 manifest는 `tool/data_provenance/manifests/g0185_legacy_pronunciation_repair.json`, 파일 SHA-256 `359a45c4a4d1d1477377b764be18bfe480c15f218f0714ce28ffafbb4470f39c`, candidate projection SHA-256 `0b3f8240493528aa01d02e71517d66e06e691120a0616c8488e94b302f2bdce7`이다. 전용 도구와 targeted test는 각각 `tool/data_provenance/g0185_legacy_pronunciation_repair.py`, `tool/data_provenance/test_g0185_legacy_pronunciation_repair.py`이며, 결과 artifact는 `tool/data_provenance/migrations/g0185_legacy_pronunciation_repair_result.json`, 파일 SHA-256 `dc3540a63bc9564650b8d441b9a6e0f5b3930c9aeeabc1f7123eb0aea1909f2b`다. verified byte backup은 ignored 경로 `data/backups/g0185_legacy_pronunciation_repair/20260719T163238_681985Z`에 유지한다.

Strong source reconciliation parity에서는 사용자 편집 `WORD_TABLE.비고`를 제외한다. 따라서 work의 `G0025_0000.비고='48-B3 백업 시점'`과 seed의 `NULL` 차이는 유지했고 양쪽 G0025 행을 변경하지 않았다. 이 repair는 repository active work·seed에만 적용했으며 Android runtime DB와 기존 설치 DB에는 아직 전파하지 않았다.

`data/bbwdb_20260106.db`는 향후 사용하지 않기로 결정된 보존 원본이므로 pronunciation migration과 schema 변경 대상에서 제외한다. 이 파일을 수정·재생성·삭제하지 않는다. 2026-08-02 runtime filename fallback을 제거했으며 설치·work DB 최초 생성·reset은 `reshet_seed.db`만 seed로 사용한다. 보존 원본은 runtime authority나 fallback seed가 아니다.

historical backup은 변형하지 않은 원본으로 보존한다. 전체 SQLite backup은 `pronunciation`을 별도로 정규화하거나 변환하지 않고 당시 DB 상태 그대로 포함한다.

### 12.5 원천 수용 조건

향후 IPA 원천은 다음 조건을 모두 검토한 뒤에만 채택한다.

- 대상 언어와 승인 profile의 일치
- 재현 가능한 판본·버전 식별자
- expression 항목별 provenance
- 라이선스와 attribution 조건
- 재현 가능한 stable key
- 명시적인 1:1 대응 또는 복수 후보 처리 규칙
- broad phonemic IPA로 정규화 가능한 구조
- import·diff·manifest 재현성과 원천 버전 비교 가능성

Strong 번호만으로 모든 expression의 IPA를 자동 확정할 수 없다. variant·secondary expression과 같은 철자의 충돌은 stable key와 명시적 후보 규칙으로 처리해야 한다.

### 12.6 migration cohort와 선행 예외

| cohort | 분류 기준 | 처리 경계 |
| --- | --- | --- |
| A | 승인 profile과 항목별 provenance가 검증된 IPA | 검증 근거와 함께 유지 가능 |
| B | non-IPA이며 승인 원천과 stable key로 1:1 대응 | dry-run 확인 뒤 자동 교체 후보 |
| C | 복수 후보·variant·충돌로 대응이 모호함 | 자동 교체 금지, 개별 판정 |
| D | 형식상 IPA이나 provenance 또는 profile이 불명확함 | 근거 확인 전 active IPA로 인정하지 않음 |
| E | 검증 가능한 IPA 원천이 없음 | `NULL` 유지 |
| F | 언어 또는 identity 등 데이터 자체의 선행 검토가 필요함 | 원천 매칭 전에 데이터 판정 |

선행 조사에서 cohort F에는 `히브리어/아람어` 19 expression의 `F-language`와 tab 문자가 포함된 word ID `L0000_0003\t`의 `F-identity`가 포함됐다. 재사용 가능한 다른 선행 예외는 pronunciation 첫 문자에 carriage return이 있는 `G2943_0000`, 철자 없이 legacy slot 2에 pronunciation `G2767`만 있는 `G0185_0000`이다. slash 포함 59건과 괄호 포함 26건은 순수 IPA 저장 규칙 대조를 위한 형식 신호이며, 그 자체만으로 잘못된 값이라고 확정하지 않는다.

2026-10-10 후속 사용자 승인으로 작업 DB의 `L0000_0003\t`와 표현·뜻·관계·수정 이력 참조를 `L0000_0003`으로 교정해 해당 identity 예외를 정리했다. seed DB와 기존 seed 발음 보류 manifest는 보존하며 다음 seed 갱신 때 승인값과 별도로 맞춘다. 적용 범위와 전후 검증은 [라틴어 정비 결정](../semantic_decisions/latin_expression_approved_content_slice.md#id-말미-tab--후속-승인으로-정리-완료)을 따른다.

현재 확정할 수 있는 것은 위 분류 기준과 확인된 예외뿐이다. cohort A~F의 실제 배정은 원천 검증 결과에 따라 달라지며, 원천 채택 전에 B·C·E의 최종 건수를 선언하거나 모든 행을 강제로 변환하지 않는다. 결과는 확인 완료, 잠정 분류와 미해결 항목을 구분해 기록한다.

### 12.7 후속 순서

1. 이 문서에서 profile·출처·migration 경계를 유지한다.
2. 우선 네 승인 profile 언어를 대상으로 언어별 read-only 원천 조사를 수행하고, 아람어는 별도로 조사한다.
3. 남은 `히브리어/아람어` expression의 실제 언어를 판정한다.
4. identity 예외와 stable key 대응 규칙을 확정한다.
5. dry-run manifest, migration 전후 전체 SQLite backup과 diff를 준비하고 work·seed·legacy projection parity를 검증한다.
6. 승인된 원천과 규칙에 한해 실제 DB migration을 수행한다.
7. 실제 pronunciation 원천과 항목별 provenance가 승인된 뒤 별도 migration에서 본문과 notation을 함께 갱신한다. Phase 50-O의 typed formatter·입력·표시 지원은 이 원천 승인을 대신하지 않는다.

`data/bbwdb_20260106.db`는 위 migration 순서에 포함하지 않는다.

## 13. 관련 문서와 외부 기준

내부 문서:

- [SCHEMA](SCHEMA.md) — 현재 DB schema authority
- [Data Structure Policy](DATA_STRUCTURE_POLICY.md) — canonical storage와 runtime authority 정책

외부 기준(2026-07-15 확인):

- [CrossWire StrongsGreek module information](https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=StrongsGreek) — `Strong's Greek Bible Dictionary`, `Distribution License: Public Domain`
- [CrossWire StrongsHebrew module information](https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=StrongsHebrew) — `Strong's Hebrew Bible Dictionary`, `Distribution License: Public Domain`
- [James Strong, *The exhaustive concordance of the Bible* (1890) 서지](https://openlibrary.org/books/OL31772852M/The_exhaustive_concordance_of_the_Bible) 및 [Internet Archive 스캔](https://archive.org/details/bwb_T2-DOA-183)
- [morphgnt Strong's Greek Dictionary XML 1.9 고정 commit](https://github.com/morphgnt/strongs-dictionary-xml/tree/dd6758b82f46b620804a8ea677d715844679eea1) — Greek 공식 전자 재구축 원천과 CC0 1.0 표시
- [Open Scriptures HebrewLexicon 고정 commit](https://github.com/openscriptures/HebrewLexicon/tree/21c9add13bc727d3a951361778e97e3ff7afd1ce) — `HebrewStrong.xml`, CC BY 4.0과 attribution 안내
- [Wiktionary: Copyrights](https://en.wiktionary.org/wiki/Wiktionary:Copyrights) 및 [Wikimedia Foundation Terms of Use](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use/en#7._Licensing_of_Content) — 전자는 오래된 비공식 안내라는 자체 경고가 있으므로 향후 재사용 판단 시 현행 이용 약관과 함께 확인
- [Wikidata: Licensing](https://www.wikidata.org/wiki/Wikidata:Licensing) — Wikidata 라이선스 안내

외부 링크의 표시는 해당 페이지에서 확인한 사실을 기록한 것이며, Reshet가 해당 데이터를 이미 채택·사용했다는 의미가 아니다.

## 승인된 Wiktionary 대조 철자 정리 (2026-10-02)

사용자가 승인한 `G0000_0015`, `G0000_0101`, `G0000_0102`, `G0000_0172`, `G0000_0201`, `G0000_0246`의 expression seq 1 철자만 각각 `Γάδαρα`, `ἐλαχύς`, `ἐλέφας`, `κόλυμβος`, `λίπος`, `οἶκτος`로 정리했다. 최초 복사 판본을 확정한 작업이 아니라 현행 원문 대조에 근거한 제한적 교정이다. 발음·음역·표기 방식 metadata·의미·비고·관계·Strong 번호·schema·기존 편집 이력은 보존했다. `ἄθλος` 등 보류 항목은 변경하지 않았다.

정확한 변경 전 값과 식별자를 조건으로 작업 DB를 수정했으며, 사본 적용·중간 실패 rollback·전체 테이블 대조로 승인 철자 6개만 변경됨을 검증했다. `integrity_check=ok`, foreign key 위반 0이다. 검증한 작업 DB에서 기존 `seed_release.dart prepare/promote` 절차로 배포 seed를 갱신했다. 후보와 이전 seed의 전체 차이도 철자 6개뿐이며 seed 이력은 0건, work 이력은 1,740건을 유지한다. 사용자 설치 DB에는 자동 적용하지 않는다.

앱 출처 안내 `docs/legal/data_attributions.md`에는 위 6개와 발음만 대조한 `G0000_0042`의 고정 Wiktionary 판본·기여자·라이선스·가공 안내·시대를 명시했다. 이 7개의 현재 대응을 전체 DB의 과거 provenance 또는 배포권 검토 완료로 확대 해석하지 않는다. 보류 항목에 대한 재작성·제외는 별도 승인 범위다.

작업 DB SHA256은 `4512e6bdcaae25ddd0fe774863718351350a0d0a11f5cf57a218b8982935ded6`, 배포 seed는 `1e30237f8fac176386db41d5d3b34dd11aa87ceef52f047aaafdef41219c5b2c`다. 수정 전 work/seed 바이트 백업은 Git 제외 `data/backups/wiktionary_spelling_six/20261001T154456171843Z/`에 보존한다. seed 승격 시 이전 seed는 `data/backups/seed_release/candidate_b2281589/previous_seed.db`에 별도 보존했다. 실행 SQL·검증·변경값 기록은 Git 제외 `build/play_release/spelling_six_receipt.json`, 후보 보고서는 해당 candidate 디렉터리의 `report.json`이다.

### 첫 테스트 seed의 승인 발음 보류

2026-10-02 사용자 승인으로 출처·발음 체계 대조 미확정인 11개 expression의 발음을 첫 배포 seed에서만 비웠다. 정확한 식별자·seq·원래 철자·발음·metadata는 `tool/data_provenance/manifests/seed_pronunciation_holds.json`에 고정한다. 이는 어휘의 오류·위법 판정이나 뜻 삭제가 아니다. 작업 DB에는 원래 연구 값을 보존한다. 이력만 제거하던 기존 seed 정책에 대한 명시적 예외와 재현 절차는 [SEED_RELEASE](SEED_RELEASE.md)를 따른다.

새 seed SHA256은 `8e67a67ecafd507a6287ed7919b5ce2902fc51c899dc8d669279f589a8d6e1de`, work SHA256은 위와 같으며 이전 seed 백업은 `data/backups/seed_release/candidate_976fc8af/previous_seed.db`다. 전체 비교에서 승인 발음·metadata 11행 이외의 데이터와 schema 변경은 0이다. 후보 runtime 검사와 실제 DB integrity/FK 검사를 통과했다. 이 처리와 현행 원문 링크 추가를 전체 데이터의 과거 provenance 복구나 재배포 근거 확인 완료로 해석하지 않는다.

### RMAC 배포용 원천과 한글 설명 재작성

2026-10-02 사용자 승인 범위는 기존 문법 코드·영문 표·작업 DB·사용자 DB를 보존하면서 공개 원천을 명시하고 seed의 한글 설명을 새로 작성하는 것이다. 과거 자료는 Python으로 외부 사이트에서 수집한 것으로 사용자에게 확인했지만 사이트와 기존 번역 작성자는 미확인이다. 이를 직접 작성한 자료로 소급 분류하지 않는다.

현재 영문 설명의 서로 다른 값 97개는 MLV Teams RMAC 페이지 55개의 문법 설명과 대조했고 각 페이지의 RMAC 전용 Public Domain 고지를 확인했다. 사이트 전체 저작권 고지와 RMAC 전용 조건을 구분한다. 원래 Robinson 문서도 https://github.com/byztxt/robinson-documentation 에서 Public Domain을 명시하지만 다른 배포처의 Robinson 모듈·번역에 이를 자동 적용하지 않는다.

`seed_rmac_translations.json`은 열·정확한 영문 값·새 한글 설명·대조 URL·HTML SHA256을 기록한다. 한글 설명은 공개 영문 원천에서 새로 작성했으며 기존 한글 표를 입력으로 사용하지 않았다. 일반 문법 용어는 기존 표현과 같을 수 있다. 97개 영문 값은 열별 중복을 제외한 한글 설명 94개에 대응한다. 전체 1,227개 RMAC 식별자와 원래 NULL 위치를 유지한다. seed 생성 때만 적용하는 정책과 보호 검증은 [SEED_RELEASE](SEED_RELEASE.md)를 따른다. 이는 어휘 meaning·비고·관계나 schema 변경이 아니다.

### 11.45 H45 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h45_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H45-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-03 연구 추천과 DB/Git 완료를 승인했다. 승인 내용 SHA는 `1c292f2bfd2210c74c26b28fda5907f555db8c32c5b8a13721b784ad18a18aa2`, 적용 manifest SHA는 `0a15e13b5c2c1c1b855a318899034b8fa564239e9ca88856f668679d053de752`이다. 해당 파일은 Git `-text` 속성으로 적용 당시 raw bytes를 보존한다.

H0045 `아비알본·아비-알본 (인)`과 승인 비고를 적용하고 H1→H45(id 7709, w1_to_w2)를 morphological/compound/asserted로 생성했다. H45 hold 없음; H22–H45 및 unknown second root/H410→H45 관계 비생성 유지. H1·H22 기존 승인·note·관계 및 expression·언어·schema·seed·hold ledger·원천 자료는 변경하지 않았다.

공식 dry-run/undo와 live apply 성공. History group `1790981306422466`, active 3행. Snapshot은 `data/backups/approved_content_batch/20261002T224825600507Z/snapshot.db`이며 전체 사용자 테이블 독립 비교에서 word·meaning 각 1행 교체, relation 1행·history 3행 추가 외 차이 없음을 확인했다. Work SHA `4512e6bdcaae25ddd0fe774863718351350a0d0a11f5cf57a218b8982935ded6` → `1278f2e05560729543e1fa16478409cdd94681f2492b724281e4bf15645d20dc`. Seed SHA `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb` 불변. Integrity ok, FK 0, sidecar 없음.

H45 explicit_approved, 전체 승인 114·hold 2·미승인 14,182·anomaly 113. Targeted applicator 테스트 29건 통과. [H45 결정 기록](../semantic_decisions/h45_cluster_approved_content_slice.md)에 최종값·핵심 근거·대안·잔여 불확실성을 기록했다. UI 테스트 N/A.

### 11.46 H46 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h46_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H46-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-04 후속 토론까지 반영한 최종 제안과 DB/Git 완료를 승인했다. Approval SHA는 `d736743180d7d92ffaf6819fe56835930b2765040ebcd0273487e0a4d09208e0`, manifest SHA는 `df9699500a252610c7ad4c986cb851ab88d584a361ac98ad3fa5e39b27bd4821`이다. 해당 manifest의 working bytes·index·applicator backup copy가 일치하며 파일별 LF 속성을 적용했다.

H46 ‘강하신 분’, H47 ‘힘센 / 황소 / 힘센 말 / 완고한(頑固한)’, H82 ‘날아오르다’, H83/H84 ‘날개’, H8038 ‘세메벨·셰므에베르 (인)’과 여섯 비고를 적용했다. 관계 7710~7714는 H46–H47 morphological/variant/asserted/undirected, H82–H83 etymological/root_shared/asserted/undirected, H83→H84 morphological/derived/asserted/w1_to_w2, H83→H8038 및 H8034→H8038 morphological/compound/hypothesized/w1_to_w2이다. H82→H46 파생 관계 및 H8034–H83 직접 관계는 생성하지 않았다. H8034 의미·비고·기존 관계, expression·언어·발음·schema·seed·hold ledger·앱 코드는 유지했다.

공식 dry-run/undo 및 live apply 성공. History group `1791044686496080`, active 17행. Snapshot은 `data/backups/approved_content_batch/20261003T162445646290Z/snapshot.db`이다. 전체 테이블 독립 비교와 manifest exact match에서 승인 대상 의미·비고 교체 및 relation 5·history 17행 추가 외 사용자 데이터 변경 없음. Work SHA `1278f2e05560729543e1fa16478409cdd94681f2492b724281e4bf15645d20dc` → `3223f756a7e71be0e9d2977a91ffdf2eb4d79f5833c4ed7f24d6e14b4167ac34`. Seed SHA `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb` 불변; work/seed integrity ok, FK 0, sidecar 없음.

여섯 CORE explicit_approved, 전체 승인 120·hold 2·미승인 14,176·anomaly 113. Discovery frontier 8의 graph closure 미완료와 hub 예외를 유지한다. [H46 결정 기록](../semantic_decisions/h46_cluster_approved_content_slice.md)에 최종값·핵심 근거·대안·잔여 불확실성을 기록했다. UI 테스트 N/A.

### 11.47 H48 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h48_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H48-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-04 “추천안대로 승인하고 DB 반영 및 Git 완료까지 진행”으로 H0048·H0087 meaning·비고와 관계 6건을 승인했다. 최종 승인 원문과 값은 `data/backups/approved_content_batch/h48_approval_20261004/00_approved_content.md`, approval SHA는 `fe0b9286de236160413e6cb48821eae00d44c45ed376b4b5020c71cee78fd9d5`이다. Manifest SHA는 `d302ab9eb5696b0cd8be311efcf6c82e352aeabd33334e4034babf62ac56e92f`이며 working bytes·index blob·applicator backup copy가 일치한다. 새 manifest에만 LF 규칙을 적용했다.

H48 ‘아비람·아비-람 (인)’, H87 ‘아브람·아브-람 (인)’과 두 비고를 적용했다. 기존 relation ID 25·26·5378·5379는 morphological/compound, 7480은 unspecified/related로 유지하며 status를 asserted로 교체하고 승인 note/source를 반영했다. 기존 direction도 유지하며 H87→H85는 이전 이름에서 이후 이름 방향이다. H48→H87 단축형 관계는 ID 7715, morphological/variant/asserted/w1_to_w2로 생성했다. H1·H7311·H85의 독립 meaning·비고, expression·언어·발음 metadata·schema·seed·원천·hold ledger·앱 코드 변경 없음.

공식 dry-run은 meaning 2·비고 2·관계 신규 1·교체 5, 총 10 operations 및 사본 undo를 검증했다. Live apply history group `1791070710426922`에 active 10행(update 9/create 1)을 기록했다. Snapshot·result·manifest copy·독립 SQL 검증은 `data/backups/approved_content_batch/20261003T233829595482Z/`에 보존한다. Work SHA는 `3223f756a7e71be0e9d2977a91ffdf2eb4d79f5833c4ed7f24d6e14b4167ac34` → `d58aa42d6b7a1ca798fcd4c096de42aed0a52a7fb4f530dbd0cc8b11bb354341`, seed SHA는 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`로 불변이다. 독립 전체 13테이블 대조에서 승인 대상 변경·history·관련 sequence 증가만 확인했다. DDL 동일, work/seed integrity ok, FK 0, sidecar 없음. Applicator 관련 테스트 29건 모두 통과했다.

공식 progress는 두 CORE explicit_approved, 전체 14,298 중 승인 120→122·hold 2→2·미승인 14,176→14,174·anomaly 113이며 JSON/CSV 14,298행이 일치한다. [H48 결정 기록](../semantic_decisions/h48_cluster_approved_content_slice.md)과 README 색인에 최종값·핵심 근거·대안·불확실성을 기록했다. CORE 2개의 72용례 평가와 전체 discovery frontier 62·research_complete=false를 구분한다. LXX는 human-reference, upstream/license unverified이고 canonical alignment·헬라어 관계로 승격하지 않는다. x-pn source의 unresolved 상태와 기존 DB 언어는 보존한다. UI 테스트 N/A.

### 11.48 H49 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h49_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H49-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-04 H4870을 ‘잘못’으로 보완한 최종 제안을 포함하여 파일·DB·Git 완료를 승인했다. 최종 승인 원문과 값은 `data/backups/approved_content_batch/h49_approval_20261004/00_approved_content.md`, approval SHA는 `35c1fd70b574f55ecaed994fbed781583ad740a297c5b01d3b48a418a41eabdd`이다. Manifest SHA는 `2ee9296f49f394a846f1cf3886ce2d31040c3b6f4ab5c0a366d828fc2d2e0f31`이며 working bytes·index blob·applicator backup copy가 일치하고 새 manifest에만 LF 속성을 적용했다.

Meaning 6건·비고 6건을 반영했다. H49 ‘아비삭·아비-샤그 (인)’, H7686 ① ‘빗나가다·잘못하다’ ② ‘취하다(醉하다)·마음을 빼앗기다’, H4870 ‘잘못’, H7681 ‘사게·샤게 (인)’, H7691 ‘허물·잘못’, H7692 ‘식가욘’이다. H4870은 비의도성을 어휘 전체의 필수 조건으로 고정하지 않고 창 43:12의 실수·착오 문맥을 비고에 보존한다. 신규 ID 7716–7720은 H1→H49·H7686→H49 compound/asserted, H7686→H4870·H7686→H7691 derived/asserted, H7686→H7681 derived/hypothesized다. Canonical 저장 순서와 semantic 방향을 구분한다. H7686–H7692 관계는 미생성이고 H0001 meaning·비고, 주변 어휘, expression·언어·발음·POS·schema·seed·source·hold ledger·앱 코드는 변경하지 않았다.

공식 dry-run은 총 17 operations와 사본 undo를 검증했고 원본 DB는 불변이었다. Live apply history group `1791078986352574`에는 active word update 12·relation create 5, 총 17행을 기록했다. Snapshot·result·manifest copy·독립 SQL 검증은 `data/backups/approved_content_batch/20261004T015625523970Z/`에 보존한다. Work SHA는 `d58aa42d6b7a1ca798fcd4c096de42aed0a52a7fb4f530dbd0cc8b11bb354341` → `4c3b7ab814d1de7ae52fc19b823f4459ad0da378f2203630e476793b1d83bf13`, seed SHA는 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`로 불변이다. 독립 전체 13테이블 대조에서 승인 대상 변경·history·관련 sequence 증가만 확인했고 DDL·승인 밖 데이터 동일, work/seed/snapshot integrity ok, FK 0, sidecar 없음. Applicator 관련 테스트 29건 모두 통과했다.

공식 progress는 6 CORE explicit_approved, 전체 14,298 중 승인 122→128·hold 2→2·미승인 14,174→14,168·anomaly 113이며 JSON/CSV 14,298행이 일치한다. [H49 결정 기록](../semantic_decisions/h49_cluster_approved_content_slice.md)과 README 색인에 최종값·후속 판단·대안·불확실성을 기록했다. CORE 31건 용례 평가·승인과 raw discovery frontier 43·research_complete=false를 구분한다. LXX는 human-reference, upstream/license unverified이고 canonical alignment·헬라어 관계로 승격하지 않는다. UI 테스트 N/A.

### 11.49 H50 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h50_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H50-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-06 제안한 어휘 클러스터와 DB/Git 완료를 승인했다. 가운데점 이격은 적용하지 않는다. 최종 승인 원문과 값은 `data/backups/approved_content_batch/h50_approval_20261006/00_approved_content.md`, approval SHA는 `d6eb2fbb5fb7e5d405fae64c25083f4b5cddb107446006692e5ea1a44e6fddc2`이다. Manifest SHA는 `b70439740d3f0894090cd93792d6f482812dce7e1b2ea3d58e850b833bed5b6c`이며 working bytes·index blob·applicator backup copy가 일치한다. 새 manifest와 hold ledger에 파일별 LF 속성을 적용했다.

15개 어휘를 승인했다. Meaning 교체 13·비고 교체 15, H7769/H7775는 현재 meaning을 유지하는 approval 2건이다. H0050 ‘아비수아·아비-슈아 (인)’, H0474 ‘엘리수아·엘리-슈아 (인)’, H0477 ‘엘리사·엘리-샤 (인)’, G1666 ‘엘리사·엘리사이오스 (인)’, H1339 ‘밧세바·바트-셰바 (인)’, H1340 ‘밧수아·바트-슈아 (인)’, H4444 ‘말기수아·말키-슈아 (인)’, H7768 ‘도움을 청하며 부르짖다’, H7769/H7773/H7775 ‘도움을 청하는 부르짖음’, H7770 ‘수아·슈아 (인)’, H7771 ① ‘귀인(貴人)’ ② ‘부르짖음’, H7772 ‘소아·쇼아’, H8668 ‘구원(救援)’이다. 관계는 신규 15(ID 7721–7735)·기존 교체 3(ID 3943/3944/3945), asserted 10·hypothesized 8이며 canonical pair와 semantic direction을 구분한다. H7774는 occurrence mapping 충돌로 hold ledger에만 추가하며 DB 값·관계는 유지한다. 기존 6683·기존 hold 두 항목과 승인 밖 데이터, expression·언어·발음·POS·schema·seed·원천·앱 코드 변경 없음.

공식 dry-run/undo와 live apply 성공, 총 46 operations. History group `1791245199213641`에 active 46행(word update 28/relation create 15/relation update 3)을 기록했다. Snapshot·result·manifest copy·독립 SQL·progress 검증은 `data/backups/approved_content_batch/20261006T000638418210Z/`에 보존한다. Work SHA는 `4c3b7ab814d1de7ae52fc19b823f4459ad0da378f2203630e476793b1d83bf13` → `d2c0be3e7fba7c04119ee13ee8c82f7ec6db7e573f44587beb3a610107ec9b44`, seed SHA는 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`로 불변이다. 독립 전체 13테이블 대조에서 승인 범위·history·관련 sequence 증가만 확인했다. DDL 동일, work/seed/snapshot integrity ok, FK 0, sidecar 없음. Applicator 관련 테스트 29건 모두 통과했다.

공식 progress는 전체 14,298 중 승인 128→143·hold 2→3·미승인 14,168→14,152·anomaly 113 동일이며 JSON/CSV 14,298행 일치. [H50 결정 기록](../semantic_decisions/h50_cluster_approved_content_slice.md)과 README 색인에 최종값·관계·핵심 근거·대안·불확실성을 기록했다. CORE 16개의 160건 전량 평가와 discovery frontier 42·research_complete=false를 구분한다. LXX 32건 수동 조회는 human-reference·upstream/license unverified이며 canonical alignment나 헬라어 관계로 승격하지 않는다. H1339 표제 참조는 수동 보충했으며 도구 수정은 후속 범위다. UI 테스트 N/A.


### 11.50 H51 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h51_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H51-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-06 성별 보충 검토 후 문서·DB·Git 완료를 승인했다. 최종 승인 원문과 값은 `data/backups/approved_content_batch/h51_approval_20261006/00_approved_content.md`, approval SHA는 `501916a68796db3616823bf60fa670dff308abc1709f300fff96d785ac3ae0f7`이다. Manifest SHA는 `d0f3ce8238fa5f60af08fcd784896f9cff2b99f4d666b52005a2949316b2261e`이며 working bytes·index blob·applicator backup copy가 일치한다. 새 manifest에 파일별 LF 속성을 적용했다.

Meaning13·비고13을 반영했다. H0051 아비술·아비-슈르 (인), H0301 아히살·아히-샤르 (인), H7788 다니다, H7789 살피다, H7791/H7792 담, H7793 술·수르·슈르 (지), H7794/H8450 소, H7891 노래하다, H7892 노래, H8670 선물(膳物), G5022 수소를 각각 sense1로 승인했다. H8450는 넓은 아람어의 암소·일반 명칭 용법과 다니엘의 성별 미명시 문맥을 고려해 이전 수소 추천을 변경했다. 민18:17 KJV cow만으로 암컷을 확정하는 근거는 철회하고 H7794 비고에 직접 사전·용례 근거를 반영했다. 원자료 태그·품사·언어를 교정하지 않는다.

관계 신설10(ID7736–7745)·기존3631 재분류1, 모두 asserted다. 명시적 source의 compound/derived와 아람어 대응 root_shared를 승인하되 독립 현대 역사언어학 검증 또는 차용 방향 확정으로 확대하지 않는다. H7791–H8284 및 H7788–H7891 관계는 보류, G5022–H8450 id3633은 inferred/unknown으로 유지한다. H8284는 의미·어원 충돌 때문에 hold ledger에만 추가하며 current 벽, 담·noteNULL을 유지한다. 기존 hold3·H0001 승인·H0251 현재값·대상 밖 데이터는 유지한다.

공식 dry-run과 사본 undo, live apply가 총37 operations로 성공했다. History group `1791294418533047`의 active37행은 word update26·relation create10·relation update1이며 undone0이다. Snapshot·result·manifest copy·독립 SQL·progress 검증은 `data/backups/approved_content_batch/20261006T134657654013Z/`에 보존한다. Work SHA는 `d2c0be3e7fba7c04119ee13ee8c82f7ec6db7e573f44587beb3a610107ec9b44` → `162830931dc84f0b0d61d74855f270c75453c33de0482a1117bb7fc1d9dca9bc`, seed SHA는 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`로 불변이다. 독립 전체13테이블 대조에서 승인 범위·history·관련 sequence 변경만 확인했다. DDL 동일, work/seed/snapshot integrity ok, FK0, sidecar 없음이다. Snapshot의 schema cookie 차이는 공식 backup 계약이며 시작13테이블 논리 projection과 모두 일치한다. 기존 applicator 테스트29건 통과.

공식 progress는 전체14,298 중 승인143→156·hold3→4·미승인14,152→14,138·anomaly113 동일, 의미 승인 비율1.000140%→1.091062%다. JSON/CSV14,298행과 대상13개 explicit_approved/H8284 hold를 확인했다. [H51 결정 기록](../semantic_decisions/h51_cluster_approved_content_slice.md)과 README 색인에 최종값·관계·핵심 근거·대안·불확실성을 기록했다. 연구 CORE14의306건 전량 검토와 hub 예외·frontier44·research_complete=false를 구분한다. LXX는 reference-only이며 canonical alignment로 승격하지 않는다. 앱 코드·schema·expression·발음·품사·언어·seed 변경 없으며 UI 테스트 N/A다.

### 11.51 H52 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h52_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H52-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-07 다섯 표기·의미 보충 검토와 비고 제한의 일치 수정까지 포함하여 문서·DB·Git 완료를 승인했다. 최종 승인 원문과 값은 `data/backups/approved_content_batch/h52_approval_20261007/00_approved_content.md`, approval SHA `d8b8bb2d78d97bf8a0f46151744f82183ce35d45ebb7f12960d16cb78a8abbf4`다. Manifest SHA `ddaa9f4c096cc0baf8408e33807ae6561d492c8fcd0dd4ed46ae79058da8065f`는 working bytes·index blob·applicator backup copy에서 일치한다. 새 manifest에만 파일별 LF 속성을 적용했다.

Meaning11·비고11을 적용했다. H0052 아비새·아비샤이·아브샤이 (인), H3144 요사·요샤 (인), H3145 요사위야·요샤우-야 (인), H3438 이스와·이쉬와 (인), H3440 이스위·이쉬위 (인), H3441 이스위 자손·이쉬위 자손(子孫), H7737 ①같다(같게 하다) ②알맞다 ③고르게 하다 ④두다 ⑤만들어 내다, H7739 ①같게 하다 ②만들다, H7740 ①평원(平原) ②사웨·샤웨 (지), H7741 사웨기랴다임·샤웨-키르야타임 (지), H7862 예물(禮物)이다. H3145의 고대 /w/ 참고와 전체 발음 재구의 한계를 구분하고, H3440 리스위는 판본 식별 비고로만 보존하며 H3441에도 같은 이름 병기를 적용했다. H7740의 실제 용례 분석과 Strong·OSHB 품사 차이도 비고에 명시했다.

관계 신규12(ID7746–7757), asserted10·hypothesized2이며 canonical pair와 semantic 방향을 구분한다. probably from 및 probably a form of는 가설이다. H7862→H0052 및 H3448→H0052 생성 보류, 기존 H3448–H7862 id7520 inferred/unknown과 H41–H3440 alias 비생성 결정을 유지한다. 새 word hold 없음; 기존 hold4·CONTEXT 및 HUB-EXCLUDED 독립 meaning·기존 승인·원자료는 유지한다.

공식 dry-run의 사본 적용·undo와 live apply가 총34 operations로 성공했다. History group `1791300675634810`의 active34행은 word update22·relation create12, undone0이다. Snapshot·result·manifest copy는 `data/backups/approved_content_batch/20261006T153114774872Z/`, 승인 원문·정확한 원본 byte 백업·독립 SQL·progress 검증은 `data/backups/approved_content_batch/h52_approval_20261007/`에 보존한다. Work SHA `162830931dc84f0b0d61d74855f270c75453c33de0482a1117bb7fc1d9dca9bc` → `abfdfcf48bf6117f21681583faddeeee164153bd9d1594ebeb395855e33f7e12`, seed SHA `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb` 불변이다. 독립 전체13테이블 대조에서 승인 범위·history·관련 sequence 증가만 확인했다. DDL 동일, 원본 backup과 snapshot 논리 projection 일치, work/seed/snapshot integrity ok·FK0·sidecar0. 기존 applicator 테스트29건 통과.

공식 progress 전체14,298 중 승인156→167·hold4 동일·미승인14,138→14,127·anomaly113 동일이다. JSON/CSV14,298행 및 CORE11 explicit_approved를 확인했고 다른 모든 progress row는 동일하다. [H52 결정 기록](../semantic_decisions/h52_cluster_approved_content_slice.md)과 README 색인에 정확한 최종 선택·관계·근거·배제 대안·잔여 불확실성을 기록했다. CORE63토큰 전량 검토와 사38:13 미확정1·hub 예외·공식 frontier40·research_complete=false를 구분한다. LXX는 reference-only다. 앱 코드·schema·expression·발음 필드·품사·언어·seed 변경 없으며 UI 테스트 N/A다.

### 11.52 H53 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h53_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H53-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-07 원천 이름·셰와·한자·보상·제사 의미를 검토하고 H3073·H7759·H8016의 마지막 선택을 반영하여 문서·DB·Git 완료와 프로젝트 루트 밖 semantic progress 갱신을 승인했다. 최종 승인 발췌와 정확한 값은 `data/backups/approved_content_batch/h53_approval_20261007/00_approved_content.md`, approval SHA `8d642401f96067f3ba3e2b48ede7fef10c81c01fefca113522a89a10e4e18d8f`다. Manifest SHA `e63cc0c1f32b989513184dbfbeb845df514e5ddddabab081f443e74f1adbd610`는 working bytes·index blob·applicator backup copy에서 일치한다. 새 manifest에만 파일별 LF 속성을 추가했다.

CORE32 중 meaning31·비고28을 적용했다. G4532 살렘·샬렘, G4672/H8010 솔로몬·셸로모 병기는 원천 히브리어 분석이며 헬라어 발음과 구분한다. G4539 살로메의 실제 히브리어·아람어 원형은 미확정이다. H3073은 여호와 살롬과 고대 신명 발음의 미확정을 설명하는 한국어 비고만 채택했고, H7759는 술람미 여자만 meaning에 두었다. H8016은 실렘 자손(子孫)·쉴렘 자손(子孫)이다. H7965 온전함(穩全함)·H7999 온전하다(穩全하다)에 한자를 병기하고 갚다를 유지했다. H7966·H8005·H8011·H8021은 보상(報償) 한 sense로 두고 부정적 실제 문맥과 지급 성격을 비고에 명시했다. H8002는 화목제(和睦祭) 한 meaning, 감사제(感謝祭)는 비고 앞에 둔다. 셰와 관련 관용명·메/셸 분석 표기와 발음 확정의 한계도 비고에 구분했다. 정확한 전체 값은 manifest와 [H53 결정 기록](../semantic_decisions/h53_cluster_approved_content_slice.md)이 기준이다.

관계35건은 신규30(ID7758–7787)·기존 교체5(ID2854/3845/2960/2958/2959)이며 asserted31·hypothesized4다. Canonical pair와 semantic 방향을 구분한다. H8003은 OSHB 대상12:39(많은 번역의12:38)의 H8003/H3824 표면형·lemma 대응 충돌 때문에 hold ledger에만 추가하고 현재 meaning·비고·expression 및 관계2852/2853을 유지했다. 기존 hold4·CONTEXT5·HUB-EXCLUDED39의 독립 meaning·승인·원자료를 보존한다. H3389–H7999와 H4919–H4921은 비생성 유지다.

공식 dry-run의 사본 적용·undo와 live apply가 총94 operations로 성공했다. 원본 DB는 dry-run 전후 byte 불변이다. History group `1791334931473804`의 active94행은 word update59·relation create30·relation update5, undone0이다. Snapshot·result·manifest copy는 `data/backups/approved_content_batch/20261007T010210642933Z/`, 승인 발췌·정확한 원본 byte 백업·독립 SQL·progress 검증은 `data/backups/approved_content_batch/h53_approval_20261007/`에 보존한다. Work SHA `abfdfcf48bf6117f21681583faddeeee164153bd9d1594ebeb395855e33f7e12` → `60ad54693be0dc0389b9797eae21475997988768830a33480a87b7221b29e79e`, seed SHA `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb` 불변이다.

독립 SQL 검증은 적용 전·후·snapshot의 각13테이블 `SELECT *` 전체 행과 `sqlite_master`의 type/name/tbl_name/sql을 대조하여 승인 밖 변경을 확인하는 목적이다. 대상 meaning은 `SELECT seq,meaning FROM word_meaning_set WHERE word_id=? ORDER BY seq`, history는 `SELECT * FROM CHANGE_HISTORY WHERE group_id=?`로 확인했다. 결과는 승인 범위·history·관련 sequence 증가만 존재하며 DDL과 나머지 데이터는 동일하다. Snapshot은 적용 전13테이블 논리 projection과 일치한다. `PRAGMA integrity_check`는 work/seed/snapshot 모두 ok, `PRAGMA foreign_key_check`는 모두0행, sidecar0이다. 실제 SQL과 테이블별 전후 행 수는 `sql_verification.json`에 보존한다. 기존 applicator 테스트29건 통과, `git diff --check`와 staged diff 검사 통과다.

공식 progress CLI를 명시적 표준 경로 `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_research_output\semantic_progress`에 실행해 JSON·CSV·Markdown을 함께 갱신했다. 새 manifest는 git ls-files 자동 발견을 위해 정확한 경로로 stage한 후 생성했다. 전체14,298 중 승인167→198·hold4→5·미승인14,127→14,095·anomaly113 동일이다. JSON/CSV14,298행·동일 상태 집계, CORE31 explicit_approved/H8003 hold를 확인했고 다른 모든 progress row는 동일하다. 의미 승인 비율1.167996%→1.384809%이며 hold를 승인에 합산하지 않는다. README 색인에도 최종 결정 기록을 연결했다.

CORE998토큰 조회·검토 및997건 잠정 분류와 H8003 충돌1건, 공식 frontier48·research_complete=false 및 hub 예외 경계를 구분한다. LXX는 reference-only다. 앱 코드·schema·expression·음역·발음 필드·품사·언어·seed 변경 없음, UI 테스트 N/A(데이터·문서 반영이며 UX 변경 없음)다. work/seed DB는 기존 *.db Git 제외 정책을 유지하며 로컬 work DB 적용을 강제로 Git 추적하지 않는다.


### 11.53 H54 클러스터 approved-content work DB slice

`tool/data_provenance/manifests/h54_cluster_approved_content_slice.json`은 format v5 batch `RESHET-EC-H54-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-12 최신 meaning·비고·관계와 DB 반영을 승인했다. H3505의 마지막 선택은 ‘이델 사람·예테르 가문(家門) 사람’이며 관용 표기와 Strong의 기반 인명 풀이를 같은 meaning에 둔다. 승인 발췌·정확한 최종 값은 `data/backups/approved_content_batch/h54_approval_20261012/00_approved_content.md`, approval SHA `c828dad2c999a0fbfb6b293d3b7cc236878da79949143eacc729069c660b1976`다. Manifest SHA는 `e953c0392f3a1910c82aef0cd27b4c861b6d8a0440b49390bb6eb9d027bfe6ad`이며 새 파일에만 LF 속성을 추가했다.

Meaning19·비고14·관계 신규18·기존 inferred 교체3, 총54operations를 공식 applicator로 적용했다. G8은 H54와 원천 이름 병기를 맞추고, H3148은 더 / 나음·유익(有益), H3492는 얏딜·얏티르, H3493은 뛰어난 / 매우를 유지한다. H3498의 창49:4 뛰어나다와 H3499의 줄 용례를 비고에 설명하고, H3508은 간엽(肝葉)과 일반 부가물의 용례 부재·해부학적 한계를 구분한다. 전체 exact meaning·비고·관계와 근거는 [H54 결정 기록](../semantic_decisions/h54_cluster_approved_content_slice.md) 및 manifest가 기준이다.

H3491은 욥39:8의 표면형·morphology와 Strong 사전 항목의 어근·품사 경계 충돌 때문에 hold ledger에만 추가했다. 기존 meaning·비고·expression·관계를 유지하며 H3498→H3491을 생성하지 않는다. H3492–H3493과 H3499–H4340의 추가 직접 파생도 생성하지 않는다. 기존 hold5·CORE 밖 독립 의미·승인·원자료는 유지한다.

공식 dry-run·사본 undo 및 live apply 성공. History group `1791810686827865`의 active54행은 word update33·relation create18·relation update3, undone0이다. 공식 snapshot/result/manifest copy는 `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_app\data\backups\approved_content_batch\20261012T131125603728Z`, 승인 원본·byte 백업·독립 SQL·test·progress 검증은 `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_app\data\backups\approved_content_batch\h54_approval_20261012`에 보존한다. Work SHA `b5a87078fad6438642c620194546f40520493e1a62939f82f978f48e6ec364ab` → `16eca62391a2cc76ecf1a6561fe43791c07ff84dc0be0bb166df410a9af1cf80`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다.

독립 SQL은 적용 전·후·snapshot 각13테이블의 전체 행과 sqlite_master(type/name/tbl_name/sql), 대상 의미 순서·비고, relation exact metadata·중복, history group을 대조했다. 승인 범위와 history·관련 sequence 증가 외 차이 없음, snapshot은 적용 전 전체 projection과 일치, DDL 동일, work/seed/snapshot integrity ok·FK0·sidecar0이다. 모든 expression·음역·발음·기존 개발 파일·원래 연구 산출물은 그대로다. 기존 applicator 테스트29건 통과, 실제 SQL·결과·해석은 `sql_verification.json`에 보존한다.

공식 CLI로 표준 외부 `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_research_output\semantic_progress`의 JSON·CSV·Markdown을 함께 갱신했다. 새 manifest는 git ls-files 발견을 위해 정확한 경로만 index에 등록했다. 전체14,298 중 승인198→217·hold5→6·미승인14,095→14,075·anomaly113 동일이다. JSON/CSV14,298행·동일 상태 집계, 대상19개 explicit_approved/H3491 hold 및 나머지 모든 행 불변을 검증했다. Semantic 승인 비율1.384809%→1.517695%, hold는 승인에 합산하지 않는다. 결정 기록과 README 색인도 갱신했다.

실제 DB는 원래 프로젝트의 work DB에 적용했으며 approval/hold/결정/provenance 기록은 별도 작업 공간 `C:\Users\kkiih\.codex\worktrees\h54-approved-content\reshet_app`의 `codex/h54-approved-content-20261012`에 준비했다. 원래 개발 브랜치의 기존 변경은 보존했다. DB 반영 후 사용자는 관련 6개 파일의 단일 커밋·작업 브랜치 push·main fast-forward 병합·push까지 후속 승인했다. 최종 commit·실제 원격 참조·DB 불변 검증은 같은 백업 폴더의 `git_closeout_verification.json`에 보존한다. CORE327토큰 검토 및325분류·2미해결, 공식 frontier49·research_complete=false와 hub 예외 scope를 구분한다. LXX는 reference-only다. 앱 코드·schema·품사·언어·seed 변경 없음, UI 테스트 N/A다.

### 11.54 H55 클러스터 approved-content work DB slice

[h55_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h55_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H55-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-13 연구 추천 내용과 DB·문서·Git 완료를 승인했다. 승인 원문·정확한 값은 `data/backups/approved_content_batch/h55_approval_20261013/00_approved_content.md`, approval SHA는 `aaa152acaee458d530f7b737911c751d13546b77c07bb34a49b3f0d02cdfde2e`다. Manifest SHA는 `0cf93ae60dc5130c87c565b76b66c42f834119bf4c6f21c356e03f95be9b11b7`이며 working bytes·index·applicator 사본이 일치하고 새 manifest에만 LF 속성을 추가했다.

H0055_0000의 meaning seq1을 ‘휘돌며 올라가다’로 교체하고 단일 히트파엘 용례·연기와 상승 문맥·기본 어근의 불확실성을 밝힌 비고를 추가했다. 의미1·비고1, 총2operations다. 관계 생성·교체와 신규 hold는 없으며 기존 hold6·expression·음역·발음·언어·schema·seed·원천·앱 코드를 보존했다. 정확한 최종값·선택 근거·주요 대안·재검토 조건은 [H55 결정 기록](../semantic_decisions/h55_cluster_approved_content_slice.md)에 기록하고 README 색인에 `active`로 추가했다.

공식 dry-run/사본 undo와 live apply가 성공했다. History group `1791821611143860`에 active word update2행(ID5909·5910, undone0)을 기록했다. Snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261012T161330000004Z/`, 승인 원본·byte 백업·실행 로그·독립 SQL·test·progress 검증은 `data/backups/approved_content_batch/h55_approval_20261013/`에 보존한다. Work SHA는 `16eca62391a2cc76ecf1a6561fe43791c07ff84dc0be0bb166df410a9af1cf80` → `65c25be516f70ff219ed545692f8868cec7fed2dd4212cbf24e439999edf4b63`, seed SHA는 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`로 불변이다.

독립 SQL은 적용 전 byte 백업·후 DB·공식 snapshot의 전체13테이블과 sqlite_master(type/name/tbl_name/sql)를 대조했다. 승인된 두 교체와 history2행·CHANGE_HISTORY sequence 증가 외 차이 없고, snapshot 전체 projection은 적용 전과 일치한다. DDL·user_version 동일, work/seed/snapshot integrity ok·FK0·sidecar0이다. Snapshot schema cookie1369와 원본1368의 차이는 VACUUM INTO의 정상 결과이며 스키마 변경이 아니다. 기존 applicator 테스트29건이 통과했다. 실제 SQL·결과·해석은 `sql_verification.json`에 보존한다.

공식 CLI로 표준 외부 `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_research_output\semantic_progress`의 JSON·CSV·Markdown을 함께 갱신했다. H55만 unapproved→explicit_approved, 전체14,298 중 승인217→218·hold6→6·미승인14,075→14,074·anomaly113 동일이다. JSON/CSV14,298행과 공식 Markdown 렌더 일치, H55 외 모든 progress 행 불변을 확인했다. Semantic 승인 비율은1.517695%→1.524689%이며 hold를 승인에 합산하지 않는다. Snapshot identity는 `8beff457b4c4ab1b479d01f247255f3e58db88c17fe0d52d49a27df3f9ae7047`이다.

연구는 CORE1·유일 용례1/1 검토, frontier0·discovery/research_complete=true다. Strong의 probably 한정, OSHB9:17/KJV9:18 대응과 로컬 참고자료의 개별 문맥 확인을 보존하며 참고자료 전체 versification profile은 unverified로 유지한다. LXX 직접 정렬·신약 연결은 미확인으로 관계를 생성하지 않았다. 초기115개 입력 중 승인된 work DB만 변경되었고 원래 machine Packet·관계·Review SHA도 불변이다. UI 테스트와 앱 빌드 N/A — 사유: 앱 코드·UX·schema·seed 변경 없는 승인 콘텐츠 slice다.

### 11.55 H56 클러스터 approved-content work DB slice

[h56_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h56_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H56-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-13 후속 검토의 최신 의미·비고·관계 결정과 한자 병기, DB·문서·Git·작업 브랜치 정리까지 승인했다. 승인 원문과 정확한 값은 `data/backups/approved_content_batch/h56_approval_20261013/00_approved_content.md`, approval SHA는 `fd6c8373c903e41b193ac6a6a5fee6fb868250477d11b841882724726a5af6fa`다. Manifest SHA는 `8adf0f4c61ba2455ea603ccf2c6b747d6663c595c99e8b528a7999902158eccb`이며 새 manifest에만 LF 속성을 추가했다.

H56·H57·H60은 기존 의미 범위를 유지하면서 哀悼을 병기했고, H61은 seq1 ‘참으로’·seq2 ‘그러나’, H179는 ‘오빌 (인)’을 유지 승인했다. 다섯 비고에 실제 쓰임·문법 기능·어원 불확실성을 보완했다. H56 ‘마르다’는 경쟁 어근 분석으로 비고에 남기고 독립 meaning으로 확정하지 않았다. H56→H57·H60은 canonical pair, morphological/derived/asserted/w1_to_w2로 생성했고 H56→H61·H179의 추정 관계는 생성하지 않았다. Meaning 교체4·비고 교체5·관계 생성2, 총11operations와 meaning 유지 승인1건이다. 신규 word hold 없고 기존 hold6·expression·음역·발음·언어·품사·schema·seed·원천·앱 코드를 보존했다. 정확한 최종값·선택 근거·주요 대안·재검토 조건은 [H56 결정 기록](../semantic_decisions/h56_cluster_approved_content_slice.md)과 README의 `active` 색인에 기록했다.

공식 dry-run의 사본 적용·undo와 live apply가 성공했다. 초기 sandbox의 Dart 실행 경로 오류는 권한을 확보해 같은 공식 SDK 명령을 다시 실행하여 해결했다. History group `1791849685896495`에 active 11행(ID5911–5921, word update9·relation create2, undone0), 관계 ID7806·7807을 기록했다. Snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261013T000124748683Z/`, 승인 원본·byte 백업·실행 로그·독립 SQL·test·progress 검증은 `data/backups/approved_content_batch/h56_approval_20261013/`에 보존한다. Work SHA는 `65c25be516f70ff219ed545692f8868cec7fed2dd4212cbf24e439999edf4b63` → `bc6347374e03cdfc651422be525d201f1c0b7659006de5ef82316046043ce78b`, seed SHA는 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`로 불변이다.

독립 SQL은 byte 백업·후 DB·공식 snapshot의 전체13테이블과 sqlite_master(type/name/tbl_name/sql)를 대조했다. 승인된11변경과 history11행·관련 sequence 증가 외 차이 없고 H179 meaning·모든 비대상 행·DDL·user_version은 불변이다. Snapshot 전체 projection은 적용 전과 일치한다. Work·seed·snapshot integrity ok·FK0·sidecar0이며 snapshot schema cookie1369/원본1368은 VACUUM INTO의 정상 차이다. SQL65항목과 기존 applicator Flutter 테스트29건이 통과했다. 실행 SQL·결과·해석은 `sql_verification.json`에 보존한다.

공식 CLI로 표준 외부 `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_research_output\semantic_progress`의 JSON·CSV·Markdown을 함께 갱신했다. 대상5개만 unapproved→explicit_approved, 전체14,298 중 승인218→223·hold6 동일·미승인14,074→14,069·anomaly113 동일이다. JSON/CSV14,298행, CSV·Markdown의 공식 렌더 일치와 모든 비대상 progress 행 불변을25항목으로 검증했다. Semantic 승인 비율은1.524689%→1.559659%이며 hold는 승인에 합산하지 않는다. Snapshot identity는 `24d17be3c2d8c173544299348b87fbae3b43eaf9aba77d3a7495f0812e1de63d`다.

연구는 closure/CORE5·전체83토큰(서로 다른78절) 검토, frontier0·discovery/research_complete=true다. 처음 확보한 원천·기존 승인 등107파일과 machine Packet·관계·Review15개의 SHA 불변을 확인했다. 초기 summary의 애통 통일 제안보다 후속 대화의 기존 meaning 유지·哀悼 병기·마름 어근 분석 보완안을 우선한다. 로컬·LXX는 reference-only이며 미확정 어원과 versification 한계를 보존한다. UI 테스트와 앱 빌드 N/A — 사유: 앱 코드·UX·schema·seed 변경 없는 승인 콘텐츠 slice다. DB 파일은 기존 정책대로 Git 미추적 로컬 자산으로 유지한다.

### 11.56 H58 클러스터 approved-content work DB slice

[h58_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h58_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H58-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-13 최신 추천의 문서·DB 반영을 승인하고 H4259의 ‘므훌랏 사람·므흘랏 사람·므홀랏 사람·메홀라 사람’과 비고 설명안을 명시적으로 선택했다. 승인 원문·최종값은 `data/backups/approved_content_batch/h58_approval_20261013/00_approved_content.md`, approval SHA는 `9eeee37e77395edf3decb669c6f27d697627914c6fa2b2c3243bf6b8d14c8617`다. 적용 manifest SHA는 `bcc6c7837e5fadac91ef6eb8c384ce38b07cea7aa6b82e69a1f66a1cc1cb16d6`이며 working bytes·index·applicator 사본이 일치한다. 적용 원본의 CRLF 바이트와 hash를 보존하기 위해 기존 H45 사례처럼 새 manifest에만 `-text whitespace=cr-at-eol` 속성을 적용했다.

CORE12의 meaning 교체12·비고 교체12·관계 생성18, 총42operations다. H62는 아벨벧마아가·아벨벳마아가·아벨-베트-마아카를 같은 sense로 보존하고 H4259는 원문 소속형에 없는 아벨을 meaning에 강제하지 않는다. H59 큰 돌 독법과 H7851 요엘 골짜기 문제는 비고에 남겼다. 관계는 morphological/asserted의 compound15·derived3이며 canonical pair와 direction_code를 검증했다. G9–H58 compare·말놀이·동일 장소 이름의 자동 variant/synonym은 생성하지 않았다. 신규 word hold0·기존 hold6 유지이며 expression·음역·발음·언어·품사·schema·seed·원천·앱 코드는 보존했다. 최종값·선택 이유·대안·불확실성은 [H58 결정 기록](../semantic_decisions/h58_cluster_approved_content_slice.md)과 README active 색인에 기록했다.

공식 dry-run 사본 적용·undo와 live apply가 성공했다. History group `1791873150222948`에 active42행(ID5922–5963, word update24·relation create18, undone0), 관계ID7808–7825를 기록했다. Snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261013T063229017324Z/`, 승인 원문·byte 백업·실행 로그·독립 SQL·test·progress 검증은 `data/backups/approved_content_batch/h58_approval_20261013/`에 보존한다. Work SHA는 `bc6347374e03cdfc651422be525d201f1c0b7659006de5ef82316046043ce78b` → `f1c4634bb4ce4270b0d9e7128655bc35f304cd9230aef7ae0f65cfbd6ed44275`, seed SHA는 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`로 불변이다.

독립 SQL은 전체13테이블·DDL·공식snapshot·기존승인·원천·machine evidence36개를 대조했다. 승인된42변경과 history42행·관련sequence 증가 외 차이 없고 모든 비대상 행·schema·user_version은 불변이다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 snapshot schema cookie1369/원본1368은 VACUUM INTO의 정상 차이다. SQL55조회·349검증과 기존 applicator Flutter 테스트29건이 통과했다. 조회 SQL·결과·해석은 `sql_verification.json`에 보존한다.

공식 CLI로 표준 외부 `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 함께 갱신했다. 대상12개만 unapproved→explicit_approved, 전체14,298 중 승인223→235·hold6 동일·미승인14,069→14,057·anomaly113 동일이다. JSON/CSV14,298행, 공식 CSV·Markdown 렌더 일치와 모든 비대상 progress 행 불변을34항목으로 검증했다. 승인 비율은1.559659%→1.643587%이며 hold를 승인에 합산하지 않는다. Snapshot identity는 `025276fc167ef010d7bdadcdbdfda3747bcc444ff8ca7dd024809cd625f52c40`다.

연구는 CORE12·전체canonical23건/21절 검토이며 미해결2건을 보존한다. 원본 discovery는86nodes·91edges·frontier69·research_complete=false로 유지하고 H1004 등의 허브 예외와 CORE 직접 관계 전량 검토를 구분한다. UI 테스트·앱 빌드는 N/A다. 이번 승인 범위는 DB·문서 반영이며 commit·merge·push·작업 브랜치 삭제는 수행하지 않았다. DB 파일은 기존 정책대로 Git 미추적 로컬 자산이다.


### 11.57 H68 클러스터 approved-content work DB slice

[h68_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h68_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H68-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-13 H68의 최종 `돌` / `추(錘)`와 슥5:8 납덩이 비고 및 나머지 최신 추천안의 문서·DB 적용, 외부 연구 산출물 정비를 승인했다. 승인 원문과 정확한 값은 `data/backups/approved_content_batch/h68_approval_20261013/00_approved_content.md`에 있다. Approval SHA `49870d84818e02fa75afc6a1fd80c0a3d3f71e35ebf093b1ac8ddf3800ac1607`, manifest SHA `da2174430a776655aa4d6ac95357877c8072a41333fd39af1d4233bb8ae53387`이며 working bytes·index·공식 applicator 사본이 일치한다. 새 manifest에만 `text eol=lf`를 적용했다.

CORE25 중 의미 교체20·기존값 그대로 의미 승인5·비고 교체16, 신규 관계26을 반영했다. 실제 write62operations이며 history group `1791883039053166`의 active62행(ID5964–6025)은 word update36·relation create26, undone0이다. 관계ID7826–7851은 derived11·compound10·root_shared4·variant1, 모두 asserted다. 어원 관계4건은 비생성, 기존 relation367과 hold6건은 유지한다. 최종 의미·비고·관계·채택 근거·대안·불확실성은 [H68 결정 기록](../semantic_decisions/h68_cluster_approved_content_slice.md)에 기록했다.

공식 dry-run의 사본 적용·undo와 live apply가 성공했다. Snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261013T091717814887Z/`, 승인 원문·원본 byte 백업·독립 SQL·실행 로그·테스트·progress 검증은 `data/backups/approved_content_batch/h68_approval_20261013/`에 보존한다. Work SHA `f1c4634bb4ce4270b0d9e7128655bc35f304cd9230aef7ae0f65cfbd6ed44275` → `69935b6edf5f868d7703d1e7528153f8365fe2a89eb239b534dd936216dfefb6`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다.

독립 검증은 전체13테이블·DDL·snapshot·비대상 행·기존 manifests·machine evidence81개를 대조해 300항목을 통과했다. 승인 범위·history·관련 sequence 외 변경 없으며 work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이다. 조회 SQL·결과·해석은 `sql_verification.json`에 있다. 기존 approved-content applicator Flutter 테스트29건도 통과했다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 갱신했다. CORE25만 unapproved→explicit_approved이며 전체14,298 중 승인235→260·hold6·미승인14,057→14,032·anomaly113이다. 모든 비대상 progress 행은 동일하고 CSV14,298행·공식 CSV/Markdown 렌더 일치를 확인했다. Snapshot identity `efdc5feba7c0ee7a1583c1e113b0a263aa43c43ab64205d3c92303e13de71e07`, 승인 비율1.643587%→1.818436%다.

외부 현재 요약·검토표를 승인 적용 상태로 정리하고 H68의 이전 저울추 값과 coverage를 최신 추 범위로 수정했다. 최초 상세 연구와 자동 대기표는 과거 스냅샷으로 명시하여 보존한다. Full Review81개 및 원본 발견 state는 바이트 불변이고 frontier100·research_complete=false를 유지한다. CORE25·812토큰 검토와 전역 발견 완료는 구분한다. 앱 코드·표현·발음·언어·schema·seed 변경 없으며 UI 테스트·앱 빌드는 N/A다. 문서·DB 반영 완료 뒤 사용자가 커밋·main fast-forward 병합·push·이번 작업 브랜치 정리를 추가 승인했다. 실제 공개 커밋은 Git 이력에서 확인한다.

### 11.58 H73 클러스터 approved-content work DB slice

[h73_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h73_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H73-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-13 착용 위치 재검토 후의 최신 `띠` 의미·비고와 문서·DB·Git·작업 브랜치 정리를 승인했다. DB는 같은 날 적용했고 중단된 문서·Git 마무리는 2026-10-14 재개했다. 승인 원문과 정확한 값은 `data/backups/approved_content_batch/h73_approval_20261013/00_approved_content.md`, approval SHA는 `9fee3767b6d035209185d233e9df2273e29d1dd592b940c6649fb37b08f7f122`다. Manifest SHA는 `280f8562051fb619f9eba2beff14281f047d7c91766c50af4174f5dcf9ed684a`이며 새 manifest에만 `text eol=lf`를 적용했다.

H0073_0000의 meaning seq1을 `띠, 허리띠`에서 `띠`로 교체하고 NULL 비고에 옷 위로 몸통에 두르는 기능, 제사장·관리의 복장, 요세푸스의 가슴 부근 착용 설명을 추가했다. 의미1·비고1의 총2operations이며 관계는 기존0건 유지, 신규 word hold0·기존 hold6 유지다. 최신 결정은 초기 허리띠 추천을 대체한다. 정확한 비고·근거·배제 대안·후대 증언의 한계는 [H73 결정 기록](../semantic_decisions/h73_cluster_approved_content_slice.md)과 README active 색인에 기록했다.

공식 dry-run의 사본 적용·undo와 live apply가 성공했다. History group `1791890340110875`의 active2행은 H73 word update이며 undone0이다. Snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261013T111858887270Z/`, 승인 원문·실행 로그·독립 SQL·test·progress 검증은 `data/backups/approved_content_batch/h73_approval_20261013/`에 있다. Work SHA는 `69935b6edf5f868d7703d1e7528153f8365fe2a89eb239b534dd936216dfefb6` → `0eca226722a751627f2b3c4e5e91885a7c19fa8871fabfe71ceaf87aced21fb2`, seed SHA는 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`로 불변이다. 재개 시에도 적용 후 hash를 확인했고 DB를 재적용하지 않았다.

독립 SQL43조회·148검증으로 전체13테이블·schema·snapshot·비대상 행을 대조했다. 승인된 meaning·비고와 history·관련 sequence 외 변경 없고 표현·음역·발음·언어·관계·기존 history·DDL은 불변이다. Work·seed·snapshot integrity ok·FK0·sidecar0이며 초기 입력과 machine evidence113파일을 보존했다. 조회 SQL·결과·해석은 `sql_verification.json`에 있다. 기존 approved-content applicator Flutter 테스트29건도 통과했다.

공식 CLI로 표준 외부 `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/semantic_progress`의 JSON·CSV·Markdown을 함께 갱신했다. 전체14,298행 중 H73만 unapproved→explicit_approved, 승인260→261·hold6·미승인14,032→14,031·anomaly113이다. JSON/CSV 행 수·공식 CSV/Markdown 렌더·비대상 행 불변·승인값 일치 등11항목을 검증했다. Snapshot identity는 `c638d45450ed185786967956e30c6af6982ad86eb80b8b1b5146651859e4059f`, 승인 비율은1.818436%→1.825430%다.

연구는 CORE1·canonical9토큰/9절 전량 검토, frontier0·discovery/research_complete=true다. 외부 요약은 최신 승인값으로 갱신하고 초기 요약은 로컬 검증 폴더에 과거 제안으로 보존한다. Machine state·Packet·관계·Review는 적용 전 연구 스냅샷으로 유지한다. 로컬 번역본·LXX 참고자료의 provenance·versification·license 한계와 어원 불확실성을 보존했다. DB 파일은 기존 정책대로 Git 미추적 로컬 자산이다. 앱 코드·schema·seed 변경이 없어 UI 테스트·앱 빌드는 N/A다.

### 11.59 H74 클러스터 approved-content work DB slice

[h74_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h74_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H74-CLUSTER-APPROVED-CONTENT-SLICE`다. 최신 의미·비고·관계는 2026-10-14 승인되었고, 기존 NULL 관계 적용 도구의 최소 보완과 실행 보류 해제는 2026-10-15 승인되었다. 최종 결정·근거·대안·불확실성은 [H74 결정 기록](../semantic_decisions/h74_cluster_approved_content_slice.md)에 있다. Meaning 교체10·기존값 유지 승인1·비고 교체11·관계 신규6·기존 교체2를 반영했다. 기존 relation3993과 hold6건은 유지한다.

재개 승인 문서는 `data/backups/approved_content_batch/h74_approval_20261014/02_resumed_approval_20261015.md`, approval SHA는 `cc432b613bfd8458a1adedf23ca055aac5087425d8b0e1cbfc8cf6283a167517`, manifest SHA는 `fe570ae8321b94aeedbe3906b3b1980b68182b4d23d55e9ee82b9b83dd9db7df`다. 새 manifest에만 `text eol=lf`를 적용했다. 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261014T230522949321Z/`에, 원승인·보류·재개 기록과 독립 검증은 `data/backups/approved_content_batch/h74_approval_20261014/`에 있다. Work SHA는 `0eca226722a751627f2b3c4e5e91885a7c19fa8871fabfe71ceaf87aced21fb2` → `2bf598118f3023b5179116fdfd3cdb1a0d0513283e23834e70133c0598579fa5`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다.

공식 dry-run에서 29건의 사본 적용과 실제 undo 1회 복원이 성공했고, live apply도 성공했다. History group `1792019124584167`의 active29행(ID6028–6056)은 word update21·relation create6·relation update2, undone0이다. 신규 관계 ID7852–7857과 기존 ID3994·6692의 최종값을 확인했다.

독립 SQL54조회·175검증으로 전체13테이블·DDL·적용 전 byte 백업·공식 snapshot을 비교했다. 승인 meaning·비고·관계와 해당 history·sequence 외 차이가 없다. Work·seed·snapshot·적용 전 백업 integrity ok·FK0·sidecar0, seed SHA 불변이며 기존 승인·원천·raw evidence160파일도 불변이다. 조회 목적·SQL·결과·해석은 로컬 `sql_verification.json`에 있다.

공식 progress JSON·CSV·Markdown을 함께 생성하고28항목을 검증했다. 전체14,298행 중 CORE11만 바뀌어 승인261→272·hold6·미승인14,031→14,020·anomaly113이다. 비대상 행 불변과 공식 CSV/Markdown 렌더 일치를 확인했다. Snapshot identity는 `71035b533e26e433b3ae0da452a5a5f3944d7de498e64a8d2458c5ac1c3a54e1`다.

최소 보완한 applicator 코드3파일과 관련 테스트의 정적 분석은 오류0이며 Flutter 테스트31건이 통과했다. 기존 관계의 before category_code/relation_type에만 명시적 NULL을 허용하고 새 값·신규 관계 검증은 유지한다. 잘못된 before, NULL after 거부와 NULL 원본의 undo 복원을 검증했다. UI·schema·의존성 변경이 없으므로 사용자 UI 테스트와 전체 앱 빌드는 N/A다.

연구는 CORE11·222토큰/165절 전량 검토이며 잠21:4 미해결·CONTEXT2·HUB-EXCLUDED174·원본 frontier45·전역 closure 미선언을 유지한다. Raw Packet·관계·Review33파일과 machine state/queue는 역사적 연구 스냅샷으로 보존하고 human assessment·coverage·요약·실행 상태만 최신 적용 결과로 갱신했다. 코드 보완 계약은 [applicator 문서](APPROVED_CONTENT_BATCH_APPLICATOR.md)에 있다. 스키마·표현·발음·언어·seed 변경은 없으며 DB는 Git 미추적 로컬 자산이다. DB·문서 반영 완료 뒤 사용자가 커밋·main fast-forward 병합·push를 추가 승인했다. 실제 공개 커밋은 Git 이력에서 확인하며 작업 브랜치 삭제는 이번 승인에 포함하지 않는다.

### 11.60 H76 확장 어휘군 approved-content work DB slice

[h76_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h76_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H76-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-15 H5042 `솟아나다·발하다(發하다)`·G2044 `발하다(發하다)`의 최신안과 나머지 의미·비고·관계 제안 및 문서·DB 반영을 승인했다. Meaning6·비고5·신규 관계3의 총14operations를 적용했다. 최종값·근거·대안·재검토 조건은 [H76 결정 기록](../semantic_decisions/h76_cluster_approved_content_slice.md)과 README active 색인에 기록했다.

H76 `물집·종기(腫氣)`, H77 `에베스·에베츠 (지)`, H78 `입산·이브찬 (인)`, H5042 `솟아나다·발하다(發하다)`, H4002 `샘`, G2044 `발하다(發하다)`를 각각 seq1 한 행으로 저장했다. H4002 비고는 NULL 유지다. ID7858은 H77–H78 etymological/root_shared/hypothesized/undirected, ID7859는 H5042→H4002 morphological/derived/asserted/w2_to_w1, ID7860은 H5042→G2044 translation/semantic_translation/asserted/w2_to_w1이다. Pair는 canonical ID 순서로 저장하고 방향은 별도 code로 표현한다. 번역 관계 note는 시편·마13:35의 발화 문맥과 로컬 LXX 시77:2의 동사 차이를 명시한다. H76–H78·H76–H5042는 비생성, 신규 word hold0·기존 hold6 유지다.

승인 원문·정확한 값·실행 로그·독립 검증은 `data/backups/approved_content_batch/h76_approval_20261015/`에 있다. Approval SHA는 `2d6ac244e212907b0316f1adc6a7fb139069d8eacb2c0036dc2cb8e8269e6b78`, manifest SHA는 `c2429c0ac7f5922977d6357c05d23b36c4f410534b492ec35d5c219afbc29a1a`이며 working bytes·index blob·공식 백업 사본이 일치한다. 새 manifest에만 LF 속성을 추가했다. 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261015T121631217325Z/`에 보존한다.

공식 dry-run은 사본 적용·undo와 원본 불변을 검증했고 live apply가 성공했다. History group `1792066592406993`에는 active14행(word update11·relation create3, undone0)을 기록했다. Work SHA는 `2bf598118f3023b5179116fdfd3cdb1a0d0513283e23834e70133c0598579fa5` → `995754cc28397c0c9d2bfb24f44d2b5a183fb9bfec5ecce3fb8188f53f7cab90`, seed SHA는 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`로 불변이다. 독립 SQL49조회·361검증에서 전체13테이블·DDL·snapshot·비대상 행·보호 입력을 대조했다. 승인 meaning·비고·관계와 history·해당 sequence 외 변경 없고 work·seed·snapshot integrity ok·FK0·sidecar0이다. SQL·결과·해석은 `04_sql_verification.json`에 있다. 기존 applicator Flutter 테스트31건도 통과했다.

공식 CLI로 표준 외부 `reshet_research_output/semantic_progress` JSON·CSV·Markdown을 함께 갱신하고32항목을 검증했다. 전체14,298행 중 대상6개만 unapproved→explicit_approved이며 승인272→278·hold6·미승인14,020→14,014·anomaly113이다. 공식 CSV/Markdown 렌더와 비대상 행 불변을 확인했다. Snapshot identity는 `feb91c525329b42140c7a3e13e0fb7ea6106cc93473c21c71b9bbe2187a73cc7`이고 승인 비율은1.902364%→1.944328%다.

연구는 CORE6·canonical20토큰 전량 검토, 주 state5단어와 G2044 별도 state1단어 모두 frontier0이다. Canonical edge와 reference-only 관계 후보를 구별하며 로컬 LXX·번역본의 provenance·license 한계 및 어원·전10:1 풀이의 불확실성은 보존한다. Raw Packet·관계·Review와 machine state/queue는 적용 전 스냅샷으로 유지하고 외부 현재 요약·추천값·실행 상태를 최종 적용값으로 갱신한다. 앱 코드·표현·발음·언어·schema·seed·canonical source·hold ledger 변경이 없고 UI 테스트·전체 앱 빌드는 N/A다. DB는 기존 정책대로 Git 미추적 로컬 자산이며 DB·문서 반영 완료 뒤 사용자가 커밋·main fast-forward 병합·push 및 이번 작업 브랜치 정리를 추가 승인했다. 실제 공개 커밋은 Git 이력에서 확인한다.


### 11.61 H79 어휘군 approved-content work DB slice

[h79_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h79_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H79-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-15 H79 어휘군 추천안과 문서·DB 및 필요한 파일 반영을 승인했다. H79 `씨름하다`·H80 `먼지`는 meaning_approvals 2건으로 현행 seq1 projection을 승인하고, H81 `가루, 분말`은 `가루` 한 행으로 교체했다. 비고3·신규 관계1을 포함한 DB write는5건이며, 유지 의미 승인은 별도2건이다. 최종 선택·근거·대안·재검토 조건은 [H79 결정 기록](../semantic_decisions/h79_cluster_approved_content_slice.md)과 README active 색인에 기록했다.

Relation ID7861은 H0080_0000→H0081_0000, morphological/derived/asserted/w1_to_w2다. H81의 feminine of 설명을 여성명사 형성으로 보존하며 source-reference 방향을 그대로 복사하지 않는다. H79–H80은 원시 어근과 실제 명사 유래 동사의 층위를 구분할 근거가 부족하여 이번에 관계를 생성하지 않는다. 신규 word hold0·기존 hold6 유지이며 세 단어의 의미는 각각 sense1개다.

승인 원문과 검증은 `data/backups/approved_content_batch/h79_approval_20261015/`에 있다. Approval SHA는 `cd9ad6d2739e684f6435de20527d7c2029b3ea69dc1c0aafb05d9e0735076667`, manifest SHA는 `0a794a9c5bc93d9cbfa5eaa651e4af4e3ff42313bb5817237b75461cc5ef0912`다. 이미 적용한 CRLF manifest의 정확한 바이트를 보존하도록 이 새 경로에만 기존 H58 사례의 `-text whitespace=cr-at-eol` 속성을 사용했고 working bytes·index blob·공식 백업 사본 SHA를 일치시켰다. 승인 원문 기록의 예정 LF 방식과 실제 바이트 보존 방식의 차이는 `00_manifest_encoding_note.md`에 기록했다. 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261015T133207457012Z/`에 보존한다.

공식 dry-run은 사본 적용·undo와 원본 불변을 검증했고 live apply가 성공했다. History group `1792071128623516`은 active5행(word update4·relation create1, undone0)이다. Work SHA는 `995754cc28397c0c9d2bfb24f44d2b5a183fb9bfec5ecce3fb8188f53f7cab90` → `4ffa7ba1ee885df0959c4016b6f362328bc0abb15d0072e864f2eea00f93534a`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL39조회·188검증에서 전체13테이블·DDL·snapshot·비대상 행·보호 입력을 대조했다. 승인된 meaning·비고·관계, history 및 해당 sequence 외 변경이 없고 work·seed·snapshot integrity ok·FK0·sidecar0이다. SQL·결과·해석은 `04_sql_verification.json`에 있다. 기존 applicator Flutter 테스트31건도 통과했다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 함께 갱신하고82항목을 검증했다. 전체14,298행에서 대상3개만 unapproved→explicit_approved이며 승인278→281·hold6·미승인14,014→14,011·anomaly113이다. Snapshot identity는 `4b32751a996abe9f2863db2407d81a647350d83dc00058ce45f46b46e4151ca7`이다. Canonical Strong·OSHB 전체9용례, 로컬 참고자료와 명시적 LXX 구절을 검토했으며 절 번호·어원·reference-only 한계를 결정 기록에 보존한다. Raw 연구 artifact는 적용 전 snapshot으로 유지한다. 앱 코드·expression·발음·언어·schema·seed·canonical source·hold ledger 변경이 없으며 UI 테스트·전체 앱 빌드는 N/A다. DB는 기존 정책대로 Git 미추적 로컬 자산이다.

### 11.62 H85·G11 이름군 approved-content work DB slice

[h85_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h85_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H85-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-15 최신 의미·비고·관계 제안과 DB·문서 및 필요한 파일 반영을 승인했고, Asia/Seoul 기준 2026-10-16에 DB 적용했다. H0085·G0011의 meaning을 각각 seq1 `아브라함·아브-라함 (인)`으로 교체하고 비고2·기존 관계 교체3을 포함한 총7operations를 반영했다. 최종값·근거·주요 대안·재검토 조건은 [H85·G11 결정 기록](../semantic_decisions/h85_cluster_approved_content_slice.md)과 README active 색인에 있다. H87·H48의 기존 승인 meaning·비고와 관계6건은 유지하며 신규 관계·삭제·supersession·hold 변경은 없다.

Relation ID23은 H85→G11 transliteration/direct_transliteration/asserted/w2_to_w1, ID24는 H1→H85 morphological/compound/asserted/w1_to_w2다. ID5377은 H1995→H85 unspecified/related/asserted/w2_to_w1로 교체했다. ID·canonical pair·created_at을 보존하고 방향은 별도 code로 기록했다. H1995 연결은 창17:5의 이름 풀이이며 역사적 compound 구성을 확정하지 않는다. G11 음역 `아브라암`은 기존 expression에 보존하고 행7:16의 Strong 추정은 비고로 한정한다.

승인 원문·정확한 값·실행 로그·독립 검증은 `data/backups/approved_content_batch/h85_approval_20261015/`에 있다. Approval SHA는 `8f2a6ffcfced8ef70b9c07354842c1a60edb0d7b4227d29238986b2763485016`, manifest SHA는 `74d1090b4fe8c8d4dd0560314e150344fc9419b4c524cd6ab53da2680dd6356c`이며 working bytes·index blob·공식 백업 사본이 일치한다. 새 manifest에만 `text eol=lf`를 추가했다. 적용 전 byte 백업과 공식 snapshot·result·manifest 사본을 보존하며 공식 결과 폴더는 `data/backups/approved_content_batch/20261015T150001848447Z/`다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792076403128673`의 active7행(ID6076–6082)은 word update4·relation update3, undone0이다. Work SHA는 `4ffa7ba1ee885df0959c4016b6f362328bc0abb15d0072e864f2eea00f93534a` → `55db8b355cec97f54e545bacdd820ecafd41abff3fb7822709d22157a63da8a4`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL75조회·242검증에서 전체13테이블·DDL·snapshot·byte 백업·비대상 행·보호 입력을 대조했다. 승인 meaning2·비고2·기존 관계3, history7·해당 history sequence 외 변경이 없고 교체 pair의 중복·이전 관계 잔존이 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이다. 조회 목적·SQL·결과·해석은 `04_sql_verification.json`에 있다. 기존 applicator Flutter 테스트31건이 통과했다.

공식 CLI로 표준 외부 `reshet_research_output/semantic_progress` JSON·CSV·Markdown을 함께 갱신하고27항목을 검증했다. 전체14,298행 중 H85·G11만 unapproved→explicit_approved이며 승인281→283·hold6·미승인14,011→14,009·anomaly113이다. 비대상 행 불변과 공식 CSV/Markdown 렌더 일치를 확인했다. Snapshot identity는 `62fe3b778d828a6d95fec9ba523b25b44094fc3b58aab769fc19f1284e72e04f`다.

연구 CORE4의 canonical320토큰을 전량 검토했으며 H1·H7311 허브 경계, CONTEXT3·HUB-EXCLUDED62, 원본 frontier39·`max_nodes_reached`·전역 closure 미선언을 유지한다. 기존 연구29파일과 원천·참고자료·기존 승인 manifest·hold ledger는 불변이다. 원본 Packet·Review·machine state는 적용 전 연구 snapshot으로 보존하고 적용 결과는 외부 `00_applied_content.md/json`에 별도 기록한다. 앱 코드·expression·발음·언어·schema·seed 변경이 없고 UI 테스트·전체 앱 빌드는 N/A다. DB는 Git 미추적 로컬 자산이다.

### 11.63 H86 외침 어휘 approved-content work DB slice

[h86_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h86_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H86-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-16 추천안과 DB·문서 및 필요한 파일 반영을 승인했다. H0086의 seq1 meaning을 `무릎을 꿇다`로 교체하고 번역·어원·형태 불확실성을 설명하는 비고1건을 추가한 총2operations를 적용했다. 최종값·선택 근거·대안·재검토 조건은 [H86 결정 기록](../semantic_decisions/h86_cluster_approved_content_slice.md)과 README active 색인에 있다. 현재 관계0건 유지·신규 관계0건·새 hold0건이며 expression·발음·언어·schema·seed·원천 및 기존 hold ledger는 불변이다.

승인 원문과 독립 검증은 `data/backups/approved_content_batch/h86_approval_20261016/`, 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261015T155253183782Z/`에 보존한다. Approval SHA는 `ac4c4c040f5d659655c17dbe557abaf3c9cf439f0e549ab381f7e3befb13a317`, manifest SHA는 `6d8d5f2add3f8fd83b5af1525342bb41614e9f7146da9327fe107a50f0923185`다. 실제 적용된 manifest의 CRLF 원본 바이트를 Git index 및 공식 사본과 일치시키기 위해 해당 새 경로에만 `.gitattributes`의 `-text whitespace=cr-at-eol` 규칙을 추가했다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792079574370818`의 ID6083–6084는 active word update2행, undone0이다. Work SHA는 `55db8b355cec97f54e545bacdd820ecafd41abff3fb7822709d22157a63da8a4` → `1eca4a97830ddd97c358950233442111f4f01d6bf2b53939416b340e4ed82c27`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL55조회·66검증으로 전체13테이블·DDL·snapshot·byte 백업을 비교했으며 승인 meaning·비고·history2행 및 history sequence 외 변경이 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0, 기존 applicator 테스트31건 통과. SQL 목적·실행문·결과·해석은 `03_independent_db_verification.json`에 있다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298행에서 H86만 unapproved→explicit_approved이며 승인283→284·hold6·미승인14,009→14,008·anomaly113이다. 비대상 행과 anomaly는 불변이며 snapshot identity는 `d892cc1ea470e7942a63b862ce9bd9f5a0f54402900b5e18838af7c8d568b6d1`다. 진행 현황은 derivative이고 semantic authority는 현재 승인 manifest와 DB다.

정상 단일-node cluster closure, canonical 전체1출현, 로컬6종 및 명시적 LXX1절의 검토 결과를 사용했다. 정확한 뜻·어원·형태는 여전히 미확정이며 대표 풀이와 비고를 승인한 것으로 기록한다. 기존 연구11파일은 적용 전 snapshot으로 보존하고 적용 결과는 외부 `00_applied_content.md/json`에 별도 기록한다. 앱 코드·UI 변경이 없어 사용자 UI 테스트·전체 앱 빌드는 N/A다. DB는 기존 정책대로 Git 미추적 로컬 자산이다.


### 11.64 H88·H178 어휘군 approved-content work DB slice

[h88_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h88_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H88-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-16 Codex의3 sense 추천안과 DB·문서·필요한 파일·Git 게시·문제없는 경우 작업 브랜치 정리를 승인했다. H88의 `오봇 (지)`는 meaning_approvals1건으로 기존 projection을 승인하고 H178의 쉼표 결합1행을 `신접한 자(神接한 者)` / `가죽 부대` / `죽은 이의 영(靈)`의 ordered3행으로 교체했다. 비고2·신규 관계1을 포함한 DB write는4건이며 유지 의미 승인은 별도1건이다. 최종 결정·근거·미채택 대안·잔여 불확실성은 [H88·H178 결정 기록](../semantic_decisions/h88_cluster_approved_content_slice.md)과 README active 색인에 있다.

Relation ID7862는 H0178→H0088, morphological/derived/asserted이며 canonical pair H0088_0000·H0178_0000 및 direction_code=w2_to_w1로 저장했다. H178 복수형의 지명 형성을 나타내고 지명 의미를 일반명사로 대체하지 않는다. H1–H178 apparently 어원 관계는 생성하지 않는다. H1 기존 승인 유지·새 hold0·기존 hold6 유지이며 expression·음역·발음·언어·schema·seed·canonical source·local reference는 불변이다.

승인 원문·byte 백업·독립 검증은 `data/backups/approved_content_batch/h88_approval_20261016/`, 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261015T164427883724Z/`에 보존한다. Approval SHA는 `a978bf9a1732eb43869a235a89da19d612bfdd276d159df65b5a6dc86d858ff8`, manifest SHA는 `3c8f0e4f1fc8649ddda64c10ede7b636435be21e9d35cc0a1694d7ca385175b9`다. 새 manifest는 처음부터 UTF-8 LF로 기록하고 해당 경로에만 `.gitattributes`의 text eol=lf를 지정하여 work bytes·index blob·공식 사본의 SHA를 일치시켰다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792082669067326`의 ID6085–6088는 active4행(word update3·relation create1, undone0)이다. Work SHA는 `1eca4a97830ddd97c358950233442111f4f01d6bf2b53939416b340e4ed82c27` → `5751bea2c8d370309b6cc665fb49da865416876cd2c02c135e82c3cf7bee3806`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL52조회·53검증으로 전체13테이블·DDL·snapshot·byte 백업을 비교했고 승인 의미·비고·관계 및 해당 history/sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 기존 applicator 테스트31건 통과. SQL 목적·실행문·결과 digest·해석은 `03_independent_db_verification.json`에 있다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298행에서 H88·H178만 unapproved→explicit_approved이며 승인284→286·hold6·미승인14,008→14,006·anomaly113이다. 비대상 행·anomaly와 기존60 승인 manifest·원천·참고자료·hold fingerprint는 불변이다. Progress 및 보호 입력 검증44건이 통과했고 snapshot identity는 `9332d189006f00b3277c23ea49ef492b370920e01525493e1ef2f9b3a33c4b50`다.

연구 CORE2의 canonical21 token/20절을 전량 검토한 추천안을 채택했다. H1 hub 예외·CONTEXT1·HUB-EXCLUDED44·원본 frontier39·max_nodes_reached·전역 graph closure 미선언을 유지한다. H178의 사람/영/술법 competing9 token을 비고에 보존하며 별도 술법 sense는 미채택했다. 원본 연구16개 artifact와 machine state/queue는 적용 전 snapshot으로 보존하고 외부 `00_applied_content.md/json`에 적용 결과를 별도로 기록한다. DB는 Git 미추적 로컬 자산이며 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.


### 11.65 H89·H90·H91 이름군 approved-content work DB slice

[h89_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h89_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H89-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-16 최신 가문 풀이·기반 인명 병기와 DB·문서·필요한 파일·Git 게시 및 이상 없는 경우 이번 작업 브랜치 정리를 승인했다. H89 아게 (인)는 meaning_approvals1건으로 기존 projection을 승인하고 H90은 아각·아가그 (인), H91은 아각 사람·아가그 가문(家門) 사람으로 교체했다. 비고3·신규 파생 관계1을 포함한 DB write는6건이며 유지 의미 승인은 별도1건이다. 최종값·선택 근거·미채택 대안·잔여 불확실성은 [결정 기록](../semantic_decisions/h89_cluster_approved_content_slice.md)과 README active 색인에 있다.

H90→H91 신규 relation ID7863은 morphological/derived/asserted, canonical pair H0090_0000–H0091_0000, direction w1_to_w2다. 어휘 형성을 나타내며 하만이 특정 아각의 실제 후손임을 입증하는 관계가 아니다. H89–H90 compare 관계는 생성하지 않고 새 hold는 없다. Expression·음역·발음·언어·schema·seed·원천·로컬 참고자료·기존 hold6건은 불변이다.

승인 원문·byte 백업·독립 검증은 `data/backups/approved_content_batch/h89_approval_20261016/`, 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261016T014727086038Z/`에 보존한다. Approval SHA는 `bb9e83ef934dbc5b51a806fa3e01e1a73c01b09147d97d4920c536fe4fdf759f`, manifest SHA는 `a77d889b7b816eadbda642230899a3ebeb075c32127ee1c3d2249d0a5cc27d02`다. 실제 적용한 CRLF manifest 바이트와 Git index·공식 사본을 일치시키기 위해 새 경로에만 `.gitattributes`의 `-text whitespace=cr-at-eol`을 지정했다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group1792115248248599의 ID6089–6094는 active6행(word update5·relation create1), undone0이다. Work SHA는 `5751bea2c8d370309b6cc665fb49da865416876cd2c02c135e82c3cf7bee3806` → `18bdd88377ed7c6bd1f9d92a62bf5525cbc061c2e8f71293d30c22939bdc1bba`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL47조회·48검증으로 전체13테이블·DDL·snapshot·byte 백업을 비교했고 승인 데이터·history6행 및 해당 sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0, 기존 applicator Flutter 테스트31건 통과. SQL 목적·실행문·결과 digest·해석은 `04_independent_db_verification.json`에 있다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298행에서 H89·H90·H91만 unapproved→explicit_approved이며 승인286→289·hold6·미승인14,006→14,003·anomaly113이다. 비대상 row·anomaly는 불변이고 progress 교차검증19건이 통과했다. Snapshot identity는 `d62ba43514b6d4d1b9fe9f22bc37c486382770f4ff1e2f5c1423147bc4f0a805`다. Progress는 derivative이며 현재 DB와 승인 manifest를 대체하지 않는다.

정상 CORE3 closure·frontier0, 전체14 canonical token/12절 및 로컬 참고6종·명시적 LXX12절의 연구를 사용했다. 가문 풀이와 실제 혈통 확인을 구분하고 H90의 왕명·칭호·불꽃 어원 및 source x-pn의 한계를 비고·결정 기록에 보존했다. 원본 연구17개 파일과 machine state/queue는 적용 전 snapshot으로 남기며 외부 `00_applied_content.md/json`에 최종 적용값을 별도로 기록한다. DB는 Git 미추적 로컬 자산이고 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.


### 11.66 H92 묶음·결속 어휘 approved-content work DB slice

[h92_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h92_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H92-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-16 마지막 추천의 네 meaning과 비고 전문을 채택하고 DB·문서·필요한 파일 반영, 검증 성공 후 Git 완료와 작업 브랜치 정리를 승인했다. 기존 `띠, 무리, 묶음` 한 행을 `묶음` / `묶는 줄` / `무리` / `둥근 천장(天障)` ordered 4행으로 교체하고 비고를 추가했다. Meaning replacement1·note replacement1의 총2 write다. 정확한 최종값·판단 근거·미채택 대안·잔여 불확실성은 [H92 결정 기록](../semantic_decisions/h92_cluster_approved_content_slice.md)과 README active 색인에 있다.

아모스의 둥근 천장은 결합된 건축 구조를 하늘의 천장으로 이해하는 전통적 해석으로 채택하고, 정확한 지시 대상·기초 지지 구조 대안·KJV 무리/묶음·LXX 약속의 차이를 마지막 승인 비고에 보존했다. 기존 relation0에서 생성·교체·삭제0이며 새 hold도 없다. 원문·음역·발음·언어·schema·seed·원천·로컬 reference·기존 hold6건은 불변이다.

승인 원문·byte 백업·독립 검증은 `data/backups/approved_content_batch/h92_approval_20261016/`, 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261016T025722639484Z/`에 보존한다. Approval SHA는 `2f1895f9bd369d1e3a3c66df27657d4c8593d71d0cc754992c770657fdb223a4`, manifest SHA는 `52e570991d56e05522a18e9370f0c9264423be9240170026a87e6a6756562832`다. 새 manifest의 UTF-8 LF bytes와 Git index·공식 사본이 일치하도록 해당 경로에만 `.gitattributes`의 `text eol=lf`를 지정했다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792119443828097`의 ID6095–6096은 active word update2행, undone0이다. Work SHA는 `18bdd88377ed7c6bd1f9d92a62bf5525cbc061c2e8f71293d30c22939bdc1bba` → `1ba1c63b8f35fc0fdd942e4652d1350af46199effe000f5f070c63006e4e2015`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL53조회·60검증으로 전체13테이블·DDL·byte 백업·공식 snapshot을 비교했고 승인 의미·비고·history2행 및 해당 sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 기존 applicator Flutter 테스트31건이 통과했다. SQL 목적·실행문·결과·해석은 `05_independent_db_verification.json`에 있다.

공식 표준 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298행 중 H0092만 unapproved→explicit_approved이며 승인289→290·미승인14,003→14,002·hold6·anomaly113이다. Progress·보호 입력 교차검증37건이 통과했고 snapshot identity는 `ed64761d8621d91de41838c3b477f4ca605807e7bb85056587d6d0e4f8648586`다. 기존62 manifest·원천·로컬 reference·hold와 비대상 progress row는 불변이다. 정상 CORE1 closure·frontier0, canonical4회 전량 및 확보 reference를 검토한 결과를 사용했으며 아모스1건의 해석 불확실성을 유지한다. 원본 연구16파일은 보존하고 실제 적용값은 외부 `00_applied_content.md/json`에 별도로 기록한다. DB는 Git 미추적 로컬 자산이며 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.


### 11.67 H93 호두 어휘 approved-content work DB slice

[h93_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h93_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H93-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-16 일반 견과/특정 호두의 추가 확인을 거친 최신 `호두` meaning과 비고, DB·문서·필요한 파일 반영 및 검증 성공 후 Git·이번 작업 브랜치 정리를 승인했다. 기존 `견과, 호도` 1행을 `호두` seq1로 교체하고 비고를 추가한 총2 write다. 최종값·근거·미채택 대안·재검토 조건은 [H93 결정 기록](../semantic_decisions/h93_cluster_approved_content_slice.md)과 README active 색인에 있다. 아가 6:11의 집합적 호두나무 문맥, 수종 식별 및 추정 어원의 한계를 비고에 보존한다. 관계 생성·교체·삭제0·신규 hold0이며 기존 hold6·표현·음역·발음·언어·schema·seed·원천·local reference는 불변이다.

승인 원문·byte 백업·검증은 `data/backups/approved_content_batch/h93_approval_20261016/`, 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261016T042716757685Z/`에 보존한다. Approval SHA는 `b8a774a9b664d24008460d7f6483d91a28300d90257069ec427972a5ce315136`, manifest SHA는 `fc843724ced6b76606687e03db2a257f44b365ece9db96ce78e965a261eff2f5`이며 새 경로의 text eol=lf 지정으로 work bytes·index blob·공식 사본이 일치한다. 공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792124837912598`의 ID6097–6098는 active word update2행, undone0이다. Work SHA는 `1ba1c63b8f35fc0fdd942e4652d1350af46199effe000f5f070c63006e4e2015` → `128f8ff9866e6637fde6d07b08c50a5f8e42a464c6e81fec0d8204980fb9a16d`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL58조회·전체13테이블·DDL·snapshot·byte 백업 대조에서 승인 데이터·history2행 및 해당 sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0, 기존 applicator 테스트31건 통과. 실행 SQL·목적·결과·해석은 `05_independent_db_verification.json`에 있다.

공식 표준 semantic_progress JSON·CSV·Markdown을 함께 갱신했고 전체14,298행 중 H0093만 unapproved→explicit_approved다. 승인290→291·미승인14,002→14,001·hold6·anomaly113이며 snapshot identity는 `01c613fb93cc4617927e70d9bdb929e36a3b286b70f4e67997e77e39196b8890`다. 비대상 progress row·anomaly는 불변이다. 정상 CORE1 closure·frontier0, canonical1회 전량과 확보 reference 검토 및 직접 확인한 Isebaert 연구의 수종 식별을 사용했다. 초기 견과 추천은 최신 호두 결정으로 수정하되 원본 연구14파일과 machine state/Review는 보존한다. 실제 적용값은 외부 `00_applied_content.md/json`에 별도로 기록한다. DB는 Git 미추적 로컬 자산이며 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.

### 11.68 H94·H95·H103 이름·삯·거두기 어휘군 approved-content work DB slice

[h94_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h94_cluster_approved_content_slice.json)은 format v5 batch `RESHET-EC-H94-CLUSTER-APPROVED-CONTENT-SLICE`다. 사용자는 2026-10-16 H95의 성경 밖 비교 자료를 검토한 최신 `삯` 제안과 H94 `아굴·아구르 (인)`·H103 `거두어 모으다`, 비고2개 및 H103→H94 가설 파생 관계1개, DB·문서·필요한 파일 반영과 이상 없는 경우 Git·이번 작업 브랜치 정리까지 승인했다. Meaning replacement3·word note replacement2·relation create1의 총6 write이며 H103 비고는 NULL 유지다. 새 관계 ID7864는 canonical pair H0094_0000/H0103_0000, `morphological/derived/hypothesized/w2_to_w1`이다. H94–H95·H103–H95 및 아굴=솔로몬 관계 비생성·신규 hold0·기존 hold6 유지다. 최종값·핵심 이유·미채택 대안·재검토 조건은 [H94 클러스터 결정 기록](../semantic_decisions/h94_cluster_approved_content_slice.md)과 README active 색인에 있다.

승인 원문·byte 백업·독립 검증은 `data/backups/approved_content_batch/h94_approval_20261016/`, 공식 snapshot·result·manifest 사본은 `data/backups/approved_content_batch/20261016T071759240569Z/`에 보존한다. Approval SHA `2809ac36db8c3711443a0780cca3930c063941f4523d5b9830abbfc681edfdf3`, manifest SHA `b1150dbdc852d04a547e1a36a61dba2d9b822665005195662e4a415e1c0a5e24`이며 새 manifest의 `-text whitespace=cr-at-eol` 지정으로 실제 적용한 CRLF bytes와 Git blob을 동일하게 보존한다. 공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했고 history group `1792135080433223`의 ID6099–6104는 active word update5·relation create1, undone0이다. Work SHA는 `128f8ff9866e6637fde6d07b08c50a5f8e42a464c6e81fec0d8204980fb9a16d` → `f23a32b94b6e19c5248d071b6b3168f7ed802001ed439d08e3aada489990f83d`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. 독립 SQL53조회·전체13테이블·DDL·snapshot·byte 백업 대조에서 승인 데이터·history6행·해당 sequence 외 차이가 없다. Integrity ok·FK0·sidecar0, 보호 입력120개·원본 연구18파일 불변, 기존 applicator 테스트31건 통과. 실행 SQL·결과·판정은 `04_independent_db_verification.json`에 있다.

공식 표준 progress JSON·CSV·Markdown을 함께 갱신했고 전체14,298행 중 H0094·H0095·H0103만 unapproved→explicit_approved다. 승인291→294·미승인14,001→13,998·hold6·anomaly113이며 snapshot identity는 `42a0d6af704be0572e4879d75d871b75bb980bdb780b2a2999b471958f9e6053`다. 비대상 progress row·anomaly는 불변이다. 정상 CORE3 closure·frontier0, canonical5회 전량과 확보 reference를 검토했고 H95 후속 판단은 아람어·아카드어 비교 evidence와 직접 Hebrew 용례를 구별한다. 원어·음역·발음·언어·schema·seed·원천·local reference는 불변이며 새 외부 source를 canonical DB로 import하지 않았다. 실제 적용 결과는 외부 `00_applied_content.md/json`에 별도로 보존한다. DB는 Git 미추적 로컬 자산이고 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.
