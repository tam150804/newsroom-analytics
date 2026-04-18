library(tidyverse)
library(lubridate)

set.seed(123)

# Helper functions
generate_title <- function() {
  words <- c("Breaking", "New", "Study", "Reveals", "Government", "Tech", "Giant", "Announces", "Climate", "Change", "Election", "Results", "Market", "Crash", "Innovation", "Discovery", "Politics", "Business", "Culture", "Science", "World", "News")
  paste(sample(words, sample(3:8, 1), replace = TRUE), collapse = " ")
}

generate_author <- function() {
  first <- c("John", "Jane", "Michael", "Sarah", "David", "Emma", "Robert", "Lisa", "James", "Anna")
  last <- c("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez")
  paste(sample(first, 1), sample(last, 1))
}

# 1. Articles
n_articles <- 1000
articles <- tibble(
  article_id = 1:n_articles,
  publish_date = sample(seq(as.Date("2023-01-01"), as.Date("2025-12-31"), by = "day"), n_articles, replace = TRUE),
  title = replicate(n_articles, generate_title()),
  section = sample(c("politics", "business", "tech", "culture", "science", "world"), n_articles, replace = TRUE),
  author = replicate(n_articles, generate_author()),
  format_type = sample(c("news", "analysis", "opinion", "feature"), n_articles, replace = TRUE),
  topic = section,
  word_count = sample(200:2000, n_articles, replace = TRUE),
  headline_length = nchar(title),
  paywalled = sample(c(0, 1), n_articles, replace = TRUE, prob = c(0.7, 0.3))
)

# 2. Users
n_users <- 10000
users <- tibble(
  user_id = 1:n_users,
  signup_date = sample(seq(as.Date("2020-01-01"), as.Date("2025-12-31"), by = "day"), n_users, replace = TRUE),
  country = sample(c("USA", "UK", "India", "Canada"), n_users, replace = TRUE),
  device_preference = sample(c("mobile", "desktop"), n_users, replace = TRUE),
  subscriber_status = sample(c(0, 1), n_users, replace = TRUE, prob = c(0.8, 0.2))
)

# 3. Sessions
n_sessions <- 50000
sessions <- tibble(
  session_id = 1:n_sessions,
  user_id = sample(users$user_id, n_sessions, replace = TRUE),
  session_start = as.POSIXct(sample(seq(as.POSIXct("2024-01-01 00:00:00"), as.POSIXct("2025-12-31 23:59:59"), by = "hour"), n_sessions, replace = TRUE)),
  traffic_source = sample(c("direct", "search", "social", "newsletter"), n_sessions, replace = TRUE),
  device_type = sample(c("mobile", "desktop"), n_sessions, replace = TRUE)
)

# 4. Article Events
n_events <- 150000
article_events <- tibble(
  event_id = 1:n_events,
  session_id = sample(sessions$session_id, n_events, replace = TRUE)
) %>%
  left_join(sessions, by = "session_id") %>%
  mutate(
    article_id = sample(articles$article_id, n_events, replace = TRUE)
  ) %>%
  left_join(articles %>% select(article_id, format_type, paywalled), by = "article_id") %>%
  mutate(
    event_timestamp = session_start + minutes(sample(0:120, n_events, replace = TRUE)),
    pageviews = 1,
    time_on_page_seconds = case_when(
      format_type == "news" ~ rnorm(n_events, 120, 30),
      format_type == "analysis" ~ rnorm(n_events, 300, 60),
      format_type == "opinion" ~ rnorm(n_events, 180, 40),
      format_type == "feature" ~ rnorm(n_events, 400, 80)
    ) %>% pmax(10) %>% pmin(1000),
    scroll_depth_pct = if_else(device_type == "mobile", rbeta(n_events, 2, 5) * 100, rbeta(n_events, 3, 3) * 100) %>% pmin(100),
    engaged_read = as.integer(time_on_page_seconds > 180 & scroll_depth_pct > 50),
    clicked_subscription_offer = sample(c(0, 1), n_events, replace = TRUE, prob = c(0.95, 0.05)),
    subscribed = as.integer(clicked_subscription_offer == 1 & paywalled == 1 & runif(n_events) < 0.1)
  ) %>%
  select(event_id, session_id, user_id, article_id, event_timestamp, pageviews, time_on_page_seconds, scroll_depth_pct, engaged_read, clicked_subscription_offer, subscribed)

# 5. AB Test Events
n_ab_events <- 20000
ab_test_events <- tibble(
  test_id = "headline_test",
  user_id = sample(users$user_id, n_ab_events, replace = TRUE),
  session_id = sample(sessions$session_id, n_ab_events, replace = TRUE),
  article_id = sample(articles$article_id, n_ab_events, replace = TRUE),
  variant = sample(c("A", "B"), n_ab_events, replace = TRUE),
  impression = 1,
  click = as.integer(runif(n_ab_events) < if_else(variant == "A", 0.05, 0.07)),
  engaged_read = sample(c(0, 1), n_ab_events, replace = TRUE, prob = c(0.7, 0.3)),
  subscription = sample(c(0, 1), n_ab_events, replace = TRUE, prob = c(0.95, 0.05)),
  event_timestamp = as.POSIXct(sample(seq(as.POSIXct("2024-01-01 00:00:00"), as.POSIXct("2025-12-31 23:59:59"), by = "hour"), n_ab_events, replace = TRUE))
)

# Save to CSV
write_csv(articles, "data/raw/articles.csv")
write_csv(users, "data/raw/users.csv")
write_csv(sessions, "data/raw/sessions.csv")
write_csv(article_events, "data/raw/article_events.csv")
write_csv(ab_test_events, "data/raw/ab_test_events.csv")