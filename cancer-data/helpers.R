# Dean Attali
# November 21 2014

# Helper functions for the cancer-data shiny app

library(magrittr)

DATA_DIR <- file.path("data")

# Read the data and get it ready for the app
getData <- function() {
	
	# read the data file
	cDat <- read.table(file.path(DATA_DIR, "cancerData.csv"), sep = ",",
										 header = TRUE, row.names = NULL)
	
	# re-order the cancerType factor based on the order that was saved
	cDatTypeOrder <- read.table(file.path(DATA_DIR,
																			"cancerData-order-cancerType.txt"),
																	header = FALSE, row.names = NULL, sep = ",")
	cDatTypeOrder %<>%
		first
	cDat %<>%
		mutate(cancerType = factor(cancerType, cDatTypeOrder))
	
	cDat
}

# Our data has 22 cancer types, so when plotting I wanted to have a good
# set of 22 unique colours
getPlotCols <- function() {
	c22 <- c("dodgerblue2","#E31A1C", # red
					 "green4",
					 "#6A3D9A", # purple
					 "#FF7F00", # orange
					 "black","gold1",
					 "skyblue2","#FB9A99", # lt pink
					 "palegreen2",
					 "#CAB2D6", # lt purple
					 "#FDBF6F", # lt orange
					 "gray70", "khaki2", "maroon", "orchid1", "deeppink1", "blue1",
					 "darkturquoise", "green1", "yellow4", "brown")
	c22
}

# Format a range of years in a nice, easy-to-read way
formatYearsText <- function(years) {
	if (min(years) == max(years)) {
		return(min(years))
	} else {
		return(paste(years, collapse = " - "))	
	}
}