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
| Strong식 발음 | 외부 참고 후 입력 | 공개 원천과 대조된 값만 공식 인정 | dry-run diff |
| 한글 음역 | 항목별 출처 미기록 | 현행 유지, 독점 권리 단정 금지 | 별도 정책 |
| 한국어 의미·설명 | 사용자 직접 작성 | Reshet 작성 데이터 | 라이선스 추후 확정 |
| 단어 관계·메모 | 사용자 작성·편집 | Reshet 작성 데이터 | 현행 유지 |
| e-Sword 모듈 | 제3자 전자 파생물 | 포함·재배포하지 않음 | 과거 참고로만 기록 |
| Wiktionary 자료 | 과거 참고 가능성 | 항목별 직접 provenance 없음 | 향후 사용 시 별도 기록 |

현재 유지 가능한 범위에는 단어 ID, 사용자가 직접 작성한 한국어 의미·설명, 사용자가 구성한 단어 관계·메모, Strong 번호, 공개 Strong 원천으로 재검증 가능한 대표 철자와 원판 또는 공개 원천에 일치하는 Strong식 발음이 포함된다.

다음 항목은 선택적 재검증 대상이다.

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

`tool/data_provenance/strong_source_diff.py`는 현행 `word_expression_set`의 원어 철자와 pronunciation을 사용자가 전달한 Open Scriptures Strong XML과 비교하는 재사용 가능한 검증 도구다. 이 도구는 Open Scriptures 자료를 Reshet의 최종 공식 재구축 원천으로 채택하지 않으며, 현재 정책상 비교용 보조 자료로만 사용한다.

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

## 12. 관련 문서와 외부 기준

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
