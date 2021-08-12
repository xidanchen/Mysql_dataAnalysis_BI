######################### analyzing channel portfolios
/* with gsearch doing well and the site performing better, we launched a second paid search channel, bsearch, around 2012-08-22.
pull weekly trended session volume since then and compare to gsearch nonbrand so we can get a sense for how important this will be for the 
business? -- 2012-11-29*/  

SELECT 
-- website_session_id,
MIN(DATE(created_at)) AS start_of_week,
COUNT(CASE WHEN utm_source = 'gsearch' THEN 1 ELSE NULL END) AS gsearch_sessions,
COUNT(CASE WHEN utm_source = 'bsearch' THEN 1 ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE utm_source IN ('gsearch', 'bsearch')
AND utm_campaign = 'nonbrand'
AND created_at > '2012-08-22' AND
 created_at < '2012-11-29'
GROUP BY YEAR(created_at), WEEK(created_at)
;

-- bsearch tends to get roughly a third the traffic of gsearch
-- we will follow up with some requests to understand channel characteristics and conversion performance


####################################### comparing channel characteristics
/* to learn more about the bsearch nonbrand campaign, pull the percentage of traffic coming on mobile and compare that to gsearch
aggregate data since 2010-08-22 to 11-30 */

SELECT
utm_source,
COUNT(website_session_id) AS sessions,
COUNT(CASE WHEN device_type = 'mobile' THEN 1 ELSE NULL END) AS mobile_sessions,
COUNT(CASE WHEN device_type = 'mobile' THEN 1 ELSE NULL END)/COUNT(website_session_id) AS pct_mobile
FROM website_sessions
WHERE utm_source IN ('gsearch', 'bsearch')
AND utm_campaign = 'nonbrand'
AND created_at > '2012-08-22' AND
 created_at < '2012-11-29'
GROUP BY utm_source
;


##################################### cross-channel bid optimization
/* should bsearch nonbrand have the same bids as gsearch? 
to pull nonbrand conversoin rates from session to order for gsearch and bsearch, and
slice the data by device type
analyze data from 2012-08-22 to 09-18  */

SELECT
utm_source,
device_type,
COUNT(ws.website_session_id) AS sessions,
COUNT(order_id) AS orders,
COUNT(order_id)/COUNT(ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE utm_source IN ('gsearch', 'bsearch')
AND utm_campaign = 'nonbrand'
AND ws.created_at > '2012-08-22' AND
 ws.created_at < '2012-09-18'
GROUP BY utm_source, device_type
;

-- the channels don't perform identically, so we should differentiate our bids in order to optimize our overall paid marketing budget.
-- bid down bsearch base on its under-performance


########################################### analyzing channel portfolio trends
/* pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since 11-04 to 12-22
include a comparison metric to show besearch as a percent of gsearch for each device
note we bid down besearch nonbrand on 12-02       */

CREATE TEMPORARY TABLE no_comparison
SELECT 
-- website_session_id,
MIN(DATE(created_at)) AS start_of_week,
COUNT(CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN 1 ELSE NULL END) AS mobile_gsearch_sessions,
COUNT(CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN 1 ELSE NULL END) AS desktop_gsearch_sessions,
COUNT(CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN 1 ELSE NULL END) AS mobile_bsearch_sessions,
COUNT(CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN 1 ELSE NULL END) AS desktop_bsearch_sessions
FROM website_sessions
WHERE utm_source IN ('gsearch', 'bsearch')
AND utm_campaign = 'nonbrand'
AND created_at > '2012-11-04' AND
 created_at < '2012-12-22'
GROUP BY YEAR(created_at), WEEK(created_at)
;

SELECT
*,
mobile_bsearch_sessions/mobile_gsearch_sessions AS pct_mobile_b_gsearch,
desktop_bsearch_sessions/desktop_gsearch_sessions AS pct_desktop_b_gsearch
FROM no_comparison
;

###################################### analyzing direct traffic
/* are we building any momentum with our brand or will we need to keep relying on paid traffic?
pull organic search, direct type in, and paid brand search sessions by month, and show those sessions as a % of paid search nonbrand 
before 12-23 */
CREATE TEMPORARY TABLE sessions
SELECT
MIN(DATE(created_at)),
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 1 ELSE NULL END) AS organic_search,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN 1 ELSE NULL END) AS direct_type,
COUNT(CASE WHEN utm_source IS NOT NULL AND utm_campaign = 'brand' THEN 1 ELSE NULL END) AS paid_brand,
COUNT(CASE WHEN utm_source IS NOT NULL AND utm_campaign = 'nonbrand' THEN 1 ELSE NULL END) AS paid_nonbrand

FROM website_sessions
WHERE created_at < '2012-12-23'
GROUP BY YEAR(created_at), MONTH(created_at)
;

SELECT
*,
organic_search/paid_nonbrand AS organic_pct_paid_nonbrand,
direct_type/paid_nonbrand AS direct_pct_paid_nonbrand,
paid_brand/paid_nonbrand AS paid_brand_pct_paid_nonbrand
FROM sessions
;

-- not only our brand, direct, and organic volumns growing, but they are growing as a percentage of our paid traffic volume

