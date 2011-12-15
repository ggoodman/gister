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
    initialize: ->
      @bind "reset", -> console.log "RESET", arguments...

    getNewFilename: (index = "") ->
      index = +index + 1 while @get("Untitled#{index}")
      "Untitled#{index}"

    getNewFileUrl: (index = "") ->
      if gister.gist.id then "#edit/#{gister.gist.id}/#{@getNewFilename()}"
      else "#edit/#{@getNewFilename()}"
      
  gister.gist = new class extends lumbar.Model
    defaults:
      id: ""
      state: "loaded"
      description: ""
      
      
    initialize: ->
      @files = new GistFileCollection()
      @files.add
        filename: "Untitled"
        language: "text"
      
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

    fetch: (@id) ->
      self = @
      self.clear()
      if @id
        self.trigger "load:start"
        
        $.ajax "https://api.github.com/gists/#{self.id}",
          dataType: "jsonp"
          success: (json) ->
            reset 
            self.set(json.data)
            self.files.reset _.values(json.data.files)
            self.trigger "load:success"
          error: -> self.trigger "load:error"

  ###
  gister.buffers
  
  class BufferModel extends lumbar.Model
    language:
      "txt"     : "text"
      "js"      : "js"
      "coffee"  : "CoffeeScript"
      "md"      : "Markdown"
      "html"    : "HTML"
      "css"     : "css"
      
    defaults:
      title: ""
      content: ""
      type: "text/plain"
      language: ""
      
  
  gister.buffers = new class extends lumbar.Collection
    model: BufferModel
    initialize: ->
      # This happens only once at load
      @add
        title: "Untitled"
        content: ""
        type: "text/plain"
        
    getNewFileUrl: (index = "") ->
      index = parseInt(index, 10) + 1 while @get("Untitled#{index}")
      
      if gister.gist.id then "#edit/#{gister.gist.id}/Untitled#{index}"
      else "#edit/Untitled#{index}"
  
  ###
)(window.gister)