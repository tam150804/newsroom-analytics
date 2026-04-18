# Tableau Integration Guide

## Overview
This guide explains how to connect your newsroom analytics data to Tableau for advanced visualization and analysis.

## Prerequisites
- Tableau Desktop or Tableau Server
- Access to the newsroom analytics data files

## Data Sources

### 1. Article Events Data
**File:** `data/raw/article_events.csv`
**Description:** Detailed user interactions with articles

**Key Fields:**
- `event_id`: Unique event identifier
- `session_id`: User session identifier
- `user_id`: Anonymous user identifier
- `article_id`: Article identifier
- `event_timestamp`: When the event occurred
- `pageviews`: Number of pageviews (usually 1)
- `time_on_page_seconds`: Time spent on page
- `scroll_depth_pct`: How far user scrolled (0-100%)
- `engaged_read`: Boolean indicating engaged reading
- `clicked_subscription_offer`: Boolean for subscription clicks
- `subscribed`: Boolean for successful subscriptions

### 2. Articles Data
**File:** `data/raw/articles.csv`
**Description:** Article metadata

**Key Fields:**
- `article_id`: Unique article identifier
- `publish_date`: When article was published
- `title`: Article title
- `section`: News section (politics, business, tech, etc.)
- `author`: Article author
- `format_type`: Article format (news, analysis, opinion, feature)
- `topic`: Article topic (same as section)
- `word_count`: Article length
- `headline_length`: Length of headline
- `paywalled`: Whether article is behind paywall

### 3. Sessions Data
**File:** `data/raw/sessions.csv`
**Description:** User session information

**Key Fields:**
- `session_id`: Unique session identifier
- `user_id`: User identifier
- `session_start`: When session began
- `traffic_source`: How user arrived (direct, search, social, newsletter)
- `device_type`: User's device (mobile, desktop)

### 4. Users Data
**File:** `data/raw/users.csv`
**Description:** User demographic information

**Key Fields:**
- `user_id`: Unique user identifier
- `signup_date`: When user signed up
- `country`: User's country
- `device_preference`: Preferred device type
- `subscriber_status`: Whether user is a subscriber

### 5. A/B Test Events Data
**File:** `data/raw/ab_test_events.csv`
**Description:** A/B test experiment data

**Key Fields:**
- `test_id`: Test identifier
- `user_id`: User identifier
- `session_id`: Session identifier
- `article_id`: Article identifier
- `variant`: Test variant (A or B)
- `impression`: Whether user saw the test
- `click`: Whether user clicked
- `engaged_read`: Whether user engaged
- `subscription`: Whether user subscribed
- `event_timestamp`: When event occurred

## Connecting to Tableau

### Step 1: Launch Tableau and Connect to Data
1. Open Tableau Desktop
2. Click "Connect" → "To a File" → "Text file"
3. Navigate to the `data/raw/` folder
4. Select the CSV files you want to analyze

### Step 2: Join the Data Sources
Since the data is normalized across multiple tables, you'll need to create joins:

1. **Primary Data Source:** article_events.csv
2. **Join articles.csv** on `article_id`
3. **Join sessions.csv** on `session_id`
4. **Join users.csv** on `user_id` (from sessions)

### Step 3: Create Calculated Fields

#### Engagement Metrics
```
Engagement Rate: SUM([engaged_read]) / SUM([pageviews])
```

```
Avg Time on Page: AVG([time_on_page_seconds])
```

```
Scroll Depth Category:
IF [scroll_depth_pct] < 25 THEN "Low"
ELSEIF [scroll_depth_pct] < 50 THEN "Medium"
ELSEIF [scroll_depth_pct] < 75 THEN "High"
ELSE "Very High"
END
```

#### Time-based Calculations
```
Hour of Day: DATEPART('hour', [event_timestamp])
```

```
Day of Week: DATEPART('weekday', [event_timestamp])
```

```
Is Weekend: [Day of Week] >= 6
```

#### Content Performance
```
Content Age (Days): DATEDIFF('day', [publish_date], [event_timestamp])
```

```
Word Count Category:
IF [word_count] < 500 THEN "Short"
ELSEIF [word_count] < 1000 THEN "Medium"
ELSEIF [word_count] < 2000 THEN "Long"
ELSE "Very Long"
END
```

## Recommended Dashboard Layout

### Overview Dashboard
- **KPIs:** Total pageviews, engaged reads, subscriptions, avg engagement rate
- **Trend Chart:** Daily engagement over time
- **Pie Chart:** Traffic source distribution
- **Bar Chart:** Top sections by engagement

### Article Performance Dashboard
- **Table:** Top articles by various metrics
- **Scatter Plot:** Time on page vs scroll depth
- **Bar Chart:** Engagement by article format
- **Filters:** Date range, section, format type

### Audience Analysis Dashboard
- **Bar Chart:** Device type comparison
- **Heatmap:** Engagement by hour and day
- **Geographic Map:** Engagement by country
- **Cohort Analysis:** User behavior over time

### A/B Testing Dashboard
- **Value Boxes:** CTR for each variant
- **Bar Chart:** Performance comparison across metrics
- **Statistical Test Results:** Significance indicators
- **Time Series:** Performance over test duration

## Advanced Analytics in Tableau

### Predictive Analytics
Use Tableau's built-in forecasting:
1. Right-click on measure → "Forecast" → "Show Forecast"
2. Configure forecast options for engagement trends

### Clustering
Create user segments:
1. Drag relevant dimensions/measures to view
2. Analysis → "Cluster" → Configure clusters

### Custom SQL
For complex queries:
1. Connect → "To a Server" → Your database
2. Use custom SQL to join tables efficiently

## Publishing and Sharing

### Publish to Tableau Server
1. File → "Publish As" → Enter name and project
2. Configure permissions and scheduling
3. Share link with stakeholders

### Export Options
- **PDF:** For static reports
- **PowerPoint:** For presentations
- **Images:** For embedding in other documents

## Best Practices

1. **Performance:** Use extracts for large datasets
2. **Data Refresh:** Schedule regular data updates
3. **Security:** Implement row-level security for sensitive data
4. **Documentation:** Add descriptions to worksheets and dashboards
5. **Version Control:** Save workbooks with version numbers

## Troubleshooting

### Common Issues
- **Data Type Errors:** Check CSV formatting and data types
- **Join Errors:** Verify key fields match exactly
- **Performance Issues:** Create extracts or aggregate data
- **Missing Data:** Check for NULL values and handle appropriately

### Getting Help
- Tableau Community Forums
- Tableau Online Help
- Your organization's Tableau administrator

This integration allows you to leverage Tableau's powerful visualization capabilities with your newsroom analytics data for deeper insights and better decision-making.