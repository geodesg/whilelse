{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h =
  stop-on-new-node: true

  select-as-target: ({$el,parent}) -> promise "note.select-as-target", $el, (d) ->
    ui.input({title: 'description', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        d.resolve do
          node-type: n.ta-note
          apply-cb: (node) ->
            node.cSetAttr n.desc, value


  edit: ({node,$el}) -> promise (d) ~>
    ui.input({title: 'description', $anchor: $el, value: node.a(n.desc)}) |> c d,
      done: ({value} = {}) ->
        node.cSetAttr n.desc, value
        d.resolve!

