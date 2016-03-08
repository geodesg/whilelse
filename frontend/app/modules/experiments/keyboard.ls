module.exports = class KeyboardExperiment extends Backbone.View

  render: ->
    @$el

  onKey: (keycode, ev) ->
    console.log "keycode", keycode
