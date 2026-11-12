-- headline numbers for the whole period
-- a "session" in GA4 = user_pseudo_id + ga_session_id

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    COUNTIF(event_name = 'purchase') > 0 AS purchased,
    SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1, 2
)

SELECT
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(*) AS sessions,
  COUNTIF(purchased) AS converting_sessions,
  ROUND(100 * COUNTIF(purchased) / COUNT(*), 2) AS session_conversion_pct,
  ROUND(SUM(revenue), 0) AS revenue_usd,
  ROUND(SUM(revenue) / NULLIF(COUNTIF(purchased), 0), 2) AS revenue_per_converting_session
FROM sessions
WHERE session_id IS NOT NULL
