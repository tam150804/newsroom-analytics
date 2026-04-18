# Newsroom Storytelling Analytics

A comprehensive analytics platform for digital newsroom operations, featuring data generation, analysis, visualization, and business intelligence integrations.

## Project Overview

This project demonstrates a complete analytics pipeline for a digital newsroom, including:

- Synthetic data generation for realistic testing
- Data quality validation and profiling
- Predictive modeling for user engagement
- Multiple visualization platforms (Shiny, Flexdashboard, Tableau, Power BI)
- REST API for programmatic access
- Automated reporting system
- A/B testing analysis

## Project Structure

```
newsroom-storytelling-analytics/
├── data/
│   └── raw/                    # Synthetic data files (CSV)
│       ├── articles.csv
│       ├── users.csv
│       ├── sessions.csv
│       ├── article_events.csv
│       └── ab_test_events.csv
├── outputs/
│   ├── figures/               # Generated plots and visualizations
│   ├── models/                # Trained ML models
│   └── *.html/csv             # Reports and summaries
├── scripts/
│   ├── generate_data.R        # Data generation
│   ├── analyze_engagement.R   # Engagement analysis
│   ├── analyze_ab_test.R      # A/B testing analysis
│   ├── data_quality_checks.R  # Data validation
│   ├── predictive_modeling.R  # ML models
│   ├── automated_reporting.R  # Daily reports
│   ├── dashboard.R            # Shiny dashboard
│   └── api.R                  # REST API
├── flexdashboard.Rmd          # Flexdashboard
├── create_tables.sql          # Database schema
├── create_reporting_tables.sql # Reporting tables
├── tableau_integration_guide.md
├── powerbi_integration_guide.md
├── related_articles_tracking_plan.md
├── .gitignore
└── README.md
```

## Quick Start

### Prerequisites
- R (version 4.0+)
- R packages: tidyverse, shiny, shinydashboard, DT, plotly, rmarkdown, plumber, etc.

### Installation
```bash
# Install required packages
install.packages(c("tidyverse", "shiny", "shinydashboard", "DT", "plotly",
                   "rmarkdown", "plumber", "caret", "randomForest", "xgboost",
                   "blastula", "flexdashboard", "DataExplorer", "validate"))
```

### Generate Data
```bash
Rscript generate_data.R
```

### Run Data Quality Checks
```bash
Rscript data_quality_checks.R
```

### Run Predictive Modeling
```bash
Rscript predictive_modeling.R
```

### Launch Shiny Dashboard
```bash
Rscript -e "shiny::runApp('dashboard.R')"
```

### Launch Flexdashboard
```bash
Rscript -e "rmarkdown::run('flexdashboard.Rmd')"
```

### Start API Server
```bash
Rscript -e "plumber::plumb('api.R')$run(port = 8000)"
```

### Generate Automated Reports
```bash
Rscript automated_reporting.R
```

## Data Schema

### Articles
- `article_id`: Unique article identifier
- `publish_date`: Publication date
- `title`: Article title
- `section`: News section (politics, business, tech, culture, science, world)
- `author`: Article author
- `format_type`: Article format (news, analysis, opinion, feature)
- `word_count`: Article length
- `paywalled`: Paywall status

### Users
- `user_id`: Unique user identifier
- `signup_date`: User registration date
- `country`: User country
- `device_preference`: Preferred device
- `subscriber_status`: Subscription status

### Sessions
- `session_id`: Unique session identifier
- `user_id`: Associated user
- `session_start`: Session start time
- `traffic_source`: How user arrived
- `device_type`: Device used

### Article Events
- `event_id`: Unique event identifier
- `session_id`: Associated session
- `user_id`: Associated user
- `article_id`: Associated article
- `event_timestamp`: Event time
- `pageviews`: Pageview count
- `time_on_page_seconds`: Time spent
- `scroll_depth_pct`: Scroll percentage
- `engaged_read`: Engagement flag
- `subscribed`: Subscription flag

### A/B Test Events
- `test_id`: Test identifier
- `user_id`: Test participant
- `variant`: Test variant (A/B)
- `impression`: Impression count
- `click`: Click count
- `engaged_read`: Engagement count
- `subscription`: Subscription count

## Analytics Features

### Data Quality & Validation
- Comprehensive data profiling
- Integrity checks and validation rules
- Automated quality reporting

### Predictive Modeling
- User engagement prediction (Random Forest, XGBoost)
- Time on page prediction
- Feature importance analysis
- Model performance evaluation

### Visualization Platforms

#### Shiny Dashboard
Interactive web application with:
- Real-time filtering
- Multiple visualization types
- A/B testing results
- Responsive design

#### Flexdashboard
R Markdown-based dashboard with:
- Plotly interactive charts
- Tabbed interface
- Self-contained HTML output

#### Tableau Integration
- CSV data connection guide
- Calculated field definitions
- Dashboard layout recommendations
- Best practices for large datasets

#### Power BI Integration
- Data import and transformation steps
- DAX measures and calculations
- Dashboard design patterns
- Publishing and sharing workflows

### API Endpoints
- `/article/<id>`: Article metrics
- `/user/<id>`: User analytics
- `/section/<section>`: Section performance
- `/ab_test/<test_id>`: A/B test results
- `/predict_engagement`: ML predictions
- `/dashboard_metrics`: Overview KPIs

### Automated Reporting
- Daily HTML reports via email
- Weekly summary CSV exports
- Configurable recipients and schedules
- Professional report formatting

## A/B Testing Framework

### Test Design
- Randomized controlled experiments
- Statistical significance testing
- Confidence interval calculations
- Power analysis for sample sizing

### Tracking Plan
- Event definitions and properties
- Success and guardrail metrics
- Segmentation dimensions
- Implementation requirements

## Business Intelligence Integration

### Tableau
- Direct CSV connections
- Custom calculated fields
- Advanced analytics features
- Server publishing workflows

### Power BI
- Data modeling and relationships
- DAX measures and time intelligence
- Forecasting and clustering
- Service publishing and sharing

## Development Workflow

1. **Data Generation**: Create synthetic datasets
2. **Quality Assurance**: Validate data integrity
3. **Model Development**: Train predictive models
4. **Dashboard Creation**: Build interactive visualizations
5. **API Development**: Create programmatic access
6. **Integration**: Connect to BI platforms
7. **Automation**: Set up reporting pipelines
8. **Deployment**: Publish to production

## Performance Considerations

- Data is optimized for ~150K events
- Models trained on balanced samples
- Dashboards designed for real-time interaction
- API endpoints cached for performance
- Reports generated on schedule

## Security & Privacy

- Anonymous user identifiers
- No personally identifiable information
- Secure API authentication (when deployed)
- Data encryption at rest and in transit
- Compliance with privacy regulations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## License

This project is for educational and demonstration purposes. Please ensure compliance with your organization's data policies before using in production.

## Contact

For questions or support, please contact the analytics team.