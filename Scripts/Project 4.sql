select *
from app_store_apps

 select *
 from play_store_apps
 

SELECT app_store_apps.name,
  MAX(price) AS max_price,
  10000.0 * GREATEST(1.0, MAX(price)) AS purchase_price
FROM app_store_apps
GROUP BY app_store_apps.name
ORDER BY purchase_price DESC;


SELECT play_store_apps.name,
  MAX(price) AS max_price
FROM play_store_apps
GROUP BY play_store_apps.name
ORDER BY max_price
