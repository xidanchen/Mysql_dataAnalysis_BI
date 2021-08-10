-- website_pageviews table
## finding top pages, entry pages/landing pages

USE mavenfuzzyfactory;
SELECT 
pageview_url,
COUNT(DISTINCT website_pageview_id) AS pvs  
FROM website_pageviews
GROUP BY pageview_url
ORDER BY pvs DESC;
# drop table first_pageview;
CREATE TEMPORARY TABLE first_pageview
SELECT 
website_session_id,
MIN(website_pageview_id) AS min_pv_id    -- first page view id
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY website_session_id
;

SELECT 
COUNT(DISTINCT first_pageview.website_session_id) AS sessions_hitting_this_lander,
website_pageviews.pageview_url AS landing_page
FROM first_pageview
LEFT JOIN website_pageviews
ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
GROUP BY website_pageviews.pageview_url
;

## find most_viewed website pages, ranked by session volume before june 09 2012
SELECT pageview_url, 
COUNT(DISTINCT website_session_id)
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY COUNT(DISTINCT website_session_id) DESC;

-- the home, products and the original mr fuzzy page get the most of the traffic
## next steps:
## dig into whether this list is also representative of our top entry pages
## analyze the performance of each of our top pages to look for improvement opportunities

#### pull all entry pages and rank them on entry volumn before June 12 2012
-- get the landing page

CREATE TEMPORARY TABLE landing_pageview
SELECT 
website_session_id,
MIN(website_pageview_id) AS min_pv_id   
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id
;

/*SELECT * FROM landing_pageview
LIMIT 100;*/
SELECT 
COUNT(DISTINCT landing_pageview.website_session_id) AS sessions_hitting_this_lander,
website_pageviews.pageview_url AS landing_page
FROM landing_pageview
LEFT JOIN website_pageviews
ON landing_pageview.min_pv_id = website_pageviews.website_pageview_id
GROUP BY website_pageviews.pageview_url
;

-- landing page is home page
## NEXT STEPS:
## analyze landing page performance, for the homepage specifically
## think about whether or not the homepage is the best initial experience for all customers

## bounce rates, conversion rates, a/b experiment
## we want to see landing page performance for a certain time period
## USE TWO TABLES website_pageviews, website_sessions
-- step1: find the first website_pageview_id for relevant sessions
-- step2: identify the landing page of each session

-- finding the minimum website pageview id associated with each session we care about
CREATE TEMPORARY TABLE first_pageview_demo
SELECT
wp.website_session_id,
MIN(wp.website_pageview_id) AS min_pv_id
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-02-01'
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE sessions_w_landing_page_demo
SELECT 
first_pageview_demo.website_session_id,
wp.pageview_url AS landing_page
FROM first_pageview_demo
LEFT JOIN website_pageviews wp
ON wp.website_pageview_id = first_pageview_demo.min_pv_id
;
# SELECT * FROM sessions_w_landing_page_demo;

-- step3: counting pageviews for each session, to identify 'bounces' (more than 1 pageview--nonbounce, 1 pageview--bounce)
CREATE TEMPORARY TABLE bounced_sessions_only
SELECT
swlp.website_session_id,
swlp.landing_page,
COUNT(DISTINCT wp.website_pageview_id) AS count_of_page_by_session
FROM sessions_w_landing_page_demo swlp
LEFT JOIN website_pageviews wp
ON wp.website_session_id = swlp.website_session_id
GROUP BY swlp.website_session_id,
		 swlp.landing_page
HAVING count_of_page_by_session = 1	
;

SELECT
swlp.landing_page,
swlp.website_session_id,
bso.website_session_id AS bounced_website_session_id
FROM sessions_w_landing_page_demo swlp
LEFT JOIN bounced_sessions_only bso
ON swlp.website_session_id = bso.website_session_id
ORDER BY
swlp.website_session_id
;





-- step4: summarizing total sessions and bounced sessions, by LP(landing page)

SELECT
swlp.landing_page,
COUNT(DISTINCT swlp.website_session_id) AS sessions,
COUNT(DISTINCT bso.website_session_id) AS bounced_sessions,
COUNT(DISTINCT bso.website_session_id)/COUNT(DISTINCT swlp.website_session_id) AS bounce_rate
FROM sessions_w_landing_page_demo swlp
LEFT JOIN bounced_sessions_only bso
ON swlp.website_session_id = bso.website_session_id
GROUP BY swlp.landing_page
ORDER BY
swlp.website_session_id
;

-- note.do not just rely on bounce_rate to make decision. because different pages might serve for different purposes

###### bounce rate analysis
### to pull bounce rates for traffic landing on homepage, showing sessions, bounced sessions, bounce rate before june 14 2012
-- to create tables first_pageview, sessions_w_landing_page, bounced_sessions_only
DROP TABLE IF EXISTS first_pageview;
CREATE TEMPORARY TABLE first_pageview
SELECT
wp.website_session_id,
MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
INNER JOIN website_sessions ws
ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at < '2012-06-14'
GROUP BY wp.website_session_id;

DROP TABLE IF EXISTS sessions_w_landing_page;
CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT 
first_pageview.website_session_id,
wp.pageview_url AS landing_page
FROM first_pageview
LEFT JOIN website_pageviews wp
ON wp.website_pageview_id = first_pageview.min_pageview_id
;

DROP TABLE IF EXISTS bounced_sessions_only;
CREATE TEMPORARY TABLE bounced_sessions_only
SELECT
swlp.website_session_id,
swlp.landing_page,
COUNT(DISTINCT wp.website_pageview_id) AS count_of_page_by_session
FROM sessions_w_landing_page swlp
LEFT JOIN website_pageviews wp
ON wp.website_session_id = swlp.website_session_id
GROUP BY swlp.website_session_id,
		 swlp.landing_page
HAVING count_of_page_by_session = 1	
;

SELECT
swlp.landing_page,
swlp.website_session_id,
bso.website_session_id AS bounced_website_session_id
FROM sessions_w_landing_page swlp
LEFT JOIN bounced_sessions_only bso
ON swlp.website_session_id = bso.website_session_id
WHERE swlp.landing_page = '/home'
ORDER BY
swlp.website_session_id
;

SELECT
swlp.landing_page,
COUNT(DISTINCT swlp.website_session_id) AS sessions,
COUNT(DISTINCT bso.website_session_id) AS bounced_sessions,
COUNT(DISTINCT bso.website_session_id)/COUNT(DISTINCT swlp.website_session_id) AS bounce_rate
FROM sessions_w_landing_page swlp
LEFT JOIN bounced_sessions_only bso
ON swlp.website_session_id = bso.website_session_id
GROUP BY swlp.landing_page
ORDER BY
swlp.website_session_id
;

-- bounce rate almost 60% -- it's high from experience, especially for paid search, which should be high quality traffic
-- website manager then will put together a custom landing page for search, and set up an experiment to see if the new page
-- does better. 
## Next steps: 
## keep an eye on bounce rates, which represent a major area of improvement
## help website manager measure and analyze a new page that she thinks will improve performance, and analyze results of an A/B 
## split test against the homepage























