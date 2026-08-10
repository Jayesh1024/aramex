DECLARE minDate STRING;
DECLARE maxDate STRING;
DECLARE v_StartDate DATETIME;
DECLARE v_EndDate DATETIME;
DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

SET minDate = (select CAST(min(ScanDate) AS STRING) from prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan);
SET maxDate = '2025-01-01 00:00:00';

-- This truncates the kpi_src stg table, loads it, then also update the end date in loadcontrol table for Fact_KPI_Scan
CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_KPI_Src_Stg_temp`(2, minDate, maxDate);
CALL `bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_KPI_Daily_Stg`(2, 'None', 'None');
CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.validation_results.fact_kpi_daily_stg_temp_part1` AS
select * from prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg;

CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_KPI_Src_Stg_temp`(2, NULL, NULL); -- This truncates the kpi_src stg table
CALL `bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_KPI_Daily_Stg`(2, 'None', 'None');
INSERT INTO prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg
select * from `prj-drgfly-prod-sp-01.validation_results.fact_kpi_daily_stg_temp_part1`;

CALL `bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Daily`(2);

CALL `bq_ds_prod_euw2_store_procedure.Staging_Set_LastValue`('Fact_KPI_Scan', 'ScanDateTime', CAST(DATETIME_SUB(DATETIME_TRUNC(CURRENT_DATETIME(), DAY), INTERVAL 1 MILLISECOND) AS STRING), FALSE);

CALL `bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Priority`(2);

CALL `bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Performance_Hist`(2);

