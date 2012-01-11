window.lumbar =
  version: "0.0.1"
  start: ->
    console.log "lumbar.start", arguments...
          
    Backbone.history.start()

_.mixin obj: (key, value) ->
  hash = {}
  hash[key] = value
  hash

class lumbar.Emitter

_.extend lumbar.Emitter.prototype, Backbone.Events


class lumbar.Router extends Backbone.Router
  routes: []
  constructor: ->
    routes = @routes
    @routes = []
    super()
    
    for route, name of @routes
      @route(new RegExp("^#{route}", "i"), name, @[name])