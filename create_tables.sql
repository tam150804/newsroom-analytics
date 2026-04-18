-- Create tables for newsroom analytics database

-- Users table
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    signup_date DATE,
    country VARCHAR(50),
    device_preference VARCHAR(20),
    subscriber_status BOOLEAN
);

-- Articles table
CREATE TABLE articles (
    article_id INTEGER PRIMARY KEY,
    publish_date DATE,
    title TEXT,
    section VARCHAR(50),
    author VARCHAR(100),
    format_type VARCHAR(20),
    topic VARCHAR(50),
    word_count INTEGER,
    headline_length INTEGER,
    paywalled BOOLEAN
);

-- Sessions table
CREATE TABLE sessions (
    session_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    session_start TIMESTAMP,
    traffic_source VARCHAR(20),
    device_type VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Article events table
CREATE TABLE article_events (
    event_id INTEGER PRIMARY KEY,
    session_id INTEGER,
    user_id INTEGER,
    article_id INTEGER,
    event_timestamp TIMESTAMP,
    pageviews INTEGER,
    time_on_page_seconds NUMERIC,
    scroll_depth_pct NUMERIC(5,2),
    engaged_read BOOLEAN,
    clicked_subscription_offer BOOLEAN,
    subscribed BOOLEAN,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (article_id) REFERENCES articles(article_id)
);

-- AB test events table
CREATE TABLE ab_test_events (
    test_id VARCHAR(50),
    user_id INTEGER,
    session_id INTEGER,
    article_id INTEGER,
    variant CHAR(1),
    impression SMALLINT,
    click BOOLEAN,
    engaged_read BOOLEAN,
    subscription BOOLEAN,
    event_timestamp TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (session_id) REFERENCES sessions(session_id),
    FOREIGN KEY (article_id) REFERENCES articles(article_id)
);