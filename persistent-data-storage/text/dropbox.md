#### Overview

You can save each submitted response in a separate text file and store the files remotely. There are many options for online file storage, and this method uses Dropbox. Dropbox allows you to host any type of file, as long as your account has enough free space. This is very similar to the "Text file" method, but the files are stored online instead of locally.

Since each response is its own file, different responses can have different fields, so it's easy to change the form to have different fields (though doing that will make aggregating all the responses more tricky).

#### Setup

You need to have a [Dropbox](https://www.dropbox.com/) account and create a folder that will contain all the responses. Dropbox gives you some free space, which should be plenty if all you're doing is hosting text files.

#### Details

You can use the [rdrop2](https://github.com/karthik/rdrop2) package to interact with Dropbox from R. 

Saving and loading the responses are both very similar to the approaches taken with the "Text file" method. The only difference is that now the responses are being saved to and loaded from Dropbox instead of the local filesystem.
