########################################## product-level [sales] analysis
/* We’re about to launch a new product, and I’d like to do a deep dive on our current flagship product.
Can you please pull monthly trends to date for number of sales, total revenue, and total margin generated for the 
business?  2013-01-04 */

SELECT
YEAR(DATE(created_at)),
MONTH(DATE(created_at)),
-- primary_product_id,
COUNT(order_id) AS number_of_sales,
SUM(price_usd) AS total_revenue,
SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY YEAR(DATE(created_at)), MONTH(DATE(created_at))
;

######################################## analyzing product launching
/* We launched our second product back on January 6th. Can you pull together some trended analysis? 
I’d like to see monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by 
product, all for the time period since April 1, 2012. */
SELECT
YEAR(DATE(ws.created_at)),
MONTH(DATE(ws.created_at)),
-- primary_product_id,
COUNT(order_id) AS orders,
-- COUNT(ws.website_session_id) AS sessions,
COUNT(order_id)/COUNT(ws.website_session_id) AS conv_rate,
-- SUM(price_usd) AS total_revenue,
SUM(price_usd)/COUNT(order_id) AS revenue_per_session,
-- SUM(price_usd - cogs_usd) AS total_margin
COUNT(CASE WHEN primary_product_id = 1 THEN 1 ELSE NULL END) AS product_one_orders,
COUNT(CASE WHEN primary_product_id = 2 THEN 1 ELSE NULL END) AS product_two_orders
FROM website_sessions ws 
LEFT JOIN orders o 
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2013-04-05'
AND ws.created_at > '2012-04-01'
GROUP BY YEAR(DATE(ws.created_at)), MONTH(DATE(ws.created_at))
;

###################################### product-level website pathing
/* 
