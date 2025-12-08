# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)

# Load shinyjs for dynamic show/hide of UI elements
library(shinyjs)

# ------------------------ CUSTOM CSS ------------------------------------------
customCSS <- "

/* ------------------------ GENERAL LAYOUT ------------------------------------*/ 
/* Logo position in the top header */ 
.top-header-logo { 
height: 40px; 
position: absolute; 
right: 10px; 
top: 8px; 
} 

/* Tab header text */ 
.tab-header { 
text-align: center; 
font-weight: bold; 
font-size: 18px; 
margin-bottom: 10px; 
}


/* 1. Filter row → all filter blocks are placed side by side */
.student-filters-row {
  display: flex;
  align-items: flex-start;     /* align all elements to the top of the container */
  gap: 25px;                    /* horizontal spacing between filter blocks */
  padding-top: 10px;            /* small padding from top of row */
}

/* 2. Each filter block stacks its contents vertically */
.filter-block {
  display: flex;
  flex-direction: column;       /* stack label above input */
  width: 220px;                 /* fixed width for all filter elements */
}

/* 3. Unified label style for all filters */
.filter-label,
.control-label,
.static-text-label {
  font-weight: bold;            /* bold text for all labels */
  height: 22px;                 /* fixed height to align all labels */
  line-height: 22px;            /* ensures vertical centering of label text */
  margin: 0 0 6px 0;            /* small spacing below label before input */
  padding: 0;                   /* remove any default padding */
}

/* 4. Dropdown Input (Selectize) */
.selectize-input {
  height: 40px !important;      /* fixed height for uniformity */
  border-radius: 45px !important;  /* rounded corners */
  padding-left: 10px !important;   /* spacing between text and left border */
  display: flex !important;         
  align-items: center !important;   /* vertically center text inside input */
}

/* 5. Dropdown list (the menu that opens) */
.selectize-dropdown {
  border-radius: 10px !important;  /* rounded corners for dropdown menu */
}

/* 6. Static text field (read-only, same height as dropdown) */
.static-text-input {
  height: 40px;                 /* same height as dropdown */
  width: 300px;
  border-radius: 45px;          /* rounded corners */
  border: 1px solid #ccc;       /* border style */
  padding: 0 10px;              /* left/right padding inside the field */
  display: flex;                
  align-items: center;          /* vertical center text */
  background: white;            /* white background */
}

/* 7. Radio Buttons → align properly with inputs */
.shiny-options-group {
  margin-top: 6px;              /* same vertical offset as dropdowns for alignment */
}

/* 8. Reset Button */
.reset-btn {
  background-color: #4da3ff;    /* light blue button background */
  color: white;                 /* text color */
  border-radius: 45px;          /* rounded corners to match inputs */
  height: 40px;                 /* same height as dropdowns */
  display: flex;
  align-items: center;          /* vertical center text inside button */
  justify-content: center;      /* horizontal center */
  border: none;                 /* remove default border */
  padding: 0 20px;              /* horizontal padding inside button */
  margin-top: 6px;              /* align vertically with inputs */
}


/* ------------------------ GPA CARD ------------------------------------------ */

.gpa-card h4 {       /* small title */
  margin: 0;
  font-weight: normal;
}

.gpa-card h2 {       /* numeric GPA value */
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
