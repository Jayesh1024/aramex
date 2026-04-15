"""
Skeleton DAG for SSIS package: SAT_Overrides
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "SAT_Overrides"

with DAG(
    dag_id="ssis_skeleton_sat_overrides",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "sat_overrides"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_customer_overrides_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Customer Overrides - Final
        op_0 = EmptyOperator(task_id="package_customer_overrides_final")

        # ref_id: Package\\Customer Overrides - Final\\Load SAT_CustomerPriceOverride
        op_1 = EmptyOperator(task_id="package_customer_overrides_final_load_sat_customerpriceoverride")

    with TaskGroup(group_id="tg_package_customer_overrides_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Customer Overrides - Staging
        op_2 = EmptyOperator(task_id="package_customer_overrides_staging")

        # ref_id: Package\\Customer Overrides - Staging\\Load Customer Price Overrides
        op_3 = EmptyOperator(task_id="package_customer_overrides_staging_load_customer_price_overrides")

        # ref_id: Package\\Customer Overrides - Staging\\Truncate Customer Overrides
        op_4 = EmptyOperator(task_id="package_customer_overrides_staging_truncate_customer_overrides")

    with TaskGroup(group_id="tg_package_zones_overrides_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Zones Overrides - Final
        op_5 = EmptyOperator(task_id="package_zones_overrides_final")

        # ref_id: Package\\Zones Overrides - Final\\Load SAT Zone Overrides
        op_6 = EmptyOperator(task_id="package_zones_overrides_final_load_sat_zone_overrides")

        # ref_id: Package\\Zones Overrides - Final\\Load SAT Zones
        op_7 = EmptyOperator(task_id="package_zones_overrides_final_load_sat_zones")

    with TaskGroup(group_id="tg_package_zones_overrides_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Zones Overrides- Staging
        op_8 = EmptyOperator(task_id="package_zones_overrides_staging")

        # ref_id: Package\\Zones Overrides- Staging\\Load fl_Zones
        op_11 = EmptyOperator(task_id="package_zones_overrides_staging_load_fl_zones")

        # ref_id: Package\\Zones Overrides- Staging\\Load Zone Satchel Overiides
        op_9 = EmptyOperator(task_id="package_zones_overrides_staging_load_zone_satchel_overiides")

        # ref_id: Package\\Zones Overrides- Staging\\Load Zone Weight Overiides
        op_10 = EmptyOperator(task_id="package_zones_overrides_staging_load_zone_weight_overiides")

        # ref_id: Package\\Zones Overrides- Staging\\Truncate Zone Overrides
        op_12 = EmptyOperator(task_id="package_zones_overrides_staging_truncate_zone_overrides")

        # ref_id: Package\\Zones Overrides- Staging\\Truncate Zones
        op_13 = EmptyOperator(task_id="package_zones_overrides_staging_truncate_zones")

    # --- precedence (upstream >> downstream) ---
    op_2 >> op_0
    op_4 >> op_3
    op_8 >> op_5
    op_7 >> op_6
    op_13 >> op_11
    op_12 >> op_9
    op_12 >> op_10
