-- ==========================================================================================
-- Routine:		[Load_Inserts_Dim_Country] 
-- Description: Run inserts to load data into table [dbo].[Dim_Country]
-- Example:		Exec [dbo].[Load_Inserts_Dim_Country] 
-- History:
--	15/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo.[Load_Inserts_Dim_Country] 
 
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

	SELECT @ProcessID = MAX(ProcessId) from Staging.LoadLog;

	BEGIN TRY
		BEGIN TRANSACTION

			TRUNCATE TABLE [dbo].[Dim_Country];

			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (1, N'Australia', 0, 0, N'$', N'AU', N'AUD', 250, N'AUS Eastern Standard Time                         ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (4, N'Hong Kong', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (5, N'Malaysia', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (6, N'New Zealand', 0, 0, N'$', N'NZ', N'NZD', 200, N'New Zealand Standard Time                         ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (7, N'Singapore', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (8, N'Great Britain', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (11, N'Ireland', 0, 0, N'€', N'IE', N'EUR', 1, N'GMT Standard Time                                 ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (12, N'Germany', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (13, N'Global IT', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (14, N'Morocco', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (15, N'Spain', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (16, N'Global', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (17, N'Fastway Post', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (18, N'Canada', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (19, N'Northern Ireland', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (20, N'Netherlands', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (21, N'Belgium', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (22, N'Luxembourg', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (23, N'Belgium(Flemish Website)', 0, 1, N' ', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (24, N'South Africa', 0, 0, N'R', N'ZA', N'   ', 1, N'South Africa Standard Time                        ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (50, N'Test Country', 0, 1, N'$', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (51, N'Test Country NZ Copies(2)', 0, 1, N'$', N'  ', N'   ', 1, N'                                                  ')
			INSERT [dbo].[Dim_Country] ([CountryCode], [CountryName], [CountryDisabled], [HideInWebsite], [CurrencySymbol], [LanguageCode], [CurrencyCode], [CubicConversion], [TimeZone]) VALUES (52, N'Test Country NZ Copies(3)', 0, 1, N'$', N'  ', N'   ', 1, N'                                                  ')

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

