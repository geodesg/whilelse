listeners = []
editing = null

emit-keycode = (key, ev) ->
  for l in listeners
    l(key, ev)

#-----------------------------------------------
gecko-keynames =
  Escape: \esc
  Backspace: \backspace
  Tab: \tab
  Enter: \enter
  CapsLock: \caps
  Shift: \shift
  Alt: \alt
  Control: \ctrl
  Meta: \cmd
  ArrowUp: \up
  ArrowDown: \down
  ArrowLeft: \left
  ArrowRight: \right
  PageDown: \pagedown
  PageUp: \pageup
  Home: \home
  End: \end
  Delete: \delete
  Insert: \insert

webkit-keynames =
  Escape: \esc
  Backspace: \backspace
  Tab: \tab
  Enter: \enter
  CapsLock: \caps
  Shift: \shift
  Alt: \alt
  Control: \ctrl
  Meta: \cmd
  Up: \up
  Down: \down
  Left: \left
  Right: \right
  PageDown: \pagedown
  PageUp: \pageup
  Home: \home
  End: \end
  Delete: \delete
  Insert: \insert

webkit-which =
  8: \backspace
  9: \tab
  13: \enter
  27: \esc
  46: \delete


handlers =
  gecko:
    keydown: (ev) ->
      key-name = function-key(ev.key) || gecko-keynames[ev.key]

      if key-name?
        key = key-name
        key = addModifiersToKeycode key, ev# unless isModifier key
        emit-keycode key, ev
      else if ev.char && ev.char != ' ' && hasModifier(ev)
        if editing! && ! ev.metaKey && ! ev.ctrlKey
          return
        key = ev.char.toLowerCase!
        if key.length > 1 || /^[a-z0-9]$/.test(key) # only function keys (Arrow, Tab, Esc, F1 etc) OR letters
          key = addModifiersToKeycode key, ev
          emit-keycode key, ev
          return

    keypress: (ev) ->
      if ev.key && /^F[0-9]+$/.test(ev.key)
        return

      if ev.key && gecko-keynames[ev.key]?
        return
      if editing!
        return
      key = ev.key
      if key == ' '
        key = addModifiersToKeycode key, ev
      if ! ev.metaKey && ! ev.ctrlKey
        emit-keycode key, ev

  webkit:
    keydown: (ev) ->
      key-name = function-key(ev.keyIdentifier) || webkit-keynames[ev.keyIdentifier] || webkit-which[ev.which]
      if key-name?
        key = key-name
        key = addModifiersToKeycode key, ev# unless isModifier key
        emit-keycode key, ev
      else if ev.char && ev.char != ' ' && hasModifier(ev)
        if editing! && ! ev.metaKey && ! ev.ctrlKey
          return
        key = ev.char.toLowerCase!
        if key.length > 1 || /^[a-z0-9]$/.test(key) # only function keys (Arrow, Tab, Esc, F1 etc) OR letters
          key = addModifiersToKeycode key, ev
          emit-keycode key, ev
          return

    keypress: (ev) ->
      return if function-key(ev.key)
      return if editing!
      key = ev.char
      if key == ' '
        key = addModifiersToKeycode key, ev
      if ! ev.metaKey && ! ev.ctrlKey
        emit-keycode key, ev


addModifiersToKeycode = (keycode, ev) ->
  plain-keycode = keycode
  keycode = "S-#{keycode}" if ev.shiftKey unless plain-keycode == 'shift'
  keycode = "M-#{keycode}" if ev.metaKey  unless plain-keycode == 'cmd'
  keycode = "A-#{keycode}" if ev.altKey   unless plain-keycode == 'alt'
  keycode = "C-#{keycode}" if ev.ctrlKey  unless plain-keycode == 'ctrl'
  keycode

hasModifier = (ev) ->
  ev.shiftKey || ev.metaKey || ev.altKey || ev.ctrlKey

hasCharModifier = (ev) ->
  # Modifiers that can change the character: e.g. Shift-a -> A, Alt-w -> ∑
  ev.shiftKey || ev.altKey

isModifier = (keycode) ->
  keycode == 'shift' || keycode == 'ctrl' || keycode == 'alt' || keycode == 'cmd'

function-key = (k) ->
  k if k && /^F[0-9]+$/.test(k)

detect-engine = ->
  ua = navigator.userAgent
  contains = (x) -> ua.indexOf(x) != -1
  if contains('Firefox')
    'gecko'
  else if contains('Chrome') || contains('Safari') || contains('AppleWebKit')
    'webkit'
  else if contains('Gecko')
    'gecko'
  else
    throw "Can't recognize engine: #{ua}"

#-----------------------

extend-ev = (ev) ->
  ev.char = String.fromCharCode(ev.keyCode)
  ev

inited = false
init = ->
  inited := true
  document.onkeydown  = keycalc.keydown
  document.onkeypress = keycalc.keypress

module.exports = keycalc =
  start: (args) ->
    init! unless args.no-document
    listeners.push args.listener
    editing := args.editing
    keycalc.engine ?= args.engine || detect-engine!

  keydown:  (ev) -> handlers[keycalc.engine].keydown  extend-ev ev
  keypress: (ev) -> handlers[keycalc.engine].keypress extend-ev ev
