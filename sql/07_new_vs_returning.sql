-- first session vs returning sessions
-- ga_session_number = 1 means it's the user's first session

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number')) AS session_number,
    COUNTIF(event_name = 'add_to_cart') > 0    AS carted,
    COUNTIF(event_name = 'begin_checkout') > 0 AS checkout,
    COUNTIF(event_name = 'purchase') > 0       AS purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1, 2
  HAVING session_id IS NOT NULL AND session_number IS NOT NULL
)

SELECT
  CASE
    WHEN session_number = 1 THEN '1st session'
    WHEN session_number BETWEEN 2 AND 3 THEN '2-3'
    ELSE '4+'
  END AS session_bucket,
  COUNT(*) AS sessions,
  ROUND(100 * COUNTIF(carted) / COUNT(*), 1) AS add_to_cart_pct,
  ROUND(100 * COUNTIF(checkout) / COUNT(*), 2) AS checkout_pct,
  ROUND(100 * COUNTIF(purchased) / COUNT(*), 2) AS conversion_pct
FROM sessions
GROUP BY session_bucket
ORDER BY session_bucket
