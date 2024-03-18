# Digital Marketing Strategy Optimisation (SQL)
### Dataset

We'll be exploring the [Google Merchandise Store](https://www.googlemerchandisestore.com/) dataset, containing data on website users from the US from October 1, 2016, to December 31, 2016. This dataset is sourced from the Google Merchandise Store, a real e-commerce platform offering Google-branded merchandise, including apparel, lifestyle products, and stationery from Google and its brands. While some sensitive fields have been obfuscated for privacy reasons, this dataset provides a unique opportunity to analyze actual customer behavior and trends in an e-commerce setting.

*Disclaimer: for this analysis, certain fields within the dataset have been aggregated. The original dataset is available as a public dataset in Google BigQuery.*

### Situation
The Google Marketing Team in the US was facing challenges in several key areas of their online business. Despite having a robust platform and a diverse range of products, the company was not fully leveraging its potential. With various strategies and channels in play, it was quite challenging to accurately assess the impact of different marketing initiatives and prove their effectiveness to stakeholders.

To address these challenges, the Google Marketing Team focused on gaining insights into several key areas:

- How do users interact with our e-commerce platform? Are there specific user behaviors or patterns that can inform our marketing strategies?
- How effective are our promotional campaigns and discount strategies in driving sales? Do these initiatives lead to long-term customer retention or only short-term gains?
- How does the user experience on our website and mobile app impact sales and customer engagement? Are there areas in need of improvement?
- Which geographical markets or customer segments are most profitable? Are there emerging markets or segments that we should focus on?
- How effective are our current strategies in acquiring new customers and retaining existing ones?
- Which traffic channels are yielding the highest conversion rates? What are the underlying reasons for variations in conversion rates across different channels?

### Task
As marketing analyst my task involved conducting a detailed analysis of the e-commerce platform's performance.
My main objective was to develop actionable strategies that would enhance overall performance. This included focusing on key areas such as customer acquisition, retention, monetization, and more efficient use of marketing channels.
The ultimate aim was to significantly boost overall revenue.

### Action
As marketing analyst I used SQL to create a database and merge multiple datasets into a unified one for in-depth analysis, followed by thorough data preprocessing, including cleansing to ensure accuracy and reliability.
I then conducted advanced analyses using advanced string, date and window functions to gain deeper insights into the website's performance, focusing on user interactions and the effectiveness of the e-commerce strategies.
Additionally, I analyzed various web traffic sources to identify the most effective channels for driving sales and conversions, turning data into actionable business intelligence.

### Set Up & Datasets
In MySQL Workbench, I have created a new database called ``` gms_project ```, and it will be used to store tables and data as part of our project.
``` 
create database gms_project;
```
First task is to create a unified view of the data across the three months. The combined dataset will serve as the base of our analysis.
Then We will "use" the the gsm_project database, since it contains all we need, and it will allow us to refer only to the table needed.
``` 
CREATE TABLE gms_project.db_combined as (
    SELECT * FROM gms_project.data_oct
    UNION ALL
    SELECT * FROM gms_project.data_nov
    UNION ALL
    SELECT * FROM gms_project.data_dec
);

USE gms_project;
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/bd7ff61b-6933-4a4d-a19e-e8fbfd4d5c95)

### Data Exploration
To get a sense of the data we're working with, we’ll take a look at the first few rows of the table. This allows us to see what columns are available and the kind of data each column contains.
``` 
SELECT * FROM db_combined
LIMIT 5;
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/29f0a306-d88f-4a9d-94ba-fb80ba15e078)

**Column Overview:** The dataset contains rows with identifiers like ```fullvisitorid``` and ```visitid```, along with date of visits, and details of traffic sources in the ```channelGrouping```, ```source```, and ```medium``` columns. It offers insights into user engagement through metrics such as visits, pageviews, time on website, and bounces. Additionally, it includes e-commerce data like transactions and revenue, user-specific information (operating system, mobile device usage, device type), and geographical data (region, country, continent, subcontinent). Some fields, like ```adcontent```, are missing data.

**Row Overview:** At first glance, it seems that each row represents a single session on the website. The ```visitid``` column appears to be a unique identifier for each session, and therefore, needs closer investigation. 
First, we’ll examine the ```fullvisitorid``` and ```visitid``` columns for ```NULL``` values. Ensuring there are no ```NULL``` values in this key column is essential for the integrity of our dataset.
To get a sense of the data we're working with, we’ll take a look at the first few rows of the table. This allows us to see what columns are available and the kind of data each column contains.
``` 
SELECT 
    COUNT(*) as total_rows,
    COUNT(fullvisitorid) as total_fullvisitorID,
    COUNT(visitid) as total_visitID
FROM db_combined;
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/cf0e69e9-9289-4ed9-88be-4f13bee5b103)

It appears that there are no ```NULL``` values in the ```visitid``` and ```fullvisitorid``` column, indicating that each session captured in the data has been assigned an identifier. The absence of ```NULL``` values in this key columns is a positive sign for data integrity.
Next, we'll check for duplicate values in ```visitid```.
```
SELECT 
	visitid AS count_of_rows,
	COUNT(visitid) AS count_of_visitID
FROM db_combined
GROUP BY 1
HAVING count_of_visitID > 1; 

```
<img width="855" alt="4 duplicates1" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/ec0ba82a-8c10-40d2-a057-66fcd671355c">

The ```visitid``` column in the dataset, while seemingly unique, does not serve as a unique identifier for each session. This is because ```visitid``` represents the timestamp when a visit or session begins. Since multiple visitors can start their sessions at the same exact time, ```visitid``` alone is not sufficient to uniquely identify each session.

To create a unique identifier for each session, we need to combine ```visitid``` with another column, ```fullvisitorid```. 
The ```fullvisitorid``` column uniquely identifies each visitor to the website. By concatenating ```fullvisitorid``` and ```visitid```, we can create a new identifier that is unique for each session. This new identifier will ensure that each session is distinctly recognized, even if multiple sessions start at the same time.
```
SELECT
    CONCAT(fullvisitorid,"-",visitid) AS unique_identifier_id,
    COUNT(*) AS total_rows
FROM db_combined
GROUP BY 1
HAVING count(*)>1;
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/30220491-1ca6-419d-9d6d-fb2ddf21f9ce)

From the analysis of the data, it appears that we still have two duplicate entries. This is likely due to how sessions are tracked around midnight. In many web analytics systems, a visitor's session is reset at midnight. This means that if a visitor is active on the website across midnight, their activity before and after midnight is counted as two separate sessions. However, if the visitid is based on the start time of the session, then the visitor will have the same visitid for both sessions. When we concatenate this visitid with the fullvisitorid, the resulting unique_session_id will be the same for both sessions. Therefore, despite being on the website across two different sessions (before and after midnight), the visitor appears in our data with the same unique_session_id for both sessions. Let’s examine one example.

*Note: Our dataset timestamps are in UTC (Coordinated Universal Time), the main time standard used globally, which remains constant year-round. As our analysis focuses on US data, we'll convert these timestamps to PDT (Pacific Daylight Time) or PST (Pacific Standard Time).*
```
SELECT
	CONCAT(fullvisitorid, '-', visitid) AS unique_session_id,
	FROM_UNIXTIME(date) + INTERVAL -9 HOUR AS date,
	COUNT(*) as total_rows
FROM db_combined
GROUP BY 1,2
HAVING unique_session_id IN ("0368176022600320212-1477983528", "4961200072408009421-1480578925")
LIMIT 5;
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/a9eeca45-29e9-4bb0-b41b-81d11322ca39)
In our analysis, we acknowledge this scenario and have decided to treat these two sessions as a single continuous session, maintaining the same ```unique_session_id```. This approach aligns with our analytical objectives and simplifies our dataset. Therefore, we won't modify the session tracking mechanism to separate these instances into distinct sessions.


### Insights
##### Website Engagement by Day
Now that we have a basic understanding of our dataset, we're ready to delve into a more detailed analysis. First, we'll explore daily web traffic to gain insights into overall website performance. This initial step will reveal key traffic patterns and trends in visitor behavior.

*Note: For simplicity, our analysis will use UTC time for all timestamps, avoiding the complexities of time zone conversions and Daylight Saving Time adjustments.*
```
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
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/4999e816-e933-488d-b844-68022bd92462)
![6 engagbydaychart](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/95b80625-0ed9-456f-bb00-5df33154b6e3)

We observe an uptick in web traffic as we approach the holiday season in December. 
In addition, web traffic consistently peaks during weekdays and tapers off during weekends. 
To better illustrate this trend, we'll extract the name of the day from the visit date.
```
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
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/19b85315-5a66-469f-b13c-d7bff9f1df59)

##### Website Engagement & Monetization by Device
We can further refine our analysis by examining the data by device type, which will reveal variations in conversion rates and visits across desktops, tablets, and smartphones. This device-specific insight is key for optimizing website design and marketing for each device category.

*Note: in the dataset, revenue is expressed in millions. To interpret these figures accurately, we’ll divide them by 10^6 to get the original dollar amount.*
```
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
	) TABLE1
GROUP BY 1;
```
<img width="854" alt="8 engagbydevice" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/d886e4ae-e1f2-41fc-a908-f258f20d226d">

While ~25% of sessions originate from mobile devices, only 5% of revenue is generated through them. This significant discrepancy suggests a need to optimize the mobile shopping experience. 
Marketing strategies should focus on enhancing mobile usability, streamlining the checkout process, and tailoring mobile-specific promotions. Considering the significant number of users who shop on their mobile devices during commutes or workday breaks, a seamless mobile experience on our e-commerce platform is crucial. To further tap into this growing user base, Google might also consider for example developing a dedicated mobile app, which could substantially increase revenue from mobile users.

##### Website Engagement & Monetization by Region
We can analyze these numbers further to determine if there are regional differences affecting mobile device usage and revenue generation. This deeper dive will help us understand whether certain regions have higher mobile engagement or sales, guiding targeted marketing strategies and region-specific optimizations.

```
SELECT 
	deviceCategory,
	region,
	COUNT(DISTINCT unique_session_id) AS sessions,
	ROUND(((COUNT(DISTINCT unique_session_id)/SUM(COUNT(DISTINCT unique_session_id)) OVER ())*100),2) AS session_percentage,
	SUM(transactionrevenue)/1e6 AS revenue,
	ROUND(((SUM(transactionrevenue)/SUM(SUM(transactionrevenue)) OVER ())*100),2) AS revenue_percentage
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
```
<img width="854" alt="9 engagbyregion" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/f4e60649-fe06-4edf-8cb5-4f65bd39515d">

The data shows that while only 1% of mobile sessions are from Washington, they contribute to 11% of revenue. Similarly, Illinois sees 3% of sessions but accounts for 9% of revenue. This suggests an untapped opportunity, as these regions have higher conversion rates or transaction values despite fewer sessions. Focusing marketing efforts on these regions could potentially increase revenue, leveraging their higher purchasing effectiveness. Potential approaches could include targeted marketing campaigns, localized promotions, or even exploring the reasons behind the higher conversion rates, such as product preferences or purchasing power.

One limitation in our analysis arises from the fact that some mobile sessions in the dataset are not mapped to any specific region. This means that for a subset of mobile sessions, the ```region``` field is either left blank or marked as ```NULL```, indicating that the geographic location of these users is unknown or not recorded. Addressing this issue with the Data Engineering team could be vital for ensuring more accurate and comprehensive data for future analyses.

##### Website Retention
Next, we’ll examine website retention, specifically focusing on whether users are new or returning. This will provide insights into user loyalty and the effectiveness of strategies in encouraging repeat visits.
```
SELECT 
	CASE
		WHEN newvisits = 1 THEN "New Visitor"
		ELSE "Returnig Visitor"
		END AS visitor_type,
	COUNT(DISTINCT(fullvisitorid)) as visitors,
	ROUND(((SUM(fullvisitorid)/SUM(SUM(fullvisitorid)) OVER ())*100),2) AS visitors_percentage
FROM db_combined
GROUP BY 1;
```
<img width="854" alt="10 website_retention" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/e45d7138-c9c5-4b8e-a551-472903da2a8a">

Interestingly, about 80% of users visit the website only once. Typically, having around 50-70% new users and 30-50% returning users is considered a good balance. 
This statistic suggests a need for better incentives or value propositions to encourage repeat visits, presenting a major opportunity for enhanced retention strategies such as personalized marketing, loyalty programs, or targeted retargeting campaigns. 
In contrast, the substantial influx of new visitors reflects successful marketing efforts in brand awareness, effectively attracting people to the site initially. Key factors like a user-friendly interface, engaging content, and smooth navigation play a crucial role here.

##### Website Acquisition
Building on this analysis, the next logical step is to calculate the bounce rate. This measure is key as it indicates the proportion of visitors who exit the site after viewing only one page and is often used to evaluate the effectiveness of acquisition strategies. A high bounce rate can indicate that the landing page or the initial content isn't meeting the expectations of visitors or isn't engaging enough to encourage further exploration of the site or purchases. Understanding the bounce rate offers valuable insights into the site's initial engagement success with its audience.
```
SELECT 
	COUNT(DISTINCT(unique_session_id)) AS sessions,
	SUM(bounces) AS bounces,
	(SUM(bounces)/COUNT(DISTINCT(unique_session_id)))*100 AS bounce_rate
FROM (
	SELECT 
		bounces,
		CONCAT(fullvisitorid, '-', visitid) AS unique_session_id
		FROM db_combined
	) TABLE1
ORDER BY 1 DESC;
```
<img width="854" alt="11 websiteaquisition_bounces" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/5e4d0202-d5b3-43c1-8322-435c798993a2">

##### Website Acquisition by Channel
Moving forward, we'll delve into the bounce rate by channel to gain a clearer picture of the effectiveness of various marketing strategies. This will also shed light on user engagement across diverse traffic sources, providing valuable insights for optimizing our outreach efforts.
```
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
	) TABLE1
GROUP BY 1
ORDER BY 2 DESC;
```
<img width="854" alt="12 webaquisition_channel" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/95d9d036-eaff-493b-9ac5-42a3e06ea87f">

##### Website Acquisition & Monetization by Channel
Building on our analysis of visits and bounce rates by channel, we'll next include key metrics like time on site, revenue, and conversion rate. 
This broader evaluation will give us a fuller view of each channel's performance, encompassing not only traffic volume but also user engagement quality, revenue generation efficiency, and overall conversion impact.
```
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
) TABLE1
GROUP BY 1
ORDER BY 2 DESC;
```
<img width="856" alt="13 webaquisitionmonetization_channel" src="https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/3a08b5ba-6e0e-4fa1-8239-d8e6b6def9cb">

Referral leads with the lowest bounce rate and highest conversion at 7%, driving strong revenue, making it a prime candidate for expanded partnerships. Organic Search, with the most sessions and a solid 32% bounce rate, shows robust SEO efficacy and good conversion potential. Direct traffic, while high at a 46% bounce rate, has moderate conversions, suggesting a need for more personalized engagement. Social media, despite high traffic, suffers from the lowest conversions, calling for more targeted campaigns. Paid Search and Display, both with 34% bounce rates, demonstrate moderate visitor retention but require improved targeting for better conversions. Lastly, Affiliates, with the highest bounce rate and lowest conversions, need a thorough evaluation of partner quality.

### Results
In cocnlusion, here below a recap of recommendations to summarize the key strategies and insights derived from this analysis.
1. **Seasonal and Holiday Campaigns**: During key periods, such as the December holidays, create themed promotions and exclusive holiday deals. Develop holiday guides, offer limited-time discounts, and run festive-themed marketing campaigns to attract shoppers. Replicating this strategy in other months could potentially lead to an uplift in revenue, akin to what is typically seen in December (around 25%).
2. **Maximize Monday Conversions**: With Mondays having the highest conversion rates but lower traffic, aim to boost Monday traffic by at least 10% to reach Tuesday levels. Launch start-of-the-week promotions and exclusive deals, and actively promote these through targeted email and social media campaigns early in the week.
3. **Targeted Weekday Promotions**: Leverage the high traffic on Tuesdays and Wednesdays with special promotions and deals. Tailor your email marketing and social media campaigns to coincide with these peak days, ensuring promotions reach users when they are most active online.
4. **Weekend Engagement Strategies**: Use retargeting ads to re-engage weekday visitors with special weekend promotions. Implement loyalty programs offering rewards for weekend shopping to boost off-peak traffic and sales.
5. **Enhance Mobile Experience**: With 25% of sessions but only 5% of revenue coming from mobile, and considering that many users shop during commutes or workday breaks, focus on improving the mobile shopping experience. This could involve optimizing the mobile site's user interface, offering mobile-specific deals, or enhancing mobile payment options.
6. **Focus on High-Value Regions**: Address the disproportionate revenue contribution from Washington and Illinois. Develop targeted marketing strategies for these regions, possibly with localized offers or campaigns, to capitalize on their higher spending patterns.
7. **Strengthen User Engagement and Retention**: With 80% one-time visitors, target at least a 10% increase in repeat visits by enhancing the user experience for first-time visitors through personalized content, retargeting campaigns, and loyalty programs. Focus on engaging direct traffic with personalized strategies to reduce its high bounce rate.
8. **Optimize Referral and Organic Channels**: Due to their low bounce rate and high conversion, aim to increase referral traffic by 15/20% through expanded partnerships. Continue to improve SEO for Organic Search, which shows robust session numbers and a good potential for conversions.
9. **Revamp Social Media and Paid Channels**: Redesign social media campaigns for higher engagement and conversion. Improve targeting in Paid Search and Display advertising to reduce the 34% bounce rate and enhance visitor retention.
10. **Reevaluate and Enhance Affiliate Strategies**: Thoroughly assess affiliate partnerships, focusing on the quality and relevance to address their high bounce rate and low conversions. Restructure or terminate underperforming affiliations to improve efficiency.
These recommendations aim to capitalize on identified trends and insights, maximizing revenue opportunities throughout the year.
