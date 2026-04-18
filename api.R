# plumber.R

library(plumber)
library(tidyverse)
library(jsonlite)

# Load data and models
articles <- read_csv("data/raw/articles.csv", show_col_types = FALSE)
users <- read_csv("data/raw/users.csv", show_col_types = FALSE)
sessions <- read_csv("data/raw/sessions.csv", show_col_types = FALSE)
article_events <- read_csv("data/raw/article_events.csv", show_col_types = FALSE)
ab_test_events <- read_csv("data/raw/ab_test_events.csv", show_col_types = FALSE)

# Load models if they exist
rf_model <- tryCatch(readRDS("outputs/models/rf_engagement_model.rds"), error = function(e) NULL)
xgb_model <- tryCatch(readRDS("outputs/models/xgb_engagement_model.rds"), error = function(e) NULL)

#* @apiTitle Newsroom Analytics API
#* @apiDescription REST API for newsroom analytics data and predictions

#* Get article metrics
#* @param article_id Article ID
#* @get /article/<article_id>
function(article_id) {
  article_id <- as.integer(article_id)

  article <- articles %>% filter(article_id == !!article_id)
  if (nrow(article) == 0) {
    return(list(error = "Article not found"))
  }

  metrics <- article_events %>%
    filter(article_id == !!article_id) %>%
    summarise(
      total_views = n(),
      avg_time_on_page = mean(time_on_page_seconds, na.rm = TRUE),
      avg_scroll_depth = mean(scroll_depth_pct, na.rm = TRUE),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      total_subscriptions = sum(subscribed, na.rm = TRUE)
    )

  result <- article %>%
    left_join(metrics, by = character()) %>%
    as.list()

  return(result)
}

#* Get user metrics
#* @param user_id User ID
#* @get /user/<user_id>
function(user_id) {
  user_id <- as.integer(user_id)

  user <- users %>% filter(user_id == !!user_id)
  if (nrow(user) == 0) {
    return(list(error = "User not found"))
  }

  user_sessions <- sessions %>% filter(user_id == !!user_id)
  user_events <- article_events %>% filter(user_id == !!user_id)

  metrics <- list(
    user_info = as.list(user),
    total_sessions = nrow(user_sessions),
    total_article_views = nrow(user_events),
    avg_engagement = mean(user_events$engaged_read, na.rm = TRUE),
    total_subscriptions = sum(user_events$subscribed, na.rm = TRUE)
  )

  return(metrics)
}

#* Get section performance
#* @param section Article section
#* @get /section/<section>
function(section) {
  section_data <- article_events %>%
    left_join(articles, by = "article_id") %>%
    filter(section == !!section)

  if (nrow(section_data) == 0) {
    return(list(error = "Section not found"))
  }

  metrics <- section_data %>%
    summarise(
      total_views = n(),
      avg_time_on_page = mean(time_on_page_seconds, na.rm = TRUE),
      avg_scroll_depth = mean(scroll_depth_pct, na.rm = TRUE),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      subscription_rate = mean(subscribed, na.rm = TRUE)
    )

  return(as.list(metrics))
}

#* Get A/B test results
#* @param test_id Test ID
#* @get /ab_test/<test_id>
function(test_id) {
  test_data <- ab_test_events %>% filter(test_id == !!test_id)

  if (nrow(test_data) == 0) {
    return(list(error = "Test not found"))
  }

  results <- test_data %>%
    group_by(variant) %>%
    summarise(
      impressions = sum(impression),
      clicks = sum(click),
      ctr = clicks / impressions,
      engaged_reads = sum(engaged_read),
      subscriptions = sum(subscription),
      engaged_read_rate = engaged_reads / impressions,
      subscription_rate = subscriptions / impressions
    )

  return(list(test_id = test_id, results = results))
}

#* Predict engagement for new data
#* @param section Article section
#* @param format_type Article format
#* @param device_type User device
#* @param traffic_source Traffic source
#* @param hour_of_day Hour of day
#* @param word_count Word count
#* @post /predict_engagement
function(section, format_type, device_type, traffic_source, hour_of_day, word_count) {
  if (is.null(rf_model)) {
    return(list(error = "Model not available"))
  }

  # Prepare input data
  input_data <- data.frame(
    section = factor(section, levels = levels(rf_model$forest$xlevels$section)),
    format_type = factor(format_type, levels = levels(rf_model$forest$xlevels$format_type)),
    device_type = factor(device_type, levels = levels(rf_model$forest$xlevels$device_type)),
    traffic_source = factor(traffic_source, levels = levels(rf_model$forest$xlevels$traffic_source)),
    hour_of_day = as.numeric(hour_of_day),
    day_of_week = factor("Mon", levels = levels(rf_model$forest$xlevels$day_of_week)), # Default
    is_weekend = FALSE,
    time_since_publish = 1, # Default
    word_count = as.numeric(word_count),
    log_word_count = log(as.numeric(word_count) + 1),
    scroll_depth_pct = 50 # Default
  )

  # Make prediction
  prediction <- predict(rf_model, input_data, type = "prob")[, 2]

  return(list(
    predicted_engagement_probability = as.numeric(prediction),
    input_features = as.list(input_data)
  ))
}

#* Get overall dashboard metrics
#* @get /dashboard_metrics
function() {
  total_pageviews <- nrow(article_events)
  total_engaged_reads <- sum(article_events$engaged_read)
  total_subscriptions <- sum(article_events$subscribed)
  avg_engagement_rate <- mean(article_events$engaged_read)

  # Daily trend (last 30 days)
  daily_trend <- article_events %>%
    mutate(date = as.Date(event_timestamp)) %>%
    filter(date >= Sys.Date() - 30) %>%
    group_by(date) %>%
    summarise(
      pageviews = n(),
      engagement_rate = mean(engaged_read)
    ) %>%
    arrange(date)

  return(list(
    total_pageviews = total_pageviews,
    total_engaged_reads = total_engaged_reads,
    total_subscriptions = total_subscriptions,
    avg_engagement_rate = avg_engagement_rate,
    daily_trend = daily_trend
  ))
}

#* Health check
#* @get /health
function() {
  return(list(
    status = "healthy",
    timestamp = Sys.time(),
    data_loaded = list(
      articles = nrow(articles),
      users = nrow(users),
      sessions = nrow(sessions),
      article_events = nrow(article_events),
      ab_test_events = nrow(ab_test_events)
    ),
    models_loaded = list(
      rf_model = !is.null(rf_model),
      xgb_model = !is.null(xgb_model)
    )
  ))
}