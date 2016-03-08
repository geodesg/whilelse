module.exports = class JavascriptExperiment extends Backbone.View

  render: ->
    $('body').append($list = $('<div>'))

    for prop of window
      $list.append($('<div>').text(prop))
