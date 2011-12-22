((lumbar) ->
  
  lumbar.Deferred = jQuery.Deferred
  
  class lumbar.Model extends Backbone.Model
    @persist: (attribute, filterOrOptions) ->
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
        for attribute, {dependentAttributes, valueBuilder} of self.constructor.exposed
          for dependency in dependentAttributes
            self.bind "change:#{dependency}", (model) ->
              args = model.get(attr) for attr in dependentAttributes
              model.set attribute: valueBuilder.apply(model, args.push(attribute))
        oldInit.call(self, arguments...)
      super(arguments...)
  
  
    toJSON: ->
      raw = super()
      unless @constructor.persisted then raw
      else
        json = {}
        json[attribute] = filter(attribute, raw[attribute]) for attribute, filter of @constructor.persisted
        json
  
    toViewModel: ->
      raw = super()
      unless @constructor.exposed then raw
      else
        json = {}
        json[attribute] = filter(attribute, raw[attribute]) for attribute, filter of @constructor.exposed
        json
  
    save: (attrs) ->
      dfd = new lumbar.Deferred
      super attrs,
        success: dfd.resolve
        error: dfd.reject
      dfd.promise()
  
    destroy: ->
      dfd = new lumbar.Deferred
      super
        success: dfd.resolve
        error: dfd.reject
      dfd.promise()
    
    fetch: ->
      console.log "lumbar.Model.fetch", @, arguments...
      dfd = new lumbar.Deferred
      super
        success: dfd.resolve
        error: dfd.reject
      dfd.promise()
  
  class lumbar.Collection extends Backbone.Collection
    create: (attrs) ->
      dfd = new lumbar.Deferred
      super attrs,
        success: dfd.resolve
        error: dfd.reject
      dfd.promise()
    
    fetch:  ->
      dfd = new lumbar.Deferred
      super
        success: dfd.resolve
        error: dfd.reject
      dfd.promise()
    

)(window.lumbar)