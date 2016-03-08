require! 'fs'
require! 'readline'
prelude = require 'prelude-ls'
{find,each,map} = prelude
Repo = require './repo'
#clog = require './clog'
repo = new Repo

source-file-name = './data/history.dylog'

source = readline.create-interface input: fs.create-read-stream source-file-name

source.on 'line', (line) ->
  #console.log "\nLine: #{line}"
  process-line(line)

source.on 'close', ->
  files = {}
  repo.export-wire-cmds (wire-cmd) ->
    {ctyp, args} = wire-cmd
    document = find-document-for wire-cmd
    files[document] ?= fs.create-write-stream "./data/documents/#{document}.dylog"
    files[document].write "#{JSON.stringify(wire-cmd)}\n"
  console.log doc-deps

doc-deps = {}

# Everything depends on core
docdep =
  core: []
  prog: ['native_coding']
  db: ['prog']
  templating: ['prog']
  web: ['prog', 'templating']





process-line = (line) ->
  wire-cmd = JSON.parse(line)
  repo.process-wire-cmd wire-cmd

get-command-ids = ([ctyp, {ni,ri,nti,rti,sni,gni,name,attrs,ati,bri,val}]) ->
  switch ctyp
  case 'core'
    [ni,[nti] ++ atis(attrs)]
  case 'comp'
    [ni,[sni,rti,nti,bri] ++ atis(attrs)]
  case 'link'
    [sni,[rti,gni,bri]]
  case 'move'
    [sni,[rti,bri]]
  case 'name'
    [ni,[]]
  case 'ntyp'
    [ni,[nti]]
  case 'attr'
    [ni,[ati]]
  case 'rtyp'
    ref = repo.refs[ri]
    [ref.sni,[rti]]
  case 'del'
    [ni,[]]
  case 'ulnk'
    ref = repo.refs[ri]
    [ref.sni,[]]
  else
    ...

find-document-for = (cmd) ->
  [ni, dep-ni] = get-command-ids(cmd)

  if ! ni
    throw "no ni for #{cmd}"

  doc = find-topmost-ancestor-name ni
  if ! doc
    throw "no doc for #{ni} #{JSON.stringify cmd}"
  deps = dep-ni |> map (d-ni) -> find-topmost-ancestor-name d-ni

  doc-deps[doc] ?= []
  deps |> each (dep) ->
    if dep != doc && doc-deps[doc].index-of(dep) == -1
      if doc == 'core' && dep == 'prog'
        console.log JSON.stringify cmd
      doc-deps[doc].push dep

  doc


find-topmost-ancestor-name = (ni) ->
  find = ->
    iter-node = repo.nodes[ni]
    while iter-node
      parent = iter-node.parent!
      if parent && parent.ni == '9' # root
        return iter-node.name
      iter-node = iter-node.parent!
    null
  doc = find! || 'core'
  doc = 'core' if doc == 'native_coding'
  doc

atis = (attrs) ->
  r = []
  for ati, val of attrs
    r.push ati
  r


# { core: [ 'prog', 'native_coding' ],
#   country: [ 'core' ],
#   pro: [ 'core' ],
#   prog: [ 'core', 'native_coding' ],
#   native_coding: [ 'core' ],
#   templating: [ 'core', 'native_coding', 'prog' ],
#   notes: [ 'core' ],
#   web: [ 'core', 'prog' ],
#   users: [ 'core' ],
#   experiments: [ 'core', 'prog', 'native_coding', 'web', 'lib', 'db' ],
#   lib: [ 'core', 'prog', 'native_coding' ],
#   db: [ 'core', 'prog' ] }
