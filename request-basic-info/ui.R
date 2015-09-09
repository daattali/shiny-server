# Dean Attali 2014-2015

# This is the ui portion of a shiny app that "mimics" a Google form, in the
# sense that it lets users enter some predefined fields and saves the answer
# as a .csv file.  Every submission is saved in its own file, so the results
# must be concatenated together at the end

library(shiny)
library(shinyjs)
# required library: DT

shinyUI(fluidPage(

  useShinyjs(),

  # add CSS
  tags$head(includeCSS(file.path('www', 'style.css'))),

  title = "STAT 545 Student Info",
  h2(tags$strong("STAT 545 Student Info")),

  # admin panel will only be shown to users with sufficient privileges
  uiOutput("adminPanel"),

  div(
    id = "form",

    # form instructions
    p("In order to facilitate communicating with students of",
      a(href = "http://stat545-ubc.github.io/", "STAT 545/547M"),
      "it would help us if you provide us with some basic information.",
      "Filling out this form is not mandatory."
    ),

    # form fields
    textInput("firstName", labelMandatory("First name (according to UBC)")),
    textInput("lastName", labelMandatory("Last name (according to UBC)")),
    textInput("studentNum", labelMandatory("Last 4 digits of UBC student number")),
    textInput("email", "Preferred email"),
    selectInput("osType", "Operating system",
                choices = c("", "Windows 7", "Windows 8", "Windows 10",
                            "Mac", "Linux", "Other"),
                selected = ""),
    textInput("gitName", "GitHub username"),
    textInput("twitterName", "Twitter username"),
    actionButton("submitBtn", "Submit", class = "btn-primary btn-lg"),
    hidden(
      div(id = "error",
          br(),
          tags$b("Error: "),
          span(id = "errmsg")
      )
    )
  ),
  hidden(
    div(
      id = "thanksMsg",
      h3("Thank you, your response was submitted")
    )
  ),

  # author info
  shiny::hr(),
  em(
    span("Created by "),
    a("Dean Attali", href = "http://deanattali.com"),
    br(), br()
  )
))
