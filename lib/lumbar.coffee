window.lumbar =
  version: "0.0.1"
  start: (mountPoint) ->
    console.log "lumbar.start", arguments...
          
    lumbar.root.render()
    
    Backbone.history.start()

_.mixin obj: (key, value) ->
  hash = {}
  hash[key] = value
  hash

class lumbar.Emitter
  bind: (event, listener) =>
    @listeners ?= {}
    (@listeners[event] ?= []).push(listener)
    @
  trigger: (event, args...) =>
    #console.log "limber.Emitter::emit", arguments...
    @listeners ?= {}
    listener(args...) for listener in @listeners[event] if @listeners[event]
    @


