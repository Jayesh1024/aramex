#!/usr/bin/env python3
"""Simple ADC/credentials inspector.

Usage:
  python3 scripts/gcp_adc_info.py /path/to/credentials.json
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/gcp_adc_info.py /path/to/credentials.json")
        sys.exit(1)

    path = Path(sys.argv[1]).expanduser().resolve()
    print(f"File: {path}")
    print(f"CWD:  {os.getcwd()}")

    if not path.exists():
        print("Error: file does not exist.")
        print("If running inside Docker, pass a path that exists inside the container.")
        sys.exit(1)

    if not path.is_file():
        print("Error: path is not a file.")
        sys.exit(1)

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Error: could not parse JSON: {exc}")
        sys.exit(1)

    cred_type = data.get("type", "unknown")
    print(f"Type: {cred_type}")

    if cred_type == "service_account":
        print(f"Project ID: {data.get('project_id', 'N/A')}")
        print(f"Account:    {data.get('client_email', 'N/A')}")
        return

    if cred_type == "authorized_user":
        print("Project ID: not in authorized_user ADC JSON")
        print("Account:    not in ADC JSON")

        # best effort hint from local gcloud
        try:
            result = subprocess.run(
                ["gcloud", "auth", "list", "--filter=status:ACTIVE", "--format=value(account)"],
                capture_output=True,
                text=True,
                timeout=8,
            )
            acct = result.stdout.strip()
            if acct:
                print(f"Active gcloud account (hint): {acct.splitlines()[0]}")
        except Exception:
            pass

        env_project = os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GCLOUD_PROJECT")
        if env_project:
            print(f"Project from env (hint): {env_project}")
        return

    print("Unknown credentials format. Top-level keys:")
    print(", ".join(sorted(data.keys())))


if __name__ == "__main__":
    main()
