library(shiny)

shinyUI(fluidPage(
  shinyjs::useShinyjs(),
  
  titlePanel("Mock Google Form and store persistent data"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("storage", "Storage type", storage_types)
    ),
    
    mainPanel(
      tabsetPanel(
        id = "mainTabs", type = "tabs",
        
        tabPanel(
          title = "Submit form", id = "submitTab", value = "submitTab",
          
          br(),
          textInput("name", "Name", ""),
          sliderInput("r_num_years", "Number of years using R", 0, 22, 1, ticks = FALSE),
          checkboxInput("used_shiny", "I've built a Shiny app in R", FALSE),
          selectInput("os_type", "Operating system used most frequently",
                      c("", "Windows", "Mac", "Linux")),
          textInput("favourite_pkg", "Favourite R package"),
          actionButton("submit", "Submit", class = "btn-primary"),
          
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
          shinyjs::hidden(textInput("timestamp", "", get_time_epoch()))
        ),
        
        tabPanel(
          title = "View responses", id = "viewTab", value = "viewTab",
          br(),
          downloadButton("downloadBtn", "Download responses"), br(), br(),
          tags$a(id = "toggleView", "Show/hide responses", href = "javascript:void(0);"),
          dataTableOutput("responsesTable")
        ),
        
        tabPanel(
          title = "Code to save/load data", id = "codeTab", value = "codeTab",
          
          br(),
          tags$b("Code to save new responses:"),
          tags$pre(id = "codeSave"),
          tags$b("Code to read all responses:"),
          tags$pre(id = "codeLoad")
        ),
        
        tabPanel(
          title = "Notes about selected storage type"
        )
      )
    )
  )
))