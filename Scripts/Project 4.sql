select *
from app_store_apps

 select *
 from play_store_apps
 

SELECT app_store_apps.name,
  MAX(price) AS max_price,
  10000.0 * GREATEST(1.0, MAX(price)):: money AS purchase_price
FROM app_store_apps
GROUP BY app_store_apps.name
ORDER BY purchase_price DESC;


SELECT play_store_apps.name,
  MAX(price) AS max_price
FROM play_store_apps
GROUP BY play_store_apps.name
ORDER BY max_price

Select Play_store_apps.genres as pl_genres, 
	   review_count as rv_count 
FROM Play_store_apps
group by pl_genres,
          rv_count
order by rv_count desc


select price, rating, review_count, name
from app_store_apps
order by rating desc









