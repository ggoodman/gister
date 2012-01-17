define ["order!vendor/jquery", "order!vendor/underscore", "order!vendor/backbone"], ->
  
  class Emitter
  
  _.extend Emitter.prototype, Backbone.Events
  
  Emitter