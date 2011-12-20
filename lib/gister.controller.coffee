((gister) ->
  ###
  Set up routes
  ###
  
  gister.router = new class extends Backbone.Router
    routes:
      "preview/:gist"         : "preview"
      "preview"               : "preview"
      ":gist/:filename"       : "edit"
      ":gist"                 : "createOrEdit"
    
    createOrEdit: (gist) ->
      if /^\d+$/.test(gist) then @edit(gist)
      else @create(gist)
    
    create: (filename) ->
      console.log "gister.router.create", arguments..., gister.state.get("active"), filename and (filename is gister.state.get("active")), filename
      gister.gist.reset() if gister.gist.id
      filename ||= gister.gist.files.getNewFilename()
      unless filename and (filename is gister.state.get("active"))
        gister.state.set active: filename
      gister.state.set mode: "create"
    
    edit: (id, filename) ->
      console.log "gister.router.edit", arguments...
      setActive = ->
        active = filename or gister.gist.files.last()?.get("filename") or gister.gist.files.getNewFilename()
        unless active == gister.state.get("active")
          gister.state.set active: filename or gister.gist.files.last()?.get("filename") or gister.gist.files.getNewFilename()

      if id isnt gister.gist.id
        gister.gist.fetch id, setActive
        
      setActive()

      if gister.state.get("mode") isnt "edit"
        gister.state.set mode: "edit"
    
    preview: (id) ->
      console.log "gister.router.preview", arguments...
      if id isnt gister.gist.id
        gister.state.set mode: "loading"
        gister.gist.fetch id, ->
          gister.state.set
            active: (gister.gist.files.last()?.get("filename") or gister.gist.files.getNewFilename())
            mode: "preview"
      else
        gister.state.set mode: "preview"

)(window.gister)