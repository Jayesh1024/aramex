-- ==========================================================================================
-- Routine:		[Load_Inserts_KPIExcludedLabels] 
-- Description: Run inserts to load data into table [dbo].[KPIExcludedLabels]
-- Example:		Exec [dbo].[Load_Inserts_KPIExcludedLabels] 
-- History:
--	15/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo].[Load_Inserts_KPIExcludedLabels] 
 
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

			TRUNCATE TABLE [dbo].[KPIExcludedLabels];

			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'*A');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'*B');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'8Q');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'8B');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'8R');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'8W');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'HJ');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'PI');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'W5');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'5Z');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9D');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9E');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9F');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9G');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9H');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9P');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9Z');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'*A');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'*B');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'8Q');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'8B');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'8R');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'8W');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'HJ');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'PI');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'W5');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'5Z');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9D');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9E');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9F');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9G');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9H');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9P');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9Z');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'9A');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9A');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'5A');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'90');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'91');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'92');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'93');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'94');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'95');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'96');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'99');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9B');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9M');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9N');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9O');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9Q');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9R');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9S');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9V');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9W');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (24, N'South Africa', N'5R');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (24, N'South Africa', N'MA');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (1, N'Australia', N'RP');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9X');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'98');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9L');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9U');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'9C');
			INSERT [dbo].[KPIExcludedLabels] ([CountryCode], [CountryName], [LabelPrefix]) VALUES (6, N'New Zealand', N'97');

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

