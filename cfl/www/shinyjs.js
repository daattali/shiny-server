shinyjs.clear = function() {
  clear();
}

shinyjs.setline = function(num) {
  setline(num[0], true);
}

shinyjs.newgame = function(gameinfo) {
  gameinfo = gameinfo[0];
  $("#homename").text(gameinfo['home_team']);
  $("#awayname").text(gameinfo['away_team']);
  $("#homescore").text("0");
  $("#awayscore").text("0");
  $("#awaylogo").attr('src', "img/" + gameinfo['away_team'] + ".png");
  $("#homelogo").attr('src', "img/" + gameinfo['home_team'] + ".png");
  $("#action-bar-homelogo").attr('src', "img/" + gameinfo['home_team'] + ".png");
    $("#action-bar-awaylogo").attr('src', "img/" + gameinfo['away_team'] + ".png");
}

shinyjs.playyoutube = function(youtube_id) {
  playyoutube(youtube_id[0]);
}