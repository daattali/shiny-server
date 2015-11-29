shinyjs.setline = function(params) {
  var defaultParams = {
    pos : 0,
    end_pos : 0,
    is_home : false
  };
  params = shinyjs.getParams(params, defaultParams);
  setline(params.pos, params.end_pos, params.is_home);
}

shinyjs.newgame = function(gameinfo) {
  window.scrollTo(0, 0);
  gameinfo = gameinfo[0];
  $("#homename").text(gameinfo['home_team']);
  $("#awayname").text(gameinfo['away_team']);
  $("#homescore").text("0");
  $("#awayscore").text("0");
  $("#awaylogo").attr('src', "img/" + gameinfo['away_team'] + ".png");
  $("#homelogo").attr('src', "img/" + gameinfo['home_team'] + ".png");
  $("#lineaway").attr('src', "img/" + gameinfo['away_team'] + ".png");
  $("#linehome").attr('src', "img/" + gameinfo['home_team'] + ".png");
  $("#action-bar-homelogo").attr('src', "img/" + gameinfo['home_team'] + ".png");
  $("#action-bar-awaylogo").attr('src', "img/" + gameinfo['away_team'] + ".png");
  $("#weathertmp").html(Math.round(gameinfo['temp']*10)/10 + "&deg;");
  $("#icon").text(gameinfo['weathericon']);
  $("#weathericon").attr('src', "img/" + gameinfo['icon'] + ".png");
}

shinyjs.playyoutube = function(youtube_info) {
  playyoutube(youtube_info[0]);
}