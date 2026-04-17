from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook


def get_last_value(project_id: str, dataset_id: str, record_source: str):
    """Call Staging_Get_LastValue; record_source must match Staging_LoadControl.RecordSource."""
    escaped = record_source.replace("\\", "\\\\").replace("'", "''")
    hook = BigQueryHook(project_id=project_id)
    query = f"CALL `{project_id}.{dataset_id}.Staging_Get_LastValue`('{escaped}')"
    return hook.get_df(sql=query, dialect="standard")[0][0]


def get_next_process_id(project_id: str, dataset_id: str) -> int:
    """IFNULL(MAX(ProcessId),0)+1 from Staging_LoadLog — SSIS LoadControl «Get Next ProcessID»."""
    hook = BigQueryHook(project_id=project_id)
    query = (
        f"SELECT IFNULL(MAX(ProcessId), 0) + 1 AS NextProcessId "
        f"FROM `{project_id}.{dataset_id}.Staging_LoadLog`"
    )
    df = hook.get_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])