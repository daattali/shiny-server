library(dplyr)
library(digest)
library(DBI)
library(RMySQL)
library(RSQLite)
library(mongolite)
library(googlesheets)
library(aws.s3)
library(rdrop2)

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
    do.call(rbind, .)
  
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
  db <- mongo(collection = TABLE_NAME,
              url = sprintf(
                "mongodb://%s:%s@%s/%s",
                options()$mongodb$username,
                options()$mongodb$password,
                options()$mongodb$host,
                DB_NAME))
  data <- as.data.frame(t(data))
  db$insert(data)
}
load_data_mongodb <- function() {
  db <- mongo(collection = TABLE_NAME,
              url = sprintf(
                "mongodb://%s:%s@%s/%s",
                options()$mongodb$username,
                options()$mongodb$password,
                options()$mongodb$host,
                DB_NAME))
  data <- db$find()

  data
}



#### Method 5: Google Sheets ####

gs_auth(token = "googlesheets_token.rds")

save_data_gsheets <- function(data) {
  TABLE_NAME %>% gs_title %>% gs_add_row(input = data)
}
load_data_gsheets <- function() {
  TABLE_NAME %>% gs_title %>% gs_read_csv
}



#### Method 6: Dropbox ####

drop_auth(rdstoken = "dropbox_token.rds")

save_data_dropbox <- function(data) {
  # Create a temporary file to hold the data
  data <- t(data)
  file_name <- paste0(
    paste(
      get_time_human(),
      digest(data, algo = "md5"),
      sep = "_"
    ),
    ".csv"
  )  
  file_path <- file.path(tempdir(), file_name)
  write.csv(data ,file_path, row.names = FALSE, quote = TRUE)

  # Upload the file to dropbox
  drop_upload(file_path, path = TABLE_NAME)
}
load_data_dropbox <- function() {
  files_info <- drop_dir(TABLE_NAME)
  file_paths <- files_info$path_display
  # Only take the last 20 because each file takes ~1 second to download
  file_paths <- tail(file_paths, 20)
  data <-
    lapply(file_paths, drop_read_csv, stringsAsFactors = FALSE) %>%
    do.call(rbind, .)

  data
}




#### Method 7: Amazon S3 ####

s3_bucket_name <- TABLE_NAME %>% gsub("_", "-", .)

save_data_s3 <- function(data) {
  # Create a plain-text representation of the data
  data <- paste0(
    paste(names(data), collapse = ","), "\n",
    paste(unname(data), collapse = ",")
  )

  file_name <- paste0(
    paste(
      get_time_human(),
      digest(data, algo = "md5"),
      sep = "_"
    ),
    ".csv"
  )

  # Upload the file to S3
  put_object(file = charToRaw(data), object = file_name, bucket = s3_bucket_name)
}
load_data_s3 <- function() {
  file_names <- get_bucket_df(s3_bucket_name)[["Key"]]
  data <- lapply(file_names, function(x) {
    object <- get_object(x, s3_bucket_name)
    object_data <- readBin(object, "character")
    read.csv(text = object_data, stringsAsFactors = FALSE)
  }) %>%
    do.call(rbind, .)

  data
}
