# Loads the Shiny package 
library(shiny)
# Loads Shiny Dashboard package 
library(shinydashboard)   

# Includes and executes the code from ui.R 
source("ui.R")            
# Includes and executes the code from server.R 
source("server.R")        

# Launches the Shiny application 
shinyApp(ui, server)      

