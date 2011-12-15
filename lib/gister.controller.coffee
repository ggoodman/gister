((gister) ->
  ###
  Set up routes
  ###
  
  gister.router = new class extends Backbone.Router
    routes:
      "edit/:id/:filename"  : "edit"
      "edit/:id"            : "edit"
      ":gist"               : "preview"
    
    
    edit: (id, filename) ->
      gister.gist.load id, ->
        if filename
          unless buffer = gister.buffers.get(filename)
            gister.buffers.add
              
          then gister.buffers.get(filename).activate()
      gister.state.set mode: "edit"
    
    preview: (id) ->
      gister.state.set model: "preview"

)(window.gister)