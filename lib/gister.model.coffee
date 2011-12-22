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
    rename: (filename) ->
      @set
        old_filename: @id
        filename: filename
      gister.router.activateFile(filename)
      
    
  class GistFileCollection extends lumbar.Collection
    model: GistFile
    sortBy: (model) -> model.get("filename")

    getNewFilename: (index = "") ->
      index = +index + 1 while @get("Untitled#{index}")
      "Untitled#{index}"

    getNewFileUrl: (index = "") ->
      if gister.gist.id then "##{gister.gist.id}/#{@getNewFilename()}"
      else "##{@getNewFilename()}"
        

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
            
            
            
  gister.gist = new class extends lumbar.Model
    @persist "description"
    @persist "public", -> true
    @persist "files", ->
      files = {}
      @files.each (file) ->
        old_filename = file.get("old_filename")
        filename = old_filename or file.id
        files[filename] = { content: file.get("content") }
        files[filename].filename = file.id
      if @saved
        for filename, file in @saved.files
          files[filename] = null unless files[filename]
      files
      
    defaults:
      id: ""
      description: ""
      
    initialize: ->
      @files = new GistFileCollection()
      
      gister.user.bind "change:id", (user) ->
        gister.gist.set owned: (user.id and user.id == gister.user.id) or false
    
    url: -> "https://api.github.com/gists/#{@id}"

    sync: (method, model, options = {}) ->
      methodMap =
        create: "POST"
        read:   "GET"
        update: "PATCH"
        delete: "DELETE"
     
      params =
        url: model.url()
        type: methodMap[method]
        dataType: "json"
        beforeSend: (xhr) ->
          #xhr.setRequestHeader "X-HTTP-Method-Override", methodMap[method]
          xhr.setRequestHeader "Authorization", "token #{token}" if token = readCookie("_gst.tok")
      
      params.data = JSON.stringify(model.toJSON()) if method in ["create", "update"]
      
      jQuery.ajax _.extend(params, options)
      
    destroy: ->
      super()
        .then -> window.location.hash = ""
    
    parse: (json) ->
      @files.reset _.values(json.files)
      json.owned = (json.user and json.user.id == gister.user.id) or false
      json
    
    reset: (attrs = {}) ->
      @clear()
      @files.reset()
      @set _.extend {}, @defaults, attrs
    
    handleJson: (data) ->
      @set(data)
      @files.reset _.values(data.files)
      
    fork: ->
      @save({}, { url: @url() + "/fork", type: "POST"})
        .then -> gister.router.activateFile(gister.state.get('active'))


)(window.gister)