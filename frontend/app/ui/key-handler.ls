{map,each,concat,join,elem-index,find} = prelude
u = require 'lib/utils'
{keypress} = require 'lib/keypress'

details = (e) ->
  [e.keyCode, e.which, e.key, e.char, e.shiftKey, e.metaKey, e.ctrlKey, String.fromCharCode(e.keyCode)]

addModifiersToKeycode = (keycode, ev) ->
  keycode = "S-#{keycode}" if ev.shiftKey
  keycode = "M-#{keycode}" if ev.metaKey
  keycode = "A-#{keycode}" if ev.altKey
  keycode = "C-#{keycode}" if ev.ctrlKey
  keycode

window.simulateKey = (keycode) -> keyHandler.onKey(keycode)

module.exports = keyHandler =
  ui: null # injected by ui

  start: ->
    listener = new keypress.Listener()

    # webkit  = (navigator.userAgent.indexOf('AppleWebkit') != -1)
    # firefox = (navigator.userAgent.indexOf('Firefox') != -1)

    #   # Keys that only emit a keydown and not a keypress in Chrome, and also emit a keypress in Firefox
    #   chrome-special = [
    #     27, # esc
    #     112, 113, 114, 115, 116, 117, 118, 119, 120, 121,
    #     9, # tab
    #     8, # backspace
    #     37, 38, 39, 40, # arrows
    #     33, 34, 35, 36 # pgup, pgdn, end, home
    #   ]
    is-chrome-special = (code) -> chrome-special.indexOf(code) != -1

    # Printable character:
    #   Chrome  press      Char
    #   Firefox press/down .key

    # Key without modifiers
    #   Chrome  down       Char
    #   Firefox down       Char

    # Keyboard handling strategy:
    # - keydown is handled first, this emits key combinations
    # - keypress handles some characters that we want to handle as characters, e.g. '+', rather than 'S-='.
    #   This handles the '+' character according to the user's keyboard layout.

    skip-keypress = (ev) ->
      if ev.key == '^' && ev.altKey && ev.metaKey && ! ev.ctrlKey && ! ev.shiftKey
        # M-A-I in Firefox to open/close inspector
        true

    last-keydown = null
    require('ui/keycalc').start do
      listener: @~onKey
      editing: @~editing

  onKey: (keycode, ev) ->
    console.log "KEY", keycode
    handled = @delegateKey(keycode, ev, ui)
    if handled
      ev.preventDefault!

  delegateKey: (keycode, ev, view) ->
    done = false
    #console.log "delegateKey", keycode, view
    view = u.call-if-func(view)
    if view
      if view.keyCommands?
        #console.log 'keyCommands defined'
        spec = view.keyCommands!
        return false if ! spec
        #console.log 'spec', view.uiName, spec
        done = false
        if spec.before
          for item in u.to-array(spec.before)
            unless done
              done = @delegateKey(keycode, ev, item)
        unless done
          if spec.commands
            keyCommand = spec.commands |> find (iterKeyCommand) ->
              u.contains iterKeyCommand.key, keycode
            if keyCommand? && @isExecutable(keyCommand)
              #console.log "executing", view.uiName, keyCommand
              keyCommand.cmd!
              done = true
        if spec.after
          for item in u.to-array(spec.after)
            unless done
              done = @delegateKey(keycode, ev, item)
        #console.log "returning", view.uiName, done
      if ! done && view.onKey
        #console.log 'onKey defined'
        view.onKey(keycode, ev)
      else
        #console.log 'no key handler defined'
      done

  findKeys: (view) ->
    #console.log 'findKeys', view.uiName
    view = u.call-if-func(view)
    commands = []

    return [] if ! view

    if view.keyCommands?
      spec = view.keyCommands!
      return [] if ! spec
      if spec.before
        #console.log "spec.before array:", u.to-array(spec.before)
        #console.log "commands(1)", commands
        for beforeItem in u.to-array(spec.before)
          #console.log 'beforeItem', beforeItem
          commandsInner = @findKeys(beforeItem)
          if commandsInner
            #console.log "appending", commandsInner
            commands = commands.concat commandsInner

      #console.log 'spec.commands', spec.commands

      if spec.commands
        spec.commands |> each (iterKeyCommand) ~>
          if @isExecutable(iterKeyCommand)
            keys = u.to-array(iterKeyCommand.key)
            #console.log 'keys', keys
            keys |> each (key) ->
              commands.push do
                key: key
                ui: view.uiName
                details: u.merge(spec.defaults || {}, iterKeyCommand)

      if spec.after
        #console.log "[#{view.uiName}]", "spec.after array:", u.to-array(spec.after)
        for afterItem in u.to-array(spec.after)
          #console.log "[#{view.uiName}]", 'afterItem', afterItem
          commandsInner = @findKeys(afterItem)
          if commandsInner
            commands = commands.concat commandsInner

      commands

  pressOnScreenKey: (keycode) ->
    done = false
    @findKeys(ui) |> each (command) ~>
      return true if done
      spec = command.details
      specKey = if spec.place then spec.place else spec.key
      if specKey == keycode
        spec.cmd!
        done = true
    false

  # Refresh key-help sidebar
  refreshKeyCommands: ->
    commands = @findKeys(ui)
    # [ { key, ui, details{ key, name } } ]
    #console.log "commands: ", JSON.stringify(commands, null, 2)

    KeyHelpView = require('../modules/key-help/view')
    @keyHelpView ||= new KeyHelpView
    #console.log @keyHelpView
    @keyHelpView.model = commands
    #console.log @keyHelpView, @keyHelpView.render
    $('#sidebar').html(@keyHelpView.render!)

  isExecutable: (keyCommand) ->
    if keyCommand.cond
      keyCommand.cond!
    else
      true

  editing: ->
    #v = $ \:focus .length > 0
    # ':focus' doesn't work in PhantomJS
    vv = (ael = document.activeElement) && ael.tagName && ael.tagName == 'INPUT'
    #console.log "EDITING", v, vv
    vv

