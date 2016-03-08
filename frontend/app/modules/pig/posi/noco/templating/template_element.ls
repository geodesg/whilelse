{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
templating = posi.module "noco/templating/-module"

module.exports = h =
  select-as-target: ({$el,parent}) -> promise 'template-element.select-as-target', $el, (d) ->
    templating.surch({$el,parent}) |> c d,
      done: (m) ->
        d.resolve do
          node-type: m.type
          apply-cb: (new-node) ->
            posi.handler-for(new-node.type!).apply-surch-result(new-node, m)


