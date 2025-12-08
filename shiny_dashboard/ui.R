# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)


# ------------------------ CUSTOM CSS ------------------------------------------
# Styling to keep the logo fixed on the right side of the top header
customCSS <- "
.navbar-custom-menu > .dropdown {
  float: right !important;        /* Forces the image to stay on the right */
}

.navbar-custom-menu img {
  height: 40px !important;        /* Scales logo height */
  margin-top: 8px !important;     /* Vertical alignment */
  margin-right: 15px !important;  /* Distance from right screen border */
}
"


# ---- UI ----------------------------------------------------------------------
# Create the overall dashboard page structure
ui <- dashboardPage(
  
  
# ---- HEADER ------------------------------------------------------------------
dashboardHeader(
  title = "HS Aalen Dashboard",    # Title aligned left by default
  
  # Add custom image to the right side inside the navbar menu area
  tags$li(
    class = "dropdown",
    tags$img(src = "HS_Aalen_Icon.png")   # Logo must be in /www folder
  )
),


# ---- SIDEBAR -----------------------------------------------------------------
 # Left sidebar navigation area
  dashboardSidebar(
    
    # Creates a collapsible menu inside the sidebar
    sidebarMenu(
      
      # Navigation tab 1
      menuItem("Student-Information", tabName = "studentinfo", icon = icon("dashboard")),
      
      # Navigation tab 2
      menuItem("Module-Information", tabName = "moduleinfo", icon = icon("th"))
    )
  ),

  
# ---- BODY --------------------------------------------------------------------
  # Main content area of the dashboard
  dashboardBody(
    
    # HS Aalen Icon
    tags$head(tags$style(HTML(customCSS))),
    
    # Wraps multiple tab pages (one for each menuItem)
    tabItems(
      
      # --- First tab: Student-Info ---
      # Links this content to the menu item "studentinfo"
      tabItem(tabName = "studentinfo",
              
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
      
      # --- Second tab: Module-Info ---
      # Links this content to the menu item "moduleinfo"
      tabItem(tabName = "moduleinfo",
              
              # Simple header text for the tab
              h2("Widgets tab content")
      )
    )
  )
)
