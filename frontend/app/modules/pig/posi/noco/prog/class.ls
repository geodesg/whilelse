{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index,filter} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
cursor = require 'modules/pig/posi/cursor'
#prog = require './module'

module.exports = h =

  select-as-target: ({$el,parent,dep}) -> promise 'expr.select-as-target', $el, (d) ->
    if dep
      d.resolve node-type: n.class
    else
      select-class {$anchor: $el} |> c d,
        done: (target) ->
          d.resolve do
            target: target
            apply-cb: ->
              if parent.type! == n.new # Object instantiation
                # Create args from constructor params
                fcall-h = posi.handler-for n.fcall
                func = target.rn(n.constructor-r)
                fcall-h.populate-args-from-func-params({fcall: parent, func})

  select-property: (klass) -> promise (d) ->
    fields = klass.rns(n.field-r)
    methods = klass.rns(n.method-r)
    posi.surch!.start do
      $el: cursor.$currentElem
      list-on-start: true
      search: (q) ->
        (fields ++ methods)
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


select-class = ({$anchor}) ->
  # returns promise
  actions = require 'modules/pig/node/actions'
  actions.search-select do
    title: "Select class"
    type: n.class
    $anchor: $anchor
