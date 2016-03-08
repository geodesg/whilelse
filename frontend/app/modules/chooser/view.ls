{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

module.exports =
  class Chooser extends Backbone.View
    uiName: 'Chooser'

    template: (data) ->
      require("./template") data

    generate: ->
      #console.log "Chooser generate", @model
      $ @template(
        model: @model
        f: (s) ->
          s
            .replace("S-", "⇧")
            .replace("M-", "⌘")
            .replace("A-", "⌥")
            .replace("C-", "^")
      )

    render: ->
      @$el.html @generate!
      @$el

    keyCommands: ->
      commands = []

      @model.options |> each (option) ~>
        commands.push do
          key: option.key
          name: option.name
          cmd: ~>
            @onFinish!
            u.delay 200, ~> option.action!

      commands.push do
        key: 'esc'
        name: 'Cancel'
        cmd: ~>
          #console.log "Chooser Cancel"
          @onFinish!
          u.delay 100, ~> @model.onCancel! if @model.onCancel

      return
        commands: commands

    onKey: (keycode, ev) ->
      if keycode == \esc
        @onFinish!
      @model.options |> each (option) ~>
        if keycode == option.key
          @onFinish!
          option.action!

    onFinish: -> # Override
