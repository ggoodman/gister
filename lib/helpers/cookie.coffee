define ->
  write: (name, value, options = {}) ->
    options.path ||= "/"
    
    if options.hours then expires = 1000 * 60 * 60 * options.hours
    if options.days then expires += 1000 * 60 * 60 * 24 * options.days
    
    if expires
      expires = new Date(expires + new Date())
      expires = "; expires=#{new Date(expires + new Date()).toGMTString()}"
    else expires = ""
    
    document.cookie = "#{name}=#{value}#{expires}; path=#{options.path}"
    
  read: (name) ->
    nameEQ = "#{name}="
    
    for c in document.cookie.split(";")
      c = c.substring(1, c.length) while c.charAt(0) is " "
      return c.substring(nameEQ.length,c.length) if c.indexOf(nameEQ) is 0
    
    null
  
  erase: (name) -> createCookie(name, "", hours: -1)
