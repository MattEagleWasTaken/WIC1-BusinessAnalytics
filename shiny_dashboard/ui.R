# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)


# ------------------------ CUSTOM CSS ------------------------------------------
customCSS <- "
/* Logo in top header right */
.top-header-logo {
  height: 40px;
  position: absolute;   /* absolute positioning in navbar */
  right: 10px;          /* distance from right edge */
  top: 8px;             /* vertical alignment */
}

/* Tab header text, centered */
.tab-header {
  text-align: center;    /* center horizontally */
  font-weight: bold;
  font-size: 18px;
  margin-bottom: 10px;   /* spacing below header */
}
"


# ---- UI ----------------------------------------------------------------------
ui <- dashboardPage(
  
  # ---------------- TOP HEADER -----------------------------------------------
  dashboardHeader(
    title = "HS-Dashboard",    # Fixed title, left-aligned by default
    
    # Logo placed in navbar, outside the title container
    tags$li(class = "dropdown",
            tags$img(src = "HS_Aalen_Icon.png", class = "top-header-logo")
    )
  ),
  
  # ---------------- SIDEBAR ---------------------------------------------------
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",    # track selected tab
      menuItem("Student-Information", tabName = "studentinfo", icon = icon("dashboard")),
      menuItem("Module-Information", tabName = "moduleinfo", icon = icon("th"))
    )
  ),
  
  # ---------------- BODY ------------------------------------------------------
  dashboardBody(
    
    # Include custom CSS
    tags$head(tags$style(HTML(customCSS))),
    
    # Tab-specific dynamic header
    uiOutput("tabHeader"),
    
    # Tab contents
    tabItems(
      # --- Tab 1: Student Information ---
      tabItem(tabName = "studentinfo",
              fluidRow(
                # Box containing a plot output
                box(plotOutput("plot1", height = 250)),
                
                # Box containing user controls
                box(
                  title = "Controls",
                  sliderInput("slider", "Number of observations:", 1, 100, 50)
                )
              )
      ),
      
      # --- Tab 2: Module Information ---
      tabItem(tabName = "moduleinfo",
              h2("Module Information content")
      )
    )
  )
)
