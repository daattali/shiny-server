library(shiny)
library(magrittr)

source("storage.R")
source("helpers.R")

shinyServer(function(input, output, session) {
  # Give an initial value to the timestamp field
  updateTextInput(session, "timestamp", value = get_time_epoch())
  
  # Enable the Submit button when all mandatory fields are filled out
  observe({
    fields_filled <-
      fields_mandatory %>%
      sapply(function(x) !is.null(input[[x]]) && input[[x]] != "") %>%
      all
      
    shinyjs::toggleState("submit", fields_filled)
  })
  
  # Gather all the form inputs
  form_data <- reactive({
    sapply(fields_all, function(x) x = input[[x]])
  })
  
  # When the Submit button is clicked 
  observeEvent(input$submit, {
    # Update the timestamp field to be the current time
    updateTextInput(session, "timestamp", value = get_time_epoch())
    
    # User-experience stuff
    shinyjs::disable("submit")
    shinyjs::show("submitMsg")
    shinyjs::hide("error")
    on.exit({
      shinyjs::enable("submit")
      shinyjs::hide("submitMsg")
    })
    
    # Save the data (show an error message in case of error)
    tryCatch({
      save_data(form_data(), input$storage)
      shinyjs::reset("form")
      updateTabsetPanel(session, "mainTabs", "viewTab")
    },
    error = function(err) {
      shinyjs::html("errorMsg", err$message)
      shinyjs::show(id = "error", anim = TRUE, animType = "fade")      
      shinyjs::logjs(err)
    })
  })

  # Update the responses whenever a new submission is made or the
  # storage type is changed
  responses_data <- reactive({
    input$submit
    load_data(input$storage)
  })
  
  # Show the responses in a table
  output$responsesTable <- DT::renderDataTable(
    DT::datatable(
      responses_data(),
      rownames = FALSE,
      options = list(searching = FALSE, lengthChange = FALSE, scrollX = TRUE)
    )
  )

  # Allow user to download responses
  output$downloadBtn <- downloadHandler(
    filename = function() { 
      paste0(TABLE_NAME, "_", input$storage, "_", get_time_human(), '.csv')
    },
    content = function(file) {
      write.csv(responses_data(), file, row.names = FALSE)
    }
  )
  
  # Show the code to save/load using current storage type
  observe({
    fxn_save <- input$storage %>% get_save_fxn
    fxn_save_body <- fxn_save %>% body %>% format %>% paste(collapse = "\n")
    fxn_save_head <- paste0(fxn_save, " <- function(data)")
    fxn_save_code <- paste(fxn_save_head, fxn_save_body)
    shinyjs::html("codeSave", fxn_save_code)

    fxn_load <- input$storage %>% get_load_fxn
    fxn_load_body <- fxn_load %>% body %>% format %>% paste(collapse = "\n")
    fxn_load_head <- paste0(fxn_load, " <- function()")
    fxn_load_code <- paste(fxn_load_head, fxn_load_body)
    shinyjs::html("codeLoad", fxn_load_code)
  })
})
