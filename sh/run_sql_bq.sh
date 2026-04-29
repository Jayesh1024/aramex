python src/run_sql_bq.py \
    misc/truncateQueriesGold/rendered \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-dev-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir misc/truncateQueriesGold/rendered/logs