# H318 시간 부사 의미·비고 및 hold 해제 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-01 (Asia/Seoul)
- 대상: H0318 / H0318_0000
- 승인 manifest: [H318 승인 manifest](../../tool/data_provenance/manifests/h318_cluster_approved_content_slice.json)
- 관련 hold ledger: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), H0318만 제거
- 이전 결정: [H268 연결군](h268_cluster_approved_content_slice.md)의 H318 hold 부분만 대체
- 연구 산출물: reshet_research_output/H318_cluster_20261101_33ad8580/00_cluster_summary.md, 04_semantic_assessment_R1.json
- 적용·독립 검증: data/backups/approved_content_batch/h318_approval_20261101/
- 공식 receipt: data/backups/approved_content_batch/20261101T052131869959Z/result.json

## 최종 결정

사용자는 H318-R1 추천안과 DB·문서·기타 필요 파일 반영, 검증, 커밋·작업 브랜치 push·main ff-only 병합·push·로컬/원격 작업 브랜치 정리를 승인했다.

H318 meaning seq1을 `마지막의, 최후의`에서 **마침내** 1의미로 교체하고 비고 NULL을 다음으로 변경했다.

> 단 4:5(OSHB, 한국어 성경 4:8)에서 עַד와 결합하여 순서의 끝에 이르는 때, 곧 마침내를 나타내는 전통 독법을 따른다. 단독 부사의 일반적 용법은 확인되지 않는다. Strong은 H317에서의 파생을 제시하지만 CAL은 עַד אָחֳרֵין을 시간 부사구로 다루며, 이집트 아람어의 עַל אחרן 나중에·마침내와 비교한다. BDB는 어형·구문을 의심하며 또 다른 이로 읽는 대안을 논의한다. 다른 사본의 אחרן과 헬라어 전승의 차이는 별도로 남기고, 현행 OSHB의 אחרין을 H321 용례로 바꾸거나 합산하지 않는다. 세부 어원과 H317의 직접 파생 관계는 확정하지 않는다.

H318 word-level hold를 해제했다. 기존 CORE16의 의미·비고 및 관계13건은 그대로 인정·유지하며 새 승인 operation을 만들지 않았다. 기존 관계 보류7쌍·비생성1쌍을 유지하고, H311/H318은 관계 보류·행 비생성, H318/H321은 대안 본문 비교만 보존하여 관계 비생성으로 결정했다. H317/H318의 직접 파생도 계속 보류한다. 관계 생성·교체·삭제0, 신규 category/type/status/direction N/A. 원문·음역·발음·언어·schema·seed·앱 구현은 변경하지 않았다.

## 핵심 판단 근거

현행 canonical Strong은 last / at last이며 OSHB의 단4:5(한국어4:8)는 H318 1 token을 AD로 분석한다. 전통 MT의 시간 부사구 독법을 기준으로 마침내를 채택했다. CORE17의 canonical1164 token 및 5820 reference 비교에서 기존 승인16의 분석을 대조·유지했으며 추가 연구는 H318에 집중했다.

CAL의 עַד אָחֳרֵין 항목과 연결된 이집트 아람어 עַל אחרן의 TAD A4.3R.4 및 C1.1(Ahiqar).53 두 용례가 시간 표현 해석을 보강한다. 이는 기존 hold의 비교 아람어 근거 확보라는 재검토 조건에 해당한다. 동일 철자·전치사 결합의 독립 H318 용례나 직접 파생 증명으로 확대하지 않는다. 사용자는 이 근거에 따른 CodeX 추천을 최종 채택했다.

BDB의 어형·구문 의심과 다른 읽기, Rodrigue 2025 chapter3 §2.5(pp234–240)의 전승 분석을 보존했다. 해당 절만 읽었으며 BHS 장치·원사본 사진은 직접 열람하지 않았다. CAL과 학술서는 연구 참고이며 canonical occurrence source 또는 재배포용 DB corpus로 수입하지 않았다. H318 일반 한국어 부사에는 한자·고유명사 병기·붙임표 N/A다. 기존 승인 고유명사의 표기와 비고는 현행 한국어 표기 정책 및 관련 H268/H251 결정과 일치하게 유지했다.

## 채택하지 않은 주요 대안

- 마지막에: 가능한 한국어 대안이지만 같은 시간 부사구 기능을 마침내로 표현했다. 별도 sense로 늘리지 않았다.
- 마지막의, 최후의: 기반 끝 개념을 보여 주지만 현행 부사구의 기능을 직접 드러내지 못한다.
- 나중에·그 후: 번역과 비교 용례의 시간 연결을 보여 주나 마지막 도달을 더 느슨하게 표현한다.
- 다른: 대안 본문 독법이다. 현행 H318의 둘째 meaning이나 추가 H321 occurrence로 만들지 않았다.
- hold 유지: 가능하나 새 비교 근거를 토대로 현행 MT 의미 승인과 어원·본문 불확실성을 분리했다.
- H317 또는 H311 직접 파생 승인, H321 lexical variant 생성: 자료 간 원천 설명 및 본문 비교의 성격이 달라 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

현재 의미의 확신도는 중간이며 직접 파생·세부 어원은 낮다. 비교 자료의 전치사·철자는 다르고 אחרן 사본과 헬라어 전승의 역사적 관계는 미확정이다. 현행 MT 시간 기능을 반박하는 직접 원문·비교 용례·비평 장치 연구 또는 Strong 경계를 바꿀 근거가 확보되면 재검토한다. 단순 번역어 차이·표기 취향·같은 용례의 재집계만으로 자동 변경하지 않는다.

다른 CORE의 의미 배정 미해결4건(H268 잠29:11; H310 창16:13·느5:15·슥2:12 OSHB)은 기존 비고대로 보존한다. 이번 결정을 모든 본문 문제의 해결로 보고하지 않는다.

### 적용 검증

공식 dry-run·undo·원본 불변 및 적용기 테스트31개 통과 후 live apply1회. 전체 테이블·DDL 독립 대조에서 H318 meaning·비고와 history2행·관련 sequence 외 변경 없음. 관계·expression 및 비대상 데이터 불변, integrity ok·FK0·sidecar0·seed 불변이다. History group1793510494585349. Work SHA 33ad858047a43e64b483d6b64d21de5b1ea6c413a67e4411168e20f62a5d9b06 → 2ddb474aa9814e10ffc8d5b00610bfe4a228cbe69fe95dc2407b4a59da6fc3ce.

공식 progress3종 갱신: 승인825→826, hold7→6, 미승인13466·anomaly113 유지. H318 승인값과 기존 CORE16 exact 검증, ledger는 H318 제거 외 불변이다. UI·build N/A: 구현·UX 변경 없음.
