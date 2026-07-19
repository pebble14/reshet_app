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

pronunciation migration의 active 대상은 `data/reshet_work.db`, `data/reshet_seed.db`와 legacy projection인 `WORD_TABLE.발음1`~`발음6`이다. 실제 pronunciation 본문 migration에서는 work·seed·legacy projection parity를 함께 유지한다.

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

`data/bbwdb_20260106.db`는 향후 사용하지 않기로 결정된 보존 원본이므로 pronunciation migration과 schema 변경 대상에서 제외한다. 이 파일을 수정·재생성·삭제하지 않는다. 현재 코드의 fallback 참조가 남아 있을 수 있다는 사실과 runtime 경로 제거는 별개다. 이 문서는 코드가 이미 해당 DB를 사용하지 않는다고 선언하지 않으며, 필요하면 후속 cleanup 또는 production 작업에서 다룬다.

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

cohort F에는 `히브리어/아람어` 19 expression의 `F-language`와 tab 문자가 포함된 word ID `L0000_0003\t`의 `F-identity`가 포함된다. 재사용 가능한 다른 선행 예외는 pronunciation 첫 문자에 carriage return이 있는 `G2943_0000`, 철자 없이 legacy slot 2에 pronunciation `G2767`만 있는 `G0185_0000`이다. slash 포함 59건과 괄호 포함 26건은 순수 IPA 저장 규칙 대조를 위한 형식 신호이며, 그 자체만으로 잘못된 값이라고 확정하지 않는다.

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
