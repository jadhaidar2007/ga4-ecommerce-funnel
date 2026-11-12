# GA4 + BigQuery ecommerce funnel analysis

I wanted to learn the full GA4 analytics workflow end to end, not just the GA4 UI. So I built a small demo shop with proper GA4 ecommerce tracking, wrote the SQL against the GA4 BigQuery export, and turned the results into a dashboard and a short write-up.

**Main finding:** 56% of sessions that start checkout never buy, and most of them leave between entering shipping info and entering payment. Full write-up in [`docs/insights.md`](docs/insights.md).

- **Dashboard:** [`dashboard/index.html`](dashboard/index.html) (live link below if Pages is on)
- **Demo shop:** [`shop/`](shop)
- **SQL:** [`sql/`](sql)

## What's in here

```
shop/          static demo store (HTML/JS), fires the full GA4 ecommerce event set
sql/           7 BigQuery queries on the GA4 export schema
scripts/       run_queries.py  -> runs the sql, saves csvs to data/
               build_dashboard.py -> bakes the csvs into dashboard/index.html
data/          query output (csv)
dashboard/     static dashboard (Chart.js), works offline once built
docs/          insights write-up
```

## The demo shop

Plain HTML + JS, no framework, no backend. The cart lives in localStorage. It tracks the standard GA4 ecommerce funnel:

| Page | Events |
|---|---|
| product list | `view_item_list`, `select_item` |
| product page | `view_item`, `add_to_cart` |
| cart | `view_cart`, `remove_from_cart`, `begin_checkout` |
| checkout | `add_shipping_info`, `add_payment_info`, `purchase` |

All events go through one `track()` function in [`shop/js/analytics.js`](shop/js/analytics.js), which adds `currency` and calculates `value` from the items. Item objects follow GA4's `items[]` format, so they show up properly in the monetization reports and the BigQuery export.

To run it with your own property:
1. Create a GA4 property and a web data stream
2. Put the measurement ID in [`shop/js/config.js`](shop/js/config.js)
3. Serve the folder (`python -m http.server` inside `shop/`) and click around
4. Check events in GA4 under Admin > DebugView

Without a measurement ID it just logs every event to the console, which is handy for checking the payloads.

## Why the analysis uses Google's sample data

A demo shop with me as the only visitor doesn't give you any real data to analyse. So the queries run on Google's public GA4 sample export (the Google Merchandise Store, Nov 2020 to Jan 2021, ~360k sessions). It has **the same schema** my shop's export would have, so the exact same SQL works on both. To point it at your own export:

```bash
python scripts/run_queries.py --project YOUR_GCP_PROJECT \
  --table YOUR_GCP_PROJECT.analytics_123456789.events_* \
  --start 20261101 --end 20261130
```

## The queries

| File | Question |
|---|---|
| `01_overview.sql` | users, sessions, conversion rate, revenue |
| `02_funnel.sql` | how many sessions reach each funnel step (open and closed funnel) |
| `03_funnel_by_device.sql` | does checkout perform worse on mobile? |
| `04_channel_conversion.sql` | which acquisition channels convert |
| `05_product_performance.sql` | products that get viewed but not added to cart |
| `06_daily_trend.sql` | daily sessions / conversion / revenue |
| `07_new_vs_returning.sql` | conversion by session number |

Some GA4 export things I had to deal with:
- there's no session table, so a session is `user_pseudo_id` + the `ga_session_id` event param
- event params are a repeated key/value field, so you pull them out with `(SELECT value.int_value FROM UNNEST(event_params) WHERE key = '...')`
- `traffic_source` is the user's *first* touch, not the session source
- the export is sharded by day (`events_YYYYMMDD`), so filter with `_TABLE_SUFFIX` to keep the scanned bytes down

## Running it

```bash
pip install -r requirements.txt
gcloud auth application-default login

python scripts/run_queries.py --project YOUR_GCP_PROJECT --dry-run   # check sql + cost
python scripts/run_queries.py --project YOUR_GCP_PROJECT
python scripts/build_dashboard.py
```

Each query scans around 1 GB, so the whole set fits easily in the BigQuery sandbox free tier (1 TB of queries per month).

## Results

| | |
|---|---|
| Sessions | 360,129 |
| Conversion rate | 1.35% |
| Cart abandonment | 68.1% |
| Checkout abandonment | 56.3% |
| Returning (4th+ session) vs first session conversion | 4.69% vs 0.68% |
| Holiday conversion dip (21 Dec - 18 Jan vs 1-20 Dec) | 0.76% vs 1.81% |

More detail, caveats and what I'd actually change in [`docs/insights.md`](docs/insights.md).

## Things I'd add next

- a Looker Studio version of the dashboard connected straight to BigQuery
- sessionized source/medium from `collected_traffic_source` (only in newer exports)
- time-to-purchase and a proper cohort retention table
- server-side tagging for the shop
