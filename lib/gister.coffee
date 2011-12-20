window.console ||=
  log: ->

window.gister = 
  version: "0.0.1"
  start: ->
    console.log "gister.start"
    
    Backbone.history.start()
    
    gister.view.render()