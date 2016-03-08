{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{n,repo} = require 'models/pig/common'


module.exports = h =
  select-as-target: ({$el,parent}) -> promise "subpath.select-as-target", $el, (d) ->
    ui.input({title: 'path element', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        if value
          d.resolve do
            node-type: n.web-subpath
            apply-cb: (node) ->
              node.cSetAttr n.value-a, value
              node.cAddComponent n.web-route-r, n.web-route, null
        else
          d.fail skip: true



