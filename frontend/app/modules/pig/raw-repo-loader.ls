{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'

module.exports = (document) -> promise (d) ~>
  url = "#{window.location.protocol}//#{window.location.host}/dy2/load/#{document}"
  console.log "GET", url
  $.getJSON url, (raw-repo) ->
    d.resolve raw-repo


