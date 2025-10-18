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
(SELECT name,
        REPLACE(price, '$','')::numeric AS price,
        'playstore' AS store,
        CASE
            WHEN REPLACE(price, '$', '')::numeric <= 1.00 THEN 10000.0
            WHEN REPLACE(price, '$', '')::numeric > 1.00 THEN REPLACE(price, '$', '')::numeric * 10000.0
            ELSE 0
        END AS purchase_price,
        CASE WHEN
            name IN (
                SELECT name FROM app_store_apps
                INTERSECT
                SELECT name FROM play_store_apps
            ) THEN 2 ELSE 1 END AS store_count,
        1000 AS cost_per_month,
		5000 * 
        CASE 
            WHEN name IN (
                SELECT name FROM app_store_apps
                INTERSECT
                SELECT name FROM play_store_apps
            ) THEN 2 ELSE 1 
        END AS income_per_month,
		ROUND(ROUND(rating * 2) / 2, 1) AS rounded_rating,
		ROUND((ROUND(rating * 2) / 2 * 2) + 1) AS expected_lifespan,
-- for a total projected income
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
--total net profit
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
	price,
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
		ROUND(ROUND(rating * 2) / 2, 1) 
		AS rounded_rating,
-----------for calculating the expected lifespan----
		ROUND((ROUND(rating * 2) / 2 * 2) + 1, 1) 
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
-------------end statement-------------------------
FROM app_store_apps
WHERE rating IS NOT NULL)
ORDER BY expected_net_profit DESC
LIMIT 25;

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

SELECT DISTINCT p.name,
	a.rating,
	a.review_count,
	a.price,
	p.rating,
	p.review_count,
	p.price
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON a.name = p.name
WHERE a.rating >4
	AND p.rating >4
ORDER BY p.rating -- this takes us down to 294 results

SELECT
    a.name AS app_name,
	a.price AS app_price,
	p.price AS play_price,
    ROUND((a.rating + p.rating) / 2.0, 2) AS avg_rating,
	a.review_count AS app_review_count,
	p.review_count AS play_review_count,
	 CASE
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
        ELSE 1
    END AS estimated_lifespan_years
FROM app_store_apps a
INNER JOIN play_store_apps p ON a.name = p.name
WHERE ROUND((a.rating + p.rating) / 2.0, 2) >= 4.0
ORDER BY avg_rating DESC

SELECT DISTINCT (genres),
	COUNT(name) AS total
FROM play_store_apps
GROUP BY genres 
ORDER BY total

SELECT DISTINCT (primary_genre),
	COUNT(name) AS total
FROM app_store_apps
GROUP BY primary_genre
ORDER BY total


-- lets dig in
SELECT
    a.name AS app_name,
	a.price AS app_price,
	p.price AS play_price,
    ROUND((a.rating + p.rating) / 2.0, 2) AS avg_rating,
	a.review_count AS app_review_count,
	p.review_count AS play_review_count,
	GREATEST(a.price::numeric, p.price::numeric) AS max_price,
    CASE
        WHEN GREATEST(a.price::numeric, p.price::numeric) <= 1 THEN 10000
        ELSE GREATEST(a.price::numeric, p.price::numeric) * 10000
    END AS purchase_cost,
    ROUND((a.rating + p.rating) / 2.0 * 2) / 2 AS avg_rating_rounded,
    CASE
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
        WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
        ELSE 1
    END AS lifespan_years,
	10000 * CASE
	    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
	    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
    	WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
    	ELSE 1
	END AS total_revenue,
	1000 * CASE
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.0 THEN 1
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 0.5 THEN 2
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.0 THEN 3
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 1.5 THEN 4
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.0 THEN 5
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 2.5 THEN 6
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.0 THEN 7
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 3.5 THEN 8
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.0 THEN 9
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 4.5 THEN 10
    WHEN ROUND((a.rating + p.rating) / 2.0 * 2) / 2 = 5.0 THEN 11
    ELSE 1
END AS total_marketing_cost,
	(10000 * lifespan_years) - (1000 * lifespan_years) - 
    CASE
        WHEN GREATEST(a.price::numeric, p.price::numeric) <= 1 THEN 10000
        ELSE GREATEST(a.price::numeric, p.price::numeric) * 10000
    END AS projected_profit
FROM app_store_apps a
INNER JOIN play_store_apps AS p ON a.name = p.name
WHERE
    (a.installs + p.installs) >= 100000
    AND ((a.rating + p.rating) / 2.0) >= 4.0
GROUP BY a.name
ORDER BY projected_profit DESC;