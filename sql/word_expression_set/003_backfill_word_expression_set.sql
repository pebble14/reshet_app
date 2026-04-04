BEGIN IMMEDIATE TRANSACTION;

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
backfill_source AS (
  SELECT
    word_id,
    seq,
    CASE WHEN seq = 1 THEN 1 ELSE 0 END AS is_representative,
    spelling,
    transliteration,
    pronunciation
  FROM expected_expression_set
)
INSERT INTO word_expression_set (
  word_id,
  seq,
  is_representative,
  spelling,
  transliteration,
  pronunciation
)
SELECT
  word_id,
  seq,
  is_representative,
  spelling,
  transliteration,
  pronunciation
FROM backfill_source
WHERE NOT EXISTS (
  SELECT 1
  FROM word_expression_set
);

COMMIT;
