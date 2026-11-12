-- session funnel from landing to purchase
--
-- two versions of each step:
--   open   = session fired this event at some point
--   closed = session fired this event AND every step before it
-- the closed one is the "real" funnel, the open one shows where tracking
-- skips steps (e.g. purchases without a begin_checkout event)

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    COUNTIF(event_name = 'view_item') > 0         AS view_item,
    COUNTIF(event_name = 'add_to_cart') > 0       AS add_to_cart,
    COUNTIF(event_name = 'begin_checkout') > 0    AS begin_checkout,
    COUNTIF(event_name = 'add_shipping_info') > 0 AS add_shipping_info,
    COUNTIF(event_name = 'add_payment_info') > 0  AS add_payment_info,
    COUNTIF(event_name = 'purchase') > 0          AS purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY 1, 2
  HAVING session_id IS NOT NULL
),

steps AS (
  SELECT 1 AS step, 'session' AS event, COUNT(*) AS open_sessions, COUNT(*) AS closed_sessions FROM sessions
  UNION ALL
  SELECT 2, 'view_item', COUNTIF(view_item), COUNTIF(view_item) FROM sessions
  UNION ALL
  SELECT 3, 'add_to_cart', COUNTIF(add_to_cart),
    COUNTIF(view_item AND add_to_cart) FROM sessions
  UNION ALL
  SELECT 4, 'begin_checkout', COUNTIF(begin_checkout),
    COUNTIF(view_item AND add_to_cart AND begin_checkout) FROM sessions
  UNION ALL
  SELECT 5, 'add_shipping_info', COUNTIF(add_shipping_info),
    COUNTIF(view_item AND add_to_cart AND begin_checkout AND add_shipping_info) FROM sessions
  UNION ALL
  SELECT 6, 'add_payment_info', COUNTIF(add_payment_info),
    COUNTIF(view_item AND add_to_cart AND begin_checkout AND add_shipping_info AND add_payment_info) FROM sessions
  UNION ALL
  SELECT 7, 'purchase', COUNTIF(purchase),
    COUNTIF(view_item AND add_to_cart AND begin_checkout AND add_shipping_info AND add_payment_info AND purchase) FROM sessions
)

SELECT
  step,
  event,
  open_sessions,
  closed_sessions,
  ROUND(100 * closed_sessions / FIRST_VALUE(closed_sessions) OVER (ORDER BY step), 2) AS pct_of_sessions,
  ROUND(100 * closed_sessions / LAG(closed_sessions) OVER (ORDER BY step), 1) AS pct_of_prev_step,
  ROUND(100 - 100 * closed_sessions / LAG(closed_sessions) OVER (ORDER BY step), 1) AS drop_off_pct
FROM steps
ORDER BY step
