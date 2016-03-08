{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
actions = require 'modules/pig/node/actions'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "node_literal.select-as-target", $el, (d) ->
    actions.search-select! .done (lnode) ->
      d.resolve do
        node-type: n.node-literal
        apply-cb: (node) ->
          node.cAddLink n.refs, lnode



