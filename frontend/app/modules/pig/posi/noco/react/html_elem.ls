{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'

module.exports = h =
  apply-surch-result: (node, result) ->
    node.cSetAttr n.react-name-a, result.name
