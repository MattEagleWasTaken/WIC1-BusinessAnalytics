# Author: Marvin Fischer (Matriculation Number: 86186)

# This application was fully developed by the author.
# The author is responsible for the complete implementation,
# including UI design, server logic, data handling, and visualizations.


# Load the Shiny package 
library(shiny)

# Load Shiny Dashboard package 
library(shinydashboard)

# Load shinyjs for dynamic show/hide of UI elements
library(shinyjs)

# ggplot2 visualization plots
library(ggplot2)


# ------------------------ CUSTOM CSS ------------------------------------------
customCSS <- "

/* ------------------------ GENERAL LAYOUT ------------------------------------*/ 
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

/* 1. Filter row */
.filter-row {
  background-color: white;
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  display: flex;
  align-items: center;     
  gap: 25px;
  height: 120px;
  margin-top: 0 !important;
  padding-top: 0 !important
  
}

/* 4. Dropdown Input Menue */
.selectize-input {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  height: 40px !important;      
  width: 300px !important;
  border-radius: 45px !important;  
  padding-left: 10px !important;   
  display: flex !important;         
  align-items: center !important;   
}

/* 5. Dropdown list */
.selectize-dropdown {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  border-radius: 10px !important;  
}

/* 6. Static text field Menue */ 
.static-text-input {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  height: 40px;                 
  width: 300px;
  border-radius: 45px;          
  border: 1px solid #ccc;       
  padding: 0 10px;              
  display: flex;                
  align-items: center;          
  background: white;            
}

/* 7. Radio Buttons */
.radio-block {
  width: 100px;
  margin-top: 5px;              
}

/* 8. Reset Button */
.reset-btn {
  box-shadow: 0px 2px 6px rgba(0,0,0,0.2);
  background-color: #4da3ff;    
  color: white;                 
  border-radius: 45px;          
  height: 40px;                 
  display: flex;
  align-items: center;          
  justify-content: center;      
  border: none;                 
  padding: 0 20px;              
  margin-top: 6px;              
}

"

# ---- UI ----------------------------------------------------------------------
ui <- dashboardPage(
  
  # ---------------- TOP HEADER -----------------------------------------------
  dashboardHeader(
    title = "HS-Dashboard"
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
                  style = "display: flex; align-items: center; gap: 15px;height:100px",
                  
                  # Toggle: All Students / One Student
                  div(
                    class = "radio-block",
                    radioButtons(
                      "student_toggle",
                      "Select Student:",
                      choices = c("All Students", "One Student"),
                      inline = FALSE
                    )
                  ),
                  
                  # Dropdowns 
                  uiOutput("one_student_filters")
                )
              ),
              
              #-----------------------------------------------------------------------------------
              # GPA Card UI and Grade Plot
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
                  
                  # Barplot Container
                  div(
                    id = "student_plot_container1",
                    style = "
                    flex: 1;
                    min-width: 0;
                    background-color: white;
                    border-radius: 15px;
                    box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
                    padding: 20px;
                    overflow-y: auto;   
                    margin-left: 15px;
                    height: calc(100vh - 200px);
                    ",
                    
                    # Plot inside this container 
                    plotOutput("grades_plot", height = "100%", width = "100%")
                    ),
                  
                  # Pieplot Container
                  div(
                    id = "student_plot_container2",
                    style = "
                    flex: 1;
                    min-width: 0;
                    background-color: white;
                    border-radius: 15px;
                    box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
                    padding: 20px;
                    overflow-y: auto;   
                    margin-left: 15px;
                    height: calc(100vh - 200px);
                    ",
                    
                    # Plot inside this container 
                    plotOutput("pie_plot", height = "100%", width = "100%")
                  ),
                    
                  
                  # Right Container
                  div(
                    id = "right_container",
                    style = "
                    width: 25%;
                    display: flex; 
                    flex-direction: column;   
                    gap: 20px;                
                    margin-right: 15px;       
                    height: 100%; 
                    ",
                    
                    # Upper Card (GPA)
                    div(
                      id = 'gpa_card',
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
                      flex: 1;
                      min-height:0;
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
                  style = "display: flex; align-items: center; gap: 15px; height:100px",
                  
                  # Radio Buttons
                  div(
                    class = "radio-block",
                    radioButtons(
                      "exam_toggle",
                      "Select Exam:",
                      choices = c("All Exams", "One Exam"),
                      inline = FALSE
                    )
                  ),
                  
                  # ------------------------------------------------------------
                  # Semester
                  uiOutput("exam_semester_filter"),
                  
                  # ------------------------------------------------------------
                  # Exam filters (One Exam)
                  uiOutput("one_exam_filters")
                )
              ) # end fluid row filter
              ,
              
              # Container for plots + right cards
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
                  
                  # Left Plot Container 1
                  div(
                    id = "exam_plot_container1",
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
                    uiOutput("exam_plot1_ui")
                  ),
                  
                  # Left Plot Container 2
                  div(
                    id = "exam_plot_container2",
                    style = "
                    flex: 1;
                    min-width: 0;
                    background-color: white;
                    border-radius: 15px;
                    box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
                    padding: 20px;
                    height: calc(100vh - 200px);
                    margin-left: 15px;
                    ",
                    plotOutput("exam_plot2", height = "100%", width = "100%")
                  ),
                  
                  # Right Container
                  div(
                    id = "exam_right_container",
                    style = "
                    width: 25%;
                    display: flex; 
                    flex-direction: column;
                    gap: 20px;
                    margin-right: 15px;
                    height: 100%;
                    ",
                    
                    # Upper Card 
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
                    
                    # Lower Card 
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
                      min-height: 0;
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
        fluidRow(
          class = "filter-row",
          
          # Flex container for toggle + dropdowns + reset button
          div(
            style = "display: flex; align-items: center; gap: 15px; height:100px",
            
            # Toggle (e.g. All Degrees / One Degree)
            div(
              class = "radio-block",
              radioButtons(
                "degree_toggle",
                "Select Degree Program:",
                choices = c("All Programs", "One Program"),
                inline = FALSE
              )
            ),
            
            # Semester filter (All Programs & One Program)
            uiOutput("degree_semester_filter"),
            
            # Dropdown + Reset (only in One Program mode)
            uiOutput("one_degree_filters")
            
          ) # end filter container
        ), # end fluid row filter
        
        
        # ----------------------------------------------------------------------
        # Container for plots + right cards
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
            
            # Left Container 1
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
              
              # for dynamic plot / UI
              uiOutput("degree_plot1_ui")
            ),
            
            # Left Container 2
            div(
              id = "degree_plot_container2",
              style = "
              flex: 1;
              min-width: 0;
              background-color: white;
              border-radius: 15px;
              box-shadow: 0px 4px 15px rgba(0,0,0,0.2);
              padding: 20px;
              height: calc(100vh - 200px);
              margin-left: 15px;
              ",
              
              # plot
              plotOutput("degree_plot2", height = "100%", width = "100%")
            ),
            
            # Right Container
            div(
              id = "degree_right_container",
              style = "
              width: 25%;
              display: flex;
              flex-direction: column;
              gap: 20px;
              margin-right: 15px;
              height: 100%;
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
                
                # title
                uiOutput("degree_card1_title"),
                
                # value
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
                box-shadow: 0px 0px 10px rgba(0,0,0,0.2);
                flex: 1;
                min-height: 0;
                padding: 15px;
                ",
                
                
                # Boxplot Container 1
                div(
                  id = "degree_boxplot_all_container",
                  style = "
                  width: 100%;
                  height: 100%;
                  ",
                  plotOutput("degree_boxplot_all", height = "100%", width = "100%")
                ),
                
                # Boxplot Container 2 
                div(
                  id = "degree_boxplot_one_container",
                  style = "
                  width: 100%;
                  height: 100%;
                  display: none;
                  ",
                  plotOutput("degree_boxplot_one", height = "100%", width = "100%")
                )
              )
              
            ) # end right container
          ) # end outer container
        ) # end fluid row
      ) # end tabItem 3
    ) # end TabItems
  ) # end Body
) # end UI
