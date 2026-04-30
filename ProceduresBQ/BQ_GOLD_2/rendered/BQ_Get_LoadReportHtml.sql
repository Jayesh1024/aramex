CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Get_LoadReportHtml`(
    IN p_ProcessId INT64,
    IN p_ExecutionId INT64
)
BEGIN
    DECLARE v_HTML STRING;
    DECLARE v_BodyIntro STRING;
    DECLARE v_BodyTable1 STRING DEFAULT '';
    DECLARE v_BodyTable2 STRING DEFAULT '';
    DECLARE v_BodyTable3 STRING DEFAULT '';
    DECLARE v_BodyEnd STRING;
    
    DECLARE v_PackageName STRING;
    DECLARE v_ExecutionResult STRING;

    -- 1. Get SSIS execution outcome summary
    -- Fix: BQ uses SET (var1, var2) = (SELECT AS STRUCT...) instead of SELECT...INTO
    SET (v_PackageName, v_ExecutionResult) = (
      SELECT AS STRUCT
          package_name,
          CASE status 
              WHEN 1 THEN 'Created' WHEN 2 THEN 'Running' WHEN 3 THEN 'Canceled' 
              WHEN 4 THEN 'Failed' WHEN 5 THEN 'Pending' WHEN 6 THEN 'Ended Unexpectedly' 
              WHEN 7 THEN 'Succeeded' WHEN 8 THEN 'Stopping' WHEN 9 THEN 'Completed' 
          END
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.SSISDB_catalog_executions`
      WHERE execution_id = p_ExecutionId
      LIMIT 1
    );

    -- 2. Build BodyTable1 (Load Log Details)
    -- Table name changed from Staging.LoadLog to Staging_LoadLog
    SET v_BodyTable1 = (
        SELECT 
            FORMAT('<table><thead><tr><th>Started</th><th>Component</th><th>Load Result</th><th>Duration</th><th>Inserted</th><th>Updated</th><th>Errors</th><th>Error Message</th></tr></thead><tbody>%s</tbody></table>',
                ARRAY_TO_STRING(ARRAY_AGG(
                    FORMAT('<tr><td>%s</td><td align="left">%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td align="left">%s</td></tr>',
                        LEFT(CAST(started AS STRING), 19),
                        Component,
                        Result,
                        FORMAT_TIMESTAMP('%H:%M:%S', TIMESTAMP_SECONDS(TIMESTAMP_DIFF(ended, started, SECOND))),
                        FORMAT("%'d", COALESCE(Inserted, 0)),
                        FORMAT("%'d", IF(COALESCE(Updated, -1) = -1, 0, Updated)),
                        FORMAT("%'d", IF(COALESCE(Errors, -1) = -1, 0, Errors)),
                        COALESCE(ErrorMessage, '')
                    ) ORDER BY Id DESC
                ), '')
            )
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadLog`
        WHERE ProcessID = p_ProcessId
    );

    -- 3. Build BodyTable2 (Package Executions)
    -- Table names updated with underscores
    SET v_BodyTable2 = (
        SELECT 
            FORMAT('<p>Packages executed:</p><table><thead><tr><th>Package Name</th><th>Started</th><th>Ended</th><th>Outcome</th></tr></thead><tbody>%s</tbody></table>',
                ARRAY_TO_STRING(ARRAY_AGG(
                    FORMAT('<tr><td align="left">%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
                        package_name,
                        FORMAT_DATETIME('%Y-%m-%d %H:%M:%S', es.start_time),
                        FORMAT_DATETIME('%Y-%m-%d %H:%M:%S', es.end_time),
                        CASE es.execution_result
                            WHEN 0 THEN 'Success' WHEN 1 THEN 'Failure'
                            WHEN 2 THEN 'Completion' WHEN 3 THEN 'Cancelled'
                        END
                    ) ORDER BY es.end_time, es.execution_id
                ), '')
            )
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.SSISDB_catalog_executables` e
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.SSISDB_catalog_executable_statistics` es
            ON e.executable_id = es.executable_id AND e.execution_id = es.execution_id
        WHERE package_path = '\\Package' AND e.execution_id = p_ExecutionId
    );

    -- 4. Build BodyTable3 (Errors)
    -- Table name updated with underscore
    SET v_BodyTable3 = (
        SELECT 
            FORMAT('<p>Package/Task errors encountered:</p><table><thead><tr><th>Package Name</th><th>Task Name</th><th>Event</th><th>Occured</th><th>Error Message</th></tr></thead><tbody>%s</tbody></table>',
                ARRAY_TO_STRING(ARRAY_AGG(
                    FORMAT('<tr><td>%s</td><td align="left">%s</td><td>%s</td><td>%s</td><td align="left">%s</td></tr>',
                        package_name, message_source_name, SUBSTR(event_name, 4),
                        FORMAT_DATETIME('%Y-%m-%d %H:%M:%S', message_time), message
                    ) ORDER BY event_message_id
                ), '')
            )
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.SSISDB_catalog_event_messages`
        WHERE operation_id = p_ExecutionId AND event_name = 'OnError'
    );

    -- 5. Construct Final HTML
    SET v_BodyIntro = FORMAT('%s load results for ProcessId %d:', COALESCE(v_PackageName, 'Process'), p_ProcessId);
    SET v_BodyEnd = 'Review logs on BigQuery for details.';

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
      <p>""" || COALESCE(v_BodyIntro, '') || """</p>
      """ || COALESCE(v_BodyTable1, '') || """
      <br/>
      """ || COALESCE(v_BodyTable2, '') || """
      <br/>
      """ || COALESCE(v_BodyTable3, '') || """
      <br/>
      <p>""" || COALESCE(v_BodyEnd, '') || """</p>
    </body>
    </html>""";

    -- Return the results as a result set
    SELECT 
        v_HTML AS HtmlBody, 
        COALESCE(v_BodyTable1, '') AS BodyTable1, 
        COALESCE(v_BodyTable2, '') AS BodyTable2, 
        COALESCE(v_BodyTable3, '') AS BodyTable3;

END;