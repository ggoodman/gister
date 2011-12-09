((lumbar) ->

  class lumbar.View extends lumbar.Emitter
    @attachDefaults:
      mountPoint: "@"
      mountMethod: "html"
      type: "one"
  
    @attach: (name, options = {}) ->
      @attachedViews ?= {}
      @attachedViews[name] = _.defaults options, @attachDefaults
  
    mountMethod: "html" # Replace contents with rendered template
    renderEvents: "all" # Re-render on 'all' events
    template: ->
    initialize: ->
  
    setMountPoint: (@mountPoint) ->
    setMountMethod: (@mountMethod) ->
    
    render: =>
      @$ = $(CoffeeKup.render @template, @model?.getViewModel())
      if @mountPoint
        if @$.size() then $(@mountPoint)[@mountMethod](@$)
        else @$ = $(@mountPoint)
        @trigger "mounted"
      @trigger "rendered"
      @renderAttachedViews()
      @bindEvents()
      @
  
    destroy: =>
      #@destroyAttachedViews()
      @$.detach()
  
    renderAttachedView: (name, options) ->
      # Check to see if the modelView needs to be lazy-loaded
      if options.createModelView and not options.modelView
        throw new Error("createModelView must be a function") unless _.isFunction(options.createModelView)
        options.modelView = options.createModelView.call(@)
  
      throw new Error("Missing or invalid modelView") unless options.modelView instanceof lumbar.View
      
      options.modelView.setMountPoint if options.mountPoint is "@" then @$ else @$.filter(options.mountPoint).add(options.mountPoint)
      options.modelView.setMountMethod options.mountMethod
      options.modelView.render()
      
      options.modelView
  
    renderAttachedViewList: (name, options) ->
      if options.createIterator and not options.iterator
        throw new Error("createIterator must be a function") unless _.isFunction(options.createIterator)
        options.iterator = options.createIterator.call(@)
  
      throw new Error("Missing or invalid iterator") unless _.isFunction(options.iterator)
      
      view.destroy() for view in @views[name] if @views[name]
      
      ret = []
      
      self = @
      options.iterator.call @, name, options, (modelView) ->
        ret.push self.renderAttachedView name, _.extend {}, self.attachDefaults, options,
          type: "one"
          modelView: modelView

      ret
  
    renderAttachedViews: ->
      if @attachedViews
        console.log "ATTACHED", @attachedViews
        for name, options of @attachedViews
          if options.type is "one" then @views[name] = @renderAttachedView(name, options)
          else if options.type is "many" then @views[name] = @renderAttachedViewList(name, options)
          else throw new Error("Invalid attachment type: #{options.type}")
      @
    
    bindEvents: ->
      if @events
        for mapping, callback of @events
          [event, selector...] = mapping.split(" ")
          selector = selector.join(" ")
          callback = if _.isFunction(callback) then callback else =>
            @trigger callback
          
          console.log "Binding", event, "selector", selector, "el", callback.toString()
            
          if event and selector then @$.delegate selector, event, callback
          else if event then @$.on event, callback
      @

    constructor: ({@model, @collection} = {}) ->
      # Transfer over things set-up through constructor-level methods
      @attachDefaults = @constructor.attachDefaults
      @attach = @constructor.attach
      @attachedViews = @constructor.attachedViews
      
      @views = []
      
      if @model then @model.bind(event, @render) for event in @renderEvents.split(/[, ]/)
      @collection.bind event, @render for event in @renderEvents.split(/[, ]/) if @collection?
  
      @initialize(arguments...)
  
  class lumbar.CollectionView extends lumbar.View
    @attachDefaults:
      type: "many"
      mountPoint: "@"
      mountMethod: "append"
      iterator: (name, options, cb) ->
        # Return a function that iterates through the collection
        throw new Error("Invalid or missing modelViewClass") unless options.modelViewClass
        @collection.each (model) -> cb(new options.modelViewClass(model: model))
      
  lumbar.root = new class extends lumbar.View
    $: $("body")
    render: => @renderAttachedViews()

)(window.lumbar)