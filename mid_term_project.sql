## objetives: 1. tell the story of your company's growth, using trended performance data
		##    2. use the database to explain some of the details around your growth story, and quantify the revenue
        ##       impact of some of your wins
        ##    3. analyze current performance, and use the data available to assess upcomming opportunities
        ## all the analysis should be before 2012-11-27
        
/* task1. Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for 
		gsearch sessions and orders so that we can showcase the growth there? */
	
USE mavenfuzzyfactory;
SELECT
MIN(DATE(ws.created_at)) AS start_of_month,
COUNT(DISTINCT ws.website_session_id) AS sessions,
COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
AND ws.utm_source = 'gsearch'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at)
;


        
/* task2. next, it would be greate to see a similar monthly trend for Gsearch, but this time splitting out
		  nonbrand and brand campaigns separately. I am wondering if brand is picking up at all. If so, this
		  is a good story to tell. */
          

SELECT
MIN(DATE(ws.created_at)) AS start_of_month,
COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders,
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders

FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
AND ws.utm_source = 'gsearch'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at)
;



/* task3. while we're on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split 
		  by device type? I want to flex our analytical muscles a little and show the board we really know
		  our traffic sources */

SELECT
MIN(DATE(ws.created_at)) AS start_of_month,
COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN o.order_id ELSE NULL END) AS desktop_orders,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_orders

FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at)
;  
          
          
          
/* task4. I'm worried that one of our more pessimistic board members may be concerned about the large % of 
		  traffic from Gserch. can you pull monthly treands for Gsearch, alongside monthly trends for each 
		  of our other channels */
/*SELECT DISTINCT utm_source
FROM    website_sessions
WHERE created_at < '2012-11-27';     */  -- four utm_source gsearch, null, bsearch
-- look into the utm_source IS NULL (null is the not paid traffic)

-- https://www.smartbugmedia.com/blog/what-is-the-difference-between-direct-and-organic-search-traffic-sources
-- organic traffic consists of visits from search engines, 
-- while direct traffic is made up of visits from people entering your company URL into their browser.
/*SELECT DISTINCT utm_source,
http_referer
FROM    website_sessions
WHERE created_at < '2012-11-27'; */   -- direct traffic (null null)  organic(null not null)
SELECT
MIN(DATE(ws.created_at)) AS start_of_month,

COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_sessions,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_sessions,
-- COUNT(DISTINCT CASE WHEN utm_source = 'socialbook' THEN ws.website_session_id ELSE NULL END) AS socialbook_sessions,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_traffic_sessions,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_traffic_sessions

FROM website_sessions ws
WHERE ws.created_at < '2012-11-27'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at)
;  
        
 
/*
task5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 
*/
   
SELECT
MIN(DATE(ws.created_at)) AS start_of_month,
COUNT(DISTINCT ws.website_session_id) AS sessions,
COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at)
;  

        
/*
task6.	For the (gsearch) lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR(conversion rate) from the test (Jun 19 – Jul 28), and use 
(nonbrand) sessions and revenue since then to calculate incremental value)
*/         
-- the lander test (lander-1)
-- find the test date first
SELECT MIN(created_at)
FROM website_pageviews
WHERE pageview_url = '/lander-1'
;	-- 2012-06-19 to 2012-07-28

DROP TABLE IF EXISTS landing_sessions;
CREATE TEMPORARY TABLE landing_sessions
SELECT
-- MIN(wp.website_pageview_id) AS firstview_page,
-- wp.created_at,
wp.website_session_id,
wp.pageview_url,
(CASE WHEN wp.pageview_url = '/home' THEN wp.website_session_id ELSE NULL END) AS home_sessions,
(CASE WHEN wp.pageview_url = '/lander-1' THEN wp.website_session_id ELSE NULL END) AS lander1_sessions

FROM website_pageviews wp
INNER JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
AND wp.created_at BETWEEN '2012-06-19' AND '2012-07-28'
AND wp.website_pageview_id >= 23504 -- first page_view, I did not include this in my previous analysis, 
                                    -- after adding this, results is the same as that from given solution
GROUP BY wp.website_session_id
;
        
        
SELECT 
pageview_url,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT home_sessions) AS home_conv_rt,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT lander1_sessions) AS lander1_conv_rt
FROM landing_sessions
LEFT JOIN orders
ON landing_sessions.website_session_id = orders.website_session_id
GROUP BY pageview_url
;

-- home conversion rate is 0.0311, lander-1 conversion rate is 0.0414
-- 0.0103 incremental conversion
-- next we need to find incremental sessions from the test 2012-07-28

SELECT 
MIN(website_pageview_id) AS firt_view_page,
pageview_url
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE pageview_url IN ('/home', '/lander-1')
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
AND wp.created_at BETWEEN '2012-07-29' AND '2012-11-27'
GROUP BY wp.website_session_id
;

-- 21837 incremental sessions from home and lander-1 for gsearch, nonbrand
-- 21837*0.0103 = 225 incremental orders from 2012-07-29 
-- which is more than 50 extra orders for 4 month 


/*
task7.	For the landing page test you analyzed previously, it would be great to show a full conversion funnel 
from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/ 
DROP TABLE IF EXISTS noflag;
CREATE TEMPORARY TABLE noflag
SELECT
wp.website_session_id,
wp.pageview_url
FROM website_pageviews wp 
INNER JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
AND wp.created_at BETWEEN '2012-06-19' AND '2012-07-28'
AND wp.pageview_url IN ('/home', '/lander-1', '/products', '/the-original-mr-fuzzy', 
						'/cart', '/shipping', '/billing', '/thank-you-for-your-order')
;
	
DROP TABLE IF EXISTS w_flag;
CREATE TEMPORARY TABLE w_flag
SELECT
pageview_url,
MAX(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE NULL END) AS to_lander_1,
MAX(CASE WHEN pageview_url = '/home' THEN 1 ELSE NULL END) AS to_home,
MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE NULL END) AS to_products,
MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS to_mrfuzzy,
MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE NULL END) AS to_cart,
MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE NULL END) AS to_shipping,
MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE NULL END) AS to_billing,
MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS to_thankyou

FROM noflag

GROUP BY website_session_id
-- HAVING to_lander_1 = 1
;

DROP TABLE IF EXISTS to_page_sessions;
CREATE TEMPORARY TABLE to_page_sessions
SELECT 
pageview_url,
COUNT(to_lander_1) AS lander1_sessions,
COUNT(to_home) AS home_sessions,
COUNT(to_products) AS to_products,
COUNT(to_mrfuzzy) AS to_mrfuzzy,
COUNT(to_cart) AS to_cart,
COUNT(to_shipping) AS to_shipping,
COUNT(to_billing) AS to_billing,
COUNT(to_thankyou) AS to_thankyou

FROM w_flag
GROUP BY pageview_url
;


SELECT*FROM to_page_sessions;

SELECT
pageview_url,
to_products/lander1_sessions AS lander1_click_rt,
to_products/home_sessions AS home_click_rt,
to_mrfuzzy/to_products AS products_click_rt,
to_cart/to_mrfuzzy AS mrfuzzy_click_rt,
to_shipping/to_cart AS cart_click_rt,
to_billing/to_shipping AS shipping_click_rt,
to_thankyou/to_billing AS billing_click_rt

FROM to_page_sessions
;


/*
8.	I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated 
from the test (Sep 10 – Nov 10), in terms of (revenue) per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/ 

SELECT DISTINCT pageview_url
FROM website_pageviews;  -- the new billing test: billing-2

SELECT
wp.pageview_url,
COUNT(DISTINCT wp.website_session_id) AS sessions,
-- price_usd
SUM(price_usd) AS revenue,
SUM(price_usd)/COUNT(DISTINCT wp.website_session_id) AS revenue_per_session
FROM website_pageviews wp 
LEFT JOIN orders o 
ON wp.website_session_id = o.website_session_id
WHERE wp.created_at BETWEEN '2012-09-10' AND '2012-11-10'
AND wp.pageview_url IN ('/billing', '/billing-2')
GROUP BY pageview_url
;

-- 23.05 for billing    31.31 for billing2
-- lift 8.26 per billing session

SELECT 
COUNT(website_session_id) AS sessions_past_month
FROM website_pageviews 
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2') 
AND created_at BETWEEN '2012-10-27' AND '2012-11-27' -- past month
;

-- 1071 all sessions
-- VALUE OF BILLING TEST: 1071*8.26 = 8846.46 over the past month







