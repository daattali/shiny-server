library(shiny)
library(dplyr)
library(ggplot2)
library(colourpicker)
library(DT)

players <- read.csv("data/fifa2019.csv", stringsAsFactors = FALSE)

ui <- fluidPage(
  shinydisconnect::disconnectMessage2(),
  titlePanel("FIFA 2019 Player Stats"),
  strong("Built as part of a Shiny workshop, code and materials",
         tags$a("on GitHub", href = "https://github.com/daattali/shiny-mini-workshop")),
  checkboxInput("full_version", strong("SHOW FULL VERSION")),
  sidebarLayout(
    sidebarPanel(
      "Exploring all player stats from the FIFA 2019 video game",
      h3("Filters"),
      sliderInput(
        inputId = "rating",
        label = "Player rating at least",
        min = 0, max = 100,
        value = c(80, 100)
      ),
      selectInput(
        "country", "Player nationality",
        unique(players$nationality),
        selected = "Brazil",
        multiple = TRUE
      ),
      conditionalPanel(
        "input.full_version",
        h3("Plot options"),
        selectInput("variable", "Variable", c("rating", "wage", "value", "age"), "value"),
        radioButtons("plot_type", "Plot type", c("histogram", "density")),
        checkboxInput("log", "Log scale", value = TRUE),
        numericInput("size", "Font size", 16),
        colourInput("col", "Line colour", "blue")
      )
    ),
    mainPanel(
      strong(
        "There are",
        textOutput("num_players", inline = TRUE),
        "players in the dataset"
      ),
      plotOutput("fifa_plot"),
      DTOutput("players_data")
    )
  )
)

server <- function(input, output, session) {

  filtered_data <- reactive({
    players <- players %>%
      filter(rating >= input$rating[1],
             rating <= input$rating[2])

    if (length(input$country) > 0) {
      players <- players %>%
        filter(nationality %in% input$country)
    }

    players
  })

  output$players_data <- renderDT({
    if (input$full_version) {
      # Turn the photo URLs into HTML image tags
      filtered_data() %>%
        mutate(
          photo = paste0("<img src='", photo, "' />")
        )
    } else {
      filtered_data()
    }
  }, escape = FALSE)

  output$num_players <- renderText({
    nrow(filtered_data())
  })

  output$fifa_plot <- renderPlot({
    if (input$full_version) {
      p <- ggplot(filtered_data(), aes_string(input$variable)) +
        theme_classic(input$size)

      if (input$plot_type == "histogram") {
        p <- p + geom_histogram(fill = input$col, colour = "black")
      } else if (input$plot_type == "density") {
        p <- p + geom_density(fill = input$col)
      }

      if (input$log) {
        p <- p + scale_x_log10(labels = scales::comma)
      } else {
        p <- p + scale_x_continuous(labels = scales::comma)
      }
    } else {
      p <- ggplot(filtered_data(), aes(value)) +
        geom_histogram() +
        theme_classic() +
        scale_x_log10(labels = scales::comma)
    }

    p
  })

}

shinyApp(ui, server)

