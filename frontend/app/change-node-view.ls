{map,each,concat,join,elem-index} = prelude

module.exports = (id) ->
  routes =
    * 'm', 'posi', "main"
    * 'r', 'pn', "raw"

  options = routes |> map (r) ~>
    [key, path, name, o] = r
    {
      key: key
      name: name
      action: ~>
        [key, path, name, o] = r
        o ?= {}
        path = "/#{path}/#{id}"

        console.log "Navigating to #{path}"
        if o.api
          window.open path, '_blank'
        else
          window.router.navigate path, trigger: true
    }

  ui = require '/ui'
  ui.choose do
    title: 'Change View...'
    options: options
