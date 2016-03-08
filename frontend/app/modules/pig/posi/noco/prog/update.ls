u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =
  apply-surch-result: (node, result) ->
    node.cAddLink n.operator-r, result.node

  get-expr-type: (node) ->
    if lvalue = node.rn(n.lvalue-r)
      posi.handler-for(n.expr).get-expr-type(lvalue)
