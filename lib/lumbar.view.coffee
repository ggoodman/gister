((lumbar) ->
  
  lumbar.views = {}
  
  lumbar.view = (name, definition) ->
    if definition?
      cls = class extends lumbar.View
      _.extend cls.prototype, definition
      lumbar.views[name] = cls
    
    lumbar.views[name]
  
  class lumbar.View extends lumbar.Emitter
    mountPoint: "<div></div>"
    template: ->
    initialize: ->
    series: do ->
      counter = 0
      (inc = true) -> if inc then counter++ else counter
    
    destroy: ->
      @resetDependents()
      @$.remove()
      @
      
    resetDependents: ->
      for model in @dependentModels
        console.log "unbinding", model
        model.unbind "all", @render
      
      for view in @dependentViews
        view.destroy()
        
      @dependentModels = []
      @dependentViews = []
      
      @      
    
    render: (locals = {}) =>
      lumbar.renderStack ||= []
      lumbar.renderStack.push [{id: 0: view: @}]
      
      lumbar.attachStack ||= []
      lumbar.attachStack.push @
      
      @resetDependents()
      
      @$ ||= $(@mountPoint)
      
      @$.html CoffeeKup.render @template, _.extend(locals, parent: @),
        hardcode:
          $v: (name, locals = {}) ->
            throw new Error("Invalid or missing view: #{name}") unless lumbar.views[name]
            top = lumbar.renderStack.length - 1
            entry = 
              view: new lumbar.views[name]
            lumbar.renderStack[top].push(entry)
            
            @parent.dependentViews.push(entry.view)

            locals = locals.getViewModel() if _.isFunction(locals.getViewModel)
            
            entry.id = entry.view.series()
            entry.view.parent = @parent
            entry.view.render(locals)
            # Return a placeholder div
            div id: "mp-#{entry.id}", ->
          $m: (path) ->
            path = path.split(".")
            model = window
            
            for step in path
              model = model[step]
            
            if model.bind?
              @parent.dependentModels.push(model)
              view = @parent
              model.bind "all", _.throttle((-> view.render()), 100)
            
            model
      
      deferred = lumbar.renderStack.pop()
      for {id, view} in deferred
        $marker = $("#mp-#{id}", @$)
        if $marker.size()
          $marker.before view.$
          $marker.remove()
      
      @trigger "render", @
      
      unless lumbar.renderStack.length
        while lumbar.attachStack.length
          view = lumbar.attachStack.pop()
          view.trigger "attach", view
          
      @bindEvents()
      @
  
    destroy: =>
      @$.detach()
      
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
      @dependentModels = []
      @dependentViews = []
      
      @initialize(arguments...)
      
  lumbar.root = $("body")

)(window.lumbar)