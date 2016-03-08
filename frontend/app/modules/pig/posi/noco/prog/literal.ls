u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
{promise,c} = u = require 'lib/utils'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

module.exports = h =

  apply-surch-result: (node, result) ->
    node.cSetAttr n.literal-value-a, result.value


  edit: ({node,$el}) -> promise (d) ~>
    # Invoke surch in literal-only mode
    prog.surch-literal({$el}) |> c d,
      done: (m) ->
        # m (example):
        #   data_type: "integer"
        #   handlerNode: Node
        #   kind: "literal"
        #   mowner_id: "814"
        #   node: Node
        #   nti: "814"
        #   value: 333
        h.apply-surch-result(node, m)
        posi.cursor.update!

  get-expr-type: (node) ->
    v = node.a(n.literal-value-a)
    if u.is-number(v)
      if Math.trunc(v) == v
        n.integer-t
      else
        n.float-t
    else if u.is-boolean(v)
      n.boolean-t
    else if u.is-string(v)
      n.string-t
    else if v == null
      n.nil-t



