(function() {
  var API, OAuth, OAuthEcho, TwitPic, fs, http, mime, querystring;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (typeof exports !== "undefined" && exports !== null) {
    fs = require('fs');
    http = require('http');
    mime = require('mime');
    querystring = require('querystring');
    OAuth = require('oauth').OAuth;
    OAuthEcho = require('oauth').OAuthEcho;
  }
  TwitPic = (function() {
    TwitPic.baseUrl = "api.twitpic.com";
    TwitPic.readOnly = true;
    TwitPic.read_endpoints = {
      'media/show': ['id'],
      'users/show': ['username'],
      'comments/show': ['media_id', 'page'],
      'place/show': ['id'],
      'places/show': ['user'],
      'events/show': ['user'],
      'event/show': ['id'],
      'tags/show': ['tag']
    };
    TwitPic.write_endpoints = {
      'comments/create': ['media_id', 'message'],
      'comments/delete': ['comment_id'],
      'faces/create': ['media_id', 'top_coord', 'left_coord'],
      'faces/edit': ['tag_id', 'top_coord', 'left_coord'],
      'faces/delete': ['tag_id'],
      'event/create': ['name'],
      'event/delete': ['event_id'],
      'event/add': ['media_id', 'event_id'],
      'event/remove': ['media_id', 'event_id'],
      'tags/create': ['media_id', 'tags'],
      'tags/delete': ['media_id', 'tag_id']
    };
    TwitPic.query = function(endpoint, args, callback) {
      var api, tp;
      api = endpoint.split("/");
      tp = new TwitPic();
      return tp[api[0]][api[1]](args, callback);
    };
    TwitPic.thumb = function(image, size, asImg) {
      var url;
      if (size == null) {
        size = "thumb";
      }
      if (asImg == null) {
        asImg = true;
      }
      if (typeof image === "object") {
        image = image.short_id;
      }
      url = "http://twitpic.com/show/" + size + "/" + image;
      if (asImg) {
        return "<img src=\"" + url + "\" />";
      } else {
        return url;
      }
    };
    TwitPic.uniqid = (function() {
      var id;
      id = 0;
      return {
        get: function() {
          return id++;
        }
      };
    })();
    function TwitPic() {
      var api, endpoint, requiredArgs, self, _ref, _ref2;
      _ref = TwitPic.read_endpoints;
      for (endpoint in _ref) {
        if (!__hasProp.call(_ref, endpoint)) continue;
        requiredArgs = _ref[endpoint];
        api = endpoint.split("/");
        if (!this[api[0]]) {
          this[api[0]] = {};
        }
        this[api[0]][api[1]] = (function(endpoint, requiredArgs) {
          return function(args, callback) {
            if (API.validate(args, requiredArgs)) {
              return API.getQuery("2/" + endpoint, args, callback);
            }
          };
        })(endpoint, requiredArgs);
      }
      if (typeof exports !== "undefined" && exports !== null) {
        self = this;
        _ref2 = TwitPic.write_endpoints;
        for (endpoint in _ref2) {
          if (!__hasProp.call(_ref2, endpoint)) continue;
          requiredArgs = _ref2[endpoint];
          api = endpoint.split("/");
          if (!this[api[0]]) {
            this[api[0]] = {};
          }
          this[api[0]][api[1]] = (function(endpoint, requiredArgs) {
            return function(args, callback) {
              if (self.readOnly) {
                throw "/" + endpoint + " requires an API key and OAuth credentials";
              }
              if (API.validate(args, requiredArgs)) {
                return API.postQuery("2/" + endpoint, self.creds, args, callback);
              }
            };
          })(endpoint, requiredArgs);
        }
      }
      this.thumb = TwitPic.thumb;
    }
    TwitPic.prototype.config = function(block) {
      var conf;
      if (!(typeof exports !== "undefined" && exports !== null)) {
        throw "Write-enabled API methods only supported in NodeJS";
      }
      conf = {};
      block(conf);
      this.readOnly = false;
      return this.creds = conf;
    };
    TwitPic.prototype.upload = function(opts, callback) {
      var mimeType;
      if (this.readOnly) {
        throw "/upload requires an API key and OAuth credentials";
      }
      mimeType = mime.lookup(opts.path);
      opts.media = ("data:" + mimeType + ";base64,") + fs.readFileSync(opts.path, 'base64');
      delete opts.path;
      if (opts.message === null) {
        opts.message = "";
      }
      return API.postQuery("2/upload", this.creds, opts, callback);
    };
    TwitPic.prototype.uploadAndPost = function(opts, callback) {
      var creds;
      creds = this.creds;
      return this.upload(opts, function(data) {
        var oa, tweet;
        tweet = "" + opts.message + " " + data.url;
        oa = new OAuth("http://twitter.com/oauth/request_token", "http://twitter.com/oauth/access_token", creds.consumerKey, creds.consumerSecret, "1.0A", null, "HMAC-SHA1");
        return oa.post("http://api.twitter.com/1/statuses/update.json", creds.oauthToken, creds.oauthSecret, {
          "status": tweet
        }, function(error, data2) {
          return callback.call(new TwitPic(), data);
        });
      });
    };
    return TwitPic;
  })();
  API = {
    validate: function(args, required) {
      var i, name;
      for (i in required) {
        if (!__hasProp.call(required, i)) continue;
        name = required[i];
        if (!args[name]) {
          console.error("Missing required parameter: " + name);
          return false;
        }
      }
      return true;
    },
    getQueryUrl: function(url) {
      var callbackName, queryUrl;
      callbackName = "TwitPic" + (TwitPic.uniqid.get());
      queryUrl = typeof exports !== "undefined" && exports !== null ? "" + url + ".json?" : "http://" + TwitPic.baseUrl + "/" + url + ".jsonp?callback=" + callbackName;
      return [queryUrl, callbackName];
    },
    getQuery: function(url, data, callback) {
      var args, callbackName, client, head, i, queryUrl, req, script, val, _ref;
      _ref = this.getQueryUrl(url), queryUrl = _ref[0], callbackName = _ref[1];
      args = [];
      for (i in data) {
        if (!__hasProp.call(data, i)) continue;
        val = data[i];
        args.push("" + i + "=" + val);
      }
      queryUrl += (typeof exports !== "undefined" && exports !== null ? "" : "&") + args.join('&');
      if (typeof window !== "undefined" && window !== null) {
        head = document.getElementsByTagName('head')[0];
        script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = queryUrl;
        script.onload = function() {
          delete window[callbackName];
          return head.removeChild(script);
        };
        window[callbackName] = function(data) {
          return callback.call(new TwitPic(), data);
        };
        return head.appendChild(script);
      } else {
        client = http.createClient(80, TwitPic.baseUrl);
        req = client.request("GET", "/" + queryUrl, {
          host: TwitPic.baseUrl
        });
        req.on("response", function(resp) {
          var body;
          resp.setEncoding('utf8');
          body = "";
          resp.on("data", function(data) {
            return body += data;
          });
          return resp.on("end", function(end) {
            return callback.call(new TwitPic(), JSON.parse(body));
          });
        });
        return req.end();
      }
    },
    postQuery: function(url, creds, data, callback) {
      var oae;
      url = "http://" + TwitPic.baseUrl + "/" + url + ".json";
      data.key = creds.apiKey;
      oae = new OAuthEcho('http://api.twitter.com/', 'https://api.twitter.com/1/account/verify_credentials.json', creds.consumerKey, creds.consumerSecret, "1.0A", "HMAC-SHA1");
      return oae.post(url, creds.oauthToken, creds.oauthSecret, data, function(error, data, resp) {
        if (error) {
          console.log(error);
        }
        return callback.call(new TwitPic(), JSON.parse(data));
      });
    }
  };
  if (typeof exports !== "undefined" && exports !== null) {
    exports.TwitPic = TwitPic;
  } else {
    window.TwitPic = TwitPic;
  }
}).call(this);
