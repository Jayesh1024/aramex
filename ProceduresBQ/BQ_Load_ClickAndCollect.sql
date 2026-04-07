-- ==========================================================================================
-- Routine:     Load_ClickAndCollect
-- Description: Loads any labels into [dbo].[FWFastway_ClickAndCollect]
-- Example:     Exec [dbo].[Load_ClickAndCollect] 30
-- History:
--  29/05/2025  B. Woods        Routine Written
--
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_ClickAndCollect`(
    IN p_ProcessID INT64
)
BEGIN
    DECLARE v_Component STRING DEFAULT 'dbo_Load_ClickAndCollect';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- Single MERGE handles both updates and inserts, scanning the source table only once.
        -- Identifiers use the Jinja2 template for project and dataset references.
        MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_FWFastlabel_ClickAndCollect` AS Tgt
        USING `{{ project_id }}.{{ target_dataset_id }}.Staging_FWFastlabel_ClickAndCollect_stg` AS Src
        ON Tgt.Id = Src.Id
        WHEN MATCHED THEN
            UPDATE SET
                -- Id is omitted from UPDATE SET as it is the join key
                LabelNo = Src.Label,
                ToContactName = Src.ToContactName,
                ToStreetAddress = Src.ToStreetAddress,
                ToLocality = Src.ToLocality,
                ToStateOrProvince = Src.ToStateOrProvince,
                ToPostalCode = Src.ToPostalCode,
                ToCountry = Src.ToCountry,
                ToPhoneNumber = Src.ToPhoneNumber,
                ToEmail = Src.ToEmail,
                WeightDead = Src.WeightDead,
                WeightCubic = Src.WeightCubic,
                Length = Src.Length,
                Width = Src.Width,
                Height = Src.Height,
                FromRf = Src.FromRf,
                FromStreetAddress = Src.FromStreetAddress,
                FromLocality = Src.FromLocality,
                FromStateOrProvince = Src.FromStateOrProvince,
                FromPostalCode = Src.FromPostalCode,
                FromCountry = Src.FromCountry,
                FromPhoneNumber = Src.FromPhoneNumber,
                FromEmail = Src.FromEmail,
                CreatedOn = Src.CreatedOn,
                CreatedBy = Src.CreatedBy,
                Processed = Src.Processed,
                ProcessedOn = Src.ProcessedOn,
                SYS_CHANGE_VERSION = Src.SYS_CHANGE_VERSION
        WHEN NOT MATCHED THEN
            INSERT (
                Id, LabelNo, ToContactName, ToStreetAddress, ToLocality, 
                ToStateOrProvince, ToPostalCode, ToCountry, ToPhoneNumber, ToEmail, 
                WeightDead, WeightCubic, Length, Width, Height, 
                FromRf, FromStreetAddress, FromLocality, FromStateOrProvince, FromPostalCode, 
                FromCountry, FromPhoneNumber, FromEmail, CreatedOn, CreatedBy, 
                Processed, ProcessedOn, SYS_CHANGE_VERSION
            )
            VALUES (
                Src.Id, Src.Label, Src.ToContactName, Src.ToStreetAddress, Src.ToLocality, 
                Src.ToStateOrProvince, Src.ToPostalCode, Src.ToCountry, Src.ToPhoneNumber, Src.ToEmail, 
                Src.WeightDead, Src.WeightCubic, Src.Length, Src.Width, Src.Height, 
                Src.FromRf, Src.FromStreetAddress, Src.FromLocality, Src.FromStateOrProvince, Src.FromPostalCode, 
                Src.FromCountry, Src.FromPhoneNumber, Src.FromEmail, Src.CreatedOn, Src.CreatedBy, 
                Src.Processed, Src.ProcessedOn, Src.SYS_CHANGE_VERSION
            );

        -- BigQuery's @@row_count returns the total rows affected (Inserted + Updated)
        SET v_Updated = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure)
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted, 
        v_Updated,
        -1
    );
END;