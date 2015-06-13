#### Overview

You can store submitted responses in a Google Sheet. Google Sheets are great because they're extremely easy to access and edit from anywhere.

Since all responses will be recorded in the same sheet, all the responses must have exactly the same fields.

#### Setup

All you need to do is create a Google Sheet and set the top row with the names of the fields.  You can either do that via the web or using the [googlesheets](https://github.com/jennybc/googlesheets) package. You also need to have a Google account, which I can safely assume you do.

#### Details

You can use the [googlesheets](https://github.com/jennybc/googlesheets) package to interact with Google Sheets from R. To connect to a specific sheet, you will need either the sheet's title or key (preferably key, as it's unique). When submitting a neW response, you need to know the current size of the sheet in order to know what cells to edit so that the response is not overwriting anyone else.