# H446 엘리압 이름 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-14
- 대상: H0446
- 승인 manifest: [h446_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h446_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `reshet_research_output/H0446_cluster_20261114_231648ba`, R1

## 최종 결정

- Meaning seq1: **엘리압·엘리-아브 (인)**, 1 sense.
- 비고: 헬론의 아들인 스불론 지파 지도자, 발루의 아들이며 다단·아비람의 아버지인 르우벤 사람, 이새의 맏아들이자 다윗의 형, 사무엘 계보의 레위인, 갓 지파 용사, 레위인 악사 등 여섯 사람의 이름이다. H410 엘(하나님)과 H1 아버지의 합성 이름으로, BDB는 ‘하나님은 아버지’로 풀이하고 Strong은 ‘(그의) 아버지의 하나님’으로 다르게 설명한다. 엘리압은 성경 관용 표기, 엘리-아브는 אֱלִי와 אָב의 구성 경계를 드러낸 교재식 읽기의 한글 근사이며 정확한 고대 발음의 재현은 아니다. 사무엘 계보의 엘리압은 대상 6:34의 엘리엘, 삼상 1:1의 엘리후와 비교된다. 다윗의 형 엘리압은 대상 27:18의 엘리후와 비교되며, 확보 LXX 자료는 그 자리에서 엘리압 형태를 전한다. 이러한 평행 전승을 별도 어휘의 자동 통합이나 확정된 이형 관계로 취급하지 않는다.
- H0001→H0446: `H0001_0000 / H0446_0000`, morphological/compound/asserted/w1_to_w2, 신규 ID8420.
- H0410→H0446: `H0410_0000 / H0446_0000`, morphological/compound/asserted/w1_to_w2, 신규 ID8421.
- 두 관계의 note·source는 승인 manifest의 정확한 값을 따른다.
- H446–H22/H447/H453 관계는 생성하지 않는다. 신규 hold 없음. H1/H410/H22 기존 승인과 다른 관련어의 상태는 유지한다.

## 핵심 판단 근거

사용자가 R1 추천안 전체를 승인했다. OSHB 21토큰·20절은 모두 같은 이름의 인명 용례이며, 여섯 인물군을 별도 lexical sense로 나눌 근거가 없다. 한국어 관용명과 원문 구성 경계를 드러내는 교재식 근사를 병기한다. H22의 아비엘·아비-엘 승인 선례와 일관되며 원문·음역·발음 필드는 바꾸지 않는다.

Strong과 BDB는 H410 엘/하나님과 H1 아버지의 결합에 일치한다. 전체 이름의 구문적 풀이는 달라 비고에 보존하고, 두 구성 관계의 확실성과 구별했다. 평행 이름과 특정 인물의 대응은 이름 전체의 자동 통합·형태 변이 관계 생성 근거로 삼지 않는다.

## 채택하지 않은 주요 대안

- 엘리압 단독: 관용 식별은 가능하지만 이번 기본 병기와 구성 비교 기준을 충분히 반영하지 못한다.
- 엘리압·엘리아브: 가능한 대안이나 분석 경계도 보여 주는 엘리-아브를 채택했다.
- 이름 풀이 또는 인물별 여러 meaning: 어원과 referent 차이를 lexical sense로 늘리지 않는다.
- H447/H453와 variant 관계: 평행 계보·명단의 이름 대응은 비고에 보존하되 정확한 어휘 관계 유형·방향은 확정하지 않는다.

## 남은 불확실성 및 재검토 조건

이름 문장의 역사적 해석, -i의 기능과 정확한 고대 발음, 평행 이름의 인물 동일성은 미확정이다. 이는 인명 의미와 두 구성 요소의 승인을 막지 않는다. 사무엘17:13·17:28은 확보 LXX의 explicit lookup에서 row가 없었으며 모든 LXX 판본의 부재로 일반화하지 않는다. LXX provenance/license와 한국어 reference profile의 unverified 경계는 보존한다. 전문 인명학·본문비평 자료가 구성·전승 판단을 실질적으로 바꿀 때 관련 항목만 재검토하며 동일 gloss 반복이나 작은 발음 차이로 자동 재감사하지 않는다.

## 적용 및 검증

공식 dry-run·실제 undo·원본 SHA 불변 및 적용기 테스트31개가 통과했다. Live apply1회, history group `1794615758897931`, 신규 history8049–8052의4행이다. 관계8420–8421을 확인하고 적용 전 백업과 사용자 테이블12개·DDL·기존 이력·비대상 데이터 및 sqlite_sequence의 기대 증분만을 독립 대조했다. Integrity ok, FK위반0, sidecar없음, seed불변이다.

- Work SHA-256: `f83238c138bf9cb626823859683c9c206019bf325693ba0095429930e011e2fb`
- Seed SHA-256: `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`
- 공식 receipt: `data/backups/approved_content_batch/20261114T002235848205Z/result.json`
- 독립 검증: `data/backups/approved_content_batch/h446_approval_20261114/independent_verification.json`
- Progress: 승인1016→1017, 미승인13276→13275, hold6·anomaly113 유지. Snapshot `facfdd94cb7f6c6a3603e899075431a8f23e58811a1560553eed406433fd8154`. JSON·CSV의 H446 승인값을 대조했고 공식 Markdown도 함께 생성했다.
- DB·manifest·본 기록의 meaning·비고·관계 값 일치 확인. App/UI·schema·seed 배포 변경 및 UI 테스트 N/A.
