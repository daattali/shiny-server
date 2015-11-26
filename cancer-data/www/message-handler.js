// This file listens for messages from the shiny app and
// redirects them to javascript

Shiny.addCustomMessageHandler("equalizePlotHeight",
  function(message) {
    equalizePlotHeight(message.target, message.by);
  }
);
