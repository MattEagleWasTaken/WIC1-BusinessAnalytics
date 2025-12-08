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

/* Inline layout for student filters */
.student-filters-row .form-group {
  display: inline-block;
  vertical-align: top;
  margin-left: 15px;
  margin-right: 20px;
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
    ) # end tags$li
  ) # end dashboardHeader
  ,
  
  # ---------------- SIDEBAR ---------------------------------------------------
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",    # track selected tab
      menuItem("Student-Information", tabName = "studentinfo", icon = icon("dashboard")),
      menuItem("Module-Information", tabName = "moduleinfo", icon = icon("th"))
    ) # end sidebarMenu
  ) # end dashboardSidebar
  ,
  
  # ---------------- BODY ------------------------------------------------------
  dashboardBody(
    
    # Include custom CSS
    tags$head(tags$style(HTML(customCSS))), # end tags$head
    
    # Tab-specific dynamic header
    uiOutput("tabHeader"),
    
    # Tab contents
    tabItems(
      # --- Tab 1: Student Information -------------------------------------------------------
      tabItem(tabName = "studentinfo",
              # Row for dynamic student filters
              fluidRow(
                class = "student-filters-row",  # <- neue Klasse
                # Use flex container to align toggle and dropdowns in one row
                div(style = "display: flex; align-items: center; gap: 20px;",
                    # Toggle: All Students / One Student
                    div(
                      radioButtons("student_toggle", "Select Student:",
                                   choices = c("All Students", "One Student"),
                                   inline = TRUE)
                    ), # end div toggle
                    
                    # Dropdowns, only show if One Student selected
                    uiOutput("one_student_filters")
                ) # end flex div
              ) # end fluidRow
      ) # end tabItem studentinfo
      ,
      
      # --- Tab 2: Module Information -------------------------------------------------------------------
      tabItem(tabName = "moduleinfo",
              h2("Module Information content")
      ) # end tabItem moduleinfo
    ) # end tabItems
  ) # end dashboardBody
) # end dashboardPage
