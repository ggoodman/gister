define ["order!vendor/jquery", "order!vendor/underscore", "order!vendor/backbone"], ->
  
  class Router extends Backbone.Router
    routes: []
    constructor: ->
      routes = @routes
      @routes = []
      super()
      
      for route, name of @routes
        @route(new RegExp("^#{route}", "i"), name, @[name])
