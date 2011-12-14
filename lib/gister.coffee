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
      button ".btn.pull-right", "Preview"
    div "#editarea", ->
      input "#toggle", type: "checkbox", checked: "checked"
      label for: "toggle", ->
        span ""
      aside "#sidebar", ->
      div "#editorC", ->
        div "#editor", ->

  events:
    "click button": ->
      window.requestFileSystem ||= window.webkitRequestFileSystem
      window.resolveLocalFilesystemURL ||= window.webkitResolveLocalFileSystemURL
      window.BlobBuilder ||= window.WebKitBlobBuilder
      
      errorHandler = (e) ->
        switch e.code
          when FileError.QUOTA_EXCEEDED_ERR
            msg = 'QUOTA_EXCEEDED_ERR'
          when FileError.NOT_FOUND_ERR
            msg = 'NOT_FOUND_ERR';
          when FileError.SECURITY_ERR
            msg = 'SECURITY_ERR';
          when FileError.INVALID_MODIFICATION_ERR
            msg = 'INVALID_MODIFICATION_ERR';
          when FileError.INVALID_STATE_ERR
            msg = 'INVALID_STATE_ERR';
          else
            msg = 'Unknown Error';
        throw new Error("FS: #{msg}")
      
      runPreview = ->
        url = resolveLocalFilesystemURL(gister.state.get("currentFile"))
        console.log "Resolved", gister.state.get("currentFile"), "to", url
        window.open("filesystem:#{window.location.protocol}//#{window.location.host}/temporary/index.html", "preview", "", true)
      
      loadFiles = (fs) ->
        remaining = 0
        gister.gist.files.each (file) ->
          remaining++
          fs.root.getFile file.get("filename"), {create: true}, (fileEntry) ->
            fileEntry.createWriter (fileWriter) ->
              fileWriter.onwriteend = (e) -> runPreview() unless --remaining
              fileWriter.onerror = errorHandler
              
              content = file.get("content")
              console.log "Blob", file.get("filename"), content
              gister.gist.files.each (file) ->
                content = content.replace file.get("filename"), "filesystem:#{window.location.protocol}//#{window.location.host}/temporary/#{file.get('filename')}"
              
              bb = new BlobBuilder()
              bb.append(content)
              
              fileWriter.write bb.getBlob(file.get("type"))
            , errorHandler
          , errorHandler

      requestFileSystem TEMPORARY, 5 * 1024 * 1024, loadFiles, errorHandler

lumbar.root.attach "gister", modelView: new GisterView
