python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_1/StoredProc/rendered \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir ProceduresBQ/BQ_GOLD_1/StoredProc/rendered/logs