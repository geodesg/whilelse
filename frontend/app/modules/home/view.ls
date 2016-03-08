u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

class HomeView extends Backbone.View

  template: (data) -> require("./template") data

  generate: ->
    $('<div>').html(@template!)

  render: ->
    ui.global-handler.handleGlobalCommands!
    @$el.html @generate!
    @$el

module.exports = HomeView


