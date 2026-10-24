# H210·H211 우바스·오빌 이름 클러스터 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-24 (Asia/Seoul)
- 대상: H0210, H0211
- 승인 manifest: [h210_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h210_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0210_cluster_20261024_36b0e214/`; cluster summary, 각 Strong의 Packet·Review·관계 evidence, 15토큰 분류 및 원문·로컬·LXX 비교
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h210_approval_20261024/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261024T142228575745Z/result.json`

## 최종 결정

사용자는 연구 추천안을 그대로 채택하고 DB·문서·기타 필요 파일 반영, Git 게시와 이번 작업 브랜치 정리까지 승인했다. 아래 값은 실제 적용 및 독립 검증을 완료한 최종 상태다.

| Strong | 최종 ordered meaning | sense | 처리 |
| --- | --- | ---: | --- |
| H0210 | 1. `우바스·우파즈 (지)` | 1 | 의미 교체·승인 |
| H0211 | 1. `오빌·오피르 (인, 지)` | 1 | 의미 교체·승인 |

가운데점은 같은 이름의 표기 병기다. H0211의 인명·지명 및 욥 22:24의 금 환유를 별도 meaning 행으로 나누지 않는다.

**H0210 최종 비고**

> 금의 산지로 언급되는 이름(렘 10:9; 단 10:5). 우바스는 한국어 성경 관용 표기, 우파즈는 원문 형태를 따른 근사 표기다. 정확한 위치는 알려져 있지 않다. Strong은 오빌(H0211)의 변형일 가능성을 제시하지만 확정하지 않는다. 단 10:5 등을 정련된 금으로 읽는 본문 대안도 있어, 이름의 동일시나 금제련소라는 뜻은 확정하지 않는다.

**H0211 최종 비고**

> 욕단의 아들 이름(창 10:29; 대상 1:23)이자 금을 들여오던 지역의 이름이다. 오빌은 한국어 성경 관용 표기, 오피르는 원문 형태를 따른 근사 표기다. 욥 22:24에서는 지명만으로 그곳의 금을 가리킨다. 정확한 위치와 어원은 미확정이며, 인명과 지명의 유래 관계 및 우바스(H0210)와의 동일성은 확정하지 않는다.

H0210↔H0211 관계는 생성하지 않는다. `perhaps a corruption of`는 본문 변형·동일시의 추정이며 확정 파생·공통 어근·동의어로 승인하지 않는다. 신규·교체·삭제 관계가 없으므로 category/type/status/direction은 N/A다. 기존 모든 관계와 hold ledger를 유지하고 두 어휘에 신규 hold를 만들지 않는다.

변경 범위는 meaning replacement2·word note replacement2다. 원어 expression·음역·발음·언어·비대상 어휘·schema·seed·앱 코드는 유지한다. Work DB는 Git 미추적 로컬 자산이며 Git에는 승인 manifest와 문서·해당 manifest의 byte 보존 속성을 게시한다.

공식 dry-run·undo·원본 불변, applicator 테스트31개, 실제 적용 후 전체13테이블 대조·52 SQL조회·241검증을 통과했다. 승인 projection·word history4·history sequence 외 데이터 변화가 없다. History group `1792851749947711`, ID6858–6861은 두 어휘별 word update2개이며 undone은 없다. integrity ok·FK0·sidecar 없음·seed 불변이다. 보호 입력162개와 원본 연구15파일이 불변이다.

표준 progress JSON·CSV·Markdown 및 독립20검증에서 대상2개만 신규 승인됐고 비대상14,296행·anomaly·lexical index는 exact 불변이다. 승인593→595·미승인13,699→13,697·hold6·anomaly113·전체14,298이며 snapshot identity는 `851852ea94aa0b54760ed4f74852d4fc319ee96b0663f5c44d86922aae4570b3`다.

## 핵심 판단 근거

- Canonical Strong H210은 `אוּפָז`, 지명이며 `perhaps a corruption of H211`을 제시한다. OSHB 렘10:9·단10:5의 전체2토큰은 금과 연결된 이름으로 읽힌다. 이 채택 본문을 보존하면서 위치·동일시·본문 교정 가능성을 비고에 구분했다.
- H211은 `אוֹפִיר`와 같은 entry 안의 축약 표기를 보존한다. Strong은 욕단의 아들과 금으로 알려진 지역을 함께 설명하고 어원은 미확정으로 둔다. OSHB 전체13토큰은 인명2, 이동·교역 지명6, 금의 출처를 수식하는 지명4, 금 환유1이다.
- 욥22:24는 단독 H211로 그곳의 금을 가리킨다. 단순히 인명·지명만 같은 방식으로 지시한다고 하면 부족하므로 환유를 비고에 명시했다. 다른 금 문맥은 별도의 금 명사가 H211을 수식하는 구문과 구별했다. 일반 금 의미를 추가할 필요는 없다고 판단했다.
- 우바스·오빌은 확보된 한국어 성경의 관용 표기, 우파즈·오피르는 현재 원어 표현과 연결되는 교재식 근사 표기다. 같은 이름의 관용·원문 비교 가치를 병기로 보존하며 특정 고대 시대의 실제 발음으로 단정하지 않는다. 근거 없는 한자·합성 붙임표를 추가하지 않는다.
- 정상 closure는 CORE2·관계 evidence1·frontier0으로 끝났고 전체15토큰·14절의 원문과 확보된 적용 가능 참고자료를 확인했다. 한국어 자료의 절 번호 충돌2곳은 명시적 후보 절 비교로 보충하되 raw Packet의 manual flag와 profile unverified 상태를 유지했다.
- LXX는 explicit human-reference 조회로만 사용했다. 확보된 단10:5의 금·이름 비대응, 시편의 이름 비대응, 일부 로컬 row 부재를 현재 Hebrew 본문 변경이나 자동 Greek relation의 근거로 사용하지 않았다.
- 사용자가 이 추천안을 최종 채택했다는 사실과 그 evidence-backed 이유를 기록한다. 사용자가 말하지 않은 개인적 이유를 부여하지 않는다.

## 채택하지 않은 주요 대안

- 기존 `우바스 (지)`·`오빌 (인, 지)`만 유지: 이름 식별에는 가능한 대안이지만, 원문 비교 가치가 있는 우파즈·오피르 병기를 채택했다. 기존 관용 표기를 오역으로 판정한 것은 아니다.
- 우파즈·오피르만 단독 사용: 한국어 성경의 관용명을 잃으므로 채택하지 않았다.
- H211 인명·지명을 두 meaning으로 분리: 현재의 동일 이름 통합 표기로 충분하며 문맥·지시 대상 차이는 비고에 보존했다. 인명에서 지명이 생겼다는 유래 관계도 확정하지 않았다.
- H211에 일반 금·순금 또는 오빌의 금을 별도 meaning으로 추가: 욥22:24의 환유를 설명하는 가능한 대안이지만 한 문맥을 일반적인 금 lexical sense로 확대하지 않고 비고에 보존했다.
- H210을 오빌의 이형으로 통합하거나 두 이름의 관계 생성: Strong의 `perhaps`와 경쟁 본문 독법을 제거할 수 없어 채택하지 않았다.
- H210에 정련된 금·금제련소 의미 추가: 정련된 금 독법은 본문 대안으로 보존하되 현재 H210 정본의 이름 meaning과 섞지 않는다. 금제련소라는 시설명 확정 근거는 부족하다.
- word 전체 hold: 현재 채택 본문에서 이름과 용법을 설명할 수 있으므로 만들지 않았다. 어원·지리·본문의 불확실성은 비고와 연구에 남겼다.

## 남은 불확실성 및 재검토 조건

H210의 정확한 위치·이름 기원·H211과의 동일성, 정련된 금으로 읽는 본문 대안은 미확정이다. H211의 정확한 위치·어원·인명과 지명의 유래 관계도 확정하지 않는다. Canonical 언어 코드 `x-pn`과 DB의 히브리어 분류를 혼동하지 않으며, 의미 승인이 원천 언어 미확정을 해결한 것은 아니다.

로컬 번역 일부의 전체 versification profile과 LXXStp의 upstream provenance·license·판본 계통은 미검증이다. 명시적으로 확인한 행의 문맥 비교를 source 전체의 자동 매핑 authority로 승격하지 않는다. 적용 후에도 연구 Packet·Review를 수정하지 않았다.

독립된 사본·본문비평·사전·역사언어 자료가 고유명사 분석, 이름의 동일시 또는 독립된 금 의미의 필요성을 직접 바꿀 때 재검토한다. 현대 지리 비정 후보, 번역 표현 차이, 한글 근사 표기의 차이만으로 승인 값을 자동 변경하지 않는다. 현재 남은 불확실성은 위 이름 meaning의 승인 blocker로 보지 않았다.
