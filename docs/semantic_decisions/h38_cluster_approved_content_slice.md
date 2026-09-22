# H38 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-23
- 대상: H0038; H0001·H3220은 합성 관계 구성 요소
- 승인 manifest: [h38_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h38_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H0038 hold 없음
- 로컬 연구 산출물: `H0038_cluster_20260923_838d80fa/00_cluster_summary.md`, `H0038_review.md`, `H0038_evidence_packet.json`, `H0038_lexical_relations.json`
- 연구 summary raw-byte SHA-256: `278e4e76856f5f85dc60fa7df02511931647dcf342215eaabace4d034a1a47a2`
- DB history group: `1790119496601845`

## 최종 결정

사용자는 추천 5가지 모두와 DB 반영 및 Git 완료를 승인했다.

- H0038 meaning: `아비얌·아비-얌 (인)`, seq 1, 단일 sense.
- H0038 비고:

  > 르호보암의 아들이며 아사의 아버지인 유다 왕으로, 역대기의 아비야(H0029)와 같은 인물이다. ‘아비얌’은 개역 계열의 관용 표기이고 ‘아비-얌’은 Strong이 제시한 H0001·H3220 구성 경계를 드러내는 분석 표기이며, 실제 마케프나 특정 시대의 발음을 재현한 표기는 아니다. Strong의 ‘바다의 아버지(뱃사람)’ 풀이는 이름의 어원 설명이므로 별도 meaning으로 삼지 않는다. 새번역은 해당 네 절에서 ‘아비야’를 쓰고 각주에 히브리어 ‘아비얌’을 남긴다. 두 이름 형태가 생긴 역사적 원인은 확정하지 않는다.

- H0001→H0038: 신규 id `7699`, `morphological / compound / asserted`, pair `H0001_0000, H0038_0000`, direction `w1_to_w2`, source `RESHET-EC-H38-CLUSTER-H0001-H0038`.
- H3220→H0038: 신규 id `7700`, `morphological / compound / asserted`, pair `H0038_0000, H3220_0000`, direction `w2_to_w1`, source `RESHET-EC-H38-CLUSTER-H3220-H0038`.
- 두 관계의 note·description·relation_group_id는 NULL. 기존 pair가 없어 교체·삭제 없음.
- H0029–H0038, H8043–H0038 관계는 생성하지 않음. H0029와 같은 왕이라는 설명은 H0038 비고로 보존.
- H0038 hold 없음. H0001·H0029 기존 승인 유지. 다른 Strong의 독립 meaning·note·relation, expression·발음·언어·schema·seed·hold ledger는 변경하지 않음.

## 핵심 판단 근거

OSHB의 왕상 14:31, 15:1, 15:7 두 token, 15:8은 모두 르호보암의 아들이자 아사의 아버지인 같은 유다 왕을 가리킨다. 5/5 occurrence를 전량 검토했고 한 인명 sense의 미분류·모호한 용례·반례는 0이었다. 개역개정·개역한글·KJV·원전분해의 네 절과 다섯 이름 표현, 새번역의 네 절과 각주, HebGrkKo exact row를 모두 비교했다.

관용명 아비얌을 보존하고 canonical source의 명시적 `from H1 and H3220`에 따라 분석 표기 아비-얌을 병기했다. 하이픈은 구성 경계를 표시하며 실제 마케프나 시대별 발음 재구가 아니다. 인명에 근거 없는 한자는 붙이지 않는다. Source-reference H38→구성 요소와 semantic 구성 요소→H38을 구별해 합성 관계 두 건을 채택했다. 사용자는 이 추천을 최종 선택했다.

새번역은 네 절에서 아비야를 사용하고 각주에 히브리어 아비얌을 남긴다. 대상 3:10·대하 12:16·13:1과의 계승·즉위 문맥 대조도 같은 왕임을 뒷받침한다. 그러나 H0029에는 다른 인물들도 있으므로 두 Strong을 포괄적으로 등치하거나 역사적 이름 변화 방향을 확정하지 않고 비고로 설명한다.

## 채택하지 않은 주요 대안

- `아비얌 (인)`만 유지: 유효한 관용명이지만 확인된 합성 경계를 함께 보이는 병기안을 선택했다.
- H38 meaning에 아비야 추가: 같은 왕의 식별에는 도움이 되지만 H29의 여러 인물과 H38 표제어의 구별을 위해 비고에 보존했다.
- 바다의 아버지·뱃사람을 독립 meaning으로 추가: Strong의 어원 풀이이며 실제 다섯 용례는 인명이다. 별도 sense로 채택하지 않았다.
- HebGrkKo의 빛의 아버지 풀이: 확보된 canonical 구성 근거가 없어 채택하지 않았다.
- H0029–H0038을 `morphological / variant / hypothesized / undirected`로 생성: 가능한 연구 대안이지만 사용자는 이번에 관계 비생성과 비고 보존을 승인했다. 영구적 반증 판정은 아니다.
- H8043–H0038 파생 관계 생성: `for H8039 (compare H38)`의 약한 비교 참조이며, H8043은 미글롯의 아들인 별도 인물이다. 직접 파생·공통 어근·동일 인물 근거로 승격하지 않았다.

## 남은 불확실성 및 재검토 조건

Canonical `x-pn / source_language_unresolved`를 DB 히브리어 및 OSHB HNp와 구별한다. 이름 야/얌 차이의 역사적 원인을 종교적 개명이나 필사 오류로 단정하지 않는다. 비판본 apparatus와 사본 전수 검토는 이번 확보 자료 범위 밖이다.

명시적으로 조회한 LXX 네 절의 αβιου는 human reference이며 upstream provenance·license는 미확인이다. Local reference의 hash 일치도 판본 authority 검증을 의미하지 않는다. 자동 Greek lemma/Strong 대응 관계는 생성하지 않았다.

Raw discovery는 46 nodes/46 edges, frontier 42, resume 0으로 closure 미완료다. H1 생산적 인명 허브와 약한 비교 chain에 예외를 적용해 CORE 1·CONTEXT 4·HUB-EXCLUDED 41을 구분했다. CORE evidence 전량 검토와 CONTEXT 관련 근거 확인을 구분하며 H1·H3220 등의 독립 의미 전량 재심사를 주장하지 않는다.

다른 지시 대상·lexical sense의 반례, H1+H3220 구성을 바꾸는 신뢰할 만한 이름 연구, 두 형태의 발생을 판별하는 본문비평 근거, 사용자의 표기 정책 변경이 재검토 조건이다. 이미 명시한 작은 불확실성이나 추가 허브 가지 발견만으로 자동 hold 또는 재연구하지 않는다.

## 적용 검증

- 공식 dry-run/apply exit 0. Meaning 1·note 1·relation create 2, active history 4행. Dry-run undo 성공, 원본 DB SHA 불변.
- Work SHA: `838d80faa317b5c286ad5394c685041f02deb8fe07fd5eb00fd171b8360bafc8` → `47a6f2a858734def654245708a35e87bba2ae622cfd935f80319a24afd148b25`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- Snapshot: `data/backups/approved_content_batch/20260922T232455767799Z/snapshot.db`; 같은 폴더 `result.json`과 `independent_verification.json`에 검증 보존. 폴더 시각은 UTC.
- Snapshot과 적용 DB의 schema 및 전체 사용자 테이블을 독립 비교했다. WORD_TABLE 1행·word_meaning_set 1행 교체, WORD_RELATION 2행·CHANGE_HISTORY 4행 추가 외 차이 없음. Meaning·비고·relation의 모든 승인 필드 exact 일치, pair 중복 없음, history undone_at NULL. 비생성 승인 pair 두 건도 없음.
- Work·seed·snapshot integrity ok, FK 0, sidecar 없음.
- H0038 explicit_approved / approved. 승인 107→108, 미승인 14,189→14,188, hold 2·anomaly 113 유지.
- Progress snapshot identity: `c40c5e70b31ee59c821d708cf2011f94a8c028934f7748bb49786f8cffd49047`.
- Targeted `approved_content_batch_service_test.dart` 29건 통과. 첫 실행은 실제 apply와 겹쳐 teardown의 원본 SHA 불변 assertion이 실패했고, DB 쓰기 없이 단독 재실행하여 전체 통과를 확인했다. 테스트 코드는 변경하지 않았다.
- Flutter UI·사용자 수동 UI 테스트 N/A — 앱 UI 변경 없는 승인 데이터 slice.
