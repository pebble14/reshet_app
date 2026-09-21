# H36 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-22
- 대상: H0036; H0001·H2898은 합성 관계 구성 요소
- 승인 manifest: [h36_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h36_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H0036 hold 없음
- 로컬 연구 산출물: `H0036_cluster_20260921_62cad49b/00_cluster_summary.md` 및 H0036 full Review·Packet·lexical relations
- 연구 summary raw-byte SHA-256: `d5e868b50ac3e082a931dc61c33a40696191ab339969ffe57548fe72659c2ed6`
- DB history group: `1790004038806277`

## 최종 결정

사용자는 연구 제안 내용 모두와 DB/Git 작업을 승인했다.

- H0036 meaning: `아비둡·아비-투브 (인)`, seq 1, 단일 sense.
- H0036 비고:

  > 베냐민 지파의 사하라임이 후심에게서 낳은 아들로, 역대상 8:11에 한 번 나온다. 아비둡은 한국어 성경의 관용 표기이며, 아비-투브는 אֲבִי와 טוּב의 구성을 드러내는 분석 표기다. 붙임표는 원문의 구두점이 아니며 특정 시대의 실제 발음을 확정한 것도 아니다. Strong은 H0001과 H2898의 합성으로 설명하고, 이름을 선함의 아버지로 풀이한다. 나의 아버지는 선하시다라는 풀이도 있으나, 이는 이름의 어원 설명이며 별도 어휘 의미로 나누지 않는다.

- H0001→H0036: 신규 id `7695`, `morphological / compound / asserted`, pair `H0001_0000, H0036_0000`, direction `w1_to_w2`, source `RESHET-EC-H36-CLUSTER-H0001-H0036`.
- H2898→H0036: 신규 id `7696`, `morphological / compound / asserted`, pair `H0036_0000, H2898_0000`, direction `w2_to_w1`, source `RESHET-EC-H36-CLUSTER-H2898-H0036`.
- 두 관계의 note·description·relation_group_id는 NULL. 기존 관계가 없어 교체·삭제 없음.
- H0036 hold 불필요. H1 기존 승인 유지. H2898·H2895·H0285 및 제외 branch의 독립 의미·관계 변경 없음. Expression·발음·언어·schema·seed·hold ledger 변경 없음.

## 핵심 판단 근거

OSHB 역대상 8:11의 1/1 occurrence와 확보된 로컬 참고자료 6종을 전량 대조했다. 사하라임이 후심에게서 낳은 아들의 이름이며 엘바알과 병렬되는 고유명사다. 단일 인명 sense를 뒤집는 반례는 없었다.

한국어 성경 관용명 아비둡을 유지하면서 canonical의 `from 1 and 2898` 및 참고 음역 아비투브/투브가 뒷받침하는 구성 경계를 아비-투브로 병기했다. 분석적 붙임표는 원문 마케프나 특정 시대의 실제 발음을 뜻하지 않는다. Source-reference H36→구성 요소와 의미 방향 구성 요소→H36을 구별하여 합성 관계 두 건을 채택했다.

사용자는 이 추천안을 최종 채택했다. 이름의 어원 문장 풀이와 인명 meaning을 구분하고, 어원 설명의 차이와 분석 표기의 한계를 비고에 보존했다.

## 채택하지 않은 주요 대안

- `아비둡 (인)`만 유지: 유효한 관용명이지만 확인된 합성 경계를 병기하는 안을 채택했다.
- `아비투브 (인)`만 사용: 관용명을 누락하므로 우선하지 않았다.
- ‘선함의 아버지’ 또는 ‘나의 아버지는 선하시다’를 별도 meaning으로 입력: 실제 인명 기능을 대신하거나 어원 설명을 sense로 승격하므로 비고에 한정했다.
- H0285 아히둡을 H0036의 변이형으로 연결: 두 번째 구성 요소만 공유하고 첫 요소와 인물 전승이 달라 생성하지 않았다.

## 남은 불확실성 및 재검토 조건

Canonical `x-pn/unresolved`와 DB 히브리어/OSHB HNp를 구분한다. 언어 metadata 불일치를 임의 변경하지 않았다. Strong의 father of goodness와 참고 사전의 my father is goodness는 동일한 문장 풀이가 아니지만 구성 요소는 일치한다. 이름으로 해당 인물의 성품·명명 동기를 확정하지 않는다.

LXX 대상 8:11의 αβιτωβ는 human reference에서 확인했지만 upstream provenance·license는 unverified이다. 자동 Greek Strong 대응이나 관계를 만들지 않는다.

Raw discovery는 44 node/43 edge, frontier 41로 closure 미완료다. CORE H36은 전량 검토했으며 H1 생산적 hub에 예외를 적용했다. CONTEXT 4개와 제외 39개를 보존했고, H1의 1,213건 full Review 생성과 전량 sense 재분류는 구별했다. H2898은 32건 문맥을 확인했으나 한국어 reference 2건은 절 번호 차이로 manual_review_required를 보존했다.

인명 식별·합성 경계에 실질적 반례가 생기거나 사용자 표기 정책이 바뀔 때 재검토한다. 이미 기록한 작은 표기·어원 해석 차이나 추가 hub branch만으로 자동 hold하지 않는다.

## 적용 검증

- 공식 dry-run/apply 모두 exit 0. Meaning 1·note 1·relation create 2, history 4행. Dry-run undo 성공, 원본 SHA 불변.
- Work SHA: `62cad49bbca797c9ed22ba0cebb50a94ec5ac9184f144e38d18b2174364a19ea` → `e55c30fa055e3981ba1d0a9642fe0f5a3888516b89854262be59728af08866f4`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- Snapshot: `data/backups/approved_content_batch/20260921T152037973494Z/snapshot.db`; 같은 폴더 `result.json`에 applicator 결과 보존. 폴더 시각은 UTC, 결정일은 한국시간이다.
- Snapshot/최종 DB의 schema 및 전체 사용자 테이블 독립 비교: WORD_TABLE 1행·word_meaning_set 1행 변경, WORD_RELATION 2행·CHANGE_HISTORY 4행 추가 외 차이 없음. Manifest의 meaning 순서·note·관계 pair/type/category/status/direction/source/NULL metadata exact 일치, 중복 없음. History undone_at 모두 NULL.
- Integrity ok, FK 0. H0036 explicit_approved/approved. 전체 승인 105→106, 미승인 14,191→14,190, hold 2·anomaly 113 유지. Progress snapshot `7fe90921f94a5b7b0f280fc5cf44252a6787e0ce6514a6b316667545470c8d4b`.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 통과. 앱 UI 코드 변경 없음, UI 테스트 N/A.
