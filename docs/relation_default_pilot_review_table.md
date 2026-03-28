# relation_default_pilot_review_table

## 범위
- DB 수정 없음. `data/reshet_work.db`를 읽기 전용으로만 조사했다.
- 대상 조건: `category_code='unspecified' AND relation_type='related' AND direction_code='unknown'`
- 조사 행 수: 21
- SQL 초안 포함 후보: 15
- 수동 검토 우선 후보: 6

## 사전 확인
- `WORD_RELATION`, `RELATION_CATEGORY`, `RELATION_TYPE` 스키마를 실제 DB에서 확인했다.
- 현재 lookup 체계:
  - `RELATION_CATEGORY`: `semantic`, `lexical`, `morphological`, `etymological`, `phonological`, `transliteration`, `translation`, `unspecified`
  - 파일럿에서 실제로 쓴 `RELATION_TYPE`: `derived`, `variant`, `compound`, `root_shared`, `borrowed_from`, `loan_translation`, `direct_transliteration`, `related`
  - `direction_code`: `w1_to_w2`, `w2_to_w1`, `undirected`, `unknown`
- 대상 7,244건은 `RELATION_CATEGORY`/`RELATION_TYPE` lookup 조인이 모두 성공했다.
- 문서(`DATABASE_SCHEMA.md`, `DATABASE_SCHEMA_v2.md`, `RELATION_MODEL_v1.md`)와 앱 UI(`word_graph_screen.dart`)는 `direction_code` 4종을 동일하게 사용한다.
- 충돌 가능성 메모:
  - `lib/data/repositories/word_repository.dart`의 주석에는 `unspecified`, `related`가 lookup에 없을 수 있다고 적혀 있지만, 현재 DB lookup에는 두 코드가 모두 존재한다.
  - 런타임 조인 실패는 이번 조사에서 재현되지 않았고, 현재 기준 충돌은 "주석/문서 설명이 실제 DB보다 뒤처진 상태"로 보는 편이 맞다.

## 대상 분포
- 총 대상 수: 7,244
- 주요 언어 조합:
  - 헬라어 ↔ 헬라어: 6,078
  - 히브리어/아람어 ↔ 히브리어/아람어: 538
  - 헬라어 ↔ 히브리어/아람어: 305
  - 헬라어 ↔ 라틴어: 124
  - 영어 ↔ 헬라어: 74
  - 영어 ↔ 라틴어: 68
- source 분포:
  - `WORD_TABLE.관련1`: 5,160
  - `WORD_TABLE.관련2`: 2,037
  - `WORD_TABLE.관련3`: 45
  - `WORD_TABLE.관련4`: 2

## confidence 분포
- 검토표 기준:
  - 높음: 12
  - 중간: 6
  - 낮음: 3
- SQL 초안 기준:
  - 높음: 12
  - 중간: 3
  - 낮음: 0

## 샘플링 메모
- 단순 `LIMIT 60` 초기 조회는 `WORD_TABLE.관련1` 편향이 강해서 대표성이 부족했다.
- 본 검토용 후보 풀 60건은 언어 조합, `source`, 반복 패턴, 의미 유형(음차/파생/차용/calque/구문 포함)을 기준으로 층화해 다시 골랐다.
- 최종 21건은 다음 대표성을 의도했다.
  - 헬라어↔히브리어/아람어 음차 이름군
  - 헬라어 내부 파생/합성 관계
  - 히브리어 내부 파생/축약/개명 사례
  - 라틴어/영어로 넘어간 차용 및 calque
  - `source=관련2/3/4`의 위험 패턴(semantic matching, renaming, phrase relation)
- 최종 선택 분포:
  - `WORD_TABLE.관련1`: 12
  - `WORD_TABLE.관련2`: 5
  - `WORD_TABLE.관련3`: 3
  - `WORD_TABLE.관련4`: 1

## 검토표
| relation_id | sampling_reason | word1 | word2 | current_value | proposed_value | proposal_basis_type | direction_basis | wiktionary_entry | wiktionary_section | evidence_summary | confidence | needs_human_review_reason | sql_ready |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 3 | 헬라어↔히브리어 이름 음차 대표 | `G0002_0000`<br>헬라어<br>`Ἀαρών`<br>아아론<br>아론 | `H0175_0000`<br>히브리어/아람어<br>`אַהֲרֹן`<br>아하론<br>아론 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=transliteration`<br>`type=direct_transliteration`<br>`dir=w2_to_w1` | transliteration | explicit "Borrowed from Biblical Hebrew" phrasing; row order maps `word2 -> word1` | `Ἀαρών` | `Ancient Greek > Etymology` | Greek lemma가 Biblical Hebrew `אַהֲרֹן`에서 빌린 말이라고 직접 적는다. Hebrew 이름을 Greek 표기로 옮긴 전형적 음차 사례다. | 높음 | 행 순서 기준으로 Hebrew(`word2`) -> Greek(`word1`) 매핑만 실행 전 마지막 확인하면 된다. | yes |
| 4 | 헬라어↔히브리어 이름 음차 대표 | `G0003_0000`<br>헬라어<br>`Ἀβαδδών`<br>아받돈<br>아바돈 | `H0011_0000`<br>히브리어/아람어<br>`אֲבַדּוֹן`<br>아받돈<br>파멸/멸망 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=transliteration`<br>`type=direct_transliteration`<br>`dir=w2_to_w1` | transliteration | explicit "Borrowed from Biblical Hebrew" phrasing; row order maps `word2 -> word1` | `Ἀβαδδών` | `Ancient Greek > Etymology` | Greek lemma가 Biblical Hebrew `אֲבַדּוֹן`에서 차용되었다고 명시한다. | 높음 | Greek 음차명과 Hebrew 원형의 대응이 선명하고, 남는 검토 포인트는 row-order 기준 direction 재확인뿐이다. | yes |
| 5 | 히브리어 내부 파생 대표 | `H0006_0000`<br>히브리어/아람어<br>`אָבַד`<br>아바드<br>파멸하다/멸망하다 | `H0011_0000`<br>히브리어/아람어<br>`אֲבַדּוֹן`<br>아받돈<br>파멸/멸망 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=derived`<br>`dir=w1_to_w2` | derived | derived form stated in etymology | `Abaddon` | `English > Etymology` | `Abaddon` 항목이 Hebrew `אֲבַדּוֹן`을 다시 `אבד`("to perish")에서 온 것으로 풀어 준다. 동사 -> 추상명사 파생으로 읽는 편이 가장 안전하다. | 중간 | 직접 Hebrew lemma가 아니라 English intermediary 설명에 기대고 있어, confidence를 높이려면 Hebrew etymology를 한 번 더 닫아야 한다. | yes |
| 6 | 헬라어 내부 공통어근 위험 사례 | `G0922_0000`<br>헬라어<br>`βάρος`<br>바로스<br>짐 | `G0926_0000`<br>헬라어<br>`βαρύς`<br>바뤼스<br>무거운 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=etymological`<br>`type=root_shared`<br>`dir=unknown` | mixed_unclear | insufficient evidence | `βάρος / βαρύς` | `Ancient Greek > Etymology / related root check` | 표기와 의미가 같은 `βαρ-` 계열을 공유해 공통어근 후보는 맞지만, 이번 확인 범위에서는 어느 쪽이 직접 파생인지까지 닫히지 않았다. | 중간 | 공통어근은 보이지만 직접 파생 방향이 닫히지 않아 `root_shared` 외 다른 해석을 밀기 어렵다. | no |
| 10 | 헬라어↔히브리어 이름 음차 대표 | `G0006_0000`<br>헬라어<br>`Ἄβελ`<br>아벨<br>아벨/헤벨 | `H1893_0000`<br>히브리어/아람어<br>`הֶבֶל`<br>헤벨<br>아벨/헤벨 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=transliteration`<br>`type=direct_transliteration`<br>`dir=w2_to_w1` | transliteration | explicit intermediary chain; mapped to row order | `Abel` | `English > Etymology` | `Abel` 항목이 `Ancient Greek Ἅβελ <- Biblical Hebrew הֶבֶל` 경로를 직접 적는다. Greek/Hebrew 대응 자체는 선명하다. | 중간 | Greek lemma direct page 대신 English etymology chain에 기대고 있어, Greek 직접 근거를 보강하면 더 안전하다. | yes |
| 13 | 헬라어↔히브리어 이름 음차 대표 | `G0007_0000`<br>헬라어<br>`Ἀβιά`<br>아비아<br>아비야/아비-야 | `H0029_0000`<br>히브리어/아람어<br>`אֲבִיָּה`<br>아비야<br>아비야/아비-야 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=transliteration`<br>`type=direct_transliteration`<br>`dir=w2_to_w1` | transliteration | explicit "Borrowed from Biblical Hebrew" phrasing; row order maps `word2 -> word1` | `Ἀβιά` | `Ancient Greek > Etymology` | Greek lemma가 Biblical Hebrew `אֲבִיָּה`에서 차용되었다고 직접 적는다. | 높음 | 음차 방향과 category/type 모두 명확하고, 남는 검토 포인트는 row-order 기준 direction 매핑뿐이다. | yes |
| 19 | 이름 음차 패턴 점검용 수동 사례 | `G0008_0000`<br>헬라어<br>`Ἀβιαθαρ`<br>아비아타르<br>아비아달/에브-야타르 | `H0054_0000`<br>히브리어/아람어<br>`אֶבְיָתָר`<br>에브야타르/에베야타르<br>아비아달/에브-야타르 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=transliteration`<br>`type=direct_transliteration`<br>`dir=w2_to_w1` | transliteration | not explicitly stated | `אביתר` | `Hebrew > Proper noun` | Hebrew entry는 `אביתר`가 `Abiathar`라는 이름임을 확인해 준다. 다만 이번 조사에서는 Greek lemma의 etymology line을 같은 수준으로 확보하지 못했다. | 낮음 | 음차 패턴은 강하지만 Greek 쪽 직접 근거가 없어 direction까지 밀기에는 증거가 부족하다. | no |
| 23 | 헬라어↔히브리어 이름 음차 대표 | `G0011_0000`<br>헬라어<br>`Ἀβραάμ`<br>아브라암<br>아브라함/아브-라함 | `H0085_0000`<br>히브리어/아람어<br>`אַבְרָהָם`<br>아브라함/아베라함<br>아브라함/아브-라함 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=transliteration`<br>`type=direct_transliteration`<br>`dir=w2_to_w1` | transliteration | explicit "Borrowed from Biblical Hebrew" phrasing; row order maps `word2 -> word1` | `Ἀβραάμ` | `Ancient Greek > Etymology` | Etymology tree가 Biblical Hebrew `אַבְרָהָם`에서 빌린 것이라고 바로 보여 준다. | 높음 | 음차 방향과 category/type이 모두 닫혀 있다. 실행 전에는 direction code가 row order와 맞는지만 재확인하면 된다. | yes |
| 28 | 형용사 -> 명사 파생 대표 | `G0899_0000`<br>헬라어<br>`βάθος`<br>바토스<br>깊음 | `G0901_0000`<br>헬라어<br>`βαθύς`<br>바튀스<br>깊은 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=derived`<br>`dir=w2_to_w1` | derived | derived form stated in etymology; row order maps `word2 -> word1` | `βάθος` | `Ancient Greek > Etymology` | `βάθος` 항목이 `βαθύς + -ος`라고 직접 적는다. 형용사에서 명사가 파생된 전형적 사례다. | 높음 | 파생 방향이 닫혀 있고, 마지막 확인 포인트는 row-order 기준 direction 매핑뿐이다. | yes |
| 32 | 합성어의 첫 구성요소 대표 | `G0015_0000`<br>헬라어<br>`ἀγαθοποιέω`<br>아가토포이에오<br>좋은 것을 행하다 | `G0018_0000`<br>헬라어<br>`ἀγαθός`<br>아가토스<br>좋은/선한 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=compound`<br>`dir=w2_to_w1` | derived | compound members stated in etymology; row order maps `word2 -> word1` | `ἀγαθοποιέω` | `Ancient Greek > Etymology` | `ἀγαθοποιέω` 항목이 `ἀγαθός + ποιέω`에서 왔다고 명시한다. 이 행은 합성어와 첫 번째 구성요소의 관계다. | 높음 | 구성요소-합성어 관계가 분명하고 direction도 "구성요소 -> 합성어"로 읽힌다. | yes |
| 48 | 라틴어 -> 영어 차용 대표 | `E0000_0032`<br>영어<br>`angel`<br>에인절(엔절)<br>천사 | `L0000_0156`<br>라틴어<br>`ángĕlus`<br>앙겔루스<br>사자 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=etymological`<br>`type=borrowed_from`<br>`dir=w2_to_w1` | borrowing | explicit "from Latin angelus" phrasing; row order maps `word2 -> word1` | `angel` | `English > Etymology 1` | `angel` 항목이 `Latin angelus`를 직접 etymon으로 적는다. 중간에 Old English/Anglo-Norman 보강이 있지만 라틴어 차용 계열이라는 점은 선명하다. | 높음 | 차용 경로가 복합적이긴 하지만 방향 자체는 `Latin -> English`로 안정적이다. | yes |
| 97 | 그리스어 -> 라틴어 차용 후보 | `G0000_0469`<br>헬라어<br>`ἱπποπόταμος`<br>히포포타모스<br>하마 | `L0000_0091`<br>라틴어<br>`hippopótămus`<br>힢포포타무스<br>하마 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=etymological`<br>`type=borrowed_from`<br>`dir=w1_to_w2` | borrowing | explicit intermediary chain; not direct Latin lemma line | `hippopotamus` | `English > Etymology` | English entry는 `Latin/New Latin hippopotamus <- Ancient Greek ἱπποπόταμος`라고 적는다. 차용 방향은 보이지만 이번 표에서는 Latin lemma 자체 section을 닫지 못했다. | 중간 | Latin 직접 section을 다시 확인하기 전까지는 차용 판단이 맞아도 SQL 실행 후보로 올리기엔 한 단계 부족하다. | no |
| 5368 | semantic matching 위험 사례 | `G0003_0000`<br>헬라어<br>`Ἀβαδδών`<br>아받돈<br>아바돈 | `G0623_0000`<br>헬라어<br>`Ἀπολλύων`<br>아폴뤼온<br>아볼루온[파멸자/파괴자] | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=semantic`<br>`type=similar`<br>`dir=unknown` | mixed_unclear | not explicitly stated | `Ἀβαδδών` + `Apollyon` | `Ancient Greek > Usage notes` + `English > Etymology` | `Ἀβαδδών` usage notes는 Greek에서 `ἀπώλεια/ἀπόλλυμι` 계열 calque를 쓴다고 하고, `Apollyon`은 Hebrew Abaddon과의 phono-semantic matching이라고 설명한다. 현재 pair는 semantic matching, calque, 음차가 한데 겹친다. | 낮음 | 하나의 relation code로 고정하기 어려운 mixed case라 confidence를 높게 줄 근거가 없다. | no |
| 5369 | 접두 파생 대표 | `G0004_0000`<br>헬라어<br>`ἀβαρής`<br>아바레스<br>짐이 되지 않는 | `G0922_0000`<br>헬라어<br>`βάρος`<br>바로스<br>짐 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=derived`<br>`dir=w2_to_w1` | derived | derived form stated in etymology; row order maps `word2 -> word1` | `ἀβαρής` | `Ancient Greek > Etymology` | `ἀβαρής` 항목이 `ἀ- + βάρος + -ής`라고 명시한다. 접두 파생으로 보는 것이 가장 자연스럽다. | 높음 | 접두 파생 관계와 direction이 분명하다. 실행 전에는 `derived` 분류 일관성만 점검하면 된다. | yes |
| 5371 | 축약형 대표 | `H3050_0000`<br>히브리어/아람어<br>`יָהּ`<br>야<br>야 | `H3069_0000`<br>히브리어/아람어<br>`יְהֹוָה`<br>예호위<br>부득이 '여호와'로 갈음함 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=variant`<br>`dir=w2_to_w1` | variant | explicit "Contracted form of" phrasing; row order maps `word2 -> word1` | `יה` | `Hebrew > Etymology 1` | `יה` 항목이 `יהוה`의 contracted form이라고 직접 적는다. 축약형/짧은 표기로 보는 편이 맞다. | 높음 | relation 자체는 분명하고, 남는 검토 포인트는 `variant` 라벨을 팀에서 그대로 쓸지 여부뿐이다. | yes |
| 5382 | 합성어의 두 번째 구성요소 대표 | `G0015_0000`<br>헬라어<br>`ἀγαθοποιέω`<br>아가토포이에오<br>좋은 것을 행하다 | `G4160_0000`<br>헬라어<br>`ποιέω`<br>포이에오<br>~하게 하다 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=compound`<br>`dir=w2_to_w1` | derived | compound members stated in etymology; row order maps `word2 -> word1` | `ἀγαθοποιέω` | `Ancient Greek > Etymology` | 같은 `ἀγαθοποιέω` 항목이 `ἀγαθός + ποιέω`라고 적는다. 이 행은 합성어와 두 번째 구성요소의 관계다. | 높음 | 구성요소-합성어 관계와 direction이 닫혀 있다. | yes |
| 5383 | 부정 접두 파생 대표 | `G0022_0000`<br>헬라어<br>`ἄγαμος`<br>아가모스<br>결혼하지 않은 자/미혼자 | `G1062_0000`<br>헬라어<br>`γάμος`<br>가모스<br>혼례/결혼식 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=derived`<br>`dir=w2_to_w1` | derived | derived form stated in etymology; row order maps `word2 -> word1` | `ἄγαμος` | `Ancient Greek > Etymology` | `ἄγαμος` 항목이 `ἀ- + γάμος`라고 적는다. 부정 접두가 붙은 파생어로 읽는 편이 안정적이다. | 높음 | prefix derivation으로 해석이 닫혀 있고 direction도 명확하다. | yes |
| 7480 | 개명/이형 처리 기준 점검용 | `H0085_0000`<br>히브리어/아람어<br>`אַבְרָהָם`<br>아브라함/아베라함<br>아브라함/아브-라함 | `H0087_0000`<br>히브리어/아람어<br>`אַבְרָם`<br>아브람/아베람<br>아브람/아브-람 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=variant`<br>`dir=w2_to_w1` | variant | not explicitly stated | `Abram` | `English > Proper noun` | `Abram` 항목은 Genesis 17:5 인용과 함께 "이제 이름을 Abraham이라 하라"를 보여 준다. 바뀐 이름 관계는 분명하지만 lexical variant와 renaming이 겹친다. | 중간 | 개명인지 lexical variant인지 코드 정책이 선행되지 않으면, 같은 근거를 두고도 해석이 갈릴 수 있다. | no |
| 7482 | 이름-어근 파생 대표 | `H0121_0000`<br>히브리어/아람어<br>`אָדָם`<br>아담<br>아담 | `H0127_0000`<br>히브리어/아람어<br>`אֲדָמָה`<br>아다마<br>땅 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=derived`<br>`dir=w2_to_w1` | derived | explicit etymology note; mapped to pair as base noun -> name | `Adam` | `English > Etymology` | `Adam` 항목이 Hebrew `אדם`이 `אדמה`("ground")에서 왔다고 적는다. 현재 pair는 이름과 기저 명사의 파생 관계로 읽을 수 있다. | 중간 | English etymology를 통한 대응이라, confidence를 더 올리려면 Hebrew 원문 lemma를 한 번 더 확인하는 편이 안전하다. | yes |
| 7488 | Greek -> Latin calque 대표 | `G5459_0000`<br>헬라어<br>`φωσφόρος`<br>포스포로스<br>새벽별/금성/계명성 | `L0000_0028`<br>라틴어<br>`Lúcĭfer`<br>루키페르<br>새벽별/금성/계명성 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=etymological`<br>`type=loan_translation`<br>`dir=w1_to_w2` | calque | explicit "calque of Greek" phrasing; row order maps `word1 -> word2` | `Lucifer` | `Latin > Etymology` | Latin `Lucifer` 항목이 `lūx + -fer`, 그리고 Ancient Greek `Φωσφόρος`의 calque라고 직접 적는다. | 높음 | calque 관계와 direction이 모두 명확하다. 남는 검토 포인트는 category/type를 팀에서 그대로 승인할지 여부다. | yes |
| 7543 | phrase linkage 위험 사례 | `G2064_0000`<br>헬라어<br>`ἔρχομαι`<br>에르코마이<br>오다/가다 | `G3801_0000`<br>헬라어<br>`ὁ ὢν ὁ ἦν ὁ ἐρχόμενος`<br>호 온 호 엔 호 에르코메노스<br>계시고, 계셨고, 오실 분 | `cat=unspecified`<br>`type=related`<br>`dir=unknown` | `cat=morphological`<br>`type=derived`<br>`dir=w1_to_w2` | mixed_unclear | insufficient evidence | `ἔρχομαι` | `Ancient Greek > participial usage cross-check` | 표면적으로는 phrase 안의 `ἐρχόμενος`가 `ἔρχομαι`에서 온 분사형이지만, 현재 row의 대상은 단일 lemma가 아니라 전체 구문이다. | 낮음 | phrase-component 관계를 현재 코드 체계에 바로 넣을 기준이 없어, direction과 type 모두 보수적으로 보류하는 편이 맞다. | no |

## 판정 메모
- 자동 제안 기준:
  - Wiktionary에 `Borrowed from`, `From`, `Contracted form of`, `calque of`처럼 직접적인 관계 서술이 있다.
  - 그 서술을 현재 row의 `word1`/`word2`에 그대로 대응시킬 수 있다.
  - `direction_code`를 `word_id_1`/`word_id_2` 순서로 무리 없이 변환할 수 있다.
- 수동 검토 기준:
  - common root만 보이고 직접 파생 방향이 닫히지 않는 경우
  - 개명/별칭/동일인물 alias처럼 어휘 관계와 개체 관계가 섞인 경우
  - phrase 전체와 lemma 하나가 연결된 경우
  - semantic matching / calque / transliteration이 한 row 안에 겹쳐 코드 체계가 애매한 경우

## proposal_basis_type 기준
- `transliteration`: 이름/표기가 다른 문자 체계로 옮겨졌다는 근거가 직접 보일 때
- `borrowing`: 한 언어 항목이 다른 언어 항목에서 왔다고 직접 말할 때
- `calque`: calque, loan translation처럼 번역 차용이라고 직접 보일 때
- `derived`: 접두/접미/합성/명사화처럼 형태론적 구성이나 파생이 적시될 때
- `variant`: contracted form, renamed/alternate form처럼 이형 또는 축약 관계가 중심일 때
- `mixed_unclear`: 위 근거가 둘 이상 겹치거나, 직접 서술이 부족해 단일 basis로 닫기 어려울 때
