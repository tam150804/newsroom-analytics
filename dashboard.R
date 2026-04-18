library(shiny)
library(tidyverse)
library(shinydashboard)
library(DT)

# Load data
articles <- read_csv("data/raw/articles.csv", show_col_types = FALSE)
users <- read_csv("data/raw/users.csv", show_col_types = FALSE)
sessions <- read_csv("data/raw/sessions.csv", show_col_types = FALSE)
article_events <- read_csv("data/raw/article_events.csv", show_col_types = FALSE)
ab_test_events <- read_csv("data/raw/ab_test_events.csv", show_col_types = FALSE)

# Prepare engagement data
engagement_data <- article_events %>%
  left_join(articles, by = "article_id") %>%
  left_join(sessions, by = "session_id")

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Newsroom Analytics Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Article Performance", tabName = "articles", icon = icon("newspaper")),
      menuItem("Audience Behavior", tabName = "audience", icon = icon("users")),
      menuItem("A/B Testing", tabName = "abtest", icon = icon("flask"))
    )
  ),
  dashboardBody(
    tabItems(
      # Overview tab
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("total_pageviews"),
          valueBoxOutput("total_engaged_reads"),
          valueBoxOutput("total_subscriptions"),
          valueBoxOutput("avg_engagement_rate")
        ),
        fluidRow(
          box(plotOutput("engagement_trend"), width = 12)
        )
      ),

      # Article Performance tab
      tabItem(tabName = "articles",
        fluidRow(
          box(
            selectInput("section_filter", "Section:", choices = c("All", unique(articles$section))),
            dateRangeInput("date_filter", "Date Range:",
              start = min(as.Date(article_events$event_timestamp)),
              end = max(as.Date(article_events$event_timestamp))),
            width = 12
          )
        ),
        fluidRow(
          box(DTOutput("article_table"), width = 12)
        ),
        fluidRow(
          box(plotOutput("article_engagement_chart"), width = 6),
          box(plotOutput("section_performance_chart"), width = 6)
        )
      ),

      # Audience Behavior tab
      tabItem(tabName = "audience",
        fluidRow(
          box(plotOutput("traffic_source_chart"), width = 6),
          box(plotOutput("device_comparison_chart"), width = 6)
        ),
        fluidRow(
          box(plotOutput("engagement_by_device"), width = 12)
        )
      ),

      # A/B Testing tab
      tabItem(tabName = "abtest",
        fluidRow(
          box(
            selectInput("test_id_select", "Select Test ID:", choices = unique(ab_test_events$test_id)),
            width = 12
          )
        ),
        fluidRow(
          valueBoxOutput("ab_ctr_a"),
          valueBoxOutput("ab_ctr_b"),
          valueBoxOutput("ab_significance")
        ),
        fluidRow(
          box(plotOutput("ab_variant_comparison"), width = 12)
        )
      )
    )
  )
)

# Server
server <- function(input, output) {

  # Overview
  output$total_pageviews <- renderValueBox({
    total <- nrow(article_events)
    valueBox(total, "Total Pageviews", icon = icon("eye"), color = "blue")
  })

  output$total_engaged_reads <- renderValueBox({
    total <- sum(article_events$engaged_read)
    valueBox(total, "Engaged Reads", icon = icon("thumbs-up"), color = "green")
  })

  output$total_subscriptions <- renderValueBox({
    total <- sum(article_events$subscribed)
    valueBox(total, "Subscriptions", icon = icon("star"), color = "yellow")
  })

  output$avg_engagement_rate <- renderValueBox({
    rate <- mean(article_events$engaged_read) * 100
    valueBox(sprintf("%.1f%%", rate), "Avg Engagement Rate", icon = icon("percent"), color = "purple")
  })

  output$engagement_trend <- renderPlot({
    trend_data <- engagement_data %>%
      mutate(date = as.Date(event_timestamp)) %>%
      group_by(date) %>%
      summarise(avg_engagement = mean(engaged_read))

    ggplot(trend_data, aes(x = date, y = avg_engagement)) +
      geom_line(color = "steelblue") +
      labs(title = "Daily Engagement Trend", x = "Date", y = "Engagement Rate") +
      theme_minimal()
  })

  # Article Performance
  filtered_articles <- reactive({
    data <- engagement_data

    if (input$section_filter != "All") {
      data <- data %>% filter(section == input$section_filter)
    }

    data <- data %>% filter(as.Date(event_timestamp) >= input$date_filter[1] & as.Date(event_timestamp) <= input$date_filter[2])

    data
  })

  output$article_table <- renderDT({
    summary <- filtered_articles() %>%
      group_by(article_id, title, section, author) %>%
      summarise(
        pageviews = n(),
        avg_time = mean(time_on_page_seconds),
        engagement_rate = mean(engaged_read),
        subscriptions = sum(subscribed)
      ) %>%
      arrange(desc(pageviews))

    datatable(summary, options = list(pageLength = 10))
  })

  output$article_engagement_chart <- renderPlot({
    top_articles <- filtered_articles() %>%
      group_by(title) %>%
      summarise(engagement_rate = mean(engaged_read)) %>%
      top_n(10, engagement_rate) %>%
      arrange(desc(engagement_rate))

    ggplot(top_articles, aes(x = reorder(title, engagement_rate), y = engagement_rate)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      coord_flip() +
      labs(title = "Top 10 Articles by Engagement", x = "Article", y = "Engagement Rate") +
      theme_minimal()
  })

  output$section_performance_chart <- renderPlot({
    section_perf <- filtered_articles() %>%
      group_by(section) %>%
      summarise(avg_engagement = mean(engaged_read))

    ggplot(section_perf, aes(x = section, y = avg_engagement, fill = section)) +
      geom_bar(stat = "identity") +
      labs(title = "Engagement by Section", x = "Section", y = "Avg Engagement") +
      theme_minimal() +
      theme(legend.position = "none")
  })

  # Audience Behavior
  output$traffic_source_chart <- renderPlot({
    traffic <- sessions %>%
      count(traffic_source) %>%
      mutate(percentage = n / sum(n) * 100)

    ggplot(traffic, aes(x = "", y = percentage, fill = traffic_source)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar("y", start = 0) +
      labs(title = "Traffic Source Breakdown") +
      theme_void()
  })

  output$device_comparison_chart <- renderPlot({
    device <- sessions %>%
      count(device_type)

    ggplot(device, aes(x = device_type, y = n, fill = device_type)) +
      geom_bar(stat = "identity") +
      labs(title = "Sessions by Device Type", x = "Device", y = "Sessions") +
      theme_minimal() +
      theme(legend.position = "none")
  })

  output$engagement_by_device <- renderPlot({
    device_engagement <- engagement_data %>%
      group_by(device_type) %>%
      summarise(
        avg_time = mean(time_on_page_seconds),
        avg_scroll = mean(scroll_depth_pct),
        engagement_rate = mean(engaged_read)
      ) %>%
      pivot_longer(cols = c(avg_time, avg_scroll, engagement_rate), names_to = "metric", values_to = "value")

    ggplot(device_engagement, aes(x = device_type, y = value, fill = device_type)) +
      geom_bar(stat = "identity") +
      facet_wrap(~metric, scales = "free_y") +
      labs(title = "Engagement Metrics by Device", x = "Device", y = "Value") +
      theme_minimal() +
      theme(legend.position = "none")
  })

  # A/B Testing
  ab_data <- reactive({
    ab_test_events %>% filter(test_id == input$test_id_select)
  })

  output$ab_ctr_a <- renderValueBox({
    data <- ab_data()
    ctr_a <- sum(data$click[data$variant == "A"]) / sum(data$impression[data$variant == "A"]) * 100
    valueBox(sprintf("%.2f%%", ctr_a), "CTR Variant A", icon = icon("mouse-pointer"), color = "blue")
  })

  output$ab_ctr_b <- renderValueBox({
    data <- ab_data()
    ctr_b <- sum(data$click[data$variant == "B"]) / sum(data$impression[data$variant == "B"]) * 100
    valueBox(sprintf("%.2f%%", ctr_b), "CTR Variant B", icon = icon("mouse-pointer"), color = "green")
  })

  output$ab_significance <- renderValueBox({
    data <- ab_data()
    test <- prop.test(
      x = c(sum(data$click[data$variant == "A"]), sum(data$click[data$variant == "B"])),
      n = c(sum(data$impression[data$variant == "A"]), sum(data$impression[data$variant == "B"]))
    )
    sig <- ifelse(test$p.value < 0.05, "Significant", "Not Significant")
    valueBox(sig, "Statistical Significance", icon = icon("chart-line"), color = ifelse(test$p.value < 0.05, "red", "orange"))
  })

  output$ab_variant_comparison <- renderPlot({
    data <- ab_data() %>%
      group_by(variant) %>%
      summarise(
        ctr = sum(click) / sum(impression),
        engaged_read_rate = sum(engaged_read) / sum(impression),
        subscription_rate = sum(subscription) / sum(impression)
      ) %>%
      pivot_longer(cols = c(ctr, engaged_read_rate, subscription_rate), names_to = "metric", values_to = "value")

    ggplot(data, aes(x = variant, y = value, fill = variant)) +
      geom_bar(stat = "identity") +
      facet_wrap(~metric, scales = "free_y") +
      labs(title = "A/B Test Variant Comparison", x = "Variant", y = "Rate") +
      theme_minimal() +
      theme(legend.position = "none")
  })
}

# Run the app
shinyApp(ui, server)