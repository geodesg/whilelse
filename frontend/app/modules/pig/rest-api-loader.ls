{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'


module.exports =
  class RestApiLoader
    load: (command-handler, {document}) -> promise (d) ~>
      $.getJSON "#{window.location.protocol}//#{window.location.host}/dy/load/#{document}", (commands) ->
        for command in commands
          command-handler command
        d.resolve!

