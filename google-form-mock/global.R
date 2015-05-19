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

storage_types <- c(
  "Text file (local)" = "flatfile",
  "SQLite (local)" = "sqlite",
  "MySQL database (local or remote)" = "mysql",
  "MongoDB database (local or remote)" = "mongodb",
  "Google Sheets (remote)" = "gsheets",
  "Amazon Simple Storage Service (S3) (remote)" = "s3"
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

storage_type_notes <- c(
  "flatfile" = "This method will saving, make sure folder exists"
)