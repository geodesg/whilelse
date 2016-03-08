{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'

key = 'store'

module.exports =
  class LocalStore
    (@conn) ->

    load: (command-handler) -> promise (d) ~>
      console.log "LocalStore load"
      data = localStorage.getItem key
      if data
        commands = JSON.parse data
        commands |> each (wire-cmd) ->
          command-handler(wire-cmd)
        d.resolve!
      else
        d.resolve!

    add: (wire-cmd) ->
      data = localStorage.getItem key

      commands =
        if data
          JSON.parse data
        else
          []
      commands.push wire-cmd

      localStorage.setItem key, JSON.stringify(commands)


