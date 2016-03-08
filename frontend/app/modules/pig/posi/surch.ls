{ifnn, promise} = u = require 'lib/utils'
{map,each,filter,any,concat,join,elem-index,sort-by,maximum} = prelude
ui = require \ui
api = require 'api'
UpDownNavigator = require 'lib/up-down-navigator'
{n,repo} = require 'models/pig/common'
pig = require 'models/pig'
surch-utils = require 'modules/pig/posi/surch-utils'

module.exports = surch =

  # opts:
  #   - $el - anchor element
  #   - title - short title indicating what kind of input is expected
  #   - help - more help
  #   - initialChars
  #   - listOnStart: whether to list all options even if the query is empty - usefull where there's a small number of possibilities, e.g. a list of struct properties
  #   - search - function (q)::matches
  #                matches:
  #                  - keywords: array of string (used for prioritizing)
  #                  - kind (display)
  #                  - name (display)
  #                  - value (display)
  start: (opts) ->
    promise (d) ->
      console.log "surch.start(", opts, ")"
      sv = new SurchView model: opts
      sv.deferred = d
      ui.showDialog sv,
        beforeShow: ($dialogEl) ->
          $el = opts.$el
          offset = $el.offset()
          # Below
          $dialogEl.css("position", 'absolute')
          $dialogEl.css("top", "#{offset.top + 20}px")
          $dialogEl.css("left", "#{offset.left}px")
          sv.retrieve!


class SurchView extends Backbone.View
  uiName: "Gosi Surch"
  className: "gosi-surch"

  events:
    'keyup input.query': 'checkForChange'
    'input input.query': 'checkForChange'

  initialize: ->
    #

  render: ->
    @update!
    @input = @$el.find('.query')
    @input.attr('placeholder', @model.title)

    @input.val(@model.initialChars)

    u.nextTick ~>
      @input.focus!
    @$el

  update: ->
    #@build!
    @$el.html @generate!

  generate: ->
    $e = $ @template(@data!)
    $e

  template: (data) -> require("./surch-template") data

  data: ->
    {
    }

  keyCommands: ->
    return
      before: @matchNavigator
      commands: [
        * key: 'esc'
          name: 'Cancel'
          desc: 'Cancel search and close window'
          cmd: ~>
            @close!
            @deferred.reject abort: true
        * key: 'tab'
          name: 'Skip'
          desc: 'Skip this item'
          cmd: ~>
            @close!
            @deferred.reject skip: true
      ] ++ @injectedKeyCommands!

  injectedKeyCommands: ->
    (@model.keyCommands || []) |> map ({key, name, cmd}) ~>
      key: key
      name: name
      cmd: ~>
        q = @input.val!
        @close!
        cmd(q, @deferred)

  close: ->
    @$el.html ''
    ui.hideDialog this

  checkForChange: ->
    console.log "checkForChange"
    if @_previousValue != @input.val()
      @initDelayedRetrieval()
    @_previousValue = @input.val()

  initDelayedRetrieval: ->
    if @timer
      clearTimeout @timer
    @timer = setTimeout ~>
      @retrieve()
    , 1


  retrieve: ~>
    q = @input.val()
    #console.log "retrieve", q, !q?, JSON.stringify(q), @model
    return if ! q?
    return if q.length < 1 && !@model.listOnStart
    return if q == @lastQ
    if @lastQ && @lastQ.length > 0 && q.indexOf(@lastQ) == 0 && @over-result
      q-addition = q.substring(@lastQ.length)
      m = ^^ @over-result
      if m.stop-condition && m.stop-condition(q-addition)
        m.remainingChars = q-addition
        @close!
        @onSelect(m, {})
    @$el.find('.results').html("")
    @lastQ = q
    matches = @model.search q
    matches = surch-utils.prioritise-matches matches, {q}
    @updateMatches matches


  updateMatches: (searchResults) ->
    $r = @$el.find('.results')
    $r.html("")
    #console.log 'search results', searchResults
    @searchResults = searchResults

    @matchNavigator = new UpDownNavigator(
      elements: searchResults
      $container: $r
      template: (m) ~>
        # m: {kind,name,value}
        @matchTemplate(m)
      onSelect: (m, opts) ~>
        @close!
        @onSelect(m, opts)
      onOver: (m, opts) ~>
        @over-result = m
      onCancel: ~> @close!
    )
    @matchNavigator.render!
    @matchNavigator.moveToFirst!

  matchTemplate: (data) ->
    require("./surch-match-template") data

  onSelect: (m, opts) ->
    #console.log "onSelect", m, opts
    if m
      @deferred.resolve(m)
    else
      console.warn "Nothing selected"




