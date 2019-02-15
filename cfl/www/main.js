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
  $("#youtubeplayer").attr('src', 'https://www.youtube.com/embed/' +
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
            Shiny.onInputChange("videodone", videonum);
          }
        }
      }
    }); 
  } else {
    player.loadVideoById(youtube_info);
  }
};

$().ready(function() {
  $( "#time-wrapper" ).on( "click", ".gameevent", function(x){
    Shiny.onInputChange("gameeventclick", $(this).data("time"));
  });

  $( "#welcome_list" ).on( "click", ".welcome_row", function(x){
    Shiny.onInputChange("gamerowclick", [$(this).data("gameinfo"), Math.random()]);
  });
  
  videoId = 'pQ-TODedlzs';
  var tag = document.createElement('script');

  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

  calculateBgYTDims();
});

function onYouTubeIframeAPIReady() {
  player = new YT.Player('bg_youtube_player', {
    playerVars: { 'autoplay': 1, 'controls': 0,
                  'wmode':'transparent', 'showinfo' : 0, 'loop' : 1,
                  'playlist' : videoId, 'modestbranding' : 1
    },
    videoId: videoId,
    events: {
      'onReady': function(event) {
        event.target.mute();
        event.target.playVideo();
      }
    }
  });
}

window.onresize = function(event) {
  calculateBgYTDims();
};

calculateBgYTDims = function() {
  var w = $(window).width();
  var h = $(window).height();
  var ratio = 0.563;
  if (w*ratio > h) {
    $('#bg_youtube_player').width(w);
    $('#bg_youtube_player').height(w*ratio);
    $('#bg_youtube_player').css('left', '0');
    $('#bg_youtube_player').css('top', ((w*ratio) - h) / -2);
  } else {
    $('#bg_youtube_player').height(h);
    $('#bg_youtube_player').width(h/ratio);
    $('#bg_youtube_player').css('top', '0');
    $('#bg_youtube_player').css('left', ((h/ratio) - w) / -2);
  }
};
