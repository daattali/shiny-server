# Dean Attali
# November 21 2014

# This is the ui portion of a shiny app shows cancer data in the United States

library(shiny)
library(shinyjs)

fluidPage(
  useShinyjs(),
  
	# add custom JS and CSS
	singleton(
		tags$head(includeScript(file.path('www', 'message-handler.js')),
							includeScript(file.path('www', 'helper-script.js')),
							includeCSS(file.path('www', 'style.css'))
		)
	),
	
	# enclose the header in its own section to style it nicer
	div(id = "headerSection",
		titlePanel("Cancer data in the United States"),
	
		# author info
		em(
			span("Created by "),
			a("Dean Attali", href = "http://deanattali.com"), br(),
			span("November 21, 2014")
		)
	),
	
	# show a loading message initially
	div(
		id = "loadingContent",
		h2("Loading...")
	),	
	
	# all content goes here, and is hidden initially until the page fully loads
	hidden(div(id = "allContent",
		
		# sidebar - filters for the data
		sidebarLayout(
			sidebarPanel(
				h3("Filter data"),

				# show all the cancers or just specific types?
				selectInput(
					"subsetType", "",
					c("Show all cancer types" = "all",
						"Select specific types" = "specific"),
					selected = "all"),
				
				# which cancer types to show
				conditionalPanel(
					"input.subsetType == 'specific'",
					uiOutput("cancerTypeUi")
				), br(),
				
				# whether to combine all data in a given year or not
				checkboxInput("showGrouped",
											strong("Group all data in each year"),
											FALSE), br(),
				
				# what years to show
				# Note: yearText should use "inline = TRUE" in newer shiny versions,
				# but since the stats server has an old version I'm doing this in css
				strong(span("Years:")),
				textOutput("yearText"), br(),  
				uiOutput("yearUi"), br(),

				# what variables to show
				uiOutput("variablesUi"),

				# button to update the data
				shiny::hr(),
				actionButton("updateBtn", "Update Data"),
				
				# footer - where the data was obtained
				br(), br(), br(), br(),
				p("Data was obtained from ",
					a("the United States CDC",
						href = "http://wonder.cdc.gov/cancer.html",
						target = "_blank")),
				a(img(src = "us-cdc.png", alt = "US CDC"),
					href = "http://wonder.cdc.gov/cancer.html",
					target = "_blank")
			),
			
			# main panel has two tabs - one to show the data, one to plot it
			mainPanel(wellPanel(
				tabsetPanel(
					id = "resultsTab", type = "tabs",
					
					# tab showing the data in table format
					tabPanel(
						title = "Show data", id = "tableTab",
						
						br(),
						downloadButton("downloadData", "Download table"),
						br(), br(),
						
						span("Table format:"),
						radioButtons(inputId = "tableViewForm",
												 label = "",
												 choices = c("Wide" = "wide", "Long" = "long"),
												 inline = TRUE),
						br(),
						
						tableOutput("dataTable")
					),
					
					# tab showing the data as plots
					tabPanel(
						title = "Plot data", id = "plotTab",
						br(),
						downloadButton("downloadPlot", "Save figure"),
						br(), br(),
						plotOutput("dataPlot")
					)
				)
			))
		)
	))
)
