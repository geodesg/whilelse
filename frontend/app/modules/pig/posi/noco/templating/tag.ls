{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
templating = posi.module "noco/templating/-module"

module.exports = h =
  select-as-target: ({$el,parent}) -> promise (d) ->
    d.resolve node-type: n.t-tag

  apply-surch-result: (tag, m) ->
    tag.cSetAttr(n.t-tag-type-a, m.value)

