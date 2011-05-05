if exports?
  http        = require('http')
  querystring = require('querystring')
  OAuth       = require('oauth').OAuth

###
TwitPic class - defines API endpoints and is used to
interact with the API.
###
class TwitPic
  @baseUrl = "api.twitpic.com"
  @readOnly = true
  
  # All of the read-only API endpoints
  @read_endpoints = {
    'media/show':     ['id']
    'users/show':     ['username']
    'comments/show':  ['media_id', 'page']
    'place/show':     ['id']
    'places/show':    ['user']
    'events/show':    ['user']
    'event/show':     ['id']
    'tags/show':      ['tag']
  }
  
  # All of the write-enabled API endpoints
  @write_endpoints = {
    'comments/create':  ['media_id', 'message']
    'comments/delete':  ['comment_id']
    'faces/create':     ['media_id', 'top_coord', 'left_coord']
    'faces/edit':       ['tag_id', 'top_coord', 'left_coord']
    'faces/delete':     ['tag_id']
    'event/create':     ['name']
    'event/delete':     ['event_id']
    'event/add':        ['media_id', 'event_id']
    'event/remove':     ['media_id', 'event_id']
    'tags/create':      ['media_id', 'tags']
    'tags/delete':      ['media_id', 'tag_id']
  }
  
  # Factory method for querying the API
  @query = (endpoint, args, callback) ->
    api = endpoint.split "/"
    tp = new TwitPic()
    
    tp[api[0]][api[1]](args, callback)
    
  # Thumb API helper method
  @thumb = (image, size = "thumb", asImg = true) ->
    image = image.short_id if typeof image == "object"
    
    url = "http://twitpic.com/show/#{size}/#{image}"
    if asImg then "<img src=\"#{url}\" />" else url
    
  # Unique ID generator
  @uniqid = (->
    id = 0
    
    { get: -> id++ }
  )()
  
  constructor: ->
      
    # Generate all of the read-only API methods
    for own endpoint, requiredArgs of TwitPic.read_endpoints
      api = endpoint.split "/"
      this[api[0]] = {} if !this[api[0]]
      this[api[0]][api[1]] = ((endpoint, requiredArgs) ->
        (args, callback) ->
          API.getQuery("2/#{endpoint}", args, callback) if API.validate(args, requiredArgs)
      )(endpoint, requiredArgs)
    
    if exports?
      # Generate all of the write-enabled API methods ONLY if NodeJS is used
      self = this
      for own endpoint, requiredArgs of TwitPic.write_endpoints
        api = endpoint.split "/"
        this[api[0]] = {} if !this[api[0]]
        this[api[0]][api[1]] = ((endpoint, requiredArgs) ->
          (args, callback) ->
            throw "#{endpoint} requires an API key and OAuth credentials" if self.readOnly
            API.postQuery("2/#{endpoint}", self.creds, args, callback) if API.validate(args, requiredArgs)
        )(endpoint, requiredArgs)
    
    this.thumb = TwitPic.thumb
    
  config: (block) ->
    throw "Write-enabled API methods only supported in NodeJS" if !exports?
    
    conf = {}
    block(conf)
    
    @readOnly = false
    this.creds = conf
    
  upload: (file, message) ->
    # Do stuff
    
  uploadAndPost: (file, message) ->
    # Do stuff
  
###
API object that acts as a helper for the TwitPic class
when querying the API. It is no longer dependent on
jQuery for the JSONP calls.
###
API = {
  ###
  Validate the query based on the required args
  ###
  validate: (args, required) ->
    for own i, name of required
      if (!(args[name]))
        console.error("Missing required parameter: " + name)
        return false
    return true
    
  ###
  Generate and return the API query URL
  ###
  getQueryUrl: (url) ->
    callbackName = "TwitPic" + TwitPic.uniqid.get()

    if exports?
      queryUrl = "#{url}.json?"
    else
      queryUrl = "http://#{TwitPic.baseUrl}/#{url}.jsonp?callback=#{callbackName}"
      
    [queryUrl, callbackName]

  ###
  Send GET/JSONP request to read-only API endpoint
  ###
  getQuery: (url, data, callback) ->
    [queryUrl, callbackName] = this.getQueryUrl(url)
    
    args = []
    for own i, val of data
      args.push "#{i}=#{val}"
      
    queryUrl += (if exports? then "" else "&") + args.join('&')
    
    if window?
      # Running in browser
        
      head          = document.getElementsByTagName('head')[0]
      script        = document.createElement('script')
      script.type   = 'text/javascript'
      script.src    = queryUrl
      script.onload = ->
        delete window[callbackName]
        head.removeChild(script)
      
      window[callbackName] = (data) ->
        callback.call(new TwitPic(), data)
        
      head.appendChild(script)
    else
      # Running in node
      
      client = http.createClient(80, TwitPic.baseUrl)
      req = client.request("GET", "/#{queryUrl}", {host: TwitPic.baseUrl})

      req.on("response", (resp) ->
        resp.setEncoding('utf8')
        
        body = ""
        resp.on("data", (data) ->
          body += data
        )
        
        resp.on("end", (end) ->
          callback.call(new TwitPic(), JSON.parse(body))
        )
      )
      
      req.end()
      
  ###    
  Send POST request to write-enabled API endpoint.
  I know this is a little gross, but it's thanks
  to OAuth Echo, I swear.
  ###
  postQuery: (url, creds, data, callback) ->
    # Add the API key to the data
    data.key = creds.apiKey
    
    # Build the POST body
    postBody = querystring.stringify(data)
    
    # Build the OAuth helper
    oa = new OAuth(
      "https://twitter.com/oauth/request_token",
      "https://twitter.com/oauth/access_token",
      creds.consumerKey, creds.consumerSecret,
      "1.0A", null, "HMAC-SHA1"
    )
    
    # Build the custom headers
    headers = {
      "Host": "api.twitpic.com"
      "Connection": "close"
      "Accept": "*/*"
      "Content-Type": "application/x-www-form-urlencoded"
      "Content-Length": postBody.length
      "X-Verify-Credentials-Authorization": this.buildHeader(oa, creds)
    }
    
    # Create the HTTP client
    client = http.createClient(80, TwitPic.baseUrl)
    req = client.request("POST", "/#{url}.json", headers)
    
    req.on("response", (resp) ->
      resp.setEncoding('utf8')
      
      body = ""
      resp.on("data", (data) ->
        body += data
      )
      
      resp.on("end", (end) ->
        # Some API requests return data, some don't
        if body.length > 0
          data = JSON.parse(body)
        else
          data = {}
          
        # Call the user-supplied callback
        callback.call(new TwitPic(), data)
      )
    )
    
    # Write the POST data
    req.write(postBody)
    req.end()
    
  buildHeader: (oa, creds) ->
    # Create the OAuth params
    params = {
      "oauth_timestamp":        oa._getTimestamp()
      "oauth_nonce":            oa._getNonce(32)
      "oauth_version":          "1.0A"
      "oauth_signature_method": "HMAC-SHA1"
      "oauth_consumer_key":     creds.consumerKey
      "oauth_token":            creds.oauthToken
    }
    
    # Build the signature
    sig = oa._getSignature(
      "GET",
      "https://api.twitter.com/1/account/verify_credentials.json",
      oa._normaliseRequestParams(params),
      creds.oauthSecret
    )
    
    params['oauth_signature'] = sig
    
    # Create the actual header
    header = 'OAuth realm="http://api.twitter.com/"'
    for own name, value of params
      header += ", " + encodeURIComponent(name) + '="' + encodeURIComponent(value) + '"'
      
    return header
}

if exports?
  # Export for Node
  exports.TwitPic = TwitPic
else
  # Move to global window scope for browser
  window.TwitPic = TwitPic