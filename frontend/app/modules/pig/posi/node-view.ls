{promise,c} = u = require 'lib/utils'
{map,each,filter,concat,join,elem-index} = prelude

{box,compute,bcg,cbox} = boxlib = require 'lib/box'
cursor = require 'modules/pig/posi/cursor'

pig = require 'models/pig'
{n, repo} = common = require 'models/pig/common'
actions = require 'modules/pig/node/actions'

{tag,div,span,text,join,compute-el} = th = require 'modules/pig/posi/template-helpers'

currentRenderNestLevel = 0

posi = require 'modules/pig/posi/main'

class NodeView extends Backbone.View
  className: 'posi-view'

  initialize: ->
    {@node, @mode, @o} = @model

  render: ->
    ...

