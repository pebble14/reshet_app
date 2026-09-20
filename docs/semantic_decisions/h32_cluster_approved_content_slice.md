# H32 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-20
- 대상: H0032; H0001·H2428은 합성 관계의 구성 요소
- 승인 manifest: [h32_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h32_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H0032 hold 없음
- 로컬 연구 산출물: `H0032_cluster_20260920_be51c0c4/00_cluster_summary.md`, H32 full Review·Packet·lexical relations
- 연구 문서 raw-byte SHA-256: `01277f617e21a0a6a2a6b156a21291c4205e5b003c3204dc132745061f46b41b`
- DB 적용 history group: `1789884646270777`

## 최종 결정

사용자는 연구 추천 내용과 DB·문서 반영을 승인했고, 적용 검증 후 커밋·병합·push도 승인했다.

- H0032 meaning: `아비하일·아비-하일 (인)` 한 행, seq 1, sense 1.
- H0032 비고:

  > 아비하일은 한국어 성경의 관용 표기이며, 아비-하일은 H0001(아버지)과 H2428(힘)의 구성 경계를 나타내는 분석 표기다. 히브리어 본문에는 ח를 쓰는 אֲבִיחַיִל 계열과 ה를 쓰는 אֲבִיהַיִל 계열이 함께 나타나며, 이 한글 표기는 두 자음의 음가 차이를 구별하지 않는다. 남성 3명과 여성 2명의 이름으로 쓰이며, 이름의 뜻은 ‘아버지는 힘’ 또는 ‘힘을 지닌 아버지’로 풀이된다. 대하 11:18의 가족관계 해석과 일부 LXX 구절의 이름 표기는 차이가 있으므로 동일 인물 관계나 별도 어휘 관계로 자동 확정하지 않는다.

- H0001→H0032: 신규 relation id `7687`, `morphological / compound / asserted`; 저장 pair `H0001_0000, H0032_0000`, direction `w1_to_w2`, source `RESHET-EC-H32-CLUSTER-H0001-H0032`.
- H2428→H0032: 신규 relation id `7688`, `morphological / compound / asserted`; 저장 pair `H0032_0000, H2428_0000`, direction `w2_to_w1`, source `RESHET-EC-H32-CLUSTER-H2428-H0032`.
- 두 관계의 note·description·relation_group_id는 NULL. 기존 H0032 관계가 없어 교체·삭제는 없다.
- H0032 hold 불필요. H0001 기존 승인 유지, H2428의 독립 meaning 및 다른 branch 상태 변경 없음. Expression·발음·schema·seed·hold ledger는 변경하지 않았다.

## 핵심 판단 근거

OSHB canonical occurrence 6/6과 각 절의 확보된 local reference를 전량 대조했다. 수리엘의 아버지, 아비술의 아내, 후리의 아들, 엘리압의 딸, 에스더의 아버지라는 남성 3명·여성 2명의 이름이다. 사람 수는 lexical sense 수와 다르며 모두 인명 하나의 meaning으로 설명된다.

한국어 성경 관용 표기 ‘아비하일’을 보존하고 canonical source의 `from H1 and H2428`이 뒷받침하는 구성 경계를 ‘아비-하일’로 병기했다. 분석 표기는 특정 시대 발음이나 실제 마케프를 주장하지 않는다. 관계 방향은 source-reference H32→구성 요소를 복사하지 않고 구성 요소→합성 이름으로 정했다.

Canonical source의 ‘힘을 지닌 아버지’ 풀이와 reference의 ‘아버지는 힘’ 계열 풀이를 하나로 강제하지 않는다. 인명 의미를 보존하고 이름의 구성·철자 차이·본문 해석 한계는 비고에 배치하는 추천안을 사용자가 채택했다.

## 채택하지 않은 주요 대안

- `아비하일 (인)`만 유지: 의미상 유효한 대안이나, 확인된 구성 경계를 함께 표시하는 추천안을 채택했다.
- 이름을 ‘나의 아버지는 강력하시다’라는 설명문 meaning으로 교체: 실제 용례의 인명 기능을 흐리므로 채택하지 않고 어원 풀이를 비고에 한정했다.
- 남녀 또는 다섯 인물별 sense 분리: 같은 이름의 대상 차이이므로 별도 lexical sense로 늘리지 않았다.
- ח/ה 철자 차이에 따른 별도 한국어 meaning: 한글 표기에서 구분되지 않는 자음 차이는 비고에 보존했다.
- LXX의 αβαιαν·αμιναδαβ를 다른 Strong과의 확정 관계로 생성: 해당 전승 표기만으로 identity·관계를 확정할 근거가 부족해 생성하지 않았다.

## 남은 불확실성 및 재검토 조건

Canonical metadata의 `x-pn/unresolved`와 `n-pr-m`을 원문대로 보존한다. 실제 여성 용례와 ח 4회/ה 2회의 철자 차이를 없애지 않는다. 대하 11:18은 마할랏의 어머니 또는 르호보암의 아내라는 구문 해석 차이가 있지만 인명 meaning을 뒤집지는 않는다.

LXX human reference는 6개 explicit verse를 확인했으나 upstream provenance·license는 unverified이다. 에스더 두 절의 αμιναδαβ와 대하의 αβαιαν을 자동 Hebrew–Greek alignment 또는 Strong 대응으로 승격하지 않는다. HebGrkKo의 ‘외숙’도 모계 친족 관계로 확정하지 않았다.

Raw discovery는 51 node/50 edge, frontier 48의 미완료 상태다. H1·H2428 생산적 hub에 예외를 적용해 CORE H32를 전량 분석했으며 전체 graph closure를 완료했다고 주장하지 않는다. H1·H2428의 full Review 확보와 독립 sense 전량 분석은 구분한다.

새 원문·본문비평 근거가 인명 식별이나 H1·H2428 구성 자체를 실질적으로 바꾸면 관련 부분을 재검토한다. 이미 기록한 작은 표기·어원 풀이 차이나 새로운 hub branch만으로 자동 재검토하거나 hold하지 않는다.

## 적용 검증

- 공식 dry-run exit 0: meaning 1·note 1·relation create 2, history 4행, undo 성공, 원본 DB 불변.
- 공식 apply exit 0: work SHA `be51c0c430804b5827f1771383633961192b822c14dbb9bfdabfa15e68f02388` → `5adbfabff24214f2238d6c106cb9c89e644622be19339647d63769e5db3efae8`.
- seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- snapshot: `data/backups/approved_content_batch/20260920T061045447061Z/snapshot.db`.
- Snapshot과 최종 DB의 schema 및 전체 사용자 테이블을 독립 비교: WORD_TABLE 1행·word_meaning_set 1행 변경, WORD_RELATION 2행·CHANGE_HISTORY 4행 추가 외 차이 없음. History는 word update 2·relation create 2, undone_at 모두 NULL.
- Manifest와 최종 meaning 순서·비고·관계 pair/category/type/status/direction/source/NULL metadata exact 일치, 중복 없음. Work·seed·snapshot integrity ok, FK 0, sidecar 없음.
- H0032 `explicit_approved / approved`. 전체 승인 100→101, 미승인 14,196→14,195, hold 2·anomaly 113 유지. Snapshot identity `60b1c7781dfc77556bfce061400770991c793ddc68457d6060fa51edd505964d`. 이는 적용 시점 derivative이다.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 통과. 앱 코드·UI 변경 없음; Flutter UI·사용자 수동 UI 테스트 N/A.
