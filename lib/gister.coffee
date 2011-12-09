window.gister = 
  version: "0.0.1"
  start: ->
    lumbar.start()
      
gister.router = new class extends Backbone.Router
  routes:
    "*gist": "onGist"
  
  onGist: (gistId) ->
    console.log "Matched route", gistId or "1450136"
    gister.state.set gistId: (gistId or "1450136")

class GistFile extends lumbar.Model
  idAttribute: "filename"
  
class GistFileCollection extends lumbar.Collection
  model: GistFile
  initialize: ->
    @bind "reset", -> console.log "RESET", arguments...

class Gist extends lumbar.Model
  initialize: ->
    @files = new GistFileCollection
  
  getViewModel: -> _.extend {}, @toJSON(),
    files: @files
        
  fetch:  ->
    if @id
      self = @
      self.trigger "load:start"
      $.ajax "https://api.github.com/gists/#{self.id}",
        dataType: "jsonp"
        success: (json) ->
          console.log "JSON", arguments...
          self.set(json.data)
          self.files.reset _.values(json.data.files)
          self.trigger "load:success"
        error: -> self.trigger "load:error"

gister.gist = new Gist
gister.state = new class extends lumbar.Model
  defaults:
    currentFile: null
    gistId: ""
  
  initialize: ->
    @bind "change:gistId", ->
      gister.gist.clear().set(id: gister.state.get("gistId"))
      gister.gist.fetch()
      
    gister.gist.files.bind "reset", ->
      if gister.gist.files.length
        console.log "FILES", gister.gist.files.first().id
        gister.state.set currentFile: gister.gist.files.first().id if gister.gist.files.length

       
# VIEWS

class GistFileView extends lumbar.View
  template: ->
    li -> @filename
  
  events:
    "click": (e) -> gister.state.set currentFile: $(e.target).text()
  
  initialize: ->
    self = @
    gister.state.bind "change:currentFile", @checkActive
    @bind "rendered", @checkActive
  
  checkActive: =>
    currentFile = gister.state.get("currentFile")
    
    if currentFile == @$.text() then @$.addClass("active")
    else @$.removeClass("active")

class GistFileListView extends lumbar.CollectionView
  @attach "files",
    modelViewClass: GistFileView

        
class SidebarView extends lumbar.View
  @attach "files",
    mountPoint: ".files"
    modelView: new GistFileListView(collection: gister.gist.files)

  template: ->
    div ".search", ->
      input name: "gistId", value: @id
    details open: "open", ->
      summary "Files"
      ul ".files", ->
    details ->
      summary "Mixins"
  
  events:
    "change input": (e) ->
      console.log "Triggered change!!", arguments...
      gister.router.navigate $(e.target).val(), true
      #e.preventDefault()
      #false # Prevent form submission


class EditorView extends lumbar.View
  modes:
    text:         require("ace/mode/text").Mode
    HTML:         require("ace/mode/html").Mode
    css:          require("ace/mode/css").Mode
    js:           require("ace/mode/javascript").Mode
    CoffeeScript: require("ace/mode/coffee").Mode
    
  initialize: ->
    @sessions = {}
    
    @bind "rendered", => @editor = ace.edit("editor")    
    
    EditSession = require("ace/edit_session").EditSession

    self = @
    gister.state.bind "change:currentFile", ->
      if filename = gister.state.get("currentFile")
        if file = gister.gist.files.get(filename)
          unless self.sessions[filename]
            mode = self.modes[file.get("language") or "text"] or self.modes.text
            self.sessions[filename] = new EditSession(file.get("content"))
            self.sessions[filename].setMode(new mode)
          
          self.editor.setSession self.sessions[filename]

class GisterView extends lumbar.View
  @attach "sidebar",
    modelView: new SidebarView(model: gister.gist)
    mountPoint: "#sidebar"
  
  @attach "editor",
    modelView: new EditorView
    mountPoint: "#editor"
    
  template: ->
    header "#topbar", ->
      span "Gister"
    div "#editarea", ->
      input "#toggle", type: "checkbox", checked: "checked"
      label for: "toggle", ->
        span ""
      aside "#sidebar", ->
      div "#editorC", ->
        div "#editor", ->


lumbar.root.attach "gister", modelView: new GisterView
