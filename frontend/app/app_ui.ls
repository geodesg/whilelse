ui = require 'ui'

module.exports =
  moveFocusToRef: (rawRef) ->
    if ui.currentView.model.get('id') == rawRef.source_id
      ui.currentView.moveFocusToRef(rawRef)

  moveFocusToAttr: (nodeId, attrTypeId) ->
    if ui.currentView && ui.currentView.moveFocusToAttr?
      if ui.currentView.model.get('id') == nodeId
        ui.currentView.moveFocusToAttr(attrTypeId)

