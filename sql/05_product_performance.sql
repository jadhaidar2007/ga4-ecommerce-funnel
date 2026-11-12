-- which products get looked at but not bought
-- counts are item-level events (one row per item in the items array)

SELECT
  i.item_name,
  ANY_VALUE(i.item_category) AS category,
  COUNTIF(event_name = 'view_item')   AS views,
  COUNTIF(event_name = 'add_to_cart') AS adds,
  SUM(IF(event_name = 'purchase', i.quantity, 0)) AS units_sold,
  ROUND(SUM(IF(event_name = 'purchase', i.item_revenue_in_usd, 0)), 0) AS revenue_usd,
  ROUND(100 * COUNTIF(event_name = 'add_to_cart') / NULLIF(COUNTIF(event_name = 'view_item'), 0), 1) AS view_to_cart_pct,
  ROUND(100 * COUNTIF(event_name = 'purchase') / NULLIF(COUNTIF(event_name = 'add_to_cart'), 0), 1) AS cart_to_purchase_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS i
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  AND event_name IN ('view_item', 'add_to_cart', 'purchase')
  AND i.item_name NOT IN ('(not set)', '')
GROUP BY i.item_name
HAVING views >= 2000
ORDER BY views DESC
LIMIT 25
