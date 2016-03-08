{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

module.exports = class ViewUpDownNavigator
  ({@view}) ->

  keyCommands: ->
    return
      commands:
        * key: 'k'
          name: 'Move up'
          place: 'up'
          cmd: ~> @navigateProperties(-1)
        * key: 'j'
          name: 'Move down'
          place: 'down'
          cmd: ~> @navigateProperties(1)

  onKey: (keycode, ev) ->
    switch keycode
    case 'j' then @navigateProperties 1; true
    case 'k' then @navigateProperties -1; true
    else false

  ensureCurrentIndex: ->
    if ! @cursorIndex?
      @changeCurrentIndex(0)

  move: (direction) ->
    @navigateProperties(direction)

  navigateProperties: (direction) ->
    newIndex =
      if @cursorIndex?
        @cursorIndex
      else
        -1
    newIndex += direction

    return if ! @view.components?
    return if @view.components.length == 0

    _max = @view.components.length - 1

    if newIndex > _max
      newIndex = _max
      @moveAcrossEdge(1) if @moveAcrossEdge?
    else if newIndex < 0
      newIndex = 0
      @moveAcrossEdge(-1) if @moveAcrossEdge?
    else
      @changeCurrentIndex(newIndex)

  changeCurrentIndex: (i) ->
    if @cursorIndex?
      @deactivateComponent @currentComponent!
    @cursorIndex = i
    comp = @currentComponent()
    if comp?
      u.setHash comp.hashId() if comp.hashId?
      @activateComponent(comp)

  currentComponent: ~>
    if @view.components? && @cursorIndex?
      @view.components[@cursorIndex]

  deactivate: ->
    @deactivateComponent @currentComponent!
    ui.refreshKeyCommands!

  activate: ->
    @ensureCurrentIndex!
    comp = @currentComponent()
    console.log "ViewUpDownNavigator/activate comp:", comp
    @activateComponent(comp) if comp

    ui.refreshKeyCommands!

  deactivateComponent: (comp) ->
    if comp?
      if comp.makeNotCurrent?
        comp.makeNotCurrent!
      else if comp.$el
        comp.$el.removeClass('current')


  activateComponent: (comp) ->
    if comp
      if @view?
        @view.currentComponent = comp
      if comp.makeCurrent?
        comp.makeCurrent!
      else if comp.$el
        comp.$el.addClass('current')
        f = ~> u.scrollTo comp.$el.find('.cursor')
        setTimeout f, 1

  blank: ->
    if ! @view?
      console.log "view-up-down-navigator: @view missing", @view
      true
    else if ! @view.components?
      console.log "view-up-down-navigator: @view.components missing", @view, @view.components
      true
    else if ! @view.components.length > 0
      console.log "view-up-down-navigator: @view.components empty", @view
      true
    else
      false

  componentAt: (index) ->
    if @view.components?
      @view.components[index]

  # Get the neighbour of the current element
  neighbour: (direction) ->
    if @cursorIndex?
      neighbourIndex = @cursorIndex + direction
      @componentAt(neighbourIndex)

  moveToEnd: (direction) ->
    if direction == 1
      @changeCurrentIndex(0)
    else
      @changeCurrentIndex(@view.components.length - 1)



