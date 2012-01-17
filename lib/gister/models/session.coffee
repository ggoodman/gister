define ["cs!lumbar/lumbar", "vendor/underscore"], (lumbar) ->
  
  e = {}
  
  class e.File extends lumbar.Model


  class e.Files extends lumbar.Collection
    model: e.File
    
  
  class e.Session extends lumbar.Model
    initialize: ->
      @files = new e.Files

    load: (gist) ->
      @clear silent: true
      @set gist.saved()
      
      @files.reset gist.files.toJSON()
      
      @
  
  e