library(dplyr)
library(digest)
library(DBI)
library(RMySQL)
library(RSQLite)
library(rmongodb)
library(googlesheets)
library(RAmazonS3)

DB_NAME <- "shinyapps"
TABLE_NAME <- "google_form_mock"

get_save_fxn <- function(type) {
  fxn <- sprintf("save_data_%s", type)
  stopifnot(existsFunction(fxn))
  fxn
}
save_data <- function(data, type) {
  fxn <- get_save_fxn(type)
  do.call(fxn, list(data))
}

get_load_fxn <- function(type) {
  fxn <- sprintf("load_data_%s", type)
  stopifnot(existsFunction(fxn))
  fxn
}
load_data <- function(type) {
  fxn <- get_load_fxn(type)
  data <- do.call(fxn, list())
  
  if (nrow(data) == 0) {
    data <-
      matrix(nrow = 0, ncol = length(fields_all),
             dimnames = list(list(), fields_all)) %>%
      data.frame
  }
  data
}

#### Method 1: Local text files ####

results_dir <- "responses"
save_data_flatfile <- function(data) {
  data <- t(data)
  file_name <- paste0(
    paste(
      get_time_human(),
      digest(data, algo = "md5"),
      sep = "_"
    ),
    ".csv"
  )

  # write out the results
  write.csv(x = data, file = file.path(results_dir, file_name),
            row.names = FALSE, quote = TRUE)
}
load_data_flatfile <- function() {
  files <- list.files(file.path(results_dir), full.names = TRUE)
  data <-
    lapply(files, read.csv, stringsAsFactors = FALSE) %>%
    rbind_all
  data
}



#### Method 2: SQLite ####

# before saving, make sure the database exists and
# the table exists (CREATE TABLE xxx(a text, b text, ...))
save_data_sqlite <- function(data) {
  db <- dbConnect(SQLite(), options()$sqlite$file)
  query <-
    sprintf("INSERT INTO %s (%s) VALUES ('%s')",
            TABLE_NAME,
            paste(names(data), collapse = ", "),
            paste(data, collapse = "', '")
    )
  dbGetQuery(db, query)
  dbDisconnect(db)
}
load_data_sqlite <- function() {
  db <- dbConnect(SQLite(), options()$sqlite$file)
  query <- sprintf("SELECT * FROM %s", TABLE_NAME)
  data <- dbGetQuery(db, query)
  dbDisconnect(db)
  
  data
}




#### Method 3: MySQL ####

# before saving, make sure the database exists and the
# table exists (CREATE TABLE xxx(a text, b text, ...))
save_data_mysql <- function(data) {
  db <- dbConnect(MySQL(), dbname = DB_NAME,
                  host = options()$mysql$host,
                  post = options()$mysql$port,
                  user = options()$mysql$user,
                  password = options()$mysql$password)
  query <-
    sprintf("INSERT INTO %s (%s) VALUES ('%s')",
            TABLE_NAME,
            paste(names(data), collapse = ", "),
            paste(data, collapse = "', '")
    )
  dbGetQuery(db, query)
  dbDisconnect(db)
}
load_data_mysql <- function() {
  db <- dbConnect(MySQL(), dbname = DB_NAME,
                  host = options()$mysql$host,
                  post = options()$mysql$port,
                  user = options()$mysql$user,
                  password = options()$mysql$password)
  query <- sprintf("SELECT * FROM %s", TABLE_NAME)
  data <- dbGetQuery(db, query)
  dbDisconnect(db)
  
  data
}




#### Method 4: MongoDB ####

collection_name <- sprintf("%s.%s", DB_NAME, TABLE_NAME)

# before saving, make sure the database exists
save_data_mongodb <- function(data) {
  db <- mongo.create(db = DB_NAME,
                     host = options()$mongodb$host,
                     username = options()$mongodb$username,
                     password = options()$mongodb$password)
  mongo.insert(db,
               collection_name,
               mongo.bson.from.list(as.list(data)))
  mongo.disconnect(db)
}
load_data_mongodb <- function() {
  db <- mongo.create(db = DB_NAME,
                     host = options()$mongodb$host,
                     username = options()$mongodb$username,
                     password = options()$mongodb$password)
  data <-
    mongo.find.all(db, collection_name) %>%
    lapply(data.frame, stringsAsFactors = FALSE) %>%
    rbind_all %>%
    .[, -1, FALSE]
  mongo.disconnect(db)
  
  data
}




#### Method 5: Google Sheets ####
# problem 1: is programmatic authentication supported? non-interactive, just using api tokens?)
# problem 2: authentication in rstudio server doesn't work
# problem 3: after making a sheet public and trying to access it:
#            gs_key("126sYt93gzRGJE6n54CY1Z5VgyXl19btsy8zVweLvYu8") -->
#            "Error in gsheets_GET(x) : Was expecting content-type to be:
#             application/atom+xml; charset=UTF-8
#             but instead it's:
#             text/html; charset=UTF-8"

# before saving, make sure the Google Sheet exists and the header row is set
save_data_gsheets <- function(data) {
  sheet <- gs_title(TABLE_NAME)
  nrows <- sheet %>% get_via_csv %>% nrow
  edit_cells(sheet, input = data, byrow = TRUE, anchor = paste0("A", nrows + 2))
}
load_data_gsheets <- function() {
  TABLE_NAME %>% gs_title %>% get_via_csv
}

#### Method 6: Amazon S3 ####

s3_bucket_name <- TABLE_NAME %>% gsub("_", "-", .)

# before saving, make sure bucket exists
save_data_s3 <- function(data) {
  file_name <- paste0(
    paste(
      get_time_human(),
      digest(data, algo = "md5"),
      sep = "_"
    ),
    ".csv"
  )
  RAmazonS3::addFile(I(paste0(paste(names(data), collapse = ","),
                              "\n",
                              paste(data, collapse = ","))),
                     s3_bucket_name, file_name, virtual = TRUE)
}
load_data_s3 <- function(data) {
  files <- listBucket(s3_bucket_name)$Key %>% as.character
  data <-
    lapply(files, function(x) {
      raw <- getFile("google-form-mock", x, virtual = TRUE)
      read.csv(text = raw, stringsAsFactors = FALSE)
    }) %>%
    rbind_all
  data
}