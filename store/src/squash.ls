require! 'fs'
require! 'readline'
prelude = require 'prelude-ls'
{find,each,map} = prelude
Repo = require './repo'
#clog = require './clog'
repo = new Repo

document = process.argv[2]

source-file-name = "./data/documents/#{document}.dylog"

source = readline.create-interface input: fs.create-read-stream source-file-name

source.on 'line', (line) ->
  #console.log "\nLine: #{line}"
  process-line(line)

source.on 'close', ->
  out = fs.create-write-stream "./data/documents/#{document}.out.dylog"
  repo.export-wire-cmds (wire-cmd) ->
    {ctyp, args} = wire-cmd
    out.write "#{JSON.stringify(wire-cmd)}\n"


process-line = (line) ->
  wire-cmd = JSON.parse(line)
  repo.process-wire-cmd wire-cmd



