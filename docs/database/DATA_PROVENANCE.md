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

Reshet 공개 데이터의 Strong 관련 공식 provenance는 다음 기준으로 재정립한다.

1. James Strong의 1890년 원판
2. CrossWire SWORD Project의 Public Domain Strong 모듈

CrossWire 공식 모듈 정보에서 다음 표시를 확인했다.

| 모듈 | 공식 모듈 제목 | 표시된 배포 라이선스 |
| --- | --- | --- |
| `StrongsGreek` | Strong's Greek Bible Dictionary | Public Domain |
| `StrongsHebrew` | Strong's Hebrew Bible Dictionary | Public Domain |

Phase 50-A에서는 CrossWire 바이너리 값을 직접 export하지 못했다. 따라서 위 확인은 공식 모듈 정보와 config의 Public Domain 표시를 근거로 하며, 개별 현행 DB 값의 대조 완료를 의미하지 않는다.

Open Scriptures 자료는 Strong 원전과 CrossWire 값을 비교하기 위한 보조 전자 자료다. 현재 공식 Reshet 재구축 원천으로 채택하지 않았다. `HebrewLexicon` 저장소의 파일은 CC BY 4.0 조건과 별도 attribution 판단이 필요하며, Greek XML의 교정 내용과 SBL식 음역은 Public Domain 원판과 구분한다.

Strong 원판·모듈과 이를 이용한 문자열 대조는 Strong 데이터의 비교 근거일 뿐, 언어별 IPA profile이나 expression별 IPA provenance를 입증하지 않는다.

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

## 11. Strong 원천 dry-run diff 도구

`tool/data_provenance/strong_source_diff.py`는 현행 `word_expression_set`의 원어 철자와 pronunciation을 사용자가 전달한 Open Scriptures Strong XML과 비교하는 재사용 가능한 검증 도구다. 이 도구는 Open Scriptures 자료를 Reshet의 최종 공식 재구축 원천으로 채택하지 않으며, 현재 정책상 비교용 보조 자료로만 사용한다. 비교 일치만으로 현행 값의 최초 출처, 승인된 pronunciation profile과의 일치 또는 최종 IPA 원천 적합성이 입증되지는 않는다.

도구는 SQLite DB를 URI `mode=ro`와 `PRAGMA query_only = ON`으로 열고 `integrity_check`를 확인한다. DB 값을 수정하거나 schema·legacy projection을 변경하지 않는다. 입력 XML을 다운로드하지 않으며 외부 XML과 생성되는 CSV·JSON 결과는 저장소에 포함하지 않고 저장소 밖 임시 디렉터리에서 관리한다.

실행 예시는 다음과 같다.

```powershell
python tool/data_provenance/strong_source_diff.py `
  --db data/reshet_work.db `
  --greek-xml "<TEMP_PATH>\strongsgreek.xml" `
  --hebrew-xml "<TEMP_PATH>\HebrewStrong.xml" `
  --output-dir "<TEMP_PATH>\reshet-strong-diff" `
  --pretty
```

출력 디렉터리에는 입력 파일·실행 조건·무결성 정보를 기록한 `manifest.json`, 집계 결과인 `summary.json`, expression 단위 `expression_diff.csv`, 대표 expression 기준 `word_summary.csv`가 생성된다. 실제 집계는 입력 XML commit과 DB 버전에 따라 달라질 수 있으므로 이 문서에 고정하지 않는다.

## 12. pronunciation profile·migration 현행 경계

### 12.1 active pronunciation 계약

Reshet의 active pronunciation은 언어별로 승인된 profile에 맞는 IPA만 사용한다. 기본 정밀도는 broad phonemic transcription이며, 다음 공통 원칙을 적용한다.

- 하나의 active pronunciation에는 승인된 profile의 대표 IPA 하나만 저장한다. 대체 발음은 active 값에 함께 넣지 않는다.
- 승인된 profile과 다른 시대·지역 체계를 fallback으로 사용하지 않는다.
- 검증 가능한 profile 일치 자료가 없으면 추측하거나 음역을 IPA처럼 취급하지 않고 `NULL`을 유지한다.
- DB에는 slash, 설명 또는 괄호를 붙이지 않은 순수 IPA만 저장한다.
- UI는 값이 있을 때 `/IPA/` 형식으로 표시하고 시대·지역·체계 설명을 행마다 반복하지 않는다. 이 표시 정책은 승인됐지만 production UI에는 아직 구현되지 않았다.

승인된 언어별 profile은 다음과 같다.

| DB 언어 값 | 승인된 pronunciation profile |
| --- | --- |
| `히브리어` | 재구성 티베리아 성서 히브리어(Reconstructed Tiberian Biblical Hebrew) |
| `헬라어` | 서기 1세기 코이네 그리스어 재구성(Reconstructed 1st-century CE Koine Greek) |
| `라틴어` | 재구성 고전 라틴어(Reconstructed Classical Latin) |
| `영어` | 일반 미국 영어(General American English) |

DB의 `헬라어` label은 정책상 Greek에 해당한다. 위 네 profile은 pronunciation 목표를 승인한 것이며, 실제 원천·판본·라이선스·stable key를 승인한 것은 아니다.

### 12.2 현행 구현과 데이터 신뢰 경계

확인된 현행 구현에서 `pronunciation`은 schema·model·repository 전 구간에서 nullable이고, 빈 문자열 write는 `NULL`로 정규화된다. 상세 화면은 값이 없으면 pronunciation 영역을 숨긴다. pronunciation은 검색 대상, 정렬·filter 기준 또는 identity로 사용되지 않으며 graph에도 표시되지 않는다. 따라서 현재 누락값은 UI 흐름에서 안전하고, `NULL` 처리를 위한 schema나 production 변경은 필요하지 않다. 후속 production 변경 후보는 값이 있을 때의 `/IPA/` 표시 형식이다.

현행 데이터의 확인된 규모와 신뢰 상태는 다음과 같다.

| 항목 | 확인된 수 |
| --- | ---: |
| 전체 expression | 15,237 |
| `pronunciation IS NULL` | 201 |
| 형식상 IPA 후보 | 576 |
| 승인 profile과 항목별 provenance가 함께 검증된 IPA | 0 |

형식상 IPA 후보 576건을 모두 잘못된 값으로 단정하지 않는다. 다만 IPA처럼 보인다는 사실만으로는 승인 profile과 provenance가 확인되지 않으므로 cohort D로 분류한다. IPA가 아닌 현행 표기는 최종 active pronunciation이 아니다.

### 12.3 언어 경계

- `히브리어`, `헬라어`, `라틴어`, `영어`는 승인 profile이 있으므로 언어별 read-only 원천 조사 후보가 된다. 원천명, 판본, 라이선스와 stable key는 아직 승인되지 않았다.
- `아람어`는 실제 데이터가 존재하지만 별도의 profile·원천 조사가 필요하다. 히브리어 profile을 자동 적용하지 않으며, profile 결정 뒤 별도 migration 대상으로 다룬다.
- `히브리어/아람어`는 독립된 pronunciation 언어가 아니라 expression 언어가 아직 확정되지 않은 임시 label이다. 해당 21단어·22 expression은 전체 migration에서 제외하지 않고 `F-language`로 포함한다. 각 expression의 언어를 먼저 판정한 뒤 히브리어이면 승인된 히브리어 profile, 아람어이면 향후 승인될 아람어 profile을 적용한다. 판정 근거나 검증 가능한 원천이 부족하면 `NULL`로 둔다.
- 고대 페르시아어, 독일어, 러시아어, 아카드어, 우가릿어, 이탈리아어에는 승인된 profile이 없다. profile을 임의로 만들거나 자동 IPA migration을 적용하지 않으며, 검증 가능한 자료가 없으면 `NULL`로 둔다. DB 집계·migration selector에서는 활성 DB의 canonical 언어 값 `아카드어`, `우가릿어`를 사용한다.

### 12.4 migration DB와 backup 경계

pronunciation migration의 active 대상은 `data/reshet_work.db`, `data/reshet_seed.db`와 legacy projection인 `WORD_TABLE.발음1`~`발음6`이다. 실제 migration에서는 work·seed·legacy projection parity를 함께 유지한다.

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

cohort F에는 `히브리어/아람어` 22 expression의 `F-language`와 tab 문자가 포함된 word ID `L0000_0003\t`의 `F-identity`가 포함된다. 재사용 가능한 다른 선행 예외는 pronunciation 첫 문자에 carriage return이 있는 `G2943_0000`, 철자 없이 legacy slot 2에 pronunciation `G2767`만 있는 `G0185_0000`이다. slash 포함 59건과 괄호 포함 26건은 순수 IPA 저장 규칙 대조를 위한 형식 신호이며, 그 자체만으로 잘못된 값이라고 확정하지 않는다.

현재 확정할 수 있는 것은 위 분류 기준과 확인된 예외뿐이다. cohort A~F의 실제 배정은 원천 검증 결과에 따라 달라지며, 원천 채택 전에 B·C·E의 최종 건수를 선언하거나 모든 행을 강제로 변환하지 않는다. 결과는 확인 완료, 잠정 분류와 미해결 항목을 구분해 기록한다.

### 12.7 후속 순서

1. 이 문서에서 profile·출처·migration 경계를 유지한다.
2. 우선 네 승인 profile 언어를 대상으로 언어별 read-only 원천 조사를 수행하고, 아람어는 별도로 조사한다.
3. `히브리어/아람어` expression의 실제 언어를 판정한다.
4. identity 예외와 stable key 대응 규칙을 확정한다.
5. dry-run manifest, migration 전후 전체 SQLite backup과 diff를 준비하고 work·seed·legacy projection parity를 검증한다.
6. 승인된 원천과 규칙에 한해 실제 DB migration을 수행한다.
7. 별도 production slice에서 `/IPA/` UI 표시를 구현한다.

`data/bbwdb_20260106.db`는 위 migration 순서에 포함하지 않는다.

## 13. 관련 문서와 외부 기준

내부 문서:

- [SCHEMA](SCHEMA.md) — 현재 DB schema authority
- [Data Structure Policy](DATA_STRUCTURE_POLICY.md) — canonical storage와 runtime authority 정책

외부 기준(2026-07-15 확인):

- [CrossWire StrongsGreek module information](https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=StrongsGreek) — `Strong's Greek Bible Dictionary`, `Distribution License: Public Domain`
- [CrossWire StrongsHebrew module information](https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=StrongsHebrew) — `Strong's Hebrew Bible Dictionary`, `Distribution License: Public Domain`
- [James Strong, *The exhaustive concordance of the Bible* (1890) 서지](https://openlibrary.org/books/OL31772852M/The_exhaustive_concordance_of_the_Bible) 및 [Internet Archive 스캔](https://archive.org/details/bwb_T2-DOA-183)
- [Open Scriptures HebrewLexicon](https://github.com/openscriptures/HebrewLexicon) — 저장소의 CC BY 4.0 및 attribution 안내
- [Open Scriptures Strong's Greek XML](https://github.com/openscriptures/strongs/blob/master/greek/StrongsGreekDictionaryXML_1.4/strongsgreek.xml) — 비교용 보조 전자 자료 후보
- [Wiktionary: Copyrights](https://en.wiktionary.org/wiki/Wiktionary:Copyrights) 및 [Wikimedia Foundation Terms of Use](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use/en#7._Licensing_of_Content) — 전자는 오래된 비공식 안내라는 자체 경고가 있으므로 향후 재사용 판단 시 현행 이용 약관과 함께 확인
- [Wikidata: Licensing](https://www.wikidata.org/wiki/Wikidata:Licensing) — Wikidata 라이선스 안내

외부 링크의 표시는 해당 페이지에서 확인한 사실을 기록한 것이며, Reshet가 해당 데이터를 이미 채택·사용했다는 의미가 아니다.
