# Dean Attali
# September 2014

# This is the ui portion of a shiny app that "mimics" a Google form, in the
# sense that it lets users enter some predefined fields and saves the answer
# as a .csv file.  Every submission is saved in its own file, so the results
# must be concatenated together at the end

source("helpers.R")

library(shiny)

shinyUI(fluidPage(
  
  # add external JS and CSS
  singleton(
    tags$head(includeScript(file.path('www', 'message-handler.js')),
              includeCSS(file.path('www', 'style.css'))
    )
  ),

  title = "STAT545 Basic Student Info",
  h2("STAT545 Basic Student Info"),
  
  # admin panel will only be shown to users with sufficient privileges
  uiOutput("adminPanel"),
  
  conditionalPanel(
    # only show this form before the form is submitted
    condition = "!output.formSubmitted",
    
    # form instructions
    p("In order to facilitate communicating with you guys, it would help us
      tremendously if you could provide us with some basic information."),
    p("You don't have to submit this form, but we would REALLY appreciate it if you did."),
    p("The fields marked with * are mandatory (if you choose to participate at all),
      and the rest are optional but highly recommended."),
    strong("Help us help you :)"),
    shiny::hr(),
    
    # form fields
    textInput(inputId = "firstName", label = "First name (according to UBC) *"),
    textInput(inputId = "lastName", label = "Last name (according to UBC) *"),
    textInput(inputId = "studentNum",
              label = "Last 4 digits of UBC student number *"),
    uiOutput(outputId = "studentNumErr"),
    textInput(inputId = "email", label = "Preferred email"),
    selectInput(inputId = "osType", label = "Operating system",
                choices = c("", "Windows 7", "Windows 8", "Mac", "Linux",
                            "Other"),
                selected = ""),  
    textInput(inputId = "gitName", label = "GitHub username"),
    uiOutput("gitTest"),
    textInput(inputId = "twitterName", label = "Twitter username"),
    uiOutput("twitterTest"),
    br(),
    actionButton(inputId = "submitBtn", label = "Submit")
    
    # the following lines use a confirmation dialog before submitting
    #modalTriggerButton("submitBtn", "#submitConfirmDlg", "Submit"),
    #modalDialog(id="submitConfirmDlg", body = "Are you sure you want to submit?",
    #            footer=list(
    #  modalTriggerButton("submitConfirmDlg", "#submitConfirmDlg", "Submit"),
    #  tags$button(type = "button", class = "btn btn-primary", 'data-dismiss' = "modal", "Cancel")
    #))
  ),
  
  conditionalPanel(
    # thank you screen after form is submitted
    condition = "output.formSubmitted",
    
    h3(textOutput("thanksName"))
  ),
  
  # author info
  shiny::hr(),
  em(
    span("Created by "),
    a("Dean Attali", href = "http://deanattali.com"),
    span(", Sept 2014"),
    br(), br()
  )
))
