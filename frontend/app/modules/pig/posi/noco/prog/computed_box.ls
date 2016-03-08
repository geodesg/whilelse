u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
{promise,c} = u = require 'lib/utils'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

module.exports = h =

  get-effective-type: (type-generator-node) ->
    type-generator-node.rn(n.component-data-type-r)


