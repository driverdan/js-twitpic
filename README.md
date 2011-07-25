# About

The TwitPic object provides read-only access in the browser, and full access (including photo uploads) in NodeJS, to the TwitPic API.

This library is no longer dependent on jQuery, and is now written in Coffeescript.

## NodeJS

The NodeJS version has support for write-enabled API methods using OAuth Echo (requires node-oauth library).

**Install with npm**

    npm install twitpic

# Example Usage

## In-Browser Usage

Simply include lib/twitpic.min.js (or the full version) in a script tag on your webpage to load the TwitPic API library.

There are two separate ways you can query the API:

**Object Instantiation**

``` js
var tp = new TwitPic();
tp.media.show({id: '3'}, function (image) {
  document.getElementById('image').innerHTML = this.thumb(image, 'mini');
});
```

**Factory Method**

``` js
TwitPic.query('media/show', {id: '3'}, function (image) {
  document.getElementById('image').innerHTML = this.thumb(image, 'mini');
});
```

## NodeJS Usage

**Object Instantiation**

``` js
var TwitPic = require('twitpic').TwitPic;

var tp = new TwitPic();
tp.users.show({username: 'meltingice'}, function (user) {
  console.log(user);
});
```

**Factory Method**

``` js
var TwitPic = require('twitpic').TwitPic;

TwitPic.query('users/show', {username: 'meltingice'}, function (user) {
  console.log(user);
});
```

**Write-Enabled API Query**

Note that this assumes you already have all of the required credentials before making this call.

``` js
var TwitPic = require('twitpic').TwitPic;

// Must create a TwitPic object for write-enabled methods
var tp = new TwitPic();

// Configure the TwitPic object with our credentials
tp.config(function (config) {
  config.apiKey = "your TwitPic API key";
  config.consumerKey = "Your apps consumer key";
  config.consumerSecret = "Your apps consumer secret";
  config.oauthToken = "The users oauth token";
  config.oauthSecret = "The users oauth secret";
});

// Post a comment on twitpic.com/abc123
tp.comments.create({media_id: "abc123", message: "BOOM!"}, function (data) {
  console.log(data);
});

// Upload a photo and post a tweet
tp.uploadAndPost({path: "./test.jpg", message: "Uploading from Node :)"}, function (data) {
  console.log(data);
});
```
	
# Supported API Endpoints

See the [official TwitPic API docs](http://dev.twitpic.com/docs) for more information. Otherwise, here's a quick list of all the available API endpoints:

**Read-Only Endpoints**

* media/show
* users/show
* comments/show
* place/show
* places/show
* events/show
* event/show
* tags/show
* thumb api

**Write-Enabled Endpoints**

* upload
* uploadAndPost
* comments/create
* comments/delete
* faces/create
* faces/edit
* faces/delete
* event/create
* event/delete
* event/add
* event/remove
* tags/create
* tags/delete
