{promise,c} = u = require 'lib/utils'
{map,each,filter,concat,join,elem-index} = prelude

module.exports = class GuideView extends Backbone.View
  className: "guide"

  initialize: ->
    u.lrem 'username'

  build: -> {}

  template: (data) ->
    content = require("./template") data
    content = content.replace(/\[([^\]\[]+)\]/g, '<kbd>$1</kbd>')
    #content = content.replace(/'([^ ]+)'/g, '<q>$1</q>')
    content

  generate: ->
    $e = $('<div>').html(@template!)
    $e

  render: ->
    @$el.html @generate!
    @$el

