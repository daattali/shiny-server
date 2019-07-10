library(plotly)
source("code-plot_git.R")

share <- list(
  title = "Visualizing when I'm most productive during the day",
  url = "https://daattali.com/shiny/visualize-git-commits-time/",
  image = "https://daattali.com/shiny/visualize-git-commits-time/dean-git-plot.png",
  description = "Analyzing my (and others') git activity",
  twitter_user = "daattali"
)

ui <- fixedPage(
  title = "Visualizing when I'm most productive during the day",
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(href = "app.css", rel = "stylesheet"),
    
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
  fixedRow(column(12,
    div(id = "titleSection",
      h1(strong("Visualizing when I'm most productive during the day")),
      h2(id = "subtitle", "Analyzing my (and others') git activity"),
      strong(p(id = "author",
               a(href="http://deanattali.com", "Dean Attali"), "2016",
               HTML("&bull;"),
               a(href = "https://daattali.com/shiny/", "More apps"), "by Dean"))
    ),
    div(id = "loading-content", h1("Loading... ", icon("spinner", class="fa-spin")),
        p("Sorry, this does take a few seconds!")),
    tabsetPanel(
      id = "mainNav",
      tabPanel(
        "Analyze",
        value = "analyze",
        div(
          id = "TOC",
          h4("Navigation"),
          tags$ul(
            tags$li(strong(actionLink("goToExplore", "Interactively explore more data"))),
            tags$li(a(href="#my-work-hours-since-first-learning-r", "My work hours since first learning R")),
            tags$li(a(href="#my-work-hours-in-the-past-6-months", "My work hours in the past 6 months")),
            tags$li(a(href="#adding-marginal-density-plots-to-see-exactly-what-times-are-alivedead", "Adding marginal density plots to see exactly what times are alive/dead")),
            tags$li(a(href="#hows-my-ex-supervisor-jenny-bryan-doing", "How's my (ex) supervisor Jenny Bryan doing?")),
            tags$li(a(href="#and-the-grand-finale-the-r-master-hadley", "And the grand finale: the R master Hadley")),
            tags$li(a(href="#working-on-weekends", "Working on weekends"))
          )
        ),
        br(), actionButton("goToExplore2", "Interactively explore", class = "btn-success btn-lg center-block"), br(),
        includeHTML(path = "analysis.html")
      ), 
      tabPanel(
        "Explore",
        value = "explore",
        div(
          id = "explore-inputs",
          div(
            selectInput("user", "Select a person to visualize their data", choices = c(
              "Dean Attali" = "dean",
              "Jenny Bryan" = "jenny",
              "Hadley Wickham" = "hadley",
              "Yihui Xie" = "yihui",
              "Jim Hester" = "jim",
              "====================" = "none",
              "Upload my own data file" = "custom"
            )),
            dateRangeInput("dates", "Display data between these dates",
                           "2014-09-01", "2016-09-01", format = "M d, yyyy")
          ),
          div(
            conditionalPanel("input.user == 'custom'",
              fileInput("logfile",
                        div("Data file",
                            p(class="custom-inst",
                                 "Please read the instructions at the bottom of the page on how to use your own data."))
              )
            )
          ),
          div(
            selectInput("xvar", "X axis variable", c("date", "repo", "time", "weekday")),
            selectInput("yvar", "Y axis variable", c("date", "repo", "time", "weekday"), "time")
          ),
          plotly::plotlyOutput("plotly", height = "600px"),
          br(),
          conditionalPanel("input.user == 'custom'",
            p(class = "custom-inst",
              "In order to use your own data, you must run the following function (", code("create_git_log_file()"), ") yourself",
              "and upload the resulting file. I cannot do it from this app because it's slow and will",
              "fill up my server with too much junk."),
            pre(id = "custom-script", includeText("code-create_git_log_file.R"))
          )
        )
      ),
      tabPanel(
        "Code",
        p("If you want to replicate these kinds of plots, here is the exact R code that was used to",
          "generate all the plots. The two functions you need to call are", code("create_git_log_file()"), "to",
          "generate the data file, and then", code("plot_git_commits()"), "to visualize the data.",
          br(), br(),
          "I know this code isn't amazing and could be optimized some more (I especially don't love that",
          "I'm using system calls) but I wanted to get this out ASAP because I have real projects I need to work on :)"),
        pre(includeText("code-plot_git.R"))
      )
    )
  ))
)

server <- function(input, output, session) {
  shinyjs::hide("loading-content", anim = TRUE, animType = "fade")
  
  observeEvent(c(input$goToExplore, input$goToExplore2), {
    updateTabsetPanel(session, "mainNav", "explore")
  }, ignoreInit = TRUE)

  values <- reactiveValues(logfile = NULL)
  
  observeEvent(c(input$user, input$logfile), {
    if (input$user == "none") {
      return()
    }
    if (input$user == "custom") {
      if (!is.null(input$logfile)) {
        values$logfile <- input$logfile$datapath[1]
      }
    } else {
      values$logfile <- paste0("data/", input$user, "-projects.csv")
    }
  })

  output$plotly <- plotly::renderPlotly({
    plot_git_commits(values$logfile, input$dates[1], input$dates[2],
                     plot_type = "plotly", x = input$xvar, y = input$yvar)
  })
}

shinyApp(ui, server)
