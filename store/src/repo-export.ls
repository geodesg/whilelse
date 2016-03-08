require! 'fs'
require! 'readline'
prelude = require 'prelude-ls'
{find,each,map} = prelude
Repo = require './repo'
#clog = require './clog'

document = process.argv[2]

{create-repo-from-document} = require './doc-loader'

create-repo-from-document document, (repo) ->
  #out = fs.create-write-stream "./data/documents/#{document}.repo.dylog"
  raw-repo = repo.export-repo!
  #out.write "#{JSON.stringify(raw-repo)}\n"






