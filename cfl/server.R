library(shiny)
library(shinyjs)
library(dplyr)

TEST_GAMEPAGE <- FALSE

function(input, output, session) {
  
  values <- reactiveValues(
    playing = FALSE,
    playdata = NULL,
    gamedata = NULL
  )
  observeEvent(input$aaa, {
    values$playing <- FALSE
    shinyjs::show("myoverlay", TRUE, "fade", 0.25)
    shinyjs::delay(250, shinyjs::show("youtubeplayer"))
    js$playyoutube("OoT_7UOUquE")
  })
  observe({
    if (!is.null(input$videodone) && input$videodone > 0) {
      shinyjs::hide("myoverlay", TRUE, "fade", 0.25)
      shinyjs::hide("youtubeplayer")
      shinyjs::delay(250, {values$playing <- TRUE})
    }
  })

  observe({
    if (values$playing) {
      shinyjs::text("play", paste0(icon("pause"), " Pause"))
    } else {
      shinyjs::text("play", paste0(icon("play"), " Play"))
    }
  })
  
  # On welcome page, user clicks on a game row
  observeEvent(input$gamerowclick, {
    values$gamedata <- input$gamerowclick
    gameid <- values$gamedata[['sked_id']]
    playdata <- load_playdata(gameid)
    new_game(playdata)
  })
  
  observeEvent(values$gamedata, {
    js$newgame(values$gamedata)
  })

  new_game <- function(playdata) {
    shinyjs::reset("game_page")
    values$playing <- FALSE
    values$playdata <- playdata

    output$home_events <- renderUI({
      lapply(
        seq(nrow(playdata)),
        function(x) {
          row <- playdata[x, ]
          if (!row$eventHome || is.na(row$eventType)) {
            return(NULL)
          }
          div(
            class = paste0("gameevent event-home event-", row$eventType),
            style = paste0("height: ", row$eventScore*2, "px;",
                           "left: ", row$seconds / MAX_TIME * 100, "%;"),
            `data-time` = row$seconds,
            `data-tooltip` = row$details
          )
        }
      )
    })
    output$away_events <- renderUI({
      lapply(
        seq(nrow(playdata)),
        function(x) {
          row <- playdata[x, ]
          if (row$eventHome || is.na(row$eventType)) {
            return(NULL)
          }
          div(
            class = paste0("gameevent event-away event-", row$eventType),
            style = paste0("height: ", row$eventScore*2, "px;",
                           "left: ", row$seconds / MAX_TIME * 100, "%;"),
            `data-time` = row$seconds,
            `data-tooltip` = row$details
          )
        }
      )
    })
    shinyjs::hide("welcome_page")
    shinyjs::show("game_page")
  }  
  
  output$output_quarter <- renderText({
    paste0("Q", get_quarter(input$time))
  })
  output$output_time <- renderText({
    get_time(input$time)
  })
  
  observeEvent(input$time, {
    playdata <- values$playdata
    index <- findInterval(input$time, playdata$second, all.inside = TRUE)
    pos <- playdata$pos[index]
    js$setline(pos)
    shinyjs::text(id = "homescore", text = playdata$home_score_after[index])
    shinyjs::text(id = "awayscore", text = playdata$away_score_after[index])
  })
  
  observeEvent(input$play, {
    values$playing <- !values$playing
  })
  
  observeEvent(input$gameeventclick, {
    updateSliderInput(session, "time", value = input$gameeventclick)
  })
  
  observe({
    lapply(EVENT_TYPES, function(x)
      shinyjs::removeClass("time-wrapper", paste0("show-", x)))
    shinyjs::removeClass()
    lapply(input$eventTypeFilter, function(x)
      shinyjs::addClass("time-wrapper", paste0("show-", x)))
  })
  
  observe({
    invalidateLater(100, session)
    if (!values$playing) {
      return()
    }
    
    isolate(val <- input$time + 10 * input$speed)
    if (val >= MAX_TIME) {
      updateSliderInput(session, "time", value = MAX_TIME)
      values$playing <- FALSE
      return()
    }
    updateSliderInput(session, "time", value = val)
  })
  
  observe({
    onclick("back_to_welcome", {
      shinyjs::show("welcome_page")
      shinyjs::hide("game_page")
    })
  })
  
  ############## TEST GAME PAGE
  if (TEST_GAMEPAGE) {
    allgames <- read.csv("data/cfl_games_trim.csv", stringsAsFactors = FALSE) %>%
      arrange(desc(game_date))
    gameid <- 12843
    values$gamedata <- allgames[allgames$sked_id == gameid, ]
    playdata <- load_playdata(gameid)
    new_game(playdata)
  }  
}