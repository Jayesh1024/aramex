CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_vwSingleCycleCF` as
	select distinct h.Country, h.RFCode, d.CFCode from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupHead` h
	left join `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupDet` d on h.GroupID = d.GroupID
	where h.GroupName like '%single cycle%' or h.GroupName like '%single%' or h.GroupName like '%once a day%'