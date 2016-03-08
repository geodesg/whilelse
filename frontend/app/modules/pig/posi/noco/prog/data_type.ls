{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
actions = require 'modules/pig/node/actions'

module.exports = include-generated 'prog-data-type', -> h =
  select-as-target: ({parent, $el}) -> promise (d) ->
    options = []

    unikey = new (require('lib/unikey'))

    basicTypes |> each (t) ->
      options.push do
        key: unikey.issue(t.name)
        name: t.name
        action: ->
          d.resolve target: repo.node(t.id)

    composerTypes |> each (t) ->
      options.push do
        key: unikey.issue(t.name)
        name: t.name
        action: ->
          console.log "t", t
          d.resolve do
            node-type: repo.node(t.id)

    options.push do
      key: unikey.issue("other")
      name: "other"
      action: ->
        actions.search-select type: n.data-type .done (data-type) ->
          #parent.cAddLink sref.rt, data-type
          d.resolve target: data-type

    ui.choose do
      $anchor: $el
      title: 'Select Type'
      options: options
    |> c d


basicTypes = [
  * name: 'integer'
    id: '843'
  * name: 'float'
    id: '841'
  * name: 'string'
    id: '849'
  * name: 'boolean'
    id: '839'
  * name: 'nil'
    id: '845'
  * name: 'number'
    id: '847'
  * name: 'hash'
    id: '962542'
  * name: 'any'
    id: '962548'
]

composerTypes = [
  * name: 'array'
    type: 'array_type'
    id: '855'
  * name: 'struct'
    type: 'struct_type'
    id: '6274'
  * name: 'enum'
    type: 'enum_type'
    id: '7311'
  * name: 'function'
    type: 'function_type'
    id: 'acMEzD5XxCyL'
  * name: 'hash with type'
    type: 'hash_type'
    id: 'acpEQrl95cnH'
  * name: 'box'
    type: 'box'
    id: 'acH2WpDR2dpN'
  * name: 'computed box'
    type: 'computed_box'
    id: 'acTfBiQeUIbA'
]
