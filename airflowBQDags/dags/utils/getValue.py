from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook

def get_last_value(project_id, dataset_id, table_id, record_source):
    hook = BigQueryHook(project_id=project_id)
    query = f"CALL `{project_id}.{dataset_id}.Staging_Get_LastValue`({record_source})"
    return hook.get_df(sql=query, dialect="standard")[0][0]