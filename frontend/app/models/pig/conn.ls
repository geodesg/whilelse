var socket
queue = []
opening = false # true when an attempt to open a connection is in progress
reconnect-attempts = 0


module.exports = conn =
  onmessage: null

  open: ->
    connect!

  send: (obj) ->
    queue.push JSON.stringify(obj)
    flush-queue!



# -- Private --

connect = ->
  if ! socket || socket.readyState != WebSocket.OPEN && ! opening
    opening := true

    protocol = if window.location.protocol == 'https:' then 'wss:' else 'ws:'
    url = "#{protocol}//#{window.location.host}/dy/"
    console.log "socket URL", url
    socket := new WebSocket url
    socket.onopen = (event) ->
      console.log "socket OPEN", event
      opening := false
      reconnect-attempts := 0
      flush-queue!

    socket.onclose = (event) ->
      console.warn "socket CLOSE", event
      opening := false
      socket := undefined
      reconnect!

    socket.onerror = (event) ->
      console.error "socket ERROR", event
      opening := false

    socket.onmessage = (event) ->
      #console.log "socket MESSAGE", event
      if conn.onmessage
        conn.onmessage JSON.parse(event.data)

flush-queue = ->
  while queue.length > 0
    if socket && socket.readyState == WebSocket.OPEN
      payload = queue.shift!
      socket.send payload
    else
      connect!
      return

reconnect-timeout = null

reconnect = ->
  unless reconnect-timeout
    reconnect-attempts := reconnect-attempts + 1
    wait-time-med = (Math.pow(2, reconnect-attempts) / 4) * 1000
    wait-time = (Math.random! + 0.5) * wait-time-med
    console.log "delay: ", wait-time, wait-time-med
    reconnect-timeout :=
      setTimeout do
        ->
          reconnect-timeout := null
          connect!
        wait-time

