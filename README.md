# About

The TwitPic object provides full access to the read-only part of the TwitPic API (due to browser security restrictions). If you need write access to the API, you may want to check out the [TwitPic API for PHP](http://github.com/meltingice/TwitPic-API-for-PHP) or [TwitPic API for Ruby](http://github.com/meltingice/TwitPic-API-for-Ruby) projects.

This library is no longer dependent on jQuery, and is now written in Coffeescript. The minified compiled JS output is only 2KB :)

# Example Usage

Simply include lib/TwitPic_API.min.js (or the full version) in a script tag on your webpage to load the TwitPic API library.

## Basic Usage

There are two separate ways you can query the API:

**Object Instantiation**

    var tp = new TwitPic();
    tp.media.show({id: '3'}, function (image) {
      document.getElementById('image').innerHTML = this.thumb(image, 'mini');
    });
	
**Factory Method**

    TwitPic.query('media/show', {id: '3'}, function (image) {
      document.getElementById('image').innerHTML = this.thumb(image, 'mini');
    });
	
## Advanced Usage

Well... maybe not too advanced. You get the idea.

    TwitPic.query('tags/show', {tag: 'FromSpace'}, function (tag) {
      for (var image in tag.images) {
        if (!tag.images.hasOwnProperty(image)) { continue; }
      
        var img = document.createElement('img');
        img.src = this.thumb(tag.images[image], 'thumb', false);
        
        document.getElementById('image').appendChild(img);
      }
    });
	
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