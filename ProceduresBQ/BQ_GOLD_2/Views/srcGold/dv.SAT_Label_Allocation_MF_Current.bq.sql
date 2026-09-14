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
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF`
        JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_IndexedViewDateRangeLimit` rl ON
        Loaded > rl.DateLimit1
            AND UPPER(rl.TargetName) = 'SAT_LABEL_ALLOCATION_MF_CURRENT'
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