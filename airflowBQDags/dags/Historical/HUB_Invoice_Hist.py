"""
DAG for SSIS package: HUB_Invoice (GCP / BigQuery).
Staging + Final + UndTcktInvoice: BigQueryInsertJobOperator CALLs where implemented.
Sequence containers (STOCK:SEQUENCE) â†’ TaskGroup.

GCP naming (from SQL Server metadata in outputs/ and Packages/):
  SSIS uses schemas such as dv, dbo, Staging (e.g. [dv].[Load_HUB_Invoice], [Staging].[Set_LastValue]).
  In BigQuery, replace only the dot: schema.object â†’ schema_object, preserving casing from the source
  (e.g. dv_Load_HUB_Invoice, Staging_Set_LastValue, Staging_FMS_InvoiceHead_Stg). Same for routines (SPs).
"""
from __future__ import annotations

from datetime import datetime
from airflow.models import Variable
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")

with DAG(
    dag_id="ssis_skeleton_hub_invoice_Hist",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_invoice", "Historical"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "DisableUndTcktFinal": 0,
        "DisableUndTcktStaging": 0,
        "process_id": -453,
        "RecordSource": 'FMS_Invoice',
        "RecordSource2": 'FMSUndTcktInvoice',
        "RecordSourceFMS_InvoiceBooks": 'FMS_InvoiceBooks',
        "RecordSourceFMS_InvoiceHead": 'FMS_InvoiceHead',
        "RecordSourceFMS_InvoiceLines": 'FMS_InvoiceLines',
        # dv_Load_Label_Invoices(p_ProcessID, p_Start_Date STRING, p_End_Date STRING); SSIS only passed LastDate â€” use this if XCom is empty/NULL.
        "LabelInvoicesDefaultStartDate": '2000-01-01 00:00:00',
        # dv_Load_Label_Invoices(p_ProcessID, p_Start_Date STRING, p_End_Date STRING); SSIS only passed LastDate â€” use this if XCom is empty/NULL.
        "LabelInvoicesDefaultStartDate": '2000-01-01 00:00:00',
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE â€” ref_id: Package\\Final (no package_final empty; staging loads >> first task)

        # ref_id: Package\\Final\\Load HUB_Invoice â€” SSIS: Exec [dv].[Load_HUB_Invoice] ProcessId, RecordSource
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_invoice",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_HUB_Invoice`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final\\Load_Label_Invoices â€” SSIS: EXEC dv.Load_Label_Invoices ?, ? (ProcessId, User::LastDate).
        # BQ SP: dv_Load_Label_Invoices(p_ProcessID, p_Start_Date STRING, p_End_Date STRING); NULL end â†’ SP uses CURRENT_DATETIME() window (see SP body).
        op_9 = BigQueryInsertJobOperator(
            task_id="package_final_load_label_invoices",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_Label_Invoices_Hist`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final\\Load_LNK_InvoiceLine â€” SSIS: Exec [dv].[Load_LNK_InvoiceLine] ProcessId
        op_5 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_invoiceline",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LNK_InvoiceLine`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSourceFMS_InvoiceLines }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final\\Load_LNK_Invoice_Label â€” SSIS: Exec [dv].[Load_LNK_Invoice_Label] ProcessId
        op_6 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_invoice_label",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LNK_Invoice_Label`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSourceFMS_InvoiceBooks }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final\\Load_LSAT_InvoiceHead â€” SSIS: EXEC dv.Load_LSAT_InvoiceHead ProcessId
        op_7 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_invoicehead",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LSAT_InvoiceHead`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSourceFMS_InvoiceHead }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final\\Load_LSAT_InvoiceLine â€” SSIS: Exec [dv].[Load_LSAT_InvoiceLine] ProcessId
        op_8 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_invoiceline",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LSAT_InvoiceLine`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSourceFMS_InvoiceLines }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final\\Set LastDate (FMS_Invoice) â€” SSIS: Exec [Staging].[Set_LastValue]; BQ: Staging_Set_LastValue(p_RecordSource, p_ColumnName, p_LastValue, p_Force)
        op_10 = BigQueryInsertJobOperator(
            task_id="package_final_set_lastdate_fms_invoice",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`('{{{{ params.RecordSource }}}}', "
                        "NULL, "
                        "NULL, "
                        "FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    with TaskGroup(group_id="tg_package_final_undtcktinvoice") as tg_final_undtckt:
        # STOCK:SEQUENCE â€” ref_id: Package\\Final UndTcktInvoice (no package_final_undtcktinvoice empty; staging load >> first task)

        # ref_id: Package\\Final UndTcktInvoice\\Load UndTckt Invoice â€” SSIS: Exec [dbo].[Load_UndTckt_Invoice] ProcessId
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_undtcktinvoice_load_undtckt_invoice",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_UndTckt_Invoice`({{{{ dag_run.conf.get('process_id', params.process_id) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final UndTcktInvoice\\Set LastDate (UndTckt Invoice) â€” SSIS binds $RecordSource2; BQ: Staging_Set_LastValue(4 args)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_undtcktinvoice_set_lastdate_undtckt_invoice",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource2 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE â€” ref_id: Package\\Staging (no package_staging empty; parallel loads >> package_final_load_hub_invoice)

        # ref_id: Package\\Staging\\Truncate Staging tables
        op_20 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_staging_tables",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FMS_InvoiceHead_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FMS_InvoiceLines_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FMS_InvoiceBooks_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FastwayLabels_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Staging\\Load FMS_InvoiceBooks_Stg
        # SSIS: OLE DB â€¦ â†’ [Staging].[FMS_InvoiceBooks_Stg]; BQ: sp_load_Staging_FMS_InvoiceBooks_Stg_Hist
        op_17 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_invoicebooks_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceBooks_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Staging\\Load FMS_InvoiceHead_Stg
        # SSIS: â€¦ â†’ [Staging].[FMS_InvoiceHead_Stg]; BQ: sp_load_Staging_FMS_InvoiceHead_Stg_Hist
        op_18 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_invoicehead_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceHead_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Staging\\Load FMS_InvoiceLines_Stg
        # SSIS: â€¦ â†’ [Staging].[FMS_InvoiceLines_Stg]; BQ: sp_load_Staging_FMS_InvoiceLines_Stg_Hist
        op_19 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_invoicelines_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceLines_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )


    with TaskGroup(group_id="tg_package_staging_undtcktinvoice") as tg_staging_undtckt:
        # STOCK:SEQUENCE â€” ref_id: Package\\Staging UndTcktInvoice (no package_staging_undtcktinvoice empty)

        # ref_id: Package\\Staging UndTcktInvoice\\Truncate Staging tables â€” SSIS: TRUNCATE [Staging].[FMS_UndTcktInvoice_Stg]
        op_15 = BigQueryInsertJobOperator(
            task_id="package_staging_undtcktinvoice_truncate_staging_tables",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FMS_UndTcktInvoice_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Staging UndTcktInvoice\\FMS_UndTcktInvoice_Load â€” SSIS: â€¦ â†’ [Staging].[FMS_UndTcktInvoice_Stg]; BQ: sp_load_Staging_FMS_UndTcktInvoice_Stg_Hist
        op_13 = BigQueryInsertJobOperator(
            task_id="package_staging_undtcktinvoice_fms_undtcktinvoice_load",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_UndTcktInvoice_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    # --- precedence (upstream >> downstream) ---
    op_7 >> op_9
    op_4 >> op_5
    op_4 >> op_6
    op_6 >> op_7
    op_5 >> op_8
    op_8 >> op_10
    op_9 >> op_10
    op_2 >> op_3
    op_20 >> op_17
    op_20 >> op_18
    op_20 >> op_19
    [op_17, op_18, op_19] >> op_4
    op_15 >> op_13
    op_13 >> op_2

    # TaskGroup-level precedence (cross-group edges are already encoded above
    # via task-level wiring; this makes the overall flow explicit in the DAG graph).
    tg_staging >> tg_final
    tg_staging_undtckt >> tg_final_undtckt