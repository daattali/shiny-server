# Dean Attali
# September 2014

# This is the server portion of a shiny app that mimics a Google form that will
# allow students to submit peer review marks

library(shiny)
library(digest) # digest() Create hash function digests for R objects

# output location
formName <- "2014-peer-review-marks"
resultsDir <- file.path("results", formName)
dir.create(resultsDir, recursive = TRUE, showWarnings = FALSE)

# input - get list of students
classList <- getClassList()

# names of users that have admin power and can view all submitted responses
adminUsers <- c("staff", "admin")

# mandatory fields in the form
fieldsMandatory <- c(
  "assignmentNum",
  "reviewer",
  "reviewee"
)

# all fields in the form
fieldsAll <- c(
  fieldsMandatory,
  "overallMark",
  "overallComment",
  "timestamp"
)

# allowable options for fields
assignmentInputChoices <- sprintf("%02d", 1:6)
## this changes the default assignment the peer review is for
assignmentInputDefault <- assignmentInputChoices[6]

# add all the rubric items to the fields that need to be submitted
rubricItems <- list(
  "codingStyle" = "Coding style",
  "codingStrategy" = "Coding strategy",
  "presentationGraphs" = "Presentation: graphs",
  "presentationTables" = "Presentation: tables",
  "mastery" = "Achievement, mastery, cleverness, creativity",
  "compliance" = "Ease of access, compliance with course conventions"
)
fieldsRubric <- paste(rep(names(rubricItems), each = 2), c("Mark", "Comment"), sep="")
fieldsAll <- c(fieldsAll, fieldsRubric)

shinyServer(function(input, output, session) {
  
  ### enable/disable the form
  output$formActive <- reactive({
    isFormActive()
  })
  outputOptions(output, 'formActive', suspendWhenHidden = FALSE)    
  
  
  ##########################################
  ##### Admin panel#####  
  
  # if logged in user is admin, show a table aggregating all the data
  isAdmin <- reactive({
    is.null(session$user) || session$user %in% adminUsers
  })
  infoTable <- reactive({
    if (!isAdmin()) return(NULL)
    
    # dependency on submit button so that a new response will get shown right away
    input$submitBtn
    
    ### This code chunk reads all submitted responses and will have to change
    ### based on where we store persistent data
    infoFiles <- list.files(resultsDir)
    allInfo <- lapply(infoFiles, function(x) {
      read.csv(file.path(resultsDir, x))
    })
    ### End of reading data
    
    allInfo <- data.frame(do.call(rbind, allInfo))
    if (nrow(allInfo) == 0) {
      allInfo <- data.frame(matrix(nrow = 1, ncol = length(fieldsAll),
                                   dimnames = list(list(), fieldsAll)))
    }
    return(allInfo)
  })
  output$adminPanel <- renderUI({
    if (!isAdmin()) return(NULL)
    
    div(id = "adminPanelInner",
        h3("This table is only visible to admins",
           class = "inlineb"),
        a("Show/Hide",
          href = "javascript:toggleVisibility('adminTableSection');",
          class = "left-space"),
        div(id = "adminTableSection",
            dataTableOutput("adminTable"),
            downloadButton("downloadSummary", "Download results")
        )
    )
  })
  output$downloadSummary <- downloadHandler(
    filename = function() { 
      paste0(formName, "_", getFormattedTimestamp(), '.csv')
    },
    content = function(file) {
      write.csv(infoTable(), file, row.names = FALSE)
    }
  )
  output$adminTable <- renderDataTable({
    infoTable()
  })
  
  ##### End admin panel #####
  ##########################################  
  
  # build the form UI 
  output$assignmentNumUi <- renderUI({
    selectInput(inputId = "assignmentNum",
                label = "Homework #",
                choices = assignmentInputChoices,
                selected = assignmentInputDefault)
  })
  output$reviewerUi <- renderUI({
    selectInput(inputId = "reviewer",
                label = "My name",
                choices = classList,
                selected = "")
  })
  output$revieweeUi <- renderUI({
    input$submitAnotherBtn  # reset when form is submitted
    
    selectInput(inputId = "reviewee", label = "Person being marked",
                choices = classList,
                selected = "")
  })  
  
  # loop through the rubric items and make input fields
  output$rubricFieldsInputs <- renderUI({
    input$submitAnotherBtn  # reset when form is submitted
      
    div(
      # row for headers
      fluidRow(
        column(4,
          h4("Item", class = "right")), 
        column(4,
          h4("Mark")),
        column(4,
          h4("Comments"))
      ),
      
      # row per rubric item
      lapply(names(rubricItems), function(i) {
        fluidRow(
          column(4,
            p(rubricItems[[i]], class = "right")
          ),
          column(4,
            selectInput(inputId = paste0(i, "Mark"),
                        label = "",
                        choices = c("check minus", "check", "check plus", "NA"),
                        selected = "check")),
          column(4,
            textInput(inputId = paste0(i, "Comment"), label = "")
          )
        )
      }),
      
      # overall mark
      fluidRow(
        column(4,
          p(strong("Overall mark"), class = "right")),
        column(4,
          selectInput(inputId = "overallMark", label = "",
                      choices = c("nothing to mark", "check minus", "check", "check plus"))),
        column(4,
          textInput(inputId = "overallComment", label = ""))
      )
    )
  })
  
  # only enable the Submit button when the mandatory fields are validated
  observe({
    fieldsFilled <-
      sapply(fieldsMandatory, function(x) !is.null(input[[x]]) && input[[x]] != "")
    fieldsFilled <- all(fieldsFilled)
    
    if (fieldsFilled && validateForm(input)) {
      session$sendCustomMessage(type = "enableBtn", list(id = "submitBtn"))
    } else {
      session$sendCustomMessage(type = "disableBtn", list(id = "submitBtn"))
    }
  })
  
  # show an error message if necessary
  output$errorMsg <- renderUI({
    if (!is.null(c(input$reviewer, input$reviewee)) &&
          all(c(input$reviewer, input$reviewee) != "")) {
      if (!validateForm(input)) {
        span("You cannot mark your own assignment!", class = "error")
      }
    }
  })
  
  # submit the form  
  observe({
    if (input$submitBtn < 1) return(NULL)
    
    updateTextInput(session, "timestamp", value = getEpochTime())
    
    # read the info into a dataframe
    isolate(
      formInfo <- t(sapply(fieldsAll, function(x) x = input[[x]]))
    )
    
    # generate a file name based on timestamp, user name, and form contents
    isolate(
      fileName <- paste0(
        paste(
          getFormattedTimestamp(),
          input$assignmentNum,
          digest(formInfo, algo = "md5"),
          sep = "_"
        ),
        ".csv"
      )
    )
    
    # write out the results
    ### This code chunk writes a response and will have to change
    ### based on where we store persistent data
    write.csv(x = formInfo, file = file.path(resultsDir, fileName),
              row.names = FALSE)
    ### End of writing data
    
    # indicate the form was submitted to show a thank you page so that the
    # user knows they're done
    output$formSubmitted <- reactive({ TRUE })
  })
  
  # the name to show on the confirmation page
  output$thanksMsg <- renderText({
    paste0("Thank you ", input$reviewer, "!")
  })
  
  # we need to have a quasi-variable flag to indicate when the form was submitted
  output$formSubmitted <- reactive({
    FALSE
  })
  outputOptions(output, 'formSubmitted', suspendWhenHidden = FALSE)  
  
  # reset the form to submit another response
  observe({
    if (input$submitAnotherBtn < 1) return(NULL)
      
    # indicate the form was not submitted
    output$formSubmitted <- reactive({ FALSE })    
  })
  
  # ------------ show form content and hide loading message
  session$sendCustomMessage(type = "hide",
                            message = list(id = "loadingContent"))
  session$sendCustomMessage(type = "show",
                            message = list(id = "allContent"))  
  
})
