library(dplyr)
library(digest)
library(DBI)
library(RMySQL)
library(RSQLite)
library(rmongodb)

DB_NAME <- "shinyapps"
TABLE_NAME <- "google_form_mock"

save_data <- function(data, type) {
  fxn <- sprintf("save_data_%s", type)
  stopifnot(existsFunction(fxn))
  do.call(fxn, list(data))
}

load_data <- function(type) {
  fxn <- sprintf("load_data_%s", type)
  stopifnot(existsFunction(fxn))
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

# before saving, make sure folder exists
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



#### Method 3: MySQL ####

sqlite_file <- file.path("sqlite", paste0(DB_NAME, ".sqlite"))

# before saving, make sure the database exists and
# the table exists (CREATE TABLE xxx(a text, b text, ...))
save_data_sqlite <- function(data) {
  db <- dbConnect(SQLite(), sqlite_file)
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
  db <- dbConnect(SQLite(), sqlite_file) 
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





#### Method 6: Amazon S3 ####