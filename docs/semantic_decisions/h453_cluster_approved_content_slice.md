# H453 엘리후 이름 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-16
- 대상: H0453
- 승인 manifest: [h453_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h453_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `reshet_research_output/H0453_cluster_20261116_871aab65`, R1

## 최종 결정

- Meaning seq1: `엘리후·엘리-후 (인)`, 1 sense.
- 비고:

> 욥과 대화한 부스 사람 바라겔의 아들, 사무엘의 증조부, 다윗에게 합류한 므낫세 지파의 천부장, 오벧에돔 집안의 문지기, 유다 지파의 지도자인 다윗의 형제 등의 이름이다. אֱלִיהוּ와 אֱלִיהוּא는 같은 이름의 철자형이며, H410 엘(하나님)과 H1931 후(그)의 합성이다. BDB는 ‘그는 (나의) 하나님이다’, Strong은 ‘그의 하나님’으로 풀이하므로 이름의 어원 풀이와 인명 용법을 구별한다. 엘리후는 성경 관용 표기이고 엘리-후는 두 구성 요소의 경계를 드러낸 교재식 읽기의 한글 근사다. 사무엘 계보의 엘리후는 대상 6:27의 엘리압·6:34의 엘리엘과 비교된다. 확보 LXX는 대상 12:21(한국어 12:20)에서 ελιμουθ, 대상 27:18에서 ελιαβ를 전한다. 평행 이름과 본문 전승 차이를 별도 어휘의 자동 통합이나 확정된 이형 관계로 취급하지 않는다. 붙임표는 실제 마케프가 아니며 정확한 고대 발음을 재현하지 않는다.

- H0410→H0453: `H0410_0000 / H0453_0000`, morphological/compound/asserted/w1_to_w2, 신규 ID8428.
- H1931→H0453: `H0453_0000 / H1931_0000`, morphological/compound/asserted/w2_to_w1, 신규 ID8429.
- 관계 note·source·NULL description·relation_group_id는 승인 manifest와 같다.
- H446·H447·H452·H30과의 별도 관계 비생성, 신규 hold 없음. CONTEXT의 기존 승인 및 H1931 미승인 상태 유지.

## 핵심 판단 근거

사용자는 R1 추천안 전체와 DB·문서·검증·Git·이번 작업 브랜치 정리를 승인했다. OSHB 11토큰·11절은 욥의 화자7건과 다른 네 지시 문맥 각1건이며 모두 같은 인명이다. אֱלִיהוּ 4건·אֱלִיהוּא 7건을 별도 sense로 나누지 않았다. Strong의 from H410 and H1931와 BDB의 이름 풀이가 두 구성 요소를 뒷받침한다. 전체 이름 문장의 풀이 차이는 비고에 보존했다.

관용명 엘리후와 구성 경계를 보이는 교재식 근사 엘리-후를 병기했다. H30 아비후·아비-후와 H446/447의 엘리- 분석 표기와 일관되며 실제 고대 호명을 복원했다는 뜻은 아니다. 대상12:20은 OSHB12:21과 수동 대조했고 욥32:5의 한국어 이름 생략도 확인했다.

## 채택하지 않은 주요 대안

- 엘리후 단독: 유효한 관용명이지만 구성 비교를 보존하도록 분석 표기를 병기했다.
- 이름 풀이 또는 인물별 여러 meaning: 어원·지시 대상과 인명 자체의 의미를 구별한다.
- H446/H447 variant 관계: 평행 계보 및 LXX 이름 차이를 자동 lexical 통합 근거로 삼지 않았다.
- H452와 통합 또는 H30과 직접 관계: 공통 철자·구성 요소만으로 독립 이름 간 관계를 확정하지 않는다.

## 남은 불확실성 및 재검토 조건

이름 전체 문장과 역사적 -i 기능, 평행 인물의 동일성, 정확한 고대 발음은 미확정이다. 확보 LXX 대상12:21의 ελιμουθ 및27:18의 ελιαβ를 보존하지만 전승 원인이나 모든 판본의 읽기를 확정하지 않는다. Local profile 및 LXX provenance/license의 unverified 경계를 유지한다. 인명학·본문비평의 새 원자료가 구성이나 관계 판단을 바꿀 때 해당 항목을 재검토하며 작은 발음 차이나 같은 gloss 반복으로 자동 재감사하지 않는다. 허브 예외의 global closure 미완료·frontier157과 CORE1 전량 검토를 구별한다.

## 적용 및 검증

공식 dry-run·실제 undo·원본 불변과 적용기31테스트 통과 후 live apply1회. 의미1·비고1·관계 생성2, history group1794799238445377의4행이다. 사용자 테이블12개·DDL·기존 이력·비대상 데이터 및 sequence의 관계+2·이력+4만을 독립 검증했다. Work·seed·백업·공식 snapshot integrity ok·FK0·sidecar없음.

- Work SHA: `2738a028b63c90948ea80f9d26bbd797f3668a5978c1f19625dc364e1175f4f4`
- Seed SHA: `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`, 불변.
- Receipt: `data/backups/approved_content_batch/20261116T032036832941Z/result.json`
- 독립 검증: `data/backups/approved_content_batch/h453_approval_20261116/independent_verification.json`
- Progress: 승인1022→1023·미승인13270→13269·hold6·anomaly113 유지. 비대상 progress row 불변 및 공식 CSV/Markdown renderer 일치 검증.
- Snapshot: `9dd849b2ac1fa83ee59fff86102eedf13fa1f1595a9055c3f1751879f139412c`
- 원문·음역·발음·언어·schema·seed·앱/UI 변경 없음. UI 테스트 N/A.
