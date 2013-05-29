###
mintpresso-0.2.coffee

Author: Jinhyuk Lee <eces at mstock.org>
Organization: MINTPRESSO <support at mintpresso.com>
Repository: https://github.com/mintpresso/javascript-api

Description:
  This is a JavaScript API library for MINTPRESSO Data Cloud.
  Supports basic graph operations.

Documentation: docs.mintpresso.com/javascript-api/index.html
###

if String.prototype.format is undefined
  String.prototype.format = () ->
    _arguments = arguments
    this.replace /{(\d+)}/g, (match, number) ->
      if typeof _arguments[number] isnt 'undefined' then _arguments[number] else match

String.prototype.endsWith = (suffix) ->
  return (this.substr(this.length - suffix.length) is suffix)

String.prototype.startsWith = (prefix) ->
  return (this.substr(0, prefix.length) is prefix)

try
  prefix =
    log: '[MINTPRESSO] '
    version: '/v1'
  
  client =
    name: 'JS 0.2 API'
    key: ''
    id: ''
    useDebugCallback: true
    getAPI: () ->
      return 'api_token=' + client.key
  
  server =
    list: []
    iteration: 0
    get: () ->
      return server.list[server.iteration]
    isReady: false
    timeout: 5000
    urls:
      getPoint: "/account/{0}/point/{1}?"
      getPointByTypeOrIdentifier: "/account/{0}/point?type={1}&identifier={2}&"
      addPoint: "/post/account/{0}/point?updateIfExists={1}&"
      findEdge: "/account/{0}/edge?subjectId={1}&subjectType={2}&subjectIdentifier={3}&verb={4}&objectId={5}&objectType={6}&objectIdentifier={7}&getInnerModels={8}&"
      linkWithEdge: "/post/account/{0}/edge?subjectId={1}&subjectType={2}&subjectIdentifier={3}&verb={4}&objectId={5}&objectType={6}&objectIdentifier={7}&getInnerModels={8}&"
    dataType: 'jsonp'
    useCallback: true
    callbackName: 'JSAPIMINTPRESSOCALLBACK'

  feature =
    pageTracker: false

  model = 
    verbs: new Array('do', 'does', 'did', 'verb')
    mark: '?'
    point:
      prototype: new Array('type', 'identifier', 'data')
    edge:
      prototype: new Array('subjectId', 'subjectType', 'verb', 'objectId', 'objectType')

  getPoint = (id, callback) ->
    jQuery.ajax {
      url: server.get() + prefix.version + server.urls.getPoint.format(client.id, id) + client.getAPI()
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: server.dataType
      jsonpCallback: server.callbackName
      timeout: server.timeout
      success: (json) ->
        data = undefined
        if json.status.code is 200
          if json.point.data isnt undefined
            for key of json.point.data
              if key isnt 'data'
                json.point[key] = json.point.data[key]
              else
                data = json.point.data[key]
            if data is undefined
              `delete json.point.data`
            else
              json.point.data = data
        callback json

      error: (xhr, status, error) ->
        console.error "#{prefix.log} Response(#{status}) #{error}"
        callback {
          status: {
            code: status
            message: "Response(#{status}) #{error}"
          }
        }
    }

  getPointByTypeOrIdentifier = (json, callback) ->
    i = 0
    _type = ""
    _identifier = ""
    for key of json
      if i > 0
        console.log "#{prefix.log}Too many arguments are given to be an informative query though no question marks are found - mintpresso.get"
        break
      if key.length is 0 or key isnt model.mark
        _type = encodeURIComponent(key)
      if json[key].length is 0 or json[key] is model.mark
        console.log prefix.log + "#{prefix.log}No question mark is allowed on 'identifier' field - mintpresso.get"
        return false
      else
        _identifier = encodeURIComponent(json[key])
      i++

    jQuery.ajax {
      url: server.get() + prefix.version + server.urls.getPointByTypeOrIdentifier.format(client.id, _type, _identifier) + client.getAPI()
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: server.dataType
      jsonpCallback: server.callbackName
      timeout: server.timeout
      success: (json) ->
        data = undefined
        if json.status.code is 200
          if json.point isnt undefined
            if json.point.data isnt undefined
              for key of json.point.data
                if key isnt 'data'
                  json.point[key] = json.point.data[key]
                else
                  data = json.point.data[key]
              if data is undefined
                `delete json.point.data`
              else
                json.point.data = data
          else if json.points isnt undefined
            for i in [0..json.points.length-1] by 1
              point = json.points[i]
              if point.data isnt undefined
                for key of point.data
                  if key isnt 'data'
                    json.points[i][key] = point.data[key]
                  else
                    data = point.data[key]
                if data is undefined
                  `delete json.points[i].data`
                else
                  json.points[i].data = data
          else
            console.error prefix.log + "Found results neither point nor points - mintpresso._getPointByTypeOrIdentifier"
        callback json
      error: (xhr, status, error) ->
        console.error "#{prefix.log} Response(#{status}) #{error}"
        callback JSON.parse(xhr.responseText)
    }

  findEdges = (json, callback, getInnerModels = false) ->
    i = 1
    sType = ''
    sId = -1
    sString = ''
    v = ''
    oType = ''
    oId = -1
    oString = ''

    for key of json
      switch i
        when 1
          sType = encodeURIComponent(key)
          sId = encodeURIComponent(json[key]) if json[key] isnt model.mark and typeof json[key] is 'number'
          sString = encodeURIComponent(json[key]) if json[key] isnt model.mark and typeof json[key] is 'string'
        when 2
          if model.verbs.indexOf(key) is -1
            console.log prefix.log + 'Verb isn\'t match with do/does/did/verb. - mintpresso.get'
          else
            v = encodeURIComponent(json[key]) if json[key] isnt model.mark
        when 3
          oType = encodeURIComponent(key)
          oId = encodeURIComponent(json[key]) if json[key] isnt model.mark and typeof json[key] is 'number'
          oString = encodeURIComponent(json[key]) if json[key] isnt model.mark and typeof json[key] is 'string'
        else
          console.log prefix.log + 'Too many arguments are given to be a form of subject/verb/object query - mintpresso.get'
          return false
      i++

    jQuery.ajax {
      url: server.get() + prefix.version + server.urls.findEdges.format(client.id, sId, sType, sString, v, oId, oType, oString, getInnerModels) + client.getAPI()
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: server.dataType
      jsonpCallback: server.callbackName
      timeout: server.timeout
      success: (json) ->
        callback json
      error: (xhr, status, error) ->
        console.error "#{prefix.log} Response(#{status}) #{error}"
        callback JSON.parse(xhr.responseText)
    }

  addPoint = (json, callback, updateIfExists = false) ->
    value = {}
    value.point = {}
    value.point.data = {}

    # Promote first citizen keys
    for key of json
      if model.point.prototype.indexOf(key) isnt -1
        value.point[key] = json[key]
      else
        value.point.data[key] = json[key]

    jQuery.ajax {
      url: server.get() + prefix.version + server.urls.addPoint.format(client.id, encodeURIComponent JSON.stringify(value), updateIfExists) + client.getAPI()
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: server.dataType
      jsonpCallback: server.callbackName
      timeout: server.timeout 
      success: (json) ->
        callback json
      error: (xhr, status, error) ->
        console.error "#{prefix.log} Response(#{status}) #{error}"
        callback JSON.parse(xhr.responseText)
    }

  addEdge = (json, callback) ->
    value = {}
    value.edge = {}
    
    i = 1
    for key of json
      switch i
        when 1
          value.edge.subjectType = key if key isnt model.mark and model.edge.prototype.indexOf(key) is -1 
          value.edge.subjectId = json[key] if json[key] isnt model.mark
        when 2
          if model.verbs.indexOf(key) is -1
            console.log "#{prefix.log} Verb isn\'t match with do/does/did/verb. - mintpresso.set"
          else
            value.edge.verb = json[key]
        when 3
          value.edge.objectType = key if key isnt model.mark and model.edge.prototype.indexOf(key) is -1 
          value.edge.objectId = json[key] if json[key] isnt model.mark
        else
          console.log "#{prefix.log} Too many arguments are given to be a form of subject/verb/object query - mintpresso.set"
          return false
      i++

    jQuery.ajax {
      url: server.get() + prefix.version + server.urls.linkWithEdge.format(client.id, encodeURIComponent JSON.stringify(value)) + client.getAPI()
      type: 'GET'
      async: true
      cache: false
      crossDomain: true
      dataType: server.dataType
      jsonpCallback: server.callbackName
      timeout: server.timeout
      success: (json) ->
        callback json
      error: (xhr, status, error) ->
        console.error "#{prefix.log} Response(#{status}) #{error}"
        callback JSON.parse(xhr.responseText)
    }

  window.mintpresso = {}
  window.mintpresso =
    get: () ->
      ###
      @param
        Object json, Function callback[, Boolean getInnerModels = false]
      ###
      # Object json, Function callback[, Boolean getInnerModels = false | Object optionsObject{getInnerModels: Boolean = false})]
      if server.isReady is false
        return console.warn "#{prefix.log}Not initialized. Add mintpress.init in your code with API key."
      if arguments.length is 0
        console.warn "#{prefix.log}An argument is required for mintpresso.get method."
      else if arguments.length <= 2
        getInnerModels = false
        # if arguments[2] isnt undefined
        #   if arguments[2] typeof 'boolean'
        #     getInnerModels = arguments
        #   else if arguments[2] typeof 'object' and `'getInnerModels' in arguments[2]`
        #     getInnerModels = Boolean(arguments[2] === true)
        if arguments[2] isnt undefined and typeof 'boolean'
          getInnerModels = true
        else
          getInnerModels = false

        if arguments[1] isnt undefined and typeof arguments[1] is 'function'
          callback = arguments[1]
        else
          callback = window.mintpresso.callback
        
        if typeof arguments[0] is 'number'
          return getPoint arguments[0], callback
        else if typeof arguments[0] is 'object'
          json = arguments[0]
          hasMark = false
          conditions = 0
          for key of json
            conditions++
            if key is "?" or json[key] is "?"
              hasMark = true
          if (hasMark and conditions > 1) or conditions is 3
            findEdges arguments[0], callback, getInnerModels
          else
            getPointByTypeOrIdentifier arguments[0], callback
        else
          console.warn "#{prefix.log} An argument type of Number or String is required for mintresso.get method."
      else
        console.warn "#{prefix.log} Too many arguments in mintpresso.get method."

    set: () ->
      ###
      @param
        Object json[, Function callback[, Boolean updateIfExists = false]]
      ###
      if server.isReady is false
        return console.warn "#{prefix.log}Not initialized. Add mintpress.init in your code with API key."
      if arguments.length is 0
        console.warn "#{prefix.log}An argument is required for mintpresso.set method."
      else if arguments.length <= 3
        if typeof arguments[0] is 'object'
          isEdgeOperation = false
          for key of arguments[0]
            if model.verbs.indexOf(key) isnt -1
              isEdgeOperation = true
              break

          updateIfExists = false
          callback = window.mintpresso.callback

          if arguments[1] isnt undefined
            if typeof arguments[1] is 'function'
              callback = arguments[1]
              if arguments[2] isnt undefined and typeof arguments is 'boolean'
                updateIfExists = true

          if isEdgeOperation is true
            addEdge arguments[0], callback
          else
            if arguments[1] is undefined or arguments[1] is false
              addPoint arguments[0], callback, updateIfExists
            else
              addPoint arguments[0], callback, updateIfExists
        else
          console.warn "#{prefix.log}An JSON object is required for mintpresso.set method."
      else
        console.warn "#{prefix.log}Too many arguments in mintpresso.get method."
      true

    # For debug 
    callback: (response) ->
      if client.useDebugCallback is true
        if response?.status?.code > 201
          console.log "#{prefix.log}Response(#{response.status.code}): #{response.status.message}", response
        else
          console.log "#{prefix.log}Response(#{response.status.code}): ", response

    init: (key, id, option) ->
      if typeof key isnt 'string'
        return console.warn "#{prefix.log} Not initialized. Invalid API key. (required: String)"
      
      # uuid = key.match /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      # if uuid is null or uuid.length is 0
      #   return console.warn "#{prefix.log} Not initialized. Invalid API key. (required: UUID Format String)"
             
      client.key = key
      client.id = id

      # use ajax callback (required CORS) or not
      if option.withoutCallback isnt undefined and option.withoutCallback is true
        server.dataType = 'json'
        server.callbackName = undefined
        server.useCallback = false
      else
        server.useCallback = true

      # use custom domain for any purpose
      domain = '//api.mintpresso.com'
      if option.useLocalhost isnt undefined and option.useLocalhost is true
        console.log "#{prefix.log}Using localhost server (http://localhost:15100)"
        domain = '//localhost:15100'

      # init server urls
      if 'https:' is document.location.protocol
        server.list.push 'https:' + domain
      else
        server.list.push 'http:' + domain

      # call given function just after mintpressso API init.
      if option.callbackFunction isnt undefined and option.callbackFunction.length > 0 and `option.callbackFunction in window`
        window[option.callbackFunction](window.mintpresso)
        console.log "#{prefix.log}window.#{option.callbackFunction} is called."

      # show description of all queries and APIs
      if option.disableDebugCallback isnt undefined and option.disableDebugCallback is true
        client.useDebugCallback = false
      else
        client.useDebugCallback = true

      server.isReady = true
      true
catch e
  if window.mintpresso isnt undefined and true
    throw e
  else
    console.warn "#{prefix.log} Failed to load API."
true