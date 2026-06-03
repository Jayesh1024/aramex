python src/run_sql_bq.py \
    misc/truncateQueriesGold/rendered \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

sleep 5

python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_2/manualLoad \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

