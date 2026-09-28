# H42 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-28
- 대상: H0042; H0001·H5278은 승인 합성 관계의 구성 요소
- 승인 manifest: [h42_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h42_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H42 word-level hold 없음
- 로컬 연구 산출물: `H0042_cluster_20260928_5acab444/00_cluster_summary.md`, `00_approved_content.md`, `H42_review.md`
- DB history group: `1790553731644648`

## 최종 결정

사용자는 “모두 승인하고 db반영과 git 작업까지 완료한다.”로 연구 추천안을 승인했다.

- H0042_0000 meaning: **아비노암·아비-노암 (인)**, seq 1, 단일 sense.
- 비고:

  > 바락의 아버지로 사사기 4–5장에 네 번 나온다. H0001(아버지)과 H5278(즐거움·아름다움·은총 계열)의 합성 이름이다. ‘아비노암’은 한국어 성경 관용 표기이고 ‘아비-노암’은 마소라 표기와 사전의 구성 분석을 드러내는 표기이다. 붙임표는 분석 기호이며 원문의 실제 구두점이나 특정 시대의 정확한 발음을 뜻하지 않는다. Strong은 이름을 ‘즐거움의 아버지’, 곧 ‘은혜로운’으로 풀이하지만, 참고 사전은 ‘나의 아버지는 은혜·기쁨이시다’로 풀이하므로 이름 전체의 문장적 해석은 하나로 확정하지 않는다.

|semantic 방향|relation id|category/type/status|저장 pair|direction_code|
|---|---|---|---|---|
|H0001 → H0042|7707|morphological / compound / asserted|H0001_0000, H0042_0000|w1_to_w2|
|H5278 → H0042|7708|morphological / compound / asserted|H0042_0000, H5278_0000|w2_to_w1|

두 관계의 note·description·relation_group_id는 NULL, source는 manifest의 pair별 식별자다. 기존 pair가 없어 교체·삭제하지 않았다.

H42 hold 없음. H42와 H5276·H0293·H5281 사이의 전이적 직접 관계 및 추정 Greek 관계는 생성하지 않는다. H1 기존 승인을 유지하며 CONTEXT/HUB-EXCLUDED의 meaning·note·hold·기존 관계를 변경하거나 재승인하지 않는다. Expression·발음·언어·schema·seed·원천 자료도 변경하지 않았다.

## 핵심 판단 근거

OSHB의 삿 4:6·4:12·5:1·5:12 네 용례 모두 바락의 아버지를 가리킨다. 각 절의 원문과 확보된 한국어·영어 참고자료를 전량 비교해 단일 인명 sense로 설명됨을 확인했다.

Canonical Strong은 H1과 H5278의 합성을 한정 없이 명시한다. 관용 표기 아비노암과 구성 경계를 드러내는 아비-노암을 한 meaning 안에 병기한다. 붙임표는 분석 기호이며 실제 마케프나 특정 시대 발음 재구가 아니다. Source-reference와 semantic 구성 방향을 구분해 두 관계의 방향을 저장했다.

H5278의 7회 용례를 이름 구성 문맥으로 전량 비교했다. 즐거움·아름다움·은총 문맥을 확인했으므로 이름 요소를 기쁨 하나로 축소하지 않았다. 사용자는 이 근거에 따른 추천을 채택했다.

## 채택하지 않은 주요 대안

- `아비노암 (인)` 유지: 인물 식별상 유효하지만 확인된 구성 경계를 드러내는 분석 표기를 함께 채택했다.
- `기쁨의 아버지` 등의 독립 meaning: 인명의 본문 기능과 어원 풀이를 혼동하므로 채택하지 않고 비고에 풀이 차이를 보존했다.
- H5276·H293·H5281과 H42의 직접 관계: 간접 파생이나 공통 구성 요소만으로 직접 관계를 만들지 않았다.
- H1 및 문맥 어휘의 새 meaning 승인: H42 승인에 필요한 범위가 아니므로 현행 상태를 유지했다.

## 남은 불확실성 및 재검토 조건

Strong의 ‘즐거움의 아버지/은혜로운’과 참고 사전의 ‘나의 아버지는 은혜·기쁨이시다’는 문장적 풀이 차이다. 하나의 역사적 작명 의도로 단정하지 않으며 인명 식별과 구성 요소 판단 자체를 뒤집지는 않는다.

LXXStp 네 절은 matched이고 αβινεεμ을 확인했으나 human-reference이며 upstream provenance/license 미검증 경계를 유지한다. 자동 Greek Strong·lemma·alignment 또는 음역 관계를 생성하지 않는다. Source x-pn/unresolved와 DB 히브리어 metadata 차이도 유지한다.

다른 인물·용례 또는 합성 구성을 뒤집는 신뢰할 수 있는 원자료가 나오면 재검토한다. 작은 발음 차이나 unrelated hub 가지 증가만으로 자동 hold하거나 재연구하지 않는다.

Discovery 45 nodes/44 edges, frontier 42, expanded 3, resume 0으로 graph closure는 미완료다. H1 생산적 hub 예외 아래 CORE H42 4/4회를 분석하고 CONTEXT 5개·HUB-EXCLUDED 39개를 구분했다. 이 결정은 다른 단어의 full semantic review 완료를 뜻하지 않는다.

## 적용 검증

- 공식 dry-run/live apply exit 0. Meaning 1·note 1·relation create 2, history 4행. Dry-run undo 성공, 원본 DB SHA 불변.
- Snapshot 및 result/독립 검증: `data/backups/approved_content_batch/20260928T000210845097Z/`.
- 전체 사용자 테이블 비교: WORD_TABLE·word_meaning_set 각 1행 교체, WORD_RELATION 2행·CHANGE_HISTORY 4행 추가만 확인. Schema DDL 동일, 승인 필드 exact 일치.
- Work SHA: `5acab4442be19539a36199842bf09ca5f7b051d2d4328d7a10aca2e88d3dab4f` → `112f7c58b1a5ff753c4f577551a503542db63c31e97a0122c2e8453c870f8246`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- Work·seed·snapshot integrity ok, FK 0, sidecar 없음.
- H42 explicit_approved. 승인 112→113, 미승인 14,184→14,183, hold 2·anomaly 113 유지.
- Progress snapshot identity: `e9b62aa26e4920ff2f23fd742d12a354824c215781c928b4af16cd0438567d19`.
- 승인 내용 SHA: `c3a6f77d574acac5271d011434b85ccd281c102ffe9f6a1cf0fd8855408c736c`.
- UI 테스트 N/A — UI 변경 없는 승인 데이터 slice. 수동 UI 테스트는 수행하지 않았다.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
