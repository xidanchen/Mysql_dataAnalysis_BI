## SET GLOBAL max_allowed_packet = 10737418240;
## DROP DATABASE mavenfuzzyfactory;


############################Analyzing traffic sources############################
## website_pageviews, website_sessions, orders
-- utm traking parameters used to measure paid marketing activity
                                        -- used by google analytics
-- user_id linked to cookie in a user's browser

USE mavenfuzzyfactory;



SELECT ws.utm_content, 
COUNT(DISTINCT ws.website_session_id) AS sessions,
COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt 
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.website_session_id BETWEEN 1000 AND 2000
GROUP BY ws.utm_content
ORDER BY sessions DESC
;   

#Assignment1: finding top traffic sources --- where the bulk of website sessions are coming from?
# UTM source, campaign, referring domain
# ws.utm_source, ws.utm_campaign, ws.http_referer
SELECT
ws.utm_source, 
ws.utm_campaign, 
ws.http_referer,
COUNT(DISTINCT ws.website_session_id) AS sessions

FROM website_sessions ws 
LEFT JOIN orders o 
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-04-12'
GROUP BY ws.utm_source, ws.utm_campaign, ws.http_referer
ORDER BY sessions DESC
;

### drill deeper into gsearch nonbrand campaign traffic to explore potential optimization opportunities
## how can we improve gsearch-nonbrand
SELECT

COUNT(DISTINCT ws.website_session_id) AS sessions,
COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt 

FROM website_sessions ws 
LEFT JOIN orders o 
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-04-14'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand' 
ORDER BY session_to_order_conv_rt DESC
;

## next step: monitor the impact of bid reductions, 
## analyze performance trending by device type in order to refine bidding strategy

## bid optimization and trend analysis
# pivoting into rows --- group by
# pivoting into columns -- count and case

SELECT 
order_id,
primary_product_id,
items_purchased,
created_at
FROM orders
WHERE order_id BETWEEN 31000 AND 32000;

SELECT 
Primary_product_id,
COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS orders_w_1_item,
COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS orders_w_2_item,
COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY Primary_product_id
;
















