# H229 에스배·히솝 식물명 클러스터 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-26 (Asia/Seoul)
- 대상: H0229_0000, H0231_0000, G5301_0000
- 승인 manifest: [h229_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h229_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0229_cluster_20261026_ca96cc7a/`, 추천 V1; `00_cluster_summary.md`, CORE3 Full Review, 전체13토큰 평가와 수동 reference 보충 자료
- 승인 원문·채택안 사본·적용 전 byte 백업·검증: `data/backups/approved_content_batch/h229_approval_20261026/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261026T110900806401Z/result.json`

## 최종 결정

사용자는 직전 CodeX V1 추천안에 동의하고 DB·문서·기타 필요 파일 반영, 검증 후 커밋·작업 브랜치 push·main ff-only 병합과 push·이번 브랜치 로컬·원격 정리까지 승인했다. 의미 교체3·비고 교체3·관계 생성1·관계 교체1을 공식 applicator로 한 번 적용했다.

|Strong|변경 전 meaning|최종 ordered meaning|sense|hold|
|---|---|---|---:|---|
|H0229|에스배 (인)|seq1 `에스배·에즈바이 (인)`|1|없음|
|H0231|히솝(풀)[시리아오레가노] / 우슬초|seq1 `히솝풀·우슬초`|1|없음|
|G5301|히솝(풀)[시리아오레가노] / 우슬초|seq1 `히솝풀·우슬초`|1|없음|

세 항목의 기존 비고는 NULL이며 다음 문안으로 교체했다.

**H0229 비고**

> 대상 11:37에서 나아래의 아버지인 인명을 가리킨다. 에스배는 한국어 성경의 관용 표기이고 에즈바이는 אֶזְבַּי의 교재식 읽기를 따른 한글 근사다. Strong은 H231에서 유래했을 가능성과 ‘히솝과 같은’이라는 풀이를 제시하지만, 참고사전은 ‘빛나는, 아름다운’으로 풀이한다. 이름의 어원은 확정하지 않으며 이 풀이를 별도 의미나 인물의 성격으로 보지 않는다. 삼하 23:35의 평행 명단과의 이름 대응은 미확정이다.

**H0231 비고**

> 성경에서 우슬초로 옮긴 히솝류 식물이다. 출 12:22와 레 14장·민 19장에서는 피나 물을 묻혀 뿌리거나 정결 의식의 재료로 쓰이고, 왕상 4:33에서는 담에 자라는 작은 식물로, 시 51:7에서는 정결을 구하는 비유에 쓰인다. 시리아오레가노(Origanum syriacum)가 대표적인 식별 후보이나 정확한 현대 식물 종은 확정하지 않는다. 한국의 우슬(牛膝), 곧 쇠무릎(Achyranthes japonica)과 이름만으로 동일시하지 않는다. Strong은 외래 기원일 가능성을 제시하며 정확한 기원과 차용 경로는 미확정이다.

**G5301 비고**

> 히브리어 אֵזוֹב(H231)에 대응하는 성경의 히솝류 식물명이다. 요 19:29에서는 신 포도주를 적신 해면을 받치는 줄기나 가지로, 히 9:19에서는 피를 뿌리는 의식의 재료로 쓰인다. 시리아오레가노(Origanum syriacum)가 대표적인 식별 후보이나 각 본문의 정확한 식물 종은 미확정이다. Strong의 외래 기원 설명과 히브리어 참조는 보존하되 직접 차용의 언어·경로·방향은 확정하지 않는다.

관계는 다음과 같다. 저장 pair는 canonical 순서이며 의미 방향은 모두 `w2_to_w1`이다.

|관계 ID·조치|semantic 방향|저장 pair|category / type / status|
|---|---|---|---|
|8131 신규|H231 → H229|H0229_0000 < H0231_0000|`morphological / derived / hypothesized`|
|3132 교체|H231 → G5301|G5301_0000 < H0231_0000|`translation / literal_translation / asserted`|

id3132의 기존 `unspecified / related / inferred / unknown`을 위 값과 `w2_to_w1`로 바꿨다. 첫 관계는 이름 어원 **가설**이고, 두 번째 관계에서 확정하는 명제는 식물명의 **번역 대응**이다. 직접 차용의 역사적 경로를 확정한 것이 아니다. 각 note 전문은 다음과 같으며 source는 각각 `RESHET-EC-H229-CLUSTER-H231-H229`, `RESHET-EC-H229-CLUSTER-H231-G5301`이다. description·relation_group_id는 모두 NULL이다.

**id8131 note**

> Strong은 H229를 ‘probably from H231; hyssop-like’로 설명한다. 확정된 파생이 아닌 이름 어원 가설이며, 참고사전의 ‘빛나는, 아름다운’ 풀이와의 차이를 보존한다. 인물의 성격이나 식물과의 실제 관련성을 단정하지 않는다.

**id3132 note**

> אֵזוֹב에 대한 ὕσσωπος의 어휘 번역 대응이다. Strong의 H231 참조, BDB의 LXX 대응 설명 및 확보 LXX의 해당 구약 10절을 수동 대조한 문맥을 근거로 한다. LXX는 provenance·license 미검증 human reference이며 자동 정렬 자료가 아니다. 직접 차용 경로나 모든 용례의 현대 식물 종 동일성을 확정하지 않는다.

기존 id3133의 영어 hyssop–G5301 관계는 모든 필드를 보존했다. 영어 항목 자체의 meaning을 새로 승인하거나 바꾸지 않았다. H229–G5301 직접 관계는 생성하지 않았다. 새 hold·hold 해제·supersession은 없으며 기존 Greek 표현 승인도 그대로 유효하다. 원문 expression·음역·발음·언어·schema·seed·비대상·hold ledger·앱 코드·원본 연구 자료는 보존했다.

공식 dry-run의8건 사본 적용·undo·원본 불변 및 기존 applicator 테스트31개가 통과했다. 적용 후 독립 SQL53조회·88검증은 전체13테이블·DDL·적용 전 byte 백업·공식 snapshot을 대조해 승인 값과 history8·필요한 sequence 외 변화 없음을 확인했다. History group `1793012942142314`, ID7000–7007은 word update6·relation create1·relation update1이며 undone_at은 모두 NULL이다. 표준 progress의 독립30검증에서 대상3개만 신규 승인되고 비대상14,295행·기존 authority·anomaly·lexical index가 불변임을 확인했다. UI·앱 배포·seed 교체는 N/A다.

## 핵심 판단 근거

H229의 대상11:37 한 용례는 나아래의 아버지라는 인명이다. 에스배는 한국어 성경 관용명이고 에즈바이는 현재 원문·expression·원전분해가 지지하는 교재식 한글 근사다. 두 표기를 같은 meaning에 병기하며 추정 이름 풀이를 별도 의미나 인물의 성격으로 만들지 않았다. 묵음 셰와 뒤 בּ를 강한 자음 중복으로 기계 처리하지 않았고 합성 경계 근거가 없어 붙임표를 넣지 않았다. H229의 source x-pn/unresolved metadata는 보존한다.

H231의10회는 실제 제의 재료8·담에서 자라는 식물1·정결을 구하는 비유1이며 모두 하나의 식물명으로 설명된다. G5301의 요19:29와 히9:19 두 용례도 같은 식물명의 줄기 사용과 제의 재료 문맥이다. `히솝풀`과 `우슬초`는 별개의 sense가 아니라 번역·관용 명칭의 병기이며 두 언어에서 동일한 대표 meaning을 사용한다. 전체13용례의 주 배정은1+10+2이고 미검토·의미 배정 미해결·실제 의미 반례는0이다. 이는 어원이나 현대 식물 종까지 해결했다는 뜻이 아니다.

시리아오레가노(Origanum syriacum)는 가치 있는 식별 후보로 비고에 남겼다. BDB의 식물학적 식별 유보, LSJ의 식물명 표기와 RHS·Kew의 현대 식물 자료를 대조해 모든 성경 용례의 종을 확정하는 meaning을 피했다. `우슬초`는 성경의 관용명으로 보존하되 meaning에 `牛膝草`를 추가하지 않는 제안을 사용자가 채택했다. 국내 쇠무릎에도 우슬초라는 이름이 쓰이므로 동일종 오해를 피하기 위한 개별 결정이다. 실제 한자어 `우슬(牛膝)`은 쇠무릎을 구별하는 비고에 사용하며 일반 한자 병기를 생략하는 정책으로 확대하지 않는다.

H231→H229는 Strong의 `probably from ...; hyssop-like;`를 qualifier와 함께 보존한 가설이다. H231→G5301은 고정 Strong의 대응 참조와 동일한 식물명 gloss, BDB의 LXX 대응 설명 및 확보 LXX 해당10절의 수동 문맥 대조가 지지하는 번역 대응이다. 사전 참조 방향을 DB 의미 방향으로 복사하지 않았다. Canonical source는 Strong XML과 OSHB/TAGNT이며 local 자료와 LXX는 reference-only다. 왕상4:33·시51:7의 한국어 자료8건을 명시적으로 보충했고 LXX의 시51:9 오대응과 왕상4:33 미일치를 제외했다. Source profile·provenance·license의 unverified 경계는 보존한다.

[H215 결정](h215_cluster_approved_content_slice.md)의 인명 병기·식물 종 유보, [H201 결정](h201_cluster_approved_content_slice.md)의 인명 어원과 일반 의미 구별, [H143 결정](h143_cluster_approved_content_slice.md)의 방향·어원 불확실성과 meaning 승인 분리를 대조했다. 기존 개별 예외를 모든 이름의 근사 생략 규칙으로 확대하지 않았다. [헬라어 표현 결정](greek_expression_approved_content_slice.md)과 실제 변경값에서 G5301의 휘쏘포스가 승인된 값임을 확인해 local 자료의 옛 휫소포스로 되돌리지 않았다.

## 채택하지 않은 주요 대안

- H229 `에스배 (인)`만 유지하거나 `에즈바이 (인)`만 두기: 각각 원어 비교 또는 관용명 식별이 줄어든다. 의미상 틀린 안은 아니지만 사용자는 병기안을 채택했다.
- H229의 `히솝 같은`·`빛나는`·`아름다운` 등을 독립 meaning으로 추가: 이름 어원 풀이가 충돌하고 실제 일반명사 용례가 아니다. 자료 차이와 한계를 비고에 보존했다.
- H231/G5301의 기존 두 meaning 유지: 같은 식물명의 번역 명칭 차이를 독립 sense로 나눌 근거가 부족하다.
- 시리아오레가노를 확정 종으로 meaning에 유지: 대표 후보는 보존하되 모든 시대·문맥의 종 동일시를 확정할 근거가 부족해 비고로 옮겼다.
- `정결 의식에 쓰는 풀`·`정결`·`막대기`를 기본 의미 또는 별도 sense로 두기: 특정 기능·비유·부분 지시를 어휘 전체의 뜻으로 바꾸며 왕상4:33·요19:29 등 전체 범위를 좁힌다.
- H231→H229를 `derived/asserted`로 생성: `probably`를 지우는 확정이므로 채택하지 않았다. 관계 비생성·비고만 보존도 가능했지만 사용자는 출처를 드러낸 가설 관계를 채택했다.
- id3132를 `borrowed_from/asserted`로 교체: 직접 차용 언어·경로·방향의 입증이 부족하다. 확인 가능한 번역 대응을 분류하는 안을 채택했다.
- 어원·종·발음 불확실성 때문에 세 단어 전체 hold: 인명과 식물명의 일반 의미를 안전하게 승인할 수 있으므로 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

H229의 정확한 어원, Strong의 히솝 관련설과 참고사전의 빛나는/아름다운 풀이의 관계, 삼하23:35 평행 명단과의 이름·인물 대응은 미확정이다. 교재식 에즈바이는 기록 당대의 실제 호명을 재현했다는 뜻이 아니다. Source x-pn을 추정으로 교정하지 않았다.

H231/G5301의 정확한 현대 식물 종, 옛 학명들의 분류사 전체, 요19:29의 구체적 식물·줄기 지지 방법, 히브리어·그리스어 식물명의 직접 차용 경로는 미확정이다. 궁극적 어원이나 사전·고대 문헌이 인용한 원전 전부와 사본 apparatus를 독립 전량 확인했다고 주장하지 않는다. 의미 배정 미해결0과 이 불확실성을 혼동하지 않는다.

검증 가능한 새 어원·본문비평·계보·시대별 식물 식별 또는 실제 차용 경로 evidence가 확보되거나 사용자가 표기를 변경하면 해당 meaning·비고·관계의 정확한 영향 범위를 재검토한다. 번호 인접성·번역 문체 차이·새 자료 없는 어원 재서술만으로 자동 재검토하지 않는다. 기존 영어 hyssop의 의미·관계 정비는 별도 범위이며 이번에 자동 변경하지 않았다. Local/LXX source contract의 검증 상태가 바뀌어도 기존 semantic 값의 자동 변경 권한은 생기지 않는다.
