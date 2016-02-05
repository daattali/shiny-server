library(shiny)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  inlineCSS("#done { color: green; }"),
  h2("Demo of shinyjs"),
  h4("This simple form submission app shows how to use some common shinyjs functions:",
     br(),
     "show(), hide(), reset(), disable(), toggleState(), hidden(), delay()"),
  div(
    id = "myform",
    textInput("name", "Name", "Dean"),
    numericInput("age", "Age", 27),
    checkboxInput("terms", "I agree to the terms", FALSE)
  ),
  actionButton("submit", "Submit", icon = icon("sign-in")),
  hidden(
    span(
      id = "done",
      icon("check")
    ),
    span(
      id = "working",
      icon("spinner", class = "fa-spin")
    )
  )
)

server <- function(input, output, session) {
  observe({
    toggleState("submit", condition = input$terms)
  })
  
  observeEvent(input$submit, {
    disable("submit")
    reset("myform")
    show("working")

    # do some work
    Sys.sleep(1)

    hide("working")
    show("done")
    delay(2000,
          hide("done", anim = TRUE, animType = "fade")
    )
  })
}

shinyApp(ui = ui, server = server, options = list("display.mode"="showcase"))
