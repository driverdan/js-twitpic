###
TwitPic class - defines API endpoints and is used to
interact with the API.
###
class TwitPic
  @conflict = false
  @baseUrl = "http://api.twitpic.com/"
  @query = (endpoint, args, callback) ->
    api = endpoint.split "/"
    tp = new TwitPic()
    
    tp[api[0]][api[1]](args, callback)
    
  @thumb = (image, size = "thumb", asImg = true) ->
    url = "http://twitpic.com/show/#{size}/#{image.short_id}"
    if asImg then "<img src=\"#{url}\" />" else url
  
  constructor: ->
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
  validate: (args, required) ->
    for own i, name of required
      if (!(args[name]))
        console.error("Missing required parameter: " + name)
        return false
    return true
        
  query: (url, data, callback) ->
  	# Hopefully relying on the date should be reliable enough. Might need to look
  	# as JSONP-Fu again to port over some collision avoidance code.
    callbackName = "TwitPic" + (new Date()).getTime()
    queryUrl = TwitPic.baseUrl + url + ".jsonp?callback=" + callbackName
    
    args = []
    for own i, val of data
      args.push "#{i}=#{val}"
      
    queryUrl += "&" + args.join('&')
    
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
        
}

window.TwitPic = TwitPic