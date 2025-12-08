server <- function(input, output, session) {
  
  library(DBI)
  library(RPostgres)
  library(jsonlite)
  library(shinyjs)  # for show/hide functionality
  
  # ---------------- Read DB Credentials ----------------
  db_config <- fromJSON("../user_login_config.json")
  
  # ---------------- Connect to PostgreSQL ----------------
  con <- dbConnect(
    RPostgres::Postgres(),
    dbname   = db_config$database,
    host     = db_config$host,
    port     = db_config$port,
    user     = db_config$username,
    password = db_config$password
  )
  
  # ---------------- Load Student Data ----------------
  students <- dbGetQuery(
    con,
    "SELECT matriculation_number, first_name, last_name FROM student"
  )
  
  # ------------------- Sorting for Dropdowns -------------------
  students_sorted_matr <- students[order(students$matriculation_number), ]
  students_sorted_name <- students[order(students$last_name, students$first_name), ]
  students_sorted_name$full_name <- paste(students_sorted_name$first_name, students_sorted_name$last_name)
  
  # Dropdown choices with placeholder
  name_choices <- c("- not selected -", students_sorted_name$full_name)
  matr_choices <- c("- not selected -", students_sorted_matr$matriculation_number)
  
  # ---------------- Dynamic Student Filters ----------------
  output$one_student_filters <- renderUI({
    if (input$student_toggle == "One Student") {
      
      # Determine which dropdowns are selected
      name_selected <- !is.null(input$name_select) && input$name_select != "- not selected -"
      matr_selected <- !is.null(input$matnr_select) && input$matnr_select != "- not selected -"
      
      div(
        style = "display: flex; align-items: center; gap: 10px;",  # horizontal alignment
        
        # ---------------- Full Name Input / Text ----------------
        if (!matr_selected) {
          # Show dropdown if no matriculation number selected
          selectInput(
            "name_select",
            "Full Name:",
            choices = name_choices,
            selected = input$name_select %||% "- not selected -"
          )
        } else {
          # Show static text if matriculation number is selected
          # label display
          div(
            class = "static-text-container",
            tags$label("Full Name:", class = "static-text-label"),
            div(
              class = "static-text-input",
            {
              student_row <- students_sorted_name[students_sorted_name$matriculation_number == input$matnr_select, ]
              paste(student_row$first_name, student_row$last_name)
            }
          )
          )
        },
        
        # ---------------- Matriculation Number Input / Text ----------------
        if (!name_selected) {
          # Show dropdown if no name selected
          selectInput(
            "matnr_select",
            "Matriculation Number:",
            choices = matr_choices,
            selected = input$matnr_select %||% "- not selected -"
          )
        } else {
          # Show static text if name is selected
          # label display
          div(
            class = "static-text-container",
            tags$label("Matriculation Number:", class = "static-text-label"),
            div(
              class = "static-text-input",
            {
              student_row <- students_sorted_name[students_sorted_name$full_name == input$name_select, ]
              student_row$matriculation_number
            }
          )
          )
        },
        
        # Reset button (always in UI, visibility controlled via shinyjs)
        actionButton(
          "reset_filters",
          "Reset Selection",
          class = "reset-btn",
          style = "position: relative; top: 5px;"
        )
      )
    }
  })
  
  # ---------------- Show/Hide Reset Button ----------------
  observe({
    if (!is.null(input$name_select) && input$name_select != "- not selected -" ||
        !is.null(input$matnr_select) && input$matnr_select != "- not selected -") {
      shinyjs::show("reset_filters")
    } else {
      shinyjs::hide("reset_filters")
    }
  })
  
  # ---------------- Reset Both Dropdowns ----------------
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "name_select", selected = "- not selected -")
    updateSelectInput(session, "matnr_select", selected = "- not selected -")
  })
  
  # ---------------- Disconnect DB on session end ----------------
  session$onSessionEnded(function() {
    dbDisconnect(con)
  })
}
