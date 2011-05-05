# About

The TwitPic object provides full access to the read-only part of the TwitPic API. If you need write access to the API, you may want to check out the [TwitPic API for PHP](http://github.com/meltingice/TwitPic-API-for-PHP) or [TwitPic API for Ruby](http://github.com/meltingice/TwitPic-API-for-Ruby) projects.

This library is no longer dependent on jQuery, and is now written in Coffeescript. The minified compiled JS output is only 3KB :)

## NodeJS

This library is also compatible with NodeJS. Currently, it still only supports the read-only API, but I would like to add full API access in the near future.

**Install with npm**

    npm install twitpic

# Example Usage

Simply include lib/twitpic.min.js (or the full version) in a script tag on your webpage to load the TwitPic API library.

## In-Browser Usage

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
	
# Supported API Endpoints

* media/show
* users/show
* comments/show
* place/show
* places/show
* events/show
* event/show
* tags/show
* thumb api