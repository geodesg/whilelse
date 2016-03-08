{ifnn} = u = require 'lib/utils'
SearchView = require 'modules/search/view'
ui = require 'ui'
api = require 'api'
appUi = require 'app_ui'

module.exports = actions =

  # Returns an object which encapsulates the node and
  # contains methods that operate on that node.
  nodeResource: (node) ->
    nodeId = node.get('id') || node.ni!
    cb = (data) -> node.set(data)
    nodeApi = api.nodeResource(node)

    do

      addAttr: ->
        actions.selectAttrType (attrTypeId) ~>
          @addAttrWithType attrTypeId

      addStringAttr: ->
        actions.selectAttrType (attrTypeId) ~>
          @addAttrWithType attrTypeId

      addAttrWithType: (attrTypeId) ->
        value = ''
        console.log "value", value, JSON.stringify(value)
        ui.editValue value, (newValue) ~>
          console.log "newValue", newValue, JSON.stringify(newValue)
          callback = (data) ->
            node.set(data)
            appUi.moveFocusToAttr(nodeId, attrTypeId)
          api.nodeResource(node, callback: callback)
            .setAttr attrTypeId, JSON.stringify(newValue)

      addComponent: ->
        actions.searchSelect 'ref_type', {}, (refTypeId) ~>
          console.log "refTypeId: #{refTypeId}"
          @addComponentWithRefTypeId(refTypeId)

      addLink: ->
        actions.searchSelect 'ref_type', {}, (refTypeId) ~>
          console.log "refTypeId: #{refTypeId}"
          @addLinkWithRefTypeId(refTypeId)

      addComponentWithRefTypeId: (refTypeId) ->
        actions.searchSelect 'node_type', {}, (nodeTypeId) ~>
          ui.prompt 'name', (name) ->
            ui.prompt 'description', (description) ->
              callback = (data) ->
                node.set(data.source)
                appUi.moveFocusToRef(data)
              api.nodeResource(node, callback: callback)
                .addComponent refTypeId, nodeTypeId, name, description

      addContainsComponent: ->
        @addComponentWithRefTypeId 8

      addLinkWithRefTypeId: (refTypeId, targetNodeType = null) ->
        actions.searchSelect 'node', {}, (nodeId)->
          console.log "nodeId: #{nodeId}"
          callback = (data) ->
            console.log "addLinkWithRefTypeId cb", data
            node.set(data.source)
            appUi.moveFocusToRef(data)
          api.nodeResource(node, callback: callback)
            .addLink refTypeId, nodeId

      editAttr: (ati, value) ->
        ui.editValue value, (newValue) ~>
          console.log "newValue", newValue, JSON.stringify(newValue)
          nodeApi.setAttr ati, JSON.stringify(newValue), {}

      setType: ->
        actions.searchSelect 'node_type', {}, (nti) ~>
          nodeApi.setType nti

      deleteAttr: (ati) ->
        if confirm('Delete?')
          nodeApi.deleteAttr ati

      deleteRef: (ri) ->
        if confirm('Delete?')
          nodeApi.deleteRef ri


  selectAttrType: (cb) ->
    @searchSelect 'attr_type', {}, (ati) -> cb(ati)


  searchSelect: (resourceName, opts, cb) ->
    searchView = new SearchView
    searchView.resourceName = resourceName
    searchView.onSelect = (m) ->
      #console.log "Selected", m
      cb(m.key)

    ui.showDialog searchView
    true

