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
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  display: flex;
  align-items: center;     /* CENTER instead of FLEX-START */
  gap: 25px;
  height: 120px;
  margin-top: 0 !important;
  padding-top: 0 !important
  
}

/* 4. Dropdown Input Menue (Selectize) */
.selectize-input {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  height: 40px !important;      /* fixed height for uniformity */
  border-radius: 45px !important;  /* rounded corners */
  padding-left: 10px !important;   /* spacing between text and left border */
  display: flex !important;         
  align-items: center !important;   /* vertically center text inside input */
}

/* 5. Dropdown list (the menu that opens) */
.selectize-dropdown {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  border-radius: 10px !important;  /* rounded corners for dropdown menu */
}

/* 6. Static text field Menue (read-only, same height as dropdown) */
.static-text-input {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
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
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
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
      menuItem("Exam-Information", tabName = "examinfo", icon = icon("chart-line")),
      menuItem("Degree-Programs", tabName = "degreeinfo", icon = icon("university"))
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
              
              # Filter Row Students
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
                  uiOutput("one_student_filters")
                )
              ),
              
              #-----------------------------------------------------------------------------------
              # GPA Card UI and Grade Plot (placed below the student filters)
              fluidRow(
                div(
                  style = "
                  display: flex;
                  align-items: flex-start;   /* top alignment */
                  gap: 30px;                 
                  width: 100%;
                  height: calc(100vh - 200px);  /* full viewport minus Header/Filter height */
                  margin-top: 15px;          /* spacing below filter row */
                  ",
                  
                  # ==== BARPLOT CONTAINER ====
                  div(
                    id = "bar_container",
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
                  
                  # ==== PIEPLOT CONTAINER ====
                  div(
                    id = "pie_container",
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
                    plotOutput("pie_plot", height = "100%", width = "100%")
                  ),
                    
                  
                  # ==== RIGHT CONTAINER WITH STACKED CARDS ====
                  div(
                    id = "right_container",
                    style = "
                    width: 25%;
                    display: flex; 
                    flex-direction: column;   /* stack cards vertically */
                    gap: 20px;                /* spacing between cards */
                    margin-right: 15px;       /* distance to screen edge */
                    height: calc(100vh - 200px); /* full container height */
                    ",
                    
                    # Upper Card (GPA)
                    div(
                      id = 'gpa_card',
                      style = "
                      background-color: white;
                      border-radius: 15px;
                      height: 160px;           /* fixed height */
                      display: flex;
                      flex-direction: column;
                      justify-content: center;
                      align-items: center;
                      box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
                      ",
                      uiOutput("gpa_title"),
                      
                      h2(
                        textOutput('student_gpa', inline = TRUE),
                        style = "
                        margin: 0;
                        font-size: 32px;
                        "
                      )
                    ),
                    
                    # Lower Card (Boxplot)
                    div(
                      id = 'boxplot_card',
                      style = "
                      background-color: white;
                      border-radius: 15px;
                      display: flex;
                      flex-direction: column;
                      justify-content: center;
                      align-items: center;
                      box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
                      flex: 1;                 /* take all remaining space */
                      padding: 15px;
                      ",
                      
                      # Render the boxplot output
                      plotOutput("boxplot_avg", height = "100%", width = "100%")
                    )
                  
                ) # end right container
                ) # end outer container around plot container and right container
                ) # end fluid row
                ), # end tab Item 1
                
              
      
      # --- Tab 2: Exam Information -------------------------------------------
      tabItem(tabName = "examinfo",
              
              # Filter Row Exams
              fluidRow(
                class = "filter-row",
                
                # Flex container for toggle + dropdowns + reset button
                div(
                  style = "display: flex; align-items: center; gap: 20px;height:100px",
                  
                  # Toggle: All Exams / One Exam
                  div(
                    radioButtons(
                      "exam_toggle",
                      "Select Exam:",
                      choices = c("All Exams", "One Exam"),
                      inline = TRUE
                    )
                    ),
                    
                  # Semester filter
                  uiOutput("exam_semester_filter"),
                  
                  # Dropdowns for One Exam (title + pnr)
                  uiOutput("one_exam_filters")
                  
                  ) # end filter container
                ) # end fluid row filter
              ,
              
              # Container for plots + right cards
              fluidRow(
                div(
                  style = "
                  display: flex;
                  align-items: flex-start;   /* top alignment */
                  gap: 30px;                 
                  width: 100%;
                  height: calc(100vh - 200px);  /* full viewport minus Header/Filter height */
                  margin-top: 15px;          /* spacing below filter row */
                  ",
                  
                  # ==== LEFT PLOT CONTAINER 1 ====
                  div(
                    id = "exam_plot_container1",
                    style = "
                    flex: 1;
                    background-color: white;
                    border-radius: 15px;
                    box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
                    padding: 20px;
                    height: calc(100vh - 200px);      /* fixed height for scroll */
                    overflow-y: auto;   /* vertical scrollbar */
                    margin-left: 15px;
                  ",
                    uiOutput("exam_plot1_ui")
                  ),
                  
                  # ==== LEFT PLOT CONTAINER 2 ====
                  div(
                    id = "exam_plot_container2",
                    style = "
                    flex: 1;
                    background-color: white;
                    border-radius: 15px;
                    box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
                    padding: 20px;
                    height: calc(100vh - 200px);
                    margin-left: 15px;
                    ",
                    plotOutput("exam_plot2", height = "100%", width = "100%")
                  ),
                  
                  # ==== RIGHT CONTAINER WITH STACKED CARDS ====
                  div(
                    id = "exam_right_container",
                    style = "
                    width: 25%;
                    display: flex; 
                    flex-direction: column;
                    gap: 20px;
                    margin-right: 15px;
                    height: calc(100vh - 200px);
                    ",
                    
                    # Upper Card Placeholder
                    div(
                      id = 'exam_card1',
                      style = "
                      background-color: white;
                      border-radius: 15px;
                      height: 160px;
                      display: flex;
                      flex-direction: column;
                      justify-content: center;
                      align-items: center;
                      box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
                      ",
                      
                      uiOutput("exam_gpa_title"),
                      
                      h2(
                        textOutput("exam_gpa_value", inline = TRUE),
                        style = "
                        margin: 0;
                        font-size: 32px;
                      "
                      )
                      ),
                    
                    # Lower Card Placeholder
                    div(
                      id = 'exam_card2',
                      style = "
                      background-color: white;
                      border-radius: 15px;
                      display: flex;
                      flex-direction: column;
                      justify-content: center;
                      align-items: center;
                      box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
                      flex: 1;
                      padding: 15px;
                      ",
                      plotOutput("exam_boxplot_avg", height = "100%", width = "100%")
                      )
                    
                  ) # end right container
                ) # end outer container around plot container and right container
              ) # end fluid row
      ), # end tabItem 2
      
      # --- Tab 3: Degree Information ------------------------------------------
      tabItem(
        tabName = "degreeinfo",
        
        # ----------------------------------------------------------------------
        # Filter Row Degree Programs
        # ----------------------------------------------------------------------
        fluidRow(
          class = "filter-row",
          
          # Flex container for toggle + dropdowns + reset button
          div(
            style = "display: flex; align-items: center; gap: 20px; height:100px",
            
            # Toggle placeholder (e.g. All Degrees / One Degree)
            div(
              radioButtons(
                "degree_toggle",
                "Select Degree Program:",
                choices = c("All Programs", "One Program"),
                inline = TRUE
              )
            ),
            
            # Placeholder: Semester / Degree filter
            uiOutput("degree_filter_1"),
            
            # Placeholder: Additional dropdowns (e.g. degree_program)
            uiOutput("degree_filter_2")
            
          ) # end filter container
        ), # end fluid row filter
        
        
        # ----------------------------------------------------------------------
        # Container for plots + right cards
        # ----------------------------------------------------------------------
        fluidRow(
          div(
            style = "
      display: flex;
      align-items: flex-start;
      gap: 30px;
      width: 100%;
      height: calc(100vh - 200px);
      margin-top: 15px;
      ",
            
            # ================================================================
            # LEFT PLOT CONTAINER 1
            # ================================================================
            div(
              id = "degree_plot_container1",
              style = "
        flex: 1;
        background-color: white;
        border-radius: 15px;
        box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
        padding: 20px;
        height: calc(100vh - 200px);
        overflow-y: auto;
        margin-left: 15px;
        ",
              
              # Placeholder for dynamic plot / UI
              uiOutput("degree_plot1_ui")
            ),
            
            # ================================================================
            # LEFT PLOT CONTAINER 2
            # ================================================================
            div(
              id = "degree_plot_container2",
              style = "
        flex: 1;
        background-color: white;
        border-radius: 15px;
        box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
        padding: 20px;
        height: calc(100vh - 200px);
        margin-left: 15px;
        ",
              
              # Placeholder plot
              plotOutput("degree_plot2", height = "100%", width = "100%")
            ),
            
            # ================================================================
            # RIGHT CONTAINER WITH STACKED CARDS
            # ================================================================
            div(
              id = "degree_right_container",
              style = "
        width: 25%;
        display: flex;
        flex-direction: column;
        gap: 20px;
        margin-right: 15px;
        height: calc(100vh - 200px);
        ",
              
              # ---------------- Upper Card ----------------
              div(
                id = "degree_card1",
                style = "
          background-color: white;
          border-radius: 15px;
          height: 160px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
          ",
                
                # Placeholder title
                uiOutput("degree_card1_title"),
                
                # Placeholder value
                h2(
                  textOutput("degree_card1_value", inline = TRUE),
                  style = "
            margin: 0;
            font-size: 32px;
            "
                )
              ),
              
              # ---------------- Lower Card ----------------
              div(
                id = "degree_card2",
                style = "
          background-color: white;
          border-radius: 15px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
          flex: 1;
          padding: 15px;
          ",
                
                # Placeholder plot
                plotOutput("degree_plot3", height = "100%", width = "100%")
              )
              
            ) # end right container
          ) # end outer container
        ) # end fluid row
      ) # end tabItem 3
    ) # end TabItems
  ) # end Body
) # end UI
