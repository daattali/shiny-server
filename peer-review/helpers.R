# validate the reviewr-reviewee pair
validateReviewerReviewee <- function(reviewer, reviewee) {
  return(reviewer != reviewee)
}

# validate the form fields
validateForm <- function(input) {
  return(validateReviewerReviewee(input$reviewer, input$reviewee))
}

# get current Epoch time
getEpochTime <- function() {
  return(as.integer(Sys.time()))
}

# get a formatted string of the timestamp (exclude colons as they are invalid
# characters in Windows filenames)
getFormattedTimestamp <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%OS")
}

# decide if the form is active or not (can be a simple T/F or based on date for example)
isFormActive <- function() {
  return(TRUE)
}

# return a vector of canonical student names to use as the class list
## TO DO: keep this classlist up-to-date!
getClassList <- function() {
  dataDir <- file.path("data")
  classInfo <- read.csv(file.path(dataDir, "2014-class-list.csv"), header = TRUE)
  classList <- sort(c("", as.character(classInfo$name)))
  return(classList)
}
