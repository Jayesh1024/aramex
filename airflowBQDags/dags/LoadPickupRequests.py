"""
Consolidated DAG for SSIS packages LoadPickupRequests_AU / _NZ / _SA (BigQuery).

Replaces three separate DAG files with one schedule and three parallel country branches.

Source metadata per country:
  * `airflowBQDags/Packages/LoadPickupRequests_<CC>.dtsx`
  * `airflowBQDags/outputs/LoadPickupRequests_<CC>/`

Flow (per country TaskGroup):
  * Watermark — `get_last_value` → `CALL <GCP_PROJECT_ID>.<SP_DATASET_ID>.Staging_Get_LastValue` (procedure
    in SP dataset; reads `Staging_LoadControl` in target). Override env via `config/template_config.env`.
  * Truncate `Staging_PickupRequest_<CC>_Stg`.
  * `CALL Staging_load_PickupRequest_<CC>_Stg(p_ingestion_time)` — silver → country stg; cutoff is **DATETIME**
    (`ingestion_time` > cutoff). See `BQ_GOLD_2/jinja/Staging_load_PickupRequest_*_Stg.sql`.
  * Copy new IDs into `Staging_PickupRequest_Stg` (SSIS «Copy Country Staging to PickupRequest_Stg»).
  * `CALL dv_Load_CT_SAT_Label_PickupRequests_<CC>(ProcessID)`.
  * `CALL Staging_Set_LastValue(RecordSource, 'ingestion_time', MAX(ingestion_time) from country stg, FALSE)`
    so `Staging_LoadControl.LastValue` advances after a successful run (requires LoadControl rows).

Coexists with `dv_Load_SAT_Label_PickupRequests` (full refresh from shared stg) — different routines.

All BigQuery SQL uses three-part names: `` `project_id.dataset_id.object` `` via `_bq_qual`.
"""
from __future__ import annotations

from datetime import datetime
import os
from typing import Any

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

from utils.getValue import get_last_value

# Defaults align with `airflowBQDags/config/template_config.env` when env is unset.
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID") or "prj-drgfly-dev-sp-01"
SP_DATASET_ID = os.getenv("SP_DATASET_ID") or "bq_ds_dev_euw2_store_procedure"
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID") or "bq_ds_dev_euw2_oceania_cube_gold_1"


def _bq_qual(dataset_id: str, object_name: str) -> str:
    """BigQuery three-part id: `project.dataset.table_or_routine`."""
    return f"`{GCP_PROJECT_ID}.{dataset_id}.{object_name}`"

# SSIS defaults preserved for testing; override via dag_run.conf when orchestrated.
_COUNTRY_BRANCHES: tuple[dict[str, Any], ...] = (
    {
        "group_id": "tg_au",
        "record_source": "PickupRequests_AU",
        "process_id": -61,
        "table_suffix": "AU",
        "load_sp": "Staging_load_PickupRequest_AU_Stg",
        "dv_sp": "dv_Load_CT_SAT_Label_PickupRequests_AU",
    },
    {
        "group_id": "tg_nz",
        "record_source": "PickupRequests_NZ",
        "process_id": -66,
        "table_suffix": "NZ",
        "load_sp": "Staging_load_PickupRequest_NZ_Stg",
        "dv_sp": "dv_Load_CT_SAT_Label_PickupRequests_NZ",
    },
    {
        "group_id": "tg_sa",
        "record_source": "PickupRequests_SA",
        "process_id": -69,
        "table_suffix": "SA",
        "load_sp": "Staging_load_PickupRequest_SA_Stg",
        "dv_sp": "dv_Load_CT_SAT_Label_PickupRequests_SA",
    },
)


def _copy_country_to_shared_sql(country_suffix: str) -> str:
    stg = _bq_qual(TARGET_DATASET_ID, f"Staging_PickupRequest_{country_suffix}_Stg")
    return (
        f"INSERT INTO {_bq_qual(TARGET_DATASET_ID, 'Staging_PickupRequest_Stg')} ("
        "ID, CreateDateUtc, ingestion_time, ShouldPrintLabel, PickupFranchiseeCode, "
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
        "SELECT Src.Id, Src.CreateDateUtc, Src.ingestion_time, Src.ShouldPrintLabel, "
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
        f"FROM {stg} AS Src "
        f"LEFT JOIN {_bq_qual(TARGET_DATASET_ID, 'Staging_PickupRequest_Stg')} AS Tgt "
        "ON Tgt.ID = Src.Id "
        "WHERE Tgt.ID IS NULL;"
    )


with DAG(
    dag_id="ssis_skeleton_loadpickuprequests",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadpickuprequests", "RecordSource_PickupRequests_AU", "RecordSource_PickupRequests_NZ", "RecordSource_PickupRequests_SA"],
) as dag:

    for spec in _COUNTRY_BRANCHES:
        gid = spec["group_id"]
        rs = spec["record_source"]
        sfx = spec["table_suffix"]
        load_sp = spec["load_sp"]
        dv_sp = spec["dv_sp"]
        proc_id = spec["process_id"]
        tid_get_last = f"{gid}.get_last_value"

        with TaskGroup(group_id=gid):
            op_get_last = PythonOperator(
                task_id="get_last_value",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": rs,
                },
            )

            op_truncate = BigQueryInsertJobOperator(
                task_id="truncate_country_stg",
                configuration={
                    "query": {
                        "query": (
                            "TRUNCATE TABLE "
                            f"{_bq_qual(TARGET_DATASET_ID, f'Staging_PickupRequest_{sfx}_Stg')};"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            xcom_jinja = f"{{{{ ti.xcom_pull(task_ids='{tid_get_last}', default='') }}}}"
            op_staging_load = BigQueryInsertJobOperator(
                task_id="staging_load_country",
                configuration={
                    "query": {
                        "query": (
                            f"CALL {_bq_qual(SP_DATASET_ID, load_sp)}('{xcom_jinja}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_copy = BigQueryInsertJobOperator(
                task_id="copy_country_to_shared_stg",
                configuration={
                    "query": {
                        "query": _copy_country_to_shared_sql(sfx),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_dv = BigQueryInsertJobOperator(
                task_id="dv_load_ct_sat_label_pickuprequests",
                configuration={
                    "query": {
                        "query": (
                            f"CALL {_bq_qual(SP_DATASET_ID, dv_sp)}({proc_id});"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_set_last_value = BigQueryInsertJobOperator(
                task_id="set_last_value_loadcontrol",
                configuration={
                    "query": {
                        "query": (
                            "BEGIN\n"
                            "  DECLARE max_ingestion STRING;\n"
                            "  SET max_ingestion = (\n"
                            "    SELECT CAST(MAX(ingestion_time) AS STRING)\n"
                            f"    FROM {_bq_qual(TARGET_DATASET_ID, f'Staging_PickupRequest_{sfx}_Stg')}\n"
                            "  );\n"
                            f"  CALL {_bq_qual(SP_DATASET_ID, 'Staging_Set_LastValue')}(\n"
                            f"    '{rs}',\n"
                            "    'ingestion_time',\n"
                            "    max_ingestion,\n"
                            "    FALSE\n"
                            "  );\n"
                            "END;"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_get_last >> op_truncate >> op_staging_load
            op_staging_load >> op_copy
            op_staging_load >> op_dv
            op_copy >> op_set_last_value
            op_dv >> op_set_last_value
