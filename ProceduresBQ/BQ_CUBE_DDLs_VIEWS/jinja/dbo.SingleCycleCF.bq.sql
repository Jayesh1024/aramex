CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_SingleCycleCF` 
AS
/*
	select h.Country, h.RFCode, d.CFCode, COUNT(*) num 
	from `{{ project_id }}.{{ dataset_id }}.dbo_KPIGroupHead` h
	inner join `{{ project_id }}.{{ dataset_id }}.dbo_KPIGroupDet` d on h.GroupID = d.GroupID
	where h.GroupName like '%single cycle%' or h.GroupName like '%single%' or h.GroupName like '%once a day%'
	group by h.Country, h.RFCode, d.CFCode 
*/

	SELECT DISTINCT h.Country, h.RFCode, d.CFCode 
	FROM `{{ project_id }}.{{ dataset_id }}.dbo_KPIGroupHead` h
	INNER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_KPIGroupDet` d ON h.GroupID = d.GroupID 
	WHERE h.GroupName LIKE '%single cycle%' OR h.GroupName LIKE '%single%' OR h.GroupName LIKE '%once a day%';