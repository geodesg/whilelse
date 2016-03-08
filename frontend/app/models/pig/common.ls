{map,each,concat,join,elem-index,find,filter} = prelude

repo =
  nodes: {}
  refs: {}
  node: (ni) ->
    return null if ! ni
    repo.nodes[ni] ?= instantiate-node(ni)
  node-ifx: (ni) ->
    node = instantiate-node(ni, allow-missing: true)
    return null if !node
    repo.nodes[ni] ?= node
  ref: (ri) ->
    repo.refs[ri] ?= instantiate-ref(ri)
  raw: null # inserted by pig.load

  instanciate-all-nodes-with-types: (types) ->
    nti-list = types |> map (.ni)
    for ni, raw-node of repo.raw.nodes
      if raw-node.nti in nti-list
        if ! repo.nodes[ni]
          node = repo.node(ni)




module.exports =
  n: {}
  repo: repo


instantiate-node = (ni, {allow-missing} = {}) ->
  throw "ni missing" if ! ni
  #console.log "Node #{ni} INSTANTIATE"
  node = repo.raw.nodes[ni]
  if ! node
    if allow-missing
      return null
    else
      throw "Node #{ni} not found in raw repo."
  {nti,name,attrs,refs,inrefs} = node
  Node = require 'models/pig/node'
  new Node(repo,ni,nti,name,attrs,refs,inrefs)

instantiate-ref = (ri) ->
  throw "ri missing" if ! ri
  #console.log "Ref #{ri} INSTANTIATE"
  {rti,sni,gni,dep} = repo.raw.refs[ri] or throw "Ref #{ri} not found in raw repo."
  Ref = require 'models/pig/ref'
  new Ref(repo,ri,sni,rti,gni,dep)
