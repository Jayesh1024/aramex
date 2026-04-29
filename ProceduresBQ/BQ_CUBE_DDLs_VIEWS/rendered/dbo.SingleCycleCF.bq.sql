CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SingleCycleCF` 
AS
/*
	select h.Country, h.RFCode, d.CFCode, COUNT(*) num 
	from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupHead` h
	inner join `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupDet` d on h.GroupID = d.GroupID
	where h.GroupName like '%single cycle%' or h.GroupName like '%single%' or h.GroupName like '%once a day%'
	group by h.Country, h.RFCode, d.CFCode 
*/

	SELECT DISTINCT h.Country, h.RFCode, d.CFCode 
	FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupHead` h
	INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupDet` d ON h.GroupID = d.GroupID 
	WHERE h.GroupName LIKE '%single cycle%' OR h.GroupName LIKE '%single%' OR h.GroupName LIKE '%once a day%';