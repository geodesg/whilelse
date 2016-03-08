{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h =
  stop-on-new-node: true

  select-as-target: ({$el,parent}) -> promise "task.select-as-target", $el, (d) ->
    ui.input({title: 'description', $anchor: $el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        d.resolve do
          node-type: n.ta-task
          apply-cb: (node) ->
            node.cSetAttr n.desc, value


  edit: ({node,$el}) -> promise (d) ~>
    ui.input({title: 'description', $anchor: $el, value: node.a(n.desc)}) |> c d,
      done: ({value} = {}) ->
        node.cSetAttr n.desc, value
        d.resolve!

  onKey: (keycode, ev) ->
    node = posi.cursor.node
    $el = posi.cursor.$currentElem
    switch keycode
    case 'm' # Importance
      ui.choose do
        title: 'Importance'
        options:
          [
            [ 'a', 'essential' ],
            [ 'b', 'important' ],
            [ 'c', 'desirable' ],
            [ 'd', 'nice-to-have' ],
          ] |> map (spec) ->
            [key, name] = spec
            key: key
            name: name
            action: ->
              value = key
              orig-value = node.a(n.ta-importance-a)
              if value != orig-value
                node.cSetAttr(n.ta-importance-a, value)
              posi.cursor.update!
    case 't' # Time Estimate
      orig-value = node.a(n.ta-estimate-a) || null
      ui.input({title: 'time estimate, number + h/d/w/m/y', $anchor: $el, value: orig-value})
        .done ({value} = {}) ->
          value = null if value == ''
          if value != orig-value
            node.cSetAttr(n.ta-estimate-a, value)
          posi.cursor.update!
    case 'w' # Status in Workflow
      orig-value = node.a(n.ta-status-a) || null
      ui.choose do
        title: 'Status'
        options:
          [
            [ 'b', 'backlog' ],
            [ 'n', 'next' ],
            [ 's', 'started' ],
            [ 'c', 'current' ],
            [ 'd', 'done' ],
          ] |> map (spec) ->
            [key, name] = spec
            key: key
            name: name
            action: ->
              value = name
              orig-value = node.a(n.ta-status-a)
              if value != orig-value
                node.cSetAttr(n.ta-status-a, value)
              posi.cursor.update!
    case 'tab'
      # Get previous sibling
      new-parent = node.prev-sibling!
      # Move under previous sibling
      node.cMove({source:new-parent,ref-type:subtask-rtyp(new-parent)})
      posi.cursor.update!
    case 'S-tab'
      # Get parent's next sibling
      before = node.parent!.next-sibling!
      new-parent = node.parent!.parent!
      # Move under parent's parent, before parent's next sibling
      before-ref = before?.parent-ref!
      node.cMove({source:new-parent,ref-type:subtask-rtyp(new-parent),before-ref})
      posi.cursor.update!








subtask-rtyp = (new-parent) ->
  switch new-parent.type!
  case n.ta-task then n.ta-subtask-r
  case n.ta-project then n.ctns
  else throw "subtask-rtyp can't handle #{new-parent.type!.inspect!}"

