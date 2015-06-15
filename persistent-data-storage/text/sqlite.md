#### Overview

You can store submitted responses in a SQLite database. SQLite is a very simple and light-weight relational database that is very easy to set up. SQLite is serverless, which means it stores the database **locally** on the same machine that is running the shiny app.

Since the responses are saved locally, this can only be used if you have access to the machine hosting the app and if you trust its filesystem.  If you don't know what machine the app is hosted on, or if the files could get deleted, do not use this method. **This approach will not work if hosting on shinyapps.io** because of those reasons.  

Since SQL tables have a schema, all the responses must have exactly the same fields.

#### Setup

First, you need to have SQLite installed on your machine. Installation is fairly easy: for a [DigitalOcean](http://deanattali.com/2015/05/09/setup-rstudio-shiny-server-digital-ocean/) Ubuntu machine, you just need to run `sudo apt-get install sqlite3 libsqlite3-dev`.

You also need to create a database and a table that will store all the responses. Make sure the table contains all the column names that your form has. For example, if your form has fields "name" and "email" then you can create the SQL table with `CREATE TABLE mytable(name TEXT, email TEXT);`.  Make sure the shiny app has write permissions on that file and its parent directory.

#### Details

You can use the [RSQlite](https://github.com/rstats-db/RSQLite) package to interact with SQLite from R. To connect to the database you just need to provide the path to the database file. Note that R does not currently have support for prepared statements, so the SQL statements have to be constructed manually.
