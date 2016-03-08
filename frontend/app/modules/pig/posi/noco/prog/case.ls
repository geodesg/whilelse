{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "property.select-as-target", $el, (d) ->
    ui.choose do
      title: 'Case?'
      options:
        * key: 'c'
          name: 'case'
          action: ->
            d.resolve node-type: n.case
        * key: 'd'
          name: 'default'
          action: ->
            d.resolve do
              node-type: n.case
              apply-cb: (node) -> node.cSetAttr n.is-default-a, true
        * key: 'tab'
          name: 'skip'
          action: ->
            d.reject skip: true



