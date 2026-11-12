"""
Takes the csv files in data/ and bakes them into dashboard/index.html
(no server needed, just open the file or host it on github pages)

    python scripts/build_dashboard.py
"""

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"

FILES = {
    "overview": "01_overview",
    "funnel": "02_funnel",
    "device": "03_funnel_by_device",
    "channel": "04_channel_conversion",
    "products": "05_product_performance",
    "daily": "06_daily_trend",
    "returning": "07_new_vs_returning",
}


def num(x):
    if x == "":
        return None
    try:
        return int(x)
    except ValueError:
        try:
            return float(x)
        except ValueError:
            return x


def load(name):
    with open(DATA / f"{name}.csv", newline="") as f:
        return [{k: num(v) for k, v in row.items()} for row in csv.DictReader(f)]


def main():
    data = {key: load(fname) for key, fname in FILES.items()}
    template = (ROOT / "dashboard" / "template.html").read_text()
    # escape "</" so a product name can never close the script tag
    blob = json.dumps(data, separators=(",", ":")).replace("</", "<\\/")
    out = ROOT / "dashboard" / "index.html"
    out.write_text(template.replace("__DATA__", blob))
    print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
