#!/bin/bash

python3 run_ddls.py \
    "Rendered BQ" \
    "$HOME/.config/gcloud/application_default_credentials.json" \
    --project searce-sandbox-da-delivery \
    --location US \
    --max-workers 5 \
    --log-dir "logs"