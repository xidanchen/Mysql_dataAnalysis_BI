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

## finding top traffic sources --- where the bulk of website sessions are coming from?
# UTM source, campaign, referring domain
# ws.utm_source, ws.utm_campaign, ws.http_referer
SELECT
ws.utm_source, 
ws.utm_campaign, 
ws.http_referer,
COUNT(DISTINCT ws.website_session_id) AS sessions
FROM website_sessions ws 
WHERE ws.created_at < '2012-04-12' -- arbitrary, depends on the date you get the task
GROUP BY ws.utm_source, ws.utm_campaign, ws.http_referer
ORDER BY sessions DESC
;

-- the results show top traffic source is gsearch, nonbrand


### drill deeper into gsearch nonbrand campaign traffic to explore potential optimization opportunities
## how can we improve gsearch-nonbrand
## Did the payment gsearch-nonbrand lead to enough orders? we then look at the source_order_conversion rate.
## did the conversion rate pass our threshold? here is 4% -- arbitrary
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
ORDER BY sessions DESC
;   

-- the current coversion rate is 2.88% which did not pass our threshold that means the current payment did not lead to
-- the expected results. we therefore made the decision to bid down the search.

## next step: monitor the impact of bid reductions, 
## analyze performance trending by device type in order to refine bidding strategy

## bid optimization and trend analysis


# pivoting into rows --- group by
# pivoting into columns -- count and case
/*SELECT 
Primary_product_id,
COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS orders_w_1_item,
COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS orders_w_2_item,
COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY Primary_product_id
; */


##traffic source trending. 
## based on the conversion rate, we bid down the gsearch nonbrand, we now want to know if the bid changes caused the volumn
## to drop. 
## we need to pull gsearch onbrand trended session volume, by week

SELECT
-- YEAR(ws.created_at),
-- WEEK(ws.created_at),
MIN(DATE(ws.created_at)) AS week_started_at,
COUNT(DISTINCT ws.website_session_id) AS sessions
FROM website_sessions ws 
WHERE ws.created_at < '2012-05-10'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand' 
GROUP BY YEAR(ws.created_at), WEEK(ws.created_at)
;

-- the results show last week we had a huge drop in sessions. It seems like gsearch nonbrand is 
-- faily sensitive to bid changes.

## NEXT STEPS:
## 1. continue to monitor volume levels
## 2. think about how we could make the campaigns more efficient so that we can increase volumn change

## here we can look into the gsearch nonbrand device level performance
## if the desktop performance is better than on mobile we may be able to bid up for desktop specifically
## to get more volume
## what we will retrieve here is the conversion rates from session to order, by device type

SELECT
ws.device_type,
COUNT(DISTINCT ws.website_session_id) AS sessions,
COUNT(DISTINCT o.order_id) AS orders,
COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt

FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-05-11' 
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY ws.device_type
;

-- the results show the desktop conversion rate is way better than mobile. so we are going to increase the bids on desktop
## NEXT STEP:
## analyze volume by device type to see if the bid changes make a material impact
## continue to look for ways to optimize campaigns

## gsearch device level trends
## after biding up the gsearch on desktop at 2012-05-19, we want to see new changes impact on volume 
## to pull the weekly trends for both desktop and mobile
## use 4/15 as base line

SELECT A.week_started_at, A.desktop_sessions, B.mobile_sessions
FROM 
(SELECT
-- YEAR(ws.created_at),
-- WEEK(ws.created_at),
MIN(DATE(ws.created_at)) AS week_started_at,
COUNT(DISTINCT ws.website_session_id) AS desktop_sessions
FROM website_sessions ws 
WHERE ws.created_at BETWEEN '2012-04-15' AND '2012-06-09'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand' 
AND ws.device_type = 'desktop'
GROUP BY YEAR(ws.created_at), WEEK(ws.created_at)) AS A

JOIN


(SELECT
-- YEAR(ws.created_at),
-- WEEK(ws.created_at),
MIN(DATE(ws.created_at)) AS week_started_at,
COUNT(DISTINCT ws.website_session_id) AS mobile_sessions
FROM website_sessions ws 
WHERE ws.created_at BETWEEN '2012-04-15' AND '2012-06-09'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand' 
AND ws.device_type = 'mobile'
GROUP BY YEAR(ws.created_at), WEEK(ws.created_at)) AS B

ON A.week_started_at = B.week_started_at

;

-- the other solution is to use case
-- COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
-- COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,

-- desktop result looks strong, the change is making postive impact
 ## NEXT STEPS:
 ## continue to monitor device-level volume and be aware of the impact bid levels has
 ## continue to monitor conversion performance at the device-level to optimize spend



