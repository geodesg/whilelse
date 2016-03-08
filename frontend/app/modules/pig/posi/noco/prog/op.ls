u = require 'lib/utils'
{map,each,concat,join,elem-index,find} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =
  # When wrapping something in an op, this will be the default ref-type, see: wrap-node
  wrap-ref-type: n.op-arg-r

  apply-surch-result: (node, result) ->
    node.cAddLink n.operator-r, result.node

  get-expr-type: (node) ->
    arg-data-types = node.rns(n.op-arg-r) |> map (arg) -> posi.handler-for(n.expr).get-expr-type(arg)
    var int, float, num, bool, other
    for t in arg-data-types
      switch t
      case n.number-t then num = true
      case n.integer-t then int = true
      case n.float-t then float = true
      case n.boolean-t then bool = true
      case n.any-t then ;
      else other = true
    if num
      n.number-t
    else if float
      n.float-t
    else if int
      n.integer-t
    else if bool
      n.boolean-t
    else
      arg-data-types |> find (t) -> t != n.any-t





