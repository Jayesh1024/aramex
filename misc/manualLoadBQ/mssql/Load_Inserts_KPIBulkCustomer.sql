-- ==========================================================================================
-- Routine:		[Load_Inserts_KPIBulkCustomer] 
-- Description: Run inserts to load data into table [dbo].[KPIBulkCustomer]
-- Example:		Exec [dbo].[Load_Inserts_KPIBulkCustomer] 
-- History:
--	15/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo].[Load_Inserts_KPIBulkCustomer] 
 
AS

	DECLARE @Loaded DATETIME2(3) = SYSDATETIME();
	
	SET NOCOUNT ON

	DECLARE	
		@Component VARCHAR(250) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID),
		@Started DATETIME2(3) = SYSDATETIME(),
		@Ended DATETIME2(3),
		@Result VARCHAR(20),
		@ErrorMessage VARCHAR(250),
		@ProcessID BIGINT,
		@Inserted INT,
		@Updated INT;

	SELECT @ProcessID = MAX(ProcessId) + 1 from Staging.LoadLog;

	BEGIN TRY
		BEGIN TRANSACTION

			TRUNCATE TABLE [dbo].[KPIBulkCustomer];

				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (272631, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (285532, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (273982, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (286905, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (255308, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (277129, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (287424, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (284413, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (286975, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (227386, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (274379, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (252999, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (233023, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (269416, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (268392, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (286111, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (274323, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (287961, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (266752, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (224849, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (225743, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (256572, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (262540, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (263080, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (274321, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (282925, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (286337, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (287963, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (288369, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (290000, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (290446, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (290503, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (290650, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (291067, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (292390, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (296399, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (236512, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (252274, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (261238, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (247464, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (289715, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (255458, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (257824, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (292107, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (256978, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (223812, 1)
				INSERT [dbo].[KPIBulkCustomer] ([OESCustomerID], [CountryCode]) VALUES (268944, 1)

			SET @Inserted = @@ROWCOUNT;

		COMMIT TRANSACTION;
	 	SET @Result = 'Success';


	END TRY

	BEGIN CATCH
  		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION;
		SELECT 
			@Result = 'Failed', 
			@ErrorMessage = ERROR_MESSAGE();
		GOTO RESULT;
	END CATCH

	/*
		Record load metrics in log
	*/
	RESULT:

		SET @Ended = SYSDATETIME();
		EXEC [Staging].[SaveLog] 
			@Component,
			@ProcessID,
			@Started,
			@Ended,
			@Result,
			@ErrorMessage,
			@Inserted,
			@Updated;

	RETURN IIF(@Result='Success',0,-1);

