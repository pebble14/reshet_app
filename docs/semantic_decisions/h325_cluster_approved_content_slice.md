# H325 아하수에로 인명 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-01 (Asia/Seoul)
- 대상: H0325 / H0325_0000
- 승인 manifest: [h325_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h325_cluster_approved_content_slice.json)
- hold authority: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 상세 연구: 로컬 reshet_research_output/H325_cluster_20261101_d6637108/00_cluster_summary.md 및 Full Review
- 승인·적용 전 백업·독립 검증: data/backups/approved_content_batch/h325_approval_20261101/
- 공식 receipt: data/backups/approved_content_batch/20261101T111630712828Z/result.json

## 최종 결정

사용자는 직전 R1 추천안의 DB·문서·필요 파일 반영, 검증 후 커밋·작업 branch push·main ff-only 병합·push·이번 작업 branch의 로컬·원격 정리를 승인했다.

Meaning seq1을 아하수에로 (인)에서 **아하수에로·아하쉬웨로쉬 (인)**으로 교체했다. 같은 인명의 관용명·교재식 근사 병기인 1 sense다. 비고 NULL은 다음으로 변경했다.

> 아하수에로는 한국어 성경 관용명이고 아하쉬웨로쉬는 기존 교재식 w 계열 읽기에 따른 히브리어 표기의 한글 근사다. 페르시아계 왕명으로, 에스더서와 스 4:6에서는 일반적으로 크세르크세스 1세로 이해한다. 단 9:1에서는 메대 사람 다리오의 아버지로 나오므로 같은 인물로 단정하지 않는다. 고대 페르시아어 Xšayāršā에 대응하는 이름으로 보지만 세부 어원 풀이와 정확한 전승 경로는 확정하지 않는다. Strong은 왕의 칭호로 설명하나 여기서는 인명으로 처리한다. 에 10:1의 짧은 철자 Ketiv와 일반형 Qere는 같은 이름의 읽기 차이로 구별한다. LXX 참고본문의 에스더서는 아르타크세르크세스라는 이름을 사용한다.

관계 신규·교체·삭제0, word-level hold 없음. 관계 pair·direction·category/type/status는 N/A다. 원문·음역·발음·언어·schema·seed·앱 구현·기존 승인은 유지했다. 기존 결정을 대체하지 않으므로 supersession 없음.

## 핵심 판단 근거

Canonical Strong XML H325의 n-pr-m과 OSHB 32토큰·30절을 전량 확인했다. 모든 토큰은 인명 의미로 설명되며 미검토·의미 배정 미해결·sense 모호·반례는0이다. 단9:1의 역사 인물 식별 미해결1은 별도 중복 태그다. 에1:1은 이름이 두 번 나오며 에10:1은 한 자리의 Ketiv/Qere 두 토큰이다. Qere 기준 읽기 자리31과 canonical32를 구별한다.

HebGrkKo exact1, KJV·개역개정·개역한글·새번역·원전분해 각30절, LXX 명시적30절을 전량 대조했다. LXX는 Greek 본문29절·Not Existed placeholder1(에9:30)이며 provenance/license unverified인 human reference다. 자동 alignment·Greek Strong 추론을 하지 않았다. 한국어 reference의 unverified profile도 유지했다.

[온라인 BDB 해당 항목](https://biblehub.com/hebrew/325.htm), [Iranica AHASUREUS](https://www.iranicaonline.org/articles/ahasureus/), [XPa 공개 번역](https://www.livius.org/sources/content/achaemenid-royal-inscriptions/xpa/)을 대조하여 Strong의 칭호 설명과 인명 처리를 구별했다. 에스더·에스라의 통상 역사 식별을 다니엘의 부친에게 자동 확대하지 않았다. 비문 원물·사전 전체·연결 논문·모든 사본 전문을 확인한 것으로 주장하지 않는다.

[표기 정책](../semantic_research/korean_lexical_notation_policy.md)과 [H307](h307_cluster_approved_content_slice.md)·[H308](h308_cluster_approved_content_slice.md)의 실제 manifest·DB를 대조했다. 관용명과 기존 교재식 w 계열 근사를 보존하며, 외래어 제1·2·3·5항 적용·제4항 제외 기준을 따른다. 한자·불확실한 붙임표를 만들지 않았다. 당대의 정확한 발음 재현은 아니다. Lexical discovery node1·edge0·frontier0으로 전역 closure 완료, hub 예외 없음이다.

## 채택하지 않은 주요 대안

- 관용명 단독 또는 근사 단독: 각각 유효하지만 식별과 원문 비교를 함께 제공하는 병기를 선택했다.
- 아하쉬베로쉬: v 계열의 가능한 대안이나 기존 자료의 w 계열 읽기를 우선했다.
- 크세르크세스 1세를 meaning 전체에 추가: 단9:1까지 동일인으로 묶지 않도록 비고에 범위를 한정했다.
- 아르타크세르크세스 병기: LXX의 전승 차이로 비고에 보존하고 다른 왕명과 직접 음역·동의어 관계를 만들지 않았다.
- 왕·칭호·추정 어원 풀이를 별도 sense로 추가: 별도 왕 명사의 뜻과 이름의 어원을 인명 의미로 옮기지 않았다.
- 짧은 Ketiv의 새 이름·sense·관계: 독립 word entity나 확정된 별도 발음으로 만들지 않았다.
- word hold: 일반 인명 의미는 승인 가능하며 남은 문제를 비고에 한정했다.

## 남은 불확실성 및 재검토 조건

단9:1의 특정 역사 인물, 모든 동명자의 동일성, 세부 어원·차용 경로·정확한 고대 음가, Ketiv 모음 부여와 사본 계통은 미확정이다. 새로운 전문 이름 사전·비문·critical apparatus가 identity·일반 의미·본문 범위를 실질적으로 바꾸거나 사용자가 읽기 체계를 바꾸면 재검토한다. 같은 자료 재집계·표기 취향·31/32 차이·번호 인접성만으로 자동 변경하지 않는다.

### 적용 검증

공식 dry-run·undo·원본 SHA 불변, 적용기 테스트31개 통과 후 live apply1회. 전체13테이블·DDL 독립 대조에서 승인 meaning·비고·history2행·해당 sequence 외 변경 없음. History group1793531793382643, ID7519–7520, undone 없음. Integrity ok·FK0·sidecar0·snapshot 정상·seed 불변이다.

Work SHA d66371088c9a7db92275d3db0e5536eddc9c9764f5095df827e2cd990e2a5f25 → c9fc95b1d6552d185bf3d7c095e56b798a93c5e255053f7f6c5d00bb2ba2e28b. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변.

표준 progress3종을 생성하여 대상 exact 일치·비대상14297행·anomaly 불변을 확인했다. 승인828→829·미승인13464→13463·hold6·anomaly113. 기존 승인 manifest·hold·입력 manifest·로컬 reference 지문 불변이다. 앱 구현·UX·schema·seed 배포 변경이 없어 UI 테스트와 전체 빌드는 N/A다.
