define [
  "cs!lumbar/router"
  "cs!lumbar/model"
  "cs!lumbar/collection"
  "cs!lumbar/view"
  "vendor/jquery"
  "vendor/underscore"
], (Router, Model, Collection, View) ->
  
  nop = (arg) -> arg
  
  version: "0.0.1"
  
  Router: Router
  Model: Model
  Collection: Collection
  View: View
  Deferred: jQuery.Deferred
  
  
  
  uid: do ->
    index = 0
    -> "uid-#{+new Date}-#{index++}"
  
  resolve: (fnOrValue, args...) ->
    if _.isFunction(fnOrValue) then fnOrValue.apply(@, args)
    else fnOrValue
  
  m: (path, iterator = (arg) -> arg) ->
    model = window
    segments = path.split(".")
    
    for segment in segments when segment
      if model[segment] then model = model[segment]
      else if model.get? and model = model.get(segment)
      else throw new Error("Invalid model path: #{path}")
    
      iterator(model)
    
    model

  # Define a view or get a reference to the view's definition
  v: do ->
    constructors = {}
    
    (viewName, constructor) ->
      if constructor
        constructor::viewName = viewName
        constructors[viewName] = constructor
      constructors[viewName]
  
  start: ->
    console.log "lumbar.start", arguments...
          
    Backbone.history.start()