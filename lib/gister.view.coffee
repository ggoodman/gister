((gister) ->
  ###
  Define view classes
  ###

  lumbar.view "gister.header.userpanel", class extends lumbar.View
    template: ->
      ul ".nav.secondary-nav", ->
        li ".dropdown", ->
          a ".dropdown-toggle", href: "#", "Username"


  lumbar.view "gister.header.login", class extends lumbar.View
    template: ->
      form ".pull-right", ->
        input ".small", type: "text", name: "username", placeholder: "Username"
        input ".small", type: "password", name: "password", placeholder: "Password"
        text " "
        a href: "#login", "Login"
  
  lumbar.view "gister.header", class extends lumbar.View
    template: ->
      div ".topbar", ->
        div ".fill", ->
          h3 ".brand", "Gister"
          ul ".nav", ->
            li name: "edit", ->
              if $m("gister.gist.id")
                a href: "##{$m('gister.gist.id')}/#{$m('gister.state.active')}", class: "create edit", name: "edit", "Edit"
              else
                a href: "##{$m('gister.state.active')}", class: "create edit", "Edit"
            li name: "preview", ->
              a href: "#preview/#{gister.gist.id}", class: "preview", "Preview"
          if $m("gister.user.id")
            $v("gister.header.userpanel")
          else
            $v("gister.header.login")
              
    updateActive: ->
      mode = gister.state.get("mode")
      console.log "Mode changed", mode, "li a[class~=#{mode}"
      if @$
        @$.find("li").removeClass("active")
        @$.find("li a[class~=#{mode}]").parent().addClass("active")
    
    initialize: ->
      gister.state.bind "change:mode", => @updateActive()
      @bind "render", => @updateActive()
  
  lumbar.view "gister.sidebar.filelist.file", class extends lumbar.View
    mountPoint: "<li>"
    template: ->
      a { href: (if gister.gist.id then "##{gister.gist.id}/#{@filename}" else "##{@filename}"), title: @filename }, @filename
    
    updateActive: ->
      active = gister.state.get("active")
      if @$
        @$.removeClass("active")
        @$.addClass("active") if $("a", @$).attr("title") == active
      
    initialize: ->
      gister.state.bind "change:active", => @updateActive()
      @bind "render", => @updateActive()
      
  lumbar.view "gister.sidebar.filelist", class extends lumbar.View
    mountPoint: "<ul>"
    mountArgs:
      class: "files"
    template: ->
      $c("gister.gist.files", "gister.sidebar.filelist.file")
  
          
  lumbar.view "gister.sidebar", class extends lumbar.View
    template: ->
      details ".files", open: "open", ->
        summary ->
          text "Files"
          a ".add.pull-right", href: $m("gister.gist.files").getNewFileUrl(), title: "Add a new file to the gist", "Add"
        $v("gister.sidebar.filelist")
        
        
  lumbar.view "gister.editor", class extends lumbar.View
    modes:
      text:         require("ace/mode/text").Mode
      HTML:         require("ace/mode/html").Mode
      css:          require("ace/mode/css").Mode
      js:           require("ace/mode/javascript").Mode
      CoffeeScript: require("ace/mode/coffee").Mode

    template: ->
      div "#editor", ->
        
    loadActive: =>
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

      gister.view.bind "render", ->
        console.log "self"
        self.editor ||= ace.edit("editor")
        self.loadActive()

      gister.gist.bind "change:id", ->
        self.sessions = {}
  
      gister.state.bind "change:active", ->
        self.loadActive()
      
      gister.state.bind "change:mode", self.loadActive

  gister.view = new class extends lumbar.View
    mountPoint: "body"
    template: ->
      header "#topbar", -> $v("gister.header")
      div "#content", ->
        if $m("gister.state.mode") in ["edit", "create"]
          aside "#sidebar", -> $v("gister.sidebar")
          div "#editarea", -> $v("gister.editor")
    

)(window.gister)