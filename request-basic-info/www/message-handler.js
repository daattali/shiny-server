// support for confirmation dialog - disabled
if (false) {
  // This recieves messages of type "dialogContentUpdate" from the server.
  Shiny.addCustomMessageHandler("dialogContentUpdate",
    function(data) {
      $('#' + data.id).find(".modal-body").html(data.message);
    }
  );
}

Shiny.addCustomMessageHandler("disableBtn",
  function(message) {
    $('#' + message.id).attr("disabled", "true");
  }
);

Shiny.addCustomMessageHandler("enableBtn",
  function(message) {
    $('#' + message.id).removeAttr('disabled');
  }
);

Shiny.addCustomMessageHandler("alert",
  function(message) {
    alert(message.msg);
  }
);

Shiny.addCustomMessageHandler("jsCode",
  function(message) {
    eval(message.code);
  }
);

function toggleVisibility(id) {
  var e = document.getElementById(id);
  if(e.style.display == "none")
    e.style.display = "block";
  else
    e.style.display = "none";
}  