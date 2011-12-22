((gister) ->
  ###
  Define view classes
  ###


  lumbar.view "gister.header.userpanel", class extends lumbar.View
    template: ->
      ul ".nav.secondary-nav", ->
        li ".dropdown", "data-dropdown": "dropdown", ->
          a ".dropdown-toggle", href: "#", ->
            text $m("gister.user.login")
          ul ".dropdown-menu", ->
            li ->
              a ".logout", href: "#", "Logout"
    
    events:
      "click .logout": (e) ->
        e.preventDefault()
        
        gister.user.clear()
        eraseCookie("_gst.tok")


  lumbar.view "gister.header.login", class extends lumbar.View
    template: ->
      form ".pull-right", ->
        input ".small", type: "text", name: "username", placeholder: "Username"
        input ".small", type: "password", name: "password", placeholder: "Password"
        text " "
        button ".login.btn.small", "Login"
    
    events:
      "click .login": "onClickLogin"
    
    onClickLogin: (e) =>
      console.log "onClickLogin", @, e
      e.preventDefault()
      
      self = @
      
      u = self.$.find("[name=username]").val()
      p = self.$.find("[name=password]").val()

      
      $.ajax
        url: "https://api.github.com/authorizations",
        type: "POST"
        data: JSON.stringify
          scopes: [ "gist" ]
        beforeSend: (xhr) ->
          xhr.setRequestHeader "Authorization", "Basic " + btoa("#{u}:#{p}")
        success: (data) ->
          console.log "Logged in ", data
          createCookie("_gst.tok", data.token)
          
          gister.user.tryLogin()
  
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
          if $m("gister.user.login")
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
      div ".fileops", ->
        a ".rename", { href: "#", name: @filename }, "R"
        a ".delete", { href: "#", name: @filename }, "X"
      a ".filename", { href: (if gister.gist.id then "##{gister.gist.id}/#{@filename}" else "##{@filename}"), title: @filename }, @filename
    
    events:
      "click .rename": (e) ->
        e.preventDefault()
        filename = $(@).attr("name")
        renamed = prompt "New filename:"
        
        if renamed and renamed isnt filename
          gister.gist.files.get(filename).rename(renamed)
      "click .delete": (e) ->
        e.preventDefault()
        
        if "delete" == prompt "Type 'delete' to remove this file:"
          gister.gist.files.remove gister.gist.files.get($(@).attr("name"))
          gister.router.activateFile gister.gist.files.getNewFilename() unless gister.gist.files.length
    updateActive: ->
      active = gister.state.get("active")
      if @$
        @$.removeClass("active")
        @$.addClass("active") if $("a.filename", @$).attr("title") == active
      
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
          unless self.sessions[filename]
            mode = self.modes[file.get("language") or "text"] or self.modes.text
            self.sessions[filename] = new EditSession(file.get("content") or "")
            self.sessions[filename].setMode(new mode)
            self.sessions[filename].setTabSize(2)
            self.sessions[filename].setUseSoftTabs(true)
            
            self.sessions[filename].on "change", ->
              file.set content: self.sessions[filename].getValue()
          
          self.editor.setSession self.sessions[filename]
    
    refreshBuffers: =>
      self = @
      
      gister.gist.files.each (file) ->
        self.sessions[file.id].setValue(file.get("content")) if self.sessions[file.id]
      
        
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
      
      gister.gist.bind "change:updated_at", self.refreshBuffers        
      
      gister.state.bind "change:mode", self.loadActive

  lumbar.view "gister.fileops",  class extends lumbar.View     
    template: ->
      if $m("gister.gist.owned")
        button ".btn.save.primary", "Save"
        if $m("gister.gist.id")
          button ".btn.delete.danger.pull-right", "Delete"
      else
        button ".btn.fork.primary", "Fork"
    
    events:
      "click .save": -> gister.gist.save()
      "click .fork": -> gister.gist.fork()
      "click .delete": -> gister.gist.destroy() if "delete" == prompt "Type 'delete' to confirm deletion:"

  lumbar.view "gister.preview",  class extends lumbar.View     
    initialize: ->
      window.requestFileSystem ||= window.webkitRequestFileSystem
      window.resolveLocalFilesystemURL ||= window.webkitResolveLocalFileSystemURL
      window.BlobBuilder ||= window.WebKitBlobBuilder
      
      self = @
      
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
        $content = $("#content")
        $iframe = $("<iframe />")
          .attr("src", "filesystem:#{window.location.protocol}//#{window.location.host}/temporary/#{gister.gist.id}/index.html")
          .css(border: 0)
          .width($content.width())
          .height($content.height())
        
        self.$.html $iframe
        
        #self.$.attr("src", "filesystem:#{window.location.protocol}//#{window.location.host}/temporary/#{gister.gist.id}/index.html")
      
      loadFiles = (fs) ->
        remaining = 0
        gister.gist.files.each (file) ->
          remaining++
          fs.root.getDirectory gister.gist.get("id"), {create: true}, (dirEntry) ->
            dirEntry.getFile file.get("filename"), {create: true}, (fileEntry) ->
              fileEntry.createWriter (fileWriter) ->
                fileWriter.onwriteend = (e) -> runPreview() unless --remaining
                fileWriter.onerror = errorHandler
                
                content = file.get("content")
                console.log "Blob", file.get("filename"), content
                gister.gist.files.each (file) ->
                  content = content.replace file.get("filename"), "filesystem:#{window.location.protocol}//#{window.location.host}/temporary/#{gister.gist.id}/#{file.get('filename')}"
                
                bb = new BlobBuilder()
                bb.append(content)
                
                blob = bb.getBlob(file.get("type"))
                
                fileWriter.truncate blob.size if fileEntry.size > blob.size
                fileWriter.write blob
              , errorHandler
            , errorHandler
          , errorHandler

      requestFileSystem TEMPORARY, 5 * 1024 * 1024, loadFiles, errorHandler      

  gister.view = new class extends lumbar.View
    mountPoint: "body"
    template: ->
      header "#topbar", -> $v("gister.header")
      div "#content", ->
        switch $m("gister.state.mode")
          when "edit", "create"
            aside "#sidebar", -> $v("gister.sidebar")
            div "#fileops", -> $v("gister.fileops")
            div "#editarea", -> $v("gister.editor")
          when "preview"
            $v("gister.preview")

)(window.gister)