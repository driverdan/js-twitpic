# TwitPic API for Javascript
# This library provides read-only access in the browser, 
# and full access (including photo uploads) in NodeJS, to the TwitPic API.
#
# Version 3.0.0

if exports?
  fs          = require('fs')
  http        = require('http')
  mime        = require('mime')
  querystring = require('querystring')
  OAuth       = require('oauth').OAuth
  OAuthEcho   = require('oauth').OAuthEcho

# TwitPic class - defines API endpoints and is used to
# interact with the API.
class TwitPic
  @baseUrl = "api.twitpic.com"
  @readOnly = true
  
  # All of the read-only API endpoints
  @read_endpoints =
    'media/show':     ['id']
    'users/show':     ['username']
    'comments/show':  ['media_id', 'page']
    'place/show':     ['id']
    'places/show':    ['user']
    'events/show':    ['user']
    'event/show':     ['id']
    'tags/show':      ['tag']
  
  # All of the write-enabled API endpoints
  @write_endpoints =
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
  @uniqid = do ->
    id = 0
    get: -> id++
  
  constructor: ->
      
    # Generate all of the read-only API methods
    for own endpoint, requiredArgs of TwitPic.read_endpoints
      api = endpoint.split "/"
      this[api[0]] = {} if !this[api[0]]
      this[api[0]][api[1]] = do (endpoint, requiredArgs) ->
        (args, callback) ->
          API.getQuery("2/#{endpoint}", args, callback) if API.validate(args, requiredArgs)
    
    if exports?
      # Generate all of the write-enabled API methods ONLY if NodeJS is used
      self = this
      for own endpoint, requiredArgs of TwitPic.write_endpoints
        api = endpoint.split "/"
        this[api[0]] = {} if !this[api[0]]
        this[api[0]][api[1]] = do (endpoint, requiredArgs) ->
          (args, callback) ->
            throw "/#{endpoint} requires an API key and OAuth credentials" if self.readOnly
            API.postQuery("2/#{endpoint}", self.creds, args, callback) if API.validate(args, requiredArgs)
    
    this.thumb = TwitPic.thumb
    
  config: (block) ->
    throw "Write-enabled API methods only supported in NodeJS" if !exports?
    
    conf = {}
    block(conf)
    
    @readOnly = false
    @creds = conf
    
  upload: (opts, callback) ->
    throw "/upload requires an API key and OAuth credentials" if @readOnly
    
    # Load the contents of the file into a string
    mimeType = mime.lookup opts.path
    opts.media = "data:#{mimeType};base64," + fs.readFileSync(opts.path, 'base64')
    delete opts.path
    
    # Empty default message
    opts.message = "" if opts.message is null
    
    # Make the query
    API.postQuery("2/upload", this.creds, opts, callback)
    
  uploadAndPost: (opts, callback) ->
    creds = this.creds
    
    this.upload(opts, (data) ->
      # Image was posted, prepare to tweet
      tweet = "#{opts.message} #{data.url}"
      
      oa = new OAuth(
        "http://twitter.com/oauth/request_token",
        "http://twitter.com/oauth/access_token", 
        creds.consumerKey, creds.consumerSecret,
        "1.0A", null, "HMAC-SHA1"
      )
     
      oa.post(
        "http://api.twitter.com/1/statuses/update.json",
        creds.oauthToken, creds.oauthSecret,
        {"status": tweet},
        (error, data2) ->
          callback.call(new TwitPic(), data)
      )
    )

# API object that acts as a helper for the TwitPic class
# when querying the API. It is no longer dependent on
# jQuery for the JSONP calls.
API =

  # Validate the query based on the required args
  validate: (args, required) ->
    for own i, name of required
      if !(args[name])
        console.error("Missing required parameter: " + name)
        return false
    return true
    
  # Generate and return the API query URL
  getQueryUrl: (url) ->
    callbackName = "TwitPic#{TwitPic.uniqid.get()}"
    queryUrl = if exports? then "#{url}.json?" else "http://#{TwitPic.baseUrl}/#{url}.jsonp?callback=#{callbackName}"
    [queryUrl, callbackName]

  # Send GET/JSONP request to read-only API endpoint
  getQuery: (url, data, callback) ->
    [queryUrl, callbackName] = this.getQueryUrl(url)
    
    args = []
    args.push "#{i}=#{val}" for own i, val of data
      
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
      
      window[callbackName] = (data) -> callback.call(new TwitPic(), data)

      head.appendChild(script)
    else
      # Running in node
      
      client = http.createClient(80, TwitPic.baseUrl)
      req = client.request "GET", "/#{queryUrl}", {host: TwitPic.baseUrl}

      req.on "response", (resp) ->
        resp.setEncoding 'utf8'
        
        body = ""
        resp.on "data", (data) -> body += data
        resp.on "end", (end) -> callback.call(new TwitPic(), JSON.parse(body))
      
      req.end()
      
  # Send POST request to write-enabled API endpoint.
  postQuery: (url, creds, data, callback) ->
    url = "http://#{TwitPic.baseUrl}/#{url}.json"
    
    # Add the API key to the data
    data.key = creds.apiKey 
    oae = new OAuthEcho(
      'http://api.twitter.com/',
      'https://api.twitter.com/1/account/verify_credentials.json',
      creds.consumerKey,
      creds.consumerSecret,
      "1.0A",
      "HMAC-SHA1"
    )

    oae.post url, creds.oauthToken, creds.oauthSecret, data, (error, data, resp) ->
      console.log error if error
      callback.call(new TwitPic(), JSON.parse(data))

if exports?
  # Export for Node
  exports.TwitPic = TwitPic
else
  # Move to global window scope for browser
  window.TwitPic = TwitPic