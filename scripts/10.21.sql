WITH playstore_clean AS (
  SELECT
    name,
    MAX(REPLACE(price, '$','')::numeric) AS price,
    MAX(rating) AS rating,
    MAX(review_count::integer) AS review_count,
    MAX(content_rating) AS content_rating
  FROM play_store_apps
  WHERE rating IS NOT NULL
  GROUP BY name),
-- Cleans app store data by aggregating the duplicates and taking the max values
appstore_clean AS (
  SELECT
    name,
    MAX(price) AS price,
    MAX(rating) AS rating,
    MAX(review_count::integer) AS review_count,
    MAX(content_rating) AS content_rating
  FROM app_store_apps
  WHERE rating IS NOT NULL
  GROUP BY name),
-- Calculates the rounded average ratings from both stores to nearest .5
avg_ratings AS (
  SELECT name,
         ROUND(ROUND(AVG(rating) * 2) / 2, 1) AS rounded_rating
  FROM (
    SELECT name, rating FROM playstore_clean
    UNION ALL
    SELECT name, rating FROM appstore_clean
  ) AS all_ratings
  GROUP BY name)
-- Final select query, picks the app name from either store (whichever is not null).
SELECT
  COALESCE(p.name, a.name) AS name,
-- Shows price from each store and creates a unified price per app
  p.price AS playstore_price,
  a.price AS appstore_price,
  GREATEST(p.price, a.price) AS price,
-- Shows ratings from each store and the calculated average.
  p.rating AS playstore_rating,
  a.rating AS appstore_rating,
  ar.rounded_rating,
-- Shows id the app is in both stores or just one
  CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END AS store_count,
-- Shows estimated fixed monthly cost and income per store.
  1000 AS cost_per_month,
  5000 * CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END AS income_per_month,
-- Calculates the expected lifespan of the app
  ROUND((ar.rounded_rating * 2) + 1) AS expected_lifespan,
-- Calculates the expected net revenue over the lifespan of the app, then subtracts the cost
  ROUND(
    ((ar.rounded_rating * 2 + 1) * 12 * (5000 * CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END))
    - ((ar.rounded_rating * 2 + 1) * 12 * 1000),
    2
  ) AS expected_net_revenue,
-- Calculates the expected net proffit of the apps by taking the net revenue then subtracting the purchase price
  ROUND(
    (
      ((ar.rounded_rating * 2 + 1) * 12 * (5000 * CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END))
      - ((ar.rounded_rating * 2 + 1) * 12 * 1000)
    )
    - CASE
        WHEN GREATEST(p.price, a.price) <= 1.00 THEN 10000.0
        ELSE GREATEST(p.price, a.price) * 10000.0
      END,
    2
  ) AS expected_net_profit
-- End statement
FROM playstore_clean p
FULL OUTER JOIN appstore_clean a ON p.name = a.name
LEFT JOIN avg_ratings ar ON COALESCE(p.name, a.name) = ar.name
ORDER BY expected_net_profit DESC
LIMIT 25;
