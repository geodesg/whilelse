{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{n,repo} = require 'models/pig/common'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "route.select-as-target", $el, (d) ->
    d.resolve node-type: n.web-route


