"""
calling-2.py — Generate CALL statements for BigQuery stored procedures from
stored_procedures_params.json (array schema).

USAGE
    python calling-2.py BQ_GOLD_RAW_STAGING/stored_procedures_params.json \\
        --project <GCP_PROJECT> --dataset <SP_DATASET_ID> \\
        --output_dir <OUTPUT_DIR>

    Jinja CALL targets ({{project_id}}.{{dataset_id}} in SQL):
    python calling-2.py ... --output_dir sp_call_sql/jinja --jinja

JSON format (array):
[
    {
        "sp_name": "sp_load_Example_Stg",
        "sp_params": [
            {"param_name": "p_date", "param_type": "DATE"},
            {"param_name": "p_id", "param_type": "INT64"}
        ]
    },
    {"sp_name": "sp_no_args", "sp_params": []}
]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

DUMMY_VALUES = {
    "INT64": "0",
    "INT32": "0",
    "INTEGER": "0",
    "FLOAT64": "0.0",
    "FLOAT": "0.0",
    "NUMERIC": "0",
    "BIGNUMERIC": "0",
    "STRING": "'dummy_string'",
    "BYTES": "b''",
    "BOOL": "FALSE",
    "BOOLEAN": "FALSE",
    "DATE": "'2024-01-01'",
    "DATETIME": "'2024-01-01T00:00:00'",
    "TIMESTAMP": "'2024-01-01 00:00:00 UTC'",
    "TIME": "'00:00:00'",
    "ARRAY": "[]",
    "STRUCT": "STRUCT()",
    "JSON": "JSON '{}'",
}


def base_scalar_type(param_type: str) -> str:
    """Map e.g. ARRAY<STRING> -> ARRAY, STRING -> STRING for dummy lookup."""
    t = param_type.strip().upper()
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)", t)
    return m.group(1) if m else t


def get_dummy_value(param_type: str) -> str:
    base = base_scalar_type(param_type)
    if base in DUMMY_VALUES:
        return DUMMY_VALUES[base]
    if "<" in param_type.upper():
        return "NULL"
    return DUMMY_VALUES.get(param_type.strip().upper(), "NULL")


def load_catalog(path: str) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        sys.exit(f"Expected JSON array at top level, got {type(data).__name__}")
    for i, entry in enumerate(data):
        if not isinstance(entry, dict):
            sys.exit(f"Entry {i}: expected object, got {type(entry).__name__}")
        if "sp_name" not in entry:
            sys.exit(f"Entry {i}: missing 'sp_name'")
        if "sp_params" not in entry:
            sys.exit(f"Entry {i}: missing 'sp_params'")
        if not isinstance(entry["sp_params"], list):
            sys.exit(f"Entry {i}: 'sp_params' must be a list")
        for j, p in enumerate(entry["sp_params"]):
            if not isinstance(p, dict):
                sys.exit(f"Entry {i} sp_params[{j}]: expected object")
            if "param_name" not in p or "param_type" not in p:
                sys.exit(
                    f"Entry {i} sp_params[{j}]: need 'param_name' and 'param_type'"
                )
    return data


def build_call(
    sp_name: str,
    params: list[dict],
    *,
    project: str,
    dataset: str,
    jinja: bool = False,
) -> str:
    """Build a multi-line CALL statement with inline parameter name/type comments."""
    if jinja:
        full_sp_name = f"`{{{{project_id}}}}.{{{{dataset_id}}}}.{sp_name}`"
    else:
        full_sp_name = f"`{project}.{dataset}.{sp_name}`"

    if not params:
        return f"CALL {full_sp_name}();\n"

    lines = []
    for i, param in enumerate(params):
        param_name = param["param_name"]
        param_type = param["param_type"]
        dummy = get_dummy_value(param_type)
        if dummy == "NULL":
            print(
                f"  [WARN] Unknown type '{param_type}' for '{param_name}' "
                "-- defaulting to NULL"
            )
        comma = "," if i < len(params) - 1 else ""
        lines.append(f"    {dummy}{comma}  -- {param_name} ({param_type})")

    return (
        f"CALL {full_sp_name}(\n"
        + "\n".join(lines)
        + "\n);\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate CALL .sql files from stored_procedures_params.json."
    )
    parser.add_argument("input_json", help="Path to stored_procedures_params.json")
    parser.add_argument(
        "--project",
        default=None,
        help="GCP project ID (required unless --jinja)",
    )
    parser.add_argument(
        "--dataset",
        default=None,
        help="BigQuery SP dataset ID (required unless --jinja)",
    )
    parser.add_argument(
        "--output_dir", required=True, help="Directory for generated call_*.sql files"
    )
    parser.add_argument(
        "--jinja",
        action="store_true",
        help="Emit {{project_id}}.{{dataset_id}} in the CALL target instead of literals",
    )
    args = parser.parse_args()

    if args.jinja:
        args.project = args.project or ""
        args.dataset = args.dataset or ""
    elif not args.project or not args.dataset:
        sys.exit("--project and --dataset are required unless --jinja is set")

    base = os.path.dirname(os.path.abspath(__file__))
    output_path = (
        args.output_dir
        if os.path.isabs(args.output_dir)
        else os.path.join(base, args.output_dir)
    )
    input_json = (
        args.input_json
        if os.path.isabs(args.input_json)
        else os.path.join(base, args.input_json)
    )

    if not os.path.isfile(input_json):
        sys.exit(f"Input JSON not found: {input_json}")

    os.makedirs(output_path, exist_ok=True)

    catalog = load_catalog(input_json)

    print(f"Project    : {args.project or '(jinja {{project_id}})'}")
    print(f"Dataset    : {args.dataset or '(jinja {{dataset_id}})'}")
    print(f"Jinja mode : {args.jinja}")
    print(f"Output dir : {output_path}")
    print(f"SPs        : {len(catalog)}\n")

    generated = 0
    for entry in catalog:
        sp_name = entry["sp_name"]
        params = entry["sp_params"]
        call_sql = build_call(
            sp_name,
            params,
            project=args.project,
            dataset=args.dataset,
            jinja=args.jinja,
        )
        out_file = os.path.join(output_path, f"call_{sp_name}.sql")
        with open(out_file, "w", encoding="utf-8") as f:
            f.write(call_sql)
        print(f"  Created: {out_file}")
        generated += 1

    print(f"\nDone: {generated} generated.")


if __name__ == "__main__":
    main()
