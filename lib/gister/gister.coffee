define [
  "cs!gister/models/gist"
  "cs!gister/models/session"
  "ace/ace"
], (gist, session, ace) ->
  
  gist = new gist.Gist(id: "6680b889977d049f4601")
  gist.fetch(saved: true).then ->
    editor = ace.edit("editor")
    editor.getSession().setValue """
    class Hello extends Workd
    """
      