{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "symbol.select-as-target", $el, (d) ->
    ui.input({title: 'symbol name', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        if value
          d.resolve do
            node-type: n.symbol
            apply-cb: (node) ->
              node.cSetName value

