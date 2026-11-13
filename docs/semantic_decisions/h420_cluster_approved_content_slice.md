# H420 엘다아 인명 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-13
- 대상: H0420
- 승인 manifest: [h420_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h420_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, 신규 hold 없음
- 로컬 연구 산출물: `H0420_cluster_20261113_0971146d/00_cluster_summary.md` R1

## 최종 결정

사용자는 R1 추천안을 채택하고 DB·문서·검증·Git·이번 작업 브랜치 정리까지 승인했다.

- meaning: `엘다아·엘-다아 (인)` 한 sense.
- 비고: 창 25:4와 대상 1:33에서 미디안의 아들, 곧 아브라함과 그두라의 손자를 가리킨다. ‘엘다아’는 한국어 성경 관용명과 교재식 한글 근사가 겹치는 표기이며, ‘엘-다아’는 신명 요소 엘과 뒤 요소의 경계를 보여 주는 분석 표기다. 붙임표는 원문 마케프를 뜻하지 않는다. Strong은 H410과 H3045의 결합으로 보아 ‘지식의 하나님’으로 풀이하지만, BDB는 아랍어 ‘부르다’와 비교하며 ‘하나님께서 부르셨다?’라는 대안을 제시한다. 엘 요소는 분명하나 뒤 요소의 정확한 어원은 확정하지 않는다. 확보된 LXX 참고자료는 창 25:4에서 ελραγα, 대상 1:33에서 ελδαα로 달라, 이를 별도 인명이나 확정된 원발음으로 삼지 않는다.
- H0410→H0420: morphological / compound / asserted, 저장 pair H0410_0000·H0420_0000, w1_to_w2, relation ID8370.
- H3045→H0420: morphological / compound / hypothesized, 저장 pair H0420_0000·H3045_0000, w2_to_w1, relation ID8371.
- 신규 hold 없음. H28·H410 기존 승인 및 나머지 CONTEXT 현행값 보존. 원문·음역·발음·언어·schema·seed 변경 없음.

## 핵심 판단 근거

창25:4와 대상1:33의 두 정본 용례는 미디안의 아들 한 사람을 가리킨다. 관용명과 교재식 근사는 엘다아로 겹치며 엘-다아는 두 어원 분석에 공통인 신명 요소 경계만 보인다. H28의 관용명·분석 표기 병기와 H419의 엘 구성 표기 선례도 대조했다. Strong의 지식 풀이와 BDB의 부르셨다? 분석이 달라, 엘 구성은 확정하지만 알다 어근 관계는 가설로 구분한다. 사용자는 이 근거에 따른 R1 추천을 채택했다.

## 채택하지 않은 주요 대안

- 현행 엘다아 (인)만 유지: 안전한 대안이나 이번에는 분석 경계를 함께 보존했다.
- 어원 풀이를 별도 meaning으로 추가: 실제 인명 용법과 어원 가설을 혼합하므로 채택하지 않았다. 비고에 보존했다.
- H3045 관계 확정 또는 비생성: 경쟁 어원이 있어 확정은 피하되, 실제 Strong 가설을 추적할 수 있도록 hypothesized 관계를 채택했다.
- 단어 전체 hold: 이름 identity와 의미는 충분히 확인되므로 두지 않았다.

## 남은 불확실성 및 재검토 조건

뒤 요소의 정확한 어원, 실제 역사적 호명, LXX 두 구절의 철자 차이 경로는 미해결이다. 신뢰할 만한 셈어 인명 연구나 검증된 원전 증거가 판단을 실질적으로 바꿀 때 재검토한다. 번역본 하나의 표기 차이나 허브의 추가 연결만으로 자동 변경하지 않는다. 전역 discovery는 미완료이며 이번 완료 범위는 허브 예외에 따른 H420 전량 검토다.

## 적용 검증

공식 dry-run·undo·원본 불변, 적용기 테스트31개, live apply1회와 전체 테이블·DDL 독립 대조를 통과했다. 의미1·비고1·관계2·history4행과 해당 sequence 외 불변이다. 두 DB 및 백업·snapshot integrity ok, FK0·sidecar0·seed SHA 불변. 진행표 승인953→954·미승인13339→13338·hold6·anomaly113, 비대상14297행 불변을 확인했다. Receipt는 로컬 `data/backups/approved_content_batch/20261113T015820644326Z/result.json`, 독립 검증은 `data/backups/approved_content_batch/h420_approval_20261113/independent_verification.json`에 있다. 앱 UI 테스트는 UI·동작 변경이 없어 N/A다.
