# H37 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-22
- 대상: H0037; H0001·H2919는 합성 관계 구성 요소
- 승인 manifest: [h37_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h37_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H0037 hold 없음
- 로컬 연구 산출물: `H0037_cluster_20260922_e55c30fa/00_cluster_summary.md`, `H37_review.md`, `H37_evidence_packet.json`, `H37_lexical_relations.json`
- 연구 summary raw-byte SHA-256: `e456deae31285f261199e8179ece2b5783d4af0ceca626f4a96e139c69a4be39`
- DB history group: `1790032500613835`

## 최종 결정

사용자는 Codex 추천 내용과 DB·Git 실행을 승인했다.

- H0037 meaning: `아비달·아비-탈 (인)`, seq 1, 단일 sense.
- H0037 비고:

  > 다윗의 아내이며 스바댜의 어머니로, 사무엘하 3:4와 역대상 3:3에 나온다. 아비달은 한국어 성경의 관용 표기이고, 아비-탈은 히브리어 이름의 아비(H0001, 아버지)와 탈(H2919, 이슬) 구성을 보여 주는 분석 표기다. 붙임표는 원문의 구두점이나 특정 시대의 실제 발음을 뜻하지 않는다. 이름의 풀이는 자료에 따라 이슬의 아버지 또는 나의 아버지는 이슬이다로 달라지므로 하나로 확정하지 않는다.

- H0001→H0037: 신규 id `7697`, `morphological / compound / asserted`, pair `H0001_0000, H0037_0000`, direction `w1_to_w2`, source `RESHET-EC-H37-CLUSTER-H0001-H0037`.
- H2919→H0037: 신규 id `7698`, `morphological / compound / asserted`, pair `H0037_0000, H2919_0000`, direction `w2_to_w1`, source `RESHET-EC-H37-CLUSTER-H2919-H0037`.
- 두 관계의 note·description·relation_group_id는 NULL. 기존 관계가 없어 교체·삭제 없음.
- H0037 hold 없음. H0001 기존 승인 유지. CONTEXT·HUB-EXCLUDED 단어의 독립 의미·비고·관계는 변경하지 않았다. Expression·발음·언어·schema·seed·hold ledger도 변경하지 않았다.

## 핵심 판단 근거

OSHB 사무엘하 3:4와 역대상 3:3의 2/2 occurrence는 다윗의 아들 스바댜의 모친인 동일한 아비달을 가리킨다. 확보된 로컬 참고자료 6종을 두 용례 전체와 대조했고 단일 인명 sense의 반례는 없었다. 전치사 및 ‘소생’ 구문은 별도 어휘 의미가 아니다.

한국어 성경 관용명 아비달을 보존하면서 canonical source의 명시적 `from H1 and H2919`와 참고 음역 아비탈을 근거로 아비-탈을 분석 표기로 병기했다. 두 표기는 같은 인명 sense다. Source-reference H37→구성 요소와 semantic 구성 요소→H37을 구분하여 두 합성 관계를 채택했다. 사용자는 이 추천안을 최종 선택했다.

이름 전체의 어원 문장 해석은 인명 meaning과 구분했다. Strong의 father of dew와 참고 자료의 my father is dew를 하나로 확정하지 않고, 분석적 붙임표와 발음의 한계를 비고에 보존했다.

## 채택하지 않은 주요 대안

- `아비달 (인)`만 유지: 유효한 관용명이지만 확인된 합성 구조를 함께 보여 주는 병기안을 채택했다.
- `아비달·아비탈 (인)`: 가능한 표기이나 확인된 구성 경계를 드러내는 아비-탈을 우선했다.
- ‘이슬의 아버지’ 또는 ‘나의 아버지는 이슬이다’를 독립 meaning으로 입력: 인명 기능을 어원 풀이로 대체하므로 비고의 자료 차이로 보존했다.
- ‘보호의 근원’ 또는 ‘신선한’을 독립 의미로 추가: 참고 사전의 해석 및 Strong의 괄호 풀이이며 실제 두 용례의 독립 sense 근거가 없어 채택하지 않았다.
- H2537을 H0037의 변이형·동일 인명으로 연결: 이슬 요소만 공유하는 다른 합성 인명이므로 승인하지 않았다.

## 남은 불확실성 및 재검토 조건

Canonical `x-pn/source_language_unresolved`와 DB 히브리어 및 OSHB HNp를 구분한다. 언어 metadata를 임의 수정하지 않았다. 아비-탈은 원문과 구성에 근거한 분석 표기이며 특정 시대의 정확한 실제 발음을 확정하지 않는다. 이름 전체의 구문적 풀이 차이는 인명 식별과 구성 관계를 뒤집지 않는다.

LXX 두 구절의 αβιταλ은 human reference로 확인했지만 upstream provenance·license는 unverified다. 자동 Greek Strong 대응이나 관계를 생성하지 않았다.

Raw discovery는 45 nodes/44 edges, frontier 42로 closure 미완료다. H0001 인명 생성 허브에 예외를 적용하여 CORE H37 전량 검토, CONTEXT 5개, HUB-EXCLUDED 39개를 구분했다. H2919의 31 token 문맥은 비교했으나 한국어 자료 등의 2건 reference conflict는 manual_review_required로 보존했다. CONTEXT 검토를 독립 meaning 승인으로 확대하지 않는다.

다른 인물 식별이나 합성 경계의 실질적 반례, 이름 구문을 판별하는 전문 근거 또는 사용자의 표기 정책 변경이 있을 때 재검토한다. 이미 명시한 작은 어원 풀이·표기 차이나 추가 허브 연결만으로 자동 hold하지 않는다.

## 적용 검증

- 공식 dry-run/apply exit 0. Meaning 1·note 1·relation create 2, history 4행. Dry-run undo 성공, 원본 DB SHA 불변.
- Work SHA: `e55c30fa055e3981ba1d0a9642fe0f5a3888516b89854262be59728af08866f4` → `838d80faa317b5c286ad5394c685041f02deb8fe07fd5eb00fd171b8360bafc8`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- Snapshot: `data/backups/approved_content_batch/20260921T231459786415Z/snapshot.db`; 같은 폴더 `result.json`에 결과 보존. 폴더 시각은 UTC다.
- Snapshot/적용 DB의 schema와 전체 사용자 테이블을 독립 비교했다. WORD_TABLE 1행·word_meaning_set 1행 변경, WORD_RELATION 2행·CHANGE_HISTORY 4행 추가 외 차이 없음. Meaning 순서·비고·relation 모든 manifest 필드 exact 일치, pair 중복 없음, history undone_at NULL.
- Integrity ok, FK 0, sidecar 없음. H0037 explicit_approved/approved. 전체 승인 106→107, 미승인 14,190→14,189, hold 2·anomaly 113 유지.
- Progress snapshot: `17bb029a8ce6880aa580e6ef70748419ca358ee52829b4bc8fed9267017b55a3`.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 통과. UI 테스트 N/A — 앱 UI 변경 없는 승인 데이터 slice.
