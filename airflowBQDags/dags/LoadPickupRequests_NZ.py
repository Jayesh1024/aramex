"""
DAG for SSIS package: LoadPickupRequests_NZ (GCP / BigQuery).

Source metadata:
  * `airflowBQDags/outputs/LoadPickupRequests_NZ/executable_dependencies.json`
  * `airflowBQDags/outputs/LoadPickupRequests_NZ/package_metadata.json`
  * `airflowBQDags/Packages/LoadPickupRequests_NZ.dtsx`

Structurally identical to LoadPickupRequests_AU; only the country-specific
values differ:
  * DatabaseName: FastwayGlobal_6 (NZ) vs FastwayGlobal_1 (AU) / _24 (SA).
  * Staging table: Staging_PickupRequest_NZ_Stg.
  * Inferred SP: Staging_load_PickupRequest_NZ_Stg(LastVersion, IsReload).
  * Final SP: dv_Load_CT_SAT_Label_PickupRequests_NZ(ProcessID).
  * ProcessID default: -66.
  * RecordSource: PickupRequests_NZ.

See LoadPickupRequests_AU.py for the full Change-Tracking translation posture
and validation flags — the same caveats apply here.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_ct_version, get_next_ct_version_null

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")

_TASK_ID_GET_LAST_CT = "package_get_last_ct_version"
_TASK_ID_GET_NEXT_CT = "package_get_next_ct_version"


with DAG(
    dag_id="ssis_skeleton_loadpickuprequests_nz",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadpickuprequests_nz"],
    params={
        "DatabaseName": "FastwayGlobal_6",
        "IsReload": 0,
        "ProcessID": -66,
        "RecordSource": "PickupRequests_NZ",
    },
) as dag:

    _xcom_last_ct = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_CT}') }}}}"
    _xcom_next_ct = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_NEXT_CT}') }}}}"

    # --- control flow ---

    # ref_id: Package\Check if Secondary — SQL Server HA gate; no BQ equivalent.
    op_check_if_secondary = EmptyOperator(task_id="package_check_if_secondary")

    # ref_id: Package\Get Last CT Version
    op_get_last_ct_version = PythonOperator(
        task_id=_TASK_ID_GET_LAST_CT,
        python_callable=get_last_ct_version,
        op_kwargs={
            "project_id": GCP_PROJECT_ID,
            "dataset_id": TARGET_DATASET_ID,
            "target_name": "{{ params.RecordSource }}",
        },
    )

    # ref_id: Package\Get Next CT Version — pushes NULL, see module docstring.
    op_get_next_ct_version = PythonOperator(
        task_id=_TASK_ID_GET_NEXT_CT,
        python_callable=get_next_ct_version_null,
    )

    with TaskGroup(group_id="tg_package_pickup_requests") as tg_pickup_requests:
        # STOCK:SEQUENCE — ref_id: Package\Pickup Requests

        # ref_id: Package\Pickup Requests\Truncate PickupRequests_Stg
        # SSIS: TRUNCATE TABLE [Staging].[PickupRequest_NZ_Stg];
        op_truncate_pickuprequests_stg = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_truncate_pickuprequests_stg",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE "
                        f"`{TARGET_DATASET_ID}.Staging_PickupRequest_NZ_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="oceania_target_sa_connection",
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Pickup Requests\Get PickupRequests (NZ)
        # SSIS reads CHANGETABLE(CHANGES ...) from FastwayGlobal_6; modelled as
        # an inferred SP consuming the CDC stream landed into Staging_PickupRequest_NZ_Stg.
        op_get_pickuprequests_nz = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_get_pickuprequests_nz",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_load_PickupRequest_NZ_Stg`("
                        f"SAFE_CAST('{_xcom_last_ct}' AS INT64), "
                        f"SAFE_CAST('{{{{ params.IsReload }}}}' AS BOOL));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="oceania_target_sa_connection",
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Pickup Requests\Copy Country Staging to PickupRequest_Stg
        # Fully deterministic translation of the SSIS pipeline; see LoadPickupRequests_AU.py.
        op_copy_country_staging = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_copy_country_staging_to_pickuprequest_stg",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"INSERT INTO `{TARGET_DATASET_ID}.Staging_PickupRequest_Stg` ("
                        "ID, CreateDateUtc, ShouldPrintLabel, PickupFranchiseeCode, "
                        "PickupCourierNumber, LabelNumber, CollectionDate, CollectionCycle, "
                        "PickupAddress1, PickupAddress2, PickupSuburb, PickupPostcode, "
                        "PickupName, PickupPhone, PickupEmail, DeliveryAddress1, "
                        "DeliveryAddress2, DeliverySuburb, DeliveryPostcode, DeliveryName, "
                        "DeliveryPhone, DeliveryEmail, IsMessageSent, Weight, Width, Height, "
                        "Length, RequestingCustomerName, CountryCode, IsPrinted, IsComplete, "
                        "ConsolidationGroupId, CourierMessageResult, ConsolidationDateUtc, "
                        "PickupSpecialInstructions, DeliverySpecialInstructions, HhcMessageId, "
                        "HasCourierRejected, IsRegularCollection, RequestingCustomerOesId, "
                        "IsCancelled, CancellationReason, CancellationTitle, FutileScanDate, "
                        "NotReadyScanDate, PickupScanDate, MessageSentDateUtc, "
                        "CourierMessageResultText, RejectionReason, RejectionDate, "
                        "InternalStatus, DidNotAssignCourierDuringCreation, IsReturnService, "
                        "IsParcelConnectPickupLocation, SecondaryLabelNumber, "
                        "PickupSubDepotFranchiseeCode, CubicWeight, PickupCompany, "
                        "DeliveryCompany, IsPriority"
                        ") "
                        "SELECT Src.ID, Src.CreateDateUtc, Src.ShouldPrintLabel, "
                        "Src.PickupFranchiseeCode, Src.PickupCourierNumber, Src.LabelNumber, "
                        "Src.CollectionDate, Src.CollectionCycle, Src.PickupAddress1, "
                        "Src.PickupAddress2, Src.PickupSuburb, Src.PickupPostcode, "
                        "Src.PickupName, Src.PickupPhone, Src.PickupEmail, Src.DeliveryAddress1, "
                        "Src.DeliveryAddress2, Src.DeliverySuburb, Src.DeliveryPostcode, "
                        "Src.DeliveryName, Src.DeliveryPhone, Src.DeliveryEmail, "
                        "Src.IsMessageSent, Src.Weight, Src.Width, Src.Height, Src.Length, "
                        "Src.RequestingCustomerName, Src.CountryCode, Src.IsPrinted, "
                        "Src.IsComplete, Src.ConsolidationGroupId, Src.CourierMessageResult, "
                        "Src.ConsolidationDateUtc, Src.PickupSpecialInstructions, "
                        "Src.DeliverySpecialInstructions, Src.HhcMessageId, "
                        "Src.HasCourierRejected, Src.IsRegularCollection, "
                        "Src.RequestingCustomerOesId, Src.IsCancelled, Src.CancellationReason, "
                        "Src.CancellationTitle, Src.FutileScanDate, Src.NotReadyScanDate, "
                        "Src.PickupScanDate, Src.MessageSentDateUtc, "
                        "Src.CourierMessageResultText, Src.RejectionReason, Src.RejectionDate, "
                        "Src.InternalStatus, Src.DidNotAssignCourierDuringCreation, "
                        "Src.IsReturnService, Src.IsParcelConnectPickupLocation, "
                        "Src.SecondaryLabelNumber, Src.PickupSubDepotFranchiseeCode, "
                        "Src.CubicWeight, Src.PickupCompany, Src.DeliveryCompany, Src.IsPriority "
                        f"FROM `{TARGET_DATASET_ID}.Staging_PickupRequest_NZ_Stg` AS Src "
                        f"LEFT JOIN `{TARGET_DATASET_ID}.Staging_PickupRequest_Stg` AS Tgt "
                        "ON Tgt.ID = Src.ID "
                        "WHERE Tgt.ID IS NULL;"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="oceania_target_sa_connection",
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Pickup Requests\Load Target Table
        # SSIS: exec dv.Load_CT_SAT_Label_PickupRequests_NZ ?  (binds @ProcessID)
        op_load_target_table = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_load_target_table",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_CT_SAT_Label_PickupRequests_NZ`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessID) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="oceania_target_sa_connection",
            job_id="bq_gold_transformation_oceania",
        )

        op_truncate_pickuprequests_stg >> op_get_pickuprequests_nz
        op_get_pickuprequests_nz >> op_copy_country_staging
        op_get_pickuprequests_nz >> op_load_target_table

    # ref_id: Package\Set Next CT_Version — see LoadPickupRequests_AU.py docstring.
    op_set_next_ct_version = BigQueryInsertJobOperator(
        task_id="package_set_next_ct_version",
        gcp_conn_id="oceania_target_sa_connection",
        configuration={
            "query": {
                "query": (
                    f"UPDATE `{TARGET_DATASET_ID}.Staging_LoadControl_ChangeTracking` "
                    f"SET LastSyncVersion = SAFE_CAST('{_xcom_next_ct}' AS INT64) "
                    f"WHERE TargetName = '{{{{ params.RecordSource }}}}' "
                    f"AND '{_xcom_next_ct}' != 'None';"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id="oceania_target_sa_connection",
        job_id="bq_gold_transformation_oceania",
    )

    # --- precedence (from executable_dependencies.json) ---
    op_check_if_secondary >> op_get_last_ct_version
    op_get_last_ct_version >> op_get_next_ct_version
    op_get_next_ct_version >> tg_pickup_requests
    tg_pickup_requests >> op_set_next_ct_version
