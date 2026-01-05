# Author: Marvin Fischer (Matriculation Number: 86186)
#
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
shinyApp(ui, server)      

