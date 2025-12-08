# --------------------------- SERVER LOGIC -------------------------------------
server <- function(input, output, session) {  # start server
  
  library(DBI)         # DB interface
  library(RPostgres)   # PostgreSQL connector
  library(jsonlite)    # read JSON files
  
  # ---------------- Read DB Credentials from JSON -------------------------
  db_config <- fromJSON("../user_login_config.json")  # relative path above Shiny app
  
  # ---------------- Connect to PostgreSQL DB ----------------
  con <- dbConnect(
    RPostgres::Postgres(),
    dbname   = db_config$database,
    host     = db_config$host,
    port     = db_config$port,
    user     = db_config$username,
    password = db_config$password
  ) # end dbConnect
  
  # ---------------- Load Student Data ----------------
  students <- dbGetQuery(
    con,
    "SELECT matriculation_number, first_name, last_name FROM student"
  ) # end dbGetQuery
  
  
  # ------------------- Sorting for Dropdowns -------------------
  
  # Matriculation numbers sorted ascending
  students_sorted_matr <- students[order(students$matriculation_number), ] # end order
  
  # Names sorted alphabetically by last name, then first name
  students_sorted_name <- students[order(students$last_name, students$first_name), ] # end order
  students_sorted_name$full_name <- paste(
    students_sorted_name$first_name,
    students_sorted_name$last_name
  ) # end paste
  
  # Create dropdown choices with an initial placeholder
  name_choices <- c("- not selected -", students_sorted_name$full_name)
  matr_choices <- c("- not selected -", students_sorted_matr$matriculation_number)
  
  
  # ---------------- Dynamic Tab Header Logic ----------------
  # (If used elsewhere)
  students <- students[order(students$last_name, students$first_name), ]  # end reorder
  
  
  # ---------------- Dynamic Student Filters ----------------
  output$one_student_filters <- renderUI({  # start renderUI
    
    if (input$student_toggle == "One Student") {  # start if
      tagList(
        # Full name dropdown
        selectInput(
          "name_select",
          "Full Name:",
          choices = name_choices,
          selected = "- not selected -"
        ),  # end selectInput name_select
        
        # Matriculation number dropdown
        selectInput(
          "matnr_select",
          "Matrikelnummer:",
          choices = matr_choices,
          selected = "- not selected -"
        ),   # end selectInput matnr_select
        
        # Reset button
        actionButton(
          "reset_filters",
          "Reset Selection",
          style = "
          background-color:#4da3ff;
          color:white;
          border-radius:45px;
          text-align:center;
          "
        )  # end actionButton
        
        
      ) # end tagList
    } # end if
    
  }) # end renderUI one_student_filters
  
  # ---------------- Reset Both Dropdowns ----------------
  observeEvent(input$reset_filters, {   # start observeEvent
    
    updateSelectInput(
      session,
      "name_select",
      selected = "- not selected -"
    ) # end updateSelectInput name_select
    
    updateSelectInput(
      session,
      "matnr_select",
      selected = "- not selected -"
    ) # end updateSelectInput matnr_select
    
  }) # end observeEvent reset_filters
  
  
 
  
  
  # ---------------- Disconnect DB when session ends ----------------
  session$onSessionEnded(function() {  # start onSessionEnded
    dbDisconnect(con)
  }) # end onSessionEnded
  
} # end server
