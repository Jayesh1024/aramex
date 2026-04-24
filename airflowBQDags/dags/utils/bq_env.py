"""BigQuery project and datasets.

Values come from the process environment. For local Docker, set them under
``services.airflow.environment`` in ``compose.yaml`` (GCP_PROJECT, SP_DATASET_ID,
TARGET_DATASET_ID). For managed Airflow, set the same variables in the product
configuration.
"""
from __future__ import annotations

import os

def _require(name: str) -> str:
    try:
        val = os.environ[name]
    except KeyError as exc:
        raise RuntimeError(
            f"Missing required environment variable {name}. "
            "Set GCP_PROJECT, SP_DATASET_ID, and TARGET_DATASET_ID in compose.yaml "
            "(services.airflow.environment) or in your Airflow deployment."
        ) from exc
    val = str(val).strip()
    if not val:
        raise RuntimeError(f"Environment variable {name} is set but empty.")
    return val


GCP_PROJECT = _require("GCP_PROJECT")
SP_DATASET_ID = _require("SP_DATASET_ID")
TARGET_DATASET_ID = _require("TARGET_DATASET_ID")
