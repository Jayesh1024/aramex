-- ==========================================================================================
-- Routine:		[Load_Inserts_KPIBulkLocalCustomer] 
-- Description: Run inserts to load data into table [dbo].[KPIBulkLocalCustomer]
-- Example:		Exec [dbo].[Load_Inserts_KPIBulkLocalCustomer] 
-- History:
--	15/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo].[Load_Inserts_KPIBulkLocalCustomer] 
 
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

			TRUNCATE TABLE [dbo].[KPIBulkLocalCustomer];

			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9070083', 364263, N'58 Logistics - Party Best Buy ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYDBAS0002', 340315, N'Interparcel - Frequent        ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9079841', 287043, N'SHIPPIT                       ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9070045', 342955, N'UBI LOGISTICS (AUS) PTY LTD   ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3120084', 377757, N'GAMERHOLIC PTY LTD            ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0250060', 347871, N'DIGITEL INTERNATIONAL         ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3390071', 376961, N'www.costumebay.com.au         ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0190131', 373857, N'Bundi pet supplies            ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD6320031', 298190, N'LIFEJOY                       ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9070093', 366675, N'Globavend                     ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3360078', 376183, N'CLEVERSTUFF EDUCATIONAL Toys  ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD5068227', 112605, N'OSCAR & FRIENDS               ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0520063', 296551, N'TEG COMPUTERS                 ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0220148', 364402, N'Stonebridge                   ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1210036', 312789, N'PET SHOP DIRECT               ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9070112', 377640, N'Austway Express               ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0002237', 284635, N'NEW AIM PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0480354', 280027, N'NILLUMBIK CELLARS / WINE SELLE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0112385', 299226, N'CRAZY MALL PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4350017', 362998, N'Laithwaites Wine', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1339085', 306066, N'Naked Wines Australia', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0292214', 320652, N'ENVIROCHEM INTERNATIONAL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'NEW0990033', 336423, N'FREIGHTEEZ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0080103', 340695, N'UBI LOGISTICS (AUS) PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0080136', 376267, N'UBI LOGISTICS (AUS) PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1050059', 299438, N'GOODNESS ME BOX', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0119099', 364721, N'BLACK BOX', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1119099', 343111, N'BLACK BOX', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1319099', 319579, N'BLACK BOX', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3329113', 381328, N'UNITED CELLARS P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BRIBS30086', 373409, N'MOCKA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BRI9996167', 297748, N'MOCKA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BRI9990063', 375346, N'MOCKA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'ALBDEP0220', 306340, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BDBDEP0410', 309100, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1208141', 96313, N'A & H TRADING P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2418823', 379989, N'AGOS NETWORK PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2517384', 107398, N'AHP DENTAL & MEDICAL (PLATNUIM', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2410106', 371577, N'ALL AUSTRALIAN CANDLE MAKING', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1157040', 252899, N'AMAYAMA TRADING', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0130025', 286118, N'AMINO Z CARINGBAH(PLATINUM)', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0380069', 326820, N'APPLIED BROKERS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD7359907', 290903, N'ART BASICS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0429917', 86634, N'ART PLUMBING & BATHROOM AUST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1090037', 93347, N'AUST & ASIA PLASTIC BAGS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD6320037', 298356, N'AUSTIMPEX', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0301175', 287315, N'BARNES PRODUCTS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0301070', 82886, N'BATTERY SPECIALTIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4604444', 114404, N'BAY BEANS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0268853', 155856, N'BE ENLIGHTENED', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD6250095', 348115, N'BEACON LIGHTING COMMERCIAL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0240001', 145555, N'BELFIELD MUSIC SHOP', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2130170', 104793, N'BELLSON ELECTRIC', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0230078', 348870, N'BEST CLICK', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1250118', 334072, N'BEST NAPPIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1221747', 96709, N'BEVERLY HILLS TRADING', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3250032', 297208, N'BIG EAGLE PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1039066', 91866, N'BIO SCULPTURE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1309054', 97997, N'BITE SIZE GROUP', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0229895', 260938, N'BOIAN SURGICAL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2130086', 354023, N'BOOMGATE ENTERPRISE PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9079870', 299107, N'BRAND LINK - ERSKINE PARK (PLA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0079749', 338165, N'CAMNET PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0490029', 282233, N'CAMPSMART', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2340091', 358026, N'CANDLE SUPPLY PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3140063', 377935, N'CARNEY SM PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1490073', 358991, N'CARTEL & CO', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0250053', 337533, N'CASTLE HILL INTERNATIONAL PTY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0058544', 266182, N'CHEF WORKS AUSTRALIA PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1338179', 376012, N'CHEMICAL CLEANING SOLUTIONS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3590011', 245726, N'CHILDS PLAY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0340013', 266420, N'COMFORT UNIFORMS (PLATINUM)', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0420023', 86399, N'COMM-CHEM MATERIALS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1390088', 321433, N'COMPLETE PROFILING SOLUTIONS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2260012', 271137, N'COOLCAR SPARE PARTS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0130073', 322022, N'CORKSCREW CELLARS SYLVANIA WAT', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1556203', 102063, N'COSMAC SURGICAL APPLIANCES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0268810', 81792, N'CTI COLOUR PRINTER', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2510077', 373952, N'DARLING BABY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1250062', 294397, N'DECOR INNOVATIONS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0138868', 78043, N'DELRICO SERVICES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9070049', 345751, N'DESSERT BOXES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9079202', 263704, N'DFMG PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0430061', 301632, N'DIGILIFE ONLINE PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4259896', 281501, N'DIGITEL TECH - SOUTH PDE (PLAT', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0479975', 302538, N'DINA CORPORATE PTY LTD (PLATIN', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1430056', 291195, N'DSM MOTOR SPORT', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4359095', 296303, N'DYNAMIC SUPPLIES (PLATINUM)', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1317369', 276883, N'EASY SIGNS PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1080040', 308554, N'ECCO LEATHER', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1150109', 94776, N'EJ TODD & SON', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2400074', 362555, N'ELLANI COLLECTIONS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3257216', 108867, N'ELTAD PTY LIMITED', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0002141', 138128, N'UBI LOGISTICS AUST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL2130004', 332210, N'HB COMMERCE P/L / VIDAXL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0298175', 82796, N'ENDEVA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1208207', 96379, N'ENFIELD PRODUCE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0600009', 91236, N'ESCENTIALS PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2358087', 270394, N'ESTELLE P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0228196', 80592, N'EURO SPICES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1250195', 378394, N'EVERSTONE PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0190095', 344402, N'EZY AUDIO VISUAL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0520014', 254416, N'GABRIEL COFFEE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0141647', 78158, N'GREG STEELE TRADING PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1098195', 93504, N'HARD ROCK ENTERPRISES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3049052', 286605, N'HELIO SUPPLY CO', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3170007', 272891, N'ICE SPORTS AUST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0420166', 376378, N'IGIFT FRUIT HAMPERS PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0200023', 304762, N'IL MERCANTE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2138908', 270516, N'IMPORT TRADENET AUSTRALIA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3080004', 266568, N'IN2PHARMA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0113678', 268225, N'INK STATION', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3590006', 245722, N'INTERNATIONAL BEAUTY SUPPLIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2300011', 266705, N'INVENCO', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2600032', 314234, N'JAY JAY THE BALLOON GUY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1219024', 96612, N'JB BATTERY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0110148', 323493, N'JED WINES PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2510012', 286961, N'JIM''S CELLARS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD6329094', 298225, N'JUMBO PETS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0449835', 284428, N'JW COMPUTERS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0110079', 284910, N'KCM AUSTRALIA - ONESIE SHOP', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1268778', 97756, N'KLEAR PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2513358', 107348, N'LAFITTE CLOTHING PTY. LIMITED', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0278847', 82256, N'LAXALES HAIR & BEAUTY SUPPLIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0050166', 367193, N'LIQUID PROMOTIONS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1250157', 350041, N'MACHTER AUTOPARTS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0130035', 293707, N'MARCLIFF ENGINEERING', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0360044', 296985, N'MDM ENTERTAINMENT', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2410034', 276250, N'MEDIAFORM COMPUTER', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0310089', 376191, N'MEGA PIXEL PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2419116', 106929, N'MRSUPPLEMENT.COM.AU', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0303233', 83016, N'MUSCLE CAR PARTS AUSTRALIA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0209871', 364148, N'NBAT INDUSTRIES PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1059186', 285209, N'NUDIE JEANS - THE GALERIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0400024', 307654, N'OEM PETCARE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1360100', 376419, N'OFFICE CATCH', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0140018', 275678, N'OPC ERGONOMICS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2340065', 321548, N'OURCELLAR.COM.AU', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9079930', 350358, N'PACK AND SEND- ONLINE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4259893', 270076, N'PARISI BATHROOMWARE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0160081', 359171, N'PCA EXPRESS PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2581055', 337022, N'PERMANENT PAINTED COATINGS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0160046', 327157, N'PET SUPPLIES EMPIRE - DYNAMIC', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2450068', 344464, N'PETER WRIGHT GOLF AGENCIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2040020', 313822, N'PETERSHAM LIQUOR MART', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0479210', 286116, N'PNW INTERNATIONAL P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0280115', 367411, N'POTTY PLANT MYFASTWAY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0270160', 327432, N'POWERTECH GROUP PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4259833', 114568, N'POWERTEK INTERNATIONAL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0349981', 84145, N'PROMOTION T SHIRT', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD7359790', 288410, N'QUALITY CAR PARTS AUSTRALIA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2430067', 301364, N'RESULTS LASER CLINIC', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1152080', 94816, N'RIDLEY DENTAL P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2347327', 306751, N'SAFEMAN', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3049198', 286611, N'SCOTTY''S MAKE-UP AND BEAUTY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0040014', 258445, N'SENDLE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYDOPS0007', 360442, N'SENDLE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0399061', 253126, N'SHOP AND SAVE ONLINE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2580063', 337901, N'SILVEREYE LEARNING RESOURCES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4600072', 307412, N'SOPRANO COFFEE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1548791', 112876, N'STANLEY ST MEATS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0130008', 247973, N'STATUS ANXIETY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1088367', 93339, N'STEFMAR PETCARE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3107021', 308975, N'SUMMER HILL WINE SHOP', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0269628', 339222, N'SUNWOOD INTERNATIONAL', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0110095', 76951, N'SUPERIOR CASINGS (AUST) P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0279151', 282771, N'TAMADA', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1410048', 305650, N'TEQ P/L', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1440043', 305238, N'THE MOBILE COFFEE GROUP', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0600041', 293543, N'THE NSW WINE SOCIETY', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0520070', 302694, N'THE PRINT FACILITY PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0527244', 89206, N'THORNTHWAITE TECHNOLOGIES', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2390090', 359062, N'TIMETECH PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0059155', 248285, N'TOBY''S ESTATE COFFEE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0350034', 327289, N'URSAFERITE PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1208149', 96321, N'VEBO TRADING', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2340074', 334103, N'VETALOGICA AUSTRALIA PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0269122', 277956, N'VILLAWOOD BETTA HOME LIVING', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1260104', 353128, N'VTS GROUP', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD7350067', 380360, N'WINE GALLERY / GOOD PAIR DAYS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0300182', 368726, N'WONDAR PTY LTD', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0470033', 303043, N'WORKWEAR ALLIANCE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2250138', 327710, N'WWW.FLASHTREND.COM.AU', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD4250044', 323006, N'XEX TRADE', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1410061', 321406, N'XPERT DIGITAL SOLUTIONS PTY LT', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2380018', 293658, N'ZOO PETS', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'PERBSE0028', 366765, N'Globavend                     ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL2090067', 366766, N'Globavend                     ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BRI0060132', 366764, N'Globavend                     ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0050026', 279897, N'MAX PET SUPPLIES              ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2410112', 378638, N'MAX PET SUPPLIES              ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1300061', 356398, N'ASIAFLY                       ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2220041', 352545, N'Catch Fitness Equipment       ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD1440023', 292468, N'MAC ECOMMERCE PTY LTD         ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2450043', 298839, N'EASTER EGG WAREHOUSE          ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2098354', 280063, N'FRENCH FLAIR FOOD AND WINE    ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD2120157', 362680, N'The Bedroom Mattress & Bedding', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD3410026', 290207, N'Fully Promoted NORWEST        ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD7358823', 270571, N'AGOS NETWORK PTY LTD          ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD0590070', 301182, N'THE HEALTH NUTT               ', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'FSA8890024', 302713, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'PERBSE8144', 306006, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9079888', 306007, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'PQQ0102925', 352535, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'ALBDEP0286', 352534, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0004607', 306005, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'TVL9994474', 306341, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'ADLBS35103', 315644, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BRIBS30017', 306004, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SYD9070117', 365294, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'PERBSE0233', 365296, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'ADLBS30095', 365291, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'ALBDEP0167', 362073, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BDBBSE0006', 362074, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BEN0010089', 362075, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BRI9990114', 365295, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CAPBS20002', 362077, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CBR2050035', 365292, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CCTBS30008', 362079, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CFSBAS0054', 362080, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CNSBS10061', 362081, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'DPO8880142', 362082, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'GEE9990032', 365290, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'GLDBS10025', 362084, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'LAU9990309', 362085, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0730124', 365293, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MKYBS10025', 362086, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MYBBSE0005', 362087, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'NEWDEP0018', 362088, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'NTHOPS0017', 362089, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'OAGBBB0008', 362090, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'PQQ0100074', 362092, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SUNSSC0065', 362093, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'TAS7000144', 362095, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'TOOBAS0024', 362096, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'TVL0350002', 362097, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'WOL9990047', 362098, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'YNGRFS0045', 362099, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'LEARFS0047', 353619, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CCTDEP5655', 353620, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'NEW0994724', 353636, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'YNG9990026', 353640, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'LAU9991279', 353632, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'DPOBSE0024', 353630, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'WOL9999566', 353639, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MYBDEP0038', 353634, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'GLD0202064', 353631, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MKY9990044', 353633, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CFSBAS9924', 353628, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'SUNSSC0053', 353638, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CNSBS11525', 353629, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'BENP010047', 353614, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CAPBS12285', 353616, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'NTH0019610', 353635, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'CBR9999816', 353618, N'DAI POST', 1);
			INSERT [dbo].[KPIBulkLocalCustomer] ([CustomerKey], [FMSCustomerId], [CustomerName], [CountryCode]) VALUES (N'MEL0250239', 365251, N'DAI POST', 1);

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

