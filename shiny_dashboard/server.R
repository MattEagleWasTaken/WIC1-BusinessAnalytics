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
  students <- dbGetQuery(con, "
    SELECT matriculation_number, first_name, last_name
    FROM student
    ORDER BY matriculation_number ASC
  ") # end dbGetQuery
  
  # ---------------- Dynamic Tab Header ----------------
  output$tabHeader <- renderUI({
    currentTab <- switch(input$tabs,
                         "studentinfo" = "Student-Information",
                         "moduleinfo" = "Module Information",
                         "")
    tags$div(currentTab, class = "tab-header")
  }) # end renderUI tabHeader
  
  # ---------------- Dynamic Student Filters ----------------
  output$one_student_filters <- renderUI({
    if(input$student_toggle == "One Student") {
      tagList(
        selectInput("matnr_select", "Matrikelnummer:",
                    choices = students$matriculation_number),
        selectInput("name_select", "Full Name:",
                    choices = paste(students$first_name, students$last_name))
      ) # end tagList
    } # end if
  }) # end renderUI one_student_filters
  
  # ---------------- Disconnect DB on app stop ----------------
  session$onSessionEnded(function() {
    dbDisconnect(con)
  }) # end onSessionEnded
  
} # end server
