library(tidyverse)
library(rmarkdown)
library(lubridate)
library(blastula)

# Configuration
REPORT_RECIPIENTS <- c("analytics@newsroom.com", "editor@newsroom.com")
REPORT_FROM <- "analytics@newsroom.com"
SMTP_SERVER <- "smtp.newsroom.com"
SMTP_PORT <- 587

# Function to generate daily report data
generate_daily_report_data <- function() {
  # Load data
  articles <- read_csv("data/raw/articles.csv", show_col_types = FALSE)
  article_events <- read_csv("data/raw/article_events.csv", show_col_types = FALSE)
  sessions <- read_csv("data/raw/sessions.csv", show_col_types = FALSE)

  # Get yesterday's date
  yesterday <- Sys.Date() - 1

  # Filter data for yesterday
  yesterday_events <- article_events %>%
    filter(as.Date(event_timestamp) == yesterday)

  yesterday_sessions <- sessions %>%
    filter(as.Date(session_start) == yesterday)

  # Calculate key metrics
  daily_metrics <- list(
    date = yesterday,
    total_pageviews = nrow(yesterday_events),
    total_sessions = nrow(yesterday_sessions),
    engaged_reads = sum(yesterday_events$engaged_read, na.rm = TRUE),
    subscriptions = sum(yesterday_events$subscribed, na.rm = TRUE),
    avg_engagement_rate = mean(yesterday_events$engaged_read, na.rm = TRUE),
    avg_time_on_page = mean(yesterday_events$time_on_page_seconds, na.rm = TRUE),
    avg_scroll_depth = mean(yesterday_events$scroll_depth_pct, na.rm = TRUE)
  )

  # Top performing articles
  top_articles <- yesterday_events %>%
    left_join(articles, by = "article_id") %>%
    group_by(article_id, title, section, author) %>%
    summarise(
      pageviews = n(),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      avg_time = mean(time_on_page_seconds, na.rm = TRUE)
    ) %>%
    arrange(desc(pageviews)) %>%
    head(5)

  # Traffic source breakdown
  traffic_sources <- yesterday_sessions %>%
    count(traffic_source) %>%
    mutate(percentage = n / sum(n) * 100)

  # Device performance
  device_performance <- yesterday_events %>%
    left_join(sessions, by = "session_id") %>%
    group_by(device_type) %>%
    summarise(
      pageviews = n(),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      avg_time = mean(time_on_page_seconds, na.rm = TRUE)
    )

  # Section performance
  section_performance <- yesterday_events %>%
    left_join(articles, by = "article_id") %>%
    group_by(section) %>%
    summarise(
      pageviews = n(),
      engagement_rate = mean(engaged_read, na.rm = TRUE),
      subscriptions = sum(subscribed, na.rm = TRUE)
    ) %>%
    arrange(desc(pageviews))

  return(list(
    daily_metrics = daily_metrics,
    top_articles = top_articles,
    traffic_sources = traffic_sources,
    device_performance = device_performance,
    section_performance = section_performance
  ))
}

# Function to generate HTML report
generate_html_report <- function(report_data) {
  # Create temporary RMarkdown content
  rmd_content <- sprintf('---
title: "Newsroom Daily Analytics Report - %s"
output: html_document
---

<style>
.metric-box {
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 5px;
  padding: 15px;
  margin: 10px 0;
  text-align: center;
}

.metric-value {
  font-size: 24px;
  font-weight: bold;
  color: #007bff;
}

.metric-label {
  font-size: 14px;
  color: #6c757d;
}
</style>

# Daily Analytics Report

**Report Date:** %s

## Key Metrics

<div class="metric-box">
  <div class="metric-value">%s</div>
  <div class="metric-label">Total Pageviews</div>
</div>

<div class="metric-box">
  <div class="metric-value">%s</div>
  <div class="metric-label">Total Sessions</div>
</div>

<div class="metric-box">
  <div class="metric-value">%s</div>
  <div class="metric-label">Engaged Reads</div>
</div>

<div class="metric-box">
  <div class="metric-value">%.1f%%</div>
  <div class="metric-label">Engagement Rate</div>
</div>

<div class="metric-box">
  <div class="metric-value">%s</div>
  <div class="metric-label">New Subscriptions</div>
</div>

## Top Performing Articles

```{r, echo=FALSE}
knitr::kable(report_data$top_articles, format = "html", table.attr = "class=\\"table table-striped\\"")
```

## Traffic Source Breakdown

```{r, echo=FALSE}
knitr::kable(report_data$traffic_sources, format = "html", table.attr = "class=\\"table table-striped\\"",
             col.names = c("Traffic Source", "Sessions", "Percentage"))
```

## Device Performance

```{r, echo=FALSE}
knitr::kable(report_data$device_performance, format = "html", table.attr = "class=\\"table table-striped\\"",
             col.names = c("Device Type", "Pageviews", "Engagement Rate", "Avg Time on Page"))
```

## Section Performance

```{r, echo=FALSE}
knitr::kable(report_data$section_performance, format = "html", table.attr = "class=\\"table table-striped\\"",
             col.names = c("Section", "Pageviews", "Engagement Rate", "Subscriptions"))
```

---
*This report was automatically generated on %s*
',
    format(report_data$daily_metrics$date, "%B %d, %Y"),
    format(report_data$daily_metrics$date, "%B %d, %Y"),
    format(report_data$daily_metrics$total_pageviews, big.mark = ","),
    format(report_data$daily_metrics$total_sessions, big.mark = ","),
    format(report_data$daily_metrics$engaged_reads, big.mark = ","),
    report_data$daily_metrics$avg_engagement_rate * 100,
    format(report_data$daily_metrics$subscriptions, big.mark = ","),
    format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  # Write RMarkdown file
  rmd_file <- tempfile(fileext = ".Rmd")
  writeLines(rmd_content, rmd_file)

  # Render to HTML
  html_file <- tempfile(fileext = ".html")
  if (rmarkdown::pandoc_available()) {
    rmarkdown::render(rmd_file, output_file = html_file, quiet = TRUE)
    cat("HTML report saved to outputs/", basename(html_file), "\n")
  } else {
    cat("Pandoc not available - skipping HTML report generation.\n")
    cat("Report data is ready for manual processing.\n")
    html_file <- NULL
  }

  return(html_file)
}

# Function to send email report
send_email_report <- function(html_file, report_data) {
  if (is.null(html_file)) {
    cat("Skipping email report - no HTML file generated.\n")
    return()
  }

  # Read HTML content
  html_content <- readLines(html_file)
  html_body <- paste(html_content, collapse = "\n")

  # Create email
  email <- compose_email(
    body = md(glue::glue("
# Newsroom Daily Analytics Report

**Date:** {format(report_data$daily_metrics$date, '%B %d, %Y')}

## Summary
- **Pageviews:** {format(report_data$daily_metrics$total_pageviews, big.mark = ',')}
- **Engaged Reads:** {format(report_data$daily_metrics$engaged_reads, big.mark = ',')}
- **Engagement Rate:** {sprintf('%.1f%%', report_data$daily_metrics$avg_engagement_rate * 100)}
- **New Subscriptions:** {format(report_data$daily_metrics$subscriptions, big.mark = ',')}

See attached HTML report for detailed analytics.

*This is an automated report generated by the Newsroom Analytics system.*
    ")),
    footer = "Newsroom Analytics Team"
  ) %>%
    add_attachment(html_file, filename = sprintf("newsroom_report_%s.html", format(report_data$daily_metrics$date, "%Y%m%d")))

  # Send email (commented out as it requires SMTP configuration)
  # smtp_send(
  #   email,
  #   to = REPORT_RECIPIENTS,
  #   from = REPORT_FROM,
  #   subject = sprintf("Newsroom Daily Analytics Report - %s", format(report_data$daily_metrics$date, "%B %d, %Y")),
  #   credentials = creds(
  #     host = SMTP_SERVER,
  #     port = SMTP_PORT,
  #     user = REPORT_FROM,
  #     use_ssl = TRUE
  #   )
  # )

  cat("Email report prepared (SMTP sending commented out for demo)\n")
  cat("To enable email sending, configure SMTP credentials and uncomment the smtp_send() call\n")
}

# Function to save report to outputs
save_report_to_outputs <- function(html_file, report_data) {
  # Copy HTML report to outputs folder
  report_filename <- sprintf("daily_report_%s.html", format(report_data$daily_metrics$date, "%Y%m%d"))
  file.copy(html_file, file.path("outputs", report_filename), overwrite = TRUE)

  cat(sprintf("Report saved to outputs/%s\n", report_filename))
}

# Function to generate weekly summary
generate_weekly_summary <- function() {
  # Load data
  article_events <- read_csv("data/raw/article_events.csv", show_col_types = FALSE)

  # Get last 7 days
  week_start <- Sys.Date() - 7
  week_end <- Sys.Date() - 1

  weekly_data <- article_events %>%
    filter(as.Date(event_timestamp) >= week_start & as.Date(event_timestamp) <= week_end)

  weekly_summary <- weekly_data %>%
    mutate(date = as.Date(event_timestamp)) %>%
    group_by(date) %>%
    summarise(
      pageviews = n(),
      engaged_reads = sum(engaged_read),
      engagement_rate = mean(engaged_read),
      subscriptions = sum(subscribed)
    ) %>%
    arrange(date)

  # Save weekly summary
  write_csv(weekly_summary, "outputs/weekly_summary.csv")

  cat("Weekly summary saved to outputs/weekly_summary.csv\n")

  return(weekly_summary)
}

# Main execution
main <- function() {
  cat("=== NEWSROOM AUTOMATED REPORTING SYSTEM ===\n\n")

  # Generate daily report data
  cat("Generating daily report data...\n")
  report_data <- generate_daily_report_data()

  # Generate HTML report
  cat("Generating HTML report...\n")
  html_file <- generate_html_report(report_data)

  # Send email report
  cat("Preparing email report...\n")
  send_email_report(html_file, report_data)

  # Save report to outputs
  cat("Saving report to outputs folder...\n")
  save_report_to_outputs(html_file, report_data)

  # Generate weekly summary
  cat("Generating weekly summary...\n")
  weekly_summary <- generate_weekly_summary()

  # Clean up temporary files
  unlink(html_file)

  cat("\n=== REPORTING COMPLETE ===\n")
  cat(sprintf("Daily report generated for: %s\n", format(report_data$daily_metrics$date, "%B %d, %Y")))
  cat("Check outputs/ folder for saved reports\n")
}

# Run the script
main()