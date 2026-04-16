"""
Skeleton DAG for SSIS package: HUB_Invoice
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Invoice"

with DAG(
    dag_id="ssis_skeleton_hub_invoice",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_invoice"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load HUB_Invoice
        op_4 = EmptyOperator(task_id="package_final_load_hub_invoice")

        # ref_id: Package\\Final\\Load_Label_Invoices
        op_9 = EmptyOperator(task_id="package_final_load_label_invoices")

        # ref_id: Package\\Final\\Load_LNK_InvoiceLine
        op_5 = EmptyOperator(task_id="package_final_load_lnk_invoiceline")

        # ref_id: Package\\Final\\Load_LNK_Invoice_Label
        op_6 = EmptyOperator(task_id="package_final_load_lnk_invoice_label")

        # ref_id: Package\\Final\\Load_LSAT_InvoiceHead
        op_7 = EmptyOperator(task_id="package_final_load_lsat_invoicehead")

        # ref_id: Package\\Final\\Load_LSAT_InvoiceLine
        op_8 = EmptyOperator(task_id="package_final_load_lsat_invoiceline")

        # ref_id: Package\\Final\\Set LastDate (FMS_Invoice)
        op_10 = EmptyOperator(task_id="package_final_set_lastdate_fms_invoice")

    with TaskGroup(group_id="tg_package_final_undtcktinvoice"):
        # STOCK:SEQUENCE — ref_id: Package\\Final UndTcktInvoice
        op_1 = EmptyOperator(task_id="package_final_undtcktinvoice")

        # ref_id: Package\\Final UndTcktInvoice\\Load UndTckt Invoice
        op_2 = EmptyOperator(task_id="package_final_undtcktinvoice_load_undtckt_invoice")

        # ref_id: Package\\Final UndTcktInvoice\\Set LastDate (UndTckt Invoice)
        op_3 = EmptyOperator(task_id="package_final_undtcktinvoice_set_lastdate_undtckt_invoice")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_11 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Get LastDate (FMS_Invoice)
        op_16 = EmptyOperator(task_id="package_staging_get_lastdate_fms_invoice")

        # ref_id: Package\\Staging\\Load FMS_InvoiceBooks_Stg
        op_17 = EmptyOperator(task_id="package_staging_load_fms_invoicebooks_stg")

        # ref_id: Package\\Staging\\Load FMS_InvoiceHead_Stg
        op_18 = EmptyOperator(task_id="package_staging_load_fms_invoicehead_stg")

        # ref_id: Package\\Staging\\Load FMS_InvoiceLines_Stg
        op_19 = EmptyOperator(task_id="package_staging_load_fms_invoicelines_stg")

        # ref_id: Package\\Staging\\Truncate Staging tables
        op_20 = EmptyOperator(task_id="package_staging_truncate_staging_tables")

    with TaskGroup(group_id="tg_package_staging_undtcktinvoice"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging UndTcktInvoice
        op_12 = EmptyOperator(task_id="package_staging_undtcktinvoice")

        # ref_id: Package\\Staging UndTcktInvoice\\FMS_UndTcktInvoice_Load
        op_13 = EmptyOperator(task_id="package_staging_undtcktinvoice_fms_undtcktinvoice_load")

        # ref_id: Package\\Staging UndTcktInvoice\\Get LastDate (UndTckt Invoice)
        op_14 = EmptyOperator(task_id="package_staging_undtcktinvoice_get_lastdate_undtckt_invoice")

        # ref_id: Package\\Staging UndTcktInvoice\\Truncate Staging tables
        op_15 = EmptyOperator(task_id="package_staging_undtcktinvoice_truncate_staging_tables")

    # --- precedence (upstream >> downstream) ---
    op_11 >> op_0
    op_7 >> op_9
    op_4 >> op_5
    op_4 >> op_6
    op_6 >> op_7
    op_5 >> op_8
    op_8 >> op_10
    op_9 >> op_10
    op_12 >> op_1
    op_2 >> op_3
    op_20 >> op_16
    op_16 >> op_17
    op_16 >> op_18
    op_16 >> op_19
    op_14 >> op_13
    op_15 >> op_14
