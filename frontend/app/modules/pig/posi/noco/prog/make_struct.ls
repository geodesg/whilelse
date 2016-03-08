u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =

  apply-surch-result: (make-struct, result) ->
    struct-type = result.node
    make-struct.cAddLink n.subject-r, struct-type
    struct-type.rns(n.field-r) |> each (field) ->
      make-struct-arg = make-struct.cAddComponent n.make-struct-arg-r, n.make-struct-arg
      make-struct-arg.cAddLink n.field-r, field

  get-expr-type: (node) ->
    node.rn(n.subject-r)

