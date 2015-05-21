#### Overview

The easiest way to store submitted responses is by simply saving each response **locally** as a separate text file. Locally means that the files get saved on the same machine that is running the shiny app.  

Since the responses are saved locally, this can only be used if you have access to the machine hosting the app and if you trust its filesystem.  If you don't know what machine the app is hosted on, or if the files could get deleted, do not use this method. **This approach will not work if hosting on shinyapps.io** because of those reasons.  

Since each response is its own file, different responses can have different fields, so it's easy to change the form to have different fields (though doing that will make aggregating all the responses more tricky).

#### Setup

This approach is very simple and easy to implement. The only required setup is to create a directory where you want the responses to be saved, and ensure the shiny app has write permissions.

#### Details

When saving the files, it is important to ensure that files get different names (so that two responses won't overwrite each other). My simple solution is to include 3 things in the filename for each response: the md5 hash of the response's content, some random number, the time of submission.

When loading the responses, simply read each file separately and concatenate them all into one dataframe.
