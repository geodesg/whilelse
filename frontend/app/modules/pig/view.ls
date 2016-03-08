{ifnn, promise} = u = require 'lib/utils'
{map,each,concat,join,elem-index,find} = prelude
ui = require \ui
api = require 'api'
{box,compute} = boxlib = require 'lib/box'

require! '/models/pig'
{n, repo} = common = require '/models/pig/common'

replacer = (k,v) ->
  if typeof(v) === 'function'
    undefined
  else
    v

j = (obj) -> JSON.stringify(obj, replacer, 2)
console.j = ->
  jargs = arguments |> map j
  console.log ...jargs

module.exports = class PigView extends Backbone.View
  uiName: 'Pig'
  className: 'pig'

  initialize: ->
    @setupMy!

  render: ->
    @update!
    @$el

  update: ->
    @$el.text "PIG"
    @$el.append $("<pre>").attr('id', 'schema')

  setupMy: ->
    pig.load! .done ~>

      # compute 'setupMyCrumbs', ~>
      #   console.log "node crumbs:", n.node.crumbs!

      boxlib.startDebug!

      # compute 'setupMySchema', ~>
      #   #console.log "schema-refs", n.op-t.schema!.refs!
      #   #$('#schema').text j n.op-t.schema!.refs!
      #   el = $('#schema')
      #   el.text('')
      #   nodeType = n.node
      #   schema = nodeType.schema!  # ████████ (step-1)
      #   el.append $('<div>').text schema.inspect!
      #   console.log schema.inspect!
      #   #schema.refs! |> each (ref) ->
      #     #console.j 'schema-ref', ref
      #     #for k, v of ref.gnt
      #       #unless typeof(v) === 'function'
      #         #console.log k, v
      #     #el.append $('<div>').text "#{ref.rt.name!}: #{numericality(ref)} #{ref.gnt.name!}"

      #   #schema.attrs! |> each (attr) ->
      #     #el.append $('<div>').text "#{attr.at.name!}: #{numericality(attr)} #{attr.avt.name!}"
      #     #console.log 'schema-attr', attr

      #compute 'setupMyStrName', ~>
        #console.log "s-str.name: ", n.s-str.name!

      # play = ->
      #   if n.ntyp.name! == 'XOX'
      #     n.ntyp.setName 'OXO'
      #   else
      #     n.ntyp.setName 'XOX'
      #   setTimeout play, 1000

      # setTimeout play, 1000


      # nodesEl = $('<div>')
      # repo |> each (node) ~>
      #   elem = $('<div style="margin: 0.25em; width: 8em; display: inline-block; overflow: hidden; background: #222; border-radius: 0.3em; padding: 0.2em;">')
      #   compute "#{node.ni}-display", ~>
      #     elem.text ""
      #     elem.append $('<div class="id" style="color: #678;"/>').text(node.ni)
      #     elem.append " "
      #     elem.append $('<div class="name"/>').text(node.name! || '-')
      #     elem.append " "
      #     elem.append $('<div class="type" style="color: #464;"/>').text(node.type!.name! || '-')
      #     elem.append " "
      #   nodesEl.append elem
      #   nodesEl.append " "
      # @$el.append(nodesEl)


      # editorEl = $('<div class="pig-editor">')
      # form = $('<form/>')
      # editorEl.append form
      # compute "pigEditor", ~>
      #   console.log "pigEditor"
      #   node = repo.node('133')
      #   schema = node.schema!
      #   console.log schema.inspect!
      #   schema.attrs! |> each (sattr) ->
      #     field = $ '<div class="pig-editor-field">'
      #     field.append $ '<label>' .text sattr.at.name!
      #     field.append $ '<input>'
      #     form.append field
      #   schema.refs! |> each (sref) ->
      #     field = $ '<div class="pig-editor-field">'
      #     field.append $ '<label>' .text sref.rt.name!
      #     field.append $ '<input>'
      #     form.append field
      # @$el.append(editorEl)

      divT = (text) -> $('<div>').text text
      spanT = (text) -> $('<span>').text text
      field = (key, value) -> $ '<div>' .append spanT(key) .append(": ") .append spanT(value) .append ' '


      editorEl = $('<div class="pig-raw-editor">')
      compute "pigEditor", ~>
        node = repo.node('116')

        row = $ '<div>'
        row.append field "id", node.ni
        row.append field "name", node.name!
        for attr in node.attrList!
          row.append field attr.type!.name!, attr.value!
        for ref in node.refs!
          crumbs = []
          node.ancestors! |> each (ancestor) ->
            crumbs.push "#{ancestor.ni}-#{ancestor.name!}"

          row.append crumbs.join(' / ')

        editorEl.append row

      @$el.append(editorEl)



# Internal command format:
#
#   Set attribute:   attr: < node, attrType, value >
#   Add component:   comp: < node, refType, nodeType, name, *< attrType, value > >
#   Add link:        link: < node, refType, targetNode >
#   Move:            move: < node, newParent, newRefType, beforeNode >
#   Set name:        name: < node, value >
#   Set node type:   type: < node, type >
#   Set ref type:    rtyp: < source, refType, target, newTargetType >
#   Delete node:     dele: < node >
#   Delete link:     unln: < source, refType, target >
#
