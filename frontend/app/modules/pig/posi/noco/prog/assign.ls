{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'

module.exports = h =
  apply-surch-result: (node, result) ->
    node.cAddLink n.operator-r, result.node


  get-expr-type: (node) ->
    if rvalue = node.rn(n.rvalue-r)
      posi.handler-for(n.expr).get-expr-type(rvalue)
