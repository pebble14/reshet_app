# H475 엘리아십 어휘군 승인 결정

- **상태** active
- **결정 및 최초 적용일** 2026-11-24
- **기록 성격** 승인 반영과 동시에 작성 · 판단 근거 복원 수준 높음
- **승인 근거** 사용자가 R2를 확인하고 뜻·비고·관계와 작업 DB·문서 반영을 승인했다.
- **승인 매니페스트** [h475_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h475_cluster_approved_content_slice.json)
- **로컬 연구 산출물** reshet_research_output/H0475_cluster_20261124_11c5d481/00_cluster_summary.md (승인 시점 R2 사본은 적용 증거 폴더에 보존).

## 최종 결정

19개 어휘의 순서 있는 뜻 25개와 비고 19건을 반영했다. 비고의 정확한 문자열은 매니페스트의 word_note_replacements에 있다.

| Strong | 승인 뜻 | 뜻 수 |
|---|---|---:|
| H0475 | 엘리아십·에랴십·엘-야쉬브 (인) | 1 |
| H7725 | 돌아가다, 돌아오다, 돌아서다 / 되돌리다 / 다시 하다 / 대답(對答)하다, 보고(報告)하다 | 4 |
| H3102 | 욥·요브 (인) | 1 |
| H3142 | 유삽헤셋·유샤브-헤세드 (인) | 1 |
| H3432 | 야숩·야슈브 가문(家門) 사람 | 1 |
| H3433 | 야수비네헴·야슈비-레헴 (인) | 1 |
| H3434 | 야소브암·야쇼브-암 (인) | 1 |
| H3437 | 야숩·야슈브 (인) | 1 |
| H4877 | 메소밥·메쇼바브 (인) | 1 |
| H4878 | 등을 돌림 | 1 |
| H7610 | 스알야숩·셰아르-야슈브 (인) | 1 |
| H7619 | 스브엘·수바엘·셰부-엘·슈바-엘 (인) | 1 |
| H7726 | 등을 돌린 | 1 |
| H7727 | 소밥·쇼바브 (인) | 1 |
| H7728 | 등을 돌린 | 1 |
| H7729 | 돌이킴 | 1 |
| H7870 | 회복(回復) | 1 |
| H8421 | 돌아오다 / 되돌리다 / 대답(對答)하다 | 3 |
| H8666 | 돌아옴 / 대답(對答) | 2 |

신규 관계 23건은 확정 15건과 가설 8건이다. 어휘 단위 hold는 0건이다. 대상 어휘의 원문과 음역·발음 자료는 적용 전후 SQL 비교에서 일치했다.

| 관계 ID | 저장 pair | 분류 / 유형 / 상태 | 방향 |
|---:|---|---|---|
| 8573 | H0410_0000 / H0475_0000 | morphological / compound / asserted | w1_to_w2 |
| 8574 | H0475_0000 / H7725_0000 | morphological / compound / asserted | w2_to_w1 |
| 8575 | H3102_0000 / H3437_0000 | morphological / variant / hypothesized | undirected |
| 8576 | H2617_0000 / H3142_0000 | morphological / compound / asserted | w1_to_w2 |
| 8577 | H3142_0000 / H7725_0000 | morphological / compound / asserted | w2_to_w1 |
| 8578 | H3432_0000 / H3437_0000 | morphological / derived / asserted | w2_to_w1 |
| 8579 | H3433_0000 / H3899_0000 | morphological / compound / hypothesized | w2_to_w1 |
| 8580 | H3433_0000 / H7725_0000 | morphological / compound / hypothesized | w2_to_w1 |
| 8581 | H3434_0000 / H5971_0000 | morphological / compound / hypothesized | w2_to_w1 |
| 8582 | H3434_0000 / H7725_0000 | morphological / compound / hypothesized | w2_to_w1 |
| 8583 | H3437_0000 / H7725_0000 | morphological / derived / asserted | w2_to_w1 |
| 8584 | H4877_0000 / H7725_0000 | morphological / derived / hypothesized | w2_to_w1 |
| 8585 | H4878_0000 / H7725_0000 | morphological / derived / asserted | w2_to_w1 |
| 8586 | H7605_0000 / H7610_0000 | morphological / compound / asserted | w1_to_w2 |
| 8587 | H7610_0000 / H7725_0000 | morphological / compound / asserted | w2_to_w1 |
| 8588 | H0410_0000 / H7619_0000 | morphological / compound / asserted | w1_to_w2 |
| 8589 | H7619_0000 / H7725_0000 | morphological / compound / hypothesized | w2_to_w1 |
| 8590 | H7725_0000 / H7726_0000 | morphological / derived / asserted | w1_to_w2 |
| 8591 | H7726_0000 / H7727_0000 | etymological / root_shared / hypothesized | undirected |
| 8592 | H7725_0000 / H7728_0000 | morphological / derived / asserted | w1_to_w2 |
| 8593 | H7725_0000 / H7729_0000 | morphological / derived / asserted | w1_to_w2 |
| 8594 | H7725_0000 / H8421_0000 | etymological / root_shared / asserted | undirected |
| 8595 | H7725_0000 / H8666_0000 | morphological / derived / asserted | w1_to_w2 |

## 핵심 판단 근거

- **H0475**의 엘리아십과 에랴십은 스 10:36을 포함한 한국어 판본의 표기다. 엘-야쉬브는 H0410과 H7725의 히필형에 대응하는 이름의 구성 경계를 보여 준다.
- **H7725**는 주어가 돌아감·돌아섬, 대상을 되돌림, 행위의 반복, 말의 응답·보고를 구별한다. 창 26:18의 다시 파기와 수 22:32의 귀환·보고가 구별을 뒷받침한다. 아람어 H8421과는 무방향 동계 관계를 적용했다.
- **H3433**의 대표 뜻은 대상 4:22의 마소라 본문을 셀라 집안 명단의 인명으로 읽는 데 근거한다. 야슈비-레헴은 사전 표제에 따른 분석형이며, 절 중간 휴지형의 라헴은 비고에 기록했다. H7725·H3899와의 합성은 가설이다.
- **H4878·H7726·H7728**의 뜻은 ‘등을 돌리다’를 공통으로 쓰고 명사와 형용사의 차이를 살렸다. H4877은 대상 4:34의 인명으로 분류했다.
- **H7729**의 돌이킴은 사 30:15의 쉼과 신뢰, 같은 장의 애굽 의존 문맥을 함께 담는다. H7870은 포로 귀환을 포함하는 시온의 회복으로 읽고, H8666은 돌아옴과 말의 대답을 구별했다.

## 채택하지 않은 주요 대안

- H3433의 어휘 단위 보류, 지명 단독 표기, 레헴으로 돌아왔다는 동사 독법을 비교했다. 채택한 인명 독법은 MT와 고정 Strong 표제를 보존하며, 대안은 비고에서 확인할 수 있다.
- H7725의 반복과 응답·보고를 비고에만 두는 두 뜻 안을 비교했다. 창 26:18과 욥 13:22에서 독립 풀이의 가치가 확인됐다. H7729의 돌아섬·물러남·회개도 비교하고 돌이킴을 택했다.

## 남은 불확실성 및 재검토 조건

대상 4:22의 새 본문비평 근거가 나오면 H3433의 대표 독법과 합성 가설을 검토한다. H7619의 앞 요소와 H7870의 어형 형성은 여전히 불확실하다. 렘 42:10의 H7725 태깅, 렘 50:6의 H7726 케티브, 미 2:4의 H7728 용례는 개별 본문 이견으로 남겼다.
