# validate the student number
validateStudentNum <- function(x) {
  return(grepl("^[0-9]{4}$", x, perl=T))
}

# get a formatted string of the timestamp (exclude colons as they are invalid
# characters in Windows filenames)
getFormattedTimestamp <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%OS")
}

# support for confirmation dialog - disabled
if (FALSE) {
  modalDialog = function(id, header = "Confirmation", body = "Are you sure?", footer = list(actionButton("confirmDlgOkBtn", "OK"))){
    div(id = id, class = "modal fade",
        div(class = "modal-dialog",
            div(class = "modal-content",
                div(class = "modal-header",
                    tags$button(type = "button", class = "close", 'data-dismiss' = "modal", 'aria-hidden' = "true", HTML('&times;')),
                    tags$h4(class = "modal-title", header)
                ),
                div(class = "modal-body",
                    tags$p(body)
                ),
                div(class = "modal-footer",
                    tagList(footer)
                )
            )
        )
    )
  }
  
  modalTriggerButton = function(inputId, target, label, icon = NULL){
    if (!is.null(icon)) 
      buttonContent <- list(icon, label)
    else buttonContent <- label
    tags$button(id = inputId, type = "button", class = "btn action-button btn-primary",
                'data-toggle' = "modal", 'data-target' = target,
                buttonContent)
  }
}
