# Author: Marvin Fischer (Matriculation Number: 86186)

# This application was fully developed by the author.
# The author is responsible for the complete implementation,
# including UI design, server logic, data handling, and visualizations.


# Loads the Shiny package 
library(shiny)
# Loads Shiny Dashboard package 
library(shinydashboard)   

# Includes and executes the code from ui.R 
source("ui.R")            
# Includes and executes the code from server.R 
source("server.R")        

# Launches the Shiny application 
# Shiny start configuration
# alter Code shinyApp(ui, server)
port <- as.numeric(Sys.getenv("SHINY_PORT", unset = 3445))

shiny::runApp(
  app = shinyApp(ui, server),
  host = "127.0.0.1",
  port = port,
  launch.browser = FALSE
)

