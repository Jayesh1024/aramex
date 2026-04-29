CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_vwSingleCycleCF` as
	select distinct h.Country, h.RFCode, d.CFCode from `{{ project_id }}.{{ dataset_id }}.dbo_KPIGroupHead` h
	left join `{{ project_id }}.{{ dataset_id }}.dbo_KPIGroupDet` d on h.GroupID = d.GroupID
	where h.GroupName like '%single cycle%' or h.GroupName like '%single%' or h.GroupName like '%once a day%'