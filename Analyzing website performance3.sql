####################### landing page trend analysis
# pull the volumn of paid search nonbrand traffic landing on home and lander-1, trended weekly since 2012-06-01 to 2012-08-31
# to confirm the traffic is all routed correctly
# pull overall paid search bounce rate trended weekly
# week_start_date, bounce_rate, home_sessions, lander_sessions
DROP TABLE IF EXISTS firstview_landing_sessions;
CREATE TEMPORARY TABLE firstview_landing_sessions
SELECT
MIN(wp.website_pageview_id) AS first_pageview_id,
wp.created_at, 
COUNT(wp.website_session_id) AS sessions,
pageview_url,
(CASE WHEN pageview_url = '/home' THEN 1 ELSE NULL END) AS home,
(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE NULL END) AS lander,
(CASE WHEN COUNT(wp.website_session_id) = 1 THEN 1 ELSE NULL END) AS bounce
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at BETWEEN '2012-06-01' AND '2012-08-31'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id
;



SELECT
MIN(DATE(created_at)) AS week_start_date,
COUNT(bounce)/COUNT(sessions) AS bounce_rate,
COUNT(home) AS home_sessions,
COUNT(lander) AS lander_sessions

FROM firstview_landing_sessions
GROUP BY YEAR(created_at), WEEK(created_at)
;

-- weekly overall bounce rate decreased after new landing page was added after 2012-06-17

