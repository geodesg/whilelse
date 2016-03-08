{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
api = require \api
ui = require \ui

module.exports =
  class UpDownNavigator
    uiName: "Up-down navigator"

    (attrs) ->
      {
        @elements,   # collection of models
        @$container, # jQuery element, will insert elements here
        @template,   # template function, takes an element, returns html
        @onSelect,
        @onCancel,
        @onOver
      } = attrs

      @onSelect ||= (data) ->
      @onCancel ||= ->

    render: ->
      @$e = []
      if @elements && @elements.length
        @elements |> each (element) ~>
          $el = $(@template(element))
          @$e.push $el
          @$container.append $el

    keyCommands: ->
      return
        commands:
          * key: 'up'
            name: 'Move up'
            cmd: ~> @_moveCursor(-1)
          * key: 'down'
            name: 'Move down'
            cmd: ~> @_moveCursor(1)
          * key: 'enter'
            name: 'Select'
            cmd: ~> @select!
          * key: 'S-enter'
            name: 'Select'
            cmd: ~> @select(modifier: 'S')
          * key: 'C-enter'
            name: 'Select'
            cmd: ~> @select(modifier: 'C')
          * key: 'M-enter'
            name: 'Select'
            cmd: ~> @select(modifier: 'M')
          * key: 'esc'
            name: 'Close'
            cmd: ~> @onCancel!

    onKey: (keycode, ev) ->
      switch keycode
      when 'down' then @_moveCursor( 1); true
      when 'up'   then @_moveCursor(-1); true
      when 'enter' then @onSelect(@elements[@_i] || @elements[0])
      when 'esc' then @onCancel()

    _moveCursor: (dir) ->
      if @_i?
        @_makeNotCurrent(@_i)
      else
        @_i = -1
      @_i += dir
      _max = @elements.length - 1
      if @_i > _max
        @_i = _max
      else if @_i < 0
        @_i = 0
      console.log 'current: ', @_i
      if @$e[@_i]
        @_makeCurrent(@_i)

    _makeCurrent:    (i) ->
      @$e[i].addClass    \current
      @onOver(@elements[@_i]) if @onOver

    _makeNotCurrent: (i) -> @$e[i].removeClass \current

    select: (opts = {}) ->
      @onSelect(@elements[@_i] || @elements[0], opts)

    moveToFirst: ->
      if @_i? && @$e[@_i]
        @_makeNotCurrent(@_i)
      @_i = 0
      @_makeCurrent(@_i) if @$e[@_i]



