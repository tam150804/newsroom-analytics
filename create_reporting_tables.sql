-- Create analytics reporting tables from raw newsroom data

-- 1. Article Daily Metrics
CREATE TABLE article_daily_metrics AS
SELECT
    ae.article_id,
    DATE(ae.event_timestamp) AS date,
    COUNT(*) AS pageviews,
    AVG(ae.time_on_page_seconds) AS avg_time_on_page,
    AVG(ae.scroll_depth_pct) AS avg_scroll_depth,
    SUM(CASE WHEN ae.engaged_read THEN 1 ELSE 0 END) AS engaged_reads,
    SUM(CASE WHEN ae.clicked_subscription_offer THEN 1 ELSE 0 END) AS subscription_clicks,
    SUM(CASE WHEN ae.subscribed THEN 1 ELSE 0 END) AS subscriptions
FROM article_events ae
GROUP BY ae.article_id, DATE(ae.event_timestamp);

-- 2. Section Daily Metrics
CREATE TABLE section_daily_metrics AS
SELECT
    DATE(ae.event_timestamp) AS date,
    a.section,
    COUNT(*) AS total_pageviews,
    AVG(CASE WHEN ae.engaged_read THEN 1.0 ELSE 0.0 END) AS avg_engagement_rate,
    SUM(CASE WHEN ae.subscribed THEN 1 ELSE 0 END)::FLOAT / COUNT(*) AS subscription_rate
FROM article_events ae
JOIN articles a ON ae.article_id = a.article_id
GROUP BY DATE(ae.event_timestamp), a.section;

-- 3. Topic Device Metrics
CREATE TABLE topic_device_metrics AS
SELECT
    a.topic,
    s.device_type,
    COUNT(*) AS pageviews,
    AVG(ae.time_on_page_seconds) AS avg_time_on_page,
    AVG(CASE WHEN ae.engaged_read THEN 1.0 ELSE 0.0 END) AS engaged_read_rate,
    SUM(CASE WHEN ae.subscribed THEN 1 ELSE 0 END)::FLOAT / COUNT(*) AS conversion_rate
FROM article_events ae
JOIN articles a ON ae.article_id = a.article_id
JOIN sessions s ON ae.session_id = s.session_id
GROUP BY a.topic, s.device_type;

-- 4. Subscription Funnel Metrics
CREATE TABLE subscription_funnel_metrics AS
SELECT
    (SELECT COUNT(*) FROM sessions) AS total_sessions,
    (SELECT COUNT(*) FROM article_events) AS total_article_views,
    (SELECT SUM(CASE WHEN engaged_read THEN 1 ELSE 0 END) FROM article_events) AS engaged_reads,
    (SELECT SUM(CASE WHEN clicked_subscription_offer THEN 1 ELSE 0 END) FROM article_events) AS subscription_clicks,
    (SELECT SUM(CASE WHEN subscribed THEN 1 ELSE 0 END) FROM article_events) AS subscriptions;

-- 5. AB Test Summary
CREATE TABLE ab_test_summary AS
SELECT
    test_id,
    variant,
    COUNT(*) AS impressions,
    SUM(CASE WHEN click THEN 1 ELSE 0 END) AS clicks,
    SUM(CASE WHEN click THEN 1 ELSE 0 END)::FLOAT / COUNT(*) AS ctr,
    AVG(CASE WHEN engaged_read THEN 1.0 ELSE 0.0 END) AS engaged_read_rate,
    AVG(CASE WHEN subscription THEN 1.0 ELSE 0.0 END) AS subscription_rate
FROM ab_test_events
GROUP BY test_id, variant;