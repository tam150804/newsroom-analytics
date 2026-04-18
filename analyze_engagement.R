library(tidyverse)
library(lubridate)

# Set working directory
setwd("/Users/tamannaagarwal/Newsroom Storytelling Analystics")

# Function to load data
load_data <- function() {
  articles <- read_csv("data/raw/articles.csv")
  users <- read_csv("data/raw/users.csv")
  sessions <- read_csv("data/raw/sessions.csv")
  article_events <- read_csv("data/raw/article_events.csv")
  ab_test_events <- read_csv("data/raw/ab_test_events.csv")

  # Join article_events with articles and sessions for analysis
  engagement_data <- article_events %>%
    left_join(articles, by = "article_id") %>%
    left_join(sessions, by = "session_id")

  return(list(
    articles = articles,
    users = users,
    sessions = sessions,
    article_events = article_events,
    ab_test_events = ab_test_events,
    engagement_data = engagement_data
  ))
}

# Function to analyze engagement by section/topic
analyze_section_engagement <- function(data) {
  section_summary <- data$engagement_data %>%
    group_by(section) %>%
    summarise(
      total_pageviews = n(),
      avg_time_on_page = mean(time_on_page_seconds, na.rm = TRUE),
      avg_scroll_depth = mean(scroll_depth_pct, na.rm = TRUE),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      subscription_rate = mean(subscribed, na.rm = TRUE)
    ) %>%
    arrange(desc(engagement_rate))

  print("Section Engagement Summary:")
  print(section_summary)

  return(section_summary)
}

# Function to compare engagement by format_type
analyze_format_engagement <- function(data) {
  format_summary <- data$engagement_data %>%
    group_by(format_type) %>%
    summarise(
      total_pageviews = n(),
      avg_time_on_page = mean(time_on_page_seconds, na.rm = TRUE),
      avg_scroll_depth = mean(scroll_depth_pct, na.rm = TRUE),
      engagement_rate = mean(engaged_read, na.rm = TRUE)
    ) %>%
    arrange(desc(avg_time_on_page))

  print("Format Type Engagement Summary:")
  print(format_summary)

  return(format_summary)
}

# Function to analyze time trends
analyze_time_trends <- function(data) {
  time_summary <- data$engagement_data %>%
    mutate(date = date(event_timestamp)) %>%
    group_by(date) %>%
    summarise(
      daily_pageviews = n(),
      avg_engagement = mean(engaged_read, na.rm = TRUE),
      avg_time_on_page = mean(time_on_page_seconds, na.rm = TRUE)
    ) %>%
    arrange(date)

  print("Time Trends Summary (first 10 rows):")
  print(head(time_summary, 10))

  return(time_summary)
}

# Function to compare mobile vs desktop
analyze_device_behavior <- function(data) {
  device_summary <- data$engagement_data %>%
    group_by(device_type) %>%
    summarise(
      total_pageviews = n(),
      avg_time_on_page = mean(time_on_page_seconds, na.rm = TRUE),
      avg_scroll_depth = mean(scroll_depth_pct, na.rm = TRUE),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      subscription_rate = mean(subscribed, na.rm = TRUE)
    )

  print("Device Behavior Summary:")
  print(device_summary)

  return(device_summary)
}

# Function to create visualizations
create_visualizations <- function(data, section_summary, format_summary, time_summary, device_summary) {
  # Plot 1: Engagement rate by section
  p1 <- ggplot(section_summary, aes(x = reorder(section, engagement_rate), y = engagement_rate)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    coord_flip() +
    labs(title = "Engagement Rate by Section", x = "Section", y = "Engagement Rate") +
    theme_minimal()

  ggsave("outputs/figures/engagement_by_section.png", p1, width = 8, height = 6)

  # Plot 2: Average time on page by format type
  p2 <- ggplot(format_summary, aes(x = format_type, y = avg_time_on_page, fill = format_type)) +
    geom_bar(stat = "identity") +
    labs(title = "Average Time on Page by Format Type", x = "Format Type", y = "Average Time (seconds)") +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave("outputs/figures/time_by_format.png", p2, width = 8, height = 6)

  # Plot 3: Time trends in engagement
  p3 <- ggplot(time_summary, aes(x = date, y = avg_engagement)) +
    geom_line(color = "darkgreen") +
    geom_point() +
    labs(title = "Daily Engagement Rate Over Time", x = "Date", y = "Average Engagement Rate") +
    theme_minimal()

  ggsave("outputs/figures/engagement_trends.png", p3, width = 10, height = 6)

  # Plot 4: Mobile vs Desktop engagement
  p4 <- ggplot(device_summary, aes(x = device_type, y = engagement_rate, fill = device_type)) +
    geom_bar(stat = "identity") +
    labs(title = "Engagement Rate by Device Type", x = "Device Type", y = "Engagement Rate") +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave("outputs/figures/engagement_by_device.png", p4, width = 8, height = 6)

  # Plot 5: Scroll depth distribution
  p5 <- ggplot(data$engagement_data, aes(x = scroll_depth_pct, fill = device_type)) +
    geom_histogram(alpha = 0.7, position = "identity", bins = 30) +
    labs(title = "Scroll Depth Distribution by Device", x = "Scroll Depth (%)", y = "Count") +
    theme_minimal()

  ggsave("outputs/figures/scroll_depth_distribution.png", p5, width = 8, height = 6)

  # Plot 6: Time on page vs Scroll depth scatter
  p6 <- ggplot(data$engagement_data %>% sample_n(10000), aes(x = time_on_page_seconds, y = scroll_depth_pct, color = engaged_read)) +
    geom_point(alpha = 0.5) +
    labs(title = "Time on Page vs Scroll Depth (Sample)", x = "Time on Page (seconds)", y = "Scroll Depth (%)", color = "Engaged Read") +
    theme_minimal()

  ggsave("outputs/figures/time_vs_scroll_scatter.png", p6, width = 8, height = 6)

  print("Visualizations saved to outputs/figures/")
}

# Main execution
main <- function() {
  # Load data
  data <- load_data()

  # Perform analyses
  section_summary <- analyze_section_engagement(data)
  format_summary <- analyze_format_engagement(data)
  time_summary <- analyze_time_trends(data)
  device_summary <- analyze_device_behavior(data)

  # Create visualizations
  create_visualizations(data, section_summary, format_summary, time_summary, device_summary)

  print("Analysis complete!")
}

# Run the script
main()