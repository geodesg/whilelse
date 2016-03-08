{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "property.select-as-target", $el, (d) ->
    ui.input({title: 'key', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        if value
          d.resolve do
            node-type: n.object-property
            apply-cb: (node) ->
              node.cSetAttr n.key-a, value


