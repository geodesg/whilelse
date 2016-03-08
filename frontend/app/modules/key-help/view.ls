{ifnn} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude

module.exports = class KeyHelpView extends Backbone.View
  uiName: "Key Help"
  className: 'key-help'

  build: ->
    @component-groups = {}
    @model |> each (command) ~>
      group = calculate-group(command)
      @component-groups[group] ?= []
      @component-groups[group].push new Entry model: command

  template: (data) -> require("./template") data

  generate: ->
    $ @template({ commands: @model })

  render: ->
    @remove!
    console.log 'render'
    @build!
    @$el.html @generate!
    $entries = @$el.find('.key-help-entries')

    groups = sort-groups @component-groups

    for group-key, entries of groups
      $group = $('<div>').addClass('group')
      $title = $('<div>').addClass('group-title').text(group-key)
      $group.append $title
      entries |> each (entry) ~>
        $group.append(entry.render!)
      $entries.append $group
    @$el


class Entry extends Backbone.View
  className: 'key-help-entry'

  template: (data) -> require("./entry-template") data
  render: ->
    @$el.html $ @template do
      key: convert-key(@model.key)
      label: @model.details.label || @model.details.name
    @$el.attr 'title', @model.details.desc || @model.details.name
    @$el

  events:
    "click": "press"

  press: (ev) ~>
    console.log ev, @model
    @model.details.cmd!


calculate-group = (command) ->
  command.details.group || command.ui || 'default'

sort-groups = (groups) ->
  g = {}
  for k in <[ nav cursor edit file mode view ]>
    g[k] = groups[k] if groups[k]

  for k, v of groups
    g[k] = v unless g[k]

  g

convert-key = (key) ->
  s = key
  end-bits = []
  if s[*-1] == '-'
    s = s.substring(0, key.length - 2)
    end-bits << '-'

  bits = s.split('-') ++ end-bits

  end-key = bits.pop!

  ret = ""
  for bit in bits
    ret +=
      switch bit
      when 'S' then '⇧'
      when 'C' then '⌃'
      when 'A' then '⌥'
      when 'M' then '⌘'
      else '?'

  ret +=
    switch end-key.toLowerCase!
    when 'enter' then '⏎ '
    when 'esc', 'escape' then '⎋'
    when 'backspace' then '⌫'
    when 'delete', 'del' then '⌦'
    when 'tab' then '⇥'
    when 'left' then '←'
    when 'right' then '→'
    when 'up' then '↑'
    when 'down' then '↓'
    when 'home' then '⇱'
    when 'end' then '⇲'
    when 'pageup', 'pgup' then '⇞'
    when 'pagedown', 'pgdn' then '⇟'
    when 'space', ' ' then '␣'
    else end-key.toUpperCase!


