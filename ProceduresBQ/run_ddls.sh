python run_ddls.py \
    BQ_CUBE_DDLs_VIEWS/rendered \
    Users/mausam.kamdar/.config/gcloud/application_default_credentials.json
    --project prj-drgfly-prod-sp-01 \
    --location europe-west2 \
    --max-workers 20 \
    --log-dir LogFolder/logs