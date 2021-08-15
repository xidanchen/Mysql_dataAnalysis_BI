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
/* Now that we have a new product, I’m thinking about our (user path and conversion funnel). Let’s look at sessions which 
hit the /products page and see where they went next. 
Could you please pull clickthrough rates from /products since the new product launch on (January 6th 2013), by product, 
and compare to the 3 months leading up to launch as a baseline? */

SELECT DISTINCT pageview_url FROM website_pageviews;

DROP TABLE IF EXISTS no_flag;
CREATE TEMPORARY TABLE no_flag
SELECT
website_session_id,
(CASE WHEN created_at >= '2013-01-06' THEN 'after_new_product_launch'
	 WHEN created_at < '2013-01-06' THEN 'before_new_product_launch'
     ELSE NULL 
END) AS time_period,
MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE NULL END) AS products,
MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS mr_fuzzy,
MAX(CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE NULL END) AS love_bear,
pageview_url
FROM website_pageviews 
WHERE 
created_at BETWEEN '2012-10-06' AND '2013-04-06'
AND pageview_url IN ('/products', '/the-original-mr-fuzzy', '/the-forever-love-bear')
GROUP BY website_session_id
;

SELECT
time_period,
COUNT(mr_fuzzy)/COUNT(products) AS pct_to_mr_fuzzy,
COUNT(love_bear)/COUNT(products) AS pct_to_love_bear
FROM no_flag
WHERE products = 1
GROUP BY time_period
;

/* Looks like the percent of /products pageviews that clicked to 
Mr. Fuzzy has gone down since the launch of the Love Bear, 
but the overall clickthrough rate has gone up, so it seems to 
be generating additional product interest overall. 
As a follow up, we should probably look at the conversion 
funnels for each product individually. */




#################################### building product-level conversion funnels
/* I’d like to look at our two products since January 6th and analyze the conversion funnels from each product page to 
conversion.  to april 10, 2013
It would be great if you could produce a comparison between the two conversion funnels, for all website traffic.   */
DROP TABLE IF EXISTS flaged;
CREATE TEMPORARY TABLE flaged
SELECT
pageview_url, 
website_session_id,
MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE NULL END) AS cart,
MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE NULL END) AS shipping,
MAX(CASE WHEN pageview_url IN ('/billing','/billing-2') THEN 1 ELSE NULL END) AS billing,
MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS thankyou

FROM website_pageviews
WHERE
created_at BETWEEN '2013-01-06' AND '2013-04-10'
AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear', 
                  '/cart', '/shipping', '/billing','/billing-2', '/thank-you-for-your-order')
GROUP BY website_session_id
;

CREATE TEMPORARY TABLE product_sessions
SELECT
pageview_url,
COUNT(website_session_id) AS sessions,
COUNT(cart) AS cart_session,
COUNT(shipping) AS shipping_session,
COUNT(billing) AS billing_session,
COUNT(thankyou) AS thankyou_session
FROM flaged
GROUP BY pageview_url
;

SELECT 
pageview_url,
cart_session/sessions AS product_page_click_rt,
shipping_session/cart_session AS cart_page_click_rt,
billing_session/shipping_session AS shipping_page_click_rt,
thankyou_session/billing_session AS billing_page_click_rt

FROM product_sessions
;

/*We had found that adding a second product increased 
overall CTR from the /products page, and this analysis shows 
that the Love Bear has a better click rate to the /cart page 
and comparable rates throughout the rest of the funnel.  */


######################################### cross-sell analysis
/*analyze orders and order_items data to understand which products cross-sell, and analyze the impact on revenue
use website_pageviews data to understand if cross-selling hurts overall conversion rates
using thi data, we can develop deeper understanding of our customer perchase behaviors */
   
/* On September 25th (2013-09-25) we started giving customers the option to add a 2nd product while on the /cart page. 
Morgan says this has been positive, but I’d like your take on it.
Could you please compare the month before vs the month after the change? 
I’d like to see CTR(click through rate) from the (/cart) page, Avg Products per Order, AOV(average order value), and overall revenue per 
/cart page view       */
DROP TABLE IF EXISTS subset;
CREATE TEMPORARY TABLE subset
SELECT
-- wp.website_session_id,
(CASE WHEN wp.created_at >= '2013-09-25' THEN 'month_after'
      WHEN wp.created_at < '2013-09-25' THEN 'month_before' 
      ELSE NULL 
      END) AS time_period,
-- pageview_url, 
o.order_id,
items_purchased,
price_usd,
(CASE WHEN o.order_id IS NOT NULL THEN 1 ELSE NULL END) AS orders,
MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE NULL END) AS cart,
MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE NULL END) AS shipping,
MAX(CASE WHEN pageview_url IN ('/billing','/billing-2') THEN 1 ELSE NULL END) AS billing,
MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS thankyou
FROM website_pageviews wp
LEFT JOIN orders o
ON wp.website_session_id = o.website_session_id
WHERE wp.created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND wp.pageview_url IN ('/cart', '/shipping', '/billing','/billing-2', '/thank-you-for-your-order')
GROUP BY wp.website_session_id
;


SELECT 
time_period,
COUNT(cart) AS cart_sessions,
COUNT(shipping)/COUNT(cart) AS ctr_cart,
-- COUNT(billing)/COUNT(shipping) AS ctr_shipping,
-- COUNT(thankyou)/COUNT(billing) AS ctr_billing,
SUM(items_purchased)/COUNT(orders) AS Avg_Products_per_Order,
SUM(price_usd)/COUNT(orders) AS AOV,
SUM(price_usd)/COUNT(cart) AS overall_revenue_per_cart

FROM subset
WHERE cart = 1
GROUP BY time_period
;


######################################### product portfolio expansion
/* On December 12th 2013, we launched a third product targeting the birthday gift market (Birthday Bear).
Could you please run a pre-post analysis comparing the 
month before vs. the month after, 2013-12-12
in terms of session-to-order conversion rate, AOV, products per order, and revenue per session? */

SELECT
(CASE WHEN wp.created_at < '2013-12-12' THEN 'pre_launch'
     WHEN wp.created_at >= '2013-12-12' THEN 'post_launch' 
     ELSE NULL
     END) AS time_period,

COUNT(DISTINCT o.order_id)/COUNT(DISTINCT wp.website_session_id) AS session_order_conv_rt,
SUM(o.price_usd)/COUNT(o.order_id) AS AOV,
SUM(o.items_purchased)/COUNT(o.order_id) AS Products_per_Order,
SUM(o.price_usd)/COUNT(wp.website_session_id) AS revenue_per_session
FROM website_pageviews wp 
LEFT JOIN orders o
ON wp.website_session_id = o.website_session_id
WHERE wp.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY time_period
;



#################################### analyzing product refund rates
# to analyze product refunds, we'll need to join our order_item data to the order_item_refunds table
/* Our Mr. Fuzzy supplier had some quality issues which  weren’t corrected until September 2013. 
Then they had a major problem where the bears’ arms were falling off in Aug/Sep 2014. 
As a result, we replaced them with a new supplier on September 16, 2014.
Can you please pull monthly product refund rates, 
by product, and confirm our quality issues are now fixed?      2014-10-15 */

SELECT 
YEAR(oi.created_at),
MONTH(oi.created_at),
-- oi.product_id,
-- COUNT(CASE WHEN oi.product_id = 1 THEN oi.order_id ELSE NULL END) AS product1_orders,
-- COUNT(CASE WHEN oi.product_id = 2 THEN oi.order_id ELSE NULL END) AS product2_orders,
-- COUNT(CASE WHEN oi.product_id = 3 THEN oi.order_id ELSE NULL END) AS product3_orders,
-- COUNT(CASE WHEN oi.product_id = 4 THEN oi.order_id ELSE NULL END) AS product4_orders,
-- COUNT(CASE WHEN oi.product_id = 1 THEN oir.order_item_refund_id ELSE NULL END) AS product1_refunds,
-- COUNT(CASE WHEN oi.product_id = 2 THEN oir.order_item_refund_id ELSE NULL END) AS product2_refunds,
-- COUNT(CASE WHEN oi.product_id = 3 THEN oir.order_item_refund_id ELSE NULL END) AS product3_refunds,
-- COUNT(CASE WHEN oi.product_id = 4 THEN oir.order_item_refund_id ELSE NULL END) AS product4_refunds,
COUNT(CASE WHEN oi.product_id = 1 THEN oir.order_item_refund_id ELSE NULL END)/COUNT(CASE WHEN oi.product_id = 1 THEN oi.order_id ELSE NULL END)
AS product1_refund_rt,
COUNT(CASE WHEN oi.product_id = 2 THEN oir.order_item_refund_id ELSE NULL END)/COUNT(CASE WHEN oi.product_id = 2 THEN oi.order_id ELSE NULL END)
AS product2_refund_rt,
COUNT(CASE WHEN oi.product_id = 3 THEN oir.order_item_refund_id ELSE NULL END)/COUNT(CASE WHEN oi.product_id = 3 THEN oi.order_id ELSE NULL END)
AS product3_refund_rt,
COUNT(CASE WHEN oi.product_id = 4 THEN oir.order_item_refund_id ELSE NULL END)/COUNT(CASE WHEN oi.product_id = 4 THEN oi.order_id ELSE NULL END)
AS product4_refund_rt




-- COUNT(oi.order_id),
-- COUNT(oir.order_item_refund_id)
FROM order_items oi
LEFT JOIN order_item_refunds oir
ON oi.order_item_id = oir.order_item_id
WHERE oi.created_at < '2014-10-15'
GROUP BY YEAR(oi.created_at), MONTH(oi.created_at)
;


















