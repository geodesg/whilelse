{map,each,concat,join,elem-index,find,filter} = prelude
{ifnn, ifnnp, promise} = u = require 'lib/utils'
{box,compute,bcg} = boxlib = require 'lib/box'
api = require 'api'

Node = require './node'
Ref = require './ref'
constants = require './constants'

process-command = (command, repo) ->
  console.log "Processing command: #{JSON.stringify command}"
  switch command_code = command[0]
  case 'n' then
    [_, ni, nti, name, attrs] = command
    node = new Node(repo, ni, nti, name, attrs)
  case 'a' then
    [_, ni, ati, val] = command
    repo.node(ni).pAttrs[ati] = val
  case 'r' then
    [_, ri, sni, rti, gni, dep] = command
    ref = new Ref(repo, ri, sni, rti, gni, dep)
    repo.node(sni).addRef ref
    repo.node(gni).addInref ref
  else console.error "Unknown command code: #{command_code}"

loaded = false

load = (repo) ->
  promise (d) ->
    if loaded
      d.resolve!
    else
      console.log "Loading js-rep..."
      api.ajax2 'get', '/js-rep', {}, (response) ->
        console.log "Importing..."
        commands = JSON.parse(response)
        for command in commands#.slice(0, 30)
          process-command(command, repo)
        console.log "Import finished."

        #window.n    = pig.n = constants.build-n!

        loaded := true
        constants.build(n, repo)
        #boxlib.startDebug!
        d.resolve!

module.exports = load

