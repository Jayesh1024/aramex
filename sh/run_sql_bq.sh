python src/run_sql_bq.py \
    sql/Partitioned \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/