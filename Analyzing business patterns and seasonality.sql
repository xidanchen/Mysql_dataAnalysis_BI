############################## analyzing seasonality
/* take a look at 2012’s monthly and weekly volume patterns, to see if we can find any seasonal trends we 
should plan for in 2013
to pull session volumns and order volumns */
SELECT 
YEAR(wp.created_at),
MONTH(wp.created_at),
COUNT(DISTINCT order_id) AS order_volumns,
COUNT(DISTINCT wp.website_session_id) AS session_volumns
FROM website_pageviews wp
LEFT JOIN orders o
ON wp.website_session_id = o.website_session_id
WHERE YEAR(wp.created_at) = '2012'
GROUP BY YEAR(wp.created_at), MONTH(wp.created_at)
;

SELECT 
MIN(DATE(wp.created_at)) AS start_of_week,
COUNT(DISTINCT order_id) AS order_volumns,
COUNT(DISTINCT wp.website_session_id) AS session_volumns
FROM website_pageviews wp
LEFT JOIN orders o
ON wp.website_session_id = o.website_session_id
WHERE YEAR(wp.created_at) = '2012'
GROUP BY YEAR(wp.created_at), WEEK(wp.created_at)
;

-- around 11-18, 11-25 has a spike   (week of black friday and cyber monday)

########################################## analyzing business patterns
/*We’re considering adding live chat support to the website to improve our customer experience. 
Could you analyze the average website session volume, by hour of day and by day week, so that we can staff appropriately? 
Let’s avoid the holiday time period and use a date range of 
Sep 15 - Nov 15, 2012. */
DROP TABLE IF EXISTS sessions_only;
CREATE TEMPORARY TABLE sessions_only
SELECT
DATE(created_at),
HOUR(created_at) AS hours,
WEEKDAY(created_at) AS weekdays,
COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY DATE(created_at), HOUR(created_at), WEEKDAY(created_at)
;


SELECT
hours,

ROUND(AVG(CASE WHEN weekdays = 0 THEN sessions ELSE NULL END), 1) AS Monday,
ROUND(AVG(CASE WHEN weekdays = 1 THEN sessions ELSE NULL END), 1) AS Tuesday,
ROUND(AVG(CASE WHEN weekdays = 2 THEN sessions ELSE NULL END), 1) AS Wednesday,
ROUND(AVG(CASE WHEN weekdays = 3 THEN sessions ELSE NULL END), 1) AS Thursday,
ROUND(AVG(CASE WHEN weekdays = 4 THEN sessions ELSE NULL END), 1) AS Friday,
ROUND(AVG(CASE WHEN weekdays = 5 THEN sessions ELSE NULL END), 1) AS Saturday,
ROUND(AVG(CASE WHEN weekdays = 6 THEN sessions ELSE NULL END), 1) AS Sunday

FROM sessions_only
GROUP BY hours
;



