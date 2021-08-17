/* task1: First, I’d like to show our (volume growth). 
Can you pull overall session and order volume, 
trended by quarter for the life of the business? 
Since the most recent quarter is incomplete, you can decide how to handle it */

SELECT 
YEAR(ws.created_at),
QUARTER(ws.created_at),
COUNT(DISTINCT ws.website_session_id) AS sessions,
COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) < '2015'
GROUP BY YEAR(ws.created_at), QUARTER(ws.created_at)
;



/* task2: Next, let’s showcase all of our (efficiency improvements). 
I would love to show quarterly figures since we 
launched, for session-to-order conversion rate, revenue per order, and revenue per session */
SELECT 
YEAR(ws.created_at),
QUARTER(ws.created_at),
COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt,
SUM(o.price_usd)/COUNT(o.order_id) AS revenue_per_order,
SUM(o.price_usd)/COUNT(ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) < '2015'
GROUP BY YEAR(ws.created_at), QUARTER(ws.created_at)
;


/* task3: I’d like to show (how we’ve grown specific channels). 
Could you pull a quarterly view of orders 
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in? */


SELECT
YEAR(ws.created_at) AS yr,
QUARTER(ws.created_at) AS qtr,
COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' AND utm_source = 'gsearch' THEN o.order_id ELSE NULL END) AS gsearch_nonbrand,
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' AND utm_source = 'bsearch' THEN o.order_id ELSE NULL END) AS bsearch_nonbrand,
COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_search,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
		 THEN o.order_id ELSE NULL END) AS organic_search,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN o.order_id ELSE NULL END) AS direct_type_in
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) < '2015'
GROUP BY YEAR(ws.created_at), QUARTER(ws.created_at)
;


/* task4: Next, let’s show the (overall session-to-order conversion rate trends) for those same channels, by quarter. 
Please also make a note of any periods where we made major improvements or optimizations */

SELECT
YEAR(ws.created_at) AS yr,
QUARTER(ws.created_at) AS qtr,
-- COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' AND utm_source = 'gsearch' THEN o.order_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' AND utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt,
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' AND utm_source = 'bsearch' THEN o.order_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' AND utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rt,
COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_search_conv_rt,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
		 THEN o.order_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
		 THEN ws.website_session_id ELSE NULL END) AS organic_search_conv_rt,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN o.order_id ELSE NULL END)/
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_type_in_conv_rt
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) < '2015'
GROUP BY YEAR(ws.created_at), QUARTER(ws.created_at)
;



/* task5: we’ve come a long way since the days of selling a single product. 
Let’s pull monthly trending for revenue and margin by product, along with total sales and revenue. 
Note anything you notice about seasonality. */
SELECT
YEAR(created_at), 
MONTH(created_at),
SUM(price_usd) AS total_revenue,
SUM(price_usd - cogs_usd) AS total_margin,
SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS product1_revenue,
SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS product1_margin,
SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS product2_revenue,
SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS product2_margin,
SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS product3_revenue,
SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS product3_margin,
SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS product4_revenue,
SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS product4_margin
FROM order_items
GROUP BY YEAR(created_at), MONTH(created_at)
;



/* task6: Let’s dive deeper into the impact of introducing new products. 
Please pull monthly sessions to the /products page, and show how the % of those sessions 
clicking through another page has changed over time, along with 
a view of how conversion from /products to placing an order has improved. */

CREATE TEMPORARY TABLE product_page
SELECT
created_at,
website_session_id
FROM website_pageviews
WHERE pageview_url = '/products'
;

SELECT
YEAR(p.created_at) AS yr,
MONTH(p.created_at) AS mth,
COUNT(DISTINCT p.website_session_id) AS product_sessions,
COUNT(DISTINCT wp.website_session_id)/COUNT(DISTINCT p.website_session_id) AS click_rt,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT p.website_session_id) AS conv_rt
FROM product_page p
LEFT JOIN website_pageviews wp
ON p.website_session_id = wp.website_session_id
AND p.created_at < wp.created_at
LEFT JOIN orders
ON orders.website_session_id = p.website_session_id
GROUP BY yr, mth
;

/* task7: We made our 4th product available as a primary product on December 05, 2014 
(it was previously only a cross-sell item). 
Could you please pull sales data since then, 
and show how well each product cross-sells from one another? */

CREATE TEMPORARY TABLE cross_sells
SELECT
o.order_id,
o.primary_product_id,
oi.product_id AS cross_sell_product
FROM orders o
LEFT JOIN order_items oi
ON o.order_id = oi.order_id
AND oi.is_primary_item = 0
WHERE o.created_at > '2014-12-05'
;



SELECT
primary_product_id, 
COUNT(DISTINCT order_id) AS orders,
COUNT(DISTINCT CASE WHEN cross_sell_product = 1 THEN order_id ELSE NULL END) AS product1_cross_sell,
COUNT(DISTINCT CASE WHEN cross_sell_product = 2 THEN order_id ELSE NULL END) AS product2_cross_sell,
COUNT(DISTINCT CASE WHEN cross_sell_product = 3 THEN order_id ELSE NULL END) AS product3_cross_sell,
COUNT(DISTINCT CASE WHEN cross_sell_product = 4 THEN order_id ELSE NULL END) AS product4_cross_sell,
COUNT(DISTINCT CASE WHEN cross_sell_product = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS product1_cross_sell_rt,
COUNT(DISTINCT CASE WHEN cross_sell_product = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS product2_cross_sell_rt,
COUNT(DISTINCT CASE WHEN cross_sell_product = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS product3_cross_sell_rt,
COUNT(DISTINCT CASE WHEN cross_sell_product = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS product4_cross_sell_rt
FROM cross_sells
GROUP BY primary_product_id
ORDER BY primary_product_id
;

/* product1 sells best and it cross sells best with product 4.
   product2 cross sells best with product 4.
   product3 cross sells best with product 4. 
   it seems like product 4 is really a popular product, and worth to launch it as an independent product. */
   
   
   























