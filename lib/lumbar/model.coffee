define ["order!vendor/jquery", "order!vendor/underscore", "order!vendor/backbone"], ->
  
  class Model extends Backbone.Model
    @persist: (attribute, filterOrOptions = {}) ->
      @persisted ||= {}
      @persisted[attribute] = _.extend {},
        if _.isFunction(filterOrOptions)
          save: filterOrOptions
          load: (value) -> value
        else _.defaults filterOrOptions,
          save: (value) -> value
          load: (value) -> value
      @
  
    @expose: (attribute, dependentAttributes, valueBuilder) ->
      @exposed ||= {}
      @exposed[attribute] = {dependentAttributes, valueBuilder}
      @
  
    constructor: ->
      self = @
      
      oldInit = self.initialize
      self.initialize = ->
        if self.constructor.exposed
          for attribute, {dependentAttributes, valueBuilder} of self.constructor.exposed
            for dependency in dependentAttributes
              self.bind "change:#{dependency}", (model) ->
                args = []
                args.push model.get(attr) for attr in dependentAttributes
                model.set attribute: valueBuilder.apply(model, args.push(attribute))
        
        self.bind "change", (model, options = {}) -> self._saved = _.clone(model.attributes) if options.saved
        
        oldInit.call(self, arguments...)
        
      super(arguments...)
  
    saved: -> @_saved
  
    toJSON: ->
      raw = super()
      unless @constructor.persisted then raw
      else
        json = {}
        json.id = @id if @id
        for attribute, {save} of @constructor.persisted
          json[attribute] = save.call(@, raw[attribute], attribute) 
        json
  
    toViewModel: ->
      unless @constructor.exposed then _.clone(@attributes)
      else
        json = {}
        json[attribute] = filter(attribute, raw[attribute]) for attribute, filter of @constructor.exposed
        json
        
    fetch: (options = {}) ->
      super _.defaults options,
        saved: true