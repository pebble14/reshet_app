# H33 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-20
- 대상: H0033, H0044, H0372, H0373; H0001·H5828은 합성 구성요소
- 승인 manifest: [h33_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h33_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음; CORE 네 단어 hold 없음
- 로컬 연구 산출물: `H0033_cluster_20260920_5adbfabf/00_cluster_summary.md`, 각 Strong Review, `08_approved_scope.md`, `09_apply_verification.json`
- DB history group: `1789909426985605`

## 최종 결정

사용자는 나머지 연구 제안을 승인하고, H0033·H0373에는 가문 소속을 명시하고 기반 인명의 표기를 함께 반영하도록 검토했다. 수정 추천안을 채택한 뒤 DB 반영 및 Git 완료를 승인했다. 네 meaning은 각각 seq 1, sense 1이다.

|Strong|최종 meaning|
|---|---|
|H0033|아비에셀·아비-에제르 가문 사람|
|H0044|아비에셀·아비-에제르 (인)|
|H0372|이에셀·이에제르 (인)|
|H0373|이에셀·이에제르 가문 사람|

최종 비고:

- H0033: 아비에셀·아비-에제르 가문에 속한 사람을 가리키는 소속형이다. 문맥에 따라 ‘그 가문의’로 풀어 옮길 수 있다.
- H0044: ‘아비에셀’은 한국어 성경 관용 표기이고 ‘아비-에제르’는 ‘아비’와 ‘에제르’의 구성을 드러낸 분석 표기다. 이름은 ‘나의 아버지는 도움’ 등으로 풀이되지만, 이를 별도 뜻으로 나누지는 않는다. 므낫세 계열의 인물과 다윗의 아나돗 출신 용사가 이 이름으로 불리며, 사사기 6:34와 8:2에서는 그 이름으로 가문을 가리킨다. 므낫세 계열 이름은 민수기 26:30의 이에셀과 비교된다.
- H0372: ‘이에셀’은 한국어 성경 관용 표기이고 ‘이에제르’는 원문 형태를 드러낸 표기다. 민수기 26:30에서 므낫세 계열 가문의 선조 이름으로 나온다. 아비에셀과 대응하는 이름으로 비교되지만, 어원에는 ‘도움 없음’이라는 분석 등 차이가 있어 확정하지 않는다. 어원 풀이를 별도 뜻으로 저장하지 않는다.
- H0373: 이에셀·이에제르 가문에 속한 사람을 가리키는 소속형이다. 민수기 26:30에서는 ‘가족·종족’을 뜻하는 말과 결합하여 그 가문에 속함을 나타낸다.

관계 category는 모두 `morphological`이며 note·description·relation_group_id는 NULL이다.

|id|저장 pair|type|status|direction|source|
|---|---|---|---|---|---|
|7689|H0033_0000 / H0044_0000|derived|asserted|w2_to_w1|RESHET-EC-H33-CLUSTER-H0044-H0033|
|7690|H0372_0000 / H0373_0000|derived|asserted|w1_to_w2|RESHET-EC-H33-CLUSTER-H0372-H0373|
|7691|H0001_0000 / H0044_0000|compound|asserted|w1_to_w2|RESHET-EC-H33-CLUSTER-H0001-H0044|
|7692|H0044_0000 / H5828_0000|compound|asserted|w2_to_w1|RESHET-EC-H33-CLUSTER-H5828-H0044|
|7693|H0044_0000 / H0372_0000|variant|hypothesized|undirected|RESHET-EC-H33-CLUSTER-H0044-H0372|
|7694|H0033_0000 / H0373_0000|variant|hypothesized|undirected|RESHET-EC-H33-CLUSTER-H0033-H0373|

H0044→H0033, H0372→H0373은 소속형 파생, H0001→H0044·H5828→H0044는 합성 관계다. H0044—H0372와 H0033—H0373은 무방향 가설 변이 관계다.

H5829→H0044는 생성하지 않는다. H0336/H5828→H0372 합성 어원 관계는 보류하지만 word-level hold는 만들지 않는다. 다른 단어의 meaning·비고, 기존 relation, expression·발음·schema·seed는 변경하지 않았다.

## 핵심 판단 근거

CORE canonical occurrence 12/12회(11개 절)와 확보된 local reference를 대조했다. H0033 3회는 요아스 또는 오브라의 가문 소속을 나타내고, H0373 1회도 이에셀 계열 소속형이다. 사용자는 단순 ‘아비에셀 사람/이에셀 사람’보다 ‘가문’을 명시하는 것이 적절하며, 기반 인명의 병기 표기도 일관되게 반영해야 한다고 판단했다. 의미에는 독립적으로 읽히는 ‘가문 사람’을 두고 ‘가문의’ 수식 기능은 비고에 보존했다.

H0044 7회는 므낫세 계보 인물, 가문의 집합적 지칭, 다윗의 아나돗 출신 용사를 가리킨다. 인물 수를 lexical sense 수로 늘리지 않는다. H0372 1회는 민26:30의 선조 인명이다. 관용명·분석 표기는 같은 이름의 병기이며 특정 시대의 발음 확정이 아니다. H0033/H0373 meaning의 병기는 기반 인명의 표기이며 소속형 전체 음역을 주장하지 않는다.

H0044 canonical source는 H5829를 참조하지만 후자는 인명이고 source 풀이 자체는 ‘도움’이다. H5829의 H5828 same-as 설명 및 이름 분석을 함께 고려하여 보통명사 도움 H5828을 합성 관계 endpoint로 선택하는 추천을 사용자가 승인했다. 원천 참조를 조용히 교정한 것이 아니라 semantic 관계 선택을 별도로 승인한 것이다.

BDB 및 local 사전의 아비에셀–이에셀 대응은 관계를 뒷받침하지만 정확한 형성 과정에는 불확실성이 남아 두 variant 관계는 hypothesized로 보존했다.

## 채택하지 않은 주요 대안

- H0033 `아비에셀 (인)`: 실제 소속형 용례를 독립 인명과 혼동하므로 교체했다.
- `아비에셀 사람`, `이에셀 사람`: 지명 출신처럼 읽힐 여지를 줄이기 위해 사용자가 가문 명시를 선택했다.
- `아비에셀 가문의`, `이에셀 가문의`: 수식 용법으로 타당하지만 단독 어휘 뜻의 완결성을 고려해 비고 설명으로 보존했다.
- `아비에셀 자손(子孫)`, `이에셀 자손(子孫)`: 가능한 대안이나 이번에는 ‘가문 사람’을 선택했다.
- H0373 기존 `이에셀의 종족`: 민26:30의 문맥 번역으로 가능하지만 target의 소속형과 별도 ‘가족/종족’ 명사를 구별했다.
- H0372 ‘도움 없음’을 별도 meaning이나 확정 합성 관계로 저장: 어원 차이가 있으므로 비고에 한정했다.
- H0044/H0372 동일성을 확정하거나 한 인물로 병합: 가설 variant로 연결하고 별도 Strong을 유지했다.

## 남은 불확실성 및 재검토 조건

H0372의 어원 및 H0044와의 형성 과정은 미확정이다. H0044와 H0372의 비교는 므낫세 계열 이름에 관한 것이며 다윗 용사까지 같은 인물이라고 주장하지 않는다. 새로운 검증된 어원·본문비평 근거가 생기면 해당 관계를 재검토한다. 작은 번역 차이만으로 word-level hold를 만들지 않는다.

원래 discovery는 45 nodes/45 edges, frontier 41로 미완료이고 보충 확인을 합치면 60 nodes/61 canonical edges다. H1·H5828의 생산적 hub에 예외를 적용했으며 전체 graph closure 완료를 주장하지 않는다. CORE 4개, CONTEXT 6개, 허브 제외 50개다.

LXX는 11개 explicit reference를 조회했으나 민26:30은 다른 내용이 반환되어 대응 근거에서 제외했다. LXX provenance/license는 unverified이며 자동 alignment를 하지 않는다. H33의 OSHB 33+와 33 두 token은 문맥에서 함께 읽되 canonical count는 현행 3회로 유지한다.

## 적용 검증

- 공식 dry-run exit0: meaning4·note4·relation6, history14, undo 성공, 원본 DB 불변.
- 공식 live apply exit0, snapshot `data/backups/approved_content_batch/20260920T130346190802Z/snapshot.db`.
- work SHA: `5adbfabff24214f2238d6c106cb9c89e644622be19339647d63769e5db3efae8` → `62cad49bbca797c9ed22ba0cebb50a94ec5ac9184f144e38d18b2174364a19ea`.
- seed SHA 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- 전체 schema·사용자 테이블 비교: WORD_TABLE4행·word_meaning_set4행 변경, WORD_RELATION6행·CHANGE_HISTORY14행 추가 외 차이 없음. 승인 target 외 변경 없음.
- 최종 meaning·비고·relation pair/type/status/direction/source/NULL metadata가 manifest와 exact 일치. 중복 없음, history14행 undone_at NULL. Work·seed·snapshot integrity ok, FK0, sidecar0.
- CORE 네 단어 explicit_approved, 전체 승인101→105·미승인14,195→14,191, hold2·anomaly113 유지.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 통과. UI 테스트 N/A — 앱 코드·UX 변경 없음.
- Progress snapshot identity: `5eb6cdde759b309baa51b83bdd3227e63ac2f3a59b158122bedc212291da9056`.
- 승인 근거 SHA: `886460e5f5213942c2f76ff4216e472a33669d621180c48af299120ba6813725`.
- 적용 snapshot의 CRLF manifest SHA는 `cd7e973c95890e445141dcd42a404685034b620fd6f658d633f8d0e9420d276e`, Git 정규화 LF blob SHA는 `3fb0ffed97b293921cc26f74cacd1b2869aeacd8bb404743492806876bcbe745`다. JSON 전체 내용은 exact 동일하며 바이트 차이는 줄바꿈뿐이다.
