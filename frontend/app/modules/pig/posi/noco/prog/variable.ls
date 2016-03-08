u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
prog = posi.module "noco/prog/-module"

module.exports = h =

  create-in-closest-scope: (node, name, surch-deferred) ->
    scope = prog.find-closest-scope(node)
    variable = scope.cAddComponent n.declaration-r, n.variable, name

    surch-deferred.resolve do
      keywords: [variable.name!]
      kind: 'variable'
      name: variable.name!
      ni: variable.ni
      node: variable
      handler-node: n.varref




