-- Create DB
create database gms_project;

-- Create combined table
CREATE TABLE gms_project.db_combined as (
	SELECT * FROM gms_project.data_oct
    UNION ALL
    SELECT * FROM gms_project.data_nov
    UNION ALL
    SELECT * FROM gms_project.data_dec
);

use gms_project;


-- Data Exploration
SELECT * FROM db_combined
LIMIT 5;

-- Check null values
SELECT 
    COUNT(*) as total_rows,
    COUNT(fullvisitorid) as total_fullvisitorID,
    COUNT(visitid) as total_visitID
FROM db_combined;

-- Looking for a unique ID identificator
SELECT 
	visitid AS count_of_rows,
	COUNT(visitid) AS count_of_visitID
FROM db_combined
GROUP BY 1
HAVING count_of_visitID > 1; 

SELECT 
	fullvisitorid AS count_of_rows,
	COUNT(fullvisitorid) AS count_of_fullvisitorid
FROM db_combined
GROUP BY 1
HAVING count_of_fullvisitorid > 1; 

-- Concatenate full_visitor_id with session_id to get a unique identifier
SELECT
    CONCAT(fullvisitorid,"-",visitid) AS unique_identifier_id,
    COUNT(*) AS total_rows
FROM db_combined
GROUP BY 1
HAVING count(*)>1;

-- Double check the 2 rows with 2 records - The records are due to Pacific time zone and winter/summer Daylight Saving Time
SELECT
	CONCAT(fullvisitorid, '-', visitid) AS unique_session_id,
	FROM_UNIXTIME(date) + INTERVAL -9 HOUR AS date,
	COUNT(*) as total_rows
FROM db_combined
GROUP BY 1,2
HAVING unique_session_id IN ("0368176022600320212-1477983528", "4961200072408009421-1480578925")
LIMIT 5;

-- Engagement by day
SELECT 
		date,
        COUNT(DISTINCT(unique_session_id)) AS sessions
FROM (
		SELECT 
			DATE(FROM_UNIXTIME(date)) AS date,
            CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
        GROUP BY 1,2
) TABLE1
GROUP BY 1
ORDER BY 1;

-- Engagement by Weekday
SELECT 
		dayname(date) AS weekday,
        COUNT(DISTINCT(unique_session_id)) AS sessions
FROM (
		SELECT 
			DATE(FROM_UNIXTIME(date)) AS date,
            CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
        GROUP BY 1,2
) TABLE1
GROUP BY 1
ORDER BY 2 DESC;

-- Website Engagement and Monetization by Weekday
SELECT 
		DAYNAME(date) AS weekday,
        COUNT(DISTINCT unique_session_id) AS sessions,
        SUM(converted) AS conversions,
        (SUM(converted)/COUNT(DISTINCT unique_session_id)) AS conversion_rate
FROM (
		SELECT 
			DATE(FROM_UNIXTIME(date)) AS date,
            CASE
				WHEN transactions >= 1 THEN 1
                ELSE 0
			END as converted,
            CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
        GROUP BY 1,2,3
) TABLE1
GROUP BY 1
ORDER BY 2 DESC;

-- Website Engagement and Monetization by Device
SELECT 
		deviceCategory,
        COUNT(DISTINCT unique_session_id) AS sessions,
        ((COUNT(DISTINCT unique_session_id)/SUM(COUNT(DISTINCT unique_session_id)) OVER ())*100) AS session_percentage,
        SUM(transactionrevenue)/1e6 AS revenue,
        ((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER ())*100) AS revenue_percentage
	FROM (
		SELECT 
				deviceCategory,
				transactionrevenue,
				CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
-- 		GROUP BY 1,2,3
	) TABLE1
GROUP BY 1;

-- Website Engagement and Monetization by Region
SELECT 
		deviceCategory,
        region,
        COUNT(DISTINCT unique_session_id) AS sessions,
        ROUND(((COUNT(DISTINCT unique_session_id)/SUM(COUNT(DISTINCT unique_session_id)) OVER ())*100),2) AS session_percentage,
        SUM(transactionrevenue)/1e6 AS revenue,
        ROUND(((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER ())*100),2)
 AS revenue_percentage
	FROM (
		SELECT 
				deviceCategory,
                CASE
					WHEN region ='' OR region IS NULL THEN 'Unknown'
                    ELSE region
				END AS region,
				transactionrevenue,
				CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
        WHERE deviceCategory = 'mobile'
		GROUP BY 1,2,3,4
	) TABLE1
GROUP BY 1,2
ORDER BY 3 DESC;

-- Website Retention
SELECT 
	CASE
		WHEN newvisits = 1 THEN "New Visitor"
        ELSE "Returnig Visitor"
	END AS visitor_type,
    COUNT(DISTINCT(fullvisitorid)) as visitors,
	ROUND(((SUM(fullvisitorid)/SUM(SUM(fullvisitorid)) OVER ())*100),2) AS visitors_percentage
FROM db_combined
GROUP BY 1;

-- Website Acquisition
SELECT 
	COUNT(DISTINCT(unique_session_id)) AS sessions,
    SUM(bounces) AS bounces,
	(SUM(bounces)/COUNT(DISTINCT(unique_session_id)))*100 AS bounce_rate
FROM (
		SELECT 
			bounces,
			CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
-- 		GROUP BY 1,2
	) TABLE1
ORDER BY 1 DESC;

-- Website Acquisition by Channel
SELECT 
	channelGrouping,
	COUNT(DISTINCT(unique_session_id)) AS sessions,
    SUM(bounces) AS bounces,
	(SUM(bounces)/COUNT(DISTINCT(unique_session_id)))*100 AS bounce_rate
FROM (
		SELECT 
			channelGrouping,
            bounces,
			CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
-- 		GROUP BY 1,2,3
	) TABLE1
GROUP BY 1
ORDER BY 2 DESC;


-- Website Acquisition & Monetization by Channel
SELECT 
	channelGrouping,
	COUNT(DISTINCT(unique_session_id)) AS sessions,
    SUM(bounces) AS bounces,
	(SUM(bounces)/COUNT(DISTINCT(unique_session_id)))*100 AS bounce_rate,
    SUM(pageviews)/COUNT(DISTINCT(unique_session_id)) AS avg_pageonsite,
    SUM(timeonsite)/COUNT(DISTINCT(unique_session_id)) AS avg_timeonsite,
    SUM(CASE WHEN transactions >= 1 THEN 1 ELSE 0 END) AS conversions,
	SUM(CASE WHEN transactions >= 1 THEN 1 ELSE 0 END)/COUNT(DISTINCT(unique_session_id))*100 AS conversion_rate,
	SUM(transactionrevenue)/1e6 AS revenue
FROM (
		SELECT 
        channelGrouping,
        bounces, 
        pageviews, 
        timeonsite, 
        transactions, 
        transactionrevenue,
        CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
-- 		GROUP BY 1,2,3,4,5,6,7
	) TABLE1
GROUP BY 1
ORDER BY 2 DESC;