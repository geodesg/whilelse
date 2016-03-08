{ifnn, promise} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
{n, repo} = common = require 'models/pig/common'
ui = require 'ui'

module.exports = cursor =

  start: (options) ->
    @startOptions = options
    $('.posi-elem').live 'mousemove', (ev) ~>
      if ev.screenX != cursor.screenX || ev.screenY != cursor.screenY
        # console.log 'mousemove', ev.screenX, ev.screenY
        cursor.screenX = ev.screenX
        cursor.screenY = ev.screenY
        $e = $ ev.target
        # ev.target might not actually be a gobj/glone/gitem, but the DOM leaf where the mouse is
        $el = $e.closest('.posi-elem')

        # Don't allow selecting children of a posi-unit
        $el = cursor.get-closest-unit($el)

        if ! @currentElem || @currentElem != $el.get(0)
          if @overTimeout
            clearTimeout @overTimeout
          f = ~>
            @overTimeout = null
            @setCurrentElem($el)
          @overTimeout = setTimeout f, 1

  currentNode: ->
    #g = require 'modules/gosi/main'

  setCurrentNode: (el) ->
    @setCurrentElem(el)

  set: ($el) ->
    #console.log "cursor.set", el.get(0)
    @setCurrentElem($el)

  set-closest-unit: ($el) ->
    cursor.set cursor.get-closest-unit($el)

  get-closest-unit: ($el) ->
    if ($units = $el.parents('.posi-unit')).length > 0
      # Choose the outermost unit and select the closest posi-elem containing it
      $units.last().closest('.posi-elem')
    else
      $el


  remove: ->
    $('.over').removeClass('over')
    $('.posi-cursor').hide!
    @$currentElem = null
    @$node = null
    @node = null
    @$reft = null
    @reft = null
    @$parent = null
    @parent = null
    @q =
      $el: null
      $node: @$node
      node: @node
      $reft: @$reft
      reft: @reft
      $parent: @$parent
      parent: @parent

  # Select the last known element by ID.
  # Useful after a DOM update, where the element might have been regenerated.
  # It also adjusts the cursor rectangle if the size or position has changed.
  update: ->
    if @currentId
      $el = $("##{@currentId}")
      if $el.length > 0
        @setCurrentElem($el)

  #private
  setCurrentElem: ($el) ->
    @$currentElem = $el
    @currentId = $el.attr('id')

    #@currentNode = $el.get(0)
    display-cursor($el)

    @$el = $el

    @$node = null
    @node = null
    if $el.hasClass('posi-node')
      @$node = $el
      @node = repo.node($el.data('ni'))
      @last-node-ni = @node.ni

    @$reft = null
    @reft = null

    $pEl = $el.parent!.closest('.posi-propt, .posi-node')
    if $pEl.hasClass 'posi-propt'
      @$reft = $pEl
      @reft = repo.node(@$reft.data('rti'))

    @$parent = null
    @parent = null
    if @$parent = $el.parent!.closest('.posi-node')
      @parent = repo.node(@$parent.data('ni'))

    @q =
      $el: $el
      $node: @$node
      node: @node
      $reft: @$reft
      reft: @reft
      $parent: @$parent
      parent: @parent

    @debounced-refresh-key-commands!
    @startOptions.onChange(@node, @reft, @parent)

  debounced-refresh-key-commands: u.debounce 100, ->
    ui.refreshKeyCommands!


$el: cursor.$currentElem


var $e1,$e2,$e3,$e4

display-cursor = ($el) ->
  $('.over').removeClass('over')
  $el.addClass('over')

  return # temp
  $c = $('.posi-cursor')
  if $c.length == 0
    $c = $('<div>').addClass('posi-cursor')
    $e1 := $('<div>').addClass('edge-h')
    $e2 := $('<div>').addClass('edge-v')
    $e3 := $('<div>').addClass('edge-h')
    $e4 := $('<div>').addClass('edge-v')
    $c.append($e1,$e2,$e3,$e4)
    $('body').append $c

  offset = $el.offset()

  set-edge-dim = ($e,x,y,w,h) ->
    $e.css 'top', y
    $e.css 'left', x
    $e.css 'width', w
    $e.css 'height', h

  set-box-dimensions = (x,y,w,h) ->
    s = 1
    set-edge-dim $e1, x - s, y - s, w + 2*s, s
    set-edge-dim $e2, x + w, y, s, h
    set-edge-dim $e3, x - s, y + h, w + 2*s, s
    set-edge-dim $e4, x - s, y, s, h

  set-box-dimensions offset.left, offset.top, $el.width!, $el.height!
  $c.show!




