# Dean Attali
# November 21 2014

# This is the server portion of a shiny app shows cancer data in the United
# States

source("helpers.R")  # have the helper functions avaiable

library(shiny)
library(magrittr)
library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(shinyjs)

# Get the raw data
cDatRaw <- getData()

# Get the list of colours to use for plotting
plotCols <- getPlotCols()

shinyServer(function(input, output, session) {
	# =========== BUILDING THE INPUTS ===========
	
	# Create select box input for choosing cancer types
	output$cancerTypeUi <- renderUI({
		selectizeInput("cancerType", "",
									 levels(cDatRaw$cancerType),
									 selected = NULL, multiple = TRUE,
									 options = list(placeholder = "Select cancer types"))
	})	
	
	# Create select box input to choose variables to show
	output$variablesUi <- renderUI({
		selectizeInput("variablesSelect", "Variables to show:",
									 unique(as.character(cDatRaw$stat)),
									 selected = unique(cDatRaw$stat), multiple = TRUE,
									 options = list(placeholder = "Select variables to show"))
	})	
	
	# Show the years selected (because of the bugs in the slider mentioned below)
	output$yearText <- renderText({
		if (is.null(input$years)) {
			return(formatYearsText(range(cDatRaw$year)))
		}
		
		formatYearsText(input$years)
	})	
	
	# Create slider for selecting year range
	# NOTE: there are some minor bugs with sliderInput rendered in renderUI
	# https://github.com/rstudio/shiny/issues/587
	output$yearUi <- renderUI({
		sliderInput("years", 
								label = "",
								min = min(cDatRaw$year), max = max(cDatRaw$year),
								value = range(cDatRaw$year),
								step = 1)
	})
	
	
	# ============== MANIPULATE THE DATA ================

	# The dataset to show/plot, which is the raw data after filtering based on
	# the user inputs
	cDat <- reactive({
		# Add dependency on the update button (only update when button is clicked)
		input$updateBtn	
		
		# If the app isn't fully loaded yet, just return the raw data 
		if (!dataValues$appLoaded) {
			return(cDatRaw)
		}
		
		data <- cDatRaw
		
		# Add all the filters to the data based on the user inputs
		# wrap in an isolate() so that the data won't update every time an input
		# is changed
		isolate({
			
			# Filter years
			data %<>%
				filter(year >= input$years[1] & year <= input$years[2])
			
			# Filter what variables to show
			if (!is.null(input$variablesSelect)) {
				data %<>%
					filter(stat %in% input$variablesSelect)
			}
			
			# Filter cancer types
			if (input$subsetType == "specific" & !is.null(input$cancerType)) {
				data %<>%
					filter(cancerType %in% input$cancerType)
			}
			
			# See if the user wants to show data per cancer type or all combined
			if (input$showGrouped) {
				data %<>%
					group_by(year, stat) %>%
					summarise(value =
											ifelse(stat[1] != "mortalityRate",
														 sum(value),
														 mean(value))) %>%
					ungroup %>%
					data.frame
			}
		})

		data
	})
	
	# The data to show in a table, which is essentially the same data as above
	# with all the filters, but formatted differently:
	# - Format the numbers to look better in a table
	# - Change the data to wide/long format (the filtered data above is long)
	cDatTable <- reactive({
		data <- cDat()
		
		# In numeric columns show 2 digits past the decimal and don't show
		# decimal if the number is a whole integer
		data %<>%
			mutate(value = formatC(data$value, format = "fg", digits = 2))		
		
		# Change the data to wide format if the user wants it
		if (input$tableViewForm == "wide") {
			data %<>%
				spread(stat, value)
		}
		
		data
	})
	
	
	# ============= TAB TO SHOW DATA IN TABLE ===========
	
	# Show the data in a table
	output$dataTable <- renderTable(
		{
			cDatTable()
		},
		include.rownames = FALSE
	)
	
	# Allow user to download the data, simply save as csv
	output$downloadData <- downloadHandler(
		filename = function() { 
			"cancerData.csv"
		},
		
		content = function(file) {
			write.table(x = cDatTable(),
									file = file,
									quote = FALSE, sep = ",", row.names = FALSE)
		}
	)	
	
	
	# ============= TAB TO PLOT DATA ===========
	
	# Function to build the plot object
	buildPlot <- reactive({
		
		# Basic ggplot object
		p <-
			ggplot(cDat()) +
			aes(x = as.factor(year), y = value)
		
		# If showing individual cancer types, group each type together, otherwise
		# just connect all the dots as one group
		isolate(
			if (input$showGrouped) {
			  p <- p + aes(group = 1)
			} else {
			  p <- p + aes(group = cancerType, col = cancerType)
			}
		)
		
		# Facet per variable, add points and lines, and make the graph pretty
		p <- p +
			facet_wrap(~stat, scales = "free_y", ncol = 2) +
			geom_point() +
			geom_line(show.legend = FALSE) +
			theme_bw(16) +
			theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
			scale_color_manual(values = plotCols) +
			theme(legend.position = "bottom") +
			guides(color = guide_legend(title = "",
																	ncol = 4,
																	override.aes = list(size = 4))) +
			xlab("Year") + ylab("") +
			theme(panel.grid.minor = element_blank(),
						panel.grid.major.x = element_blank())
		
		p
	})	
	
	# Show the plot, use the width/height that javascript calculated
	output$dataPlot <-
		renderPlot(
			{
				buildPlot()
			},
			height = function(){ input$plotDim },
			width = function(){ input$plotDim },
			units = "px",
			res = 100
		)

	# Allow user to download the plot
	output$downloadPlot <- downloadHandler(
		filename = function() {
			"cancerDataPlot.pdf"
		},
		
		content = function(file) {
			pdf(file = file,
					width = 12,
					height = 12)
			print(buildPlot())
			dev.off()
		}
	)		
	
	
	# ========== LOADING THE APP ==========
	
	# We need to have a quasi-variable flag to indicate when the app is loaded
	dataValues <- reactiveValues(
		appLoaded = FALSE
	)
	
	# Wait for the years input to be rendered as a proxy to determine when the app
	# is loaded. Once loaded, call the javascript funtion to fix the plot area
	# (see www/helper-script.js for more information)
	observe({
		if (dataValues$appLoaded) {
			return(NULL)
		}
		if(!is.null(input$years)) {
			dataValues$appLoaded <- TRUE
			
  		session$sendCustomMessage(type = "equalizePlotHeight",
  															message = list(target = "dataPlot",
  																						 by = "resultsTab"))
		}
	})
	
	# Show form content and hide loading message
	hide("loadingContent")
	show("allContent")
})
