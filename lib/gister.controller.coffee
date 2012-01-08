((gister) ->
  
  ###
  Set up routes
  ###
  gister.router = new class extends Backbone.Router
    routes:
      ""                      : "create"
      "browse"                : "browsePublic"
      "browse/mine"           : "browseMine"
      "browse/starred"        : "browseStarred"
      "preview/:gist"         : "preview"
      "preview"               : "preview"
      ":gist/:filename"       : "edit"
      ":gist"                 : "createOrEdit"
          
    activateFile: (filename) ->
      # Check if the gist already has a file by that name, otherwise create it
      unless gister.gist.files.get(filename)
        gister.gist.files.add({filename}) # Not async
      
      # Avoid firing unnecessary callbacks
      unless filename is gister.state.get("active")
        gister.state.set active: filename
        if gister.state.get("mode") in ["edit", "create"]
          window.location.hash = if gister.gist.id then "##{gister.gist.id}/#{gister.state.get('active')}" else "##{gister.state.get('active')}"
    
    browsePublic: ->
      gister.browse.fetch
        url: "https://api.github.com/gists"
      
      @browse()
    
    browseMine: ->
      gister.browse.fetch
        url: "https://api.github.com/gists"
        beforeSend: (xhr) ->
          #xhr.setRequestHeader "X-HTTP-Method-Override", methodMap[method]
          xhr.setRequestHeader "Authorization", "token #{token}" if token = readCookie("_gst.tok")
      
      @browse()
    
    browseStarred: ->
      gister.browse.fetch
        url: "https://api.github.com/gists/starred"
        beforeSend: (xhr) ->
          #xhr.setRequestHeader "X-HTTP-Method-Override", methodMap[method]
          xhr.setRequestHeader "Authorization", "token #{token}" if token = readCookie("_gst.tok")
      
      @browse()

          
    browse: ->
      console.log "gister.router.create", arguments...
      
      # Allow the interface to react to a change in modes
      if gister.state.get("mode") isnt "browse"
        gister.state.set mode: "browse"
      
    
    createOrEdit: (gist) ->
      if /^\d+$/.test(gist) then @edit(gist)
      else @create(gist)
    
    create: (filename) ->
      console.log "gister.router.create", arguments...
      
      # Reset the gist because it previously referred to a saved gist
      if gister.gist.id then gister.gist.reset()
      
      @activateFile filename or gister.gist.files.getNewFilename()
      
      # Allow the interface to react to a change in modes
      if gister.state.get("mode") isnt "create"
        gister.state.set mode: "create"
    
    edit: (id, filename) ->
      console.log "gister.router.edit", arguments...
      
      self = @
      
      if id isnt gister.gist.id
        gister.gist.reset({id})
        dfd = gister.gist.fetch()
          .done -> self.activateFile filename or gister.gist.files.last()?.get("filename") or gister.gist.files.getNewFilename()
          .fail ->
            alert "No such gist"
            self.activateFile()
      else if filename
        @activateFile filename

      # Allow the interface to react to a change in modes
      if gister.state.get("mode") isnt "edit"
        gister.state.set mode: "edit"
    
    preview: (id, filename) ->
      console.log "gister.router.preview", arguments...
      
      self = @
      
      if id isnt gister.gist.id
        gister.gist.reset({id})
        dfd = gister.gist.fetch()
          .done ->
            self.activateFile filename or gister.gist.files.last()?.get("filename") or gister.gist.files.getNewFilename()
            gister.state.set mode: "preview"
          .fail ->
            alert "No such gist"
            self.activateFile()
      else
        gister.state.set mode: "preview"

)(window.gister)