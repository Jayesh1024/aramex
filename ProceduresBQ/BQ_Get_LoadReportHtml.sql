{#-- ==========================================================================================
Routine:     Get_LoadReportHtml
Description: Generates the load report in html format
History:
    22/11/2019  P. Waldron      Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.Staging_Get_LoadReportHtml`(
    IN p_ProcessId INT64,
    IN p_ExecutionId INT64
)
BEGIN
    DECLARE v_HTML STRING;
    DECLARE v_BodyIntro STRING;
    DECLARE v_BodyTable1 STRING;
    DECLARE v_BodyTable2 STRING;
    DECLARE v_BodyTable3 STRING;
    DECLARE v_BodyEnd STRING;

    DECLARE v_PackageName STRING;
    DECLARE v_ExecutionStart TIMESTAMP;
    DECLARE v_ExecutionEnd TIMESTAMP;
    DECLARE v_ExecutionResult STRING;

    SET v_HTML = '''
<!DOCTYPE html>
<html>
  <head>
  <style>
    body { font-family: Tahoma,Geneva,sas-serif; font-size: 11px; }
    table { font-family: Tahoma,Geneva,sas-serif; border: 1px solid #f3efef; text-align: center; border-collapse: collapse; }
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
</html>''';

    -- Construct HTML Table 1: Load Log Details
    SET v_BodyTable1 = (
        SELECT CONCAT(
            '<table><thead><tr><th>Started</th><th>Component</th><th>Load Result</th><th>Duration</th><th>Inserted</th><th>Updated</th><th>Errors</th><th>Error Message</th></tr></thead><tbody>',
            IFNULL(STRING_AGG(
                CONCAT(
                    '<tr>',
                    '<td>', IFNULL(Started, ''), '</td>',
                    '<td align="left">', IFNULL(Component, ''), '</td>',
                    '<td>', IFNULL(Result, ''), '</td>',
                    '<td>', IFNULL(Duration, ''), '</td>',
                    '<td>', IFNULL(Inserted, ''), '</td>',
                    '<td>', IFNULL(Updated, ''), '</td>',
                    '<td>', IFNULL(Errors, ''), '</td>',
                    '<td align="left">', IFNULL(ErrorMessage, ''), '</td>',
                    '</tr>'
                ),
                '' 
            ), ''),
            '</tbody></table>'
        )
        FROM (
            SELECT 
                SUBSTR(CAST(started AS STRING), 1, 19) AS Started,
                Component,
                -- UDF Call: dbo.FormatDuration -> dbo_FormatDuration
                `{{ project_id }}.{{ target_dataset_id }}.dbo_FormatDuration`(started, ended, 'hh:mm:ss') AS Duration,
                Result,
                FORMAT("%'d", IFNULL(Inserted, 0)) AS Inserted,
                FORMAT("%'d", IF(IFNULL(Updated, -1) = -1, 0, Updated)) AS Updated,
                FORMAT("%'d", IF(IFNULL(Errors, -1) = -1, 0, Errors)) AS Errors,
                IFNULL(ErrorMessage, '') AS ErrorMessage
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadLog` 
            WHERE ProcessID = p_ProcessId
            ORDER BY Id DESC
        )
    );

    -- Get SSIS execution outcome
    SET (v_PackageName, v_ExecutionStart, v_ExecutionEnd, v_ExecutionResult) = (
        SELECT AS STRUCT 
            package_name,
            start_time,
            end_time,
            CASE status 
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
        FROM `{{ project_id }}.{{ target_dataset_id }}.SSISDB_executions` 
        WHERE execution_id = p_ExecutionId
        LIMIT 1
    );

    -- Construct HTML Table 2: Packages Executed
    SET v_BodyTable2 = (
        SELECT CONCAT(
            '<p>Packages executed:</p><table><thead><tr><th>Package Name</th><th>Started</th><th>Ended</th><th>Outcome</th></tr></thead><tbody>',
            IFNULL(STRING_AGG(
                CONCAT(
                    '<tr>',
                    '<td align="left">', IFNULL(Package_Name, ''), '</td>',
                    '<td>', IFNULL(Started, ''), '</td>',
                    '<td>', IFNULL(Ended, ''), '</td>',
                    '<td>', IFNULL(ExecutionResult, ''), '</td>',
                    '</tr>'
                ),
                ''
            ), ''),
            '</tbody></table>'
        )
        FROM (
            SELECT 
                e.package_name AS Package_Name,
                FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', es.start_time) AS Started,
                FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', es.end_time) AS Ended,
                CASE es.execution_result
                    WHEN 0 THEN 'Success'
                    WHEN 1 THEN 'Failure'
                    WHEN 2 THEN 'Completion'
                    WHEN 3 THEN 'Cancelled'
                END AS ExecutionResult
            FROM `{{ project_id }}.{{ target_dataset_id }}.SSISDB_executables` e
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.SSISDB_executable_statistics` es
                ON e.executable_id = es.executable_id
               AND e.execution_id = es.execution_id
            WHERE e.package_path = '\\Package'
              AND e.execution_id = p_ExecutionId
            ORDER BY es.end_time, es.execution_id
        )
    );

    -- Construct HTML Table 3: Package Errors
    SET v_BodyTable3 = (
        SELECT IF(COUNT(1) > 0,
            CONCAT(
                '<p>Package/Task errors encountered:</p><table><thead><tr><th>Package Name</th><th>Task Name</th><th>Event</th><th>Occured</th><th>Error Message</th></tr></thead><tbody>',
                STRING_AGG(
                    CONCAT(
                        '<tr>',
                        '<td>', IFNULL(PackageName, ''), '</td>',
                        '<td align="left">', IFNULL(TaskName, ''), '</td>',
                        '<td>', IFNULL(Event, ''), '</td>',
                        '<td>', IFNULL(Occurred, ''), '</td>',
                        '<td align="left">', IFNULL(ErrorMessage, ''), '</td>',
                        '</tr>'
                    ),
                    ''
                ),
                '</tbody></table>'
            ),
            NULL
        )
        FROM (
            SELECT  
                package_name AS PackageName, 
                message_source_name AS TaskName,
                SUBSTR(event_name, 3) AS Event,
                FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', message_time) AS Occurred,
                message AS ErrorMessage
            FROM `{{ project_id }}.{{ target_dataset_id }}.SSISDB_event_messages`
            WHERE operation_id = p_ExecutionId
              AND event_name = 'OnError'
            ORDER BY event_message_id
        )
    );

    -- Format email Html variables
    SET v_BodyIntro = CONCAT(IFNULL(v_PackageName, 'Unknown Package'), ' load results for ProcessId ', CAST(p_ProcessId AS STRING), ':');
    SET v_BodyEnd   = CONCAT('Review logs on project ', @@project_id, ' for details.');

    -- Inject values into HTML template
    SET v_HTML = REPLACE(v_HTML, '$bodyIntro', IFNULL(v_BodyIntro, ''));
    SET v_HTML = REPLACE(v_HTML, '$bodyEnd', IFNULL(v_BodyEnd, ''));
    SET v_HTML = REPLACE(v_HTML, '$bodyTable1', IFNULL(v_BodyTable1, ''));
    SET v_HTML = REPLACE(v_HTML, '$bodyTable2', IFNULL(v_BodyTable2, ''));
    SET v_HTML = REPLACE(v_HTML, '$bodyTable3', IFNULL(v_BodyTable3, ''));

    -- Final Output
    SELECT 
        v_HTML AS HtmlBody, 
        IFNULL(v_BodyTable1, '') AS BodyTable1, 
        IFNULL(v_BodyTable2, '') AS BodyTable2,
        IFNULL(v_BodyTable3, '') AS BodyTable3;

END;