-- ==========================================================================================
-- Routine:		Load_LNK_Label_Address
-- Description: Loads LabelNo-Address relationships into [dv].[LNK_Label_Address]
-- Example:		Exec [dv].[Load_LNK_Label_Address] 288 
-- History:
--	07/11/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_LNK_Label_Address`(
    IN p_ProcessID INT64
)
OPTIONS(strict_mode=false)
BEGIN
    -- Variable declarations must be at the top of the BEGIN...END block
    DECLARE v_Component STRING DEFAULT 'dv_Load_LNK_Label_Address';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN
        -- One MERGE handles both updates (based on address length logic) and inserts.
        MERGE INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_LNK_Label_Address` AS Tgt
        USING (
            WITH NewAddresses AS (
                -- Pivot the Staging data to get From/To addresses on a single row per LabelNo
                SELECT 
                    LabelNo,
                    MAX(IF(FromTo = 'From', Address_HSK, NULL)) AS Pickup_Address_HSK,
                    MAX(IF(FromTo = 'From', AddressLen, 0)) AS Pickup_AddressLen,
                    MAX(IF(FromTo = 'From', RecordSource, '')) AS Pickup_RecordSource,
                    MAX(IF(FromTo = 'To', Address_HSK, NULL)) AS Delivery_Address_HSK,
                    MAX(IF(FromTo = 'To', AddressLen, 0)) AS Delivery_AddressLen,
                    MAX(IF(FromTo = 'To', RecordSource, '')) AS Delivery_RecordSource
                FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Label_Address_Stg`
                WHERE LabelNo IS NOT NULL
                GROUP BY LabelNo
            )
            SELECT 
                Src.LabelNo,
                `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_GetHashKey`(Src.LabelNo, '^') AS LabelNo_HSK,
                Src.Pickup_Address_HSK,
                Src.Delivery_Address_HSK,
                CONCAT('[From:', Src.Pickup_RecordSource, ']', '[To:', Src.Delivery_RecordSource, ']') AS RecordSource,
                -- Compare with current satellite lengths
                LENGTH(p.AddressKey) AS CurrentPickupLen,
                LENGTH(d.AddressKey) AS CurrentDeliveryLen,
                Src.Pickup_AddressLen,
                Src.Delivery_AddressLen
            FROM NewAddresses AS Src
            -- Left Join to existing link and satellites
            LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_LNK_Label_Address` AS LinkTgt ON LinkTgt.LabelNo = Src.LabelNo
            -- FIX: Changed TRUE to 1 because IsCurrent is INT64
            LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_SAT_Address` AS p ON p.Address_HSK = LinkTgt.Pickup_Address_HSK AND p.IsCurrent = 1
            LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_SAT_Address` AS d ON d.Address_HSK = LinkTgt.Delivery_Address_HSK AND d.IsCurrent = 1
        ) AS Src
        ON Tgt.LabelNo = Src.LabelNo
        WHEN MATCHED AND (
            -- Update logic: if the new address in staging is "better" (longer) than what is currently stored
            (Src.Pickup_AddressLen - IFNULL(Src.CurrentPickupLen, 0) > 0) OR 
            (Src.Delivery_AddressLen - IFNULL(Src.CurrentDeliveryLen, 0) > 0)
        ) THEN
            UPDATE SET
                LabelNo_HSK = Src.LabelNo_HSK,
                Pickup_Address_HSK = Src.Pickup_Address_HSK,
                Delivery_Address_HSK = Src.Delivery_Address_HSK,
                Loaded = v_Loaded,
                ProcessId = p_ProcessID,
                RecordSource = Src.RecordSource,
                RecordSourceId = NULL
        WHEN NOT MATCHED THEN
            INSERT (
                LabelNo_HSK,
                Pickup_Address_HSK,
                Delivery_Address_HSK,
                LabelNo,
                Loaded,
                ProcessId,
                RecordSource,
                RecordSourceId
            )
            VALUES (
                Src.LabelNo_HSK,
                Src.Pickup_Address_HSK,
                Src.Delivery_Address_HSK,
                Src.LabelNo,
                v_Loaded,
                p_ProcessID,
                Src.RecordSource,
                NULL
            );

        -- Total rows affected (Updated + Inserted)
        SET v_Updated = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles Success and Failure metrics)
    CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_DATETIME(),
        v_Result,
        v_ErrorMessage,
        v_Inserted, 
        v_Updated,
        -1
    );
END;