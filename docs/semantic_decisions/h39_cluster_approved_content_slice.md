# H39 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-24
- 대상: H0039; H0001은 합성 관계 구성 요소
- 승인 manifest: [h39_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h39_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H0039 hold 없음
- 로컬 연구 산출물: `H0039_cluster_20260924_47a6f2a8/00_cluster_summary.md`, `H39_review.md`, `H39_evidence_packet.json`, `H39_lexical_relations.json`
- 연구 summary raw-byte SHA-256: `85e88e329620392b3ceb8453208725840143836e03e7468ec8242faab6786fb5`
- DB history group: `1790203611119728`

## 최종 결정

사용자는 추천 내용과 DB 반영 및 Git 완료를 승인했다.

- H0039 meaning: `아비마엘·아비-마엘 (인)`, seq 1, 단일 sense.
- H0039 비고:

  > 욕단의 아들로 족보에 나오는 이름(창 10:28; 대상 1:22). ‘아비마엘’은 한국어 성경의 관용 표기이고, ‘아비-마엘’은 Strong이 제시한 H0001(아버지)과 마엘 요소의 구성 경계를 드러내는 분석 표기다. 마엘의 뜻과 기원은 확정하기 어렵다. Strong은 아마 외래어인 미확인 요소로 설명하며 ‘마엘의 아버지’로 풀이하고, HebGrkKo는 ‘나의 아버지는 하나님이시다’로 풀이한다. 후자의 풀이만으로 H0410(엘)과의 합성 관계를 확정하지 않는다.

- H0001 → H0039: 신규 id `7701`, `morphological / compound / asserted`, pair `H0001_0000, H0039_0000`, direction `w1_to_w2`, source `RESHET-EC-H39-CLUSTER-H0001-H0039`.
- 관계 note·description·relation_group_id는 NULL. 기존 pair가 없어 교체·삭제 없음.
- H0410 및 미확인 마엘 요소와의 관계는 생성하지 않음.
- H0039 hold 불필요. H1 기존 승인 및 다른 Strong 상태 유지. Expression·발음·언어·schema·seed·hold ledger 변경 없음.

## 핵심 판단 근거

OSHB 창 10:28과 대상 1:22의 2/2 occurrence는 모두 욕단의 아들을 열거한 족보의 동일 이름이다. 두 용례와 주변 족보 문맥, HebGrkKo exact row, 개역개정·개역한글·KJV·새번역·원전분해 두 절을 전량 비교했다. 단일 인명 sense의 미분류·모호한 용례·반례는 0이었다.

관용명 아비마엘을 보존하고 canonical Strong의 H1과 다른 요소의 결합 설명에 따라 아비-마엘을 병기했다. 붙임표는 분석 경계이며 마케프나 특정 시대의 실제 음가 재구가 아니다. H1 구성요소에 대한 명시적 from과 미확인 후반 요소에 대한 probably foreign / apparently를 구분했다. H1 → H39 관계 승인은 이름 전체의 어원 번역까지 확정하는 것이 아니다. 사용자는 이 추천을 채택했다.

## 채택하지 않은 주요 대안

- `아비마엘 (인)`만 유지: 정확한 관용명이며 유효한 대안이지만, 구성 경계를 함께 보여 주는 병기안을 선택했다.
- `나의 아버지는 하나님이시다` 또는 `마엘의 아버지`를 meaning으로 저장: 어원 해석과 실제 고유명 용법을 구분하여 비고에만 남겼다.
- H410(엘) 합성 관계 생성: HebGrkKo의 하나님 풀이와 canonical source가 다르며 H39 entry에 H410 직접 참조가 없다. 관계 비생성은 영구적 반증 판정이 아니다.
- 종족·지명을 별도 sense로 추가: 족보의 인명 기능과 구분되는 직접 용례 근거가 부족하다.

## 남은 불확실성 및 재검토 조건

마엘의 정확한 뜻·언어·집단 동정은 미해결이다. Source의 x-pn/unresolved와 DB 히브리어, pronunciation_notation=unknown은 별도 metadata이며 이번 내용 승인으로 변경하지 않았다.

LXX Human Reference는 창 10:28에서 αβιμεηλ을 확인했으나 대상 1:22는 미매칭이었다. Upstream provenance·license 미확인 경계를 유지하며 Greek Strong/lemma 또는 NT 연결을 생성하지 않았다.

Raw discovery는 42 nodes/41 edges, frontier 39, resume 0으로 closure 미완료다. H1 생산적 인명 hub 예외를 적용해 CORE H39, graph CONTEXT H1, HUB-EXCLUDED 40개를 구분했고 H410은 경쟁 해석 확인용 보충 context로 확인했다. H1·H410 전체 occurrence를 재검토했다고 주장하지 않는다.

신뢰할 만한 전문 어원 근거가 마엘 또는 H410 연결을 입증하거나 다른 lexical sense의 직접 반례가 생기면 재검토한다. 이미 기록한 불확실성, 번역 표현 차이 또는 단순 hub 가지 추가만으로 자동 hold·재연구하지 않는다.

## 적용 검증

- 공식 dry-run/apply exit 0. Meaning 1·note 1·relation create 1, active history 3행. Dry-run undo 성공, 원본 DB SHA 불변.
- Work SHA: `47a6f2a858734def654245708a35e87bba2ae622cfd935f80319a24afd148b25` → `5c915348421d589674dc35243d4b3c7cb3c7fe6b5b97b7464c369d8a65a6f571`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- Snapshot: `data/backups/approved_content_batch/20260923T224650308417Z/snapshot.db`; 같은 폴더 result.json과 independent_verification.json에 적용 및 독립 검증 보존.
- Snapshot과 현재 DB의 schema 및 전체 사용자 테이블 대조: WORD_TABLE 1행·word_meaning_set 1행 교체, WORD_RELATION 1행·CHANGE_HISTORY 3행 추가 외 차이 없음. 승인 meaning·비고·관계 필드 exact 일치, H39 관계는 승인한 1개뿐이며 history undone_at NULL.
- Work·seed·snapshot integrity ok, FK 0, work·seed sidecar 없음.
- H0039 explicit_approved. 승인 108→109, 미승인 14,188→14,187, hold 2·anomaly 113 유지. 승인율 약 0.7623%.
- Progress snapshot identity: `249f6fb69773c33d3e1a5c1ae780e964119ce029c42ca0994a58190495dda3cb`.
- Targeted approved_content_batch_service_test.dart 29건 통과.
- Flutter UI·사용자 수동 UI 테스트 N/A — UI 변경 없는 승인 데이터 slice.
