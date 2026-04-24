"""
Skeleton DAG for SSIS package: HUB_Label(old)
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime
import os
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup


GCP_PROJECT = os.getenv("GCP_PROJECT")

with DAG(
    dag_id="ssis_skeleton_hub_label_old",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label(old)"],
    params={
        "DisableFinal": 0,
        "DisableLoad_API_RF_AdHocLabel_AllocationHistory": 0,
        "DisableLoad_ConsignmentItem": 0,
        "DisableLoad_fl_ConItem": 0,
        "DisableLoad_HDManifests": 0,
        "DisableLoad_LabelMaster": 0,
        "DisableLoad_tblFastLabel_Consignment": 0,
        "DisableStaging": 0,
        "ProcessId": 185,
        "RecordSource1": 'LabelMaster',
        "RecordSource2": 'DynamicLabel',
        "RecordSource3": 'FastLabel',
        "RecordSource4": 'MyFastway',
        "RecordSource5": 'IFS',
        "RecordSource6": 'FastLabelEnterprise',
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final_load_hub"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load HUB)
        op_0 = EmptyOperator(task_id="package_final_load_hub")

        # ref_id: Package\\Final (Load HUB)\\Load HUB_Label
        op_2 = EmptyOperator(task_id="package_final_load_hub_load_hub_label")

    with TaskGroup(group_id="tg_package_final_load_other_sats"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load other SATs)
        op_9 = EmptyOperator(task_id="package_final_load_other_sats")

        # ref_id: Package\\Final (Load other SATs)\\Load SAT_Label_Allocation_FL
        op_10 = EmptyOperator(task_id="package_final_load_other_sats_load_sat_label_allocation_fl")

        # ref_id: Package\\Final (Load other SATs)\\Load SAT_Label_Allocation_FLE
        op_11 = EmptyOperator(task_id="package_final_load_other_sats_load_sat_label_allocation_fle")

        # ref_id: Package\\Final (Load other SATs)\\Load SAT_Label_Allocation_IFS
        op_12 = EmptyOperator(task_id="package_final_load_other_sats_load_sat_label_allocation_ifs")

        # ref_id: Package\\Final (Load other SATs)\\Load SAT_Label_Allocation_MF
        op_13 = EmptyOperator(task_id="package_final_load_other_sats_load_sat_label_allocation_mf")

        # ref_id: Package\\Final (Load other SATs)\\Set LastDate (FastLabel)
        op_14 = EmptyOperator(task_id="package_final_load_other_sats_set_lastdate_fastlabel")

        # ref_id: Package\\Final (Load other SATs)\\Set LastDate (FastLabelEnterprise)
        op_15 = EmptyOperator(task_id="package_final_load_other_sats_set_lastdate_fastlabelenterprise")

        # ref_id: Package\\Final (Load other SATs)\\Set LastDate (IFS)
        op_16 = EmptyOperator(task_id="package_final_load_other_sats_set_lastdate_ifs")

        # ref_id: Package\\Final (Load other SATs)\\Set LastDate (MyFastway)
        op_17 = EmptyOperator(task_id="package_final_load_other_sats_set_lastdate_myfastway")

    with TaskGroup(group_id="tg_package_final_load_sat_allocation"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Allocation)
        op_3 = EmptyOperator(task_id="package_final_load_sat_allocation")

        # ref_id: Package\\Final (Load SAT_Allocation)\\Load SAT_Label_Allocation
        op_4 = EmptyOperator(task_id="package_final_load_sat_allocation_load_sat_label_allocation")

        # ref_id: Package\\Final (Load SAT_Allocation)\\Set LastId (DynamicLabel)
        op_5 = EmptyOperator(task_id="package_final_load_sat_allocation_set_lastid_dynamiclabel")

    with TaskGroup(group_id="tg_package_final_load_sat_distribution"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Distribution)
        op_6 = EmptyOperator(task_id="package_final_load_sat_distribution")

        # ref_id: Package\\Final (Load SAT_Distribution)\\Load SAT_Label_Distribution
        op_7 = EmptyOperator(task_id="package_final_load_sat_distribution_load_sat_label_distribution")

        # ref_id: Package\\Final (Load SAT_Distribution)\\Set LastDate (LabelMaster)
        op_8 = EmptyOperator(task_id="package_final_load_sat_distribution_set_lastdate_labelmaster")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_18 = EmptyOperator(task_id="package_staging")

        with TaskGroup(group_id="tg_package_staging_load_sat_allocation_stg"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Load SAT_Allocation_Stg
            op_19 = EmptyOperator(task_id="package_staging_load_sat_allocation_stg")

            # ref_id: Package\\Staging\\Load SAT_Allocation_Stg\\Load SAT_Label_Allocation_Stg
            op_20 = EmptyOperator(task_id="package_staging_load_sat_allocation_stg_load_sat_label_allocation_stg")

            # ref_id: Package\\Staging\\Load SAT_Allocation_Stg\\Truncate SAT_Label_Allocation_Stg
            op_22 = EmptyOperator(task_id="package_staging_load_sat_allocation_stg_truncate_sat_label_allocation_stg")

        with TaskGroup(group_id="tg_package_staging_source1_labelmaster"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source1 (LabelMaster)
            op_23 = EmptyOperator(task_id="package_staging_source1_labelmaster")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Get LastDate (LabelMaster)
            op_24 = EmptyOperator(task_id="package_staging_source1_labelmaster_get_lastdate_labelmaster")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Load LabelMaster_Stg
            op_25 = EmptyOperator(task_id="package_staging_source1_labelmaster_load_labelmaster_stg")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Truncate LabelMaster_Stg
            op_27 = EmptyOperator(task_id="package_staging_source1_labelmaster_truncate_labelmaster_stg")

        with TaskGroup(group_id="tg_package_staging_source2_api_rf_adhoclabel_allocationhistory_stg"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source2 (API_RF_AdHocLabel_AllocationHistory_Stg)
            op_28 = EmptyOperator(task_id="package_staging_source2_api_rf_adhoclabel_allocationhistory_stg")

            # ref_id: Package\\Staging\\Source2 (API_RF_AdHocLabel_AllocationHistory_Stg)\\Get LastId (DynamicLabel)
            op_29 = EmptyOperator(task_id="package_staging_source2_api_rf_adhoclabel_allocationhistory_stg_get_lastid_dynamiclabel")

            # ref_id: Package\\Staging\\Source2 (API_RF_AdHocLabel_AllocationHistory_Stg)\\Load API_RF_AdHocLabel_AllocationHistory_Stg
            op_30 = EmptyOperator(task_id="package_staging_source2_api_rf_adhoclabel_allocationhistory_stg_load_api_rf_adhoclabel_allocationhistory_stg")

            # ref_id: Package\\Staging\\Source2 (API_RF_AdHocLabel_AllocationHistory_Stg)\\Truncate API_RF_AdHocLabel_AllocationHistory_Stg
            op_32 = EmptyOperator(task_id="package_staging_source2_api_rf_adhoclabel_allocationhistory_stg_truncate_api_rf_adhoclabel_allocationhistory_stg")

        with TaskGroup(group_id="tg_package_staging_source3_tblfastlabel_consignment_fl"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source3 (tblFastLabel_Consignment) _FL
            op_33 = EmptyOperator(task_id="package_staging_source3_tblfastlabel_consignment_fl")

            # ref_id: Package\\Staging\\Source3 (tblFastLabel_Consignment) _FL\\Get LastDate (FastLabel)
            op_34 = EmptyOperator(task_id="package_staging_source3_tblfastlabel_consignment_fl_get_lastdate_fastlabel")

            # ref_id: Package\\Staging\\Source3 (tblFastLabel_Consignment) _FL\\Load tblFastLabel_Consignment_Stg
            op_35 = EmptyOperator(task_id="package_staging_source3_tblfastlabel_consignment_fl_load_tblfastlabel_consignment_stg")

            # ref_id: Package\\Staging\\Source3 (tblFastLabel_Consignment) _FL\\Truncate tblFastLabel_Consignment_Stg
            op_37 = EmptyOperator(task_id="package_staging_source3_tblfastlabel_consignment_fl_truncate_tblfastlabel_consignment_stg")

        with TaskGroup(group_id="tg_package_staging_source4_fl_conitem_mf"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source4 (fl_ConItem) _MF
            op_38 = EmptyOperator(task_id="package_staging_source4_fl_conitem_mf")

            # ref_id: Package\\Staging\\Source4 (fl_ConItem) _MF\\Get LastDate (MyFastway)
            op_39 = EmptyOperator(task_id="package_staging_source4_fl_conitem_mf_get_lastdate_myfastway")

            # ref_id: Package\\Staging\\Source4 (fl_ConItem) _MF\\Load fl_ConItem_Stg
            op_40 = EmptyOperator(task_id="package_staging_source4_fl_conitem_mf_load_fl_conitem_stg")

            # ref_id: Package\\Staging\\Source4 (fl_ConItem) _MF\\Truncate fl_ConItem_Stg
            op_42 = EmptyOperator(task_id="package_staging_source4_fl_conitem_mf_truncate_fl_conitem_stg")

        with TaskGroup(group_id="tg_package_staging_source5_hdmanifests_ifs"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source5 (HDManifests) _IFS
            op_43 = EmptyOperator(task_id="package_staging_source5_hdmanifests_ifs")

            # ref_id: Package\\Staging\\Source5 (HDManifests) _IFS\\Get LastDate (IFS)
            op_44 = EmptyOperator(task_id="package_staging_source5_hdmanifests_ifs_get_lastdate_ifs")

            # ref_id: Package\\Staging\\Source5 (HDManifests) _IFS\\Load HDManifests_Stg
            op_45 = EmptyOperator(task_id="package_staging_source5_hdmanifests_ifs_load_hdmanifests_stg")

            # ref_id: Package\\Staging\\Source5 (HDManifests) _IFS\\Truncate HDManifests_Stg
            op_47 = EmptyOperator(task_id="package_staging_source5_hdmanifests_ifs_truncate_hdmanifests_stg")

        with TaskGroup(group_id="tg_package_staging_source6_consignmentitem_fle"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source6 (ConsignmentItem) _FLE
            op_48 = EmptyOperator(task_id="package_staging_source6_consignmentitem_fle")

            # ref_id: Package\\Staging\\Source6 (ConsignmentItem) _FLE\\Get LastDate (FastLabelEnterprise)
            op_49 = EmptyOperator(task_id="package_staging_source6_consignmentitem_fle_get_lastdate_fastlabelenterprise")

            # ref_id: Package\\Staging\\Source6 (ConsignmentItem) _FLE\\Load ConsignmentItem_Stg
            op_50 = EmptyOperator(task_id="package_staging_source6_consignmentitem_fle_load_consignmentitem_stg")

            # ref_id: Package\\Staging\\Source6 (ConsignmentItem) _FLE\\Truncate ConsignmentItem_Stg
            op_52 = EmptyOperator(task_id="package_staging_source6_consignmentitem_fle_truncate_consignmentitem_stg")

    # --- precedence (upstream >> downstream) ---
    op_18 >> op_0
    op_3 >> op_9
    op_10 >> op_14
    op_11 >> op_15
    op_12 >> op_16
    op_13 >> op_17
    op_0 >> op_3
    op_4 >> op_5
    op_0 >> op_6
    op_7 >> op_8
    op_28 >> op_19
    op_33 >> op_19
    op_43 >> op_19
    op_38 >> op_19
    op_48 >> op_19
    op_22 >> op_20
    op_27 >> op_24
    op_24 >> op_25
    op_32 >> op_29
    op_29 >> op_30
    op_37 >> op_34
    op_34 >> op_35
    op_42 >> op_39
    op_39 >> op_40
    op_47 >> op_44
    op_44 >> op_45
    op_52 >> op_49
    op_49 >> op_50
