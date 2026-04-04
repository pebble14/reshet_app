BEGIN IMMEDIATE TRANSACTION;

CREATE TABLE IF NOT EXISTS word_expression_set (
  id INTEGER PRIMARY KEY,
  word_id TEXT NOT NULL,
  seq INTEGER NOT NULL,
  is_representative INTEGER NOT NULL,
  spelling TEXT NOT NULL,
  transliteration TEXT,
  pronunciation TEXT,
  FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE,
  CHECK (seq >= 1),
  CHECK (is_representative IN (0, 1)),
  CHECK (LENGTH(TRIM(spelling)) > 0),
  CHECK (transliteration IS NULL OR LENGTH(TRIM(transliteration)) > 0),
  CHECK (pronunciation IS NULL OR LENGTH(TRIM(pronunciation)) > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_word_expression_set_word_seq
ON word_expression_set(word_id, seq);

CREATE UNIQUE INDEX IF NOT EXISTS ux_word_expression_set_one_representative
ON word_expression_set(word_id)
WHERE is_representative = 1;

COMMIT;
