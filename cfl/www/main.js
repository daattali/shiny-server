window.onload = function() {
  clear();
  $( "#time-wrapper" ).on( "click", ".gameevent", function(x){
    Shiny.onInputChange("gameeventclick", $(this).data("time"));
  });

  $( "#welcome_list" ).on( "click", ".welcome_row", function(x){
    Shiny.onInputChange("gamerowclick", $(this).data("gameinfo"));
  });  
};

clear = function() {
  setline(55, false);
};

setline = function(num, animate) {
    if ($("#downline").data("pos") == num) {
        return;
    }
    var pos = 109 + 580 * num / 110;
    if (!animate) {
      $("#downline").removeClass("animate");
    }
    $("#downline").css("left", pos + "px");
    if (!animate) {
      $("#downline").addClass("animate");
    }
    $("#downline").data("pos", num);
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