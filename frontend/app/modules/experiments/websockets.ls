module.exports = class WebsocketExperiment extends Backbone.View

  render: ->

    socket = new WebSocket "ws://#{window.location.host}/dy/"
    socket.onopen = (ev) ->
      console.log "OPENED", ev
      socket.send "halo"

    socket.onmessage = (ev) ->
      console.log "RECEIVED", ev.data, ev
