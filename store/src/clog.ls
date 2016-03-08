prelude = require 'prelude-ls'
{find,each,map} = prelude
Repo = require './repo'

module.exports = clog =
  nodes = {}
  refs = {}
  log = []
  repo = new Repo

  add: (wire-cmd) ->
    [ctyp, {ni,ri,nti,rti,sni,gni,name,attrs,ati,bri,val}] = wire-cmd

    log.push wire-cmd
    repo.process-wire-cmd wire-cmd

    switch ctyp
    case 'core'
      @nodes[ni] = log.length - 1
    case 'comp'
      @nodes[ni] = log.length - 1
      @refs[ni] = log.length - 1
    case 'link'
      @refs[ni] = log.length - 1
    case 'move'
      # Find comp command for the ni

      # Modify the source
      # - if the source non-existent at that point, move all commands

      # if bri not yet inserted at that point => insert before the next ri that was available
      node = @nodes[ni]
      ref = node.parent-ref!
      ref.source!.rm-ref ref
      ref.sni = sni
      ref.rti = rti
      @nodes[sni].add-ref ref, {bri}
    case 'name'
      @nodes[ni].name = name
    case 'ntyp'
      @nodes[ni].nti = nti
    case 'attr'
      if ati == '5' # name
        @nodes[ni].name = name
      else
        @nodes[ni].attrs[ati] = val
    case 'rtyp'
      @refs[ri].rti = rti
    case 'del'
      parent-ref = @nodes[ni].parent-ref!
      parent-ref.source!.rm-ref(parent-ref)
      delete @nodes[ni]
    case 'ulnk'
      ref = @refs[ri]
      ref.source!.rm-ref(ref)
      ref.target!.rm-inref(ref)

