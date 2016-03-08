{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

module.exports = class LayoutView extends Backbone.View
  id: 'layout'

  events:
    'click .key':   'onPress'

  build: ->

  template: (data) -> require("./template") data

  generate: ->
    $ @template!

  render: ->
    @build!
    @$el.html @generate!
    @$el

  keyCommands: ~>
    return @currentTreeNode.keyCommands!

  onPress: (ev) ~>
    console.log 'ev', ev
    keycode = $(ev.currentTarget).data('key')
    console.log "on-screen key:", keycode, JSON.stringify(keycode)
    @pressOnScreenKey(keycode)

  pressOnScreenKey: (keycode) ->
    ui = require 'ui'
    ui.pressOnScreenKey(keycode)
