{promise,ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index,find} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
ui = require '/ui'

module.exports = h =

  onKey: (keycode, ev) ->
    switch keycode
    when 'S-t' # Go to test subject
      if node = posi.cursor.node
        if subject = node.inrefNodesWithType(n.te-test-r)[0]
          posi.navigateToNode subject
        true

