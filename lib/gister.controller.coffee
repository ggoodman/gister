((gister) ->
  ###
  Set up routes
  ###
  
  gister.router = new class extends Backbone.Router
    routes:
      "edit/(\d+)/:filename"  : "edit"
      "edit/(\d+)"            : "edit"
      "edit/:filename"        : "create"
      "edit/?"                : "create"
      ":gist"                 : "preview"
    
    create: (filename) ->
      gister.gist.reset() if gister.gist.id
      gister.state.set active: (filename or gister.gist.files.getNewFilename()) if filename and filename isnt gister.state.get("active")
      gister.state.set mode: "create"
    
    edit: (id, filename) ->
      if id isnt gister.gist.id
        gister.gist.fetch id, ->
          gister.state.set active: (filename or gister.gist.files.getNewFilename())
      if gister.state.get("mode") isnt "edit"
        gister.state.set mode: "edit"
    
    preview: (id) ->
      gister.state.set model: "preview"

)(window.gister)