{n, repo} = common = require 'models/pig/common'
{map,each,concat,join,elem-index,find,filter} = prelude

{promise,c} = u = require 'lib/utils'

# bridging models & dom objects

class BNode
  (@el) ->
    if ! @el
      throw "@el blank"
  node: ~> node-from-el(@el)
  parent: ~>
    @_parent ?= new BNode @el.parent!.closest('.posi-node')
  parent-reft: ~>
    @_parent-reft ?= new BReft @el.closest('.posi-reft')

  add-to-reft: ({reft}) -> promise (d) ~>
    posi = require 'modules/pig/posi/main'
    $refts = posi.find-elements-within @el, '.posi-reft', '.posi-propt'
    $reft = $refts |> find ($iter-reft) ->
      ('' + $iter-reft.data('rti')) == ('' + reft.ni)
    if !$reft
      d.resolve(nothing: true)
      return
    console.log "ADD-TO-PROPT", $reft
    posi.add-to-propt $reft |> c d


class BReft
  (@el) ->
    window.breftel = @el
  rti: ~> @el.data \rti
  source: ~>
    $node = @el.closest('.posi-node')
    $node.length > 0 or throw "source node not found for BReft #{@el.get(0).outerHTML}"
    new BNode $node
  reft: ~> repo.node(@rti!) || throw 'reft not found'
  sref: ~> @_sref ?= @source!.node!.type!.schema!.ref-with-type(@reft!)
  gnt: ~> (sref = @sref!) && sref.gnt
  rt: ~> (sref = @sref!) && sref.rt
  rep: ~> ((sref = @sref!) && sref.rep) || false
  reload: ~> @el := reload-by-id(@el)
  find-append-blank: ~>
    console.log "find-append-blank"
    # Find first blank that doesn't belong to a child
    a = find-elements-within(@el, '.blank', '.posi-node')
    console.log "a.length", a.length, a
    if a.length > 0
      # Example: op arg: fill in the first one first
      a[0]

class BAttr
  (@el) ->

  edit: -> promise (d) ~>
    posi = require 'modules/pig/posi/main'
    attr-type = @attr-type!
    node = @node!
    ui.input({title: attr-type.name!, $anchor: @el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        value = posi.guess-and-convert-type(value)
        node.cSetAttr(attr-type, value)
        posi.cursor.update!
        d.resolve!

  attr-type: ->
    ati = @el.closest('.posi-attrt').data('ati') || throw 'ati missing'
    repo.node(ati) || throw 'attr-type node not found'

  node: ->
    ni = @el.closest('.posi-node').data('ni') || throw 'ni missing'
    repo.node(ni) || throw 'node not found'

class BAttrt
  (@el) ->

class BName
  (@el) ->
  edit: -> promise (d) ~>
    posi = require 'modules/pig/posi/main'
    node = @node!
    ui.input({title: "name", $anchor: @el}) |> c d,
      done: ({value} = {}) ->
        value = null if value == ''
        node.cSetName(value)
        posi.cursor.update!
        d.resolve!

  node: ->
    ni = @el.closest('.posi-node').data('ni') || throw 'ni missing'
    repo.node(ni) || throw 'node not found'

export BName, BReft, BNode, BAttr, BAttrt


#--- private
node-from-el = ($node) ->
  $node.length || throw 'node element blank'
  ni = $node.data('ni') || throw 'ni missing'
  node = repo.node(ni) || throw 'node not found'
  node

reload-by-id = ($el) ->
  $el || throw "no $el given"
  if $el.closest('body').length
    $el
  else
    $el || throw "$el missing"
    $el.length > 0 || throw "$el does not refer to any element"
    id = $el.attr('id')
    if !id
      console.error "No id for el", $el, $el.html!
      throw "no id for el"
    $el = $("##{id}")
    $el.length > 0 || throw "$el not found by id"
    $el

find-elements-within = ($el, selector, stop-selector = null, results = []) ->
  $el.children!.each (i, child) ->
    $child = $ child
    if $child.is selector
      results.push $child
    else
      if stop-selector && $child.is(stop-selector)
        # don't go deeper
        ;
      else
        find-elements-within($child, selector, stop-selector, results)
    true
  results
