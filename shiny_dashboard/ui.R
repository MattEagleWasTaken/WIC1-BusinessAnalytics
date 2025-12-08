# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)

# Load shinyjs for dynamic show/hide of UI elements
library(shinyjs)

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
  text-align: center;    /* horizontal centering */
  font-weight: bold;
  font-size: 18px;
  margin-bottom: 10px;   /* spacing below header */
}

/* Flex container for student filters row */
.student-filters-row {
  display: flex;
  align-items: center;  /* vertical centering for all elements */
  gap: 20px;
}

/* Make selected text in selectInput vertically centered */
.selectize-input {
  display: flex !important;          
  align-items: center !important;    
  border-radius: 45px !important;   /* rounded corners */
  height: 40px;                      /* fixed height for uniformity */
  padding-left: 10px;                /* left padding for text */
}

/* Rounded corners for dropdown list */
.selectize-dropdown {
  border-radius: 10px !important;
}

/* Reset button styling */
.reset-btn {
  background-color: #4da3ff;  /* light blue */
  color: white;               /* text color */
  border-radius: 45px;        /* rounded corners */
  height: 40px;               /* same height as dropdowns */
  padding: 0 15px;            /* horizontal padding */
  display: flex;
  align-items: center;
  justify-content: center;
}

.static-text-container {
  display: flex;
  flex-direction: column;
  justify-content: center;  /* vertical centering */
}

.static-text-label {
  font-weight: bold;
  margin: 0;          /* remove default margin */
  padding: 0;
  line-height: 1;
  margin-bottom: 2px;  /* adjust spacing between label and text */
  position: relative;
  top: -12px;
}

.static-text-input {
  border: 1px solid #ccc;
  border-radius: 45px;
  height: 40px;
  padding: 0 10px;
  display: flex;
  align-items: center;      /* vertical center text */
  background-color: white;
  min-width: 300px;
  margin-top: -6px;         /* shift text up to align with dropdowns */
}

/* h4 is the label of the card */
.gpa-card h4 {
  margin: 0;
  font-weight: normal;
}

/* h2 is the content showing the student's average grade */
.gpa-card h2 {
  margin: 0;
  font-size: 28px;
  font-weight: bold;
}


"

# ---- UI ----------------------------------------------------------------------
ui <- dashboardPage(
  
  # ---------------- TOP HEADER -----------------------------------------------
  dashboardHeader(
    title = "HS-Dashboard",
    
    # Logo placed in top right of header
    tags$li(class = "dropdown",
            tags$img(src = "HS_Aalen_Icon.png", class = "top-header-logo")
    )
  ),
  
  # ---------------- SIDEBAR ---------------------------------------------------
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",  # track which tab is selected
      menuItem("Student-Information", tabName = "studentinfo", icon = icon("dashboard")),
      menuItem("Module-Information", tabName = "moduleinfo", icon = icon("th"))
    )
  ),
  
  # ---------------- BODY ------------------------------------------------------
  dashboardBody(
    
    # Include custom CSS
    tags$head(tags$style(HTML(customCSS))),
    
    # Enable shinyjs for dynamic show/hide
    useShinyjs(),
    
    # Dynamic tab header
    uiOutput("tabHeader"),
    
    # Tab contents
    tabItems(
      
      # --- Tab 1: Student Information ------------------------------------------
      tabItem(tabName = "studentinfo",
              fluidRow(
                class = "student-filters-row",
                
                # Flex container for toggle + dropdowns + reset button
                div(
                  style = "display: flex; align-items: center; gap: 20px;",
                  
                  # Toggle: All Students / One Student
                  div(
                    radioButtons(
                      "student_toggle",
                      "Select Student:",
                      choices = c("All Students", "One Student"),
                      inline = TRUE
                    )
                  ),
                  
                  # Dropdowns (rendered dynamically when toggle is 'One Student')
                  uiOutput("one_student_filters"),
                  
                  # Reset Button (always in DOM, visibility controlled by shinyjs)
                  actionButton(
                    "reset_filters",
                    "Reset Selection",
                    class = "reset-btn"
                  )
                )
              ),
              
              #-----------------------------------------------------------------------------------
              # GPA Card UI (placed below the student filters)
              fluidRow(
                column(
                  width = 3,   # adjust width as needed
                  div(
                    id = "gpa_card",  # ID for dynamic updating
                    class = "gpa-card",
                    style = "
                    background-color: #f0f4ff;   /* light blue background */
                    border-radius: 15px;
                    height: 100px;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    margin-bottom: 20px;
                    ",
                    h4("Overall GPA"),
                    h2(textOutput("student_gpa", inline = TRUE))  # dynamic GPA value
                  )
                )
              )
      ),
      
      # --- Tab 2: Module Information -------------------------------------------
      tabItem(tabName = "moduleinfo",
              h2("Module Information content")
      )
    ) # end TabItems
  ) # end Body
) # end UI
