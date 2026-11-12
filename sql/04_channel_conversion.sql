-- conversion by acquisition channel
-- NOTE: traffic_source.* in the export is the user's FIRST touch, not the
-- session source. good enough to compare channels, just don't read it as
-- last-click attribution

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    ANY_VALUE(traffic_source.medium) AS medium,
    COUNTIF(event_name = 'add_to_cart') > 0 AS carted,
    COUNTIF(event_name = 'purchase') > 0    AS purchased,
    SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1, 2
  HAVING session_id IS NOT NULL
)

SELECT
  medium,
  COUNT(*) AS sessions,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_of_sessions_pct,
  ROUND(100 * COUNTIF(carted) / COUNT(*), 1) AS add_to_cart_pct,
  ROUND(100 * COUNTIF(purchased) / COUNT(*), 2) AS conversion_pct,
  ROUND(SUM(revenue), 0) AS revenue_usd,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions
GROUP BY medium
HAVING sessions > 1000
ORDER BY sessions DESC
