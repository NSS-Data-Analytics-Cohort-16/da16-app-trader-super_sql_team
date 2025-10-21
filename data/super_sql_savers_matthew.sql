-- ### App Trader

-- Your team has been hired by a new company called App Trader to help them explore and gain insights
-- from apps that are made available through the Apple App Store and Android Play Store. App Trader is a
-- broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase. 

-- Unfortunately, the data for Apple App Store apps and Android Play Store Apps is located in separate tables 
-- with no referential integrity.

-- #### 1. Loading the data
-- a. Launch PgAdmin and create a new database called app_trader.  
-- b. Right-click on the app_trader database and choose `Restore...`  
-- c. Use the default values under the `Restore Options` tab. 
-- d. In the `Filename` section, browse to the backup file `app_store_backup.backup` in the data folder of 
-- this repository.  
-- e. Click `Restore` to load the database.  
-- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  
--     - `play_store_apps` with 10840 rows

SELECT *
FROM app_store_apps

SELECT *
FROM play_store_apps

SELECT *
FROM app_store_apps
ORDER BY price DESC

SELECT *
FROM play_store_apps
ORDER BY price_num desc

SELECT *
FROM play_store_apps
WHERE price != '0'
ORDER BY price DESC;

-- #### 2. Assumptions

-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free
-- up to $1.00, the purchase price is $10,000.
-- - For example, an app that costs $2.00 will be purchased for $20,000.
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will
-- cost the same as a $1.00 app on both stores. 
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between
-- the two stores. 

--cleans and aggregates the play store data (cleans price by removing $, removes duplicates by taking the max values, filters out apps with NULL ratings)
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
LIMIT 15;

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless
-- of the price of the app.
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 
-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If 
-- App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of 
-- $1000 per month.
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless
-- of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other 
-- words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be 
-- expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding
-- to the nearest 0.5.

-------------------------------------------------------------------------------
---------for the rounded average rating----------
WITH avg_ratings AS (
  SELECT name,
         ROUND(ROUND(AVG(rating) * 2) / 2, 1) AS rounded_rating
  FROM (
    SELECT name, rating FROM play_store_apps WHERE rating IS NOT NULL
    UNION ALL
    SELECT name, rating FROM app_store_apps WHERE rating IS NOT NULL
  ) AS all_ratings
  GROUP BY name), 
combined_apps AS (
-------------------union query--------------------
(SELECT name,
        REPLACE(price, '$','')::numeric AS price, -- for the combined price column
		REPLACE(price, '$','')::numeric AS playstore_price, --for the appstore price
  (SELECT price
  FROM app_store_apps
  WHERE app_store_apps.name = play_store_apps.name
  LIMIT 1)
  AS appstore_price,
        'playstore' AS store,
---------for how much App Trader has to pay to buy each app---------
        CASE
            WHEN REPLACE(price, '$', '')::numeric <= 1.00 THEN 10000.0
            WHEN REPLACE(price, '$', '')::numeric > 1.00 THEN REPLACE(price, '$', '')::numeric * 10000.0
            ELSE 0
        END AS purchase_price,
---------for what store(s) the apps are on__________
        CASE WHEN
            name IN (
                SELECT name FROM app_store_apps
                INTERSECT
                SELECT name FROM play_store_apps
            ) THEN 2 ELSE 1 END AS store_count,
        1000 AS cost_per_month,
		5000 * 
---------for how many stores each app is on---------
        CASE WHEN name IN (
                SELECT name FROM app_store_apps
                INTERSECT
                SELECT name FROM play_store_apps
            ) THEN 2 ELSE 1 
        END AS income_per_month,
---------- for rounding the rating column-----------
		ROUND(ROUND(rating * 2) / 2, 1) AS rounded_rating,
-----------for calculating the expected lifespan----
		ROUND((ROUND(rating * 2) / 2 * 2) + 1) AS expected_lifespan,
-----------for a total exoected net revenue-------------
		ROUND(
    (((ROUND(rating * 2) / 2) * 2 + 1) * 12 *
        (5000 * 
            CASE 
                WHEN name IN (
                    SELECT name FROM app_store_apps
                    INTERSECT
                    SELECT name FROM play_store_apps
                ) THEN 2 ELSE 1 
            END
		)
	) -
    (((ROUND(rating * 2) / 2) * 2 + 1) * 12 * 1000),
    2
) AS expected_net_revenue,
---------------total expected net profit--------------------
ROUND((
        (((ROUND(rating * 2) / 2) * 2 + 1) * 12 *
            (5000 * 
                CASE 
                    WHEN name IN (
                        SELECT name FROM app_store_apps
                        INTERSECT
                        SELECT name FROM play_store_apps
                    ) THEN 2 ELSE 1 
                END
            )
        ) -
        (((ROUND(rating * 2) / 2) * 2 + 1) * 12 * 1000)
    ) -
    CASE
            WHEN REPLACE(price, '$', '')::numeric <= 1.00 THEN 10000.0
            WHEN REPLACE(price, '$', '')::numeric > 1.00 THEN REPLACE(price, '$', '')::numeric * 10000.0
            ELSE 0
    END,
    2
) AS expected_net_profit
FROM play_store_apps
WHERE rating IS NOT NULL)
-------------------------------------------
UNION
-------------------------------------------
(SELECT name,
	price AS price, -- for the price column
	price AS appstore_price, --for playstore price
(SELECT REPLACE(price, '$','')::numeric
  FROM play_store_apps
  WHERE play_store_apps.name = app_store_apps.name
  LIMIT 1)
  AS playstore_price,
	'appstore' AS store,
---------for how much App Trader has to pay to buy each app---------
	CASE
		WHEN price <=1.00 THEN 10000.0
		WHEN price >1.00 THEN price * 10000.0
		ELSE '0'
		END AS purchase_price,
---------for what store(s) the apps are on__________
		CASE WHEN
		name IN (
			SELECT 
				name
			FROM app_store_apps
---------for how many stores each app is on---------
			INTERSECT
			SELECT
				name
			FROM play_store_apps)
		THEN 2
		ELSE 1
		END AS store_count,
----------for expenses per month--------------------
		1000 AS cost_per_month,
---------for income per month-----------------------
		5000 * 
        CASE 
            WHEN name IN (
                SELECT name FROM app_store_apps
                INTERSECT
                SELECT name FROM play_store_apps
            ) THEN 2 ELSE 1 
        END AS income_per_month,
---------- for rounding the rating column-----------
		ROUND(ROUND(rating * 2) / 2, 1) AS rounded_rating,
-----------for calculating the expected lifespan----
		ROUND((ROUND(rating * 2) / 2 * 2) + 1) 
		AS expected_lifespan,
-----------for a total projected net revenue--------
		ROUND(
    (((ROUND(rating * 2) / 2) * 2 + 1) * 12 *
        (5000 * 
            CASE 
                WHEN name IN (
                    SELECT name FROM app_store_apps
                    INTERSECT
                    SELECT name FROM play_store_apps
                ) THEN 2 ELSE 1 
            END
        )
    ) -
    (((ROUND(rating * 2) / 2) * 2 + 1) * 12 * 1000),
    2
) AS expected_net_revenue,
----------for a total net profit (repeat net profit - the purchase price)
ROUND((
        (((ROUND(rating * 2) / 2) * 2 + 1) * 12 *
            (5000 * 
                CASE 
                    WHEN name IN (
                        SELECT name FROM app_store_apps
                        INTERSECT
                        SELECT name FROM play_store_apps
                    ) THEN 2 ELSE 1 
                END
            )
        ) -
        (((ROUND(rating * 2) / 2) * 2 + 1) * 12 * 1000)
    ) -
	CASE
	  WHEN price <= 1.00 THEN 10000.0
	  WHEN price > 1.00 THEN price * 10000.0
	  ELSE 0
    END,
    2
) AS expected_net_profit
FROM app_store_apps
WHERE rating IS NOT NULL)
-------------end statement-------------------------
)SELECT ca.*,
       ar.rounded_rating
FROM combined_apps ca
JOIN avg_ratings ar ON ca.name = ar.name
ORDER BY expected_net_profit DESC
LIMIT 25;

------------------------------------------
-- SELECT *
-- FROM app_store_apps
-- --WHERE review_count >1000
-- ORDER BY rating DESC

-- SELECT *
-- FROM play_store_apps
-- WHERE rating IS NOT NULL
-- 	AND review_count >1000
-- ORDER BY rating DESC
------------------------------------------


-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since 
-- they can market both for the same $1000 per month.

-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for 
-- apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may 
-- export query results to create charts in Excel for your report. 




-- --query I tried but was running into errors
-- WITH app_metrics AS (
--     SELECT
--         a.name AS app_name,
-- 		GREATEST(
-- 		    REGEXP_REPLACE(TRIM(a.price), '[$]', '', 'g')::numeric,
-- 		    REGEXP_REPLACE(TRIM(p.price), '[$]', '', 'g')::numeric)
-- 		AS max_price,
--         a.rating AS app_rating,
--         p.rating AS play_rating,
--         a.review_count AS app_review_count,
--         p.review_count AS play_review_count,
--         ROUND((a.rating + p.rating) / 2.0, 2) AS avg_rating,
--         ROUND((a.rating + p.rating) / 2.0 * 2) / 2 AS avg_rating_rounded,
--         GREATEST(a.price::numeric, p.price::numeric) AS max_price
--     FROM app_store_apps a
--     INNER JOIN play_store_apps p ON a.name = p.name
--     WHERE ((a.rating + p.rating) / 2.0) >= 4.0)
-- SELECT
--     app_name,
--     app_price,
--     play_price,
--     app_review_count,
--     play_review_count,
--     avg_rating,
--     avg_rating_rounded,
--     max_price,
--     -- Purchase cost
--     CASE
--         WHEN max_price <= 1 THEN 10000
--         ELSE max_price * 10000
--     END AS purchase_cost,
--     -- Lifespan
--     CASE
--         WHEN avg_rating_rounded = 0.0 THEN 1
--         WHEN avg_rating_rounded = 0.5 THEN 2
--         WHEN avg_rating_rounded = 1.0 THEN 3
--         WHEN avg_rating_rounded = 1.5 THEN 4
--         WHEN avg_rating_rounded = 2.0 THEN 5
--         WHEN avg_rating_rounded = 2.5 THEN 6
--         WHEN avg_rating_rounded = 3.0 THEN 7
--         WHEN avg_rating_rounded = 3.5 THEN 8
--         WHEN avg_rating_rounded = 4.0 THEN 9
--         WHEN avg_rating_rounded = 4.5 THEN 10
--         WHEN avg_rating_rounded = 5.0 THEN 11
--         ELSE '0'
--     END AS lifespan_years,
--     -- Revenue
--     10000 * CASE
--         WHEN avg_rating_rounded = 0.0 THEN 1
--         WHEN avg_rating_rounded = 0.5 THEN 2
--         WHEN avg_rating_rounded = 1.0 THEN 3
--         WHEN avg_rating_rounded = 1.5 THEN 4
--         WHEN avg_rating_rounded = 2.0 THEN 5
--         WHEN avg_rating_rounded = 2.5 THEN 6
--         WHEN avg_rating_rounded = 3.0 THEN 7
--         WHEN avg_rating_rounded = 3.5 THEN 8
--         WHEN avg_rating_rounded = 4.0 THEN 9
--         WHEN avg_rating_rounded = 4.5 THEN 10
--         WHEN avg_rating_rounded = 5.0 THEN 11
--         ELSE 1
--     END AS total_revenue,
--     -- Marketing cost
--     1000 * CASE
--         WHEN avg_rating_rounded = 0.0 THEN 1
--         WHEN avg_rating_rounded = 0.5 THEN 2
--         WHEN avg_rating_rounded = 1.0 THEN 3
--         WHEN avg_rating_rounded = 1.5 THEN 4
--         WHEN avg_rating_rounded = 2.0 THEN 5
--         WHEN avg_rating_rounded = 2.5 THEN 6
--         WHEN avg_rating_rounded = 3.0 THEN 7
--         WHEN avg_rating_rounded = 3.5 THEN 8
--         WHEN avg_rating_rounded = 4.0 THEN 9
--         WHEN avg_rating_rounded = 4.5 THEN 10
--         WHEN avg_rating_rounded = 5.0 THEN 11
--         ELSE 1
--     END AS total_marketing_cost,
--     -- Projected profit
--     (10000 * CASE
--             WHEN avg_rating_rounded = 0.0 THEN 1
--             WHEN avg_rating_rounded = 0.5 THEN 2
--             WHEN avg_rating_rounded = 1.0 THEN 3
--             WHEN avg_rating_rounded = 1.5 THEN 4
--             WHEN avg_rating_rounded = 2.0 THEN 5
--             WHEN avg_rating_rounded = 2.5 THEN 6
--             WHEN avg_rating_rounded = 3.0 THEN 7
--             WHEN avg_rating_rounded = 3.5 THEN 8
--             WHEN avg_rating_rounded = 4.0 THEN 9
--             WHEN avg_rating_rounded = 4.5 THEN 10
--             WHEN avg_rating_rounded = 5.0 THEN 11
--             ELSE 1
--         END
--         - 1000 * CASE
--             WHEN avg_rating_rounded = 0.0 THEN 1
--             WHEN avg_rating_rounded = 0.5 THEN 2
--             WHEN avg_rating_rounded = 1.0 THEN 3
--             WHEN avg_rating_rounded = 1.5 THEN 4
--             WHEN avg_rating_rounded = 2.0 THEN 5
--             WHEN avg_rating_rounded = 2.5 THEN 6
--             WHEN avg_rating_rounded = 3.0 THEN 7
--             WHEN avg_rating_rounded = 3.5 THEN 8
--             WHEN avg_rating_rounded = 4.0 THEN 9
--             WHEN avg_rating_rounded = 4.5 THEN 10
--             WHEN avg_rating_rounded = 5.0 THEN 11
--             ELSE 1
--         END
--         - CASE
--             WHEN max_price <= 1 THEN 10000
--             ELSE max_price * 10000
--         END
--     ) AS projected_profit
-- --ending
-- FROM app_metrics
-- ORDER BY projected_profit DESC
-- LIMIT 50;

-- SELECT DISTINCT p.name,
-- 	a.rating,
-- 	a.review_count,
-- 	a.price,
-- 	p.rating,
-- 	p.review_count,
-- 	p.price
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- 	ON a.name = p.name
-- WHERE a.rating >4
-- 	AND p.rating >4
-- ORDER BY p.rating -- this takes us down to 294 results

-- SELECT
--     a.name AS app_name,
-- 	a.price AS app_price,
-- 	p.price AS play_price,
--     ROUND((a.rating + p.rating) / 2.0, 2) AS avg_rating,
-- 	a.review_count AS app_review_count,
-- 	p.review_count AS play_review_count,
-- 	 CASE
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
--         ELSE 1
--     END AS estimated_lifespan_years
-- FROM app_store_apps a
-- INNER JOIN play_store_apps p ON a.name = p.name
-- WHERE ROUND((a.rating + p.rating) / 2.0, 2) >= 4.0
-- ORDER BY avg_rating DESC

-- SELECT DISTINCT (genres),
-- 	COUNT(name) AS total
-- FROM play_store_apps
-- GROUP BY genres 
-- ORDER BY total

-- SELECT DISTINCT (primary_genre),
-- 	COUNT(name) AS total
-- FROM app_store_apps
-- GROUP BY primary_genre
-- ORDER BY total


-- -- lets dig in
-- SELECT
--     a.name AS app_name,
-- 	a.price AS app_price,
-- 	p.price AS play_price,
--     ROUND((a.rating + p.rating) / 2.0, 2) AS avg_rating,
-- 	a.review_count AS app_review_count,
-- 	p.review_count AS play_review_count,
-- 	GREATEST(a.price::numeric, p.price::numeric) AS max_price,
--     CASE
--         WHEN GREATEST(a.price::numeric, p.price::numeric) <= 1 THEN 10000
--         ELSE GREATEST(a.price::numeric, p.price::numeric) * 10000
--     END AS purchase_cost,
--     ROUND((a.rating + p.rating) / 2.0 * 2) / 2 AS avg_rating_rounded,
--     CASE
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
--         WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
--         ELSE 1
--     END AS lifespan_years,
-- 	10000 * CASE
-- 	    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
-- 	    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
--     	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
--     	ELSE 1
-- 	END AS total_revenue,
-- 	1000 * CASE
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
--     WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
--     ELSE 1
-- END AS total_marketing_cost,
-- 	(10000 * lifespan_years) - (1000 * lifespan_years) - 
--     CASE
--         WHEN GREATEST(a.price::numeric, p.price::numeric) <= 1 THEN 10000
--         ELSE GREATEST(a.price::numeric, p.price::numeric) * 10000
--     END AS projected_profit
-- FROM app_store_apps a
-- INNER JOIN play_store_apps AS p ON a.name = p.name
-- WHERE
--     (a.installs + p.installs) >= 100000
--     AND ((a.rating + p.rating) / 2.0) >= 4.0
-- GROUP BY a.name
-- ORDER BY projected_profit DESC;



-- WITH avg_ratings AS (
--   SELECT name,
--          ROUND(ROUND(AVG(rating) * 2) / 2, 1) AS rounded_rating
--   FROM (
--     SELECT name, rating FROM play_store_apps WHERE rating IS NOT NULL
--     UNION ALL
--     SELECT name, rating FROM app_store_apps WHERE rating IS NOT NULL
--   ) AS all_ratings
--   GROUP BY name)
-- SELECT
--   p.name,
--   MAX(REPLACE(p.price, '$','')::numeric) AS playstore_price,
--   MAX(a.price) AS appstore_price,
--   COALESCE(REPLACE(p.price, '$','')::numeric, 0) AS price, -- unified price
--   'playstore' AS store,
--   CASE
--     WHEN a.name IS NOT NULL THEN 2 ELSE 1
--   END AS store_count,
--   1000 AS cost_per_month,
--   5000 * CASE WHEN a.name IS NOT NULL THEN 2 ELSE 1 END AS income_per_month,
--   ROUND(ROUND(p.rating * 2) / 2, 1) AS rounded_rating,
--   ROUND((ROUND(p.rating * 2) / 2 * 2) + 1) AS expected_lifespan,
--   ROUND(
--     (((ROUND(p.rating * 2) / 2) * 2 + 1) * 12 * (5000 * CASE WHEN a.name IS NOT NULL THEN 2 ELSE 1 END))
--     - (((ROUND(p.rating * 2) / 2) * 2 + 1) * 12 * 1000),
--     2
--   ) AS expected_net_revenue,
--   ROUND(
--     (
--       (((ROUND(p.rating * 2) / 2) * 2 + 1) * 12 * (5000 * CASE WHEN a.name IS NOT NULL THEN 2 ELSE 1 END))
--       - (((ROUND(p.rating * 2) / 2) * 2 + 1) * 12 * 1000)
--     )
--     - CASE
--         WHEN REPLACE(p.price, '$','')::numeric <= 1.00 THEN 10000.0
--         ELSE REPLACE(p.price, '$','')::numeric * 10000.0
--       END,
--     2
--   ) AS expected_net_profit,
--   ar.rounded_rating
-- FROM play_store_apps AS p
-- LEFT JOIN app_store_apps AS a ON p.name = a.name
-- JOIN avg_ratings ar ON p.name = ar.name
-- WHERE p.rating IS NOT NULL
--   AND p.content_rating NOT IN ('17+', 'Unrated')
--   AND (a.content_rating NOT IN ('17+', 'Unrated') OR a.content_rating IS NULL)
-- GROUP BY p.name, 
-- ORDER BY expected_net_profit DESC
-- LIMIT 25;

WITH ranked_apps AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY name ORDER BY expected_net_profit DESC) AS rn
  FROM (SELECT
  COALESCE(p.name, a.name) AS name,
  -- Normalize prices
  REPLACE(p.price, '$', '')::numeric AS play_price,
  a.price AS app_price,
  -- Highest price across both stores
  GREATEST(
    COALESCE(REPLACE(p.price, '$', '')::numeric, 0),
    COALESCE(a.price, 0)
  ) AS highest_price,
  -- Store count
  CASE
    WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2
    ELSE 1
  END AS store_count,
  -- Rounded average rating
  ROUND(ROUND((COALESCE(p.rating, a.rating)) * 2) / 2, 1) AS rounded_rating,
  -- Expected lifespan
  ROUND((ROUND(COALESCE(p.rating, a.rating) * 2) / 2 * 2) + 1, 1) AS expected_lifespan,
  -- Monthly income and cost
  5000 * CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END AS income_per_month,
  1000 AS cost_per_month,
  -- Expected net revenue
  ROUND(
    (
      ((ROUND(COALESCE(p.rating, a.rating) * 2) / 2 * 2) + 1) * 12 *
      (5000 * CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END)
    ) -
    ((ROUND(COALESCE(p.rating, a.rating) * 2) / 2 * 2) + 1) * 12 * 1000,
    2
  ) AS expected_net_revenue,
  -- Expected net profit (revenue - purchase price)
  ROUND(
    (
      ((ROUND(COALESCE(p.rating, a.rating) * 2) / 2 * 2) + 1) * 12 *
      (5000 * CASE WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 2 ELSE 1 END)
    ) -
    ((ROUND(COALESCE(p.rating, a.rating) * 2) / 2 * 2) + 1) * 12 * 1000
    -
    CASE
      WHEN GREATEST(
        COALESCE(REPLACE(p.price, '$', '')::numeric, 0),
        COALESCE(a.price, 0)
      ) <= 1.00 THEN 10000.0
      ELSE GREATEST(
        COALESCE(REPLACE(p.price, '$', '')::numeric, 0),
        COALESCE(a.price, 0)
      ) * 10000.0
    END,
    2
  ) AS expected_net_profit
  -- end query statement
FROM play_store_apps AS p
FULL OUTER JOIN app_store_apps AS a ON p.name = a.name
WHERE COALESCE(p.rating, a.rating) IS NOT NULL
	) AS base
)SELECT *
FROM ranked_apps
WHERE rn = 1
ORDER BY expected_net_profit DESC
LIMIT 25;