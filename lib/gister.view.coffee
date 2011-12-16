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
            li name: "edit", ->
              a href: "##{$m('gister.gist.id')}/#{$m('gister.state.active')}", name: "edit", "Edit"
            li name: "preview", ->
              a href: "#preview/#{gister.gist.id}", name: "preview", "Preview"
              
    updateActive: ->
      mode = gister.state.get("mode")
      if @$
        @$.find("li").removeClass("active")
        @$.find("li a[name=#{mode}").parent().addClass("active")
        
        console.log "Found", mode, @$.find("li a[name=#{mode}")
    
    initialize: ->
      console.log "Initialized gister.header"
      gister.state.bind "change:mode", => @updateActive()
      @bind "render", => @updateActive()
  
  lumbar.view "gister.sidebar.filelist.file",
    mountPoint: "<li>"
    template: ->
      a { href: (if gister.gist.id then "##{gister.gist.id}/#{@filename}" else "##{@filename}"), title: @filename }, @filename
    
    updateActive: ->
      active = gister.state.get("active")
      if @$
        @$.removeClass("active")
        @$.addClass("active") if $("a", @$).attr("title") == active
      
    initialize: ->
      console.log "Initialized gister.sidebar.filelist.file"
      gister.state.bind "change:active", => @updateActive()
      @bind "render", => @updateActive()
      
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
    modes:
      text:         require("ace/mode/text").Mode
      HTML:         require("ace/mode/html").Mode
      css:          require("ace/mode/css").Mode
      js:           require("ace/mode/javascript").Mode
      CoffeeScript: require("ace/mode/coffee").Mode

    template: ->
      div "#editor", ->
        
    loadActive: ->
      EditSession = require("ace/edit_session").EditSession
      
      self = @
      if filename = gister.state.get("active")
        if file = gister.gist.files.get(filename)
          console.log "Session changed", file, filename
          unless self.sessions[filename]
            mode = self.modes[file.get("language") or "text"] or self.modes.text
            self.sessions[filename] = new EditSession(file.get("content") or "")
            self.sessions[filename].setMode(new mode)
            self.sessions[filename].setTabSize(2)
            self.sessions[filename].setUseSoftTabs(true)
          
          self.editor.setSession self.sessions[filename]
        
    initialize: ->
      @sessions = {}

      self = @

      @bind "attach", ->
        self.editor ||= ace.edit("editor")
        self.loadActive()

      gister.gist.bind "change:id", ->
        self.sessions = {}
  
      gister.state.bind "change:active", ->
        self.loadActive()

  gister.view = new class extends lumbar.View
    mountPoint: "body"
    template: ->
      header "#topbar", -> $v("gister.header")
      div "#content", ->
        if $m("gister.state.mode") in ["edit", "create"]
          aside "#sidebar", -> $v("gister.sidebar")
          div "#editarea", -> $v("gister.editor")
    

)(window.gister)