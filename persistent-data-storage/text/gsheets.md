#### Overview

You can store submitted responses in a Google Sheet. Google Sheets are great because they're extremely easy to access and edit from anywhere. For example, [the Google Sheet used in this app](https://docs.google.com/spreadsheets/d/126sYt93gzRGJE6n54CY1Z5VgyXl19btsy8zVweLvYu8) can be viewed by anyone and you can see it getting populated immediately after submitting a response.

Since all responses will be recorded in the same sheet, all the responses must have exactly the same fields.

#### Setup

All you need to do is create a Google Sheet and set the top row with the names of the fields.  You can either do that via the web or using the [googlesheets](https://github.com/jennybc/googlesheets) package. You also need to have a Google account, which I can safely assume you do.

#### Details

You can use the [googlesheets](https://github.com/jennybc/googlesheets) package to interact with Google Sheets from R. To connect to a specific sheet, you will need either the sheet's title or key (preferably key, as it's unique).
