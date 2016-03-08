u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
{promise,c} = u = require 'lib/utils'
pig = require 'models/pig'
prog = posi.module "noco/prog/-module"

module.exports = h =

  get-expr-type: (node) ->
    # Find subject type, and if it's a typed hash, then select the value type
    if subject = node.rn(n.subject-r)
      subject-type = posi.handler-for(n.expr).get-expr-type(subject)
      if subject-type
        if subject-type.type! == n.hash-type
          subject-type.rn(n.data-type-r)



