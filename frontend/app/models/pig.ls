{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'
{box,compute,bcg} = boxlib = require 'lib/box'

constants = require './pig/constants'
{n, repo, ref-repo} = common = require './pig/common'
conn = require './pig/conn'

conn.open!

WebsocketStore = require 'modules/pig/websocket-store'
websocket-store = new WebsocketStore(conn)

RestApiLoader = require 'modules/pig/rest-api-loader'
rest-api-loader = new RestApiLoader

LocalStore = require 'modules/pig/local-store'
local-store = new LocalStore(conn)

loaded = false
last-id = 0
record-id = (id) -> last-id := id if id > last-id

module.exports = pig = window.pig =
  repo: repo
  load: ->
    promise (d) ->
      if loaded
        d.resolve!
      else
        show-time "Loading"
        t0 = (new Date()).getTime!
        command-counter = 0
        command-limit = null # if gen then 1000 else null
        command-handler = (wire-cmd) ->
          command-counter := command-counter + 1
          if command-limit && command-counter > command-limit
            if command-counter == command-limit + 1
              console.error "Stopped processing commands. Max #{command-limit}"
          else
            pointy-cmd = convert-to-pointy(wire-cmd)
            pig.apply-pointy ...pointy-cmd

        # init ws connection with document name
        websocket-store.init(command-handler, {document: pig.workspace!})

        # load as raw repo
        raw-repo-loader = require 'modules/pig/raw-repo-loader'
        raw-repo-loader(pig.workspace!).done (raw-repo) ->
          repo.raw = raw-repo
          loaded := true
          constants.build(n, repo)
          t1 = (new Date()).getTime!
          console.log "Loaded in ", t1 - t0
          show-time "Loaded"
          d.resolve!

        # steps = []
        # #steps.push -> websocket-store.load(command-handler, {document: pig.workspace!})
        #
        # steps.push -> rest-api-loader.load(command-handler, {document: pig.workspace!})
        #
        # if /^local\-/.test pig.workspace!
        #   steps.push -> local-store.load(command-handler)
        #
        # u.iterateF steps .done ->
        #   #Skip to the next 10^x
        #   #record-id Math.pow(10, Math.ceil(Math.log10(last-id)))
        #   loaded := true
        #   constants.build(n, repo)
        #   t1 = (new Date()).getTime!
        #   console.log "Loaded in ", t1 - t0
        #   d.resolve!

  workspace: ->
    window.workspace ?= 'local-write'

  # Wild command from the UI
  #   -> to be converted and sent to backend
  command: (ctyp, h) ->
    wire-cmd = [ctyp, h]
    console.log "☀︎ COMMAND-#{pig.workspace!}", JSON.stringify wire-cmd
    wire-cmd =[ctyp, h]

    switch sync-mode
    case 'local-write'
      local-store.add(wire-cmd)
    case 'remote-write'
      websocket-store.add(wire-cmd)


  search: (q, opts) ->
    surch-utils = require 'modules/pig/posi/surch-utils'

    r = new RegExp(q.split('').join('.*'))

    results = []
    repo.nodes |> prelude.Obj.each (node) ->
      dbg = false # (node.ni == '6450')
      if (!opts.type || pig.is-a(node, opts.type))
        console.log "node.fq", node.fq! if dbg
        if fq = node.fq!
          if dbg
            console.log "fq match", fq, r, fq.match(r)
          if fq.match(r)
            results.push do
              keywords: surch-utils.keywords-for-node(node)
              display: fq
              key: node.ni
              node: node

    results = surch-utils.prioritise-matches(results, {q})

    results

  is-a: (subject, test-type) ->
    dbg = false #(subject.ni == '6450')
    console.log "is-a", subject.inspect!, test-type.inspect! if dbg
    iter-type = subject.type!
    console.log "iter-type", iter-type.inspect! if dbg
    while iter-type
      if iter-type == test-type
        console.log "return true" if dbg
        return true
      iter-type = iter-type.super-type!
      console.log "iter-type", iter-type.inspect! if dbg
    console.log "return false" if dbg
    false


  apply-pointy: (ctyp, {ni,ri,node,node-type,ref-type,source,target,name,attrs,attr-type,ref,before-ref,value}) ->
    switch ctyp
    case 'core'
      Node = require 'models/pig/node'
      nti = (node-type && node-type.ni || ni) # node-type missing for special case: node #1 => default to nti
      #console.log "New Node", ni, nti, name
      new-node = new Node repo, ni, nti, name, {}
      new-node
    case 'comp'
      Node = require 'models/pig/node'
      Ref = require 'models/pig/ref'
      if repo.node-ifx(ni)
        # special case: set parent for core node
        target = repo.node(ni)
      else
        target = new Node repo, ni, node-type.ni, name, attrs
      ref = new Ref repo, ri, source.ni, ref-type.ni, ni, true
      boxlib.transaction ->
        source.addRef ref, before-ref
        target.addInref ref
      target
    case 'link'
      Ref = require 'models/pig/ref'
      ref = new Ref repo, ri, source.ni, ref-type.ni, target.ni, false
      source.addRef ref
      target.addInref ref
      target
    case 'move'
      ref = node.parentRef!
      ref.source!.rmRef ref
      ref.setSource source
      ref.setType(ref-type)
      source.addRef ref, before-ref
    case 'name'
      node.setName(name)
    case 'ntyp'
      node.setType(node-type)
    case 'attr'
      if attr-type == n.name
        node.setName(value)
      else
        node.setAttr(attr-type, value)
    case 'rtyp'
      ref.setType(ref-type)
    case 'del'
      node or throw "node missing"
      delete repo.nodes[node.ni]
      parentRef = node.parentRef!
      parentRef.source!.rmRef(parentRef)
    case 'ulnk'
      ref.source!.rmRef(ref)
      ref.target!.rmInref(ref)
    else
      throw "unknown ctyp: #{ctyp}"

  issue-new-id: (repo) ->
    "ac#{u.random-string(10)}"
    # local-last = localStorage.getItem('last-id')
    # local-last = parseInt(local-last) if local-last
    # l = Math.max(last-id, local-last || 0)
    # new-id = l + 1
    # record-id new-id
    # localStorage.setItem('last-id', new-id)
    # new-id
    #min = 10000
    #loop
      #candidate = rand-in-range min, min * 100
      ##console.log "candidate", candidate
      #if ! repo.node(candidate)
        ##console.log "return", candidate
        #return candidate
      #else
        ##console.log "bad candidate"
      #min *= 10

  undo-stack: []

  push-undo: (...wire-cmd) ->
    #console.log "PUSH-UNDO", ...wire-cmd
    if pig.activity-status == false
      pig.activity null, -> pig.push-undo ...wire-cmd
    else
      pig.undo-stack[*-1].commands.push wire-cmd

  undo: ->
    if item = pig.undo-stack.pop!
      wire-cmds = item.commands

      # Sync to Backend
      pig.command 'undo', val: wire-cmds.length

      # Apply on Frontend
      for wire-cmd in prelude.reverse(wire-cmds)
        #console.log "UNDO", ...wire-cmd
        pointy-cmd = convert-to-pointy wire-cmd
        pig.apply-pointy ...pointy-cmd

      # Restore cursor before original action
      if item.cursor-elem-id && ($el = $("##{item.cursor-elem-id}")) && $el.length > 0
        posi = require 'modules/pig/posi/main'
        posi.cursor.set($el)
      else if item.cursor-ni
        posi = require 'modules/pig/posi/main'
        posi.select-node repo.node(item.cursor-ni)


  activity-status: false # Used by activity()

  # Bundles commands together so that one Undo will undo all commands in the last activity
  activity: (name, cb) ->
    posi = require 'modules/pig/posi/main'

    prev-status = pig.activity-status
    if prev-status == false # not a nested activity
      pig.undo-stack.push do
        cursor-ni: posi.cursor.last-node-ni
        cursor-elem-id: posi.cursor.$currentElem?.attr('id')
        commands: []
    pig.activity-status = true
    ret = cb!
    pig.activity-status = prev-status
    if prev-status == false
      if pig.undo-stack[*-1].commands == [] # nothing happened
        pig.undo-stack.pop!
    ret


window.schemas = {}

# ------------ Utils ------------
rand-in-range = (min, max) -> Math.floor(Math.random! * (max - min + 1) + min)



convert-to-pointy = (wire-cmd) ->
  [ctyp, {ni,ri,nti,rti,sni,gni,name,attrs,ati,bri,val}] = wire-cmd
  record-id ni if ni
  record-id ri if ri
  h =
    switch ctyp
    case 'core'
      node-type =
        if nti && nti != ni
          then repo.node(nti) || throw "nti not found: #{nti}"
          else null
      {ni, node-type, name}
    case 'comp'
      source = repo.node(sni) || throw "sni not found: #{sni}"
      ref-type = repo.node(rti) || throw "rti not found: #{rti}"
      before-ref =
        if bri
          (source.refs! |> find (ref) -> ref.ri == bri) || throw "bri not found: #{bri}"
      node-type = repo.node(nti) || throw "nti not found: #{nti}"
      {ri,source,ref-type,before-ref,ni,node-type,name,attrs}
    case 'link'
      source = repo.node(sni) || throw "sni not found: #{sni}"
      ref-type = repo.node(rti) || throw "rti not found: #{rti}"
      target = repo.node(gni) || throw "gni not found: #{gni}"
      if bri
        before-ref = repo.node(bri)# || throw "bri not found: #{bri}"
      {ri,source,ref-type,target,before-ref}
    case 'move'
      node = repo.node(ni) || throw "ni not found: #{ni}"
      source = repo.node(sni) || throw "sni not found: #{sni}"
      ref-type = repo.node(rti) || throw "rti not found: #{rti}"
      before-ref =
        if bri
          repo.ref(bri) || throw "bri not found: #{bri}"
        else
          null
      {node,source,ref-type,before-ref}
    case 'name'
      node = repo.node(ni) || throw "ni not found: #{ni}"
      {node,name}
    case 'ntyp'
      node = repo.node(ni) || throw "ni not found: #{ni}"
      node-type = repo.node(nti)
      {node,node-type}
    case 'attr'
      node = repo.node(ni) || throw "ni not found: #{ni}"
      attr-type = repo.node(ati) || throw "ati not found: #{ati}"
      {node,attr-type,value:val}
    case 'rtyp'
      ref = repo.ref(ri) || throw "ri not found: #{ri}"
      ref-type = repo.node(rti) || throw "rti not found: #{rti}"
      {ref,ref-type}
    case 'del'
      node = repo.node(ni) || throw "ni not found: #{ni}"
      {node}
    case 'ulnk'
      ref = repo.ref(ri) || throw "ri not found: #{ri}"
      {ref}
    else
      throw "unknown ctyp: #{ctyp}"
  [ctyp, h]


