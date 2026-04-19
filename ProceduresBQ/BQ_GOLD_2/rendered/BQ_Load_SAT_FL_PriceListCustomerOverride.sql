CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_SAT_FL_PriceListCustomerOverride`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- Logging Variables
    DECLARE v_Component STRING DEFAULT 'prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_Load_SAT_FL_PriceListCustomerOverride';
    
    -- OPTION 2: Use DATETIME and CURRENT_DATETIME()
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    
    -- Initialize to 0 for strict logging type matching
    DECLARE v_Updated INT64 DEFAULT 0; 
    DECLARE v_Step STRING;
    DECLARE v_delim STRING DEFAULT '\r'; -- Carriage Return

    -- Working Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN
        INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_SAT_FL_PriceListCustomerOverride` (
            CustomerPriceOverride_HSK,
            CountryId,
            CustomerId,
            PriceList,
            ProductId,
            BaseDiscountPercent,
            ExcessDiscountPercent,
            BaseCommissionOverridePercent,
            BaseCommissionOverridePercentForce,
            ExcessCommissionOverridePercent,
            ExcessCommissionOverrideForce,
            Loaded,
            RecordSource
        )
        SELECT
            -- UDF Call (Table naming rule: dbo.GetHashKey -> dbo_GetHashKey)
            `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_GetHashKey`(
                CONCAT(
                    IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') || v_delim,
                    IFNULL(NULLIF(CAST(CustomerId AS STRING), ''), '') || v_delim,
                    IFNULL(NULLIF(CAST(PriceList AS STRING), ''), '') || v_delim,
                    IFNULL(NULLIF(CAST(ProductId AS STRING), ''), '') || v_delim
                ), '^'
            ) AS CustomerPriceOverride_HSK,
            CountryId,
            CustomerId,
            PriceList,
            ProductId,
            BaseDiscountPercent,
            ExcessDiscountPercent,
            BaseCommissionOverridePercent,
            BaseCommissionOverridePercentForce,
            ExcessCommissionOverridePercent,
            ExcessCommissionOverrideForce,
            v_Loaded AS Loaded,
            p_RecordSource AS RecordSource
        FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_fl_PriceListCustomerOverride_Stg`;

        SET v_Inserted = @@row_count;
        SET v_Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log (Option 2: Using DATETIME and CURRENT_DATETIME)
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