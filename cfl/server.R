library(shiny)
library(shinyjs)
library(dplyr)
library(ggvis)
library(reshape2)

TEST_GAMEPAGE <- FALSE

demo_clips <- list(
  list(videoId = "snwanVaPMys", startSeconds = 126, endSeconds = 135),
  list(videoId = "snwanVaPMys", startSeconds = 145, endSeconds = 153),
  list(videoId = "snwanVaPMys", startSeconds = 196, endSeconds = 210),
  list(videoId = "snwanVaPMys", startSeconds = 260, endSeconds = 296),
  list(videoId = "snwanVaPMys", startSeconds = 359, endSeconds = 368),
  list(videoId = "mefLj3eB7Gc", startSeconds = 8, endSeconds = 30),
  list(videoId = "mefLj3eB7Gc", startSeconds = 63, endSeconds = 75),
  list(videoId = "mefLj3eB7Gc", startSeconds = 122, endSeconds = 138),
  list(videoId = "mefLj3eB7Gc", startSeconds = 145, endSeconds = 157),
  list(videoId = "mefLj3eB7Gc", startSeconds = 183, endSeconds = 195)
)

function(input, output, session) {
  
  values <- reactiveValues(
    playing = FALSE,
    playdata = NULL,
    gamedata = NULL,
    touchdowns = c()
  )

  closeVideo <- function() {
    shinyjs::hide("myoverlay", TRUE, "fade", 0.25)
    shinyjs::hide("youtube_area")
    shinyjs::delay(250, {values$playing <- TRUE})
    shinyjs::runjs('$("#youtubeplayer").attr("src", "");')
  }
  
  shinyjs::onclick("youtube_close", closeVideo())
  shinyjs::onclick("myoverlay", closeVideo())
  
  observe({
    if (!is.null(input$videodone) && input$videodone > 0) {

    }
  })

  observe({
    if (values$playing) {
      shinyjs::html("play", paste0(icon("pause"), " Pause"))
    } else {
      shinyjs::html("play", paste0(icon("play"), " Play"))
    }
  })
  
  # On welcome page, user clicks on a game row
  observeEvent(input$gamerowclick, {
    shinyjs::addClass(selector = "body", class = "game_page")
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
    
    # store time points of touchdowns
    touchdown_idx <- which(playdata$eventType == "Score" &
                             playdata$eventScore == 30)
    values$touchdowns <- playdata[touchdown_idx, ]$seconds
    
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

    pos <- playdata$pos[1]
    end_pos <- playdata$end_pos[1]
    ishome <- playdata$eventHome[1]
    
    js$setline(pos, end_pos, ishome)    
  }  
  
  shinyjs::html("output_quarter", "Q1")
  shinyjs::html("output_time", "15:00")
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
    end_pos <- playdata$end_pos[index]
    ishome <- playdata$eventHome[index]
    
    js$setline(pos, end_pos, ishome)
    shinyjs::html(id = "homescore", html = playdata$home_score_after[index])
    shinyjs::html(id = "awayscore", html = playdata$away_score_after[index])
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
    
    isolate({
      prevval <- input$time
      val <- prevval + 4 * input$speed
    })
    
    # figure out if a touchdown just happened
    for(touchdown in values$touchdowns) {
      if (touchdown >= prevval && touchdown < val) {
        values$playing <- FALSE
        shinyjs::show("myoverlay", TRUE, "fade", 0.25)
        shinyjs::delay(250, shinyjs::show("youtube_area"))
        clip_idx <- sample(length(demo_clips), 1)
        clip_info <- demo_clips[[clip_idx]]
        js$playyoutube(clip_info)
      }
    }
    
    if (val >= MAX_TIME) {
      updateSliderInput(session, "time", value = MAX_TIME)
      values$playing <- FALSE
      return()
    }
    updateSliderInput(session, "time", value = val)
  })
  
  observe({
    onclick("back_to_welcome", {
      values$playing <- FALSE
      shinyjs::show("welcome_page")
      shinyjs::hide("game_page")
      shinyjs::removeClass(selector = "body", class = "game_page")
    })
  })
  
  frame <- reactive({
    if(is.null(values$gamedata['sked_id'])){
      return(data.frame(value=double(0),
                        variable=character(0), 
                        x = double(0),
                        id = integer(0)))
    }
    set.seed(values$gamedata['sked_id'] %>% unlist)
    bluPeak = runif(n = floor(runif(n=1,min=2,max=5)),min=1,max=3600)
    redPeak = runif(n = floor(runif(n=1,min=1,max=4)),min=1,max=3600)
    blu = c(sample(1:3600,300,replace = T),
            unlist(sapply(bluPeak,function(x){
              rnorm(100,mean = x, sd = 150)
            })))
    red = c(sample(1:3600,300,replace = T), 
            unlist(sapply(redPeak,function(x){
              rnorm(100,mean = x, sd = 150)
            })))
    blu = blu %>% density %>% .$y
    red = red %>% density %>% .$y
    frame = list(Heart_Rate = blu, Fan_Tweets = red) %>% melt
    frame$x = 1:length(red)
    frame$id = 1:nrow(frame)
    names(frame) = c('value','variable','x','id')
    frame$value = scale01(frame$value) * 100 
    return(frame)
  })
  
  
  frame %>% ggvis(~x ,~value,  stroke= ~variable,key := ~id) %>% 
    add_tooltip(function(x){
      return(paste0('<p>',
                    gsub('_',' ',frame()$variable[x$id]),
                    '</p><p>',
                    format(frame()$value[x$id],digits=2),
                    '</p>'))
    }) %>%
    layer_points(size := 4) %>% hide_legend(scales = 'stroke') %>% 
    hide_axis("x") %>% hide_axis("y") %>% 
    set_options(height = 70, width = 800,resizable=FALSE,padding = padding(0,0,0,0)) %>% 
    bind_shiny('reactionPlot')  
  
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

