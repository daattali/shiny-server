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
          textInput("name", "Name", "testg"),
          sliderInput("r_num_years", "Number of years using R", 0, 22, 1, ticks = FALSE),
          checkboxInput("used_shiny", "I've built a Shiny app in R", FALSE),
          selectInput("os_type", "Opearting system used most frequently",
                      c("", "Windows", "Mac", "Linux")),
          textInput("favourite_pkg", "Favourite R package"),
          actionButton("submit", "Submit", class = "btn-primary"),
          
          # hidden input field tracking the timestamp of the submission
          shinyjs::hidden(textInput("timestamp", "", get_time_epoch()))
        ),
        
        tabPanel(
          title = "View responses", id = "viewTab", value = "viewTab",
          br(),
          downloadButton("downloadBtn", "Download responses"), br(), br(),
          tags$a(id = "toggleView", "Show/hide responses", href = "#"),
          dataTableOutput("responsesTable")
        )
      )
    )
  )
))