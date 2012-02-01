define [
  "cs!gister/router"
  "cs!lumbar/lumbar"
], (Router, lumbar) ->
  
  router = new Router()
  
  lumbar.start()