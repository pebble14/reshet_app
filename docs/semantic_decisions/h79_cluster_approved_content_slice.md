# H79 어휘군 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-15
- 대상: H0079·H0080·H0081
- 승인 manifest: [h79_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h79_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지·신규 0건
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H79_cluster_20261015_995754cc`
- 승인 원문·dry-run·독립 검증: `data/backups/approved_content_batch/h79_approval_20261015/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261015T133207457012Z/`

## 최종 결정

사용자는 Codex의 추천안에 동의하고 문서·DB 및 필요한 파일 반영을 승인했다. 세 단어는 각각 seq1의 단일 meaning으로 승인했다.

| Strong | 최종 meaning | 조치 |
|---|---|---|
| H0079 | 씨름하다 | 현행 meaning 유지 승인, 비고 추가 |
| H0080 | 먼지 | 현행 meaning 유지 승인, 비고 추가 |
| H0081 | 가루 | 기존 `가루, 분말`을 정리, 비고 추가 |

승인 비고:

- **H0079**: 창세기 32:24–25(히브리어 본문 32:25–26)에서 니팔형으로만 쓰인다. Strong은 H80 ‘먼지’와 연결하여 설명하지만, 두 단어의 역사적 파생 방향은 현 용례만으로 확정하기 어렵다.
- **H0080**: 나훔 1:3은 구름을 ‘그 발의 먼지’에 빗댄 표현이다. ‘구름’은 별도 단어(H6051)로 쓰인다.
- **H0081**: 유일한 성경 용례인 아가 3:6에서는 가루 형태의 향료(香料)를 가리킨다.

H0080_0000 → H0081_0000을 `morphological / derived / asserted / w1_to_w2`로 생성했다(relation ID 7861). 저장 pair는 H0080_0000,H0081_0000이다. Strong의 여성형 설명을 별도 여성명사 형성 관계로 보존하며, 단순 굴절형으로 처리하지 않는다.

H79–H80 관계는 생성하지 않는다. 이는 단어 전체의 hold 설정과 다르다. 세 대상의 신규 word hold는 없고 기존 ledger 6건을 유지한다. 원문 expression·음역·발음·언어·schema·seed와 canonical source는 보존한다.

## 핵심 판단 근거

- H79의 canonical 두 용례는 모두 창세기에서 야곱과 상대가 몸을 맞대고 힘을 겨루는 같은 사건이다. `씨름하다` 하나로 두 용례를 설명한다. OSHB의 창32:25–26과 로컬 한국어 자료의 창32:24–25는 원문·내용·표면형을 직접 대조했으며 그 차이를 비고에 보존한다.
- H80의 여섯 용례는 물질로서의 먼지 3개, 비교 표현 2개, 은유 1개다. 나1:3의 구름은 별도 단어 H6051이며 먼지에 빗댄 대상이므로 `먼지`의 독립 sense를 늘리지 않는다.
- H81은 여성 단수 연계형으로 아3:6에 한 번 나오며 상인의 향료 가루를 가리킨다. Canonical Strong의 powder 범위를 `가루`로 두고 향료라는 용도는 비고에 남긴다. 기존 `가루, 분말`은 두 sense가 아니라 한 행의 동의 표현이므로 하나로 정리했다.
- Strong은 H81을 H80의 여성형으로 명시하며 이 파생 관계는 qualifier가 없다. 반면 H79의 명사 유래 동사 설명과 H80의 H79 원시 어근 참조는 서로 다른 어원 층위를 담으므로 방향 있는 관계 row로 단순화하지 않는다. 사용자는 이 근거에 따른 추천안을 채택했다.

## 채택하지 않은 주요 대안

- **H79 `먼지로 뒤덮다` 또는 `증기처럼 떠가다` 추가**: Strong의 어원 풀이 또는 probably가 붙은 원시 어근 가설이며, 두 실제 용례에서 별도 lexical sense로 확인되지 않았다. 원자료와 어원 불확실성은 연구 자료·비고에 보존한다.
- **H80 `티끌`**: 가능한 한국어 대안이지만 현재 `먼지`가 여섯 용례를 포괄하여 교체 이득이 작다. **`구름`을 추가하는 안**은 나훔의 비유 대상과 단어 자체의 의미를 혼동하므로 채택하지 않았다.
- **H81 `분말(粉末)` 또는 `가루, 분말(粉末)`**: 같은 sense의 가능한 대안이지만 간결한 `가루`를 선택했다. **`향료(香料)`·`향가루`**는 문맥을 잘 드러내지만 가루라는 형상보다 특정 용도를 고정할 수 있어 비고로 보존했다. 새번역의 **`향수(香水)`**만으로 액체의 별도 의미를 추가하지 않는다.
- **H79–H80 방향 관계 생성**: 원시 어근과 실제 명사 유래 동사 용법을 한 층위로 합치면 순환하는 설명이 될 수 있다. 두 항목의 관련성을 부정하거나 Strong 원자료를 교정하지 않고 이번에는 관계를 생성하지 않는다.

## 남은 불확실성 및 재검토 조건

H79와 H80의 역사적 파생 방향 및 원시 어근의 원래 뜻은 미확정이다. 이 두 층위를 구분할 수 있는 새 비교언어·어원 근거나 명시적인 사용자 관계 결정이 생기면 재검토한다. 동일한 사전 참조의 반복이나 번호 인접성만으로 재검토하지 않는다.

H81은 성경 용례가 한 번뿐이므로 다른 재료에 대한 실제 사용 범위까지 실증한 것으로 해석하지 않는다. 새 corpus evidence가 별도 lexical sense를 입증하면 재검토한다. H80의 신28:24에서는 원전분해와 다른 로컬 자료의 모래·티끌 대응 배치가 다르며, 이를 canonical token identity 변경이나 별도 sense의 근거로 삼지 않았다.

Canonical Strong·OSHB의 CORE3 전체 9용례를 검토했고 closure와 frontier0을 확인했다. 한국어 자료의 창세기 두 절은 개별 대조 결과이며 global reference profile은 unverified 상태를 유지한다. 로컬 번역본·LXX는 reference-only/human_reference이며 LXX upstream provenance·license의 미검증 경계를 보존한다. G2868의 NT5용례는 비교용으로만 검토했고 이번 semantic 승인에 포함하지 않았다. 원본 Packet·Review·machine state는 적용 전 연구 snapshot으로 남긴다.

공식 dry-run의 사본 적용·undo와 live apply가 성공했다. 독립 검증에서 13개 테이블·DDL·snapshot을 대조하여 승인된 meaning1·비고3·relation1, history5와 해당 sequence 외 변경이 없음을 확인했다. Work·seed·snapshot integrity ok, FK0·sidecar0, seed SHA 불변이다. 공식 progress에서 세 대상만 explicit_approved로 바뀌었고 기존 applicator Flutter 테스트31건이 통과했다. 앱/UI 코드 변경이 없어 사용자 UI 테스트와 전체 앱 빌드는 N/A다.
