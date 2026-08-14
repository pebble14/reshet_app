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

`tool/data_provenance/biblical_research_evidence_packet.py`는 Strong 번호 하나를 입력받아 기본 어휘 정보, ±10 번호창, Strong XML의 직접 참조, canonical 성경 occurrence와 로컬 번역·원전분해 참고자료를 결정적인 UTF-8 JSON으로 stdout에 출력하는 개발·연구 CLI다. 기존 Strong parser와 mapping 계약을 재사용하며 work DB와 모든 로컬 SQLite 자료는 read-only·query-only로 열고 실행 전후 SHA-256 불변을 확인한다.

canonical Hebrew·Aramaic occurrence는 `openscriptures/morphhb` commit `3d15126fb1ef74867fc1434be1942e837932691f`의 `wlc/` OSHB corpus를 사용한다. WLC 본문은 Public Domain, lemma·morphology는 CC BY 4.0이며 `Open Scriptures Hebrew Bible Project` attribution을 유지한다. augmented lemma 원문은 보존하고 숫자 slash component처럼 문법적으로 결정적인 경우에만 standard Strong으로 연결하며, 모호한 확장은 warning으로 남긴다. occurrence identity는 source-native OSIS verse로 유지하고 verse direct child의 `KJV:` note는 typed alternate 목록으로 별도 보존한다. 같은 kind의 서로 다른 복수 alternate와 `!b`처럼 현재 계약으로 확정할 수 없는 suffix는 임의 해석하지 않는다.

canonical Greek NT occurrence는 `STEPBible/STEPBible-Data` commit `b86d26cdb1f51729e73b5b4eb7f7ccadc5dfba39`의 TAGNT Mat–Jhn·Act–Rev 파일을 사용한다. `editions` 필드에 NA27 또는 NA28 membership이 명시된 token만 기본 canonical profile에 포함하고 다른 판본에만 존재하는 variant token은 occurrence count에서 제외한다. TAGNT base reference를 occurrence identity로 유지하며 `[KJV]`, `(NA)`, `{other}` alternate는 kind와 원문 표기를 보존한 별도 후보로 전달한다. `(NA)`가 있다는 이유로 occurrence identity나 모든 local target의 lookup key를 NA reference로 교체하지 않는다. 자료는 CC BY 4.0이며 `STEP Bible` attribution을 유지한다. 개별 corpus 파일의 실제 SHA-256, repository·commit·path, parser 계약과 canonical profile은 `tool/data_provenance/manifests/biblical_occurrence_sources.json`에 고정한다. raw corpus cache는 ignored `tool/data_provenance/.source_cache/biblical_occurrences/`에 두고 추적하지 않는다.

`HebGrkKo.dct`, `KJV_S.sdb`, `개역개정S.sdb`, `개역한글S.sdb`, `새번역.bdb`, `원전분해.sdb`는 reference-only 자료다. 파일명·승인된 SHA-256·역할·reference profile·경계는 `tool/data_provenance/manifests/local_research_reference_sources.json`에 기록하며 절대경로와 원본 파일은 기록하지 않는다. 현재 verse target 중 `kjv`만 KJV profile로 검증됐고 개역개정·개역한글·새번역·원전분해는 `unverified`다. source에 reference conflict가 없으면 기존 source-native same-key 조회를 `same_key_no_source_conflict` 근거로 유지한다. 명시적 alternate가 검증된 target profile과 하나로 대응할 때만 해당 alternate를 사용하고, explicit conflict와 `unverified` target의 조합이나 복수·특수 형식 ambiguity는 SQLite 조회 없이 `manual_review_required`로 닫는다. 선택한 alternate 조회가 실패해도 source-native나 다른 후보로 fallback하지 않는다. CLI는 fingerprint와 schema 불일치를 fail-closed한다. 로컬 row ID와 marker count는 cross-source key나 canonical occurrence count로 사용하지 않으며, 비표준 marker를 standard Strong으로 병합하지 않는다.

실행 예시는 다음과 같다.

```powershell
python tool/data_provenance/biblical_research_evidence_packet.py G32 `
  --local-sources ..\reshet_research_sources
```

Evidence Packet JSON은 전체 machine-readable evidence의 source of truth다. occurrence에는 source-native/base reference와 source-provided typed alternate를 보존하고, 각 local target 결과에는 target profile, 실제 lookup reference, reference 선택 근거, join 상태, lookup 수행 여부와 manual review 여부를 기록한다. `tool/data_provenance/biblical_research_evidence_review.py`는 이 JSON만 읽어 target 요약, Strong ±10, raw 번역 표현 빈도, occurrence 비교표와 접힌 상세를 UTF-8 Markdown으로 재배열하는 local human-readable derivative이며 성경 source나 DB를 직접 읽거나 의미·relation을 판단하지 않는다. Review는 정상 자동 join의 lookup reference와 선택 근거, 일반 `unmatched`, 의도적으로 lookup을 생략한 `manual_review_required`를 서로 구분하고 manual 사례에는 source-native reference와 alternate 후보를 함께 표시한다.

```powershell
python tool/data_provenance/biblical_research_evidence_review.py `
  ..\reshet_research_output\G32_evidence_packet.json `
  --output ..\reshet_research_output\G32_review.md
```

`--output`은 PowerShell의 native stdout 재인코딩을 거치지 않고 renderer의 결정적 UTF-8 바이트를 직접 기록한다. 생략하면 기존 stdout 출력을 유지한다. 생성된 Review Markdown은 저장소 밖 연구 output에만 두고 Git tracked artifact로 관리하지 않는다. 전체 source hash와 상세 provenance는 Review에 복제하지 않고 원 Evidence Packet JSON을 참조한다.

completion gate는 새 저장소를 만들지 않고 Git tracked `*_approved_content_slice.json` manifest를 approved-content format·batch ID 계약으로 검증한 뒤 파일명 순으로 집계한다. 기존 format v1 exact 계약을 유지하며, format v2에서는 필수 `word_note_replacements`의 null/non-empty string·필드·중복 계약까지 fail-closed로 검증한다. `explicit_approved`는 version과 무관하게 `meaning_replacements[].word_id`에 명시된 Strong의 현재 work DB meaning projection이 해당 manifest의 승인 `after`와 exact 일치할 때만 부여하며, `word_note_replacements`와 `relation_creates` endpoint는 승인 Strong 집계에 사용하지 않는다. 따라서 note-only v2 manifest는 `explicit_approved` 근거가 아니고, meaning+note v2 manifest의 현재 note 불일치도 semantic completion state를 낮추지 않는다. note 적용 무결성은 approved-content applicator의 before/after·history·undo 계약에서 별도로 검증한다. 해당 Strong의 동일 승인 meaning projection이 여러 manifest에 있으면 근거 파일을 모두 기록하고, 서로 상충하면 임의의 최신 순서를 추론하지 않고 오류로 닫는다. Packet provenance에는 실제 참조한 approved-content manifest 전체를 같은 결정적 순서로 기록한다.

기존 괄호 한자 marker와 source-only import projection을 함께 사용해 `legacy_hanja_candidate`, `source_only`, `unclassified`를 실행 시 계산한다. `legacy_hanja_candidate`는 최종 승인 상태가 아니며 한자가 없다는 이유만으로 미완료로 분류하지 않는다. `tool/data_provenance/manifests/p1_historical_approval_approved_content_slice.json`은 tracked P1 rehearsal fixture와 그 fixture를 추가한 commit `985830cd6f1dd6d759ae2f8fefc68a035ddb19b8`, SHA-256 `cbc4d60b13b4489f3677122bda486aecafaecc47166a71d1a2cb4c901392599d`의 pre-write snapshot, active history group `1786202221443735`, 현재 work DB projection의 exact 일치를 근거로 H1653·H1655·H1656의 기존 human-approved meaning을 현행 completion 계약에 연결한다. 이 manifest는 historical tracking backfill이며 live apply나 DB write를 수행하지 않는다. completion gate는 세 `meaning_replacements`만 `explicit_approved` 근거로 사용하고 같은 historical batch의 `relation_creates` endpoint는 의미 승인으로 간주하지 않는다. MVP 1에서 LXX alignment, Hebrew↔Greek 분석, 의미 후보·semantic relation 자동 판정, Approval Ledger, Dashboard/UI, DB write와 runtime schema 변경은 N/A다. LXX Human Reference의 explicit lookup·manual review 경계는 아래 11.7의 별도 계약을 유지하며 자동 Evidence Packet join에 참여하지 않는다.

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

현재 첫 entry는 H1833이다. lexical source의 damask 직물 의미와 Damascus 지명 의미 및 Amos 3:12 관련 현재 evidence만으로 일반 semantic meaning 하나를 확정하기 어려워 hold하며, completion state는 `source_only` 그대로다. hold 집합을 production batch 자동 제외 selector에는 아직 연결하지 않으며, H2646 conflict/manual-review pilot 후 연결 여부를 판단한다.

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
