-- same funnel split by device, open version (any order) to keep it readable

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    ANY_VALUE(device.category) AS device,
    COUNTIF(event_name = 'view_item') > 0      AS viewed,
    COUNTIF(event_name = 'add_to_cart') > 0    AS carted,
    COUNTIF(event_name = 'begin_checkout') > 0 AS checkout,
    COUNTIF(event_name = 'purchase') > 0       AS purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1, 2
  HAVING session_id IS NOT NULL
)

SELECT
  device,
  COUNT(*) AS sessions,
  ROUND(100 * COUNTIF(viewed) / COUNT(*), 1) AS view_item_pct,
  ROUND(100 * COUNTIF(carted) / COUNT(*), 1) AS add_to_cart_pct,
  ROUND(100 * COUNTIF(checkout) / COUNT(*), 2) AS checkout_pct,
  ROUND(100 * COUNTIF(purchased) / COUNT(*), 2) AS purchase_pct,
  -- of the sessions that started checkout, how many finished
  ROUND(100 * COUNTIF(checkout AND purchased) / NULLIF(COUNTIF(checkout), 0), 1) AS checkout_completion_pct
FROM sessions
GROUP BY device
ORDER BY sessions DESC
