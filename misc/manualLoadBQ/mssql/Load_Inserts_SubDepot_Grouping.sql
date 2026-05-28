-- ==========================================================================================
-- Routine:		[SubDepot_Grouping] 
-- Description: Run inserts to load data into table [dbo].[KPIRate]
-- Example:		Exec [dbo].[SubDepot_Grouping] 
-- History:
--	20/04/2026 B. Woods		Routine Written
-- ==========================================================================================
CREATE PROCEDURE [dbo].[Load_Inserts_SubDepot_Grouping] 
 
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

			TRUNCATE TABLE [dbo].[SubDepot_Grouping];

			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'020', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'022', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'023', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'024', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'026', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'028', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'029', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'230', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'030', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'122', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'123', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'126', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'129', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'130', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'226', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'225', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'425', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'125', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'325', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'625', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'525', N'RNO', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'258', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'058', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'060', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'158', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'160', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'260', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'658', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'358', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'360', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'458', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'460', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'560', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'660', N'NBB', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'016', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'017', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'019', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'021', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'115', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'116', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'117', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'120', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'121', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'114', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'219', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'317', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'319', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'119', N'DOG', N'SYD', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'036', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'037', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'038', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'136', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'236', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'237', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'238', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'536', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'437', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'436', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'336', N'BMW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'027', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'034', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'035', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'039', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'234', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'235', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'239', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'327', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'935', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'735', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'535', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'439', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'435', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'339', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'335', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'334', N'WEB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'031', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'032', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'033', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'131', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'132', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'133', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'232', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'433', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'432', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'632', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'736', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'832', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'932', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'532', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'333', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'233', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'332', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'533', N'SOW', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'041', N'NHL', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'138', N'NHL', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'139', N'NHL', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'140', N'NHL', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'145', N'NHL', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'541', N'NHL', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'042', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'043', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'044', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'046', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'050', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'141', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'143', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'350', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'348', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'244', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'243', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'241', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'150', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'144', N'CWB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'047', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'049', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'148', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'248', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'048', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'124', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'149', N'CTB', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'045', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'053', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'154', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'252', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'345', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'354', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'051', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'151', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'251', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'254', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'351', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'450', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'052', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'255', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'059', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'155', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'359', N'NRT', N'WHP', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'012', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'013', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'014', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'112', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'113', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'212', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'213', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'214', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'312', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'313', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'314', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'322', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'413', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'414', N'SHK', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'106', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'107', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'206', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'208', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'303', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'306', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'308', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'006', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'406', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'408', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'503', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'506', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'606', N'EST', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'054', N'UNS', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'055', N'UNS', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'057', N'UNS', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'153', N'UNS', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'257', N'UNS', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'157', N'UNS', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'002', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'010', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'011', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'018', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'104', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'310', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'110', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'204', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'210', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'211', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'304', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'410', N'ICT', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'001', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'101', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'301', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'401', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'402', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'501', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'601', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'701', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'801', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'910', N'CBD', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'003', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'005', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'007', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'008', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'009', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'209', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'103', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'105', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'108', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'109', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'203', N'RES', N'MAT', N'SYD');
			INSERT [dbo].[SubDepot_Grouping] ([CF], [Group], [Depot], [RF]) VALUES (N'205', N'RES', N'MAT', N'SYD');

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

