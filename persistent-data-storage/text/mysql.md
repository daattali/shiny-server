#### Overview

You can store submitted responses in a MySQL database. MySQL is a popular relational database that can be hosted either locally or remotely. 

Since SQL tables have a schema, all the responses must have exactly the same fields.

#### Setup

You need to create a MySQL database and a table that will store all the responses. You can either install MySQL locally, install MySQL on a remote machine, or just find a web service that hosts MySQL databases. Make sure the table contains all the column names that your form has. For example, if your form has fields "name" and "email" then you can create the SQL table with `CREATE TABLE mytable(name TEXT, email TEXT);`.

#### Details

You can use the [RMySQL](https://github.com/rstats-db/RMySQL) package to interact with MySQL from R. To connect to the database you need to provide the following: host, port, dbname, user, password. Note that R does not currently have support for prepared statements, so the SQL statements have to be constructed manually.
