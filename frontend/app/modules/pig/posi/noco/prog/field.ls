{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index,filter} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
cursor = require 'modules/pig/posi/cursor'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise 'field.select-as-target', $el, (d) ->
    # This will probably not be invoked as '.' will trigger
    # a case in prog/-module.ls

    # find type
    parent-type = parent.type!
    switch parent-type
    when n.select
      select-as-target-for-select({$el,parent,d})
    when n.struct-type, n.class
      ui.input({title: 'field name', $anchor: $el}) |> c d,
        done: ({value} = {}) ->
          value = null if value == ''
          if value
            d.resolve do
              node-type: n.field
              apply-cb: (node) ->
                node.cSetName value
          else
            d.reject skip: true
    else
      d.reject error: 'parent not a select or struct-type node'


  select-field: (expr-type) -> promise (d) ->
    fields = expr-type.rns(n.field-r)
    posi.surch!.start do
      $el: cursor.$currentElem
      list-on-start: true
      search: (q) ->
        fields
        |> filter (field) ->
          field.name!.indexOf(q) == 0
        |> map (field) ->
          keywords: [field.name!]
          kind: 'field'
          name: field.name!
          node: field
    .then (m) ->
      if m && m.node
        d.resolve(m.node)
      else
        d.reject!

# Private

select-as-target-for-select = ({$el,parent,d}) ->
  expr = parent.rn(n.subject-r)

  expr-type = posi.handler-for(n.expr).get-expr-type(expr)

  if ! expr-type
    d.reject error: 'could not get expr type'
    return

  if expr-type.type! == n.struct-type
    h.select-field(expr-type) |> c d,
      done: (selected-field) ->
        d.resolve target: selected-field
  else
    d.reject error: 'expr not a struct'
    return
