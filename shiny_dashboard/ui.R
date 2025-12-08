# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)

# ------------------------ CUSTOM CSS ------------------------------------------
customCSS <- "
/* Logo in top header right */
.top-header-logo {
  height: 40px;
  position: absolute;  
  right: 10px;          
  top: 8px;             
}

/* Tab header text, centered */
.tab-header {
  text-align: center;
  font-weight: bold;
  font-size: 18px;
  margin-bottom: 10px;
}

/* Flex container for filters */
.student-filters-row {
  display: flex;
  align-items: center;  /* vertical center for all elements */
  gap: 20px;
}

/* Make selected text in dropdown vertically centered */
.selectize-input {
  display: flex !important;          /* use flexbox for content */
  align-items: center !important;    /* vertically center text */
  border-radius: 45px !important;   /* keep rounded corners */
  height: 40px;                      /* optional: fix height */
  padding-left: 10px;                /* optional: padding */
}

/* Rounded corners for dropdown list */
.selectize-dropdown {
  border-radius: 10px !important;
}

/* Reset button styling */
.reset-btn {
  background-color: #4da3ff;
  color: white;
  border-radius: 10px;
  height: 40px;          /* gleiche Höhe wie Dropdowns */
  padding: 0 15px;       /* horizontal padding */
  display: flex;
  align-items: center;
  justify-content: center;
}
"

# ---- UI ----------------------------------------------------------------------
ui <- dashboardPage(
  
  # ---------------- TOP HEADER -----------------------------------------------
  dashboardHeader(
    title = "HS-Dashboard",
    
    tags$li(class = "dropdown",
            tags$img(src = "HS_Aalen_Icon.png", class = "top-header-logo")
    )
  ),
  
  # ---------------- SIDEBAR ---------------------------------------------------
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
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
      # --- Tab 1: Student Information -------------------------------------------------------
      tabItem(tabName = "studentinfo",
              # Row for dynamic student filters
              fluidRow(
                class = "student-filters-row",
                
                # Toggle + dropdowns + reset button
                div(
                  style = "display: flex; align-items: center; gap: 20px;",
                  
                  # Toggle: All / One Student
                  div(
                    radioButtons("student_toggle", "Select Student:",
                                 choices = c("All Students", "One Student"),
                                 inline = TRUE)
                  ),
                  
                  # Dropdowns & Reset button
                  uiOutput("one_student_filters")
                )
              )
      ),
      
      # --- Tab 2: Module Information -------------------------------------------------------
      tabItem(tabName = "moduleinfo",
              h2("Module Information content")
      )
    )
  )
)
