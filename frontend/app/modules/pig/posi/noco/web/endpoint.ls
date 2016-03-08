{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{n,repo} = require 'models/pig/common'


module.exports = h =
  select-as-target: ({$el,parent}) -> promise "endpoint.select-as-target", $el, (d) ->
    item = (key, value) ->
      key: key
      name: value
      action: ->
        d.resolve do
          node-type: n.web-endpoint
          apply-cb: (node) ->
            node.cSetAttr n.web-request-method-a, value

    ui.choose do
      title: "Endpoint method"
      $anchor: $el
      options:
        * item \g, \GET
        * item \p, \POST
        * item \u, \PUT
        * item \d, \DELETE
        * item \h, \HEAD
        * item \o, \OPTIONS
    |> c d

http-methods = <[
  GET
  POST
  PUT
  DELETE
  HEAD
  OPTIONS
]>
