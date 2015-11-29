library(dplyr)

source("returnGameData.R")

MAX_TIME <- 4*15*60

EVENT_TYPES <- c("Pass", "Rush", "Score")

get_quarter <- function(time) {
  if (time == 0) {
    1
  } else {
    ceiling(time / MAX_TIME * 4)
  }
}

get_time <- function(time) {
  quarter <- get_quarter(time)
  time <- time - (quarter - 1) * 15 * 60
  
  minutes <- floor(time / 60)
  seconds <- time %% 60
  if (seconds == 0) {
    sprintf("%02d:%02d", 15 - minutes, 0)
  } else {
    sprintf("%02d:%02d", 15 - minutes - 1, 60 - seconds)
  }
}

load_playdata <- function(gameid) {
  gamedata <- returnGameData(gameid)
  playbyplay <- gamedata$playByPlay %>%
    select(quarter, time, down, secondsTotal, details, yardsFromHome,
           end_yardsFromHome, home_score_after, away_score_after, isHome,
           epicEvent, epicness) %>%
    rename(seconds = secondsTotal, pos = yardsFromHome, end_pos = end_yardsFromHome,
           eventHome = isHome, eventType = epicEvent,
           eventScore = epicness) %>%
    arrange(seconds)
  playbyplay$eventType <- sub("^SCORE!!!111$", "Score", playbyplay$eventType)
  playbyplay
}