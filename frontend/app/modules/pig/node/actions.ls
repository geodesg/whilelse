{promise,c} = u = require 'lib/utils'
{map,each,concat,join,elem-index} = prelude
ui = require 'ui'
pig = require '/models/pig'
{n, repo} = require '/models/pig/common'

module.exports = actions =

  editName: (node) ->
    ui.editValue node.name!, (newValue) ->
      #console.log "newValue", newValue
      node.cSetName(newValue)

  editType: (node) ->
    actions.search-select type: n.ntyp .done (new-type) ->
      node.cSetType(new-type)

  editAttr: (node, attr) ->
    ui.editValue attr.value!, (newValue) ~>
      node.cSetAttr attr.type!, newValue

  removeAttr: (node, attr) ->
    node.cSetAttr attr.type!, null

  addAttr: (node) ->
    actions.selectAttrType! .done (attr-type) ->
      #console.log "attr-type selected", attr-type
      actions.addAttrWithType node, attr-type

  addAttrWithType: (node, attr-type) ->
    ui.editValue '', (newValue) ~>
      node.cSetAttr attr-type, newValue

  addComponent: (node) ->
    actions.search-select type: n.rtyp .done (ref-type) ->
      actions.addComponentWithType(node, ref-type)

  addComponentWithType: (node, ref-type) ->
    actions.search-select type: n.ntyp .done (node-type) ->
      actions.getName! .done (name) ->
        #node: (source, ref-type, before-ref, ni, node-type, name, attrs) ->
        node.cAddComponent(ref-type, node-type, name)

  getName: ({$anchor} = {}) ->
    promise (d) ->
      ui.input({title: 'name', $anchor}) |> c d,
        done: ({value} = {}) ->
          name = value
          name = null if name == ''
          d.resolve(name)

  addLink: (node) ->
    actions.search-select type: n.rtyp .done (ref-type) ->
      actions.addLinkWithType(node, ref-type)

  addLinkWithType: (node, ref-type) ->
    actions.search-select! .done (target) ->
      node.cAddLink(ref-type, target)

  deleteRef: (ref) ->
    if ref.dep!
      ref.target!.cDelete!
    else
      ref.cUnlink!

  # Flow:
  #
  #   - select dep (unless specified by the schema)
  #   - select target type (unless specified and doesn't have subtypes)
  #   [dep=true]
  #     - get name for new node - can be skipped => doesn't create node
  #   [dep=false]
  #     - search-select filtered by type
  #
  sAddRefWithType: (node, rt, sref = null, $el, gnt = null) -> promise (d) ->
    throw 'node missing' if ! node
    throw 'rt missing' if ! rt
    #console.log "sAddRefWithType", gnt
    #console.log node.type!.schema!.inspect!
    sref ?= node.type!.schema!.ref-with-type(rt)
    gnt ?:= (sref && sref.gnt || null)
    #if sref
      #console.log "sref", sref
    dep = (sref.dep if sref)
    actions.selectDep(dep) .done (dep) ->
      actions.sSelectTargetType(gnt) .done (gnt) ->
        if dep
          actions.getName({$anchor: $el}) |> c d,
            done: (name) ->
              new-node = node.cAddComponent rt, gnt, name
              d.resolve {new-node}
        else
          actions.search-select do
            title: "Select link target"
            type: gnt
            $anchor: $el
          |> c d,
            done: (target) ->
              node.cAddLink rt, target
              d.resolve!

  selectDep: (dep) ->
    promise (d) ->
      #console.log "dep: ", dep
      if dep == true || dep == false
        d.resolve(dep)
      else
        ui.choose do
          title: "Link or component?"
          options:
            * key: 'c'
              name: 'component'
              action: -> d.resolve(true)
            * key: 'l'
              name: 'link'
              action: -> d.resolve(false)

  sSelectTargetType: (gnt) ->
    promise (d) ->
      if gnt
        d.resolve(gnt)
      else
        actions.search-select do
          title: "Select target node type"
          type: n.ntyp
        .done (node-type) ->
          d.resolve(node-type)




  selectAttrType: ->
    # return promise
    @searchSelect type: n.atyp

  search-select: ({title,type,$anchor} = {}) ->
    type = undefined if type == n.node
    promise (d) ->
      SearchView = require 'modules/search/view'
      searchView = new SearchView
      searchView.title = title
      searchView.$anchor = $anchor
      #searchView.resourceName = resourceName
      suffix = ''#((type.name! if type) || '') #problem: messes up subtypes
      searchView.retrieve = (q, cb) ->
        cb do
          matches: pig.search(q + suffix, {type})

      ui.anchored-dialog $anchor, d, {view: searchView} ($container, dialog) ->
        searchView.onSelect = (m) ->
          #console.log "Selected", m
          dialog.close!
          d.resolve(m.node)

        dialog.afterShow = -> searchView.onShow!

        $container.append searchView.render!

      #ui.showDialog searchView
      true

  search-and-goto: (path-element) ->
    actions.search-select! .done (node) ~>
      @navigateToNode(node, path-element)

  navigateToNode: (node, path-element, opts) ->
    throw "node missing" if !node
    @navigateToNodeId(node.ni, path-element, opts)

  navigateToNodeId: (id, path-element, opts) ->
    throw "id missing" if !id
    path-element ?= "posi/#{pig.workspace!}"
    path = "/#{path-element}/#{id}"
    #console.log "Path", path
    window.router.navigate path, u.merge({trigger: true}, opts)

  change-view: (id) ->
    require('/change-node-view')(id)


