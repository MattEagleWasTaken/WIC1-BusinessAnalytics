# --------------------------- SERVER LOGIC -------------------------------------
server <- function(input, output, session) {  # start server
  
  library(DBI)         # Interface für DB-Verbindungen
  library(RPostgres)   # PostgreSQL-Connector
  library(jsonlite)    # read JSON
  
  # ---------------- Read DB Credentials from JSON -------------------------
  db_config <- fromJSON("../user_login_config.json")  # relative path one level above Shiny app
  
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
  # ------------------- Get student table -------------------
  students <- dbGetQuery(con, "SELECT matriculation_number, first_name, last_name FROM student") # end dbGetQuery
  
  # ------------------- Sort for dropdowns -------------------
  # Matriculation number dropdown sorted ascending
  students_sorted_matr <- students[order(students$matriculation_number), ] # end order
  
  # Full Name dropdown sorted alphabetically by last name (then first name)
  students_sorted_name <- students[order(students$last_name, students$first_name), ] # end order
  students_sorted_name$full_name <- paste(students_sorted_name$first_name, students_sorted_name$last_name) # end paste
  
  # ---------------- Dynamic Tab Header ----------------
  # Sort names alphabetically by last name
  students <- students[order(students$last_name, students$first_name), ]  # sort by last name, then first name
  
  # ---------------- Dynamic Student Filters ----------------
  output$one_student_filters <- renderUI({
    if(input$student_toggle == "One Student") {
      tagList(
        selectInput("name_select", "Full Name:",
                    choices = students_sorted_name$full_name),
        
        selectInput("matnr_select", "Matrikelnummer:",
                    choices = students_sorted_matr$matriculation_number)
        
              ) # end tagList
    } # end if
  }) # end renderUI one_student_filters
  
  # ---------------- Disconnect DB on app stop ----------------
  session$onSessionEnded(function() {
    dbDisconnect(con)
  }) # end onSessionEnded
  
} # end server
