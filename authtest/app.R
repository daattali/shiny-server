ui <- fluidPage(
  shinydisconnect::disconnectMessage(),
  "User:", textOutput("user")
)
server <- function(input, output, session) {
  output$user <- renderText({
    session$user
  })
}

shinyApp(ui, server)
