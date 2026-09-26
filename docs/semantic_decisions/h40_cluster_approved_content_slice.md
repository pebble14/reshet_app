# H40·H1125 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-27
- 대상: H0040, H1125; H0001·H4428·H1121은 승인 관계의 구성 요소
- 승인 manifest: [h40_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h40_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음. 두 대상에 word-level hold 없음
- 로컬 연구 산출물: `H0040_cluster_20260927_5c915348/00_cluster_summary.md`, `00_approved_content.md`, H40/H1125 full Review·packet·relation context
- DB history group: `1790466814169456`

## 최종 결정

사용자는 H1125의 다층 분석 표기를 검토한 후 조정안을 승인하고 DB 반영 및 Git 완료를 요청했다. 초기 연구 summary의 `벤-아비나다브`보다 최신 사용자 결정이 우선한다.

- H0040_0000 meaning: `아비멜렉·아비-멜레크 (인)`, seq 1, 단일 sense.
- 비고:

  > 아비멜렉은 한국어 성경의 관용 표기이고, 아비-멜레크는 אֲבִי־מֶלֶךְ의 구성 요소를 드러내는 원문 기반 분석 표기이다. 붙임표는 원문 표제어의 구두점이나 특정 시대의 정확한 발음을 뜻하지 않는다. H0001(아버지)과 H4428(왕)으로 이루어지며, 이름의 풀이는 자료에 따라 ‘왕의 아버지’ 또는 ‘아버지는 왕이시다’로 다르다. 창세기의 그랄 왕들, 기드온의 아들, 역대상 18:16의 제사장에게 쓰인다. 시편 34편 표제의 인물 식별과 역대상 18:16의 ‘아히멜렉’ 이문은 구별해서 보며, 모두를 하나의 인물이나 공통 왕호로 단정하지 않는다.

- H1125_0000 meaning: `벤아비나답·벤-아비-나다브 (인)`, seq 1, 단일 sense.
- 비고:

  > 벤아비나답은 한국어 성경의 관용 표기이다. 벤-아비-나다브는 ‘벤 + 아비나답’, 그리고 아비나답 내부의 ‘아비 + 나다브’ 구성을 드러내는 분석 표기이다. 원문의 마케프는 벤과 아비나답 사이에 있으며, 아비와 나다브 사이의 붙임표는 분석을 위해 추가한 것이다. ‘아비나답의 아들’이라는 부칭으로, 열왕기상 4:11에서 솔로몬의 관장으로 언급된다. canonical Strong 자료는 둘째 구성 요소를 H0040으로 참조하지만 표제어와 풀이, 원전분해 및 한국어 사전 참고자료는 아비나답(H0041)을 가리킨다. 이 참조 충돌은 이름 자체의 식별과 구분하며 H0040과의 파생 관계로 해석하지 않는다.

|semantic 방향|relation id|category/type/status|저장 pair|direction_code|
|---|---|---|---|---|
|H0001 → H0040|7702|morphological / compound / asserted|H0001_0000, H0040_0000|w1_to_w2|
|H4428 → H0040|7703|morphological / compound / asserted|H0040_0000, H4428_0000|w2_to_w1|
|H1121 → H1125|7704|morphological / compound / asserted|H1121_0000, H1125_0000|w1_to_w2|

각 관계의 note·description·relation_group_id는 NULL이며 source는 manifest의 pair별 batch 식별자다. 기존 pair가 없어 교체·삭제하지 않았다.

H0040–H1125 관계는 생성하지 않았다. H0041 → H1125는 구성 근거가 강하지만 canonical 참조 충돌을 보존하여 생성 보류했다. 이 보류는 word-level hold가 아니다. 다층 분석 표기를 선택했다고 H0001·H5068에서 H1125로 추가 관계를 생성하지 않았다. CONTEXT·HUB-EXCLUDED 단어의 기존 의미·승인·hold는 그대로 유지했다. Expression·발음·언어·schema·seed·원천 자료는 변경하지 않았다.

## 핵심 판단 근거

H40의 OSHB 67회/62절을 전량 검토했다. 아브라함 시대 그랄 왕 17회, 이삭 시대 그랄 왕 7회, 기드온의 아들 41회, 제사장 1회, 시34 표제 1회 모두 인명 기능이므로 하나의 meaning으로 포괄했다. H1+H4428 구성을 드러내되 Strong의 ‘왕의 아버지’와 한국어 사전의 ‘아버지는 왕이시다’라는 어원 풀이 차이는 비고에 보존했다.

H1125는 왕상4:11의 1회다. 표제어 בֶּן־אֲבִינָדָב, 풀이, OSHB 문맥과 로컬 자료가 아비나답의 아들을 가리킨다. canonical entry의 H40 참조는 이 identity와 충돌하므로 관계로 승인하지 않았다. 첫 요소 H1121은 독립적으로 일치한다.

사용자는 `벤-아비나다브`와 `벤-아비-나다브`의 장단점을 검토하고 후자를 채택했다. 직접 구성은 벤+[아비나답]이고 H41 내부는 아비+나다브다. 다층 표기는 확인된 두 단계 구성을 보여주며 다른 아비- 인명의 분석 표기와도 일관된다. 원문 마케프는 첫 경계에만 있고 두 번째 붙임표는 분석 기호라는 점을 비고에서 구분했다. 특정 시대 발음을 확정하거나 H1125를 세 동등한 요소의 직접 결합이라고 단정하지 않는다.

## 채택하지 않은 주요 대안

- 관용명만 유지: 두 이름을 정확히 식별하는 유효한 대안이지만 원문 구성 비교 가치를 위해 분석 표기를 병기했다.
- `벤아비나답·벤-아비나다브 (인)`: 직접 구성과 아버지 이름의 덩어리를 간결하게 보이지만 확인된 내부 구성을 숨긴다. 강한 배제 근거는 없었으며, 사용자 최종 결정으로 다층 표기를 선택했다.
- 어원 풀이·‘아비나답의 아들’을 별도 meaning으로 추가: 인명 용법과 어원/부칭 설명을 구분해 비고에 보존했다.
- H40을 블레셋 왕호로만 정의하거나 인물별 sense 분리: 비왕족 인명 용례를 포함하는 최소 meaning과 맞지 않는다.
- H40 → H1125 생성 또는 H41로 자동 교정: 원천 참조를 semantic assertion으로 승격하지 않고 충돌을 기록했다. H41 관계 보류는 영구 반증 판정이 아니다.

## 남은 불확실성 및 재검토 조건

H40 이름의 어원 문장 해석, 시34 표제 인물 식별 및 대상18:16 아히멜렉 이문은 미해결이다. OSHB의 해당 이름을 유지하되 새번역·LXX의 다른 표기를 숨기지 않는다. 로컬 LXX 63개 명시적 절 조회는 human-reference로만 사용했으며 provenance/license 미확인과 자동 alignment 금지 경계를 유지했다.

H1125의 H40 참조가 원천 오기일 강한 정황은 있으나 source를 변경하지 않았다. 원천 정정 또는 이를 대체할 근거를 별도로 채택하는 사용자 결정이 있을 때 H41 관계를 재검토한다. source x-pn/unresolved와 DB 히브리어의 차이도 이번 내용 승인으로 변경하지 않는다.

Discovery 62 nodes/61 edges, frontier 58, expanded 4, resume 0으로 graph closure 미완료다. 생산적 H1/H4428 hub 예외 아래 CORE 2개, CONTEXT 4개, HUB-EXCLUDED 56개를 구분했다. CORE 전체 68회는 분석했지만 context/제외 단어 전체 occurrence를 재검토했다고 주장하지 않는다. 단순 hub 가지 추가나 같은 출처의 복제 사이트 증가만으로 자동 재연구하지 않는다.

## 적용 검증

- 공식 dry-run/live apply exit 0. Meaning 2·note 2·relation create 3, active history 7행. Dry-run undo 성공, 원본 SHA 불변.
- Snapshot: `data/backups/approved_content_batch/20260926T235333388907Z/snapshot.db`; result.json과 independent_verification.json에 적용 결과·실행 SQL에 따른 독립 exact 검증 보존.
- 전후 schema 동일. 전체 사용자 테이블 비교에서 WORD_TABLE 2행·word_meaning_set 2행 교체, WORD_RELATION 3행·CHANGE_HISTORY 7행 추가 외 차이 없음.
- Work SHA: `5c915348421d589674dc35243d4b3c7cb3c7fe6b5b97b7464c369d8a65a6f571` → `d1710e4e0cb10de5c3cb363b7a3521290d97e6308abb1cb3bd462e89f9c7ccc4`.
- Seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- work·seed·snapshot integrity ok, FK 위반 0, sidecar 없음. Manifest 최종값과 실제 meaning·note·관계 필드 exact 일치.
- H0040/H1125 explicit_approved. 승인 109→111, 미승인 14,187→14,185, hold 2·anomaly 113 유지.
- UI 테스트 N/A — UI 변경 없는 승인 데이터 slice. 수동 UI 테스트를 수행하지 않았다.
- 승인 내용 artifact SHA: `c1588f2369bbc5963369da0bc03a2228200e70905bc22d2ccab12c291ec3e82b`.
- Progress snapshot identity: `f76e4749293590e694be4fc2ffe9647bf3fe60e2bc096305e6e5d2b48a1d9aca`.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
- 적용 manifest는 CRLF raw-byte SHA `3cbab33b012913e5d9e6d5132d96c29b9de5ab6694370b59ddf24ead488e0b27`, Git LF blob SHA는 `f18d347aebebcf5832d7e7f80a2851e385974c3ed0f40d06dce32edff9c4bd0d`다. core.autocrlf에 따른 줄바꿈 차이만 있으며 JSON 내용은 동일하다. 적용 backup manifest는 적용 당시 바이트를 보존한다.
