{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
api = require \api
ui = require \ui

module.exports =
  class UpAndDown
    uiName: "Up-down navigator"

    (components) ->
      @components = components
      for iter_component, iter_index in @components
        if iter_component.hasClass('current')
          @index = iter_index

    keyCommands: ->
      return
        commands:
          * key: 'up'
            name: 'Move up'
            cmd: ~> @_moveCursor(-1)
          * key: 'down'
            name: 'Move down'
            cmd: ~> @_moveCursor(1)
          * key: 'k'
            name: 'Move up'
            cmd: ~> @_moveCursor(-1)
          * key: 'j'
            name: 'Move down'
            cmd: ~> @_moveCursor(1)

    onKey: (keycode, ev) ->
      switch keycode
      when 'down' then @_moveCursor( 1); true
      when 'up'   then @_moveCursor(-1); true
      when 'j'    then @_moveCursor( 1); true
      when 'k'    then @_moveCursor(-1); true

    _moveCursor: (dir) ->
      if @index?
        @_makeNotCurrent(@index)
      else
        @index = -1
      @index += dir
      _max = @components.length - 1
      if @index > _max
        @index = _max
      else if @index < 0
        @index = 0
      @_makeCurrent(@index)

    _makeCurrent:    (i) -> @components[i].addClass    \current
    _makeNotCurrent: (i) -> @components[i].removeClass \current


