-- ==========================================================================================
-- Routine:		[Load_Inserts_KPIRate] 
-- Description: Run inserts to load data into table [dbo].[KPIRate]
-- Example:		Exec [dbo].[Load_Inserts_KPIRate] 
-- History:
--	15/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo].[Load_Inserts_KPIRate] 
 
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

			TRUNCATE TABLE [dbo].[KPIRate];

			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-01-01T00:00:00.0000000' AS DateTime2), 90)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-02-01T00:00:00.0000000' AS DateTime2), 91)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-03-01T00:00:00.0000000' AS DateTime2), 92)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-04-01T00:00:00.0000000' AS DateTime2), 93)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-05-01T00:00:00.0000000' AS DateTime2), 94)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-06-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-07-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-08-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-09-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-10-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-11-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2023-12-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2024-01-01T00:00:00.0000000' AS DateTime2), 95)
			INSERT [dbo].[KPIRate] ([DateBOM], [Rate]) VALUES (CAST(N'2024-02-01T00:00:00.0000000' AS DateTime2), 95)

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

