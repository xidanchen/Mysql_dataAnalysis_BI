######################## analyzing landing page tests
# 50/50 A/B split test, lander-1 vs. home for gsearch nonbrand traffic before July 28, 2012
# pull bounce rate for the two groups to evaluate the new page
# make sure to just look at the time period where/lander-1 was getting traffic
# table for lander-1: first created_at, first_pageview_id
# final results table: landing_page, total_sessions, bounced_sessions, bounce_rate

DROP TABLE IF EXISTS first_view;
CREATE TEMPORARY TABLE first_view
SELECT
wp.pageview_url as landing_page,
wp.website_session_id,
wp.created_at AS first_created_at,
MIN(wp.website_pageview_id) AS first_pageview_id,
COUNT(wp.website_session_id) AS sessions
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE wp.created_at < '2012-07-28' 
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id
;

DROP TABLE lander_1;
CREATE TEMPORARY TABLE lander_1
SELECT 
DATE(MIN(first_created_at)),
DATE(MAX(first_created_at))
FROM first_view
Where landing_page = '/lander-1'
;

-- date between 2012-06-19 and 2012-07-27
DROP TABLE landing_page_sessions;
CREATE TEMPORARY TABLE landing_page_sessions
SELECT
landing_page, 
sessions, 
(CASE WHEN sessions = 1 THEN sessions ELSE NULL END) AS bounced 
FROM first_view
WHERE first_created_at BETWEEN '2012-06-19' AND '2012-07-27'
AND landing_page IN ('/home', '/lander-1')
;

SELECT
landing_page,
COUNT(sessions) AS total_sessions,
COUNT(bounced) AS bounced_sessions,
COUNT(bounced)/COUNT(sessions) AS bounce_rate
FROM landing_page_sessions
GROUP BY landing_page
;

-- lander-1 has lower bounce_rate

## NEXT STEPS: 
## HELP website manager confirm that traffic is all runnning to the new custom lander after campaign updates
## keep an eye on bounce rates and help the team look for other areas to test and optimize






