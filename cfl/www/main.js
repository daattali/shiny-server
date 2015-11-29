var videonum = 0;
var player;

window.onload = function() {
  clear();
  $( "#time-wrapper" ).on( "click", ".gameevent", function(x){
    Shiny.onInputChange("gameeventclick", $(this).data("time"));
  });

  $( "#welcome_list" ).on( "click", ".welcome_row", function(x){
    Shiny.onInputChange("gamerowclick", $(this).data("gameinfo"));
  });  

  // load youtube
  var tag = document.createElement('script');

  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

  function onYouTubeIframeAPIReady() {
    console.log("youtube ready");
  }
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

playyoutube = function(youtube_id) {
  videonum++;
  if (videonum == 1) {
    player = new YT.Player('youtubeplayer', {
      height: '390',
      width: '640',
      videoId: youtube_id,
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
    player.loadVideoById(youtube_id);
  }
}