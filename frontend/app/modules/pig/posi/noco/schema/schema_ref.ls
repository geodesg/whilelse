{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{box,compute,bcg,cbox} = boxlib = require 'lib/box'
{tag,div,span,text,join,compute-el,name} = th = require 'modules/pig/posi/template-helpers'
{n,repo} = require 'models/pig/common'
posi = require 'modules/pig/posi/main'
schema-module = posi.module "noco/schema/-module"

module.exports = h =
  select-as-target: schema-module.select-attr-ref-target

  onKey: (keycode, ev) ->
    switch keycode
    when 'S-n'
      node = posi.cursor.node
      ui.choose do
        title: 'Select numericality...'
        options:
          [
            ['o', '0/1', 'optional', false, false]
            ['s', '1',   'strict',   true,  false]
            ['m', '0+',  'multiple', false, true ]
            ['r', '1+',  'repeat',   true,  true ]
          ] |> map (spec) ->
            [key, code, description, req, rep] = spec
            key: key
            name: "#{code} #{description}"
            action: ->
              node.cSetAttr(n.s-req, req) unless node.a(n.s-req) == req
              node.cSetAttr(n.s-rep, rep) unless node.a(n.s-rep) == rep
      true

    when 'S-e'
      node = posi.cursor.node
      ui.choose do
        title: 'Select dependency flag...'
        options:
          [
            ['c', 'component', true]
            ['l', 'link',      false]
            ['u', 'undefined', null ]
          ] |> map (spec) ->
            [key, description, val] = spec
            key: key
            name: description
            action: ->
              node.cSetAttr(n.s-dep, val) unless node.a(n.s-dep) == val
      true

