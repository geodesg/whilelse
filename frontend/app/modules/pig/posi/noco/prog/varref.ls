u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
pig = require 'models/pig'

module.exports = h =

  apply-surch-result: (node, result) ->
    if result.node.type! == n.field
      # class field
      field = result.node
      select = node
      if result.subject == 'this'
        select.cAddComponent n.subject-r, n.this
      else if (subject = result.subject) && subject.type! == n.variable
        varref = select.cAddComponent n.subject-r, n.varref
        varref.cAddLink n.variable-r, subject
      select.cAddLink n.field-r, field
    else
      varref = node
      variable = result.node
      varref.cAddLink n.variable-r, variable

  get-expr-type: (node) ->
    node.rn(n.variable-r).rn(n.data-type-r)
