# Dean Attali
# September 2014

# This is the server portion of a shiny app that "mimics" a Google form, in the
# sense that it lets users enter some predefined fields and saves the answer
# as a .csv file.  Every submission is saved in its own file, so the results
# must be concatenated together at the end

library(shiny)
library(digest) # digest() Create hash function digests for R objects

formName <- "2014-fall-basic-info"
resultsDir <- file.path("data", formName)
dir.create(resultsDir, recursive = TRUE, showWarnings = FALSE)

# names of the fields on the form we want to save
fieldNames <- c("firstName",
                "lastName",
                "studentNum",
                "email",
                "gitName",
                "twitterName",
                "osType"
                )

# names of users that have admin power and can view all submitted responses
adminUsers <- c("staff", "admin")

shinyServer(function(input, output, session) {

  ##########################################
  ##### Admin panel#####
  
  # if logged in user is admin, show a table aggregating all the data
  isAdmin <- reactive({
    is.null(session$user) || session$user %in% adminUsers
  })
  infoTable <- reactive({
    if (!isAdmin()) return(NULL)
    
    ### This code chunk reads all submitted responses and will have to change
    ### based on where we store persistent data
    infoFiles <- list.files(resultsDir)
    allInfo <- lapply(infoFiles, function(x) {
      read.csv(file.path(resultsDir, x))
    })
    ### End of reading data
    
    #allInfo <- data.frame(rbind_all(allInfo)) # dplyr version
    #allInfo <- data.frame(rbindlist(allInfo)) # data.table version
    allInfo <- data.frame(do.call(rbind, allInfo))
    if (nrow(allInfo) == 0) {
      allInfo <- data.frame(matrix(nrow = 1, ncol = length(fieldNames),
                                   dimnames = list(list(), fieldNames)))
    }
    return(allInfo)
  })
  output$adminPanel <- renderUI({
    if (!isAdmin()) return(NULL)
    
    div(id = "adminPanelInner",
      h3("This table is only visible to admins",
         style = "display: inline-block;"),
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
  
  # only enable the Submit button when the mandatory fields are validated
  observe({
    if (input$firstName == '' || input$lastName == '' ||
          input$studentNum == '' ||
          !validateStudentNum(input$studentNum)) {
      session$sendCustomMessage(type = "disableBtn", list(id = "submitBtn"))
    } else {
      session$sendCustomMessage(type = "enableBtn", list(id = "submitBtn"))
    }
  })
  
  # the name to show in the Thank you confirmation page
  output$thanksName <- renderText({
    paste0("Thank you ", input$firstName, "!")
  })
  
  # we need to have a quasi-variable flag to indicate when the form was submitted
  output$formSubmitted <- reactive({
    FALSE
  })
  outputOptions(output, 'formSubmitted', suspendWhenHidden = FALSE)

  # show an error beside the student number when the regex (4 digits) fails
  output$studentNumErr <- renderUI({
    if (input$studentNum != '') {
      if(validateStudentNum(input$studentNum)) return(NULL)
      span("Student number must be 4 digits", class = "left-space error")
    }
  })
  
  # show a link to test the GitHub name
  output$gitTest <- renderUI({
    if (input$gitName == '') return(NULL)
    a("Click here to test GitHub name", target = "_blank",
      href = paste0("https://github.com/", input$gitName),
      class = "left-space")
  })
  
  # show a link to test the Twitter name
  output$twitterTest <- renderUI({
    if (input$twitterName == '') return(NULL)
    a("Click here to test Twitter name", target = "_blank",
      href = paste0("https://twitter.com/", input$twitterName),
      class = "left-space")
  })  

  # submit the form  
  observe({
    #if (input$submitConfirmDlg < 1) return(NULL)
    if (input$submitBtn < 1) return(NULL)
        
    # read the info into a dataframe
    isolate(
      infoList <- t(sapply(fieldNames, function(x) x = input[[x]]))
    )
    
    # generate a file name based on timestamp, user name, and form contents
    isolate(
      fileName <- paste0(
        paste(
          getFormattedTimestamp(),
          input$lastName,
          input$firstName,
          digest(infoList, algo = "md5"),
          sep = "_"
        ),
        ".csv"
      )
    )
    
    # write out the results
    ### This code chunk writes a response and will have to change
    ### based on where we store persistent data
    write.csv(x = infoList, file = file.path(resultsDir, fileName),
              row.names = FALSE)
    ### End of writing data
    
    # indicate the the form was submitted to show a thank you page so that the
    # user knows they're done
    output$formSubmitted <- reactive({ TRUE })
  })
  
})
