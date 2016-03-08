
module.exports = api =

  urlRoot: "/api"

  ajax: (opts) ->
    opts.url = @urlRoot + opts.url
    #console.log 'AJAX Request', opts
    $.ajax(opts).done (response) -> #console.log 'AJAX Response', response

  ajax2: (type, url, data = {}, cb = (-> {})) -->
    #console.log "ajax2", type, url, data, cb
    #console.log '@ajax', api.ajax
    api.ajax do
      url: url
      type: type
      data: data
      success: cb
      error: -> alert "Failed API call: #{type} #{url}"

  #getNodeRep: (nodeId, repType, cb) ->
    #@ajax do
      #url: "/rep/#{repType}/#{nodeId}"
      #success: (data) ->
        #cb(data)

  getNode: (nodeId) -->
    @ajax2 \get "/n/#{nodeId}" {}


  bcallT: (nodeId, procName, params = {}) ->
    api.ajax do
      type: \post
      url: "/rpc/bt/#{nodeId}/#{procName}"
      data: params

  bcallN: (nodeId, procName, params = {}) ->
    api.ajax do
      type: \post
      url: "/rpc/bn/#{nodeId}/#{procName}"
      data: params

  bcallO: (nodeId, ownerNodeId, procName, params = {}) ->
    api.ajax do
      type: \post
      url: "/rpc/bo/#{nodeId}/#{ownerNodeId}/#{procName}"
      data: params

  # Returns object that encapsulates a node and contains methods
  # which call the API in the context of that node.
  #
  # The default callback expects the response data to represent
  # a node and sets the node model's attributes from this.
  # This can be overriden with the `cb` option.
  #
  nodeResource: (node, opts = {}) ->
    nodeId = node.get('id')
    cb = (data) ->
      if opts.callback
        opts.callback(data)
      else
        node.set(data)

    call = (type, path, data) -->
      api.ajax2 type, "/n/#{nodeId}#{path}", data, cb

    do

      setAttr: (attrTypeId, newValue) -->
        call \put "/a/#{attrTypeId}" { value: newValue }

      setType: (nti) -->
        call \put "/type" { value: nti }

      setAttrByName: (attrName, newValue) -->
        call \put "/an/#{attrName}", { value: newValue }

      deleteAttr: (ati) -->
        call \delete "/a/#{ati}", {}

      deleteRef: (ri) -->
        call \delete "/r/#{ri}", {}

      addCustomComponent: (key, opts) -->
        call \post "/component", { name: key, preset: opts.preset }

      addComponent: (rti, nti, name, desc) -->
        call \post "/component" do
          ref_type_id:  rti,
          node_type_id: nti,
          name:         name,
          description:  desc

      addCodeComponent: (key) -->
        @addCustomComponent key { preset: 'code' }

      addLink: (rti, gni) -->
        call \post "/link" do
          ref_type_id:    rti
          target_node_id: gni

      changeNodeAttrType: (ati, newAti) -->
        call \put "/a/#{ati}" newAti

      changeNodeRefType: (ri, newRti) -->
        call \post "/r/#{ri}/rti", { new_ref_type_id: newRti }

      moveNodeRef: (ri, position) -->
        call \post "/r/#{ri}/move" {@position}

