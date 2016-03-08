{promise,c} = u = require 'lib/utils'
{map,each,filter,concat,join,elem-index} = prelude

module.exports = class LoginView extends Backbone.View
  className: "login"

  events:
    'submit form' : 'onSubmit'

  initialize: ->
    u.lrem 'username'

  build: -> {}

  template: (data) -> require("./template") data

  generate: ->
    $e = $('<div>').html(@template!)
    $e

  render: ->
    @$el.html @generate!
    u.delay 1, ~> @$el.find('#username-input').focus!
    @$el

  onSubmit: (ev) ->
    ev.preventDefault!
    username = @$el.find('#username-input').val!
    u.lset 'username', username
    window.router.navigate "/posi/#{username}", trigger: true
