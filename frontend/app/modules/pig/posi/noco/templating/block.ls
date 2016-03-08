{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
templating = posi.module "noco/templating/-module"

module.exports = h =
  select-as-target: ({$el,parent}) -> promise (d) ->
    templating.surch({$el,parent}) |> c d,
      done: (m) ->
        d.resolve do
          node-type: n.t-block
          apply-cb: (block-node) ->
            new-node = block-node.cAddComponent(n.t-element-r, m.type)
            posi.handler-for(new-node.type!).apply-surch-result(new-node, m)


