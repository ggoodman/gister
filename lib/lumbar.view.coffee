lumbar = window.lumbar

lumbar.uid = do ->
  index = 0
  -> "uid-#{+new Date}-#{index++}"

window.log = do ->
  repeat = (char, times) ->
    str = ""
    for i in [0...times] then str += char
    str

  stack = []
  enter: (method, args...) ->
    return unless lumbar.view.DEBUG
    console.log repeat(".", stack.length) + ">", method, args
    stack.push(method)
  exit: (args...) ->
    return unless lumbar.view.DEBUG
    method = stack.pop()
    console.log repeat(".", stack.length) + "<", method, args
 

lumbar.view = (viewName, constructor) ->
  log.enter "lumbar.view", arguments...
  if constructor
    constructor::viewName = viewName
    lumbar.view.constructors[viewName] = constructor
  log.exit()
  lumbar.view.constructors[viewName]
lumbar.view.constructors = {}

lumbar.view.DEBUG = true

lumbar.view.registry = {}
lumbar.view.getRegisteredInstance = (dependent, viewName, locals = {}, args = {}) ->
  log.enter "lumbar.view.getRegisteredInstance", arguments...
  uid = dependent.uid or dependent.uid = lumbar.uid()
  reg = lumbar.view.registry

  reg[uid] ||= {}

  unless reg[uid][viewName]
    unless viewClass = lumbar.view(viewName)          
      throw new Error("View not defined: #{viewName}")

    reg[uid][viewName] = new viewClass(args)
    reg[uid][viewName].render(locals)
  
  log.exit reg[uid][viewName]

  reg[uid][viewName]

 

lumbar.view.childViews = {}
lumbar.view.registerChildView = (parentView, childView) ->
  lumbar.childViews[parentView.uid] ||= {}
  lumbar.childViews[parentView.uid][childView.uid] = childViews

 

lumbar.view.renderStack = []
lumbar.view.renderStack.peek = (n = lumbar.view.renderStack.length - 1) ->
  lumbar.view.renderStack[n]

 

lumbar.view.renderChildView = (viewName, locals = {}) ->
  log.enter "lumbar.view.renderChildView", arguments...
  parentView = lumbar.view.renderStack.peek()
  view = lumbar.view.getRegisteredInstance(parentView, viewName, locals)
  
  parentView.childViews.push(view)

  log.exit """<div id="#{view.uid}">PLACEHOLDER DIV</div>"""

  # Return a placeholder div
  #div id: view.uid, -> "PLACEHOLDER DIV THAT YOU SHOULDN'T SEE!"
  """<div id="#{view.uid}">PLACEHOLDER DIV</div>"""



lumbar.view.renderIteratedChildView = (viewName, model) ->
  log.enter "lumbar.view.renderIteratedChildView", arguments...
  parentView = lumbar.view.renderStack.peek()
  view = lumbar.view.getRegisteredInstance(model, viewName, model.toViewModel(), model: model)
  
  lumbar.view.registerDependentModel(view, model)

  parentView.childViews.push(view)

  log.exit """<div id="#{view.uid}">PLACEHOLDER DIV</div>"""

  # Return a placeholder div
  """<div id="#{view.uid}">PLACEHOLDER DIV</div>"""



lumbar.view.renderIteratedView = (modelPath, viewName, locals = {}) ->
  log.enter "lumbar.view.renderIteratedView", arguments...
  collection = lumbar.view.resolveModel(modelPath)

  placeholders = ""

  collection.each (model) ->
    placeholders += lumbar.view.renderIteratedChildView(viewName, model)
  
  log.exit(placeholders)

  text placeholders
   

lumbar.view.registerDependentModel = (view, model) ->
  view.rerender ||= ->
    view.render(model.toViewModel())
    
  model.unbind "change", view.rerender
  model.bind "change", view.rerender

lumbar.view.registerDependentAttribute = (view, model, key) ->
  model.unbind "change:#{key}", view.render
  model.bind "change:#{key}", view.render
   


lumbar.view.registerDependentCollection = (view, model) ->
  console.log "lumbar.view.registerDependentCollection", arguments...
  model.unbind "add", view.render
  model.unbind "remove", view.render
  model.unbind "reset", view.render
  model.bind "add", view.render
  model.bind "remove", view.render
  model.bind "reset", view.render

 

lumbar.view.resolveModel = (modelPath) ->
  log.enter "lumbar.view.resolveModel", arguments...
  parentView = lumbar.view.renderStack.peek()
  model = window
  segments = modelPath.split(".")

  checkSegment = (parentView, model, segment) ->
    if model instanceof Backbone.Model
      model.uid ||= lumbar.uid()
      lumbar.view.registerDependentAttribute(parentView, model, segment)
    else if model instanceof Backbone.Collection
      model.uid ||= lumbar.uid()
      lumbar.view.registerDependentCollection(parentView, model)
  
  for segment in segments
    if model[segment] then model = model[segment]
    else
      checkSegment(parentView, model, segment)
      model = model.get(segment)
  
  checkSegment(parentView, model)

  log.exit model
  
  model

 

class lumbar.View extends lumbar.Emitter
  @register = (name) -> lumbar.view(name, @)
  
  mountPoint: "<div></div>"
  mountOptions: null
  mountMethod: "html"
  template: ->
  initialize: ->


  constructor: (args) ->
    _.extend(@, args)
    
    @uid = lumbar.uid()

    @childViews = []

    @initialize(arguments...)

  detach: ->
    @$.detach if @$
    @


  attachChildViews: ->
    for childView in @childViews
      @$.find("##{childView.uid}").replaceWith(childView.$)
    @

  detachChildViews: ->
    while @childViews.length
      childView = @childViews.pop()
      childView.detach()
    @

  create: ->
    args = [@mountPoint]
    args.push(if _.isFunction(@mountOptions) then @mountOptions.call(@) else @mountOptions) if @mountOptions?
    @$ = $.apply($, args)
    @trigger "create", @
  
  update: ->
    @$.prop(if _.isFunction(@mountOptions) then @mountOptions.call(@) else @mountOptions) if @mountOptions?
    @trigger "update", @

  detach: ->
    @$.detach()
    @trigger "detach", @

  getRenderOptions: (locals) ->
    _.extend locals,
      parent: @
      hardcode:
        $v: lumbar.view.renderChildView
        $c: lumbar.view.renderIteratedView
        $m: lumbar.view.resolveModel

  generateMarkup: (locals) ->
    @markup = CoffeeKup.render(@template, @getRenderOptions(locals))
    @trigger "generate", @
   

  bindEvents: ->
    @boundEvents ||= {}
    if @events
      for mapping, callback of @events
        unless @boundEvents[mapping]
          [event, selector...] = mapping.split(" ")
          selector = selector.join(" ")
          @boundEvents[mapping] = if _.isFunction(callback) then callback else _.bind(@[callback], @)
          
        callback = @boundEvents[mapping]
        
        if event and selector then @$.undelegate(selector, event, callback).delegate(selector, event, callback)
        else if event then @$.off(event, callback).on(event, callback)
    @


  # Full re-render
  render: (locals = {}) =>
    log.enter @viewName, arguments...
    lumbar.view.renderStack.push(@)

    @detachChildViews()

    if @$ then @update()
    else @create()

    @generateMarkup(locals)

    @$[@mountMethod] @markup

    @trigger "mount", @

    @attachChildViews()

    lumbar.view.renderStack.pop()

    @bindEvents()

    log.exit()

    @trigger "render"