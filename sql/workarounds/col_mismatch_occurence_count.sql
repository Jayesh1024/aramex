SELECT
  col AS mismatch_column,
  COUNT(*) AS occurrence_count
FROM `prj-drgfly-prod-sp-01.validation_results.Fact_Scan_KPI_bq_vs_sqlserver_18th_March_2026_analysis`,
UNNEST(mismatch_columns) AS col
GROUP BY col
ORDER BY occurrence_count DESC;