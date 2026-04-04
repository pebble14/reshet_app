WITH legacy_slots AS (
  SELECT
    id AS word_id,
    1 AS source_slot,
    TRIM(COALESCE([표기1], '')) AS spelling,
    TRIM(COALESCE([음역1], '')) AS transliteration,
    TRIM(COALESCE([발음1], '')) AS pronunciation
  FROM WORD_TABLE
  UNION ALL
  SELECT
    id,
    2,
    TRIM(COALESCE([표기2], '')),
    TRIM(COALESCE([음역2], '')),
    TRIM(COALESCE([발음2], ''))
  FROM WORD_TABLE
  UNION ALL
  SELECT
    id,
    3,
    TRIM(COALESCE([표기3], '')),
    TRIM(COALESCE([음역3], '')),
    TRIM(COALESCE([발음3], ''))
  FROM WORD_TABLE
  UNION ALL
  SELECT
    id,
    4,
    TRIM(COALESCE([표기4], '')),
    TRIM(COALESCE([음역4], '')),
    TRIM(COALESCE([발음4], ''))
  FROM WORD_TABLE
  UNION ALL
  SELECT
    id,
    5,
    TRIM(COALESCE([표기5], '')),
    TRIM(COALESCE([음역5], '')),
    TRIM(COALESCE([발음5], ''))
  FROM WORD_TABLE
  UNION ALL
  SELECT
    id,
    6,
    TRIM(COALESCE([표기6], '')),
    TRIM(COALESCE([음역6], '')),
    TRIM(COALESCE([발음6], ''))
  FROM WORD_TABLE
),
expected_expression_set AS (
  SELECT
    word_id,
    ROW_NUMBER() OVER (PARTITION BY word_id ORDER BY source_slot) AS seq,
    spelling,
    NULLIF(transliteration, '') AS transliteration,
    NULLIF(pronunciation, '') AS pronunciation
  FROM legacy_slots
  WHERE spelling <> ''
),
expected_expression_set_with_representative AS (
  SELECT
    word_id,
    seq,
    CASE WHEN seq = 1 THEN 1 ELSE 0 END AS is_representative,
    spelling,
    transliteration,
    pronunciation
  FROM expected_expression_set
),
expected_issues AS (
  SELECT
    word_id,
    source_slot,
    NULLIF(spelling, '') AS raw_spelling,
    NULLIF(transliteration, '') AS raw_transliteration,
    NULLIF(pronunciation, '') AS raw_pronunciation,
    'supplemental_without_spelling' AS issue_code,
    'manual_cleanup_required' AS resolution
  FROM legacy_slots
  WHERE spelling = ''
    AND (transliteration <> '' OR pronunciation <> '')
),
seq_failures AS (
  SELECT word_id
  FROM word_expression_set
  GROUP BY word_id
  HAVING MIN(seq) <> 1 OR MAX(seq) <> COUNT(*)
),
representative_failures AS (
  SELECT word_id
  FROM word_expression_set
  GROUP BY word_id
  HAVING SUM(CASE WHEN is_representative = 1 THEN 1 ELSE 0 END) <> 1
),
expected_minus_actual AS (
  SELECT
    word_id,
    seq,
    is_representative,
    spelling,
    transliteration,
    pronunciation
  FROM expected_expression_set_with_representative
  EXCEPT
  SELECT
    word_id,
    seq,
    is_representative,
    spelling,
    transliteration,
    pronunciation
  FROM word_expression_set
),
actual_minus_expected AS (
  SELECT
    word_id,
    seq,
    is_representative,
    spelling,
    transliteration,
    pronunciation
  FROM word_expression_set
  EXCEPT
  SELECT
    word_id,
    seq,
    is_representative,
    spelling,
    transliteration,
    pronunciation
  FROM expected_expression_set_with_representative
)
SELECT
  (SELECT COUNT(*) FROM expected_expression_set_with_representative) AS expected_row_count,
  (SELECT COUNT(*) FROM word_expression_set) AS actual_row_count,
  (SELECT COUNT(*) FROM expected_issues) AS expected_issue_count,
  (SELECT COUNT(*) FROM seq_failures) AS seq_integrity_failure_count,
  (SELECT COUNT(*) FROM representative_failures) AS representative_failure_count,
  (SELECT COUNT(*) FROM word_expression_set WHERE LENGTH(TRIM(spelling)) = 0) AS blank_spelling_count,
  (
    SELECT COUNT(*)
    FROM word_expression_set
    WHERE transliteration IS NOT NULL
      AND LENGTH(TRIM(transliteration)) = 0
  ) AS empty_transliteration_string_count,
  (
    SELECT COUNT(*)
    FROM word_expression_set
    WHERE pronunciation IS NOT NULL
      AND LENGTH(TRIM(pronunciation)) = 0
  ) AS empty_pronunciation_string_count,
  (SELECT COUNT(*) FROM expected_minus_actual) AS expected_minus_actual_count,
  (SELECT COUNT(*) FROM actual_minus_expected) AS actual_minus_expected_count;
