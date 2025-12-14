# Modern Shiny Dashboard for Poverty Analysis in Tunisia

## Overview
This is a professionally designed Shiny dashboard application for analyzing poverty rates (Enquête vs Recensement) data from Tunisian governorates and regions.

## Features

### 🎨 Modern Design Elements
- **Gradient-based color scheme** with professional blues, teals, purples, and accent colors
- **Smooth transitions and hover effects** on all interactive elements
- **Box shadows and rounded corners** for modern card designs
- **Animated elements** with fade-in effects
- **Professional typography** using Segoe UI font family
- **Responsive design** that works on different screen sizes

### 📊 Dashboard Components

#### 1. Dashboard Overview
- **Info Boxes**: Display key metrics (Average Enquête Rate, Average Recensement Rate, Total Population, Number of Regions)
- **Governorate Bar Chart**: Top 10 governorates by poverty rate
- **Regional Pie Chart**: Poverty distribution across regions
- **Comparison Scatter Plot**: Enquête vs Recensement with population-based coloring

#### 2. Governorate Analysis
- **Filtering options** by region
- **Detailed bar charts** comparing Enquête and Recensement rates
- **Top 5 highest** poverty rates visualization
- **Top 5 lowest** poverty rates visualization

#### 3. Regional Analysis
- **Regional comparison charts** with grouped bars
- **Population distribution** by region
- **Governorates per region** pie chart

#### 4. Comparative Study
- **Scatter plot analysis** with perfect agreement line
- **Difference analysis** showing Enquête - Recensement variations

#### 5. Data Explorer
- **Interactive data tables** using DT package
- **Sortable and searchable** governorate and region data

#### 6. Predictions & Insights
- **Value boxes** showing correlation, average difference, and highest rate
- **Correlation plot** with trend line
- **Key insights panel** with automated findings
- **Distribution plots** comparing poverty rate distributions

## Color Palette

The application uses a professional color scheme:

- **Primary Dark**: `#2C3E50` - Used for headers and main elements
- **Primary Light**: `#3498DB` - Used for charts and accents
- **Secondary Teal**: `#16A085` - Used for success indicators
- **Secondary Cyan**: `#1ABC9C` - Used for positive elements
- **Accent Coral**: `#E67E22` - Used for warnings and attention
- **Accent Red**: `#E74C3C` - Used for critical information
- **Success Green**: `#27AE60` - Used for positive trends
- **Warning Amber**: `#F39C12` - Used for moderate warnings
- **Background Light**: `#ECF0F1` - Light background color
- **Background Lighter**: `#F8F9FA` - Lighter background variant

## Installation & Usage

### Prerequisites
```r
# Required R packages
install.packages(c(
  'shiny',
  'shinydashboard',
  'ggplot2',
  'plotly',
  'dplyr',
  'DT'
))
```

### Data Files
The application requires two CSV files:
- `par_gouvernorat.csv` - Governorate-level data
- `par_region.csv` - Regional summary data

### Running the Application
```r
# In R or RStudio
shiny::runApp("app.R")
```

Or from command line:
```bash
Rscript -e "shiny::runApp('app.R')"
```

The application will open in your default web browser.

## Data Structure

### par_gouvernorat.csv
Columns:
- `Gouvernorat`: Name of the governorate
- `Enquete`: Poverty rate from survey (%)
- `Recensement`: Poverty rate from census (%)
- `Population`: Population count
- `Region`: Parent region name

### par_region.csv
Columns:
- `Region`: Name of the region
- `Enquete`: Average poverty rate from survey (%)
- `Recensement`: Average poverty rate from census (%)
- `Population`: Total population
- `Gouvernorats`: Number of governorates in the region

## Design Highlights

### CSS Enhancements
- **Custom scrollbars** with gradient styling
- **Animated info boxes** with hover transformations
- **Gradient headers** for all dashboard components
- **Professional button styling** with 3D effects
- **Enhanced table styling** with hover effects
- **Loading animations** for async operations

### Interactive Elements
- **Plotly integration** for interactive charts
- **DataTables** for sortable, searchable data views
- **Dynamic filtering** for governorate analysis
- **Tooltip displays** on hover
- **Responsive sidebar** menu with icons

## Technical Details

### Dependencies
- **shiny**: Core framework for reactive web applications
- **shinydashboard**: Dashboard layout and components
- **ggplot2**: Grammar of graphics for plotting
- **plotly**: Interactive, web-based graphs
- **dplyr**: Data manipulation and transformation
- **DT**: Interactive data tables

### Browser Compatibility
The application works best on:
- Chrome/Chromium (recommended)
- Firefox
- Safari
- Edge

### Performance
- Optimized for datasets with 20-30 governorates
- Reactive filtering for improved performance
- Lazy loading of chart data

## Customization

### Modifying Colors
Edit the `:root` CSS variables in the `custom_css` section:
```css
:root {
  --primary-dark: #2C3E50;
  --primary-light: #3498DB;
  /* ... other color variables ... */
}
```

### Adding New Visualizations
Add new tabs in the `dashboardSidebar` and corresponding `tabItem` elements in the `dashboardBody`.

### Adjusting Layout
Modify the `fluidRow` and `box` widths (1-12 columns) to adjust the layout grid.

## License
This application is provided as-is for educational and analytical purposes.

## Support
For questions or issues, please refer to the main repository documentation.
