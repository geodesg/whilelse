{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
api = require \api
ui = require \ui
UpDownNavigator = require 'lib/up-down-navigator'

class SearchView extends Backbone.View
  id: 'search-view'
  uiName: 'Search'

  resourceName: 'node' # node | attr_type | ref_type
  onSelect: (m, opts) ->
    path = "/gosi/#{m.key}"
    if opts.modifier == 'S'
      window.open path, '_blank'
    else
      window.router.navigate path, trigger: true

  events:
    'keyup input.search-query': 'checkForChange'
    'input input.search-query': 'checkForChange'

  input: -> @$el.find('input.search-query')


  template: (data) ->
    require("./template") data

  generate: ->
    $ @template title: (@title || "Search #{@resourceName}")

  render: ->
    #@build!
    @$el.html @generate!
    #@selectFromHash()
    @$el

  onShow: ->
    @$el.find 'input.search-query' .focus!

  checkForChange: ~>
    if @_previousValue != @input().val()
      @initDelayedRetrieval()
    @_previousValue = @input().val()

  initDelayedRetrieval: ->
    if @timer
      clearTimeout @timer
    @timer = setTimeout ~>
      @_retrieve()
    , 200

  _retrieve: ~>
    @$el.find('.search-results').html("")

    q = @input().val()
    return if ! q?
    return if q.length < 1
    return if q == @lastQ
    @lastQ = q
    #console.log "_retrieve", q
    @retrieve q, (data) ~>
      @updateMatches(data)

  # overridable
  retrieve: (q, cb) ->
    api.ajax(
      url: "/search/#{@resourceName}"
      method: 'get'
      data:
        q: q
        target_node_type: @opts.targetNodeType
      success: (data) ~>
        #console.log data
        cb(data)
      error: ->
        alert("Failed search: #{q}")
    )


  matchTemplate: (data) ->
    require("./match-template") data


  updateMatches: (searchResults) ->
    $r = @$el.find('.search-results')
    $r.html("")
    #console.log 'search results', searchResults
    @searchResults = searchResults

    @matchNavigator = new UpDownNavigator(
      elements: searchResults.matches
      $container: $r
      template: (m) ~>
        @matchTemplate(
          url: "/gosi/#{m.key}",
          display: m.display
        )
      onSelect: (m, opts) ~>
        @close!
        @onSelect(m, opts)
      onCancel: ~> @close!
    )
    @matchNavigator.render!
    @matchNavigator.moveToFirst!

  close: ->
    @$el.html ''
    ui.hideDialog this


  keyCommands: ->
    return
      before: @matchNavigator
      commands: [
        * key: 'esc'
          name: 'Cancel'
          desc: 'Cancel search and close window'
          cmd: ~> @close!
      ]


  opts: {}




module.exports = SearchView
