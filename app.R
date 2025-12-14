# ==============================================================================
# Modern Shiny Dashboard for Poverty Analysis in Tunisia
# Analyzing Enquête vs Recensement data by Governorate and Region
# ==============================================================================

library(shiny)
library(shinydashboard)
library(ggplot2)
library(plotly)
library(dplyr)
library(DT)

# ==============================================================================
# Data Loading and Preparation
# ==============================================================================

# Load data with error handling
tryCatch({
  gouvernorat_data <- read.csv("par_gouvernorat.csv", stringsAsFactors = FALSE)
  region_data <- read.csv("par_region.csv", stringsAsFactors = FALSE)
}, error = function(e) {
  stop("Error loading data files. Please ensure 'par_gouvernorat.csv' and 'par_region.csv' are in the same directory as app.R.\nError: ", e$message)
})

# ==============================================================================
# Custom CSS for Modern Design
# ==============================================================================

custom_css <- "
/* Modern Color Scheme & Global Styles */
:root {
  --primary-dark: #2C3E50;
  --primary-light: #3498DB;
  --secondary-teal: #16A085;
  --secondary-cyan: #1ABC9C;
  --accent-coral: #E67E22;
  --accent-red: #E74C3C;
  --success-green: #27AE60;
  --warning-amber: #F39C12;
  --bg-light: #ECF0F1;
  --bg-lighter: #F8F9FA;
  --shadow: 0 4px 6px rgba(0,0,0,0.1);
}

/* Body & Main Container */
body, .content-wrapper, .right-side {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  font-family: 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

/* Dashboard Header */
.main-header .logo {
  background: linear-gradient(135deg, #2C3E50 0%, #34495E 100%) !important;
  color: white !important;
  font-weight: 700;
  font-size: 22px;
  border-bottom: 3px solid #1ABC9C;
  transition: all 0.3s ease;
}

.main-header .logo:hover {
  background: linear-gradient(135deg, #34495E 0%, #2C3E50 100%) !important;
  transform: scale(1.02);
}

.main-header .navbar {
  background: linear-gradient(135deg, #3498DB 0%, #2980B9 100%) !important;
  border-bottom: 2px solid #1ABC9C;
  box-shadow: 0 2px 10px rgba(0,0,0,0.2);
}

/* Sidebar Styling */
.main-sidebar {
  background: linear-gradient(180deg, #2C3E50 0%, #1a252f 100%) !important;
  box-shadow: 2px 0 15px rgba(0,0,0,0.3);
}

.sidebar-menu > li > a {
  color: #ECF0F1 !important;
  border-left: 4px solid transparent;
  transition: all 0.3s ease;
  padding: 15px 20px;
  font-weight: 500;
}

.sidebar-menu > li > a:hover {
  background: rgba(26, 188, 156, 0.2) !important;
  border-left: 4px solid #1ABC9C;
  color: white !important;
  padding-left: 25px;
}

.sidebar-menu > li.active > a {
  background: linear-gradient(90deg, rgba(26, 188, 156, 0.3) 0%, transparent 100%) !important;
  border-left: 4px solid #1ABC9C;
  color: white !important;
  font-weight: 600;
}

.sidebar-menu li a i {
  margin-right: 10px;
  font-size: 18px;
  color: #1ABC9C;
}

/* Content Area */
.content-wrapper {
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important;
  min-height: 100vh;
  padding: 20px;
}

/* Box/Card Styling */
.box {
  border-radius: 15px !important;
  box-shadow: 0 8px 20px rgba(0,0,0,0.15) !important;
  border: none !important;
  margin-bottom: 25px;
  background: white !important;
  transition: all 0.3s ease;
  overflow: hidden;
}

.box:hover {
  box-shadow: 0 12px 30px rgba(0,0,0,0.2) !important;
  transform: translateY(-5px);
}

.box-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  color: white !important;
  padding: 20px !important;
  border-radius: 15px 15px 0 0 !important;
  font-weight: 600;
  font-size: 18px;
}

.box-header.with-border {
  border-bottom: 3px solid #1ABC9C !important;
}

.box-title {
  font-weight: 700;
  font-size: 20px;
  color: white !important;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.2);
}

.box-body {
  padding: 25px !important;
  background: white !important;
}

/* Info Boxes */
.info-box {
  border-radius: 15px !important;
  box-shadow: 0 6px 15px rgba(0,0,0,0.15) !important;
  border: none !important;
  min-height: 110px;
  transition: all 0.3s ease;
  background: white !important;
  overflow: hidden;
  position: relative;
}

.info-box:hover {
  transform: translateY(-8px) scale(1.02);
  box-shadow: 0 12px 25px rgba(0,0,0,0.25) !important;
}

.info-box::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 5px;
  height: 100%;
  background: linear-gradient(180deg, #1ABC9C 0%, #16A085 100%);
}

.info-box-icon {
  border-radius: 15px 0 0 15px !important;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  width: 110px !important;
  transition: all 0.3s ease;
}

.info-box:hover .info-box-icon {
  transform: scale(1.1);
}

.info-box-icon > i {
  font-size: 45px !important;
  color: white !important;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
}

.info-box-content {
  padding: 15px 20px !important;
}

.info-box-text {
  font-size: 14px;
  font-weight: 600;
  color: #2C3E50;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-box-number {
  font-size: 28px;
  font-weight: 700;
  color: #667eea;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.1);
}

/* Custom color variations for info boxes */
.info-box.bg-aqua {
  border-left: 5px solid #3498DB !important;
}

.info-box.bg-aqua .info-box-icon {
  background: linear-gradient(135deg, #3498DB 0%, #2980B9 100%) !important;
}

.info-box.bg-green {
  border-left: 5px solid #27AE60 !important;
}

.info-box.bg-green .info-box-icon {
  background: linear-gradient(135deg, #27AE60 0%, #229954 100%) !important;
}

.info-box.bg-yellow {
  border-left: 5px solid #F39C12 !important;
}

.info-box.bg-yellow .info-box-icon {
  background: linear-gradient(135deg, #F39C12 0%, #E67E22 100%) !important;
}

.info-box.bg-red {
  border-left: 5px solid #E74C3C !important;
}

.info-box.bg-red .info-box-icon {
  background: linear-gradient(135deg, #E74C3C 0%, #C0392B 100%) !important;
}

/* Buttons */
.btn {
  border-radius: 25px !important;
  padding: 10px 25px !important;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  transition: all 0.3s ease;
  border: none !important;
  box-shadow: 0 4px 10px rgba(0,0,0,0.15);
}

.btn:hover {
  transform: translateY(-3px);
  box-shadow: 0 6px 15px rgba(0,0,0,0.25);
}

.btn-primary {
  background: linear-gradient(135deg, #3498DB 0%, #2980B9 100%) !important;
  color: white !important;
}

.btn-success {
  background: linear-gradient(135deg, #27AE60 0%, #229954 100%) !important;
  color: white !important;
}

.btn-warning {
  background: linear-gradient(135deg, #F39C12 0%, #E67E22 100%) !important;
  color: white !important;
}

.btn-danger {
  background: linear-gradient(135deg, #E74C3C 0%, #C0392B 100%) !important;
  color: white !important;
}

/* Select Inputs */
.selectize-input {
  border-radius: 10px !important;
  border: 2px solid #ECF0F1 !important;
  padding: 12px !important;
  transition: all 0.3s ease;
  box-shadow: 0 2px 5px rgba(0,0,0,0.05);
}

.selectize-input:focus {
  border-color: #3498DB !important;
  box-shadow: 0 0 10px rgba(52, 152, 219, 0.3) !important;
}

/* DataTables */
.dataTables_wrapper {
  padding: 20px;
}

table.dataTable {
  border-radius: 10px;
  overflow: hidden;
}

table.dataTable thead th {
  background: linear-gradient(135deg, #2C3E50 0%, #34495E 100%) !important;
  color: white !important;
  font-weight: 600;
  padding: 15px !important;
  border: none !important;
}

table.dataTable tbody tr {
  transition: all 0.2s ease;
}

table.dataTable tbody tr:hover {
  background: #ECF0F1 !important;
  transform: scale(1.01);
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

table.dataTable tbody td {
  padding: 12px !important;
  border-bottom: 1px solid #ECF0F1 !important;
}

/* Plotly Charts */
.plotly {
  border-radius: 10px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
}

/* Value Boxes */
.small-box {
  border-radius: 15px !important;
  box-shadow: 0 6px 15px rgba(0,0,0,0.15) !important;
  transition: all 0.3s ease;
  overflow: hidden;
  position: relative;
}

.small-box:hover {
  transform: translateY(-8px);
  box-shadow: 0 12px 25px rgba(0,0,0,0.25) !important;
}

.small-box::before {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 200%;
  height: 200%;
  background: rgba(255,255,255,0.1);
  transform: rotate(45deg);
  transition: all 0.5s ease;
}

.small-box:hover::before {
  top: -100%;
  right: -100%;
}

.small-box > .inner {
  padding: 20px !important;
}

.small-box h3 {
  font-size: 38px !important;
  font-weight: 700 !important;
  margin: 0 !important;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
}

.small-box p {
  font-size: 16px !important;
  font-weight: 600 !important;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.small-box .icon {
  font-size: 90px !important;
  top: 10px !important;
  opacity: 0.3 !important;
}

/* Tab Panels */
.nav-tabs-custom {
  border-radius: 15px !important;
  box-shadow: 0 6px 15px rgba(0,0,0,0.15) !important;
  background: white !important;
}

.nav-tabs-custom > .nav-tabs > li.active {
  border-top: 3px solid #3498DB !important;
}

.nav-tabs-custom > .nav-tabs > li > a {
  border-radius: 10px 10px 0 0 !important;
  font-weight: 600;
  transition: all 0.3s ease;
}

.nav-tabs-custom > .nav-tabs > li > a:hover {
  background: #ECF0F1 !important;
  transform: translateY(-2px);
}

/* Animations */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.box, .info-box, .small-box {
  animation: fadeInUp 0.6s ease;
}

/* Scrollbar Styling */
::-webkit-scrollbar {
  width: 10px;
  height: 10px;
}

::-webkit-scrollbar-track {
  background: #ECF0F1;
  border-radius: 10px;
}

::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #3498DB 0%, #2980B9 100%);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #2980B9 0%, #3498DB 100%);
}

/* Responsive Design */
@media (max-width: 768px) {
  .info-box-icon {
    width: 80px !important;
  }
  
  .info-box-icon > i {
    font-size: 35px !important;
  }
  
  .box-header {
    padding: 15px !important;
  }
  
  .box-body {
    padding: 15px !important;
  }
}

/* Loading Animation */
.shiny-busy-container {
  background: rgba(0,0,0,0.7);
  z-index: 9999;
}

.shiny-busy-icon {
  border: 5px solid #ECF0F1;
  border-top: 5px solid #3498DB;
  border-radius: 50%;
  width: 60px;
  height: 60px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
"

# ==============================================================================
# UI Definition
# ==============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  # Dashboard Header
  dashboardHeader(
    title = tags$span(
      icon("chart-line"),
      " Poverty Analysis Tunisia"
    ),
    titleWidth = 300
  ),
  
  # Sidebar Menu
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      menuItem("Dashboard Overview", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Governorate Analysis", tabName = "gouvernorat", icon = icon("map-marked-alt")),
      menuItem("Regional Analysis", tabName = "region", icon = icon("globe-africa")),
      menuItem("Comparative Study", tabName = "comparison", icon = icon("balance-scale")),
      menuItem("Data Explorer", tabName = "data", icon = icon("table")),
      menuItem("Predictions & Insights", tabName = "predictions", icon = icon("brain"))
    )
  ),
  
  # Main Body
  dashboardBody(
    tags$head(tags$style(HTML(custom_css))),
    
    tabItems(
      # Tab 1: Dashboard Overview
      tabItem(
        tabName = "dashboard",
        h2("Poverty Rate Analysis Dashboard", style = "color: #2C3E50; font-weight: 700; margin-bottom: 30px;"),
        
        # Info Boxes Row
        fluidRow(
          infoBoxOutput("avgEnqueteBox", width = 3),
          infoBoxOutput("avgRecensementBox", width = 3),
          infoBoxOutput("totalPopBox", width = 3),
          infoBoxOutput("regionCountBox", width = 3)
        ),
        
        # Charts Row
        fluidRow(
          box(
            title = "Poverty Rates by Governorate", 
            status = "primary", 
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("gouvernoratBarChart", height = "400px")
          ),
          box(
            title = "Regional Poverty Distribution", 
            status = "success", 
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("regionPieChart", height = "400px")
          )
        ),
        
        # Additional Row
        fluidRow(
          box(
            title = "Enquête vs Recensement Comparison", 
            status = "warning", 
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("comparisonScatter", height = "400px")
          )
        )
      ),
      
      # Tab 2: Governorate Analysis
      tabItem(
        tabName = "gouvernorat",
        h2("Detailed Governorate Analysis", style = "color: #2C3E50; font-weight: 700; margin-bottom: 30px;"),
        
        fluidRow(
          box(
            title = "Filter Options",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            selectInput("regionFilter", "Select Region:", 
                       choices = c("All", unique(gouvernorat_data$Region)),
                       selected = "All")
          )
        ),
        
        fluidRow(
          box(
            title = "Poverty Rates by Governorate",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("gouvernoratDetailChart", height = "500px")
          )
        ),
        
        fluidRow(
          box(
            title = "Top 5 Highest Poverty Rates (Enquête)",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("top5Chart", height = "350px")
          ),
          box(
            title = "Top 5 Lowest Poverty Rates (Enquête)",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("bottom5Chart", height = "350px")
          )
        )
      ),
      
      # Tab 3: Regional Analysis
      tabItem(
        tabName = "region",
        h2("Regional Poverty Analysis", style = "color: #2C3E50; font-weight: 700; margin-bottom: 30px;"),
        
        fluidRow(
          box(
            title = "Regional Poverty Rates Comparison",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("regionBarChart", height = "450px")
          )
        ),
        
        fluidRow(
          box(
            title = "Population Distribution by Region",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("populationChart", height = "400px")
          ),
          box(
            title = "Governorates per Region",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("gouvernoratsPerRegion", height = "400px")
          )
        )
      ),
      
      # Tab 4: Comparative Study
      tabItem(
        tabName = "comparison",
        h2("Enquête vs Recensement Analysis", style = "color: #2C3E50; font-weight: 700; margin-bottom: 30px;"),
        
        fluidRow(
          box(
            title = "Scatter Plot: Enquête vs Recensement",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("scatterComparison", height = "500px")
          )
        ),
        
        fluidRow(
          box(
            title = "Difference Analysis (Enquête - Recensement)",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("differenceChart", height = "450px")
          )
        )
      ),
      
      # Tab 5: Data Explorer
      tabItem(
        tabName = "data",
        h2("Data Explorer", style = "color: #2C3E50; font-weight: 700; margin-bottom: 30px;"),
        
        fluidRow(
          box(
            title = "Governorate Data",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("gouvernoratTable")
          )
        ),
        
        fluidRow(
          box(
            title = "Regional Summary Data",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            DTOutput("regionTable")
          )
        )
      ),
      
      # Tab 6: Predictions & Insights
      tabItem(
        tabName = "predictions",
        h2("Statistical Insights & Trends", style = "color: #2C3E50; font-weight: 700; margin-bottom: 30px;"),
        
        fluidRow(
          valueBoxOutput("correlationBox", width = 4),
          valueBoxOutput("avgDifferenceBox", width = 4),
          valueBoxOutput("highestRateBox", width = 4)
        ),
        
        fluidRow(
          box(
            title = "Correlation Analysis",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("correlationPlot", height = "400px")
          ),
          box(
            title = "Key Insights",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            htmlOutput("insightsText")
          )
        ),
        
        fluidRow(
          box(
            title = "Poverty Rate Distribution",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("distributionPlot", height = "400px")
          )
        )
      )
    )
  )
)

# ==============================================================================
# Server Logic
# ==============================================================================

server <- function(input, output, session) {
  
  # Reactive filtered data
  filtered_data <- reactive({
    if (input$regionFilter == "All") {
      gouvernorat_data
    } else {
      filtered <- gouvernorat_data %>% filter(Region == input$regionFilter)
      # Return all data if filter results in empty dataset
      if (nrow(filtered) == 0) {
        gouvernorat_data
      } else {
        filtered
      }
    }
  })
  
  # Info Boxes
  output$avgEnqueteBox <- renderInfoBox({
    avg_val <- round(mean(gouvernorat_data$Enquete), 2)
    infoBox(
      "Avg Enquête Rate",
      paste0(avg_val, "%"),
      icon = icon("chart-line"),
      color = "aqua",
      fill = TRUE
    )
  })
  
  output$avgRecensementBox <- renderInfoBox({
    avg_val <- round(mean(gouvernorat_data$Recensement), 2)
    infoBox(
      "Avg Recensement Rate",
      paste0(avg_val, "%"),
      icon = icon("chart-bar"),
      color = "green",
      fill = TRUE
    )
  })
  
  output$totalPopBox <- renderInfoBox({
    total_pop <- sum(gouvernorat_data$Population)
    infoBox(
      "Total Population",
      format(total_pop, big.mark = ","),
      icon = icon("users"),
      color = "yellow",
      fill = TRUE
    )
  })
  
  output$regionCountBox <- renderInfoBox({
    n_regions <- length(unique(gouvernorat_data$Region))
    infoBox(
      "Regions",
      n_regions,
      icon = icon("map"),
      color = "red",
      fill = TRUE
    )
  })
  
  # Value Boxes
  output$correlationBox <- renderValueBox({
    corr_val <- round(cor(gouvernorat_data$Enquete, gouvernorat_data$Recensement), 3)
    valueBox(
      corr_val,
      "Correlation (Enq-Rec)",
      icon = icon("link"),
      color = "aqua"
    )
  })
  
  output$avgDifferenceBox <- renderValueBox({
    avg_diff <- round(mean(gouvernorat_data$Enquete - gouvernorat_data$Recensement), 2)
    valueBox(
      paste0(avg_diff, "%"),
      "Avg Difference",
      icon = icon("exchange-alt"),
      color = "yellow"
    )
  })
  
  output$highestRateBox <- renderValueBox({
    max_rate <- max(gouvernorat_data$Enquete)
    max_gov <- gouvernorat_data$Gouvernorat[which.max(gouvernorat_data$Enquete)]
    valueBox(
      paste0(max_rate, "%"),
      paste("Highest Rate:", max_gov),
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  # Governorate Bar Chart
  output$gouvernoratBarChart <- renderPlotly({
    top_10 <- gouvernorat_data %>%
      arrange(desc(Enquete)) %>%
      head(10)
    
    plot_ly(top_10, x = ~reorder(Gouvernorat, Enquete), y = ~Enquete,
            type = 'bar', name = 'Enquête',
            marker = list(color = '#3498DB',
                         line = list(color = '#2980B9', width = 2))) %>%
      add_trace(y = ~Recensement, name = 'Recensement',
               marker = list(color = '#1ABC9C',
                           line = list(color = '#16A085', width = 2))) %>%
      layout(title = "Top 10 Governorates by Poverty Rate",
             xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Poverty Rate (%)"),
             barmode = 'group',
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Regional Pie Chart
  output$regionPieChart <- renderPlotly({
    plot_ly(region_data, labels = ~Region, values = ~Enquete,
            type = 'pie',
            marker = list(colors = c('#3498DB', '#1ABC9C', '#F39C12', '#E74C3C', 
                                    '#9B59B6', '#34495E', '#16A085'),
                         line = list(color = '#ffffff', width = 2))) %>%
      layout(title = "Poverty Distribution by Region",
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Comparison Scatter
  output$comparisonScatter <- renderPlotly({
    plot_ly(gouvernorat_data, x = ~Recensement, y = ~Enquete,
            type = 'scatter', mode = 'markers',
            text = ~Gouvernorat,
            marker = list(size = 12,
                         color = ~Population,
                         colorscale = list(c(0, '#3498DB'), c(1, '#E74C3C')),
                         showscale = TRUE,
                         colorbar = list(title = "Population"),
                         line = list(color = '#2C3E50', width = 1))) %>%
      add_trace(x = c(0, 40), y = c(0, 40), mode = 'lines',
               line = list(color = '#16A085', width = 2, dash = 'dash'),
               name = 'Perfect Agreement', showlegend = TRUE) %>%
      layout(title = "Enquête vs Recensement Poverty Rates",
             xaxis = list(title = "Recensement (%)"),
             yaxis = list(title = "Enquête (%)"),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Governorate Detail Chart
  output$gouvernoratDetailChart <- renderPlotly({
    data <- filtered_data()
    
    plot_ly(data, x = ~reorder(Gouvernorat, Enquete), y = ~Enquete,
            type = 'bar', name = 'Enquête',
            marker = list(color = '#667eea',
                         line = list(color = '#764ba2', width = 1.5))) %>%
      add_trace(y = ~Recensement, name = 'Recensement',
               marker = list(color = '#1ABC9C',
                           line = list(color = '#16A085', width = 1.5))) %>%
      layout(title = paste("Poverty Rates -", input$regionFilter),
             xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Poverty Rate (%)"),
             barmode = 'group',
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Top 5 Chart
  output$top5Chart <- renderPlotly({
    top_5 <- gouvernorat_data %>%
      arrange(desc(Enquete)) %>%
      head(5)
    
    plot_ly(top_5, x = ~Enquete, y = ~reorder(Gouvernorat, Enquete),
            type = 'bar', orientation = 'h',
            marker = list(color = '#E74C3C',
                         line = list(color = '#C0392B', width = 2))) %>%
      layout(title = "Highest Poverty Rates",
             xaxis = list(title = "Poverty Rate (%)"),
             yaxis = list(title = ""),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Bottom 5 Chart
  output$bottom5Chart <- renderPlotly({
    bottom_5 <- gouvernorat_data %>%
      arrange(Enquete) %>%
      head(5)
    
    plot_ly(bottom_5, x = ~Enquete, y = ~reorder(Gouvernorat, Enquete),
            type = 'bar', orientation = 'h',
            marker = list(color = '#27AE60',
                         line = list(color = '#229954', width = 2))) %>%
      layout(title = "Lowest Poverty Rates",
             xaxis = list(title = "Poverty Rate (%)"),
             yaxis = list(title = ""),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Regional Bar Chart
  output$regionBarChart <- renderPlotly({
    plot_ly(region_data, x = ~reorder(Region, -Enquete), y = ~Enquete,
            type = 'bar', name = 'Enquête',
            marker = list(color = '#667eea',
                         line = list(color = '#764ba2', width = 2))) %>%
      add_trace(y = ~Recensement, name = 'Recensement',
               marker = list(color = '#1ABC9C',
                           line = list(color = '#16A085', width = 2))) %>%
      layout(title = "Regional Poverty Rates",
             xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Poverty Rate (%)"),
             barmode = 'group',
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Population Chart
  output$populationChart <- renderPlotly({
    plot_ly(region_data, x = ~reorder(Region, -Population), y = ~Population,
            type = 'bar',
            marker = list(color = '#F39C12',
                         line = list(color = '#E67E22', width = 2))) %>%
      layout(title = "Population by Region",
             xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Population"),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Governorats per Region
  output$gouvernoratsPerRegion <- renderPlotly({
    plot_ly(region_data, labels = ~Region, values = ~Gouvernorats,
            type = 'pie',
            marker = list(colors = c('#3498DB', '#1ABC9C', '#F39C12', '#E74C3C',
                                    '#9B59B6', '#34495E', '#16A085'),
                         line = list(color = '#ffffff', width = 2))) %>%
      layout(title = "Number of Governorates per Region",
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Scatter Comparison
  output$scatterComparison <- renderPlotly({
    plot_ly(gouvernorat_data, x = ~Recensement, y = ~Enquete,
            type = 'scatter', mode = 'markers+text',
            text = ~Gouvernorat,
            textposition = 'top center',
            marker = list(size = 14,
                         color = '#667eea',
                         line = list(color = '#764ba2', width = 2))) %>%
      add_trace(x = c(0, 40), y = c(0, 40), mode = 'lines',
               line = list(color = '#E74C3C', width = 2, dash = 'dash'),
               name = 'Y = X Line', showlegend = TRUE) %>%
      layout(title = "Enquête vs Recensement (All Governorates)",
             xaxis = list(title = "Recensement (%)"),
             yaxis = list(title = "Enquête (%)"),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Difference Chart
  output$differenceChart <- renderPlotly({
    diff_data <- gouvernorat_data %>%
      mutate(Difference = Enquete - Recensement) %>%
      arrange(Difference)
    
    plot_ly(diff_data, x = ~Difference, y = ~reorder(Gouvernorat, Difference),
            type = 'bar', orientation = 'h',
            marker = list(color = ~Difference,
                         colorscale = list(c(0, '#27AE60'), c(0.5, '#F39C12'), c(1, '#E74C3C')),
                         line = list(color = '#2C3E50', width = 1))) %>%
      layout(title = "Difference in Poverty Rates (Enquête - Recensement)",
             xaxis = list(title = "Difference (%)"),
             yaxis = list(title = ""),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Data Tables
  output$gouvernoratTable <- renderDT({
    datatable(gouvernorat_data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = 'cell-border stripe',
              rownames = FALSE)
  })
  
  output$regionTable <- renderDT({
    datatable(region_data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = 'cell-border stripe',
              rownames = FALSE)
  })
  
  # Correlation Plot
  output$correlationPlot <- renderPlotly({
    plot_ly(gouvernorat_data, x = ~Recensement, y = ~Enquete,
            type = 'scatter', mode = 'markers',
            marker = list(size = 10,
                         color = '#3498DB',
                         line = list(color = '#2980B9', width = 1))) %>%
      add_trace(x = gouvernorat_data$Recensement,
               y = fitted(lm(Enquete ~ Recensement, data = gouvernorat_data)),
               mode = 'lines',
               line = list(color = '#E74C3C', width = 3),
               name = 'Trend Line') %>%
      layout(title = paste("Correlation:", round(cor(gouvernorat_data$Enquete, gouvernorat_data$Recensement), 3)),
             xaxis = list(title = "Recensement (%)"),
             yaxis = list(title = "Enquête (%)"),
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
  
  # Insights Text
  output$insightsText <- renderUI({
    corr <- round(cor(gouvernorat_data$Enquete, gouvernorat_data$Recensement), 3)
    avg_diff <- round(mean(gouvernorat_data$Enquete - gouvernorat_data$Recensement), 2)
    max_gov <- gouvernorat_data$Gouvernorat[which.max(gouvernorat_data$Enquete)]
    min_gov <- gouvernorat_data$Gouvernorat[which.min(gouvernorat_data$Enquete)]
    
    HTML(paste0(
      "<div style='padding: 20px; line-height: 2;'>",
      "<h4 style='color: #2C3E50; font-weight: 700;'><i class='fa fa-lightbulb' style='color: #F39C12;'></i> Key Findings:</h4>",
      "<ul style='font-size: 15px; color: #34495E;'>",
      "<li><strong>Strong Correlation:</strong> The correlation between Enquête and Recensement is <span style='color: #3498DB; font-weight: 700;'>", corr, "</span>, indicating high consistency.</li>",
      "<li><strong>Average Difference:</strong> On average, Enquête rates are <span style='color: #E67E22; font-weight: 700;'>", avg_diff, "%</span> higher than Recensement rates.</li>",
      "<li><strong>Highest Poverty:</strong> <span style='color: #E74C3C; font-weight: 700;'>", max_gov, "</span> has the highest poverty rate.</li>",
      "<li><strong>Lowest Poverty:</strong> <span style='color: #27AE60; font-weight: 700;'>", min_gov, "</span> has the lowest poverty rate.</li>",
      "<li><strong>Regional Disparity:</strong> Significant variation exists between regions, with Centre-Ouest showing the highest rates.</li>",
      "</ul>",
      "</div>"
    ))
  })
  
  # Distribution Plot
  output$distributionPlot <- renderPlotly({
    plot_ly(alpha = 0.6) %>%
      add_histogram(x = gouvernorat_data$Enquete, name = "Enquête",
                   marker = list(color = '#667eea',
                               line = list(color = '#764ba2', width = 1))) %>%
      add_histogram(x = gouvernorat_data$Recensement, name = "Recensement",
                   marker = list(color = '#1ABC9C',
                               line = list(color = '#16A085', width = 1))) %>%
      layout(title = "Distribution of Poverty Rates",
             xaxis = list(title = "Poverty Rate (%)"),
             yaxis = list(title = "Frequency"),
             barmode = "overlay",
             plot_bgcolor = '#F8F9FA',
             paper_bgcolor = '#F8F9FA',
             font = list(family = "Segoe UI, sans-serif"))
  })
}

# ==============================================================================
# Run Application
# ==============================================================================

shinyApp(ui = ui, server = server)
