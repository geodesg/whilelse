{map,each,concat,join,elem-index,find} = prelude
{promise} = u = require 'lib/utils'
LayoutView = require './modules/layout/view'
keyHandler = require './ui/key-handler'

module.exports = ui =
  uiName: "Main"

  dialogStack: []

  start: ->
    keyHandler.ui = @
    keyHandler.start!

    @layoutView = new LayoutView
    $('body').html @layoutView.render!

    setTimeout((~> @refreshKeyCommands!), 100)

  pressOnScreenKey: (keycode) ->
    keyHandler.pressOnScreenKey(keycode)

  render: (template-name, options = {}) ->
    require("/templates/#{template-name}") options

  update: (place, template-name, options) ->
    @render template-name, options
    |> $("##{place}").html

  recalculateCurrentView: ->
    @currentView =
      if @dialogStack.length
        @dialogStack[@dialogStack.length - 1]
      else
        @mainView
    ui.refreshKeyCommands!

  setMainView: (view) ->
    @mainView = view
    @recalculateCurrentView!
    $('#main').html(view.render!)
    @trigger view, \onShow
    ui.refreshKeyCommands!

  showDialog: (view, opts = {}) ->
    view.isDialog = true
    @dialogStack.push(view)
    @recalculateCurrentView!
    view.close = ~>
      @hideDialog(view)
    unless opts.invisible
      view.render! if view.render
      $el = $('<div>').addClass('dialog').css("display", "none")
      if view.$el?
        $el.html(view.$el)
        $('body').append($el)
      opts.beforeShow($el) if opts.beforeShow?
      $el.css("display", "block")
      @trigger view, \onShow
    ui.refreshKeyCommands!

  activateInvisibleControl: (view) ->
    ui.showDialog view, invisible: true

  hideDialog: (view) ->
    if view.$el
      view.$el.parent('.dialog').remove!
      view.$el.remove!
    @dialogStack.pop!
    @recalculateCurrentView!


  trigger: (view, fn) ->
    view[fn]() if view[fn]

  keyCommands: ->
    return
      before: @currentView
      after: @global-handler

  refreshKeyCommands: ->
    if keyHandler?
      keyHandler.refreshKeyCommands!


  prompt: (title, cb) -> s = prompt(title); cb(s)

  input: ({title, $anchor, value}) -> promise (d) ->
    ui.anchored-dialog $anchor, d, {}, ($container, dialog) ->
      $input = $('<input>')
      $input.attr('placeholder', title)
      $input.attr('value', value) if value
      $form = $('<form>').append($input)
      $form.submit (ev) ->
        ev.preventDefault!
        dialog.close!
        d.resolve(value: $input.val())
      $container.append($form)
      $input.focus!

  anchored-dialog: ($anchor, d, {view} = {},  cb) ->
    @showDialog do
      className: 'anchored-dialog'
      uiName: 'Popup'
      render: ->
        @$el = $('<div>').addClass('anchored')
        ui.refreshKeyCommands!
        @$el
      keyCommands: ->
        return
          commands: [
            * key: 'esc'
              name: 'Abort'
              cmd: ~>
                @close!
                d.reject(abort: true)
            * key: 'tab'
              name: 'Skip'
              cmd: ~>
                @close!
                d.reject(skip: true)
          ]
          after: view
      onShow: ->
        ui.anchor(@$el.parent!, $anchor)
        cb @$el, @
        @afterShow! if @afterShow?

  anchor: ($dialog, $anchor) ->
    #console.log "ANCHOR", $dialog, $anchor
    if $anchor
      offset = $anchor.offset()
      #console.log offset
      #$container = $('body')
      #console.log "Offset: (#{offset.top},#{offset.left}) Scroll: (#{$container.scrollTop!},#{$container.scrollLeft!})"
      $dialog.css("position", 'absolute')
      $dialog.css("padding", ".1em")
      $dialog.css("background", "#334")
      $dialog.css("position", "absolute")
      $dialog.css("top", "#{offset.top + 20}px")
      $dialog.css("left", "#{offset.left}px")

  # args: {title,
  #        options: [{key, name, action
  #        $anchor
  choose: (args) ->
    {$anchor,title,options} = args
    Chooser = require('/modules/chooser/view')
    chooser = new Chooser(model: args)
    if $anchor
      promise (d) ->
        ui.anchored-dialog $anchor, d, {view: chooser}, ($container, dialog) ->
          $container.append(chooser.render!)
          chooser.onFinish = ~> dialog.close!
    else
      @showDialog(chooser)
      chooser.onFinish = ~> @hideDialog(chooser)

  select: (title, ...list) ->
    promise (d) ~>
      unikey = new (require('lib/unikey'))
      console.log 'unikey', unikey
      i = 1
      ui.choose do
        title: title
        options: list |> map (item) ~>
          {
            key: unikey.issue(item, i)
            name: item
            action: ~> d.resolve(item)
          }

  confirm: (title) ->
    promise (d) ~>
      ui.choose do
        title: title
        options:
          * key: 'y'
            name: 'yes'
            action: ~> d.resolve!
          * key: 'n'
            name: 'no'
            action: ~> null

  editValue: (value, callback) ->
    ValueEditor = require('/modules/value-editor/view')
    dialog = new ValueEditor(model: { value: value })
    dialog.callback = callback
    @showDialog(dialog)
    dialog.onFinish = ~> @hideDialog(dialog)

  htmlPopup: (html) ->
    @showDialog do
      uiName: 'Popup'
      render: ->
        @$el = $('<div>')
        @$el.html(html);
        ui.refreshKeyCommands!
        @$el
      keyCommands: ->
        return
          commands: [
            * key: 'esc'
              name: 'Close'
              cmd: ~> @close!
          ]
      onKey: (keycode, ev) ->
        if keycode == \esc
          @close!

  flash: (msgType, msg) ->
    $('.flash').remove!
    $el = null
    $('body').append do
      $el =
        $('<div>').addClass('flash')
                  .addClass("flash-#{msgType}")
                  .text(msg)
    f = -> $el.fadeOut 10000, -> $el.remove!
    setTimeout f, 2000

  delay: (t, f) -> setTimeout f, t


  find-or-create-global-el: (id) ->
    $el = $("##{id}")
    if $el.length == 0
      $el = $('<div>').attr('id', id)
      $('body').append($el)
    $el

  popupTextarea: (contents, {select} = {}) ->
    ui.showDialog do
      render: ->
        $display = u.ensure-element 'textarea-popup'
        $display.append($textarea = $('<textarea>'))
        $textarea.val(contents)
        $textarea.show!
        setTimeout do
          ->
            $textarea.focus!
            $textarea.select! if select
          100
        @$el = $display
      keyCommands: ->
        return
          commands: [
            * key: 'esc'
              name: 'close'
              cmd: ~>
                @close!
          ]

  navigate: (path, options = {}) ->
    if @currentView && @currentView.on-navigating-away
      @currentView.on-navigating-away!
    window.router.navigate path, u.merge({trigger: true}, options)


