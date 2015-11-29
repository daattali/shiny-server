window.onload = function() {
  $( "#time-wrapper" ).on( "click", ".gameevent", function(x){
    Shiny.onInputChange("gameeventclick", $(this).data("time"));
  });

  $( "#welcome_list" ).on( "click", ".welcome_row", function(x){
    Shiny.onInputChange("gamerowclick", $(this).data("gameinfo"));
  });  
};

setline = function(pos, end_pos, is_home) {
    if ($("#downline").data("pos") == pos) {
        return;
    }
    pos = 109 + 580 * pos / 110;
    end_pos = 109 + 580 * end_pos / 110;
    
    $("#downline").css("left", pos + "px");
    $("#downline2").css("left", end_pos + "px");
    $("#downline").data("pos", pos);
    if (is_home) {
      $("#game_page").removeClass("isaway");
      $("#game_page").addClass("ishome");
    } else {
      $("#game_page").removeClass("ishome");
      $("#game_page").addClass("isaway");
    }
    
    $("#downline").data("pos", pos);
    
    if (Math.abs(pos - end_pos) < 15) {
      $("#canvas-wrap").addClass("deltanone");
    } else if (pos < end_pos) {
      $("#canvas-wrap").removeClass("deltanone");
      $(".deltaline").css("left", pos + "px");
      $(".deltaline").css("width", (end_pos - pos - 5) + "px");
      $("#canvas-wrap").addClass("deltaright");
      $("#canvas-wrap").removeClass("deltaleft");
    } else {
      $("#canvas-wrap").removeClass("deltanone");
      $(".deltaline").css("left", (end_pos + 7) + "px");
      $(".deltaline").css("width", (pos - end_pos) + "px");
      $("#canvas-wrap").addClass("deltaleft");
      $("#canvas-wrap").removeClass("deltaright");
    }
};

playyoutube = function(youtube_info) {
  $("#youtubeplayer").attr('src', 'https://www.youtube.com/v/' +
     youtube_info['videoId'] + '?start=' + youtube_info['startSeconds'] + '&end=' + youtube_info['endSeconds'] + '&autoplay=1');
  return;
  videonum++;
  if (videonum == 1) {
    player = new YT.Player('youtubeplayer', {
      height: '390',
      width: '640',
      videoId: youtube_info['videoId'],
      playerVars : { start : youtube_info['startSeconds'],
                     end : youtube_info['endSeconds'] },
      events: {
        'onReady': function(event) { event.target.playVideo(); },
        'onStateChange': function(event) {
          if (event.data == 0) {
            console.log("now");
            Shiny.onInputChange("videodone", videonum);
          }
        }
      }
    }); 
  } else {
    player.loadVideoById(youtube_info);
  }
}

$().ready(function() {
  $('.container-fluid').tubular({videoId: 'pQ-TODedlzs'});
});