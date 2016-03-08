require! 'express'
require! 'url'
app = express!

app.get '/dy2/load/:document', (req, res) ->
  document = req.params.document
  {create-repo-from-document} = require './doc-loader'
  create-repo-from-document document, (repo) ->
    raw-repo = repo.export-repo!
    res.send "#{JSON.stringify(raw-repo)}\n"

server = app.listen 3025, ->
  host = server.address!.address
  port = server.address!.port
  console.log 'Listening on http://%s:%s', host, port


