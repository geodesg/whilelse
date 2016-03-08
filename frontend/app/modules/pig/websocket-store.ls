{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'


module.exports =
  class WebsocketStore
    (@conn) ->

    load: (command-handler, {document}) -> promise (d) ~>
      console.log "WebsocketStore load"
      @conn.send type: 'init', document: document
      #@conn.send type: 'all' # loading initial stuff via rest api
      @conn.onmessage = (message) ->
        switch message.type
        case 'command'
          wire-cmd = message.data
          #console.log "COMMAND from WS", JSON.stringify wire-cmd
          command-handler(wire-cmd)
        case 'done'
          d.resolve!

    init: (command-handler, {document}) -> promise (d) ~>
      console.log "WebsocketStore init"
      @conn.send type: 'init', document: document

    add: (wire-cmd) ->
      @conn.send type: 'command', data: wire-cmd
