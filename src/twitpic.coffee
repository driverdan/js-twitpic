http = require('http') if exports?

###
TwitPic class - defines API endpoints and is used to
interact with the API.
###
class TwitPic
  @conflict = false
  @baseUrl = "api.twitpic.com"
  
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
  
  constructor: ->
    # All of the read-only API endpoints
    endpoints = {
      'media/show':     ['id']
      'users/show':     ['username']
      'comments/show':  ['media_id', 'page']
      'place/show':     ['id']
      'places/show':    ['user']
      'events/show':    ['user']
      'event/show':     ['id']
      'tags/show':      ['tag']
    }
    
    # Generate all of the API methods
    for own endpoint, requiredArgs of endpoints
      api = endpoint.split "/"
      this[api[0]] = {} if !this[api[0]]
      this[api[0]][api[1]] = ((endpoint, requiredArgs) ->
        (args, callback) ->
          API.query("2/#{endpoint}", args, callback) if API.validate(requiredArgs)
      )(endpoint, requiredArgs)
    
    this.thumb = TwitPic.thumb

  
###
API object that acts as a helper for the TwitPic class
when querying the API. It is no longer dependent on
jQuery for the JSONP calls.
###
API = {
  # Validate the query based on the required args
  validate: (args, required) ->
    for own i, name of required
      if (!(args[name]))
        console.error("Missing required parameter: " + name)
        return false
    return true
  
  # Query the API
  query: (url, data, callback) ->
    # Hopefully relying on the date should be reliable enough. Might need to look
    # as JSONP-Fu again to port over some collision avoidance code.
    callbackName = "TwitPic" + (new Date()).getTime()

    if exports?
      queryUrl = "#{url}.json?"
    else
      queryUrl = "http://#{TwitPic.baseUrl}/#{url}.jsonp?callback=#{callbackName}"
    
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
}

if exports?
  # Export for Node
  exports.TwitPic = TwitPic
else
  # Move to global window scope for browser
  window.TwitPic = TwitPic