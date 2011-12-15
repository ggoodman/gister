((gister) ->
  ###
  Define view classes
  ###
  
  lumbar.view "gister.header",
    template: ->
      div ".topbar", ->
        div ".fill", ->
          h3 ".brand", "Gister"
          ul ".nav", ->
            li ".active", ->
              a href: "#edit/#{gister.gist.id}", "Edit"
  
  lumbar.view "gister.sidebar.filelist.file",
    mountPoint: "<li>"
    template: ->
      a {href: if gister.gist.id then "#edit/#{gister.gist.id}/@filename" else "#edit/#{@filename}"}, @filename
      
  lumbar.view "gister.sidebar.filelist",
    mountPoint: "<ul>"
    template: ->
      $m("gister.gist.files").each (file) -> $v("gister.sidebar.filelist.file", file)
  
          
  lumbar.view "gister.sidebar",
    template: ->
      details ".files", open: "open", ->
        summary ->
          text "Files"
          a ".add.pull-right", href: $m("gister.gist.files").getNewFileUrl(), title: "Add a new file to the gist", "Add"
        $v("gister.sidebar.filelist")
        
        
  lumbar.view "gister.editor",
    template: ->
      div "#editor", ->
        
    initialize: ->
      @bind "attach", (view) ->
        console.log "Editor", $("body"), $("#editor")
        view.editor = ace.edit("editor")
        
  gister.view = new class extends lumbar.View
    mountPoint: "body"
    template: ->
      header "#topbar", -> $v("gister.header")
      div "#content", ->
        aside "#sidebar", -> $v("gister.sidebar")
        div "#editarea", -> $v("gister.editor")
    

)(window.gister)