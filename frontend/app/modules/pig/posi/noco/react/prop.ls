{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h =
  apply-surch-result: (node, result) ->
    node.cSetAttr n.react-name-a, result.name

  select-as-target: ({$el,parent}) -> promise (d) ->
    ui.input({title: 'prop name', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        d.resolve do
          node-type: n.react-prop
          apply-cb: (node) ->
            node.cSetAttr n.react-name-a, value


