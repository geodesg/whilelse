u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,node-link} = th = require 'modules/pig/posi/template-helpers'
posi = require 'modules/pig/posi/main'

module.exports =

  # REFACTOR: extract pattern: key combination to change attribute
  onKey: (keycode, ev) ->
    switch keycode
    when 'S-e'
      node = posi.cursor.node
      ui.choose do
        title: 'Select mode...'
        options:
          [
            ['c', 'collapsed', false]
            ['e', 'expanded',   true]
          ] |> map (spec) ->
            [key, description, value] = spec
            key: key
            name: description
            action: ->
              node.cSetAttr(n.expand-children-a, value) unless node.a(n.expand-children-a) == value
              posi.cursor.update!
      true

  rig: (node,o) ->
    groups = {}
    node.rns(n.ctns) |> each (child) ->
      type = child.type!
      groups[type.ni] ||= { type: type, items: [] }
      groups[type.ni].items.push child
    list = []
    for _, group of groups
      list.push div 'group posi-elem',
        div 'group-head',
          text(group.type.name!)
        div 'group-body',
          group.items |> map (node) ->
            div 'group-item',
              node-link node,
                o.node 'name', node, o
              #text(node.name! || node.id)
    list
