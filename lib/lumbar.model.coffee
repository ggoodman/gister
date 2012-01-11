lumbar = window.lumbar

lumbar.Deferred = jQuery.Deferred

class lumbar.Model extends Backbone.Model
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
      oldInit.call(self, arguments...)
    super(arguments...)


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

  __save: (attrs, options = {}) ->
    self = @
    dfd = new lumbar.Deferred
    super attrs, _.extend {}, options,
      success: _.bind(dfd.resolve, self)
      error: (args...) -> dfd.rejectWith(self, args)
    dfd.promise()

  __destroy: (options = {}) ->
    self = @
    dfd = new lumbar.Deferred
    super _.extend {}, options,
      success: (args...) -> dfd.resolveWith(self, args)
      error: (args...) -> dfd.rejectWith(self, args)
    dfd.promise()
  
  __fetch: (options = {}) ->
    self = @
    dfd = new lumbar.Deferred
    super _.extend {}, options,
      success: (args...) -> dfd.resolveWith(self, args)
      error: (args...) -> dfd.rejectWith(self, args)
    dfd.done -> self.saved = _.clone(self.attributes )
    dfd.promise()

class lumbar.Collection extends Backbone.Collection
  __create: (attrs, options = {}) ->
    self = @
    dfd = new lumbar.Deferred
    super attrs, _.extend {}, options,
      success: _.bind(dfd.resolve, self)
      error: (args...) -> dfd.rejectWith(self, args)
    dfd.promise()
  
  __fetch: (options = {}) ->
    self = @
    dfd = new lumbar.Deferred
    super _.extend {}, options,
      success: (args...) -> dfd.resolveWith(self, args)
      error: (args...) -> dfd.rejectWith(self, args)
    dfd.promise()