define ["cs!lumbar/lumbar"], (lumbar) ->
  
  class Gist extends lumbar.Model
    @persist "id"
    @persist "description"
    @persist "files", ->
      files = {}
      files[file.id] = file for file in @files.toJSON()
      files
      

    defaults:
      description: ""
      public: true
  

    initialize: ->
      @user = new User
      @comments = new Comments
      @files = new Files
      @history = new History
      @forks = new Forks
      
      @token = null
  
    url: (pushState = false) =>
      if @isNew() then ""
      else if pushState or lumbar.pushState then "/#{@id}"
      else "##{@id}"
  
    parse: (json = {}) ->
      @user = new User(json.user)
      delete json.user
  
      @comments.reset json.comments
      delete json.comments
      
      @files.reset _.map(json.files, File::parse)
      delete json.files
  
      @history.reset json.history
      delete json.history
  
      @forks.reset json.forks
      delete json.forks
  
      json
      
    reset: ->
      @clear()
      
      delete @[@idAttribute]
      delete @user.clear().id
      
      @comments.reset()
      @files.reset()
      @history.reset()
      @forks.reset()
      
      @
      
    fork: ->
      @save url: lumbar.resolve(@url) + "/fork"
  
    sync: (method, model, options = { auth: !!@token }) ->
      methodMap =
        create: "POST"
        read:   "GET"
        update: "PATCH"
        delete: "DELETE"
     
      params =
        url: "https://api.github.com/gists" + lumbar.resolve(model.url, true)
        type: methodMap[method]
        dataType: "json"
  
      if options.auth
        params.beforeSend = (xhr) ->
          xhr.setRequestHeader "Authorization", "token #{@token}" if @token
          
      if method in ["create", "update"]
        params.data = JSON.stringify(model.toJSON()) 
      
      jQuery.ajax _.extend(params, options)
  

  class User extends lumbar.Model
  
  
  class Comment extends lumbar.Model
    parse: (json = {}) ->
      @user = new User(json.user)
      delete json.user
  
      json
  
  class Comments extends lumbar.Collection
    model: Comment
  
  
  class File extends lumbar.Model
    parse: (json) ->
      json.id = json.filename
      json
  
  class Files extends lumbar.Collection
    model: File
  
  
  class Revision extends lumbar.Model
    parse: (json = {}) ->
      @user = new User(json.user)
      delete json.user
  
      @changes = new Changes(json.change_status)
      delete json.change_status
  
      json
  
  class History extends lumbar.Collection
    model: Revision
  
  
  class Forks extends lumbar.Collection
    model: Gist

  Gist: Gist