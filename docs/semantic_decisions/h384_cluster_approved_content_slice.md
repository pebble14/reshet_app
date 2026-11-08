# H0384 이디엘 뜻·비고·관계 결정

- 상태는 `active`다.
- 결정일은 2026-11-08이다. 근거 복원 수준은 높음이다.
- 적용 대상은 H0384의 뜻과 비고, 합성 관계 두 건이다.
- 연구 요약은 로컬 `reshet_research_output/H0384_cluster_20261108_7d8e6c65/00_cluster_summary.md`에 있다. SHA-256은 `505834408e50e9baf7692addc6b64ec863e6860577fb1a49753ba473adf47c15`다.
- [승인 manifest](../../tool/data_provenance/manifests/h384_cluster_approved_content_slice.json) · [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

H0384 `אִיתִיאֵל`의 뜻 seq 1을 `이디엘 (인)`에서 **`이디엘·이티-엘 (인)`**으로 교체했다. 가운데점으로 병기한 두 표기는 하나의 인명 뜻이다.

**승인 비고**

> 느헤미야 11:7의 베냐민 계보에 나오는 인명이다. 잠언 30:1의 마소라 본문에서는 아굴의 말을 받는 이 이름이 두 번 나오며, 자음의 분절과 모음을 달리해 ‘하나님, 저는 지쳤습니다’로 읽는 해석도 있다. ‘이디엘’은 성경 관용명이고 ‘이티-엘’은 이름 끝의 אֵל(하나님)을 드러낸 교재식 표기다. 첫 요소를 אֵת(H0854)의 인칭형과 연결하면 ‘하나님이 나와 함께 계신다’는 이름 풀이가 된다. Strong은 H0837과 H0410을 추정하여 ‘하나님이 오셨다’로 풀이하지만 H0837을 첫 요소로 볼 형태 근거는 약하다.

|관계 ID|의미 방향|저장 pair|category / type / status / direction|
|---:|---|---|---|
|8309|H0410 → H0384|`H0384_0000 / H0410_0000`|`morphological / compound / asserted / w2_to_w1`|
|8310|H0854 → H0384|`H0384_0000 / H0854_0000`|`morphological / compound / hypothesized / w2_to_w1`|

- 관계 8309 비고는 ‘אֵל은 이름 끝의 신명 요소다. 첫 요소의 분석은 견해가 갈린다.’이다. 출처는 `Strong H0384; BDB H0384; Gesenius, Ithiel`이다.
- 관계 8310 비고는 ‘첫 요소를 אִתִּי(H0854, 나와 함께)에 연결하는 가설이다. 이름의 철자 및 ת의 다게쉬에 차이가 있다.’이다. 출처는 `BDB H0384, H0854; Gesenius, Ithiel; OSHB Judg.16.15; HebGrkKo H384`이다.
- H0837 연결은 비생성, H0383 연결은 보류로 결정했다. 신규 단어 단위 hold는 0건이다.

## 핵심 판단 근거

- OSHB 정본 3토큰을 전량 검토했다. 느헤미야 11:7의 계보는 인명 읽기가 확실하다. 마소라 본문에서 잠언 30:1의 두 토큰은 인명으로 읽히며, 새번역 각주와 고대 역본은 다른 읽기를 전한다. 정본 기준 인명 3건, 미검토 0건, 초기 독법 미해결은 잠언의 2토큰이다. [OSHB 고정본](https://github.com/openscriptures/morphhb/tree/3d15126fb1ef74867fc1434be1942e837932691f/wlc) · [Kirk의 잠언 30:1b 연구](https://doi.org/10.1163/15685330-00001146)
- ‘이디엘’은 개역개정·개역한글·새번역의 관용명이다. ‘이티-엘’은 현대식 성경 히브리어 교재 읽기의 한글 근사로, 확인된 אֵל 앞의 합성 경계를 표시한다. 티베리아 전통에서 다게쉬 없는 ת의 재구 음가는 [θ]이며, 교재식 근사와 구별한다. H0022의 신명 경계 표기와 H0385의 교재식 타브 근사를 대조했다. [H0022 표기 결정](h0022_h1841_g1158_analytic_name_notation_approved_content_slice.md) · [H0385 결정](h176_cluster_approved_content_slice.md) · [Khan의 티베리아 발음 연구](https://books.openbookpublishers.com/10.11647/obp.0163.pdf)
- Strong의 `perhaps from 837 and 410`은 전체 어원의 추정이다. H0410은 이름의 형태와 여러 독법에 공통으로 나타나는 요소로 확정했다. H0854에는 BDB와 Gesenius의 분석, 삿 16:15의 실제 אִתִּי 및 H0863의 인명 철자 평행이 있다. 이름의 אִיתִי와는 י 및 다게쉬가 달라 관계의 확실성은 가설이다. [BDB 이디엘 항목](https://biblehub.com/bdb/384.htm) · [Gesenius 인명 항목](https://www.bibliquest.org/Auteurs_divers/Simonis_Gesenius-Dictionnaire_noms_propres_AT.pdf)
- 읽기 전용 연구의 양방향 탐색은 9,152노드·11,835간선, frontier 0에 도달했다. CORE 1개, CONTEXT 6개를 검토했다. 생산적 신명 요소 H0410과 H0837의 약한 참조에서 이어진 9,145개 표제는 별도 판단 범위로 분류했다.

## 채택하지 않은 주요 대안

- `이디엘 (인)` 단독 표기는 관용명만 제공한다. `이디엘·이티엘 (인)`은 근사를 보존하지만 근거가 확보된 אֵל 경계가 드러나지 않는다.
- ‘하나님이 나와 함께 계신다’와 ‘하나님이 오셨다’는 경쟁 어원 풀이로 비고에 뒀다. H0837의 창 30:13 ‘행복’ 용례와 형태는 Strong의 추정 연결을 뒷받침하기 어렵다.
- H0383과의 존재 구문 평행은 이름 첫 요소의 차용을 판별하기에 부족하다. 단어 전체를 hold할 근거는 느헤미야의 안정적인 인명 용례를 고려할 때 부족하다.

## 남은 불확실성 및 재검토 조건

잠언 30:1의 초기 독법과 수신자의 구체적 식별, 이름 첫 요소의 어원은 미확정이다. 이름 초기 철자나 독립 비교 자료가 확보되면 H0854 가설과 H0383 보류를 재검토할 수 있다. 잠언의 본문 계통을 판별할 자료가 확보되면 비고의 본문비평 설명을 재검토한다.

## 적용 검증

공식 dry-run의 사본 적용·undo 및 기존 적용기 테스트 31개가 통과했다. 적용 후 이력 그룹 `1794125650556269`의 4행(ID 7627–7630)과 비대상 데이터, 작업 DB와 백업·snapshot의 13개 테이블 및 DDL을 독립 대조했다. SQLite 무결성 `ok`, FK 위반과 sidecar 0건이다.

- Work DB SHA-256은 `7d8e6c65e0b303362954fceaf85b81bc5ec58faee964e77deefc742c2550c5de`에서 `e929e7cfa0bec54bacb6dbc39140bb76183c2cd898b8f7edc0722976a7f52891`로 바뀌었다. Seed SHA-256은 적용 전후 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`였다.
- 공식 progress는 승인 869→870, 미승인 13,423→13,422, hold 6, anomaly 113이다. H0384만 승인으로 전환됐고 비대상 14,297행이 일치했다. Snapshot ID는 `6a293a20780bd5795397436a5cfb731754009fa50623559f7cb07f4b73ed5795`이다.
- 공식 적용 receipt는 로컬 `data/backups/approved_content_batch/20261108T081407647481Z/result.json`에 있다. 독립 SQL·진행표 대조 결과는 로컬 `data/backups/approved_content_batch/h384_approval_20261108/`에 있다. UI 테스트는 콘텐츠 적용 범위에서 N/A다.
