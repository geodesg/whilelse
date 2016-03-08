{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

module.exports = h =

  get-expr-type: (node) ->
    console.log 'get-expr-type', node.inspect!

    # Find function
    iter-node = node
    loop
      iter-node = iter-node.parent!
      if ! iter-node
        throw "Invalid 'this': parent class not found"
      break if iter-node.type! == n.class
    iter-node

