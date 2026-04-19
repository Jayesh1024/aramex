#!/bin/bash
# run_calling-2.sh — configure args here, then run calling-2.py
python calling-2.py \
    BQ_GOLD_RAW_STAGING/stored_procedures_params.json \
    --output_dir BQ_GOLD_RAW_STAGING/sp_call_sql/jinja \
    --jinja
