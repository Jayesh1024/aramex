CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF_Current`
AS
SELECT
    LabelNo,
    CountryCode,
    LabelExternal,
    CustomerId,
    Reference,
    Zone,
    ToRf,
    ToCf,
    COUNT(*) CountPerLabel
FROM
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF_partitioned`
        JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_IndexedViewDateRangeLimit` rl ON
        Loaded > rl.DateLimit1
            AND rl.TargetName = 'SAT_Label_Allocation_MF_Current'
WHERE
    IsCurrent = 1
GROUP BY
    LabelNo,
    CountryCode,
    LabelExternal,
    CustomerId,
    Reference,
    Zone,
    ToRf,
    ToCf