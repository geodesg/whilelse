u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
actions = require './actions'

{box,compute,bcg} = boxlib = require 'lib/box'

divT = (text) -> $('<div>').text text
spanT = (tagClass, text) -> $('<span>').addClass(tagClass).text text

pig = require 'models/pig'
{n, repo} = common = require 'models/pig/common'
window.repo = repo
window.n = n

class PigNodeView extends Backbone.View
  className: "node property-editor"
  # keyCommands: ->
  #   return
  #     before: (@components[0] if @components)
  #
  # onKey: (keycode, ev) ->
  #   console.log "node-page received: ", keycode
  #   @components[0].onKey(keycode, ev)

  initialize: ->
    @id = @model


  build: ->
    { id: @model }
    # @components = []
    # @components.push new NodeEditor {@model}
    # if @model.get(\type) == 'node_type'
    #   @components.push new SnodeEditor { model: new Snode { id: @model.id } }
    # @components.push new SnodeEditor { model: new Snode { id: @model.get(\type_id) } }


  template: (data) -> require("./template") data

  generate: ->
    $e = $('<div>').html(@template!)
    $e

  render: ->
    console.log "RENDER"
    ni = @model || throw "no model"

    loaded = false
    setTimeout((~> @$el.html('Loading...') unless loaded), 200)

    pig.load! .done ~>
      loaded := true

      ni || throw "no model"
      compute "#{ni}-node-view", ~>
        console.log "computing node-view"
        @propertyComponents = []
        editorEl = $('<div class="pig-raw-editor">')
        @node = node = repo.node(ni)

        rows = $ '<div class="rows">'

        @propertyComponents.push new NameComponent model: {node,ni}
        @propertyComponents.push new TypeComponent model: {node,ni}

        node.attrList! |> each (attr) ~>
          @propertyComponents.push new AttComponent model: {node,ni,attr}

        node.refs! |> each (ref) ~>
          @propertyComponents.push new RefComponent model: {node,ni,ref}


        @propertyComponents |> each (component) -> rows.append(component.render!)

        editorEl.append headEl = $('<div class="head"/>')

        compute "#{ni}-node-view-crumbs", ~>
          crumbs = []
          node.ancestors! |> each (ancestor) ->
            crumbs.push "#{ancestor.ni}-#{ancestor.name!}"

          headEl.text crumbs.join(' / ')

        editorEl.append bodyEl = $('<div class="body"/>')
        bodyEl.append rows

        @$el.html(editorEl)
    @$el

  keyCommands: ->
    return
      before: @currentComponent!
      commands:

        * key: 's'
          name: 'Search'
          cmd: ~> actions.search-and-goto 'pn'

        * key: 'j'
          name: 'Down'
          place: 'down'
          cmd: ~> @navigateProperties 1

        * key: 'k'
          name: 'Up'
          place: 'up'
          cmd: ~> @navigateProperties -1

        * key: 'a'
          name: 'Add...'
          cmd: ~> @addSomething!

        * key: 'g'
          name: 'Go to...'
          cmd: ~> @goSomewhere!

        * key: 'esc'
          name: 'Close'
          cmd: ~> @close!
          cond: ~> @close?

        * key: 'v'
          name: 'View...'
          cmd: ~> actions.change-view(@id)

  onKey: (keycode, ev) ->
    console.log "node-editor received: ", keycode
    switch keycode
    case 'j' then @navigateProperties 1; true
    case 'k' then @navigateProperties -1; true
    case 'a' then @addSomething!; true
    case 'e' then @editFocusedPropertyValue(); true
    case 'esc' then @close! if @close?; true
    default ifnn @currentView, \onKey, keycode, ev

  addSomething: ->
    console.log 'actions', actions
    ui.choose(
      title: 'Add...'
      options: [
        { key: 's',   name: 'string attr',        action: ~> actions.addAttr(@node) }
        { key: 'a',   name: 'other attr',         action: ~> actions.addAttr(@node) }
        #{ key: 'o',   name: 'native method',      action: ~> actions.addNativeMethod(@node) }
        { key: 'c',   name: 'component',          action: ~> actions.addComponent(@node) }
        #{ key: 'S-c', name: 'contains component', action: ~> actions.addContainsComponent(@node) }
        { key: 'l',   name: 'link',               action: ~> actions.addLink(@node) }
        #{ key: 't',   name: 'type ref',           action: ~> actions.addLinkWithKey @node, 'type' 'node_type' }
        { key: 'n',   name: 'name attr',          action: ~> actions.editName @node }
        { key: 'd',   name: 'description attr',   action: ~> actions.addAttrWithType @node, n.desc }
      ]
    )

  goSomewhere: ->
    ui.choose(
      title: 'Go...'
      options: [
        { key: 'p',   name: 'to parent',  action: ~> @goToParent! }
      ]
    )

  selectFromHash: ->
    h = location.hash
    index = u.find-index @propertyComponents, (component) ->
      "##{component.hashId()}" == h
    if index?
      @setCurrentComponentIndex index

  setCurrentComponentIndex: (index) ->
    @cursorIndex = index
    c = @currentComponent()
    c.makeCurrent() if c

  ready: -> @node?

  navigateProperties: (direction) ->
    newIndex =
      if @cursorIndex?
        @cursorIndex
      else
        -1
    newIndex += direction
    _max = @propertyComponents.length - 1
    if newIndex > _max
      newIndex = _max
    else if newIndex < 0
      newIndex = 0
    @changeCurrentIndex(newIndex)

  moveFocusToRef: (rawRef) ->
    @propertyComponents |> each (propertyComponent) ~>
      if propertyComponent.type == \ref
        ref = propertyComponent.model
        if rawRef.type_id == ref.get(\type_id) && rawRef.target_id == ref.get(\target_id)
          @moveFocusTo(propertyComponent)

  moveFocusToAttr: (attrTypeId) ->
    @propertyComponents |> each (propertyComponent) ~>
      console.log "propertyComponent", propertyComponent
      if propertyComponent.type == \att
        attr = propertyComponent.model
        if attr.get('type_id') == attrTypeId
          @moveFocusTo(propertyComponent)

  moveFocusTo: (propertyComponent) ->
    i = 0
    @propertyComponents |> each (iPropertyComponent) ~>
      if propertyComponent == iPropertyComponent
        @changeCurrentIndex(i)
      i += 1

  changeCurrentIndex: (i) ->
    if @cursorIndex?
      comp = @currentComponent()
      if comp
        comp.makeNotCurrent()

    @cursorIndex = i
    u.setHash @currentComponent().hashId()
    @currentComponent().makeCurrent()
    ui.refreshKeyCommands!


  currentComponent: ~>
    @propertyComponents[@cursorIndex] if @cursorIndex?


  goToParent: ->
    navigateToNode @node.parent!


Component = Backbone.View.extend do
  className: 'row'
  render: ->
    #field = $ '<div class="row">'# .attr "id", "pig-field-#{fieldId}"
    if ! @ni
      console.error @
      throw "@ni missing"
    compute "#{@ni}-node-view-f#{@hashId!}", ~>
      @$el.hide!
      @$el.text ""
      @$el.append spanT('label', @label!)
      @$el.append spanT('field', @field!)
      @$el.fadeIn(100)


  makeCurrent: -> @$el.addClass \current
  makeNotCurrent: -> @$el.removeClass \current
  nodeActions: -> actions.nodeResource(@node)

NameComponent = Component.extend do
  initialize: -> {@node, @ni} = @model
  uiName: 'Name'
  type: \name
  hashId: -> \name
  label: -> \name
  field: -> @node.name!
  keyCommands: ->
    return
      commands: [
        * key: 'e'
          name: "Edit"
          cmd: ~> actions.editName(@node)
      ]

TypeComponent = Component.extend do
  initialize: -> {@node, @ni} = @model
  uiName: 'Type'
  type: \type
  hashId: -> "type"
  label: -> \type
  field: -> @node.type!.name!
  keyCommands: ->
    return
      commands: [
        * key: 'o'
          name: 'Open'
          cmd: ~>
            target = @node.type!
            console.log "Target", target
            navigateToNode(target)
        * key: 'e'
          name: "Edit"
          cmd: ~> actions.editType(@node)
      ]

AttComponent = Component.extend do
  initialize: -> {@node, @ni, @attr} = @model
  uiName: 'Attr'
  type: \att
  hashId: -> "a#{@attr.ati}"
  label: -> @attr.type!.name!
  field: -> @attr.value!
  keyCommands: ->
    return
      commands: [
        * key: 'e'
          name: "Edit"
          cmd: ~> actions.editAttr(@node, @attr)
        * key: 'd'
          name: 'Delete'
          cmd: ~> actions.removeAttr(@node, @attr)
      ]

RefComponent = Component.extend do
  initialize: -> {@node, @ni, @ref} = @model
  uiName: 'Ref'
  type: \ref
  hashId: -> "r#{@ref.ri || (throw "no ri in @ref")}"
  label: -> @ref.type!.name!
  field: -> "#{@ref.target!.ni} #{@ref.target!.name! || ''} <#{@ref.target!.type!.name!}>"
  keyCommands: ->
    return
      commands: [
        * key: 'o'
          name: 'Open'
          cmd: ~>
            target = @ref.target()
            console.log "Target", target
            navigateToNode(target)
        * key: 'd'
          name: 'Delete'
          cmd: ~> actions.deleteRef @ref
      ]

navigateToNode = (node) -> actions.navigateToNode(node, 'pn')
navigateToNodeId = (id) -> actions.navigateToNodeId(id, 'pn')

module.exports = PigNodeView


