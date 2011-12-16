((lumbar) ->
  
  lumbar.views = {}
  
  lumbar.view = (name, definition) ->
    if definition?
      cls = class extends lumbar.View
      _.extend cls.prototype, definition
      lumbar.views[name] = cls
    
    lumbar.views[name]
  
  lumbar.view.stack = []
  lumbar.view.top = -> lumbar.view.stack[lumbar.view.stack.length - 1]
  
  class lumbar.View
    mountPoint: "<div></div>"
    mountArgs: null
    mountMethod: "html"
    template: ->
    compiled: null
    initialize: ->
  
    sequence: do ->
      sequence = 0
      (increment = true) -> if increment then sequence++ else sequence
  
    constructor: ->
      @dependentModels = []
      @dependentViews = []
  
      @initialize(arguments...)
  
    create: (mountPoint = @mountPoint, mountArgs = @mountArgs) ->
      args = [mountPoint]
      args.push(mountArgs) if mountArgs
      @$ = $.apply($, args)
      @
    
    destroy: =>
      console.log "Destroying", @
      @clearDependents()
      @unbind()
      @$.remove() if @$
      @$ = null
      @
  
    clearDependents: ->
      while @dependentModels.length
        model = @dependentModels.pop()
        if model instanceof Backbone.Collection
          model.unbind "add", @rerender
          model.unbind "remove", @rerender
          model.unbind "destroy", @rerender
          model.unbind "reset", @rerender
        else if model instanceof Backbone.Model
          model.unbind "change", @rerender
      
      while @dependentViews.length then @dependentViews.pop().destroy()
      
      @attachQueue = []
      @
  
    # Attach the child to this view and return a temporary mountPoint
    attachDependentView: (view) ->
      id = "mount-#{@sequence()}"
      @dependentViews.push(view)
      @attachQueue.push(id: id, view: view)
      id
  
    attachDependentModel: (model, key) ->
      @dependentModels.push(model) unless model in @dependentModels
      self = @
      @rerender = ->
        console.log "Asked to rerender", self, @
        self.render()
      
      if model instanceof Backbone.Collection
        console.log "Dependent collection attached", model
        model.bind "add", @rerender
        model.bind "remove", @rerender
        model.bind "destroy", @rerender
        model.bind "reset", @rerender
      else if model instanceof Backbone.Model
        console.log "Dependend model attached", model
        model.bind "change:#{key}", @rerender
      @
      
  
    createCompileOptions: ->
        locals:
          parent: @
  
    createRenderOptions: (locals = {}) ->
      _.extend locals,
        parent: @
        hardcode:
          $v: (viewName, locals = {}) ->
            unless viewClass = lumbar.view(viewName)
              throw new Error("View not defined: #{viewName}")
            
            locals = locals.getViewModel() if _.isFunction(locals.getViewModel)
            
            view = new viewClass()
            view.render(locals)
            id = lumbar.view.top().attachDependentView(view)
            div id: id, "Mount point"
          $m: (modelPath) ->
            path = modelPath.split(".")
            model = window
            for step in path
              lastModel = model
              model = model[step] or model.get(step)
              break unless model
            
            lastModel = model if model.bind
              
            lumbar.view.top().attachDependentModel(lastModel, step) if lastModel.bind
            model
            
  
    bindEvents: ->
      if @events
        for mapping, callback of @events
          [event, selector...] = mapping.split(" ")
          selector = selector.join(" ")
          callback = if _.isFunction(callback) then callback else =>
            @trigger callback
          
          if event and selector then @$.delegate selector, event, callback
          else if event then @$.on event, callback
      @
  
    generateMarkup: (locals = {}) ->
      @markup = CoffeeKup.render(@template, @createRenderOptions(locals))
      @trigger "generate", @
      @
  
    attachChildViews: ->
      while @attachQueue.length
        {id, view} = @attachQueue.pop()
        $("##{id}", @$).replaceWith(view.$)
        view.trigger "attach", view
      @
  
    render: (locals = {}) =>
      # Clear dependent models and views, removing listeners and DOM elements
      @clearDependents()
  
      # Create the container that will hold the view's DOM
      @create() unless @$
  
      lumbar.view.stack.push(@)
  
      # Render the generated markup into the container
      @$[@mountMethod] @generateMarkup(locals).markup
  
      lumbar.view.stack.pop()
   
      @trigger "mount", @
  
      # Child views have been rendered as empty divs; replace those with the markup
      @attachChildViews()
  
      @trigger "render", @
  
      @bindEvents()
      
      @

  _.extend lumbar.View.prototype, Backbone.Events

)(window.lumbar)