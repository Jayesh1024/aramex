-- ==========================================================================================
-- Routine:		[Load_Inserts_KPIScanGroups] 
-- Description: Run inserts to load data into table [dbo].[KPIScanGroups]
-- Example:		Exec [dbo].[Load_Inserts_KPIScanGroups] 
-- History:
--	15/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo].[Load_Inserts_KPIScanGroups] 
 
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

			TRUNCATE TABLE [dbo].[KPIScanGroups];

			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'CKN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'DNF')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'DUP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'HBD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'LGM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'NCB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'RIA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'RID')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'SCG')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'ALL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'ATL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ1')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ2')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ3')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ4')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ5')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ6')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ7')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ8')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZ9')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'AZA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'BDS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'BTR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CCL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CCP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CCQ')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CLM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'COV')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'DAM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'DIS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'DLY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'DRU')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'LAI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'MAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'MRP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'NEI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'ONF')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'OWC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'OWR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'PCY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'PEX')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'PFC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'PRS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'R34')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'R35')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'R36')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'RBX')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'RTD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'UNA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'UND')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'YEA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'YES')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'ALL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'ATL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'AZ1')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'AZ2')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'AZ7')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'AZ8')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'BDS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'CLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'DIS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'DRU')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'LAI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'MAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'NEI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'OWR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'PCY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'PRS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'R34')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'R35')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'R36')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'YEA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'YES')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'ADL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'ALB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'BAT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'BDB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'BEN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'BLT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'BRI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'CAP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'CBR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'CCT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'CFS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'CNS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'DAR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'DDY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'DPO')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'DUB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'GEE')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'GFT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'GLD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'GLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'GOU')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'LAU')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'MEL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'MKY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'MUD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'MYB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'NEW')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'NTH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'OAG')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'PAR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'PER')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'PQQ')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'PRP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'SUN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'SYD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'TAS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'TMW')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'TOO')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'TVL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'UNW')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'WGG')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'WOL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departure', N'YNG')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'STT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'M2S')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'IAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'SLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Out', N'OFH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Departed', N'ONH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CCD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'CCA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'CNC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'SP1')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'SP2')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'SP3')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'SP4')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'684')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'766')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Arrival', N'784')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'CKN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'DNF')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'DUP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'HBD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'LGM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'NCB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'RIA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'RID')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'SCG')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'ALL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'ATL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ1')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ2')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ3')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ4')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ5')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ6')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ7')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ8')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZ9')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'AZA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'BDS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'BTR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CCL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CCP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CCQ')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CLM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'COV')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'DAM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'DIS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'DLY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'DRU')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'LAI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'MAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'MRP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'NEI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'ONF')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'OWC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'OWR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'PCY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'PEX')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'PFC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'PRS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'R34')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'R35')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'R36')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'RBX')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'RTD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'UNA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'UND')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'YEA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'YES')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'ALL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'ATL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'AZ1')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'AZ2')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'AZ7')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'AZ8')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'BDS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'CLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'DIS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'DRU')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'LAI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'MAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'NEI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'OWR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'PCY')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'PRS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'R34')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'R35')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'R36')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'YEA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'YES')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WSZ')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WES')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'KAP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'TUO')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'NSA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'FNT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WRE')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'TGA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'NPL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'OAM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'CSI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'CSV')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'HLZ')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'PMR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'FMS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'GIS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'FSO')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WRK')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'TOK')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'CHC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'HUC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'GRE')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'EBP')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'NPE')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'BLH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'HWA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'ASH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'AUK')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'HUB')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'BOI')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'TIM')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'MAS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WEL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WIR')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'TLL')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'IVC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'WAG')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'CES')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'ZQN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'ROT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'NSN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'DUN')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departure', N'POS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'STT')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'M2S')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'IAC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'SLS')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Out', N'OFH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Departed', N'ONH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CCD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'CCA')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'CNC')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'SP1')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'SP2')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'SP3')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'SP4')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'684')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'766')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Arrival', N'784')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'D35')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Delivery', N'ACH')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Attempted', N'SPD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (6, N'Attempted', N'SPD')
			INSERT [dbo].[KPIScanGroups] ([CountryCode], [KPIGroup], [ScanStatus]) VALUES (1, N'Delivery', N'RPP')

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

