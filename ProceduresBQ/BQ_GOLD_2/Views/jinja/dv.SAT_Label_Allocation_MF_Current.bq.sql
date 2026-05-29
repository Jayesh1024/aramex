CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Allocation_MF_Current`
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
    `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Allocation_MF_partitioned`
        JOIN `{{ project_id }}.{{ dataset_id }}.dbo_IndexedViewDateRangeLimit` rl ON
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