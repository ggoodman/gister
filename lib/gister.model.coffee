((gister) ->
  ###
  gister.state
  ###
  
  gister.state = new class extends lumbar.Model
  
  
  ###
  gister.gist
  ###

  class GistFile extends lumbar.Model
    idAttribute: "filename"
    
  class GistFileCollection extends lumbar.Collection
    model: GistFile
    sortBy: (model) -> model.get("filename")

    getNewFilename: (index = "") ->
      index = +index + 1 while @get("Untitled#{index}")
      "Untitled#{index}"

    getNewFileUrl: (index = "") ->
      if gister.gist.id then "##{gister.gist.id}/#{@getNewFilename()}"
      else "##{@getNewFilename()}"
      
  gister.gist = new class extends lumbar.Model
    defaults:
      id: ""
      description: ""
      
      
    initialize: ->
      console.log "MODEL", @
      @files = new GistFileCollection()
    
    url: -> "https://api.github.com/gists/#{@id}"

    sync: (method, model, options = {}) ->
      methodMap =
        create: "POST"
        read: "GET"
        update: "PATCH"
        delete: "DELETE"
     
      params =
        type: methodMap[method]
        dataType: "json"
        beforeSend: (xhr) ->
          #xhr.setRequestHeader "X-HTTP-Method-Override", methodMap[method]
          xhr.setRequestHeader "Authorization", "token #{token}" if token = readCookie("_gst.tok")
      
      params.data = JSON.stringify(model.toJSON()) if method in ["create", "update"]
      
      console.log "AJAX", _.extend({}, params, options)
      
      jQuery.ajax model.url(), _.extend(params, options)
    
    parse: (json) ->
      @files.reset _.values(json.files)
      delete json.files
      json
      
    reset: (attrs = {}) ->
      @clear()
      @files.reset()
      @set _.extend {}, @defaults, attrs
    
    handleJson: (data) ->
      @set(data)
      @files.reset _.values(data.files)
    
    save: =>
      self = @
      if @id
        self.trigger "save:start"
        
        data = 
          files: {}
          
        self.files.each (file) ->
          data.files[file.get("filename")] =
            content: file.get("content")
        
        console.log "Saving data", data
        
        $.ajax "https://api.github.com/gists/#{self.id}?access_token=#{readCookie('_gst.tok')}",
          dataType: "json"
          type: "patch"
          data: JSON.stringify(data)
          success: (data) ->
            console.log "JSON came back"
            self.handleJson(data)
            self.trigger "save:success"
        

  gister.user = new class extends lumbar.Model
    initialize: ->
      @tryLogin()
    
    tryLogin: ->
      self = @
      if token = readCookie("_gst.tok")
        console.log "read token", token
        $.ajax "https://api.github.com/user",
          dataType: "jsonp"
          data:
            access_token: token
          success: (json) ->
            self.set(json.data)
            console.log "USER", json

)(window.gister)