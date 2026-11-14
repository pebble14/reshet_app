# H447 엘리엘 이름 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-14
- 대상: H0447
- 승인 manifest: [h447_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h447_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `reshet_research_output/H0447_cluster_20261114_f83238c1`, R1

## 최종 결정

- Meaning seq1: **엘리엘·엘리-엘 (인)**, 1 sense.
- 비고: 므낫세·베냐민 지파의 지도자들, 사무엘의 조상, 다윗의 용사들, 헤브론계 레위인 지도자와 히스기야 때 봉헌물 관리인 등의 이름이다. H410 엘(하나님)이 반복된 합성 이름으로, BDB는 ‘엘은 하나님’ 또는 ‘나의 하나님은 하나님’으로 풀이하고 Strong은 ‘(그의) 하나님의 하나님’으로 설명한다. 엘리엘은 성경 관용 표기이고, 엘리-엘은 אֱלִי와 אֵל의 경계를 드러낸 교재식 읽기의 한글 근사로서 정확한 고대 발음의 재현은 아니다. 대상 6:34의 인물은 대상 6:27의 엘리압, 삼상 1:1의 엘리후와 비교된다. 대상 12:11의 엘리엘 자리는 확보 LXX의 12:12에서 ελιαβ(엘리압 형태)로 전해진다. 이러한 평행 이름과 본문 전승 차이를 별도 어휘의 자동 통합이나 확정된 이형 관계로 취급하지 않는다.
- H0410→H0447: `H0410_0000 / H0447_0000`, morphological/compound/asserted/w1_to_w2, 신규 ID8422. 관계 note/source는 승인 manifest의 정확한 값과 같다.
- H447–H446/H453 variant 관계는 생성하지 않는다. 신규 hold 없음. H22/H410/H446 기존 승인과 H453 미승인 상태를 유지한다.

## 핵심 판단 근거

사용자는 R1 추천안 전체와 DB·문서·Git·이번 작업 브랜치 정리를 승인했다. OSHB 10토큰·10절 전량은 모두 남성 인명이며, 여러 지시 대상을 별도 lexical sense로 늘리지 않았다. Strong의 H410 repeated와 BDB의 두 엘 요소 분석은 구성 관계를 지지한다. 동일 요소가 두 위치에 반복되지만 관계는 하나만 만든다.

관용명 엘리엘과 אֱלִי/אֵל 경계를 드러내는 교재식 근사 엘리-엘을 병기했다. H22 아비엘·아비-엘, H446 엘리압·엘리-아브의 현재 승인과 같은 원칙이다. 전체 이름 문장의 풀이와 역사적 -i 기능의 불확실성은 확정된 구성 요소와 구별했다.

## 채택하지 않은 주요 대안

- 엘리엘 단독: 정확한 관용명이지만 이번에 확인한 구성 비교를 드러내지 못하여 분석 표기를 병기했다.
- 나의 하나님은 하나님 등 어원 풀이를 별도 meaning으로 추가: 인명 용례와 어원 설명을 구별하여 비고에 보존했다.
- 인물마다 별도 meaning: 지시 대상 차이가 lexical sense 차이를 입증하지 않는다.
- H446/H453와 variant 관계: 평행 계보와 확보 LXX의 이름 차이는 비고에 남기되 자동 어휘 통합이나 확정 이형 관계로 승격하지 않았다.

## 남은 불확실성 및 재검토 조건

Strong의 아홉 인물 집계와 BDB가 열어 둔 일부 용사 동일성, 이름 문장의 해석·-i 기능·정확한 고대 발음은 미확정이다. 일반 인명 의미와 두 엘 요소의 구성 승인을 막지 않는다. 한국어/KJV 대상6:34·12:11과 OSHB6:19·12:12의 번호 차이는 수동 대조했다. 확보 LXX12:12는 ελιαβ를 전하지만 모든 LXX 판본의 읽기로 일반화하지 않는다. HebGrkKo의11:47 모압 출신 설명은 본문으로 확인되지 않아 채택하지 않았다.

로컬 reference profile과 LXX upstream provenance/license의 unverified 경계는 유지한다. 전문 인명학·본문비평·source 정정 근거가 판단을 실질적으로 바꿀 때 해당 항목을 재검토하며 같은 gloss나 작은 발음 차이로 반복 감사하지 않는다. H410 hub 예외로 전역 closure 미완료·frontier149를 원본 연구 state에 보존했다. CORE1 전량 검토와 전역 탐색 완료를 구별한다.

## 적용 및 검증

공식 dry-run·실제 undo·원본 불변 및 적용기31테스트 통과 후 live apply1회. History group1794617587871397의8053–8055 세 행과 관계8422를 확인했다. 적용 전 byte 백업과 사용자 테이블12개·DDL·기존 이력·비대상 데이터 및 기대 sequence 증분(관계+1·이력+3)을 독립 대조했다. Work·seed·백업·공식 snapshot integrity ok·FK0·sidecar없음, seed 불변이다.

- Work SHA: `68887e0b829abc916442a9ebece7fabf4e325f41a987f52a772e253ff1b044e4`
- Seed SHA: `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`
- 공식 receipt: `data/backups/approved_content_batch/20261114T005304742289Z/result.json`
- 독립 SQL·검증: `data/backups/approved_content_batch/h447_approval_20261114/independent_verification.json`
- Progress 승인1017→1018·미승인13275→13274, hold6·anomaly113 유지. JSON·CSV·Markdown을 공식 도구로 함께 갱신했다.
- Progress snapshot: `500220dddd344055f01c68e701819b5fe651e7045e97ee8ecd7060a7f8c6bd18`
- 앱 코드·UI·원문·음역·발음·언어·schema·seed 배포 변경 없음. UI 테스트 N/A.
