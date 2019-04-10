# Dean Attali
# July 11, 2017
#
# This script scrapes data from the useR 2017 scheduling website to see the
# attendance preferences of conference attendees.
# There were 1,161 attendees in total, and 966 of them used the Sched app. 
# This code was written in a hurry while on a train, and it is far
# from being "great and robust" scraping code, so beware trying to copy any of
# this code :)

library(rvest)

base_url <- "https://user2017.sched.com"

# Get all info for a talk from its event URL; return a one-row tibble
get_event_data <- function(event_id) {
  # Read the HTML page
  full_url <- paste0(base_url, "/event/", event_id)
  content <- read_html(full_url)

  # Extract information from the page
  title <-
    content %>% html_node(".event a.name") %>%
    html_text(trim = TRUE)
  attendance <-
    content %>% html_node("#sched-page-event-attendees h2") %>%
    html_text(trim = TRUE) %>%
    sub(pattern = ".*\\((.*)\\).*", replacement = "\\1", x = .) %>%
    as.numeric()
  speaker <-
    content %>% html_node(".sched-person h2 a") %>%
    html_text(trim = TRUE)
  time <-
    content %>% html_node(".sched-event-details-timeandplace") %>%
    html_text(trim = TRUE) %>%
    sub(pattern = ".*(July.*) -.*", replacement = "\\1", x = .) %>%
    strptime("%B %d, %Y %I:%M%p", tz = "CET") %>%
    as.POSIXct()
  room <-
    content %>% html_node(".sched-event-details-timeandplace a") %>%
    html_text(trim = TRUE)
  type <-
    content %>% html_node(".sched-event-type a") %>%
    html_text(trim = TRUE)

  # Return all event information as a one-row tibble
  tibble::tibble(type = type, title = title, attendance = attendance,
                 speaker = speaker, time = time, room = room, url = full_url)
}

# Find all event links from the main page, extract the event ID,
# and scrape each event page
content <- read_html(base_url)
event_ids <- content %>%
  html_nodes(".event a.name") %>%
  html_attr("href") %>%
  sub("/event/(.*)/.*", "\\1", .)
all_talks <- purrr::map_df(event_ids, get_event_data)


# Remove RIOT SESSION because it's the only session that is not the same type
# of session as everything else in its time slot. It's also the lowest
# attendance with 21, so not too interesting as far as this dataset is concerned
all_talks <- all_talks[-which(all_talks$title == "RIOT SESSION"), ]

# Make sure all concurrent sessions are of the same type
stopifnot(
  all(dplyr::group_by(all_talks, time) %>%
        dplyr::summarize(num_types = length(unique(type))) %>%
        .$num_types == 1)
)

# add some aggregate attendance data
total_attendance <- 966
aggregate_data <- all_talks %>%
  dplyr::group_by(time) %>%
  dplyr::summarize(
    concurrent_sessions = n(),
    concurrent_attendance = sum(attendance),
    type = type[1]
  ) %>%
  dplyr::mutate(expected = round(total_attendance / concurrent_sessions))

all_talks <- all_talks %>%
  dplyr::left_join(aggregate_data, by = c("time", "type")) %>%
  dplyr::mutate(attendance_ratio = round(attendance/expected, 2))

# add unique id and save
all_talks$id <- rownames(all_talks)
write.csv(all_talks, "all_talks.csv", row.names = FALSE)
