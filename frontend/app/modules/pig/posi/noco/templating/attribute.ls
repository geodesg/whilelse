{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
templating = posi.module "noco/templating/-module"

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "attribute.select-as-target", $el, (d) ->
    ui.input({title: 'attribute name', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        d.resolve do
          node-type: n.t-attribute
          apply-cb: (node) ->
            node.cSetAttr n.t-attribute-name-a, value


