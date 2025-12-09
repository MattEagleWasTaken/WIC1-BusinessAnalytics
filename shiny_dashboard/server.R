server <- function(input, output, session) {
  
  library(DBI)
  library(RPostgres)
  library(jsonlite)
  library(shinyjs)
  # ggplot2 → used for creating the grade visualization plot
  library(ggplot2)
  
  
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
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      
      # ---------------- Student Name ----------------
      if (!matr_selected) {
        selectInput(
          "name_select",
          label = tags$label("Student Name:",style = "margin-top: 5px;"),
          choices = name_choices,
          selected = input$name_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          tags$label("Student Name:", style = "margin-top: 5px;"),
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.15);",
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
          label = tags$label("Matriculation Number:", style = "margin-top: 5px;"),
          choices = matr_choices,
          selected = input$matnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          tags$label("Matriculation Number:", style = "margin-top: 5px"),
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.15);",
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
        style = "margin-top:35px; box-shadow: 0px 2px 6px rgba(0,0,0,0.15);"
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
# All Grades for selected student
# ============================================================================
  # Platz zum Speichern der Plotdaten
  student_grades_for_plot <- reactiveVal(NULL)
  
  
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
    
    # Load grades + exam titles
    student_grades <- dbGetQuery(
      con,
      paste0("
      SELECT g.grade, g.grade_date, e.title AS exam_title
      FROM grade g
      JOIN exam e ON g.pnr = e.pnr
      WHERE g.matriculation_number = '", matr, "'
    ")
    )
    
    # Speichere die Daten für den Plot
    student_grades_for_plot(student_grades)
    
    # Average Grade Calculation stays unchanged
    if (nrow(student_grades) == 0) return("-")
    
    round(mean(student_grades$grade, na.rm = TRUE), 2)
    
  })
  
  # ============================================================================
  # Grades horizontal bar plot
  # ============================================================================
  output$grades_plot <- renderPlot({
    df <- student_grades_for_plot()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    # Assign colors based on grade ranges
    df$color <- cut(
      df$grade,
      breaks = c(0, 2.7, 4.0, 6),
      labels = c("green", "orange", "red"),
      include.lowest = TRUE
    )
    
    ggplot(df, aes(x = grade, y = reorder(exam_title, grade), fill = color)) +
      # Draw horizontal bars
      geom_col(width = 0.6, color = "black") +
      # Add grade label inside each bar, aligned to the left end
      geom_text(aes(label = grade), 
                hjust = 1.1,   
                color = "black",
                size = 4,
                fontface = "bold") +
      # X-axis from grade 1 (left) to 6 (right)
      scale_x_continuous(
        breaks = 1:6,
        labels = 1:6,
        expand = c(0,0),
        limits = c(0,6)   
      ) +
      # Use softer colors for grade ranges
      scale_fill_manual(
        values = c(
          "green"  = "#88c999",
          "orange" = "#f3b173",
          "red"    = "#e16b6b"
        )
      ) +
      # Labels and title
      labs(x = "Grade", y = "Exam", title = "Student Grades Overview") +
      # Minimal theme with custom styling
      theme_minimal(base_size = 14) +
      theme(
        plot.background  = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white"),
        axis.text.y      = element_text(face = "bold"),
        axis.text.x      = element_text(face = "bold")
      )
  })
  
  
  
  
  
  
  
  # Disconnect when session ends---------------------------------------------------------
  session$onSessionEnded(function() dbDisconnect(con))
}
