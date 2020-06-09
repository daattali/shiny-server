library(shiny)
library(dplyr)
library(ggplot2)
library(colourpicker)
library(DT)
library(readr)

players <- read_csv("data/nba2018.csv", col_types = cols())

ui <- fluidPage(
  shinydisconnect::disconnectMessage2(),
  titlePanel("NBA 2018/19 Player Stats"),
  checkboxInput("full_version", strong("SHOW FULL VERSION"), value = TRUE),
  sidebarLayout(
    sidebarPanel(
      "Exploring all player stats from the NBA 2018/19 season",
      h3("Filters"),
      sliderInput(
        inputId = "VORP",
        label = "Player VORP rating at least",
        min = -3, max = 10,
        value = c(0, 10)
      ),
      selectInput(
        "Team", "Team",
        unique(players$Team),
        multiple = TRUE
      ),
      conditionalPanel(
        "input.full_version",
        h3("Plot options"),
        selectInput("variable", "Variable",
                    c("VORP", "Salary", "Age", "Height", "Weight"),
                    "Salary"),
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
      plotOutput("nba_plot"),
      DTOutput("players_data")
    )
  )
)

server <- function(input, output, session) {

  filtered_data <- reactive({
    players <- players %>%
      filter(VORP >= input$VORP[1],
             VORP <= input$VORP[2])

    if (length(input$Team) > 0) {
      players <- players %>%
        filter(Team %in% input$Team)
    }

    players
  })

  output$players_data <- renderDT({
    datatable(filtered_data()) %>% formatCurrency('Salary')
  })

  output$num_players <- renderText({
    nrow(filtered_data())
  })

  output$nba_plot <- renderPlot({
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
      p <- ggplot(filtered_data(), aes(Salary)) +
        geom_histogram() +
        theme_classic() +
        scale_x_log10(labels = scales::comma)
    }

    p
  })

}

shinyApp(ui, server)
