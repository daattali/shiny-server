# which fields get saved
fieldsAll <- c("firstName",
               "lastName",
               "studentNum",
               "email",
               "gitName",
               "twitterName",
               "osType"
              )

# which fields are mandatory
fieldsMandatory <- c("firstName", "lastName", "studentNum")

# add an asterisk to an input label
labelMandatory <- function(label) {
  tagList(
    label,
    span("*", class = "mandatory_star")
  )
}

# validate the student number
validateStudentNum <- function(x) {
  grepl("^[0-9]{4}$", x, perl = TRUE)
}

# get current Epoch time
epochTime <- function() {
  as.integer(Sys.time())
}

# get a formatted string of the timestamp (exclude colons as they are invalid
# characters in Windows filenames)
humanTime <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%OS")
}
