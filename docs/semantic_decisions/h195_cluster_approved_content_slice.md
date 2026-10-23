# H195 을래·울라이 강 이름 의미·비고 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-23 (Asia/Seoul)
- 대상: H0195
- 승인 manifest: [h195_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h195_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0195_cluster_20261023_ff361299/`; `00_cluster_summary.md`, H195 full Review·원문 문맥·용례 분류·관계 평가·LXX 비교 보존
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h195_approval_20261023/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261023T034839207514Z/result.json`

## 최종 결정

사용자는 CodeX 추천안을 그대로 승인하고 DB·문서·기타 필요 파일 반영 후 각 단계의 안전한 완료를 확인하면서 커밋·작업 브랜치 push·main fast-forward 병합·main push·이번 로컬 및 원격 작업 브랜치 정리까지 진행하도록 명시했다. 아래 값은 그 승인에 따라 실제 적용·검증한 최종값이다.

|Strong|최종 ordered meaning|sense|처리|
|---|---|---:|---|
|H0195|1. 을래·울라이 (지)|1|의미 교체·승인|

최종 비고:

> 엘람 지방 수산 부근의 강 이름이다. ‘을래’는 한국어 성경의 관용 표기이고 ‘울라이’는 히브리어 표기를 따른 근사 표기이다. Strong은 페르시아계 이름으로 설명하며, 이름 자체의 뜻은 확정하지 않는다.

관계는 생성하지 않는다. H194의 동일 철자, H193과 연결할 수 있을 듯한 어원 가설, H180과의 문맥 공기를 lexical derivation·variant로 승인하지 않는다. 적용할 category/type/status/direction은 N/A다. 기존 H195 관계는 없으며, 전체 기존 관계와 hold6은 그대로 유지하고 신규 hold는 만들지 않는다.

원어 expression·음역·발음·언어·비대상 어휘·schema·seed·앱 코드는 유지한다. Manifest는 meaning replacement1·word note replacement1의 write2건이다. 공식 dry-run·undo와 원본 불변, applicator 테스트31건 이후 실제 DB에1회 적용했다. 독립 SQL44조회·47검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 대조하여 승인 projection·history2·history sequence 외 변경 없음을 확인했다. History group `1792727320470177`, ID6751–6752는 H0195_0000의 word update2·undone0이다. integrity ok·FK0·sidecar 없음·seed 불변이다.

표준 progress JSON·CSV·Markdown 갱신과 독립21검증에서 H195만 `explicit_approved`가 됐다. 승인553→554·미승인13,739→13,738·hold6·anomaly113·전체14,298이며 비대상14,297행과 lexical index는 exact 불변이다. Snapshot identity는 `4eb3e130c91af36e5915203bf774e2ee553d4f7901930dfc3bbbc233ddc04f3f`이다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·UI 수동 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong의 H195는 페르시아계 이름으로 설명된 Ulai/Eulaeus 강이다. OSHB 단8:2·16의 전체2토큰·2절을 검토했으며 모두 HNp 고유명사다. Recursive closure는 H195 한 node·관계0·frontier0으로 완료됐다.
- 단8:2의 별도 물길 명사 H180 뒤에 H195가 오고, 단8:16에서도 같은 이름을 사용한다. 번역의 강·두 언덕/강 둑이라는 표현 차이는 별도 lexical sense로 나누지 않는다. 한 강 이름으로2/2를 설명하며 모호·미분류·정경 반례는0이다.
- 을래는 확보된 개역개정·개역한글·새번역의 관용 표기다. 울라이는 히브리어 표기·Strong 음역 및 현재 한글 음역 필드에 따른 교재식 근사이며 특정 고대 시대의 실제 발음으로 단정하지 않는다. 동일 이름의 두 표기이므로 한 meaning에서 가운데점으로 병기하고 근거 없는 합성 붙임표나 한자를 만들지 않는다.
- Strong은 Persian derivation을 제시하지만 이름 자체의 뜻을 제시하지 않는다. HebGrkKo의 나의 힘(줄)은 자료 자체가 추정으로 표현하므로 meaning·확정 어원·특정 히브리어 어근 관계로 승격하지 않는다. 기원 언어와 canonical 표제어의 언어 heb도 구별한다.
- Canonical 자료와 로컬 사전 exact1행·용례2개×5자료의10비교 슬롯을 전량 확인했다. LXX는 명시적2절을 human reference로 조회·수동 비교했고, 단8:2의 문 표현 차이와8:16의 이름 참고를 구별했다. 로컬·LXX 자료는 canonical authority나 자동 alignment로 사용하지 않았다.
- 사용자가 추천안을 최종 채택했다는 사실과 그 추천안의 evidence-backed 이유를 기록한다. 사용자가 따로 말하지 않은 개인적 선택 이유는 만들지 않는다.

## 채택하지 않은 주요 대안

- 기존 을래 (지)만 유지:2/2 용례를 설명하는 적절한 대안이지만 원문과의 비교 가치가 있는 울라이 병기를 채택했다. 기존 값을 오역으로 판정한 것은 아니다.
- 울라이 (지)만 사용: 원문 비교에는 유용하나 한국어 성경의 관용명 을래를 잃으므로 단독 대표 표기로 채택하지 않았다.
- 나의 힘(줄)을 meaning이나 확정 어원으로 추가: 로컬 사전의 추정이며 정경 용례에서 이름의 번역 의미로 확인되지 않는다. 연구에 남기고 비고에는 어원 한계를 기록했다.
- 을래 강을 두 번째 sense로 추가하거나 Ulai/Eulaeus를 다른 대상으로 분리: 같은 강 이름의 문맥 표현·대조 표기이므로 분리하지 않았다.
- H194·H193·H180과의 신규 관계 또는 전체 hold: 동일 철자·추정 어원·문맥 공기는 lexical 관계의 충분한 근거가 아니다. 기본 이름 식별은 충분하므로 관계 비생성·hold 없음으로 결정했다.

## 남은 불확실성 및 재검토 조건

원천 페르시아어 이름의 정확한 형태·뜻, 역사적 발음, 현대 특정 하천·운하와의 비정은 확정하지 않는다. 확보된 LXXStp 단8:2에는 `πυλη αιλαμ`이라는 문을 언급하는 표현이 있어 OSHB의 강 이름 구문과 다르다. 로컬 파일의 판본 계통·upstream provenance·license는 미검증이며,8:16의 `ουλαι`도 자동 Hebrew–Greek alignment나 Greek Strong 관계로 승격하지 않는다. 이 제한은 연구에 보존하고 미검증 판본 설명을 기본 word note에 넣지 않았다.

독립된 원문·사전·본문비평·역사언어 자료가 H195의 이름 식별이나 의미 범위를 직접 바꿀 때 재검토한다. 단순 번역 span·철자 근사·현대 하천 비정 차이만으로 승인 값을 자동 변경하지 않는다. 현재 불확실성은 기본 의미 승인을 뒤집는 blocker가 아니다.
