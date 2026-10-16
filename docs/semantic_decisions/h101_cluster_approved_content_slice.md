# H101 그릇·음악·가트 이름군 의미 및 관계 결정

- 상태: `active`
- 기록 성격: 승인 결정·적용 기록
- 승인일: 2026-10-16 (Asia/Seoul)
- 적용일: 2026-10-17 (Asia/Seoul)
- 대상: CORE14 의미와 비고, 신규 관계13건
- 승인 manifest: [h101_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h101_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 신규 hold 없음, 기존 [hold ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json) 6건 유지
- 원본 연구: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H101_cluster_20261016_25554f27/`
- 승인 원문·최종값·byte 백업·SQL 검증: `data/backups/approved_content_batch/h101_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261016T150123404020Z/`

## 최종 결정

사용자는 최초 추천 중 추가 검토 항목 외의 제안을 승인한 뒤, 의미 범위·명사 형성·원천 이름 병기·읽기 쉬운 표기에 관한 최신 피드백 수정안을 채택했다. 이어 DB·문서·필요한 파일 반영, 이상 없는 경우 커밋·병합·push와 이번 작업 브랜치 정리까지 승인했다. 아래 최종값이 최초 연구 추천보다 우선한다.

| Strong | seq1 최종 meaning | canonical 출현 |
| --- | --- | ---: |
| H0101 | 오목한 그릇 | 3 |
| H5059 | 연주하다(演奏하다) | 15 |
| H1660 | 포도즙(葡萄汁) 틀 | 5 |
| H4485 | 비웃는 노래 | 1 |
| H5058 | 음악(音樂) | 14 |
| G1068 | 겟세마네·가트-셰마네 (지) | 2 |
| H1661 | 가드·가트 (지) | 33 |
| H1662 | 가드헤벨·가트-하헤페르 (지) | 2 |
| H1663 | 가드 사람·가트 사람 | 10 |
| H1664 | 깃다임·깃타임 (지) | 2 |
| H1667 | 가드림몬·가트-림몬 (지) | 4 |
| H4182 | 가드모레셋·모레셋가드·모레셰트-가트 (지) | 1 |
| H4183 | 모레셋 사람·모레셰트 사람 | 2 |
| H1665 | 깃딧·깃티트 | 3 |

모두 1 sense이며 H5058의 초기 2행 추천은 최종안에서 음악 1행으로 통합했다. Meaning replacement14·word note replacement13·relation create13, 총40 DB write다. H4183 비고는 기존 NULL을 유지한다. Expression·음역·발음·언어·Strong identity·graph_expand_mode·schema·seed DB는 변경하지 않는다. 기존 의미 승인과의 supersession은 없다.

### 최종 비고

**H0101**

> 양푼·사발·잔과 같은 그릇을 가리키며, 크기·재질이나 의식용이라는 용도를 특정하지 않는다. 오목한 그릇이라는 풀이는 사발·대야 계열을 나타내며 정확한 깊이나 곡률을 규정하지 않는다. 이사야 22:24에서는 집안 식구들을 그릇에 빗댄다. H5059와의 어원 관계는 Strong도 추정으로 제시한다.

**H5059**

> 분사형은 악기를 연주하는 사람을 가리킨다. 성경 용례에서는 특히 현악기 연주와 연결되지만, Strong의 일반적인 음악 연주 풀이와 성경 밖 사전의 피리 연주 설명을 고려하여 현악기에만 배타적으로 한정하지 않는다. 구약에서 피리 연주 용례가 직접 확인되었다는 뜻은 아니며, 번역본의 수금·거문고를 특정 악기 하나로 고정하지 않는다.

**H1660**

> 포도를 밟아 즙을 내는 시설로, 포도를 담아 밟는 통이나 공간도 가리킨다. 삿 6:11의 밀 타작은 그 시설의 다른 사용이며, 사 63:2·애 1:15·욜 3:13에서는 심판을 포도 밟기에 빗댄다. 겟세마네를 기름 짜는 틀로 풀이하는 합성 이름에서 관련 말의 확장 사용을 볼 수 있지만, 이것만으로 구약의 이 단어를 모든 기름틀·압착틀로 일반화하지 않는다. H5059에서 유래했다는 설명은 추정이다.

**H4485**

> 성경의 유일한 용례인 애 3:63에서는 화자 자신이 남들의 비웃음의 노랫거리가 되는 상황을 가리킨다. 이 성경 문맥을 meaning에 반영한 것이며, 명사 형성 요소 מ 자체가 비웃음을 뜻하거나 모든 시대에 조롱만을 뜻한다고 단정하지 않는다. 성경 밖 후대 자료에는 조롱과 무관한 음악 용법도 확인되지만, 고대의 일반적인 노래 의미를 직접 입증한 것으로 소급하지 않는다.

**H5058**

> 연주와 노래를 포괄하며, 성경에서는 특히 현악기로 연주하는 음악과 그 반주·악기를 가리킨다. 노래를 뜻할 때에는 비웃는 노래도 포함한다(욥 30:9; 시 69:12; 애 3:14). 시편 표제와 합 3:19에서는 연주 지시로 쓰인다. 음악·반주·악기 가운데 정확히 무엇을 지시하는지는 문맥마다 확정되지 않으며, 음악이라는 포괄 표현으로 하나의 meaning에 정리한다.

**G1068**

> 아람어계 어원으로 '기름 짜는 틀'이라는 풀이가 전해지는 지명이다. 겟세마네는 한국어 성경의 관용명이고 가트-셰마네는 그 어원 풀이에 따른 분석 표기다. 독립된 아람어 원자료에서 정확한 원형·모음·당대 발음을 확인한 직접 전사로 단정하지 않는다. 마 26:36·막 14:32에서는 예수께서 기도하신 장소의 이름이다. Strong의 H1660·H8081 compare를 두 히브리어 단어에서 헬라어 표제어가 직접 만들어졌다는 확정 관계로 바꾸지 않는다.

**H1661**

> 가드는 한국어 성경의 관용 표기이고 가트는 원문 형태를 보여주는 표기다. 포도즙 틀을 뜻하는 H1660과 같은 형태가 도시명으로 쓰인다. 개별 본문이 가리키는 장소를 특정 현대 유적 하나로 일괄 고정하지 않는다.

**H1662**

> 가드헤벨은 한국어 성경의 관용명이고 가트-하헤페르는 표제형의 구성을 드러내는 표기다. 수 19:13의 깉타-헤페르는 OSHB가 방향 표시 접미형으로 분석하는 본문 형태이며 Strong의 짧은 형태 설명과 함께 참고한다. 분석 표기는 고대 실제 발음의 복원이 아니다. Strong은 H1660과 H2658의 결합으로 '우물의 포도즙 틀'을 풀이한다. 원전분해는 두 요소를 H1660·H2660으로 나누므로 그 marker 수를 H1662의 출현 수로 대체하지 않는다.

**H1663**

> 가드에서 온 사람 또는 가드에 속한 사람을 가리키는 출신지 형용사다. 가드 사람은 한국어 성경 관용 표기이고 가트 사람은 기반 지명 가트의 표기를 풀어 쓴 표현이다. 오벧에돔·잇대·골리앗 등에 붙으며 이 낱말만으로 모두 같은 혈통이나 민족이라고 단정하지 않는다.

**H1664**

> 깃다임은 한국어 성경의 관용명이고 깃타임은 읽기 쉬운 원문 기반 이름 표기다. 현재 expression의 깉타임 음역은 별도로 보존한다. 두 표기는 서로 다른 장소나 별도 sense를 나타내지 않는다. Strong은 H1660의 쌍수형으로 이름을 설명하지만, 이름만으로 현장에 포도즙 틀이 실제 두 개 있었다고 단정하지 않는다.

**H1667**

> 가드림몬은 관용명이고 가트-림몬은 이름의 구성을 보여준다. Strong은 H1660과 H7416의 결합으로 풀이한다. 수 21:25의 가드림몬은 LXX의 다른 지명 및 병행 목록 대상 6:70의 빌르암과 차이가 있어 정확한 지리적 동일시가 불확실하다. 현재 히브리어 본문에 있는 이름은 보존한다.

**H4182**

> 가드모레셋은 개역 계열의 관용 표기, 모레셋가드는 새번역의 순서와 현재 DB 이름, 모레셰트-가트는 원문 구성 표기다. Strong은 H3423과 H1661의 결합으로 '가드의 소유지'를 풀이한다. 미 1:14의 어원적 말놀이는 별도의 보통명사 meaning으로 늘리지 않는다.

**H4183**

> `NULL` 유지

**H1665**

> 시 8·81·84편 표제의 음악 지시어다. 깃딧은 한국어 성경 관용 표기이고 깃티트는 원문 자음 구성을 보여 주는 분석 표기로, 특정 시대의 실제 발음을 확정하지 않는다. Strong은 가드 사람형 H1663의 여성형으로 가드의 수금을 풀이하지만, 가드에서 온 악기·곡조인지 정확히 확정되지 않는다. LXX의 해당 표제는 '포도주틀들에 관하여'로 전한다. 특정 악기나 포도 수확 노래 하나로 단정하지 않는다.

### 관계 결정

| 의미 방향 | 신규 ID | category / type / status | canonical 저장 방향 |
| --- | ---: | --- | --- |
| H5059 → H4485 | 7868 | morphological / derived / asserted | `H4485_0000`–`H5059_0000`, `w2_to_w1` |
| H5059 → H5058 | 7869 | morphological / derived / asserted | `H5058_0000`–`H5059_0000`, `w2_to_w1` |
| H1660 → H1661 | 7870 | morphological / derived / asserted | `H1660_0000`–`H1661_0000`, `w1_to_w2` |
| H1660 → H1662 | 7871 | morphological / compound / asserted | `H1660_0000`–`H1662_0000`, `w1_to_w2` |
| H2658 → H1662 | 7872 | morphological / compound / asserted | `H1662_0000`–`H2658_0000`, `w2_to_w1` |
| H1660 → H1664 | 7873 | morphological / derived / asserted | `H1660_0000`–`H1664_0000`, `w1_to_w2` |
| H1660 → H1667 | 7874 | morphological / compound / asserted | `H1660_0000`–`H1667_0000`, `w1_to_w2` |
| H7416 → H1667 | 7875 | morphological / compound / asserted | `H1667_0000`–`H7416_0000`, `w2_to_w1` |
| H1661 → H1663 | 7876 | morphological / derived / asserted | `H1661_0000`–`H1663_0000`, `w1_to_w2` |
| H1661 → H4182 | 7877 | morphological / compound / asserted | `H1661_0000`–`H4182_0000`, `w1_to_w2` |
| H3423 → H4182 | 7878 | morphological / compound / asserted | `H3423_0000`–`H4182_0000`, `w1_to_w2` |
| H4182 → H4183 | 7879 | morphological / derived / asserted | `H4182_0000`–`H4183_0000`, `w1_to_w2` |
| H1663 → H1665 | 7880 | morphological / derived / hypothesized | `H1663_0000`–`H1665_0000`, `w1_to_w2` |

신규13건은 asserted12·hypothesized1이다. H1663→H1665는 Strong의 feminine of를 보존하되 실제 음악 지시어의 기원 해석이 경쟁하므로 가설로 둔다. Asserted도 원자료의 명시적 lexical 형태 설명을 채택한 것이며 독립적인 역사언어학 확정이나 현대 장소 동일시를 뜻하지 않는다.

- **비생성2**: H5059→H0101, H5059→H1660은 probably 어원이므로 새 관계를 생성하지 않는다.
- **기존 유지2**: G1068–H1660 ID3645, G1068–H8081 ID6525의 unspecified/related/inferred/unknown과 기존 raw 행을 그대로 유지한다. Compare를 확정 직접 파생·합성으로 바꾸지 않는다.
- **CONTEXT**: H2658·H2660·H3423·H7416·H7417·H8081의 의미·비고를 승인하거나 변경하지 않는다. 승인된 구성 관계의 끝점으로만 사용하는 경우를 구분한다.

## 판단 근거와 미채택 대안

**H0101**: 그릇 일반으로 넓히면 사발·대야 계열과 항아리 등의 구별이 약해진다. 오목한은 정확한 깊이·곡률의 필수조건을 확정한 말이 아니다. 사발·대야·잔 등의 크기·용도 차이는 별도 sense로 늘리지 않는다.

용례 근거: 출 24:6은 피를 담는 양푼, 아 7:3(OSHB; 한국어 7:2)은 배꼽을 빗댄 둥근 잔, 사 22:24는 작은 그릇이다. 용도와 크기 차이를 별도 sense로 만들 근거는 없다.

**H5059**: 초기 현악기 전용 추천을 연주하다로 수정했다. Strong 자체의 일반적인 음악 연주 풀이와 Ben-Yehuda의 피리 연주 설명을 반영한다. 구약의 직접 피리 용례나 일반 타격 동사 의미를 새로 입증한 것으로 해석하지 않는다.

용례 근거: 15토큰/12절. 삼상 16:16의 2토큰과 왕하 3:15의 3토큰을 각각 보존했다. 다윗의 연주, 엘리사의 연주자, 시 33:3·68:26, 사 23:16·38:20, 겔 33:32가 모두 연주 행위 또는 연주자를 가리킨다.

**H1660**: 기본 뜻은 포도즙 틀이다. 삿6:11의 밀 타작은 시설의 다른 사용이고, 겟세마네의 기름틀 풀이만으로 구약의 이 단어를 모든 압착기구의 일반명사로 확대하지 않는다. 성경 밖 자료의 포도용 גת와 올리브용 בד 구별도 참고했다.

용례 근거: 실제 시설 2회(삿 6:11·느 13:15), 심판에 사용한 형상 3회(사 63:2·애 1:15·욜 4:13 OSHB). Strong은 wine-press와 포도를 담아 누르는 vat를 함께 설명한다.

**H4485**: Strong·BDB가 성경 유일 용례에 근거해 정의한 비웃는 노래를 유지한다. מ는 명사 형성 요소이며 조롱을 나타내는 접두사가 아니다. 후대의 조롱과 무관한 음악 용법은 확인되지만, 같은 시대의 일반 노래 용례를 직접 확인한 것으로 소급하지 않는다.

용례 근거: 유일한 애 3:63은 '나는 그들의 노래'라는 문맥이다. canonical Strong은 satire를, HebGrkKo는 조롱하는 노래를 제시한다. 앞뒤의 적대적 행동과 개역개정·새번역이 이를 지지한다.

**H5058**: 초기 현악 / 노래의 2행 추천을 음악(音樂) 1행으로 통합했다. BDB의 상위 정의 music 및 연주·노래를 함께 포괄하는 한국어 표현을 따른다. 현악 반주·악기 자체의 환유·조롱 노래와 정확한 세부 지시의 불확실성은 비고에 보존한다. 초기 8+6 용례 배치는 검토 편의를 위한 분류이며 최종 독립 2 sense 승인으로 해석하지 않는다.

용례 근거: 현악·반주 영역 8회는 시 4·6·54·55·61·67·76편 표제와 합 3:19이다. 노래 영역 6회는 욥 30:9, 시 69:13·77:7, 사 38:20, 애 3:14·5:14이며, 이 중 비웃는 노래는 3회다. 사 38:20은 노래와 연주가 겹치는 경계 용례다.

**G1068**: 겟세마네 단독에서 가트-셰마네를 병기하는 안으로 수정했다. 후자는 아람어계 어원 분석 표기이며 독립 아람어 원자료의 정확한 원형·모음·당대 발음에 대한 확정 전사가 아니다. 히브리어 두 단어로 이루어진 헬라어 합성어라는 확정 관계를 만들지 않는다.

용례 근거: TAGNT NA27/28 canonical 2토큰은 모두 장소명이다. source 표제 Γεθσημανῆ, 실제 형태 Γεθσημανί 계열과 현재 승인 expression Γεθσημανί를 구분했다.

**H1661**: 영문 Gath는 의미 필드에 중복할 필요가 없다. 포도즙 틀은 이름의 배경이지 이 Strong의 독립 보통명사 sense가 아니다.

용례 근거: 33토큰/31절을 전량 검토했다. 블레셋 도시, 그 왕·주민, 이동과 전쟁의 목적지 및 시 56편 표제의 지명 사용이 한 이름 뜻으로 묶인다. 두 번 나오는 왕상 2:39·40도 각각 2토큰으로 보존했다.

**H1662**: 우물의 포도즙 틀·판 포도즙 틀은 어원 설명으로 보존하고 별도 보통명사 뜻으로 넣지 않는다. 관용명만 쓰는 대안도 가능하지만 이번 제안은 두 source 형태의 분석 가치를 함께 보존한다.

용례 근거: 수 19:13의 גִּתָּה חֵפֶר와 왕하 14:25의 גַּת הַחֵפֶר를 실제 전체 구절에서 확인했다. OSHB는 H1662를 마지막 구성어에 표기한다. 둘 다 지명이며 한국어 역본은 가드헤벨로 식별한다.

**H1663**: 가드 사람 단독에서 가트 사람을 병기했다. H4259의 므훌랏 사람·므흘랏 사람·므홀랏 사람·메홀라 사람과 H3505의 관용명·기반 이름 풀이 병기 선례를 적용했다. 깉티는 expression에 있는 소속형 음역으로 보존하고 meaning에 별도 인명으로 추가하지 않는다.

용례 근거: 10토큰/10절은 가드 출신형이다. 수 13:3의 집단, 삼하 6:10·11 및 대상 13:13의 오벧에돔, 삼하 15·18장의 잇대와 병사들, 삼하 21:19·대상 20:5의 골리앗 문맥을 전량 비교했다.

**H1664**: 초기 깃다임·깉타임에서 깃다임·깃타임으로 수정했다. 기존 음역 깉타임은 expression에 보존하며 meaning의 읽기 쉬운 이름 병기와 구분한다. 쌍수형 어원은 실제 시설 두 개나 별도 일반명사 sense를 확정하지 않는다.

용례 근거: 삼하 4:3은 방향 접미가 붙은 지명, 느 11:33은 지명 목록이다. 2/2가 장소 이름이며 쌍수형의 어원 풀이와 lexical 뜻을 분리한다.

**H1667**: 석류즙 틀은 어원 풀이로만 보존한다. LXX ιεβαθα나 병행 빌르암으로 현재 H1667 meaning을 교체하지 않는다.

용례 근거: 수 19:45·21:24·21:25와 대상 6:54(OSHB; 한국어 6:69) 모두 가드림몬 이름이다. 둘 이상의 지역 식별과 한 어휘의 의미 수는 구분한다.

**H4182**: 소유·상속을 이 지명의 별도 meaning으로 만들지 않는다. 한국어 관용 순서 차이는 동일 이름 한 sense의 병기다.

용례 근거: 미 1:14의 מוֹרֶשֶׁת גַּת를 원문 전체와 번역본에서 확인했다. source H3423/H1661, LXX의 κληρονομιας γεθ가 이름의 소유·가드 구성을 비교할 참고가 된다.

**H4183**: 모레셋 사람에 모레셰트 사람을 병기했다. H4182의 원문 기반 지명 표기와 출신명 병기 선례를 반영한다. 전체 소속형 모라쉬티 음역·기존 원어 표기는 expression에 보존하고 비고 NULL도 유지한다.

용례 근거: 렘 26:18·미 1:1에서 미가의 출신지를 나타낸다. Strong patrial from H4182와 두 용례가 일치하며, 최신 승인에서는 같은 출신지의 관용형과 원문 기반 표기를 한 meaning에 병기했다.

**H1665**: 깃딧 단독에서 깃티트를 병기했다. 깃팃의 ㅍ에 대응하는 자음은 원문에 없어 채택하지 않았다. 기존 깉티트 음역은 expression에서 보존한다. Strong의 가드 수금, 악기·곡조, LXX의 포도주틀 풀이가 경쟁하므로 구체 지시 대상 3/3은 미해결이며 명칭 식별과 불확실성 비고를 승인한 것이다.

용례 근거: 3/3은 같은 표제 구조 על־הגיתית에 있다. canonical Strong의 Gittite harp, local reference의 악기·곡조·포도 수확 해석, LXX 시 8·80·83편 표제를 모두 비교했다. 음악 지시어의 명칭 식별 수준에서 깃딧·깃티트를 병기하고 구체 지시 대상은 미확정으로 남긴다.

H1662의 수19:13 깉타-헤페르는 OSHB 방향 표시 접미형을 포함하는 본문 형태이므로 별도 meaning 이름으로 늘리지 않는다. H1667 수21:25는 LXX의 다른 지명과 병행 목록 대상6:70의 빌르암 문제를 남기며 현재 히브리어 이름을 자동 교정하지 않는다. H1663의 출신 형용사만으로 관련 인물의 혈통·민족을 일괄 확정하지 않는다.

출신명 병기 선례는 [H4259 결정](h58_cluster_approved_content_slice.md), [H3505 결정](h54_cluster_approved_content_slice.md), [H8016 결정](h53_cluster_approved_content_slice.md)과 적용 전 현행 DB에서 교차확인했다. 가운데점은 같은 이름의 표현 병기이고, 붙임표는 분석적 구성 경계이며, 기존 expression 체계를 재작성하거나 고대 발음을 복원한 것은 아니다.

### 원천과 참고자료 경계

Canonical lexical authority는 [strong_sources.json](../../tool/data_provenance/manifests/strong_sources.json)에 고정된 [HebrewStrong 원문](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml)·[Greek Strong 원문](https://raw.githubusercontent.com/morphgnt/strongs-dictionary-xml/dd6758b82f46b620804a8ea677d715844679eea1/strongsgreek.xml)이다. 출현 authority는 [biblical_occurrence_sources.json](../../tool/data_provenance/manifests/biblical_occurrence_sources.json)의 OSHB와 TAGNT canonical membership이다.

추가 의미 판단은 BDB H101·H4485·H5058·H5059의 정의, Ben-Yehuda의 [נָגַן](https://benyehuda.org/dict/24412/49256)·[נְגִינָה](https://benyehuda.org/dict/24412/49245)·[מַנְגִּינָה](https://benyehuda.org/dict/24412/47970)·[גַּת](https://ebydict.benyehuda.org/definition/view/54170), [카츠넬손의 실제 후대 작품](https://benyehuda.org/read/48533), [Gesenius 문법 §85](https://en.wikisource.org/wiki/Gesenius%27_Hebrew_Grammar/85._Nouns_with_Preformatives_and_Afformatives), [WiBiLex Gethsemane](https://www.die-bibel.de/stichwort/48924/)를 참고했다. 성경 시대·후대·현대의 증거를 동일시하지 않는다. 이 참고자료를 새 canonical data source로 도입하거나 원문을 재배포 DB에 import하지 않았다.

## 연구 경계와 남은 불확실성

공식 discovery는 122노드·125관계에서 expanded64·frontier58, stopped_reason=max_nodes_reached·discovery_complete=false·research_complete=false로 멈췄다. CORE14·CONTEXT6·HUB-EXCLUDED102 경계를 유지하며 전체 graph closure를 선언하지 않는다. CORE14의 canonical97토큰/90절(Hebrew95·Greek2), 전체 Packet·Relation·Review42개 및 원문 문맥을 검토한 범위의 승인을 완료한 것이다. H1 등 큰 허브 방향의 외곽은 재연구·승인하지 않았다.

Local reference의 automatic join 미해결9토큰은 명시적 verse 후보를 별도로 확인했으며 source profile을 검증된 것으로 승격하지 않았다. LXX98개 명시적 lookup의 matched93·unmatched5 및 번호가 달라 거부한 후보를 원본 evidence에 보존한다. LXX는 provenance·license 미검증 human reference이며 Hebrew–Greek 자동 정렬·관계 생성 authority가 아니다. H1665의 음악 지시 대상, G1068의 정확한 원형·발음, H1667의 지리적 식별, H101/H1660 추정 어원은 미해결이다. 이 불확실성은 비고·가설 관계·관계 비생성으로 보존하며 새 word hold를 만들지 않는다.

새 직접 용례·원자료·형태·본문비평 증거가 기존 범위를 실질적으로 바꿀 때 사용자 판단으로 재검토한다. 동일한 번역어 발견이나 후대 용법만으로 고대 의미를 자동 확대하지 않는다.

## 적용과 검증

공식 dry-run에서 사본 적용·실제 undo·원본 불변이 성공했고 live apply도 성공했다. History group `1792162884626272`, ID6115–6154는 active40행(word update27·relation create13), undone0이다. 독립 SQL81조회·282검증에서 전체13테이블·DDL·snapshot·byte 백업을 대조했고 승인 변경·history40행·해당 sequence 외 변경이 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 기존 applicator Flutter 테스트31건이 통과했다. 조회 목적·실행 SQL·결과·해석은 `04_independent_db_verification.json`에 보존한다.

Work SHA `25554f27cafaa5dec997b8bf9839e5d3866de50a6d01a8d8c49a911232369989` → `011938a8149ad6c4610fa5524eaa7a1113c2d23e83d00fea21c5d03122ca7bb7`, seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. Approval SHA `35929a29729fa6052d73a73594384b61b75f5cd3ee4b91d662702501281f86ed`, manifest SHA `38d365b34f62fbe8e50acc6461758b17406f1b391f26e550ca3fb29293ad6e3a`이며 UTF-8 LF·경로별 `.gitattributes` text eol=lf로 실제 적용 사본과 Git blob을 일치시킨다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298행 중 CORE14만 unapproved→explicit_approved이며 승인299→313·미승인13,993→13,979·hold6·anomaly113이다. Progress 독립 검증22건에서 비대상 행·canonical relation index·anomaly 불변과 공식 CSV/Markdown render 일치를 확인했다. Snapshot identity는 `be914feae22aec40a3b750ac68e1dfb4d5e1a850207e9184a3950365a434c93a`다.

원본 연구57파일과 machine state/queue·최초 추천서는 적용 전 snapshot으로 보존한다. 최신 승인값과 실제 적용 결과는 외부 `00_applied_content.md/json`에 별도로 기록한다. 앱/UI 코드·schema 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다. Work DB는 기존 정책대로 Git 미추적 로컬 자산이며 seed 변경·앱 설치 DB 교체·배포는 이번 범위가 아니다.
