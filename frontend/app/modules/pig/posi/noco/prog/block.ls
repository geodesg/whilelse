{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

module.exports = h =
  select-as-target: ({$el,parent}) -> promise 'block.select-as-target', $el, (d) ->
    d.resolve do
      node-type: n.block
