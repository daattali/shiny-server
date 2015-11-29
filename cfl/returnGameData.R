library(dplyr)
library(magrittr)
library(jsonlite)
library(data.table)

scale01 = function(x){
  scaleToInt(x,1,0)
}
scaleToInt = function(x, max,min){
  scaleFun = scaleIntervals(max(x),min(x),max,min)
  scaleFun(x)
}
scaleIntervals = function(max,min,maxOut,minOut){
  a = (max - min)/(maxOut - minOut)
  b = max - maxOut*a
  hede = teval(paste0("function(x){(x - ",b,")/",a,'}'))
  hede
}
trimNAs = function(aVector) {
  return(aVector[!is.na(aVector)])
}
teval = function(daString){
  eval(parse(text=daString))
}

returnGameData = function(gameID){
    playByPlay = fread('data/playByPlayTrim.csv',stringsAsFactors = F,data.table = F)
    games = fread('data/cfl_games_trim.csv',data.table=F)
    games %<>% filter(sked_id==gameID)
    
    playByPlay %<>% filter(game_id==gameID) %>% 
        arrange(play_id)
    
    playByPlay$secondsQuarter = playByPlay$time %>% strsplit(':') %>% sapply(function(x){
        x %<>% as.numeric()
        900 - (x[1]*60*60 + x[2]*60 + x[3])
    }) + playByPlay$play_id * 0.00001
    playByPlay %<>% mutate(secondsTotal = secondsQuarter + (quarter-1)*15*60)
    
    home = games$home_initial
    homeID = games$home_id
    
    toYardFromHome = function(x){
        x %>% sapply(function(x){
            team = gsub("([0-9])*",'',x)
            yard = gsub("([A-Z]|[a-z])*",'',x) %>% as.numeric
            if (tolower(team)==home){
                return(yard)
            } else {
                return(110-yard)
            }
        })  
    }
    
    playByPlay$yardsFromHome = playByPlay$yardline %>% toYardFromHome
    
    
    
    playByPlay$end_yardsFromHome = playByPlay$end_yardline %>% toYardFromHome
    playByPlay %<>% mutate(homeIsHappy =  home_score_after - home_score_before,
                           awayIsHappy = away_score_after - away_score_before,
                           isHome = playByPlay$end_possession_id == homeID)
    
    
    # playByPlay$deltaYard[playByPlay$end_possession_id != homeID] %<>% -.
    
    playByPlay$epicEvent = playByPlay$name
    playByPlay$epicEvent[playByPlay$homeIsHappy >0 | playByPlay$awayIsHappy > 0] = 'SCORE!!!111' 
    playByPlay$epicEvent[!(playByPlay$epicEvent %in% c('Pass','Rush') |  playByPlay$homeIsHappy>0 | playByPlay$awayIsHappy >0)] = NA
    
    playByPlay$epicness = 0
    playByPlay$epicness[is.na(playByPlay$epicEvent)] = -9999
    playByPlay$epicness[playByPlay$homeIsHappy > 0 | playByPlay$awayIsHappy > 0] = 10
    playByPlay$epicness[playByPlay$homeIsHappy > 1 | playByPlay$awayIsHappy > 1] = 15
    playByPlay$epicness[playByPlay$homeIsHappy > 2 | playByPlay$awayIsHappy > 2] = 20
    playByPlay$epicness[playByPlay$homeIsHappy ==6 | playByPlay$awayIsHappy ==6 ] = 30
    
    outliers = (trimNAs(playByPlay$yards[playByPlay$epicness ==0]) %>% boxplot %>% .$out)
    outliers = outliers[outliers>0]
    
    outIds = playByPlay$play_id[playByPlay$epicness ==0][playByPlay$yards[playByPlay$epicness ==0] %in% outliers]
    
    
    playByPlay$epicness[playByPlay$play_id %in% outIds] = 20
    
    playByPlay$epicness[ playByPlay$epicness ==0] = (((playByPlay$yards[playByPlay$epicness==0]  %>% scale01)*8 ))+5
    playByPlay$epicness[playByPlay$epicness == -9999] = NA
    
    # playByPlay %>% select(time, quarter, secondsQuarter,secondsTotal,yardline ,yardsFromHome,end_yardsFromHome)
    # write.csv(playByPlay,file = 'data/playByPlayWithSecs.csv',quote =T ,row.names = F)
    
    # weather shit -------

    #Sys.setenv(FORECASTIO_API_KEY = '00ba2d55171f1bc6aa526291ff7df772')
    
    location = games$home_team
    if (location == "BC"){
        location = 'Vancouver'
    }
    
    
    # fahrenheit conversion
   # temperature = (weather$currently$temperature -32) * 5/ 9
  #  summary = weather$currently$summary
  #  rain = weather$currently$precipProbability
    return(list(playByPlay = playByPlay,
                game = games))
                #weather = list(temp = temperature, desc = summary,rain = rain)))
}