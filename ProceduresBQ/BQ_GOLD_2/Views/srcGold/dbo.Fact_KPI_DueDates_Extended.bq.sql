CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_DueDates_Extended`
	AS

	SELECT kpi.*,
    (SELECT ARRAY_AGG(Calendar_Date ORDER BY Calendar_Date)[SAFE_OFFSET(COALESCE(kpi.SLA - 1, 0))]
                FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time`
                LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ON Calendar_Date = Date AND Franchise IN (FromRf, ToRf) AND CountryCode = CountryCode
                WHERE Calendar_Date >= CAST(kpi.RealisedDate AS DATE) AND week_day_flag = 'Y' AND Comment IS NULL
    ) AS DueDate_Minus1,
	(SELECT ARRAY_AGG(Calendar_Date ORDER BY Calendar_Date)[SAFE_OFFSET(COALESCE(kpi.SLA + 1, 2))]
                    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time`
                    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ON Calendar_Date = Date AND Franchise IN (FromRf, ToRf) AND CountryCode = CountryCode
                    WHERE Calendar_Date >= CAST(kpi.RealisedDate AS DATE) AND week_day_flag = 'Y' AND Comment IS NULL
    ) AS DueDate_Plus1,
	(SELECT ARRAY_AGG(Calendar_Date ORDER BY Calendar_Date)[SAFE_OFFSET(COALESCE(kpi.SLA + 2, 3))]
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time`
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ON Calendar_Date = Date AND Franchise IN (FromRf, ToRf) AND CountryCode = CountryCode
    WHERE Calendar_Date >= CAST(kpi.RealisedDate AS DATE) AND week_day_flag = 'Y' AND Comment IS NULL
    ) AS DueDate_Plus2,
    (SELECT ARRAY_AGG(Calendar_Date ORDER BY Calendar_Date)[SAFE_OFFSET(COALESCE(kpi.SLA + 3, 4))]
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time`
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ON Calendar_Date = Date AND Franchise IN (FromRf, ToRf) AND CountryCode = CountryCode
    WHERE Calendar_Date >= CAST(kpi.RealisedDate AS DATE) AND week_day_flag = 'Y' AND Comment IS NULL
    ) AS DueDate_Plus3

	FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI` kpi
	JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` mf ON kpi.LabelNo = mf.LabelNo AND kpi.CountryCode = mf.CountryCode
	AND mf.IsCurrent = 1