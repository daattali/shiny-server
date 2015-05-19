library(shiny)
library(magrittr)
source("storage.R")

shinyServer(function(input, output, session) {
  
  # enable the Submit button when all mandatory fields are filled out
  observe({
    fields_filled <-
      fields_mandatory %>%
      sapply(function(x) !is.null(input[[x]]) && input[[x]] != "") %>%
      all
      
    shinyjs::toggleState("submit", fields_filled)
  })
  
  form_data <- reactive({
    sapply(fields_all, function(x) x = input[[x]])
  })
  
  observeEvent(input$submit, {
    updateTextInput(session, "timestamp", value = get_time_epoch())
    data <- form_data()
    shinyjs::disable("submit")
    shinyjs::show("submitMsg")
    shinyjs::hide("error")
    
    tryCatch({
      save_data(data, input$storage)
      updateTabsetPanel(session, "mainTabs", "viewTab")
    },
    error = function(err) {
      shinyjs::text("errorMsg", err$message)
      shinyjs::show(id = "error", anim = TRUE, animType = "fade")      
      shinyjs::logjs(err)
    }, finally = {
      shinyjs::enable("submit")
      shinyjs::hide("submitMsg")
    })
  })
  
  shinyjs::onclick("toggleView",
                   shinyjs::toggle(id = "responsesTable", anim = TRUE))
  
  responses_data <- reactive({
    input$submit
    load_data(input$storage)
  })
  
  output$responsesTable <- renderDataTable(
    responses_data(),
    options = list(searching = FALSE, lengthChange = FALSE)
  )

  output$downloadBtn <- downloadHandler(
    filename = function() { 
      paste0("google-form-mock_", input$storage, "_", get_time_human(), '.csv')
    },
    content = function(file) {
      write.csv(responses_data(), file, row.names = FALSE)
    }
  )
  
  observe({
    fxn_save <- input$storage %>% get_save_fxn
    fxn_save_body <- fxn_save %>% body %>% format %>% paste(collapse = "\n")
    fxn_save_head <- paste0(fxn_save, " <- function(data)")
    fxn_save_code <- paste(fxn_save_head, fxn_save_body)
    shinyjs::text("codeSave", fxn_save_code)

    fxn_save <- input$storage %>% get_save_fxn
    fxn_save_body <- fxn_save %>% body %>% format %>% paste(collapse = "\n")
    fxn_save_head <- paste0(fxn_save, " <- function(data)")
    fxn_save_code <- paste(fxn_save_head, fxn_save_body)
    shinyjs::text("codeLoad", fxn_save_code)
  })
})