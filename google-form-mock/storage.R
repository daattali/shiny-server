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

# decide which function to use to save based on storage type
get_save_fxn <- function(type) {
  fxn <- sprintf("save_data_%s", type)
  stopifnot(existsFunction(fxn))
  fxn
}
save_data <- function(data, type) {
  fxn <- get_save_fxn(type)
  do.call(fxn, list(data))
}

# decide which function to use to load based on storage type
get_load_fxn <- function(type) {
  fxn <- sprintf("load_data_%s", type)
  stopifnot(existsFunction(fxn))
  fxn
}
load_data <- function(type) {
  fxn <- get_load_fxn(type)
  data <- do.call(fxn, list())
  
  # Just for a nicer UI, if there is no data, construct an empty
  # dataframe so that the colnames will still be shown
  if (nrow(data) == 0) {
    data <-
      matrix(nrow = 0, ncol = length(fields_all),
             dimnames = list(list(), fields_all)) %>%
      data.frame
  }
  data %>% dplyr::arrange(desc(timestamp))
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

save_data_mysql <- function(data) {
  db <- dbConnect(MySQL(), dbname = DB_NAME,
                  host = options()$mysql$host,
                  port = options()$mysql$port,
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
                  port = options()$mysql$port,
                  user = options()$mysql$user,
                  password = options()$mysql$password)
  query <- sprintf("SELECT * FROM %s", TABLE_NAME)
  data <- dbGetQuery(db, query)
  dbDisconnect(db)
  
  data
}




#### Method 4: MongoDB ####

collection_name <- sprintf("%s.%s", DB_NAME, TABLE_NAME)

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
      raw <- getFile(s3_bucket_name, x, virtual = TRUE)
      read.csv(text = raw, stringsAsFactors = FALSE)
    }) %>%
    rbind_all
  data
}