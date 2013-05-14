###
# mintpresso-0.1.coffee
#
# Author: Jinhyuk Lee <eces at mstock.org>
# Organization: MINTPRESSO <support at mintpresso.com>
# Repository: https://github.com/mintpresso/javascript-api
#
# Description: This is an JavaScript API library for MINTPRESSO Data Cloud.
#
###

__init__ = (d, key) ->
  script = d.createElement "script"
  script.type = "text/javascript"
  script.async = !0
  script.onload = () ->
    window['mintpresso'].init key
  server = '//api.mintpresso.com:9000/assets/javascripts/mintpresso-0.1.min.js'
  if 'https:' is d.location.protocol
    script.src = 'https:' + server
  else
    script.src = 'http:' + server
  entry = d.getElementsByTagName("script")[0]
  entry.parentNode.insertBefore(script, entry)

String.format = () ->
  s = arguments[0]
  for i in [(arguments.length-1)..0] by 1
    reg = new RegExp("\\{" + i + "\\}", "gm")
    s = s.replace(reg, arguments[i + 1])
  return s

String.prototype.endsWith = (suffix) ->
  return (this.substr(this.length - suffix.length) is suffix)

String.prototype.startsWith = (prefix) ->
  return (this.substr(0, prefix.length) is prefix)

try
  _logPrefix = '[MINTPRESSO] '
  _versionPrefix = '/v1'
  _initial = 'JS 0.1 API'
  _key = ''
  _accId = ''
  _servers = []
  _initialized = false
  _serverIteration = 0
  _timeout = 1000

  _pageTracker = true
  _urls = []
  _urls['getPoint'] = _versionPrefix + '/account/{0}/point/{1}'
  _urls['getPointByTypeOrIdentifier'] = _versionPrefix + '/account/{0}/point'
  _urls['addPoint'] = _versionPrefix + '/account/%d/point'
  _urls['findEdges'] = _versionPrefix + '/account/%d/edge'
  _verbs = Array('do', 'does', 'did', 'verb')
  _mark = '?'
  _point_proto = Array('type', 'identifier', 'data')
  _edge_proto = Array('subjectId', 'subjectType', 'verb', 'objectId', 'objectType')
  _dataType = 'jsonp'
  _callbackEnabled = true
  _debugCallbackEnabled = true

  _log = (f) ->
    console.log _logPrefix + 'backlog executed due to network problems.'
    true
  _getPoint = (id, callback) ->
    retry = () ->
      if _serverIteration == _servers.length-1
        _serverIteration = 0
        _log () ->
          return _getPoint id, callback
      else
        _serverIteration++
        return _getPoint id, callback
    jQuery.ajax {
      url: "#{ _servers[_serverIteration] }#{ _versionPrefix }/account/#{_accId}/point/#{id}?api_token=#{_key}"
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: _dataType
      jsonpCallback: mintpresso._callbackName
      success: (json) ->
        _data = undefined
        if json.status.code is 200
          if json.point['data'] isnt undefined
            for key of json.point.data
              if key isnt 'data'
                json.point[key] = json.point.data[key]
              else
                _data = json.point.data[key]
            if _data is undefined
              `delete json.point.data`
            else
              json.point.data = _data
        callback json

      error: (xhr, status, error) ->
        retry()
        callback {
          status: {
            code: 400
            message: "status (#{error})"
          }
        }
      timeout: _timeout
    }

  _getPointByTypeOrIdentifier = (json, callback, option) ->
    retry = () ->
      if _serverIteration == _servers.length-1
        _serverIteration = 0
        _log () ->
          return _getPointByTypeOrIdentifier json, callback, option
      else
        _serverIteration++
        return _getPointByTypeOrIdentifier json, callback, option

    i = 0
    _type = ""
    _identifier = ""
    for key of json
      if i > 0
        console.log _logPrefix + 'Too many arguments are given to be an informative query though no question marks are found - mintpresso.get'
        break
      if key.length is 0 or key isnt _mark
        _type = encodeURIComponent(key)
      if json[key].length is 0 or json[key] is _mark
        console.log _logPrefix + 'No question mark is allowed on \'identifier\' field - mintpresso.get'
        return false
        break
      else
        _identifier = encodeURIComponent(json[key])
      i++

    jQuery.ajax {
      url: "#{ _servers[_serverIteration] }#{ _versionPrefix }/account/#{_accId}/point?type=#{_type}&identifier=#{_identifier}&api_token=#{_key}"
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: _dataType
      jsonpCallback: mintpresso._callbackName
      success: (json) ->
        _data = undefined
        if json.status.code is 200
          if json['point'] isnt undefined
            if json.point['data'] isnt undefined
              for key of json.point.data
                if key isnt 'data'
                  json.point[key] = json.point.data[key]
                else
                  _data = json.point.data[key]
              if _data is undefined
                `delete json.point.data`
              else
                json.point.data = _data
          else if json['points'] isnt undefined
            for i in [0..json.points.length-1] by 1
              point = json.points[i]
              if point['data'] isnt undefined
                for key of point.data
                  if key isnt 'data'
                    json.points[i][key] = point.data[key]
                  else
                    _data = point.data[key]
                if _data is undefined
                  `delete json.points[i].data`
                else
                  json.points[i].data = _data
          else
            console.error _logPrefix + "Found results neither point nor points - mintpresso._getPointByTypeOrIdentifier"
        callback json
      error: (xhr, status, error) ->
        retry()
        callback {
          status: {
            code: 400
            message: "status (#{error})"
          }
        }
      timeout: _timeout
    }

  _findRelations = (json, callback, option) ->
    retry = () ->
      if _serverIteration == _servers.length-1
        _serverIteration = 0
        _log () ->
          arg = id
          return _findRelations json, callback, option
      else
        _serverIteration++
        return _findRelations json, callback, option

    i = 1

    sType = ""
    sId = -1
    sString = ""
    v = ""
    oType = ""
    oId = -1
    oString = ""
    for key of json
      switch i
        when 1
          sType = encodeURIComponent(key)
          sId = encodeURIComponent(json[key]) if json[key] isnt _mark and typeof json[key] is 'number'
          sString = encodeURIComponent(json[key]) if json[key] isnt _mark and typeof json[key] is 'string'
        when 2
          if _verbs.indexOf(key) is -1
            console.log _logPrefix + 'Verb isn\'t match with do/does/did/verb. - mintpresso.get'
          else
            v = encodeURIComponent(json[key]) if json[key] isnt _mark
        when 3
          oType = encodeURIComponent(key)
          oId = encodeURIComponent(json[key]) if json[key] isnt _mark and typeof json[key] is 'number'
          oString = encodeURIComponent(json[key]) if json[key] isnt _mark and typeof json[key] is 'string'
        else
          console.log _logPrefix + 'Too many arguments are given to be a form of subject/verb/object query - mintpresso.get'
          return false
          break
      i++

    jQuery.ajax {
      url: "#{ _servers[_serverIteration] }#{ _versionPrefix }/account/#{_accId}/edge?subjectId=#{sId}&subjectType=#{sType}&subjectIdentifier=#{sString}&verb=#{v}&objectId=#{oId}&objectType=#{oType}&objectIdentifier=#{oString}&api_token=#{_key}"
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: _dataType
      jsonpCallback: mintpresso._callbackName
      success: (json) ->
        callback json
      error: (xhr, status, error) ->
        retry()
        callback {
          status: {
            code: 400
            message: "status (#{error})"
          }
        }
      timeout: _timeout
    }

  _addPoint = (json, callback, update) ->
    retry = () ->
      if _serverIteration == _servers.length-1
        _serverIteration = 0
        _log () ->
          arg = id
          return _addPoint json, callback, update
      else
        _serverIteration++
        return _addPoint json, callback, update

    value = {}
    value.point = {}
    value.point.data = {}

    # Promote first citizen keys
    for key of json
      if _point_proto.indexOf(key) isnt -1
        value.point[key] = json[key]
      else
        value.point.data[key] = json[key]

    jQuery.ajax {
      url: "#{ _servers[_serverIteration] }#{ _versionPrefix }/post/account/#{_accId}/point?json=#{ encodeURIComponent JSON.stringify(value) }&api_token=#{_key}"
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: _dataType
      jsonpCallback: mintpresso._callbackName
      success: (json) ->
        callback json
      error: (xhr, status, error) ->
        # retry()
        callback {
          status: {
            code: 400
            message: "status (#{error})"
          }
        }
      timeout: _timeout
    }

  _addEdge = (json, callback, update) ->
    retry = () ->
      if _serverIteration == _servers.length-1
        _serverIteration = 0
        _log () ->
          arg = id
          return _addEdge json, callback, update
      else
        _serverIteration++
        return _addEdge json, callback, update

    value = {}
    value.edge = {}
    
    i = 1
    for key of json
      switch i
        when 1
          value.edge.subjectType = key if key isnt _mark and _edge_proto.indexOf(key) is -1 
          value.edge.subjectId = json[key] if json[key] isnt _mark
        when 2
          if _verbs.indexOf(key) is -1
            console.log _logPrefix + 'Verb isn\'t match with do/does/did/verb. - mintpresso.set'
          else
            value.edge.verb = json[key]
        when 3
          value.edge.objectType = key if key isnt _mark and _edge_proto.indexOf(key) is -1 
          value.edge.objectId = json[key] if json[key] isnt _mark
        else
          console.log _logPrefix + 'Too many arguments are given to be a form of subject/verb/object query - mintpresso.set'
          return false
          break
      i++

    jQuery.ajax {
      url: "#{ _servers[_serverIteration] }#{ _versionPrefix }/post/account/#{_accId}/edge?json=#{ encodeURIComponent(JSON.stringify(value)) }&api_token=#{_key}"
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: _dataType
      jsonpCallback: mintpresso._callbackName
      success: (json) ->
        callback json
      error: (xhr, status, error) ->
        # retry()
        callback {
          status: {
            code: 400
            message: "status (#{error})"
          }
        }
      timeout: _timeout
    }

  window.mintpresso = {}
  window.mintpresso =
    get: () ->
      ###
      @param
        Object json, Function callback[, Object optionsObject]
      ###
      if _initialized is false
        return console.warn _logPrefix + 'Not initialized. Add mintpress.init in your code with API key.'
      if arguments.length is 0
        console.warn _logPrefix + 'An argument is required for mintpresso.get method.'
      else if arguments.length <= 2
        option = {}
        if arguments[1] isnt undefined and typeof arguments[1] is 'function'
          callback = arguments[1]
        else
          callback = mintpresso.callback
        if typeof arguments[0] is 'number'
          return _getPoint arguments[0], callback, option
        else if typeof arguments[0] is 'object'
          json = arguments[0]
          hasMark = false
          conditions = 0
          for key of json
            conditions++
            if key is "?" or json[key] is "?"
              hasMark = true
          if (hasMark and conditions > 1) or conditions is 3
            _findRelations arguments[0], callback, option
          else
            _getPointByTypeOrIdentifier arguments[0], callback, option
        else
          console.warn _logPrefix + 'An argument type of Number or String is required for mintresso.get method.'
      else
        console.warn _logPrefix + 'Too many arguments in mintpresso.get method.'

    trackPage: () ->
      true

    set: () ->
      ###
      @param
        Object json[, Boolean updateIfExists = true]
      ###
      if _initialized is false
        return console.warn _logPrefix + 'Not initialized. Add mintpress.init in your code with API key.'
      if arguments.length is 0
        console.warn _logPrefix + 'An argument is required for mintpresso.set method.'
      else if arguments.length <= 3
        if typeof arguments[0] is 'object'
          isEdgeOperation = false
          for key of arguments[0]
            if _verbs.indexOf(key) isnt -1
              isEdgeOperation = true
              break
          if arguments[1] isnt undefined and typeof arguments[1] is 'function'
            callback = arguments[1]
            option = arguments[2]
          else if arguments[1] isnt undefined and typeof arguments[1] is 'boolean'
            callback = mintpresso.callback
            option = arguments[1]
          else
            callback = mintpresso.callback
            option = true
          if isEdgeOperation is true
            _addEdge arguments[0], callback, option
          else
            if arguments[1] is undefined or arguments[1] is false
              _addPoint arguments[0], callback, option
            else
              _addPoint arguments[0], callback, option
        else
          console.warn _logPrefix + 'An JSON object is required for mintpresso.set method.'
      else
        console.warn _logPrefix + 'Too many arguments in mintpresso.get method.'
      true

    # For debug 
    callback: (response) ->
      if _debugCallbackEnabled is true
        if response?.status?.code > 201
          console.log _logPrefix + "Response(#{response.status.code}): #{response.status.message}", response
        else
          console.log _logPrefix + "Response(#{response.status.code}): ", response

    init: (key, option) ->
      if typeof key isnt 'string' or key.length < 10
        return console.warn _logPrefix + 'Not initialized. Invalid API key.'
        
      temp = key.split '::'
      _key = temp[0]
      _accId = temp[1]

      # use ajax callback (required CORS) or not
      if option['withoutCallback'] isnt undefined and option['withoutCallback'] is true
        _dataType = 'json'
        _callbackName = undefined
        _callbackEnabled = false
      else
        _callbackName = 'JSAPIMINTPRESSOCALLBACK'
        _callbackEnabled = true

      # use custom domain for any purpose
      domain = '//api.mintpresso.com'
      if option['useLocalhost'] isnt undefined and option['useLocalhost'] is true
        domain = '//localhost'

      # init server urls
      if 'https:' is document.location.protocol
        _servers.push 'https:' + domain + ':9001'
      else
        _servers.push 'http:' + domain + ':9001'

      # call given function just after mintpressso API init.
      if option['callbackFunction'] isnt undefined and option['callbackFunction'].length > 0 and `option['callbackFunction'] in window`
        window[option['callbackFunction']](window.mintpresso)
        console.log _logPrefix + "window.#{option['callbackFunction']} is called."

      # show description of all queries and APIs
      if option['disableDebugCallback'] isnt undefined and option['disableDebugCallback'] is true
        _debugCallbackEnabled = false
      else
        _debugCallbackEnabled = true

      _initialized = true
      true

catch e
  if window['__mintpresso__'] isnt undefined and true
    throw e
  else
    console.warn '[MINTPRESSO] API Load failed.'

true
