# Power BI Integration Guide

## Overview
This guide explains how to connect your newsroom analytics data to Microsoft Power BI for interactive dashboards and advanced analytics.

## Prerequisites
- Power BI Desktop (free download from Microsoft)
- Access to the newsroom analytics data files

## Data Sources

### File Locations
All data files are located in the `data/raw/` folder:
- `article_events.csv`
- `articles.csv`
- `sessions.csv`
- `users.csv`
- `ab_test_events.csv`

## Connecting Data to Power BI

### Step 1: Launch Power BI Desktop
1. Open Power BI Desktop
2. Click "Get Data" → "Text/CSV"
3. Navigate to `data/raw/article_events.csv`
4. Click "Load" to import the data

### Step 2: Import Additional Tables
Repeat the process for each CSV file:
1. "Get Data" → "Text/CSV"
2. Select each file
3. Click "Load"

### Step 3: Create Relationships
1. Go to "Model" view (bottom left)
2. Create relationships between tables:
   - `article_events.article_id` → `articles.article_id`
   - `article_events.session_id` → `sessions.session_id`
   - `sessions.user_id` → `users.user_id`
   - `ab_test_events.user_id` → `users.user_id`
   - `ab_test_events.session_id` → `sessions.session_id`
   - `ab_test_events.article_id` → `articles.article_id`

## Data Transformation (Power Query)

### Clean and Transform Data
1. Go to "Home" → "Transform Data"
2. For each table, apply transformations:

#### Article Events Table
```
- Change data types:
  - event_timestamp: Date/Time
  - time_on_page_seconds: Decimal Number
  - scroll_depth_pct: Decimal Number
  - engaged_read, clicked_subscription_offer, subscribed: True/False
- Add custom columns:
  - Hour of Day: Time.Hour([event_timestamp])
  - Day of Week: Date.DayOfWeekName([event_timestamp])
  - Is Weekend: if Date.DayOfWeek([event_timestamp]) >= 5 then "Weekend" else "Weekday"
```

#### Articles Table
```
- Change data types:
  - publish_date: Date
  - word_count, headline_length: Whole Number
  - paywalled: True/False
- Add custom columns:
  - Content Age: Duration.Days(DateTime.LocalNow() - [publish_date])
  - Word Count Category:
    if [word_count] < 500 then "Short"
    else if [word_count] < 1000 then "Medium"
    else if [word_count] < 2000 then "Long"
    else "Very Long"
```

#### Sessions Table
```
- Change data types:
  - session_start: Date/Time
- Add custom columns:
  - Session Hour: Time.Hour([session_start])
  - Session Duration: // Calculate if you have end times
```

### Create Calculated Columns and Measures

#### Key Measures (DAX)
Create these measures in each relevant table:

**Article Events Table:**
```
Total Pageviews = COUNTROWS('article_events')

Engaged Reads = SUM('article_events'[engaged_read])

Engagement Rate = DIVIDE([Engaged Reads], [Total Pageviews])

Avg Time on Page = AVERAGE('article_events'[time_on_page_seconds])

Avg Scroll Depth = AVERAGE('article_events'[scroll_depth_pct])

Total Subscriptions = SUM('article_events'[subscribed])

Subscription Rate = DIVIDE([Total Subscriptions], [Total Pageviews])
```

**Articles Table:**
```
Article Views = CALCULATE(COUNTROWS('article_events'), ALLEXCEPT('articles', 'articles'[article_id]))

Article Engagement Rate = CALCULATE([Engagement Rate], ALLEXCEPT('articles', 'articles'[article_id]))

Article Avg Time = CALCULATE([Avg Time on Page], ALLEXCEPT('articles', 'articles'[article_id]))
```

**Sessions Table:**
```
Session Pageviews = CALCULATE(COUNTROWS('article_events'), ALLEXCEPT('sessions', 'sessions'[session_id]))

Session Engagement = CALCULATE([Engaged Reads], ALLEXCEPT('sessions', 'sessions'[session_id]))
```

**A/B Test Events Table:**
```
Test Impressions = SUM('ab_test_events'[impression])

Test Clicks = SUM('ab_test_events'[click])

Test CTR = DIVIDE([Test Clicks], [Test Impressions])

Test Engaged Reads = SUM('ab_test_events'[engaged_read])

Test Subscriptions = SUM('ab_test_events'[subscription])
```

## Building Dashboards

### Overview Page
1. **Cards:** Total Pageviews, Engaged Reads, Subscriptions, Engagement Rate
2. **Line Chart:** Daily engagement trend
   - X-axis: Date (from article_events[event_timestamp])
   - Y-axis: Engagement Rate
3. **Pie Chart:** Traffic source distribution
4. **Bar Chart:** Top sections by pageviews

### Article Performance Page
1. **Table:** Top articles
   - Fields: Title, Section, Views, Engagement Rate, Avg Time
   - Sort by: Views descending
2. **Scatter Plot:** Time on page vs scroll depth
   - X-axis: Avg Time on Page
   - Y-axis: Avg Scroll Depth
   - Size: Pageviews
   - Color: Section
3. **Bar Chart:** Engagement by format type
4. **Slicers:** Date range, Section, Format Type

### Audience Analysis Page
1. **Column Chart:** Device type comparison
   - X-axis: Device Type
   - Y-axis: Pageviews, Engagement Rate (secondary axis)
2. **Heatmap:** Engagement by hour and day
   - Rows: Day of Week
   - Columns: Hour of Day
   - Values: Engagement Rate
3. **Map:** Engagement by country
   - Location: Country
   - Size: Pageviews
   - Color: Engagement Rate
4. **Area Chart:** User acquisition over time

### A/B Testing Page
1. **Cards:** CTR for Variant A, CTR for Variant B, Statistical Significance
2. **Bar Chart:** Performance comparison
   - X-axis: Metric (CTR, Engaged Read Rate, Subscription Rate)
   - Y-axis: Value
   - Legend: Variant
3. **Line Chart:** Test performance over time
4. **Table:** Detailed test results

## Advanced Analytics

### Time Intelligence
Add time-based calculations:
```
This Month Pageviews = CALCULATE([Total Pageviews], DATESMTD('Date'[Date]))

Last Month Pageviews = CALCULATE([Total Pageviews], DATEADD('Date'[Date], -1, MONTH))

Month over Month Growth = DIVIDE(([This Month Pageviews] - [Last Month Pageviews]), [Last Month Pageviews])
```

### Segmentation
Create user segments:
```
High Value Users = IF([Session Pageviews] > 5 && [Engagement Rate] > 0.5, "High Value", "Regular")
```

### Forecasting
Use Power BI's built-in forecasting:
1. Create a line chart with date and engagement rate
2. Right-click the line → "Add Forecast"

## Publishing and Sharing

### Publish to Power BI Service
1. "File" → "Publish to Power BI"
2. Sign in to your Power BI account
3. Select workspace
4. Click "Publish"

### Schedule Data Refresh
1. In Power BI Service, go to dataset settings
2. Configure gateway for on-premises data
3. Set refresh schedule

### Share with Stakeholders
1. Create app workspace
2. Add reports and dashboards
3. Publish app
4. Share with specific users or groups

## Power BI Best Practices

### Performance Optimization
- Use summarized tables for large datasets
- Avoid calculated columns when possible (use measures)
- Limit visuals on single pages
- Use appropriate aggregation levels

### Data Modeling
- Star schema design
- Consistent naming conventions
- Hide unnecessary columns
- Create hierarchies for drill-down

### Security
- Implement Row-Level Security (RLS) for sensitive data
- Use Power BI security groups
- Encrypt sensitive connections

## Troubleshooting

### Common Issues
- **Import Errors:** Check CSV formatting and file paths
- **Relationship Errors:** Verify key field data types match
- **Performance Issues:** Use DirectQuery for large datasets or create aggregations
- **Refresh Failures:** Check data source credentials and network connectivity

### Resources
- Power BI Community
- Microsoft Learn: Power BI training
- Power BI Blog for latest features

This integration enables powerful, interactive analytics with your newsroom data using Power BI's robust visualization and AI capabilities.