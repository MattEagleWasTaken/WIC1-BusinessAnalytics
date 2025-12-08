server <- function(input, output, session) {
  
  library(DBI)
  library(RPostgres)
  library(jsonlite)
  library(shinyjs)
  
  # ---------------- Load DB Credentials ----------------
  db_config <- fromJSON("../user_login_config.json")
  
  con <- dbConnect(
    RPostgres::Postgres(),
    dbname   = db_config$database,
    host     = db_config$host,
    port     = db_config$port,
    user     = db_config$username,
    password = db_config$password
  )
  
  # ---------------- Load Student Data ----------------
  students <- dbGetQuery(con, "
    SELECT matriculation_number, first_name, last_name FROM student
  ")
  
  students_sorted_matr <- students[order(students$matriculation_number), ]
  students_sorted_name <- students[order(students$last_name, students$first_name), ]
  students_sorted_name$full_name <- paste(students_sorted_name$first_name,
                                          students_sorted_name$last_name)
  
  name_choices <- c("- not selected -", students_sorted_name$full_name)
  matr_choices <- c("- not selected -", students_sorted_matr$matriculation_number)
  
  
  # ============================================================================
  # Dynamic Input Row (for "One Student")
  # ============================================================================
  output$one_student_filters <- renderUI({
    
    req(input$student_toggle == "One Student")
    
    name_selected <- !is.null(input$name_select) && input$name_select != "- not selected -"
    matr_selected <- !is.null(input$matnr_select) && input$matnr_select != "- not selected -"
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px;",
      
      # ---------------- Student Name ----------------
      if (!matr_selected) {
        selectInput(
          "name_select",
          label = tags$label("Student Name:", class = "unified-label"),
          choices = name_choices,
          selected = input$name_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          tags$label("Student Name:", class = "unified-label"),
          div(
            class = "static-text-input",
            {
              row <- students_sorted_name[
                students_sorted_name$matriculation_number == input$matnr_select, ]
              paste(row$first_name, row$last_name)
            }
          )
        )
      },
      
      # ---------------- Matriculation Number ----------------
      if (!name_selected) {
        selectInput(
          "matnr_select",
          label = tags$label("Matriculation Number:", class = "unified-label"),
          choices = matr_choices,
          selected = input$matnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          tags$label("Matriculation Number:", class = "unified-label"),
          div(
            class = "static-text-input",
            {
              row <- students_sorted_name[
                students_sorted_name$full_name == input$name_select, ]
              row$matriculation_number
            }
          )
        )
      },
      
      # ---------------- Reset Button ----------------
      actionButton(
        "reset_filters",
        "Reset Selection",
        class = "reset-btn",
        style = "margin-top: 10px;"
      )
    )
  })
  
  
  # ============================================================================
  # Show / Hide Reset Button
  # ============================================================================
  observe({
    if (
      (!is.null(input$name_select) && input$name_select != "- not selected -") ||
      (!is.null(input$matnr_select) && input$matnr_select != "- not selected -")
    ) {
      shinyjs::show("reset_filters")
    } else {
      shinyjs::hide("reset_filters")
    }
  })
  
  
  # ============================================================================
  # Reset all dropdowns
  # ============================================================================
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "name_select", selected = "- not selected -")
    updateSelectInput(session, "matnr_select", selected = "- not selected -")
  })
  
  
  # ============================================================================
  # Compute GPA for selected student
  # ============================================================================
  output$student_gpa <- renderText({
    req(input$student_toggle == "One Student")
    
    selected_matr <- input$matnr_select
    selected_name <- input$name_select
    
    # Resolve matriculation number
    if (!is.null(selected_matr) && selected_matr != "- not selected -") {
      matr <- selected_matr
    } else if (!is.null(selected_name) && selected_name != "- not selected -") {
      row <- students_sorted_name[students_sorted_name$full_name == selected_name, ]
      matr <- row$matriculation_number
    } else {
      return("-")
    }
    
    # Load grades
    student_grades <- dbGetQuery(
      con,
      paste0("SELECT grade FROM grade WHERE matriculation_number = '", matr, "'")
    )
    
    if (nrow(student_grades) == 0) return("-")
    
    round(mean(student_grades$grade, na.rm = TRUE), 2)
  })
  
  
  # Disconnect when session ends
  session$onSessionEnded(function() dbDisconnect(con))
}
