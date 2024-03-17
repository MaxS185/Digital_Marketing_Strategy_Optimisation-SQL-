# Digital_Marketing_Strategy_Optimisation (SQL)
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
First, we’ll examine the ```fullvisitorid``` and ```visitid``` columns for null values. Ensuring there are no NULL values in this key column is essential for the integrity of our dataset.
To get a sense of the data we're working with, we’ll take a look at the first few rows of the table. This allows us to see what columns are available and the kind of data each column contains.
``` 
SELECT 
    COUNT(*) as total_rows,
    COUNT(fullvisitorid) as total_fullvisitorID,
    COUNT(visitid) as total_visitID
FROM db_combined;
```
![image](https://github.com/MaxS185/Digital_Marketing_Strategy_Optimisation_SQL/assets/48988778/cf0e69e9-9289-4ed9-88be-4f13bee5b103)

It appears that there are no NULL values in the ```visitid``` and ```fullvisitorid``` column, indicating that each session captured in the data has been assigned an identifier. The absence of NULL values in this key columns is a positive sign for data integrity.
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
