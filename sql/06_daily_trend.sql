-- daily sessions / purchases / revenue, mostly for the dashboard line chart

WITH sessions AS (
  SELECT
    PARSE_DATE('%Y%m%d', MIN(event_date)) AS day,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    COUNTIF(event_name = 'purchase') > 0 AS purchased,
    SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 2, 3
  HAVING session_id IS NOT NULL
)

SELECT
  day,
  COUNT(*) AS sessions,
  COUNTIF(purchased) AS converting_sessions,
  ROUND(100 * COUNTIF(purchased) / COUNT(*), 2) AS conversion_pct,
  ROUND(SUM(revenue), 0) AS revenue_usd
FROM sessions
GROUP BY day
ORDER BY day
