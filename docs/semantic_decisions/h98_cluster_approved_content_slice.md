# H98·H99·H100 못·슬픔·갈대·밧줄 클러스터 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16
- 대상: H0098, H0099, H0100
- 승인 manifest: [h98_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h98_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: `H0098_cluster_20261016_ce2b0b9e/batch`, 외부 `reshet_research_output/`
- 적용·검증 자료: 로컬 `data/backups/approved_content_batch/h98_approval_20261016/`, 공식 snapshot·result는 `data/backups/approved_content_batch/20261016T093403326205Z/`

## 최종 결정

사용자는 Codex 추천안을 채택하고 H98—H99 가설 관계 생성도 명시적으로 승인했다. DB·문서·필요한 파일·Git 및 이상 없는 경우 이번 작업 브랜치 정리까지 승인한 결정이다.

|Strong|최종 ordered meaning|sense 수|적용|
|---|---|---:|---|
|H0098|못·늪|1|기존 ‘습지, 웅덩이, 늪’ 1행 교체|
|H0099|슬픈|1|기존 meaning row 유지, meaning_approvals로 승인|
|H0100|① 갈대·골풀 ② 밧줄|2|기존 ‘갈대, 골풀’ 1행을 ordered 2행으로 교체|

H98 비고:

> 렘 51:32에서는 불태운 대상으로 나와, 늪 자체보다 그곳에 자란 갈대밭을 가리키는 환유로 이해할 수 있다. Strong은 갈대와 갈대 울타리 풀이도 전하지만, 이 용례를 별도의 요새 의미로 확정하지 않는다.

H99 비고:

> 사 19:10에서 נֶפֶשׁ와 결합하여 마음이 슬프거나 근심하는 상태를 나타낸다. KJV는 해당 구절을 ‘못’으로 달리 풀이하지만, 여기서는 원문의 형용사 분석에 따라 ‘슬픈’을 유지한다. Strong의 H98 공통 어원 설명에는 probably라는 제한이 있으므로 역사적 어원을 확정하지 않는다.

H100 비고:

> 정확한 식물 종은 확정하지 않는다. 사 9:14와 19:15에서는 종려가지와 대비되어 낮은 지위의 사람들을 비유하며, 이를 별도 의미로 나누지 않는다. 욥 41:2에서는 코를 꿰는 줄을 가리키며, Strong은 골풀 등으로 꼰 줄로 풀이한다. 욥 41:20은 태우는 갈대 풀이를 우선하되, KJV의 ‘가마’ 및 NET 번역 주석이 전하는 다른 히브리어 읽기에 따른 끓는 솥 해석도 가능성으로 남긴다.

|저장 pair|category_code|relation_type|status_code|direction_code|relation ID|
|---|---|---|---|---|---:|
|H0098_0000 / H0099_0000|etymological|root_shared|hypothesized|undirected|7866|
|H0098_0000 / H0100_0000|etymological|root_shared|asserted|undirected|7867|

두 관계 모두 공통 어근을 나타내는 무방향 관계다. H99·H100의 source에서 H98을 참조하는 방향을 직접 파생 방향으로 복사하지 않는다.

관계 7866 비고:

> Strong의 probably를 보존하는 공통 어근 가설이다. 직접 파생 방향과 역사적 어원을 확정하지 않는다.

관계 7867 비고:

> 같은 어근이라는 Strong의 명시적 설명에 따른다. H98에서 H100으로의 직접 파생 방향을 확정하지 않으며 kettle에 관한 다른 어근 대안은 해당 용례의 비고에 남긴다.

관계 source는 각각 `RESHET-EC-H98-CLUSTER-H0098-H0099`, `RESHET-EC-H98-CLUSTER-H0098-H0100`이며 description·relation_group_id는 NULL이다. H99—H100 관계는 생성하지 않는다. 새 word hold는 없고 기존 hold 6건은 유지한다. 원어 expression·음역·발음·언어·Strong identity·schema·seed·원천·로컬 참고자료는 변경하지 않았다. 기존 semantic approval과 충돌하지 않아 supersession은 없다.

## 핵심 판단 근거

- 정상 lexical closure는 3개 전체, source edge 2개, frontier 0이다. Canonical Strong XML 3 entry와 OSHB 15/15 token, 로컬 참고자료 6종을 전량 비교했다. 한국어·원전분해의 절 번호 차이 4곳은 source alternate와 실제 문맥으로 각각 수동 대조했다. LXX는 명시적 23요청 중 해당 문맥 15절을 수동 비교했고 번호 진단 8건을 구분했다. LXX와 로컬 자료는 reference-only이며 자동 alignment·신약 Strong 추론·canonical count 변경에 사용하지 않았다.
- H98은 8곳에서 물이 고인 수역, 렘 51:32에서 늪의 식생을 불태운 환유로 읽힌다. ‘못·늪’ 하나의 어휘 범위와 비고로 9곳을 설명할 수 있어 독립 ‘갈대밭’ sense를 추가하지 않았다. 기존 meaning도 범위 자체는 대체로 적절하며 이번 선택은 대표 표현을 압축하는 결정이다. Strong의 갈대·갈대 울타리 풀이를 지우지 않고 비고에 보존했다.
- H99의 유일 용례 사 19:10은 אַגְמֵי נָפֶשׁ이며 OSHB는 형용사 남성 복수 연계형으로 분석한다. 한국어 판본·원전분해·LXX의 슬픔 문맥과 Strong의 sad가 기존 ‘슬픈’을 지지한다. KJV의 ponds는 같은 절의 다른 독해로 보존하고 두 번째 meaning으로 추가하지 않았다.
- H100은 식물 의미 4곳과 코를 꿰는 줄 의미 1곳을 구분했다. Strong도 rush와 rope of rushes를 정의에 포함한다. 욥 41:2의 줄은 한국어 세 판본·원전분해·NET의 cord 풀이와 일치하므로 ‘밧줄’을 두 번째 sense로 둔다. 사 9:14·19:15의 낮은 사람 비유는 독립 meaning으로 늘리지 않았다.
- H99 source의 ‘probably from the same as H98’는 확정 어원으로 승격하지 않고 hypothesized로 기록한다. H100의 ‘from the same as H98’는 명시적 공통 어근으로 기록하되 직접 파생 방향을 강제하지 않는다. 사용자는 이 가설 관계를 생성하는 안을 별도로 명시했다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 이유|남기는 위치|
|---|---|---|
|H98 기존 세 표현 유지 또는 ‘습지(濕地)’|기존 범위는 유효하나 물이 고인 수역과 늪을 간결하게 나타내는 ‘못·늪’을 선택|원본 연구·이전 projection|
|H98 ‘갈대밭’을 별도 sense로 추가|렘 51:32의 식생 환유를 비고로 설명 가능하며 sense 증가의 필요성이 낮음|비고·연구 대안|
|H98 ‘갈대 울타리·요새’|Strong·LXX의 다른 풀이가 있지만 해당 구절에서 독립 요새 의미를 확정할 근거가 충분하지 않음|비고·연구 대안|
|H99 ‘근심하는’ 또는 두 번째 ‘못’|근심하는도 가능한 표현이나 기존 형용사 ‘슬픈’이 적절함. 못은 경쟁하는 절 독해이며 별도 lexical sense로 채택하지 않음|비고·연구 대안|
|H100 ‘골풀로 꼰 줄’|식물성 재료 풀이는 source에 있으나 대표 meaning은 물건을 간결하게 나타내고 재료는 비고에 둠|비고|
|H100 ‘가마’·‘갈고리’ 추가|KJV 및 다른 본문 읽기·LXX의 경쟁 해석으로 보존하되 현재 MT의 식물·줄 풀이를 우선|비고·연구 대안|
|H100 ‘낮은 사람’·‘하찮음’ 추가|종려가지와 갈대의 문맥상 비유를 독립 의미로 늘리지 않음|비고|
|H98→H99/H100 직접 derived 방향|from the same as는 같은 어근 설명이며 직접 파생 방향을 입증하지 않음|무방향 root_shared로 기록|
|H98—H99 관계 비생성|비고에만 남기는 대안도 가능했으나 사용자가 가설 관계 생성을 명시 승인함|hypothesized 관계 생성|

## 남은 불확실성 및 재검토 조건

H98 렘 51:32의 정확한 대상, H99의 역사적 어원, H100의 식물 종·줄 재료와 모양·욥 41:20의 본문 읽기는 미확정이다. H100의 ‘타는 갈대’에서 타는 동작은 문맥상 번역 보충이며 별도 burning token이 입증됐다는 뜻이 아니다. NET 번역 주석이 전하는 다른 히브리어 읽기와 시리아어·불가타 해석을 기록하되 이번에 그 원전들을 독립 확인했다고 주장하지 않는다. LXX 사 58:5의 고리 표현과 욥기의 화덕·고리 표현도 MT와 구별한다.

쟁점 절의 critical apparatus·새 고대 증거 또는 독립된 역사언어학 자료가 특정 독해·어근 관계를 실질적으로 판별할 때 재검토할 수 있다. 번역 표현·표기 취향·번호 인접성만으로 meaning이나 관계를 자동 변경하지 않는다. H99 가설 관계를 새 사용자 승인 없이 asserted로 승격하지 않는다.

적용 검증: 공식 dry-run의 사본 적용·실제 undo·원본 불변 및 live apply 성공. Meaning replacement2·note3·relation create2의 7 write와 H99 meaning approval1이다. 독립 SQL59조회·54검증으로 전체13테이블·DDL·공식 snapshot·byte 백업을 비교했고 승인 범위와 history7행·해당 sequence 외 차이가 없다. History group `1792143244476028`, ID6108–6114는 active word update5·relation create2이며 undone0이다. Work·seed·snapshot·byte 백업은 integrity ok·FK0·sidecar0이다. 보호 입력167개·원본 연구22파일 불변, 기존 applicator 테스트31건 통과. 공식 progress JSON·CSV·Markdown에서 대상3개만 explicit_approved로 전환했고 승인296→299·미승인13,996→13,993·hold6·anomaly113은 유지한다. 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.
