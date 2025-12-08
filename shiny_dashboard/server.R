# --------------------------- SERVER LOGIC -------------------------------------
server <- function(input, output, session) {
  
  # Update tab header text dynamically based on selected tab
  output$tabHeader <- renderUI({
    currentTab <- switch(input$tabs,
                         "studentinfo" = "Student-Information",
                         "moduleinfo" = "Module Information",
                         "")
    tags$div(currentTab, class = "tab-header")
  })
  
  # Example reactive plot
  output$plot1 <- renderPlot({
    hist(rnorm(500)[1:input$slider])
  })
}
