{promise,c} = u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
cursor = require 'modules/pig/posi/cursor'

module.exports = h = schema-module =
  select-attr-ref-target: ({parent, $el}) -> promise (d) ->
    ui.choose do
      $anchor: $el
      title: 'Select Type'
      options:
        * key: 'a'
          name: 'attr'
          action: -> d.resolve node-type: n.s-attr
        * key: 'r'
          name: 'ref'
          action: -> d.resolve node-type: n.s-ref
    |> c d

