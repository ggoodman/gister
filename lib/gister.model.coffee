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

    fetch: (@id, cb = ->) ->
      self = @
      self.clear()
      if @id
        self.trigger "load:start"
        
        $.ajax "https://api.github.com/gists/#{self.id}",
          dataType: "jsonp"
          success: (json) ->
            self.clear()
            self.set(json.data)
            self.files.reset _.values(json.data.files)
            self.trigger "load:success"
            cb(true)
          error: ->
            self.trigger "load:error"
            cb()

  gister.user = new class extends lumbar.Model
    id: "1"

)(window.gister)