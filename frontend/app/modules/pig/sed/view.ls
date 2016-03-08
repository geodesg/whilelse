u = require 'lib/utils'
{map,each,filter,concat,join,elem-index} = prelude

{box,compute,bcg,cbox} = boxlib = require 'lib/box'

pig = require 'models/pig'
{n, repo} = common = require 'models/pig/common'
actions = require 'modules/pig/node/actions'

{tag,div,span,text,join,compute-el} = th = require 'modules/pig/posi/template-helpers'


class SedView extends Backbone.View
  className: "sed"

  initialize: ->
    @node = @model

  render: ->
    node = @node
    schema = @node.type!.schema!
    console.log "schema", schema.inspect

    el =
      div 'head',
        text "Node #{node.ni}"
        div 'field',
          div 'label', text 'type'
          div 'items',
            div 'value',
              text node.type!.name!
        div 'field',
          div 'label', text 'name'
          div 'items',
            div 'value',
              text node.name!
        schema.attrs!
          |> filter (sattr) -> sattr.at && sattr.at != n.name
          |> map (sattr) ->
            div 'field attrt',
              div 'label',
                text sattr.at.name!
              div 'items',
                div 'value',
                  text node.a(sattr.at)
        schema.refs!
          |> filter (sref) -> sref.rt && sref.rt != n.type
          |> map (sref) ->
            children = node.rns(sref.rt)
            div 'field reft',
              div 'label',
                text sref.rt.name!
              div 'items',
                children |> map (child) ->
                  div 'value',
                    text child.inspect!
                if children.length == 0 || sref.rep
                  div 'value'

    @$el.html(el)


module.exports = SedView
