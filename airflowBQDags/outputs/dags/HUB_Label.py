"""
Skeleton DAG for SSIS package: HUB_Label
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Label"

with DAG(
    dag_id="ssis_skeleton_hub_label",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final_load_hub"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load HUB)
        op_0 = EmptyOperator(task_id="package_final_load_hub")

        # ref_id: Package\\Final (Load HUB)\\Defrag HUB_Label Indexes
        op_1 = EmptyOperator(task_id="package_final_load_hub_defrag_hub_label_indexes")

        # ref_id: Package\\Final (Load HUB)\\Load HUB_Label
        op_2 = EmptyOperator(task_id="package_final_load_hub_load_hub_label")

    with TaskGroup(group_id="tg_package_final_load_sat_allocation"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Allocation)
        op_3 = EmptyOperator(task_id="package_final_load_sat_allocation")

        # ref_id: Package\\Final (Load SAT_Allocation)\\Load SAT_Label_Allocation
        op_4 = EmptyOperator(task_id="package_final_load_sat_allocation_load_sat_label_allocation")

        # ref_id: Package\\Final (Load SAT_Allocation)\\Load SAT_Label_Allocation_Stg
        op_5 = EmptyOperator(task_id="package_final_load_sat_allocation_load_sat_label_allocation_stg")

        # ref_id: Package\\Final (Load SAT_Allocation)\\Truncate SAT_Label_Allocation_Stg
        op_6 = EmptyOperator(task_id="package_final_load_sat_allocation_truncate_sat_label_allocation_stg")

    with TaskGroup(group_id="tg_package_final_load_sat_distribution"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Distribution)
        op_7 = EmptyOperator(task_id="package_final_load_sat_distribution")

        # ref_id: Package\\Final (Load SAT_Distribution)\\Load SAT_Label_Distribution
        op_8 = EmptyOperator(task_id="package_final_load_sat_distribution_load_sat_label_distribution")

        # ref_id: Package\\Final (Load SAT_Distribution)\\Set LastDate (LabelMaster)
        op_9 = EmptyOperator(task_id="package_final_load_sat_distribution_set_lastdate_labelmaster")

    with TaskGroup(group_id="tg_package_final_load_sat_label_allocation"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Label_Allocation_*)
        op_10 = EmptyOperator(task_id="package_final_load_sat_label_allocation")

        with TaskGroup(group_id="tg_package_final_load_sat_label_allocation_group_1"):
            # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1
            op_11 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Load SAT_Label_Allocation_DL
            op_12 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1_load_sat_label_allocation_dl")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Load SAT_Label_Allocation_EBAY
            op_13 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1_load_sat_label_allocation_ebay")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Load SAT_Label_Allocation_FLE
            op_14 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1_load_sat_label_allocation_fle")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Set LastDate (DynamicLabel)
            op_15 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1_set_lastdate_dynamiclabel")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Set LastDate (EBAY)
            op_16 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1_set_lastdate_ebay")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Set LastDate (FastLabelEnterprise)
            op_17 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_1_set_lastdate_fastlabelenterprise")

        with TaskGroup(group_id="tg_package_final_load_sat_label_allocation_group_2"):
            # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2
            op_18 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_2")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Load SAT_Label_Allocation_IFS
            op_19 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_2_load_sat_label_allocation_ifs")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Load SAT_Label_Allocation_MF
            op_20 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_2_load_sat_label_allocation_mf")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Load SAT_Label_Pickup_Requests
            op_21 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_2_load_sat_label_pickup_requests")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Set LastDate (MyFastway)
            op_22 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_2_set_lastdate_myfastway")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Set LastID (IFS)
            op_23 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_2_set_lastid_ifs")

        with TaskGroup(group_id="tg_package_final_load_sat_label_allocation_group_3"):
            # STOCK:SEQUENCE — ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3
            op_24 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Load SAT_Label_Allocation_FL
            op_25 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3_load_sat_label_allocation_fl")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Load SAT_Label_Allocation_RP
            op_26 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3_load_sat_label_allocation_rp")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Load SAT_Label_Allocation_TMD
            op_27 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3_load_sat_label_allocation_tmd")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Set LastDate (FastLabel)
            op_28 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3_set_lastdate_fastlabel")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Set LastDate (ReceiverPays)
            op_29 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3_set_lastdate_receiverpays")

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Set LastDate (Temando)
            op_30 = EmptyOperator(task_id="package_final_load_sat_label_allocation_group_3_set_lastdate_temando")

    # ref_id: Package\\HUB_Address
    op_31 = EmptyOperator(task_id="package_hub_address")

    # ref_id: Package\\LNK_Label_Product_ServiceItem
    op_32 = EmptyOperator(task_id="package_lnk_label_product_serviceitem")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_33 = EmptyOperator(task_id="package_staging")

        with TaskGroup(group_id="tg_package_staging_source1_labelmaster"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source1 (LabelMaster)
            op_34 = EmptyOperator(task_id="package_staging_source1_labelmaster")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Get LastDate (LabelMaster)
            op_35 = EmptyOperator(task_id="package_staging_source1_labelmaster_get_lastdate_labelmaster")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Load LabelMaster_Stg
            op_36 = EmptyOperator(task_id="package_staging_source1_labelmaster_load_labelmaster_stg")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Rebuild Indexes 1
            op_37 = EmptyOperator(task_id="package_staging_source1_labelmaster_rebuild_indexes_1")

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Truncate LabelMaster_Stg
            op_38 = EmptyOperator(task_id="package_staging_source1_labelmaster_truncate_labelmaster_stg")

        with TaskGroup(group_id="tg_package_staging_source10_ebay_ebay"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source10 (EBAY) _EBAY
            op_39 = EmptyOperator(task_id="package_staging_source10_ebay_ebay")

            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Get LastID (EBAY)
            op_40 = EmptyOperator(task_id="package_staging_source10_ebay_ebay_get_lastid_ebay")

            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Load Ebay_labels_Stg
            op_41 = EmptyOperator(task_id="package_staging_source10_ebay_ebay_load_ebay_labels_stg")

            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Rebuild Indexes 10
            op_42 = EmptyOperator(task_id="package_staging_source10_ebay_ebay_rebuild_indexes_10")

            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Truncate Ebay_labels_Stg
            op_43 = EmptyOperator(task_id="package_staging_source10_ebay_ebay_truncate_ebay_labels_stg")

        with TaskGroup(group_id="tg_package_staging_source11_myfastwaysrv_mf_2"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2
            op_44 = EmptyOperator(task_id="package_staging_source11_myfastwaysrv_mf_2")

            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Get LastDate (MyFastway)
            op_45 = EmptyOperator(task_id="package_staging_source11_myfastwaysrv_mf_2_get_lastdate_myfastway")

            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Load fl_ConItemSrv_Stg
            op_46 = EmptyOperator(task_id="package_staging_source11_myfastwaysrv_mf_2_load_fl_conitemsrv_stg")

            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Rebuild Indexes 11
            op_47 = EmptyOperator(task_id="package_staging_source11_myfastwaysrv_mf_2_rebuild_indexes_11")

            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Truncate fl_ConItemSrv_Stg
            op_48 = EmptyOperator(task_id="package_staging_source11_myfastwaysrv_mf_2_truncate_fl_conitemsrv_stg")

        with TaskGroup(group_id="tg_package_staging_source13_pickuprequests"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source13 (PickupRequests)
            op_49 = EmptyOperator(task_id="package_staging_source13_pickuprequests")

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Load Pickup Requests (AU)
            op_50 = EmptyOperator(task_id="package_staging_source13_pickuprequests_load_pickup_requests_au")

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Load Pickup Requests (NZ)
            op_51 = EmptyOperator(task_id="package_staging_source13_pickuprequests_load_pickup_requests_nz")

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Load Pickup Requests (SA)
            op_52 = EmptyOperator(task_id="package_staging_source13_pickuprequests_load_pickup_requests_sa")

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Truncate Staging Tables
            op_53 = EmptyOperator(task_id="package_staging_source13_pickuprequests_truncate_staging_tables")

        with TaskGroup(group_id="tg_package_staging_source2_dynamiclabel_dl"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL
            op_54 = EmptyOperator(task_id="package_staging_source2_dynamiclabel_dl")

            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Get LastId (DynamicLabel)
            op_55 = EmptyOperator(task_id="package_staging_source2_dynamiclabel_dl_get_lastid_dynamiclabel")

            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Load API_RF_AdHocLabel_AllocationHistory_Stg
            op_56 = EmptyOperator(task_id="package_staging_source2_dynamiclabel_dl_load_api_rf_adhoclabel_allocationhistory_stg")

            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Rebuild Indexes 2
            op_57 = EmptyOperator(task_id="package_staging_source2_dynamiclabel_dl_rebuild_indexes_2")

            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Truncate API_RF_AdHocLabel_AllocationHistory_Stg
            op_58 = EmptyOperator(task_id="package_staging_source2_dynamiclabel_dl_truncate_api_rf_adhoclabel_allocationhistory_stg")

        with TaskGroup(group_id="tg_package_staging_source3_fastlabel_fl"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source3 (FastLabel) _FL
            op_59 = EmptyOperator(task_id="package_staging_source3_fastlabel_fl")

            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Get LastDate (FastLabel)
            op_60 = EmptyOperator(task_id="package_staging_source3_fastlabel_fl_get_lastdate_fastlabel")

            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Load tblFastLabel_Consignment_Stg
            op_61 = EmptyOperator(task_id="package_staging_source3_fastlabel_fl_load_tblfastlabel_consignment_stg")

            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Rebuild Indexes 3
            op_62 = EmptyOperator(task_id="package_staging_source3_fastlabel_fl_rebuild_indexes_3")

            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Truncate tblFastLabel_Consignment_Stg
            op_63 = EmptyOperator(task_id="package_staging_source3_fastlabel_fl_truncate_tblfastlabel_consignment_stg")

        with TaskGroup(group_id="tg_package_staging_source4_myfastway_mf"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source4 (MyFastway) _MF
            op_64 = EmptyOperator(task_id="package_staging_source4_myfastway_mf")

            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Get LastDate (MyFastway)
            op_65 = EmptyOperator(task_id="package_staging_source4_myfastway_mf_get_lastdate_myfastway")

            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Load fl_ConItem_Stg
            op_66 = EmptyOperator(task_id="package_staging_source4_myfastway_mf_load_fl_conitem_stg")

            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Rebuild Indexes 4
            op_67 = EmptyOperator(task_id="package_staging_source4_myfastway_mf_rebuild_indexes_4")

            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Truncate fl_ConItem_Stg
            op_68 = EmptyOperator(task_id="package_staging_source4_myfastway_mf_truncate_fl_conitem_stg")

        with TaskGroup(group_id="tg_package_staging_source5_hdmanifest_ifs"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source5 (HDManifest) _IFS
            op_69 = EmptyOperator(task_id="package_staging_source5_hdmanifest_ifs")

            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Get LastID(IFS)
            op_70 = EmptyOperator(task_id="package_staging_source5_hdmanifest_ifs_get_lastid_ifs")

            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Load HDManifests_Stg
            op_71 = EmptyOperator(task_id="package_staging_source5_hdmanifest_ifs_load_hdmanifests_stg")

            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Rebuild Indexes 5
            op_72 = EmptyOperator(task_id="package_staging_source5_hdmanifest_ifs_rebuild_indexes_5")

            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Truncate HDManifests_Stg
            op_73 = EmptyOperator(task_id="package_staging_source5_hdmanifest_ifs_truncate_hdmanifests_stg")

        with TaskGroup(group_id="tg_package_staging_source6_fastlabelenterprise_fle"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE
            op_74 = EmptyOperator(task_id="package_staging_source6_fastlabelenterprise_fle")

            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Get LastDate (FastLabelEnterprise)
            op_75 = EmptyOperator(task_id="package_staging_source6_fastlabelenterprise_fle_get_lastdate_fastlabelenterprise")

            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Load ConsignmentItem_Stg
            op_76 = EmptyOperator(task_id="package_staging_source6_fastlabelenterprise_fle_load_consignmentitem_stg")

            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Rebuild Indexes 6
            op_77 = EmptyOperator(task_id="package_staging_source6_fastlabelenterprise_fle_rebuild_indexes_6")

            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Truncate ConsignmentItem_Stg
            op_78 = EmptyOperator(task_id="package_staging_source6_fastlabelenterprise_fle_truncate_consignmentitem_stg")

        with TaskGroup(group_id="tg_package_staging_source7_temando_tmd"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source7 (Temando) _TMD
            op_79 = EmptyOperator(task_id="package_staging_source7_temando_tmd")

            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Get LastId (Temando)
            op_80 = EmptyOperator(task_id="package_staging_source7_temando_tmd_get_lastid_temando")

            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Load API_Temando_RequestLabel_Stg
            op_81 = EmptyOperator(task_id="package_staging_source7_temando_tmd_load_api_temando_requestlabel_stg")

            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Rebuild Indexes 7
            op_82 = EmptyOperator(task_id="package_staging_source7_temando_tmd_rebuild_indexes_7")

            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Truncate API_Temando_RequestLabel_Stg
            op_83 = EmptyOperator(task_id="package_staging_source7_temando_tmd_truncate_api_temando_requestlabel_stg")

        with TaskGroup(group_id="tg_package_staging_source8_receiverpays_rp"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP
            op_84 = EmptyOperator(task_id="package_staging_source8_receiverpays_rp")

            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Get LastID  (ReceiverPays)
            op_85 = EmptyOperator(task_id="package_staging_source8_receiverpays_rp_get_lastid_receiverpays")

            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Load tblOnlineEnquiry_RP_Stg
            op_86 = EmptyOperator(task_id="package_staging_source8_receiverpays_rp_load_tblonlineenquiry_rp_stg")

            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Rebuild Indexes 8
            op_87 = EmptyOperator(task_id="package_staging_source8_receiverpays_rp_rebuild_indexes_8")

            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Truncate tblOnlineEnquiry_RP_Stg
            op_88 = EmptyOperator(task_id="package_staging_source8_receiverpays_rp_truncate_tblonlineenquiry_rp_stg")

    # --- precedence (upstream >> downstream) ---
    op_33 >> op_0
    op_2 >> op_1
    op_33 >> op_3
    op_5 >> op_4
    op_6 >> op_5
    op_0 >> op_7
    op_8 >> op_9
    op_3 >> op_10
    op_12 >> op_15
    op_13 >> op_16
    op_14 >> op_17
    op_11 >> op_18
    op_20 >> op_22
    op_19 >> op_23
    op_18 >> op_24
    op_25 >> op_28
    op_26 >> op_29
    op_27 >> op_30
    op_33 >> op_31
    op_33 >> op_32
    op_38 >> op_35
    op_35 >> op_36
    op_36 >> op_37
    op_43 >> op_40
    op_40 >> op_41
    op_41 >> op_42
    op_48 >> op_45
    op_45 >> op_46
    op_46 >> op_47
    op_53 >> op_50
    op_50 >> op_51
    op_51 >> op_52
    op_58 >> op_55
    op_55 >> op_56
    op_56 >> op_57
    op_63 >> op_60
    op_60 >> op_61
    op_61 >> op_62
    op_68 >> op_65
    op_65 >> op_66
    op_66 >> op_67
    op_73 >> op_70
    op_70 >> op_71
    op_71 >> op_72
    op_78 >> op_75
    op_75 >> op_76
    op_76 >> op_77
    op_83 >> op_80
    op_80 >> op_81
    op_81 >> op_82
    op_88 >> op_85
    op_85 >> op_86
    op_86 >> op_87
