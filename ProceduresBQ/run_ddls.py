#!/usr/bin/env python3
"""
run_ddls.py — Execute every .sql file in a directory against BigQuery,
running jobs concurrently and logging results to a timestamped log file.

Positional arguments
--------------------
  sql_dir        Directory containing the .sql files to execute.
  credentials    Path to a GCP service-account JSON or Application Default
                 Credentials (ADC) JSON file.

Required flags
--------------
  --project      GCP project ID the queries run against.

Optional flags
--------------
  --location     BigQuery job location            (default: US)
  --max-workers  Max parallel BigQuery jobs        (default: 20)
  --log-dir      Where to write log files          (default: logs/ next to this script)
  --dry-run      List discovered .sql files and exit without executing anything.

Examples
--------
  # Dry-run — just list the files that would be executed:
  python run_ddls.py BQ_CUBE_DDLs_VIEWS/rendered creds.json \\
      --project my-project --dry-run

  # Execute stored-procedure DDLs against a sandbox project:
  python run_ddls.py BQ_GOLD_RAW_STAGING/rendered \\
      ~/.config/gcloud/application_default_credentials.json \\
      --project searce-sandbox-da-delivery

  # Execute view DDLs in production (europe-west2, custom log dir):
  python run_ddls.py BQ_CUBE_DDLs_VIEWS/rendered \\
      /Users/jayesh.mhaske/.config/gcloud/application_default_credentials.json \\
      --project prj-drgfly-prod-sp-01 \\
      --location europe-west2 \\
      --max-workers 20 \\
      --log-dir BQ_CUBE_DDLs_VIEWS/logs

Shell wrapper (run_ddls.sh)
---------------------------
  A convenience shell script is provided for repeated runs. Edit the
  arguments inside run_ddls.sh and invoke it with:

      bash run_ddls.sh

Exit codes
----------
  0  All DDLs executed successfully.
  1  At least one DDL failed, or a startup error occurred.
"""

from __future__ import annotations
from typing import NamedTuple
import argparse
import concurrent.futures
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


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Execute .sql files from a directory against BigQuery and log results.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "sql_dir",
        help="Path to directory containing .sql files to execute",
    )
    p.add_argument(
        "credentials",
        help="Path to GCP service-account or ADC JSON file",
    )
    p.add_argument("--project", required=True,
                    help="GCP project ID to run queries against")
    p.add_argument("--location", default="US",
                    help="BigQuery job location (default: US)")
    p.add_argument("--max-workers", type=int, default=20,
                    help="Max concurrent BQ jobs (default: 20)")
    p.add_argument("--log-dir", default=str(SCRIPT_DIR / "logs"),
                    help="Directory for log files (default: logs/ next to script)")
    p.add_argument("--dry-run", action="store_true",
                    help="List discovered SQL files without executing them")
    return p


def setup_logging(log_dir: Path) -> tuple[logging.Logger, Path]:
    log_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"ddl_execution_{timestamp}.log"

    logger = logging.getLogger("ddl_runner")
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()

    fmt = logging.Formatter(
        "%(asctime)s  %(levelname)-8s  %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(fmt)

    logger.addHandler(fh)
    logger.addHandler(ch)

    return logger, log_file


def discover_sql_files(sql_dir: Path) -> list[DdlJob]:
    jobs: list[DdlJob] = []
    for path in sorted(sql_dir.glob("*.sql")):
        jobs.append(DdlJob(name=path.name, sql=path.read_text(encoding="utf-8")))
    return jobs


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


def main() -> None:
    args = build_parser().parse_args()

    sql_dir = Path(args.sql_dir)
    if not sql_dir.is_dir():
        print(f"[ERROR] SQL directory not found: {sql_dir}")
        sys.exit(1)

    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"[ERROR] Credentials file not found: {creds_path}")
        sys.exit(1)

    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(creds_path)

    ddl_jobs = discover_sql_files(sql_dir)
    if not ddl_jobs:
        print(f"[ERROR] No .sql files found in {sql_dir}")
        sys.exit(1)

    logger, log_file = setup_logging(Path(args.log_dir))
    sep = "═" * 72

    logger.info(sep)
    logger.info("  DDL Execution — BigQuery")
    logger.info(f"  Started      : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info(f"  Project      : {args.project}")
    logger.info(f"  BQ location  : {args.location}")
    logger.info(f"  SQL dir      : {sql_dir.resolve()}")
    logger.info(f"  Credentials  : {creds_path.resolve()}")
    logger.info(f"  SQL files    : {len(ddl_jobs)}")
    logger.info(f"  Max Workers  : {args.max_workers}")
    logger.info(sep)

    if args.dry_run:
        logger.info("")
        logger.info("  DRY RUN — files that would be executed:")
        for job in ddl_jobs:
            logger.info(f"    {job.name}")
        logger.info("")
        logger.info(f"Total: {len(ddl_jobs)} file(s). No queries sent.")
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
    logger.info(f"Full log saved to: {log_file}")

    if failed_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()