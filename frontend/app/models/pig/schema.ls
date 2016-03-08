{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'
{box,compute,bcg} = boxlib = require 'lib/box'

{n, repo} = require './common'

module.exports = class Schema
  (@type) ->
    #u.debug true, "new Schema", @type.ni

  attrs: ~> @pAttrs ?= bcg "#{@type.ni}-schema-attrs", ~>
    merge-sattrs do
      (((@type != n.node) && (supt = @super-type!) && supt != 'none') && supt.schema!.attrs! || [])
      (
        @type.refs!
        |> filter (ref) -> ref.target!.type! == n.s-attr
        |> map (ref) -> ref.target!
        |> map (sattrNode) ->
          id:  sattrNode.ni
          at:  sattrNode.rn n.s-at
          avt: sattrNode.rn n.s-avt
          req: sattrNode.a n.s-req
          rep: sattrNode.a n.s-rep
      )


  refs: ~> @pRefs ?= bcg "#{@type.ni}-schema-refs", ~>
    merge-srefs do
      (((@type != n.node) && (supt = @super-type!) && supt != 'none') && supt.schema!.refs! || [])
      (
        @type.refs!
        |> filter (ref) -> ref.target!.type! == n.s-ref
        |> map (ref) -> ref.target!
        |> map (srefNode) ->
          id:  srefNode.ni
          rt:  srefNode.rn n.s-rt
          gnt: srefNode.rn n.s-gnt
          req: srefNode.a n.s-req
          rep: srefNode.a n.s-rep
          dep: srefNode.a n.s-dep
      )

  super-type: ~> @pSuperType ?= bcg "#{@type.ni}-schema-supertype", ~>
    #u.debugCall \warn, "#{@type.ni}-schema-supertype", ~>
      if @type == n.node
        \none
      else
        @type.rn(n.s-subtype-of) || n.node

  ref-with-type: (ref-type) ~>
    throw 'ref-type missing' if ! ref-type
    @refs! |> find (sref) ->
      sref.rt.ni == ref-type.ni

  inspect: ~> @pInspect ?= bcg "#{@type.ni}-schema-inspect", ~>
    s = "SCHEMA #{@type.ni}.#{@type.name!} "
    @attrs! |> map (attr) ->
      s += "#{numericality(attr)}#{attr.at && attr.at.name! || '@'}:#{attr.avt && attr.avt.name! || '@'} "
    @refs! |> map (ref) ->
      s += "#{numericality(ref)}#{ref.rt && ref.rt.name! || '@'}#{tfu(ref.dep,'-<','->','-:')}#{ref.gnt && ref.gnt.name! || '@'} "
    s

numericality = (prop) ->
  req = prop.req || false
  rep = prop.rep || false
  if req
    if rep then '+' else '!'
  else
    if rep then '*' else '?'

tfu = (x, trueval, falseval, undefinedval) ->
  if x === undefined
    undefinedval
  else if x
    trueval
  else
    falseval

merge-sattrs = (a, b) ->
  h = {}
  for sattr in a
    if sattr.at
      h[sattr.at.ni] = sattr
  for sattr in b
    if sattr.at
      h[sattr.at.ni] = sattr
  c = []
  for _, sattr of h
    c.push sattr
  c

merge-srefs = (a, b) ->
  h = {}
  key = (sref) -> "#{sref.rt.ni}-#{sref.gnt && sref.gnt.ni || ''}"
  for sref in a
    if sref.rt
      h[key(sref)] = sref
  for sref in b
    if sref.rt
      h[key(sref)] = sref
  c = []
  for _, sref of h
    c.push sref
  c

