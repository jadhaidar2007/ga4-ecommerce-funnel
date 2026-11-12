"""
Runs every query in sql/ against BigQuery and saves the results to data/*.csv

    pip install -r requirements.txt
    gcloud auth application-default login
    python scripts/run_queries.py --project my-gcp-project

By default it reads the public GA4 sample dataset (Google Merchandise Store).
To run it on your own GA4 export instead:

    python scripts/run_queries.py --project my-gcp-project \
        --table my-gcp-project.analytics_123456789.events_* \
        --start 20261001 --end 20261031
"""

import argparse
from pathlib import Path

from google.cloud import bigquery

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "data"

PUBLIC_TABLE = "bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*"
PUBLIC_START, PUBLIC_END = "20201101", "20210131"


def prepare(sql, table, start, end):
    return (
        sql.replace(PUBLIC_TABLE, table)
        .replace(f"'{PUBLIC_START}'", f"'{start}'")
        .replace(f"'{PUBLIC_END}'", f"'{end}'")
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True, help="GCP project that gets billed for the queries")
    ap.add_argument("--table", default=PUBLIC_TABLE)
    ap.add_argument("--start", default=PUBLIC_START)
    ap.add_argument("--end", default=PUBLIC_END)
    ap.add_argument("--only", help="run a single file, e.g. 02_funnel")
    ap.add_argument("--dry-run", action="store_true", help="just check the sql + bytes scanned")
    args = ap.parse_args()

    client = bigquery.Client(project=args.project)
    OUT_DIR.mkdir(exist_ok=True)

    files = sorted(SQL_DIR.glob("*.sql"))
    if args.only:
        files = [f for f in files if f.stem == args.only]

    total_gb = 0
    for f in files:
        sql = prepare(f.read_text(), args.table, args.start, args.end)
        cfg = bigquery.QueryJobConfig(dry_run=args.dry_run, use_query_cache=True)
        job = client.query(sql, job_config=cfg)

        if args.dry_run:
            gb = job.total_bytes_processed / 1e9
            total_gb += gb
            print(f"{f.stem:<28} ok   {gb:6.2f} GB")
            continue

        df = job.result().to_dataframe()
        df.to_csv(OUT_DIR / f"{f.stem}.csv", index=False)
        total_gb += (job.total_bytes_billed or 0) / 1e9
        print(f"{f.stem:<28} {len(df):>5} rows")

    print(f"\n~{total_gb:.2f} GB {'would be ' if args.dry_run else ''}scanned")


if __name__ == "__main__":
    main()
