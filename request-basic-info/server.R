# Dean Attali
# September 2014

# This is the server portion of a shiny app that "mimics" a Google form, in the
# sense that it lets users enter some predefined fields and saves the answer
# as a .csv file.  Every submission is saved in its own file, so the results
# must be concatenated together at the end

library(shiny)
library(digest)

formName <- "2014-fall-basic-info"
resultsDir <- file.path("data", formName)
dir.create(resultsDir, recursive = TRUE, showWarnings = FALSE)

# names of users that have admin power and can view all submitted responses
adminUsers <- c("staff", "admin")

# logic for saving a response
saveData <- function(data) {
  # Create a unique file name
  fileName <- sprintf("%s_%s_%s_%s.csv",
                      humanTime(),
                      data['lastName'],
                      data['firstName'],
                      digest(data))

  data <- t(data)
  write.csv(
    x = data,
    file = file.path(resultsDir, fileName),
    row.names = FALSE, quote = TRUE
  )
}

# logic for retrieving responses
loadData <- function() {
  files <- list.files(file.path(resultsDir), full.names = TRUE)
  data <- lapply(files, read.csv, stringsAsFactors = FALSE)
  data <- do.call(rbind, data)
  data
}

shinyServer(function(input, output, session) {

  # Enable the Submit button when all mandatory fields are filled out
  observe({

    mandatoryFilled <-
      vapply(fieldsMandatory,
             function(x) {
               !is.null(input[[x]]) && input[[x]] != ""
             },
             logical(1))
    mandatoryFilled <- all(mandatoryFilled)

    toggleState(id = "submitBtn", condition = mandatoryFilled)
  })

  validateData <- function() {
    if (!validateStudentNum(input$studentNum)) {
      stop("Student number must be 4 digits")
    }
  }

  # Gather all the form inputs
  formData <- reactive({
    data <- sapply(fieldsAll, function(x) input[[x]])
    data
  })

  # When the Submit button is clicked, submit the response
  observeEvent(input$submitBtn, {

    # User-experience stuff
    disable("submitBtn")
    hide("error")

    # Save the data (show an error message in case of error)
    tryCatch({
      validateData()
      saveData(formData())
      hide("form")
      show("thanksMsg")
    },
    error = function(err) {
      html("errmsg", err$message)
      show(id = "error", anim = TRUE, animType = "fade")
    },
    finally = {
      enable("submitBtn")
    })
  })

  # -------------------------
  # Admin panel
  # -------------------------

  # if logged in user is admin, show a table aggregating all the data
  isAdmin <- reactive({
    !is.null(session$user) && session$user %in% adminUsers
  })

  adminTable <- reactive({
    input$submitBtn
    loadData()
  })

  output$adminPanel <- renderUI({
    if (isAdmin()) return(NULL)

    tagList(
      a(id = "toggleAdmin", "Show/hide admin panel", href = "#"),
      div(
        id = "adminPanelInner",
        h2("Submissions (only visible to admins)"),
        downloadButton("downloadBtn", "Download data"), br(), br(),
        DT::dataTableOutput("adminTable")
      )
    )
  })

  # Allow admins to download responses
  output$downloadBtn <- downloadHandler(
    filename = function() {
      sprintf("%s_%s.csv", formName, humanTime())
    },
    content = function(file) {
      write.csv(adminTable(), file, row.names = FALSE)
    }
  )

  # Show the admin table
  output$adminTable <- DT::renderDataTable(
    adminTable(),
    rownames = FALSE,
    options = list(searching = FALSE, lengthChange = FALSE)
  )

  observe({
    onclick("toggleAdmin", toggle("adminPanelInner"))
  })
})
