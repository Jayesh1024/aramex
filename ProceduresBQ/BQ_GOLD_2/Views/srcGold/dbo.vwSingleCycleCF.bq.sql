CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_vwSingleCycleCF` as
SELECT DISTINCT h.Country, h.RFCode, d.CFCode
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupHead` h
LEFT JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupDet` d
  ON h.GroupID = d.GroupID
WHERE
  UPPER(h.GroupName) LIKE '%SINGLE CYCLE%'
  OR UPPER(h.GroupName) LIKE '%SINGLE%'
  OR UPPER(h.GroupName) LIKE '%ONCE A DAY%'
