((gister) ->
  ###
  Set up models
  ###
  
  class BufferModel extends lumbar.Model
    language:
      "txt"     : "text"
      "js"      : "js"
      "coffee"  : "CoffeeScript"
      "md"      : "Markdown"
      "html"    : "HTML"
      "css"     : "css"
      
    defaults:
      title: ""
      content: ""
      type: "text/plain"
      language: ""
      
  
  gister.buffers = new class extends lumbar.Collection
    model: BufferModel
    initialize: ->
      # This happens only once at load
      @add
        title: "Untitled"
        content: ""
        type: "text/plain"
  
  gister.state = new class extends lumbar.Model
    initialize: ->

)(window.gister)