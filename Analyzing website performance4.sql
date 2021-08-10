####################building converson funnels
# website_pageviews
# when we perform conversion funnel analysis, we will look at each step in our conversion flow to see
# how many customers drop off and how many continue on at each step

-- demo on building conversion funnels
-- business context
   -- we want to build a mini conversion funnel, from /lander-2 to /cart
   -- we want to know how many people reach each step, and also dropoff rates
   -- for simplicity of the demo, we're looking at /lander-2 traffic only-- the demo is a four step funnel
   -- for simplicity of the demo, we're looking at customers who like Mr Fuzzy only --- to avoid the multi-path case


-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: identify each relevant pageview as the specific funnel step
-- STEP 3: create the session-levle conversion funnel view
-- STEP 4: aggregate the data to assess funnel performance

# check out the lecture for script


################################## building conversion funnels
## to understand where we lose our gsearch visitors between the /lander-1 page and placing an order
## build a full conversion funnel, analyzing how many customers make it to each step?
## start with /lander-1 and build the funnel all the way to thank you page, use data from 2012-08-05 to 2012-09-04
## two tables: sessions, to_products, to_mrfuzzy, to_cart, to_shipping, to_billing, to_thankyou
              ## lander_click_rt, products_click_rt,...
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
AND wp.created_at BETWEEN '2012-08-05' AND '2012-09-05'
AND wp.pageview_url IN ('/lander-1', '/products', '/the-original-mr-fuzzy', 
						'/cart', '/shipping', '/billing', '/thank-you-for-your-order')
;

/*select
DISTINCT pageview_url
FROM website_pageviews*/
;

DROP TABLE IF EXISTS w_flag;
CREATE TEMPORARY TABLE w_flag
SELECT
MAX(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE NULL END) AS to_lander_1,
MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE NULL END) AS to_products,
MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS to_mrfuzzy,
MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE NULL END) AS to_cart,
MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE NULL END) AS to_shipping,
MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE NULL END) AS to_billing,
MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS to_thankyou

FROM noflag

GROUP BY website_session_id
HAVING to_lander_1 = 1
;

DROP TABLE IF EXISTS to_page_sessions;
CREATE TEMPORARY TABLE to_page_sessions
SELECT 
COUNT(to_lander_1) AS sessions,
COUNT(to_products) AS to_products,
COUNT(to_mrfuzzy) AS to_mrfuzzy,
COUNT(to_cart) AS to_cart,
COUNT(to_shipping) AS to_shipping,
COUNT(to_billing) AS to_billing,
COUNT(to_thankyou) AS to_thankyou

FROM w_flag
;


SELECT*FROM to_page_sessions;

SELECT
to_products/sessions AS lander_click_rt,
to_mrfuzzy/to_products AS products_click_rt,
to_cart/to_mrfuzzy AS mrfuzzy_click_rt,
to_shipping/to_cart AS cart_click_rt,
to_billing/to_shipping AS shipping_click_rt,
to_thankyou/to_billing AS billing_click_rt

FROM to_page_sessions
;

-- the lander, mrfuzzy, billing page have the lowest click through rates


################################### analyzing conversion funnel tests
## test an updated billing page based on previous funnel analysis, this test was ran for all traffic
## to check if the /billing-2 is better than original /billing page
## what % of sessions on those pages end up an order
## date before 2012-11-10

# find the time billing-2 was created
SELECT
min(created_at),
pageview_url
FROM website_pageviews
WHERE pageview_url = '/billing-2'
;

-- first time appear at 2012-09-10
DROP TABLE IF EXISTS flagged;
CREATE TEMPORARY TABLE flagged
SELECT
website_session_id,
pageview_url,
MAX(CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE NULL END) AS to_billing_2,
MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE NULL END) AS to_billing,
MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS to_order
FROM website_pageviews 
WHERE created_at BETWEEN '2012-09-10' AND '2012-11-10'
AND pageview_url IN ('/billing-2', '/billing', '/thank-you-for-your-order')
GROUP BY website_session_id
;




SELECT
pageview_url AS billing_version_seen,
COUNT(pageview_url) AS sessions,
COUNT(to_order) AS orders,
COUNT(to_order)/COUNT(pageview_url) AS billing_to_order_rt
FROM flagged
GROUP BY pageview_url
;

-- the new billing page is doing much better than the old one converting customers
## next step: after website manager gets engineering to roll out the new version to 100% of trffic, use the data to confirm they
## have done so correctly
## monitor overall sales performance to see the impact this change produces
## can also use the orders table to solve the task