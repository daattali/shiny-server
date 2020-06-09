library(shiny)
library(ggplot2)
library(magrittr)

share <- list(
  title = "useR! 2017 Attendance",
  url = "https://daattali.com/shiny/user2017attendance",
  image = "https://daattali.com/shiny/img/user2017attendance.png",
  description = "Explore the attendees' schedules from the useR! 2017 Conference",
  twitter_user = "daattali"
)

all_talks <- read.csv("all_talks.csv")
all_talks$time <- as.POSIXct(all_talks$time)
viz_fields <- c("type", "attendance", "time", "room", "concurrent_attendance",
                "concurrent_sessions", "attendance_ratio", "expected")
fill_fields <- c("type", "room")
aggregate_fields <- c("type", "time", "room")
aggregate_fields_y <- c("attendance", "concurrent_attendance",
                        "concurrent_sessions", "expected", "attendance_ratio")

fix_name <- function(x) {
  gsub("_", " ", x)
}

ui <- fluidPage(
  shinydisconnect::disconnectMessage2(),
  title = "useR! 2017 Attendance",
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(href = "style.css", rel = "stylesheet"),

    # Favicon
    tags$link(rel = "shortcut icon", type="image/x-icon", href="https://daattali.com/shiny/img/favicon.ico"),

    # Facebook OpenGraph tags
    tags$meta(property = "og:title", content = share$title),
    tags$meta(property = "og:type", content = "website"),
    tags$meta(property = "og:url", content = share$url),
    tags$meta(property = "og:image", content = share$image),
    tags$meta(property = "og:description", content = share$description),

    # Twitter summary cards
    tags$meta(name = "twitter:card", content = "summary"),
    tags$meta(name = "twitter:site", content = paste0("@", share$twitter_user)),
    tags$meta(name = "twitter:creator", content = paste0("@", share$twitter_user)),
    tags$meta(name = "twitter:title", content = share$title),
    tags$meta(name = "twitter:description", content = share$description),
    tags$meta(name = "twitter:image", content = share$image)
  ),
  div(id = "header",
      div(id = "title",
          "useR! 2017 Attendance"
      ),
      div(id = "subtitle",
          "Explore the attendees' schedules from the useR! 2017 Conference"),
      div(id = "subsubtitle",
          "By",
          tags$a(href = "https://deanattali.com/", "Dean Attali"),
          HTML("&bull;"),
          "Code and data",
          tags$a(href = "https://github.com/daattali/user2017", "on GitHub"),
          HTML("&bull;"),
          tags$a(href = "https://deanattali.com/colourpicker-user2017/", "My talk"),
          HTML("&bull;"),
          tags$a(href = "https://deanattali.com/blog/user2017/", "Blog post")
      )
  ),
  fluidRow(
    column(
      3,
      class = "col-settings",
      checkboxGroupInput(
        "type", "Event type",
        choices = unique(all_talks$type),
        selected = unique(all_talks$type),
        inline = TRUE
      ),
      selectInput("xvar", "X axis", viz_fields, selected = "type"),
      checkboxInput("aggregate", "Aggregate?", FALSE),
      selectInput("yvar", "Y axis", viz_fields, selected = "attendance"),
      selectInput("fillvar", "Colour by", c("none", fill_fields), selected = "type"),
      checkboxInput("jitter", "Add jitter?", FALSE),
      div(id = "aggregate-note",
          HTML("<strong>Note:</strong> when aggregating data, 'attendance' is the",
               "<strong>total</strong> attendance, while all other numeric",
               "columns are the <strong>mean</strong> of the respective variable")),
      downloadButton("download", "Download Data")
    ),
    column(
      9,
      class = "col-tabs",
      tabsetPanel(
        id = "mainnav",
        tabPanel(
          div(icon("bar-chart"), "Plot"),
          div(
            style = "position:relative",
            plotOutput("scatterplot", width = "90%", height = "600px",
                       hover = hoverOpts("plot_hover", delay = 10)),
            uiOutput("hover_info")
          )
        ),
        tabPanel(
          div(icon("table"), "Data"),
          DT::dataTableOutput("table")
        ),
        tabPanel(
          div(icon("code"), "Data prep code"),
          tags$pre(includeText("scrape_data.R"))
        )
      )
    )
  )
)

server <- function(input, output) {

  # Filter the data according to the inputs
  talks_data_filtered <- reactive({
    all_talks <- dplyr::filter(all_talks, type %in% input$type)

    if (aggregated()) {
      all_talks <-
        all_talks %>%
        dplyr::group_by_(input$xvar) %>%
        dplyr::summarize(
          attendance = sum(attendance),
          concurrent_attendance = round(mean(concurrent_attendance)),
          concurrent_sessions = round(mean(concurrent_sessions), 1),
          expected = round(mean(expected)),
          attendance_ratio = round(mean(attendance_ratio), 2)
        ) %>%
        dplyr::ungroup()
    }

    all_talks
  })

  # whether or not the data is aggregated
  aggregated <- reactive({
    input$xvar %in% aggregate_fields && input$aggregate
  })

  observe({
    shinyjs::toggle("fillvar", condition = !aggregated())
    shinyjs::toggle("jitter", condition = !aggregated())
    shinyjs::toggle("aggregate-note", condition = aggregated())
  })

  # Don't show "aggregated?" checkbox when a non-aggregateable variable is chosen
  observe({
    if (input$xvar %in% aggregate_fields) {
      shinyjs::html(selector = "#aggregate +span", html = sprintf("Aggregate %s?", input$xvar))
      shinyjs::show("aggregate")
    } else {
      shinyjs::hide("aggregate")
    }
  })

  # render the scatter plot
  output$scatterplot <- renderPlot({
    validate(
      need(
        !aggregated() || input$yvar %in% aggregate_fields_y,
        sprintf("Cannot plot '%s' when using aggregate data (only numeric columns can be plotted)",
                input$yvar)
      )
    )

    p <- ggplot(talks_data_filtered(), aes_string(input$xvar, input$yvar)) +
      theme_minimal(24) +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
            panel.grid.minor = element_blank(),
            legend.position = "bottom",
            plot.title = element_text(hjust = 0.5),
            axis.line.x = element_line(), axis.line.y = element_line()) +
      guides(fill = guide_legend(title = "")) +
      scale_fill_brewer(type = "qual", palette = 3) +
      xlab(fix_name(input$xvar)) +
      ylab(fix_name(input$yvar))

    geom_params <- list(pch = 21, size = 5)
    if (input$jitter && !aggregated()) {
      geom_fxn <- geom_jitter
      geom_params$width <- 0.2
    } else {
      geom_fxn <- geom_point
    }
    if (input$fillvar == "none" || aggregated()) {
      geom_params <- c(geom_params, list(fill = "#1f78b4", col = "#555555"))
    } else {
      geom_params <- c(geom_params, list(
        mapping = aes_string(fill = input$fillvar), col = "#222222"))
    }
    p <- p + do.call(geom_fxn, geom_params)

    title <- fix_name(input$xvar)
    title <- paste0(title, if (aggregated()) " (aggregated)" else "", " vs")
    if (aggregated()) {
      if (input$yvar == "attendance") {
        title <- paste0(title, " total")
      } else {
        title <- paste0(title, " average")
      }
    }
    title <- paste0(title, " ", fix_name(input$yvar))

    p <- p + ggtitle(title)
    p
  })

  # render the tooltip when hovering over points
  output$hover_info <- renderUI({
    if (nrow(talks_data_filtered()) == 0) return(NULL)
    hover <- input$plot_hover
    row <- nearPoints(talks_data_filtered(), hover, threshold = 5, maxpoints = 1, addDist = TRUE)
    if (nrow(row) == 0) return(NULL)

    left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
    top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)

    style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                    "left:", left_px + 2, "px; top:", top_px + 2, "px; padding: 10px;")

    if (aggregated()) {
      html <- paste0(
        "<strong>", input$xvar, ":</strong> ", row[[input$xvar]], "<br/>",
        "<strong>", input$yvar, ":</strong> ", row[[input$yvar]]
      )
    } else {
      html <- paste0(
        "<strong>", row$title, "</strong><br/>",
        "<em>", row$speaker, "</em> @ ", row$room, "<hr/>",
        row$time, "<br/>",
        row$attendance, " people<br/>",
        row$type, "<br/>",
        "Expected ", row$expected,
        " (attendance ratio: ", row$attendance_ratio, ")"
      )
    }

    div(style = style, HTML(html))
  })

  # Render the table
  output$table <- DT::renderDataTable({
    talks_data_filtered()
  }, rownames = FALSE)

  output$download <- downloadHandler(
    filename = "user2017data.csv",
    content = function(file) {
      write.csv(talks_data_filtered(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
