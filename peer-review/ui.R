# Dean Attali
# September 2014

# This is the ui portion of a shiny app that mimics a Google form that will
# allow students to submit peer review marks

source("helpers.R")

library(shiny)

shinyUI(fluidPage( 
  
  # add external JS and CSS
  singleton(
    tags$head(includeScript(file.path('www', 'message-handler.js')),
              includeScript(file.path('www', 'helper-script.js')),
              includeCSS(file.path('www', 'style.css'))
    )
  ),
  
  title = "STAT545 Peer Review", ## TO DO? change to 547
  h2("STAT545 Peer Review"),
  
  # show a loading message initially
  div(
    id = "loadingContent",
    h3("Loading...")
  ),
  
  # all form content goes here, and is hidden initially until the form fully loads
  div(id = "allContent", class = " hideme",
  
  # admin panel will only be shown to users with sufficient privileges
  uiOutput("adminPanel"),
  
  conditionalPanel(
    # if the form is not active, show a message
    condition = "!output.formActive",
    h4("The form is now closed, submissions are no longer accepted.")
  ),
  
  conditionalPanel(
    # form is active - show it
    condition = "output.formActive",
    
    conditionalPanel(
      # only show this form before the form is submitted
      condition = "!output.formSubmitted",
      
      strong("Please refer to the rubric at ",
             a("http://stat545-ubc.github.io/peer-review01_marking-rubric.html",
               href = "http://stat545-ubc.github.io/peer-review01_marking-rubric.html",
               target = "_blank")
      ),
      shiny::hr(),
      
      # form fields
      fluidRow(column(4,
        wellPanel(
          uiOutput("assignmentNumUi"),
          uiOutput("reviewerUi"),
          uiOutput("revieweeUi"),
          uiOutput("errorMsg"),
          div(
            # hidden input field tracking the timestamp of the submission
            textInput("timestamp", "", getEpochTime()),
            style = "display: none;"
          )
        )
      )),
      
      h2("Rubric"),
      uiOutput("rubricFieldsInputs"),
      
      br(),
      actionButton(inputId = "submitBtn", label = "Submit")
    ),
    
    conditionalPanel(
      # thank you screen after form is submitted
      "output.formSubmitted",
      
      h3(textOutput("thanksMsg")),
      actionButton(inputId = "submitAnotherBtn", label = "Submit another peer review")
    )
  ),
  
  # author info
  shiny::hr(),
  em(
    span("Created by "),
    a("Dean Attali", href = "mailto:daattali@gmail.com"),
    span(", Sept 2014"),
    br(), br()
  )
)))
