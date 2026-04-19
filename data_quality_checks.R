library(tidyverse)
library(janitor)
library(validate)
library(DataExplorer)

# Load data
articles <- read_csv("data/raw/articles.csv", show_col_types = FALSE)
users <- read_csv("data/raw/users.csv", show_col_types = FALSE)
sessions <- read_csv("data/raw/sessions.csv", show_col_types = FALSE)
article_events <- read_csv("data/raw/article_events.csv", show_col_types = FALSE)
ab_test_events <- read_csv("data/raw/ab_test_events.csv", show_col_types = FALSE)

# Function to perform data quality checks
perform_data_quality_checks <- function() {
  cat("=== DATA QUALITY REPORT ===\n\n")

  # Articles checks
  cat("ARTICLES DATA:\n")
  cat("- Rows:", nrow(articles), "\n")
  cat("- Columns:", ncol(articles), "\n")
  cat("- Missing values:\n")
  print(colSums(is.na(articles)))
  cat("- Duplicate article_ids:", sum(duplicated(articles$article_id)), "\n")
  cat("- Invalid word counts:", sum(articles$word_count < 0), "\n")
  cat("- Invalid headline lengths:", sum(articles$headline_length < 0), "\n\n")

  # Users checks
  cat("USERS DATA:\n")
  cat("- Rows:", nrow(users), "\n")
  cat("- Columns:", ncol(users), "\n")
  cat("- Missing values:\n")
  print(colSums(is.na(users)))
  cat("- Duplicate user_ids:", sum(duplicated(users$user_id)), "\n")
  cat("- Future signup dates:", sum(users$signup_date > Sys.Date()), "\n\n")

  # Sessions checks
  cat("SESSIONS DATA:\n")
  cat("- Rows:", nrow(sessions), "\n")
  cat("- Columns:", ncol(sessions), "\n")
  cat("- Missing values:\n")
  print(colSums(is.na(sessions)))
  cat("- Duplicate session_ids:", sum(duplicated(sessions$session_id)), "\n")
  cat("- Invalid user_ids:", sum(!sessions$user_id %in% users$user_id), "\n\n")

  # Article events checks
  cat("ARTICLE EVENTS DATA:\n")
  cat("- Rows:", nrow(article_events), "\n")
  cat("- Columns:", ncol(article_events), "\n")
  cat("- Missing values:\n")
  print(colSums(is.na(article_events)))
  cat("- Duplicate event_ids:", sum(duplicated(article_events$event_id)), "\n")
  cat("- Invalid session_ids:", sum(!article_events$session_id %in% sessions$session_id), "\n")
  cat("- Invalid article_ids:", sum(!article_events$article_id %in% articles$article_id), "\n")
  cat("- Invalid time_on_page:", sum(article_events$time_on_page_seconds < 0), "\n")
  cat("- Invalid scroll_depth:", sum(article_events$scroll_depth_pct < 0 | article_events$scroll_depth_pct > 100), "\n\n")

  # A/B test events checks
  cat("A/B TEST EVENTS DATA:\n")
  cat("- Rows:", nrow(ab_test_events), "\n")
  cat("- Columns:", ncol(ab_test_events), "\n")
  cat("- Missing values:\n")
  print(colSums(is.na(ab_test_events)))
  cat("- Invalid user_ids:", sum(!ab_test_events$user_id %in% users$user_id), "\n")
  cat("- Invalid session_ids:", sum(!ab_test_events$session_id %in% sessions$session_id), "\n")
  cat("- Invalid article_ids:", sum(!ab_test_events$article_id %in% articles$article_id), "\n\n")
}

# Function to generate data quality report
generate_data_profile <- function() {
  cat("=== DATA PROFILE REPORT ===\n\n")

  # Create data profile for article_events (largest dataset)
  cat("Generating data profile for article_events...\n")
  if (rmarkdown::pandoc_available()) {
    DataExplorer::create_report(
      article_events,
      output_file = "outputs/data_quality_report.html",
      output_dir = "outputs/",
      report_title = "Newsroom Analytics Data Quality Report"
    )
    cat("Data profile report saved to outputs/data_quality_report.html\n\n")
  } else {
    cat("Skipping HTML report: pandoc not found. Install pandoc or RStudio to enable report generation.\n\n")
  }
}

# Function to validate data integrity rules
validate_data_integrity <- function() {
  cat("=== DATA INTEGRITY VALIDATION ===\n\n")

  # Define validation rules
  rules <- validator(
    article_id_positive = article_id > 0,
    user_id_positive = user_id > 0,
    session_id_positive = session_id > 0,
    event_id_positive = event_id > 0,
    time_on_page_positive = time_on_page_seconds >= 0,
    scroll_depth_valid = scroll_depth_pct >= 0 & scroll_depth_pct <= 100,
    dates_not_future = event_timestamp <= Sys.time(),
    signup_dates_valid = signup_date <= Sys.time(),
    publish_dates_valid = publish_date <= Sys.time()
  )

  # Validate article_events
  cat("Validating article_events...\n")
  article_events_valid <- confront(article_events, rules)
  summary_article <- summary(article_events_valid)
  print(summary_article)

  cat("\nValidation complete. Check summary for any failures.\n\n")
}

# Function to check data consistency
check_data_consistency <- function() {
  cat("=== DATA CONSISTENCY CHECKS ===\n\n")

  # Check if all referenced IDs exist
  cat("Checking foreign key relationships...\n")

  # Sessions should reference existing users
  invalid_sessions <- sessions %>% filter(!user_id %in% users$user_id)
  cat("- Invalid user references in sessions:", nrow(invalid_sessions), "\n")

  # Article events should reference existing sessions and articles
  invalid_article_events <- article_events %>%
    filter(!session_id %in% sessions$session_id | !article_id %in% articles$article_id)
  cat("- Invalid references in article_events:", nrow(invalid_article_events), "\n")

  # A/B events should reference existing entities
  invalid_ab_events <- ab_test_events %>%
    filter(!user_id %in% users$user_id | !session_id %in% sessions$session_id | !article_id %in% articles$article_id)
  cat("- Invalid references in ab_test_events:", nrow(invalid_ab_events), "\n\n")

  # Check date consistency
  cat("Checking date consistency...\n")
  future_events <- article_events %>% filter(event_timestamp > Sys.time())
  cat("- Future event timestamps:", nrow(future_events), "\n")

  future_signups <- users %>% filter(signup_date > Sys.time())
  cat("- Future signup dates:", nrow(future_signups), "\n")

  future_publishes <- articles %>% filter(publish_date > Sys.time())
  cat("- Future publish dates:", nrow(future_publishes), "\n\n")
}

# Main execution
main <- function() {
  perform_data_quality_checks()
  generate_data_profile()
  validate_data_integrity()
  check_data_consistency()

  cat("Data quality assessment complete!\n")
  cat("Check outputs/data_quality_report.html for detailed profile.\n")
}

# Run the script
main()