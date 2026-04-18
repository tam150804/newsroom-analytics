library(tidyverse)
library(broom)

# Set working directory
setwd("/Users/tamannaagarwal/Newsroom Storytelling Analystics")

# Function to load AB test data
load_ab_test_data <- function() {
  ab_test_events <- read_csv("data/raw/ab_test_events.csv", show_col_types = FALSE)
  return(ab_test_events)
}

# Function to calculate metrics by variant
calculate_metrics <- function(data) {
  metrics <- data %>%
    group_by(variant) %>%
    summarise(
      impressions = sum(impression),
      clicks = sum(click),
      engaged_reads = sum(engaged_read),
      subscriptions = sum(subscription),
      ctr = clicks / impressions,
      engaged_read_rate = engaged_reads / impressions,
      subscription_rate = subscriptions / impressions
    )
  return(metrics)
}

# Function to compute confidence intervals
compute_confidence_intervals <- function(data) {
  # CTR CI
  ctr_a <- binom.test(sum(data$click[data$variant == "A"]), sum(data$impression[data$variant == "A"]))
  ctr_b <- binom.test(sum(data$click[data$variant == "B"]), sum(data$impression[data$variant == "B"]))

  # Engaged read rate CI
  er_a <- binom.test(sum(data$engaged_read[data$variant == "A"]), sum(data$impression[data$variant == "A"]))
  er_b <- binom.test(sum(data$engaged_read[data$variant == "B"]), sum(data$impression[data$variant == "B"]))

  # Subscription rate CI
  sub_a <- binom.test(sum(data$subscription[data$variant == "A"]), sum(data$impression[data$variant == "A"]))
  sub_b <- binom.test(sum(data$subscription[data$variant == "B"]), sum(data$impression[data$variant == "B"]))

  ci_data <- tibble(
    variant = c("A", "B", "A", "B", "A", "B"),
    metric = rep(c("CTR", "Engaged Read Rate", "Subscription Rate"), each = 2),
    estimate = c(ctr_a$estimate, ctr_b$estimate, er_a$estimate, er_b$estimate, sub_a$estimate, sub_b$estimate),
    lower_ci = c(ctr_a$conf.int[1], ctr_b$conf.int[1], er_a$conf.int[1], er_b$conf.int[1], sub_a$conf.int[1], sub_b$conf.int[1]),
    upper_ci = c(ctr_a$conf.int[2], ctr_b$conf.int[2], er_a$conf.int[2], er_b$conf.int[2], sub_a$conf.int[2], sub_b$conf.int[2])
  )

  return(ci_data)
}

# Function to perform statistical significance tests
perform_significance_tests <- function(data) {
  # CTR test
  ctr_test <- prop.test(
    x = c(sum(data$click[data$variant == "A"]), sum(data$click[data$variant == "B"])),
    n = c(sum(data$impression[data$variant == "A"]), sum(data$impression[data$variant == "B"]))
  )

  # Engaged read test
  er_test <- prop.test(
    x = c(sum(data$engaged_read[data$variant == "A"]), sum(data$engaged_read[data$variant == "B"])),
    n = c(sum(data$impression[data$variant == "A"]), sum(data$impression[data$variant == "B"]))
  )

  # Subscription test
  sub_test <- prop.test(
    x = c(sum(data$subscription[data$variant == "A"]), sum(data$subscription[data$variant == "B"])),
    n = c(sum(data$impression[data$variant == "A"]), sum(data$impression[data$variant == "B"]))
  )

  tests <- list(
    CTR = tidy(ctr_test),
    Engaged_Read = tidy(er_test),
    Subscription = tidy(sub_test)
  )

  return(tests)
}

# Function to create visualizations
create_visualizations <- function(metrics, ci_data) {
  # Plot 1: CTR by variant with CI
  p1 <- ggplot(ci_data %>% filter(metric == "CTR"), aes(x = variant, y = estimate, fill = variant)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.2) +
    labs(title = "Click-Through Rate by Variant", y = "CTR", x = "Variant") +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave("outputs/figures/ab_test_ctr.png", p1, width = 6, height = 4)

  # Plot 2: Engaged Read Rate by variant with CI
  p2 <- ggplot(ci_data %>% filter(metric == "Engaged Read Rate"), aes(x = variant, y = estimate, fill = variant)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.2) +
    labs(title = "Engaged Read Rate by Variant", y = "Engaged Read Rate", x = "Variant") +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave("outputs/figures/ab_test_engaged_read.png", p2, width = 6, height = 4)

  # Plot 3: Subscription Rate by variant with CI
  p3 <- ggplot(ci_data %>% filter(metric == "Subscription Rate"), aes(x = variant, y = estimate, fill = variant)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.2) +
    labs(title = "Subscription Rate by Variant", y = "Subscription Rate", x = "Variant") +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave("outputs/figures/ab_test_subscription.png", p3, width = 6, height = 4)

  # Plot 4: All metrics comparison
  p4 <- ggplot(ci_data, aes(x = metric, y = estimate, fill = variant)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), position = position_dodge(0.9), width = 0.2) +
    labs(title = "A/B Test Results: All Metrics", y = "Rate", x = "Metric") +
    theme_minimal() +
    coord_flip()

  ggsave("outputs/figures/ab_test_all_metrics.png", p4, width = 8, height = 6)
}

# Function to interpret results
interpret_results <- function(metrics, tests) {
  cat("=== A/B Test Results Interpretation ===\n\n")

  cat("Summary Metrics:\n")
  print(metrics)

  cat("\nStatistical Significance Tests:\n")
  for (metric in names(tests)) {
    test <- tests[[metric]]
    p_value <- test$p.value
    significant <- p_value < 0.05
    cat(sprintf("%s: p-value = %.4f (%s)\n", metric, p_value, ifelse(significant, "SIGNIFICANT", "NOT SIGNIFICANT")))
  }

  cat("\nInterpretation:\n")
  ctr_diff <- metrics$ctr[metrics$variant == "B"] - metrics$ctr[metrics$variant == "A"]
  er_diff <- metrics$engaged_read_rate[metrics$variant == "B"] - metrics$engaged_read_rate[metrics$variant == "A"]
  sub_diff <- metrics$subscription_rate[metrics$variant == "B"] - metrics$subscription_rate[metrics$variant == "A"]

  cat(sprintf("Variant B has %.2f%% higher CTR than Variant A.\n", ctr_diff * 100))
  cat(sprintf("Variant B has %.2f%% higher engaged read rate than Variant A.\n", er_diff * 100))
  cat(sprintf("Variant B has %.2f%% higher subscription rate than Variant A.\n", sub_diff * 100))

  if (tests$CTR$p.value < 0.05) {
    cat("The difference in CTR is statistically significant.\n")
  } else {
    cat("The difference in CTR is not statistically significant.\n")
  }

  cat("\nRecommendation: ")
  if (ctr_diff > 0 && tests$CTR$p.value < 0.05) {
    cat("Variant B performs better - consider implementing it.\n")
  } else {
    cat("No clear winner - may need more data or further testing.\n")
  }
}

# Main execution
main <- function() {
  # Load data
  ab_data <- load_ab_test_data()

  # Calculate metrics
  metrics <- calculate_metrics(ab_data)

  # Compute confidence intervals
  ci_data <- compute_confidence_intervals(ab_data)

  # Perform significance tests
  tests <- perform_significance_tests(ab_data)

  # Create visualizations
  create_visualizations(metrics, ci_data)

  # Interpret results
  interpret_results(metrics, tests)

  cat("\nA/B test analysis complete. Plots saved to outputs/figures/\n")
}

# Run the script
main()