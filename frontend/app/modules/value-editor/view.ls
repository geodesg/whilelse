{ifnn} = u = require 'lib/utils'

module.exports =

  class ValueEditor extends Backbone.View
    uiName: 'Value Editor'
    callback: ->

    template: (data) ->
      require("./template") data

    generate: ->
      console.log 'generated', @, @model
      $ @template @model

    render: ->
      @$el.html @generate!
      console.log "ValueEditor.$el", @$el
      @$el

    withValidation: (validCb) ->
      [validValue, success] = @convertOutputValue(@$el.find('.value').val())
      if success
        validCb(validValue)
      else
        @$el.find('.type').addClass('invalid')
        clearInvalidClass = ~> @$el.find('.type').removeClass('invalid')
        setTimeout clearInvalidClass, 500

    keyCommands: ->
      return
        commands:

          * key: 'esc'
            name: 'Cancel'
            cmd: ~> @onFinish!

          * key: 'enter'
            name: 'Save'
            cmd: ~>
              @withValidation (newValue) ~>
                console.log "newValue", newValue
                @onFinish!
                @callback(newValue)

          * key: 'S-down'
            name: 'Toggle Type'
            cmd: ~>
              @$el.find('.type').addClass('active')
              @selectNextTypeRoundRobin!

    onKey: (keycode, ev) ->
      switch keycode
      case \esc then
        @onFinish!
      case \enter then
        @withValidation (newValue) ~>
          console.log "newValue", newValue
          @onFinish!
          @callback(newValue)

      if keycode == \shift
        @$el.find('.type').addClass('active')
        if @typeShiftStarted
          @selectNextTypeRoundRobin!
        else
          @typeShiftStarted = true
      else
        @$el.find('.type').removeClass('active')
        @typeShiftStarted = false

    convertOutputValue: (v) ->
      type = @$el.find('.type').text!
      switch type
      case \string then
        [v, true]
      case \number then
        if JSON.stringify(i = parseInt(v)) == v
          [i, true]
        else if JSON.stringify(f = parseFloat(v)) == v
          [f, true]
        else
          [null, false]
      case \boolean then
        if v == 'true' || v == 't'
          [true, true]
        else if v == 'false' || v == 'f'
          [false, true]
        else
          [null, false]
      case \null then
        if v == 'null' || v == ''
          [null, true]
        else
          [null, false]
      case \undefined
        [@convertValueGuessingType(v), true]
      else
        [null, false]

    convertValueGuessingType: (v) ->
      if JSON.stringify(i = parseInt(v)) == v
        i
      else if JSON.stringify(f = parseFloat(v)) == v
        f
      else if v == 'true' || v == 'yes'
        true
      else if v == 'false' || v == 'no'
        false
      else if v == 'null' || v == 'nil'
        null
      else if v[0] == '"' && v[v.length - 1] == '"'
        v.substring(1, v.length - 1)
      else if v[0] == "'"
        v.substring(1, v.length)
      else
        v


    onShow: ->
      @$el.find('.type').text(@getType(@model.value))
      @$el.find('.value').val(@model.value)
      @$el.find('.value').focus()
      @$el.find('.value').select()

    onFinish: -> # Override

    types: [ \string \number \boolean \null ]

    selectNextTypeRoundRobin: ->
      u.apply-fn-to-jq-text u.round-robin-by-value(@types), @$el.find('.type')

    getType: (obj) ->
      ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()
