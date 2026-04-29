"""
DAG for SSIS package: LoadPickupRequests_AU (GCP / BigQuery).

Source metadata:
  * `airflowBQDags/outputs/LoadPickupRequests_AU/executable_dependencies.json`
  * `airflowBQDags/outputs/LoadPickupRequests_AU/package_metadata.json`
  * `airflowBQDags/Packages/LoadPickupRequests_AU.dtsx`

Structure (preserved from SSIS):
  Check if Secondary -> Get Last CT Version -> Get Next CT Version
                                                       |
                                                       v
                        [STOCK:SEQUENCE] Pickup Requests (TaskGroup)
                          Truncate PickupRequest_AU_Stg
                             -> Get PickupRequests (AU)
                                  -> Copy Country Staging to PickupRequest_Stg
                                  -> Load Target Table
                             -> Set Next CT_Version

Change-Tracking translation posture (documented for the reviewer):
  SSIS runs SQL Server Change Tracking. BigQuery has no CT equivalent, so the
  CT-specific tasks are translated as follows:
    * «Check if Secondary» — SQL Server AlwaysOn HA gate. No meaning in BQ.
      Rendered as EmptyOperator to preserve the DAG shape; drop it once the
      CDC / Datastream architecture is finalised.
    * «Get Last CT Version» — direct BQ SELECT against
      `Staging_LoadControl_ChangeTracking` (utils.getValue.get_last_ct_version).
    * «Get Next CT Version» — pushes NULL (utils.getValue.get_next_ct_version_null).
      Downstream «Set Next CT_Version» UPDATE is guarded on NextVersion IS NOT NULL,
      so the CT watermark is effectively frozen until CDC is wired in.
    * «Get PickupRequests (AU)» — SSIS reads CHANGETABLE(CHANGES …) from
      SQL Server. Modelled as `CALL Staging_load_PickupRequest_AU_Stg(LastVersion, IsReload)`
      (inferred SP, same precedent as HUB_Invoice `sp_load_Staging_*_Stg`).
    * «Copy Country Staging to PickupRequest_Stg» — SSIS pipeline translates
      cleanly to an INSERT … SELECT … LEFT JOIN … WHERE Tgt.ID IS NULL.
    * «Load Target Table» — `CALL dv_Load_CT_SAT_Label_PickupRequests_AU(ProcessID)`
      (SSIS: `exec dv.Load_CT_SAT_Label_PickupRequests_AU ?`).

Flagged for validation (see DAG_COMPLETION_NOTES.md):
  * `Staging_load_PickupRequest_AU_Stg(LastVersion INT64, IsReload BOOL)` SP
    is inferred — confirm it exists / will be created.
  * `dv_Load_CT_SAT_Label_PickupRequests_AU(p_ProcessID INT64)` SP follows the
    `schema_object` naming convention; confirm BQ signature.
  * `Staging_LoadControl_ChangeTracking(TargetName STRING, LastSyncVersion INT64)`
    table is assumed to exist in `TARGET_DATASET_ID` as the BQ mirror of
    `[Staging].[LoadControl_ChangeTracking]`.

GCP naming (per repo convention): SSIS `schema.object` -> BQ `schema_object`
(case preserved). `CALL` targets go to `SP_DATASET_ID`; tables (TRUNCATE /
INSERT / UPDATE / SELECT) go to `TARGET_DATASET_ID`.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_ct_version, get_next_ct_version_null

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

_TASK_ID_GET_LAST_CT = "package_get_last_ct_version"
_TASK_ID_GET_NEXT_CT = "package_get_next_ct_version"


with DAG(
    dag_id="ssis_skeleton_loadpickuprequests_au",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadpickuprequests_au"],
    params={
        # SSIS $Package::DatabaseName — operational SQL Server DB for CT queries.
        # Carried through for traceability; not used by BQ-side queries.
        "DatabaseName": "FastwayGlobal_1",
        # SSIS $Package::IsReload — 0 = delta, 1 = full reload (bound into the
        # inferred Staging_load_PickupRequest_AU_Stg SP).
        "IsReload": 0,
        # SSIS $Package::ProcessID default. Preserved from the .dtsx metadata.
        # When triggered from LoadControl, override via dag_run.conf.
        "ProcessID": -61,
        # SSIS $Package::RecordSource — TargetName key in Staging_LoadControl_ChangeTracking.
        "RecordSource": "PickupRequests_AU",
    },
) as dag:

    _xcom_last_ct = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_CT}') }}}}"
    _xcom_next_ct = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_NEXT_CT}') }}}}"

    # --- control flow ---

    # ref_id: Package\Check if Secondary
    # SSIS: sys.fn_hadr_is_primary_replica(@DBname). No BigQuery equivalent
    # (no AlwaysOn Availability Groups concept). Rendered as a no-op to keep
    # the DAG shape aligned with the source package.
    op_check_if_secondary = EmptyOperator(task_id="package_check_if_secondary")

    # ref_id: Package\Get Last CT Version
    # SSIS: SELECT LastSyncVersion FROM [Staging].[LoadControl_ChangeTracking]
    #       WHERE TargetName = @RecordSource
    op_get_last_ct_version = PythonOperator(
        task_id=_TASK_ID_GET_LAST_CT,
        python_callable=get_last_ct_version,
        op_kwargs={
            "project_id": GCP_PROJECT_ID,
            "dataset_id": TARGET_DATASET_ID,
            "target_name": "{{ params.RecordSource }}",
        },
    )

    # ref_id: Package\Get Next CT Version
    # SSIS: SELECT CHANGE_TRACKING_CURRENT_VERSION() — not available in BQ.
    # Pushes NULL; Set Next CT_Version below is guarded on IS NOT NULL.
    op_get_next_ct_version = PythonOperator(
        task_id=_TASK_ID_GET_NEXT_CT,
        python_callable=get_next_ct_version_null,
    )

    with TaskGroup(group_id="tg_package_pickup_requests") as tg_pickup_requests:
        # STOCK:SEQUENCE — ref_id: Package\Pickup Requests

        # ref_id: Package\Pickup Requests\Truncate PickupRequests_Stg
        # SSIS: TRUNCATE TABLE [Staging].[PickupRequest_AU_Stg];
        op_truncate_pickuprequests_stg = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_truncate_pickuprequests_stg",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE "
                        f"`{TARGET_DATASET_ID}.Staging_PickupRequest_AU_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\Pickup Requests\Get PickupRequests (AU)
        # SSIS: OLE DB source runs CHANGETABLE(CHANGES [PickupDashboard].[PickupRequest], @Last_synced_version)
        # against FastwayGlobal_1 and writes rows into [Staging].[PickupRequest_AU_Stg].
        # BigQuery cannot query SQL Server; modelled as an inferred SP that is
        # expected to consume the CDC stream (Datastream or equivalent) and
        # respect the (LastVersion, IsReload) signature bound in SSIS.
        op_get_pickuprequests_au = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_get_pickuprequests_au",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_load_PickupRequest_AU_Stg`("
                        f"SAFE_CAST('{_xcom_last_ct}' AS INT64), "
                        f"SAFE_CAST('{{{{ params.IsReload }}}}' AS BOOL));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\Pickup Requests\Copy Country Staging to PickupRequest_Stg
        # SSIS pipeline: SELECT Src.* FROM Staging.PickupRequest_AU_Stg Src
        #                LEFT JOIN Staging.PickupRequest_Stg Tgt ON Tgt.ID = Src.ID
        #                WHERE Tgt.ID IS NULL   -> INSERT INTO Staging.PickupRequest_Stg
        # Fully deterministic from per_component_data in package_metadata.json.
        op_copy_country_staging = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_copy_country_staging_to_pickuprequest_stg",
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
                        f"FROM `{TARGET_DATASET_ID}.Staging_PickupRequest_AU_Stg` AS Src "
                        f"LEFT JOIN `{TARGET_DATASET_ID}.Staging_PickupRequest_Stg` AS Tgt "
                        "ON Tgt.ID = Src.ID "
                        "WHERE Tgt.ID IS NULL;"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\Pickup Requests\Load Target Table
        # SSIS: exec dv.Load_CT_SAT_Label_PickupRequests_AU ?  (binds @ProcessID)
        op_load_target_table = BigQueryInsertJobOperator(
            task_id="package_pickup_requests_load_target_table",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_CT_SAT_Label_PickupRequests_AU`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessID) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # Sequence inside Pickup Requests (from executable_dependencies.json):
        #   Truncate -> Get PickupRequests (AU) -> {Copy Country Staging, Load Target Table}
        op_truncate_pickuprequests_stg >> op_get_pickuprequests_au
        op_get_pickuprequests_au >> op_copy_country_staging
        op_get_pickuprequests_au >> op_load_target_table

    # ref_id: Package\Set Next CT_Version
    # SSIS:
    #   IF @NextVersion IS NOT NULL
    #     UPDATE [FastwayDW].[Staging].[LoadControl_ChangeTracking]
    #        SET LastSyncVersion = @NextVersion
    #      WHERE TargetName = @TargetName
    # PythonOperators render `None` XComs as the literal string "None" during
    # Jinja interpolation, so the guard below compares that literal directly.
    # SAFE_CAST('None' AS INT64) would be NULL anyway, but the WHERE clause
    # ensures we don't touch any row when the CT version is unavailable.
    op_set_next_ct_version = BigQueryInsertJobOperator(
        task_id="package_set_next_ct_version",
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
        gcp_conn_id="google_cloud_default",
    )

    # --- precedence (from executable_dependencies.json) ---
    op_check_if_secondary >> op_get_last_ct_version
    op_get_last_ct_version >> op_get_next_ct_version
    op_get_next_ct_version >> tg_pickup_requests
    tg_pickup_requests >> op_set_next_ct_version
