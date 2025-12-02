# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)

# Create the overall dashboard page structure
ui <- dashboardPage(
  
  # Top header bar with a title
  dashboardHeader(title = "Basic dashboard"),
  
  # Left sidebar navigation area
  dashboardSidebar(
    
    # Creates a collapsible menu inside the sidebar
    sidebarMenu(
      
      # Navigation tab 1
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      
      # Navigation tab 2
      menuItem("Widgets", tabName = "widgets", icon = icon("th"))
    )
  ),
  
  # Main content area of the dashboard
  dashboardBody(
    
    # Wraps multiple tab pages (one for each menuItem)
    tabItems(
      
      # --- First tab: Dashboard ---
      # Links this content to the menu item "Dashboard"
      tabItem(tabName = "dashboard",
              
              # Creates a responsive horizontal layout row
              fluidRow(
                
                # Box containing a plot output
                box(plotOutput("plot1", height = 250)),
                
                # Box containing user controls
                box(
                  
                  # Title for the box
                  title = "Controls",
                  
                  # Slider that lets users choose a number
                  sliderInput("slider",
                              "Number of observations:",
                              1, 100, 50)  # Range: 1–100, default value: 50
                )
              )
      ),
      
      # --- Second tab: Widgets ---
      # Links this content to the menu item "Widgets"
      tabItem(tabName = "widgets",
              
              # Simple header text for the tab
              h2("Widgets tab content")
      )
    )
  )
)
