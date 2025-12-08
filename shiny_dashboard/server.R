# --------------------------- SERVER LOGIC -------------------------------------
server <- function(input, output, session) {
  
  # ---------------- Dynamic Tab Header ----------------
  # Update tab header text dynamically based on selected tab
  output$tabHeader <- renderUI({
    currentTab <- switch(input$tabs,
                         "studentinfo" = "Student-Information",
                         "moduleinfo" = "Module Information",
                         "")
    tags$div(currentTab, class = "tab-header")
  }) # end renderUI tabHeader
  
  # ---------------- Dummy Student Filter ----------------
  # Dummy student data (can later come from PostgreSQL)
  students <- data.frame(
    matriculation_number = c("00001", "00002", "00003"),
    full_name = c("Max Müller", "Anna Schmidt", "Lukas Weber"),
    stringsAsFactors = FALSE
  ) # end students data.frame
  
  # Render the dropdowns only when "One Student" is selected
  output$one_student_filters <- renderUI({
    if(input$student_toggle == "One Student") {
      
      # Flex container again to align two dropdowns side by side
      div(style = "display: flex; align-items: center; gap: 20px;",
          selectInput("matric_number", "Matriculation Number:",
                      choices = students$matriculation_number),
          selectInput("student_name", "Full Name:",
                      choices = students$full_name)
      ) # end div flex
    } # end if
  }) # end renderUI

  
  } # end server

