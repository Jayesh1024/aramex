-- ==========================================================================================
-- Routine:     Get_LoadReportHtml
-- Description: Generates the load report in html format
-- Example:     Exec [Staging].[Get_LoadReportHtml] 346,847
-- History:
--  02/02/2023  B. Woods      Copied & modified
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_Get_ExportReportHtml`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_HTML        STRING;
  DECLARE v_BodyIntro   STRING;
  DECLARE v_BodyTable1  STRING;
  DECLARE v_BodyTable2  STRING;
  DECLARE v_BodyTable3  STRING DEFAULT '';
  DECLARE v_BodyEnd     STRING DEFAULT '';
  DECLARE v_DateBOM     DATE;

  -- -----------------------------------------------------------------------
  -- Base HTML template (Using triple quotes for multi-line string)
  -- -----------------------------------------------------------------------
  SET v_HTML = """
<!DOCTYPE html>
<html>
  <head>
  <style>
    body { font-family: Tahoma,Geneva,sans-serif; font-size: 11px; }
    table { font-family: Tahoma,Geneva,sans-serif; border: 1px solid #f3efef; text-align: center; border-collapse: collapse; }
    table td, table th { border: 1px solid #f3efef; padding: 3px 2px; }
    table tbody td { font-size: 10px; }
    table tr:nth-child(even) { background: #D0E4F5; }
    table thead { background: #0B6FA4; border-bottom: 3px solid #f3efef; }
    table thead th { font-size: 11px; font-weight: bold; color: #FFFFFF; text-align: center; border-left: 2px solid #f3efef; }
  </style>
  </head>
<body>
  <p>$bodyIntro</p>
  $bodyTable1
  <br/>
  $bodyTable2
  <br/>
  $bodyTable3
  <br/>
  <p>$bodyEnd</p>
</body>
</html>""";

  -- -----------------------------------------------------------------------
  -- Table 1: Row counts per DeliveryRF
  -- -----------------------------------------------------------------------
  SET v_BodyTable1 = (
    SELECT AS VALUE 
      CONCAT(
        '<table>',
          '<thead><tr><th>Delivery RF</th><th>Row Count</th></tr></thead>',
          '<tbody>',
            STRING_AGG(
              CONCAT('<tr><td>', CAST(DeliveryRF AS STRING), '</td><td align="left">', CAST(cnt AS STRING), '</td></tr>'),
              ''
            ORDER BY DeliveryRF),
          '</tbody>',
        '</table>'
      )
    FROM (
      SELECT DeliveryRF, COUNT(*) AS cnt
      FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Export_KPI_Delivery_Perf_Data`
      GROUP BY DeliveryRF
    )
  );

  -- -----------------------------------------------------------------------
  -- Table 2: Total row count
  -- -----------------------------------------------------------------------
  SET v_BodyTable2 = (
    SELECT AS VALUE 
      CONCAT(
        '<table>',
          '<thead><tr><th>&nbsp;</th><th>&nbsp;</th></tr></thead>',
          '<tbody>',
            '<tr><td>Total Rows</td><td align="left">', CAST(COUNT(*) AS STRING), '</td></tr>',
          '</tbody>',
        '</table>'
      )
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Export_KPI_Delivery_Perf_Data`
  );

  -- -----------------------------------------------------------------------
  -- Format intro and footer (Scalar Subquery Fixed)
  -- -----------------------------------------------------------------------
  SET v_DateBOM = (
    SELECT DATE(MIN(DateBOM))
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Export_KPI_Delivery_Perf_Data`
  );

  SET v_BodyIntro = CONCAT(
    'FMS_RFBatchingPerformanceBonus load results for Date BOM = ',
    IFNULL(FORMAT_DATE('%Y-%m-%d', v_DateBOM), 'N/A'),
    ':'
  );

  -- -----------------------------------------------------------------------
  -- Inject sections into HTML template
  -- -----------------------------------------------------------------------
  SET v_HTML = REPLACE(v_HTML, '$bodyIntro',  IFNULL(v_BodyIntro,  ''));
  SET v_HTML = REPLACE(v_HTML, '$bodyTable1', IFNULL(v_BodyTable1, ''));
  SET v_HTML = REPLACE(v_HTML, '$bodyTable2', IFNULL(v_BodyTable2, ''));
  SET v_HTML = REPLACE(v_HTML, '$bodyTable3', IFNULL(v_BodyTable3, ''));
  SET v_HTML = REPLACE(v_HTML, '$bodyEnd',    IFNULL(v_BodyEnd,    ''));

  -- -----------------------------------------------------------------------
  -- Return results to caller
  -- -----------------------------------------------------------------------
  SELECT
    v_HTML                    AS HtmlBody,
    IFNULL(v_BodyTable1, '')  AS BodyTable1,
    IFNULL(v_BodyTable2, '')  AS BodyTable2,
    IFNULL(v_BodyTable3, '')  AS BodyTable3;

END;