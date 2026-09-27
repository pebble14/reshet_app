# H41 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-27
- 대상: H0041; H0001·H5068은 승인 합성 관계의 구성 요소
- 승인 manifest: [h41_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h41_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H41 word-level hold 없음
- 로컬 연구 산출물: `H0041_cluster_20260927_d1710e4e/00_cluster_summary.md`, `00_approved_content.md`, `H41_review.md`
- DB history group: `1790506379385621`

## 최종 결정

사용자는 “추천안대로 DB 반영 및 Git 완료까지 진행”으로 아래 내용을 승인했다.

- H0041_0000 meaning: **아비나답·아비-나다브 (인)**, seq 1, 단일 sense.
- 비고:

  > 아비나답은 한국어 성경의 관용 표기이고, 아비-나다브는 אֲבִינָדָב의 아비와 나다브 구성을 드러내는 원문 기반 분석 표기이다. 붙임표는 분석 기호이며 원문의 구두점이나 특정 시대의 정확한 발음을 뜻하지 않는다. H0001(아버지)과 H5068(기꺼이 하다)에서 유래한 이름으로, Strong은 ‘관대함의 아버지’, 한국어 사전 참고자료는 ‘나의 아버지는 고귀하다’로 풀이한다. 궤를 보관한 집의 주인, 이새의 아들, 사울의 아들에게 쓰인다. 왕상 4:11의 벤아비나답은 H1125로 별도 집계하며, 그 아버지를 이새의 아들과 동일인으로 단정하지 않는다.

|semantic 방향|relation id|category/type/status|저장 pair|direction_code|
|---|---|---|---|---|
|H0001 → H0041|7705|morphological / compound / asserted|H0001_0000, H0041_0000|w1_to_w2|
|H5068 → H0041|7706|morphological / compound / asserted|H0041_0000, H5068_0000|w2_to_w1|

두 관계의 note·description·relation_group_id는 NULL, source는 manifest의 pair별 batch 식별자다. 기존 pair가 없어 교체·삭제하지 않았다.

H41 hold 없음. H41 → H1125 생성 보류를 유지하고 H41–H3440 및 추정 LXX/Greek 관계는 생성하지 않았다. H1/H1125 기존 승인을 유지하고 H5068과 HUB-EXCLUDED 단어의 meaning·note·hold는 변경하지 않았다. Expression·발음·언어·schema·seed·원천 자료도 변경하지 않았다.

## 핵심 판단 근거

OSHB 12회/11절 전체는 인명 용법이다. 궤를 보관한 집의 주인 5회, 이새의 아들 3회, 사울의 아들 4회를 동일 이름이라는 한 lexical sense로 포괄한다. 동명이인을 같은 인물로 합친다는 뜻은 아니다. 개역개정·개역한글·새번역의 관용 표기와 원전분해·lexicon의 아비나다브 표기를 비교했다.

Canonical Strong은 H0001과 H5068에서 유래한다고 명시하며 probably/perhaps 한정이 없다. 아비-나다브는 이 경계를 보여 주는 분석 표기이고 실제 원문 마케프나 특정 시대 발음을 재구한 표기가 아니다. H1125의 최신 승인 `벤-아비-나다브`와도 일관된다. Source-reference H41 → 구성 요소와 semantic 구성 요소 → H41 방향을 구분했다.

사용자는 이 evidence-backed 추천안을 채택했다. 이름의 어원 문장 해석은 인명 meaning으로 올리지 않고 비고에 보존했다.

## 채택하지 않은 주요 대안

- `아비나답 (인)` 유지: 12회 전체를 설명하는 유효한 대안이지만 확인된 원문 구성을 보여 주기 위해 분석 표기를 함께 승인했다.
- `아비나다브 (인)` 단독: 로컬 음역 근거는 있지만 한국어 성경 관용명을 보존하지 못하므로 단독 채택하지 않았다.
- `관대함의 아버지` 또는 `나의 아버지는 고귀하다`를 독립 meaning으로 추가: 인명 용법과 어원 풀이를 구분하고 비고에 보존했다.
- 인물별 세 sense 분리: 동명이인이라는 차이가 이름의 독립 lexical sense를 요구하지 않는다.
- H41 → H1125 생성: 구성 근거는 있으나 H1125 canonical source의 H40 참조 충돌이 남아 [기존 결정](h40_cluster_approved_content_slice.md)의 보류를 유지했다.
- H41–H3440 별명 관계: KJV의 Ishui 주석만으로 인물 동일성이나 lexical variant를 확정하지 않았다.

## 남은 불확실성 및 재검토 조건

Strong의 ‘네 이스라엘인’, HebGrkKo의 ‘13회’, 현행 OSHB 12회/세 인물 문맥은 구분한다. 왕상4:11은 H1125로 별도 집계되며 부칭의 아버지를 이새의 아들과 동일인으로 확정하지 않는다. ‘13회’의 원인을 추정으로 단정하지 않는다. 어원 문장 풀이 차이는 인명과 구성 요소 자체를 뒤집지 않는다.

LXXStp는 11개 명시적 절 조회 중 10 matched·1 unmatched다. 삼상17:13 unmatched, 삼하6:4는 row가 있지만 이름이 없다. Human-reference이며 upstream provenance/license 미확인, 자동 alignment 금지 경계를 유지했다. 다른 이름과의 Greek 표기 유사만으로 관계를 생성하지 않는다.

H1125의 source 정정 또는 별도 근거를 채택하는 새로운 사용자 결정이 있을 때 H41 관계를 재검토한다. 새 본문비평 근거가 인물 식별을 바꿀 때 관련 비고/관계를 재검토할 수 있다. 단순 복제 사이트나 unrelated hub 가지 증가만으로 자동 재연구하지 않는다. x-pn/unresolved와 DB 히브리어의 차이는 이번 의미 승인으로 변경하지 않았다.

Discovery 52 nodes/51 edges, frontier 49, expanded 3, resume 0으로 graph closure 미완료다. H1/H5068 허브 예외 아래 CORE H41 전체 12회를 분석했으며 CONTEXT 2개·HUB-EXCLUDED 49개를 구분했다. 이 기록은 제외 단어의 semantic 완료를 선언하지 않는다.

## 적용 검증

- 공식 dry-run/live apply exit 0. Meaning 1·note 1·relation create 2, active history 4행. Dry-run undo 성공, 원본 SHA 불변.
- Snapshot: `data/backups/approved_content_batch/20260927T105258568895Z/snapshot.db`; `result.json`, `independent_verification.json`에 적용 및 독립 SQL 검증 보존.
- 전후 schema 동일. 전체 사용자 테이블 비교에서 WORD_TABLE 1행·word_meaning_set 1행 교체, WORD_RELATION 2행·CHANGE_HISTORY 4행 추가만 확인했다.
- Work SHA: `d1710e4e0cb10de5c3cb363b7a3521290d97e6308abb1cb3bd462e89f9c7ccc4` → `5acab4442be19539a36199842bf09ca5f7b051d2d4328d7a10aca2e88d3dab4f`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- Work·seed·snapshot integrity ok, FK 위반 0, sidecar 없음. Manifest와 최종 meaning·note·관계 필드 exact 일치.
- H41 explicit_approved. 승인 111→112, 미승인 14,185→14,184, hold 2·anomaly 113 유지.
- Progress snapshot identity: `5e7f5c409a3529ce1404ab084b100638227adb72336609198acb1ca2874751f3`.
- 승인 내용 artifact SHA: `c9cf8669172b1b2e9c75cd30e27539d644293617f315037affe2eee6cbcf3c4b`.
- UI 테스트 N/A — UI 변경 없는 승인 데이터 slice. 수동 UI 테스트를 수행하지 않았다.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
