-- draft_update_word_relation_pilot.sql
-- 실행 금지. 파일럿 검토용 초안만 기록한다.
-- 포함 기준:
-- 1) Wiktionary 근거가 직접적이거나 꽤 선명한 건
-- 2) direction_code를 row order 기준으로 보수적으로 확정할 수 있는 건
-- 3) confidence가 높음 위주이고, 중간은 근거가 충분히 선명한 경우만 포함

-- relation_id=3
-- entry: Ἀαρών
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: Greek lemma가 Biblical Hebrew אַהֲרֹן에서 차용되었다고 명시.
-- direction note: word2(H0175_0000) -> word1(G0002_0000)
UPDATE WORD_RELATION
SET category_code='transliteration',
    relation_type='direct_transliteration',
    direction_code='w2_to_w1'
WHERE id=3
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=4
-- entry: Ἀβαδδών
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: Greek lemma가 Biblical Hebrew אֲבַדּוֹן에서 차용되었다고 명시.
-- direction note: word2(H0011_0000) -> word1(G0003_0000)
UPDATE WORD_RELATION
SET category_code='transliteration',
    relation_type='direct_transliteration',
    direction_code='w2_to_w1'
WHERE id=4
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=5
-- entry: Abaddon
-- section: English > Etymology
-- confidence: 중간
-- evidence: Hebrew אֲבַדּוֹן이 אבד("to perish")에서 온다고 풀어 줌.
-- direction note: word1(H0006_0000) -> word2(H0011_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='derived',
    direction_code='w1_to_w2'
WHERE id=5
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=10
-- entry: Abel
-- section: English > Etymology
-- confidence: 중간
-- evidence: Abel 항목이 Ancient Greek Ἅβελ, Biblical Hebrew הֶבֶל 경로를 직접 적는다.
-- direction note: word2(H1893_0000) -> word1(G0006_0000)
UPDATE WORD_RELATION
SET category_code='transliteration',
    relation_type='direct_transliteration',
    direction_code='w2_to_w1'
WHERE id=10
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=13
-- entry: Ἀβιά
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: Greek lemma가 Biblical Hebrew אֲבִיָּה에서 차용되었다고 명시.
-- direction note: word2(H0029_0000) -> word1(G0007_0000)
UPDATE WORD_RELATION
SET category_code='transliteration',
    relation_type='direct_transliteration',
    direction_code='w2_to_w1'
WHERE id=13
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=23
-- entry: Ἀβραάμ
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: Etymology tree가 Biblical Hebrew אַבְרָהָם에서 차용되었다고 명시.
-- direction note: word2(H0085_0000) -> word1(G0011_0000)
UPDATE WORD_RELATION
SET category_code='transliteration',
    relation_type='direct_transliteration',
    direction_code='w2_to_w1'
WHERE id=23
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=28
-- entry: βάθος
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: βάθος = βαθύς + -ος 로 직접 제시됨.
-- direction note: word2(G0901_0000) -> word1(G0899_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='derived',
    direction_code='w2_to_w1'
WHERE id=28
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=32
-- entry: ἀγαθοποιέω
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: ἀγαθός + ποιέω 에서 온 합성어라고 명시.
-- direction note: word2(G0018_0000) -> word1(G0015_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='compound',
    direction_code='w2_to_w1'
WHERE id=32
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=48
-- entry: angel
-- section: English > Etymology 1
-- confidence: 높음
-- evidence: English angel이 Latin angelus 계열에서 온다고 직접 설명.
-- direction note: word2(L0000_0156) -> word1(E0000_0032)
UPDATE WORD_RELATION
SET category_code='etymological',
    relation_type='borrowed_from',
    direction_code='w2_to_w1'
WHERE id=48
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=5369
-- entry: ἀβαρής
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: ἀ- + βάρος + -ής 로 직접 제시됨.
-- direction note: word2(G0922_0000) -> word1(G0004_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='derived',
    direction_code='w2_to_w1'
WHERE id=5369
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=5371
-- entry: יה
-- section: Hebrew > Etymology 1
-- confidence: 높음
-- evidence: Contracted form of יהוה 라고 직접 제시됨.
-- direction note: word2(H3069_0000) -> word1(H3050_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='variant',
    direction_code='w2_to_w1'
WHERE id=5371
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=5382
-- entry: ἀγαθοποιέω
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: ἀγαθός + ποιέω 에서 온 합성어라고 명시.
-- direction note: word2(G4160_0000) -> word1(G0015_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='compound',
    direction_code='w2_to_w1'
WHERE id=5382
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=5383
-- entry: ἄγαμος
-- section: Ancient Greek > Etymology
-- confidence: 높음
-- evidence: ἀ- + γάμος 로 직접 제시됨.
-- direction note: word2(G1062_0000) -> word1(G0022_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='derived',
    direction_code='w2_to_w1'
WHERE id=5383
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=7482
-- entry: Adam
-- section: English > Etymology
-- confidence: 중간
-- evidence: Hebrew אדם이 אדמה("ground")에서 온다고 적음.
-- direction note: word2(H0127_0000) -> word1(H0121_0000)
UPDATE WORD_RELATION
SET category_code='morphological',
    relation_type='derived',
    direction_code='w2_to_w1'
WHERE id=7482
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- relation_id=7488
-- entry: Lucifer
-- section: Latin > Etymology
-- confidence: 높음
-- evidence: Latin Lucifer가 Ancient Greek Φωσφόρος의 calque라고 명시.
-- direction note: word1(G5459_0000) -> word2(L0000_0028)
UPDATE WORD_RELATION
SET category_code='etymological',
    relation_type='loan_translation',
    direction_code='w1_to_w2'
WHERE id=7488
  AND category_code='unspecified'
  AND relation_type='related'
  AND direction_code='unknown';

-- SQL 제외 건 메모
-- 6: root_shared는 보이지만 direction 불명확
-- 19: Greek lemma 근거 보강 필요
-- 97: Latin intermediary 재확인 필요
-- 5368: semantic matching / calque / transliteration이 겹쳐 code 선택 애매
-- 7480: 개명/variant 정책 확인 필요
-- 7543: phrase linkage라 현재 code 체계와 어긋남
