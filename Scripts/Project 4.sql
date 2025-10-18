-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. 
--For apps that are priced from free up to $1.00, the purchase price is $10,000.

select *
from app_store_apps
select *
from play_store_apps


SELECT
    name AS app_name,
    GREATEST(
        COALESCE(NULLIF(REGEXP_REPLACE(TRIM(price), '[$,]', '', 'g'), '')::numeric, 0),
        1
    ) * 10000 AS purchase_price
FROM play_store_apps
ORDER BY purchase_price DESC;
    
-- - For example, an app that costs $2.00 will be purchased for $20,000.

select
    'Example App' AS app_name,
     2 AS price,
    GREATEST(2, 1) * 10000 AS purchase_price;

-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 


SELECT app_store_apps.name,
  price AS max_price,
  10000.0 * GREATEST(1.0, price):: money AS purchase_price
FROM app_store_apps
GROUP BY app_store_apps.name, price
ORDER BY purchase_price DESC
LIMIT 20

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 


SELECT
    COALESCE(a.name, p.name) AS app_name,
    (COALESCE(a.name IS NOT NULL, FALSE)::int +
     COALESCE(p.name IS NOT NULL, FALSE)::int) * 5000 AS monthly_revenue
FROM app_store_apps AS a
FULL OUTER JOIN play_store_apps AS p
USING (name)
ORDER BY monthly_revenue DESC;

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

SELECT
    COALESCE(a.name, p.name) AS app_name,
    1000 AS monthly_marketing_cost
FROM app_store_apps AS a
FULL OUTER JOIN play_store_apps AS p
USING (name)
ORDER BY app_name;

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.

SELECT 
  name as app_name,
GREATEST(app_store_apps.price, 1) * 10000 AS purchase_price,
  CASE 
    WHEN app_store_apps AND play_store_apps THEN 10000
    ELSE 5000
  END AS monthly_revenue,
  1000 AS monthly_marketing_cost
  FROM app_store_apps
inner join play_store_apps
using(name)


SELECT play_store_apps.name,
  MAX(price) AS max_price
FROM play_store_apps
GROUP BY play_store_apps.name
ORDER BY max_price


Select Play_store_apps.genres as pl_genres,
       name as app_name,
	   Play_store_apps.review_count as rv_count 
FROM Play_store_apps
left join app_store_apps
using(name)
group by pl_genres,
          rv_count,
		  name
order by rv_count desc


select price, rating, review_count, name
from app_store_apps
order by rating desc


SELECT 
    a.name,
    a.primary_genre,
    ROUND(a.rating, 2) AS app_store_rating,
    ROUND(p.rating, 2) AS play_store_rating
FROM app_store_apps AS a
LEFT JOIN play_store_apps AS p
USING (name)
WHERE p.rating IS NOT NULL
ORDER BY a.name DESC;

select name as g_name, 
	   app_store_apps.price as price_list,
	   primary_genre as p_genre,
	   genres as a_genre
from play_store_apps
left join app_store_apps
using(name)
where app_store_apps.price is not null
and primary_genre is not null
order by name desc


SELECT
    COALESCE(a.name::text, p.name::text) AS app_name,
    CASE
        WHEN a.name IS NOT NULL AND p.name IS NOT NULL THEN 10000
        ELSE 5000
    END AS monthly_revenue
FROM app_store_apps AS a
FULL OUTER JOIN play_store_apps AS p
USING (name);


SELECT
    COALESCE(a.name::text, p.name::text) AS app_name,
    CASE
        WHEN a.name IS NOT NULL AND p.name IS NOT NULL THEN 10000
        ELSE 5000
    END AS monthly_revenue,
    1000 AS monthly_marketing_cost
FROM app_store_apps AS a
FULL OUTER JOIN play_store_apps AS p
USING (name);


SELECT
    COALESCE(a.name::text, p.name::text) AS app_name,
    1 + (2 * ROUND(
        COALESCE((a.rating + p.rating)/2, a.rating, p.rating) * 2
    ) / 2) AS projected_lifespan_years
FROM app_store_apps AS a
FULL OUTER JOIN play_store_apps AS p
USING (name);



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
) AS expected_revenue
		FROM play_store_apps)
UNION
(SELECT name,
price,
'appstore' AS store,
CASE
WHEN price <=1.00 THEN 10000.0
WHEN price >1.00 THEN price * 10000.0
ELSE '0'
END AS purchase_price,
CASE WHEN
name IN (
SELECT 
name
FROM app_store_apps
INTERSECT
SELECT
name
FROM play_store_apps)
THEN 2
ELSE 1
END AS store_count,
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
ROUND((ROUND(rating * 2) / 2 * 2) + 1, 1) AS expected_lifespan,
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
) AS expected_revenue
FROM app_store_apps)
ORDER BY price DESC, purchase_price DESC

-- ______________________________________________________________________________________________________

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

-- ______________________________________________________.

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
LIMIT 10;



