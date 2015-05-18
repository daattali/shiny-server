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
    save_data(data, input$storage)
  })
  
  shinyjs::onclick("toggleView",
                   shinyjs::toggle(id = "responsesTable", anim = TRUE))
  
  responses_data <- reactive({
    
    input$storage
    input$mainTabs

    if (input$mainTabs != "viewTab") {
      return()
    }
    
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
})