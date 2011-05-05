(function() {
  var API, TwitPic, http;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (typeof exports !== "undefined" && exports !== null) {
    http = require('http');
  }
  /*
  TwitPic class - defines API endpoints and is used to
  interact with the API.
  */
  TwitPic = (function() {
    TwitPic.conflict = false;
    TwitPic.baseUrl = "api.twitpic.com";
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
    function TwitPic() {
      var api, endpoint, endpoints, requiredArgs;
      endpoints = {
        'media/show': ['id'],
        'users/show': ['username'],
        'comments/show': ['media_id', 'page'],
        'place/show': ['id'],
        'places/show': ['user'],
        'events/show': ['user'],
        'event/show': ['id'],
        'tags/show': ['tag']
      };
      for (endpoint in endpoints) {
        if (!__hasProp.call(endpoints, endpoint)) continue;
        requiredArgs = endpoints[endpoint];
        api = endpoint.split("/");
        if (!this[api[0]]) {
          this[api[0]] = {};
        }
        this[api[0]][api[1]] = (function(endpoint, requiredArgs) {
          return function(args, callback) {
            if (API.validate(requiredArgs)) {
              return API.query("2/" + endpoint, args, callback);
            }
          };
        })(endpoint, requiredArgs);
      }
      this.thumb = TwitPic.thumb;
    }
    return TwitPic;
  })();
  /*
  API object that acts as a helper for the TwitPic class
  when querying the API. It is no longer dependent on
  jQuery for the JSONP calls.
  */
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
    query: function(url, data, callback) {
      var args, callbackName, client, head, i, queryUrl, req, script, val;
      callbackName = "TwitPic" + (new Date()).getTime();
      if (typeof exports !== "undefined" && exports !== null) {
        queryUrl = "" + url + ".json?";
      } else {
        queryUrl = "http://" + TwitPic.baseUrl + "/" + url + ".jsonp?callback=" + callbackName;
      }
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
    }
  };
  if (typeof exports !== "undefined" && exports !== null) {
    exports.TwitPic = TwitPic;
  } else {
    window.TwitPic = TwitPic;
  }
}).call(this);
