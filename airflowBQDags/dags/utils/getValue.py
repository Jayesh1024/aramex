"""Shared Python callables used by the ssis_skeleton_* DAGs.

Any function that is passed as `python_callable=...` to a PythonOperator lives
here (single module) instead of being defined inline inside a DAG file. This
keeps the DAG files focused on graph wiring and makes the helpers unit-testable
without Airflow DAG parsing.

Grouped by responsibility:

* `get_last_value` / `get_next_process_id`        — original helpers.
* `allocate_dashboard_processid`                  — Fact_KPI_Dashboard / Dashboard2.
* `allocate_negative_sentinel_processid`          — Interim_*, HUB_ZenTickets, HUB_BLKContainerManifest.
* `get_max_process_id`                            — LNK_RuralOnFowards.
* `get_max_id`                                    — generic MAX(<col>) on a table.
* `get_last_value_scans`                          — calls Staging_Get_LastValue_Scans SP.
* `get_yesterday_eod_iso`                         — SSIS `DATEADD(DAY, -1, GETDATE())` + `T23:59:59.999`.
"""
from __future__ import annotations

from datetime import datetime, timedelta

from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook


def _escape_sql_literal(value: str) -> str:
    """Escape a string for safe inclusion inside a BigQuery single-quoted literal."""
    return value.replace("\\", "\\\\").replace("'", "''")


def get_last_value(project_id: str, dataset_id: str, record_source: str):
    """Call Staging_Get_LastValue; record_source must match Staging_LoadControl.RecordSource."""
    escaped = _escape_sql_literal(record_source)
    hook = BigQueryHook(project_id=project_id)
    query = f"CALL `{project_id}.{dataset_id}.Staging_Get_LastValue`('{escaped}')"
    return hook.get_pandas_df(sql=query, dialect="standard")[0][0]


def get_next_process_id(project_id: str, dataset_id: str) -> int:
    """IFNULL(MAX(ProcessId),0)+1 from Staging_LoadLog — SSIS LoadControl «Get Next ProcessID»."""
    hook = BigQueryHook(project_id=project_id)
    query = (
        f"SELECT IFNULL(MAX(ProcessId), 0) + 1 AS NextProcessId "
        f"FROM `{project_id}.{dataset_id}.Staging_LoadLog`"
    )
    df = hook.get_pandas_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def allocate_dashboard_processid(project_id: str, dataset_id: str) -> int:
    """Fact_KPI_Dashboard / Dashboard2 «Get Next ProcessID» — negative-sentinel capped at -30000.

    Mirrors SSIS Package\\Staging\\Initial\\Get Next ProcessID::
        DECLARE @ProcessId Int;
        SELECT @ProcessId = IIF(MIN(ProcessId) > -30000, -30000, MIN(ProcessId))
          FROM [Staging].[LoadLog];
        SELECT IsNull(@ProcessId, 0) - 1 AS NextProcessId;
    """
    hook = BigQueryHook(project_id=project_id)
    query = (
        "WITH s AS ("
        "  SELECT MIN(ProcessId) AS min_pid "
        f"  FROM `{project_id}.{dataset_id}.Staging_LoadLog` "
        ") "
        "SELECT IFNULL(IF(min_pid > -30000, -30000, min_pid), 0) - 1 AS NextProcessId "
        "FROM s"
    )
    df = hook.get_pandas_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def allocate_negative_sentinel_processid(project_id: str, dataset_id: str) -> int:
    """Interim_*, HUB_ZenTickets, HUB_BLKContainerManifest «Get ProcessID».

    Walks the -99999 sentinel space downward::
        SELECT IFNULL(MIN(ProcessID), -99999) - 1
          FROM Staging.LoadLog
         WHERE ProcessID < -99999;
    """
    hook = BigQueryHook(project_id=project_id)
    query = (
        "SELECT IFNULL(MIN(ProcessID), -99999) - 1 AS ProcessID "
        f"FROM `{project_id}.{dataset_id}.Staging_LoadLog` "
        "WHERE ProcessID < -99999"
    )
    df = hook.get_pandas_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def get_max_process_id(project_id: str, dataset_id: str) -> int:
    """LNK_RuralOnFowards «Get ProcessID» — just `MAX(ProcessID)` from Staging_LoadLog."""
    hook = BigQueryHook(project_id=project_id)
    query = (
        f"SELECT IFNULL(MAX(ProcessID), 0) AS ProcessID "
        f"FROM `{project_id}.{dataset_id}.Staging_LoadLog`"
    )
    df = hook.get_pandas_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def get_max_id(
    project_id: str,
    dataset_id: str,
    table_name: str,
    id_column: str = "ID",
) -> int:
    """Return `IFNULL(MAX(<id_column>), 0)` from `<project>.<dataset>.<table>`.

    Used e.g. by Fact_KPI_Dashboard «Get LastScanID (TrackAndTrace)» which
    executes::
        SELECT LastID = MAX(ID) FROM [Staging].[TrackAndTrace_Stg];
    """
    hook = BigQueryHook(project_id=project_id)
    query = (
        f"SELECT IFNULL(MAX(`{id_column}`), 0) AS LastId "
        f"FROM `{project_id}.{dataset_id}.{table_name}`"
    )
    df = hook.get_pandas_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def get_last_value_scans(
    project_id: str,
    dataset_id: str,
    record_source: str,
    calc_method: str,
    max_days: int,
) -> str:
    """Call `Staging_Get_LastValue_Scans` and return `LastDate` as an ISO string.

    SP signature::
        (RecordSource STRING, CalcMethod STRING,
         EndDate DATETIME INOUT, MaxDays INT64)

    The SP SELECTs `(LastId, LastDate, EndDate)` — we pull `LastDate`.
    """
    escaped = _escape_sql_literal(record_source)
    hook = BigQueryHook(project_id=project_id)
    query = (
        f"CALL `{project_id}.{dataset_id}.Staging_Get_LastValue_Scans`("
        f"'{escaped}', '{calc_method}', NULL, {int(max_days)})"
    )
    df = hook.get_pandas_df(sql=query, dialect="standard")
    return str(df.iloc[0]["LastDate"])


def get_yesterday_eod_iso() -> str:
    """SSIS equivalent: `CONVERT(varchar(10), DATEADD(DAY, -1, GETDATE()), 120) + 'T23:59:59.999'`."""
    d = datetime.utcnow().date() - timedelta(days=1)
    return f"{d.isoformat()}T23:59:59.999"
