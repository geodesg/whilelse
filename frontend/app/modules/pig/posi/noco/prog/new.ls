u = require 'lib/utils'
{map,each,concat,join,elem-index,filter,find} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
fcall-h = require 'modules/pig/posi/noco/prog/fcall'

#module.exports = include-generated 'prog-new', -> h =
module.exports = h =

  get-expr-type: (node) ->
    node.rn(n.data-type-r)

  keyCommands: ->
    return
      defaults:
        group: 'new'
      commands: [
        * key: 'S-o'
          name: "Open class definition"
          cmd: ->
            if node = posi.cursor.node
              posi.navigateToNode(node.rn(n.data-type-r))
        * key: 'S-l'
          name: "Complete parameters"
          cmd: ->
            u.info "Complete Parameters"
        * key: 'S-p'
          name: "Set/edit parameter"
          cmd: ->
            node = posi.cursor.node
            construc = node.rn(n.data-type-r).rn(n.constructor-r)
            if construc
              fcall-h.choose-and-set-or-edit-parameter node, construc
      ]

  #apply-surch-result: (node, result) ->


    # compute "#{node.ni}-new-class-select", ->
    #   cl = node.rn(n.data-type-r)
    #   if cl
    #     # class selected => populate arguments
    #     if (construc = node.rn(n.data-type-r).rn(n.constructor-r))
    #       u.next-tick ->
    #         fcall-h.populate-args-from-func-params(
    #           fcall: node,
    #           func: construc
    #         )



