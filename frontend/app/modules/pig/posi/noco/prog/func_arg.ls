{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'

module.exports = h =
  select-as-target: ({$el,parent}) -> promise "func-arg.select-as-target", $el, (d) ->
    # For a function with no parameters don't ask for any arguments.
    # Arguments are created based on the parameters when the fcall is created.
    d.reject skip: true




