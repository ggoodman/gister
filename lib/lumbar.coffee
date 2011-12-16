window.lumbar =
  version: "0.0.1"
  start: (mountPoint) ->
    console.log "lumbar.start", arguments...
          
    Backbone.history.start()
    
    console.log "View", lumbar.view.render()
    
    gister.view.render().$.appendTo("body")

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

console.log "Backbone.Router", Backbone.Router

class lumbar.Router extends Backbone.Router
  routes: []
  constructor: ->
    routes = @routes
    @routes = []
    super()
    
    for route, name of @routes
      @route(new RegExp("^#{route}", "i"), name, @[name])
    
