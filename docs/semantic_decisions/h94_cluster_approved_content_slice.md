# H94·H95·H103 이름·삯·거두기 어휘군 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0094, H0095, H0103
- 승인 manifest: [h94_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h94_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 신규 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0094_cluster_20261016_128f8ff9/`, 최신 H95 판단은 `01_h95_external_evidence_followup.md`
- 승인 원문·byte 백업·독립 검증: `data/backups/approved_content_batch/h94_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261016T071759240569Z/`

## 최종 결정

사용자는 H94·H103 제안을 긍정적으로 평가한 뒤 H95의 성경 밖 자료와 한국어 대표 뜻을 추가 검토했다. 최신 H95 `삯` 추천을 포함한 전체 제안의 DB·문서·필요한 파일 반영과, 이상 없는 경우 Git 완료·이번 작업 브랜치 정리까지 승인했다. 최초 `푼돈` 추천은 최종 승인값이 아니다. H95 비고는 후속 artifact의 긴 초안보다 마지막 채팅에 제시한 아래 문안을 우선했다.

| Strong / word_id | seq | 최종 meaning | 최종 비고 |
|---|---:|---|---|
| H94 / H0094_0000 | 1 | 아굴·아구르 (인) | 아래 전문 |
| H95 / H0095_0000 | 1 | 삯 | 아래 전문 |
| H103 / H0103_0000 | 1 | 거두어 모으다 | NULL 유지 |

기존 `아굴 (인)`, `지불, 조각`, `모으다, 추수하다`의 각 한 행을 위 한 행으로 교체했다. 쉼표가 들어 있던 기존 행들을 독립적인 승인 sense 여러 개로 해석하지 않는다.

H94 비고:

> 잠 30:1에서 야게의 아들로 소개되는 인물. ‘아굴’은 한국어 성경 관용 표기이고, ‘아구르’는 히브리어 형태를 드러내는 근사 표기다. Strong은 H103 ‘거두어 모으다’의 수동분사로 설명하며 솔로몬의 별명으로 해석하지만, 본문은 솔로몬과의 동일성을 확정하지 않는다. 비교 사전에는 ‘고용된 이’ 계열의 어원 설명도 있어 이름의 뜻은 확정하지 않는다.

H95 비고:

> 삼상 2:36에서 제사장 직분을 맡아 생계를 잇고자 하며 구하는 적은 돈을 가리킨다. 뒤의 כֶּסֶף(H3701)가 은으로 지급되는 것임을 명시한다. 지급금·보수로 보는 분석과 작은 은전으로 보는 사전 해석이 있으며, 정확한 금액·무게나 주조된 동전인지는 확정하지 않는다.

신규 관계는 1건이다.

| 항목 | 최종값 |
|---|---|
| semantic direction | H0103 → H0094 |
| 저장 pair | H0094_0000 / H0103_0000 |
| category_code | morphological |
| relation_type | derived |
| status_code | hypothesized |
| direction_code | w2_to_w1 |
| relation ID | 7864 |
| 관계 비고 | Strong의 수동분사 분석에 따른 이름 파생 가설. BDB는 고용된 이 계열의 경쟁 어원도 제시한다. |
| source | RESHET-EC-H94-CLUSTER-H0103-H0094 |
| description / relation_group_id | NULL / NULL |

H94–H95와 H103–H95의 어원 관계는 생성하지 않는다. H94와 솔로몬의 동일 인물 관계도 생성하지 않는다. 관계 생성 보류를 word hold로 바꾸지 않으며 신규 word hold는 없다. 기존 hold 6건, 원문 expression·음역·발음·DB 언어·Strong 번호·schema·seed·canonical source·local reference는 보존했다. 대상의 기존 active semantic 승인과 충돌하지 않아 supersession은 없다.

## 핵심 판단 근거

- 정상 lexical closure는 CORE H94·H95·H103 전체 3개, source relation evidence2개, frontier0이다. OSHB canonical 출현은 H94 1회·H95 1회·H103 3회이며 총5/5를 검토했다. 각 단어를 단일 sense로 설명할 수 있으며 새 sense를 만들 반례는 확인되지 않았다.
- H94는 잠30:1에서 야게의 아들인 인명으로 식별된다. `아굴`은 한국어 성경 관용명을 보존하고 `아구르`는 현행 expression 음역과 일치하는 히브리어 형태 근사 표기다. 같은 이름이므로 가운데점으로 한 meaning에 병기하며 합성 경계를 추정하는 붙임표는 넣지 않는다. 특정 시대의 정확한 발음을 확정한 값으로 취급하지 않는다.
- Strong은 H94를 H103의 수동분사에서 나온 이름으로 설명하지만 BDB에는 고용 계열의 경쟁 어원도 있다. 따라서 동사에서 인명으로 향하는 lexicalized 파생 관계를 `derived`로 두고 상태는 `hypothesized`로 승인했다. source-reference H94→H103과 semantic H103→H94는 반대이므로 canonical 저장 pair에 `w2_to_w1`을 사용한다. Strong의 솔로몬 별명 해석은 본문의 인물 동일성 확정과 구별해 비고에 남겼다.
- H95의 유일한 용례 삼상2:36은 אֲגוֹרַת כֶּסֶף라는 연계 구문이다. BDB는 지급금으로 설명하고, CAL의 아람어 비교 어휘와 CAD의 아카드어 igru 문서 용례는 고용·보수 분석을 뒷받침한다. CAD 인쇄44–45쪽의 KT Hahn 22:13, ARM 1 17:11, VAS 1 103:12 인용을 확인했다. 비교 언어의 원 점토판을 직접 판독했거나 이 용례를 Hebrew H95 자체의 추가 출현으로 확인한 것은 아니다.
- H95의 대표 뜻은 대가로 지급되는 기능을 드러내는 고유어 `삯`으로 선택했다. 작은 금액은 생계 요청 문맥에서 설명하고 별도 sense로 늘리지 않는다. H3701이 뒤에 있다는 사실만으로 H95 자체의 은전 해석이 반증되는 것은 아니므로, 지급금·작은 은전이라는 사전 차이와 정확한 화폐 형태의 한계를 비고에 보존한다.
- H103은 신28:39의 포도, 잠6:8의 개미 양식, 잠10:5의 거두는 사람을 `거두어 모으다`로 포괄한다. 형태·주어·목적어 차이를 독립 meaning으로 늘리지 않고, 별도의 고용·지급 비교 어근을 이 Strong의 성경 의미에 넣지 않는다. 뜻과 세 용례를 반복하는 비고는 추가하지 않았다.

Canonical authority는 현행 manifest에 고정된 HebrewStrong XML과 OSHB다. [BDB H94](https://biblehub.com/bdb/94.htm), [BDB H95](https://biblehub.com/bdb/95.htm), [BDB H103](https://biblehub.com/bdb/103.htm), [CAL 명사 자료1쪽](https://cal.huc.edu/pdfs/Nouns.pdf), [CAD I–J 공식 출판·다운로드](https://isac.uchicago.edu/publications/chicago-assyrian-dictionary-volume-7-i-j), [Gesenius H95 항목 전사](https://www.studylight.org/lexicons/eng/hebrew/95.html)는 비교 reference다. 외부 사전·PDF·LXX를 canonical occurrence나 재배포 DB로 import하지 않았다.

## 채택하지 않은 주요 대안

- **H94 `아굴 (인)`만 유지**: 기존값도 정확한 식별이다. 최신 승인은 관용명을 보존하면서 현행 원문 근사 표기를 함께 보여 주는 병기안이다. ‘모아진 이’·‘고용된 이’는 경쟁 어원 풀이로 남기고 이름의 독립 meaning으로 저장하지 않는다. 솔로몬의 별명이라는 설명 역시 확정 meaning·동일 인물 관계로 채택하지 않았다.
- **H95 `푼돈`**: 최초 추천으로 작은 금액 문맥에는 적합하나 지급·보수라는 기능이 약하다. 비교 자료를 추가 검토한 최신 `삯` 추천을 사용자가 채택했다. 구어적 소액 번역 후보로 연구 자료와 이 기록에 보존한다.
- **H95 `보수(報酬)`·`지급금(支給金)`·`지불(支拂)`**: 지급·보수 범주를 설명하는 대안이다. 대표 meaning에는 간결한 고유어 `삯`을 선택했다. 한국어 `지불`은 행위로 읽히기 쉬워 지급되는 대상을 드러내기에 덜 적절하다.
- **H95 `은(銀) 조각`·`은화(銀貨)`**: 은 조각은 전체 구의 번역 후보다. 작은 은전이라는 사전 전통도 유효한 경쟁 분석이지만, 재질·주조 형태·확정 액면을 단어의 의미에 과도하게 고정할 수 있어 대표 meaning으로는 채택하지 않았다. 이 분석은 최종 비고에 보존했다.
- **H95 곡립·열매 및 후기 동일 철자의 견과 껍질 속 칸**: 전자는 Strong의 추정 어원 설명이고 후자는 Jastrow의 별도 시기·용법이다. 삼상2:36 금전 어휘의 독립 sense를 입증하지 않으므로 새 meaning으로 추가하지 않는다.
- **H103 `모으다`·`추수하다(秋收하다)`의 별도 의미 및 `거두는 자` 추가**: 실제 세 용례는 하나의 거두어 모으는 동작으로 설명된다. 분사의 문장 기능을 독립 명사 sense로 만들지 않는다. `모으다` 자체는 여전히 유효한 간결한 대안이다.
- **H95 어원 관계 생성·확정 파생으로 승격·word hold**: Strong의 `from the same as H94`는 인명에서 돈이 파생됐다는 뜻이 아니다. 모으기와 고용·보수 어원 사이의 구별이 남아 있어 H94–H95·H103–H95 관계를 만들지 않는다. 의미 범주는 승인할 수 있어 어휘 전체 hold도 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

H94의 역사적 정체·솔로몬 동일성·어원과 H95의 정확한 금액·무게·주조 여부는 미확정이다. H94 source의 `x-pn unresolved`를 임의로 `heb`로 바꾸지 않았다. H95의 독립적인 비성경 고대 Hebrew 금전 용례를 직접 확보하지 못했으며, 이를 전수 부재로 단정하지 않는다. 아람어·아카드어 비교 어휘의 기능을 H95의 직접 용례나 확정 차용 관계로 승격하지 않는다.

Strong·Gesenius의 은전 해석과 BDB의 지급금 해석 차이를 유지한다. HALOT는 공개 검색 결과만 확인하고 해당 판본 본문을 안정적으로 열람하지 못했으므로 직접 검증 완료 source로 집계하지 않았다. LXX의 잠30:1·신28:39·잠10:5 차이를 직접 alignment로 덮지 않으며, local LXX upstream provenance·license 미검증 경계를 유지한다. HebGrkKo의 H103 설명에 있는 잠10:15는 실제 OSHB 잠10:5와 달라 canonical source를 우선했다.

검증된 전문 사전·역사언어학 자료, H95 자체의 독립적인 고대 금전 용례, H94 정체의 직접 근거가 기존 판단을 실질적으로 바꿀 때 사용자 판단으로 재검토한다. 같은 번역 표현·번호 인접성·현대 통화명·비교 언어 어형만으로 의미·relation·hold를 자동 변경하지 않는다.

공식 dry-run의 사본 적용·실제 undo·원본 불변과 live apply가 성공했다. 독립 SQL 53조회로 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했고 승인 delta와 history6099–6104(group `1792135080433223`), 해당 history·relation sequence 외 차이가 없다. Relation ID7864이며 work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0, 보호 입력120개·원본 연구18파일은 불변이다. 기존 applicator 테스트31건이 통과했다. 표준 progress는 H94·H95·H103만 승인 전환해 승인291→294·미승인14,001→13,998·hold6·anomaly113이며 snapshot identity는 `42a0d6af704be0572e4879d75d871b75bb980bdb780b2a2999b471958f9e6053`다. DB는 Git 미추적 로컬 자산이며 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.
