gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- ssis_skeleton_loadcontrol

gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- interim_scans

gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- load_interbranch

gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- ssis_skeleton_loadpickuprequests

gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- ssis_skeleton_load_fwfastlabel_invoices

gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- ssis_skeleton_loadgokutables

gcloud composer environments run composer-prod-euw2-01 \
    --location europe-west2 \
    dags trigger -- ssis_skeleton_hub_blkcontainermanifest