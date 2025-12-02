# Define the server logic for the Shiny app
server <- function(input, output) {
  
  # Set a fixed seed for the random number generator
  # This ensures that the random numbers are the same every time the app runs
  set.seed(122)
  
  # Generate 500 random numbers from a standard normal distribution
  histdata <- rnorm(500)
  
  # Create a reactive plot output called "plot1"
  # This is linked to the plotOutput("plot1") in the UI
  output$plot1 <- renderPlot({
    
    # Select only the first 'n' numbers from histdata,
    # where 'n' is defined by the slider input in the UI
    data <- histdata[seq_len(input$slider)]
    
    # Draw a histogram of the selected data
    hist(data)
  })
}
