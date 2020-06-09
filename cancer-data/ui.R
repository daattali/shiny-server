# Dean Attali
# November 21 2014

# This is the ui portion of a shiny app shows cancer data in the United States

library(shiny)
library(shinyjs)

share <- list(
  title = "Cancer data in the United States",
  url = "http://daattali.com/shiny/cancer-data/",
  image = "http://daattali.com/shiny/img/cancer.png",
  description = "Explore trends in cancer incidence over the years and compare different cancer types.",
  twitter_user = "daattali"
)

function(request) {
fluidPage(
  useShinyjs(),
  shinydisconnect::disconnectMessage2(),
  title = "Cancer data in the United States",
  
  # add custom JS and CSS
  singleton(
    tags$head(
      includeScript(file.path('www', 'message-handler.js')),
      includeScript(file.path('www', 'helper-script.js')),
      includeCSS(file.path('www', 'style.css')),
      tags$link(rel = "shortcut icon", type="image/x-icon", href="http://daattali.com/shiny/img/favicon.ico"),
      # Facebook OpenGraph tags
      tags$meta(property = "og:title", content = share$title),
      tags$meta(property = "og:type", content = "website"),
      tags$meta(property = "og:url", content = share$url),
      tags$meta(property = "og:image", content = share$image),
      tags$meta(property = "og:description", content = share$description),
    
      # Twitter summary cards
      tags$meta(name = "twitter:card", content = "summary"),
      tags$meta(name = "twitter:site", content = paste0("@", share$twitter_user)),
      tags$meta(name = "twitter:creator", content = paste0("@", share$twitter_user)),
      tags$meta(name = "twitter:title", content = share$title),
      tags$meta(name = "twitter:description", content = share$description),
      tags$meta(name = "twitter:image", content = share$image)
    )
  ),
  tags$a(
    href="https://github.com/daattali/shiny-server/tree/master/cancer-data",
    tags$img(style="position: absolute; top: 0; right: 0; border: 0;",
             src="github-green-right.png",
             alt="Fork me on GitHub")
  ),
	
	# enclose the header in its own section to style it nicer
	div(id = "headerSection",
		h1("Cancer data in the United States"),
	
		# author info
		span(
                  style = "font-size: 1.2em",
			span("Created by "),
			a("Dean Attali", href = "http://deanattali.com"),
			HTML("&bull;"),
			span("Code"),
			a("on GitHub", href = "https://github.com/daattali/shiny-server/tree/master/cancer-data"),
                        HTML("&bull;"),
                        a("More apps", href = "http://daattali.com/shiny/"), "by Dean",
			br(),
			
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
				h3("Filter data", style = "margin-top: 0;"),

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
				br(), br(),
				p("Data was obtained from ",
					a("the United States CDC",
						href = "http://wonder.cdc.gov/cancer.html",
						target = "_blank")),
				a(img(src = "us-cdc.png", alt = "US CDC"),
					href = "http://wonder.cdc.gov/cancer.html",
					target = "_blank"),
                                br(), br(), bookmarkButton()
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
}
