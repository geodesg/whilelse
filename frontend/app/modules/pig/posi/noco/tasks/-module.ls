{promise,c} = u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
cursor = require 'modules/pig/posi/cursor'

module.exports = h = tasks-h =
  onKey: (keycode, ev) ->
    switch keycode
    when 'up'
      posi.line-motion -1
      true
    when 'down'
      posi.line-motion 1
      true
    else
      false

