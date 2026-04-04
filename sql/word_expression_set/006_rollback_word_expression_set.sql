BEGIN IMMEDIATE TRANSACTION;

DROP INDEX IF EXISTS ux_word_expression_set_one_representative;
DROP INDEX IF EXISTS ux_word_expression_set_word_seq;
DROP TABLE IF EXISTS word_expression_set;

COMMIT;
