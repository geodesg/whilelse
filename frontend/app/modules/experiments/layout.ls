module.exports = class LayoutExperiment extends Backbone.View

  template: (data) -> require("./layout-view") data

  generate: ->
    $e = $('<div>').html(@template!)
    $e

  render: ->
    @$el.html @generate!
    @$el
