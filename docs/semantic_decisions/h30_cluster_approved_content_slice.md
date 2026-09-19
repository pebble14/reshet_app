# H30 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-19
- 대상: H0030; H0001·H1931은 합성 관계의 구성요소
- 승인 manifest: [h30_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h30_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H0030 hold 없음
- 로컬 연구 산출물: `H0030_cluster_20260919_d2aa4704`
- DB 적용: history group `1789821998340133`

## 최종 결정

사용자는 연구 추천안 전체를 승인하고 이후 DB 반영·커밋·병합·push·정리를 승인했다.

- H0030 meaning: `아비후·아비-후 (인)` 한 행, sense 1.
- H0030 비고:

  > 아론과 엘리세바의 아들. ‘아비후’는 한국어 성경의 관용 표기이고, ‘아비-후’는 אָב(H0001, 아버지)와 הוּא(H1931, 그)의 구성을 나타내는 분석 표기이다. 붙임표는 원문의 구두점이나 특정 시대의 발음을 뜻하지 않는다. BDB는 이름을 ‘그는 아버지이다’로 풀이하며, Strong은 ‘그분의 아버지’, 곧 ‘그분을 예배하는 자’로 설명하므로 이름 전체의 어원 해석은 구분해 이해해야 한다.

- H0001→H0030: `morphological / compound / asserted`, 저장 pair `H0001_0000, H0030_0000`, `direction_code=w1_to_w2`, relation id `7685`.
- H1931→H0030: `morphological / compound / asserted`, 저장 pair `H0030_0000, H1931_0000`, `direction_code=w2_to_w1`, relation id `7686`.
- 두 관계의 description·relation_group_id·note는 NULL이며 source는 각각 `RESHET-EC-H30-CLUSTER-H0001-H0030`, `RESHET-EC-H30-CLUSTER-H1931-H0030`이다.
- H0030 hold 없음. H0001·H1931의 의미, expression·transliteration·pronunciation, schema·seed는 변경하지 않았다.

## 핵심 판단 근거

OSHB 정경 출현 12회는 모두 아론의 아들 아비후를 가리킨다. 계보와 이름 목록 5회, 시내산에 오르는 장면 2회, 제사장 직무 지명 1회, 다른 불·죽음 관련 문맥 4회는 같은 인명의 문맥 차이다. 원문 12개 절과 KJV·한국어 번역·원전분해를 비교했으며 한국어 자료의 절 번호 충돌 1건은 수동 대조했다. 별도 sense나 hold를 요구하는 반례는 확인되지 않았다.

‘아비후’는 한국어 성경 관용 표기, ‘아비-후’는 canonical Strong source가 명시한 H0001과 H1931의 구성 경계를 보여주는 분석 표기다. 동일 인명의 두 표기를 가운데점으로 묶어 한 meaning으로 승인했다. 붙임표는 원문 구두점이나 특정 시대의 재구 발음을 주장하지 않는다.

두 관계는 canonical source의 `from H1 and H1931`에 근거한 구성요소→합성 이름 방향이다. 이름 전체의 번역 풀이에는 자료 차이가 있으나 구성요소 분석과 구별하여 비고에 보존했다. 사용자는 이 evidence-backed 추천안을 최종 채택했다.

## 채택하지 않은 주요 대안

- `아비후 (인)`만 유지: 의미상 틀리지는 않으나 확인된 구성 경계를 함께 보여주는 정책에 따라 분석 표기를 병기했다.
- ‘그는 아버지이다’ 또는 ‘그분을 예배하는 자’를 별도 meaning으로 추가: 인명 지시 기능과 어원 풀이를 혼합하므로 채택하지 않았다. BDB와 Strong의 설명 차이는 비고에 남겼다.
- LXX의 `αβιουδ`를 근거로 H31 또는 NT G10과 관계 생성: 표면형만으로 lexical identity를 확정할 수 없어 생성하지 않았다.
- H0001·H1931의 독립 의미 재승인: 이번 이름의 구성 문맥이며 별도 전체 용례 심사 대상이 아니므로 변경하지 않았다.

## 남은 불확실성 및 재검토 조건

H0030의 source 언어코드 `x-pn`은 현행 mapping상 unresolved이며 그대로 보존했다. BDB의 ‘그는 아버지이다’와 Strong의 ‘그분의 아버지/예배자’ 풀이 차이는 이름 전체의 어원 해석에 관한 것으로 인물 식별과 구성 관계를 뒤집지 않는다.

OSHB 역대상 5:29는 KJV 및 한국어 자료 6:3과 대응한다. LXX의 해당 문맥은 5:29이고 LXX 6:3은 다른 계보다. 로컬 reference profile은 미검증 상태를 유지하며 LXX는 provenance/license unverified human reference로만 사용했다.

Discovery는 H1·H1931 hub를 통해 50 node/49 edge를 발견하고 frontier 47을 보존한 미완료 상태다. CORE H30과 두 CONTEXT를 분리한 hub 예외이며 전체 그래프 closure 완료를 뜻하지 않는다.

H1의 현행 meaning은 후속 승인 표기 결정과 일치하지만 progress는 옛 manifest의 projection mismatch로 미승인 분류한다. 이번에는 이 분류를 수정하거나 기존 결정을 철회하지 않았다.

새로운 원문 자료가 인물 식별 또는 H1·H1931 구성을 부정하면 재검토할 수 있다. 단순 한국어 조사 차이, 간접 hub 발견, 이미 보존한 사전 풀이 차이만으로 자동 재검토하지 않는다.

## 적용 및 마감 검증

- 공식 dry-run exit 0: meaning 1, word note 1, relation create 2, history 4; 실제 undo 성공 및 원본 DB 불변.
- 공식 live apply exit 0. work SHA-256: `d2aa4704444a529429174fbe36609b1ac490954cd8a33690f20c03e731f7bc5f` → `3d62213308ee031c769236aa9c58d56e6baba2a4ec649fbc2d364cb5e78f1ced`.
- seed SHA-256 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- snapshot: `data/backups/approved_content_batch/20260919T124637535784Z/snapshot.db`, SHA-256 `cffc96525fb659360e32d248f10e6d2662fc5eabb6e2846141101a3969059915`.
- Snapshot/현재 DB의 모든 사용자 테이블과 schema를 독립 비교하여 위 승인 변경 및 CHANGE_HISTORY 4행 외 차이 없음 확인. H1·H1931 의미 불변.
- work·seed·snapshot 모두 integrity ok, FK 오류 0, sidecar 0.
- H0030 `explicit_approved / approved`. 전체 승인 79→80, hold 2 유지, 미승인 14,217→14,216, anomaly 113 유지. Progress snapshot identity: `3f5996c84de9a46a14a87923358803e61736c403f1c1d5f4b214f6a9d85caa97`.
- 기존 applicator targeted 테스트 29건 통과. 앱 코드·schema·UI 동작 변경 없음, 사용자 UX 테스트 N/A.
