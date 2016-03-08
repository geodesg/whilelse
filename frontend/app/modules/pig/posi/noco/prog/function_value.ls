u = require 'lib/utils'
{map,each,concat,join,elem-index,filter,find} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h =

  apply-surch-result: (node, result) ->
    node.cAddLink n.function-r, result.node

