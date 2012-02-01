define [
  "cs!lumbar/lumbar"
], (lumbar) ->
  
  class extends lumbar.Router
    routes:
      ""                      : "create"
      
    create: ->
      console.log "Routed create"
