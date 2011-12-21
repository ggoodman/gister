((gister) ->
  ###
  gister.state
  ###
  
  gister.state = new class extends lumbar.Model
    initialize: ->
  
  
  ###
  gister.gist
  ###

  class GistFile extends lumbar.Model
    idAttribute: "filename"
    
  class GistFileCollection extends lumbar.Collection
    model: GistFile
    sortBy: (model) -> model.get("filename")
    initialize: ->
      @bind "reset", -> console.log "RESET", arguments...

    getNewFilename: (index = "") ->
      index = +index + 1 while @get("Untitled#{index}")
      "Untitled#{index}"

    getNewFileUrl: (index = "") ->
      if gister.gist.id then "##{gister.gist.id}/#{@getNewFilename()}"
      else "##{@getNewFilename()}"
      
  gister.gist = new class extends lumbar.Model
    defaults:
      id: ""
      state: "loaded"
      description: ""
      
      
    initialize: ->
      @files = new GistFileCollection()
      
      self = @
      gister.state.bind "change:active", ->
        active = gister.state.get("active")
        console.log "Changed active file", active
        unless self.files.get(active)
          self.files.add filename: active
      
    reset: ->
      @clear()
      @set @defaults
      @files.reset()
    
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
        

    fetch: (@id, cb = ->) ->
      self = @
      self.clear()
      if @id
        self.trigger "load:start"
        
        $.ajax "https://api.github.com/gists/#{self.id}",
          dataType: "jsonp"
          success: (json) ->
            self.clear()
            self.handleJson(json.data)
            self.trigger "load:success"
            cb(true)
          error: ->
            self.trigger "load:error"
            cb()

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