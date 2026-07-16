# Truncate CUBE
python src/run_sql_bq.py \
    sql/truncateQueriesGold/rendered \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

# Deploy Partitioned tables
python src/run_sql_bq.py \
    sql/Partitioned \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

sleep 5

# Manual Loads
python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_2/manualLoad \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

# Gold Layer 1 SP (Silver to GOLD data transfer) Stored Procedures - Historical
python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_1/StoredProc/rendered/Historical \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

# Gold Layer 1 SP (Silver to GOLD data transfer) Stored Procedures - Incremental
python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_1/StoredProc/rendered/Incremental \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

# Gold Layer 2 SP (GOLD to GOLD data transfer) Stored Procedures - Historical
python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_2/rendered/Historical \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/

# Gold Layer 2 SP (GOLD to GOLD data transfer) Stored Procedures - Incremental
python src/run_sql_bq.py \
    ProceduresBQ/BQ_GOLD_2/rendered/Incremental \
    ~/.config/gcloud/application_default_credentials.json \
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir logs/