# Loads the Shiny package (framework for building web apps in R)
library(shiny)
# Loads Shiny Dashboard package (provides dashboard layout components)
library(shinydashboard)   

# Includes and executes the code from ui.R (defines the user interface)
source("ui.R")            
# Includes and executes the code from server.R (defines server logic)
source("server.R")        

# Launches the Shiny application using the UI and server objects
shinyApp(ui, server)      

