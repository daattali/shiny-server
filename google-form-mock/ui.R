library(shiny)

storage_types <- c(
  "Text file (local)" = "flatfile",
  "SQLite (local)" = "sqlite",
  "MySQL database (local or remote)" = "mysql",
  "MongoDB database (local or remote)" = "mongodb",
  "Google Sheets (remote)" = "gsheets",
  "Amazon Simple Storage Service (S3) (remote)" = "s3"
)

shinyUI(fluidPage(
  shinyjs::useShinyjs(),
  
  titlePanel("Mock Google Form and store persistent data"),
  
  # Select storage type and show a description about it
  sidebarLayout(
    sidebarPanel(
      selectInput("storage", "Select storage type", storage_types),
      lapply(
        storage_types,
        function(x) {
          conditionalPanel(
            sprintf("input.storage == '%s'", x),
            includeMarkdown(file.path("text", sprintf("%s.md", x)))
          )
        }
      )
    ),
    
    mainPanel(
      tabsetPanel(
        id = "mainTabs", type = "tabs",
        
        # Build the form
        tabPanel(
          title = "Submit form", id = "submitTab", value = "submitTab",
          
          br(),
          div(id = "form",
            textInput("name", "Name", ""),
            sliderInput("r_num_years", "Number of years using R", 0, 22, 1, ticks = FALSE),
            checkboxInput("used_shiny", "I've built a Shiny app in R", FALSE),
            selectInput("os_type", "Operating system used most frequently",
                        c("", "Windows", "Mac", "Linux")),
            textInput("favourite_pkg", "Favourite R package"),
            actionButton("submit", "Submit", class = "btn-primary")
          ),
          
          shinyjs::hidden(
            span(id = "submitMsg", "Submitting...", style = "margin-left: 15px;")
          ),
          
          shinyjs::hidden(
            div(id = "error",
                div(br(), tags$b("Error: "), span(id = "errorMsg")),
                style = "color: red;"
            )
          ),          
          
          # hidden input field tracking the timestamp of the submission
          shinyjs::hidden(textInput("timestamp", ""))
        ),
        
        tabPanel(
          title = "View responses", id = "viewTab", value = "viewTab",
          br(),
          downloadButton("downloadBtn", "Download responses"), br(), br(),
          tags$a(id = "toggleView", "Show/hide responses", href = "javascript:void(0);"),
          DT::dataTableOutput("responsesTable")
        ),
        
        tabPanel(
          title = "Code to save/load data", id = "codeTab", value = "codeTab",
          
          br(),
          tags$b("Code to save new responses:"),
          tags$pre(id = "codeSave"),
          tags$b("Code to read all responses:"),
          tags$pre(id = "codeLoad")
        )
      )
    )
  )
))