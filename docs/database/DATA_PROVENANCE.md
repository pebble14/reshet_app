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

completion gate는 새 저장소를 만들지 않고 Git tracked `*_approved_content_slice.json` manifest를 approved-content format·batch ID 계약으로 검증한 뒤 결정적 파일명 순서로 집계하되, 그 순서를 승인 우선순위로 사용하지 않는다. 기존 format v1 exact 계약을 유지하고 format v2에서는 필수 `word_note_replacements` 계약을 검증하며, format v3는 v2 필드에 필수 `supersedes` 배열을 추가한다. format v4는 v3 필드에 필수 `relation_replacements` 배열을 추가하며 `supersedes` 의미는 v3와 같다. format v5는 v4 필드에 필수 `meaning_approvals` 배열을 추가해 DB 쓰기 없이 승인된 현행 meaning 전체 projection을 기록한다. 각 supersession은 canonical `strong_number`와 이전 승인 manifest의 고유 `batch_id`를 exact 필드로 기록한다. tracked manifest set의 `batch_id`는 고유해야 하고, supersession source와 target batch 모두 해당 Strong의 meaning replacement after 또는 current meaning approval을 포함해야 한다. 존재하지 않는 target, self-supersession, cycle은 fail-closed다.

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
