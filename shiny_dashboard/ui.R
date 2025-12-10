# Load the Shiny package (base framework for interactive web apps)
library(shiny)

# Load Shiny Dashboard package (provides dashboard layout and components)
library(shinydashboard)

# Load shinyjs for dynamic show/hide of UI elements
library(shinyjs)

# ggplot2 → used for creating the grade visualization plot
library(ggplot2)


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

/* Remove default padding/margin from Shiny dashboard body */
.content {
  padding-top: 0 !important;
}

.row {
  margin-top: 0 !important;
}

/* 1. Filter row → all filter blocks are placed side by side */
.filter-row {
  background-color: white;
  box-shadow: 0px 2px 6px rgba(0,0,0,0.15);
  display: flex;
  align-items: center;     /* CENTER instead of FLEX-START */
  gap: 25px;
  height: 120px;
  margin-top: 0 !important;
  padding-top: 0 !important
  
}

/* 4. Dropdown Input Menue (Selectize) */
.selectize-input {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.15);
  height: 40px !important;      /* fixed height for uniformity */
  border-radius: 45px !important;  /* rounded corners */
  padding-left: 10px !important;   /* spacing between text and left border */
  display: flex !important;         
  align-items: center !important;   /* vertically center text inside input */
}

/* 5. Dropdown list (the menu that opens) */
.selectize-dropdown {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.15);
  border-radius: 10px !important;  /* rounded corners for dropdown menu */
}

/* 6. Static text field Menue (read-only, same height as dropdown) */
.static-text-input {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.15);
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
  margin-top: 5px;              /* same vertical offset as dropdowns for alignment */
}

/* 8. Reset Button */
.reset-btn {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.15);
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


"

# ---- UI ----------------------------------------------------------------------
ui <- dashboardPage(
  
  # ---------------- TOP HEADER -----------------------------------------------
  dashboardHeader(
    title = "HS-Dashboard",
    
    # Logo placed in top right of header
    tags$li(class = "dropdown",tags$img(src = "HS_Aalen_Icon.png", class = "top-header-logo")
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
                class = "filter-row",
                
                # Flex container for toggle + dropdowns + reset button
                div(
                  style = "display: flex; align-items: center; gap: 20px;height:100px",
                  
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
              # GPA Card UI and Grade Plot (placed below the student filters)
              fluidRow(
                div(
                  style = "
                  display: flex;
                  align-items: flex-start;   /* top alignment */
                  gap: 20px;                 
                  width: 100%;
                  height: calc(100vh - 200px);  /* full viewport minus Header/Filter height */
                  margin-top: 10px;          /* spacing below filter row */
                  ",
                  
                  # container within plot student grades
                  div(
                    style = "
                    flex: 1;
                    background-color: white;         /* white background */
                    border-radius: 15px;             /* rounded corners */
                    box-shadow: 0px 4px 15px rgba(0,0,0,0.2);  /* soft shadow */
                    padding: 20px;                   /* inner spacing */
                    height: calc(100vh - 200px);
                    margin-left: 15px;               /* left margin */
                    
                    ",
                    
                    # Plot inside this container
                    plotOutput("grades_plot", height = "100%", width = "100%")
                    ),
                  
                  # GPA Card (right side)
                  div(
                    id = 'gpa_card',
                    style = "
                    background-color: white;
                    border-radius: 15px;
                    width: 180px;
                    height: 160px;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    box-shadow: 0px 0px 10px rgba(0,0,0,0.15);
                    margin-right: 15px;        /* spacing from right edge */
                    ",
                    
                    uiOutput("gpa_title"),
                    
                    h2(
                      textOutput('student_gpa', inline = TRUE),
                      style = "
                      margin: 0;
                      font-size: 32px;
                    "
                    )
                  )
                )
                ) # end fluid row
                  ), # end tab Item 1
                
              
      
      # --- Tab 2: Module Information -------------------------------------------
      tabItem(tabName = "moduleinfo",
              h2("Module Information content")
      )
    ) # end TabItems
  ) # end Body
) # end UI
