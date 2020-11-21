#### Overview

You can store submitted responses in a mongoDB database. MongoDB is a popular NoSQL database that can be hosted either locally or remotely.

Being NoSQL means that the database is schema-less. That means that different responses can have different fields, so it's easy to change the form to have different fields (though doing that will make aggregating all the responses more tricky).

#### Setup

All you need to do is create a mongoDB database. Since there is no schema, it's not mandatory to create a collection (collection in mongoDB = table in SQL) before populating it. You can either install mongoDB locally, remotely, or use a web service that provides mongoDB hosting such as [mongoDB Atlas](https://www.mongodb.com/cloud/atlas).

#### Details

You can use the [mongolite](https://github.com/jeroen/mongolite) package to interact with mongoDB from R. To connect to the database you need to provide the following: db, host, username, password.
