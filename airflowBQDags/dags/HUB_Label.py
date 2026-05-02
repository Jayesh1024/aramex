"""
DAG for SSIS package: HUB_Label.

Migrated from the original SSIS .dtsx to BigQuery. Earlier work (by Jayesh)
completed the Staging\\Source1..Source8, Source10, Source11, Source13 branches
and the Final\\Load HUB and Final\\Load SAT_Allocation containers. This pass
finishes the remaining `EmptyOperator` stubs:

* Final\\Load SAT_Distribution — `dv_Load_SAT_Label_Distribution` + `Staging_Set_LastValue`.
* Final\\Load SAT_Label_Allocation\\Group 1/2/3 — 3 × (Loads + Set LastDate),
  with the three groups chained via TaskGroup-level precedence
  (`tg_group_1 >> tg_group_2 >> tg_group_3`) in place of the removed
  sequence-container `STOCK:SEQUENCE` EmptyOperator gates (op_11, op_18).
* `Microsoft.ExecutePackageTask` calls to `HUB_Address.dtsx` and
  `LNK_Label_Product_ServiceItem.dtsx` become `TriggerDagRunOperator` targeting
  the corresponding `ssis_skeleton_*` child DAGs with
  `wait_for_completion=True`.

`op_33` (package_staging gate) was left in place — it is part of the already
completed wiring (fan-in from every Source* branch, fan-out to HUB_Label /
SAT_Allocation / HUB_Address / LNK_Label_Product_ServiceItem) and replacing it
with pure TaskGroup-level deps would require restructuring the done logic.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


with DAG(
    dag_id="ssis_skeleton_hub_label",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label"],
    params={
        "DisableFinal": 0,
        "DisableInterBranch": -1,
        "DisableLoad_DynamicLabel": 0,
        "DisableLoad_EBAY": 0,
        "DisableLoad_FastLabel": 0,
        "DisableLoad_FastLabelEnterprise": 0,
        "DisableLoad_IFS": 0,
        "DisableLoad_LabelMaster": 0,
        "DisableLoad_MyFastway": 0,
        "DisableLoad_MyFastwaySrv": 0,
        "DisableLoad_ReceiverPays": 0,
        "DisableLoad_Tasman": -1,
        "DisableLoad_Temando": -1,
        "DisableStaging": 0,
        "MyFastwayAltLargeWinDoW": 1,
        "MyFastwayWinSizeDays": 7,
        "Parameter": 0,
        "process_id": -207,
        "RecordSource1": 'LabelMaster',
        "RecordSource10": 'EBAY',
        "RecordSource11": 'MyFastwaySrv',
        "RecordSource12": 'InterBranchAU',
        "RecordSource13": 'PickupRequest',
        "RecordSource2": 'DynamicLabel',
        "RecordSource3": 'FastLabel',
        "RecordSource4": 'MyFastway',
        "RecordSource5": 'HDManifestID',
        "RecordSource6": 'FastLabelEnterprise',
        "RecordSource7": 'Temando',
        "RecordSource8": 'ReceiverPays',
        "RecordSource9": 'Tasman',
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---

    op_2 = BigQueryInsertJobOperator(
        task_id="package_final_load_hub_load_hub_label",
        gcp_conn_id="oceania_target_sa_connection",
        location="europe-west2",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.dv_Load_HUB_Label`({{{{ dag_run.conf.get('process_id', params.process_id) }}}});",
                "useLegacySql": False,
            }
        },
        job_id="bq_gold_transformation_oceania",
    )

    with TaskGroup(group_id="tg_package_final_load_sat_allocation"):
        # ref_id: Package\\Final (Load SAT_Allocation)\\Truncate SAT_Label_Allocation_Stg
        op_6 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_allocation_truncate_sat_label_allocation_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_SAT_Label_Allocation_Stg`",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final (Load SAT_Allocation)\\Load SAT_Label_Allocation_Stg
        op_5 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_allocation_load_sat_label_allocation_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.staging_Load_SAT_Label_Allocation_Stg2`({{{{ dag_run.conf.get('process_id', params.process_id) }}}});",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final (Load SAT_Allocation)\\Load SAT_Label_Allocation
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_allocation_load_sat_label_allocation",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation`({{{{ dag_run.conf.get('process_id', params.process_id) }}}});",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        

        

    with TaskGroup(group_id="tg_package_final_load_sat_distribution") as tg_sat_distribution:

        # ref_id: Package\\Final (Load SAT_Distribution)\\Load SAT_Label_Distribution
        # SSIS: Exec [dv].[Load_SAT_Label_Distribution] ProcessID, 'LabelMaster'
        op_8 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_distribution_load_sat_label_distribution",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Distribution`"
                        f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\\Final (Load SAT_Distribution)\\Set LastDate (LabelMaster)
        # SSIS: Exec [Staging].[Set_LastValue] 'LabelMaster' — BQ: Staging_Set_LastValue(4 args)
        op_9 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_distribution_set_lastdate_labelmaster",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource1 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    with TaskGroup(group_id="tg_package_final_load_sat_label_allocation") as tg_sat_label_allocation:

        with TaskGroup(group_id="tg_package_final_load_sat_label_allocation_group_1") as tg_sat_label_allocation_group_1:

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Load SAT_Label_Allocation_DL
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_DL] ProcessID
            op_12 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_1_load_sat_label_allocation_dl",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_DL`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource2 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Load SAT_Label_Allocation_EBAY
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_EBAY] ProcessID
            op_13 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_1_load_sat_label_allocation_ebay",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_EBAY`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource10 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Load SAT_Label_Allocation_FLE
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_FLE] ProcessID, 'FastLabelEnterprise'
            op_14 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_1_load_sat_label_allocation_fle",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_FLE`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource6 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Set LastDate (DynamicLabel)
            op_15 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_1_set_lastdate_dynamiclabel",
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

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Set LastDate (EBAY)
            op_16 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_1_set_lastdate_ebay",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource10 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 1\\Set LastDate (FastLabelEnterprise)
            op_17 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_1_set_lastdate_fastlabelenterprise",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource6 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_final_load_sat_label_allocation_group_2") as tg_sat_label_allocation_group_2:

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Load SAT_Label_Allocation_IFS
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_IFS] ProcessID, 'HDManifestID'
            op_19 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_2_load_sat_label_allocation_ifs",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_IFS`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource5 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Load SAT_Label_Allocation_MF
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_MF] ProcessID, 'MyFastway'
            op_20 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_2_load_sat_label_allocation_mf",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_MF`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource4 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Load SAT_Label_Pickup_Requests
            # SSIS: Exec [dv].[Load_SAT_Label_PickupRequests] ProcessID
            op_21 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_2_load_sat_label_pickup_requests",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_PickupRequests`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}});"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Set LastDate (MyFastway)
            op_22 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_2_set_lastdate_myfastway",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource4 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 2\\Set LastID (IFS)
            op_23 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_2_set_lastid_ifs",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource5 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_final_load_sat_label_allocation_group_3") as tg_sat_label_allocation_group_3:

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Load SAT_Label_Allocation_FL
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_FL] ProcessID
            op_25 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_3_load_sat_label_allocation_fl",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_FL`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource3 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Load SAT_Label_Allocation_RP
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_RP] ProcessID, 'ReceiverPays'
            op_26 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_3_load_sat_label_allocation_rp",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_RP`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource8 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Load SAT_Label_Allocation_TMD
            # SSIS: Exec [dv].[Load_SAT_Label_Allocation_TMD] ProcessID, 'Temando'
            op_27 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_3_load_sat_label_allocation_tmd",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_TMD`"
                            f"({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource7 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Set LastDate (FastLabel)
            op_28 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_3_set_lastdate_fastlabel",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource3 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Set LastDate (ReceiverPays)
            op_29 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_3_set_lastdate_receiverpays",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource8 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Final (Load SAT_Label_Allocation_*)\\Group 3\\Set LastDate (Temando)
            op_30 = BigQueryInsertJobOperator(
                task_id="package_final_load_sat_label_allocation_group_3_set_lastdate_temando",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                            f"'{{{{ params.RecordSource7 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

    # ref_id: Package\\HUB_Address — SSIS Microsoft.ExecutePackageTask (HUB_Address.dtsx)
    op_31 = TriggerDagRunOperator(
        task_id="package_hub_address",
        trigger_dag_id="ssis_skeleton_hub_address",
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        conf={"process_id": "{{ dag_run.conf.get('process_id', params.process_id) }}"},
    )

    # ref_id: Package\\LNK_Label_Product_ServiceItem — SSIS Microsoft.ExecutePackageTask (LNK_Label_Product_ServiceItem.dtsx)
    op_32 = TriggerDagRunOperator(
        task_id="package_lnk_label_product_serviceitem",
        trigger_dag_id="ssis_skeleton_lnk_label_product_serviceitem",
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        conf={"process_id": "{{ dag_run.conf.get('process_id', params.process_id) }}"},
    )

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging (join after each source branch completes)
        op_33 = EmptyOperator(task_id="package_staging")

        with TaskGroup(group_id="tg_package_staging_source1_labelmaster"):

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Get LastDate (LabelMaster)
            op_35 = PythonOperator(
                task_id="package_staging_source1_labelmaster_get_lastdate_labelmaster",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource1 }}",
                },
            )

            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Load LabelMaster_Stg
            op_36 = BigQueryInsertJobOperator(
                task_id="package_staging_source1_labelmaster_load_labelmaster_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_LabelMaster_Stg` "
                            f"(SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_35.task_id}') }}}}' AS DATETIME))"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )


            # ref_id: Package\\Staging\\Source1 (LabelMaster)\\Truncate LabelMaster_Stg
            op_38 = BigQueryInsertJobOperator(
                task_id="package_staging_source1_labelmaster_truncate_labelmaster_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_LabelMaster_Stg`",
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source10_ebay_ebay"):
            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Get LastID (EBAY)
            op_40 = PythonOperator(
                task_id="package_staging_source10_ebay_ebay_get_lastid_ebay",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource10 }}",
                },
            )

            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Load Ebay_labels_Stg
            op_41 = BigQueryInsertJobOperator(
                task_id="package_staging_source10_ebay_ebay_load_ebay_labels_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_Ebay_Labels_Stg` "
                            f"({{{{ ti.xcom_pull(task_ids='{op_40.task_id}') }}}})"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source10 (EBAY) _EBAY\\Truncate Ebay_labels_Stg
            op_43 = BigQueryInsertJobOperator(
                task_id="package_staging_source10_ebay_ebay_truncate_ebay_labels_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Ebay_Labels_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source11_myfastwaysrv_mf_2"):
            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Get LastDate (MyFastway)
            op_45 = PythonOperator(
                task_id="package_staging_source11_myfastwaysrv_mf_2_get_lastdate_myfastway",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource11 }}",
                },
            )

            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Load fl_ConItemSrv_Stg
            op_46 = BigQueryInsertJobOperator(
                task_id="package_staging_source11_myfastwaysrv_mf_2_load_fl_conitemsrv_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_ConItemSrv_Stg` "
                            f"(SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_45.task_id}') }}}}' AS DATETIME))"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source11 (MyFastwaySrv) _MF 2\\Truncate fl_ConItemSrv_Stg
            op_48 = BigQueryInsertJobOperator(
                task_id="package_staging_source11_myfastwaysrv_mf_2_truncate_fl_conitemsrv_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_ConItemSrv_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source13_pickuprequests"):
            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Load Pickup Requests (AU)
            op_50 = BigQueryInsertJobOperator(
                task_id="package_staging_source13_pickuprequests_load_pickup_requests_au",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_PickupRequest_Stg` ()"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Load Pickup Requests (NZ)
            op_51 = BigQueryInsertJobOperator(
                task_id="package_staging_source13_pickuprequests_load_pickup_requests_nz",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_PickupRequest_Stg__2` ()"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Load Pickup Requests (SA)
            op_52 = BigQueryInsertJobOperator(
                task_id="package_staging_source13_pickuprequests_load_pickup_requests_sa",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_PickupRequest_Stg__3` ()"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source13 (PickupRequests)\\Truncate Staging Tables
            op_53 = BigQueryInsertJobOperator(
                task_id="package_staging_source13_pickuprequests_truncate_staging_tables",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_PickupRequest_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source2_dynamiclabel_dl"):

            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Get LastId (DynamicLabel)
            op_55 = PythonOperator(
                task_id="package_staging_source2_dynamiclabel_dl_get_lastid_dynamiclabel",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource2 }}",
                }
            )

            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Load API_RF_AdHocLabel_AllocationHistory_Stg
            op_56 = BigQueryInsertJobOperator(
                task_id="package_staging_source2_dynamiclabel_dl_load_api_rf_adhoclabel_allocationhistory_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg` "
                            f"({{{{ ti.xcom_pull(task_ids='{op_55.task_id}') }}}})"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )


            # ref_id: Package\\Staging\\Source2 (DynamicLabel) _DL\\Truncate API_RF_AdHocLabel_AllocationHistory_Stg
            op_58 = BigQueryInsertJobOperator(
                task_id="package_staging_source2_dynamiclabel_dl_truncate_api_rf_adhoclabel_allocationhistory_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg`",
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source3_fastlabel_fl"):
            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Get LastDate (FastLabel)
            op_60 = PythonOperator(
                task_id="package_staging_source3_fastlabel_fl_get_lastdate_fastlabel",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource3 }}",
                },
            )

            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Load tblFastLabel_Consignment_Stg
            op_61 = BigQueryInsertJobOperator(
                task_id="package_staging_source3_fastlabel_fl_load_tblfastlabel_consignment_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_tblFastLabel_Consignment_Stg` "
                            f"(SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_60.task_id}') }}}}' AS DATETIME))"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source3 (FastLabel) _FL\\Truncate tblFastLabel_Consignment_Stg
            op_63 = BigQueryInsertJobOperator(
                task_id="package_staging_source3_fastlabel_fl_truncate_tblfastlabel_consignment_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_tblFastLabel_Consignment_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source4_myfastway_mf"):
            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Get LastDate (MyFastway)
            op_65 = PythonOperator(
                task_id="package_staging_source4_myfastway_mf_get_lastdate_myfastway",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource4 }}",
                },
            )

            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Load fl_ConItem_Stg
            op_66 = BigQueryInsertJobOperator(
                task_id="package_staging_source4_myfastway_mf_load_fl_conitem_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_ConItem_Stg` "
                            f"(SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_65.task_id}') }}}}' AS DATETIME))"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source4 (MyFastway) _MF\\Truncate fl_ConItem_Stg
            op_68 = BigQueryInsertJobOperator(
                task_id="package_staging_source4_myfastway_mf_truncate_fl_conitem_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_ConItem_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source5_hdmanifest_ifs"):
            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Get LastID(IFS)
            op_70 = PythonOperator(
                task_id="package_staging_source5_hdmanifest_ifs_get_lastid_ifs",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource5 }}",
                },
            )

            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Load HDManifests_Stg
            op_71 = BigQueryInsertJobOperator(
                task_id="package_staging_source5_hdmanifest_ifs_load_hdmanifests_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_HDManifests_Stg` "
                            f"({{{{ ti.xcom_pull(task_ids='{op_70.task_id}') }}}})"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source5 (HDManifest) _IFS\\Truncate HDManifests_Stg
            op_73 = BigQueryInsertJobOperator(
                task_id="package_staging_source5_hdmanifest_ifs_truncate_hdmanifests_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_HDManifests_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source6_fastlabelenterprise_fle"):
            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Get LastDate (FastLabelEnterprise)
            op_75 = PythonOperator(
                task_id="package_staging_source6_fastlabelenterprise_fle_get_lastdate_fastlabelenterprise",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource6 }}",
                },
            )

            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Load ConsignmentItem_Stg
            op_76 = BigQueryInsertJobOperator(
                task_id="package_staging_source6_fastlabelenterprise_fle_load_consignmentitem_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_ConsignmentItem_Stg` "
                            f"(SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_75.task_id}') }}}}' AS DATETIME))"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source6 (FastLabelEnterprise) _FLE\\Truncate ConsignmentItem_Stg
            op_78 = BigQueryInsertJobOperator(
                task_id="package_staging_source6_fastlabelenterprise_fle_truncate_consignmentitem_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_ConsignmentItem_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source7_temando_tmd"):
            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Get LastId (Temando)
            op_80 = PythonOperator(
                task_id="package_staging_source7_temando_tmd_get_lastid_temando",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource7 }}",
                },
            )

            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Load API_Temando_RequestLabel_Stg
            op_81 = BigQueryInsertJobOperator(
                task_id="package_staging_source7_temando_tmd_load_api_temando_requestlabel_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_API_Temando_RequestLabel_Stg` "
                            f"({{{{ ti.xcom_pull(task_ids='{op_80.task_id}') }}}})"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source7 (Temando) _TMD\\Truncate API_Temando_RequestLabel_Stg
            op_83 = BigQueryInsertJobOperator(
                task_id="package_staging_source7_temando_tmd_truncate_api_temando_requestlabel_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_API_Temando_RequestLabel_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

        with TaskGroup(group_id="tg_package_staging_source8_receiverpays_rp"):
            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Get LastID  (ReceiverPays)
            op_85 = PythonOperator(
                task_id="package_staging_source8_receiverpays_rp_get_lastid_receiverpays",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.RecordSource8 }}",
                },
            )

            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Load tblOnlineEnquiry_RP_Stg
            op_86 = BigQueryInsertJobOperator(
                task_id="package_staging_source8_receiverpays_rp_load_tblonlineenquiry_rp_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{SP_DATASET_ID}.sp_load_Staging_tblOnlineEnquiry_RP_Stg` "
                            f"({{{{ ti.xcom_pull(task_ids='{op_85.task_id}') }}}})"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

            # ref_id: Package\\Staging\\Source8 (ReceiverPays) _RP\\Truncate tblOnlineEnquiry_RP_Stg
            op_88 = BigQueryInsertJobOperator(
                task_id="package_staging_source8_receiverpays_rp_truncate_tblonlineenquiry_rp_stg",
                gcp_conn_id="oceania_target_sa_connection",
                location="europe-west2",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_tblOnlineEnquiry_RP_Stg`"
                        ),
                        "useLegacySql": False,
                    }
                },
                job_id="bq_gold_transformation_oceania",
            )

    # --- precedence (upstream >> downstream) ---
    # Sink of each nested staging TaskGroup (last task along the current >> chain)
    _staging_branch_last_tasks = (
        op_36,
        op_41,
        op_46,
        op_52,
        op_56,
        op_61,
        op_66,
        op_71,
        op_76,
        op_81,
        op_86,
    )
    for _stg_last in _staging_branch_last_tasks:
        _stg_last >> op_33
    op_33 >> op_2
    op_33 >> op_6
    op_33 >> op_31
    op_33 >> op_32

    op_5 >> op_4
    op_6 >> op_5
    op_2 >> op_8
    op_8 >> op_9
    op_4 >> op_13
    op_4 >> op_12
    op_4 >> op_14
    op_12 >> op_15
    op_13 >> op_16
    op_14 >> op_17
    op_20 >> op_22
    op_19 >> op_23
    op_25 >> op_28
    op_26 >> op_29
    op_27 >> op_30

    # TaskGroup-level precedence (was routed through removed `op_11` / `op_18`
    # STOCK:SEQUENCE gates). Chaining the three Allocation subgroups preserves
    # the original SSIS ordering: Group 1 (DL, EBAY, FLE) -> Group 2 (IFS, MF,
    # Pickup Requests) -> Group 3 (FL, RP, TMD).
    tg_sat_label_allocation_group_1 >> tg_sat_label_allocation_group_2 >> tg_sat_label_allocation_group_3
    op_38 >> op_35
    op_35 >> op_36
    op_43 >> op_40
    op_40 >> op_41
    op_48 >> op_45
    op_45 >> op_46
    op_53 >> op_50
    op_50 >> op_51
    op_51 >> op_52
    op_58 >> op_55
    op_55 >> op_56
    op_63 >> op_60
    op_60 >> op_61
    op_68 >> op_65
    op_65 >> op_66
    op_73 >> op_70
    op_70 >> op_71
    op_78 >> op_75
    op_75 >> op_76
    op_83 >> op_80
    op_80 >> op_81
    op_88 >> op_85
    op_85 >> op_86
