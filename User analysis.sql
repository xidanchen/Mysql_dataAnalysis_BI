###################################### identifying repeat visitors
USE mavenfuzzyfactory;
/* We’ve been thinking about customer value based solely on their first session conversion and revenue. 
But if customers have repeat sessions, they may be more valuable than we thought. 
If that’s the case, we might be able to spend a bit more to acquire them.
Could you please pull data on 
how many of our website visitors come back for another session? 2014 to date is good.  2014-11-01 */
DROP TABLE IF EXISTS all_sessions;
CREATE TEMPORARY TABLE all_sessions
SELECT 
first_session.user_id,
first_session.website_session_id,
ws.website_session_id AS repeat_session_id
FROM 
(SELECT 
user_id,
website_session_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
AND is_repeat_session = 0 ) AS first_session
LEFT JOIN website_sessions ws
ON first_session.user_id = ws.user_id
AND ws.website_session_id > first_session.website_session_id
AND ws.is_repeat_session = 1
AND ws.created_at BETWEEN '2014-01-01' AND '2014-11-01'
;


SELECT
repeat_sessions,
COUNT(user_id) AS users
FROM
(SELECT 
user_id,
COUNT(website_session_id),
COUNT(repeat_session_id) AS repeat_sessions
FROM all_sessions
GROUP BY user_id) AS user_level
GROUP BY repeat_sessions
ORDER BY repeat_sessions
;


####################################### analyzing time to repeat
/* Ok, so the repeat session data was really interesting to see. 
Now you’ve got me curious to better understand the behavior of these repeat customers.
Could you help me understand the minimum, maximum, and average time (between the first and second session) for 
customers who do come back? 
Again, analyzing 2014 to date is probably the right time period.    2014-11-05 */

CREATE TEMPORARY TABLE sessions_created_at
SELECT 
first_session.user_id,
first_session.website_session_id,
first_session.created_at,
ws.website_session_id AS repeat_session_id,
MIN(ws.created_at) AS second_session_created_at
FROM 
(SELECT 
user_id,
website_session_id,
created_at 
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
AND is_repeat_session = 0 ) AS first_session
INNER JOIN website_sessions ws
ON first_session.user_id = ws.user_id
AND ws.website_session_id > first_session.website_session_id
AND ws.is_repeat_session = 1
AND ws.created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY user_id
;


SELECT
MIN(DATEDIFF(second_session_created_at, created_at)),
MAX(DATEDIFF(second_session_created_at, created_at)),
AVG(DATEDIFF(second_session_created_at, created_at))
FROM sessions_created_at
;


####################################### analyzing repeat channel behavior
/* Let’s do a bit more digging into our repeat customers. 
Can you help me understand the channels they come back through? Curious if it’s all direct type-in, or if we’re paying for 
these customers with paid search ads multiple times. 
Comparing new vs. repeat sessions by channel would be 
really valuable, if you’re able to pull it! 2014 to date is great.   2014-11-05   */

SELECT
(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
     WHEN utm_source IS NULL AND http_referer IN ('https://www.bsearch.com', 'https://www.gsearch.com') THEN 'organic_search'
     WHEN utm_campaign = 'brand' THEN 'paid_brand'
     WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
     WHEN utm_source = 'socialbook' THEN 'paid_social'
     ELSE NULL
     END) AS channel_group,
COUNT(CASE WHEN is_repeat_session = 0 THEN 1 ELSE NULL END) AS new_session,
COUNT(CASE WHEN is_repeat_session = 1 THEN 1 ELSE NULL END) AS repeat_session

FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY channel_group
ORDER BY repeat_session DESC
;

/* So, it looks like when customers come back for repeat visits, they come mainly through organic search, direct type-in, 
and paid brand 
Only about 1/3 come through a paid channel, and brand clicks are cheaper than nonbrand. So all in all, we’re not 
paying very much for these subsequent visits.
This make me wonder whether these convert to orders… */


########################################### analyzing new and repeat convertion rates
/* Sounds like you and Tom have learned a lot about our repeat customers. Can I trouble you for one more thing? 
I’d love to do a comparison of conversion rates and revenue per session for repeat sessions vs new sessions. 
Let’s continue using data from 2014, year to date.  2014-11-08 */

SELECT
-- ws.website_session_id,
is_repeat_session,
COUNT(o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rt,
SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY is_repeat_session
;

-- Looks like repeat sessions are more likely to convert, and produce more revenue per session





















