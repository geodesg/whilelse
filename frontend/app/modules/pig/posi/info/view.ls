{promise,c} = u = require 'lib/utils'
{map,each,filter,concat,join,elem-index} = prelude

posi = require 'modules/pig/posi/main'


module.exports = class PosiInfoView extends Backbone.View
  className: "posi-info"

  render: ->
    @$el.text "POSI-INFO"
    @$el

  inspect-element: (el) ->
    {
      tag,div,span,text,
      join,compute-el,add-children,ch,node-link,blank,
      line,space,lines
    } = require 'modules/pig/posi/template-helpers'

    @$el.text('')
    if el
      a = []

      n = 20
      e = el
      while n > 0 && e && e.length > 0
        item-class = switch
                     case e.hasClass('posi-node') then "node"
                     case e.hasClass('posi-propt') then "propt"
                     case e.hasClass('posi-prop') then "prop"
        el =
          div "item #{item-class}",
            span 'type', text e[0].tagName
            space!
            span 'id', text e.attr('id')
            space!
            span 'classes',
              (e.attr('class') || '').split(' ') |> map (c) ->
                span 'class', text c
            span 'data',
              (->
                d = div!
                for k,v of e.data!
                  d.appendChild div 'row',
                    span 'key', text k
                    span 'value', text v
                d
              )()
        @$el.prepend($(el))
        e = e.parent!

        n--
      @show!

  hide: -> @$el.hide!
  show: -> @$el.show!
