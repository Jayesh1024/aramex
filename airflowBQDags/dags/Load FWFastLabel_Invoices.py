"""
Skeleton DAG for SSIS package: Load FWFastLabel_Invoices
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Load FWFastLabel_Invoices"

with DAG(
    dag_id="ssis_skeleton_load_fwfastlabel_invoices",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "load fwfastlabel_invoices"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load LSAT_FL_InvoiceHeader
        op_1 = EmptyOperator(task_id="package_final_load_lsat_fl_invoiceheader")

        # ref_id: Package\\Final\\Load LSAT_FL_InvoicePayment
        op_2 = EmptyOperator(task_id="package_final_load_lsat_fl_invoicepayment")

        # ref_id: Package\\Final\\Set Last InvoiceHeaderDate
        op_3 = EmptyOperator(task_id="package_final_set_last_invoiceheaderdate")

        # ref_id: Package\\Final\\Set Last InvoicePaymentDate
        op_4 = EmptyOperator(task_id="package_final_set_last_invoicepaymentdate")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_5 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Get Last InvoiceHeaderDate
        op_6 = EmptyOperator(task_id="package_staging_get_last_invoiceheaderdate")

        # ref_id: Package\\Staging\\Get Last InvoicePaymentDate
        op_7 = EmptyOperator(task_id="package_staging_get_last_invoicepaymentdate")

        # ref_id: Package\\Staging\\Load fl_InvoiceHeader_Stg
        op_8 = EmptyOperator(task_id="package_staging_load_fl_invoiceheader_stg")

        # ref_id: Package\\Staging\\Load fl_InvoicePayment_Stg
        op_9 = EmptyOperator(task_id="package_staging_load_fl_invoicepayment_stg")

        # ref_id: Package\\Staging\\Truncate Staging tables
        op_10 = EmptyOperator(task_id="package_staging_truncate_staging_tables")

    # --- precedence (upstream >> downstream) ---
    op_5 >> op_0
    op_1 >> op_3
    op_2 >> op_4
    op_10 >> op_6
    op_10 >> op_7
    op_6 >> op_8
    op_7 >> op_9
