#!/usr/bin/env python3
"""
run_sql_bq.py — Execute every .sql file in a GCS path against BigQuery,
running jobs concurrently and uploading a timestamped log file to GCS.

Positional arguments
--------------------
  sql_dir        GCS path (gs://bucket/prefix/) or local directory containing .sql files.
  credentials    Path to a GCP service-account JSON, ADC JSON file, or "adc" to use
                 Application Default Credentials (default on Cloud Composer).

Required flags
--------------
  --project      GCP project ID the queries run against.

Optional flags
--------------
  --location     BigQuery job location            (default: US)
  --max-workers  Max parallel BigQuery jobs        (default: 20)
  --log-dir      GCS path (gs://bucket/prefix/) or local dir for log files
  --dry-run      List discovered .sql files and exit without executing anything.

Examples
--------
  # Read from GCS, write logs to GCS:
  python run_sql_bq.py gs://my-bucket/sql/ adc \\
      --project my-project \\
      --log-dir gs://my-bucket/logs/

  # Local directory (original behaviour):
  python run_sql_bq.py ./sql/ adc --project my-project
"""

from __future__ import annotations
from typing import NamedTuple
import argparse
import concurrent.futures
import io
import logging
import os
import sys
import threading
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent


class DdlJob(NamedTuple):
    name: str
    sql: str


def _parse_gcs_path(gcs_path: str) -> tuple[str, str]:
    """Return (bucket, prefix) from a gs://bucket/prefix/ string."""
    without_scheme = gcs_path[len("gs://"):]
    bucket, _, prefix = without_scheme.partition("/")
    return bucket, prefix


def is_gcs(path: str) -> bool:
    return path.startswith("gs://")


def discover_sql_files_gcs(gcs_path: str, gcs_client) -> list[DdlJob]:
    bucket_name, prefix = _parse_gcs_path(gcs_path)
    blobs = sorted(
        [b for b in gcs_client.list_blobs(bucket_name, prefix=prefix) if b.name.endswith(".sql")],
        key=lambda b: b.name,
    )
    jobs = []
    for blob in blobs:
        name = blob.name.split("/")[-1]
        sql = blob.download_as_text(encoding="utf-8")
        jobs.append(DdlJob(name=name, sql=sql))
    return jobs


def discover_sql_files_local(sql_dir: Path) -> list[DdlJob]:
    return [
        DdlJob(name=path.name, sql=path.read_text(encoding="utf-8"))
        for path in sorted(sql_dir.glob("*.sql"))
    ]


class GcsLogHandler(logging.Handler):
    """Buffers log records in memory and uploads to GCS on flush."""

    def __init__(self, gcs_client, bucket_name: str, blob_name: str):
        super().__init__()
        self._client = gcs_client
        self._bucket_name = bucket_name
        self._blob_name = blob_name
        self._buffer = io.StringIO()

    def emit(self, record: logging.LogRecord) -> None:
        self._buffer.write(self.format(record) + "\n")

    def flush(self) -> None:
        content = self._buffer.getvalue()
        if not content:
            return
        bucket = self._client.bucket(self._bucket_name)
        blob = bucket.blob(self._blob_name)
        blob.upload_from_string(content, content_type="text/plain")


def setup_logging(log_dir: str, gcs_client=None) -> tuple[logging.Logger, str]:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"ddl_execution_{timestamp}.log"

    logger = logging.getLogger("ddl_runner")
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()

    fmt = logging.Formatter(
        "%(asctime)s  %(levelname)-8s  %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Always stream to stdout (visible in Airflow task logs)
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(fmt)
    logger.addHandler(ch)

    if is_gcs(log_dir):
        bucket_name, prefix = _parse_gcs_path(log_dir)
        blob_name = f"{prefix.rstrip('/')}/{log_filename}"
        gcs_handler = GcsLogHandler(gcs_client, bucket_name, blob_name)
        gcs_handler.setLevel(logging.DEBUG)
        gcs_handler.setFormatter(fmt)
        logger.addHandler(gcs_handler)
        log_location = f"gs://{bucket_name}/{blob_name}"
    else:
        local_log_dir = Path(log_dir)
        local_log_dir.mkdir(parents=True, exist_ok=True)
        log_file = local_log_dir / log_filename
        fh = logging.FileHandler(log_file, encoding="utf-8")
        fh.setLevel(logging.DEBUG)
        fh.setFormatter(fmt)
        logger.addHandler(fh)
        log_location = str(log_file)

    return logger, log_location


def execute_ddl(
    job: DdlJob,
    bq_client,
    logger: logging.Logger,
    lock: threading.Lock,
    results: dict,
) -> None:
    try:
        query_job = bq_client.query(job.sql)
        query_job.result()
        with lock:
            results["success"].append(job.name)
        logger.info(f"[SUCCESS] {job.name}")
    except Exception as exc:
        error_msg = " ".join(str(exc).split())
        with lock:
            results["failed"].append((job.name, error_msg))
        logger.error(f"[FAILED]  {job.name}")
        logger.error(f"          {error_msg}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Execute .sql files from GCS or a local directory against BigQuery.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("sql_dir", help="GCS path (gs://bucket/prefix/) or local directory of .sql files")
    p.add_argument("credentials", help="Path to service-account JSON, ADC JSON, or 'adc'")
    p.add_argument("--project", required=True, help="GCP project ID")
    p.add_argument("--location", default="US", help="BigQuery job location (default: US)")
    p.add_argument("--max-workers", type=int, default=20, help="Max concurrent BQ jobs (default: 20)")
    p.add_argument("--log-dir", default=str(SCRIPT_DIR / "logs"),
                   help="GCS path or local dir for log files")
    p.add_argument("--dry-run", action="store_true", help="List SQL files without executing")
    return p


def main() -> None:
    args = build_parser().parse_args()

    # Credentials — skip file check when using ADC on Composer
    if args.credentials.lower() != "adc":
        creds_path = Path(args.credentials)
        if not creds_path.exists():
            print(f"[ERROR] Credentials file not found: {creds_path}")
            sys.exit(1)
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(creds_path)

    # GCS client (needed for both SQL discovery and log upload)
    from google.cloud import storage
    gcs_client = storage.Client(project=args.project)

    # Discover SQL files
    if is_gcs(args.sql_dir):
        ddl_jobs = discover_sql_files_gcs(args.sql_dir, gcs_client)
    else:
        sql_dir = Path(args.sql_dir)
        if not sql_dir.is_dir():
            print(f"[ERROR] SQL directory not found: {sql_dir}")
            sys.exit(1)
        ddl_jobs = discover_sql_files_local(sql_dir)

    if not ddl_jobs:
        print(f"[ERROR] No .sql files found in {args.sql_dir}")
        sys.exit(1)

    logger, log_location = setup_logging(args.log_dir, gcs_client)
    sep = "═" * 72

    logger.info(sep)
    logger.info("  DDL Execution — BigQuery")
    logger.info(f"  Started      : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info(f"  Project      : {args.project}")
    logger.info(f"  BQ location  : {args.location}")
    logger.info(f"  SQL dir      : {args.sql_dir}")
    logger.info(f"  SQL files    : {len(ddl_jobs)}")
    logger.info(f"  Max Workers  : {args.max_workers}")
    logger.info(sep)

    if args.dry_run:
        logger.info("")
        logger.info("  DRY RUN — files that would be executed:")
        for job in ddl_jobs:
            logger.info(f"    {job.name}")
        logger.info(f"\nTotal: {len(ddl_jobs)} file(s). No queries sent.")
        for h in logger.handlers:
            h.flush()
        return

    from google.cloud import bigquery
    try:
        bq_client = bigquery.Client(project=args.project, location=args.location)
    except Exception as exc:
        logger.error(f"Failed to initialise BigQuery client: {exc}")
        sys.exit(1)

    logger.info("")
    logger.info("  Results")
    logger.info("─" * 72)

    lock = threading.Lock()
    results: dict = {"success": [], "failed": []}
    start = datetime.now()

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.max_workers) as executor:
        futures = {
            executor.submit(execute_ddl, job, bq_client, logger, lock, results): job.name
            for job in ddl_jobs
        }
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as exc:
                logger.error(f"Unhandled worker exception: {exc}")

    elapsed = datetime.now() - start
    minutes, secs = divmod(int(elapsed.total_seconds()), 60)
    success_count = len(results["success"])
    failed_count = len(results["failed"])

    logger.info("")
    logger.info(sep)
    logger.info("  SUMMARY")
    logger.info(f"  Finished : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info(f"  Elapsed  : {minutes}m {secs}s")
    logger.info(f"  Success  : {success_count}")
    logger.info(f"  Failed   : {failed_count}")
    logger.info(f"  Total    : {len(ddl_jobs)}")
    logger.info(sep)

    if failed_count > 0:
        logger.info("")
        logger.info("  Failed files:")
        for name, err in results["failed"]:
            logger.info(f"    {name}")
            logger.info(f"      {err}")

    logger.info("")
    logger.info(f"Full log saved to: {log_location}")

    # Flush GCS log handler to upload before exit
    for h in logger.handlers:
        h.flush()

    if failed_count > 0:
        print(f"Script completed successfully with {failed_count} SQL file(s) having errors. Check the log for details: {log_location}")


if __name__ == "__main__":
    main()
