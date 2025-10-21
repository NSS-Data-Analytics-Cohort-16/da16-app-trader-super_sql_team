if price::numeric <= 1.00 then $10,000
if price::numeric > 1.00 then price * $10,000

SELECT * FROM app_store_apps
SELECT * FROM play_store_apps

 -- purchase price for apple store
 SELECT
 	name,
	price,
	CASE WHEN
		price::numeric <=1::numeric then 10000.0
		WHEN
		price::numeric >1:0::numeric then price::numeric * 10000.0
		ELSE '0'
	END AS pur_price
FROM app_store_apps

-- purchase price for play store table---------------------

SELECT
	name,
	price,
	CASE WHEN
		REPLACE(price, '$', '')::numerica <= 1.00::numeric then 10000.0
		WHEN
		REPLACE(price, '$', '')::numeric > 1.00::numeric then REPLACE(price, '$', '')::numeric * 10000.0
		ELSE '0'
	END AS pur_price
FROM play_store_apps

SELECT
	price,
	count(price)
FROM play_store_apps

SELECT
	price,
	count(price)
FROM play_store_apps
GROUP BY 1
ORDER BY 2 DESC

-----best way to link these tables----------

SELECT
	name
	count(name)
FROM app_store_apps
GROUP BY 1
HAVING count(name) > 1
ORDER BY 2 DESC
--only 2 duplicates on apple----

SELECT
	name
	count(name)
FROM play_store_apps
GROUP BY 1
HAVING count(name) > 1
ORDER BY 2 DESC
----lots of duplcates. Will aggregate on name

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
		ROUND((ROUND(rating * 2) / 2 * 2) + 1) AS expected_lifespan
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
ROUND((ROUND(rating * 2) / 2 * 2) + 1, 1) AS expected_lifespan
FROM app_store_apps)
ORDER BY price DESC, purchase_price DESC

---for total rojected income---------
Round(
(((Round(rating*2)/2)*2+1)*12*
(5000 *
	CASE
		WHEN name IN (
			SELECT name from app_store_appps
			INTERSECT
			SELECT NAME app_store_apps
		) THEN 2 ELSE 1
	END
)
)-
(((ROUND(rating*2)/2)*2+1)*12*1000)
2
) AS expected_revenue
	FROM app_store_apps)
ORDER BY price DESC, purchase_price DES

		)
