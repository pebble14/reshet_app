SELECT COUNT(*) AS existing_row_count
FROM word_expression_set;

SELECT CASE
  WHEN COUNT(*) = 0 THEN 'ok_to_backfill'
  ELSE 'stop_already_populated'
END AS precheck_status
FROM word_expression_set;
