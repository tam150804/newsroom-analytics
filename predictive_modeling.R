library(tidyverse)
library(caret)
library(randomForest)
library(xgboost)
library(pROC)

# Load data
engagement_data <- read_csv("data/raw/article_events.csv", show_col_types = FALSE) %>%
  left_join(read_csv("data/raw/articles.csv", show_col_types = FALSE), by = "article_id") %>%
  left_join(read_csv("data/raw/sessions.csv", show_col_types = FALSE), by = "session_id")

# Function to prepare data for modeling
prepare_modeling_data <- function(data) {
  # Create features
  model_data <- data %>%
    mutate(
      hour_of_day = hour(event_timestamp),
      day_of_week = wday(event_timestamp, label = TRUE),
      is_weekend = day_of_week %in% c("Sat", "Sun"),
      time_since_publish = as.numeric(difftime(event_timestamp, publish_date, units = "days")),
      log_word_count = log(word_count + 1),
      log_time_on_page = log(time_on_page_seconds + 1)
    ) %>%
    select(
      engaged_read,
      time_on_page_seconds,
      scroll_depth_pct,
      section,
      format_type,
      device_type,
      traffic_source,
      hour_of_day,
      day_of_week,
      is_weekend,
      time_since_publish,
      word_count,
      log_word_count,
      log_time_on_page
    ) %>%
    na.omit()

  # Convert categorical variables
  model_data <- model_data %>%
    mutate(across(c(section, format_type, device_type, traffic_source, day_of_week), as.factor))

  return(model_data)
}

# Function to train engagement prediction model
train_engagement_model <- function(data) {
  cat("=== TRAINING ENGAGEMENT PREDICTION MODEL ===\n\n")

  # Split data
  set.seed(123)
  train_index <- createDataPartition(data$engaged_read, p = 0.7, list = FALSE)
  train_data <- data[train_index, ]
  test_data <- data[-train_index, ]

  cat("Training set size:", nrow(train_data), "\n")
  cat("Test set size:", nrow(test_data), "\n\n")

  # Train Random Forest model
  cat("Training Random Forest model...\n")
  rf_model <- randomForest(
    engaged_read ~ . -time_on_page_seconds -log_time_on_page,
    data = train_data,
    ntree = 100,
    importance = TRUE
  )

  # Make predictions
  rf_pred <- predict(rf_model, test_data)
  rf_pred_prob <- predict(rf_model, test_data, type = "prob")[, 2]

  # Evaluate model
  rf_confusion <- confusionMatrix(rf_pred, test_data$engaged_read)
  rf_auc <- auc(roc(test_data$engaged_read, rf_pred_prob))

  cat("Random Forest Results:\n")
  print(rf_confusion)
  cat("AUC:", rf_auc, "\n\n")

  # Train XGBoost model
  cat("Training XGBoost model...\n")
  train_matrix <- xgb.DMatrix(
    data = as.matrix(train_data %>% select(-engaged_read, -time_on_page_seconds, -log_time_on_page)),
    label = as.numeric(train_data$engaged_read)
  )

  test_matrix <- xgb.DMatrix(
    data = as.matrix(test_data %>% select(-engaged_read, -time_on_page_seconds, -log_time_on_page)),
    label = as.numeric(test_data$engaged_read)
  )

  xgb_model <- xgb.train(
    params = list(
      objective = "binary:logistic",
      eval_metric = "auc",
      max_depth = 6,
      eta = 0.1
    ),
    data = train_matrix,
    nrounds = 100,
    verbose = 0
  )

  # XGBoost predictions
  xgb_pred_prob <- predict(xgb_model, test_matrix)
  xgb_pred <- ifelse(xgb_pred_prob > 0.5, TRUE, FALSE)
  xgb_auc <- auc(roc(test_data$engaged_read, xgb_pred_prob))

  cat("XGBoost Results:\n")
  xgb_confusion <- confusionMatrix(as.factor(xgb_pred), as.factor(test_data$engaged_read))
  print(xgb_confusion)
  cat("AUC:", xgb_auc, "\n\n")

  # Feature importance
  cat("Random Forest Feature Importance:\n")
  rf_importance <- importance(rf_model)
  print(rf_importance[order(rf_importance[, "MeanDecreaseGini"], decreasing = TRUE), ])

  # Save models
  saveRDS(rf_model, "outputs/models/rf_engagement_model.rds")
  saveRDS(xgb_model, "outputs/models/xgb_engagement_model.rds")

  cat("\nModels saved to outputs/models/\n")

  return(list(rf_model = rf_model, xgb_model = xgb_model, test_data = test_data))
}

# Function to predict time on page
train_time_prediction_model <- function(data) {
  cat("=== TRAINING TIME ON PAGE PREDICTION MODEL ===\n\n")

  # Filter for engaged reads only
  time_data <- data %>%
    filter(engaged_read == TRUE) %>%
    select(-engaged_read)

  # Split data
  set.seed(123)
  train_index <- createDataPartition(time_data$time_on_page_seconds, p = 0.7, list = FALSE)
  train_data <- time_data[train_index, ]
  test_data <- time_data[-train_index, ]

  # Train linear regression
  cat("Training Linear Regression model...\n")
  lm_model <- train(
    time_on_page_seconds ~ . -log_time_on_page,
    data = train_data,
    method = "lm",
    trControl = trainControl(method = "cv", number = 5)
  )

  # Train random forest regression
  cat("Training Random Forest regression...\n")
  rf_reg_model <- train(
    time_on_page_seconds ~ . -log_time_on_page,
    data = train_data,
    method = "rf",
    trControl = trainControl(method = "cv", number = 5),
    ntree = 50
  )

  # Evaluate models
  lm_pred <- predict(lm_model, test_data)
  rf_pred <- predict(rf_reg_model, test_data)

  lm_rmse <- RMSE(lm_pred, test_data$time_on_page_seconds)
  rf_rmse <- RMSE(rf_pred, test_data$time_on_page_seconds)

  cat("Linear Regression RMSE:", lm_rmse, "\n")
  cat("Random Forest RMSE:", rf_rmse, "\n\n")

  # Save models
  saveRDS(lm_model, "outputs/models/lm_time_model.rds")
  saveRDS(rf_reg_model, "outputs/models/rf_time_model.rds")

  cat("Time prediction models saved to outputs/models/\n")

  return(list(lm_model = lm_model, rf_model = rf_reg_model))
}

# Function to create model performance visualizations
create_model_plots <- function(models, test_data) {
  # ROC curves
  rf_pred_prob <- predict(models$rf_model, test_data, type = "prob")[, 2]
  xgb_pred_prob <- predict(models$xgb_model, xgb.DMatrix(
    data = as.matrix(test_data %>% select(-engaged_read, -time_on_page_seconds, -log_time_on_page))
  ))

  rf_roc <- roc(test_data$engaged_read, rf_pred_prob)
  xgb_roc <- roc(test_data$engaged_read, xgb_pred_prob)

  roc_plot <- ggroc(list("Random Forest" = rf_roc, "XGBoost" = xgb_roc)) +
    labs(title = "ROC Curves for Engagement Prediction Models") +
    theme_minimal()

  ggsave("outputs/figures/model_roc_curves.png", roc_plot, width = 8, height = 6)

  # Feature importance plot
  rf_importance <- importance(models$rf_model)
  importance_df <- data.frame(
    Feature = rownames(rf_importance),
    Importance = rf_importance[, "MeanDecreaseGini"]
  ) %>%
    arrange(desc(Importance)) %>%
    head(10)

  importance_plot <- ggplot(importance_df, aes(x = reorder(Feature, Importance), y = Importance)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    coord_flip() +
    labs(title = "Top 10 Feature Importance (Random Forest)", x = "Feature", y = "Importance") +
    theme_minimal()

  ggsave("outputs/figures/feature_importance.png", importance_plot, width = 8, height = 6)

  cat("Model performance plots saved to outputs/figures/\n")
}

# Main execution
main <- function() {
  # Prepare data
  model_data <- prepare_modeling_data(engagement_data)

  # Train models
  engagement_models <- train_engagement_model(model_data)
  time_models <- train_time_prediction_model(model_data)

  # Create visualizations
  create_model_plots(engagement_models, engagement_models$test_data)

  cat("Predictive modeling complete!\n")
  cat("Models saved to outputs/models/\n")
  cat("Visualizations saved to outputs/figures/\n")
}

# Run the script
main()