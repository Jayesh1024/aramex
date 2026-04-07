

-- ==========================================================================================
-- Routine:     Get_LoadReportHtml
-- Description: Generates the load report in html format
-- Example:     Exec [Staging].[Get_LoadReportHtml] 346,847
-- History:
--  02/02/2023  B. Woods      Copied & modified
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.staging.Get_ExportReportHtml`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_HTML        STRING;
  DECLARE v_BodyIntro   STRING;
  DECLARE v_BodyTable1  STRING;
  DECLARE v_BodyTable2  STRING;
  DECLARE v_BodyTable3  STRING DEFAULT '';
  DECLARE v_BodyEnd     STRING;
  DECLARE v_DateBOM     DATE;

  -- -----------------------------------------------------------------------
  -- Base HTML template
  -- -----------------------------------------------------------------------
  SET v_HTML = '''
<!DOCTYPE html>
<html>
  <head>
  <style>
    body {
      font-family: Tahoma,Geneva,sas-serif;
      font-size: 11px;
    }
    table {
      font-family: Tahoma,Geneva,sas-serif;
      border: 1px solid #f3efef;
      text-align: center;
      border-collapse: collapse;
    }
    table td, table th {
      border: 1px solid #f3efef;
      padding: 3px 2px;
    }
    table tbody td {
      font-size: 10px;
    }
    table tr:nth-child(even) {
      background: #D0E4F5;
    }
    table thead {
      background: #0B6FA4;
      border-bottom: 3px solid #f3efef;
    }
    table thead th {
      font-size: 11px;
      font-weight: bold;
      color: #FFFFFF;
      text-align: center;
      border-left: 2px solid #f3efef;
    }
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
</html>''';

  -- -----------------------------------------------------------------------
  -- WAITFOR DELAY '00:00:05' omitted
  -- BQ has no sleep primitive; delay logic belongs in the orchestration layer
  -- -----------------------------------------------------------------------

  -- -----------------------------------------------------------------------
  -- Table 1: Row counts per DeliveryRF
  -- Replaces FOR XML PATH / ROOT / RAW HTML generation
  -- -----------------------------------------------------------------------
  SET v_BodyTable1 = (
    SELECT CONCAT(
      '<table>',
        '<thead><tr><th>Delivery RF</th><th>Row Count</th></tr></thead>',
        '<tbody>',
          STRING_AGG(
            CONCAT('<tr><td>', DeliveryRF, '</td><td align="left">', cnt, '</td></tr>'),
            ''
          ORDER BY DeliveryRF),
        '</tbody>',
      '</table>'
    )
    FROM (
      SELECT DeliveryRF, COUNT(*) AS cnt
      FROM `{{ project_id }}.{{ dataset_id }}.staging.Export_KPI_Delivery_Perf_Data`
      GROUP BY DeliveryRF
    )
  );

  -- -----------------------------------------------------------------------
  -- Table 2: Total row count
  -- -----------------------------------------------------------------------
  SET v_BodyTable2 = (
    SELECT CONCAT(
      '<table>',
        '<thead><tr><th>&nbsp;</th><th>&nbsp;</th></tr></thead>',
        '<tbody>',
          '<tr><td>Total Rows</td><td align="left">', COUNT(*), '</td></tr>',
        '</tbody>',
      '</table>'
    )
    FROM `{{ project_id }}.{{ dataset_id }}.staging.Export_KPI_Delivery_Perf_Data`
  );

  /*
  -- -----------------------------------------------------------------------
  -- SSIS execution outcome block - omitted (SSISDB not available in BQ)
  -- Preserved for reference
  -- -----------------------------------------------------------------------

  -- Get SSIS execution outcome
  SELECT
    @PackageName    = package_name,
    @ExecutionStart = start_time,
    @ExecutionEnd   = end_time,
    @ExecutionResult =
      CASE [status]
        WHEN 1 THEN 'Created'
        WHEN 2 THEN 'Running'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'Failed'
        WHEN 5 THEN 'Pending'
        WHEN 6 THEN 'Ended Unexpectedly'
        WHEN 7 THEN 'Succeeded'
        WHEN 8 THEN 'Stopping'
        WHEN 9 THEN 'Completed'
      END
  FROM [SSISDB].[catalog].executions e
  WHERE e.execution_id = @ExecutionId

  -- Get SSIS package execution outcome
  ;WITH SSISPackageExecutions AS (
    SELECT
      es.execution_id,
      e.package_name,
      FORMAT(es.start_time, 'yyyy-MM-dd HH:MM:ss') AS [Started],
      FORMAT(es.end_time,   'yyyy-MM-dd HH:MM:ss') AS Ended,
      (CASE es.execution_result
        WHEN 0 THEN 'Success'
        WHEN 1 THEN 'Failure'
        WHEN 2 THEN 'Completion'
        WHEN 3 THEN 'Cancelled'
      END) AS ExecutionResult
    FROM SSISDB.catalog.executables e
    LEFT JOIN SSISDB.catalog.executable_statistics es
      ON e.executable_id = es.executable_id
     AND e.execution_id  = es.execution_id
    WHERE package_path   = '\Package'
      AND e.execution_id = @ExecutionId
  )
  ... (HTML generation for BodyTable2)

  -- Get SSIS Errors (if any)
  ;WITH SSISErrorData AS (
    SELECT
      event_message_id,
      SUBSTRING(event_name, 3, 99) AS [Event],
      package_name                 AS PackageName,
      message_source_name          AS TaskName,
      FORMAT(message_time, 'yyyy-MM-dd HH:MM:ss') AS Occurred,
      [message]                    AS ErrorMessage
    FROM [SSISDB].[catalog].[event_messages] em
    WHERE operation_id = @ExecutionId
      AND event_name   = 'OnError'
  )
  ... (HTML generation for BodyTable3)
  */

  -- -----------------------------------------------------------------------
  -- Format intro and footer
  -- CONVERT(varchar(10), @DateBOM, 120) → FORMAT_DATE('%Y-%m-%d', v_DateBOM)
  -- -----------------------------------------------------------------------
  SELECT MIN(DateBOM) INTO v_DateBOM
  FROM `{{ project_id }}.{{ dataset_id }}.staging.Export_KPI_Delivery_Perf_Data`;

  SET v_BodyIntro = CONCAT(
    'FMS_RFBatchingPerformanceBonus load results for Date BOM = ',
    FORMAT_DATE('%Y-%m-%d', v_DateBOM),
    ':'
  );

  -- SET v_BodyEnd = CONCAT('Review logs on ', @@SERVERNAME, ' for details.');

  -- -----------------------------------------------------------------------
  -- Inject sections into HTML template
  -- -----------------------------------------------------------------------
  SET v_HTML = REPLACE(v_HTML, '$bodyIntro',  IFNULL(v_BodyIntro,  ''));
  -- SET v_HTML = REPLACE(v_HTML, '$bodyTable1', IFNULL(v_BodyTable1, ''));
  -- SET v_HTML = REPLACE(v_HTML, '$bodyTable2', IFNULL(v_BodyTable2, ''));
  -- SET v_HTML = REPLACE(v_HTML, '$bodyTable3', IFNULL(v_BodyTable3, ''));
  SET v_HTML = REPLACE(v_HTML, '$bodyEnd',    IFNULL(v_BodyEnd,    ''));

  -- -----------------------------------------------------------------------
  -- Return results to caller
  -- -----------------------------------------------------------------------
  CREATE TEMP TABLE Results AS
  SELECT
    v_HTML                        AS HtmlBody,
    IFNULL(v_BodyTable1, '')      AS BodyTable1,
    IFNULL(v_BodyTable2, '')      AS BodyTable2,
    IFNULL(v_BodyTable3, '')      AS BodyTable3;

END;