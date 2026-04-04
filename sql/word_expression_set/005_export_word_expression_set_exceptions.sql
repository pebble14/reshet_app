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
)
SELECT
  word_id,
  source_slot,
  raw_spelling,
  raw_transliteration,
  raw_pronunciation,
  issue_code,
  resolution
FROM expected_issues
ORDER BY word_id, source_slot;
