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

Shiny.addCustomMessageHandler("show",
  function(message) {
    show(message.id);
  }
);

Shiny.addCustomMessageHandler("hide",
  function(message) {
    hide(message.id);
  }
);
