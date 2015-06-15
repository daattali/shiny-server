# mandatory fields in the form
fields_mandatory <- c(
  "name"
)

# all fields in the form we want to save
fields_all <- c(
  fields_mandatory,
  "r_num_years",
  "used_shiny",
  "os_type",
  "favourite_pkg",
  "timestamp"
)

# get current Epoch time
get_time_epoch <- function() {
  return(as.integer(Sys.time()))
}

# get a formatted string of the timestamp (exclude colons as they are invalid
# characters in Windows filenames)
get_time_human <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%OS")
}