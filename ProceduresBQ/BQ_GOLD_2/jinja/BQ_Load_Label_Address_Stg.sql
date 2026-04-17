-- ==========================================================================================
-- Routine:     Load_Label_Address_Stg
-- Description: Prepare load of new parcel pickup/delivery locations
-- Example:     Exec [Staging].[Load_Label_Address_Stg] 123
-- History:
--  29/10/2019  P. Waldron      Routine Written
--  23/04/2020  P. Waldron      LTRIM FastLabel address elements
--  06/09/2022  B. Woods        Changed order of address sources the same 
--                              as Label allocation load. (Part of BI-265)
--	05/02/2024	B. Woods		Added PickupRequest source as the second preference address
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_Label_Address_Stg`(
    IN p_ProcessID INT64
)
OPTIONS(strict_mode=false)
BEGIN
    -- 1. All DECLARE statements must be at the very top
    DECLARE v_Component STRING DEFAULT 'Staging_Load_Label_Address_Stg';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    DECLARE v_Step STRING;
    DECLARE v_StartedSrc DATETIME;
    DECLARE v_EndedSrc DATETIME;
    DECLARE v_InsertedSrc INT64 DEFAULT 0;
    DECLARE v_Loaded TIMESTAMP;
    DECLARE v_delim STRING DEFAULT CHR(13); -- Carriage Return

    BEGIN

        /* ==============================================================================
            fl_ConItem (MF)
           ============================================================================== */
        SET v_Step = 'MyFastway';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        ) 
        SELECT 
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq,
            RecordSource
        FROM (
            SELECT 
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'MyFastway' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT 
                    Label AS LabelNo, 'From' AS FromTo, TRIM(FromStreetAddress) AS AddressLine1, 
                    CAST(NULL AS STRING) AS AddressLine2, TRIM(FromLocality) AS Town, 
                    CAST(NULL AS STRING) AS State, FromPostalCode AS Postcode, CAST(NULL AS INT64) AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItem_Stg` 
                UNION ALL
                SELECT 
                    Label AS LabelNo, 'To' AS FromTo, TRIM(ToStreetAddress) AS AddressLine1, 
                    CAST(NULL AS STRING) AS AddressLine2, TRIM(ToLocality) AS Town, 
                    CAST(NULL AS STRING) AS State, ToPostalCode AS Postcode, CountryId AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItem_Stg`
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK;

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
           Pickup Requests for AU and NZ
           ============================================================================== */
        SET v_Step = 'PickupRequest';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        ) 
        SELECT          
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq, 
            RecordSource
        FROM (
            SELECT 
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'PickupRequest' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT 
                    LabelNumber AS LabelNo, 'From' AS FromTo,
                    REPLACE(TRIM(PickupAddress1), CHR(34), '') AS AddressLine1,
                    REPLACE(TRIM(PickupAddress2), CHR(34), '') AS AddressLine2,
                    REPLACE(TRIM(PickupSuburb), CHR(34), '') AS Town,
                    CAST(NULL AS STRING) AS State,
                    TRIM(PickupPostcode) AS Postcode,
                    CAST(NULL AS STRING) AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_PickupRequest_Stg`
                UNION ALL
                SELECT 
                    LabelNumber AS LabelNo, 'To' AS FromTo,
                    REPLACE(TRIM(DeliveryAddress1), CHR(34), '') AS AddressLine1,
                    REPLACE(TRIM(DeliveryAddress2), CHR(34), '') AS AddressLine2,
                    REPLACE(TRIM(DeliverySuburb), CHR(34), '') AS Town,
                    CAST(NULL AS STRING) AS State,
                    TRIM(DeliveryPostcode) AS Postcode,
                    CountryCode AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_PickupRequest_Stg` 
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK; 

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
            API_RF_AdHocLabel_AllocationHistory (DL)
           ============================================================================== */
        SET v_Step = 'DynamicLabel';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        ) 
        SELECT          
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq, 
            RecordSource
        FROM (
            SELECT 
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'DynamicLabel' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT 
                    LabelNumber AS LabelNo, 'From' AS FromTo,
                    REPLACE(TRIM(PickupAddr1), CHR(34), '') AS AddressLine1,
                    REPLACE(TRIM(PickupAddr2), CHR(34), '') AS AddressLine2,
                    REPLACE(TRIM(PickupTown), CHR(34), '') AS Town,
                    CAST(NULL AS STRING) AS State,
                    TRIM(PickupPostcode) AS Postcode,
                    CAST(NULL AS STRING) AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg`
                UNION ALL
                SELECT 
                    LabelNumber AS LabelNo, 'To' AS FromTo,
                    REPLACE(TRIM(DeliveryAddr1), CHR(34), '') AS AddressLine1,
                    REPLACE(TRIM(DeliveryAddr2), CHR(34), '') AS AddressLine2,
                    REPLACE(TRIM(DeliveryTown), CHR(34), '') AS Town,
                    CAST(NULL AS STRING) AS State,
                    TRIM(DeliveryPostcode) AS Postcode,
                    CountryCode AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg` 
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK; 

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
            tblFastLabel_Consignment (FL)
           ============================================================================== */
        SET v_Step = 'FastLabel';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        ) 
        SELECT  
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq,
            RecordSource
        FROM (
            SELECT 
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'FastLabel' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT DISTINCT
                    LabelNumber AS LabelNo, 'To' AS FromTo,
                    TRIM(Address1) AS AddressLine1,
                    TRIM(Address2) AS AddressLine2,
                    TRIM(Town) AS Town,
                    TRIM(State) AS State,
                    TRIM(Postcode) AS Postcode,
                    CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblFastLabel_Consignment_Stg`
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK;

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
            ConsignmentItem (FLE)
           ============================================================================== */
        SET v_Step = 'FastLabelEnterprise';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        ) 
        SELECT 
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq,
            RecordSource 
        FROM (
            SELECT 
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'FastLabelEnterprise' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT DISTINCT
                    LabelNumber AS LabelNo, 'To' AS FromTo,
                    TRIM(ReceiverAddress1) AS AddressLine1,
                    TRIM(
                        IF(IFNULL(ReceiverSuburb, '') != IFNULL(ReceiverCity, ''), 
                            CASE WHEN IFNULL(ReceiverAddress2, '') = '' THEN ReceiverSuburb ELSE CONCAT(ReceiverAddress2, ' ', ReceiverSuburb) END, 
                            ReceiverAddress2 
                        )
                    ) AS AddressLine2,
                    TRIM(
                        CASE 
                            WHEN IFNULL(ReceiverSuburb, '') = '' OR IFNULL(ReceiverCity, '') = '' THEN CONCAT(IFNULL(ReceiverSuburb, ''), IFNULL(ReceiverCity, '')) 
                            WHEN ReceiverSuburb = ReceiverCity THEN ReceiverSuburb 
                            ELSE IF(IFNULL(ReceiverCity, '') != '', ReceiverCity, ReceiverSuburb)
                        END
                    ) AS Town,
                    CAST(NULL AS STRING) AS State,
                    TRIM(ReceiverPostcode) AS Postcode,
                    CAST(NULL AS STRING) AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg` 
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK;

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
            HDManifests (IFS)
           ============================================================================== */
        SET v_Step = 'HDManifests';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        ) 
        SELECT 
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq,
            RecordSource
        FROM (
            SELECT 
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'HDManifests' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT 
                    LabelNo, 'From' AS FromTo,
                    REPLACE(CAST(TRIM(SendAdd1) AS STRING), CHR(34), '') AS AddressLine1,
                    REPLACE(CAST(TRIM(SendAdd2) AS STRING), CHR(34), '') AS AddressLine2,
                    REPLACE(CAST(TRIM(SendAdd3) AS STRING), CHR(34), '') AS Town,
                    REPLACE(CAST(TRIM(SendAdd4) AS STRING), CHR(34), '') AS State,
                    CAST(RTRIM(CASE 
                        WHEN CollectionPostCode IS NOT NULL THEN CollectionPostCode
                        WHEN REGEXP_CONTAINS(SendAdd5, r'[0-9]') AND SendAdd5 != '0000' THEN SendAdd5 
                        WHEN REGEXP_CONTAINS(SendAdd4, r'[0-9]') THEN SendAdd4 
                        WHEN REGEXP_CONTAINS(SendAdd6, r'[0-9]') THEN SendAdd6 
                    END) AS STRING) AS Postcode, 
                    CollectionCountryCode AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg`
                UNION ALL
                SELECT 
                    LabelNo, 'To' AS FromTo,
                    REPLACE(CAST(TRIM(RecAdd1) AS STRING), CHR(34), '') AS AddressLine1,
                    REPLACE(CAST(TRIM(RecAdd2) AS STRING), CHR(34), '') AS AddressLine2,
                    REPLACE(CAST(TRIM(RecAdd3) AS STRING), CHR(34), '') AS Town,
                    REPLACE(CAST(TRIM(IF(NOT REGEXP_CONTAINS(RecAdd4, r'[0-9]'), RecAdd4, RecAdd6)) AS STRING), CHR(34), '') AS State,
                    CAST(RTRIM(CASE 
                        WHEN CollectionPostCode IS NOT NULL THEN CollectionPostCode
                        WHEN REGEXP_CONTAINS(RecAdd5, r'[0-9]') AND ((LENGTH(CAST(RecAdd5 AS STRING)) = 4 AND RecAdd5 != '0000') OR DeliveryCountryCode NOT IN (1,6)) THEN RecAdd5 
                        WHEN REGEXP_CONTAINS(RecAdd4, r'[0-9]') THEN RecAdd4 
                        WHEN REGEXP_CONTAINS(RecAdd6, r'[0-9]') THEN RecAdd6 
                    END) AS STRING) AS Postcode, 
                    DeliveryCountryCode AS CountryCode 
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg`
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK;

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
            vw_Ebay_Labels (EBAY)
           ============================================================================== */
        SET v_Step = 'EBAY';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        )
        SELECT  
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq,
            RecordSource
        FROM (
            SELECT
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'EBAY' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT
                    LabelNumber AS LabelNo, 'From' AS FromTo,
                    TRIM(C_Address1) AS AddressLine1, 
                    TRIM(C_Address2) AS AddressLine2, 
                    TRIM(C_Town) AS Town,
                    CAST(NULL AS STRING) AS State,
                    C_Postcode AS PostCode,
                    C_CountryCode AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Ebay_Labels_Stg`
                UNION ALL
                SELECT 
                    LabelNumber AS LabelNo, 'To' AS FromTo,
                    TRIM(DeliveryStreet) AS AddressLine1, 
                    TRIM(DeliveryStreet1) AS AddressLine2, 
                    TRIM(DeliveryCity) AS Town,
                    CAST(NULL AS STRING) AS State,
                    DeliveryPostcode AS PostCode,
                    DeliveryCountry AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Ebay_Labels_Stg` 
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK;

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);


        /* ==============================================================================
            tblOnlineEnquiry_RP (RP)
           ============================================================================== */
        SET v_Step = 'ReceiverPays';
        SET v_StartedSrc = CURRENT_DATETIME();
        
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` (
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, PostCode, 
            CountryCode, CountryName, AddressKey, AddressLen, AddressSeq, RecordSource
        )
        SELECT  
            LabelNo, FromTo, Address_HSK, AddressLine1, AddressLine2, Town, State, Postcode, 
            CountryCode, CountryName, AddressKey, AddressLen,
            ROW_NUMBER() OVER (PARTITION BY Address_HSK ORDER BY LabelNo) AS AddressSeq,
            RecordSource
        FROM (
            SELECT
                a.LabelNo, a.FromTo, a.AddressLine1, a.AddressLine2, a.Town, a.State, a.Postcode, 
                a.CountryCode, c.CountryName, 'ReceiverPays' AS RecordSource,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                        IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                    ), v_delim
                ) AS Address_HSK,
                CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                ) AS AddressKey,
                LENGTH(CONCAT(
                    IFNULL(CONCAT(NULLIF(a.AddressLine1, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.AddressLine2, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Town, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(a.Postcode, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(c.CountryName, ''), v_delim), '')
                )) AS AddressLen
            FROM (
                SELECT DISTINCT
                    label_number AS LabelNo, 'From' AS FromTo,
                    TRIM(Sender_StreetAddress) AS AddressLine1,
                    TRIM(Sender_StreetAddress1) AS AddressLine2,
                    TRIM(IF(IFNULL(Sender_Suburb, '') = '', Sender_City, Sender_Suburb)) AS Town,
                    CAST(NULL AS STRING) AS State,
                    Sender_Postcode AS PostCode,
                    CAST(NULL AS STRING) AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblOnlineEnquiry_RP_Stg` 
                UNION ALL
                SELECT DISTINCT
                    label_number AS LabelNo, 'To' AS FromTo,
                    TRIM(Receiver_StreetAddress) AS AddressLine1,
                    TRIM(Receiver_StreetAddress1) AS AddressLine2,
                    TRIM(IF(IFNULL(Receiver_Suburb, '') = '', Receiver_City, Receiver_Suburb)) AS Town,
                    CAST(NULL AS STRING) AS State,
                    Receiver_Postcode AS PostCode,
                    CAST(NULL AS STRING) AS CountryCode
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblOnlineEnquiry_RP_Stg` 
            ) AS a
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = a.CountryCode
        ) AS h
        WHERE NOT EXISTS (SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg` AS s WHERE s.Address_HSK = h.Address_HSK)
        ORDER BY Address_HSK;

        SET v_InsertedSrc = @@row_count;
        SET v_EndedSrc = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Step, p_ProcessID, v_StartedSrc, v_EndedSrc, v_Result, v_ErrorMessage, v_InsertedSrc, 0, -1);

        -- Record load metrics in log
        SET v_Result = 'Success';
        SET v_Inserted = (SELECT COUNT(*) FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg`);

    EXCEPTION WHEN ERROR THEN
        SET v_Result = CONCAT('Failed - loading ', v_Step, ' data');
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Master Logging
    SET v_Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        0,
        -1
    );

END;