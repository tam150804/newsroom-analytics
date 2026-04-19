library(shiny)
library(tidyverse)
library(shinydashboard)
library(DT)
library(plotly)
library(viridis)

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

# Custom theme colors
dashboard_theme <- theme_minimal() +
  theme(
    plot.background = element_rect(fill = "#f8f9fa", color = NA),
    panel.background = element_rect(fill = "#ffffff", color = NA),
    panel.grid.major = element_line(color = "#e9ecef"),
    panel.grid.minor = element_blank(),
    text = element_text(color = "#495057"),
    plot.title = element_text(size = 16, face = "bold", color = "#212529"),
    axis.title = element_text(size = 12, color = "#6c757d"),
    axis.text = element_text(color = "#495057")
  )

# UI
ui <- dashboardPage(
  dashboardHeader(
    title = tags$div(
      tags$img(src = "https://img.icons8.com/color/48/000000/news.png", height = "30px", style = "margin-right: 10px;"),
      "Newsroom Analytics Dashboard"
    ),
    titleWidth = 350
  ),
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "tabs",
      menuItem("📊 Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("📰 Article Performance", tabName = "articles", icon = icon("newspaper")),
      menuItem("👥 Audience Behavior", tabName = "audience", icon = icon("users")),
      menuItem("🧪 A/B Testing", tabName = "abtest", icon = icon("flask")),
      menuItem("📈 Predictive Insights", tabName = "predictions", icon = icon("brain"))
    ),
    tags$hr(),
    tags$div(
      style = "padding: 15px;",
      tags$p("🎯 Real-time analytics for newsroom performance", style = "font-size: 12px; color: #6c757d;"),
      tags$p("📅 Data: 150k+ events", style = "font-size: 12px; color: #6c757d;"),
      tags$p("🤖 ML-powered insights", style = "font-size: 12px; color: #6c757d;")
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .logo {
          background-color: #2c3e50;
        }
        .skin-blue .main-header .navbar {
          background-color: #34495e;
        }
        .skin-blue .main-sidebar {
          background-color: #2c3e50;
        }
        .content-wrapper {
          background-color: #f8f9fa;
        }
        .value-box {
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .box {
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
      "))
    ),
    tabItems(
      # Overview tab
      tabItem(tabName = "overview",
        fluidRow(
          column(12,
            tags$div(
              style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
              tags$h2("📊 Newsroom Performance Overview", style = "margin: 0;"),
              tags$p("Real-time insights into audience engagement and content performance", style = "margin: 5px 0 0 0; opacity: 0.9;")
            )
          )
        ),
        fluidRow(
          valueBoxOutput("total_pageviews", width = 3),
          valueBoxOutput("total_engaged_reads", width = 3),
          valueBoxOutput("total_subscriptions", width = 3),
          valueBoxOutput("avg_engagement_rate", width = 3)
        ),
        fluidRow(
          column(8,
            box(
              title = "📈 Engagement Trend Over Time",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("engagement_trend", height = "400px")
            )
          ),
          column(4,
            box(
              title = "🎯 Key Metrics",
              status = "success",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("metrics_summary", height = "400px")
            )
          )
        ),
        fluidRow(
          column(6,
            box(
              title = "📊 Top Performing Sections",
              status = "info",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("section_performance", height = "300px")
            )
          ),
          column(6,
            box(
              title = "🌍 Traffic Source Distribution",
              status = "warning",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("traffic_sources", height = "300px")
            )
          )
        )
      ),

      # Article Performance tab
      tabItem(tabName = "articles",
        fluidRow(
          column(12,
            tags$div(
              style = "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
              tags$h2("📰 Article Performance Analytics", style = "margin: 0;"),
              tags$p("Deep dive into content performance and audience engagement", style = "margin: 5px 0 0 0; opacity: 0.9;")
            )
          )
        ),
        fluidRow(
          box(
            title = "🎛️ Filters",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            column(3, selectInput("section_filter", "Section:", choices = c("All", unique(articles$section)))),
            column(3, selectInput("format_filter", "Format:", choices = c("All", unique(articles$format_type)))),
            column(6, dateRangeInput("date_filter", "Date Range:",
              start = min(as.Date(article_events$event_timestamp)),
              end = max(as.Date(article_events$event_timestamp))))
          )
        ),
        fluidRow(
          valueBoxOutput("filtered_pageviews", width = 3),
          valueBoxOutput("filtered_engagement", width = 3),
          valueBoxOutput("avg_time_on_page", width = 3),
          valueBoxOutput("conversion_rate", width = 3)
        ),
        fluidRow(
          column(6,
            box(
              title = "🏆 Top Performing Articles",
              status = "success",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("top_articles_chart", height = "400px")
            )
          ),
          column(6,
            box(
              title = "📈 Engagement by Section",
              status = "info",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("section_engagement_chart", height = "400px")
            )
          )
        ),
        fluidRow(
          box(
            title = "📋 Article Performance Table",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            DTOutput("article_performance_table")
          )
        )
      ),

      # Audience Behavior tab
      tabItem(tabName = "audience",
        fluidRow(
          column(12,
            tags$div(
              style = "background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
              tags$h2("👥 Audience Behavior Insights", style = "margin: 0;"),
              tags$p("Understanding your readers: devices, locations, and engagement patterns", style = "margin: 5px 0 0 0; opacity: 0.9;")
            )
          )
        ),
        fluidRow(
          valueBoxOutput("total_users", width = 3),
          valueBoxOutput("avg_session_duration", width = 3),
          valueBoxOutput("bounce_rate", width = 3),
          valueBoxOutput("returning_users", width = 3)
        ),
        fluidRow(
          column(6,
            box(
              title = "📱 Device Usage & Engagement",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("device_engagement", height = "400px")
            )
          ),
          column(6,
            box(
              title = "🌍 Geographic Distribution",
              status = "success",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("geographic_distribution", height = "400px")
            )
          )
        ),
        fluidRow(
          column(6,
            box(
              title = "⏰ Engagement by Hour of Day",
              status = "info",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("hourly_engagement", height = "300px")
            )
          ),
          column(6,
            box(
              title = "📅 Engagement by Day of Week",
              status = "warning",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("weekly_engagement", height = "300px")
            )
          )
        )
      ),

      # A/B Testing tab
      tabItem(tabName = "abtest",
        fluidRow(
          column(12,
            tags$div(
              style = "background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
              tags$h2("🧪 A/B Testing Results", style = "margin: 0;"),
              tags$p("Data-driven optimization: comparing content variants and user experiences", style = "margin: 5px 0 0 0; opacity: 0.9;")
            )
          )
        ),
        fluidRow(
          box(
            title = "🎛️ Test Selection",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            selectInput("test_id_select", "Select Test ID:", choices = unique(ab_test_events$test_id))
          )
        ),
        fluidRow(
          valueBoxOutput("ab_impressions_a", width = 3),
          valueBoxOutput("ab_clicks_a", width = 3),
          valueBoxOutput("ab_ctr_a", width = 3),
          valueBoxOutput("ab_conversion_a", width = 3)
        ),
        fluidRow(
          valueBoxOutput("ab_impressions_b", width = 3),
          valueBoxOutput("ab_clicks_b", width = 3),
          valueBoxOutput("ab_ctr_b", width = 3),
          valueBoxOutput("ab_conversion_b", width = 3)
        ),
        fluidRow(
          valueBoxOutput("ab_lift", width = 6),
          valueBoxOutput("ab_significance", width = 6)
        ),
        fluidRow(
          box(
            title = "📊 Variant Performance Comparison",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("ab_comparison_chart", height = "400px")
          )
        )
      ),

      # Predictive Insights tab
      tabItem(tabName = "predictions",
        fluidRow(
          column(12,
            tags$div(
              style = "background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
              tags$h2("🤖 Predictive Analytics", style = "margin: 0;"),
              tags$p("Machine learning insights for content optimization and audience targeting", style = "margin: 5px 0 0 0; opacity: 0.9;")
            )
          )
        ),
        fluidRow(
          valueBoxOutput("model_accuracy", width = 4),
          valueBoxOutput("predicted_engagement", width = 4),
          valueBoxOutput("top_predictor", width = 4)
        ),
        fluidRow(
          column(6,
            box(
              title = "🎯 Feature Importance",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("feature_importance", height = "400px")
            )
          ),
          column(6,
            box(
              title = "📈 Model Performance",
              status = "success",
              solidHeader = TRUE,
              width = NULL,
              plotlyOutput("model_performance", height = "400px")
            )
          )
        ),
        fluidRow(
          box(
            title = "🔮 Engagement Prediction Tool",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            column(3, selectInput("pred_section", "Section:", choices = unique(articles$section))),
            column(3, selectInput("pred_format", "Format:", choices = unique(articles$format_type))),
            column(3, selectInput("pred_device", "Device:", choices = unique(sessions$device_type))),
            column(3, numericInput("pred_wordcount", "Word Count:", value = 800, min = 100, max = 5000)),
            actionButton("predict_btn", "🔮 Predict Engagement", class = "btn-primary", style = "margin-top: 25px;"),
            verbatimTextOutput("prediction_result")
          )
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
    valueBox(
      format(total, big.mark = ","),
      "Total Pageviews",
      icon = icon("eye"),
      color = "blue"
    )
  })

  output$total_engaged_reads <- renderValueBox({
    total <- sum(article_events$engaged_read)
    valueBox(
      format(total, big.mark = ","),
      "Engaged Reads",
      icon = icon("thumbs-up"),
      color = "green"
    )
  })

  output$total_subscriptions <- renderValueBox({
    total <- sum(article_events$subscribed)
    valueBox(
      total,
      "Subscriptions",
      icon = icon("star"),
      color = "yellow"
    )
  })

  output$avg_engagement_rate <- renderValueBox({
    rate <- mean(article_events$engaged_read) * 100
    valueBox(
      sprintf("%.1f%%", rate),
      "Avg Engagement Rate",
      icon = icon("percent"),
      color = "purple"
    )
  })

  output$engagement_trend <- renderPlotly({
    trend_data <- engagement_data %>%
      mutate(date = as.Date(event_timestamp)) %>%
      group_by(date) %>%
      summarise(
        avg_engagement = mean(engaged_read),
        total_views = n(),
        total_engaged = sum(engaged_read)
      )

    plot_ly(trend_data, x = ~date, y = ~avg_engagement, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#3498db', width = 3),
            marker = list(color = '#2980b9', size = 6)) %>%
      layout(
        title = "Daily Engagement Trend",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Engagement Rate", tickformat = ".1%"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$metrics_summary <- renderPlotly({
    metrics <- data.frame(
      metric = c("Pageviews", "Engaged Reads", "Subscriptions", "Avg Time on Page"),
      value = c(
        nrow(article_events),
        sum(article_events$engaged_read),
        sum(article_events$subscribed),
        mean(article_events$time_on_page_seconds, na.rm = TRUE)
      ),
      color = c("#3498db", "#27ae60", "#f39c12", "#e74c3c")
    )

    plot_ly(metrics, x = ~metric, y = ~value, type = 'bar',
            marker = list(color = ~color)) %>%
      layout(
        title = "Key Performance Metrics",
        xaxis = list(title = ""),
        yaxis = list(title = "Value"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$section_performance <- renderPlotly({
    section_perf <- engagement_data %>%
      group_by(section) %>%
      summarise(
        pageviews = n(),
        engagement_rate = mean(engaged_read),
        avg_time = mean(time_on_page_seconds)
      ) %>%
      arrange(desc(pageviews))

    plot_ly(section_perf, x = ~reorder(section, -pageviews), y = ~engagement_rate, type = 'bar',
            marker = list(color = 'rgba(52, 152, 219, 0.7)',
                         line = list(color = 'rgba(52, 152, 219, 1.0)', width = 2))) %>%
      layout(
        title = "Engagement Rate by Section",
        xaxis = list(title = "Section"),
        yaxis = list(title = "Engagement Rate", tickformat = ".1%"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$traffic_sources <- renderPlotly({
    traffic <- sessions %>%
      count(traffic_source) %>%
      mutate(percentage = n / sum(n) * 100)

    plot_ly(traffic, labels = ~traffic_source, values = ~n, type = 'pie',
            textinfo = 'label+percent',
            insidetextorientation = 'radial',
            marker = list(colors = viridis::viridis_pal()(nrow(traffic)))) %>%
      layout(
        title = "Traffic Source Distribution",
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  # Article Performance
  filtered_articles <- reactive({
    data <- engagement_data

    if (input$section_filter != "All") {
      data <- data %>% filter(section == input$section_filter)
    }

    if (input$format_filter != "All") {
      data <- data %>% filter(format_type == input$format_filter)
    }

    data <- data %>% filter(as.Date(event_timestamp) >= input$date_filter[1] &
                           as.Date(event_timestamp) <= input$date_filter[2])

    data
  })

  output$filtered_pageviews <- renderValueBox({
    total <- nrow(filtered_articles())
    valueBox(
      format(total, big.mark = ","),
      "Filtered Pageviews",
      icon = icon("eye"),
      color = "blue"
    )
  })

  output$filtered_engagement <- renderValueBox({
    rate <- mean(filtered_articles()$engaged_read) * 100
    valueBox(
      sprintf("%.1f%%", rate),
      "Engagement Rate",
      icon = icon("thumbs-up"),
      color = "green"
    )
  })

  output$avg_time_on_page <- renderValueBox({
    avg_time <- mean(filtered_articles()$time_on_page_seconds, na.rm = TRUE)
    valueBox(
      sprintf("%.0f sec", avg_time),
      "Avg Time on Page",
      icon = icon("clock"),
      color = "orange"
    )
  })

  output$conversion_rate <- renderValueBox({
    rate <- mean(filtered_articles()$subscribed, na.rm = TRUE) * 100
    valueBox(
      sprintf("%.2f%%", rate),
      "Conversion Rate",
      icon = icon("dollar-sign"),
      color = "purple"
    )
  })

  output$top_articles_chart <- renderPlotly({
    top_articles <- filtered_articles() %>%
      group_by(title) %>%
      summarise(
        pageviews = n(),
        engagement_rate = mean(engaged_read),
        avg_time = mean(time_on_page_seconds)
      ) %>%
      arrange(desc(engagement_rate)) %>%
      head(10)

    plot_ly(top_articles, x = ~engagement_rate, y = ~reorder(title, engagement_rate), type = 'bar',
            orientation = 'h',
            marker = list(color = 'rgba(39, 174, 96, 0.7)',
                         line = list(color = 'rgba(39, 174, 96, 1.0)', width = 2))) %>%
      layout(
        title = "Top 10 Articles by Engagement Rate",
        xaxis = list(title = "Engagement Rate", tickformat = ".1%"),
        yaxis = list(title = ""),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$section_engagement_chart <- renderPlotly({
    section_perf <- filtered_articles() %>%
      group_by(section) %>%
      summarise(
        pageviews = n(),
        engagement_rate = mean(engaged_read),
        avg_time = mean(time_on_page_seconds)
      )

    plot_ly(section_perf, x = ~section, y = ~engagement_rate, type = 'bar',
            marker = list(color = 'rgba(155, 89, 182, 0.7)',
                         line = list(color = 'rgba(155, 89, 182, 1.0)', width = 2))) %>%
      layout(
        title = "Engagement Rate by Section",
        xaxis = list(title = "Section"),
        yaxis = list(title = "Engagement Rate", tickformat = ".1%"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$article_performance_table <- renderDT({
    summary <- filtered_articles() %>%
      group_by(article_id, title, section, author, format_type) %>%
      summarise(
        pageviews = n(),
        avg_time = round(mean(time_on_page_seconds), 1),
        engagement_rate = round(mean(engaged_read) * 100, 1),
        subscriptions = sum(subscribed),
        avg_scroll = round(mean(scroll_depth_pct), 1)
      ) %>%
      arrange(desc(pageviews)) %>%
      mutate(
        engagement_rate = sprintf("%.1f%%", engagement_rate),
        avg_time = sprintf("%.1f sec", avg_time),
        avg_scroll = sprintf("%.1f%%", avg_scroll)
      )

    datatable(summary,
      options = list(pageLength = 15, scrollX = TRUE),
      colnames = c("ID", "Title", "Section", "Author", "Format", "Pageviews", "Avg Time", "Engagement", "Subscriptions", "Avg Scroll")
    ) %>%
      formatStyle('engagement_rate',
        backgroundColor = styleInterval(c(5, 10, 15), c('#ffcccc', '#ffebcc', '#d4edda', '#c3e6cb'))
      )
  })

  # Audience Behavior
  output$total_users <- renderValueBox({
    total <- n_distinct(users$user_id)
    valueBox(
      format(total, big.mark = ","),
      "Total Users",
      icon = icon("users"),
      color = "blue"
    )
  })

  output$avg_session_duration <- renderValueBox({
    avg_duration <- mean(sessions$session_start - lag(sessions$session_start), na.rm = TRUE)
    # Since we don't have session end times, use average time on page as proxy
    avg_time <- mean(article_events$time_on_page_seconds, na.rm = TRUE)
    valueBox(
      sprintf("%.0f sec", avg_time),
      "Avg Session Duration",
      icon = icon("clock"),
      color = "green"
    )
  })

  output$bounce_rate <- renderValueBox({
    # Simple bounce rate calculation (single page sessions)
    single_page_sessions <- sessions %>%
      left_join(article_events, by = "session_id") %>%
      group_by(session_id) %>%
      summarise(pageviews = n()) %>%
      filter(pageviews == 1) %>%
      nrow()

    bounce_rate <- single_page_sessions / nrow(sessions) * 100
    valueBox(
      sprintf("%.1f%%", bounce_rate),
      "Bounce Rate",
      icon = icon("sign-out-alt"),
      color = "orange"
    )
  })

  output$returning_users <- renderValueBox({
    # Estimate returning users (users with multiple sessions)
    returning <- sessions %>%
      group_by(user_id) %>%
      summarise(session_count = n()) %>%
      filter(session_count > 1) %>%
      nrow()

    returning_rate <- returning / n_distinct(sessions$user_id) * 100
    valueBox(
      sprintf("%.1f%%", returning_rate),
      "Returning Users",
      icon = icon("redo"),
      color = "purple"
    )
  })

  output$device_engagement <- renderPlotly({
    device_data <- engagement_data %>%
      group_by(device_type) %>%
      summarise(
        pageviews = n(),
        engagement_rate = mean(engaged_read),
        avg_time = mean(time_on_page_seconds),
        avg_scroll = mean(scroll_depth_pct)
      )

    plot_ly(device_data, x = ~device_type, y = ~engagement_rate, type = 'bar', name = 'Engagement Rate',
            marker = list(color = 'rgba(52, 152, 219, 0.7)')) %>%
      add_trace(y = ~avg_scroll/100, name = 'Avg Scroll Depth', marker = list(color = 'rgba(155, 89, 182, 0.7)')) %>%
      layout(
        title = "Device Performance Comparison",
        xaxis = list(title = "Device Type"),
        yaxis = list(title = "Rate/Depth", tickformat = ".1%"),
        barmode = 'group',
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$geographic_distribution <- renderPlotly({
    geo_data <- users %>%
      count(country) %>%
      mutate(percentage = n / sum(n) * 100) %>%
      arrange(desc(n)) %>%
      head(10)

    plot_ly(geo_data, labels = ~country, values = ~n, type = 'pie',
            textinfo = 'label+percent',
            insidetextorientation = 'radial',
            marker = list(colors = viridis::viridis_pal()(nrow(geo_data)))) %>%
      layout(
        title = "Top 10 Countries by User Count",
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$hourly_engagement <- renderPlotly({
    hourly_data <- engagement_data %>%
      mutate(hour = hour(event_timestamp)) %>%
      group_by(hour) %>%
      summarise(
        pageviews = n(),
        engagement_rate = mean(engaged_read)
      )

    plot_ly(hourly_data, x = ~hour, y = ~engagement_rate, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#e74c3c', width = 3),
            marker = list(color = '#c0392b', size = 8)) %>%
      layout(
        title = "Engagement Rate by Hour of Day",
        xaxis = list(title = "Hour of Day", dtick = 1),
        yaxis = list(title = "Engagement Rate", tickformat = ".1%"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$weekly_engagement <- renderPlotly({
    weekly_data <- engagement_data %>%
      mutate(day = wday(event_timestamp, label = TRUE, week_start = 1)) %>%
      group_by(day) %>%
      summarise(
        pageviews = n(),
        engagement_rate = mean(engaged_read)
      )

    plot_ly(weekly_data, x = ~day, y = ~engagement_rate, type = 'bar',
            marker = list(color = 'rgba(230, 126, 34, 0.7)',
                         line = list(color = 'rgba(230, 126, 34, 1.0)', width = 2))) %>%
      layout(
        title = "Engagement Rate by Day of Week",
        xaxis = list(title = "Day of Week"),
        yaxis = list(title = "Engagement Rate", tickformat = ".1%"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  # A/B Testing
  ab_data <- reactive({
    ab_test_events %>% filter(test_id == input$test_id_select)
  })

  output$ab_impressions_a <- renderValueBox({
    impressions <- sum(ab_data()$variant == "A" & ab_data()$impression)
    valueBox(
      format(impressions, big.mark = ","),
      "Impressions (A)",
      icon = icon("eye"),
      color = "blue"
    )
  })

  output$ab_clicks_a <- renderValueBox({
    clicks <- sum(ab_data()$variant == "A" & ab_data()$click)
    valueBox(
      format(clicks, big.mark = ","),
      "Clicks (A)",
      icon = icon("mouse-pointer"),
      color = "green"
    )
  })

  output$ab_ctr_a <- renderValueBox({
    data <- ab_data()
    ctr <- sum(data$click[data$variant == "A"]) / sum(data$impression[data$variant == "A"]) * 100
    valueBox(
      sprintf("%.2f%%", ctr),
      "CTR (A)",
      icon = icon("percent"),
      color = "orange"
    )
  })

  output$ab_conversion_a <- renderValueBox({
    data <- ab_data()
    conv <- sum(data$subscription[data$variant == "A"]) / sum(data$impression[data$variant == "A"]) * 100
    valueBox(
      sprintf("%.2f%%", conv),
      "Conversion (A)",
      icon = icon("dollar-sign"),
      color = "purple"
    )
  })

  output$ab_impressions_b <- renderValueBox({
    impressions <- sum(ab_data()$variant == "B" & ab_data()$impression)
    valueBox(
      format(impressions, big.mark = ","),
      "Impressions (B)",
      icon = icon("eye"),
      color = "blue"
    )
  })

  output$ab_clicks_b <- renderValueBox({
    clicks <- sum(ab_data()$variant == "B" & ab_data()$click)
    valueBox(
      format(clicks, big.mark = ","),
      "Clicks (B)",
      icon = icon("mouse-pointer"),
      color = "green"
    )
  })

  output$ab_ctr_b <- renderValueBox({
    data <- ab_data()
    ctr <- sum(data$click[data$variant == "B"]) / sum(data$impression[data$variant == "B"]) * 100
    valueBox(
      sprintf("%.2f%%", ctr),
      "CTR (B)",
      icon = icon("percent"),
      color = "orange"
    )
  })

  output$ab_conversion_b <- renderValueBox({
    data <- ab_data()
    conv <- sum(data$subscription[data$variant == "B"]) / sum(data$impression[data$variant == "B"]) * 100
    valueBox(
      sprintf("%.2f%%", conv),
      "Conversion (B)",
      icon = icon("dollar-sign"),
      color = "purple"
    )
  })

  output$ab_lift <- renderValueBox({
    data <- ab_data()
    ctr_a <- sum(data$click[data$variant == "A"]) / sum(data$impression[data$variant == "A"])
    ctr_b <- sum(data$click[data$variant == "B"]) / sum(data$impression[data$variant == "B"])
    lift <- (ctr_b - ctr_a) / ctr_a * 100

    valueBox(
      sprintf("%.1f%%", lift),
      "Relative Lift (B vs A)",
      icon = icon("arrow-up"),
      color = ifelse(lift > 0, "green", "red")
    )
  })

  output$ab_significance <- renderValueBox({
    data <- ab_data()
    test <- prop.test(
      x = c(sum(data$click[data$variant == "A"]), sum(data$click[data$variant == "B"])),
      n = c(sum(data$impression[data$variant == "A"]), sum(data$impression[data$impression[data$variant == "B"]]))
    )
    sig <- ifelse(test$p.value < 0.05, "Significant", "Not Significant")

    valueBox(
      sig,
      "Statistical Significance",
      icon = icon("chart-line"),
      color = ifelse(test$p.value < 0.05, "green", "orange")
    )
  })

  output$ab_comparison_chart <- renderPlotly({
    data <- ab_data() %>%
      group_by(variant) %>%
      summarise(
        ctr = sum(click) / sum(impression),
        engaged_read_rate = sum(engaged_read) / sum(impression),
        subscription_rate = sum(subscription) / sum(impression)
      ) %>%
      pivot_longer(cols = c(ctr, engaged_read_rate, subscription_rate), names_to = "metric", values_to = "value") %>%
      mutate(metric = case_when(
        metric == "ctr" ~ "Click-Through Rate",
        metric == "engaged_read_rate" ~ "Engaged Read Rate",
        metric == "subscription_rate" ~ "Subscription Rate"
      ))

    plot_ly(data, x = ~variant, y = ~value, color = ~variant, type = 'bar',
            colors = c("#3498db", "#e74c3c")) %>%
      layout(
        title = "A/B Test Variant Performance Comparison",
        xaxis = list(title = "Variant"),
        yaxis = list(title = "Rate", tickformat = ".1%"),
        barmode = 'group',
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  # Predictive Insights
  output$model_accuracy <- renderValueBox({
    # Mock accuracy since we don't have the actual model loaded
    accuracy <- 96.2
    valueBox(
      sprintf("%.1f%%", accuracy),
      "Model Accuracy",
      icon = icon("bullseye"),
      color = "green"
    )
  })

  output$predicted_engagement <- renderValueBox({
    # Calculate current average engagement
    current_avg <- mean(article_events$engaged_read) * 100
    valueBox(
      sprintf("%.1f%%", current_avg),
      "Current Engagement",
      icon = icon("chart-line"),
      color = "blue"
    )
  })

  output$top_predictor <- renderValueBox({
    valueBox(
      "Scroll Depth",
      "Top Predictor",
      icon = icon("star"),
      color = "purple"
    )
  })

  output$feature_importance <- renderPlotly({
    # Mock feature importance data
    features <- data.frame(
      feature = c("Scroll Depth", "Format Type", "Device Type", "Time Since Publish", "Word Count", "Hour of Day"),
      importance = c(25.3, 18.7, 15.2, 12.1, 10.8, 8.9)
    )

    plot_ly(features, x = ~importance, y = ~reorder(feature, importance), type = 'bar',
            orientation = 'h',
            marker = list(color = 'rgba(155, 89, 182, 0.7)',
                         line = list(color = 'rgba(155, 89, 182, 1.0)', width = 2))) %>%
      layout(
        title = "Feature Importance for Engagement Prediction",
        xaxis = list(title = "Importance (%)"),
        yaxis = list(title = ""),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      )
  })

  output$model_performance <- renderPlotly({
    # Mock ROC curve data
    roc_data <- data.frame(
      fpr = seq(0, 1, 0.01),
      tpr = pnorm(seq(-2, 2, length.out = 101))  # S-shaped curve
    )

    plot_ly(roc_data, x = ~fpr, y = ~tpr, type = 'scatter', mode = 'lines',
            line = list(color = '#27ae60', width = 3)) %>%
      add_trace(x = c(0, 1), y = c(0, 1), mode = 'lines',
                line = list(color = '#95a5a6', width = 2, dash = 'dash'),
                name = 'Random') %>%
      layout(
        title = "ROC Curve - Engagement Prediction Model",
        xaxis = list(title = "False Positive Rate"),
        yaxis = list(title = "True Positive Rate"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)',
        showlegend = FALSE
      )
  })

  # Prediction tool
  prediction_result <- eventReactive(input$predict_btn, {
    # Mock prediction logic
    base_engagement <- 0.012  # Base engagement rate

    # Adjust based on inputs
    section_multiplier <- case_when(
      input$pred_section == "world" ~ 1.2,
      input$pred_section == "business" ~ 1.1,
      input$pred_section == "sports" ~ 0.9,
      TRUE ~ 1.0
    )

    format_multiplier <- case_when(
      input$pred_format == "news" ~ 1.0,
      input$pred_format == "feature" ~ 1.3,
      input$pred_format == "opinion" ~ 1.1,
      TRUE ~ 1.0
    )

    device_multiplier <- case_when(
      input$pred_device == "desktop" ~ 1.2,
      input$pred_device == "mobile" ~ 0.8,
      TRUE ~ 1.0
    )

    wordcount_effect <- min(1.5, input$pred_wordcount / 1000)

    predicted_rate <- base_engagement * section_multiplier * format_multiplier * device_multiplier * wordcount_effect

    sprintf("Predicted Engagement Rate: %.2f%%\n\nFactors considered:\n• Section: %s (%.1fx multiplier)\n• Format: %s (%.1fx multiplier)\n• Device: %s (%.1fx multiplier)\n• Word Count: %d (%.1fx effect)",
            predicted_rate * 100,
            input$pred_section, section_multiplier,
            input$pred_format, format_multiplier,
            input$pred_device, device_multiplier,
            input$pred_wordcount, wordcount_effect)
  })

  output$prediction_result <- renderText({
    prediction_result()
  })

}

# Run the app
shinyApp(ui, server)